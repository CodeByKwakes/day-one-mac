'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-hook-'));
const fixture = path.join(temporary, 'Contributor é with spaces');
try {
  fs.mkdirSync(fixture);
  fs.symlinkSync(path.join(root, 'node_modules'), path.join(fixture, 'node_modules'));
  for (const name of ['package.json', '.markdownlint-cli2.jsonc']) {
    fs.copyFileSync(path.join(root, name), path.join(fixture, name));
  }
  const archived = path.join(fixture, 'maintainers/archive/source');
  fs.mkdirSync(archived, {recursive:true});
  const archiveSource = path.join(root, 'maintainers/archive/2026-10-31-day-one-mac-mcp/source');
  fs.copyFileSync(path.join(archiveSource, 'package.json'), path.join(archived, 'package.json'));
  const original = fs.readFileSync(path.join(archiveSource, 'integrations/mcp/README.md'));
  fs.writeFileSync(path.join(archived, 'README.md'), original);
  fs.writeFileSync(path.join(fixture, 'README.md'), '# Contributor fixture\n\nCurrent documentation.\n');
  fs.writeFileSync(path.join(fixture, '.gitignore'), 'node_modules/\n');
  const env = {...process.env};
  const localNames = spawnSync('git', ['rev-parse', '--local-env-vars'], {encoding:'utf8'});
  assert.equal(localNames.status, 0, localNames.stderr);
  for (const name of localNames.stdout.trim().split('\n')) delete env[name];
  for (const args of [['init', '-q'], ['add', '.']]) {
    const result = spawnSync('git', args, {cwd:fixture, env, encoding:'utf8'});
    assert.equal(result.status, 0, result.stderr);
  }
  const checked = spawnSync('/bin/bash', [path.join(root, '.husky/pre-commit')], {
    cwd:fixture, env, encoding:'utf8', timeout:60000,
  });
  assert.equal(checked.status, 0, 'The current hook must lint archived Markdown using current root rules, without loading historical package tasks.\n' + checked.stdout + checked.stderr);
  assert.deepEqual(fs.readFileSync(path.join(archived, 'README.md')), original, 'Linting must preserve archived bytes');
  console.log('PASS: contributor hook applies current root rules across an archived package and preserves historical bytes');
} finally {fs.rmSync(temporary, {recursive:true, force:true});}
