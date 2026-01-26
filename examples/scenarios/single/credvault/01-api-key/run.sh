#!/bin/bash
# ============================================================================
# 01-api-key: Basic API key credential CRUD
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "CredVault: 01-api-key"

# Prerequisites
check_cli_available
check_server_health

# Credential name (unique per run)
CRED_NAME="starter-apikey-$(date +%s)-$RANDOM"

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI sec delete \"$CRED_NAME\" -t apiKey --force 2>/dev/null || true"
fi

# Step 1: Create API key credential
info "Creating API key credential: $CRED_NAME"
if $CLI sec create "$CRED_NAME" -t apiKey --value '{"apiKey":"sk-test-12345"}' -d "Starter test API key" >/dev/null; then
    success "Credential created"
else
    fail "Failed to create credential"
fi

# Step 2: Get credential metadata
info "Getting credential metadata..."
CRED_JSON=$($CLI -o json sec get "$CRED_NAME" -t apiKey)
CRED_STATUS=$(echo "$CRED_JSON" | jq -r '.status')
CRED_TYPE=$(echo "$CRED_JSON" | jq -r '.kind')
info "  Status: $CRED_STATUS"
info "  Type: $CRED_TYPE"
if [[ "$CRED_STATUS" == "active" ]] && [[ "$CRED_TYPE" == "credential/apiKey" ]]; then
    success "Metadata verified"
else
    fail "Unexpected metadata: status=$CRED_STATUS, type=$CRED_TYPE"
fi

# Step 3: Reveal secret value
info "Revealing secret value..."
REVEAL_JSON=$($CLI -o json sec reveal "$CRED_NAME" -t apiKey)
API_KEY=$(echo "$REVEAL_JSON" | jq -r '.value.apiKey')
if [[ "$API_KEY" == "sk-test-12345" ]]; then
    success "Secret value verified: ${API_KEY:0:10}..."
else
    fail "Unexpected value: $API_KEY"
fi

# Step 4: List credentials
info "Listing credentials..."
$CLI sec list | head -5

echo ""
success "01-api-key completed successfully"
