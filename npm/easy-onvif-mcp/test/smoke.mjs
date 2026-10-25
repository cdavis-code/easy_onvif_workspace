// Smoke test for the published bundle: start the compiled server, complete an
// MCP handshake, and confirm the tool list and a real SOAP attempt make it back
// on stdout. Run from npm/easy-onvif-mcp: `npm test`.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const server = resolve(dirname(fileURLToPath(import.meta.url)), '../bin/easy-onvif-mcp.js');

/** Sends one JSON-RPC message per line and collects parsed replies. */
function runSession(messages, { waitMs = 6000 } = {}) {
  return new Promise((resolveReplies, reject) => {
    const child = spawn('node', [server], { stdio: ['pipe', 'pipe', 'pipe'] });
    const replies = [];
    let stdout = '';

    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString();
      for (const line of stdout.split('\n')) {
        if (!line.trim().startsWith('{')) continue;
        try {
          replies.push(JSON.parse(line));
        } catch {
          // Partial line; keep buffering.
        }
      }
    });

    child.on('error', reject);

    for (const message of messages) child.stdin.write(`${JSON.stringify(message)}\n`);

    setTimeout(() => {
      child.stdin.end();
      child.kill();
      resolveReplies(replies);
    }, waitMs);
  });
}

const handshake = [
  {
    jsonrpc: '2.0',
    id: 1,
    method: 'initialize',
    params: {
      protocolVersion: '2025-06-18',
      capabilities: {},
      clientInfo: { name: 'smoke', version: '0' },
    },
  },
  { jsonrpc: '2.0', method: 'notifications/initialized' },
];

test('handshake reports the server and a full tool list', async () => {
  const replies = await runSession([...handshake, { jsonrpc: '2.0', id: 2, method: 'tools/list' }]);

  const init = replies.find((r) => r.id === 1);
  assert.ok(init, 'no initialize response');
  assert.equal(init.result.serverInfo.name, 'easy-onvif-mcp');

  const list = replies.find((r) => r.id === 2);
  assert.ok(list, 'no tools/list response');
  const names = list.result.tools.map((tool) => tool.name);
  assert.ok(names.length > 30, `expected the full registry, got ${names.length} tools`);
  assert.ok(names.includes('onvif_connect'));
  assert.ok(names.includes('onvif_ptz_goto_preset'));
  assert.ok(names.every((name) => name.startsWith('onvif_')));
});

test('a tool call reaches the SOAP layer and fails cleanly, not silently', async () => {
  const replies = await runSession([
    ...handshake,
    {
      jsonrpc: '2.0',
      id: 3,
      method: 'tools/call',
      params: {
        name: 'onvif_connect',
        arguments: { host: '127.0.0.1:1', username: 'x', password: 'y' },
      },
    },
  ]);

  const result = replies.find((r) => r.id === 3);
  assert.ok(result, 'the compiled server dropped the tool response');
  // Unreachable device: an isError payload proves the fetch adapter ran and
  // the error was reported, rather than an XMLHttpRequest crash swallowed by
  // the JSON-RPC peer sink.
  assert.equal(result.result.isError, true);
  assert.match(result.result.content[0].text, /onvif_connect failed/);
});
