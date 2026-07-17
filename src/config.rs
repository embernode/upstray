use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct AppConfig {
    #[serde(default)]
    pub general: GeneralConfig,
    #[serde(default)]
    pub server: ServerConfig,
    #[serde(default)]
    pub notifications: NotificationsConfig,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct NotificationsConfig {
    #[serde(default = "default_true")]
    pub enabled: bool,
}

impl Default for NotificationsConfig {
    fn default() -> Self {
        Self {
            enabled: default_true(),
        }
    }
}

fn default_true() -> bool {
    true
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct GeneralConfig {
    #[serde(default = "default_poll_interval")]
    pub poll_interval_secs: u64,
}

impl Default for GeneralConfig {
    fn default() -> Self {
        Self {
            poll_interval_secs: default_poll_interval(),
        }
    }
}

fn default_poll_interval() -> u64 {
    5
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ServerConfig {
    #[serde(default = "default_host")]
    pub host: String,
    #[serde(default = "default_port")]
    pub port: u16,
    #[serde(default)]
    pub ups_name: String,
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: default_host(),
            port: default_port(),
            ups_name: String::new(),
        }
    }
}

fn default_host() -> String {
    "localhost".to_string()
}

fn default_port() -> u16 {
    3493
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            general: GeneralConfig::default(),
            server: ServerConfig::default(),
            notifications: NotificationsConfig::default(),
        }
    }
}

pub fn load_config() -> AppConfig {
    let config_dir = dirs::config_dir().unwrap_or_else(|| PathBuf::from("."));
    let config_path = config_dir.join("upstray").join("config.toml");

    if config_path.exists() {
        match fs::read_to_string(&config_path) {
            Ok(content) => match toml::from_str(&content) {
                Ok(config) => config,
                Err(e) => {
                    tracing::error!("Failed to parse config file at {:?}: {}", config_path, e);
                    backup_corrupt_config(&config_path);
                    AppConfig::default()
                }
            },
            Err(e) => {
                tracing::error!("Failed to read config file at {:?}: {}", config_path, e);
                backup_corrupt_config(&config_path);
                AppConfig::default()
            }
        }
    } else {
        tracing::info!("No config file found at {:?}, using defaults", config_path);
        // Create default config file directory context
        if let Some(parent) = config_path.parent() {
            let _ = fs::create_dir_all(parent);
        }
        AppConfig::default()
    }
}

/// Move an unreadable/unparseable config aside so the next save doesn't clobber it
/// with defaults, preserving whatever the user had for recovery.
fn backup_corrupt_config(config_path: &Path) {
    let backup_path = config_path.with_extension("toml.bak");
    match fs::rename(config_path, &backup_path) {
        Ok(_) => tracing::error!("Preserved unreadable config as {:?}", backup_path),
        Err(e) => tracing::error!(
            "Failed to back up corrupt config {:?} to {:?}: {}",
            config_path,
            backup_path,
            e
        ),
    }
}

pub fn config_path() -> PathBuf {
    let config_dir = dirs::config_dir().unwrap_or_else(|| PathBuf::from("."));
    config_dir.join("upstray").join("config.toml")
}

fn save_full_config(config: &AppConfig) -> Result<(), Box<dyn std::error::Error>> {
    let content = toml::to_string_pretty(config)?;
    let path = config_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(&path, content)?;
    tracing::info!("Config saved to {:?}", path);
    Ok(())
}

pub fn save_config(host: &str, port: u16) -> Result<(), Box<dyn std::error::Error>> {
    let mut config = load_config();
    config.server.host = host.to_string();
    config.server.port = port;
    save_full_config(&config)
}

pub fn save_ups_name(ups_name: &str) -> Result<(), Box<dyn std::error::Error>> {
    let mut config = load_config();
    config.server.ups_name = ups_name.to_string();
    save_full_config(&config)
}

pub fn set_notifications_config(enabled: bool) -> Result<(), Box<dyn std::error::Error>> {
    let mut config = load_config();
    config.notifications.enabled = enabled;
    save_full_config(&config)
}

pub fn autostart_path() -> PathBuf {
    let config_dir = dirs::config_dir().unwrap_or_else(|| PathBuf::from("."));
    config_dir.join("autostart").join("upstray.desktop")
}

pub fn set_autostart(enabled: bool) -> Result<(), Box<dyn std::error::Error>> {
    let path = autostart_path();
    if enabled {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        let desktop_content = "[Desktop Entry]\nName=UpsTray\nExec=upstray\nIcon=upstray\nTerminal=false\nType=Application\nX-GNOME-Autostart-enabled=true\n";
        fs::write(&path, desktop_content)?;
        tracing::info!("Autostart enabled: wrote {:?}", path);
    } else {
        if path.exists() {
            fs::remove_file(&path)?;
            tracing::info!("Autostart disabled: removed {:?}", path);
        }
    }
    Ok(())
}
