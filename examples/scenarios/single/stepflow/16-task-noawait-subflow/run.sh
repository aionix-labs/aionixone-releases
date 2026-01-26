#!/bin/bash
# ==========================================================================
# 16-task-noawait-subflow: Fire-and-forget child workflow success
# ==========================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../common/helpers.sh"

header "Stepflow: 16-task-noawait-subflow"

# Prerequisites
check_cli_available
check_server_health

# Workflow names (unique per run)
CHILD_WORKFLOW=$(random_name "starter-child-ff")
PARENT_WORKFLOW=$(random_name "starter-parent-ff")

CHILD_DSL="$SCRIPT_DIR/workflow-child.json"
PARENT_TEMPLATE="$SCRIPT_DIR/workflow-parent.json"
PARENT_DSL="$(mktemp "${TMPDIR:-/tmp}/stepflow-noawait-16-XXXX.json")"
sed "s/__CHILD_WORKFLOW__/$CHILD_WORKFLOW/g" "$PARENT_TEMPLATE" > "$PARENT_DSL"
register_cleanup "rm -f \"$PARENT_DSL\""

# Cleanup on exit
if [ "$KEEP_RESOURCES" != "true" ]; then
    register_cleanup "$CLI wf delete \"$PARENT_WORKFLOW\" --force 2>/dev/null || true"
    register_cleanup "$CLI wf delete \"$CHILD_WORKFLOW\" --force 2>/dev/null || true"
fi

# Step 1: Create child workflow
info "Creating child workflow: $CHILD_WORKFLOW"
if ! $CLI wf create "$CHILD_WORKFLOW" --dsl "$CHILD_DSL" --description "Starter: 16-task-noawait-subflow child"; then
    fail "Failed to create child workflow"
fi
success "Child workflow created"

# Step 2: Create parent workflow
info "Creating parent workflow: $PARENT_WORKFLOW"
if ! $CLI wf create "$PARENT_WORKFLOW" --dsl "$PARENT_DSL" --description "Starter: 16-task-noawait-subflow parent"; then
    fail "Failed to create parent workflow"
fi
success "Parent workflow created"

# Step 3: Run parent workflow
info "Running parent workflow..."
RUN_OUTPUT=$($CLI wf run "$PARENT_WORKFLOW" --data '{}' 2>&1)
RUN_ID=$(echo "$RUN_OUTPUT" | awk '/Run ID:/ {print $3}' | tail -n 1)

if [ -z "$RUN_ID" ]; then
    echo "$RUN_OUTPUT"
    fail "Failed to get run ID"
fi
success "Parent workflow started: $RUN_ID"

# Step 4: Wait for completion
info "Waiting for completion..."
timeout=30
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

# Step 5: Show result
info "Execution result:"
$CLI --output json wf execution "$RUN_ID" | jq '.output // .result // .'

echo ""
success "16-task-noawait-subflow completed successfully"
