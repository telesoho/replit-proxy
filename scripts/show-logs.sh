#!/bin/bash
# Replit Proxy — Service Log Viewer
# Usage: ./show-logs.sh [--system] [-n LINES] [-f]
#
# Options:
#   --system        Show logs for system-wide installation
#   -n LINES        Number of recent lines to show (default: 50)
#   -f, --follow    Follow live log output (Ctrl+C to exit)

set -e

SERVICE_NAME="replit-proxy"
LINES=50
FOLLOW=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --system)
            SYSTEM_WIDE=true
            shift
            ;;
        -n)
            LINES="$2"
            shift 2
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--system] [-n LINES] [-f]"
            echo ""
            echo "Options:"
            echo "  --system        Show logs for system-wide installation"
            echo "  -n LINES        Number of recent lines to show (default: 50)"
            echo "  -f, --follow    Follow live log output"
            echo ""
            echo "Examples:"
            echo "  $0                       # Show last 50 lines (user-level)"
            echo "  $0 --system               # Show last 50 lines (system-wide)"
            echo "  $0 -n 200                 # Show last 200 lines"
            echo "  $0 -f                     # Follow live logs"
            echo "  $0 --system -n 100 -f     # System-wide, last 100 lines, follow"
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

# Default to user-level if not specified
SYSTEM_WIDE=${SYSTEM_WIDE:-false}

if $SYSTEM_WIDE; then
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
    echo "[MODE] System-wide"
    echo "Hint:   $SUDO journalctl -u $SERVICE_NAME --since '1 hour ago'"
    echo "---"
    $SUDO journalctl -u "$SERVICE_NAME" -n "$LINES" --no-pager
    if $FOLLOW; then
        $SUDO journalctl -u "$SERVICE_NAME" -f --no-pager
    fi
else
    echo "[MODE] User-level"
    echo "Hint:   journalctl --user -u $SERVICE_NAME --since '1 hour ago'"
    echo "---"
    journalctl --user -u "$SERVICE_NAME" -n "$LINES" --no-pager
    if $FOLLOW; then
        journalctl --user -u "$SERVICE_NAME" -f --no-pager
    fi
fi
