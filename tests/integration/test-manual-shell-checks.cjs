#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const guide = fs.readFileSync(path.join(root, 'docs/setup/manual/shell/chezmoi.md'), 'utf8');
const section = guide.split('### 5. Validate the active result')[1].split('### 6.')[0];
const commands = [...section.matchAll(/```bash\n([\s\S]*?)```/g)].map(match => match[1]);
assert.equal(commands.length, 2);
assert(!commands.join('\n').includes('/opt/homebrew/bin/zsh'), 'Base validation must work with Apple Zsh');
if (process.platform !== 'darwin') {
  console.log('SKIP: Apple Zsh command fixtures require macOS');
  process.exit(0);
}
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-shell-check-'));
const fixture = path.join(temp, 'User é with spaces');
fs.mkdirSync(path.join(fixture, '.config/zsh'), {recursive:true});
try {
  const marker = path.join(fixture, 'must-not-execute');
  fs.writeFileSync(path.join(fixture, '.zshrc'), 'touch "$FIXTURE_ROOT/must-not-execute"\n');
  fs.writeFileSync(path.join(fixture, '.zprofile'), 'export EXAMPLE=value\n');
  fs.writeFileSync(path.join(fixture, '.config/zsh/path.zsh'), 'typeset -U path PATH\n');
  const run = command => spawnSync('/bin/bash', ['-c', command.replaceAll('$HOME', '$FIXTURE_ROOT')],
    {encoding:'utf8', env:{PATH:'/usr/bin:/bin', FIXTURE_ROOT:fixture}});
  for (const command of commands) {
    const result = run(command);
    assert.equal(result.status, 0, result.stderr);
  }
  assert(!fs.existsSync(marker), 'Syntax validation must never execute startup files');
  fs.writeFileSync(path.join(fixture, '.config/zsh/aliases.zsh'), 'if then\n');
  assert.notEqual(run(commands[1]).status, 0, 'An existing invalid optional file must fail');
  fs.writeFileSync(path.join(fixture, '.config/zsh/aliases.zsh'), 'alias ll="ls -l"\n');
  assert.equal(run(commands[1]).status, 0);
  fs.writeFileSync(path.join(fixture, '.zshrc'), 'if then\n');
  assert.notEqual(run(commands[0]).status, 0, 'Invalid required shell configuration must fail');
  console.log('PASS: documented Apple Zsh syntax checks support absent optional aliases, reject invalid files, preserve Unicode paths and never execute startup files');
} finally {fs.rmSync(temp, {recursive:true, force:true});}
