#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname,'../..');
const source = path.join(root,'integrations/shortcuts/git-clone.applescript');
assert(fs.existsSync(source),'Portable Git Clone source must exist');
const text = fs.readFileSync(source,'utf8');
assert(!/\/Users\/|shortcutIdentifier|[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}/.test(text),'No personal paths or local shortcut identifiers');
if(process.platform !== 'darwin') { console.log('SKIP: AppleScript compilation requires macOS'); process.exit(0); }
const tmp = fs.mkdtempSync(path.join(os.tmpdir(),'day-one-shortcuts-'));
const literal = value => '"'+value.replaceAll('\\','\\\\').replaceAll('"','\\"')+'"';
try {
  const compiled = path.join(tmp,'clone.scpt');
  const compile = spawnSync('/usr/bin/osacompile',['-o',compiled,source],{encoding:'utf8'});
  assert.equal(compile.status,0,compile.stderr);
  const call = (handler,args,fail=false) => {
    // Invoke only pure handlers: no dialogs, app events or interactive run handler.
    const script = `set fixture to load script POSIX file ${literal(compiled)}\nreturn fixture's ${handler}(${args.map(literal).join(', ')})\n`;
    const run = spawnSync('/usr/bin/osascript',['-'],{input:script,encoding:'utf8',timeout:10000});
    assert.equal(run.status,fail?1:0,run.stdout+run.stderr);
    return run.stdout.trimEnd();
  };
  for(const url of ['https://github.com/octocat/Hello-World.git','ssh://git@example.org/team/repo.git','git@example.org:team/repo.git']) assert.equal(call('validatedRepositoryURL',[url]),url);
  for(const url of ['', '--upload-pack=bad', 'file:///tmp/repo', 'ext::sh', 'https://token@example.org/repo',
    'https://example.org/repo?token=secret','https://example.org/repo#secret','ssh://user:secret@example.org/repo',
    'https://example.org/repo name', 'https://example.org/repo\nextra', 'https://', 'git@:repo', 'git@example.org:']) call('validatedRepositoryURL',[url],true);
  for(const name of ['my repo é','project $(touch BAD)',"project's demo"]) assert.equal(call('validatedFolderName',[name]),name);
  for(const name of ['', '.', '..', '../escape', 'folder/child','a:b','line\nbreak','tab\there']) call('validatedFolderName',[name],true);
  assert.equal(call('suggestedFolderName',['git@example.org:repo.git']),'repo');
  assert.equal(call('suggestedFolderName',['https://example.org/team/repo.git/']),'repo');
  const fakeGit = path.join(tmp,'mock Git é');
  fs.writeFileSync(fakeGit,`#!${process.execPath}\nconst fs=require('node:fs');\nif(process.argv[2]==='config') process.exit(1);\nfs.writeFileSync(process.env.FIXTURE_LOG,JSON.stringify(process.argv.slice(2)));\nif(process.env.FIXTURE_FAIL) process.exit(9);\nfs.writeFileSync(process.argv.at(-1)+'/cloned','fixture');\n`,{mode:0o700});
  const log = path.join(tmp,'arguments.json');
  const isolatedEnv={...process.env,GIT_CONFIG_NOSYSTEM:'1',GIT_CONFIG_GLOBAL:path.join(tmp,'gitconfig')};
  for(const name of Object.keys(isolatedEnv)) if(/^GIT_(SSH|CONFIG_(COUNT|KEY_|VALUE_))/.test(name)) delete isolatedEnv[name];
  const execute = (destination,status=0,extra={}) => {
    const url = 'https://example.org/team/repo$(touch-BAD).git';
    const command=call('cloneCommand',[url,destination,fakeGit]);
    const result=spawnSync('/bin/sh',['-c',command],{cwd:tmp,env:{...isolatedEnv,FIXTURE_LOG:log,...extra},encoding:'utf8'});
    assert.equal(result.status,status,result.stdout+result.stderr);
    return url;
  };
  const destination=path.join(tmp,"new repo's é $(touch BAD)");
  const url=execute(destination);
  assert(fs.existsSync(path.join(destination,'cloned')));
  assert(!fs.existsSync(path.join(tmp,'BAD')));
  assert.equal(fs.statSync(destination).mode&0o777,0o700);
  assert.deepEqual(JSON.parse(fs.readFileSync(log)),['-c','protocol.ext.allow=never','-c','core.hooksPath=/dev/null','clone','--',url,destination]);
  fs.unlinkSync(log);
  for(const variable of ['GIT_SSH_COMMAND','GIT_SSH']) {
    const target=path.join(tmp,variable);
    execute(target,2,{[variable]:'ssh -F custom-config'});
    assert(!fs.existsSync(target),'Custom SSH settings must stop before creating a destination');
    assert(!fs.existsSync(log),'Custom SSH settings must stop before cloning');
  }
  fs.writeFileSync(isolatedEnv.GIT_CONFIG_GLOBAL,'[core]\n\tsshCommand = ssh -F custom-config\n');
  const sshTarget=path.join(tmp,'custom ssh configuration');
  const sshCommand=call('cloneCommand',['git@example.invalid:team/repo.git',sshTarget,'/usr/bin/git']);
  const sshResult=spawnSync('/bin/sh',['-c',sshCommand],{cwd:tmp,env:isolatedEnv,encoding:'utf8',timeout:10000});
  assert.equal(sshResult.status,2,sshResult.stdout+sshResult.stderr);
  assert.match(sshResult.stderr,/custom SSH command/i);
  assert(!fs.existsSync(sshTarget),'Real Git configuration must be checked before creating a destination');
  fs.unlinkSync(isolatedEnv.GIT_CONFIG_GLOBAL);
  for(const kind of ['empty-directory','file','symlink','dangling-link']) {
    const target=path.join(tmp,kind);
    if(kind==='empty-directory')fs.mkdirSync(target);
    else if(kind==='file')fs.writeFileSync(target,'keep');
    else fs.symlinkSync(kind==='symlink'?destination:path.join(tmp,'missing'),target);
    if(fs.existsSync(log))fs.unlinkSync(log);
    execute(target,1);
    assert(!fs.existsSync(log),'Collision must stop before invoking Git');
  }
  const failed=path.join(tmp,'failed clone');
  execute(failed,9,{FIXTURE_FAIL:'1'});
  assert(fs.existsSync(failed),'Failed clones are retained for explicit inspection');
  console.log('PASS: portable AppleScript compiles; validation, quoting, exclusive clone destination and failure retention verified without UI or network');
} finally { fs.rmSync(tmp,{recursive:true,force:true}); }
