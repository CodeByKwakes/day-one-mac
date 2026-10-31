#!/usr/bin/env node
'use strict';
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const root=path.resolve(__dirname,'../..');
const need=(condition,message)=>{if(!condition)throw new Error(message);};
const hash=value=>crypto.createHash('sha256').update(value).digest('hex');
const exists=file=>{try{fs.lstatSync(file);return true;}catch(error){if(error.code==='ENOENT')return false;throw error;}};
function regular(file,encoding='utf8') {
  for(let current=file;current!==path.dirname(current);current=path.dirname(current))
    need(!fs.lstatSync(current).isSymbolicLink(),'Symlink source refused: '+file);
  need(fs.statSync(file).isFile(),'Expected a regular source: '+file);
  return fs.readFileSync(file,encoding);
}
function catalogue(sourceRoot) {
  const base=path.join(sourceRoot.replace(/^\/tmp(?=\/|$)/,'/private/tmp').replace(/^\/var(?=\/|$)/,'/private/var'),'integrations/shortcuts');
  const value=JSON.parse(regular(path.join(base,'catalog.json')));
  need(value.schema===1 && Array.isArray(value.recipes) && value.recipes.length>0,'Invalid shortcut catalogue');
  need(value.quickActions===undefined || (Array.isArray(value.quickActions) && value.quickActions.every(recipe=>recipe.format==='automator-quick-action')),'Invalid Quick Action catalogue');
  const ids=new Set(),names=new Set(),bundles=new Set();
  for(const recipe of [...value.recipes,...(value.quickActions || [])]) {
    need(/^[a-z][a-z0-9-]+$/.test(recipe.id) && !ids.has(recipe.id),'Invalid or duplicate recipe ID');ids.add(recipe.id);
    need(typeof recipe.name==='string' && /^[A-Za-z][A-Za-z0-9 ]+$/.test(recipe.name) && !names.has(recipe.name),'Invalid or duplicate app name');names.add(recipe.name);
    need(recipe.bundleId===`com.codebykwakes.day-one-shortcuts.${recipe.id}` && !bundles.has(recipe.bundleId),'Invalid bundle ID');bundles.add(recipe.bundleId);
    need(Array.isArray(recipe.sources) && recipe.sources.length>0 && Array.isArray(recipe.requires) && recipe.requires.every(v=>typeof v==='string') && typeof recipe.input==='string','Invalid recipe fields');
    recipe.sourceText=recipe.sources.map(name=>{
      need(/^[a-z][a-z0-9-]+\.applescript$/.test(name),'Invalid source filename');
      return regular(path.join(base,name));
    }).join('\n');
    need(!/\/Users\/|shortcutIdentifier/.test(recipe.sourceText),'Personal paths or installed shortcut IDs are not portable');
    if(recipe.icon!==undefined) {
      need(typeof recipe.icon==='string' && /^icons\/[a-z][a-z0-9-]+\.icns$/.test(recipe.icon),'Invalid icon filename');
      recipe.iconData=regular(path.join(base,recipe.icon),null);
      need(recipe.iconData.length>=8 && recipe.iconData.toString('ascii',0,4)==='icns' && recipe.iconData.readUInt32BE(4)===recipe.iconData.length,'Invalid ICNS asset');
    }
  }
  return value;
}
function destination(sourceRoot,output) {
  need(typeof output==='string' && path.isAbsolute(output) && !/[\x00-\x1f\x7f]/.test(output),'Output must be an absolute path without control characters');
  const normalized=path.resolve(output.replace(/^\/tmp(?=\/|$)/,'/private/tmp').replace(/^\/var(?=\/|$)/,'/private/var'));
  need(!exists(normalized),'Output already exists; choose a new review folder');
  const parent=path.dirname(normalized);
  for(let current=parent;current!==path.dirname(current);current=path.dirname(current))
    need(!fs.lstatSync(current).isSymbolicLink(),'Output ancestor is a symlink');
  const info=fs.statSync(parent);
  need(info.isDirectory() && info.uid===process.getuid(),'Output parent must exist and belong to you');
  const boundary=path.basename(sourceRoot)==='project' && path.basename(path.dirname(sourceRoot))==='references' ? path.resolve(sourceRoot,'../..') : sourceRoot;
  const physical=fs.realpathSync(boundary);
  need(normalized!==physical && !normalized.startsWith(physical+path.sep),'Keep app output outside the source or installed skill');
  return normalized;
}
function plan(sourceRoot,selected,output) {
  const all=catalogue(sourceRoot).recipes;
  const recipes=selected==='all'?all:all.filter(recipe=>recipe.id===selected);
  need(recipes.length>0,'Unknown recipe');
  return {sourceRoot,output:destination(sourceRoot,output),recipes};
}
function command(executable,args) {
  const result=spawnSync(executable,args,{encoding:'utf8',timeout:60000});
  need(result.status===0,`${path.basename(executable)} failed: ${result.error || result.stderr || result.stdout}`);
  return result.stdout;
}
function build(review) {
  need(process.platform==='darwin','App compilation requires macOS');
  need(process.arch==='arm64','Day One Mac targets native Apple silicon');
  const output=destination(review.sourceRoot,review.output);
  fs.mkdirSync(output,{mode:0o700});
  const record={schema:1,apps:[]};
  try {
    for(const recipe of review.recipes) {
      const source=path.join(output,recipe.id+'.applescript');
      fs.writeFileSync(source,recipe.sourceText,{flag:'wx',mode:0o600});
      const app=path.join(output,recipe.name+'.app');
      command('/usr/bin/osacompile',['-o',app,source]);
      const plist=path.join(app,'Contents/Info.plist');
      const info=JSON.parse(command('/usr/bin/plutil',['-convert','json','-o','-',plist]));
      for(const [key,value] of Object.entries({CFBundleIdentifier:recipe.bundleId,NSAppleEventsUsageDescription:'Read the selected Finder folder for this developer shortcut.'}))
        command('/usr/libexec/PlistBuddy',['-c',`${Object.hasOwn(info,key)?'Set':'Add'} :${key} ${Object.hasOwn(info,key)?'':'string '}${value}`,plist]);
      if(recipe.iconData) {
        fs.writeFileSync(path.join(app,'Contents/Resources/DayOneIcon.icns'),recipe.iconData,{flag:'wx',mode:0o644});
        command('/usr/libexec/PlistBuddy',['-c',`${Object.hasOwn(info,'CFBundleIconFile')?'Set':'Add'} :CFBundleIconFile ${Object.hasOwn(info,'CFBundleIconFile')?'':'string '}DayOneIcon.icns`,plist]);
      }
      command('/usr/bin/codesign',['--force','--sign','-',app]);
      command('/usr/bin/codesign',['--verify','--strict',app]);
      record.apps.push({id:recipe.id,app:recipe.name+'.app',bundleId:recipe.bundleId,source:recipe.id+'.applescript',sourceSha256:hash(recipe.sourceText),...(recipe.iconData?{icon:recipe.icon,iconSha256:hash(recipe.iconData)}:{})});
    }
    fs.writeFileSync(path.join(output,'build-manifest.json'),JSON.stringify(record,null,2)+'\n',{flag:'wx',mode:0o600});
  } catch(error) {
    fs.writeFileSync(path.join(output,'BUILD-INCOMPLETE.txt'),'Build stopped. Inspect this folder; keep it for diagnosis and choose a fresh output for retry.\n',{flag:'wx',mode:0o600});
    throw new Error(`${error.message}\nPartial output retained at ${output}`);
  }
  return record;
}
function main(args) {
  if(args.length===0 || args.includes('--help')) {
    console.log('Usage: bash build-apps.sh --list\n       bash build-apps.sh --recipe <id|all> --output <new-absolute-directory> [--build]\nDefault: preview only. --build creates review apps; never installs, replaces or launches them.');return;
  }
  if(args.length===1 && args[0]==='--list') {
    for(const recipe of catalogue(root).recipes) console.log(`${recipe.id}: ${recipe.name} (${recipe.requires.join('; ')})`);return;
  }
  let selected,output,execute=false;
  for(let i=0;i<args.length;i++) {
    if(args[i]==='--recipe' && selected===undefined) selected=args[++i];
    else if(args[i]==='--output' && output===undefined) output=args[++i];
    else if(args[i]==='--build' && !execute) execute=true;
    else throw new Error('Unknown or duplicate option. Use --help.');
  }
  const review=plan(root,selected,output);
  console.log(`Output: ${review.output}`);
  for(const recipe of review.recipes) console.log(`${recipe.name}.app: ${recipe.requires.join('; ')}; source SHA-256 ${hash(recipe.sourceText)}${recipe.iconData?`; icon ${recipe.icon}; SHA-256 ${hash(recipe.iconData)}`:''}`);
  if(!execute) {console.log('Preview only. No files created. Review the source before adding --build.');return;}
  const result=build(review);console.log(`Built ${result.apps.length} local review apps. Nothing installed or launched.`);
}
if(require.main===module) {try{main(process.argv.slice(2));}catch(error){console.error(error.message);process.exitCode=1;}}
module.exports={catalogue,plan,build};
