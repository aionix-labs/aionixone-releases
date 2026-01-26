#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../common/helpers.sh"
source "$SCRIPT_DIR/../../helpers.sh"

header "Igniter: webhook -> stepflow"

check_cli_available
check_server_health

TRIGGER_NAME="$(random_name starter-webhook-wf)"
WORKFLOW_NAME="$(random_name starter-igniter-wf)"
WEBHOOK_PATH="/hooks/$(random_name igniter-wf)"
DSL_FILE="$SCRIPT_DIR/../../workflows/simple-set.json"

register_cleanup "$CLI tr delete 'webhook/$TRIGGER_NAME' --force 2>/dev/null || true"
register_cleanup "$CLI wf delete \"$WORKFLOW_NAME\" --force 2>/dev/null || true"

info "Creating workflow: $WORKFLOW_NAME"
if ! $CLI wf create "$WORKFLOW_NAME" --dsl "$DSL_FILE" --description "Igniter webhook workflow" > /dev/null; then
    fail "Failed to create workflow"
fi
success "Workflow created"

info "Creating webhook trigger: $TRIGGER_NAME"
TRIGGER_CONFIG=$(cat <<EOF_CONFIG
{
  "path": "$WEBHOOK_PATH",
  "methods": ["POST"]
}
EOF_CONFIG
)
TRIGGER_ACTION=$(cat <<EOF_ACTION
{
  "target": "trn:stepflow:default:workflow/$WORKFLOW_NAME:start",
  "input": {"input": "from-igniter-webhook", "payload": "$.body"}
}
EOF_ACTION
)

if $CLI tr create "$TRIGGER_NAME" -t webhook --config "$TRIGGER_CONFIG" --action "$TRIGGER_ACTION" > /dev/null; then
    success "Webhook trigger created"
else
    fail "Failed to create webhook trigger"
fi

TRIGGER_JSON=$($CLI -o json tr get "webhook/$TRIGGER_NAME")
WEBHOOK_URL=$(echo "$TRIGGER_JSON" | jq -r '.webhookUrl')
info "Webhook URL: $WEBHOOK_URL"

if [ -z "${AIONIX_API_KEY:-}" ]; then
    fail "AIONIX_API_KEY not set"
fi

info "Firing webhook"
API_BASE="${AIONIX_API_BASE:-http://127.0.0.1:53000}"
RESPONSE=$(curl -s -X POST "${API_BASE%/}${WEBHOOK_URL}" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AIONIX_API_KEY" \
  -d '{"message":"hello"}' 2>&1)

if [ -n "$RESPONSE" ] && ! echo "$RESPONSE" | grep -q '"success"'; then
    fail "Webhook failed: $RESPONSE"
fi
success "Webhook fired"

info "Waiting for trigger execution to complete"
EXEC_LIST=$(wait_for_trigger_terminal "webhook/$TRIGGER_NAME" 30 1) || fail "Trigger execution did not complete"
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
success "webhook -> stepflow completed successfully"
