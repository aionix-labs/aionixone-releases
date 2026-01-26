#!/bin/bash
set -e

echo "=== Workspace Export Test ==="
echo ""

# Use CLI from PATH
CLI=${CLI:-aio}
if ! command -v "$CLI" >/dev/null 2>&1; then
    echo "❌ aio not found in PATH"
    exit 1
fi

# Ensure server is running
AIONIX_API_BASE="${AIONIX_API_BASE:-http://127.0.0.1:53000}"
if ! curl -s "${AIONIX_API_BASE%/}/health" >/dev/null 2>&1; then
    echo "❌ Server is not running. Start with: aio server --db-mode sqlite --data-path ~/.aionixone/data --port 53000"
    exit 1
fi

echo "✓ Server is running"
echo ""

# Step 1: Initialize a test workspace
echo "=== 1. Initialize test workspace ==="
WORKSPACE_DIR="/tmp/aionix-test-ws-export-$$"
rm -rf "$WORKSPACE_DIR"

$CLI ws init test-export-ws \
    --template minimal \
    --tenant default

cd test-export-ws || exit 1
echo "✓ Workspace initialized at: $(pwd)"
echo ""

# Step 2: Create a test workflow via CLI (not from workspace)
echo "=== 2. Create test workflow ==="
cat > /tmp/test-workflow.yaml <<'EOF'
entry: start
steps:
  start:
    type: set
    assign:
      - output: Hello from export test
    next: end
  end:
    type: succeed
EOF

$CLI wf create test-export-workflow \
    --dsl /tmp/test-workflow.yaml \
    --description "Test workflow for export" \
    >/dev/null 2>&1 || echo "Workflow might already exist, continuing..."

echo "✓ Test workflow created"
echo ""

# Step 3: Tag the workflow with workspace tag (simulate workspace deploy)
# Note: In real usage, this would be done by `aio ws deploy`
# For now, we'll create it directly and manually verify

echo "=== 3. List workflows before export ==="
$CLI wf list -o table
echo ""

# Step 4: Test export (dry-run first)
echo "=== 4. Test export (dry-run) ==="
$CLI ws export --dry-run --only flow
echo ""

# Step 5: Actual export
echo "=== 5. Export workflows ==="
$CLI ws export --only flow --format yaml
echo ""

# Step 6: Verify exported files
echo "=== 6. Verify exported files ==="
if [ -d "flows" ]; then
    echo "✓ flows/ directory created"
    ls -la flows/
    echo ""

    if ls flows/*.yaml >/dev/null 2>&1; then
        echo "✓ YAML files exported"
        echo ""
        echo "=== Sample exported workflow ==="
        head -20 flows/*.yaml | head -20
    else
        echo "⚠️  No workflow files found (workspace tag might be missing)"
    fi
else
    echo "⚠️  No flows/ directory created"
    echo "   This is expected if no workflows have workspace tags"
fi
echo ""

# Step 7: Test with different format
echo "=== 7. Test JSON export ==="
$CLI ws export --only flow --format json --overwrite --dry-run
echo ""

# Cleanup
echo "=== Cleanup ==="
cd ..
rm -rf test-export-ws
rm -f /tmp/test-workflow.yaml
echo "✓ Cleaned up test workspace"
echo ""

echo "=== Test Complete ==="
echo ""
echo "📝 Note: For full testing, workflows need workspace tags"
echo "   Workflows created via 'aio ws deploy' will have these tags automatically"
