# CredVault Scenarios

Credential management with versioning, rotation, and secure storage.

> **Security Model**: Secret values are only returned at creation time or via explicit `reveal` operations. List and get operations return metadata only.

## Scenarios

| # | Scenario | Description |
|---|----------|-------------|
| 01 | api-key | Basic API key credential CRUD |
| 02 | rotation | Credential rotation and version management |

## Run All

```bash
./run.sh
```

## CLI Reference

```bash
# Create credential
aio sec create <name> -t <type> --value '<json>'

# Get credential metadata
aio sec get <name> -t <type>

# Reveal secret value
aio sec reveal <name> -t <type>

# Rotate credential (new version)
aio sec rotate <name> -t <type> --value '<json>' [--activate]

# List versions
aio sec versions <name> -t <type>

# Activate specific version
aio sec activate <name> -t <type> --version <v>

# Delete credential
aio sec delete <name> -t <type> [--force]
```

## Credential Types

- `apiKey` - API keys with optional prefix
- `bearer` - Bearer tokens
- `basicAuth` - Username/password
- `database` - Database connection credentials
- `custom` - Custom structured data

## Expression Reference

Use `$secret()` expressions to reference credentials in OpenAct connections and actions:

```yaml
# Syntax: $secret('<credential-name>').<field>
token: "{% $secret('my-bearer-token').token %}"
password: "{% $secret('my-db-cred').password %}"
apiKey: "{% $secret('my-api-key').apiKey %}"
```

> **Note**: Credential names are globally unique within a tenant. Use the credential `name` directly (not `type/name`). The `-t` flag is only required for CLI commands, not for `$secret()` expressions.
