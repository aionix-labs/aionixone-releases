# HTTP Connector Scenarios

HTTP/REST API integration with authentication and response handling.

## Scenarios

| # | Scenario | Description |
|---|----------|-------------|
| 01 | basic-get | Simple GET request to public API |
| 02 | auth-bearer | Bearer token authentication |
| 03 | post-json | POST with JSON body |

## Run All

```bash
./run.sh
```

## CLI Reference

```bash
# Create HTTP connection
aio act conn create <name> -k http --config '{"baseUrl":"https://api.example.com"}'

# Create action using connection
aio act create <name> -k http -c <connection> --config '{"method":"GET","path":"/endpoint"}'

# Execute action
aio act execute <action-name> --data '{}'

# Test connection
aio act conn test <connection-name>
```

## Connection Types

- **No auth**: Public APIs
- **Bearer**: Token-based auth (CredVault integration)
- **API Key**: Header/query parameter auth
- **Basic**: Username/password
