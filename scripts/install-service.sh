#!/bin/bash
# Replit Proxy — systemd Service Installer
# Usage: ./install-service.sh
# Supports both system-wide and user-level service

set -e

SERVICE_NAME="replit-proxy"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UV_BIN="$(command -v uv || echo "$HOME/.local/bin/uv")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UNIT_SRC="$SCRIPT_DIR/replit-proxy.service"

# Detect install mode
SYSTEM_WIDE=false
if [[ "$1" == "--system" ]]; then
    SYSTEM_WIDE=true
fi

# Resolve uv path
if [[ ! -x "$UV_BIN" ]]; then
    echo "[ERROR] uv not found: $UV_BIN"
    echo "Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

echo "uv found: $UV_BIN"
echo "Project: $PROJECT_DIR"

# Determine user
if $SYSTEM_WIDE; then
    SYSTEMD_USER_DIR="/etc/systemd/system"
    SUDO="sudo"
    echo "[MODE] System-wide (root)"
else
    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    SUDO=""
    mkdir -p "$SYSTEMD_USER_DIR"
    echo "[MODE] User-level"
fi

# Build unit file based on install mode
USERNAME=$(whoami)
TMP_UNIT="/tmp/${SERVICE_NAME}.service"
if $SYSTEM_WIDE; then
    sed \
        -e "s|%u|$USERNAME|g" \
        -e "s|%h|$HOME|g" \
        -e "s|^WorkingDirectory=.*|WorkingDirectory=$PROJECT_DIR|" \
        -e "s|^ExecStart=.*|ExecStart=$UV_BIN run uvicorn main:app --host 0.0.0.0 --port 8080|" \
        -e "s|^WantedBy=.*|WantedBy=multi-user.target|" \
        "$UNIT_SRC" > "$TMP_UNIT"
else
    sed \
        -e "s|%u|$USERNAME|g" \
        -e "s|%h|$HOME|g" \
        -e "s|^WorkingDirectory=.*|WorkingDirectory=$PROJECT_DIR|" \
        -e "s|^ExecStart=.*|ExecStart=$UV_BIN run uvicorn main:app --host 0.0.0.0 --port 8080|" \
        -e "/^User=/d" \
        -e "s|^WantedBy=.*|WantedBy=default.target|" \
        "$UNIT_SRC" > "$TMP_UNIT"
fi

# Copy unit file
$SUDO cp "$TMP_UNIT" "$SYSTEMD_USER_DIR/${SERVICE_NAME}.service"
rm -f "$TMP_UNIT"

if $SYSTEM_WIDE; then
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable "$SERVICE_NAME"
    $SUDO systemctl start "$SERVICE_NAME"
    echo ""
    echo "[OK] Service installed and started (system-wide)."
    echo "    Check: sudo systemctl status $SERVICE_NAME"
else
    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    systemctl --user start "$SERVICE_NAME"
    echo ""
    echo "[OK] Service installed and started (user-level)."
    echo "    Check: systemctl --user status $SERVICE_NAME"
fi

echo ""
echo "Commands:"
if $SYSTEM_WIDE; then
    echo "  sudo systemctl start   $SERVICE_NAME"
    echo "  sudo systemctl stop    $SERVICE_NAME"
    echo "  sudo systemctl restart $SERVICE_NAME"
    echo "  sudo systemctl status  $SERVICE_NAME"
    echo "  sudo journalctl -u $SERVICE_NAME -f   # view logs"
else
    echo "  systemctl --user start   $SERVICE_NAME"
    echo "  systemctl --user stop    $SERVICE_NAME"
    echo "  systemctl --user restart $SERVICE_NAME"
    echo "  systemctl --user status  $SERVICE_NAME"
    echo "  journalctl --user -u $SERVICE_NAME -f   # view logs"
fi
