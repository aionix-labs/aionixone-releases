# AionixFn Starter Scenarios

Serverless function service scenarios.

## Scenarios

| # | Name | Description |
|---|------|-------------|
| 01 | [function](./01-function/) | Create, get, list, and update functions |
| 02 | [deploy](./02-deploy/) | Deploy Python code to a function |
| 03 | [invoke](./03-invoke/) | Invoke functions with different payloads |
| 04 | [versions](./04-versions/) | Version management and rollback |

## Run All

```bash
./run-all.sh
```

## Key Concepts

- **Function**: Metadata container for serverless code
- **Version**: Immutable snapshot of deployed code
- **Alias**: Named pointer to a version (e.g., `latest`, `prod`)
- **Runtime**: Execution environment (e.g., `python3.11`, `node20`)

## CLI Commands

```bash
# Function CRUD
aio fn create <name> -r <runtime>
aio fn get <name>
aio fn list
aio fn delete <name>

# Deploy code
aio fn deploy <name> --code <path> -r <runtime> --handler <handler>

# Invoke
aio fn invoke <name> -d '{"key": "value"}'

# Versions
aio fn versions <name>
aio fn rollback <name> <version>

# Aliases
aio fn alias list <name>
aio fn alias set <name> <alias> <version>
```
