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
  // Use the release inventory, with no node_modules, Git checkout or real HOME.
  const inventory = fs.readFileSync(path.join(root, 'config/runtime-files.txt'), 'utf8')
    .split('\n').filter(line => line && !line.startsWith('#'));
  for (const file of inventory) {
    const target = path.join(fixture, file);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(path.join(root, file), target);
  }
  fs.writeFileSync(path.join(fixture, 'docs/private-note.md'), 'PRIVATE_UNLISTED_SENTINEL');
  fs.mkdirSync(path.join(home, '.day-one-mac'));
  fs.writeFileSync(path.join(home, '.day-one-mac/private.md'), 'PRIVATE_HOME_SENTINEL');
  const run = (args, expected = 0, environment = {}) => {
    const result = spawnSync('/bin/bash', [path.join(fixture, 'scripts/runtime-manager.sh'), 'docs', ...args], {
      env: { ...process.env, HOME: home, DAY_ONE_MAC_STATE_ROOT: path.join(home, '.day-one-mac'),
        PATH: '/usr/bin:/bin:/usr/sbin:/sbin', ...environment }, encoding: 'utf8',
    });
    assert.equal(result.status, expected, `${args.join(' ')}\n${result.stdout}\n${result.stderr}`);
    return result.stdout;
  };
  assert.match(run([]), /docs\/START-HERE.md/);
  assert.match(run(['manual']), /20-reference\/MANUAL-SETUP-GUIDE.md/);
  assert.match(run(['chezmoi']), /CHEZMOI-SETUP-TUTORIAL.md/);
  assert.match(run(['handbook']), /manual\/README.md/);
  assert.match(run(['chezmoi-guide']), /manual\/chezmoi.md/);
  assert.match(run(['--list']), /chezmoi-daily/);
  assert.match(run(['second-brain']), /second-brain\/README.md/);
  const handbookTopics = {
    'second-brain-guide': 'docs/manual/second-brain.md',
    security: 'docs/manual/security.md',
    '1password': 'docs/manual/1password.md',
    keychain: 'docs/manual/keychain-ssh.md',
    ssh: 'docs/manual/ssh-signing-and-recovery.md',
    software: 'docs/20-reference/SOFTWARE-CATALOGUE.md',
  };
  for (const [topic, file] of Object.entries(handbookTopics)) {
    assert.equal(fs.realpathSync(run([topic]).trim()), fs.realpathSync(path.join(fixture, file)));
    assert.ok(run(['--list']).includes(topic));
  }

  // Compare the public catalogue with executable selection sources, not a
  // second hand-maintained package list. Sourcing setup exposes functions only.
  const catalogue = fs.readFileSync(path.join(fixture, handbookTopics.software), 'utf8');
  const rows = heading => catalogue.split(heading)[1].split('\n## ')[0]
    .split('\n').filter(line => line.startsWith('| ')).slice(1)
    .map(line => line.split('|').slice(1, -1).map(cell => cell.trim().replaceAll('`', '')));
  const appRows = rows('## Registered applications, CLI casks and font');
  const registeredApps = fs.readFileSync(path.join(fixture, 'config/applications.tsv'), 'utf8')
    .split('\n').filter(line => line && !line.startsWith('#')).map(line => line.split('\t'));
  assert.deepEqual(appRows.map(row => row[0]).sort(), registeredApps.map(row => row[0]).sort());
  for (const [id, , , name, cask] of registeredApps) {
    const documented = appRows.find(row => row[0] === id);
    assert.equal(documented[2], cask, id);
    assert.ok(documented[1].startsWith(name), id);
  }
  const optionalRows = rows('## Optional formulae');
  const optionalFormulae = fs.readFileSync(path.join(fixture, 'config/optional-formulae.tsv'), 'utf8')
    .split('\n').filter(line => line && !line.startsWith('#')).map(line => line.split('\t'));
  assert.deepEqual(optionalRows.map(row => row.slice(0, 3)), optionalFormulae);
  const selectedFormulae = spawnSync('/bin/bash', ['-c',
    'source "$1/scripts/setup.sh"; for TRACK in 1 2 3; do for STACK in node python both; do required_formulae; done; done',
    'catalogue-fixture', fixture], {
    env: { HOME: home, PATH: '/usr/bin:/bin:/usr/sbin:/sbin',
      DAY_ONE_MAC_STATE_ROOT: path.join(home, '.day-one-mac'), DAY_ONE_MAC_DISABLE_BREW_DISCOVERY: '1' },
    encoding: 'utf8',
  });
  assert.equal(selectedFormulae.status, 0, selectedFormulae.stderr);
  assert.deepEqual(rows('## Required and conditional formulae').map(row => row[0]).sort(),
    Array.from(new Set(selectedFormulae.stdout.trim().split('\n'))).sort());
  fs.writeFileSync(path.join(fixture, 'SHA256SUMS'), 'runtime marker');
  run(['export', '--format', 'html', '--output', path.join(fixture, 'export')], 2);
  assert.ok(!fs.existsSync(path.join(fixture, 'export')));
  run(['--browser', '--open'], 2);
  run(['--browser', '--folder'], 2);
  run(['export', '--format', 'pdf', '--output', path.join(temporary, 'invalid')], 2);
  run(['export', '--format', 'html'], 2);
  run(['export', '--format', 'html', '--format', 'html', '--output', path.join(temporary, 'invalid')], 2);
  assert.ok(!fs.existsSync(path.join(temporary, 'invalid')));

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
  assert.equal(embedded.get('docs/manual/chezmoi.md'), fs.readFileSync(path.join(root, 'docs/manual/chezmoi.md'), 'utf8'));
  for (const file of Object.values(handbookTopics)) {
    assert.equal(embedded.get(file), fs.readFileSync(path.join(root, file), 'utf8'));
  }
  for (const name of ['CHEZMOI-SETUP-TUTORIAL', 'MANAGING-DOTFILES-WITH-CHEZMOI', 'CHEZMOI-COMMAND-REFERENCE', 'CHEZMOI-CONCEPTS-AND-BOUNDARIES']) {
    assert.ok(embedded.has(`docs/20-reference/${name}.md`));
  }
  run(['export', '--format', 'html', '--output', htmlDir], 1);
  assert.equal(fs.readFileSync(path.join(htmlDir, 'index.html'), 'utf8'), html);
  const alias = path.join(temporary, 'existing-link');
  fs.symlinkSync(htmlDir, alias);
  run(['export', '--format', 'markdown', '--output', alias], 1);
  const mdDir = path.join(temporary, 'markdown');
  run(['export', '--format', 'markdown', '--output', mdDir]);
  assert.ok(!fs.existsSync(path.join(mdDir, 'index.html')));
  assert.equal(fs.readFileSync(path.join(mdDir, 'docs/manual/chezmoi.md'), 'utf8'), embedded.get('docs/manual/chezmoi.md'));
  for (const file of Object.values(handbookTopics)) {
    assert.equal(fs.readFileSync(path.join(mdDir, file), 'utf8'), embedded.get(file));
  }

  const markdownIt = require(path.join(fixture, 'scripts/vendor/markdown-it/markdown-it.min.js'));
  const { documentationRenderer } = require(path.join(fixture, 'scripts/lib/docs-browser.js'));
  const render = text => documentationRenderer(markdownIt, embedded, 'docs/manual/chezmoi.md').render(text);
  const rendered = render('# Example\n\n# Example\n\n[Daily](../20-reference/MANAGING-DOTFILES-WITH-CHEZMOI.md#recovery)\n\n[Here](#example)\n\n<script>alert(1)</script>\n\n![remote](https://example.org/pixel.png)\n\n[bad](javascript:alert(1))\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n```sh\n<unsafe>\n```');
  assert.match(rendered, /id="example"/);
  assert.match(rendered, /id="example-1"/);
  assert.match(rendered, /href="#docs\/20-reference\/MANAGING-DOTFILES-WITH-CHEZMOI.md#recovery"/);
  assert.match(rendered, /href="#docs\/manual\/chezmoi.md#example"/);
  assert.match(rendered, /<table>/);
  assert.match(rendered, /&lt;unsafe&gt;/);
  assert.ok(!rendered.includes('<script>'));
  assert.ok(!rendered.includes('<img'));
  assert.ok(!rendered.includes('href="javascript:'));

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

  // Browser opening is stubbed; no app is launched and no Node binary is on PATH.
  const bin = path.join(temporary, 'bin'); fs.mkdirSync(bin);
  const openLog = path.join(temporary, 'opened');
  fs.writeFileSync(path.join(bin, 'open'), '#!/bin/bash\nprintf "%s\\n" "$@" > "$DOCS_OPEN_LOG"\n', { mode: 0o700 });
  const browserTemp = path.join(temporary, 'browser space # percent %'); fs.mkdirSync(browserTemp);
  run(['chezmoi-guide', '--browser'], 0, { PATH: `${bin}:/usr/bin:/bin`, TMPDIR: browserTemp, DOCS_OPEN_LOG: openLog });
  const opened = fs.readFileSync(openLog, 'utf8').trim();
  assert.match(opened, /index.html#docs\/manual\/chezmoi.md$/);
  assert.ok(fs.existsSync(decodeURIComponent(opened.slice('file://'.length).split('#')[0])));
  assert.deepEqual(fs.readdirSync(path.join(home, '.day-one-mac')), ['private.md']);

  // Reject symlinked listed inputs and symlink parents before writing output.
  const guide = path.join(fixture, 'docs/manual/chezmoi.md');
  fs.unlinkSync(guide); fs.symlinkSync(path.join(home, '.day-one-mac/private.md'), guide);
  const rejected = path.join(temporary, 'rejected');
  run(['export', '--format', 'html', '--output', rejected], 1);
  assert.ok(!fs.existsSync(rejected));
  fs.unlinkSync(guide); fs.copyFileSync(path.join(root, 'docs/manual/chezmoi.md'), guide);
  fs.renameSync(path.join(fixture, 'docs/manual'), path.join(temporary, 'manual'));
  fs.symlinkSync(path.join(temporary, 'manual'), path.join(fixture, 'docs/manual'));
  run(['export', '--format', 'markdown', '--output', rejected], 1);
  assert.ok(!fs.existsSync(rejected));
  console.log('PASS: offline docs, guide links/anchors, handbook topics, software catalogue coverage, exports, privacy, no-overwrite, and symlink rejection');
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
