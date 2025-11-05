#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";

const server = new Server(
  { name: "listen-voice-server", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

async function executeListenCommand(options = {}) {
  return new Promise((resolve, reject) => {
    const { model = "base", language = "es", verbose = false } = options;
    const args = ["-m", model, "-l", language];
    if (verbose) args.push("-v");

    const listenCmd = process.env.LISTEN_PATH || "listen";
    const child = spawn(listenCmd, args, { stdio: ["inherit", "pipe", "pipe"] });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (data) => (stdout += data.toString()));
    child.stderr.on("data", (data) => {
      stderr += data.toString();
      console.error(data.toString());
    });

    child.on("close", (code) => {
      if (code === 0) {
        resolve({ success: true, transcription: stdout.trim() });
      } else {
        reject(new Error(`listen failed with code ${code}: ${stderr}`));
      }
    });

    child.on("error", (err) => reject(new Error(`Failed to execute: ${err.message}`)));
  });
}

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "listen_voice",
      description: "Record audio and transcribe using Whisper. Press Ctrl+C to stop recording.",
      inputSchema: {
        type: "object",
        properties: {
          model: { type: "string", enum: ["tiny", "base", "small", "medium", "large"], default: "base" },
          language: { type: "string", enum: ["es", "en", "fr", "de", "it", "pt", "zh", "ja", "ko"], default: "es" },
          verbose: { type: "boolean", default: false },
        },
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "listen_voice") {
    try {
      const result = await executeListenCommand(args);
      return { content: [{ type: "text", text: result.transcription || "No transcription" }] };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error: ${error.message}\nCheck listen installation.` }],
        isError: true,
      };
    }
  }

  throw new Error(`Unknown tool: ${name}`);
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Listen MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
