#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================"
echo "  Igniter (Trigger) Scenarios"
echo "================================"
echo ""

# Find all scenario scripts (nested)
SCRIPTS=$(find "$SCRIPT_DIR" -type f -name run.sh | sort | grep -v "$SCRIPT_DIR/run.sh")
SCENARIO_COUNT=$(echo "$SCRIPTS" | wc -l | tr -d ' ')

echo "Found $SCENARIO_COUNT scenarios:"
for script in $SCRIPTS; do
    name="${script#$SCRIPT_DIR/}"
    name="${name%/run.sh}"
    echo "  - $name"
done
echo ""

PASSED=0
FAILED=0

for script in $SCRIPTS; do
    name="${script#$SCRIPT_DIR/}"
    name="${name%/run.sh}"

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
