# ParamStore — Parameter Management

**Category:** Core Service
**Complexity:** Low
**Typical Use:** Store application configuration, feature flags, runtime settings

> **Status**: Stable

## Overview

ParamStore is a versioned key-value store for application parameters. It supports string and JSON value types with automatic version history.

Each subdirectory demonstrates one paramstore operation pattern.

## Learning Path

| # | Example | Concept Introduced | Description |
|---|---------|-------------------|-------------|
| 01 | string-param | `param set/get` | Basic string parameter CRUD |
| 02 | json-param | JSON values | Structured configuration |
| 03 | versions | `param versions` | Version history and rollback |

## Prerequisites

- [x] aionix-server running (port 53000)
- [x] `aio` CLI installed and configured

## Quick Start

```bash
# Run all examples in sequence
./run.sh

# Or run a specific example
cd 01-string-param
./run.sh
```

## CLI Reference

```bash
# Create or update parameter
aio param set --type string "app/config/key" --value "value"
aio param set --type json "app/config/settings" --value '{"enabled":true}'

# Read parameter
aio param get --type string "app/config/key"

# List parameters
aio param list --prefix app/config

# View version history
aio param versions --type string "app/config/key"

# Get specific version
aio param version --type string "app/config/key" 1

# Delete parameter
aio param delete --type string "app/config/key" --force
```

## Parameter Types

| Type | Use Case |
|------|----------|
| `string` | Simple values, API keys, URLs |
| `json` | Structured config, feature flags |

## Expression Reference

Use `$param()` expressions to reference parameters in OpenAct connections and actions:

```yaml
# Syntax: $param('<path>')
baseUrl: "{% $param('/app/api/base-url') %}"
timeout: "{% $param('/app/config/timeout') %}"

# For JSON parameters, access nested fields:
host: "{% $param('/db/config').host %}"
port: "{% $param('/db/config').port %}"
```

> **Note**: Parameter paths start with `/` and use `/` as separator (e.g., `/app/config/key`).

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLI` | `aio` | Path to aio CLI |
| `KEEP_RESOURCES` | `false` | Keep parameters after run |
