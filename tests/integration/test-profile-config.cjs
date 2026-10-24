'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const { recipe } = require('../../src/modules/vscode-profiles/build.cjs');
const golden = require('../fixtures/vscode/recipes-v1.json');
// Keep the original migration snapshot intact; allow only this deliberate addition.
const expected = structuredClone(golden);
for (const profile of Object.values(expected)) profile.settings['terminal.integrated.suggest.upArrowNavigatesHistory'] = true;
for (const slug of Object.keys(expected)) assert.deepEqual(recipe(slug), expected[slug]);
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-profile-config-'));
try {
  fs.mkdirSync(path.join(tmp, 'src/modules/vscode-profiles'), { recursive: true });
  fs.mkdirSync(path.join(tmp, 'config/profiles/vscode'), { recursive: true });
  fs.copyFileSync(path.join(root, 'src/modules/vscode-profiles/build.cjs'), path.join(tmp, 'src/modules/vscode-profiles/build.cjs'));
  const target = path.join(tmp, 'config/profiles/vscode/profiles.json');
  const config = JSON.parse(fs.readFileSync(path.join(root, 'config/profiles/vscode/profiles.json')));
  fs.writeFileSync(target, JSON.stringify(config));
  const independent = require(path.join(tmp, 'src/modules/vscode-profiles/build.cjs'));
  for (const slug of Object.keys(expected)) assert.deepEqual(independent.recipe(slug), expected[slug]);
  config.schemaVersion = 99;
  fs.writeFileSync(target, JSON.stringify(config));
  assert.throws(() => independent.recipe('default'), /schema/);
  config.schemaVersion = 1;
  config.profiles.default.optional.push('bad extension');
  fs.writeFileSync(target, JSON.stringify(config));
  assert.throws(() => independent.recipe('default'), /extension ID/);
  console.log('Profile configuration: baseline equivalence, no documentation dependency, invalid schema and invalid extension rejection passed.');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
