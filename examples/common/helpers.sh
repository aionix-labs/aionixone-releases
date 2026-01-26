#!/bin/bash
# ============================================================================
# Common helper functions for AionixOne Starter scenarios
# Usage: source "$SCRIPT_DIR/../../common/helpers.sh"
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Project root directory
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -z "$SCRIPT_SOURCE" ] || [ "$SCRIPT_SOURCE" = "bash" ] || [ "$SCRIPT_SOURCE" = "sh" ]; then
    if command -v git >/dev/null 2>&1; then
        PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    else
        PROJECT_ROOT="$(pwd)"
    fi
else
    PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")/../.." && pwd)"
fi

# Load optional env files (for CLI path and settings)
ENV_FILE="${PROJECT_ROOT}/.env"
AIONIX_HOME="${AIONIX_HOME:-$HOME/.aionixone}"
AIONIX_ENV_FILE="${AIONIX_ENV_FILE:-$AIONIX_HOME/env}"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi
if [ -f "$AIONIX_ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$AIONIX_ENV_FILE"
fi

# CLI path (can be overridden via environment variable or .env)
CLI="${CLI:-aio}"

# Environment
DEFAULT_HOST="${AIONIX_HOST:-127.0.0.1}"
DEFAULT_PORT="${AIONIX_PORT:-53000}"
AIONIX_API_BASE="${AIONIX_API_BASE:-http://${DEFAULT_HOST}:${DEFAULT_PORT}}"
KEEP_RESOURCES="${KEEP_RESOURCES:-false}"

# ============================================================================
# Credential Resolution (AWS CLI-style priority)
# ============================================================================
# Priority order:
#   1. AIONIX_API_KEY environment variable (already set)
#   2. data/.admin-api-key (bootstrap file; reliable for local dev/tests)
#   3. ~/.aionix/credentials [default] profile
#
# Note: The aio CLI handles this automatically. This is for shell scripts
# that need the API key directly.
# ============================================================================

resolve_api_key() {
    # 1. Prefer community env file (created by scripts/setup.sh) unless disabled
    if [ -f "$AIONIX_ENV_FILE" ] && [ -z "${AIONIX_API_KEY_NO_BOOTSTRAP:-}" ]; then
        # shellcheck disable=SC1090
        source "$AIONIX_ENV_FILE"
        if [ -n "${AIONIX_API_KEY:-}" ]; then
            return 0
        fi
    fi

    # 2. Check if already set via environment
    if [ -n "${AIONIX_API_KEY:-}" ]; then
        return 0
    fi

    # 3. Try ~/.aionix/credentials [default] profile
    local CREDS_FILE="$HOME/.aionix/credentials"
    if [ -f "$CREDS_FILE" ]; then
        # Parse TOML: extract api_key from [default] section
        local key=$(awk '
            /^\[default\]/ { in_default=1; next }
            /^\[/ { in_default=0 }
            in_default && /^api_key/ { gsub(/.*= *"?|"?$/, ""); print; exit }
        ' "$CREDS_FILE")
        if [ -n "$key" ]; then
            export AIONIX_API_KEY="$key"
            return 0
        fi
    fi

    # No credentials found
    return 1
}

# Auto-resolve API key when helpers.sh is sourced
resolve_api_key

# Ensure AIONIX_API_KEY is exported
export AIONIX_API_KEY="${AIONIX_API_KEY:-}"

# Cleanup registry
CLEANUP_CMDS=""

# ============================================================================
# Output helpers
# ============================================================================

info() {
    echo -e "${BLUE}→${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
}

# ============================================================================
# CLI helpers
# ============================================================================

check_cli_available() {
    if ! command -v "$CLI" &> /dev/null; then
        fail "CLI not found: $CLI"
    fi
    success "CLI available: $CLI"
}

check_server_health() {
    local url="${AIONIX_API_BASE%/}/health"

    if curl -sf "$url" > /dev/null 2>&1; then
        success "server is healthy (${AIONIX_API_BASE})"
        return 0
    else
        fail "server is not responding at $url"
    fi
}

# ============================================================================
# Resource helpers
# ============================================================================

random_name() {
    local prefix="${1:-starter}"
    echo "${prefix}-$(date +%s)-$RANDOM"
}

register_cleanup() {
    if [ "$KEEP_RESOURCES" = "true" ]; then
        info "KEEP_RESOURCES=true, cleanup skipped: $1"
        return
    fi
    if [ -z "$CLEANUP_CMDS" ]; then
        CLEANUP_CMDS="$1"
    else
        CLEANUP_CMDS="$CLEANUP_CMDS; $1"
    fi
}

run_cleanup() {
    if [ -n "$CLEANUP_CMDS" ]; then
        info "Cleaning up resources..."
        eval "$CLEANUP_CMDS" 2>/dev/null || true
    fi
}

# Set trap for automatic cleanup
trap run_cleanup EXIT

# ============================================================================
# Wait helpers
# ============================================================================

wait_for() {
    local cmd="$1"
    local timeout="${2:-30}"
    local interval="${3:-1}"
    local msg="${4:-Waiting...}"

    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if eval "$cmd" > /dev/null 2>&1; then
            return 0
        fi
        sleep $interval
        ((elapsed += interval))
    done
    return 1
}

# ============================================================================
# JSON helpers
# ============================================================================

json_get() {
    local json="$1"
    local path="$2"
    echo "$json" | jq -r "$path"
}

json_has() {
    local json="$1"
    local path="$2"
    echo "$json" | jq -e "$path" > /dev/null 2>&1
}
