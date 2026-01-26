#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "AionixFn: 05-layer (v0.2.0 - ZIP upload)"

# Prerequisites
check_cli_available
check_server_health

# Unique names
LAYER_NAME="starter-layer-$(date +%s)-$RANDOM"
FN_NAME="starter-layer-fn-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"
register_cleanup "$CLI fn layer delete $LAYER_NAME --force 2>/dev/null || true"
register_cleanup "rm -rf $SCRIPT_DIR/build $SCRIPT_DIR/layer.zip 2>/dev/null || true"

# 1. Create a layer
info "Creating layer: $LAYER_NAME"
if $CLI fn layer create "$LAYER_NAME" -d "Starter layer with requests" > /dev/null 2>&1; then
    success "Layer created"
else
    fail "Failed to create layer"
fi

# 2. Build layer locally (v0.2.0: platform does NOT build)
info "Building layer locally (pip install)..."

BUILD_DIR="$SCRIPT_DIR/build"
SITE_PACKAGES="$BUILD_DIR/python/lib/python3.13/site-packages"
mkdir -p "$SITE_PACKAGES"

# Install dependencies
if python3 -m pip install --quiet -t "$SITE_PACKAGES" requests==2.31.0 2>&1; then
    success "Dependencies installed to $SITE_PACKAGES"
else
    fail "Failed to install dependencies"
fi

# 3. Create ZIP file
info "Creating layer ZIP..."
LAYER_ZIP="$SCRIPT_DIR/layer.zip"
(cd "$BUILD_DIR" && zip -qr "$LAYER_ZIP" python/)

ZIP_SIZE=$(stat -f%z "$LAYER_ZIP" 2>/dev/null || stat -c%s "$LAYER_ZIP" 2>/dev/null)
ZIP_SIZE_MB=$(echo "scale=2; $ZIP_SIZE / 1048576" | bc)
info "  ZIP size: ${ZIP_SIZE_MB} MB"
success "Layer ZIP created"

# 4. Publish layer version with ZIP upload
info "Publishing layer version (--zip upload)..."
if $CLI fn layer publish "$LAYER_NAME" --zip "$LAYER_ZIP" -R python3.13 > /dev/null 2>&1; then
    success "Layer version published"
else
    fail "Failed to publish layer version"
fi

# 5. Check layer status
info "Checking layer version status..."
VERSIONS_JSON=$($CLI -o json fn layer versions "$LAYER_NAME")
VERSION_STATUS=$(echo "$VERSIONS_JSON" | jq -r '.[0].status')
VERSION_ID=$(echo "$VERSIONS_JSON" | jq -r '.[0].version')
info "  Version: $VERSION_ID"
info "  Status: $VERSION_STATUS"

if [ "$VERSION_STATUS" = "ready" ]; then
    success "Layer ready immediately (no server-side build)"
else
    warn "Layer status is $VERSION_STATUS (expected: ready)"
fi

# 6. Get artifact info
ARTIFACT_SIZE=$(echo "$VERSIONS_JSON" | jq -r '.[0].artifact.compressedSize // 0')
UNCOMPRESSED_SIZE=$(echo "$VERSIONS_JSON" | jq -r '.[0].artifact.uncompressedSize // 0')

if [ "$ARTIFACT_SIZE" != "0" ] && [ "$ARTIFACT_SIZE" != "null" ]; then
    SIZE_MB=$(echo "scale=2; $ARTIFACT_SIZE / 1048576" | bc)
    UNCOMPRESSED_MB=$(echo "scale=2; $UNCOMPRESSED_SIZE / 1048576" | bc)
    info "  Compressed size: ${SIZE_MB} MB"
    info "  Uncompressed size: ${UNCOMPRESSED_MB} MB"
    success "Artifact stored"
else
    warn "No artifact info available"
fi

# 7. Deploy function that uses the layer
info "Deploying function with layer..."

# Get the layer version TRN
LAYER_VERSION_TRN=$($CLI -o json fn layer versions "$LAYER_NAME" | jq -r '.[0].trn')
info "  Layer version TRN: $LAYER_VERSION_TRN"

# Deploy function with explicit layer reference
if $CLI fn deploy "$FN_NAME" --code "$SCRIPT_DIR/code" -r python3.13 --handler handler:handler --layers "$LAYER_VERSION_TRN" > /dev/null 2>&1; then
    success "Function deployed with layer"
else
    fail "Failed to deploy function"
fi

# 8. Invoke function
info "Invoking function (uses requests library from layer)..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{"url": "https://httpbin.org/get"}' 2>&1 || echo '{"error":"invoke failed"}')
echo "DEBUG: Result = $RESULT" >&2

# Check if invocation succeeded (result should contain status code)
if echo "$RESULT" | jq -e '.result.output.status_code' > /dev/null 2>&1; then
    STATUS_CODE=$(echo "$RESULT" | jq -r '.result.output.status_code')
    info "  HTTP response status: $STATUS_CODE"
    if [ "$STATUS_CODE" = "200" ]; then
        success "Function invoked successfully using layer dependency"
    else
        warn "Unexpected status code: $STATUS_CODE"
    fi
else
    # Layer attachment should work now - if not, it's a real error
    fail "Invocation failed - layer may not have loaded correctly"
    info "  Result: $(echo "$RESULT" | head -c 200)"
fi

echo ""
success "05-layer completed successfully"
info "  v0.2.0: Platform does NOT build layers"
info "  Users build locally: pip install -t ./python/lib/pythonX.X/site-packages -r requirements.txt"
info "  Upload pre-built ZIP: aio fn layer publish <name> --zip layer.zip"
