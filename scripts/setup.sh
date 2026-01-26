#!/bin/bash
# ============================================================================
# AionixOne Setup - First time setup
# ============================================================================

BASE_DIR="${AIONIX_HOME:-$HOME/.aionixone}"
DATA_DIR="${AIONIX_DATA_DIR:-$BASE_DIR/data}"
ENV_FILE="${AIONIX_ENV_FILE:-$BASE_DIR/env}"
PORT="${AIONIX_PORT:-53000}"
AIO_BIN="${AIO_BIN:-aio}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== AionixOne Setup ===${NC}"

if ! command -v "$AIO_BIN" >/dev/null 2>&1; then
    echo -e "${RED}Error: aio not found in PATH${NC}"
    exit 1
fi

mkdir -p "$BASE_DIR" "$DATA_DIR"

# Stop existing server
if [ -f "$BASE_DIR/aio.pid" ]; then
    PID="$(cat "$BASE_DIR/aio.pid" 2>/dev/null || true)"
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill "$PID" >/dev/null 2>&1 || true
    fi
fi
sleep 1

# Bootstrap admin
echo -e "${YELLOW}Creating admin API key...${NC}"
OUTPUT=$("$AIO_BIN" server --bootstrap-admin admin --db-mode sqlite --data-path "$DATA_DIR" --port "$PORT" 2>&1 || true)

# Extract API key (format: ak_XXXX_XXXX-XXXX)
API_KEY=$(echo "$OUTPUT" | grep -oE "ak_[A-Za-z0-9_-]{30,}" | head -1)

if [ -z "$API_KEY" ] && [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    if [ -n "${AIONIX_API_KEY:-}" ]; then
        API_KEY="$AIONIX_API_KEY"
        echo -e "${YELLOW}Using existing API key${NC}"
    fi
fi

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Failed to create API key${NC}"
    echo "$OUTPUT"
    exit 1
fi

# Save config
cat > "$ENV_FILE" << EOF
# AionixOne Community Environment
export AIONIX_API_KEY="$API_KEY"
export AIONIX_API_BASE="http://127.0.0.1:${PORT}"
export AIONIX_DATA_PATH="$DATA_DIR"
EOF

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "API Key: ${YELLOW}$API_KEY${NC}"
echo ""
echo "Next steps:"
echo "  1. source \"$ENV_FILE\""
echo "  2. ./start.sh"
echo "  3. aio --help"
