# Claude Listen Plugin

Voice input for Claude Code using [listen](https://github.com/gmoqa/listen) CLI tool with local Whisper transcription.

## Features

- Voice input instead of typing
- Multi-language support (es, en, fr, de, it, pt, zh, ja, ko)
- Multiple Whisper models (tiny to large)
- MCP server integration with slash commands

## Requirements

- Claude Code
- [listen CLI](https://github.com/gmoqa/listen)
- Node.js v18+
- Working microphone

## Installation

### 1. Install listen CLI

```bash
git clone https://github.com/gmoqa/listen.git
cd listen
pip install -r requirements.txt
# Ensure 'listen' is available in PATH
```

### 2. Install plugin in Claude Code

Open Claude Code and run:

```
/plugin marketplace add gmoqa/listen-claude-code
/plugin install claude-listen@gmoqa/listen-claude-code
```

That's it! The plugin will automatically:
- Install MCP server dependencies
- Configure the listen voice tool
- Add the `/listen` command

## Usage

### `/listen` command

```
/listen
```

Starts voice recording. Press Ctrl+C when done speaking. Claude processes the transcription automatically.

### Direct MCP tool

Claude can also use the `listen_voice` tool directly when needed.

## How it works

1. User runs `/listen`
2. MCP tool calls `listen` CLI
3. User speaks, then presses Ctrl+C
4. Whisper transcribes audio to text
5. Claude processes the text as a normal request

## Testing

```bash
cd test
./quick-test.sh    # Fast validation
./auto-test.sh     # Full test suite
```

## Troubleshooting

**"listen command not found"**
Add listen to PATH or set `LISTEN_PATH` in `.mcp.json`

**"No module named 'whisper'"**
`pip install -r requirements.txt` in listen directory

**Microphone not working**
Check permissions in System Preferences → Privacy → Microphone

## License

MIT - See LICENSE file

## Credits

- [listen](https://github.com/gmoqa/listen) by @gmoqa
- [Whisper](https://github.com/openai/whisper) by OpenAI
- [Claude Code](https://claude.com/claude-code) MCP integration
