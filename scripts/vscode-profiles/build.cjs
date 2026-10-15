#!/usr/bin/env node
'use strict';
// The reviewed guide is the source of truth; fail if its headings/table change.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const names = { default: 'Default', 'full-stack': 'Full Stack', ai: 'AI', operations: 'Operations' };

function section(source, heading) {
  const lines = source.split('\n');
  const start = lines.indexOf(heading);
  if (start < 0 || lines.lastIndexOf(heading) !== start) throw new Error(`Expected one heading: ${heading}`);
  const level = heading.match(/^#+/)[0].length;
  const end = lines.findIndex((line, i) => i > start && /^#+ /.test(line) && line.match(/^#+/)[0].length <= level);
  return lines.slice(start + 1, end < 0 ? undefined : end).join('\n');
}
function jsonBlock(source, heading) {
  const match = section(source, heading).match(/```json\n([\s\S]*?)\n```/);
  if (!match) throw new Error(`Missing JSON: ${heading}`);
  return JSON.parse(match[1]);
}
function merge(base, override) {
  const result = structuredClone(base);
  for (const [key, value] of Object.entries(override)) {
    result[key] = value && typeof value === 'object' && !Array.isArray(value)
      ? merge(result[key] && typeof result[key] === 'object' && !Array.isArray(result[key]) ? result[key] : {}, value)
      : structuredClone(value);
  }
  return result;
}
function recipe(slug, selected = []) {
  const name = names[slug];
  if (!name) throw new Error('Profile must be default, full-stack, ai, or operations.');
  const guide = fs.readFileSync(path.join(root, 'docs/10-app-guides/VSCODE-PROFILES.md'), 'utf8');
  const rows = [...section(guide, `#### ${name} extensions`).matchAll(/^\|.*?\| `([^`]+)` \| (Recommended|Optional):/gm)];
  if (!rows.length) throw new Error(`Missing extension table: ${name}`);
  const required = rows.filter(row => row[2] === 'Recommended').map(row => row[1].toLowerCase());
  const optional = rows.filter(row => row[2] === 'Optional').map(row => row[1].toLowerCase());
  if (new Set([...required, ...optional]).size !== rows.length) throw new Error('Duplicate extension ID.');
  for (const id of [...required, ...optional]) {
    if (!/^[a-z0-9-]+\.[a-z0-9._-]+$/.test(id) || /^github\.copilot(?:-chat)?$/.test(id)) {
      throw new Error(`Unexpected extension ID: ${id}`);
    }
  }
  for (const id of selected) if (!optional.includes(id)) throw new Error(`Not optional for ${name}: ${id}`);
  let settings = jsonBlock(guide, '## 3. Apply shared User Settings');
  if (slug === 'ai') settings = merge(settings, jsonBlock(guide, '### Full Stack overrides'));
  settings = merge(settings, jsonBlock(guide, `### ${name} overrides`));
  const detailed = fs.readFileSync(path.join(root, 'docs/10-app-guides/VSCODE-TYPESCRIPT.md'), 'utf8');
  const keybindings = ['ai', 'full-stack'].includes(slug)
    ? jsonBlock(detailed, '### Personal import shortcuts') : [];
  const extensions = [...new Set([...required, ...selected])];
  return { name, settings, keybindings, extensions, optional };
}
function main(args) {
  const slug = args.shift();
  let output;
  let dryRun = false;
  let install = false;
  let code = 'code';
  const selected = [];
  while (args.length) {
    const arg = args.shift();
    if (['--output', '--with', '--code'].includes(arg)) {
      const value = args.shift();
      if (!value || value.startsWith('--')) throw new Error(`Missing value for ${arg}`);
      if (arg === '--output') output = path.resolve(value);
      if (arg === '--with') selected.push(value.toLowerCase());
      if (arg === '--code') code = value;
    } else if (arg === '--dry-run') dryRun = true;
    else if (arg === '--install-extensions') install = true;
    else if (arg === '--help') {
      console.log('Usage: bash scripts/vscode-profiles/<profile>.sh [--dry-run] [--output NEW_DIRECTORY]\n'
        + '  [--with OPTIONAL_EXTENSION_ID]... [--install-extensions] [--code CLI_PATH]\n'
        + 'Generates review files only by default. Requires Node.js 22+.\n'
        + 'Install mode adds missing extensions; it may create the named VS Code profile.\n'
        + 'It never applies settings, removes extensions, or installs Copilot.');
      return;
    } else throw new Error(`Unknown option: ${arg}`);
  }
  const data = recipe(slug, selected);
  console.log(`${data.name}: ${data.extensions.length} selected extensions\n${data.extensions.join('\n')}`);
  if (dryRun) {
    console.log('Dry run: no files written and no VS Code commands run.');
    return;
  }
  // A new directory prevents overwriting earlier output, including symlinks.
  if (output) fs.mkdirSync(output, { mode: 0o700 });
  else output = fs.mkdtempSync(path.join(os.tmpdir(), `day-one-vscode-${slug}-`));
  const write = (file, value) => fs.writeFileSync(path.join(output, file), value, { mode: 0o600, flag: 'wx' });
  const json = value => `${JSON.stringify(value, null, 2)}\n`;
  const template = {
    name: `${data.name} Review`,
    // VS Code SettingsResource/KeybindingsResource wrap the file text in JSON.
    // These resource envelopes are themselves strings in IUserDataProfileTemplate.
    settings: json({ settings: json(data.settings) }),
    extensions: json(data.extensions.map(id => ({ identifier: { id } }))),
  };
  if (data.keybindings.length) template.keybindings = json({ keybindings: json(data.keybindings), platform: 1 });
  write(`${slug}.code-profile`, json(template));
  write('settings.json', json(data.settings));
  write('keybindings.json', json(data.keybindings));
  write('extensions.txt', `${data.extensions.join('\n')}\n`);
  write('optional-extensions.txt', `${data.optional.join('\n')}\n`);
  write('README.txt', `Profile: ${data.name}\n`
    + 'Export existing profiles as backups first. Import the .code-profile through the Profiles editor.\n'
    + 'The Review suffix avoids confusing the bundle with your existing profile. Review before creating it.\n'
    + 'To update an existing profile (especially the built-in Default), switch to it and merge settings.json\n'
    + 'into Preferences: Open User Settings (JSON). Merge keybindings only after checking conflicts.\n'
    + 'Do not replace unrelated personal settings. Install-mode targets the original profile name, not Review.\n'
    + 'Copilot is intentionally excluded from the installation list. Account sign-in remains manual.\n'
    + 'Folder icon mappings, Angular token colours, shell files, skills, agents, MCP, and database\n'
    + 'connections remain manual: follow docs/10-app-guides/VSCODE-PROFILES.md and VSCODE-TYPESCRIPT.md.\n');
  console.log(`Review files: ${output}`);
  if (!install) return;
  const run = extra => {
    const result = spawnSync(code, ['--profile', data.name, ...extra], { encoding: 'utf8' });
    if (result.error) throw new Error(`Cannot run VS Code CLI: ${result.error.message}. Review files remain in ${output}`);
    if (result.status !== 0) throw new Error(`VS Code failed (${result.status}): ${result.stderr || result.stdout}`);
    return result.stdout;
  };
  const installed = new Set(run(['--list-extensions']).split(/\r?\n/).map(id => id.trim().toLowerCase()));
  for (const id of data.extensions) {
    if (installed.has(id)) console.log(`Already installed: ${id}`);
    else {
      console.log(`Installing in ${data.name}: ${id}`);
      run(['--install-extension', id]);
    }
  }
  console.log('Extensions finished. Settings still require review and manual import/merge.');
}
module.exports = { recipe, merge, main };
if (require.main === module) {
  try { main(process.argv.slice(2)); }
  catch (error) { console.error(`Error: ${error.message}`); process.exitCode = 1; }
}
