#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const markdownIt = require(path.join(root, 'src/vendor/markdown-it/markdown-it.min.js'));
const { documentationNavigation, resolveDocumentationRoute } = require(path.join(root, 'src/docs/docs-browser.js'));
const inventory = fs.readFileSync(path.join(root, 'config/runtime-files.txt'), 'utf8').split('\n').filter(x => x && !x.startsWith('#'));
const documents = new Map(inventory.filter(x => x.endsWith('.md')).map(x => [x, fs.readFileSync(path.join(root, x), 'utf8')]));
const anchors = text => {
  const counts = new Map();
  const declared = Array.from(text.matchAll(/<a id="([a-z0-9_-]+)"><\/a>/g), m => m[1]);
  return declared.concat(markdownIt().parse(text, {}).filter(t => t.type === 'inline' && t.map && /^#+ /.test(text.split('\n')[t.map[0]]))
    .map(t => {
      const base = t.content.toLowerCase().replace(/[^a-z0-9 _-]/g, '').replace(/[ \t]/g, '-');
      const count = counts.get(base) || 0; counts.set(base, count + 1);
      return count ? `${base}-${count}` : base;
    }));
};
const nav = documentationNavigation(documents);
assert.deepEqual(nav.coreSequence, ['docs/setup/ai/README.md', 'docs/setup/ai/bootstrap.md', 'docs/setup/ai/operation.md']);
assert.ok(!nav.groups.some(g => /Scripted/.test(g.label)));

for (const label of ['AI-assisted setup', 'Manual Setup', 'Shared library']) {
  assert.ok(nav.groups.some(g => g.label === label), `Missing navigation section: ${label}`);
}
for (const [file, text] of documents) {
  if (!file.startsWith('docs/') || text.includes('<!-- day-one-mac:compatibility-guide -->')) continue;
  assert.ok(['docs/README.md', 'docs/START-HERE.md'].includes(file)
    || /^docs\/(setup\/(ai|manual)|shared)\//.test(file), `Guide outside approved roots: ${file}`);
}
const aliases = JSON.parse(fs.readFileSync(path.join(root, 'config/catalogs/document-aliases.json'), 'utf8'));
const originalHeadings = JSON.parse(fs.readFileSync(path.join(root, 'tests/fixtures/documentation-headings-before-routes.json'), 'utf8'));
for (const [file, originalAnchors] of Object.entries(originalHeadings)) {
  assert.ok(documents.has(file), `Original documentation path disappeared: ${file}`);
  const currentAnchors = [...anchors(documents.get(file)), ...Array.from(documents.get(file).matchAll(/<a id="([a-z0-9_-]+)"><\/a>/g), m => m[1])];
  for (const anchor of originalAnchors) assert.ok(currentAnchors.includes(anchor), `Original heading disappeared: ${file}#${anchor}`);
}
for (const [oldPath, newPath] of Object.entries(aliases)) {
  assert.ok(documents.has(oldPath), `Old path omitted from package: ${oldPath}`);
  if (newPath.startsWith('maintainers/')) continue;
  assert.ok(documents.has(newPath), `Destination omitted from package: ${newPath}`);
  assert.ok(!documents.get(newPath).includes('<!-- day-one-mac:compatibility-guide -->'), `Alias chain: ${oldPath}`);
  for (const anchor of ['', ...anchors(documents.get(oldPath))]) {
    const target = resolveDocumentationRoute(oldPath, anchor, documents);
    assert.ok(documents.has(target.path), `Missing resolved page: ${oldPath}#${anchor}`);
    assert.ok(!target.anchor || anchors(documents.get(target.path)).includes(target.anchor),
      `Missing resolved section: ${oldPath}#${anchor} -> ${target.path}#${target.anchor}`);
  }
}
for (const [oldPath, anchor, owner] of [
  ['docs/how-to/development/VSCODE-TYPESCRIPT.md', '12-use-zsh-consistently-in-vs-code-and-warp', 'docs/setup/manual/shell/zsh.md'],
  ['docs/10-app-guides/VSCODE-TYPESCRIPT.md', '11-configure-project-and-global-mcp-servers', 'docs/setup/manual/ai/mcp.md'],
  ['docs/how-to/modules/advanced/19-macos-gui-and-local-https.md', 'step-199--create-a-new-local-https-authority', 'docs/setup/manual/local-https.md'],
  ['docs/10-app-guides/DATAGRIP.md', '4-create-a-local-example-database-and-roles', 'docs/setup/manual/databases/postgresql.md'],
]) {
  assert.equal(resolveDocumentationRoute(oldPath, anchor, documents).path, owner, `Split topic lost its owner: ${oldPath}#${anchor}`);
}
for (const file of ['docs/shared/prerequisites.md', 'docs/shared/troubleshooting.md',
  'docs/setup/manual/homebrew.md', 'docs/setup/manual/languages.md',
  'docs/setup/manual/security/https-git.md', 'docs/setup/manual/editors/vscode.md',
  'docs/setup/assisted/optional/vscode-profiles.md']) {
  assert.ok(documents.has(file), `Missing required task: ${file}`);
}
for (const [file, text] of documents) {
  if (!file.startsWith('docs/setup/manual/') || text.includes('day-one-mac:compatibility-guide')) continue;
  const examples = markdownIt().parse(text, {}).filter(token => token.type === 'fence' && /^(sh|bash|zsh)$/.test(token.info.trim()));
  for (const example of examples) {
    assert.ok(!/^\s*(?:day-one-mac(?:\s|$)|second-brain-(?:report|codex|claude|manager)(?:\s|$)|\.\/scripts\/)/m.test(example.content),
      `Manual task requires a project helper: ${file}`);
  }
}
// Execute only the noninteractive Warp branch, in a private HOME with no tools
// or startup files. This catches misplaced completion guards in copyable docs.
const zshGuide = documents.get('docs/setup/manual/shell/zsh.md');
const startup = markdownIt().parse(zshGuide, {}).find(token => token.type === 'fence' && token.info === 'zsh' && token.content.includes('HISTFILE='));
assert.ok(startup, 'Manual Zsh task includes the complete startup example');
if (process.platform === 'darwin') {
  const os = require('node:os');
  const { spawnSync } = require('node:child_process');
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-doc-shell.'));
  try {
    const result = spawnSync('/bin/zsh', ['-f'], { input: `set -e\n${startup.content}\ntrue\n`, encoding: 'utf8',
      env: { PATH: '/usr/bin:/bin', HOME: temporary, TERM_PROGRAM: 'WarpTerminal' } });
    assert.equal(result.status, 0, `Warp startup example failed: ${result.stderr}`);
    assert.equal(result.stderr, '', 'Warp startup example has no missing completion commands');
    const syntaxCheck = markdownIt().parse(zshGuide, {}).find(token => token.type === 'fence'
      && token.content.includes('/bin/zsh -n'));
    assert.ok(syntaxCheck, 'Zsh guide provides a syntax check');
    fs.mkdirSync(path.join(temporary, '.config/zsh'), { recursive: true });
    const startupFiles = ['.zprofile', '.zshrc', '.config/zsh/path.zsh'];
    for (const invalidFile of [null, ...startupFiles]) {
      for (const file of startupFiles) fs.writeFileSync(path.join(temporary, file), file === invalidFile ? 'if then\n' : ':\n');
      const checked = spawnSync('/bin/zsh', ['-f'], { input: syntaxCheck.content, encoding: 'utf8',
        env: { PATH: '/usr/bin:/bin', HOME: temporary } });
      if (invalidFile) assert.notEqual(checked.status, 0, `Syntax errors in ${invalidFile} must fail the documented check`);
      else assert.equal(checked.status, 0, 'Valid startup files pass the documented syntax check');
    }
  } finally { fs.rmSync(temporary, { recursive: true, force: true }); }
}
// Run only the backup example with disposable files. Simulate a failed copy
// so the guide cannot promise a backup after suppressing a filesystem error.
{
  const os = require('node:os');
  const { spawnSync } = require('node:child_process');
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-doc-backup.'));
  const brewGuide = documents.get('docs/setup/manual/apps/brewfile.md');
  const backupSection = brewGuide.split('## 2. Back up the desired-state file')[1].split('\n## ')[0];
  const backup = markdownIt().parse(backupSection, {}).find(token => token.type === 'fence' && token.info === 'bash');
  assert.ok(backup, 'Brewfile guide includes a backup example');
  const run = extraPath => spawnSync('/bin/bash', [], { input: backup.content, encoding: 'utf8',
    env: { HOME: temporary, PATH: `${extraPath}:/usr/bin:/bin` } });
  try {
    fs.writeFileSync(path.join(temporary, 'Brewfile'), 'brew "git"\n');
    const fakeBin = path.join(temporary, 'bin');
    fs.mkdirSync(fakeBin);
    fs.writeFileSync(path.join(fakeBin, 'cp'), '#!/bin/sh\nexit 1\n', { mode: 0o700 });
    fs.writeFileSync(path.join(fakeBin, 'chezmoi'), '#!/bin/sh\nexit 0\n', { mode: 0o700 });
    assert.notEqual(run(fakeBin).status, 0, 'A failed copy must fail the backup example');
    const first = run('/usr/bin');
    assert.equal(first.status, 0, first.stderr);
    const backupRoot = path.join(temporary, '.local/state/development-setup/manual-backups');
    const copies = () => fs.readdirSync(backupRoot).map(name => path.join(backupRoot, name, 'Brewfile'))
      .filter(file => fs.existsSync(file));
    const originalCopy = copies().find(file => fs.readFileSync(file, 'utf8') === 'brew "git"\n');
    assert.ok(originalCopy, 'Backup preserves the original contents');
    fs.writeFileSync(path.join(temporary, 'Brewfile'), 'brew "jq"\n');
    assert.equal(run('/usr/bin').status, 0, 'A second backup succeeds');
    assert.equal(fs.readFileSync(originalCopy, 'utf8'), 'brew "git"\n', 'A second backup keeps the first copy');
    assert.equal(copies().length, 2, 'Each successful backup has a separate destination');
    fs.unlinkSync(path.join(temporary, 'Brewfile'));
    assert.equal(run('/usr/bin').status, 0, 'No existing Brewfile needs no copy');
  } finally { fs.rmSync(temporary, { recursive: true, force: true }); }
}
// Execute the editor backup and personal skill link using disposable homes.
{
  const os = require('node:os');
  const { spawnSync } = require('node:child_process');
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-doc-safe.'));
  const run = (content, extraPath = '/usr/bin') => spawnSync('/bin/bash', [], {
    input: content, encoding: 'utf8', env: { HOME: temporary, PATH: `${extraPath}:/usr/bin:/bin` }
  });
  const fences = text => markdownIt().parse(text, {}).filter(t => t.type === 'fence' && t.info === 'bash');
  try {
    const bin = path.join(temporary, 'bin'); fs.mkdirSync(bin);
    fs.writeFileSync(path.join(bin, 'code'), '#!/bin/sh\necho publisher.extension@1.0.0\n', { mode: 0o700 });
    fs.writeFileSync(path.join(bin, 'cp'), '#!/bin/sh\nexit 1\n', { mode: 0o700 });
    const user = path.join(temporary, 'Library/Application Support/Code/User');
    fs.mkdirSync(user, { recursive: true }); fs.writeFileSync(path.join(user, 'settings.json'), '{}\n');
    const backup = fences(documents.get('docs/setup/manual/apps/brewfile.md').split('## 8. Handle VS Code removal recoverably')[1]).find(t => t.content.includes('code --list-extensions --show-versions'));
    assert.ok(backup);
    assert.notEqual(run(backup.content, bin).status, 0, 'Failed VS Code backup must stop the documented procedure');
    fs.unlinkSync(path.join(bin, 'cp'));
    assert.equal(run(backup.content, bin).status, 0, 'A valid VS Code backup succeeds');
    assert.equal(run(backup.content, bin).status, 0, 'Repeated VS Code backups preserve earlier copies');
    const copies = fs.readdirSync(path.join(temporary, '.local/state/development-setup/vscode-backups'))
      .map(n => path.join(temporary, '.local/state/development-setup/vscode-backups', n, 'User/settings.json'))
      .filter(n => fs.existsSync(n));
    assert.equal(copies.length, 2);
    const link = fences(documents.get('docs/setup/manual/ai/maintenance.md')).find(t => t.content.includes('ln -s'));
    const source = path.join(temporary, '.agents/skills/review'); fs.mkdirSync(source, { recursive: true });
    fs.writeFileSync(path.join(source, 'SKILL.md'), '# Review\n');
    assert.equal(run(link.content).status, 0, 'New compatibility link succeeds');
    assert.equal(run(link.content).status, 0, 'Correct existing link is reusable');
    const target = path.join(temporary, '.claude/skills/review'); fs.unlinkSync(target);
    fs.symlinkSync('missing-skill', target);
    assert.notEqual(run(link.content).status, 0, 'A dangling link must be reported, not replaced');
    assert.equal(fs.readlinkSync(target), 'missing-skill');
  } finally { fs.rmSync(temporary, { recursive: true, force: true }); }
}
// Keep the coverage reference tied to actual phase/module inventory and check
// copyable syntax without running installers, account clients or databases.
{
  const { spawnSync } = require('node:child_process');
  const coverage = documents.get('docs/shared/reference/setup-coverage.md');
  assert.ok(coverage);
  const moduleIds = fs.readFileSync(path.join(root, 'config/catalogs/modules.tsv'), 'utf8')
    .split('\n').filter(line => line && !line.startsWith('#')).map(line => line.split('\t')[0]);
  for (const id of moduleIds) {
    assert.ok(documents.get('docs/shared/reference/tools.md').includes(`| ${id} |`), `Missing reviewed tool mapping: ${id}`);
  }
  let examples = 0;
  for (const [file, text] of documents) {
    if (!/^docs\/(setup\/(manual|ai)|shared)\//.test(file)) continue;
    for (const token of markdownIt().parse(text, {}).filter(t => t.type === 'fence')) {
      const language = token.info.trim();
      const shell = { bash: '/bin/bash', sh: '/bin/sh', zsh: '/bin/zsh' }[language];
      if (shell) {
        assert.ok(token.content.trim(), `Empty shell example: ${file}:${token.map[0] + 1}`);
        if (!fs.existsSync(shell)) continue;
        const checked = spawnSync(shell, ['-n'], { input: token.content, encoding: 'utf8' });
        assert.equal(checked.status, 0, `Invalid shell syntax: ${file}:${token.map[0] + 1} ${checked.stderr}`);
        examples++;
      } else if (language === 'json') {
        assert.doesNotThrow(() => JSON.parse(token.content), `Invalid JSON: ${file}:${token.map[0] + 1}`);
      }
    }
  }
  console.log(`Validated ${examples} shell examples without executing their commands.`);
}
console.log('Documentation routes, preserved fragments, manual boundaries, Zsh startup/syntax and Brewfile backups passed.');
