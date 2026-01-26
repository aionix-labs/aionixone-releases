#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../common/helpers.sh"

header "Agent: OpenAI-compatible (OpenAI LLM + Tool)"

# Prerequisites
check_cli_available
check_server_health

if [ -z "${OPENAI_API_KEY:-}" ]; then
    fail "OPENAI_API_KEY is required (export it before running this script)"
fi

# Names
CRED_NAME="starter-openai-key-$(date +%s)-$RANDOM"
OPENAI_CONN="starter-openai-conn"
LLM_ACTION="llm-chat"
TOOL_CONN="starter-tool-conn-$(date +%s)-$RANDOM"
TOOL_ACTION="starter-weather-$(date +%s)-$RANDOM"
TOOL_NAME="starter_weather_$(date +%s)"

# Cleanup on exit (only for resources we create here)
register_cleanup "$CLI param delete --type json \"agent/tools/$TOOL_NAME\" --force 2>/dev/null || true"
register_cleanup "$CLI act delete \"http/$TOOL_ACTION\" --force 2>/dev/null || true"
register_cleanup "$CLI act conn delete \"http/$TOOL_CONN\" --force 2>/dev/null || true"
register_cleanup "$CLI sec delete \"$CRED_NAME\" -t apiKey --force 2>/dev/null || true"

# 1) CredVault: store OpenAI key
info "Creating OpenAI API key credential: $CRED_NAME"
if $CLI sec create "$CRED_NAME" -t apiKey --value "{\"apiKey\":\"$OPENAI_API_KEY\"}" -d "Starter OpenAI key" >/dev/null; then
    success "Credential created"
else
    fail "Failed to create credential"
fi

# 2) OpenAct connection + LLM action (use default action name)
if $CLI act conn get "http/$OPENAI_CONN" >/dev/null 2>&1; then
    warn "OpenAI connection already exists: $OPENAI_CONN (reusing)"
else
    info "Creating OpenAI HTTP connection: $OPENAI_CONN"
    if $CLI act conn create "$OPENAI_CONN" -t http --config '{"baseUrl":"https://api.openai.com"}' >/dev/null; then
        success "Connection created"
    else
        fail "Failed to create connection"
    fi
fi

if $CLI act get "http/$LLM_ACTION" >/dev/null 2>&1; then
    warn "LLM action already exists: $LLM_ACTION (reusing)"
else
    info "Creating OpenAI LLM action: $LLM_ACTION"
    ACTION_CONFIG=$(cat <<EOF
{
  "method": "POST",
  "path": "/v1/chat/completions",
  "headers": {
    "Authorization": "Bearer {% \\$secret('$CRED_NAME').apiKey %}",
    "Content-Type": "application/json"
  },
  "body": "{% input %}",
  "response": {
    "successCodes": [200]
  }
}
EOF
)
    if $CLI act create "$LLM_ACTION" -t http -c "http/$OPENAI_CONN" --config "$ACTION_CONFIG" >/dev/null; then
        success "LLM action created"
    else
        fail "Failed to create LLM action"
    fi
fi

# 3) Tool action (httpbin) + ParamStore mapping
info "Creating tool HTTP connection: $TOOL_CONN"
if $CLI act conn create "$TOOL_CONN" -t http --config '{"baseUrl":"https://httpbin.org"}' >/dev/null; then
    success "Tool connection created"
else
    fail "Failed to create tool connection"
fi

info "Creating tool action: $TOOL_ACTION"
TOOL_ACTION_CONFIG=$(cat <<'EOF'
{
  "method": "GET",
  "path": "/get",
  "query": {
    "source": "aionix-agent-starter"
  },
  "response": {
    "successCodes": [200]
  }
}
EOF
)
if $CLI act create "$TOOL_ACTION" -t http -c "http/$TOOL_CONN" --config "$TOOL_ACTION_CONFIG" >/dev/null; then
    success "Tool action created"
else
    fail "Failed to create tool action"
fi

info "Mapping tool name -> TRN in ParamStore: $TOOL_NAME"
TOOL_MAPPING=$(cat <<EOF
{"action":"trn:openact:default:action/http/$TOOL_ACTION:execute"}
EOF
)
if $CLI param set --type json "agent/tools/$TOOL_NAME" --value "$TOOL_MAPPING" >/dev/null; then
    success "Tool mapping created"
else
    fail "Failed to create tool mapping"
fi

# 4) Call Agent API (tool_choice forces tool execution)
info "Calling Agent Runtime with tool_choice=$TOOL_NAME"
REQUEST_JSON=$(cat <<EOF
{
  "model": "gpt-4o-mini",
  "messages": [{"role":"user","content":"call the tool"}],
  "tools": [{
    "type": "function",
    "function": {
      "name": "$TOOL_NAME",
      "parameters": {}
    }
  }],
  "tool_choice": {
    "type": "function",
    "function": {"name": "$TOOL_NAME"}
  },
  "stream": false
}
EOF
)

curl -s http://${AIONIX_HOST}:${AIONIX_PORT}/v1/chat/completions \
  -H "Authorization: Bearer ${AIONIX_API_KEY}" \
  -H "Content-Type: application/json" \
  -H "x-aionix-tenant: default" \
  -H "x-request-id: starter-agent-$(date +%s)" \
  -d "$REQUEST_JSON" | jq .

echo ""
success "Agent OpenAI starter completed"
info "  Tool name: $TOOL_NAME"
info "  LLM action: http/$LLM_ACTION (uses OpenAI API key from CredVault)"
