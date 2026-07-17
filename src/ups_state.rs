use std::time::Instant;

#[derive(Debug, Clone)]
pub struct UpsState {
    pub name: String,
    pub description: String,

    // Status
    pub status: UpsStatus,

    // Battery
    pub battery_charge: Option<f64>,
    pub battery_charge_low: Option<f64>,
    pub battery_runtime_secs: Option<u64>,
    pub battery_voltage: Option<f64>,

    // Power
    pub input_voltage: Option<f64>,
    pub output_voltage: Option<f64>,
    pub ups_load: Option<f64>,

    // Device Info
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub serial: Option<String>,
    pub temperature: Option<f64>,
    pub firmware_version: Option<String>,
    pub connection_type: Option<String>,
    pub frequency: Option<f64>,
    pub efficiency: Option<f64>,

    // Meta
    pub last_updated: Instant,
    pub connection_ok: bool,

    // Names of every UPS the last successful list_ups reported (empty when unknown).
    pub available_ups: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UpsStatus {
    pub flags: Vec<StatusFlag>,
}

impl std::fmt::Display for UpsStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.flags.is_empty() {
            return write!(f, "Unknown");
        }
        let mut parts = Vec::new();
        for flag in &self.flags {
            parts.push(match flag {
                StatusFlag::Online => "Online",
                StatusFlag::OnBattery => "On Battery",
                StatusFlag::LowBattery => "Low Battery",
                StatusFlag::ReplaceBattery => "Replace Battery",
                StatusFlag::Charging => "Charging",
                StatusFlag::Discharging => "Discharging",
                StatusFlag::Boost => "Boost",
                StatusFlag::Trim => "Trim",
                StatusFlag::ForcedShutdown => "Forced Shutdown",
                StatusFlag::NoCommunication => "No Comm",
                StatusFlag::Overloaded => "Overloaded",
                StatusFlag::Bypass => "Bypass",
            });
        }
        write!(f, "{}", parts.join(", "))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StatusFlag {
    Online,          // OL
    OnBattery,       // OB
    LowBattery,      // LB
    ReplaceBattery,  // RB
    Charging,        // CHRG
    Discharging,     // DISCHRG
    Boost,           // BOOST
    Trim,            // TRIM
    ForcedShutdown,  // FSD
    NoCommunication, // NOCOMM
    Overloaded,      // OVER
    Bypass,          // BYPASS
}

impl PartialEq for UpsState {
    fn eq(&self, other: &Self) -> bool {
        // Intentionally excludes last_updated — two states with identical UPS data
        // should compare equal regardless of when they were sampled.
        self.name == other.name
            && self.description == other.description
            && self.status == other.status
            && self.battery_charge == other.battery_charge
            && self.battery_charge_low == other.battery_charge_low
            && self.battery_runtime_secs == other.battery_runtime_secs
            && self.battery_voltage == other.battery_voltage
            && self.input_voltage == other.input_voltage
            && self.output_voltage == other.output_voltage
            && self.ups_load == other.ups_load
            && self.manufacturer == other.manufacturer
            && self.model == other.model
            && self.serial == other.serial
            && self.temperature == other.temperature
            && self.firmware_version == other.firmware_version
            && self.connection_type == other.connection_type
            && self.frequency == other.frequency
            && self.efficiency == other.efficiency
            && self.connection_ok == other.connection_ok
            && self.available_ups == other.available_ups
    }
}

impl Default for UpsState {
    fn default() -> Self {
        Self {
            name: String::new(),
            description: String::new(),
            status: UpsStatus { flags: vec![] },
            battery_charge: None,
            battery_charge_low: None,
            battery_runtime_secs: None,
            battery_voltage: None,
            input_voltage: None,
            output_voltage: None,
            ups_load: None,
            manufacturer: None,
            model: None,
            serial: None,
            temperature: None,
            firmware_version: None,
            connection_type: None,
            frequency: None,
            efficiency: None,
            last_updated: Instant::now(),
            connection_ok: false,
            available_ups: Vec::new(),
        }
    }
}
