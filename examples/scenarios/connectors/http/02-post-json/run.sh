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
echo -e "${BLUE}  HTTP Connector: 02-post-json${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Find CLI
CLI="${AIO_CLI:-aio}"
if ! command -v "$CLI" &> /dev/null; then
    CLI="./apps/aio-cli/target/release/aio"
fi
print_ok "CLI available: $CLI"

# Health check
if ! curl -sf http://localhost:53000/health > /dev/null 2>&1; then
    print_fail "aionix-server is not healthy"
    exit 1
fi
print_ok "aionix-server is healthy (port 53000)"

# Unique names
TIMESTAMP=$(date +%s)
RANDOM_SUFFIX=$RANDOM
CONN_NAME="starter-post-conn-${TIMESTAMP}-${RANDOM_SUFFIX}"
ACTION_NAME="starter-post-action-${TIMESTAMP}-${RANDOM_SUFFIX}"

cleanup() {
    print_step "Cleaning up resources..."
    $CLI act delete "http/$ACTION_NAME" --force 2>/dev/null || true
    $CLI act conn delete "http/$CONN_NAME" --force 2>/dev/null || true
}
trap cleanup EXIT

# 1. Create HTTP connection
print_step "Creating HTTP connection: $CONN_NAME"
CONN_CONFIG=$(cat <<'EOF'
{
  "baseUrl": "https://httpbin.org",
  "headers": {
    "Content-Type": "application/json"
  }
}
EOF
)

if ! $CLI act conn create "$CONN_NAME" -t http --config "$CONN_CONFIG" -o json > /dev/null 2>&1; then
    print_fail "Failed to create connection"
    exit 1
fi
print_ok "Connection created"

# 2. Create POST action
print_step "Creating POST action: $ACTION_NAME"
ACTION_CONFIG=$(cat <<'EOF'
{
  "method": "POST",
  "path": "/post",
  "requestBody": {
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "properties": {
            "message": {"type": "string"},
            "count": {"type": "integer"}
          }
        }
      }
    }
  },
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

# 3. Execute POST with JSON body
print_step "Executing POST with JSON body..."
INPUT_DATA='{"message": "Hello from AionixOne", "count": 42}'
RESULT=$($CLI act execute "http/$ACTION_NAME" -d "$INPUT_DATA" -o json 2>&1)

# httpbin.org/post echoes back the JSON in the response
if echo "$RESULT" | grep -q '"message".*Hello from AionixOne'; then
    print_ok "Request body echoed in response"
    print_step "  message: Hello from AionixOne"
else
    # Check for any successful response
    if echo "$RESULT" | grep -q '"status".*200'; then
        print_ok "POST successful (status 200)"
    else
        print_fail "Unexpected response: $RESULT"
        exit 1
    fi
fi

if echo "$RESULT" | grep -q '"count".*42'; then
    print_step "  count: 42"
fi

echo ""
print_ok "02-post-json completed successfully"
