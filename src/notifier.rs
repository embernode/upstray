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

pub enum Urgency {
    Low = 0,
    Normal = 1,
    Critical = 2,
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

pub async fn check_and_notify_state_changes(old_state: &UpsState, new_state: &UpsState) {
    if new_state.name.is_empty() {
        return;
    }

    // Connection lost
    if old_state.connection_ok && !new_state.connection_ok {
        let _ = send_notification(
            "UPS: Connection Lost",
            &format!("Cannot reach UPS '{}'. Check NUT service.", old_state.name),
            Urgency::Normal,
            "dialog-warning",
        )
        .await;
        return;
    }

    // Connection restored
    if !old_state.connection_ok && new_state.connection_ok {
        let _ = send_notification(
            "UPS: Connection Restored",
            &format!("Communication with '{}' re-established.", new_state.name),
            Urgency::Low,
            "dialog-information",
        )
        .await;
        return;
    }

    let newly_on_battery = !old_state.status.flags.contains(&StatusFlag::OnBattery)
        && new_state.status.flags.contains(&StatusFlag::OnBattery);
    let newly_low_battery = !old_state.status.flags.contains(&StatusFlag::LowBattery)
        && new_state.status.flags.contains(&StatusFlag::LowBattery);
    let newly_power_restored = old_state.status.flags.contains(&StatusFlag::OnBattery)
        && !new_state.status.flags.contains(&StatusFlag::OnBattery)
        && new_state.connection_ok;
    let newly_replace_battery = !old_state.status.flags.contains(&StatusFlag::ReplaceBattery)
        && new_state.status.flags.contains(&StatusFlag::ReplaceBattery);
    let newly_fsd = !old_state.status.flags.contains(&StatusFlag::ForcedShutdown)
        && new_state.status.flags.contains(&StatusFlag::ForcedShutdown);

    if newly_on_battery {
        let charge = new_state.battery_charge.unwrap_or(0.0);
        let runtime = new_state.battery_runtime_secs.unwrap_or(0) / 60;
        let body = format!(
            "Power outage detected. Running on battery ({}%, ~{} min)",
            charge, runtime
        );
        let _ =
            send_notification("UPS: On Battery", &body, Urgency::Normal, "battery-caution").await;
    }

    if newly_low_battery {
        let charge = new_state.battery_charge.unwrap_or(0.0);
        let runtime = new_state.battery_runtime_secs.unwrap_or(0) / 60;
        let body = format!(
            "Battery at {}% (~{} min remaining). Save your work!",
            charge, runtime
        );
        let _ = send_notification(
            "⚠️ UPS: Low Battery",
            &body,
            Urgency::Critical,
            "battery-low",
        )
        .await;
    }

    if newly_fsd {
        let _ = send_notification(
            "🔴 UPS: Shutdown Imminent",
            "Forced shutdown in progress. Save immediately!",
            Urgency::Critical,
            "dialog-error",
        )
        .await;
    }

    if newly_power_restored {
        let charge = new_state.battery_charge.unwrap_or(0.0);
        let body = format!("Mains power restored. Battery at {}%", charge);
        let _ = send_notification(
            "UPS: Power Restored",
            &body,
            Urgency::Low,
            "battery-charging",
        )
        .await;
    }

    if newly_replace_battery {
        let _ = send_notification(
            "UPS: Replace Battery",
            "UPS reports battery replacement needed.",
            Urgency::Normal,
            "dialog-warning",
        )
        .await;
    }
}
