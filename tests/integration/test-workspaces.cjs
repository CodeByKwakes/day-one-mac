'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const w = require('../../helpers/workspaces/workspace.cjs');
const first = 'AAAAAAAA-BBBB-CCCC-DDDD-000000000001';
const second = 'AAAAAAAA-BBBB-CCCC-DDDD-000000000002';
const arg = (id, x=0) => `id:${id} res:1920x1080 hz:60 color_depth:8 enabled:true scaling:off origin:(${x},0) degree:0`;
const listing = args => args.map(a => `Persistent screen id: ${a.match(/(?:^| )id:([^ ]+)/)[1]}\nType: fixture`).join('\n') + '\nExecute the command below:\ndisplayplacer ' + args.map(a => `"${a}"`).join(' ') + '\n';
const original = listing([arg(first),arg(second,1920)]);
assert.equal(w.parse(original).length,2);
for (const bad of [original.replace('enabled:true','enabled:false'),original.replace('degree:0','degree:0;touch /tmp/no'),original.replace(second,first),original.replace('hz:60','hz:$(id)'),original.replace('res:1920x1080','mode:23')]) {
  assert.throws(()=>w.parse(bad));
}
let reads=0;
const stable=w.stable(()=>{reads++;return reads===1 ? listing([arg(first)]) : original;},()=>{});
assert.equal(stable.length,2); assert.equal(reads,4);
assert.throws(()=>w.stable(()=>reads++%2 ? original : listing([arg(first)]),()=>{}),/stable/);
const root = fs.mkdtempSync(path.join(os.tmpdir(),'workspace fixtures ü '));
let current=original; const calls=[];
const services={list:()=>current, sleep:()=>{}, place:args=>{calls.push(['place',args]);current=listing(args);}, open:url=>calls.push(['open',url])};
try {
  const config=path.join(root,'private');
  const saved=w.capture(config,'Office-Code','Office-Code',first,services);
  assert.equal(fs.statSync(config).mode & 0o777,0o700);
  assert.equal(fs.statSync(path.join(config,'Office-Code.json')).mode & 0o777,0o600);
  assert.throws(()=>w.capture(config,'Office-Code','Office-Code',first,services),/exists/);
  assert.throws(()=>w.capture(config,'../escape','x',first,services));
  assert.throws(()=>w.capture(config,'Bad','x',second+'BAD',services),/built-in/);
  for (const layout of [null,undefined,1,{}]) {
    fs.writeFileSync(path.join(config,'Office-Code.json'),JSON.stringify({...saved,layout}));
    assert.throws(()=>w.preview(config,'Office-Code',services),/name/);
  }
  fs.writeFileSync(path.join(config,'Office-Code.json'),JSON.stringify(saved));
  const plan=w.preview(config,'Office-Code',services);
  assert.equal(calls.length,0);
  assert.equal(w.detect(config,services),'Office-Code');
  w.capture(config,'Office-Data','Office-Data',first,services);
  assert.throws(()=>w.detect(config,services),/Multiple/);
  fs.unlinkSync(path.join(config,'Office-Data.json'));
  current=listing([arg(first)]);
  assert.throws(()=>w.apply(config,'Office-Code',plan.token,services),/topology/);
  assert.equal(calls.length,0);
  current=original;
  fs.writeFileSync(path.join(config,'Office-Code.json'),JSON.stringify({...saved,layout:'Changed'}),{mode:0o600});
  assert.throws(()=>w.apply(config,'Office-Code',plan.token,services),/changed/);
  fs.writeFileSync(path.join(config,'Office-Code.json'),JSON.stringify(saved),{mode:0o600});
  const approved=w.preview(config,'Office-Code',services);
  const backup=w.apply(config,'Office-Code',approved.token,services);
  assert.equal(calls.filter(c=>c[0]==='open').length,1);
  assert.ok(fs.existsSync(backup));
  assert.equal(fs.statSync(backup).mode & 0o777,0o600);
  w.apply(config,'Office-Code',w.preview(config,'Office-Code',services).token,services);
  assert.equal(fs.readdirSync(path.join(config,'recovery')).length,2);
  const recoverySelector='recovery:'+path.basename(backup,'.json');
  current=listing([arg(first),arg(second,2500)]);
  const recoveryPlan=w.preview(config,recoverySelector,services);
  w.apply(config,recoverySelector,recoveryPlan.token,services);
  assert.deepEqual(w.parse(current),w.parse(original));
  assert.equal(calls.filter(c=>c[0]==='open').length,2,'Recovery never requests a Raycast layout');
  assert.equal(fs.readdirSync(path.join(config,'recovery')).length,3);

  fs.mkdirSync(path.join(config,'.lock'));
  assert.throws(()=>w.apply(config,'Office-Code',approved.token,services),/locked/);
  fs.rmdirSync(path.join(config,'.lock'));
  const before=calls.length;
  assert.throws(()=>w.apply(config,'Office-Code',approved.token,{...services,place:()=>{throw Error('interrupted');}}),/interrupted.*Recovery data:/);
  assert.equal(calls.length,before); assert.ok(!fs.existsSync(path.join(config,'.lock')));
  assert.throws(()=>w.apply(config,'Office-Code',approved.token,{...services,place:()=>{current=listing([arg(first)]);}}),/topology/);
  assert.equal(calls.filter(c=>c[0]==='open').length,2);
  current=original;
  assert.throws(()=>w.apply(config,'Office-Code',w.preview(config,'Office-Code',services).token,{...services,open:()=>{throw Error('Raycast unavailable');}}),/Raycast unavailable.*Recovery data:/);
  const linked=path.join(root,'linked');fs.symlinkSync(config,linked);
  assert.throws(()=>w.preview(linked,'Office-Code',services),/Symlink/);
  fs.chmodSync(path.join(config,'Office-Code.json'),0o644);
  assert.throws(()=>w.preview(config,'Office-Code',services),/private/);
  console.log('PASS: workspace parsing, delayed/missing/duplicate displays, explicit selection, preview drift, recovery, repeat runs, failures, locks and private paths (fixtures only)');
} finally {fs.rmSync(root,{recursive:true,force:true});}
