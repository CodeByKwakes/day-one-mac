#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const markdown = require('./vendor/markdown-it/markdown-it.min.js')();
const root = path.resolve(__dirname, '..');
const read = name => fs.readFileSync(path.join(root, name), 'utf8');
const metadata = JSON.parse(read('config/catalogs/assistant-skills.json'));
const aliases = JSON.parse(read('config/catalogs/document-aliases.json'));
const sources = new Set(read('config/skill-sources.txt').split('\n').filter(name => name && !name.startsWith('#') && !name.startsWith('skills/')));
const hash = content => crypto.createHash('sha256').update(content).digest('hex');
const external = href => /^[a-z][a-z\d+.-]*:|^\/\//i.test(href);
const portableNotes = '\n## Installed package\n\n'
  + 'Resolve bundled links relative to this skill directory, not the working directory.\n'
  + 'The project reference snapshot is under `references/project/`; use its matching\n'
  + 'paths when a guide refers to supplied configuration or template files. Read only\n'
  + 'the guide needed for the current task. Keep this installed package unchanged.\n\n'
  + 'Save private notes outside this installed package. No Day One Mac runtime is required.\n'
  + 'Reviewed helpers are bundled under `references/project/helpers/`; inspect their\n'
  + 'help and preview output before approving changes. Manual recipes need no helpers.\n';
function regular(name) {
  if (!name || path.isAbsolute(name) || name.split('/').some(part => !part || part === '.' || part === '..')) throw new Error(`Unsafe source: ${name}`);
  if (!/^(docs\/|config\/|helpers\/|templates\/|extensions\/second-brain\/obsidian\/assets\/|README\.md$|CONTRIBUTING\.md$|AGENTS\.md$|LICENSE$)/.test(name)) throw new Error(`Unapproved source: ${name}`);
  if (!sources.has(name)) throw new Error(`Source is not in the reviewed skill-source inventory: ${name}`);
  for (let current = name; current !== '.'; current = path.dirname(current)) {
    if (fs.lstatSync(path.join(root, current)).isSymbolicLink()) throw new Error(`Symlink source: ${current}`);
  }
  if (!fs.statSync(path.join(root, name)).isFile()) throw new Error(`Not a file: ${name}`);
}
function walk(directory) {
  const absolute = path.join(root, directory);
  if (fs.lstatSync(absolute).isSymbolicLink()) throw new Error(`Symlink directory: ${directory}`);
  return fs.readdirSync(absolute, { withFileTypes: true }).sort((a,b) => a.name.localeCompare(b.name, 'en')).flatMap(entry => {
    const name = `${directory}/${entry.name}`;
    if (entry.isSymbolicLink()) throw new Error(`Symlink source: ${name}`);
    return entry.isDirectory() ? walk(name) : [name];
  });
}
function links(text) {
  const found = new Set();
  const visit = tokens => {
    for (const token of tokens) {
      const href = token.attrGet('href') || token.attrGet('src');
      if (href && !external(href) && !href.startsWith('#')) found.add(href);
      if (token.children) visit(token.children);
    }
  };
  visit(markdown.parse(text, {}));
  return [...found];
}
function reference(source, href) {
  const split = href.indexOf('#');
  const name = decodeURIComponent(split < 0 ? href : href.slice(0, split));
  const resolved = path.resolve(root, path.dirname(source), name);
  if (!resolved.startsWith(root + path.sep)) throw new Error(`Escaping reference: ${source}: ${href}`);
  const relative = path.relative(root, resolved);
  const canonical = aliases[relative] || relative;
  regular(canonical);
  // Compatibility pages may have headings absent from their new owner.
  return { source: canonical, fragment: aliases[relative] ? '' : split < 0 ? '' : href.slice(split) };
}
function buildPackage(spec) {
  if (!/^day-one-[a-z-]+$/.test(spec.name)) throw new Error('Invalid skill name.');
  const output = new Map();
  const pending = [];
  const targets = new Map();
  const entry = `templates/skills/${spec.name}/SKILL.md`;
  targets.set(entry, 'SKILL.md');
  for (const name of spec.workflows || []) targets.set(`templates/skills/${name}/SKILL.md`, `references/workflows/${name}.md`);
  const schedule = (source, target) => {
    regular(source);
    if (!targets.has(source)) targets.set(source, target || `references/project/${source}`);
    if (!pending.includes(source) && !output.has(targets.get(source))) pending.push(source);
  };
  schedule(entry);
  schedule('LICENSE', 'LICENSE');
  for (const name of spec.workflows || []) schedule(`templates/skills/${name}/SKILL.md`);
  for (const asset of metadata.assets) for (const source of walk(asset)) schedule(source);
  if (spec.roles) {
    for (const source of walk('templates/agents')) schedule(source, source.replace('templates/', 'assets/'));
  }
  while (pending.length) {
    const source = pending.shift();
    const target = targets.get(source);
    if (output.has(target)) continue;
    let content = fs.readFileSync(path.join(root, source));
    if (source.endsWith('.md')) {
      let text = content.toString('utf8');
      if (target === 'SKILL.md') text = text.trimEnd() + '\n' + portableNotes;
      if (target.startsWith('references/workflows/')) text = text.replace(/^---\n[\s\S]*?\n---\n+/, '');
      const replacements = new Map();
      for (const href of links(text)) {
        const next = reference(source, href);
        schedule(next.source);
        const relative = path.relative(path.dirname(target), targets.get(next.source)).split(path.sep).join('/');
        replacements.set(decodeURI(href), encodeURI(relative) + next.fragment);
      }
      const replace = href => replacements.get(decodeURI(href)) || href;
      text = text.replace(/(\]\()(<[^>]+>|[^\s)]+)(?=(?:\s+"[^"]*")?\))/g, (_, prefix, href) => {
        const angle = href.startsWith('<');
        const next = replace(angle ? href.slice(1, -1) : href);
        return prefix + (angle ? `<${next}>` : next);
      }).replace(/^(\s{0,3}\[[^\]]+\]:\s*)(<[^>]+>|\S+)/gm, (_, prefix, href) => {
        const angle = href.startsWith('<');
        return prefix + (angle ? `<${replace(href.slice(1,-1))}>` : replace(href));
      });
      content = Buffer.from(text);
    }
    output.set(target, content);
  }
  output.set('bundle.json', Buffer.from(JSON.stringify({ schema: 1, skill: spec.name,
    files: Object.fromEntries([...output].sort(([a],[b]) => a.localeCompare(b, 'en')).map(([name, content]) => [name, hash(content)])) }, null, 2) + '\n'));
  return output;
}
function generatedFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  if (fs.lstatSync(directory).isSymbolicLink()) throw new Error(`Symlink output: ${directory}`);
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const full = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Symlink output: ${full}`);
    return entry.isDirectory() ? generatedFiles(full) : [full];
  });
}
function writeAtomic(file, content) {
  const temporary = path.join(path.dirname(file), `.${path.basename(file)}.${crypto.randomBytes(8).toString('hex')}`);
  try {
    fs.writeFileSync(temporary, content, { flag: 'wx', mode: 0o644 });
    fs.renameSync(temporary, file);
  } finally {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
  }
}
function main() {
  const check = process.argv.length === 3 && process.argv[2] === '--check';
  if (!check && process.argv.length !== 2) throw new Error('Usage: node tools/build-skills.cjs [--check]');
  if (metadata.schema !== 1 || new Set(metadata.skills.map(s => s.name)).size !== metadata.skills.length) throw new Error('Invalid skill catalogue.');
  const expected = new Map();
  for (const spec of metadata.skills) for (const [file, content] of buildPackage(spec)) expected.set(`skills/${spec.name}/${file}`, content);
  const existing = generatedFiles(path.join(root, 'skills')).map(file => path.relative(root, file));
  const unexpected = existing.filter(file => !expected.has(file));
  if (unexpected.length) throw new Error(`Unexpected generated files; review before removing: ${unexpected.join(', ')}`);
  const stale = [];
  for (const [file, content] of expected) {
    const full = path.join(root, file);
    if (!fs.existsSync(full) || !fs.readFileSync(full).equals(content)) {
      if (check) stale.push(file);
      else { fs.mkdirSync(path.dirname(full), { recursive: true }); writeAtomic(full, content); }
    }
  }
  if (stale.length) throw new Error(`Generated skills are stale (${stale.length} files). Run node tools/build-skills.cjs.`);
  console.log(`Portable skills ${check ? 'verified' : 'generated'}: ${metadata.skills.length} packages, ${expected.size} files.`);
}
if (require.main === module) { try { main(); } catch (error) { console.error(error.message); process.exitCode = 1; } }
module.exports = { buildPackage, links, reference, regular, writeAtomic };
