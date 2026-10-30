#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');

function regular(rootDir, file) {
  for (let p = file; p !== '.'; p = path.dirname(p)) {
    if (fs.lstatSync(path.join(rootDir, p)).isSymbolicLink()) throw Error(`Symlink agent path: ${p}`);
  }
  if (!fs.statSync(path.join(rootDir, file)).isFile()) throw Error(`Not an agent file: ${file}`);
}
function buildAgents(rootDir = root) {
  regular(rootDir, 'config/catalogs/assistant-agents.json');
  const metadata = JSON.parse(fs.readFileSync(path.join(rootDir, 'config/catalogs/assistant-agents.json'), 'utf8'));
  if (metadata.schema !== 1 || !Array.isArray(metadata.roles) || !metadata.roles.length) throw Error('Invalid agent catalog.');
  const output = new Map(), names = new Set();
  for (const role of metadata.roles) {
    if (!/^day-one-[a-z-]+$/.test(role.name) || names.has(role.name) || typeof role.description !== 'string' || !role.description.trim() || /[\r\n]/.test(role.description) || typeof role.readOnly !== 'boolean') throw Error('Invalid agent role.');
    names.add(role.name);
    const source = `templates/agents/shared/${role.name}.md`;
    regular(rootDir, source);
    const policy = fs.readFileSync(path.join(rootDir, source), 'utf8').trim();
    if (!policy) throw Error(`Empty policy: ${source}`);
    const notice = `Generated from ${source}; edit the shared policy and rebuild.`;
    output.set(`templates/agents/codex/${role.name}.toml`, `# ${notice}\nname = ${JSON.stringify(role.name)}\ndescription = ${JSON.stringify(role.description)}\ndeveloper_instructions = ${JSON.stringify(policy)}\n${role.readOnly ? '\n[features]\nshell_tool = false\napps = false\nplugins = false\n' : ''}`);
    const claudeTools = role.readOnly ? 'Read, Glob, Grep' : 'Read, Glob, Grep, Bash, Edit, Write';
    output.set(`templates/agents/claude/${role.name}.md`, `---\nname: ${role.name}\ndescription: ${JSON.stringify(role.description)}\ntools: ${claudeTools}\npermissionMode: ${role.readOnly ? 'plan' : 'default'}\n---\n\n<!-- ${notice} -->\n\n${policy}\n`);
    output.set(`templates/agents/copilot/${role.name}.agent.md`, `---\nname: ${role.name}\ndescription: ${JSON.stringify(role.description)}\ntools: ${role.readOnly ? "['read', 'search']" : "['read', 'search', 'edit', 'execute']"}\n---\n\n<!-- ${notice} -->\n\n${policy}\n`);
  }
  return output;
}
function main() {
  const check = process.argv.length === 3 && process.argv[2] === '--check';
  if (!check && process.argv.length !== 2) throw Error('Usage: node tools/build-agents.cjs [--check]');
  const output = buildAgents(), stale = [];
  for (const platform of ['codex', 'claude', 'copilot']) {
    const dir = `templates/agents/${platform}`;
    if (fs.lstatSync(path.join(root, dir)).isSymbolicLink()) throw Error(`Symlink agent path: ${dir}`);
    for (const name of fs.readdirSync(path.join(root, dir))) {
      if (!output.has(`${dir}/${name}`)) throw Error(`Unexpected agent adapter; review before removal: ${dir}/${name}`);
    }
  }
  for (const [name, content] of output) {
    const file = path.join(root, name);
    if (fs.existsSync(file)) regular(root, name);
    else if (fs.lstatSync(path.dirname(file)).isSymbolicLink()) throw Error(`Symlink agent output: ${name}`);
    if (fs.existsSync(file) && fs.readFileSync(file, 'utf8') === content) continue;
    if (check) { stale.push(name); continue; }
    const temp = `${file}.${crypto.randomBytes(8).toString('hex')}`;
    try { fs.writeFileSync(temp, content, {flag: 'wx', mode: 0o644}); fs.renameSync(temp, file); }
    finally { if (fs.existsSync(temp)) fs.unlinkSync(temp); }
  }
  if (stale.length) throw Error(`Generated agents are stale: ${stale.join(', ')}`);
  console.log(`Native agent adapters ${check ? 'verified' : 'generated'}: ${output.size}.`);
}
if (require.main === module) { try { main(); } catch (error) { console.error(error.message); process.exitCode = 1; } }
module.exports = { buildAgents };
