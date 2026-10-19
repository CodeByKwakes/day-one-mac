#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const fail = message => { throw new Error(message); };
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const regular = file => {
 if (!file || file.startsWith('/') || file.split('/').some(part => !part || part === '.' || part === '..')) fail(`Unsafe path: ${file}`);
 for (let current = file; current !== '.'; current = path.dirname(current)) {
  const info = fs.lstatSync(path.join(root, current));
  if (info.isSymbolicLink()) fail(`Symlink in maintained path: ${current}`);
 }
 if (!fs.statSync(path.join(root, file)).isFile()) fail(`Not a regular file: ${file}`);
};
try {
 const files = read('config/runtime-files.txt').split('\n').filter(line => line && !line.startsWith('#'));
 if (new Set(files).size !== files.length) fail('Duplicate runtime inventory entry.');
 for (const file of files) {
  regular(file);
  if (/^(?:\.agents|\.claude|\.git|node_modules|tests|tools|maintainers)\//.test(file)) fail(`Contributor data in runtime: ${file}`);
 }
 const rows = file => read(file).split('\n').filter(line => line && !line.startsWith('#')).map(line => line.split('\t'));
 const phases = rows('config/catalogs/phases.tsv');
 if (phases.map(row => row[0]).join(',') !== '01,02,03,04,05,06,07,08') fail('Required phase IDs changed.');
 for (const [id,title,guide,implementation,...extra] of phases) {
  if (!title || extra.length) fail(`Invalid phase row: ${id}`);
  regular(guide); regular(implementation);
 }
 const modules = rows('config/catalogs/modules.tsv');
 if (new Set(modules.map(row => row[0])).size !== modules.length || modules.some(row => row[0] === '12')) fail('Duplicate or retired module ID.');
 for (const row of modules) { if (row.length !== 6) fail('Invalid module metadata.'); regular(row[5]); }
 const dependencies = rows('config/catalogs/phase-dependencies.tsv');
 const seen = new Set();
 for (const [phase,file,...extra] of dependencies) {
  if (extra.length || !/^(\*|0[1-8])$/.test(phase) || seen.has(`${phase}:${file}`)) fail('Invalid or duplicate phase dependency.');
  seen.add(`${phase}:${file}`); regular(file);
  if (!files.includes(file)) fail(`Unpackaged phase dependency: ${file}`);
 }
 for (const [phase,,,implementation] of phases) {
  if (!seen.has(`${phase}:${implementation}`)) fail(`Missing own implementation dependency: ${phase}`);
 }
 const aliases = JSON.parse(read('config/catalogs/document-aliases.json'));
 for (const [old,target] of Object.entries(aliases)) {
  regular(old); regular(target);
  if (!read(old).includes('<!-- day-one-mac:compatibility-guide -->') || read(target).includes('<!-- day-one-mac:compatibility-guide -->')) fail(`Invalid guide alias: ${old}`);
  if (!files.includes(old) || !files.includes(target)) fail(`Unpackaged documentation alias: ${old}`);
 }
 console.log(`Project layout: ${files.length} runtime files, ${phases.length} phases, ${modules.length} modules and ${Object.keys(aliases).length} guide aliases verified.`);
} catch (error) { console.error(error.message); process.exitCode=1; }
