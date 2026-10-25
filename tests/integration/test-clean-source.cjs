#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { execFileSync, spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
// Include deliberate new source files during development, but never ignored files.
const eligible = new Set(execFileSync('git', ['ls-files','--cached','--others','--exclude-standard','-z'], { cwd: root, encoding: 'utf8' }).split('\0').filter(Boolean));
for (const manifest of ['config/document-sources.txt','config/skill-sources.txt']) {
  for (const file of fs.readFileSync(path.join(root,manifest),'utf8').split('\n').filter(s=>s&&!s.startsWith('#'))) {
    assert(!file.split('/').includes('.DS_Store'), `Finder metadata must not be bundled: ${manifest}: ${file}`);
    assert(eligible.has(file), `Source depends on an ignored file: ${manifest}: ${file}`);
  }
}
const temp = fs.mkdtempSync(path.join(os.tmpdir(),'day-one-clean-source-'));
try {
  for (const file of eligible) {
    if (!/^(?:docs\/|config\/|templates\/|helpers\/|tools\/|skills\/|tests\/|integrations\/|extensions\/|README\.md$|AGENTS\.md$|CONTRIBUTING\.md$|LICENSE$|SECURITY\.md$|CHANGELOG\.md$)/.test(file)) continue;
    const source=path.join(root,file);
    if(!fs.existsSync(source))continue; // Tracked deletions in the working tree.
    assert(fs.lstatSync(source).isFile(),`Unexpected non-regular public file: ${file}`);
    fs.mkdirSync(path.dirname(path.join(temp,file)),{recursive:true});
    fs.copyFileSync(source,path.join(temp,file));
  }
  for(const script of ['tools/check-project-layout.cjs','tools/build-skills.cjs','tests/integration/test-docs.cjs','tests/integration/test-profile-config.cjs']) {
    const args=script==='tools/build-skills.cjs'?['--check']:[];
    const run=spawnSync(process.execPath,[path.join(temp,script),...args],{cwd:temp,encoding:'utf8',timeout:60000});
    assert.equal(run.status,0,`${script}\n${run.stdout}\n${run.stderr}`);
  }
  console.log('PASS: inventories exclude ignored files; clean source validates, builds skills and exports its reader');
} finally { fs.rmSync(temp,{recursive:true,force:true}); }
