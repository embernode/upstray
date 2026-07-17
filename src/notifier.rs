use crate::ups_state::{StatusFlag, UpsState};
use std::sync::atomic::{AtomicBool, Ordering};
use tokio::sync::OnceCell;
use zbus::proxy;
use zbus::Connection;

/// Global kill-switch for all desktop notifications (toggled from QML Settings).
pub static NOTIFICATIONS_ENABLED: AtomicBool = AtomicBool::new(true);

static DBUS_CONNECTION: OnceCell<Connection> = OnceCell::const_new();

async fn get_dbus_connection() -> zbus::Result<&'static Connection> {
    DBUS_CONNECTION
        .get_or_try_init(|| Connection::session())
        .await
}

#[proxy(
    interface = "org.freedesktop.Notifications",
    default_service = "org.freedesktop.Notifications",
    default_path = "/org/freedesktop/Notifications"
)]
trait Notifications {
    fn notify(
        &self,
        app_name: &str,
        replaces_id: u32,
        app_icon: &str,
        summary: &str,
        body: &str,
        actions: &[&str],
        hints: &std::collections::HashMap<&str, zbus::zvariant::Value<'_>>,
        expire_timeout: i32,
    ) -> zbus::Result<u32>;
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Urgency {
    Low = 0,
    Normal = 1,
    Critical = 2,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Notification {
    pub summary: &'static str,
    pub body: String,
    pub urgency: Urgency,
    pub icon: &'static str,
}

pub async fn send_notification(
    summary: &str,
    body: &str,
    urgency: Urgency,
    icon: &str,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    if !NOTIFICATIONS_ENABLED.load(Ordering::Relaxed) {
        return Ok(());
    }
    let connection = get_dbus_connection().await?;
    let proxy = NotificationsProxy::new(connection).await?;

    let mut hints = std::collections::HashMap::new();
    hints.insert("urgency", zbus::zvariant::Value::U8(urgency as u8));

    proxy
        .notify("upstray", 0, icon, summary, body, &[], &hints, 5000)
        .await?;

    Ok(())
}

pub async fn send_notifications(notifications: Vec<Notification>) {
    for n in notifications {
        let _ = send_notification(n.summary, &n.body, n.urgency, n.icon).await;
    }
}

/// Pure decision of which desktop notifications a state transition should emit.
///
/// `prev` is `None` before any state has ever been observed, so a healthy first
/// poll stays silent while a first poll that is already on battery still alarms.
pub fn transition_notifications(prev: Option<&UpsState>, new: &UpsState) -> Vec<Notification> {
    let mut out = Vec::new();

    if let Some(prev) = prev {
        if prev.connection_ok && !new.connection_ok {
            out.push(Notification {
                summary: "UPS: Connection Lost",
                body: format!("Cannot reach UPS '{}'. Check NUT service.", prev.name),
                urgency: Urgency::Normal,
                icon: "dialog-warning",
            });
            return out;
        }

        if !prev.connection_ok && new.connection_ok {
            out.push(Notification {
                summary: "UPS: Connection Restored",
                body: format!("Communication with '{}' re-established.", new.name),
                urgency: Urgency::Low,
                icon: "dialog-information",
            });
            // Fall through: a reconnect that reveals the UPS is already on battery (or
            // any other alarm) must still fire that alarm alongside the restore notice.
        }
    }

    // Status transitions are only meaningful while we currently hold a live connection.
    if !new.connection_ok {
        return out;
    }

    // When reconnecting from a disconnected state its flags are empty, so any currently
    // active alarm is measured against that empty baseline and re-fires as expected.
    let empty: Vec<StatusFlag> = Vec::new();
    let prev_flags: &[StatusFlag] = match prev {
        Some(p) => &p.status.flags,
        None => &empty,
    };
    let new_flags = &new.status.flags;

    let newly = |flag: StatusFlag| !prev_flags.contains(&flag) && new_flags.contains(&flag);

    let newly_on_battery = newly(StatusFlag::OnBattery);
    let newly_low_battery = newly(StatusFlag::LowBattery);
    let newly_power_restored = prev_flags.contains(&StatusFlag::OnBattery)
        && !new_flags.contains(&StatusFlag::OnBattery);
    let newly_replace_battery = newly(StatusFlag::ReplaceBattery);
    let newly_fsd = newly(StatusFlag::ForcedShutdown);

    if newly_on_battery {
        let charge = new.battery_charge.unwrap_or(0.0);
        let runtime = new.battery_runtime_secs.unwrap_or(0) / 60;
        out.push(Notification {
            summary: "UPS: On Battery",
            body: format!(
                "Power outage detected. Running on battery ({}%, ~{} min)",
                charge, runtime
            ),
            urgency: Urgency::Normal,
            icon: "battery-caution",
        });
    }

    if newly_low_battery {
        let charge = new.battery_charge.unwrap_or(0.0);
        let runtime = new.battery_runtime_secs.unwrap_or(0) / 60;
        out.push(Notification {
            summary: "⚠️ UPS: Low Battery",
            body: format!(
                "Battery at {}% (~{} min remaining). Save your work!",
                charge, runtime
            ),
            urgency: Urgency::Critical,
            icon: "battery-low",
        });
    }

    if newly_fsd {
        out.push(Notification {
            summary: "🔴 UPS: Shutdown Imminent",
            body: "Forced shutdown in progress. Save immediately!".to_string(),
            urgency: Urgency::Critical,
            icon: "dialog-error",
        });
    }

    if newly_power_restored {
        let charge = new.battery_charge.unwrap_or(0.0);
        out.push(Notification {
            summary: "UPS: Power Restored",
            body: format!("Mains power restored. Battery at {}%", charge),
            urgency: Urgency::Low,
            icon: "battery-charging",
        });
    }

    if newly_replace_battery {
        out.push(Notification {
            summary: "UPS: Replace Battery",
            body: "UPS reports battery replacement needed.".to_string(),
            urgency: Urgency::Normal,
            icon: "dialog-warning",
        });
    }

    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ups_state::{UpsState, UpsStatus};

    fn connected(flags: Vec<StatusFlag>) -> UpsState {
        UpsState {
            name: "myups".to_string(),
            status: UpsStatus { flags },
            connection_ok: true,
            ..Default::default()
        }
    }

    fn disconnected() -> UpsState {
        UpsState::default()
    }

    fn summaries(ns: &[Notification]) -> Vec<&'static str> {
        ns.iter().map(|n| n.summary).collect()
    }

    #[test]
    fn connected_to_lost_fires_connection_lost_once() {
        let prev = connected(vec![StatusFlag::Online]);
        let lost = disconnected();
        let first = transition_notifications(Some(&prev), &lost);
        assert_eq!(summaries(&first), vec!["UPS: Connection Lost"]);

        // A second consecutive failure must not re-fire.
        let again = transition_notifications(Some(&lost), &lost);
        assert!(again.is_empty());
    }

    #[test]
    fn lost_to_connected_fires_connection_restored() {
        let prev = disconnected();
        let new = connected(vec![StatusFlag::Online]);
        let ns = transition_notifications(Some(&prev), &new);
        assert_eq!(summaries(&ns), vec!["UPS: Connection Restored"]);
    }

    #[test]
    fn first_healthy_poll_fires_nothing() {
        let new = connected(vec![StatusFlag::Online]);
        let ns = transition_notifications(None, &new);
        assert!(ns.is_empty());
    }

    #[test]
    fn first_on_battery_poll_fires_on_battery_not_restored() {
        let new = connected(vec![StatusFlag::OnBattery, StatusFlag::Discharging]);
        let ns = transition_notifications(None, &new);
        assert_eq!(summaries(&ns), vec!["UPS: On Battery"]);
    }

    #[test]
    fn reconnect_already_on_battery_fires_restored_and_on_battery() {
        let prev = disconnected();
        let new = connected(vec![StatusFlag::OnBattery, StatusFlag::Discharging]);
        let ns = transition_notifications(Some(&prev), &new);
        assert_eq!(
            summaries(&ns),
            vec!["UPS: Connection Restored", "UPS: On Battery"]
        );
    }

    #[test]
    fn on_battery_to_online_fires_power_restored() {
        let prev = connected(vec![StatusFlag::OnBattery]);
        let new = connected(vec![StatusFlag::Online]);
        let ns = transition_notifications(Some(&prev), &new);
        assert_eq!(summaries(&ns), vec!["UPS: Power Restored"]);
    }
}
