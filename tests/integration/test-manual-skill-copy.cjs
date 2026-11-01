#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '../..');
const guide = fs.readFileSync(path.join(root, 'docs/setup/manual/ai/day-one-skills.md'), 'utf8');
const block = heading => guide.split(heading)[1].match(/```bash\n([\s\S]*?)\n\s*```/)[1];
const copy = block('## Install by manual copy without Node or Git');
const verify = block('## Verify and start');
const link = block('## Link skills in an existing project');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-manual-copy-'));
try {
  for (const shell of ['/bin/bash', '/bin/zsh']) {
    const work = path.join(temp, path.basename(shell), 'Setup é');
    const source = path.join(temp, path.basename(shell), 'Reviewed source é');
    const packageDir = path.join(source, 'skills/day-one-mac');
    fs.mkdirSync(work, {recursive: true});
    for (const file of ['SKILL.md', 'references/workflows/day-one-check.md', 'assets/example.txt']) {
      fs.mkdirSync(path.dirname(path.join(packageDir, file)), {recursive: true});
      fs.writeFileSync(path.join(packageDir, file), `fixture: ${file}\n`);
    }
    const run = script => spawnSync(shell, shell.endsWith('zsh') ? ['-f', '-c', script] : ['--noprofile', '--norc', '-c', script], {
      cwd: work, encoding: 'utf8', env: {...process.env, PATH: '/usr/bin:/bin:/usr/sbin:/sbin', DAY_ONE_SOURCE: source},
    });
    assert.notEqual(run('command -v npx').status, 0, 'The copy fixture must not have npx available');
    for (const script of [copy, verify, link]) {
      const result = run(script);
      assert.equal(result.status, 0, result.stdout + result.stderr);
    }
    const installed = path.join(work, '.agents/skills/day-one-mac');
    assert(fs.existsSync(path.join(installed, 'assets/example.txt')));
    fs.writeFileSync(path.join(installed, 'keep.txt'), 'existing installation');
    assert.notEqual(run(copy).status, 0, 'A repeat copy must preserve the existing installation');
    assert.equal(fs.readFileSync(path.join(installed, 'keep.txt'), 'utf8'), 'existing installation');
    fs.rmSync(source, {recursive: true});
    assert.equal(run(verify).status, 0, 'Copied skill must remain usable without the source');
    assert.equal(fs.realpathSync(path.join(work, '.claude/skills/day-one-mac')), fs.realpathSync(installed));

    // Update in the original workspace while retaining its existing client link.
    const backup = path.join(work, 'recovery', 'original-skill');
    fs.mkdirSync(path.dirname(backup), {mode: 0o700});
    fs.renameSync(installed, backup);
    fs.cpSync(backup, packageDir, {recursive: true});
    fs.writeFileSync(path.join(packageDir, 'assets/example.txt'), 'updated fixture');
    for (const script of [copy, verify]) {
      const result = run(script);
      assert.equal(result.status, 0, result.stdout + result.stderr);
    }
    assert.equal(fs.readFileSync(path.join(installed, 'assets/example.txt'), 'utf8'), 'updated fixture');
    assert.equal(fs.readFileSync(path.join(backup, 'assets/example.txt'), 'utf8'), 'fixture: assets/example.txt\n');
    assert.equal(fs.realpathSync(path.join(work, '.claude/skills/day-one-mac')), fs.realpathSync(installed));

    fs.renameSync(installed, path.join(work, 'saved-skill'));
    fs.symlinkSync(path.join(work, 'missing-skill'), installed);
    assert.notEqual(run(copy).status, 0, 'A dangling destination link must also be preserved');
    assert(fs.lstatSync(installed).isSymbolicLink());
  }
} finally {
  fs.rmSync(temp, {recursive: true, force: true});
}
console.log('PASS: documented Bash/Zsh manual copy works without npx, preserves destinations, survives source removal and updates in the original workspace');
