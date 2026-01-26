#!/bin/bash
# ============================================================================
# 01-string-param: Basic string parameter CRUD
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "ParamStore: 01-string-param"

# Prerequisites
check_cli_available
check_server_health

# Parameter name (unique per run)
PARAM_NAME="starter/string-$(date +%s)-$RANDOM"

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI param delete --type string \"$PARAM_NAME\" --force 2>/dev/null || true"
fi

# Step 1: Create parameter
info "Creating string parameter: $PARAM_NAME"
if $CLI param set --type string "$PARAM_NAME" --value "hello-world" >/dev/null; then
    success "Parameter created"
else
    fail "Failed to create parameter"
fi

# Step 2: Read parameter (using versions to get JSON)
info "Reading parameter value..."
VERSIONS_JSON=$($CLI param versions --type string "$PARAM_NAME")
VALUE=$(echo "$VERSIONS_JSON" | jq -r '.items[0].value')
info "Value: $VALUE"
if [[ "$VALUE" == "hello-world" ]]; then
    success "Parameter read"
else
    fail "Unexpected value: $VALUE"
fi

# Step 3: Update parameter
info "Updating parameter value..."
if $CLI param set --type string "$PARAM_NAME" --value "updated-value" >/dev/null; then
    success "Parameter updated"
else
    fail "Failed to update parameter"
fi

# Step 4: Verify update
info "Verifying updated value..."
VERSIONS_JSON=$($CLI param versions --type string "$PARAM_NAME")
VALUE=$(echo "$VERSIONS_JSON" | jq -r '.items[0].value')
if [[ "$VALUE" == "updated-value" ]]; then
    success "Value verified: $VALUE"
else
    fail "Unexpected value: $VALUE"
fi

# Step 5: List parameters
info "Listing parameters under /starter..."
$CLI param list --prefix starter | head -5

echo ""
success "01-string-param completed successfully"
