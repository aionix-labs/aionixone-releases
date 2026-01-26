#!/bin/bash
# ============================================================================
# AionixOne Starter - Environment Setup Check
# Verifies CLI and services are available
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$STARTER_ROOT/common/helpers.sh"

header "AionixOne Starter Environment Check"

# ============================================================================
# CLI Check
# ============================================================================

echo "CLI:"
if command -v "$CLI" &> /dev/null; then
    CLI_PATH=$(command -v "$CLI")
    success "aio CLI found at $CLI_PATH"

    CLI_VERSION=$($CLI --version 2>/dev/null || echo "unknown")
    success "Version: $CLI_VERSION"
else
    fail "aio CLI not found. Please install it first."
fi

echo ""

# ============================================================================
# Server Check
# ============================================================================

echo "Server:"

AIONIX_API_BASE="${AIONIX_API_BASE:-http://127.0.0.1:53000}"
SERVER_URL="${AIONIX_API_BASE%/}/health"

SERVER_HEALTHY=true

if curl -sf "$SERVER_URL" > /dev/null 2>&1; then
    printf "  ${GREEN}✓${NC} server (%s)\n" "$AIONIX_API_BASE"
else
    printf "  ${RED}✗${NC} server (%s) - not responding\n" "$AIONIX_API_BASE"
    SERVER_HEALTHY=false
fi

ALL_HEALTHY=$SERVER_HEALTHY

echo ""

# ============================================================================
# Summary
# ============================================================================

if [ "$ALL_HEALTHY" = true ]; then
    echo -e "Environment: ${GREEN}Ready${NC}"
    echo ""
    echo "You can now run scenarios:"
    echo "  cd scenarios/connectors/http"
    echo "  ./run.sh"
else
    echo -e "Environment: ${YELLOW}Not Ready${NC}"
    echo ""
    echo "Server is not running. Start it with:"
    echo "  ../scripts/start.sh"
fi

echo ""
