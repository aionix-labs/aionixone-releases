#!/bin/bash
# ============================================================================
# AionixOne Starter - Server Manager
# Convenience wrapper for starting/stopping aionix-server
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Try to find the main repo's scripts
START_SCRIPT=""
STOP_SCRIPT=""

# If starter is inside main repo (incubation phase)
if [ -f "$STARTER_ROOT/../scripts/start-server.sh" ]; then
    START_SCRIPT="$STARTER_ROOT/../scripts/start-server.sh"
    STOP_SCRIPT="$STARTER_ROOT/../scripts/stop-server.sh"
fi

# If AIONIX_ROOT is set
if [ -n "${AIONIX_ROOT:-}" ] && [ -f "$AIONIX_ROOT/scripts/start-server.sh" ]; then
    START_SCRIPT="$AIONIX_ROOT/scripts/start-server.sh"
    STOP_SCRIPT="$AIONIX_ROOT/scripts/stop-server.sh"
fi

if [ -z "$START_SCRIPT" ]; then
    echo "Error: Cannot find AionixOne server scripts."
    echo ""
    echo "Options:"
    echo "  1. Run this from within the main aionixone repository"
    echo "  2. Set AIONIX_ROOT to point to the main repository"
    echo ""
    echo "Example:"
    echo "  export AIONIX_ROOT=/path/to/aionixone"
    echo "  ./scripts/start-server.sh"
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
        echo "  start [--fresh|--bootstrap]  Start aionix-server"
        echo "  stop                         Stop aionix-server"
        exit 1
        ;;
esac
