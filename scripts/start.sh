#!/bin/bash
# ============================================================================
# AionixOne Start - Start server
# ============================================================================

BASE_DIR="${AIONIX_HOME:-$HOME/.aionixone}"
DATA_DIR="${AIONIX_DATA_DIR:-$BASE_DIR/data}"
LOG_FILE="${AIONIX_LOG_FILE:-$BASE_DIR/aio.log}"
PID_FILE="${AIONIX_PID_FILE:-$BASE_DIR/aio.pid}"
ENV_FILE="${AIONIX_ENV_FILE:-$BASE_DIR/env}"
PORT="${AIONIX_PORT:-53000}"
AIO_BIN="${AIO_BIN:-aio}"
AGENT_SESSION_STORE="${AIONIX_AGENT_SESSION_STORE:-jsonl}"
AGENT_SESSION_DIR="${AIONIX_AGENT_SESSION_DIR:-$DATA_DIR/agent-session}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if already running
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo -e "${YELLOW}Server already running (PID: $(cat "$PID_FILE"))${NC}"
    exit 0
fi

if ! command -v "$AIO_BIN" >/dev/null 2>&1; then
    echo -e "${RED}Error: aio not found in PATH${NC}"
    exit 1
fi

# Load env if available
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

if [ -z "${AIONIX_API_KEY:-}" ]; then
    echo -e "${RED}Error: AIONIX_API_KEY not set. Run scripts/setup.sh first.${NC}"
    exit 1
fi

# Ensure data directory exists
mkdir -p "$BASE_DIR" "$DATA_DIR"

echo -e "${YELLOW}Starting AionixOne server...${NC}"

# Start server
AIONIX_API_KEY="$AIONIX_API_KEY" \
AIONIX_AGENT_SESSION_STORE="$AGENT_SESSION_STORE" \
AIONIX_AGENT_SESSION_DIR="$AGENT_SESSION_DIR" \
"$AIO_BIN" server --db-mode sqlite --data-path "$DATA_DIR" --port "$PORT" > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

# Wait for startup
for i in {1..15}; do
    if curl -s "http://127.0.0.1:${PORT}/health" > /dev/null 2>&1; then
        echo -e "${GREEN}Server started!${NC}"
        echo "  PID: $(cat "$PID_FILE")"
        echo "  URL: http://127.0.0.1:${PORT}"
        echo "  Log: $LOG_FILE"
        exit 0
    fi
    sleep 0.5
done

echo -e "${RED}Server failed to start. Check log:${NC}"
tail -20 "$LOG_FILE"
exit 1
