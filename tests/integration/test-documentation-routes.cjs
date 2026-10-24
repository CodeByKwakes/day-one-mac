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
  return markdownIt().parse(text, {}).filter(t => t.type === 'inline' && t.map && /^#+ /.test(text.split('\n')[t.map[0]]))
    .map(t => {
      const base = t.content.toLowerCase().replace(/[^a-z0-9 _-]/g, '').replace(/[ \t]/g, '-');
      const count = counts.get(base) || 0; counts.set(base, count + 1);
      return count ? `${base}-${count}` : base;
    });
};
const nav = documentationNavigation(documents);
for (const label of ['Scripted (Assisted) Setup', 'Manual Setup', 'Shared library']) {
  assert.ok(nav.groups.some(g => g.label === label), `Missing navigation section: ${label}`);
}
for (const [file, text] of documents) {
  if (!file.startsWith('docs/') || text.includes('<!-- day-one-mac:compatibility-guide -->')) continue;
  assert.ok(['docs/README.md', 'docs/START-HERE.md'].includes(file)
    || /^docs\/(setup\/(assisted|manual)|shared)\//.test(file), `Guide outside approved roots: ${file}`);
}
const aliases = JSON.parse(fs.readFileSync(path.join(root, 'config/catalogs/document-aliases.json'), 'utf8'));
const originalHeadings = JSON.parse(fs.readFileSync(path.join(root, 'tests/fixtures/documentation-headings-before-routes.json'), 'utf8'));
for (const [file, originalAnchors] of Object.entries(originalHeadings)) {
  assert.ok(documents.has(file), `Original documentation path disappeared: ${file}`);
  const currentAnchors = anchors(documents.get(file));
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
  } finally { fs.rmSync(temporary, { recursive: true, force: true }); }
}
console.log('Documentation route ownership, old fragments, manual boundaries and Warp startup passed.');
