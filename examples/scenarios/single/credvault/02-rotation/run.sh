#!/bin/bash
# ============================================================================
# 02-rotation: Credential rotation and version management
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "CredVault: 02-rotation"

# Prerequisites
check_cli_available
check_server_health

# Credential name (unique per run)
CRED_NAME="starter-rotate-$(date +%s)-$RANDOM"

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI sec delete \"$CRED_NAME\" -t apiKey --force 2>/dev/null || true"
fi

# Step 1: Create initial credential
info "Creating credential with initial value..."
if $CLI sec create "$CRED_NAME" -t apiKey --value '{"apiKey":"key-v1"}' -d "Rotation test" >/dev/null; then
    success "Version 1 created"
else
    fail "Failed to create credential"
fi

# Step 2: Rotate to version 2
info "Rotating to version 2..."
if $CLI sec rotate "$CRED_NAME" -t apiKey --value '{"apiKey":"key-v2"}' --activate >/dev/null; then
    success "Version 2 created and activated"
else
    fail "Failed to rotate credential"
fi

# Step 3: Rotate to version 3
info "Rotating to version 3..."
if $CLI sec rotate "$CRED_NAME" -t apiKey --value '{"apiKey":"key-v3"}' --activate >/dev/null; then
    success "Version 3 created and activated"
else
    fail "Failed to rotate credential"
fi

# Step 4: List versions
info "Listing version history..."
VERSIONS_JSON=$($CLI -o json sec versions "$CRED_NAME" -t apiKey)
VERSION_COUNT=$(echo "$VERSIONS_JSON" | jq '.items | length')
info "Total versions: $VERSION_COUNT"

echo "$VERSIONS_JSON" | jq -r '.items[] | "  v\(.version): \(.status)"'

# Step 5: Verify current value is v3
info "Verifying current value is v3..."
CURRENT_JSON=$($CLI -o json sec reveal "$CRED_NAME" -t apiKey)
CURRENT_KEY=$(echo "$CURRENT_JSON" | jq -r '.value.apiKey')
if [[ "$CURRENT_KEY" == "key-v3" ]]; then
    success "Current value is latest: $CURRENT_KEY"
else
    fail "Expected 'key-v3', got '$CURRENT_KEY'"
fi

# Step 6: Reveal specific version (v1)
info "Revealing version 1 specifically..."
V1_JSON=$($CLI -o json sec reveal "$CRED_NAME" -t apiKey --version 1)
V1_KEY=$(echo "$V1_JSON" | jq -r '.value.apiKey')
if [[ "$V1_KEY" == "key-v1" ]]; then
    success "Version 1 value: $V1_KEY"
else
    fail "Expected 'key-v1', got '$V1_KEY'"
fi

echo ""
success "02-rotation completed successfully"
