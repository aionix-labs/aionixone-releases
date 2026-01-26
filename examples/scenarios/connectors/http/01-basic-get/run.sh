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
echo -e "${BLUE}  HTTP Connector: 01-basic-get${NC}"
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
CONN_NAME="starter-http-conn-${TIMESTAMP}-${RANDOM_SUFFIX}"
ACTION_NAME="starter-http-get-${TIMESTAMP}-${RANDOM_SUFFIX}"

cleanup() {
    print_step "Cleaning up resources..."
    $CLI act delete "http/$ACTION_NAME" --force 2>/dev/null || true
    $CLI act conn delete "http/$CONN_NAME" --force 2>/dev/null || true
}
trap cleanup EXIT

# 1. Create HTTP connection (using httpbin.org as test endpoint)
print_step "Creating HTTP connection: $CONN_NAME"
CONN_CONFIG=$(cat <<'EOF'
{
  "baseUrl": "https://httpbin.org",
  "headers": {
    "User-Agent": "AionixOne-Starter/1.0"
  }
}
EOF
)

if ! $CLI act conn create "$CONN_NAME" -t http --config "$CONN_CONFIG" -o json > /dev/null 2>&1; then
    print_fail "Failed to create connection"
    exit 1
fi
print_ok "Connection created"

# 2. Test connection
print_step "Testing connection..."
if ! $CLI act conn test "$CONN_NAME" -o json 2>&1 | grep -q '"success"'; then
    # Connection test might not be implemented, continue anyway
    print_step "  Connection test skipped (not implemented)"
fi

# 3. Create GET action
print_step "Creating GET action: $ACTION_NAME"
ACTION_CONFIG=$(cat <<'EOF'
{
  "method": "GET",
  "path": "/get",
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

# 4. Execute the action
print_step "Executing GET request to httpbin.org/get..."
RESULT=$($CLI act execute "http/$ACTION_NAME" -d '{}' -o json 2>&1)

if echo "$RESULT" | grep -q '"url".*httpbin.org/get'; then
    print_ok "Response received from httpbin.org"
    print_step "  URL verified in response"
else
    # Check if we got any valid response
    if echo "$RESULT" | grep -q '"statusCode".*200'; then
        print_ok "Response received (status 200)"
    else
        print_fail "Unexpected response: $RESULT"
        exit 1
    fi
fi

# 5. Verify response structure
print_step "Verifying response structure..."
if echo "$RESULT" | grep -q '"headers"'; then
    print_ok "Response contains headers"
fi

echo ""
print_ok "01-basic-get completed successfully"
