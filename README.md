# UpsTray

A modern, minimal-footprint KDE Plasma system tray monitor for [Network UPS Tools (NUT)](https://networkupstools.org/), written in Rust and Qt6 via [CXX-Qt](https://github.com/KDAB/cxx-qt).

## Features

- **Live System Tray Status** — Tray icon changes with UPS state (online / on battery / low battery / disconnected), with a tooltip showing status, charge, and runtime at a glance
- **Rich Detail Window** — Tabbed UI showing live power metrics (voltage, load, runtime, temperature), device info, and settings
- **UPS Device Selection** — Point upstray at a specific UPS on servers with multiple devices, selectable from the Settings tab and hot-reloaded without restart
- **Desktop Notifications** — Native KDE/D-Bus alerts for power outage, low battery, and reconnection events; outage-class notifications (on battery, low battery, shutdown, connection lost) are sent critical/persistent, restore notifications are normal urgency
- **Persistent Settings** — Notification toggle, NUT server address, and UPS device saved to `~/.config/upstray/config.toml`; autostart is tracked via a `~/.config/autostart/upstray.desktop` file that the app writes or removes when you toggle it
- **Async & Non-blocking** — Tokio-powered background poller with persistent TCP connection and exponential backoff reconnection
- **Wayland Native** — Uses `QSystemTrayIcon` via Qt's StatusNotifierItem protocol; works on KDE Plasma 6 Wayland sessions

See [TODO.md](TODO.md) for the roadmap.

## Screenshots

> Coming soon.

## Requirements

| Dependency | Purpose |
|------------|---------|
| `qt6-base` | Qt application framework |
| `qt6-declarative` | QML engine |
| `qt6-wayland` | Wayland platform integration |
| `nut` | NUT server (`upsd`) must be running and reachable |

## Installation

### Arch Linux

```bash
cd packaging/
makepkg -si
```

### Other distributions

Install Qt6 and NUT via your package manager, then:

```bash
cargo build --release

# Install binary
sudo install -Dm755 target/release/upstray /usr/bin/upstray

# Install desktop entry
sudo install -Dm644 resources/upstray.desktop /usr/share/applications/upstray.desktop

# Install icon
sudo install -Dm644 resources/icons/upstray.svg /usr/share/icons/hicolor/scalable/apps/upstray.svg
```

### NUT Setup (if not already configured)

UpsTray connects to `upsd` over TCP (default `localhost:3493`). If you haven't set up NUT yet:

1. Install the `nut` package for your distribution
2. Configure `/etc/nut/ups.conf` with your UPS device
3. Enable the services:
   ```bash
   sudo systemctl enable --now nut-driver-enumerator nut-server
   ```
4. Verify with: `upsc <upsname>@localhost`

## Configuration

UpsTray reads `~/.config/upstray/config.toml`. On first run only the config directory is created; the file itself is written the first time you save settings from the UI, and built-in defaults are used until then. You can also change the NUT server address from the **Settings** tab in the app.

```toml
[general]
poll_interval_secs = 5

[server]
host = "localhost"
port = 3493
# ups_name = "ups"  # empty or omitted = auto-select the first device the server reports

[notifications]
enabled = true
```

## Building from Source

**Build dependencies:** `rust` (stable), `cargo`, `cmake`

```bash
git clone https://github.com/embernode/upstray.git
cd upstray
cargo build --release
./target/release/upstray
```

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).
