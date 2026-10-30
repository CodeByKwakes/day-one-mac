#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { buildAgents } = require('../../tools/build-agents.cjs');
const root = path.resolve(__dirname, '../..');

const check = spawnSync(process.execPath, ['tools/build-agents.cjs', '--check'], {cwd: root, encoding: 'utf8'});
assert.equal(check.status, 0, check.stdout + check.stderr);
const instruction = path.join(root, 'CLAUDE.md');
assert(fs.lstatSync(instruction).isSymbolicLink());
assert.equal(fs.realpathSync(instruction), path.join(root, 'AGENTS.md'));
for (const entry of fs.readdirSync(path.join(root, '.agents/skills'), {withFileTypes:true}).filter(e => e.isDirectory())) {
  const link = path.join(root, '.claude/skills', entry.name);
  assert(fs.lstatSync(link).isSymbolicLink(), `Claude skill must share source: ${entry.name}`);
  assert.equal(fs.realpathSync(link), fs.realpathSync(path.join(root, '.agents/skills', entry.name)));
  assert(fs.existsSync(path.join(link, 'SKILL.md')));
}

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-roles-'));
try {
  for (const directory of ['config/catalogs', 'templates/agents']) {
    fs.mkdirSync(path.dirname(path.join(temp, directory)), {recursive: true});
    fs.cpSync(path.join(root, directory), path.join(temp, directory), {recursive:true});
  }
  const source = path.join(temp, 'templates/agents/shared/day-one-planner.md');
  fs.appendFileSync(source, '\nFixture policy change: preserve the selected installation owner.\n');
  const generated = buildAgents(temp);
  for (const platform of ['codex', 'claude', 'copilot']) {
    const suffix = platform === 'codex' ? 'toml' : platform === 'claude' ? 'md' : 'agent.md';
    const output = generated.get(`templates/agents/${platform}/day-one-planner.${suffix}`);
    assert(output.includes('Fixture policy change: preserve the selected installation owner.'));
  }
  for (const role of ['planner', 'verifier']) {
    const codex = generated.get(`templates/agents/codex/day-one-${role}.toml`);
    assert.match(codex, /shell_tool = false/);
    assert.match(codex, /plugins = false/);
    const claude = generated.get(`templates/agents/claude/day-one-${role}.md`);
    assert.match(claude, /tools: Read, Glob, Grep\npermissionMode: plan/);
  }
  fs.renameSync(source, source + '.real');
  fs.symlinkSync(source + '.real', source);
  assert.throws(() => buildAgents(temp), /Symlink agent path/);
} finally { fs.rmSync(temp, {recursive:true, force:true}); }
console.log('PASS: shared agent policy propagation, read-only capabilities and Claude source symlinks');
