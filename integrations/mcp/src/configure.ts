#!/usr/bin/env node
import * as fs from 'node:fs/promises';
import { constants } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export type ClientName = 'all' | 'claude' | 'codex' | 'vscode' | 'raycast';
export type Launch = 'direct' | 'npm' | 'docker';
export type Command = { command: string; args: string[]; env?: Record<string, string> };
export interface ConfigurationOptions { client: ClientName; launch: Launch; npmCli?: string; image?: string }
const usage = 'Usage: day-one-mac-mcp-configure [--client all|claude|codex|vscode|raycast] [--launch direct|npm|docker] [--npm-cli ABSOLUTE_PATH] [--image IMAGE]';

export function parseOptions(args: string[]): ConfigurationOptions {
  const options: ConfigurationOptions = { client: 'all', launch: 'direct' };
  const seen = new Set<string>();
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i], value = args[i + 1];
    if (seen.has(key) || !value || value.startsWith('--')) throw Error(usage);
    seen.add(key);
    if (key === '--client' && ['all', 'claude', 'codex', 'vscode', 'raycast'].includes(value)) options.client = value as ClientName;
    else if (key === '--launch' && ['direct', 'npm', 'docker'].includes(value)) options.launch = value as Launch;
    else if (key === '--npm-cli' && path.isAbsolute(value)) options.npmCli = value;
    else if (key === '--image' && /^[a-zA-Z0-9][a-zA-Z0-9._:/@-]{0,254}$/.test(value)) options.image = value;
    else throw Error(usage);
  }
  if (options.npmCli && options.launch !== 'npm') throw Error('--npm-cli requires --launch npm');
  if (options.image && options.launch !== 'docker') throw Error('--image requires --launch docker');
  return options;
}

async function executable(name: string) {
  for (const dir of (process.env.PATH ?? '').split(path.delimiter).filter(Boolean)) {
    const candidate = path.resolve(dir, name);
    try { await fs.access(candidate, constants.X_OK); if ((await fs.stat(candidate)).isFile()) return candidate; } catch { /* Try the next PATH entry. */ }
  }
  throw Error(`${name} is not executable on PATH. Open a terminal with the approved tool installation available.`);
}

export async function configuration(options: ConfigurationOptions) {
  const metadata = JSON.parse(await fs.readFile(new URL('../../package.json', import.meta.url), 'utf8')) as { name: string; version: string };
  let server: Command;
  if (options.launch === 'docker') {
    server = { command: await executable('docker'), args: ['run', '-i', '--rm', '--read-only', '--cap-drop=ALL', '--security-opt=no-new-privileges', options.image ?? `day-one-mac-mcp:${metadata.version}`] };
  } else {
    const node = await fs.realpath(process.execPath);
    const entry = fileURLToPath(new URL('./index.js', import.meta.url));
    await fs.access(entry, constants.R_OK);
    if (options.launch === 'direct') server = { command: node, args: [entry] };
    else {
      const discoveredNpm = options.npmCli ? undefined : await executable('npm').catch(() => undefined);
      const candidates = (options.npmCli ? [options.npmCli] : [process.env.npm_execpath, discoveredNpm, path.resolve(path.dirname(node), '../lib/node_modules/npm/bin/npm-cli.js')]).filter((v): v is string => Boolean(v));
      let npm: string | undefined;
      for (const candidate of candidates) {
        try {
          const resolved = await fs.realpath(candidate);
          if (path.basename(resolved) === 'npm-cli.js' && (await fs.stat(resolved)).isFile()) { npm = resolved; break; }
        } catch { /* Try the next npm installation path. */ }
      }
      if (!npm) throw Error('Cannot locate npm-cli.js; provide --npm-cli with its absolute path.');
      server = { command: node, args: [npm, 'exec', '--yes', '--ignore-scripts', `--package=${metadata.name}@${metadata.version}`, '--', 'day-one-mac-mcp'],
        env: { PATH: [path.dirname(node), '/usr/bin', '/bin', '/usr/sbin', '/sbin'].join(path.delimiter) } };
    }
  }
  const codex = ['[mcp_servers.day_one_mac]', `command = ${JSON.stringify(server.command)}`, `args = ${JSON.stringify(server.args)}`, 'startup_timeout_sec = 60', 'tool_timeout_sec = 15'];
  if (server.env) codex.push('', '[mcp_servers.day_one_mac.env]', ...Object.entries(server.env).map(([key, value]) => `${key} = ${JSON.stringify(value)}`));
  return {
    claude: { mcpServers: { 'day-one-mac': server } },
    codex: codex.join('\n') + '\n',
    vscode: { servers: { 'day-one-mac': { type: 'stdio', ...server } } },
    raycast: { name: 'day-one-mac', transport: 'stdio', ...server }
  };
}

async function main() {
  if (process.argv.includes('--help')) { console.log(usage); return; }
  const options = parseOptions(process.argv.slice(2));
  const configs = await configuration(options);
  if (options.launch === 'npm') console.error('Registry launch configuration only: verify this exact package release is published by its intended owner before using it.');
  const selected = options.client === 'all' ? configs : configs[options.client];
  console.log(typeof selected === 'string' ? selected.trimEnd() : JSON.stringify(selected, null, 2));
}
const invoked = process.argv[1] ? await fs.realpath(process.argv[1]).catch(() => undefined) : undefined;
if (invoked && fileURLToPath(import.meta.url) === invoked) {
  main().catch(error => { console.error((error as Error).message); process.exitCode = 1; });
}
