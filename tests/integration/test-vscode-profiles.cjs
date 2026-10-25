#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { recipe } = require('../../helpers/vscode/build.cjs');
const temporary = fs.mkdtempSync(path.join('/tmp', 'day-one-profile-tests-'));
const root = path.resolve(__dirname, '../..');
const environment = { ...process.env, PROFILE_TEST_LOG: path.join(temporary, 'calls.jsonl'),
  DAY_ONE_MAC_STATE_ROOT: path.join(temporary, 'state'), DAY_ONE_MAC_STATE_DIR: path.join(temporary, 'state') };
const run = (slug, args = [], status = 0) => {
  const result = spawnSync(process.execPath, [path.join(root, 'helpers/vscode/build.cjs'), slug, ...args], {
    encoding: 'utf8', env: environment,
  });
  assert.equal(result.status, status, `${result.stdout}\n${result.stderr}`);
  return result;
};
try {
  for (const [slug, count] of Object.entries({ default: 5, 'full-stack': 23, ai: 18, operations: 11 })) {
    const output = path.join(temporary, `${slug} with spaces`);
    const data = recipe(slug);
    assert.equal(data.extensions.length, count);
    assert(!data.extensions.some(id => id.startsWith('github.copilot')));
    assert.equal(data.settings['[markdown]']['files.trimTrailingWhitespace'], false);
    assert.equal(data.settings['github.copilot.chat.commitMessageGeneration.instructions'].length, 5);
    assert.equal(data.settings['chat.tools.global.autoApprove'], false);
    assert.equal(data.settings['chat.tools.terminal.enableAutoApprove'], false);
    assert.equal(data.settings['terminal.integrated.suggest.upArrowNavigatesHistory'], true);
    const languageProviders = { 'azure-pipelines': 'ms-azure-devops.azure-pipelines', dotenv: 'mikestead.dotenv', tailwindcss: 'bradlc.vscode-tailwindcss' };
    for (const language of Object.values(data.settings['files.associations'] || {})) {
      const provider = languageProviders[language];
      if (provider) assert(data.extensions.includes(provider), `${data.name} associates files with ${language} without ${provider}`);
    }
    run(slug, ['--output', output, '--dry-run', '--install-extensions', '--code', '/does/not/exist']);
    assert(!fs.existsSync(output));
    run(slug, ['--output', output]);
    const template = JSON.parse(fs.readFileSync(path.join(output, `${slug}.code-profile`)));
    assert.equal(template.name, `${data.name} Review`);
    // Match VS Code's SettingsResource.apply and KeybindingsResource.apply:
    // parse the resource envelope first, then parse the embedded file text.
    assert.deepEqual(JSON.parse(JSON.parse(template.settings).settings), data.settings);
    assert.deepEqual(JSON.parse(template.extensions).map(item => item.identifier.id), data.extensions);
    assert.deepEqual(template.keybindings ? JSON.parse(JSON.parse(template.keybindings).keybindings) : [], data.keybindings);
    if (template.keybindings) assert.equal(JSON.parse(template.keybindings).platform, 1);
    if (slug === 'ai') {
      assert.equal(data.keybindings.length, 3);
      assert.equal(data.settings['github.copilot.enable']['*'], false);
      assert(data.settings['[typescript]']);
    }
    assert.equal(fs.statSync(output).mode & 0o777, 0o700);
    assert.equal(fs.statSync(path.join(output, 'settings.json')).mode & 0o777, 0o600);
    const before = fs.readFileSync(path.join(output, `${slug}.code-profile`), 'utf8');
    run(slug, ['--output', output], 1);
    assert.equal(fs.readFileSync(path.join(output, `${slug}.code-profile`), 'utf8'), before);
  }
  const link = path.join(temporary, 'link');
  fs.symlinkSync(path.join(temporary, 'default with spaces'), link);
  run('default', ['--output', link], 1);
  const invalid = path.join(temporary, 'invalid');
  run('default', ['--output', invalid, '--with', 'anthropic.claude-code'], 1);
  assert(!fs.existsSync(invalid));
  run('ai', ['--with'], 1);
  run('ai', ['--unknown'], 1);
  assert.match(run('ai', ['--help']).stdout, /Usage:/);
  const blockedOutput = path.join(temporary, 'blocked-install');
  run('default', ['--install-extensions', '--output', blockedOutput, '--code', '/does/not/exist'], 1);
  assert(!fs.existsSync(blockedOutput));
  const publicPreview = spawnSync(process.execPath, [path.join(root, 'helpers/vscode/build.cjs'), 'ai', '--dry-run'], { cwd: temporary, env: environment, encoding: 'utf8' });
  assert.equal(publicPreview.status, 0, publicPreview.stderr);
  assert.match(publicPreview.stdout, /Dry run: no files written/);
  const mock = path.join(temporary, 'mock code');
  fs.writeFileSync(mock, `#!${process.execPath}
const fs = require('node:fs');
const args = process.argv.slice(2);
if (args.includes('--version')) { console.log('1.105.0'); process.exit(0); }
fs.appendFileSync(process.env.PROFILE_TEST_LOG, JSON.stringify(args) + '\\n');
if (args.includes('--list-extensions')) console.log('ESBENP.PRETTIER-VSCODE');
else if (args.includes('--install-extension') && args.at(-1) === 'tomoki1207.pdf') process.exit(9);
`, { mode: 0o700 });
  const installOutput = path.join(temporary, 'install');
  run('default', ['--code', mock, '--install-extensions', '--output', installOutput]);
  let calls = fs.readFileSync(path.join(temporary, 'calls.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  assert.equal(calls.length, 5); // One list + four missing extensions.
  assert(calls.every(args => args[0] === '--profile' && args[1] === 'Default'));
  assert(!calls.some(args => args.includes('--force') || args.includes('--uninstall-extension')));
  assert(!calls.some(args => args.includes('esbenp.prettier-vscode')));
  const failOutput = path.join(temporary, 'failed-install');
  const failed = run('default', ['--code', mock, '--install-extensions', '--output', failOutput,
    '--with', 'Tomoki1207.PDF'], 1);
  assert.match(failed.stderr, /VS Code failed \(9\)/);
  assert(fs.existsSync(path.join(failOutput, 'settings.json')));
  assert.equal(recipe('default', ['tomoki1207.pdf']).extensions.length, 6);
  console.log('VS Code profile scripts passed: bundles, deep merges, optional selection, safe output, and mock CLI.');
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
