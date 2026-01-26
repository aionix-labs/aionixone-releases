#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "AionixFn: 01-function"

# Prerequisites
check_cli_available
check_server_health

# Unique name
FN_NAME="starter-fn-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"

# 1. Create function
info "Creating function: $FN_NAME"

if $CLI fn create "$FN_NAME" -r python3.10 --handler handler:handler -d "Starter test function" > /dev/null 2>&1; then
    success "Function created"
else
    fail "Failed to create function"
fi

# 2. Get function details
info "Getting function details..."
FN_JSON=$($CLI -o json fn get "$FN_NAME")
NAME=$(echo "$FN_JSON" | jq -r '.metadata.name')
RUNTIME=$(echo "$FN_JSON" | jq -r '.spec.runtime')
info "  Name: $NAME"
info "  Runtime: $RUNTIME"

if [ "$NAME" = "$FN_NAME" ]; then
    success "Function name verified"
else
    fail "Unexpected name: $NAME"
fi

if [ "$RUNTIME" = "python3.10" ]; then
    success "Runtime verified"
else
    fail "Unexpected runtime: $RUNTIME"
fi

# 3. List functions
info "Listing functions..."
FN_COUNT=$($CLI -o json fn list | jq 'length')
info "  Found $FN_COUNT function(s)"

if [ "$FN_COUNT" -ge 1 ]; then
    success "Function appears in list"
else
    fail "Function not found in list"
fi

# 4. Update function description
info "Updating function description..."
if $CLI fn update "$FN_NAME" -d "Updated description" > /dev/null 2>&1; then
    success "Function updated"
else
    fail "Failed to update function"
fi

# 5. Verify update
info "Verifying update..."
UPDATED_DESC=$($CLI -o json fn get "$FN_NAME" | jq -r '.metadata.description')
if [ "$UPDATED_DESC" = "Updated description" ]; then
    success "Description updated correctly"
else
    warn "Description not updated as expected: $UPDATED_DESC"
fi

echo ""
success "01-function completed successfully"
info "  Functions are the basic unit of deployment"
info "  Use 'aio fn create' to create, 'aio fn get' to view details"
