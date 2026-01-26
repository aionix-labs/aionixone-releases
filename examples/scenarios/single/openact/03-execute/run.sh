#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "OpenAct: 03-execute"

# Prerequisites
check_cli_available
check_server_health

# Unique names
CONN_NAME="starter-exec-conn-$(date +%s)-$RANDOM"
ACTION_NAME="starter-exec-action-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI act delete 'http/$ACTION_NAME' --force 2>/dev/null || true"
register_cleanup "$CLI act conn delete 'http/$CONN_NAME' --force 2>/dev/null || true"

# 1. Create connection
info "Creating HTTP connection: $CONN_NAME"
CONN_CONFIG='{"baseUrl": "https://httpbin.org"}'
if $CLI act conn create "$CONN_NAME" -t http --config "$CONN_CONFIG" > /dev/null 2>&1; then
    success "Connection created"
else
    fail "Failed to create connection"
fi

# 2. Create action with input mapping
info "Creating HTTP action with input mapping: $ACTION_NAME"

# Action that accepts dynamic input
# When body.data is null/empty, the input is passed directly as JSON body
ACTION_CONFIG=$(jq -n '{
  method: "POST",
  path: "/post",
  body: {type: "json", data: null},
  response: {successCodes: [200]}
}')

if $CLI act create "$ACTION_NAME" -t http -c "http/$CONN_NAME" --config "$ACTION_CONFIG" > /dev/null 2>&1; then
    success "Action created"
else
    fail "Failed to create action"
fi

# 3. Execute action with input
info "Executing action with input..."

INPUT_DATA=$(cat <<'EOF'
{
  "message": "Hello from AionixOne!",
  "timestamp": "2026-01-04T12:00:00Z",
  "source": "starter-scenario"
}
EOF
)

EXEC_JSON=$($CLI -o json act execute "http/$ACTION_NAME" -d "$INPUT_DATA" 2>&1)

# Check execution result (support legacy direct execute and new invoke envelope)
STATUS=$(echo "$EXEC_JSON" | jq -r '.status // .result.status // empty')
HTTP_STATUS=$(echo "$EXEC_JSON" | jq -r '.result.output.status // .result.output.body.status // .output.status // .output.body.status // "unknown"')

info "  Execution status: $STATUS"
info "  HTTP status: $HTTP_STATUS"

if [ "$STATUS" = "completed" ] || [ "$STATUS" = "succeeded" ]; then
    success "Action executed successfully"

    # Verify the input was sent
    ECHOED_MESSAGE=$(echo "$EXEC_JSON" | jq -r '.result.output.body.json.message // .output.body.json.message // "not found"')
    if [ "$ECHOED_MESSAGE" = "Hello from AionixOne!" ]; then
        info "  Input data echoed correctly by httpbin.org"
    fi
else
    fail "Execution failed: $EXEC_JSON"
fi

# 4. Execute again with different input
info "Executing with different input..."

EXEC_JSON2=$($CLI -o json act execute "http/$ACTION_NAME" -d '{"count": 42, "enabled": true}' 2>&1)
STATUS2=$(echo "$EXEC_JSON2" | jq -r '.status // .result.status // empty')

if [ "$STATUS2" = "completed" ] || [ "$STATUS2" = "succeeded" ]; then
    success "Second execution completed"
else
    warn "Second execution status: $STATUS2"
fi

echo ""
success "03-execute completed successfully"
info "  Actions can accept dynamic input and execute against external services"
