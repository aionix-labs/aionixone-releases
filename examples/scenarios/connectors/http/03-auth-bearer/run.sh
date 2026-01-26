#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}→${NC} $1"; }
print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_fail() { echo -e "${RED}✗${NC} $1"; }

# Header
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  HTTP Connector: 03-auth-bearer${NC}"
echo -e "${BLUE}  (CredVault Integration)${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Find CLI
CLI="${AIO_CLI:-aio}"
if ! command -v "$CLI" &> /dev/null; then
    print_fail "aio not found in PATH"
    exit 1
fi
print_ok "CLI available: $CLI"

# Health check
AIONIX_API_BASE="${AIONIX_API_BASE:-http://127.0.0.1:53000}"
if ! curl -sf "${AIONIX_API_BASE%/}/health" > /dev/null 2>&1; then
    print_fail "server is not healthy"
    exit 1
fi
print_ok "server is healthy (${AIONIX_API_BASE})"

# Unique names
TIMESTAMP=$(date +%s)
RANDOM_SUFFIX=$RANDOM
CRED_NAME="starter-bearer-cred-${TIMESTAMP}-${RANDOM_SUFFIX}"
CONN_NAME="starter-auth-conn-${TIMESTAMP}-${RANDOM_SUFFIX}"
ACTION_NAME="starter-auth-action-${TIMESTAMP}-${RANDOM_SUFFIX}"

cleanup() {
    print_step "Cleaning up resources..."
    $CLI act delete "http/$ACTION_NAME" --force 2>/dev/null || true
    $CLI act conn delete "http/$CONN_NAME" --force 2>/dev/null || true
    $CLI sec delete "$CRED_NAME" -t bearer --force 2>/dev/null || true
}
trap cleanup EXIT

# 1. Create bearer credential in CredVault
print_step "Creating bearer credential in CredVault: $CRED_NAME"
if ! $CLI sec create "$CRED_NAME" -t bearer --value '{"token":"test-bearer-token-12345"}' -d "Starter bearer token" > /dev/null 2>&1; then
    print_fail "Failed to create credential"
    exit 1
fi
print_ok "Credential created in CredVault"

# 2. Create HTTP connection with $secret() reference
print_step "Creating HTTP connection with \$secret() expression: $CONN_NAME"

# Use $secret('<name>').token to reference the bearer token
# Note: The secret name must match the credential name (without type prefix)
CONN_CONFIG=$(cat <<EOF
{
  "baseUrl": "https://httpbin.org",
  "auth": {
    "type": "bearer",
    "token": "{% \$secret('$CRED_NAME').token %}"
  }
}
EOF
)

if ! $CLI act conn create "$CONN_NAME" -t http --config "$CONN_CONFIG" -o json > /dev/null 2>&1; then
    print_fail "Failed to create connection"
    exit 1
fi
print_ok "Connection created with \$secret() expression"

# 3. Create action that uses authenticated connection
print_step "Creating action: $ACTION_NAME"
ACTION_CONFIG=$(cat <<'EOF'
{
  "method": "GET",
  "path": "/bearer",
  "response": {
    "successCodes": [200]
  }
}
EOF
)

if ! $CLI act create "$ACTION_NAME" -t http -c "http/$CONN_NAME" --config "$ACTION_CONFIG" -o json > /dev/null 2>&1; then
    print_fail "Failed to create action"
    exit 1
fi
print_ok "Action created"

# 4. Execute - httpbin.org/bearer validates and echoes the token
print_step "Executing authenticated request to /bearer..."
print_step "  (token resolved from CredVault via \$secret() expression)"
RESULT=$($CLI act execute "http/$ACTION_NAME" -d '{}' -o json 2>&1)

# httpbin.org/bearer returns {"authenticated": true, "token": "..."}
if echo "$RESULT" | grep -q '"authenticated".*true'; then
    print_ok "Authentication successful"
    print_step "  authenticated: true"
    print_step "  token: test-bearer-token-... (from CredVault)"
else
    print_fail "Unexpected response: $RESULT"
    exit 1
fi

echo ""
print_ok "03-auth-bearer completed successfully"
print_step "  Demonstrated: CredVault + OpenAct \$secret() integration"
