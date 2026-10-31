#!/usr/bin/env node
import { serveStdio } from '@modelcontextprotocol/server/stdio';
import { readFile } from 'node:fs/promises';
import { createServer, type Guides } from './server.js';

async function main() {
  const args = process.argv.slice(2);
  let allowChanges = false;
  let backupDir: string | undefined;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--allow-changes' && !allowChanges) allowChanges = true;
    else if (args[i] === '--backup-dir' && !backupDir && args[i + 1] && !args[i + 1].startsWith('--')) backupDir = args[++i];
    else throw Error('Usage: node dist/src/index.js [--allow-changes --backup-dir ABSOLUTE_PRIVATE_DIRECTORY]');
  }
  if (allowChanges !== Boolean(backupDir)) throw Error('--allow-changes and --backup-dir must be supplied together.');
  const guides = JSON.parse(await readFile(new URL('../guides.json', import.meta.url), 'utf8')) as Guides;
  await serveStdio(() => createServer(guides, { allowChanges, backupDir }));
}
main().catch(error => { console.error((error as Error).message); process.exitCode = 1; });
