#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync, execFileSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-site-'));
try {
  const fixture = path.join(temporary, 'source');
  for (const file of ['tools/build-docs-site.cjs', 'tools/export-docs.cjs', 'tools/docs/docs-browser.html',
    'tools/docs/docs-browser.css', 'tools/docs/docs-browser.js', 'tools/vendor/markdown-it/markdown-it.min.js',
    'tools/vendor/markdown-it/LICENSE']) {
    assert(fs.existsSync(path.join(root, file)), `Missing site source: ${file}`);
    fs.mkdirSync(path.dirname(path.join(fixture, file)), { recursive: true });
    fs.copyFileSync(path.join(root, file), path.join(fixture, file));
  }
  fs.mkdirSync(path.join(fixture, 'config'));
  fs.mkdirSync(path.join(fixture, 'docs'));
  fs.writeFileSync(path.join(fixture, 'config/document-sources.txt'), 'docs/START-HERE.md\n');
  fs.writeFileSync(path.join(fixture, 'docs/START-HERE.md'), '# Start here\n\nA reviewed guide.\n');
  fs.writeFileSync(path.join(fixture, 'docs/private.md'), 'PRIVATE_SENTINEL');
  const run = (args, status = 0) => {
    const result = spawnSync(process.execPath, [path.join(fixture, 'tools/build-docs-site.cjs'), ...args], { encoding: 'utf8' });
    assert.equal(result.status, status, result.stdout + result.stderr);
    return result;
  };
  const output = path.join(temporary, 'website with spaces');
  const revision = 'a'.repeat(40);
  run(['--output', output, '--revision', 'not-a-commit'], 1);
  assert(!fs.existsSync(output), 'Invalid revision must not create output');
  run(['--output', output, '--revision', revision]);
  const site = fs.readFileSync(path.join(output, 'index.html'), 'utf8');
  const snapshot = JSON.parse(fs.readFileSync(path.join(output, 'snapshot.json'), 'utf8'));
  assert.equal(snapshot.revision, revision);
  assert.match(snapshot.contentSha256, /^[a-f0-9]{64}$/);
  assert.match(site, /data-download="day-one-mac-offline.zip"/);
  assert(site.includes(snapshot.contentSha256.slice(0, 12)));
  assert(!site.includes('PRIVATE_SENTINEL'));
  const zip = path.join(output, 'day-one-mac-offline.zip');
  const entries = execFileSync('unzip', ['-Z1', zip], { encoding: 'utf8' });
  assert(entries.includes('day-one-mac-guide/index.html'));
  assert(!/private\.md|\.git\/|node_modules\/|\.zip/.test(entries));
  const readZip = file => execFileSync('unzip', ['-p', zip, `day-one-mac-guide/${file}`], { encoding: 'utf8' });
  assert.deepEqual(JSON.parse(readZip('snapshot.json')), snapshot, 'Offline download matches website provenance');
  assert(!readZip('index.html').includes('data-download='), 'Offline copy has no broken ZIP download');
  assert.equal(readZip('docs/START-HERE.md'), '# Start here\n\nA reviewed guide.\n');
  run(['--output', output], 1);
  assert.equal(fs.readFileSync(path.join(output, 'index.html'), 'utf8'), site, 'Existing output is preserved');
  const link = path.join(temporary, 'linked-output'); fs.symlinkSync(output, link);
  run(['--output', link], 1);
  const changed = path.join(temporary, 'changed');
  fs.appendFileSync(path.join(fixture, 'tools/docs/docs-browser.css'), '\n/* changed reader */\n');
  run(['--output', changed]);
  const next = JSON.parse(fs.readFileSync(path.join(changed, 'snapshot.json'), 'utf8'));
  assert.equal(next.revision, null, 'Unspecified revision is not invented');
  assert.notEqual(next.contentSha256, snapshot.contentSha256, 'Reader assets participate in the fingerprint');
  console.log('PASS: standalone website, matching offline ZIP, asset fingerprint, revision validation, private-file exclusion and no-overwrite');
} finally { fs.rmSync(temporary, { recursive: true, force: true }); }
