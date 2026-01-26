#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../common/helpers.sh"
source "$SCRIPT_DIR/../../helpers.sh"

header "Igniter: cron -> openact"

check_cli_available
check_server_health

TRIGGER_NAME="$(random_name starter-cron-act)"
CONN_NAME="$(random_name starter-igniter-conn)"
ACTION_NAME="$(random_name starter-igniter-action)"

register_cleanup "$CLI tr delete 'cron/$TRIGGER_NAME' --force 2>/dev/null || true"
register_cleanup "$CLI act delete 'http/$ACTION_NAME' --force 2>/dev/null || true"
register_cleanup "$CLI act conn delete 'http/$CONN_NAME' --force 2>/dev/null || true"

info "Creating HTTP connection: $CONN_NAME"
CONN_CONFIG='{"baseUrl": "https://httpbin.org"}'
if $CLI act conn create "$CONN_NAME" -t http --config "$CONN_CONFIG" > /dev/null 2>&1; then
    success "Connection created"
else
    fail "Failed to create connection"
fi

info "Creating HTTP action: $ACTION_NAME"
ACTION_CONFIG=$(jq -n '{method: "POST", path: "/post", body: {type: "json", data: null}, response: {successCodes: [200]}}')
if $CLI act create "$ACTION_NAME" -t http -c "http/$CONN_NAME" --config "$ACTION_CONFIG" > /dev/null 2>&1; then
    success "Action created"
else
    fail "Failed to create action"
fi

info "Creating cron trigger: $TRIGGER_NAME"
TRIGGER_CONFIG='{"schedule":"*/1 * * * * *"}'
TRIGGER_ACTION=$(cat <<EOF_ACTION
{
  "target": "trn:openact:default:action/http/$ACTION_NAME:execute",
  "input": {"message": "hello", "source": "igniter-cron"}
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
success "cron -> openact completed successfully"
