'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname,'../..');
const read = file => fs.readFileSync(path.join(root,file),'utf8');
const archive = 'maintainers/archive/2026-10-31-day-one-mac-mcp';
const manifest = JSON.parse(read(archive+'/manifest.json'));
assert.match(manifest.sourceRevision,/^[a-f0-9]{40}$/);
assert(manifest.files['integrations/mcp/src/server.ts']);
assert(manifest.files['integrations/mcp/npm-shrinkwrap.json']);
for (const [name,hash] of Object.entries(manifest.files)) {
  assert(!path.isAbsolute(name) && !name.split('/').includes('..'));
  const bytes=fs.readFileSync(path.join(root,archive,'source',name));
  assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),hash,name);
}
for (const file of ['integrations/mcp/package.json','integrations/mcp/src/server.ts','config/mcp/day-one-mac.json','.dockerignore']) {
  assert(!fs.existsSync(path.join(root,file)),`Active MCP artifact remains: ${file}`);
}
const scripts=JSON.parse(read('package.json')).scripts;
assert(!scripts['test:mcp']);
for (const command of Object.values(scripts)) assert(!command.includes('integrations/mcp'));
assert(!/mcp-container|integrations\/mcp/.test(read('.github/workflows/validate.yml')));
assert.match(read('integrations/mcp/README.md'),/archived/);
for (const file of ['config/skill-sources.txt','config/document-sources.txt']) {
  assert(!read(file).split('\n').some(line=>line.startsWith('maintainers/archive/') || line==='config/mcp/day-one-mac.json'));
}
console.log('PASS: hashed MCP archive preserved; server build, container CI and active specification excluded; skills retain portable archive notice');
