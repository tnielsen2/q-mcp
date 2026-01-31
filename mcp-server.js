#!/usr/bin/env node

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const server = new Server(
  { name: 'mcp-tools', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

const exec = (cmd) => execSync(cmd, { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    { name: 'fs_read', description: 'Read file contents', inputSchema: { type: 'object', properties: { path: { type: 'string' } }, required: ['path'] } },
    { name: 'fs_write', description: 'Write file contents', inputSchema: { type: 'object', properties: { path: { type: 'string' }, content: { type: 'string' } }, required: ['path', 'content'] } },
    { name: 'fs_list', description: 'List directory contents', inputSchema: { type: 'object', properties: { path: { type: 'string' } }, required: ['path'] } },
    { name: 'shell', description: 'Run shell commands', inputSchema: { type: 'object', properties: { command: { type: 'string' } }, required: ['command'] } },
    { name: 'terraform', description: 'Run terraform commands', inputSchema: { type: 'object', properties: { command: { type: 'string' } }, required: ['command'] } },
    { name: 'gh', description: 'Run GitHub CLI commands', inputSchema: { type: 'object', properties: { command: { type: 'string' } }, required: ['command'] } },
    { name: 'aws', description: 'Run AWS CLI commands', inputSchema: { type: 'object', properties: { command: { type: 'string' } }, required: ['command'] } }
  ]
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'fs_read':
        return { content: [{ type: 'text', text: fs.readFileSync(args.path, 'utf8') }] };
      case 'fs_write':
        fs.writeFileSync(args.path, args.content);
        return { content: [{ type: 'text', text: 'File written successfully' }] };
      case 'fs_list':
        return { content: [{ type: 'text', text: fs.readdirSync(args.path).join('\n') }] };
      case 'shell':
        return { content: [{ type: 'text', text: exec(args.command) }] };
      case 'terraform':
        return { content: [{ type: 'text', text: exec(`terraform ${args.command}`) }] };
      case 'gh':
        return { content: [{ type: 'text', text: exec(`gh ${args.command}`) }] };
      case 'aws':
        return { content: [{ type: 'text', text: exec(`aws ${args.command}`) }] };
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return { content: [{ type: 'text', text: `Error: ${error.message}` }], isError: true };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main();
