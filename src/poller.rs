use std::time::Instant;
use tokio::sync::watch;
use tokio::time::{interval, Duration};

use rups::tokio::Connection;
use rups::ConfigBuilder;

use crate::ups_state::{StatusFlag, UpsState, UpsStatus};

pub async fn run_polling_loop(
    state_tx: watch::Sender<UpsState>,
    mut config_rx: watch::Receiver<(String, u16)>,
    poll_interval: Duration,
) {
    let (mut host, mut port) = config_rx.borrow_and_update().clone();

    let mut poll_interval_timer = interval(poll_interval);
    let mut old_state = UpsState::default();
    let mut conn_opt: Option<Connection> = None;
    let mut backoff = Duration::from_secs(5);

    loop {
        if conn_opt.is_none() {
            let nut_host: rups::Host = match (host.clone(), port).try_into() {
                Ok(h) => h,
                Err(e) => {
                    tracing::error!("Invalid NUT host '{}:{}': {}", host, port, e);
                    let mut err_state = UpsState::default();
                    err_state.connection_ok = false;
                    let _ = state_tx.send(err_state);

                    tokio::select! {
                        _ = tokio::time::sleep(backoff) => {},
                        Ok(()) = config_rx.changed() => {
                            let cfg = config_rx.borrow_and_update();
                            host = cfg.0.clone();
                            port = cfg.1;
                            backoff = Duration::from_secs(5);
                        },
                    }
                    backoff = std::cmp::min(backoff * 2, Duration::from_secs(60));
                    continue;
                }
            };
            let config = ConfigBuilder::new().with_host(nut_host).build();

            match Connection::new(&config).await {
                Ok(c) => {
                    tracing::info!("Connected to NUT server at {}:{}", host, port);
                    conn_opt = Some(c);
                    backoff = Duration::from_secs(5);
                }
                Err(e) => {
                    tracing::error!(
                        "Failed to connect to NUT server at {}:{}: {}",
                        host,
                        port,
                        e
                    );
                    let mut err_state = UpsState::default();
                    err_state.connection_ok = false;
                    let _ = state_tx.send(err_state);

                    tokio::select! {
                        _ = tokio::time::sleep(backoff) => {},
                        Ok(()) = config_rx.changed() => {
                            let cfg = config_rx.borrow_and_update();
                            host = cfg.0.clone();
                            port = cfg.1;
                            backoff = Duration::from_secs(5);
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
                conn_opt = None;
                backoff = Duration::from_secs(5);
                tracing::info!("Config changed, reconnecting to {}:{}", host, port);
                continue;
            },
        }

        if let Some(mut conn) = conn_opt.take() {
            match conn.list_ups().await {
                Ok(ups_list) => {
                    // Only monitor the first UPS
                    if let Some((ups_name, ups_desc)) = ups_list.into_iter().next() {
                        match conn.list_vars(&ups_name).await {
                            Ok(vars) => {
                                let state = parse_ups_state(&ups_name, &ups_desc, vars);

                                if state.status != old_state.status
                                    || state.connection_ok != old_state.connection_ok
                                {
                                    let old = old_state.clone();
                                    let new = state.clone();
                                    tokio::spawn(async move {
                                        crate::notifier::check_and_notify_state_changes(&old, &new)
                                            .await;
                                    });
                                }

                                let _ = state_tx.send(state.clone());
                                old_state = state;
                            }
                            Err(e) => {
                                tracing::warn!(
                                    "Failed to fetch vars for UPS {}: {}",
                                    ups_name,
                                    e
                                );
                            }
                        }
                    }
                    conn_opt = Some(conn);
                }
                Err(e) => {
                    tracing::error!("Failed to list UPS devices / Connection lost: {}", e);
                    let mut err_state = UpsState::default();
                    err_state.connection_ok = false;
                    let _ = state_tx.send(err_state);
                }
            }
        }
    }
}

fn parse_ups_state(name: &str, desc: &str, vars: Vec<rups::Variable>) -> UpsState {
    let mut state = UpsState {
        name: name.to_string(),
        description: desc.to_string(),
        connection_ok: true,
        last_updated: Instant::now(),
        ..Default::default()
    };

    for var in vars {
        let name = var.name();
        let value = var.value();

        match name {
            "ups.status" => {
                state.status = parse_status(&value);
            }
            "battery.charge" => state.battery_charge = var.value().parse().ok(),
            "battery.charge.low" => state.battery_charge_low = var.value().parse().ok(),
            "battery.runtime" => state.battery_runtime_secs = var.value().parse().ok(),
            "battery.voltage" => state.battery_voltage = var.value().parse().ok(),
            "input.voltage" => state.input_voltage = var.value().parse().ok(),
            "output.voltage" => state.output_voltage = var.value().parse().ok(),
            "ups.load" => state.ups_load = var.value().parse().ok(),
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

    state
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
