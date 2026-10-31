#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const markdown = require('./vendor/markdown-it/markdown-it.min.js')();
const { documentationRenderer } = require('./docs/docs-browser.js');
const { checkDocumentationQuality } = require('./docs/document-quality.cjs');
const root = path.resolve(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
function regular(file) {
  if (!file || file.split('/').includes('.DS_Store') || path.isAbsolute(file) || file.split('/').some(p => !p || p === '.' || p === '..')) throw new Error(`Unsafe inventory path: ${file}`);
  if (!/^(docs\/|config\/|templates\/|helpers\/|integrations\/|extensions\/|README\.md$|CONTRIBUTING\.md$|AGENTS\.md$|LICENSE$|SECURITY\.md$|CHANGELOG\.md$)/.test(file)) throw new Error(`Non-public source: ${file}`);
  for (let p = file; p !== '.'; p = path.dirname(p)) if (fs.lstatSync(path.join(root,p)).isSymbolicLink()) throw new Error(`Symlink source: ${file}`);
  if (!fs.statSync(path.join(root,file)).isFile()) throw new Error(`Not a regular file: ${file}`);
}
try {
  const inventories = ['config/skill-sources.txt','config/document-sources.txt'].map(file => {
    const lines = read(file).split('\n').filter(s => s && !s.startsWith('#'));
    if (new Set(lines).size !== lines.length) throw new Error(`Duplicates in ${file}`);
    lines.forEach(regular); return new Set(lines);
  });
  const aliases = JSON.parse(read('config/catalogs/document-aliases.json'));
  for (const [old,target] of Object.entries(aliases)) {
    regular(old); regular(target);
    if (!read(old).includes('<!-- day-one-mac:compatibility-guide -->') || read(target).includes('<!-- day-one-mac:compatibility-guide -->')) throw new Error(`Invalid alias: ${old}`);
    if (!inventories.every(set => set.has(old) && set.has(target))) throw new Error(`Unbundled alias: ${old}`);
  }
  const documents = new Map([...new Set(inventories.flatMap(set => [...set]))].filter(f => f.endsWith('.md')).map(f => [f,read(f)]));
  const rendered = new Map([...documents].map(([file,text]) => [file,documentationRenderer(require('./vendor/markdown-it/markdown-it.min.js'),documents,file).render(text)]));
  const failures = checkDocumentationQuality(documents, inventories[1], JSON.parse(read('config/catalogs/assistant-skills.json')).nodeMinimum);
  for (const [file,text] of documents) {
    const visit = tokens => { for (const token of tokens) {
      const href = token.attrGet('href') || token.attrGet('src');
      if (href && !/^[a-z][a-z\d+.-]*:|^\/\//i.test(href)) {
        const [name,fragment] = decodeURIComponent(href).split('#');
        const target = name ? path.relative(root,path.resolve(root,path.dirname(file),name)) : file;
        if (target.startsWith('..') || !fs.existsSync(path.join(root,target))) failures.push(`${file}: missing ${href}`);
        else if (fragment && rendered.has(target) && !rendered.get(target).includes(`id="${fragment}"`)) failures.push(`${file}: missing anchor ${href}`);
      }
      if (token.children) visit(token.children);
    } };
    visit(markdown.parse(text,{}));
  }
  if (failures.length) throw new Error(failures.join('\n'));
  console.log(`PASS: reviewed sources, ${Object.keys(aliases).length} aliases and links/anchors across ${documents.size} documents`);
} catch (e) { console.error(e.message); process.exitCode=1; }
