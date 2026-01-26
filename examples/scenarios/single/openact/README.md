# OpenAct — Action Management

**Category:** Core Service
**Complexity:** Low to Medium
**Typical Use:** API integrations, external service calls, data transformations

> **Status**: Stable

## Overview

OpenAct is the action execution service. It manages connections to external services and defines reusable actions that can be executed with dynamic input.

## Scenarios

| # | Scenario | Description |
|---|----------|-------------|
| 01 | connection | Create and manage HTTP connections |
| 02 | action | Define actions on connections |
| 03 | execute | Execute actions with dynamic input |

## Run All

```bash
./run.sh
```

## CLI Reference

```bash
# Connection management
aio act conn create <name> -t <type> --config '<json>'
aio act conn get <type>/<name>
aio act conn list [-t <type>]
aio act conn test <type>/<name>
aio act conn delete <type>/<name> [--force]

# Action management
aio act create <name> -t <type> -c <connection> --config '<json>'
aio act get <type>/<name>
aio act list [-t <type>]
aio act delete <type>/<name> [--force]

# Execution
aio act execute <type>/<name> [-d '<input>']
```

## Connector Types

| Type | Use Case |
|------|----------|
| `http` | REST APIs, webhooks |
| `postgres` | PostgreSQL queries |
| `mysql` | MySQL queries |
| `redis` | Redis commands |
| `kafka` | Kafka publish |
| `mcp` | MCP protocol |

## Expression Support

Actions support expressions for dynamic values:

```json
{
  "method": "POST",
  "path": "/users/{% input.userId %}",
  "body": "{% input %}",
  "headers": {
    "Authorization": "Bearer {% $secret('api-token').token %}"
  }
}
```

See CredVault and ParamStore READMEs for `$secret()` and `$param()` expression syntax.
