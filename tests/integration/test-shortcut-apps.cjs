#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {spawnSync}=require('node:child_process');
const root=path.resolve(__dirname,'../..');
const helper=path.join(root,'helpers/shortcuts/build.cjs');
assert(fs.existsSync(helper),'Shortcut app builder must exist');
const {catalogue,plan,build}=require(helper);
const tmp=fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(),'day-one-apps-')));
try {
  assert.equal(catalogue(root).recipes.length,5);
  for(const id of ['git-clone','open-in-warp','open-in-vscode'])
    assert.equal(catalogue(root).recipes.find(r=>r.id===id).icon,`icons/${id}.icns`);
  assert.throws(()=>plan(root,'unknown',path.join(tmp,'unknown')));
  const output=path.join(tmp,"Review é $(touch BAD)");
  const preview=plan(root,'all',output);
  assert.equal(preview.recipes.length,5);
  assert(!fs.existsSync(output),'Planning must not create output');
  for(const kind of ['folder','file','symlink','dangling']) {
    const target=path.join(tmp,kind);
    if(kind==='folder') fs.mkdirSync(target);
    else if(kind==='file') fs.writeFileSync(target,'keep');
    else fs.symlinkSync(kind==='symlink'?tmp:path.join(tmp,'missing'),target);
    assert.throws(()=>plan(root,'all',target),/exists|symlink/i);
  }
  assert.throws(()=>plan(root,'all',path.join(root,'forbidden-output')),/outside/i);
  if(process.platform!=='darwin') {console.log('SKIP: app compilation requires macOS');process.exit(0);}
  build(preview);
  assert(fs.existsSync(path.join(output,'build-manifest.json')));
  assert(!fs.existsSync(path.join(tmp,'BAD')));
  assert.throws(()=>build(preview),/exists/i,'A reviewed destination must be rechecked');
  for(const recipe of preview.recipes) {
    const app=path.join(output,recipe.name+'.app');
    const executable=spawnSync('/usr/libexec/PlistBuddy',['-c','Print :CFBundleExecutable',path.join(app,'Contents/Info.plist')],{encoding:'utf8'});
    assert.equal(executable.status,0,executable.stderr);
    assert(fs.existsSync(path.join(app,'Contents/MacOS',executable.stdout.trim())));
    assert(fs.existsSync(path.join(app,'Contents/Resources/Scripts/main.scpt')));
    const info=spawnSync('/usr/libexec/PlistBuddy',['-c','Print :CFBundleIdentifier',path.join(app,'Contents/Info.plist')],{encoding:'utf8'});
    assert.equal(info.status,0,info.stderr);
    assert.equal(info.stdout.trim(),recipe.bundleId);
    if(recipe.icon) {
      const iconName=spawnSync('/usr/libexec/PlistBuddy',['-c','Print :CFBundleIconFile',path.join(app,'Contents/Info.plist')],{encoding:'utf8'});
      assert.equal(iconName.status,0,iconName.stderr);
      const expected=fs.readFileSync(path.join(root,'integrations/shortcuts',recipe.icon));
      assert.deepEqual(fs.readFileSync(path.join(app,'Contents/Resources',iconName.stdout.trim())),expected);
      const manifest=JSON.parse(fs.readFileSync(path.join(output,'build-manifest.json')));
      assert.equal(manifest.apps.find(r=>r.id===recipe.id).iconSha256,require('node:crypto').createHash('sha256').update(expected).digest('hex'));
    }
    const signature=spawnSync('/usr/bin/codesign',['--verify','--strict',app],{encoding:'utf8'});
    assert.equal(signature.status,0,signature.stderr);
  }
  const literal=value=>'"'+value.replaceAll('\\','\\\\').replaceAll('"','\\"')+'"';
  const compiled=path.join(output,'Open in VS Code.app/Contents/Resources/Scripts/main.scpt');
  const call=(expression,fail=false)=>{
    const script=`set fixture to load script POSIX file ${literal(compiled)}\nreturn ${expression}\n`;
    const result=spawnSync('/usr/bin/osascript',['-'],{input:script,encoding:'utf8',timeout:10000});
    assert.equal(result.status,fail?1:0,result.stdout+result.stderr);
    return result.stdout.trimEnd();
  };
  const folder=path.join(tmp,"Project é ' &? #$(touch BAD)");fs.mkdirSync(folder);
  assert.equal(call(`fixture's validatedFolder(${literal(folder)})`),folder);
  call(`fixture's folderFromItems({})`,true);
  call(`fixture's folderFromItems({POSIX file ${literal(folder)} as alias, POSIX file ${literal(tmp)} as alias})`,true);
  const ownApp=path.join(output,'Open in VS Code.app')+'/';
  assert.equal(call(`count (fixture's excludeOwnLauncher({POSIX file ${literal(ownApp)} as alias}, ${literal(ownApp)}))`),'0');
  call(`fixture's validatedFolder(${literal(ownApp)})`,true);
  call(`fixture's requiredApplication("invalid.day-one.fixture-missing")`,true);
  for(const target of [path.join(tmp,'missing'),path.join(tmp,'file'),'/']) call(`fixture's validatedFolder(${literal(target)})`,true);
  assert.equal(call(`fixture's warpURL(${literal(folder)})`),'warp://action/new_tab?path='+encodeURIComponent(folder).replace(/[!'()*]/g,c=>'%'+c.charCodeAt(0).toString(16).toUpperCase()));
  const profiles='{"userDataProfiles":[{"name":"Full Stack","location":"one"},{"name":"AI","location":"two"}]}';
  const profileFile=path.join(tmp,"Profile metadata é.json");
  fs.writeFileSync(profileFile,profiles);
  assert.equal(call(`fixture's readProfileState(${literal(profileFile)})`),profiles);
  call(`fixture's readProfileState(${literal(path.join(tmp,'absent-profile-file'))})`,true);
  const profileCases=[
    {label:'No invented default',expression:`count (fixture's profileNames("{\\"userDataProfiles\\":[]}"))`,expected:'0'},
    {label:'Default requires a registered entry',expression:`fixture's verifiedProfile("Default", ${literal(profiles)})`,fail:true},
    ...[undefined,null,'',{},[],42].map(location=>({
      label:'Invalid location '+JSON.stringify(location),
      expression:`fixture's profileNames(${literal(JSON.stringify({userDataProfiles:[{name:'AI',location}]}))})`,fail:true
    }))
  ];
  const profileFailures=[];
  for(const test of profileCases) {
    try {const actual=call(test.expression,test.fail);if(!test.fail) assert.equal(actual,test.expected);}
    catch {profileFailures.push(test.label);}
  }
  assert.deepEqual(profileFailures,[],'Profile guards must reject synthetic names and unsupported records');
  assert.equal(call(`fixture's profileNames(${literal(profiles)})`),'Full Stack, AI');
  assert.equal(call(`fixture's profileNames(${literal('{"userDataProfiles":[{"name":"Nested","location":"../nested/profile"}]}')})`),'Nested');
  for(const invalid of ['broken','[]','{"userDataProfiles":null}','{"userDataProfiles":[{"name":"AI"},{"name":"AI"}]}']) call(`fixture's profileNames(${literal(invalid)})`,true);
  assert.equal(call(`fixture's verifiedProfile("AI", ${literal(profiles)})`),'AI');
  call(`fixture's verifiedProfile("Missing", ${literal(profiles)})`,true);
  call(`fixture's verifiedProfile("ai", ${literal(profiles)})`,true);
  const command=call(`fixture's codeCommand("/mock code", ${literal(folder)}, "AI")`);
  const mock=path.join(tmp,'mock code');
  fs.writeFileSync(mock,`#!${process.execPath}\nrequire('fs').writeFileSync(process.env.FIXTURE_LOG,JSON.stringify(process.argv.slice(2)));\n`,{mode:0o700});
  const actual=call(`fixture's codeCommand(${literal(mock)}, ${literal(folder)}, "AI")`);
  assert(command.includes('--profile'));
  const log=path.join(tmp,'args.json');
  const run=spawnSync('/bin/sh',['-c',actual],{env:{...process.env,FIXTURE_LOG:log},encoding:'utf8'});
  assert.equal(run.status,0,run.stderr);
  assert.deepEqual(JSON.parse(fs.readFileSync(log)),['--new-window','--profile','AI',folder]);
  assert(!fs.existsSync(path.join(tmp,'BAD')));
  const iconRoot=path.join(tmp,'Icon source');
  fs.mkdirSync(path.join(iconRoot,'integrations'),{recursive:true});
  fs.cpSync(path.join(root,'integrations/shortcuts'),path.join(iconRoot,'integrations/shortcuts'),{recursive:true});
  const iconCatalogue=path.join(iconRoot,'integrations/shortcuts/catalog.json');
  const iconSpec=JSON.parse(fs.readFileSync(iconCatalogue));
  for(const invalid of ['../outside.icns','/tmp/outside.icns','icons/missing.icns']) {
    iconSpec.recipes[0].icon=invalid;fs.writeFileSync(iconCatalogue,JSON.stringify(iconSpec));
    assert.throws(()=>catalogue(iconRoot));
  }
  iconSpec.recipes[0].icon='icons/git-clone.icns';fs.writeFileSync(iconCatalogue,JSON.stringify(iconSpec));
  const badIcon=path.join(iconRoot,'integrations/shortcuts/icons/git-clone.icns');
  fs.writeFileSync(badIcon,'not an icon');assert.throws(()=>catalogue(iconRoot),/ICNS/);
  fs.unlinkSync(badIcon);fs.symlinkSync(path.join(root,'integrations/shortcuts/icons/git-clone.icns'),badIcon);
  assert.throws(()=>catalogue(iconRoot),/Symlink/);
  const brokenRoot=path.join(tmp,'Broken source');
  fs.mkdirSync(path.join(brokenRoot,'integrations'),{recursive:true});
  fs.cpSync(path.join(root,'integrations/shortcuts'),path.join(brokenRoot,'integrations/shortcuts'),{recursive:true});
  fs.writeFileSync(path.join(brokenRoot,'integrations/shortcuts/git-clone.applescript'),'on run\nthis is invalid AppleScript !\nend run\n');
  const failedOutput=path.join(tmp,'Failed build');
  assert.throws(()=>build(plan(brokenRoot,'git-clone',failedOutput)),/Partial output retained/);
  assert(fs.existsSync(path.join(failedOutput,'BUILD-INCOMPLETE.txt')));
  assert(!fs.existsSync(path.join(failedOutput,'build-manifest.json')));
  console.log('PASS: five app bundles, signatures, preview/no-overwrite, folder/URI quoting and existing-profile guards; no live apps launched');
} finally {fs.rmSync(tmp,{recursive:true,force:true});}
