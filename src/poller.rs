use std::time::Instant;
use tokio::sync::watch;
use tokio::time::{interval, Duration};

use rups::tokio::Connection;
use rups::ConfigBuilder;

use crate::notifier;
use crate::ups_state::{StatusFlag, UpsState, UpsStatus};

const NET_TIMEOUT: Duration = Duration::from_secs(10);

pub async fn run_polling_loop(
    state_tx: watch::Sender<UpsState>,
    mut config_rx: watch::Receiver<(String, u16, String)>,
    poll_interval: Duration,
) {
    let (mut host, mut port, mut ups_name_cfg) = config_rx.borrow_and_update().clone();

    let mut poll_interval_timer = interval(poll_interval);
    let mut old_state: Option<UpsState> = None;
    let mut conn_opt: Option<Connection> = None;
    let mut backoff = Duration::from_secs(5);

    // Emit a new state to the UI and fire any notifications its transition warrants,
    // routing every state change (success or failure) through the same bookkeeping.
    let emit = |old_state: &mut Option<UpsState>, new: UpsState| {
        let notifications = notifier::transition_notifications(old_state.as_ref(), &new);
        if !notifications.is_empty() {
            tokio::spawn(notifier::send_notifications(notifications));
        }
        let _ = state_tx.send(new.clone());
        *old_state = Some(new);
    };

    loop {
        if conn_opt.is_none() {
            let nut_host: rups::Host = match (host.clone(), port).try_into() {
                Ok(h) => h,
                Err(e) => {
                    tracing::error!("Invalid NUT host '{}:{}': {}", host, port, e);
                    emit(&mut old_state, UpsState::default());

                    tokio::select! {
                        _ = tokio::time::sleep(backoff) => {},
                        Ok(()) = config_rx.changed() => {
                            let cfg = config_rx.borrow_and_update();
                            host = cfg.0.clone();
                            port = cfg.1;
                            ups_name_cfg = cfg.2.clone();
                            backoff = Duration::from_secs(5);
                            old_state = None;
                        },
                    }
                    backoff = std::cmp::min(backoff * 2, Duration::from_secs(60));
                    continue;
                }
            };
            let config = ConfigBuilder::new().with_host(nut_host).build();

            let conn = match tokio::time::timeout(NET_TIMEOUT, Connection::new(&config)).await {
                Ok(Ok(c)) => Some(c),
                Ok(Err(e)) => {
                    tracing::error!(
                        "Failed to connect to NUT server at {}:{}: {}",
                        host,
                        port,
                        e
                    );
                    None
                }
                Err(_) => {
                    tracing::error!("Timed out connecting to NUT server at {}:{}", host, port);
                    None
                }
            };

            match conn {
                Some(c) => {
                    tracing::info!("Connected to NUT server at {}:{}", host, port);
                    conn_opt = Some(c);
                    backoff = Duration::from_secs(5);
                }
                None => {
                    emit(&mut old_state, UpsState::default());

                    tokio::select! {
                        _ = tokio::time::sleep(backoff) => {},
                        Ok(()) = config_rx.changed() => {
                            let cfg = config_rx.borrow_and_update();
                            host = cfg.0.clone();
                            port = cfg.1;
                            ups_name_cfg = cfg.2.clone();
                            backoff = Duration::from_secs(5);
                            old_state = None;
                        },
                    }
                    backoff = std::cmp::min(backoff * 2, Duration::from_secs(60));
                    continue;
                }
            }
        }

        // Wait for next poll tick or config change
        tokio::select! {
            _ = poll_interval_timer.tick() => {},
            Ok(()) = config_rx.changed() => {
                let cfg = config_rx.borrow_and_update();
                host = cfg.0.clone();
                port = cfg.1;
                ups_name_cfg = cfg.2.clone();
                conn_opt = None;
                backoff = Duration::from_secs(5);
                old_state = None;
                tracing::info!("Config changed, reconnecting to {}:{}", host, port);
                continue;
            },
        }

        if let Some(mut conn) = conn_opt.take() {
            let ups_list = match tokio::time::timeout(NET_TIMEOUT, conn.list_ups()).await {
                Ok(Ok(list)) => list,
                Ok(Err(e)) => {
                    tracing::error!("Failed to list UPS devices / connection lost: {}", e);
                    emit(&mut old_state, UpsState::default());
                    continue;
                }
                Err(_) => {
                    tracing::error!("Timed out listing UPS devices from {}:{}", host, port);
                    emit(&mut old_state, UpsState::default());
                    continue;
                }
            };

            let available: Vec<String> = ups_list.iter().map(|(name, _)| name.clone()).collect();

            let (ups_name, ups_desc) = match select_ups(&ups_list, &ups_name_cfg) {
                Some(pair) => pair,
                None => {
                    if ups_name_cfg.is_empty() {
                        tracing::warn!("NUT server at {}:{} reports no UPS devices", host, port);
                    } else {
                        tracing::error!(
                            "Configured UPS '{}' not found at {}:{}. Available: [{}]",
                            ups_name_cfg,
                            host,
                            port,
                            available.join(", ")
                        );
                    }
                    emit(&mut old_state, UpsState::default());
                    continue;
                }
            };

            let vars = match tokio::time::timeout(NET_TIMEOUT, conn.list_vars(&ups_name)).await {
                Ok(Ok(vars)) => vars,
                Ok(Err(e)) => {
                    tracing::warn!("Failed to fetch vars for UPS {}: {}", ups_name, e);
                    emit(&mut old_state, UpsState::default());
                    continue;
                }
                Err(_) => {
                    tracing::warn!("Timed out fetching vars for UPS {}", ups_name);
                    emit(&mut old_state, UpsState::default());
                    continue;
                }
            };

            match parse_ups_state(&ups_name, &ups_desc, vars) {
                Some(mut state) => {
                    state.available_ups = available;
                    emit(&mut old_state, state);
                    conn_opt = Some(conn);
                }
                None => {
                    // ups.status was absent: treat the poll as failed rather than emitting a
                    // state with empty flags (which would flap "Power Restored"). Keep the
                    // connection and try again next tick.
                    conn_opt = Some(conn);
                }
            }
        }
    }
}

/// Pick which UPS to monitor from a NUT `list_ups` result.
///
/// An empty `configured` name keeps the historical "first UPS" behavior. A
/// non-empty name must match exactly; a missing name yields `None` so the caller
/// can treat it as a connection-level failure rather than silently falling back.
fn select_ups(list: &[(String, String)], configured: &str) -> Option<(String, String)> {
    if configured.is_empty() {
        list.first().cloned()
    } else {
        list.iter().find(|(name, _)| name == configured).cloned()
    }
}

fn parse_ups_state(name: &str, desc: &str, vars: Vec<rups::Variable>) -> Option<UpsState> {
    let mut state = UpsState {
        name: name.to_string(),
        description: desc.to_string(),
        connection_ok: true,
        last_updated: Instant::now(),
        ..Default::default()
    };

    let mut saw_status = false;
    // Held separately so ups.power wins regardless of the order vars arrive in.
    let mut output_realpower: Option<f64> = None;
    for var in vars {
        let var_name = var.name();
        let value = var.value();

        match var_name {
            "ups.status" => {
                state.status = parse_status(&value);
                saw_status = true;
            }
            "battery.charge" => state.battery_charge = var.value().parse().ok(),
            "battery.charge.low" => state.battery_charge_low = var.value().parse().ok(),
            "battery.runtime" => state.battery_runtime_secs = var.value().parse().ok(),
            "battery.voltage" => state.battery_voltage = var.value().parse().ok(),
            "input.voltage" => state.input_voltage = var.value().parse().ok(),
            "output.voltage" => state.output_voltage = var.value().parse().ok(),
            "ups.load" => state.ups_load = var.value().parse().ok(),
            "ups.power" => state.power_watts = var.value().parse().ok(),
            "output.realpower" => output_realpower = var.value().parse().ok(),
            "ups.temperature" => state.temperature = var.value().parse().ok(),
            "ups.mfr" => state.manufacturer = Some(var.value().to_string()),
            "ups.model" => state.model = Some(var.value().to_string()),
            "ups.serial" => state.serial = Some(var.value().to_string()),
            "ups.firmware" => state.firmware_version = Some(var.value().to_string()),
            "input.frequency" => state.frequency = var.value().parse().ok(),
            "ups.efficiency" => state.efficiency = var.value().parse().ok(),
            "driver.name" => {
                if value.contains("usb") {
                    state.connection_type = Some("USB".to_string());
                } else if value.contains("snmp") || value.contains("netxml") {
                    state.connection_type = Some("Network".to_string());
                } else {
                    state.connection_type = Some(value.to_string());
                }
            }
            _ => {}
        }
    }

    if state.power_watts.is_none() {
        state.power_watts = output_realpower;
    }

    if !saw_status {
        tracing::warn!("UPS {} response is missing ups.status; treating poll as failed", name);
        return None;
    }

    Some(state)
}

fn parse_status(status_str: &str) -> UpsStatus {
    let mut flags = Vec::new();
    for part in status_str.split_whitespace() {
        match part {
            "OL" => flags.push(StatusFlag::Online),
            "OB" => flags.push(StatusFlag::OnBattery),
            "LB" => flags.push(StatusFlag::LowBattery),
            "RB" => flags.push(StatusFlag::ReplaceBattery),
            "CHRG" => flags.push(StatusFlag::Charging),
            "DISCHRG" => flags.push(StatusFlag::Discharging),
            "BOOST" => flags.push(StatusFlag::Boost),
            "TRIM" => flags.push(StatusFlag::Trim),
            "FSD" => flags.push(StatusFlag::ForcedShutdown),
            "NOCOMM" => flags.push(StatusFlag::NoCommunication),
            "OVER" => flags.push(StatusFlag::Overloaded),
            "BYPASS" => flags.push(StatusFlag::Bypass),
            _ => tracing::warn!("Unknown UPS status flag: {}", part),
        }
    }
    UpsStatus { flags }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rups::Variable;

    #[test]
    fn parse_ups_state_without_status_returns_none() {
        let vars = vec![
            Variable::parse("battery.charge", "80".to_string()),
            Variable::parse("ups.load", "20".to_string()),
        ];
        assert!(parse_ups_state("myups", "desc", vars).is_none());
    }

    #[test]
    fn parse_ups_state_with_status_returns_state() {
        let vars = vec![
            Variable::parse("ups.status", "OB DISCHRG".to_string()),
            Variable::parse("battery.charge", "80".to_string()),
        ];
        let state = parse_ups_state("myups", "desc", vars).expect("state present");
        assert!(state.connection_ok);
        assert!(state.status.flags.contains(&StatusFlag::OnBattery));
        assert_eq!(state.battery_charge, Some(80.0));
    }

    #[test]
    fn parse_ups_state_prefers_ups_power_over_output_realpower() {
        // output.realpower deliberately precedes ups.power to prove order doesn't decide.
        let vars = vec![
            Variable::parse("ups.status", "OL".to_string()),
            Variable::parse("output.realpower", "150".to_string()),
            Variable::parse("ups.power", "202".to_string()),
        ];
        let state = parse_ups_state("myups", "desc", vars).expect("state present");
        assert_eq!(state.power_watts, Some(202.0));
    }

    #[test]
    fn parse_ups_state_falls_back_to_output_realpower() {
        let vars = vec![
            Variable::parse("ups.status", "OL".to_string()),
            Variable::parse("output.realpower", "202".to_string()),
        ];
        let state = parse_ups_state("myups", "desc", vars).expect("state present");
        assert_eq!(state.power_watts, Some(202.0));
    }

    #[test]
    fn parse_ups_state_without_power_vars_leaves_power_none() {
        let vars = vec![Variable::parse("ups.status", "OL".to_string())];
        let state = parse_ups_state("myups", "desc", vars).expect("state present");
        assert_eq!(state.power_watts, None);
    }

    fn ups_list() -> Vec<(String, String)> {
        vec![
            ("serverroom".to_string(), "Rack UPS".to_string()),
            ("desk".to_string(), "Desk UPS".to_string()),
        ]
    }

    #[test]
    fn select_ups_empty_config_picks_first() {
        let selected = select_ups(&ups_list(), "");
        assert_eq!(selected, Some(("serverroom".to_string(), "Rack UPS".to_string())));
    }

    #[test]
    fn select_ups_named_picks_exact_match() {
        let selected = select_ups(&ups_list(), "desk");
        assert_eq!(selected, Some(("desk".to_string(), "Desk UPS".to_string())));
    }

    #[test]
    fn select_ups_named_not_found_returns_none() {
        assert!(select_ups(&ups_list(), "missing").is_none());
    }
}
