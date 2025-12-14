#!/bin/bash
# ============================================================================
# AionixOne Stop - Stop server
# ============================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$DIR/.pid"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo -e "${YELLOW}Stopping server (PID: $PID)...${NC}"
        kill "$PID"
        rm -f "$PID_FILE"
        echo -e "${GREEN}Server stopped${NC}"
    else
        echo -e "${YELLOW}Server not running${NC}"
        rm -f "$PID_FILE"
    fi
else
    echo -e "${YELLOW}Server not running${NC}"
fi
