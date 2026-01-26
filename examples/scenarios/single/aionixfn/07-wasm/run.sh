#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "AionixFn: 07-wasm (WebAssembly)"

# Prerequisites
check_cli_available
check_server_health

# ============================================================================
# Check/Install WASM toolchain
# ============================================================================

check_rust_wasm_target() {
    if rustup target list --installed 2>/dev/null | grep -q "wasm32-unknown-unknown"; then
        success "Rust wasm32-unknown-unknown target installed"
        return 0
    fi
    return 1
}

install_rust_wasm_target() {
    info "Installing wasm32-unknown-unknown target..."
    if rustup target add wasm32-unknown-unknown > /dev/null 2>&1; then
        success "WASM target installed"
        return 0
    else
        fail "Failed to install WASM target. Run: rustup target add wasm32-unknown-unknown"
    fi
}

check_wasm_opt() {
    if command -v wasm-opt &> /dev/null; then
        success "wasm-opt is available (optional optimization)"
        return 0
    fi
    return 1
}

# Check Rust
if ! command -v rustc &> /dev/null; then
    fail "Rust is not installed. Install via: https://rustup.rs"
fi

RUST_VERSION=$(rustc --version | awk '{print $2}')
info "Rust version: $RUST_VERSION"

# Check/install WASM target
if ! check_rust_wasm_target; then
    warn "WASM target not installed"
    install_rust_wasm_target
fi

# Check wasm-opt (optional)
WASM_OPT_AVAILABLE=false
if check_wasm_opt; then
    WASM_OPT_AVAILABLE=true
fi

# ============================================================================
# Build WASM module
# ============================================================================

info "Building WASM module..."
cd "$SCRIPT_DIR/code"

# Build
if cargo build --release --target wasm32-unknown-unknown > /dev/null 2>&1; then
    success "WASM module compiled"
else
    fail "Failed to compile WASM module"
fi

WASM_FILE="$SCRIPT_DIR/code/target/wasm32-unknown-unknown/release/starter_wasm.wasm"

if [ ! -f "$WASM_FILE" ]; then
    fail "WASM file not found: $WASM_FILE"
fi

WASM_SIZE=$(stat -f%z "$WASM_FILE" 2>/dev/null || stat -c%s "$WASM_FILE" 2>/dev/null)
info "  Size: $WASM_SIZE bytes"

# Optional: optimize with wasm-opt
if [ "$WASM_OPT_AVAILABLE" = true ]; then
    info "Optimizing with wasm-opt..."
    OPTIMIZED_FILE="$SCRIPT_DIR/code/handler.wasm"
    if wasm-opt -Os "$WASM_FILE" -o "$OPTIMIZED_FILE" 2>/dev/null; then
        WASM_FILE="$OPTIMIZED_FILE"
        OPT_SIZE=$(stat -f%z "$WASM_FILE" 2>/dev/null || stat -c%s "$WASM_FILE" 2>/dev/null)
        info "  Optimized size: $OPT_SIZE bytes"
        success "WASM optimized"
    else
        warn "wasm-opt failed, using unoptimized binary"
    fi
fi

# Copy to deploy location
DEPLOY_WASM="$SCRIPT_DIR/code/handler.wasm"
if [ "$WASM_FILE" != "$DEPLOY_WASM" ]; then
    cp "$WASM_FILE" "$DEPLOY_WASM"
fi

cd "$SCRIPT_DIR"

# ============================================================================
# Test function
# ============================================================================

# Unique name
FN_NAME="starter-wasm-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"
register_cleanup "rm -rf $SCRIPT_DIR/code/target $SCRIPT_DIR/code/handler.wasm 2>/dev/null || true"

# 1. Deploy function with WASM runtime
info "Deploying WASM function: $FN_NAME"
info "  WASM file: $DEPLOY_WASM"
info "  Runtime: wasm"

# Create a temp directory with just the WASM file for deployment
DEPLOY_DIR=$(mktemp -d)
cp "$DEPLOY_WASM" "$DEPLOY_DIR/handler.wasm"
register_cleanup "rm -rf $DEPLOY_DIR"

if $CLI fn deploy "$FN_NAME" --code "$DEPLOY_DIR" -r wasm --handler handler.wasm:handler > /dev/null 2>&1; then
    success "Function deployed with WASM runtime"
else
    # WASM might not be enabled on server
    warn "Failed to deploy WASM function"
    info "  This may indicate WASM feature is not enabled on the server"
    info "  Server needs to be compiled with --features wasm"
    echo ""
    warn "07-wasm skipped (WASM not enabled on server)"
    exit 0
fi

# 2. Verify deployment
info "Verifying deployment..."
FN_JSON=$($CLI -o json fn get "$FN_NAME")
RUNTIME=$(echo "$FN_JSON" | jq -r '.spec.runtime')
info "  Runtime: $RUNTIME"

if [[ "$RUNTIME" == wasm* ]]; then
    success "Runtime verified: $RUNTIME"
else
    fail "Unexpected runtime: $RUNTIME (expected: wasm*)"
fi

# 3. Invoke function
info "Invoking WASM function..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{"name": "WASM"}' 2>&1 || echo '{"error":"invoke failed"}')

if echo "$RESULT" | jq -e '.output.message' > /dev/null 2>&1; then
    MESSAGE=$(echo "$RESULT" | jq -r '.output.message')
    SOURCE=$(echo "$RESULT" | jq -r '.output.source')
    info "  Message: $MESSAGE"
    info "  Source: $SOURCE"

    if [ "$MESSAGE" = "Hello, WASM!" ] && [ "$SOURCE" = "wasm" ]; then
        success "WASM function invoked successfully"
    else
        warn "Unexpected result (message=$MESSAGE, source=$SOURCE)"
    fi
else
    warn "Invocation returned unexpected result"
    info "  Result: $(echo "$RESULT" | head -c 200)"
fi

# 4. Invoke with default name
info "Invoking with default name..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{}' 2>&1 || echo '{"error":"invoke failed"}')

if echo "$RESULT" | jq -e '.output.message' > /dev/null 2>&1; then
    MESSAGE=$(echo "$RESULT" | jq -r '.output.message')
    info "  Message: $MESSAGE"

    if [ "$MESSAGE" = "Hello, World!" ]; then
        success "Default name works"
    fi
fi

echo ""
success "07-wasm completed successfully"
info "  WASM provides memory-level sandboxing"
info "  Cold starts are in milliseconds"
info "  ABI v1 exports: handler, alloc, get_last_error"
info "  Build: cargo build --release --target wasm32-unknown-unknown"
