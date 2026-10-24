#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '../..');
const digest = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const validRelative = name => typeof name === 'string' && name.length > 0 && !path.isAbsolute(name)
  && !/[\x00-\x1f\x7f\\]/.test(name) && name.split('/').every(part => part && part !== '.' && part !== '..');
function safePath(target) {
  if (!path.isAbsolute(target) || /[\x00-\x1f\x7f]/.test(target)) throw new Error('Use an absolute path without control characters.');
  for (let current = target; current !== path.dirname(current); current = path.dirname(current)) {
    try { if (fs.lstatSync(current).isSymbolicLink()) throw new Error(`Refusing symlink path: ${current}`); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
}
function filesUnder(directory, prefix = '') {
  const entries = [];
  for (const name of fs.readdirSync(directory).sort()) {
    const relative = prefix ? `${prefix}/${name}` : name;
    if (!validRelative(relative)) throw new Error('Invalid file name.');
    const full = path.join(directory, name);
    const info = fs.lstatSync(full);
    if (info.isDirectory()) entries.push(...filesUnder(full, relative));
    else if (info.isFile() || info.isSymbolicLink()) entries.push(relative);
    else throw new Error(`Unsupported filesystem object: ${relative}`);
  }
  return entries;
}
function exportWorkspace(destination) {
  safePath(destination);
  if (!fs.statSync(path.dirname(destination)).isDirectory()) throw new Error('Create the parent directory first.');
  // Exclusive directory creation refuses existing files, directories and dangling links.
  fs.mkdirSync(destination, { mode: 0o700 });
  const files = {};
  const copy = (source, relative) => {
    if (!validRelative(relative)) throw new Error('Unsafe export path.');
    safePath(source);
    if (!fs.lstatSync(source).isFile()) throw new Error('Only regular source files can be exported.');
    const target = path.join(destination, relative);
    fs.mkdirSync(path.dirname(target), { recursive: true, mode: 0o700 });
    fs.writeFileSync(target, fs.readFileSync(source), { flag: 'wx', mode: 0o600 });
    files[relative] = digest(target);
  };
  // The package allowlist is authoritative; never copy private checkout additions.
  for (const relative of fs.readFileSync(path.join(root, 'config/runtime-files.txt'), 'utf8').split('\n')) {
    if (!relative || relative.startsWith('#')) continue;
    if (!validRelative(relative)) throw new Error('Unsafe runtime manifest.');
    if (relative.startsWith('docs/') || relative.startsWith('config/') || relative === 'README.md' || relative === 'CONTRIBUTING.md' || relative === 'LICENSE'
      || relative.startsWith('templates/phase-05-shell-files/')) copy(path.join(root, relative), relative);
  }
  for (const [source, target] of [['skills', '.agents/skills'], ['templates/agents/codex', '.codex/agents'],
    ['templates/agents/claude', '.claude/agents'], ['templates/agents/copilot', '.github/agents'], ['templates/setup-assistant', '']]) {
    const listed = fs.readFileSync(path.join(root, 'config/runtime-files.txt'), 'utf8').split('\n').filter(file => file.startsWith(`${source}/`));
    if (!listed.length) throw new Error(`Missing assistant assets: ${source}`);
    for (const entry of listed) {
      const file = entry.slice(source.length + 1);
      copy(path.join(root, entry), target ? `${target}/${file}` : file);
    }
  }
  fs.symlinkSync('../.agents/skills', path.join(destination, '.claude/skills'));
  fs.mkdirSync(path.join(destination, 'session'), { mode: 0o700 });
  fs.writeFileSync(path.join(destination, 'assistant-manifest.json'), `${JSON.stringify({
    schema: 1, version: fs.readFileSync(path.join(root, 'VERSION'), 'utf8').trim(), files,
    links: { '.claude/skills': '../.agents/skills' },
  }, null, 2)}\n`, { flag: 'wx', mode: 0o600 });
  checkWorkspace(destination);
  console.log(`Open this private workspace in your client: ${destination}\nRead START.md. Account and permission setup remain manual.`);
}
function checkWorkspace(destination) {
  safePath(destination);
  const manifestPath = path.join(destination, 'assistant-manifest.json');
  safePath(manifestPath);
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  if (manifest.schema !== 1 || typeof manifest.version !== 'string' || !manifest.files || !manifest.links
    || manifest.links['.claude/skills'] !== '../.agents/skills' || Object.keys(manifest.links).length !== 1
    || !manifest.files['AGENTS.md'] || !manifest.files['START.md']) throw new Error('Invalid assistant manifest.');
  const expected = ['assistant-manifest.json'];
  for (const [relative, hash] of Object.entries(manifest.files)) {
    if (!validRelative(relative) || relative === 'assistant-manifest.json' || relative.startsWith('session/')
      || !/^[a-f0-9]{64}$/.test(hash)) throw new Error('Invalid checksum entry.');
    const full = path.join(destination, relative); safePath(full);
    if (!fs.lstatSync(full).isFile() || digest(full) !== hash) throw new Error(`Changed assistant file: ${relative}`);
    expected.push(relative);
  }
  const link = path.join(destination, '.claude/skills');
  safePath(path.dirname(link));
  if (!fs.lstatSync(link).isSymbolicLink() || fs.readlinkSync(link) !== '../.agents/skills') throw new Error('Changed Claude skills link.');
  expected.push('.claude/skills');
  const session = path.join(destination, 'session'); safePath(session);
  const actual = filesUnder(destination).filter(file => !file.startsWith('session/'));
  if (JSON.stringify(actual.sort()) !== JSON.stringify(expected.sort())) throw new Error('Unexpected assistant files. Export a new workspace for updates.');
  console.log(`Assistant files verified (${manifest.version}). This checks file integrity, not accounts, machine readiness or publisher authenticity.`);
}
try {
  if (Number(process.versions.node.split('.')[0]) < 22) throw new Error('Node.js 22+ is required.');
  const args = process.argv.slice(2);
  if (args.length === 0 || (args.length === 1 && ['--help', '--plan'].includes(args[0]))) {
    console.log('Usage: day-one-mac assistant --plan | --export NEW_ABSOLUTE_DIRECTORY | --check ABSOLUTE_DIRECTORY\n'
      + 'Requires Node.js 22+. Export creates a private workspace with guides, seven portable skills and Codex/Claude/Copilot roles.\n'
      + 'It never installs or launches a client, changes global settings or installs development tools.\n'
      + 'Choose direct provider access, an existing OmniRoute gateway, local OmniRoute, or defer the gateway.\n'
      + 'Updates use a new export; retain session notes separately. Plan/check do not write.');
  } else if (args.length === 2 && args[0] === '--export') exportWorkspace(args[1]);
  else if (args.length === 2 && args[0] === '--check') checkWorkspace(args[1]);
  else throw new Error('Choose --plan, --export NEW_ABSOLUTE_DIRECTORY, or --check ABSOLUTE_DIRECTORY.');
} catch (error) { console.error(error.message); process.exitCode = 1; }
