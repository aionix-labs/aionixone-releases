#!/bin/bash
# ============================================================================
# 12-wait-signal: Workflow that waits for an external signal
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "Stepflow: 12-wait-signal"

# Prerequisites
check_cli_available
check_server_health

# Workflow name (unique per run)
WORKFLOW_NAME=$(random_name "starter-wait-signal")
DSL_FILE="$SCRIPT_DIR/workflow.json"

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI wf delete \"$WORKFLOW_NAME\" --force 2>/dev/null || true"
fi

# Step 1: Create workflow
info "Creating workflow: $WORKFLOW_NAME"
if ! $CLI wf create "$WORKFLOW_NAME" --dsl "$DSL_FILE" --description "Starter: 12-wait-signal"; then
    fail "Failed to create workflow"
fi
success "Workflow created"

# Step 2: Run workflow
info "Running workflow..."
RUN_OUTPUT=$($CLI wf run "$WORKFLOW_NAME" --data '{}' 2>&1)
RUN_ID=$(echo "$RUN_OUTPUT" | awk '/Run ID:/ {print $3}' | tail -n 1)

if [ -z "$RUN_ID" ]; then
    echo "$RUN_OUTPUT"
    fail "Failed to get run ID"
fi
success "Workflow started: $RUN_ID"

# Step 3: Wait for execution to enter WAITING
info "Waiting for execution to enter WAITING state..."
WAIT_TIMEOUT=30
WAITED=0

while [ $WAITED -lt $WAIT_TIMEOUT ]; do
    STATUS=$($CLI --output json wf execution "$RUN_ID" 2>/dev/null | jq -r '.status // empty' || echo '')
    STATUS=$(echo "$STATUS" | tr "[:upper:]" "[:lower:]")

    if [ "$STATUS" = "waiting" ]; then
        success "Execution is waiting for signal"
        break
    fi

    sleep 1
    WAITED=$((WAITED + 1))
 done

if [ $WAITED -ge $WAIT_TIMEOUT ]; then
    fail "Execution did not enter WAITING state"
fi

# Step 4: Send signal
info "Sending approval signal..."
if ! $CLI wf signal "$RUN_ID" approved --data '{"approved": true}' >/dev/null; then
    fail "Failed to send signal"
fi
success "Signal sent"

# Step 5: Wait for completion
info "Waiting for completion..."
TIMEOUT=30
WAITED=0

while [ $WAITED -lt $TIMEOUT ]; do
    STATUS=$($CLI --output json wf execution "$RUN_ID" 2>/dev/null | jq -r '.status // empty' || echo '')
    STATUS=$(echo "$STATUS" | tr "[:upper:]" "[:lower:]")

    case "$STATUS" in
        succeeded)
            success "Workflow completed: $STATUS"
            break
            ;;
        failed|cancelled|timeout)
            fail "Workflow ended with status: $STATUS"
            ;;
        *)
            sleep 1
            WAITED=$((WAITED + 1))
            ;;
    esac
 done

if [ $WAITED -ge $TIMEOUT ]; then
    fail "Workflow timed out after ${TIMEOUT}s"
fi

# Step 6: Show result
info "Execution result:"
$CLI --output json wf execution "$RUN_ID" | jq '.output // .result // .'

echo ""
success "12-wait-signal completed successfully"
