#!/bin/bash
# Replit Proxy — systemd Service Remover
# Usage: ./remove-service.sh

set -e

SERVICE_NAME="replit-proxy"

# Detect install mode
if [[ "$1" == "--system" ]]; then
    SYSTEM_WIDE=true
else
    SYSTEM_WIDE=false
fi

if $SYSTEM_WIDE; then
    SUDO="sudo"
    SYSTEMD_USER_DIR="/etc/systemd/system"
else
    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    SUDO=""
fi

echo "Removing service: $SERVICE_NAME"

$SUDO systemctl stop "$SERVICE_NAME" 2>/dev/null || true
$SUDO systemctl disable "$SERVICE_NAME" 2>/dev/null || true
$SUDO rm -f "$SYSTEMD_USER_DIR/${SERVICE_NAME}.service"

if $SYSTEM_WIDE; then
    $SUDO systemctl daemon-reload
fi

echo "[OK] Service removed."
