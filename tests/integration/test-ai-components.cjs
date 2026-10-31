#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { buildAgents } = require('../../tools/build-agents.cjs');
const root = path.resolve(__dirname, '../..');

const ownedSkills = ['day-one-mac-maintenance'];
const localSkills = fs.readdirSync(path.join(root, '.agents/skills')).filter(name => name !== '.DS_Store').sort();
assert.deepEqual(localSkills.filter(name => name !== 'gstack'), ownedSkills, 'Only the owned maintenance skill and optional local gstack dependency belong here');
assert.deepEqual(fs.readdirSync(path.join(root, '.claude/skills')).filter(name => name !== '.DS_Store').sort(), ownedSkills, 'Claude aliases must expose only project-owned skills');
const lock = JSON.parse(fs.readFileSync(path.join(root, 'skills-lock.json'), 'utf8'));
assert.equal(lock.version, 1);
assert.deepEqual(Object.keys(lock.skills), ['gstack'], 'Only the reviewed optional contributor dependency belongs in the lock');
assert.deepEqual(Object.keys(lock.skills.gstack).sort(), ['computedHash', 'skillPath', 'source', 'sourceType']);
assert.equal(lock.skills.gstack.source, 'garrytan/gstack');
assert.equal(lock.skills.gstack.sourceType, 'github');
assert.equal(lock.skills.gstack.skillPath, 'SKILL.md');
assert.match(lock.skills.gstack.computedHash, /^[a-f0-9]{64}$/);

const check = spawnSync(process.execPath, ['tools/build-agents.cjs', '--check'], {cwd: root, encoding: 'utf8'});
assert.equal(check.status, 0, check.stdout + check.stderr);
const instruction = path.join(root, 'CLAUDE.md');
assert(fs.lstatSync(instruction).isSymbolicLink());
assert.equal(fs.realpathSync(instruction), path.join(root, 'AGENTS.md'));
for (const name of ownedSkills) {
  const link = path.join(root, '.claude/skills', name);
  assert(fs.lstatSync(link).isSymbolicLink(), `Claude skill must share source: ${name}`);
  assert.equal(fs.realpathSync(link), fs.realpathSync(path.join(root, '.agents/skills', name)));
  assert(fs.existsSync(path.join(link, 'SKILL.md')));
}

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-roles-'));
try {
  // Exercise the lint boundary without installing or modifying any real toolkit.
  const lintRoot = path.join(temp, 'lint fixture é');
  fs.mkdirSync(path.join(lintRoot, 'tools'), {recursive: true});
  fs.copyFileSync(path.join(root, 'tools/lint.sh'), path.join(lintRoot, 'tools/lint.sh'));
  const owned = ['tools/owned.sh', '.agents/skills/day-one-mac-maintenance/check.sh', '.agents/skills/unreviewed/check.sh'];
  const dependencies = ['.agents/skills/gstack/vendor.sh', 'node_modules/pkg/dependency.sh', '.husky/_/hook.sh'];
  for (const file of [...owned, ...dependencies]) {
    fs.mkdirSync(path.dirname(path.join(lintRoot, file)), {recursive: true});
    fs.writeFileSync(path.join(lintRoot, file), '#!/bin/bash\ntrue\n');
  }
  const bin = path.join(temp, 'bin');
  const capture = path.join(temp, 'lint-inputs.txt');
  fs.mkdirSync(bin);
  fs.writeFileSync(path.join(bin, 'shellcheck'), '#!/bin/sh\nif [ "$1" = --version ]; then\n  printf "version: fixture\\n"\nelse\n  printf "%s\\n" "$@" > "$LINT_FIXTURE_CAPTURE"\nfi\n', {mode: 0o700});
  const lint = spawnSync('/bin/bash', [path.join(lintRoot, 'tools/lint.sh')], {encoding: 'utf8', env: {...process.env, PATH: `${bin}:${process.env.PATH}`, LINT_FIXTURE_CAPTURE: capture}});
  assert.equal(lint.status, 0, lint.stdout + lint.stderr);
  const lintInputs = fs.readFileSync(capture, 'utf8').split('\n');
  for (const file of owned) assert(lintInputs.includes(path.join(lintRoot, file)), `Must lint owned/unreviewed source: ${file}`);
  for (const file of dependencies) assert(!lintInputs.includes(path.join(lintRoot, file)), `Must exclude dependency: ${file}`);

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
