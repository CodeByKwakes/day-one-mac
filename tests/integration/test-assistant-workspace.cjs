#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const temp = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-assistant-')));
const env = { ...process.env, HOME: temp, DAY_ONE_MAC_STATE_ROOT: path.join(temp, 'state') };
const run = args => spawnSync('/bin/bash', [path.join(root, 'scripts/day-one-mac'), 'assistant', ...args], { env, cwd: temp, encoding: 'utf8' });
try {
  assert.equal(run(['--plan']).status, 0);
  assert(!fs.existsSync(env.DAY_ONE_MAC_STATE_ROOT));
  const output = path.join(temp, 'Assistant é with spaces');
  const result = run(['--export', output]);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.equal(fs.statSync(output).mode & 0o777, 0o700);
  assert.equal(run(['--check', output]).status, 0);
  assert.equal(fs.readlinkSync(path.join(output, '.claude/skills')), '../.agents/skills');
  const skills = fs.readdirSync(path.join(output, '.agents/skills'));
  assert.equal(skills.length, 6);
  for (const name of skills) {
    const text = fs.readFileSync(path.join(output, '.agents/skills', name, 'SKILL.md'), 'utf8');
    for (const match of text.matchAll(/\]\((\.\.\/[^)]+)\)/g)) {
      assert(fs.existsSync(path.resolve(output, '.agents/skills', name, match[1])), `${name}: ${match[1]}`);
    }
  }
  for (const [folder, suffix] of [['.codex/agents', '.toml'], ['.claude/agents', '.md'], ['.github/agents', '.agent.md']]) {
    assert.equal(fs.readdirSync(path.join(output, folder)).filter(x => x.endsWith(suffix)).length, 4);
  }
  assert.notEqual(run(['--export', output]).status, 0);
  fs.writeFileSync(path.join(output, 'session/notes.md'), 'Private decisions, no credentials.\n');
  assert.equal(run(['--check', output]).status, 0);
  fs.appendFileSync(path.join(output, 'AGENTS.md'), '\nchanged\n');
  assert.notEqual(run(['--check', output]).status, 0);
  const alias = path.join(temp, 'alias'); fs.symlinkSync(output, alias);
  assert.notEqual(run(['--export', path.join(alias, 'nested')]).status, 0);
  assert.notEqual(run(['--check', alias]).status, 0);
  assert(!fs.existsSync(path.join(temp, '.codex')));
  assert(!fs.existsSync(path.join(temp, '.claude')));
  console.log('Assistant workspace: portable references, shared skills, adapters, integrity and collision checks passed.');
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
