#!/bin/bash
# ============================================================================
# AionixOne Setup - First time setup
# ============================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$DIR/data"
CONFIG_FILE="$DIR/.env"
SERVER="$DIR/bin/aionix-server"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== AionixOne Setup ===${NC}"

# Check binary
if [ ! -f "$SERVER" ]; then
    echo -e "${RED}Error: bin/aionix-server not found${NC}"
    exit 1
fi

# Create data directory
mkdir -p "$DATA_DIR"

# Stop existing server
pkill -f "$SERVER" 2>/dev/null || true
sleep 1

# Bootstrap admin
echo -e "${YELLOW}Creating admin API key...${NC}"
OUTPUT=$("$SERVER" --bootstrap-admin admin --data-path "$DATA_DIR" 2>&1 || true)

# Extract API key (format: ak_XXXX_XXXX_XXXX)
API_KEY=$(echo "$OUTPUT" | grep -oE "ak_[A-Za-z0-9_]{30,}" | head -1)

if [ -z "$API_KEY" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        if [ -n "$AIONIX_API_KEY" ]; then
            API_KEY="$AIONIX_API_KEY"
            echo -e "${YELLOW}Using existing API key${NC}"
        fi
    fi
fi

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Failed to create API key${NC}"
    echo "$OUTPUT"
    exit 1
fi

# Save config
cat > "$CONFIG_FILE" << EOF
# AionixOne Environment
export AIONIX_API_KEY="$API_KEY"
export AIONIX_URL="http://localhost:53000"
export PATH="\$PATH:$DIR/bin"
EOF

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "API Key: ${YELLOW}$API_KEY${NC}"
echo ""
echo "Next steps:"
echo "  1. source .env"
echo "  2. ./start.sh"
echo "  3. aio --help"
