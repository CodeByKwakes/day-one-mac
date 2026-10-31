#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const { TextDecoder } = require('node:util');
const limits = { configBytes: 65536, repositories: 32, paths: 64, files: 2000, fileBytes: 524288, totalBytes: 8388608 };
class Invalid extends Error { constructor(code, message) { super(message); this.code = code; } }
const fail = (code, message) => { throw new Invalid(code, message); };
const isObject = value => value && typeof value === 'object' && !Array.isArray(value);
const text = value => typeof value === 'string' && value.length > 0 && value.length <= 4096 && !/[\x00-\x1f\x7f]/.test(value);
const inside = (root, file) => file === root || file.startsWith(root + path.sep);
function keys(value, allowed) {
 if (!isObject(value) || Object.keys(value).some(key => !allowed.includes(key))) fail('schema', 'Unexpected fields or object type.');
}
function relative(value) {
 if (!text(value) || path.isAbsolute(value) || /[\\*?\[\]{}]/.test(value) || value.split('/').some(p => !p || p === '.' || p === '..')) fail('path', 'Use exact relative files or directories without traversal, globs or control characters.');
 return value;
}
function denied(name) {
 return name.split('/').some(part => /^(?:\.env(?:\..*)?|\.git|\.obsidian|\.trash|\.agents|\.claude|\.codex|\.aws|\.ssh|\.gnupg|\.config|\.vscode|\.idea|\.npm|\.npmrc|\.netrc|\.pypirc|node_modules|vendor|dist|build|coverage|\.next|\.nx|\.cache|secrets?|credentials?|tokens?|exports|backups|id_rsa|id_ed25519)$/i.test(part) || /\.(?:pem|key|p12|pfx|keystore|mobileprovision)$/i.test(part));
}
function rootDirectory(value) {
 if (!text(value) || !path.isAbsolute(value)) fail('path', 'Choose an existing absolute local directory.');
 const resolved = fs.realpathSync(value);
 if (resolved === path.parse(resolved).root || !fs.statSync(resolved).isDirectory()) fail('path', 'Choose a specific directory.');
 return resolved;
}
function contained(root, name, mayBeMissing = false) {
 relative(name);
 let file = root;
 for (const part of name.split('/')) {
  file = path.join(file, part);
  try {
   const stat = fs.lstatSync(file);
   if (stat.isSymbolicLink()) fail('symlink', 'A selected path contains a symbolic link. Select its intended regular target explicitly.');
   if (!inside(root, fs.realpathSync(file))) fail('escape', 'A path leaves its selected root.');
  } catch (error) {
   if (mayBeMissing && error.code === 'ENOENT') continue;
   throw error;
  }
 }
 return file;
}
function git(root, args) {
 const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith('GIT_')));
 Object.assign(env, { GIT_CONFIG_NOSYSTEM:'1', GIT_CONFIG_GLOBAL:'/dev/null', GIT_OPTIONAL_LOCKS:'0', GIT_TERMINAL_PROMPT:'0', GIT_ALLOW_PROTOCOL:'', GIT_NO_LAZY_FETCH:'1', LC_ALL:'C' });
 const result = spawnSync('git', ['--no-pager','--no-lazy-fetch','--no-replace-objects','--literal-pathspecs','-C',root,
  '-c','core.fsmonitor=false','-c','core.untrackedCache=false','-c','core.hooksPath=/dev/null',
  ...args], {env, encoding:'utf8', timeout:15000, maxBuffer:4194304});
 if (result.error || result.status !== 0) fail('git', 'Git could not inspect local metadata. Check --no-lazy-fetch support, permissions and locally available objects; no automatic fetch is allowed.');
 return result.stdout;
}
function load(file) {
 const stat = fs.lstatSync(file);
 if (!stat.isFile() || stat.isSymbolicLink() || stat.size > limits.configBytes) fail('config', 'Select a regular connection JSON file no larger than 64 KiB.');
 const real = fs.realpathSync(file);
 const projectRoot = path.resolve(__dirname, '../..');
 const packageRoot = path.basename(projectRoot) === 'project' && path.basename(path.dirname(projectRoot)) === 'references'
  ? path.resolve(projectRoot, '../..') : projectRoot;
 if (inside(packageRoot, real)) fail('private-location', 'Keep private connections outside the source or installed skill package.');
 let data;
 try { data = JSON.parse(fs.readFileSync(real, 'utf8')); } catch { fail('config', 'The connection file must contain valid JSON.'); }
 keys(data, ['schema','vault','repositories']);
 if (data.schema !== 1 || !Array.isArray(data.repositories) || data.repositories.length > limits.repositories) fail('schema', 'Expected schema 1 and at most 32 repository records.');
 const ids = new Set();
 for (const record of data.repositories) {
  keys(record, ['id','checkout','projectNote','projectPage','readPaths','aiAccess']);
  if (typeof record.id !== 'string' || !/^[a-z][a-z0-9-]{0,63}$/.test(record.id) || ids.has(record.id)) fail('id', 'Repository IDs must be unique lowercase names.');
  ids.add(record.id);
  if (!text(record.checkout) || !path.isAbsolute(record.checkout)) fail('path', 'Each checkout must be an absolute local path.');
  if ((record.projectNote !== undefined) === (record.projectPage !== undefined)) fail('destination', 'Select exactly one projectNote or projectPage.');
  if (record.projectNote !== undefined) {
   relative(record.projectNote);
   if (denied(record.projectNote) || !record.projectNote.endsWith('.md') || !text(data.vault)) fail('destination', 'A project note needs a Markdown path and an explicit vault.');
  } else {
   let url;
   try { url = new URL(record.projectPage); } catch { fail('destination', 'Use an approved Notion HTTPS page reference.'); }
   if (url.protocol !== 'https:' || url.username || url.password || url.search || !/^(?:www\.)?notion\.so$|^(?:[a-z0-9-]+\.)?notion\.site$/.test(url.hostname)) fail('destination', 'Use a Notion page link without credentials or query parameters.');
  }
  record.aiAccess ??= 'link-only';
  if (!['link-only','selected-files'].includes(record.aiAccess) || !Array.isArray(record.readPaths) || record.readPaths.length > limits.paths) fail('schema', 'Use link-only or selected-files with at most 64 readPaths.');
  if ((record.aiAccess === 'link-only' && record.readPaths.length) || (record.aiAccess === 'selected-files' && !record.readPaths.length)) fail('scope', 'Link-only needs an empty readPaths list; selected-files needs explicit paths.');
  for (const selected of record.readPaths) {
   relative(selected);
   if (denied(selected)) fail('forbidden', 'A selected path is excluded from knowledge inspection.');
  }
 }
 return {data, real};
}
function readText(root, name, mode, objectHash) {
 if (!['100644','100755'].includes(mode)) return { reason: mode === '160000' ? 'submodule' : 'non-regular' };
 if (denied(name)) return { reason:'excluded' };
 const extension = path.posix.extname(name).toLowerCase();
 const known = /\.(md|mdx|txt|json|yaml|yml|toml|ts|tsx|js|jsx|cjs|mjs|html|css|scss|sass|less|prisma|sql|graphql|gql|sh|bash|zsh|py|rb|go|rs|java|kt|swift|c|h|cpp|cs|xml|csv|ini|conf)$/;
 if (!known.test(extension) && !/^(Dockerfile|Containerfile|Makefile|LICENSE|\.gitignore|\.editorconfig)$/i.test(path.basename(name))) return {reason:'unsupported-file-type'};
 const full = contained(root,name);
 const before = fs.lstatSync(full);
 if (!before.isFile()) return {reason:'non-regular'};
 if (before.size > limits.fileBytes) return {reason:'over-512-KiB'};
 const fd = fs.openSync(full, fs.constants.O_RDONLY | fs.constants.O_NOFOLLOW | fs.constants.O_NONBLOCK);
 try {
  const opened = fs.fstatSync(fd);
  if (!opened.isFile() || opened.dev !== before.dev || opened.ino !== before.ino || opened.size > limits.fileBytes) fail('drift','A selected file changed during inspection. Retry when edits stop.');
  contained(root,name);
  const bytes = Buffer.alloc(limits.fileBytes + 1);
  let length = 0, got;
  do { got = fs.readSync(fd,bytes,length,bytes.length-length,null); length += got; } while(got && length < bytes.length);
  const after = fs.fstatSync(fd);
  const current = fs.lstatSync(contained(root,name));
  if (length > limits.fileBytes || opened.size !== after.size || opened.mtimeMs !== after.mtimeMs || opened.ctimeMs !== after.ctimeMs || current.ino !== after.ino || current.dev !== after.dev) fail('drift','A selected file changed during inspection. Retry when edits stop.');
  const body = bytes.subarray(0,length);
  if (body.includes(0)) return {reason:'binary'};
  try { new TextDecoder('utf-8',{fatal:true}).decode(body); } catch { return {reason:'non-UTF8'}; }
  return {
   path:name, bytes:length, sha256:crypto.createHash('sha256').update(body).digest('hex'),
   objectId:crypto.createHash(objectHash).update(`blob ${length}\0`).update(body).digest('hex'),
   fileMode:(after.mode & 0o111) ? '100755' : '100644'
  };
 } finally { fs.closeSync(fd); }
}
function inspectRecord(record, vault, configPath) {
 const result = {id:record.id, aiAccess:record.aiAccess, checkout:null, revision:null, workingTree:'not-inspected', files:[], skipped:[], findings:[]};
 try {
  const checkout = rootDirectory(record.checkout); result.checkout=checkout;
  if (inside(checkout,configPath) || (vault && (inside(vault,checkout) || inside(checkout,vault)))) fail('overlap','Keep the vault, checkout and private connection file separate.');
  if (fs.realpathSync(git(checkout,['rev-parse','--show-toplevel']).replace(/\r?\n$/, '')) !== checkout) fail('root','Select the checkout root, not a subdirectory.');
  if (record.projectNote) {
   const note = contained(vault,record.projectNote,true);
   if (fs.existsSync(note) && !fs.statSync(note).isFile()) fail('destination','The project note path is not a regular file.');
   result.projectNote=record.projectNote;
  } else result.projectPage=record.projectPage;
  if (record.aiAccess === 'link-only') return result;
  for (const selected of record.readPaths) contained(checkout,selected);
  result.revision=git(checkout,['rev-parse','--verify','HEAD']).trim();
  if(!/^(?:[a-f0-9]{40}|[a-f0-9]{64})$/.test(result.revision)) fail('git','Unsupported Git object format.');
  const objectHash=result.revision.length===40?'sha1':'sha256';
  const listing=git(checkout,['ls-files','--stage','-z','--',...record.readPaths]);
  const entries=listing.split('\0').filter(Boolean);
  if(entries.length > limits.files) fail('limit','Select fewer files: the limit is 2000 tracked entries.');
  const tree=git(checkout,['ls-tree','-r','-z','--full-tree',result.revision,'--',...record.readPaths]).split('\0').filter(Boolean);
  if(tree.length > limits.files) fail('limit','Select fewer files: the limit is 2000 committed entries.');
  const inScope=name=>record.readPaths.some(selected=>name===selected || name.startsWith(selected+'/'));
  const committed=new Map();
  for(const entry of tree) {
   const match=/^(\d{6}) (?:blob|commit) ([a-f0-9]+)\t([\s\S]+)$/.exec(entry);
   if(!match) fail('git','Unexpected committed metadata.');
   const [,mode,objectId,name]=match;relative(name);
   if(!inScope(name)) fail('escape','Git returned a file outside selected paths.');
   committed.set(name,{mode,objectId});
  }
  const seen=new Set();let total=0,dirty=false;
  for (const entry of entries) {
   const match=/^(\d{6}) ([a-f0-9]+) (\d)\t([\s\S]+)$/.exec(entry);
   if(!match || match[3] !== '0') fail('conflict','Resolve the selected Git conflict before inspecting it.');
   const [,mode,indexObject,,name]=match;
   relative(name);
   if(!inScope(name)) fail('escape','Git returned a file outside selected paths.');
   if(seen.has(name)) continue;seen.add(name);
   let read;
   try { read=readText(checkout,name,mode,objectHash); } catch(error) {
    if(error.code==='ENOENT') {dirty=true;result.skipped.push({path:name,reason:'missing'});continue;}
    throw error;
   }
   if(read.reason) result.skipped.push({path:name,reason:read.reason});
   else {
    const head=committed.get(name);
    if(!head || head.objectId!==indexObject || head.mode!==mode || read.objectId!==indexObject || read.fileMode!==mode) dirty=true;
    total+=read.bytes;if(total>limits.totalBytes) fail('limit','Select fewer files: the text limit is 8 MiB.');
    result.files.push({path:read.path,bytes:read.bytes,sha256:read.sha256});
   }
  }
  if(!result.files.length) fail('empty','No eligible tracked text files. Choose a smaller, reviewed text selection.');
  for(const [name,head] of committed) {
   if(!seen.has(name) && ['100644','100755'].includes(head.mode) && !denied(name)) {
    dirty=true;result.skipped.push({path:name,reason:'removed-from-index'});
   }
  }
  if(git(checkout,['ls-files','--stage','-z','--',...record.readPaths])!==listing) fail('drift','The selected index changed. Run the check again.');
  if(git(checkout,['rev-parse','--verify','HEAD']).trim() !== result.revision) fail('drift','The checkout revision changed. Run the check again.');
  result.files.sort((a,b)=>a.path < b.path ? -1 : a.path > b.path ? 1 : 0);
  result.workingTree=dirty?'selected-files-changed':'selected-files-clean';
 } catch(error) {
  result.files=[];
  result.findings.push({code:error instanceof Invalid?error.code:'unavailable', message:error instanceof Invalid?error.message:'A selected path is missing, unreadable or unavailable.'});
 }
 return result;
}
function inspect(file, selectedId) {
 try {
  const {data,real}=load(file);
  const selected=selectedId?data.repositories.filter(r=>r.id===selectedId):data.repositories;
  if(selectedId && !selected.length) fail('id','The selected repository ID is not registered.');
  const vault=data.vault===undefined?null:rootDirectory(data.vault);
  if(vault && inside(vault,real)) fail('private-location','Store the connection file outside the vault.');
  const repositories=selected.map(record=>inspectRecord(record,vault,real));
  return {schema:1,ok:repositories.every(r=>!r.findings.length),repositories,findings:[]};
 } catch(error) {
  return {schema:1,ok:false,repositories:[],findings:[{code:error instanceof Invalid?error.code:'unavailable',message:error instanceof Invalid?error.message:'The selected connection file or vault is missing or unreadable.'}]};
 }
}
function main(args) {
 if(args.length===1 && ['--help','-h'].includes(args[0])) {console.log('Usage: node inspect.cjs --connections FILE [--repo ID]\nRead-only local check. Outputs metadata and hashes, never file bodies. No network or writes.');return 0;}
 let file,id;
 for(let i=0;i<args.length;i+=2) {
  if(!args[i+1] || args[i+1].startsWith('--')) return 2;
  if(args[i]==='--connections' && file===undefined) file=args[i+1];
  else if(args[i]==='--repo' && id===undefined) id=args[i+1];
  else return 2;
 }
 if(!file) return 2;
 const result=inspect(file,id);console.log(JSON.stringify(result,null,2));return result.ok?0:1;
}
if(require.main===module) {process.exitCode=main(process.argv.slice(2));if(process.exitCode===2)console.error('Usage: node inspect.cjs --connections FILE [--repo ID]');}
module.exports={inspect,limits};
