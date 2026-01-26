#!/bin/bash
# ============================================================================
# AionixOne Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/aionixone/aionixone-releases/main/install.sh | bash
# ============================================================================

set -e

REPO="aionix-labs/aionixone-releases"
INSTALL_BIN_DIR="${AIONIX_INSTALL_BIN_DIR:-$HOME/.local/bin}"
DATA_DIR="${AIONIX_DATA_DIR:-$HOME/.aionixone/data}"
VERSION="${AIONIX_VERSION:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║       AionixOne Installer             ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Detect platform
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS-$ARCH" in
    Darwin-arm64)
        PLATFORM="darwin-arm64"
        ;;
    Darwin-x86_64)
        echo -e "${RED}Error: Intel Mac not supported yet. Use Apple Silicon or Linux.${NC}"
        exit 1
        ;;
    Linux-x86_64)
        PLATFORM="linux-x86_64"
        ;;
    Linux-aarch64)
        echo -e "${RED}Error: Linux ARM64 not supported yet.${NC}"
        exit 1
        ;;
    *)
        echo -e "${RED}Error: Unsupported platform: $OS-$ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}Platform: $PLATFORM${NC}"
echo -e "${YELLOW}Install binary dir: $INSTALL_BIN_DIR${NC}"
echo -e "${YELLOW}Data directory: $DATA_DIR${NC}"
echo ""

if [ -z "$VERSION" ]; then
    # Get latest community release (including pre-releases)
    echo -e "${YELLOW}Fetching latest community release...${NC}"
    VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases" \
        | grep '"tag_name"' \
        | sed -E 's/.*"([^"]+)".*/\1/' \
        | grep '^community-v' \
        | head -1)
fi

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Could not determine latest version${NC}"
    exit 1
fi

echo -e "${GREEN}Version: $VERSION${NC}"

# Download
FILENAME="aio-community-$PLATFORM.tar.gz"
URL="https://github.com/$REPO/releases/download/$VERSION/$FILENAME"

echo -e "${YELLOW}Downloading $URL...${NC}"
curl -fSL "$URL" -o "/tmp/$FILENAME"

# Extract
echo -e "${YELLOW}Installing to $INSTALL_BIN_DIR...${NC}"
mkdir -p "$INSTALL_BIN_DIR"
mkdir -p "$DATA_DIR"
TMP_DIR="$(mktemp -d)"
tar -xzf "/tmp/$FILENAME" -C "$TMP_DIR"
mv "$TMP_DIR/aio" "$INSTALL_BIN_DIR/aio"
chmod +x "$INSTALL_BIN_DIR/aio"
rm -rf "$TMP_DIR"

# Cleanup
rm -f "/tmp/$FILENAME"

# Remove quarantine on macOS
if [ "$OS" = "Darwin" ]; then
    xattr -d com.apple.quarantine "$INSTALL_BIN_DIR/aio" 2>/dev/null || true
fi

# Ensure PATH for common shells
PATH_HINT="$INSTALL_BIN_DIR"
ensure_path() {
    local shell_rc="$1"
    if [ -f "$shell_rc" ] && ! grep -Fq "$PATH_HINT" "$shell_rc"; then
        echo "" >> "$shell_rc"
        echo "export PATH=\"$PATH_HINT:\$PATH\"" >> "$shell_rc"
    fi
}

ensure_path "$HOME/.zshrc"
ensure_path "$HOME/.bashrc"
ensure_path "$HOME/.bash_profile"

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo ""
echo -e "  ${CYAN}aio --help${NC}"
echo -e "  ${CYAN}export AIONIX_DATA_PATH=\"$DATA_DIR\"${NC}"
echo -e "  ${CYAN}aio server --bootstrap-admin admin --db-mode sqlite --data-path \"$DATA_DIR\" --port 53000${NC}"
echo -e "  ${CYAN}AIONIX_API_KEY=\"<key>\" aio server --db-mode sqlite --data-path \"$DATA_DIR\" --port 53000${NC}"
echo ""
