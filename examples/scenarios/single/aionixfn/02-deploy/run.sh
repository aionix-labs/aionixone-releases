#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "AionixFn: 02-deploy"

# Prerequisites
check_cli_available
check_server_health

# Unique name
FN_NAME="starter-deploy-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"

# 1. Deploy function (auto-creates if not exists)
info "Deploying function: $FN_NAME"
info "  Code: $SCRIPT_DIR/code"

if $CLI fn deploy "$FN_NAME" --code "$SCRIPT_DIR/code" -r python3.10 --handler handler:handler > /dev/null 2>&1; then
    success "Function deployed"
else
    fail "Failed to deploy function"
fi

# 2. Verify deployment
info "Verifying deployment..."
FN_JSON=$($CLI -o json fn get "$FN_NAME")
NAME=$(echo "$FN_JSON" | jq -r '.metadata.name')
RUNTIME=$(echo "$FN_JSON" | jq -r '.spec.runtime')
HANDLER=$(echo "$FN_JSON" | jq -r '.spec.handler')

info "  Name: $NAME"
info "  Runtime: $RUNTIME"
info "  Handler: $HANDLER"

if [ "$RUNTIME" = "python3.10" ]; then
    success "Runtime verified"
else
    fail "Unexpected runtime: $RUNTIME"
fi

if [ "$HANDLER" = "handler:handler" ]; then
    success "Handler verified"
else
    fail "Unexpected handler: $HANDLER"
fi

# 3. Check version was created
info "Checking versions..."
VERSION_COUNT=$($CLI -o json fn versions "$FN_NAME" | jq 'length')
info "  Found $VERSION_COUNT version(s)"

if [ "$VERSION_COUNT" -ge 1 ]; then
    success "Version created after deploy"
else
    fail "No versions found after deploy"
fi

# 4. Get latest version info
info "Getting latest version info..."
LATEST=$($CLI -o json fn versions "$FN_NAME" | jq -r '.[0].version')
info "  Latest version: $LATEST"

echo ""
success "02-deploy completed successfully"
info "  Deploy creates a new version of the function"
info "  Use 'aio fn deploy' with --code to upload code"
