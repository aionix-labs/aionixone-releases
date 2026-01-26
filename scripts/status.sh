#!/bin/bash
# ============================================================================
# AionixOne Status - Check server status
# ============================================================================

BASE_DIR="${AIONIX_HOME:-$HOME/.aionixone}"
PID_FILE="${AIONIX_PID_FILE:-$BASE_DIR/aio.pid}"
LOG_FILE="${AIONIX_LOG_FILE:-$BASE_DIR/aio.log}"
ENV_FILE="${AIONIX_ENV_FILE:-$BASE_DIR/env}"
PORT="${AIONIX_PORT:-53000}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== AionixOne Status ==="
echo ""

# Check process
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo -e "Process: ${GREEN}Running${NC} (PID: $(cat "$PID_FILE"))"
else
    echo -e "Process: ${RED}Stopped${NC}"
fi

# Check health
# Load env if available
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

if curl -s "http://127.0.0.1:${PORT}/health" > /dev/null 2>&1; then
    echo -e "Health:  ${GREEN}OK${NC}"
    echo "URL:     http://127.0.0.1:${PORT}"
else
    echo -e "Health:  ${RED}Unavailable${NC}"
fi

# Show recent logs
if [ -f "$LOG_FILE" ]; then
    echo ""
    echo "=== Recent Logs ==="
    tail -10 "$LOG_FILE"
fi
