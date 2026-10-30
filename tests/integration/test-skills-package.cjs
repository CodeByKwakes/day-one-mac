#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const names = ['day-one-mac', 'day-one-setup', 'day-one-check', 'day-one-maintain', 'day-one-recover', 'day-one-omniroute', 'day-one-contribute', 'day-one-shortcuts', 'day-one-second-brain', 'day-one-vscode', 'day-one-macos-apps'];
const files = dir => fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
  const file = path.join(dir, entry.name);
  assert(!entry.isSymbolicLink(), `Unexpected packaged symlink: ${file}`);
  return entry.isDirectory() ? files(file) : [file];
});
function validatePackage(folder) {
  const all = files(folder);
  assert(fs.existsSync(path.join(folder, 'LICENSE')));
  const bundle = JSON.parse(fs.readFileSync(path.join(folder, 'bundle.json'), 'utf8'));
  assert.equal(all.length, Object.keys(bundle.files).length + 1);
  for (const [name, hash] of Object.entries(bundle.files)) {
    assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(folder, name))).digest('hex'), hash, name);
  }
  assert.equal(all.filter(file => path.basename(file) === 'SKILL.md').length, 1, 'Nested discoverable skill');
  for (const file of all.filter(file => file.endsWith('.md'))) {
    const text = fs.readFileSync(file, 'utf8');
    assert(!text.includes(os.homedir() + '/'), `Personal path: ${file}`);
    for (const match of text.matchAll(/\]\(([^\s)]+)(?:\s+"[^"]*")?\)/g)) {
      const href = match[1];
      if (/^[a-z][a-z\d+.-]*:|^#/i.test(href)) continue;
      const relative = decodeURIComponent(href.split('#')[0]);
      const target = path.resolve(path.dirname(file), relative);
      assert(target.startsWith(folder + path.sep), `Escaping reference ${file}: ${href}`);
      assert(fs.existsSync(target), `Missing reference ${file}: ${href}`);
    }
  }
}
if (require.main === module) {
 const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-skills-'));
 try {
  const { regular, reference, writeAtomic, buildPackage } = require('../../tools/build-skills.cjs');
  const inventory = path.join(temp, 'skill inventory.txt');
  fs.writeFileSync(inventory, 'old complete inventory\n');
  const reader = fs.openSync(inventory, 'r');
  writeAtomic(inventory, Buffer.from('new complete inventory\n'));
  assert.equal(fs.readFileSync(reader, 'utf8'), 'old complete inventory\n');
  fs.closeSync(reader);
  assert.equal(fs.readFileSync(inventory, 'utf8'), 'new complete inventory\n');
  for (const name of ['../README.md', '/etc/passwd', '.git/config', '.agents/skills/private/SKILL.md', 'config/unreviewed-secret.txt']) assert.throws(() => regular(name));
  assert.throws(() => reference('docs/START-HERE.md', '../../../../etc/passwd'));
  assert.throws(() => buildPackage({name:'day-one-check', assets:['../private']}));
  assert.throws(() => buildPackage({name:'day-one-check', workflows:['missing-workflow']}));
  for (const name of names) {
    const folder = path.join(temp, `Independent é ${name}`);
    fs.cpSync(path.join(root, 'skills', name), folder, { recursive: true });
    validatePackage(folder);
    const helper = path.join(folder, 'references/project/helpers/vscode/build.cjs');
    const review = path.join(temp, `Profile output é ${name}`);
    const generated = spawnSync(process.execPath, [helper, 'full-stack', '--output', review], { cwd: temp, encoding: 'utf8' });
    assert.equal(generated.status, 0, generated.stdout + generated.stderr);
    assert(fs.existsSync(path.join(review, 'full-stack.code-profile')));
    const forbidden = spawnSync(process.execPath, [helper, 'default', '--output', path.join(folder,'private-output')], { cwd: temp, encoding: 'utf8' });
    assert.equal(forbidden.status,1);
    assert(!fs.existsSync(path.join(folder,'private-output')));
    const shortcuts = require(path.join(folder, 'references/project/helpers/shortcuts/build.cjs'));
    assert.equal(shortcuts.catalogue(path.join(folder,'references/project')).recipes.length,5);
    const shortcutOutput=path.join(temp,`Shortcut review ${name}`);
    const shortcutPlan=shortcuts.plan(path.join(folder,'references/project'),'all',shortcutOutput);
    assert.equal(shortcutPlan.recipes.length,5);
    assert(!fs.existsSync(shortcutOutput));
    assert.throws(()=>shortcuts.plan(path.join(folder,'references/project'),'all',path.join(folder,'app-output')),/outside/);
    assert(!('sourceVersion' in JSON.parse(fs.readFileSync(path.join(folder, 'bundle.json'), 'utf8'))));
    const entry = fs.readFileSync(path.join(folder, 'SKILL.md'), 'utf8');
    assert(entry.startsWith(`---\nname: ${name}\n`));
    const starter=path.join(folder,'references/project/extensions/second-brain/obsidian/assets/vault/01 Dashboards/Development.base');
    assert.equal(fs.existsSync(starter),['day-one-mac','day-one-second-brain'].includes(name),'Starter asset scope');
    if(name==='day-one-second-brain' || name==='day-one-mac') {
      assert(fs.existsSync(path.join(folder,'references/project/config/second-brain/repositories.example.json')));
      const inspect=spawnSync(process.execPath,[path.join(folder,'references/project/helpers/second-brain/inspect.cjs'),'--help'],{cwd:temp,encoding:'utf8'});
      assert.equal(inspect.status,0,inspect.stderr);
      const misplaced=path.join(folder,'private-connections.json');
      fs.writeFileSync(misplaced,'{"schema":1,"repositories":[]}');
      const refused=spawnSync(process.execPath,[path.join(folder,'references/project/helpers/second-brain/inspect.cjs'),'--connections',misplaced],{cwd:temp,encoding:'utf8'});
      assert.equal(refused.status,1,'Private outputs must stay outside the entire installed skill');
      fs.unlinkSync(misplaced);
    }
    if (name === 'day-one-mac') {
      assert(fs.existsSync(path.join(folder, 'agents/openai.yaml')), 'Main package UI metadata must survive independent installation');
      for (const specialist of names.slice(1)) {
        assert(fs.existsSync(path.join(folder, 'references/workflows', `${specialist}.md`)));
      }
      assert(entry.includes('read-only'));
      assert(entry.includes('installed specialist'));
    }
  }
  const check = spawnSync(process.execPath, [path.join(root, 'tools/build-skills.cjs'), '--check'], { encoding: 'utf8' });
  assert.equal(check.status, 0, check.stdout + check.stderr);
  console.log(`PASS: ${names.length} independent packages, bundled workflows, contained references and generated-file consistency`);
 } finally { fs.rmSync(temp, { recursive: true, force: true }); }
}

module.exports = { validatePackage };
