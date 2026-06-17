# Nabu Casa Cloud - Troubleshoot & Setup

Nabu Casa gives HA a cloud URL at `https://YOUR_ID.ui.nabu.casa`. $9.99 USD/month.

## Quick Setup

1. Go to **Settings > Home Assistant Cloud** in HA
2. Sign up at [home.nabucasa.com](https://home.nabucasa.com)
3. Sign in from the HA UI
4. Toggle **Remote Control** ON
5. Your remote URL appears immediately

## Common Failures

### "Remote access is being prepared"
- Wait 5-10 min after first enable
- If stuck: Settings > 3 dots > Restart HA > Expand Advanced Options > Reboot System

### "Unable to reach Home Assistant Cloud" / IPv6 errors
Fix: Disable IPv6 on the HA host.

For HA OS:
```
# SSH into HA OS (port 22222)
ha network info
# Disable IPv6 via UI: Settings > System > Network > uncheck IPv6
```

For Docker:
```bash
# In docker-compose.yml for homeassistant container:
# Add: sysctls: net.ipv6.conf.all.disable_ipv6=1
docker restart homeassistant
```

### Nabu Casa disconnects after HA restart
This is the most common issue. Fix with the watchdog.sh script in this repo.

Also add to HA `configuration.yaml`:
```yaml
cloud:
  # Forces reconnect on startup
```

And add an automation to reconnect cloud after HA starts:
```yaml
automation:
  - alias: "Reconnect Nabu Casa on startup"
    trigger:
      - platform: homeassistant
        event: start
    action:
      - delay: "00:01:00"
      - service: cloud.remote_connect
```

## Best Setup: Nabu Casa + Tailscale (belt AND suspenders)

- Nabu Casa = easy mobile access via app, Google Assistant, Alexa
- Tailscale = rock-solid fallback, no subscription risk, local-speed access
- Run both. If Nabu Casa drops, Tailscale still works.

```
Mobile App --> Nabu Casa cloud URL --> HA
                    OR
Mobile App --> Tailscale --> HA IP:8123 (direct, encrypted)
```
