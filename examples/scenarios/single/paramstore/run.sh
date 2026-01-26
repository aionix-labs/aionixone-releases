#!/bin/bash
# ============================================================================
# Run all ParamStore scenarios
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================"
echo "  ParamStore Scenarios"
echo "================================"
echo ""

PASSED=0
FAILED=0
SCENARIOS=()

# Find all scenario directories
for dir in "$SCRIPT_DIR"/*/; do
    if [ -f "${dir}run.sh" ]; then
        SCENARIOS+=("$(basename "$dir")")
    fi
done

# Sort scenarios
IFS=$'\n' SCENARIOS=($(sort <<<"${SCENARIOS[*]}")); unset IFS

echo "Found ${#SCENARIOS[@]} scenarios:"
for scenario in "${SCENARIOS[@]}"; do
    echo "  - $scenario"
done
echo ""

# Run each scenario
for scenario in "${SCENARIOS[@]}"; do
    echo "----------------------------------------"
    echo "Running: $scenario"
    echo "----------------------------------------"

    if "$SCRIPT_DIR/$scenario/run.sh"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
        echo "FAILED: $scenario"
    fi
    echo ""
done

# Summary
echo "================================"
echo "  Summary"
echo "================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  ${#SCENARIOS[@]}"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
