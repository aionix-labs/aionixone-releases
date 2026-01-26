#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../common/helpers.sh"
source "$SCRIPT_DIR/../../helpers.sh"

header "Igniter: webhook -> aionixfn"

check_cli_available
check_server_health

TRIGGER_NAME="$(random_name starter-webhook-fn)"
FN_NAME="$(random_name starter-igniter-fn)"
WEBHOOK_PATH="/hooks/$(random_name igniter-fn)"
CODE_DIR="$SCRIPT_DIR/../../../aionixfn/03-invoke/code"

register_cleanup "$CLI tr delete 'webhook/$TRIGGER_NAME' --force 2>/dev/null || true"
register_cleanup "$CLI fn delete $FN_NAME --force 2>/dev/null || true"

info "Deploying function: $FN_NAME"
if $CLI fn deploy "$FN_NAME" --code "$CODE_DIR" -r python3.10 --handler handler:handler > /dev/null 2>&1; then
    success "Function deployed"
else
    fail "Failed to deploy function"
fi

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
  "target": "trn:aionixfn:default:function/$FN_NAME:invoke",
  "input": {"operation": "echo", "data": "$.body"}
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
RESPONSE=$(curl -s -X POST "http://${AIONIX_HOST}:${AIONIX_PORT}${WEBHOOK_URL}" \
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
INVOKE_STATUS=$(echo "$EXEC_JSON" | jq -r '.targetResult.status // empty')

case "$INVOKE_STATUS" in
    pending|running|succeeded)
        success "Invoke routed via /api/invoke (status: $INVOKE_STATUS)"
        ;;
    *)
        fail "Unexpected invoke status: $INVOKE_STATUS"
        ;;
esac

echo ""
success "webhook -> aionixfn completed successfully"
