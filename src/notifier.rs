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

    fn close_notification(&self, id: u32) -> zbus::Result<()>;
}

/// Announcements of something that has already resolved. These expire on their
/// own; there is no condition left for them to track.
const TIMEOUT_ROUTINE_MS: i32 = 5_000;

/// Alarms for a condition that is still true. Zero means the server keeps them
/// up, which is what the spec asks for at critical urgency and what KDE does.
/// They are not left for the user to sweep up: `transition_dismissals` closes
/// each one by id as soon as its condition clears.
const TIMEOUT_PERSISTENT: i32 = 0;

/// Identifies a standing alarm so it can be closed again once resolved.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum NotificationKind {
    ConnectionLost,
    OnBattery,
    LowBattery,
    ForcedShutdown,
    /// Announcements that expire by themselves and are never closed by us.
    Transient,
}

/// Server-assigned ids of the alarms currently on screen, so they can be closed.
static ACTIVE: std::sync::OnceLock<
    std::sync::Mutex<std::collections::HashMap<NotificationKind, u32>>,
> = std::sync::OnceLock::new();

fn active() -> &'static std::sync::Mutex<std::collections::HashMap<NotificationKind, u32>> {
    ACTIVE.get_or_init(|| std::sync::Mutex::new(std::collections::HashMap::new()))
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
    /// Milliseconds on screen; zero means the server keeps it up until closed.
    pub timeout_ms: i32,
    pub kind: NotificationKind,
}

pub async fn send_notification(
    summary: &str,
    body: &str,
    urgency: Urgency,
    icon: &str,
    timeout_ms: i32,
    kind: NotificationKind,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    if !NOTIFICATIONS_ENABLED.load(Ordering::Relaxed) {
        return Ok(());
    }
    let connection = get_dbus_connection().await?;
    let proxy = NotificationsProxy::new(connection).await?;

    let mut hints = std::collections::HashMap::new();
    hints.insert("urgency", zbus::zvariant::Value::U8(urgency as u8));

    // Re-alarming an already-standing condition replaces its notification rather
    // than stacking a second copy of the same warning.
    let replaces = match kind {
        NotificationKind::Transient => 0,
        k => active().lock().map(|m| m.get(&k).copied().unwrap_or(0)).unwrap_or(0),
    };

    let id = proxy
        .notify("upstray", replaces, icon, summary, body, &[], &hints, timeout_ms)
        .await?;

    if kind != NotificationKind::Transient {
        if let Ok(mut m) = active().lock() {
            m.insert(kind, id);
        }
    }

    Ok(())
}

/// Closes standing alarms whose condition has resolved. Unknown kinds are a
/// no-op, so dismissing something that was never shown is harmless.
pub async fn close_notifications(kinds: Vec<NotificationKind>) {
    // Resolve ids first. Dismissals are evaluated on every poll now, so with
    // nothing standing this must cost a map lookup and no D-Bus round trip.
    let ids: Vec<u32> = match active().lock() {
        Ok(mut m) => kinds.iter().filter_map(|k| m.remove(k)).collect(),
        Err(_) => return,
    };
    if ids.is_empty() {
        return;
    }

    let Ok(connection) = get_dbus_connection().await else {
        return;
    };
    let Ok(proxy) = NotificationsProxy::new(connection).await else {
        return;
    };
    for id in ids {
        let _ = proxy.close_notification(id).await;
    }
}

pub async fn send_notifications(notifications: Vec<Notification>) {
    for n in notifications {
        let _ = send_notification(n.summary, &n.body, n.urgency, n.icon, n.timeout_ms, n.kind).await;
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
                urgency: Urgency::Critical,
                icon: "dialog-warning",
                timeout_ms: TIMEOUT_PERSISTENT,
                kind: NotificationKind::ConnectionLost,
            });
            return out;
        }

        if !prev.connection_ok && new.connection_ok {
            out.push(Notification {
                summary: "UPS: Connection Restored",
                body: format!("Communication with '{}' re-established.", new.name),
                urgency: Urgency::Normal,
                icon: "dialog-information",
                timeout_ms: TIMEOUT_ROUTINE_MS,
                kind: NotificationKind::Transient,
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
            urgency: Urgency::Critical,
            icon: "battery-caution",
            timeout_ms: TIMEOUT_PERSISTENT,
            kind: NotificationKind::OnBattery,
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
            timeout_ms: TIMEOUT_PERSISTENT,
            kind: NotificationKind::LowBattery,
        });
    }

    if newly_fsd {
        out.push(Notification {
            summary: "🔴 UPS: Shutdown Imminent",
            body: "Forced shutdown in progress. Save immediately!".to_string(),
            urgency: Urgency::Critical,
            icon: "dialog-error",
            timeout_ms: TIMEOUT_PERSISTENT,
            kind: NotificationKind::ForcedShutdown,
        });
    }

    if newly_power_restored {
        let charge = new.battery_charge.unwrap_or(0.0);
        out.push(Notification {
            summary: "UPS: Power Restored",
            body: format!("Mains power restored. Battery at {}%", charge),
            urgency: Urgency::Normal,
            icon: "battery-charging",
            timeout_ms: TIMEOUT_ROUTINE_MS,
            kind: NotificationKind::Transient,
        });
    }

    if newly_replace_battery {
        out.push(Notification {
            summary: "UPS: Replace Battery",
            body: "UPS reports battery replacement needed.".to_string(),
            urgency: Urgency::Normal,
            icon: "dialog-warning",
            timeout_ms: TIMEOUT_ROUTINE_MS,
            kind: NotificationKind::Transient,
        });
    }

    out
}

/// Standing alarms that no longer describe the present, and should therefore be
/// taken off screen. The counterpart to `transition_notifications`: alarms are
/// raised at critical urgency and stay up, so something has to retire them.
///
/// Deliberately decided from `new` alone rather than from a prev/new edge. An
/// edge is only observed if we are watching at the instant it happens, and we
/// are not: the connection can drop across the end of an outage, and the poller
/// resets its previous state to `None` whenever the config changes. Both left
/// alarms standing forever. Judging the current state instead is idempotent —
/// closing something that is not on screen is a no-op — so a missed edge simply
/// gets cleaned up on the next poll.
pub fn transition_dismissals(prev: Option<&UpsState>, new: &UpsState) -> Vec<NotificationKind> {
    let mut out = Vec::new();

    // Flags read empty on a dropout. Treating that as "the alarm cleared" would
    // retire a live warning at the worst possible moment.
    if !new.connection_ok {
        return out;
    }

    // We are talking to the UPS, so any connection alarm is stale by definition,
    // whatever we thought the previous state was.
    out.push(NotificationKind::ConnectionLost);

    let has = |f: StatusFlag| new.status.flags.contains(&f);
    let newly =
        |f: StatusFlag| has(f) && !prev.is_some_and(|p| p.status.flags.contains(&f));

    if !has(StatusFlag::OnBattery) {
        out.push(NotificationKind::OnBattery);
        // Mains is back, so a low-battery warning raised during the outage no
        // longer applies — charge lags the transfer, so its flag often has not
        // dropped yet. Unless it has only just appeared, in which case it does
        // describe the present and must not be retired in the same tick that
        // raises it.
        if !newly(StatusFlag::LowBattery) {
            out.push(NotificationKind::LowBattery);
        }
    } else if !has(StatusFlag::LowBattery) {
        out.push(NotificationKind::LowBattery);
    }

    if !has(StatusFlag::ForcedShutdown) {
        out.push(NotificationKind::ForcedShutdown);
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

    fn urgencies(ns: &[Notification]) -> Vec<Urgency> {
        ns.iter().map(|n| n.urgency).collect()
    }

    #[test]
    fn connected_to_lost_fires_connection_lost_once() {
        let prev = connected(vec![StatusFlag::Online]);
        let lost = disconnected();
        let first = transition_notifications(Some(&prev), &lost);
        assert_eq!(summaries(&first), vec!["UPS: Connection Lost"]);
        assert_eq!(urgencies(&first), vec![Urgency::Critical]);

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
        assert_eq!(urgencies(&ns), vec![Urgency::Normal]);
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
        assert_eq!(urgencies(&ns), vec![Urgency::Critical]);
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
        assert_eq!(urgencies(&ns), vec![Urgency::Normal, Urgency::Critical]);
    }

    fn kinds(ns: &[Notification]) -> Vec<NotificationKind> {
        ns.iter().map(|n| n.kind).collect()
    }

    #[test]
    fn standing_alarms_never_expire_and_announcements_always_do() {
        // A critical alarm the server keeps up must be one we can close again,
        // and anything we cannot close must expire by itself, or it is litter.
        let cases = vec![
            transition_notifications(Some(&connected(vec![StatusFlag::Online])), &disconnected()),
            transition_notifications(None, &connected(vec![StatusFlag::OnBattery])),
            transition_notifications(None, &connected(vec![StatusFlag::LowBattery])),
            transition_notifications(None, &connected(vec![StatusFlag::ForcedShutdown])),
            transition_notifications(
                Some(&connected(vec![StatusFlag::OnBattery])),
                &connected(vec![StatusFlag::Online]),
            ),
            transition_notifications(None, &connected(vec![StatusFlag::ReplaceBattery])),
        ];
        for ns in cases {
            for n in ns {
                if n.kind == NotificationKind::Transient {
                    assert!(n.timeout_ms > 0, "{} cannot be closed, so it must expire", n.summary);
                } else {
                    assert_eq!(n.timeout_ms, TIMEOUT_PERSISTENT, "{} should stand", n.summary);
                }
            }
        }
    }

    #[test]
    fn reconnecting_dismisses_the_connection_lost_alarm() {
        let ns = transition_dismissals(Some(&disconnected()), &connected(vec![StatusFlag::Online]));
        assert!(ns.contains(&NotificationKind::ConnectionLost));
    }

    #[test]
    fn power_returning_dismisses_both_battery_alarms() {
        // Charge lags the transfer, so LowBattery may still be flagged when
        // mains returns; the warning is stale either way.
        let prev = connected(vec![StatusFlag::OnBattery, StatusFlag::LowBattery]);
        let new = connected(vec![StatusFlag::Online, StatusFlag::LowBattery]);
        let ns = transition_dismissals(Some(&prev), &new);
        assert!(ns.contains(&NotificationKind::OnBattery));
        assert!(ns.contains(&NotificationKind::LowBattery));
    }

    #[test]
    fn recovering_charge_while_still_on_battery_keeps_the_outage_alarm() {
        let prev = connected(vec![StatusFlag::OnBattery, StatusFlag::LowBattery]);
        let new = connected(vec![StatusFlag::OnBattery]);
        let ns = transition_dismissals(Some(&prev), &new);
        assert!(ns.contains(&NotificationKind::LowBattery));
        // Still on battery, so that alarm must stay up.
        assert!(!ns.contains(&NotificationKind::OnBattery));
    }

    #[test]
    fn outage_ending_during_a_dropout_still_retires_the_alarm() {
        // The edge that raised On Battery is never followed by an edge that
        // clears it: the connection drops mid-outage and mains is already back
        // by the time we see the UPS again. Judging `new` alone catches it.
        let ns = transition_dismissals(Some(&disconnected()), &connected(vec![StatusFlag::Online]));
        assert!(ns.contains(&NotificationKind::OnBattery));
        assert!(ns.contains(&NotificationKind::ConnectionLost));
    }

    #[test]
    fn a_reset_previous_state_still_retires_alarms() {
        // The poller drops its previous state to None whenever the config
        // changes — which is exactly what happens after the user fixes the host
        // in Settings, with a Connection Lost alarm standing.
        let ns = transition_dismissals(None, &connected(vec![StatusFlag::Online]));
        assert!(ns.contains(&NotificationKind::ConnectionLost));
    }

    #[test]
    fn low_battery_appearing_as_mains_returns_is_not_retired_at_once() {
        // Mains back but charge still under the low threshold is an ordinary
        // NUT state. The alarm is raised this tick, so it must not also be
        // dismissed this tick.
        let prev = connected(vec![StatusFlag::OnBattery]);
        let new = connected(vec![StatusFlag::Online, StatusFlag::LowBattery]);
        let raised = transition_notifications(Some(&prev), &new);
        let dropped = transition_dismissals(Some(&prev), &new);
        assert!(kinds(&raised).contains(&NotificationKind::LowBattery));
        assert!(
            !dropped.contains(&NotificationKind::LowBattery),
            "raised and retired in the same tick"
        );
    }

    #[test]
    fn stale_low_battery_is_retired_when_mains_returns() {
        // Same shape, but the flag was already set during the outage, so it is
        // left over rather than new.
        let prev = connected(vec![StatusFlag::OnBattery, StatusFlag::LowBattery]);
        let new = connected(vec![StatusFlag::Online, StatusFlag::LowBattery]);
        let ns = transition_dismissals(Some(&prev), &new);
        assert!(ns.contains(&NotificationKind::LowBattery));
    }

    #[test]
    fn cancelled_shutdown_is_retired() {
        let prev = connected(vec![StatusFlag::OnBattery, StatusFlag::ForcedShutdown]);
        let new = connected(vec![StatusFlag::OnBattery]);
        let ns = transition_dismissals(Some(&prev), &new);
        assert!(ns.contains(&NotificationKind::ForcedShutdown));
    }

    #[test]
    fn a_live_outage_is_never_retired() {
        // The one thing that must never happen: closing an alarm whose
        // condition still holds.
        let prev = connected(vec![StatusFlag::OnBattery, StatusFlag::LowBattery]);
        let new = connected(vec![StatusFlag::OnBattery, StatusFlag::LowBattery]);
        let ns = transition_dismissals(Some(&prev), &new);
        assert!(!ns.contains(&NotificationKind::OnBattery));
        assert!(!ns.contains(&NotificationKind::LowBattery));
    }

    #[test]
    fn flapping_retires_and_re_raises_without_losing_track() {
        let online = connected(vec![StatusFlag::Online]);
        let battery = connected(vec![StatusFlag::OnBattery]);
        // out -> back -> out again
        assert!(kinds(&transition_notifications(Some(&online), &battery))
            .contains(&NotificationKind::OnBattery));
        assert!(transition_dismissals(Some(&battery), &online)
            .contains(&NotificationKind::OnBattery));
        assert!(kinds(&transition_notifications(Some(&online), &battery))
            .contains(&NotificationKind::OnBattery));
        assert!(!transition_dismissals(Some(&online), &battery)
            .contains(&NotificationKind::OnBattery));
    }

    #[test]
    fn losing_the_connection_dismisses_nothing() {
        // Flags go empty on a dropout. Reading that as "the outage ended" would
        // clear a live alarm at the worst possible moment.
        let prev = connected(vec![StatusFlag::OnBattery, StatusFlag::LowBattery]);
        let ns = transition_dismissals(Some(&prev), &disconnected());
        assert!(ns.is_empty());
    }

    #[test]
    fn on_battery_alarm_is_closeable() {
        let ns = transition_notifications(None, &connected(vec![StatusFlag::OnBattery]));
        assert_eq!(kinds(&ns), vec![NotificationKind::OnBattery]);
    }

    #[test]
    fn on_battery_to_online_fires_power_restored() {
        let prev = connected(vec![StatusFlag::OnBattery]);
        let new = connected(vec![StatusFlag::Online]);
        let ns = transition_notifications(Some(&prev), &new);
        assert_eq!(summaries(&ns), vec!["UPS: Power Restored"]);
        assert_eq!(urgencies(&ns), vec![Urgency::Normal]);
    }
}
