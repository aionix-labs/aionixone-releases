#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../common/helpers.sh"

header "ActionHub: Function Samples (hub install + invoke)"

check_cli_available
check_server_health

ACTIONHUB_DIR="$(cd "$SCRIPT_DIR/../../../../actionhub/function-samples" && pwd)"
if [ ! -d "$ACTIONHUB_DIR" ]; then
    fail "ActionHub package not found: $ACTIONHUB_DIR"
fi

info "Installing ActionHub package: function-samples"
$CLI hub install "$ACTIONHUB_DIR" --yes

info "Invoking function: hello-python"
$CLI fn invoke "hello-python" -d '{"name":"ActionHub"}'

echo ""
success "ActionHub function sample completed"
