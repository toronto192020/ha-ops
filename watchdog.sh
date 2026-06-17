#!/usr/bin/env bash
# watchdog.sh - Home Assistant health watchdog
# Checks HA is responding every 2 minutes. If dead, restarts it.
# Run via cron or launchd on the machine hosting HA.
# Works for: HA OS, HA Supervised, HA Docker
#
# Usage: bash watchdog.sh
# Cron (every 2 min): */2 * * * * /path/to/watchdog.sh >> /var/log/ha-watchdog.log 2>&1

set -euo pipefail

HA_HOST="${HA_HOST:-localhost}"
HA_PORT="${HA_PORT:-8123}"
HA_TOKEN="${HA_TOKEN:-}"  # Set in env or replace here
LOG="$HOME/logs/ops/ha-watchdog.log"
MAX_FAILURES=3
FAILURE_FILE="/tmp/ha-watchdog-failures"

mkdir -p "$(dirname "$LOG")"
TS=$(date '+%Y-%m-%d %H:%M:%S')

check_ha() {
  if [ -n "$HA_TOKEN" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $HA_TOKEN" \
      --connect-timeout 10 \
      "http://$HA_HOST:$HA_PORT/api/" 2>/dev/null || echo "000")
  else
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      --connect-timeout 10 \
      "http://$HA_HOST:$HA_PORT" 2>/dev/null || echo "000")
  fi
  echo "$HTTP_CODE"
}

restart_ha_docker() {
  echo "[$TS] Restarting HA Docker container..." | tee -a "$LOG"
  docker restart homeassistant 2>/dev/null || docker restart home-assistant 2>/dev/null || true
}

restart_ha_supervised() {
  echo "[$TS] Restarting HA via supervisor..." | tee -a "$LOG"
  ha core restart 2>/dev/null || true
}

# Track failures
FAILURES=0
if [ -f "$FAILURE_FILE" ]; then
  FAILURES=$(cat "$FAILURE_FILE" 2>/dev/null || echo 0)
fi

STATUS=$(check_ha)

if [ "$STATUS" = "200" ] || [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  # 401 = HA is up but needs auth token (still alive)
  # 302 = redirect to login (still alive)
  echo "[$TS] HA OK (HTTP $STATUS)" >> "$LOG"
  echo 0 > "$FAILURE_FILE"
else
  FAILURES=$((FAILURES + 1))
  echo $FAILURES > "$FAILURE_FILE"
  echo "[$TS] WARN: HA not responding (HTTP $STATUS) - failure $FAILURES/$MAX_FAILURES" | tee -a "$LOG"

  if [ "$FAILURES" -ge "$MAX_FAILURES" ]; then
    echo "[$TS] CRITICAL: HA down $FAILURES times - restarting" | tee -a "$LOG"
    echo 0 > "$FAILURE_FILE"
    
    # Try Docker first, then supervisor
    if command -v docker &>/dev/null && docker ps | grep -q -E 'homeassistant|home-assistant'; then
      restart_ha_docker
    else
      restart_ha_supervised
    fi
    
    sleep 30
    
    # Verify restart worked
    NEW_STATUS=$(check_ha)
    echo "[$TS] Post-restart check: HTTP $NEW_STATUS" | tee -a "$LOG"
  fi
fi
