# Igniter — Trigger Management

**Category:** Core Service
**Complexity:** Low to Medium
**Typical Use:** Event-driven automation, scheduled tasks, webhooks

> **Status**: Stable

## Overview

Igniter is the trigger management service. It listens for events from various sources and executes actions when triggered.

## Scenarios (Trigger × Target)

| Trigger | Target | Description |
|---|---|---|
| cron | stepflow workflow | Scheduled workflow start |
| cron | aionixfn function | Scheduled function invoke via `/api/invoke` |
| cron | openact action | Scheduled action execute via `/api/invoke` |
| webhook | stepflow workflow | Webhook-triggered workflow start |
| webhook | aionixfn function | Webhook-triggered function invoke |
| webhook | openact action | Webhook-triggered action execute |
| manual | aionixfn function | Manual trigger fire (no external event) |
| manual | openact action | Manual trigger fire (no external event) |

## Run All

```bash
./run.sh
```

## CLI Reference

```bash
# Create trigger
aio tr create <name> -t <type> --config '<json>' --action '<json>'

# List triggers
aio tr list

# Get trigger details
aio tr get <type>/<name>

# Fire trigger manually
aio tr fire <type>/<name>

# Enable/disable trigger
aio tr enable <type>/<name>
aio tr disable <type>/<name>

# Check trigger health
aio tr health <type>/<name>

# Delete trigger
aio tr delete <type>/<name> [--force]
```

## Trigger Types

| Type | Source | Use Case |
|------|--------|----------|
| `webhook` | HTTP request | API integrations, external events |
| `cron` | Schedule | Periodic tasks, batch jobs |
| `delay` | Timer | One-shot delayed execution (used for manual fire in scenarios) |
| `httppoll` | HTTP polling | Monitor external APIs |
| `kafka` | Kafka topic | Stream processing |
| `redis` | Redis pub/sub | Real-time messaging |
| `postgres` | PostgreSQL LISTEN | Database events |
| `filewatch` | File system | File arrival processing |

## Action Target Format

Actions specify what to execute when triggered:

```json
{
  "target": "trn:SERVICE:TENANT:RESOURCE:OPERATION",
  "input": { ... }
}
```

Examples:
- Function: `trn:aionixfn:default:function/my-func:invoke`
- Workflow: `trn:stepflow:default:workflow/my-flow:start`
- Action: `trn:openact:default:action/http/my-action:execute`
- HTTP: `trn:builtin:system:http:request`

## Future Directions

- Agent-based file monitoring for remote hosts
- Object storage event integration (S3 / MinIO)
