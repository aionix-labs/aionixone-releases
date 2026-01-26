#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================"
echo "  OpenAct Scenarios"
echo "================================"
echo ""

# Find all scenario directories
SCENARIOS=$(find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
SCENARIO_COUNT=$(echo "$SCENARIOS" | wc -l | tr -d ' ')

echo "Found $SCENARIO_COUNT scenarios:"
for dir in $SCENARIOS; do
    name=$(basename "$dir")
    echo "  - $name"
done
echo ""

PASSED=0
FAILED=0

for dir in $SCENARIOS; do
    name=$(basename "$dir")
    script="$dir/run.sh"

    if [ -f "$script" ]; then
        echo "----------------------------------------"
        echo "Running: $name"
        echo "----------------------------------------"
        echo ""

        if bash "$script"; then
            ((PASSED++))
        else
            ((FAILED++))
            echo "FAILED: $name"
        fi
        echo ""
    fi
done

echo "================================"
echo "  Summary"
echo "================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
