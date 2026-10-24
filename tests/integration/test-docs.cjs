#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-docs-test.'));
const fixture = path.join(temporary, 'standalone');
const home = path.join(temporary, 'private-home');
fs.mkdirSync(home);
try {
  // Use the reviewed public inventory, with no node_modules, Git checkout or real HOME.
  const inventory = fs.readFileSync(path.join(root, 'config/document-sources.txt'), 'utf8')
    .split('\n').filter(line => line && !line.startsWith('#'));
  inventory.push('config/document-sources.txt', 'tools/export-docs.cjs', 'tools/docs/docs-browser.js', 'tools/docs/docs-browser.css', 'tools/docs/docs-browser.html', 'tools/vendor/markdown-it/markdown-it.min.js', 'tools/vendor/markdown-it/LICENSE');
  for (const file of inventory) {
    const target = path.join(fixture, file);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(path.join(root, file), target);
  }
  fs.writeFileSync(path.join(fixture, 'docs/private-note.md'), 'PRIVATE_UNLISTED_SENTINEL');
  fs.mkdirSync(path.join(home, '.day-one-mac'));
  fs.writeFileSync(path.join(home, '.day-one-mac/private.md'), 'PRIVATE_HOME_SENTINEL');
  const run = (args, expected = 0, environment = {}) => {
    const result = spawnSync(process.execPath, [path.join(fixture, 'tools/export-docs.cjs'), ...(args[0] === 'export' ? args.slice(1) : args)], {
      env: { ...process.env, HOME: home, DAY_ONE_MAC_STATE_ROOT: path.join(home, '.day-one-mac'),
        PATH: '/usr/bin:/bin:/usr/sbin:/sbin', ...environment }, encoding: 'utf8',
    });
    assert.equal(result.status, expected, `${args.join(' ')}\n${result.stdout}\n${result.stderr}`);
    return result.stdout;
  };
  const handbookTopics = {
    'second-brain-guide': 'docs/setup/manual/second-brain/README.md',
    folders: 'docs/setup/manual/development/folders.md',
    security: 'docs/setup/manual/security/README.md',
    '1password': 'docs/setup/manual/security/1password.md',
    keychain: 'docs/setup/manual/security/keychain-ssh.md',
    ssh: 'docs/setup/manual/security/ssh-signing-and-recovery.md',
    software: 'docs/shared/reference/software-catalogue.md',
    worktrees: 'docs/setup/manual/development/worktrees/README.md',
    shortcuts: 'docs/setup/manual/apps/macos-shortcuts.md',
  };
  run(['--format', 'pdf', '--output', path.join(temporary, 'invalid')], 1);
  run(['--format', 'html'], 1);
  run(['--format', 'html', '--format', 'html', '--output', path.join(temporary, 'invalid')], 1);
  assert(!fs.existsSync(path.join(temporary, 'invalid')));

  const htmlDir = path.join(temporary, 'html export');
  run(['export', '--format', 'html', '--output', htmlDir]);
  const html = fs.readFileSync(path.join(htmlDir, 'index.html'), 'utf8');
  assert.match(html, /Content-Security-Policy/);
  assert.ok(!html.includes('PRIVATE_UNLISTED_SENTINEL'));
  assert.ok(!html.includes('PRIVATE_HOME_SENTINEL'));
  assert.ok(!fs.existsSync(path.join(htmlDir, 'scripts')));
  assert.ok(!fs.existsSync(path.join(htmlDir, 'docs/private-note.md')));
  assert.match(html, /Print \/ save PDF/);
  const embedded = new Map(Array.from(html.matchAll(/class="document-data" data-path="([^"]+)">([^<]+)<\/script>/g),
    match => [match[1], Buffer.from(match[2], 'base64').toString('utf8')]));
  assert.equal(embedded.get('docs/setup/manual/shell/README.md'), fs.readFileSync(path.join(root, 'docs/setup/manual/shell/README.md'), 'utf8'));
  const npmGuide = 'docs/setup/manual/git/azure-artifacts-npm.md';
  assert.equal(embedded.get(npmGuide), fs.readFileSync(path.join(root, npmGuide), 'utf8'),
    'The private-registry guide is bundled in offline HTML');
  // Exercise the published encoder with synthetic input only. Replace the
  // clipboard sink before execution; never read or modify the real clipboard.
  if (process.platform === 'darwin') {
    const encoder = embedded.get(npmGuide).match(/```sh\n\/bin\/zsh -f -c '\n([\s\S]*?)\n'\n```/)?.[1];
    assert.ok(encoder, 'The documented macOS encoder is present');
    assert.equal((encoder.match(/\/usr\/bin\/pbcopy/g) || []).length, 1);
    const safeEncoder = encoder.replace('/usr/bin/pbcopy', '/bin/cat');
    const dummy = 'documentation-fixture-not-a-token';
    const encode = input => spawnSync('/bin/zsh', ['-f', '-c', safeEncoder], {
      input, encoding: 'utf8', env: { PATH: '/usr/bin:/bin', HOME: home },
    });
    const encoded = encode(`${dummy}\n`);
    assert.equal(encoded.status, 0, encoded.stderr);
    assert.ok(encoded.stdout.includes(Buffer.from(dummy).toString('base64')));
    assert.ok(!encoded.stdout.includes(dummy), 'The prompt does not echo input');
    const empty = encode('\n');
    assert.equal(empty.status, 1);
    assert.match(empty.stderr, /No token entered/);
    assert.ok(!empty.stdout.includes('Encoded credential copied'));
    assert.equal(encode('').status, 1, 'EOF cancels without reporting success');
  }
  for (const file of Object.values(handbookTopics)) {
    assert.equal(embedded.get(file), fs.readFileSync(path.join(root, file), 'utf8'));
  }
  for (const file of ['docs/setup/manual/shell/chezmoi.md', 'docs/setup/manual/shell/chezmoi.md', 'docs/shared/reference/chezmoi-commands.md', 'docs/shared/explanation/chezmoi-boundaries.md']) {
    assert.ok(embedded.has(file));
  }
  run(['export', '--format', 'html', '--output', htmlDir], 1);
  assert.equal(fs.readFileSync(path.join(htmlDir, 'index.html'), 'utf8'), html);
  const alias = path.join(temporary, 'existing-link');
  fs.symlinkSync(htmlDir, alias);
  run(['export', '--format', 'markdown', '--output', alias], 1);
  const mdDir = path.join(temporary, 'markdown');
  run(['export', '--format', 'markdown', '--output', mdDir]);
  assert.ok(!fs.existsSync(path.join(mdDir, 'index.html')));
  assert.equal(fs.readFileSync(path.join(mdDir, 'docs/setup/manual/shell/README.md'), 'utf8'), embedded.get('docs/setup/manual/shell/README.md'));
  assert.equal(fs.readFileSync(path.join(mdDir, npmGuide), 'utf8'), embedded.get(npmGuide),
    'The private-registry guide is included in Markdown exports');
  for (const file of Object.values(handbookTopics)) {
    assert.equal(fs.readFileSync(path.join(mdDir, file), 'utf8'), embedded.get(file));
  }

  const markdownIt = require(path.join(fixture, 'tools/vendor/markdown-it/markdown-it.min.js'));
  const { documentationRenderer, documentationNavigation, findDocumentation, resolveDocumentationRoute } = require(path.join(fixture, 'tools/docs/docs-browser.js'));
  const navigation = documentationNavigation(embedded);
  const { coreSequence } = navigation;
  assert.deepEqual(resolveDocumentationRoute('docs/10-app-guides/DATAGRIP.md', 'create-a-local-example-database-and-roles', embedded).path, 'docs/setup/manual/databases/datagrip.md');
  assert.equal(resolveDocumentationRoute('docs/10-app-guides/DATAGRIP.md', '4-create-a-local-example-database-and-roles', embedded).path, 'docs/setup/manual/databases/postgresql.md');
  assert.deepEqual(navigation.groups.map(group => group.label), ['Start here', 'AI-assisted setup', 'Manual Setup', 'Shared library']);
  const worktrees = navigation.groups.flatMap(group => group.sections).find(section => section.label === 'Git worktrees');
  assert.equal(worktrees.entries.length, 8);
  assert.ok(worktrees.entries.some(entry => entry.path.endsWith('/copilot.md')));
  assert.ok(worktrees.entries.some(entry => entry.path.endsWith('/vscode.md')));
  const listed = navigation.groups.flatMap(group => group.sections.flatMap(section => section.entries.map(entry => entry.path)));
  assert.equal(new Set(listed).size, listed.length, 'Each guide has one canonical navigation location');
  assert.deepEqual([...listed].sort(), [...embedded.keys()].filter(path => !embedded.get(path).includes('<!-- day-one-mac:compatibility-guide -->')).sort(), 'All canonical guides remain discoverable');
  assert.deepEqual(navigation.groups[1].sections[0].entries.map(entry => entry.path), coreSequence);
  const git = navigation.groups.find(group => group.label === 'Manual Setup')
    .sections.find(section => section.label === 'Git and providers');
  assert.ok(git.entries.some(entry => entry.path === npmGuide), 'Private registry setup is discoverable with Git and hosting');
  assert.ok(!coreSequence.includes(npmGuide), 'Private-registry setup is optional');
  assert.ok(coreSequence.indexOf('docs/setup/ai/bootstrap.md') < coreSequence.indexOf('docs/setup/ai/operation.md'));
  assert.ok(!coreSequence.some(file => file.includes('/assisted/')));
  assert.ok(findDocumentation(navigation.titles, ' CHEZMOI ').length > 1);
  assert.deepEqual(findDocumentation(navigation.titles, ''), []);
  assert.deepEqual(findDocumentation(navigation.titles, 'no-matching-guide-xyz'), []);
  const render = text => documentationRenderer(markdownIt, embedded, 'docs/setup/manual/shell/README.md').render(text);
  assert.match(render('<a id="published-anchor"></a>'), /<a id="published-anchor"><\/a>/);
  assert.ok(!render('<a id="unsafe" onclick="alert(1)"></a>').includes('<a id="unsafe"'));
  const rendered = render('# Example\n\n# Example\n\n[Daily](../../../reference/MANAGING-DOTFILES-WITH-CHEZMOI.md#recovery)\n\n[Here](#example)\n\n<script>alert(1)</script>\n\n![remote](https://example.org/pixel.png)\n\n[bad](javascript:alert(1))\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n```sh\n<unsafe>\n```');
  assert.match(rendered, /id="example"/);
  assert.match(rendered, /id="example-1"/);
  assert.match(rendered, /href="#docs\/reference\/MANAGING-DOTFILES-WITH-CHEZMOI.md#recovery"/);
  assert.match(rendered, /href="#docs\/setup\/manual\/shell\/README.md#example"/);
  assert.match(rendered, /<table>/);
  assert.match(rendered, /&lt;unsafe&gt;/);
  assert.ok(!rendered.includes('<script>'));
  assert.ok(!rendered.includes('<img'));
  assert.ok(!rendered.includes('href="javascript:'));
  const checklist = render('- [ ] **Review** [the guide](README.md)\n- [x] Recorded\n  - [X] Nested\n- Ordinary item\n\n1. [ ] Ordered item\n\n- [ ] Loose item\n\n  Another paragraph with [ ] literal text.\n\n[ ] Not a list\n\n- `[ ]` Inline code\n- \\[ ] Escaped marker\n\n```sh\n- [ ] Code example\n```');
  assert.equal((checklist.match(/class="task-item"/g) || []).length, 5);
  assert.equal((checklist.match(/class="task-marker task-checked"/g) || []).length, 2);
  assert.match(checklist, /role="img" aria-label="Unchecked checklist item \(documented state\)"/);
  assert.match(checklist, /<strong>Review<\/strong>/);
  assert.match(checklist, /<li>Ordinary item<\/li>/);
  assert.match(checklist, /<p>\[ \] Not a list<\/p>/);
  assert.match(checklist, /<code>\[ \]<\/code>/);
  assert.match(checklist, /<li>\[ \] Escaped marker<\/li>/);
  assert.match(checklist, /- \[ \] Code example/);
  assert.ok(!/<input|role="checkbox"|tabindex=/.test(checklist), 'Checklist symbols are non-interactive and do not imply saved progress');

  // Check every rendered local Markdown link, including relative paths and anchors.
  const pages = new Map(Array.from(embedded, ([file, text]) => [file, documentationRenderer(markdownIt, embedded, file).render(text)]));
  for (const [file, page] of pages) {
    for (const match of page.matchAll(/href="#([^"#]+\.md)(?:#([^"#]+))?"/g)) {
      const linkedPage = pages.get(decodeURIComponent(match[1]));
      assert.ok(linkedPage, `Missing bundled guide from ${file}: ${match[1]}`);
      if (match[2]) assert.ok(linkedPage.includes(`id="${decodeURIComponent(match[2])}"`), `Missing heading from ${file}: ${match[0]}`);
    }
    assert.ok(!/href="\.\/[^"#]+\.md(?:#|"|$)/.test(page), `Unbundled Markdown link in ${file}`);
  }

  // The exported reader survives removal of the source checkout.
  assert.deepEqual(fs.readdirSync(path.join(home, '.day-one-mac')), ['private.md']);
  const readerBefore = fs.readFileSync(path.join(htmlDir, 'index.html'));
  const movedFixture = path.join(temporary, 'source-unavailable');
  fs.renameSync(fixture, movedFixture);
  assert(fs.readFileSync(path.join(htmlDir, 'index.html')).equals(readerBefore));
  fs.renameSync(movedFixture, fixture);

  // Reject symlinked listed inputs and symlink parents before writing output.
  const guide = path.join(fixture, 'docs/setup/manual/shell/README.md');
  fs.unlinkSync(guide); fs.symlinkSync(path.join(home, '.day-one-mac/private.md'), guide);
  const rejected = path.join(temporary, 'rejected');
  run(['export', '--format', 'html', '--output', rejected], 1);
  assert.ok(!fs.existsSync(rejected));
  fs.unlinkSync(guide); fs.copyFileSync(path.join(root, 'docs/setup/manual/shell/README.md'), guide);
  fs.renameSync(path.join(fixture, 'docs/manual'), path.join(temporary, 'manual'));
  fs.symlinkSync(path.join(temporary, 'manual'), path.join(fixture, 'docs/manual'));
  run(['export', '--format', 'markdown', '--output', rejected], 1);
  assert.ok(!fs.existsSync(rejected));
  console.log('PASS: offline docs, guide links/anchors, handbook topics, software catalogue coverage, exports, privacy, no-overwrite, and symlink rejection');
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
require('./test-docs-reader.cjs');
