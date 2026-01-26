---
name: openai-basics
description: Guide for using OpenAI tools for chat, embeddings, and image generation.
version: 0.1
requires:
  toolsets:
    - openai
---

# OpenAI Basics

Use this skill when you need general-purpose model reasoning, embeddings, or images.

## Workflow
1. For text reasoning or generation, use `openai_chat_completions`.
2. For embeddings, use `openai_embeddings` with the input text.
3. For images, use `openai_images_generate` with a short, concrete prompt.

## Notes
- Keep prompts concise.
- Always confirm the output format with the user if it is ambiguous.
