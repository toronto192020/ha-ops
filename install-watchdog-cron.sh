#!/usr/bin/env bash
# Install the HA watchdog as a cron job (checks every 2 minutes)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WATCHDOG="$SCRIPT_DIR/watchdog.sh"
chmod +x "$WATCHDOG"

# Add to crontab if not already there
if crontab -l 2>/dev/null | grep -q "ha-watchdog\|watchdog.sh"; then
  echo "Watchdog cron already installed."
else
  (crontab -l 2>/dev/null; echo "*/2 * * * * HA_HOST=localhost HA_PORT=8123 bash $WATCHDOG >> $HOME/logs/ops/ha-watchdog.log 2>&1") | crontab -
  echo "Watchdog cron installed (every 2 min)."
  echo "Check with: crontab -l"
fi

mkdir -p "$HOME/logs/ops"
echo "Logs: $HOME/logs/ops/ha-watchdog.log"
