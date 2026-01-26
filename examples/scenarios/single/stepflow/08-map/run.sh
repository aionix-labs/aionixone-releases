#!/bin/bash
# ============================================================================
# 08-map: Iterate over a collection with map step
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "Stepflow: 08-map"

# Prerequisites
check_cli_available
check_server_health

# Workflow name (unique per run)
WORKFLOW_NAME=$(random_name "starter-map")
DSL_FILE="$SCRIPT_DIR/workflow.json"

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI wf delete \"$WORKFLOW_NAME\" --force 2>/dev/null || true"
fi

# Step 1: Create workflow
info "Creating workflow: $WORKFLOW_NAME"
if ! $CLI wf create "$WORKFLOW_NAME" --dsl "$DSL_FILE" --description "Starter: 08-map"; then
    fail "Failed to create workflow"
fi
success "Workflow created"

# Step 2: Run workflow with array input
info "Running workflow with items=[1,2,3]..."
RUN_OUTPUT=$($CLI wf run "$WORKFLOW_NAME" --data '{"items": [1, 2, 3]}' 2>&1)
RUN_ID=$(echo "$RUN_OUTPUT" | awk '/Run ID:/ {print $3}' | tail -n 1)

if [ -z "$RUN_ID" ]; then
    echo "$RUN_OUTPUT"
    fail "Failed to get run ID"
fi
success "Workflow started: $RUN_ID"

# Step 3: Wait for completion
info "Waiting for completion..."
timeout=60
WAITED=0

while [ $WAITED -lt $timeout ]; do
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

if [ $WAITED -ge $timeout ]; then
    fail "Workflow timed out after ${timeout}s"
fi

# Step 4: Show result
info "Execution result:"
$CLI --output json wf execution "$RUN_ID" | jq '.output // .result // .'

echo ""
success "08-map completed successfully"
