#!/bin/bash
# ==========================================================================
# AionixOne Uninstaller
# ===========================================================================

set -euo pipefail

DEFAULT_BIN_DIR="$HOME/.local/bin"
if [ -n "${AIONIX_INSTALL_BIN_DIR:-}" ]; then
  INSTALL_BIN_DIR="$AIONIX_INSTALL_BIN_DIR"
else
  AIO_PATH="$(command -v aio 2>/dev/null || true)"
  if [ -n "$AIO_PATH" ]; then
    INSTALL_BIN_DIR="$(dirname "$AIO_PATH")"
  else
    INSTALL_BIN_DIR="$DEFAULT_BIN_DIR"
  fi
fi
DATA_DIR="${AIONIX_DATA_DIR:-$HOME/.aionixone}"
REMOVE_PATH="false"
KEEP_DATA="false"
ASSUME_YES="false"

usage() {
  cat <<USAGE
Usage: ./uninstall.sh [options]

Options:
  --yes            Skip confirmation prompt
  --keep-data      Keep data directory (default: remove)
  --remove-path    Remove PATH entries from shell rc files
  -h, --help       Show this help

Env overrides:
  AIONIX_INSTALL_BIN_DIR  Default: ~/.local/bin
  AIONIX_DATA_DIR         Default: ~/.aionixone
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --yes) ASSUME_YES="true" ;;
    --keep-data) KEEP_DATA="true" ;;
    --remove-path) REMOVE_PATH="true" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
 done

if [ "$ASSUME_YES" != "true" ]; then
  echo "This will remove AionixOne binaries and data."
  echo "  Binary: $INSTALL_BIN_DIR/aio"
  echo "  Data:   $DATA_DIR"
  read -r -p "Continue? [y/N] " ans
  case "$ans" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# Stop server if running (best-effort)
if [ -f "$DATA_DIR/aio.pid" ]; then
  PID=$(cat "$DATA_DIR/aio.pid" 2>/dev/null || true)
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" >/dev/null 2>&1 || true
  fi
  rm -f "$DATA_DIR/aio.pid" >/dev/null 2>&1 || true
fi

# Remove binary
rm -f "$INSTALL_BIN_DIR/aio"

# Remove data
if [ "$KEEP_DATA" != "true" ]; then
  rm -rf "$DATA_DIR"
fi

# Optionally remove PATH entries
if [ "$REMOVE_PATH" = "true" ]; then
  PATH_HINT="$INSTALL_BIN_DIR"
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "$rc" ]; then
      sed -i '' "/${PATH_HINT//\//\/}/d" "$rc" 2>/dev/null || true
    fi
  done
fi

echo "Uninstall complete."
if [ "$KEEP_DATA" = "true" ]; then
  echo "Data preserved at: $DATA_DIR"
fi
if [ "$REMOVE_PATH" != "true" ]; then
  echo "Note: PATH entries were not modified. Remove manually if desired."
fi
