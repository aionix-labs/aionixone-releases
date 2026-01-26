#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "AionixFn: 03-invoke"

# Prerequisites
check_cli_available
check_server_health

# Unique name
FN_NAME="starter-invoke-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"

# 1. Deploy function first
info "Deploying function: $FN_NAME"

if $CLI fn deploy "$FN_NAME" --code "$SCRIPT_DIR/code" -r python3.10 --handler handler:handler > /dev/null 2>&1; then
    success "Function deployed"
else
    fail "Failed to deploy function"
fi

# 2. Invoke with greet operation
info "Invoking function (greet operation)..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{"operation": "greet", "name": "AionixOne"}')
GREET_RESULT=$(echo "$RESULT" | jq -r '.result.output.result')
info "  Result: $GREET_RESULT"

if [ "$GREET_RESULT" = "Hello, AionixOne!" ]; then
    success "Greet operation works"
else
    fail "Unexpected greet result: $GREET_RESULT"
fi

# 3. Invoke with add operation
info "Invoking function (add operation)..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{"operation": "add", "a": 10, "b": 25}')
ADD_RESULT=$(echo "$RESULT" | jq -r '.result.output.result')
info "  10 + 25 = $ADD_RESULT"

if [ "$ADD_RESULT" = "35" ]; then
    success "Add operation works"
else
    fail "Unexpected add result: $ADD_RESULT"
fi

# 4. Invoke with echo operation
info "Invoking function (echo operation)..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{"operation": "echo", "data": "test"}')
ECHO_OP=$(echo "$RESULT" | jq -r '.result.output.operation')
info "  Operation: $ECHO_OP"

if [ "$ECHO_OP" = "echo" ]; then
    success "Echo operation works"
else
    fail "Unexpected echo result"
fi

# 5. Invoke with default (no data)
info "Invoking function (default)..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{}')
DEFAULT_RESULT=$(echo "$RESULT" | jq -r '.result.output.result')
info "  Default result: $DEFAULT_RESULT"

if [ "$DEFAULT_RESULT" = "Hello, World!" ]; then
    success "Default invocation works"
else
    warn "Unexpected default result: $DEFAULT_RESULT"
fi

echo ""
success "03-invoke completed successfully"
info "  Functions can be invoked with JSON payloads"
info "  Use 'aio fn invoke' with -d for inline data or -f for file"
