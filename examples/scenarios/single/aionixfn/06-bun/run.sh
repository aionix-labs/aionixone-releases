#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "AionixFn: 06-bun (TypeScript/JavaScript)"

# Prerequisites
check_cli_available
check_server_health

# Check if Bun is installed
check_bun_installed() {
    if command -v bun &> /dev/null; then
        BUN_VERSION=$(bun --version 2>/dev/null || echo "unknown")
        success "Bun is installed: v$BUN_VERSION"
        return 0
    fi

    # Check common install locations
    if [ -x "$HOME/.bun/bin/bun" ]; then
        export PATH="$HOME/.bun/bin:$PATH"
        BUN_VERSION=$(bun --version 2>/dev/null || echo "unknown")
        success "Bun found at ~/.bun/bin: v$BUN_VERSION"
        return 0
    fi

    return 1
}

install_bun() {
    info "Installing Bun runtime..."
    if curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1; then
        export PATH="$HOME/.bun/bin:$PATH"
        BUN_VERSION=$(bun --version 2>/dev/null || echo "unknown")
        success "Bun installed: v$BUN_VERSION"
        return 0
    else
        fail "Failed to install Bun. Please install manually: https://bun.sh"
    fi
}

# Check/install Bun
if ! check_bun_installed; then
    warn "Bun is not installed"
    install_bun
fi

# Show which bun binary will be used (debug friendly)
info "Bun binary: $(command -v bun)"

# Unique name
FN_NAME="starter-bun-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"

# 1. Deploy function with Bun runtime
info "Deploying TypeScript function: $FN_NAME"
info "  Code: $SCRIPT_DIR/code"
info "  Runtime: bun"

if $CLI fn deploy "$FN_NAME" --code "$SCRIPT_DIR/code" -r bun --handler handler:main > /dev/null 2>&1; then
    success "Function deployed with Bun runtime"
else
    fail "Failed to deploy function"
fi

# 2. Verify deployment
info "Verifying deployment..."
FN_JSON=$($CLI -o json fn get "$FN_NAME")
RUNTIME=$(echo "$FN_JSON" | jq -r '.spec.runtime')
HANDLER=$(echo "$FN_JSON" | jq -r '.spec.handler')

info "  Runtime: $RUNTIME"
info "  Handler: $HANDLER"

if [[ "$RUNTIME" == bun* ]]; then
    success "Runtime verified: $RUNTIME"
else
    fail "Unexpected runtime: $RUNTIME (expected: bun*)"
fi

# 3. Invoke with greet operation
info "Invoking function (greet operation)..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{"operation": "greet", "name": "Bun"}')
MESSAGE=$(echo "$RESULT" | jq -r '.result.output.message')
info "  Result: $MESSAGE"

if [ "$MESSAGE" = "Hello, Bun!" ]; then
    success "Greet operation works"
else
    fail "Unexpected greet result: $MESSAGE"
fi

# 4. Invoke with add operation
info "Invoking function (add operation)..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{"operation": "add", "a": 100, "b": 23}')
ADD_RESULT=$(echo "$RESULT" | jq -r '.result.output.result')
info "  100 + 23 = $ADD_RESULT"

if [ "$ADD_RESULT" = "123" ]; then
    success "Add operation works"
else
    fail "Unexpected add result: $ADD_RESULT"
fi

# 5. Invoke info operation (shows Bun version)
info "Invoking function (info operation)..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{"operation": "info"}')
BUN_VER=$(echo "$RESULT" | jq -r '.result.output.bun_version // "unknown"')
IS_TS=$(echo "$RESULT" | jq -r '.result.output.typescript')
info "  Bun version: $BUN_VER"
info "  TypeScript: $IS_TS"

if [ "$IS_TS" = "true" ]; then
    success "TypeScript execution verified"
else
    warn "TypeScript flag not set (may be runtime limitation)"
fi

echo ""
success "06-bun completed successfully"
info "  Bun runtime supports TypeScript natively"
info "  Use -r bun for JavaScript/TypeScript functions"
info "  Handler format: module:function (e.g., handler:main)"
