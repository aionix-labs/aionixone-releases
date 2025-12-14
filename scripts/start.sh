#!/bin/bash
# ============================================================================
# AionixOne Start - Start server
# ============================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$DIR/data"
LOG_FILE="$DATA_DIR/server.log"
PID_FILE="$DIR/.pid"
SERVER="$DIR/bin/aionix-server"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if already running
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo -e "${YELLOW}Server already running (PID: $(cat "$PID_FILE"))${NC}"
    exit 0
fi

# Check binary
if [ ! -f "$SERVER" ]; then
    echo -e "${RED}Error: bin/aionix-server not found${NC}"
    exit 1
fi

# Ensure data directory exists
mkdir -p "$DATA_DIR"

echo -e "${YELLOW}Starting AionixOne server...${NC}"

# Start server
"$SERVER" --data-path "$DATA_DIR" > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

# Wait for startup
for i in {1..15}; do
    if curl -s http://localhost:53000/health > /dev/null 2>&1; then
        echo -e "${GREEN}Server started!${NC}"
        echo "  PID: $(cat "$PID_FILE")"
        echo "  URL: http://localhost:53000"
        echo "  Log: $LOG_FILE"
        exit 0
    fi
    sleep 0.5
done

echo -e "${RED}Server failed to start. Check log:${NC}"
tail -20 "$LOG_FILE"
exit 1
