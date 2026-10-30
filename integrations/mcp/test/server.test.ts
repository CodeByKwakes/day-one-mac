import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
import { DesktopClick, CONFIRMATION, readDesktopPreference, type Host } from '../src/server.js';
import { serverSpec } from '../src/spec.js';

async function fixture() {
  const dir = await fs.realpath(await fs.mkdtemp(path.join(os.tmpdir(), 'day-one-mcp-')));
  let value: boolean | null = true;
  let writes = 0;
  let now = 0;
  const host: Host = { platform: 'darwin', arch: 'arm64',
    readPreference: async () => value,
    writePreference: async next => { writes++; value = next; }, version: async () => 'fixture' };
  const service = new DesktopClick({ allowChanges: true, backupDir: dir, lockDir: dir, host, now: () => now });
  return { dir, host, service, writes: () => writes, value: () => value,
    setValue: (v: boolean | null) => { value = v; }, expire: () => { now = 60001; } };
}
const preview = (service: DesktopClick) => service.call({ mode: 'stage-manager-only', dry_run: true });
const apply = (service: DesktopClick, token: string, extra = {}) => service.call({ mode: 'stage-manager-only', dry_run: false, preview_token: token, confirmation: CONFIRMATION, ...extra });

test('preview is read-only; apply backs up original and verifies; replay fails', async () => {
  const f = await fixture();
  try {
    const p = await preview(f.service); assert.equal(f.writes(), 0);
    assert.equal(p.dry_run, true); assert.equal(p.before, true);
    const output = await apply(f.service, p.preview_token!);
    assert.equal(output.applied, true); assert.equal(f.value(), false);
    const backup = JSON.parse(await fs.readFile(output.backup!, 'utf8'));
    assert.equal(backup.before, true); assert.equal((await fs.stat(output.backup!)).mode & 0o777, 0o600);
    await assert.rejects(apply(f.service, p.preview_token!), /missing/);
    assert.equal(f.writes(), 1);
  } finally { await fs.rm(f.dir, { recursive: true }); }
});
for (const scenario of ['confirmation', 'token', 'expiry', 'drift', 'mode', 'lock', 'permissions'] as const) {
  test(`reject ${scenario} without writes`, async () => {
    const f = await fixture();
    try {
      const p = await preview(f.service);
      let extra = {};
      if (scenario === 'confirmation') extra = { confirmation: 'yes' };
      if (scenario === 'token') extra = { preview_token: '00000000-0000-4000-8000-000000000000' };
      if (scenario === 'expiry') f.expire();
      if (scenario === 'drift') f.setValue(null);
      if (scenario === 'mode') extra = { mode: 'always' };
      if (scenario === 'lock') await fs.writeFile(path.join(f.dir, 'desktop-click.lock'), 'another client');
      if (scenario === 'permissions') await fs.chmod(f.dir, 0o755);
      await assert.rejects(apply(f.service, p.preview_token!, extra)); assert.equal(f.writes(), 0);
    } finally { await fs.rm(f.dir, { recursive: true }); }
  });
}
test('startup opt-in and supported platform are mandatory', async () => {
  const f = await fixture();
  try {
    const disabled = new DesktopClick({ host: f.host }); const p = await preview(disabled);
    await assert.rejects(apply(disabled, p.preview_token!), /Changes disabled/);
    for (const platform of ['linux', 'win32']) await assert.rejects(preview(new DesktopClick({ host: { ...f.host, platform } })), /Native Apple/);
    await assert.rejects(preview(new DesktopClick({ host: { ...f.host, arch: 'x64' } })), /Native Apple/);
    assert.equal(f.writes(), 0);
  } finally { await fs.rm(f.dir, { recursive: true }); }
});
test('symlink backup directory is rejected', async () => {
  const f = await fixture();
  try {
    const link = path.join(f.dir, 'link'); await fs.symlink(f.dir, link);
    const service = new DesktopClick({ host: f.host, allowChanges: true, backupDir: link });
    const p = await preview(service); await assert.rejects(apply(service, p.preview_token!), /real directories/);
    assert.equal(f.writes(), 0);
  } finally { await fs.rm(f.dir, { recursive: true }); }
});
test('absent key recovery deletes only the introduced key', async () => {
  const f = await fixture();
  try {
    f.setValue(null); const p = await preview(f.service); const output = await apply(f.service, p.preview_token!);
    const record = JSON.parse(await fs.readFile(output.backup!, 'utf8'));
    assert.deepEqual(record.restore, ['defaults', 'delete', 'com.apple.WindowManager', 'EnableStandardClickToShowDesktop']);
  } finally { await fs.rm(f.dir, { recursive: true }); }
});
test('write or verification failure retains backup and clears owned lock', async () => {
  const f = await fixture();
  try {
    f.host.writePreference = async () => { throw Error('fixture write failed'); };
    const p = await preview(f.service); await assert.rejects(apply(f.service, p.preview_token!), /Recovery evidence retained/);
    assert.equal((await fs.readdir(f.dir)).filter(x => x.endsWith('.json')).length, 1);
    assert(!(await fs.readdir(f.dir)).includes('desktop-click.lock'));
    f.host.writePreference = async () => {};
    const next = await preview(f.service); await assert.rejects(apply(f.service, next.preview_token!), /verification failed/);
  } finally { await fs.rm(f.dir, { recursive: true }); }
});
test('independent server instances cannot apply while another holds the lock', async () => {
  const f = await fixture();
  try {
    let release!: () => void; let entered!: () => void;
    const started = new Promise<void>(r => { entered = r; });
    const wait = new Promise<void>(r => { release = r; });
    const original = f.host.writePreference;
    f.host.writePreference = async v => { entered(); await wait; await original(v); };
    const other = new DesktopClick({ host: f.host, allowChanges: true, backupDir: f.dir, lockDir: f.dir });
    const a = await preview(f.service), b = await preview(other);
    const pending = apply(f.service, a.preview_token!); await started;
    await assert.rejects(apply(other, b.preview_token!), /lock/); release(); await pending;
    assert.equal(f.writes(), 1);
  } finally { await fs.rm(f.dir, { recursive: true }); }
});
test('stdio discovery, resource/prompt reads, invalid input and default denial', async () => {
  const transport = new StdioClientTransport({ command: process.execPath, args: [path.resolve('dist/src/index.js')], stderr: 'pipe' });
  const client = new Client({ name: 'day-one-mac-test', version: '0.1.0' });
  try {
    await client.connect(transport);
    const tools = (await client.listTools()).tools;
    assert.deepEqual(tools.map(t => t.name).sort(), ['check_host', 'desktop_click', 'list_guides', 'preview_desktop_click', 'read_guide']);
    assert(tools.every(t => t.annotations?.readOnlyHint === true), 'Default server must expose no mutation-capable tool');
    for (const name of serverSpec.readOnlyTools) assert.equal(tools.find(t => t.name === name)?.annotations?.readOnlyHint, true, `Unsafe or unknown allowlisted tool: ${name}`);
    assert.equal((await client.listResources()).resources.length, 11);
    assert.equal((await client.listPrompts()).prompts.length, 2);
    const resource = await client.readResource({ uri: 'day-one-mac://guide/macos' });
    assert.match((resource.contents[0] as { text: string }).text, /Prepare macOS/);
    const prompt = await client.getPrompt({ name: 'setup_plan', arguments: { topic: 'git' } });
    assert.match((prompt.messages[0].content as { text: string }).text, /explicit human approval/);
    const shortcuts = await client.callTool({name:'read_guide', arguments:{id:'shortcuts'}});
    assert.match(JSON.parse((shortcuts.content as {text:string}[])[0].text).text, /Send to Archive/);
    await assert.rejects(client.callTool({name:'apply_desktop_click', arguments:{mode:'always'}}), /not found/);
    for (const args of [{ id: '../../auth.json' }, { id: 'macos', path: '/etc/passwd' }]) {
      const invalid = await client.callTool({ name: 'read_guide', arguments: args }); assert.equal(invalid.isError, true);
    }
    await assert.rejects(client.getPrompt({ name: 'setup_plan', arguments: { topic: 'git', extra: 'reject me' } }));
    if (process.platform === 'darwin' && process.arch === 'arm64') {
      const defaultPreview = await client.callTool({ name: 'desktop_click', arguments: { mode: 'stage-manager-only' } });
      assert.equal(defaultPreview.isError, false);
      assert.equal(JSON.parse((defaultPreview.content as {text:string}[])[0].text).dry_run, true);
    }
    const denied = await client.callTool({ name: 'desktop_click', arguments: { mode: 'stage-manager-only', dry_run: false, confirmation: CONFIRMATION } });
    assert.equal(denied.isError, true);
    const host = await client.callTool({ name: 'check_host', arguments: {} }); assert.equal(host.isError, false);
  } finally { await client.close(); await transport.close(); }
});

test('mutation tool discovery requires startup opt-in; rejected apply creates no recovery files', async () => {
  const directory = await fs.realpath(await fs.mkdtemp(path.join(os.tmpdir(), 'day-one-mcp-discovery-')));
  const transport = new StdioClientTransport({command:process.execPath, args:[path.resolve('dist/src/index.js'), '--allow-changes', '--backup-dir', directory], stderr:'pipe'});
  const client = new Client({name:'day-one-opt-in-test', version:'0.1.0'});
  try {
    await client.connect(transport);
    const tools = (await client.listTools()).tools;
    assert.equal(tools.length, 6);
    assert.equal(tools.find(t => t.name === 'preview_desktop_click')?.annotations?.readOnlyHint, true);
    for (const name of ['apply_desktop_click', 'desktop_click']) {
      assert.equal(tools.find(t => t.name === name)?.annotations?.readOnlyHint, false);
      assert.equal(tools.find(t => t.name === name)?.annotations?.destructiveHint, true);
    }
    for (const name of serverSpec.readOnlyTools) assert.equal(tools.find(t => t.name === name)?.annotations?.readOnlyHint, true);
    const invalid = await client.callTool({name:'apply_desktop_click', arguments:{mode:'always', preview_token:'00000000-0000-4000-8000-000000000000', confirmation:CONFIRMATION}});
    assert.equal(invalid.isError, true);
    assert.deepEqual(await fs.readdir(directory), []);
  } finally { await client.close(); await transport.close(); await fs.rm(directory, {recursive:true}); }
});

test('different backup directories still serialize the same user preference', async () => {
  const f = await fixture();
  let release!: () => void;
  const pending: Promise<unknown>[] = [];
  try {
    const secondDir = path.join(f.dir, 'second-backups'); await fs.mkdir(secondDir, {mode: 0o700});
    let firstEntered!: () => void, secondEntered!: () => void, entries = 0;
    const firstStarted = new Promise<void>(r => { firstEntered = r; });
    const secondStarted = new Promise<void>(r => { secondEntered = r; });
    const wait = new Promise<void>(r => { release = r; });
    const original = f.host.writePreference;
    f.host.writePreference = async v => {
      if (++entries === 1) firstEntered(); else secondEntered();
      await wait; await original(v);
    };
    const other = new DesktopClick({host: f.host, allowChanges: true, backupDir: secondDir, lockDir: f.dir});
    const a = await preview(f.service), b = await preview(other);
    pending.push(apply(f.service, a.preview_token!)); await firstStarted;
    const second = apply(other, b.preview_token!).then(() => 'applied', () => 'rejected'); pending.push(second);
    assert.equal(await Promise.race([second, secondStarted.then(() => 'entered')]), 'rejected', 'Second writer bypassed the per-user lock');
    release(); await Promise.all(pending); assert.equal(f.writes(), 1);
  } finally { release?.(); await Promise.allSettled(pending); await fs.rm(f.dir, {recursive:true, force:true}); }
});

test('native adapter distinguishes booleans, missing keys, invalid types and command errors', async () => {
  for (const [raw,expected] of [['0',false],['1',true]] as const) {
    const calls: string[][] = [];
    const value = await readDesktopPreference(async (file,args) => {
      assert.equal(file, '/usr/bin/defaults'); calls.push(args);
      return args[0] === 'read-type' ? 'Type is boolean' : raw;
    });
    assert.equal(value,expected); assert.equal(calls.length,2);
  }
  assert.equal(await readDesktopPreference(async () => {throw {code:1,stderr:'The domain/default pair does not exist'};}),null);
  await assert.rejects(readDesktopPreference(async () => 'Type is string'),/not a boolean/);
  await assert.rejects(readDesktopPreference(async (_,args) => args[0] === 'read-type' ? 'Type is boolean' : 'garbage'),/Unexpected/);
  for (const failure of [{code:1,stderr:'Permission denied'}, {code:'ETIMEDOUT'}, {code:'ENOENT'}]) {
    await assert.rejects(readDesktopPreference(async () => {throw failure;}));
  }
});
