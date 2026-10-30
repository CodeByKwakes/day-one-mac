import assert from 'node:assert/strict';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
const transport = new StdioClientTransport({ command: process.argv[2] ?? 'docker', args: [
  'run', '-i', '--rm', '--read-only', '--cap-drop=ALL', '--security-opt=no-new-privileges', process.argv[3] ?? 'day-one-mac-mcp:0.1.0'
], stderr: 'inherit' });
const client = new Client({ name: 'day-one-mac-docker-smoke', version: '0.1.0' });
try {
  await client.connect(transport);
  assert.equal((await client.listTools()).tools.length, 4);
  assert.equal((await client.listResources()).resources.length, 8);
  assert.equal((await client.listPrompts()).prompts.length, 2);
  const host = await client.callTool({ name: 'check_host', arguments: {} });
  const metadata = JSON.parse((host.content as {text: string}[])[0].text);
  assert.equal(metadata.platform, 'linux'); assert.equal(metadata.native_mac, false);
  for (const dry_run of [true, false]) {
    const denied = await client.callTool({ name: 'desktop_click', arguments: { mode: 'stage-manager-only', dry_run } });
    assert.equal(denied.isError, true);
  }
  console.log('PASS: final read-only non-root Docker image: discovery, Linux detection and host-operation denial');
} finally { await client.close(); await transport.close(); }
