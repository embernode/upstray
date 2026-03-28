use crate::ups_state::UpsState;
use std::sync::{Mutex, OnceLock};
use tokio::sync::watch;

pub static STATE_RX: OnceLock<Mutex<watch::Receiver<UpsState>>> = OnceLock::new();
pub static CONFIG_TX: OnceLock<watch::Sender<(String, u16)>> = OnceLock::new();
const UNAVAILABLE: &str = "—";

#[cxx_qt::bridge]
mod ffi {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    unsafe extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, status_text)]
        #[qproperty(QString, battery_charge)]
        #[qproperty(QString, icon_name)]
        #[qproperty(QString, runtime_text)]
        #[qproperty(QString, input_voltage)]
        #[qproperty(QString, output_voltage)]
        #[qproperty(QString, load_percentage)]
        #[qproperty(QString, temperature)]
        #[qproperty(QString, manufacturer_model)]
        #[qproperty(QString, firmware_version)]
        #[qproperty(QString, connection_type)]
        #[qproperty(QString, frequency)]
        #[qproperty(QString, efficiency)]
        #[qproperty(QString, health)]
        #[qproperty(QString, serial_number)]
        // Settings state
        #[qproperty(QString, nut_host)]
        #[qproperty(QString, nut_port)]
        #[qproperty(bool, autostart_enabled)]
        #[qproperty(bool, notifications_enabled)]
        type Backend = super::BackendRust;

        #[qsignal]
        fn quit_requested(self: Pin<&mut Backend>);

        #[qinvokable]
        fn init(self: Pin<&mut Backend>);

        #[qinvokable]
        fn quit(self: Pin<&mut Backend>);

        #[qinvokable]
        fn refresh(self: Pin<&mut Backend>);

        #[qinvokable]
        fn save_network_settings(self: Pin<&mut Backend>, host: QString, port: QString);

        #[qinvokable]
        fn set_autostart(self: Pin<&mut Backend>, enabled: bool);

        #[qinvokable]
        fn set_notifications(self: Pin<&mut Backend>, enabled: bool);
    }
}

pub struct BackendRust {
    status_text: cxx_qt_lib::QString,
    battery_charge: cxx_qt_lib::QString,
    icon_name: cxx_qt_lib::QString,
    runtime_text: cxx_qt_lib::QString,
    input_voltage: cxx_qt_lib::QString,
    output_voltage: cxx_qt_lib::QString,
    load_percentage: cxx_qt_lib::QString,
    temperature: cxx_qt_lib::QString,
    manufacturer_model: cxx_qt_lib::QString,
    firmware_version: cxx_qt_lib::QString,
    connection_type: cxx_qt_lib::QString,
    frequency: cxx_qt_lib::QString,
    efficiency: cxx_qt_lib::QString,
    health: cxx_qt_lib::QString,
    serial_number: cxx_qt_lib::QString,
    // Settings
    nut_host: cxx_qt_lib::QString,
    nut_port: cxx_qt_lib::QString,
    autostart_enabled: bool,
    notifications_enabled: bool,
}

impl Default for BackendRust {
    fn default() -> Self {
        Self {
            status_text: cxx_qt_lib::QString::from("Initializing..."),
            battery_charge: cxx_qt_lib::QString::from("?"),
            icon_name: cxx_qt_lib::QString::from("battery-missing"),
            runtime_text: cxx_qt_lib::QString::from(UNAVAILABLE),
            input_voltage: cxx_qt_lib::QString::from(UNAVAILABLE),
            output_voltage: cxx_qt_lib::QString::from(UNAVAILABLE),
            load_percentage: cxx_qt_lib::QString::from(UNAVAILABLE),
            temperature: cxx_qt_lib::QString::from(UNAVAILABLE),
            manufacturer_model: cxx_qt_lib::QString::from(UNAVAILABLE),
            firmware_version: cxx_qt_lib::QString::from(UNAVAILABLE),
            connection_type: cxx_qt_lib::QString::from(UNAVAILABLE),
            frequency: cxx_qt_lib::QString::from(UNAVAILABLE),
            efficiency: cxx_qt_lib::QString::from(UNAVAILABLE),
            health: cxx_qt_lib::QString::from("Good"),
            serial_number: cxx_qt_lib::QString::from(UNAVAILABLE),
            nut_host: cxx_qt_lib::QString::from("localhost"),
            nut_port: cxx_qt_lib::QString::from("3493"),
            autostart_enabled: false,
            notifications_enabled: true,
        }
    }
}

impl ffi::Backend {
    pub fn init(mut self: std::pin::Pin<&mut Self>) {
        let config = crate::config::load_config();
        let autostart = crate::config::autostart_path().exists();
        self.as_mut()
            .set_nut_host(cxx_qt_lib::QString::from(&config.server.host));
        self.as_mut()
            .set_nut_port(cxx_qt_lib::QString::from(&config.server.port.to_string()));
        self.as_mut().set_autostart_enabled(autostart);
        self.as_mut()
            .set_notifications_enabled(config.notifications.enabled);

        use std::sync::atomic::Ordering;
        crate::notifier::NOTIFICATIONS_ENABLED
            .store(config.notifications.enabled, Ordering::Relaxed);
    }

    pub fn quit(self: std::pin::Pin<&mut Self>) {
        tracing::info!("Quit requested from QML");
        self.quit_requested();
    }

    pub fn refresh(mut self: std::pin::Pin<&mut Self>) {
        let rx_mutex = match STATE_RX.get() {
            Some(m) => m,
            None => return,
        };
        let mut rx = match rx_mutex.lock() {
            Ok(rx) => rx,
            Err(e) => {
                tracing::error!("STATE_RX lock poisoned: {}", e);
                return;
            }
        };

        // Skip refresh if the poller hasn't pushed new data
        if !rx.has_changed().unwrap_or(false) {
            return;
        }

        let state = rx.borrow_and_update().clone();
        drop(rx); // Release lock before doing work

        let status_str = if !state.connection_ok {
            "Disconnected".to_string()
        } else if state.name.is_empty() {
            "Connecting...".to_string()
        } else {
            state.status.to_string()
        };

        self.as_mut()
            .set_status_text(cxx_qt_lib::QString::from(&status_str));

        let charge = state.battery_charge.map(|c| c as i32);
        let charge_str = match charge {
            Some(c) if state.connection_ok => c.to_string(),
            _ => "?".to_string(),
        };
        self.as_mut()
            .set_battery_charge(cxx_qt_lib::QString::from(&charge_str));

        let icon = if !state.connection_ok || state.name.is_empty() {
            "battery-missing"
        } else if state
            .status
            .flags
            .contains(&crate::ups_state::StatusFlag::LowBattery)
        {
            "battery-low"
        } else if state
            .status
            .flags
            .contains(&crate::ups_state::StatusFlag::OnBattery)
        {
            "battery-caution"
        } else if state
            .status
            .flags
            .contains(&crate::ups_state::StatusFlag::Charging)
        {
            "battery-charging"
        } else if charge.map_or(false, |c| c > 80) {
            "battery-full"
        } else {
            "battery-good"
        };
        self.as_mut().set_icon_name(cxx_qt_lib::QString::from(icon));

        let runtime_str = if let Some(secs) = state.battery_runtime_secs {
            format!("{} min", secs / 60)
        } else {
            UNAVAILABLE.to_string()
        };
        self.as_mut()
            .set_runtime_text(cxx_qt_lib::QString::from(&runtime_str));

        self.as_mut().set_input_voltage(cxx_qt_lib::QString::from(
            &state
                .input_voltage
                .map(|v| format!("{:.1} V", v))
                .unwrap_or_else(|| UNAVAILABLE.to_string()),
        ));

        self.as_mut().set_output_voltage(cxx_qt_lib::QString::from(
            &state
                .output_voltage
                .map(|v| format!("{:.1} V", v))
                .unwrap_or_else(|| UNAVAILABLE.to_string()),
        ));

        self.as_mut().set_load_percentage(cxx_qt_lib::QString::from(
            &state
                .ups_load
                .map(|l| format!("{:.0}%", l))
                .unwrap_or_else(|| UNAVAILABLE.to_string()),
        ));

        self.as_mut().set_temperature(cxx_qt_lib::QString::from(
            &state
                .temperature
                .map(|t| format!("{:.1}°C", t))
                .unwrap_or_else(|| UNAVAILABLE.to_string()),
        ));

        let mfr = state.manufacturer.unwrap_or_default();
        let model = state.model.unwrap_or_default();
        let mut combined = format!("{} {}", mfr, model).trim().to_string();
        if combined.is_empty() {
            combined = state.name.clone();
        }
        self.as_mut()
            .set_manufacturer_model(cxx_qt_lib::QString::from(&combined));

        self.as_mut()
            .set_firmware_version(cxx_qt_lib::QString::from(
                &state
                    .firmware_version
                    .unwrap_or_else(|| UNAVAILABLE.to_string()),
            ));
        self.as_mut().set_serial_number(cxx_qt_lib::QString::from(
            &state.serial.unwrap_or_else(|| UNAVAILABLE.to_string()),
        ));
        self.as_mut().set_connection_type(cxx_qt_lib::QString::from(
            &state.connection_type.unwrap_or_else(|| "Local".to_string()),
        ));
        self.as_mut().set_frequency(cxx_qt_lib::QString::from(
            &state
                .frequency
                .map(|v| format!("{:.1} Hz", v))
                .unwrap_or_else(|| UNAVAILABLE.to_string()),
        ));
        self.as_mut().set_efficiency(cxx_qt_lib::QString::from(
            &state
                .efficiency
                .map(|v| format!("{:.0}%", v))
                .unwrap_or_else(|| UNAVAILABLE.to_string()),
        ));

        let health = if !state.connection_ok {
            "critical"
        } else if state
            .status
            .flags
            .contains(&crate::ups_state::StatusFlag::OnBattery)
            || state
                .status
                .flags
                .contains(&crate::ups_state::StatusFlag::LowBattery)
            || state
                .status
                .flags
                .contains(&crate::ups_state::StatusFlag::Overloaded)
        {
            "warning"
        } else if state
            .status
            .flags
            .contains(&crate::ups_state::StatusFlag::ReplaceBattery)
            || state
                .status
                .flags
                .contains(&crate::ups_state::StatusFlag::ForcedShutdown)
        {
            "critical"
        } else {
            "good"
        };
        self.as_mut().set_health(cxx_qt_lib::QString::from(health));
    }

    pub fn save_network_settings(
        mut self: std::pin::Pin<&mut Self>,
        host: cxx_qt_lib::QString,
        port: cxx_qt_lib::QString,
    ) {
        let host_str = host.to_string();
        let port_str = port.to_string();

        if host_str.trim().is_empty() {
            tracing::warn!("Ignoring empty host");
            return;
        }
        let port_num: u16 = match port_str.parse() {
            Ok(p) if p > 0 => p,
            _ => {
                tracing::warn!("Invalid port '{}', ignoring", port_str);
                return;
            }
        };

        match crate::config::save_config(&host_str, port_num) {
            Ok(_) => tracing::info!("Network settings saved: {}:{}", host_str, port_num),
            Err(e) => {
                tracing::error!("Failed to save network settings: {}", e);
                return;
            }
        }

        // Notify the poller to reconnect with new settings
        if let Some(tx) = CONFIG_TX.get() {
            let _ = tx.send((host_str.clone(), port_num));
        }

        self.as_mut()
            .set_nut_host(cxx_qt_lib::QString::from(&host_str));
        self.as_mut()
            .set_nut_port(cxx_qt_lib::QString::from(&port_num.to_string()));
    }

    pub fn set_autostart(mut self: std::pin::Pin<&mut Self>, enabled: bool) {
        match crate::config::set_autostart(enabled) {
            Ok(_) => tracing::info!("Autostart set to: {}", enabled),
            Err(e) => tracing::error!("Failed to set autostart: {}", e),
        }
        self.as_mut().set_autostart_enabled(enabled);
    }

    pub fn set_notifications(mut self: std::pin::Pin<&mut Self>, enabled: bool) {
        use std::sync::atomic::Ordering;
        crate::notifier::NOTIFICATIONS_ENABLED.store(enabled, Ordering::Relaxed);
        let _ = crate::config::set_notifications_config(enabled);
        self.as_mut().set_notifications_enabled(enabled);
        tracing::info!("Notifications set to: {}", enabled);
    }
}
