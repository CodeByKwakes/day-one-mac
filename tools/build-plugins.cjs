#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const json = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function files(directory) {
  if (fs.lstatSync(directory).isSymbolicLink()) throw Error(`Symlink plugin source: ${directory}`);
  return fs.readdirSync(directory, {withFileTypes:true}).sort((a,b) => a.name.localeCompare(b.name, 'en')).flatMap(entry => {
    const file = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw Error(`Symlink plugin source: ${file}`);
    if (entry.isDirectory()) return files(file);
    if (!entry.isFile()) throw Error(`Not a regular plugin source: ${file}`);
    return [file];
  });
}
function write(file, value) {
  fs.mkdirSync(path.dirname(file), {recursive:true});
  fs.writeFileSync(file, typeof value === 'string' ? value : JSON.stringify(value, null, 2) + '\n', {flag:'wx', mode:0o644});
}
function copyDirectory(source, destination) {
  for (const file of files(source)) {
    const target = path.join(destination, path.relative(source, file));
    fs.mkdirSync(path.dirname(target), {recursive:true});
    fs.copyFileSync(file, target, fs.constants.COPYFILE_EXCL);
  }
}
async function buildPlugins(output) {
  if (!output || !path.isAbsolute(output)) throw Error('Plugin output must be a new absolute directory outside the checkout.');
  const resolved = path.join(fs.realpathSync(path.dirname(output)), path.basename(output));
  if (resolved === root || resolved.startsWith(root + path.sep)) throw Error('Keep plugin artifacts outside the checkout.');
  const checked = spawnSync(process.execPath, [path.join(root, 'tools/build-skills.cjs'), '--check'], {encoding:'utf8'});
  if (checked.status !== 0) throw Error(checked.stdout + checked.stderr);
  const metadata = json(path.join(root, 'templates/plugins/metadata.json'));
  const mcp = json(path.join(root, 'integrations/mcp/package.json'));
  const spec = json(path.join(root, 'config/mcp/day-one-mac.json'));
  if (metadata.name !== 'day-one-mac' || metadata.version !== mcp.version) throw Error('Plugin identity/version must match the reviewed MCP package version.');
  const { build } = require('../integrations/mcp/node_modules/esbuild');
  fs.mkdirSync(resolved, {mode:0o700}); // Existing outputs, including links, are never replaced.
  const codex = path.join(resolved, 'codex', metadata.name);
  const claude = path.join(resolved, 'claude', metadata.name);
  const runtime = path.join(codex, 'runtime');
  // Preserve import.meta-relative metadata paths used by the existing server.
  const bundled = await build({absWorkingDir:root, entryPoints:['integrations/mcp/dist/src/index.js'],
    outfile:path.join(runtime, 'dist/src/index.js'), bundle:true, platform:'node', format:'esm',
    target:'node22.20', metafile:true, sourcemap:false, legalComments:'eof',
    banner:{js:"import { createRequire as pluginCreateRequire } from 'node:module'; const require = pluginCreateRequire(import.meta.url);"}});
  write(path.join(runtime, 'package.json'), {name:mcp.name, version:mcp.version, type:'module', license:mcp.license, engines:mcp.engines});
  for (const name of ['guides.json', 'server-spec.json']) fs.copyFileSync(path.join(root, 'integrations/mcp/dist', name), path.join(runtime, 'dist', name), fs.constants.COPYFILE_EXCL);
  const notices = [];
  const packages = new Set();
  for (const input of Object.keys(bundled.metafile.inputs)) {
    const match = input.match(/^integrations\/mcp\/node_modules\/((?:@[^/]+\/)?[^/]+)\//);
    if (match) packages.add(match[1]);
  }
  for (const name of [...packages].sort()) {
    const folder = path.join(root, 'integrations/mcp/node_modules', name);
    const pkg = json(path.join(folder, 'package.json'));
    const licenses = fs.readdirSync(folder).filter(file => /^(license|copying|notice)(\.|$)/i.test(file));
    if (!licenses.length) throw Error(`Missing bundled dependency license: ${name}`);
    notices.push({name:pkg.name, version:pkg.version, license:pkg.license});
    for (const file of licenses) {
      if (!fs.lstatSync(path.join(folder,file)).isFile()) throw Error(`Invalid license file: ${name}/${file}`);
      write(path.join(runtime, 'licenses', name.replace('/', '__'), file), fs.readFileSync(path.join(folder,file), 'utf8'));
    }
  }
  write(path.join(runtime, 'licenses', 'dependencies.json'), notices);
  copyDirectory(runtime, path.join(claude, 'runtime'));
  for (const [platform, folder, variable] of [['codex',codex,'PLUGIN_ROOT'], ['claude',claude,'CLAUDE_PLUGIN_ROOT']]) {
    copyDirectory(path.join(root, 'skills/day-one-mac'), path.join(folder, 'skills/day-one-mac'));
    fs.copyFileSync(path.join(root, 'LICENSE'), path.join(folder, 'LICENSE'), fs.constants.COPYFILE_EXCL);
    const server = {type:'stdio', command:'node', args:['${' + variable + '}/runtime/dist/src/index.js']};
    const servers = {mcpServers:{[spec.names[platform]]:server}};
    write(path.join(folder, '.mcp.json'), servers);
    if (platform === 'codex') {
      const overlay = {requires_local_executor:true, interface:{displayName:'Day One Mac', shortDescription:metadata.description, capabilities:['Read']}};
      write(path.join(folder, 'plugin.json'), {$schema:'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json', ...metadata, extensions:{'com.openai':overlay}});
      write(path.join(folder, 'mcp.json'), {$schema:'https://agent-plugins.org/schemas/1.0.0/mcp.schema.json', ...servers});
      write(path.join(folder, '.codex-plugin/plugin.json'), {...metadata, ...overlay, skills:'./skills/', mcpServers:'./.mcp.json'});
    } else write(path.join(folder, '.claude-plugin/plugin.json'), metadata);
    const entries = Object.fromEntries(files(folder).map(file => [path.relative(folder,file).split(path.sep).join('/'), hash(fs.readFileSync(file))]));
    write(path.join(folder, 'artifact.json'), {schema:1, platform, version:metadata.version, files:entries});
  }
  write(path.join(resolved, 'codex/.agents/plugins/marketplace.json'), {name:'day-one-mac-local', interface:{displayName:'Day One Mac local'}, plugins:[{name:metadata.name, source:{source:'local',path:'./day-one-mac'}}]});
  write(path.join(resolved, 'claude/.claude-plugin/marketplace.json'), {name:'day-one-mac-local', owner:metadata.author, metadata:{description:metadata.description}, plugins:[{name:metadata.name, description:metadata.description, source:'./day-one-mac'}]});
  return {codex, claude};
}
async function main() {
  if (process.argv.length !== 4 || process.argv[2] !== '--output') throw Error('Usage: node tools/build-plugins.cjs --output NEW_ABSOLUTE_DIRECTORY');
  console.log(JSON.stringify(await buildPlugins(process.argv[3]), null, 2));
}
if (require.main === module) main().catch(error => { console.error(error.message); process.exitCode = 1; });
module.exports = {buildPlugins};
