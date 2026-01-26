#!/bin/bash
# ============================================================================
# AionixOne Starter - Server Manager
# Convenience wrapper for starting/stopping community aio server
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASE_SCRIPTS="$STARTER_ROOT/../scripts"
START_SCRIPT="${RELEASE_SCRIPTS}/start.sh"
STOP_SCRIPT="${RELEASE_SCRIPTS}/stop.sh"

if [ ! -f "$START_SCRIPT" ] || [ ! -f "$STOP_SCRIPT" ]; then
    echo "Error: Cannot find community scripts (start.sh/stop.sh)."
    echo "Run from the aionixone-releases repo or set AIONIX_ROOT to it."
    exit 1
fi

case "${1:-start}" in
    start)
        shift || true
        exec "$START_SCRIPT" "$@"
        ;;
    stop)
        exec "$STOP_SCRIPT"
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        echo ""
        echo "  start                        Start community aio server"
        echo "  stop                         Stop community aio server"
        exit 1
        ;;
esac
