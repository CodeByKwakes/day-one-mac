#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const temp = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-routes-')));
const env = { ...process.env, HOME: temp, DAY_ONE_MAC_STATE_ROOT: path.join(temp, 'state'), DAY_ONE_MAC_STATE_DIR: path.join(temp, 'state') };
const run = args => spawnSync('/bin/bash', [path.join(root, 'scripts/day-one-mac'), ...args], { env, encoding: 'utf8', timeout: 60000 });
try {
  const entry = run([]);
  assert.equal(entry.status, 0, entry.stderr);
  assert.match(entry.stdout, /AI-assisted/);
  assert.match(entry.stdout, /Manual/);
  assert(!fs.existsSync(env.DAY_ONE_MAC_STATE_ROOT));
  for (const command of ['setup', 'install', 'finalize', 'clean', 'reset-development', 'remove', 'prepare-existing']) {
    const result = run([command, '--apply', '--yes']);
    assert.equal(result.status, 2, `${command}: ${result.stdout}${result.stderr}`);
    assert.match(result.stderr, /retired/);
    assert(!fs.existsSync(env.DAY_ONE_MAC_STATE_ROOT));
  }
  const direct = spawnSync('/bin/bash', [path.join(root, 'scripts/bootstrap-day-one-mac.sh'), '--apply', '--yes'], { env, encoding: 'utf8' });
  assert.equal(direct.status, 2);
  assert(!fs.existsSync(env.DAY_ONE_MAC_STATE_ROOT));
  const tools = run(['tool', '--list']);
  assert.equal(tools.status, 0, tools.stderr);
  assert.match(tools.stdout, /OmniRoute/);
  assert.doesNotMatch(tools.stdout, /\texecutable\t08\t/);
  const output = path.join(temp, 'Warp review é');
  const exported = run(['tool', '--module', '14', '--apply', '--yes']);
  assert.equal(exported.status, 0, exported.stdout + exported.stderr);
  assert(!fs.existsSync(path.join(env.DAY_ONE_MAC_STATE_ROOT, 'completed')));
  assert.equal(run(['tool', '--module', '14', '--check']).status, 0);
  fs.mkdirSync(output);
  const legacy = path.join(env.DAY_ONE_MAC_STATE_ROOT, 'advanced/completed/15');
  fs.mkdirSync(path.dirname(legacy), { recursive: true });
  fs.writeFileSync(legacy, 'historical-guide-hash\n');
  const audit = run(['tool', '--module', '21', '--apply', '--yes']);
  assert.equal(audit.status, 0, audit.stdout + audit.stderr);
  assert.equal(run(['tool', '--module', '21', '--check']).status, 0);
  assert.equal(fs.readFileSync(legacy, 'utf8'), 'historical-guide-hash\n');
  const report = run(['modules']);
  assert.doesNotMatch(report.stdout, /ready +15|record completion again/);
  fs.unlinkSync(legacy);
  fs.symlinkSync(path.join(temp, 'outside'), legacy);
  const unsafe = run(['tool', '--module', '21', '--apply', '--yes']);
  assert.notEqual(unsafe.status, 0, 'Unsafe historical state must still fail');
  console.log('Two-route entry, retired commands and independent utility prerequisites passed.');
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
