#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../common/helpers.sh"
source "$SCRIPT_DIR/../../helpers.sh"

header "Igniter: cron -> stepflow"

check_cli_available
check_server_health

TRIGGER_NAME="$(random_name starter-cron-wf)"
WORKFLOW_NAME="$(random_name starter-igniter-wf)"
DSL_FILE="$SCRIPT_DIR/../../workflows/simple-set.json"

register_cleanup "$CLI tr delete 'cron/$TRIGGER_NAME' --force 2>/dev/null || true"
register_cleanup "$CLI wf delete \"$WORKFLOW_NAME\" --force 2>/dev/null || true"

info "Creating workflow: $WORKFLOW_NAME"
if ! $CLI wf create "$WORKFLOW_NAME" --dsl "$DSL_FILE" --description "Igniter cron workflow" > /dev/null; then
    fail "Failed to create workflow"
fi
success "Workflow created"

info "Creating cron trigger: $TRIGGER_NAME"
TRIGGER_CONFIG='{"schedule":"*/1 * * * * *"}'
TRIGGER_ACTION=$(cat <<EOF_ACTION
{
  "target": "trn:stepflow:default:workflow/$WORKFLOW_NAME:start",
  "input": {"input": "from-igniter-cron"}
}
EOF_ACTION
)

if $CLI tr create "$TRIGGER_NAME" -t cron --config "$TRIGGER_CONFIG" --action "$TRIGGER_ACTION" > /dev/null; then
    success "Cron trigger created"
else
    fail "Failed to create cron trigger"
fi

info "Firing cron trigger manually"
if ! $CLI tr fire "cron/$TRIGGER_NAME" > /dev/null 2>&1; then
    fail "Failed to fire trigger"
fi

info "Waiting for trigger execution to complete"
EXEC_LIST=$(wait_for_trigger_terminal "cron/$TRIGGER_NAME" 30 1) || fail "Trigger execution did not complete"
EXEC_ID=$(echo "$EXEC_LIST" | jq -r '.[0].id')
STATUS=$(echo "$EXEC_LIST" | jq -r '.[0].status')
info "  Execution status: $STATUS"

if [ "$STATUS" != "succeeded" ]; then
    fail "Trigger execution failed with status: $STATUS"
fi

EXEC_JSON=$($CLI -o json tr exec get "$TRIGGER_NAME/$EXEC_ID")
RUN_ID=$(echo "$EXEC_JSON" | jq -r '.targetResult.run_id // empty')

if [ -z "$RUN_ID" ]; then
    fail "Missing workflow run_id in trigger result"
fi
success "Workflow started via trigger: $RUN_ID"

echo ""
success "cron -> stepflow completed successfully"
