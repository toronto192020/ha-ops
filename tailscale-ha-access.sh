#!/usr/bin/env bash
# tailscale-ha-access.sh
# Configure Tailscale for reliable Home Assistant remote access.
# More reliable than Nabu Casa alone. Free. No port forwarding.
# Run this on the machine hosting HA.

set -euo pipefail

echo "[tailscale-ha] Setting up Tailscale remote access for Home Assistant"

# 1. Install Tailscale if not present
if ! command -v tailscale &>/dev/null; then
  echo "Installing Tailscale..."
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS - download from tailscale.com or mas
    echo "Install Tailscale for macOS from: https://tailscale.com/download/macos"
    echo "Or: brew install --cask tailscale"
  else
    # Linux
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
else
  echo "[tailscale-ha] Tailscale already installed"
fi

# 2. Enable Tailscale SSH
echo "[tailscale-ha] Enabling Tailscale (with SSH)..."
sudo tailscale up --ssh --accept-dns=false

# 3. Get Tailscale IP
TAIL_IP=$(tailscale ip -4 2>/dev/null || echo "check 'tailscale ip -4'")
echo ""
echo "[tailscale-ha] Your Tailscale IP: $TAIL_IP"
echo ""
echo "To access Home Assistant remotely:"
echo "  http://$TAIL_IP:8123"
echo ""
echo "Add this to your HA configuration.yaml for trusted proxy:"
cat <<EOF

# In configuration.yaml:
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - ::1
    - 100.64.0.0/10   # Tailscale network range
EOF
echo ""
echo "After updating configuration.yaml, restart HA."
echo "You can now access HA from any device on your Tailnet at: http://$TAIL_IP:8123"
