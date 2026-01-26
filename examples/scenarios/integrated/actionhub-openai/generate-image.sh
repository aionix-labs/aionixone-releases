#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../common/helpers.sh"

header "ActionHub: OpenAI (agent image generation)"

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

info "Installing ActionHub package: openai"
$CLI hub install "$ACTIONHUB_DIR" --yes

CHAT_MODEL="${CHAT_MODEL:-gpt-4o-mini}"
IMAGE_MODEL="${IMAGE_MODEL:-dall-e-3}"
IMAGE_PROMPT="${IMAGE_PROMPT:-A flying cat, watercolor illustration}"
IMAGE_SIZE="${IMAGE_SIZE:-1024x1024}"

# Ensure model -> LLM action mapping exists
$CLI agent llm map set "$CHAT_MODEL" \
  --action trn:openact:default:action/http/openai/chat/completions:execute >/dev/null

MESSAGE=$(cat <<EOF_MSG
Use the openai_images_generate tool with these exact parameters:
- model: "$IMAGE_MODEL"
- prompt: "$IMAGE_PROMPT"
- size: "$IMAGE_SIZE"
Return only the image URL.
EOF_MSG
)

info "Generating image via agent..."
RESULT=$($CLI agent chat \
  --model "$CHAT_MODEL" \
  --tool-set openai \
  --skills openai-basics \
  --tool-choice required \
  --message "$MESSAGE" \
  -o json --no-spinner --no-logs)

URL=$(echo "$RESULT" | grep -oE 'https?://[^)[:space:]]+' | head -n 1)

if [ -n "$URL" ]; then
    success "Image generated"
    echo ""
    echo "URL: $URL"
else
    warn "Image URL not found in response"
    echo "$RESULT" | jq .
fi
