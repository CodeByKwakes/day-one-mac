#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
for (const file of ['install-day-one-mac', 'scripts/day-one-mac', 'src/runtime', 'src/setup',
  'config/runtime-files.txt', 'VERSION', '.github/workflows/release.yml', 'release-please-config.json', '.release-please-manifest.json']) {
  assert(!fs.existsSync(path.join(root, file)), `Retired runtime artifact remains: ${file}`);
}
const builder = fs.readFileSync(path.join(root, 'tools/build-skills.cjs'), 'utf8');
assert(!/sourceVersion|runtime-files|read\('VERSION'/.test(builder));
const walk = dir => fs.readdirSync(path.join(root, dir), { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(`${dir}/${e.name}`) : [`${dir}/${e.name}`]);
for (const file of walk('helpers')) {
  const text = fs.readFileSync(path.join(root, file), 'utf8');
  assert(!/src\/core|DAY_ONE_MAC_STATE|with-operation-lock|\.day-one-mac/.test(text), `Runtime dependency: ${file}`);
}
for (const file of walk('integrations').filter(f => /\.(yaml|sh)$/.test(f))) {
  const text = fs.readFileSync(path.join(root, file), 'utf8');
  assert(!/day-one-mac\s+(?:runtime|workspace|tool|modules|root|docs|rollback|uninstall|assistant)/.test(text), `Retired integration: ${file}`);
}
console.log('PASS: runtime and publishing removed; retained helpers and integrations are independent');
