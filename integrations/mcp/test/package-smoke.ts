import assert from 'node:assert/strict';
import * as fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
const exec = promisify(execFile);
const root = await fs.realpath(await fs.mkdtemp(path.join(os.tmpdir(),'day-one-mcp-package-')));
const npmCli = process.env.npm_execpath;
assert(npmCli && path.isAbsolute(npmCli), 'Run through npm run test:package');
const npm = async (args: string[], cwd: string) => (await exec(process.execPath,[npmCli,...args], {cwd,timeout:120000,maxBuffer:1024*1024,env:{...process.env,DO_NOT_TRACK:'1',npm_config_cache:path.join(root,'cache')}})).stdout;
try {
  const records = JSON.parse(await npm(['pack','--ignore-scripts','--json','--pack-destination',root],process.cwd()));
  assert.equal(records.length,1); assert.equal(records[0].name,'day-one-mac-mcp');
  const files: string[] = records[0].files.map((f: {path: string}) => f.path);
  for (const name of files) assert(/^(package\.json|npm-shrinkwrap\.json|README\.md|LICENSE|dist\/(guides|server-spec)\.json|dist\/src\/[a-z-]+\.(js|d\.ts))$/.test(name), 'Unexpected packed file: '+name);
  for (const name of ['LICENSE','README.md','npm-shrinkwrap.json','dist/guides.json','dist/server-spec.json','dist/src/index.js','dist/src/configure.js']) assert(files.includes(name));
  const workspace = path.join(root,'Standalone Mac é with spaces'); await fs.mkdir(workspace);
  const tarball = path.join(root,records[0].filename);
  await npm(['install','--prefix',workspace,'--ignore-scripts','--no-audit','--no-fund','--prefer-offline','--fetch-retries=0','--fetch-timeout=20000',tarball],workspace);
  const installed=path.join(workspace,'node_modules/day-one-mac-mcp');
  const manifest=JSON.parse(await fs.readFile(path.join(installed,'package.json'),'utf8'));
  assert.equal(manifest.bin['day-one-mac-mcp'],'dist/src/index.js');
  for (const development of ['typescript','@types/node','@modelcontextprotocol/client','esbuild']) await assert.rejects(fs.stat(path.join(workspace,'node_modules',development)));
  assert.equal((await fs.stat(path.join(installed,'dist/src/index.js'))).mode & 0o111,0o111);
  const configBin=path.join(workspace,'node_modules/.bin/day-one-mac-mcp-configure');
  const env={...process.env,PATH:path.dirname(process.execPath)+path.delimiter+(process.env.PATH??'')};
  const configs=JSON.parse((await exec(configBin,[],{cwd:workspace,env})).stdout);
  assert.equal(configs.claude.mcpServers['day-one-mac'].args[0],path.join(installed,'dist/src/index.js'));
  const npmConfigs=JSON.parse((await exec(configBin,['--launch','npm'],{cwd:workspace,env})).stdout);
  assert(npmConfigs.claude.mcpServers['day-one-mac'].args.includes('--package=day-one-mac-mcp@0.1.0'));
  const transport=new StdioClientTransport({command:path.join(workspace,'node_modules/.bin/day-one-mac-mcp'),args:[],cwd:workspace,env:env as Record<string,string>,stderr:'pipe'});
  const client=new Client({name:'packed-install-test',version:'0.1.0'});
  try {
    await client.connect(transport);
    assert.equal((await client.listTools()).tools.length,5);
    assert.equal((await client.listResources()).resources.length,11);
    assert.equal((await client.listPrompts()).prompts.length,2);
    const guide=await client.readResource({uri:'day-one-mac://guide/macos'});
    assert.match((guide.contents[0] as {text:string}).text,/# Prepare macOS/);
    const denied=await client.callTool({name:'desktop_click',arguments:{mode:'always',dry_run:false}});assert.equal(denied.isError,true);
  } finally {await client.close();await transport.close();}
  const gui=path.join(root,'GUI working directory');await fs.mkdir(gui);
  const npmLaunch=npmConfigs.claude.mcpServers['day-one-mac'];
  const npmTransport=new StdioClientTransport({command:npmLaunch.command,
    args:npmLaunch.args.map((arg:string)=>arg.startsWith('--package=')?'--package='+tarball:arg),cwd:gui,
    env:{...npmLaunch.env,npm_config_cache:path.join(root,'cache'),npm_config_offline:'true',npm_config_update_notifier:'false'},stderr:'pipe'});
  const npmClient=new Client({name:'minimal-gui-npm-launch',version:'0.1.0'});
  try {await npmClient.connect(npmTransport);assert.equal((await npmClient.listTools()).tools.length,5);}
  finally {await npmClient.close();await npmTransport.close();}
  const artifact=path.join(root,'checked-package');
  const artifactScript=path.resolve('scripts/package-artifact.mjs');
  await exec(process.execPath,[artifactScript,artifact],{cwd:gui,env:process.env});
  const checksum=await fs.readFile(path.join(artifact,'day-one-mac-mcp-0.1.0.tgz.sha256'),'utf8');
  await assert.rejects(exec(process.execPath,[artifactScript,artifact],{cwd:gui,env:process.env}));
  assert.equal(await fs.readFile(path.join(artifact,'day-one-mac-mcp-0.1.0.tgz.sha256'),'utf8'),checksum);
  console.log('PASS: GUI-like pinned npm launch and no-overwrite package artifact command');
  console.log('PASS: inspected tarball; production-only installation, executable bins, client configuration and stdio work outside the checkout in a Unicode path with spaces');
} finally {await fs.rm(root,{recursive:true,force:true});}
