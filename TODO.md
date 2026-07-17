# Roadmap

## Planned

- **Staleness indicator** — surface `UpsState.last_updated` in the Monitor tab ("updated Ns ago", amber when older than a couple of poll intervals); the field exists but nothing reads it yet.
- **Event history tab** — timestamped log of power events (on battery / power restored / connection lost) with durations, so outages can be reviewed after the fact.
- **Battery & load sparkline** — in-memory history of charge/load rendered in the Monitor tab.
- **Device dropdown recovery after a bad `ups_name`** — a configured name the server doesn't report is treated as a connection error (by design), which also empties the live device list in the Settings dropdown until Auto is selected and the connection recovers; surface the last-known device list (or the names from the error log) so the correct device can be picked directly.

## Low priority

- **NUT authentication** — `upsd` username/password support (`rups` already supports it); prerequisite for instrument commands (beeper toggle, battery self-test).
- **Poll interval in Settings UI** — currently config-file only (`poll_interval_secs`) and requires a restart to take effect.
