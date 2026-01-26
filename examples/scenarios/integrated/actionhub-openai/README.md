# ActionHub OpenAI (Integrated)

This directory contains integrated ActionHub OpenAI examples.

## Prerequisites

- AionixOne server running
- `aio` CLI configured
- `OPENAI_API_KEY` exported in your shell

## Run the base example

Installs the ActionHub package + skill and runs a chat request.

```bash
bash ./run.sh
```

## Generate an image (agent-driven)

Uses the agent runtime + OpenAI toolset to call the image tool.

```bash
export OPENAI_API_KEY="sk-..."

bash ./generate-image.sh
```

Optional overrides:

```bash
CHAT_MODEL="gpt-4o-mini" \
IMAGE_PROMPT="A flying cat over a city" \
IMAGE_MODEL="dall-e-3" \
IMAGE_SIZE="1024x1024" \
  bash ./generate-image.sh
```

Note: `gpt-image-1` may require verified organization access. If you see an
error about organization verification, use `dall-e-3` instead.

> Note: `aio act execute` waits for stdin when `-d` is omitted. This example
> uses the agent runtime instead of calling OpenAct directly.
