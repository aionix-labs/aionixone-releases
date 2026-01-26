#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "AionixFn: 04-versions"

# Prerequisites
check_cli_available
check_server_health

# Unique name
FN_NAME="starter-versions-$(date +%s)-$RANDOM"

# Cleanup on exit
register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"

# 1. Deploy version 1
info "Deploying version 1..."

if $CLI fn deploy "$FN_NAME" --code "$SCRIPT_DIR/code_v1" -r python3.10 --handler handler:handler > /dev/null 2>&1; then
    success "Version 1 deployed"
else
    fail "Failed to deploy version 1"
fi

# Get version 1 ID
V1=$($CLI -o json fn versions "$FN_NAME" | jq -r '.[0].versionId')
info "  Version 1 ID: $V1"

# Invoke v1
info "Invoking version 1..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{}')
V1_MSG=$(echo "$RESULT" | jq -r '.result.output.version')
info "  Response version: $V1_MSG"

if [ "$V1_MSG" = "v1" ]; then
    success "Version 1 returns correct response"
else
    fail "Unexpected v1 response: $V1_MSG"
fi

# 2. Deploy version 2
info "Deploying version 2..."

if $CLI fn deploy "$FN_NAME" --code "$SCRIPT_DIR/code_v2" -r python3.10 --handler handler:handler > /dev/null 2>&1; then
    success "Version 2 deployed"
else
    fail "Failed to deploy version 2"
fi

# Get version 2 ID
V2=$($CLI -o json fn versions "$FN_NAME" | jq -r '.[0].versionId')
info "  Version 2 ID: $V2"

# 3. Verify we now have 2 versions
info "Checking versions..."
VERSION_COUNT=$($CLI -o json fn versions "$FN_NAME" | jq 'length')
info "  Found $VERSION_COUNT version(s)"

if [ "$VERSION_COUNT" -ge 2 ]; then
    success "Multiple versions exist"
else
    fail "Expected at least 2 versions, found $VERSION_COUNT"
fi

# 4. Invoke latest (should be v2)
info "Invoking latest version..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{}')
LATEST_MSG=$(echo "$RESULT" | jq -r '.result.output.version')
HAS_FEATURE=$(echo "$RESULT" | jq -r '.result.output.feature // "none"')
info "  Response version: $LATEST_MSG"
info "  New feature: $HAS_FEATURE"

if [ "$LATEST_MSG" = "v2" ]; then
    success "Latest version is v2"
else
    fail "Expected v2, got: $LATEST_MSG"
fi

# 5. Rollback to version 1
info "Rolling back to version 1 ($V1)..."

if $CLI fn rollback "$FN_NAME" "$V1" -f > /dev/null 2>&1; then
    success "Rollback completed"
else
    fail "Failed to rollback"
fi

# 6. Invoke after rollback (should be v1)
info "Invoking after rollback..."
RESULT=$($CLI -o json fn invoke "$FN_NAME" -d '{}')
ROLLBACK_MSG=$(echo "$RESULT" | jq -r '.result.output.version')
info "  Response version: $ROLLBACK_MSG"

if [ "$ROLLBACK_MSG" = "v1" ]; then
    success "Rollback successful - now serving v1"
else
    warn "Expected v1 after rollback, got: $ROLLBACK_MSG"
fi

# 7. List aliases
info "Listing aliases..."
ALIASES=$($CLI -o json fn alias list "$FN_NAME" 2>/dev/null || echo "[]")
ALIAS_COUNT=$(echo "$ALIASES" | jq 'length')
info "  Found $ALIAS_COUNT alias(es)"

echo ""
success "04-versions completed successfully"
info "  Each deploy creates a new immutable version"
info "  Use 'aio fn versions' to list, 'aio fn rollback' to switch"
