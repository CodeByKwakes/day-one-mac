#!/usr/bin/env node
'use strict';
// Contributor build only. The output is static and needs no installed manager.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { spawnSync } = require('node:child_process');
const { exportDocumentation } = require('./export-docs.cjs');

function main(args) {
  const options = {};
  while (args.length) {
    const key = args.shift();
    if (key === '--help') { console.log('Usage: node tools/build-docs-site.cjs --output NEW_DIRECTORY [--revision COMMIT_SHA]\nRequires Node.js 22.20+ and zip. Builds only; never serves or publishes.'); return; }
    if (!['--output', '--revision'].includes(key) || options[key] || !args.length) throw new Error('Use --output NEW_DIRECTORY and optional --revision COMMIT_SHA once each.');
    options[key] = args.shift();
  }
  if (!options['--output']) throw new Error('Choose a new output directory.');
  const output = path.resolve(options['--output']);
  const revision = options['--revision'] ?? null;
  if (revision !== null && !/^[a-f0-9]{40}$/.test(revision)) throw new Error('Revision must be a full lowercase Git commit SHA.');
  try { fs.lstatSync(output); throw new Error('Output already exists; choose a new directory.'); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  const probe = spawnSync('zip', ['-v'], { encoding: 'utf8', timeout: 10000 });
  if (probe.error || probe.status !== 0) throw new Error('Install the zip command before building the website.');
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-offline-'));
  try {
    const offline = exportDocumentation({ format: 'html', output: path.join(temporary, 'day-one-mac-guide'), revision });
    const website = exportDocumentation({ format: 'html', output, revision, offlineDownload: true });
    if (offline.contentSha256 !== website.contentSha256) throw new Error('Sources changed during export. Choose a fresh output and build again.');
    const archive = spawnSync('zip', ['-q', '-X', '-r', path.join(output, 'day-one-mac-offline.zip'), 'day-one-mac-guide'], {
      cwd: temporary, encoding: 'utf8', timeout: 60000,
    });
    if (archive.error || archive.status !== 0) throw new Error('Offline archive failed; incomplete output retained for inspection.');
    fs.writeFileSync(path.join(output, '.nojekyll'), '', { flag: 'wx', mode: 0o600 });
    console.log(`Website: ${path.join(output, 'index.html')}\nOffline download: ${path.join(output, 'day-one-mac-offline.zip')}\nSnapshot: ${website.contentSha256}`);
  } finally { fs.rmSync(temporary, { recursive: true, force: true }); }
}
if (require.main === module) { try { main(process.argv.slice(2)); } catch (error) { console.error(error.message); process.exitCode = 1; } }
module.exports = { main };
