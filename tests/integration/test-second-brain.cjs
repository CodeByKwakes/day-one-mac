#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const cli = path.join(root, 'helpers/second-brain/inspect.cjs');
const temp = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'brain é ')));
const repo = path.join(temp, 'Sample API é'), vault = path.join(temp, 'Private Vault');
const config = path.join(temp, 'connections.json');
const env = { ...process.env, GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_NOSYSTEM: '1' };
function git(args, cwd = repo) {
 const r = spawnSync('git', ['-c','core.hooksPath=/dev/null','-c','commit.gpgsign=false',...args], { cwd, env, encoding:'utf8' });
 assert.equal(r.status, 0, r.stderr); return r.stdout.trim();
}
function write(file, value) { fs.mkdirSync(path.dirname(file), {recursive:true}); fs.writeFileSync(file,value); }
function snapshot(dir) {
 const out = {};
 function walk(d) { for (const ent of fs.readdirSync(d,{withFileTypes:true})) {
  const file = path.join(d, ent.name), rel = path.relative(dir,file);
  if(ent.isSymbolicLink()) out[rel]='link:'+fs.readlinkSync(file);
  else if(ent.isDirectory()) walk(file);
  else out[rel]=crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
 } } walk(dir); return out;
}
let record;
function run(data, expected=0, args=[], extraEnv={}) {
 fs.writeFileSync(config,JSON.stringify(data));
 const before=snapshot(temp);
 const r=spawnSync(process.execPath,[cli,'--connections',config,...args],{encoding:'utf8',env:{...env,...extraEnv}});
 assert.equal(r.status,expected,r.stdout+r.stderr);
 assert.deepEqual(snapshot(temp),before,'Inspection mutated fixtures or Git metadata');
 const report=JSON.parse(r.stdout);
 assert(!r.stdout.includes('DO_NOT_DISCLOSE_TEST_VALUE'),'Leaked a fixture body');
 return report;
}
try {
 fs.mkdirSync(repo);fs.mkdirSync(vault);
 git(['init','-q']);git(['config','user.email','fixture@example.test']);git(['config','user.name','Fixture']);
 write(path.join(repo,'README.md'),'# Service\n');
 write(path.join(repo,'docs/architecture/Overview.md'),'# Overview\n');
 write(path.join(repo,'docs/architecture/.env'),'DO_NOT_DISCLOSE_TEST_VALUE');
 write(path.join(repo,'docs/architecture/node_modules/private.md'),'DO_NOT_DISCLOSE_TEST_VALUE');
 write(path.join(repo,'docs/architecture/binary.md'),Buffer.from([0,255,1]));
 write(path.join(repo,'docs/architecture/large.md'),'x'.repeat(524289));
 write(path.join(repo,'notes.md'),'DO_NOT_DISCLOSE_TEST_VALUE');
 git(['add','.']);git(['commit','-qm','fixture']);
 record={schema:1,vault,repositories:[{id:'sample-api',checkout:repo,projectNote:'Projects/Sample.md',readPaths:['README.md','docs/architecture'],aiAccess:'selected-files'}]};
 let result=run(record);let checked=result.repositories[0];
 assert.equal(checked.workingTree,'selected-files-clean');
 assert.equal(checked.revision,git(['rev-parse','HEAD']));
 assert.deepEqual(checked.files.map(f=>f.path),['README.md','docs/architecture/Overview.md']);
 assert(checked.files.every(f=>/^[a-f0-9]{64}$/.test(f.sha256)));
 assert.equal(checked.skipped.length,4);
 write(path.join(repo,'README.md'),'# Local edit\n');
 result=run(record);assert.equal(result.repositories[0].workingTree,'selected-files-changed');
 assert.notEqual(result.repositories[0].files.find(f=>f.path==='README.md').sha256,checked.files.find(f=>f.path==='README.md').sha256);
 // A tracked file changed back to HEAD but still staged is also local evidence.
 git(['add','README.md']);write(path.join(repo,'README.md'),'# Service\n');
 assert.equal(run(record).repositories[0].workingTree,'selected-files-changed');
 // Inherited Git location/config variables must not redirect the check.
 assert.equal(run(record,0,[],{GIT_DIR:'/missing',GIT_WORK_TREE:'/missing'}).repositories[0].checkout,repo);
 const change=(values)=>({...record,repositories:[{...record.repositories[0],...values}]});
 assert.equal(run(change({aiAccess:'link-only',readPaths:[]})).repositories[0].files.length,0);
 assert.equal(run(change({aiAccess:undefined,readPaths:[]})).repositories[0].aiAccess,'link-only');
 run({...record,repositories:[record.repositories[0],record.repositories[0]]},1);
 for (const readPaths of [['../notes.md'],['.git/config'],['docs/architecture/.env'],['*'],['missing.md'],['notes.md\nother']]) run(change({readPaths}),1);
 run(change({readPaths:['README.md'],aiAccess:'link-only'}),1);
 run(change({checkout:path.join(repo,'docs')}),1);
 run({...record,vault:repo},1);
 run(change({projectNote:'../escape.md'}),1);
 run(change({projectNote:'Secrets/.env'}),1);
 run(change({projectPage:'https://www.notion.so/example'}),1);
 run({...record,unknown:true},1);
 const remoteOnly={schema:1,repositories:[{...record.repositories[0],projectNote:undefined,projectPage:'https://www.notion.so/example'}]};
 run(remoteOnly);run({...remoteOnly,repositories:[{...remoteOnly.repositories[0],projectPage:'https://user:secret@www.notion.so/example'}]},1);
 run(record,1,['--repo','absent']);
 assert.deepEqual(run({...record,repositories:[]}).repositories,[],'Disconnect leaves data intact');
 run({...record,repositories:[record.repositories[0],{...record.repositories[0],id:'offline',checkout:'/missing'}]},0,['--repo','sample-api']);
 const outside=path.join(temp,'Outside');fs.mkdirSync(outside);write(path.join(outside,'private.md'),'DO_NOT_DISCLOSE_TEST_VALUE');
 fs.symlinkSync(outside,path.join(repo,'docs/escape'));
 run(change({readPaths:['docs/escape/private.md']}),1);
 fs.symlinkSync(path.join(outside,'private.md'),path.join(repo,'docs/architecture/shortcut.md'));
 git(['add','docs/architecture/shortcut.md']);
 result=run(record);assert(!result.repositories[0].files.some(f=>f.path.endsWith('shortcut.md')));
 fs.mkdirSync(path.join(repo,'docs/architecture/external'));
 write(path.join(repo,'docs/architecture/external/private.md'),'DO_NOT_DISCLOSE_TEST_VALUE');
 git(['update-index','--add','--cacheinfo',`160000,${git(['rev-parse','HEAD'])},docs/architecture/external`]);
 assert(run(record).repositories[0].skipped.some(f=>f.reason==='submodule'));
 fs.symlinkSync(outside,path.join(vault,'Projects'));run(record,1);fs.unlinkSync(path.join(vault,'Projects'));
 const worktree=path.join(temp,'Worktree é');git(['worktree','add','-qb','fixture-worktree',worktree]);
 run(change({checkout:worktree}));
 const moved=path.join(temp,'Moved API');fs.renameSync(repo,moved);run(record,1);
 run(change({checkout:moved}));fs.renameSync(moved,repo);
 const spaced=path.join(temp,'Checkout with trailing space ');fs.renameSync(repo,spaced);
 run(change({checkout:spaced}));fs.renameSync(spaced,repo);
 // Empty allowlists and new files have no implicit scope.
 run(change({readPaths:[]}),1);write(path.join(repo,'untracked.md'),'DO_NOT_DISCLOSE_TEST_VALUE');
 run(change({readPaths:['untracked.md']}),1);
 // Git command hooks/configured external processes must not execute.
 const marker=path.join(temp,'unexpected-hook');
 git(['config','core.fsmonitor',`touch '${marker}'`]);
 run(record);assert(!fs.existsSync(marker));
 const bad=spawnSync(process.execPath,[cli,'--unknown'],{encoding:'utf8'});assert.equal(bad.status,2);
 const help=spawnSync(process.execPath,[cli,'--help'],{encoding:'utf8'});assert.equal(help.status,0);
 // Run the published, non-Git vault link recipe, preserving an existing file.
 const guide=fs.readFileSync(path.join(root,'docs/setup/manual/second-brain/obsidian/note-contract.md'),'utf8');
 const recipe=guide.match(/   ```bash\n([\s\S]+?)   ```/)[1].replace(/^   /gm,'');
 write(path.join(vault,'AGENTS.md'),'# Existing user policy\n');
 const link=()=>spawnSync('/bin/bash',['-c',recipe],{cwd:vault,encoding:'utf8'});
 assert.equal(link().status,0);assert.equal(fs.readlinkSync(path.join(vault,'CLAUDE.md')),'AGENTS.md');
 assert.equal(link().status,0);fs.unlinkSync(path.join(vault,'CLAUDE.md'));
 write(path.join(vault,'CLAUDE.md'),'# Existing Claude policy\n');
 const existing=snapshot(vault);assert.equal(link().status,0);assert.deepEqual(snapshot(vault),existing);
 console.log('PASS: selected repository scope, private metadata, source evidence, worktrees, dirty files, forbidden/symlink paths and read-only fixtures');
} finally { fs.rmSync(temp,{recursive:true,force:true}); }
