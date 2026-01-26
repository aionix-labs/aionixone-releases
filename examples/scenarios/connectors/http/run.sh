#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================"
echo "  HTTP Connector Scenarios"
echo "================================"
echo ""

# Find all scenario directories
SCENARIOS=$(find . -maxdepth 1 -type d -name '[0-9]*' | sort)

if [ -z "$SCENARIOS" ]; then
    echo "No scenarios found"
    exit 0
fi

echo "Found $(echo "$SCENARIOS" | wc -l | tr -d ' ') scenarios:"
for dir in $SCENARIOS; do
    name=$(basename "$dir")
    echo "  - $name"
done
echo ""

PASSED=0
FAILED=0

for dir in $SCENARIOS; do
    name=$(basename "$dir")
    echo "----------------------------------------"
    echo "Running: $name"
    echo "----------------------------------------"
    echo ""

    if [ -f "$dir/run.sh" ]; then
        if "$dir/run.sh"; then
            PASSED=$((PASSED + 1))
        else
            FAILED=$((FAILED + 1))
            echo "FAILED: $name"
        fi
    else
        echo "SKIPPED: No run.sh found"
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
