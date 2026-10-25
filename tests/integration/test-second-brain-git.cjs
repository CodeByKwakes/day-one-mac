#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const {spawnSync}=require('node:child_process');
const {inspect}=require('../../helpers/second-brain/inspect.cjs');
const temp=fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(),'brain-git-safety-')));
const failures=[];
function git(cwd,args){
 const result=spawnSync('git',['-c','commit.gpgsign=false','-c','core.hooksPath=/dev/null',...args],{cwd,encoding:'utf8',env:{...process.env,GIT_CONFIG_GLOBAL:'/dev/null',GIT_CONFIG_NOSYSTEM:'1'}});
 assert.equal(result.status,0,result.stderr);return result.stdout.trim();
}
try{
 for(const kind of ['clean','process','assume-unchanged','skip-worktree']){
  const repo=path.join(temp,kind);fs.mkdirSync(repo);
  const marker=path.join(temp,`${kind}-executed`), file=path.join(repo,'README.md');
  fs.writeFileSync(file,'# Committed\n');
  fs.writeFileSync(path.join(repo,'.gitattributes'),'README.md filter=fixture\n');
  git(repo,['init','-q']);git(repo,['add','.']);git(repo,['-c','user.name=Fixture','-c','user.email=fixture@example.test','commit','-qm','fixture']);
  if(kind==='clean')git(repo,['config','filter.fixture.clean',`touch '${marker}'; cat`]);
  else if(kind==='process'){
   const script=path.join(temp,'process-filter.sh');fs.writeFileSync(script,`#!/bin/sh\ntouch '${marker}'\nexit 1\n`,{mode:0o700});
   git(repo,['config','filter.fixture.process',`'${script}'`]);
  }else git(repo,['update-index',`--${kind}`,'README.md']);
  fs.writeFileSync(file,'# Different\n');fs.utimesSync(file,new Date(),new Date(Date.now()+5000));
  const config=path.join(temp,`${kind}.json`);
  fs.writeFileSync(config,JSON.stringify({schema:1,repositories:[{id:'fixture',checkout:repo,projectPage:'https://www.notion.so/fixture',aiAccess:'selected-files',readPaths:['README.md']}]}));
  const report=inspect(config);
  if(fs.existsSync(marker))failures.push(`${kind}: executed a content filter`);
  if(!report.ok)failures.push(`${kind}: failed instead of inspecting raw local evidence`);
  if(report.repositories[0]?.workingTree!=='selected-files-changed')failures.push(`${kind}: mislabeled altered evidence as clean`);
 }
 for(const format of ['sha1','sha256']){
  const repo=path.join(temp,format);fs.mkdirSync(repo);
  fs.mkdirSync(path.join(repo,'docs'));
  fs.writeFileSync(path.join(repo,'docs/keep.md'),'# Keep\n');
  fs.writeFileSync(path.join(repo,'docs/remove.md'),'# Remove\n');
  git(repo,['init','-q',`--object-format=${format}`]);git(repo,['add','.']);
  git(repo,['-c','user.name=Fixture','-c','user.email=fixture@example.test','commit','-qm','fixture']);
  const config=path.join(temp,`${format}.json`);
  fs.writeFileSync(config,JSON.stringify({schema:1,repositories:[{id:'fixture',checkout:repo,projectPage:'https://www.notion.so/fixture',aiAccess:'selected-files',readPaths:['docs']}]}));
  assert.equal(inspect(config).repositories[0].workingTree,'selected-files-clean');
  git(repo,['rm','-q','docs/remove.md']);
  const removed=inspect(config).repositories[0];
  assert.equal(removed.workingTree,'selected-files-changed');
  assert(removed.skipped.some(file=>file.path==='docs/remove.md'&&file.reason==='removed-from-index'));
  const marker=path.join(temp,`${format}-transport`), script=path.join(temp,`${format}-transport.sh`);
  fs.writeFileSync(script,`#!/bin/sh\ntouch '${marker}'\nexit 1\n`,{mode:0o700});
  git(repo,['config','remote.origin.url',`ext::${script}`]);
  git(repo,['config','remote.origin.promisor','true']);
  git(repo,['config','extensions.partialClone','origin']);
  git(repo,['config','protocol.ext.allow','always']);
  const tree=git(repo,['rev-parse','HEAD^{tree}']);
  fs.unlinkSync(path.join(repo,'.git/objects',tree.slice(0,2),tree.slice(2)));
  const missing=inspect(config);
  assert.equal(missing.ok,false);assert.equal(missing.repositories[0].findings[0].code,'git');
  assert(!fs.existsSync(marker),'Missing local objects must not launch a remote transport');
 }
 assert.deepEqual(failures,[]);
 console.log('PASS: filters and transports never execute; hidden changes, staged deletions and SHA-1/SHA-256 evidence are handled');
}finally{fs.rmSync(temp,{recursive:true,force:true});}
