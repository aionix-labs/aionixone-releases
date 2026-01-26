#!/bin/bash
# ============================================================================
# 10-task-retry: Retry behavior when a task fails
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "Stepflow: 10-task-retry"

# Prerequisites
check_cli_available
check_server_health

# Check if Bun is installed
check_bun_installed() {
    if command -v bun &> /dev/null; then
        BUN_VERSION=$(bun --version 2>/dev/null || echo "unknown")
        success "Bun is installed: v$BUN_VERSION"
        return 0
    fi

    if [ -x "$HOME/.bun/bin/bun" ]; then
        export PATH="$HOME/.bun/bin:$PATH"
        BUN_VERSION=$(bun --version 2>/dev/null || echo "unknown")
        success "Bun found at ~/.bun/bin: v$BUN_VERSION"
        return 0
    fi

    return 1
}

install_bun() {
    info "Installing Bun runtime..."
    if curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1; then
        export PATH="$HOME/.bun/bin:$PATH"
        BUN_VERSION=$(bun --version 2>/dev/null || echo "unknown")
        success "Bun installed: v$BUN_VERSION"
        return 0
    else
        fail "Failed to install Bun. Please install manually: https://bun.sh"
    fi
}

if ! check_bun_installed; then
    warn "Bun is not installed"
    install_bun
fi

# Deploy Bun function for the task
FN_NAME=$(random_name "starter-stepflow-bun")
FN_CODE_DIR="$SCRIPT_DIR/../common/bun-task/code"

register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"

info "Deploying Bun function: $FN_NAME"
if ! $CLI fn deploy "$FN_NAME" --code "$FN_CODE_DIR" -r bun --handler handler:main > /dev/null 2>&1; then
    fail "Failed to deploy Bun function"
fi
success "Function deployed"

# Workflow name (unique per run)
WORKFLOW_NAME=$(random_name "starter-task-retry")
DSL_TEMPLATE="$SCRIPT_DIR/workflow.json"
DSL_FILE="$(mktemp "${TMPDIR:-/tmp}/stepflow-bun-10-XXXX.json")"
sed "s/__FUNCTION_NAME__/$FN_NAME/g" "$DSL_TEMPLATE" > "$DSL_FILE"
register_cleanup "rm -f \"$DSL_FILE\""

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI wf delete \"$WORKFLOW_NAME\" --force 2>/dev/null || true"
fi

# Step 1: Create workflow
info "Creating workflow: $WORKFLOW_NAME"
if ! $CLI wf create "$WORKFLOW_NAME" --dsl "$DSL_FILE" --description "Starter: 10-task-retry"; then
    fail "Failed to create workflow"
fi
success "Workflow created"

# Step 2: Run workflow
info "Running workflow with retry policy (expected to fail after retries)..."
info "  - maxAttempts: 3"
info "  - intervalSeconds: 1"
info "  - backoffRate: 2.0"
RUN_OUTPUT=$($CLI wf run "$WORKFLOW_NAME" --data '{}' 2>&1)
RUN_ID=$(echo "$RUN_OUTPUT" | awk '/Run ID:/ {print $3}' | tail -n 1)

if [ -z "$RUN_ID" ]; then
    echo "$RUN_OUTPUT"
    fail "Failed to get run ID"
fi
success "Workflow started: $RUN_ID"

# Step 3: Wait for completion
info "Waiting for completion..."
timeout=30
WAITED=0

while [ $WAITED -lt $timeout ]; do
    STATUS=$($CLI --output json wf execution "$RUN_ID" 2>/dev/null | jq -r '.status // empty' || echo '')
    STATUS=$(echo "$STATUS" | tr "[:upper:]" "[:lower:]")

    case "$STATUS" in
        succeeded)
            fail "Workflow completed unexpectedly: $STATUS"
            ;;
        failed)
            success "Workflow ended with expected status: $STATUS"
            break
            ;;
        cancelled|timeout)
            fail "Workflow ended with status: $STATUS"
            ;;
        *)
            sleep 1
            WAITED=$((WAITED + 1))
            ;;
    esac
done

if [ $WAITED -ge $timeout ]; then
    fail "Workflow timed out after ${timeout}s"
fi

# Step 4: Show result
info "Execution result:"
$CLI --output json wf execution "$RUN_ID" | jq '.error // .output // .result // .'

echo ""
success "10-task-retry completed successfully"
