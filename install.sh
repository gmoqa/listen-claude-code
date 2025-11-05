#!/bin/bash
set -e

echo "Installing claude-listen-plugin..."

# Install MCP server dependencies
cd mcp-server && npm install && cd ..

# Create directories
mkdir -p "$HOME/.local/bin" "$HOME/.claude/commands" "$HOME/.claude/mcp-servers/listen-voice"

# Copy files
cp .claude/commands/*.md "$HOME/.claude/commands/"
cp -r mcp-server/* "$HOME/.claude/mcp-servers/listen-voice/"

# Configure MCP server
if command -v claude &> /dev/null; then
    claude mcp add --transport stdio --scope user listen-voice \
        --env LISTEN_PATH=listen \
        -- node "$HOME/.claude/mcp-servers/listen-voice/server.js" || true
fi

# Check PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo "Done. Run /listen in Claude Code."
