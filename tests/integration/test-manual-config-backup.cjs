#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '../..');
const guide = fs.readFileSync(path.join(root, 'docs/shared/terminal-basics.md'), 'utf8');
const recipe = guide.split('2. Prepare the [private evidence folder]')[1].match(/```bash\n([\s\S]*?)\n\s*```/)[1];
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-manual-backup-'));
try {
  for (const shell of ['/bin/bash', '/bin/zsh']) {
    const fixture = path.join(temp, path.basename(shell), 'Private space é');
    const evidence = path.join(fixture, '.local/state/development-setup');
    fs.mkdirSync(evidence, {recursive: true, mode: 0o700});
    const target = path.join(fixture, 'config.toml');
    const run = extra => spawnSync(shell, shell.endsWith('zsh') ? ['-f', '-c', recipe.replaceAll('$HOME', '$BACKUP_FIXTURE')] : ['--noprofile', '--norc', '-c', recipe.replaceAll('$HOME', '$BACKUP_FIXTURE')], {
      encoding: 'utf8', env: {...process.env, BACKUP_FIXTURE: fixture, TARGET_FILE: target, ...extra},
    });
    const backup = result => {
      assert.equal(result.status, 0, result.stdout + result.stderr);
      const folder = result.stdout.match(/Recovery folder: (.+)/)?.[1];
      assert(folder, 'The recipe must identify the recovery folder');
      assert.equal(fs.statSync(folder).mode & 0o777, 0o700);
      return folder;
    };
    fs.writeFileSync(target, 'original fixture\n', {mode: 0o644});
    const first = backup(run());
    assert.equal(fs.statSync(path.join(first, 'original')).mode & 0o777, 0o600, 'Recovery files must be private even when the source is readable');
    fs.writeFileSync(target, 'second fixture\n');
    const second = backup(run());
    assert.notEqual(first, second);
    assert.equal(fs.readFileSync(path.join(first, 'original'), 'utf8'), 'original fixture\n');
    assert.equal(fs.readFileSync(path.join(second, 'original'), 'utf8'), 'second fixture\n');
    const bin = path.join(fixture, 'bin');
    fs.mkdirSync(bin);
    fs.writeFileSync(path.join(bin, 'cp'), '#!/bin/sh\nprintf "fixture copy failure\\n" >&2\nexit 73\n', {mode: 0o700});
    const failed = run({PATH: `${bin}:${process.env.PATH}`});
    assert.notEqual(failed.status, 0);
    assert.match(failed.stderr, /fixture copy failure/);
    assert(!failed.stdout.includes('Recovery folder:'), 'A failed copy must not announce success');
    fs.writeFileSync(path.join(bin, 'cp'), '#!/bin/sh\nprintf "incomplete copy\\n" > "$2"\n', {mode: 0o700});
    const mismatch = run({PATH: `${bin}:${process.env.PATH}`});
    assert.notEqual(mismatch.status, 0, 'A copy that differs from its source must fail verification');
    assert(!mismatch.stdout.includes('Recovery folder:'));
    fs.unlinkSync(target);
    const absent = backup(run());
    assert(fs.existsSync(path.join(absent, 'absent.txt')));
    assert(!fs.existsSync(path.join(absent, 'original')));
    fs.symlinkSync(path.join(fixture, 'missing-target'), target);
    assert.notEqual(run().status, 0, 'Reject dangling symlinks rather than recording absence');
    fs.unlinkSync(target);
    fs.mkdirSync(target);
    assert.notEqual(run().status, 0, 'Reject directories rather than recording absence');
  }
} finally {
  fs.rmSync(temp, {recursive: true, force: true});
}
console.log('PASS: documented Bash/Zsh backups preserve generations, privacy, absence and failure evidence');
