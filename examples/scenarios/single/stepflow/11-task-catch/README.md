# 11-task-catch

Demonstrates error recovery using `catch` block.

## Key Concept

**Failure ≠ Workflow Failure**

When a task fails, `catch` can redirect execution to an alternative path instead of terminating the workflow.

## Execution Flow

```
RiskyTask (exit 1) → FAILS → catch matches Shell_NonZeroExitCode
                           → sets { caught: true }
                           → jumps to HandleError
                           → workflow SUCCEEDS
```

## Note

The `Success` step is intentionally unreachable in this example, demonstrating that `catch` redirects execution flow away from the normal path.

## DSL Highlights

```json
"catch": [
  {
    "errorCodes": ["Shell_NonZeroExitCode"],
    "next": "HandleError",
    "set": { "caught": true }
  }
]
```

- `errorCodes`: Match specific error codes
- `next`: Target step when error is caught
- `set`: Modify workflow variables during catch
