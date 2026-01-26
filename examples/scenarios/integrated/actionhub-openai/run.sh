#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../common/helpers.sh"

header "ActionHub: OpenAI (hub install + skill + agent)"

check_cli_available
check_server_health

if [ -z "${OPENAI_API_KEY:-}" ]; then
    fail "OPENAI_API_KEY is required (export it before running this script)"
fi

ACTIONHUB_DIR="$(cd "$SCRIPT_DIR/../../../../actionhub/openai" && pwd)"
if [ ! -d "$ACTIONHUB_DIR" ]; then
    fail "ActionHub package not found: $ACTIONHUB_DIR"
fi

# Ensure secret exists (openai/api-key)
if $CLI sec create "openai/api-key" -t apiKey --value "{\"apiKey\":\"$OPENAI_API_KEY\"}" \
    -d "OpenAI API key (ActionHub)" >/dev/null 2>&1; then
    success "Secret created: openai/api-key"
else
    warn "Secret already exists: openai/api-key (reusing)"
fi

# Install ActionHub package
info "Installing ActionHub package: openai"
$CLI hub install "$ACTIONHUB_DIR" --yes

# Install skill
info "Installing skill: openai-basics"
$CLI skill install "$ACTIONHUB_DIR/skills/openai-basics"

# Run agent chat with toolset + skill
info "Running agent chat (toolset=openai, skill=openai-basics)"
$CLI agent chat \
  --model gpt-4o-mini \
  --tool-set openai \
  --skills openai-basics \
  --message "List one OpenAI model"

echo ""
success "ActionHub OpenAI example completed"
