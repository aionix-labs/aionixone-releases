# AionixOne Releases

Official binary releases for AionixOne - a unified automation platform.

## Quick Install

### macOS (Apple Silicon)

```bash
curl -fsSL https://raw.githubusercontent.com/aionix-labs/aionixone-releases/main/install.sh | bash
```

Or manually:

```bash
# Download
curl -LO https://github.com/aionix-labs/aionixone-releases/releases/latest/download/aionix-darwin-arm64.tar.gz

# Extract
tar -xzf aionix-darwin-arm64.tar.gz
cd aionix-darwin-arm64

# Setup & Start
./setup.sh
./start.sh
```

### Linux (x86_64)

```bash
# Download
curl -LO https://github.com/aionix-labs/aionixone-releases/releases/latest/download/aionix-linux-x86_64.tar.gz

# Extract
tar -xzf aionix-linux-x86_64.tar.gz
cd aionix-linux-x86_64

# Setup & Start
./setup.sh
./start.sh
```

## Usage

After installation:

```bash
# Load environment (required for CLI)
source .env

# Use CLI
aio --help
aio fn list
aio param list
aio wf list
```

## Package Contents

```
aionix-<platform>/
├── bin/
│   ├── aionix-server    # Server binary
│   └── aio              # CLI binary
├── setup.sh             # First time setup
├── start.sh             # Start server
├── stop.sh              # Stop server
├── status.sh            # Check status
└── README.md
```

## Scripts

| Script | Description |
|--------|-------------|
| `setup.sh` | First time setup, creates admin API key |
| `start.sh` | Start server in background |
| `stop.sh` | Stop server |
| `status.sh` | Check server status |

## Server

- **URL**: http://localhost:53000
- **Health Check**: http://localhost:53000/health

## Community Edition Limits

This is the free Community Edition:

| Resource | Limit |
|----------|-------|
| Governed Objects | 25 |
| Tenants | 1 |
| Features | All enabled |

Governed objects include: Functions, Triggers, Workflows, Connections, Secrets, Parameters.

## Requirements

- macOS 12+ (Apple Silicon) or Linux (x86_64)
- 512MB RAM minimum
- 1GB disk space

## Troubleshooting

### macOS Security Warning

If you see "cannot be opened because the developer cannot be verified":

```bash
xattr -d com.apple.quarantine bin/aio bin/aionix-server
```

### Server won't start

```bash
# Check if port is in use
lsof -i :53000

# Check logs
cat data/server.log
```

### Reset everything

```bash
./stop.sh
rm -rf data .env .pid
./setup.sh
```

## Links

- [Source Code](https://github.com/aionixone/aionixone-platform) (Private)
- [Documentation](https://github.com/aionix-labs/aionixone-releases/wiki)

## License

AionixOne is proprietary software. See [LICENSE](LICENSE) for details.
