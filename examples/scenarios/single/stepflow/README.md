# Stepflow — Workflow Engine

**Category:** Core Service
**Complexity:** Low
**Typical Use:** Orchestrate multi-step processes, coordinate tasks, implement business logic

> **Status**: Stable

## Overview

Stepflow is the workflow execution engine of AionixOne. It executes DSL-defined workflows that coordinate steps, handle branching, parallel execution, and error recovery.

Each subdirectory represents one atomic DSL concept.
Examples are ordered and designed to be read sequentially.

These examples are not tests; they are reference execution patterns intended for reuse.

## Learning Path

### Control Flow (01-08)

| # | Example | Concept Introduced | Description |
|---|---------|-------------------|-------------|
| 01 | simple-set | `set` + `end` | Minimal workflow, single step |
| 02 | sequential-set | `next` | Multi-step sequential execution |
| 03 | wait | `wait` | Pause execution for a duration |
| 04 | succeed | `succeed` | Explicit success termination |
| 05 | fail | `fail` | Explicit failure termination |
| 06 | router | `router` | Conditional branching with expressions |
| 07 | parallel | `parallel` | Concurrent branch execution |
| 08 | map | `map` | Batch processing over arrays |

### Task Execution (09-16)

| # | Example | Concept Introduced | Description |
|---|---------|-------------------|-------------|
| 09 | task-bun | `task` | Execute a Bun function |
| 10 | task-retry | `task` + `retry` | Retry on failure |
| 11 | task-catch | `task` + `catch` | Branch on failure (error recovery) |
| 13 | task-await-subflow | `task` + `await` | Await a child workflow completion |
| 14 | task-await-subflow-fail | `task` + `await` | Child failure propagates |
| 15 | task-noawait-subflow-fail | `task` | Child failure does not block parent |
| 16 | task-noawait-subflow | `task` | Fire-and-forget child workflow success |

### Signal Flow (12)

| # | Example | Concept Introduced | Description |
|---|---------|-------------------|-------------|
| 12 | wait-signal | `waitSignal` | Pause execution until an external signal arrives |

## Prerequisites

- [x] aionix-server running (port 53000)
- [x] `aio` CLI installed and configured

## Quick Start

```bash
# Run all examples in sequence
./run.sh

# Or run a specific example
cd 01-simple-set
./run.sh
```

## DSL Reference

Stepflow uses a JSON-based DSL:

```json
{
  "entry": "StepName",
  "steps": {
    "StepName": {
      "type": "set|task|router|parallel|map|succeed|fail",
      ...
    }
  }
}
```

**Key fields:**

| Field | Purpose |
|-------|---------|
| `entry` | Name of the first step to execute |
| `steps` | Map of step definitions |
| `type` | Step type |
| `next` | Explicitly specifies the next step to execute |
| `end` | Marks this step as terminal (no next step) |

**Expression syntax:** `{% expression %}` (JSONata)

## Step Types

| Type | Purpose |
|------|---------|
| `set` | Assign values to output |
| `task` | Execute external action (shell, openact, aionixfn) |
| `router` | Conditional branching |
| `parallel` | Execute branches concurrently |
| `map` | Process array items |
| `wait` | Pause execution |
| `waitSignal` | Wait for an external signal |
| `succeed` | Terminate with success |
| `fail` | Terminate with failure |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLI` | `aio` | Path to aio CLI |
| `KEEP_RESOURCES` | `false` | Keep workflows after run |

## Troubleshooting

**Server not responding:**
```bash
curl http://localhost:53000/health
```

**CLI not found:**
```bash
which aio
aio --version
```

**Workflow execution fails:**
```bash
# Check execution status
aio wf execution <run-id>

# View step details
aio wf steps <run-id>
```
