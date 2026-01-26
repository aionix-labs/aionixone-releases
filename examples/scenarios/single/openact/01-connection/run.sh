#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "OpenAct: 01-connection"

# Prerequisites
check_cli_available
check_server_health

# Unique names
CONN_NAME="starter-http-conn-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI act conn delete 'http/$CONN_NAME' --force 2>/dev/null || true"

# 1. Create HTTP connection
info "Creating HTTP connection: $CONN_NAME"

CONN_CONFIG=$(cat <<'EOF'
{
  "baseUrl": "https://httpbin.org",
  "timeout": 30000,
  "headers": {
    "User-Agent": "AionixOne-Starter/1.0"
  }
}
EOF
)

if $CLI act conn create "$CONN_NAME" -t http --config "$CONN_CONFIG" > /dev/null 2>&1; then
    success "Connection created"
else
    fail "Failed to create connection"
fi

# 2. Get connection details
info "Getting connection details..."
CONN_JSON=$($CLI -o json act conn get "http/$CONN_NAME")
KIND=$(echo "$CONN_JSON" | jq -r '.kind')
BASE_URL=$(echo "$CONN_JSON" | jq -r '.spec.baseUrl')
info "  Kind: $KIND"
info "  Base URL: $BASE_URL"

if [ "$KIND" = "connection/http" ]; then
    success "Connection kind verified"
else
    fail "Unexpected kind: $KIND"
fi

# 3. Test connection
info "Testing connection..."
if $CLI act conn test "http/$CONN_NAME" > /dev/null 2>&1; then
    success "Connection test passed"
else
    warn "Connection test not implemented or failed"
fi

# 4. List connections
info "Listing HTTP connections..."
CONN_COUNT=$($CLI -o json act conn list -t http | jq 'length')
info "  Found $CONN_COUNT HTTP connection(s)"

echo ""
success "01-connection completed successfully"
info "  Connections define how to connect to external services"
