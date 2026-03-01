#!/usr/bin/env node

const { spawn } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  prompt: 'mcp> '
});

const mcp = spawn('docker', ['exec', '-i', 'mcp-tools', 'node', '/mcp/mcp-server.js']);

let buffer = '';
let requestId = 1;

mcp.stdout.on('data', (data) => {
  buffer += data.toString();
  const lines = buffer.split('\n');
  buffer = lines.pop();
  
  lines.forEach(line => {
    if (line.trim()) {
      try {
        const response = JSON.parse(line);
        if (response.result?.content) {
          response.result.content.forEach(c => console.log(c.text));
        }
      } catch (e) {}
    }
  });
  rl.prompt();
});

function sendRequest(tool, args) {
  const request = {
    jsonrpc: '2.0',
    id: requestId++,
    method: 'tools/call',
    params: { name: tool, arguments: args }
  };
  mcp.stdin.write(JSON.stringify(request) + '\n');
}

console.log('MCP CLI - Available tools: shell, gh, ssh, kubectl, fs_read, fs_write, fs_list, terraform, aws');
console.log('Usage: <tool> <json-args>');
console.log('Example: shell {"command":"ls /workspace"}');
rl.prompt();

rl.on('line', (line) => {
  const [tool, ...rest] = line.trim().split(' ');
  if (!tool) {
    rl.prompt();
    return;
  }
  
  try {
    const args = rest.length ? JSON.parse(rest.join(' ')) : {};
    sendRequest(tool, args);
  } catch (e) {
    console.log('Error:', e.message);
    rl.prompt();
  }
});

rl.on('close', () => {
  mcp.kill();
  process.exit(0);
});
