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

echo "Removing service: $SERVICE_NAME"

if $SYSTEM_WIDE; then
    # System-wide service (/etc/systemd/system)
    if [[ $EUID -eq 0 ]]; then
        RUN_AS_ROOT=""
    else
        RUN_AS_ROOT="sudo"
    fi

    $RUN_AS_ROOT systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    $RUN_AS_ROOT systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    $RUN_AS_ROOT rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    $RUN_AS_ROOT systemctl daemon-reload
    echo "[OK] System-wide service removed."
else
    # User-level service (~/.config/systemd/user)
    TARGET_USER="${SUDO_USER:-$USER}"
    TARGET_UID="$(id -u "$TARGET_USER")"
    # Fall back to $HOME if getent fails (e.g. when run as root directly without sudo)
    if ! TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)"; then
        TARGET_HOME="$HOME"
    fi
    SYSTEMD_USER_DIR="${TARGET_HOME}/.config/systemd/user"

    if [[ $EUID -eq 0 ]]; then
        # Called via sudo: operate on the original invoking user's --user systemd
        sudo -u "$TARGET_USER" XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
        sudo -u "$TARGET_USER" XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
        rm -f "${SYSTEMD_USER_DIR}/${SERVICE_NAME}.service"
        sudo -u "$TARGET_USER" XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" systemctl --user daemon-reload || true
    else
        systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
        systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
        rm -f "${SYSTEMD_USER_DIR}/${SERVICE_NAME}.service"
        systemctl --user daemon-reload || true
    fi

    echo "[OK] User-level service removed for user: ${TARGET_USER}"
fi
