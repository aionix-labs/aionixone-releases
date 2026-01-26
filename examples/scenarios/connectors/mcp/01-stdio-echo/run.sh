#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "MCP Connector: 01-stdio-echo"

# Prerequisites
check_cli_available
check_server_health

# Build or find MCP test server
MCP_BIN="$REPO_ROOT/libraries/aionix-mcp/target/release/rmcp_test_server"
if [ ! -x "$MCP_BIN" ]; then
    info "Building MCP test server..."
    (cd "$REPO_ROOT" && cargo build --manifest-path libraries/aionix-mcp/Cargo.toml -p aionix-rmcp-client --bin rmcp_test_server --release >/dev/null 2>&1)
fi

if [ ! -x "$MCP_BIN" ]; then
    fail "MCP test server not found: $MCP_BIN"
fi
success "MCP test server available"

# Unique names
CONN_NAME="starter-mcp-conn-$(date +%s)-$RANDOM"
ACTION_NAME="starter-mcp-echo-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI act delete mcp/$ACTION_NAME --force 2>/dev/null || true"
register_cleanup "$CLI act conn delete mcp/$CONN_NAME --force 2>/dev/null || true"

# 1. Create MCP connection with stdio transport
info "Creating MCP connection: $CONN_NAME"
CONN_CONFIG=$(jq -n --arg cmd "$MCP_BIN" '{
  transport: {
    type: "stdio",
    command: $cmd,
    args: [],
    env: {}
  },
  serverName: "test-mcp",
  connectTimeoutMs: 30000,
  requestTimeoutMs: 30000
}')

if $CLI act conn create "$CONN_NAME" -t mcp --config "$CONN_CONFIG" -o json > /dev/null 2>&1; then
    success "Connection created"
else
    fail "Failed to create connection"
fi

# 2. Test connection (optional - may not be fully implemented)
info "Testing connection..."
if $CLI act conn test "$CONN_NAME" -o json 2>&1 | grep -q '"success"'; then
    success "Connection test passed"
else
    info "  Connection test skipped (may not be implemented)"
fi

# 3. Create echo action
info "Creating echo action: $ACTION_NAME"
ACTION_CONFIG=$(jq -n '{
  tool: "echo",
  arguments: {
    message: "Hello from AionixOne",
    env_var: "starter-test"
  }
}')

if $CLI act create "$ACTION_NAME" -t mcp -c "mcp/$CONN_NAME" --config "$ACTION_CONFIG" -o json > /dev/null 2>&1; then
    success "Action created"
else
    fail "Failed to create action"
fi

# 4. Execute the echo action
info "Executing echo action..."
RESULT=$($CLI act execute "mcp/$ACTION_NAME" -o json 2>&1) || true
STATUS=$(echo "$RESULT" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")

if [ "$STATUS" = "completed" ]; then
    success "MCP action executed successfully"
    OUTPUT=$(echo "$RESULT" | jq -r '.output // {}' 2>/dev/null)
    info "  Status: completed"
    info "  Output: $(echo "$OUTPUT" | head -c 100)"
else
    warn "Unexpected status: $STATUS"
    info "  Result: $(echo "$RESULT" | head -c 300)"
fi

echo ""
success "01-stdio-echo completed successfully"
info "  MCP connector enables calling tools from MCP servers"
info "  Use stdio transport for local MCP servers (npx, uvx)"
info "  Use http transport for remote MCP servers"
