#!/usr/bin/env node
'use strict';
// Standalone, on-demand display restore. Presets are data, never shell code.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const digest = value => crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');
const namePattern = /^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$/;
const uuid = /^[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}$/;
function checkName(name) {
  if (typeof name!=='string' || !namePattern.test(name)) throw Error('Use a name containing 1-64 letters, digits, hyphens or underscores.');
}
function validateArgs(args) {
  if (!Array.isArray(args) || args.length < 1 || args.length > 8) throw Error('Expected 1-8 enabled, separate displays.');
  const rules = {
    id: uuid, res: /^[1-9]\d{1,4}x[1-9]\d{1,4}$/, hz: /^\d{1,3}(?:\.\d{1,3})?$/,
    color_depth: /^(4|8|10|12|16|24|30|32|64)$/, enabled: /^true$/, scaling: /^(on|off)$/,
    origin: /^\(-?\d{1,6},-?\d{1,6}\)$/, degree: /^(0|90|180|270)$/
  };
  const result = args.map(arg => {
    if (typeof arg !== 'string') throw Error('Invalid display argument.');
    const values = {};
    for (const item of arg.split(' ')) {
      const at = item.indexOf(':'); const key = item.slice(0,at); const value = item.slice(at+1);
      if (!rules[key] || !rules[key].test(value) || Object.hasOwn(values,key)) throw Error('Unsupported display argument; recalibrate manually.');
      values[key] = key === 'id' ? value.toUpperCase() : value;
    }
    for (const key of ['id','res','hz','color_depth','scaling','origin','degree']) {
      if (!Object.hasOwn(values,key)) throw Error(`Missing display field: ${key}`);
    }
    if (Number(values.hz) <= 0) throw Error('Invalid refresh rate.');
    delete values.enabled; // Enabled is implicit; disabling and mirroring are unsupported.
    return Object.entries(values).sort(([a],[b])=>a.localeCompare(b)).map(([k,v])=>`${k}:${v}`).join(' ');
  }).sort();
  const ids = result.map(a => a.match(/(?:^| )id:([^ ]+)/)[1]);
  if (new Set(ids).size !== ids.length) throw Error('Duplicate display identities; use manual arrangement.');
  return result;
}
const ids = args => args.map(a=>a.match(/(?:^| )id:([^ ]+)/)[1]).sort();
function parse(output) {
  const lines = output.split(/\r?\n/).filter(s=>s.startsWith('displayplacer '));
  if (lines.length !== 1) throw Error('Unsupported displayplacer list output: expected one restore command.');
  const tail = lines[0].slice('displayplacer '.length);
  if (!/^"[^"\r\n]+"(?: +"[^"\r\n]+")* *$/.test(tail)) throw Error('Unsupported displayplacer command quoting.');
  const args = validateArgs([...tail.matchAll(/"([^"\r\n]+)"/g)].map(m=>m[1]));
  const reported = [...output.matchAll(/^Persistent screen id: ([^\r\n]+)$/gm)].map(m=>m[1].trim().toUpperCase()).sort();
  if (JSON.stringify(ids(args)) !== JSON.stringify(reported)) throw Error('Missing, duplicate or mismatched persistent display identities.');
  return args;
}
function stable(list, sleep) {
  let previous=''; let consecutive=0;
  for (let i=0;i<12;i++) {
    const args=parse(list()); const key=JSON.stringify(args);
    consecutive=key===previous ? consecutive+1 : 1; previous=key;
    if (consecutive===3) return args;
    sleep(1000);
  }
  throw Error('Displays did not become stable; wait for DisplayLink and retry.');
}
function noSymlinks(location) {
  // Permit macOS's system /tmp and /var aliases, but no user-controlled symlink.
  for (let p=path.resolve(location);p!==path.dirname(p);p=path.dirname(p)) {
    if (!fs.existsSync(p) && !fs.lstatSync(p,{throwIfNoEntry:false})) continue;
    const st=fs.lstatSync(p);
    if (st.isSymbolicLink() && !['/tmp','/var'].includes(p)) throw Error(`Symlink path refused: ${p}`);
  }
}
function privatePath(location, directory=false) {
  noSymlinks(location);
  const st=fs.lstatSync(location);
  if ((directory ? !st.isDirectory() : !st.isFile()) || (st.mode & 0o077) || st.uid!==process.getuid()) throw Error(`Expected an owned private ${directory?'directory':'file'}: ${location}`);
}
function ensureDirectory(directory) {
  noSymlinks(directory);
  if (!fs.existsSync(directory)) fs.mkdirSync(directory,{recursive:true,mode:0o700});
  privatePath(directory,true);
}
function locked(directory, action) {
  ensureDirectory(directory);
  const lock=path.join(directory,'.lock');
  try {fs.mkdirSync(lock,{mode:0o700});} catch {throw Error('Workspace directory is locked; inspect any interrupted operation before removing .lock.');}
  try {return action();} finally {fs.rmdirSync(lock);}
}
function writeNew(file, data) {
  // Publish complete data exclusively; never overwrite an existing target.
  const temporary=file+'.'+crypto.randomUUID()+'.tmp';
  const fd=fs.openSync(temporary,'wx',0o600);
  try {
    try {fs.writeFileSync(fd,JSON.stringify(data,null,2)+'\n');fs.fsyncSync(fd);} finally {fs.closeSync(fd);}
    fs.linkSync(temporary,file);
  } finally {fs.unlinkSync(temporary);}
}
function validatePreset(preset, recovery=false) {
  if (!preset || preset.schema!==1 || typeof preset.name!=='string') throw Error('Unsupported workspace preset.');
  checkName(preset.name);
  if (!(recovery && preset.layout===null)) checkName(preset.layout);
  const args=validateArgs(preset.args);
  if (typeof preset.builtin!=='string' || !ids(args).includes(preset.builtin)) throw Error('Select the built-in display explicitly during calibration.');
  return {schema:1,name:preset.name,layout:preset.layout,builtin:preset.builtin,args};
}
function load(directory, selector) {
  privatePath(directory,true);
  let file; let recovery=false;
  if (selector.startsWith('recovery:')) {
    const id=selector.slice(9); if (!uuid.test(id)) throw Error('Invalid recovery ID.');
    privatePath(path.join(directory,'recovery'),true);
    file=path.join(directory,'recovery',id+'.json');recovery=true;
  } else {checkName(selector);file=path.join(directory,selector+'.json');}
  privatePath(file);
  return validatePreset(JSON.parse(fs.readFileSync(file,'utf8')),recovery);
}
function topology(current,preset) {
  if (JSON.stringify(ids(current))!==JSON.stringify(ids(preset.args)) || !ids(current).includes(preset.builtin)) throw Error('Display topology differs from calibration; no layout was requested.');
}
function capture(directory,name,layout,builtin,services) {
  checkName(name);checkName(layout);
  return locked(directory,()=>{
    const file=path.join(directory,name+'.json');
    if (fs.existsSync(file)) throw Error('Preset exists; capture under a new name and preserve the previous copy.');
    const preset=validatePreset({schema:1,name,layout,builtin:builtin.toUpperCase(),args:stable(services.list,services.sleep)});
    writeNew(file,preset);return preset;
  });
}
function preview(directory,selector,services) {
  const preset=load(directory,selector);const current=stable(services.list,services.sleep);
  topology(current,preset);
  return {preset,current,token:digest({preset,current})};
}
function detect(directory,services) {
  privatePath(directory,true);const current=stable(services.list,services.sleep);
  const matches=fs.readdirSync(directory).filter(f=>f.endsWith('.json')).map(f=>f.slice(0,-5)).filter(name=>{
    const p=load(directory,name); return JSON.stringify(ids(current))===JSON.stringify(ids(p.args));
  });
  if (!matches.length) throw Error('No matching topology; calibrate this desk first.');
  if (matches.length>1) throw Error('Multiple activities match; select a preset by name.');
  return matches[0];
}
function apply(directory,selector,token,services) {
  return locked(directory,()=>{
    const approved=preview(directory,selector,services);
    if (!token || approved.token!==token) throw Error('Preset or displays changed since preview; review a new preview.');
    const {preset,current}=approved;
    const recovery=path.join(directory,'recovery');ensureDirectory(recovery);
    const file=path.join(recovery,crypto.randomUUID()+'.json');
    writeNew(file,{schema:1,name:'Recovery',layout:null,builtin:preset.builtin,args:current});
    try {
      services.place(preset.args);
      const actual=stable(services.list,services.sleep);topology(actual,preset);
      if (JSON.stringify(actual)!==JSON.stringify(preset.args)) throw Error('Display restore did not match. Window layout was not requested.');
      if (preset.layout!==null) services.open('raycast://customWindowManagementCommand?name='+encodeURIComponent(preset.layout));
      return file;
    } catch(error) {
      throw Error(`${error.message} Recovery data: ${file}. Inspect displays before retrying; no automatic rollback was attempted.`);
    }
  });
}
function run(executable,args) {
  const result=cp.spawnSync(executable,args,{encoding:'utf8',timeout:30000,maxBuffer:1024*1024,shell:false});
  if (result.error || result.status!==0) throw Error(`${executable} failed: ${result.error?.message || result.stderr?.trim() || result.status}`);
  return result.stdout;
}
const services={
  list:()=>run('displayplacer',['list']), place:args=>run('displayplacer',args),
  open:url=>run('/usr/bin/open',[url]), sleep:ms=>Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,ms)
};
const help=`Usage: node workspace.cjs COMMAND [arguments]
  inspect                              Read stable display arguments; no writes
  capture NAME LAYOUT BUILTIN_UUID      Save current calibration; never overwrite
  detect                               Print the sole matching preset, or stop
  preview NAME|recovery:UUID            Read-only JSON plan and approval token
  apply NAME|recovery:UUID TOKEN        Verify token, back up, restore, request layout
  run NAME|auto                        Preview, macOS confirmation, apply
Set DAY_ONE_WORKSPACE_DIR to a private directory (default ~/.config/workspace-layouts).
Requires Node.js 22.20+, displayplacer and Raycast Pro for named layouts.
No daemon, window closing, app launching by this tool, or automatic rollback.
Raycast may launch applications configured in its selected layout.
`;
function main(argv) {
  const [command,...args]=argv;
  if (!command || command==='--help') {process.stdout.write(help);return;}
  const counts={inspect:0,capture:3,detect:0,preview:1,apply:2,run:1};
  if (!(command in counts) || args.length!==counts[command]) throw Error(help);
  if (process.platform!=='darwin') throw Error('Live workspace operations require macOS.');
  const directory=path.resolve(process.env.DAY_ONE_WORKSPACE_DIR || path.join(os.homedir(),'.config/workspace-layouts'));
  if (command==='inspect') return console.log(JSON.stringify(stable(services.list,services.sleep),null,2));
  if (command==='capture') return console.log(JSON.stringify(capture(directory,...args,services),null,2));
  if (command==='detect') return console.log(detect(directory,services));
  if (command==='preview') return console.log(JSON.stringify(preview(directory,args[0],services),null,2));
  let selector=args[0]; let token=args[1];
  if (command==='run') {
    if (selector==='auto') selector=detect(directory,services);
    const plan=preview(directory,selector,services);token=plan.token;
    const message=`Restore ${selector}?\n\n${plan.preset.args.join('\n')}\n\nRaycast layout: ${plan.preset.layout}\nOther Windows must be set to None. Verify the target VS Code window first.\nA private display recovery file will be saved.`;
    run('/usr/bin/osascript',['-e','on run argv\n display dialog (item 1 of argv) buttons {"Cancel", "Restore"} default button "Cancel" cancel button "Cancel"\nend run',message]);
  }
  const file=apply(directory,selector,token,services);
  console.log(`Display configuration verified. Recovery: ${file}`);
  console.log(selector.startsWith('recovery:') ? 'Display-only recovery completed; verify windows manually.' : 'Raycast layout requested; verify app placement and the VS Code project manually.');
}
module.exports={parse,validateArgs,stable,capture,preview,detect,apply};
if (require.main===module) {try {main(process.argv.slice(2));} catch(error) {console.error(error.message);process.exitCode=1;}}
