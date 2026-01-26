#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../common/helpers.sh"

header "AionixFn: All Scenarios"

SCENARIOS=(
    "01-function"
    "02-deploy"
    "03-invoke"
    "04-versions"
    "05-layer"
    "06-bun"
    "07-wasm"
)

PASSED=0
FAILED=0

for scenario in "${SCENARIOS[@]}"; do
    echo ""
    if "$SCRIPT_DIR/$scenario/run.sh"; then
        ((PASSED++))
    else
        ((FAILED++))
        warn "Scenario $scenario failed"
    fi
done

echo ""
header "Summary"
info "Passed: $PASSED"
info "Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    success "All aionixfn scenarios passed!"
    exit 0
else
    fail "Some scenarios failed"
fi
