#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const tmp = fs.mkdtempSync('/private/tmp/day-one-profile-replacement-');
const home = path.join(tmp, 'home with spaces é');
const user = path.join(home, 'Library/Application Support/Code/User');
const state = path.join(home, 'Profile backups');
const env = { ...process.env, HOME: home, DAY_ONE_MAC_STATE_ROOT: state, DAY_ONE_MAC_STATE_DIR: state };
const settings = path.join(user, 'settings.json');
const shortcuts = path.join(user, 'keybindings.json');
const named = path.join(user, 'profiles/named-fixture/settings.json');
const original = '// Preserve my exact JSONC bytes\n{ "editor.fontSize": 19, }\n';
const originalShortcuts = '// Preserve my custom shortcuts\n[{"key":"cmd+alt+x","command":"workbench.action.files.save"},]\n';
function run(slug, args = [], expected = 0, overrides = {}) {
  const result = spawnSync(process.execPath, [path.join(root, 'helpers/vscode/build.cjs'), slug, ...(args.includes('--replace-settings') ? ['--backup-dir', state] : []), ...args], {
    env: { ...env, ...overrides }, cwd: tmp, encoding: 'utf8', timeout: 20000,
  });
  assert.equal(result.status, expected, `${result.error || ''}\n${result.stdout}\n${result.stderr}`);
  return result.stdout;
}
const approval = output => {
  const match = output.match(/Approval hash: ([a-f0-9]{64})/);
  assert(match, output);
  return match[1];
};
const approve = output => ['--execute', '--approve', approval(output)];
try {
  fs.mkdirSync(path.dirname(named), { recursive: true });
  fs.writeFileSync(settings, original);
  fs.writeFileSync(shortcuts, originalShortcuts);
  fs.chmodSync(settings, 0o640);
  fs.writeFileSync(named, '{"editor.fontSize":21}\n');
  fs.mkdirSync(path.join(home, '.vscode/extensions'), { recursive: true });
  const extensionSentinel = path.join(home, '.vscode/extensions/keep-this');
  fs.writeFileSync(extensionSentinel, 'untouched');
  const preview = run('default', ['--replace-settings']);
  assert.match(preview, /Preview only/);
  assert(!fs.existsSync(state));
  assert(!fs.existsSync(`${state}.operation.lock`));
  assert.equal(fs.readFileSync(settings, 'utf8'), original);
  run('default', ['--replace-settings', '--execute'], 1);
  run('default', ['--replace-settings', '--execute', '--dry-run']);
  assert(!fs.existsSync(state));
  assert(!fs.existsSync(state));
  run('full-stack', ['--replace-settings'], 1);
  run('full-stack', ['--replace-settings', '--settings-file', settings], 1);
  run('default', ['--replace-settings', '--settings-file', named], 1);
  run('default', ['--replace-settings', '--install-extensions'], 1);
  run('default', ['--approve', 'a'.repeat(64)], 1);
  run('default', ['--replace-settings', '--settings-file', path.join(tmp, 'settings.json')], 1);
  run('default', ['--replace-settings', '--execute', '--approve', '0'.repeat(64)], 1);
  assert(!fs.existsSync(path.join(state, 'profile-replacements')));
  const applied = run('default', ['--replace-settings', ...approve(preview)]);
  const backup = applied.match(/Backup: (.+)/)[1];
  assert.equal(fs.statSync(backup).mode & 0o777, 0o700);
  assert.equal(fs.statSync(path.join(backup, 'settings.before')).mode & 0o777, 0o600);
  assert.equal(fs.readFileSync(path.join(backup, 'settings.before'), 'utf8'), original);
  assert.equal(fs.readFileSync(path.join(backup, 'keybindings.before'), 'utf8'), originalShortcuts);
  assert.equal(JSON.parse(fs.readFileSync(settings))['terminal.integrated.suggest.upArrowNavigatesHistory'], true);
  assert.deepEqual(JSON.parse(fs.readFileSync(shortcuts)), []);
  assert.equal(fs.readFileSync(extensionSentinel, 'utf8'), 'untouched');
  assert.equal(fs.readFileSync(named, 'utf8'), '{"editor.fontSize":21}\n');
  // Backups are verified even when a restore would otherwise be a no-op.
  const originalBackup = path.join(backup, 'settings.before');
  fs.appendFileSync(originalBackup, 'corruption');
  run('default', ['--restore', backup], 1);
  fs.writeFileSync(originalBackup, original);
  assert.match(run('default', ['--replace-settings']), /Already matches/);
  const restore = run('default', ['--restore', backup]);
  // Recovery must work even if required setup evidence has become unavailable.
  assert(!fs.existsSync(path.join(state, 'completed')));
  run('default', ['--restore', backup, ...approve(restore)]);
  assert.equal(fs.readFileSync(settings, 'utf8'), original);
  assert.equal(fs.statSync(settings).mode & 0o777, 0o640);
  assert.equal(fs.readFileSync(shortcuts, 'utf8'), originalShortcuts);
  assert.match(run('default', ['--restore', backup]), /Already restored/);

  // A stale preview cannot overwrite later edits.
  const stale = run('default', ['--replace-settings']);
  fs.appendFileSync(settings, '\n// A later edit\n');
  run('default', ['--replace-settings', ...approve(stale)], 1);
  const fresh = run('full-stack', ['--replace-settings', '--settings-file', named]);
  const namedApply = run('full-stack', ['--replace-settings', '--settings-file', named, ...approve(fresh)]);
  const namedBackup = namedApply.match(/Backup: (.+)/)[1];
  assert.equal(JSON.parse(fs.readFileSync(path.join(path.dirname(named), 'keybindings.json'))).length, 3);
  assert.match(fs.readFileSync(settings, 'utf8'), /A later edit/);
  fs.appendFileSync(named, '\n// Keep later edits\n');
  run('full-stack', ['--restore', namedBackup], 1);
  assert.match(fs.readFileSync(named, 'utf8'), /Keep later edits/);
  run('ai', ['--restore', namedBackup], 1);
  // Recover a partial write: inject a failure publishing only keybindings.
  // No production failure switch is introduced; the patch exists in this child only.
  const partialSettings = path.join(user, 'profiles/partial-fixture/settings.json');
  fs.mkdirSync(path.dirname(partialSettings));
  fs.writeFileSync(partialSettings, original);
  const partialPreview = run('ai', ['--replace-settings', '--settings-file', partialSettings]);
  const harness = path.join(tmp, 'partial-write.cjs');
  fs.writeFileSync(harness, `
const fs = require('node:fs');
const originalRename = fs.renameSync;
fs.renameSync = (from, to) => { if (to === ${JSON.stringify(path.join(path.dirname(partialSettings), 'keybindings.json'))}) throw new Error('fixture publish failure'); return originalRename(from, to); };
const { recipe } = require(${JSON.stringify(path.join(root, 'helpers/vscode/build.cjs'))});
const { replacement } = require(${JSON.stringify(path.join(root, 'helpers/vscode/replace.cjs'))});
try { replacement(${JSON.stringify(root)}, recipe('ai'), { replace: true, execute: true, settingsFile: ${JSON.stringify(partialSettings)}, backupDir: ${JSON.stringify(state)}, approve: ${JSON.stringify(approval(partialPreview))} }); }
catch (error) { console.error(error.message); process.exitCode = 1; }
`);
  const partial = spawnSync(process.execPath, [harness], { env, encoding: 'utf8', timeout: 20000 });
  assert.equal(partial.status, 1, partial.stderr);
  const partialBackup = partial.stderr.match(/Recovery backup retained: (.+)/)[1];
  const partialRestore = run('ai', ['--restore', partialBackup]);
  run('ai', ['--restore', partialBackup, ...approve(partialRestore)]);
  assert.equal(fs.readFileSync(partialSettings, 'utf8'), original);
  assert(!fs.existsSync(path.join(path.dirname(partialSettings), 'keybindings.json')));
  const link = path.join(user, 'profiles/link-fixture');
  fs.symlinkSync(path.dirname(named), link);
  run('full-stack', ['--replace-settings', '--settings-file', path.join(link, 'settings.json')], 1);
  fs.unlinkSync(settings);
  fs.symlinkSync(named, settings);
  run('default', ['--replace-settings'], 1);
  fs.unlinkSync(settings);
  fs.mkdirSync(settings);
  run('default', ['--replace-settings'], 1);
  console.log('PASS: profile replacement preview, approval, gates, Default/named isolation, private backups, exact restore, drift and unsafe-path refusal');
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}
