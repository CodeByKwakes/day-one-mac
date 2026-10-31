#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { checkDocumentationQuality } = require('../../tools/docs/document-quality.cjs');
const { documentationRenderer, findDocumentation } = require('../../tools/docs/docs-browser.js');
const documents = new Map([
  ['docs/setup/manual/current.md', '# Current\n\n[Continue](../../shared/old.md)\n'],
  ['docs/shared/old.md', '<!-- day-one-mac:compatibility-guide -->\n\n[Current](../setup/manual/current.md)'],
]);
assert(checkDocumentationQuality(documents).some(error => error.includes('retired page')));
documents.set('docs/setup/manual/current.md', '# Current\n\nRerun the local planner.');
assert(checkDocumentationQuality(documents).some(error => error.includes('retired behaviour')));
documents.set('docs/setup/manual/current.md', '# Current\n\n```bash\nbrew install --cask docker-desktop\n# Or\nbrew install --cask orbstack\n```');
assert(checkDocumentationQuality(documents).some(error => error.includes('alternative installers')));
documents.set('docs/setup/manual/current.md', '# Current\n\n```bash\nbrew install --cask docker-desktop\n```\n\nOr:\n\n```bash\nbrew install --cask orbstack\n```');
assert.deepEqual(checkDocumentationQuality(documents), []);
documents.set('docs/setup/manual/current.md', '# Current\n\n[Missing example](../../../config/missing.csv)');
assert(checkDocumentationQuality(documents, new Set(documents.keys())).some(error => error.includes('unbundled asset')));
// Historical records and explicit notices must remain readable, not rewritten to pass.
documents.set('docs/setup/manual/current.md', '# Current\n\n[Current section](#setup)');
documents.set('maintainers/plans/old.md', '# Historical\n\nRerun the local planner.');
assert.deepEqual(checkDocumentationQuality(documents), []);
assert(checkDocumentationQuality(new Map([['guide.md', 'Use Node 22 or newer.']]), null, '22.20.0').some(error => error.includes('Node minimum')));
assert.deepEqual(checkDocumentationQuality(new Map([['guide.md', 'Use Node.js 22.20 or newer.']]), null, '22.20.0'), []);
assert(checkDocumentationQuality(new Map([['guide.md', '# Guide\n\n[Continue]()']])).some(error => error.includes('empty destination')));
assert(checkDocumentationQuality(new Map([['guide.md', '# Guide\n\nUse Day One Script Commands for setup checks.']])).some(error => error.includes('retired behaviour')));
assert(checkDocumentationQuality(new Map([['guide.md', 'An assistant workspace\nupdates by creating a new export.']])).some(error => error.includes('retired behaviour')));
for (const text of [
  'For Day One Mac itself, follow the [native plugin and standalone MCP recipe](guide.md).',
  'Use native plugins for selected Codex/Claude Code clients and a separate MCP\nregistration for Claude Desktop.',
  'Follow the [plugin and standalone MCP location guide](guide.md).',
]) {
  assert(checkDocumentationQuality(new Map([['templates/skills/day-one-setup/SKILL.md', text]])).some(error => error.includes('archived Day One Mac MCP route')));
}
assert.deepEqual(checkDocumentationQuality(new Map([['guide.md', 'Day One Mac native plugins start no MCP server. External MCP services have their own recipes.']])), []);
for (const entry of ['README.md', 'docs/setup/manual/ai/day-one-skills.md']) {
  assert(checkDocumentationQuality(new Map([[entry, 'Use Node.js and npm.\n\n```bash\nnpx skills@1.7.4 add CodeByKwakes/day-one-mac --list\n```']])).some(error => error.includes('Git prerequisite')));
  assert.deepEqual(checkDocumentationQuality(new Map([[entry, 'Check `git --version` first.\n\n```bash\nnpx skills@1.7.4 add CodeByKwakes/day-one-mac --list\n```']])), []);
}
const titles = new Map([['guide.md', 'Troubleshoot the client']]);
assert.deepEqual(findDocumentation(titles, 'spawn node ENOENT', new Map([['guide.md', '# Client\n\nIf spawn node ENOENT appears, inspect PATH.']])), [['guide.md', 'Troubleshoot the client']]);
assert.deepEqual(findDocumentation(titles, 'not-present', new Map([['guide.md', '# Client']])), []);
// Check every reviewed current source, not the generated copies of that source.
const root = path.resolve(__dirname, '../..');
const sources = fs.readFileSync(path.join(root, 'config/document-sources.txt'), 'utf8').split('\n').filter(s => s && !s.startsWith('#'));
const current = new Map(sources.filter(f => f.endsWith('.md')).map(f => [f, fs.readFileSync(path.join(root, f), 'utf8')]));
assert.deepEqual(checkDocumentationQuality(current, new Set(sources), JSON.parse(fs.readFileSync(path.join(root, 'config/catalogs/assistant-skills.json'))).nodeMinimum), []);
const pluginPage = 'docs/setup/manual/ai/day-one-plugins.md';
const pluginHtml = documentationRenderer(require('../../tools/vendor/markdown-it/markdown-it.min.js'), current, pluginPage).render(current.get(pluginPage));
for (const id of ['review-the-package', 'verify-and-remove']) assert(pluginHtml.includes(`id="${id}"`), `Published plugin section lost: ${id}`);
const dbText = current.get('docs/setup/manual/databases/dbeaver.md').split('### Manual server route')[1].split('### Shared manual verification')[0];
assert(!/both routes|assisted route/i.test(dbText), 'The manual server recipe must not route to removed provisioning');
const oldAnchors = JSON.parse(fs.readFileSync(path.join(root, 'tests/fixtures/docs/vscode-published-anchors.json')));
const rendered = documentationRenderer(require('../../tools/vendor/markdown-it/markdown-it.min.js'), current, 'docs/setup/manual/editors/vscode.md').render(current.get('docs/setup/manual/editors/vscode.md'));
for (const anchor of oldAnchors) assert(rendered.includes(`id="${anchor}"`), `Published VS Code section lost: ${anchor}`);
for (const skill of JSON.parse(fs.readFileSync(path.join(root, 'config/catalogs/assistant-skills.json'))).skills) {
  const seed = path.join(root, 'skills', skill.name, 'references/project/extensions/second-brain/notion/seeds/domains.csv');
  assert(fs.readFileSync(seed).equals(fs.readFileSync(path.join(root, 'extensions/second-brain/notion/seeds/domains.csv'))), 'The linked Notion seed must work without a checkout');
}
console.log('PASS: current documentation rejects retired routes, removed behaviour, combined alternative installers and missing bundled assets; search finds guide body text');
