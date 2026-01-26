#!/bin/bash
# ============================================================================
# 02-json-param: JSON parameter for structured configuration
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "ParamStore: 02-json-param"

# Prerequisites
check_cli_available
check_server_health

# Parameter name (unique per run)
PARAM_NAME="starter/config-$(date +%s)-$RANDOM"

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI param delete --type json \"$PARAM_NAME\" --force 2>/dev/null || true"
fi

# Step 1: Create JSON parameter
info "Creating JSON parameter: $PARAM_NAME"
JSON_VALUE='{"enabled":true,"threshold":42,"features":["auth","logging"]}'
if $CLI param set --type json "$PARAM_NAME" --value "$JSON_VALUE" >/dev/null; then
    success "JSON parameter created"
else
    fail "Failed to create parameter"
fi

# Step 2: Read and verify structure
info "Reading parameter..."
VERSIONS_JSON=$($CLI param versions --type json "$PARAM_NAME")
ENABLED=$(echo "$VERSIONS_JSON" | jq -r '.items[0].value.enabled')
THRESHOLD=$(echo "$VERSIONS_JSON" | jq -r '.items[0].value.threshold')

info "Configuration:"
info "  enabled: $ENABLED"
info "  threshold: $THRESHOLD"

if [[ "$ENABLED" == "true" ]] && [[ "$THRESHOLD" == "42" ]]; then
    success "JSON structure verified"
else
    fail "JSON structure mismatch"
fi

# Step 3: Update with new structure
info "Updating configuration..."
UPDATED_JSON='{"enabled":false,"threshold":100,"features":["auth","logging","metrics"]}'
if $CLI param set --type json "$PARAM_NAME" --value "$UPDATED_JSON" >/dev/null; then
    success "Configuration updated"
else
    fail "Failed to update parameter"
fi

# Step 4: Verify update
info "Verifying updated configuration..."
VERSIONS_JSON=$($CLI param versions --type json "$PARAM_NAME")
ENABLED=$(echo "$VERSIONS_JSON" | jq -r '.items[0].value.enabled')
THRESHOLD=$(echo "$VERSIONS_JSON" | jq -r '.items[0].value.threshold')

info "Updated configuration:"
info "  enabled: $ENABLED"
info "  threshold: $THRESHOLD"

if [[ "$ENABLED" == "false" ]] && [[ "$THRESHOLD" == "100" ]]; then
    success "Updated structure verified"
else
    fail "Update verification failed"
fi

echo ""
success "02-json-param completed successfully"
