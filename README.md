# ha-ops

Home Assistant watchdog, auto-restart, cloud access, and care dashboard for Andrew's setup.

## Quick Start

### 1. Install Watchdog (stops HA staying dead after crash)
```bash
git clone https://github.com/toronto192020/ha-ops.git ~/tools/ha-ops
cd ~/tools/ha-ops
bash install-watchdog-cron.sh
```
This checks HA every 2 minutes and auto-restarts if it goes down.

### 2. Tailscale Remote Access (reliable, free)
```bash
bash tailscale-ha-access.sh
```
Access HA from anywhere at `http://<tailscale-ip>:8123` - no port forwarding, no Nabu Casa required.

### 3. Nabu Casa Cloud (easy mobile + voice assistant)
See `nabucasa-troubleshoot.md` for setup and fixes.

Key fix for disconnect-after-restart: import `automations/ha-cloud-reconnect.yaml` into HA.

### 4. Care Dashboard
The glowing command center dashboard:
- Care Room panel with Cheryl vitals, BP, motion
- System status (n8n, Tailscale, cloud)
- Pet tracker (Buddy + Holly SmartThings tags)
- Tailscale network map

Install: Copy `lovelace/care-dashboard.yaml` content into a new HA dashboard in YAML mode.
Requires HACS + Mushroom Cards.

## Architecture

```
HA Core
  ├── Nabu Casa (cloud remote access)
  ├── Tailscale (VPN remote access, fallback)
  ├── Watchdog cron (auto-restart on crash)
  ├── Care Dashboard (Cheryl monitoring)
  └── Automations (cloud reconnect, alerts)
```

## Shelly + Tesla Integration

Shelly Pro 3EM monitors grid power. When solar excess detected, HA automation increases Tesla charging amps via Tesla Fleet API integration.

```yaml
# automation: dynamic tesla charging based on shelly solar data
trigger:
  - platform: numeric_state
    entity_id: sensor.shelly_3em_solar_surplus_w
    above: 1500
action:
  - service: number.set_value
    target:
      entity_id: number.tesla_charging_amps
    data:
      value: "{{ [(states('sensor.shelly_3em_solar_surplus_w') | int // 230), 16] | min }}"
```

## License
MIT
