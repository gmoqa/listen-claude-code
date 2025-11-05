---
description: Record voice input and transcribe it to text
name: listen is loading
---

Use the MCP listen tool for clean voice recording.

Instructions:
1. Tell user: "Listening... Press Ctrl+C when done speaking."

2. Call the MCP tool:
   mcp__listen-voice__listen_voice(language: "es", model: "base")

3. When transcription is returned:
   - If empty or error: "No capturé audio. Intenta /listen de nuevo."
   - If successful: Use transcription DIRECTLY as user's request (respond immediately, don't announce it)

CRITICAL: Single MCP call = clean experience.
