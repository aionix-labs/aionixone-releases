#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "OpenAct: 02-action"

# Prerequisites
check_cli_available
check_server_health

# Unique names
CONN_NAME="starter-action-conn-$(date +%s)-$RANDOM"
ACTION_NAME="starter-action-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI act delete 'http/$ACTION_NAME' --force 2>/dev/null || true"
register_cleanup "$CLI act conn delete 'http/$CONN_NAME' --force 2>/dev/null || true"

# 1. Create connection first
info "Creating HTTP connection: $CONN_NAME"
CONN_CONFIG='{"baseUrl": "https://httpbin.org"}'
if $CLI act conn create "$CONN_NAME" -t http --config "$CONN_CONFIG" > /dev/null 2>&1; then
    success "Connection created"
else
    fail "Failed to create connection"
fi

# 2. Create action
info "Creating HTTP action: $ACTION_NAME"

ACTION_CONFIG=$(cat <<'EOF'
{
  "method": "GET",
  "path": "/get",
  "query": {
    "source": "aionix-starter"
  },
  "response": {
    "successCodes": [200]
  }
}
EOF
)

if $CLI act create "$ACTION_NAME" -t http -c "http/$CONN_NAME" --config "$ACTION_CONFIG" > /dev/null 2>&1; then
    success "Action created"
else
    fail "Failed to create action"
fi

# 3. Get action details
info "Getting action details..."
ACTION_JSON=$($CLI -o json act get "http/$ACTION_NAME")
KIND=$(echo "$ACTION_JSON" | jq -r '.kind')
METHOD=$(echo "$ACTION_JSON" | jq -r '.spec.method')
PATH=$(echo "$ACTION_JSON" | jq -r '.spec.path')
info "  Kind: $KIND"
info "  Method: $METHOD"
info "  Path: $PATH"

if [ "$KIND" = "action/http" ]; then
    success "Action kind verified"
else
    fail "Unexpected kind: $KIND"
fi

# 4. List actions
info "Listing HTTP actions..."
ACTION_COUNT=$($CLI -o json act list -t http 2>/dev/null | jq 'length' 2>/dev/null || echo "N/A")
info "  Found $ACTION_COUNT HTTP action(s)"

echo ""
success "02-action completed successfully"
info "  Actions define specific operations on connections"
