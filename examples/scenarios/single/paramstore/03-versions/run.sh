#!/bin/bash
# ============================================================================
# 03-versions: Parameter version history
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "ParamStore: 03-versions"

# Prerequisites
check_cli_available
check_server_health

# Parameter name (unique per run)
PARAM_NAME="starter/versioned-$(date +%s)-$RANDOM"

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI param delete --type string \"$PARAM_NAME\" --force 2>/dev/null || true"
fi

# Step 1: Create initial version
info "Creating parameter with initial value..."
if $CLI param set --type string "$PARAM_NAME" --value "version-1" >/dev/null; then
    success "Version 1 created"
else
    fail "Failed to create parameter"
fi

# Step 2: Create version 2
info "Updating to version 2..."
if $CLI param set --type string "$PARAM_NAME" --value "version-2" >/dev/null; then
    success "Version 2 created"
else
    fail "Failed to update parameter"
fi

# Step 3: Create version 3
info "Updating to version 3..."
if $CLI param set --type string "$PARAM_NAME" --value "version-3" >/dev/null; then
    success "Version 3 created"
else
    fail "Failed to update parameter"
fi

# Step 4: List all versions
info "Listing version history..."
VERSIONS_JSON=$($CLI param versions --type string "$PARAM_NAME")
VERSION_COUNT=$(echo "$VERSIONS_JSON" | jq '.items | length')
info "Total versions: $VERSION_COUNT"

echo "$VERSIONS_JSON" | jq -r '.items[] | "  v\(.version): \(.value)"'

# Step 5: Retrieve specific version
info "Retrieving version 1..."
V1_JSON=$($CLI param version --type string "$PARAM_NAME" 1)
V1_VALUE=$(echo "$V1_JSON" | jq -r '.value')
if [[ "$V1_VALUE" == "version-1" ]]; then
    success "Version 1 retrieved: $V1_VALUE"
else
    fail "Expected 'version-1', got '$V1_VALUE'"
fi

# Step 6: Verify current (latest) version
info "Verifying current version..."
CURRENT_JSON=$($CLI param versions --type string "$PARAM_NAME")
CURRENT_VALUE=$(echo "$CURRENT_JSON" | jq -r '.items[0].value')
if [[ "$CURRENT_VALUE" == "version-3" ]]; then
    success "Current version is latest: $CURRENT_VALUE"
else
    fail "Expected 'version-3', got '$CURRENT_VALUE'"
fi

echo ""
success "03-versions completed successfully"
