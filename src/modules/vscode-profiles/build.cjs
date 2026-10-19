#!/usr/bin/env node
'use strict';
// Versioned configuration is authoritative; prose can be reorganized independently.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../../..');
const names = { default: 'Default', 'full-stack': 'Full Stack', ai: 'AI', operations: 'Operations' };

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
  const config = JSON.parse(fs.readFileSync(path.join(root, 'config/profiles/vscode/profiles.json'), 'utf8'));
  if (config.schemaVersion !== 1) throw new Error('Unsupported profile configuration schema.');
  const profile = config.profiles?.[slug];
  const object = value => value && typeof value === 'object' && !Array.isArray(value);
  if (!profile || profile.name !== name || !object(config.sharedSettings) || !object(profile.settings)
      || !Array.isArray(profile.extensions) || !Array.isArray(profile.optional)) {
    throw new Error('Invalid profile configuration.');
  }
  const required = profile.extensions;
  const optional = profile.optional;
  if (new Set([...required, ...optional]).size !== required.length + optional.length) throw new Error('Duplicate extension ID.');
  for (const id of [...required, ...optional]) {
    if (typeof id !== 'string' || !/^[a-z0-9-]+\.[a-z0-9._-]+$/.test(id) || /^github\.copilot(?:-chat)?$/.test(id)) {
      throw new Error(`Unexpected extension ID: ${id}`);
    }
  }
  for (const id of selected) if (!optional.includes(id)) throw new Error(`Not optional for ${name}: ${id}`);
  let settings = config.sharedSettings;
  if (profile.extends) {
    if (profile.extends !== 'full-stack' || slug !== 'ai' || !object(config.profiles['full-stack']?.settings)) {
      throw new Error('Invalid profile inheritance.');
    }
    settings = merge(settings, config.profiles[profile.extends].settings);
  }
  settings = merge(settings, profile.settings);
  const keybindings = profile.keybindings ? config.keybindings?.[profile.keybindings] : [];
  if (!Array.isArray(keybindings)) throw new Error('Invalid profile keybindings.');
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
      console.log('Usage: day-one-mac vscode-profile <profile> [--dry-run] [--output NEW_DIRECTORY]\n'
        + '  [--with OPTIONAL_EXTENSION_ID]... [--install-extensions] [--code CLI_PATH]\n'
        + 'Generates review files only by default. Requires Node.js 22+.\n'
        + 'Install mode requires current Phase 8 and adds missing extensions; it may create the named profile.\n'
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
  if (install) {
    const gate = spawnSync('/bin/bash', ['-c', 'source "$1"; day_one_phase_current 08',
      'profile-prerequisite', path.join(root, 'src/core/module-execution.sh')], { encoding: 'utf8' });
    if (gate.error || gate.status !== 0) {
      console.error('Current Phase 8 completion is required before installing extensions; use --dry-run or generate a review bundle first.');
      process.exitCode = 10;
      return;
    }
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
    + 'connections remain manual: follow docs/how-to/apps/VSCODE-PROFILES.md and VSCODE-TYPESCRIPT.md.\n');
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
