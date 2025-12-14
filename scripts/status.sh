#!/bin/bash
# ============================================================================
# AionixOne Status - Check server status
# ============================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$DIR/.pid"
LOG_FILE="$DIR/data/server.log"

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
if curl -s http://localhost:53000/health > /dev/null 2>&1; then
    echo -e "Health:  ${GREEN}OK${NC}"
    echo "URL:     http://localhost:53000"
else
    echo -e "Health:  ${RED}Unavailable${NC}"
fi

# Show recent logs
if [ -f "$LOG_FILE" ]; then
    echo ""
    echo "=== Recent Logs ==="
    tail -10 "$LOG_FILE"
fi
