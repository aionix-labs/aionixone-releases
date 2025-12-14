#!/bin/bash
# ============================================================================
# AionixOne Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/aionixone/aionixone-releases/main/install.sh | bash
# ============================================================================

set -e

REPO="aionix-labs/aionixone-releases"
INSTALL_DIR="${AIONIX_INSTALL_DIR:-$HOME/aionixone}"

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
echo -e "${YELLOW}Install directory: $INSTALL_DIR${NC}"
echo ""

# Get latest release
echo -e "${YELLOW}Fetching latest release...${NC}"
LATEST=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST" ]; then
    echo -e "${RED}Error: Could not determine latest version${NC}"
    exit 1
fi

echo -e "${GREEN}Latest version: $LATEST${NC}"

# Download
FILENAME="aionix-$PLATFORM.tar.gz"
URL="https://github.com/$REPO/releases/download/$LATEST/$FILENAME"

echo -e "${YELLOW}Downloading $URL...${NC}"
curl -fSL "$URL" -o "/tmp/$FILENAME"

# Extract
echo -e "${YELLOW}Installing to $INSTALL_DIR...${NC}"
mkdir -p "$INSTALL_DIR"
tar -xzf "/tmp/$FILENAME" -C "$INSTALL_DIR" --strip-components=1

# Cleanup
rm -f "/tmp/$FILENAME"

# Remove quarantine on macOS
if [ "$OS" = "Darwin" ]; then
    xattr -d com.apple.quarantine "$INSTALL_DIR/bin/aio" 2>/dev/null || true
    xattr -d com.apple.quarantine "$INSTALL_DIR/bin/aionix-server" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo ""
echo -e "  ${CYAN}cd $INSTALL_DIR${NC}"
echo -e "  ${CYAN}./setup.sh${NC}"
echo -e "  ${CYAN}source .env${NC}"
echo -e "  ${CYAN}./start.sh${NC}"
echo -e "  ${CYAN}aio --help${NC}"
echo ""
