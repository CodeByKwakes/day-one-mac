import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import * as fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { parseOptions, configuration } from '../src/configure.js';

test('configuration arguments reject unknown, repeated and incompatible options', () => {
  assert.deepEqual(parseOptions([]), {client:'all', launch:'direct'});
  for (const args of [['--client','wrong'], ['--launch','wrong'],['--write','yes'],['--client'],['--client','all','--client','all'],['--npm-cli','relative'],['--image','image','--launch','direct']]) assert.throws(() => parseOptions(args));
});
test('direct configurations share the actual installed Node and server path', async () => {
  const configs = await configuration({client:'all',launch:'direct'});
  const expected = configs.claude.mcpServers['day-one-mac'];
  assert.equal(expected.command, await fs.realpath(process.execPath));
  assert.equal(path.basename(expected.args[0]),'index.js');
  assert.deepEqual(configs.vscode.servers['day-one-mac'], {type:'stdio',...expected});
  assert.deepEqual(configs.raycast.args,expected.args);
  assert.match(configs.codex,/startup_timeout_sec = 60/);
  const allowlist = JSON.parse(configs.codex.match(/^enabled_tools = (.+)$/m)![1]) as string[];
  assert(allowlist.includes('preview_desktop_click'));
  assert(!allowlist.includes('apply_desktop_click'));
  assert(!allowlist.includes('desktop_click'), 'Mixed legacy interface is not a default client permission');
  const printed = JSON.parse(execFileSync(process.execPath,['dist/src/configure.js'],{encoding:'utf8'}));
  assert.deepEqual(printed.claude,configs.claude);
});
test('npm configuration pins the package and includes Node on the child PATH', async () => {
  const configs = await configuration({client:'all',launch:'npm'});
  const server = configs.claude.mcpServers['day-one-mac'];
  assert.match(server.args[0],/npm-cli\.js$/);
  assert(server.args.includes('--package=day-one-mac-mcp@0.1.0'));
  assert(server.args.includes('--ignore-scripts'));
  assert.equal(server.env?.PATH.split(path.delimiter)[0],path.dirname(server.command));
  const fallback = JSON.parse(execFileSync(process.execPath, ['dist/src/configure.js','--launch','npm'], {encoding:'utf8',env:{...process.env,npm_execpath:''},stdio:['pipe','pipe','pipe']}));
  assert.match(fallback.claude.mcpServers['day-one-mac'].args[0],/npm-cli\.js$/);
  await assert.rejects(configuration({client:'all',launch:'npm',npmCli:'/definitely/absent/npm-cli.js'}));
});

test('Docker configuration resolves the executable on this machine and rejects missing Docker', async () => {
  const dir=await fs.mkdtemp(path.join(os.tmpdir(),'day-one-docker-config-'));
  try {
    const mock=path.join(dir,'docker');await fs.writeFile(mock,'#!/bin/sh\nexit 0\n',{mode:0o755});
    const configs=JSON.parse(execFileSync(process.execPath,['dist/src/configure.js','--launch','docker'],{encoding:'utf8',env:{...process.env,PATH:dir}}));
    assert.equal(configs.claude.mcpServers['day-one-mac'].command,mock);
    assert.equal(configs.claude.mcpServers['day-one-mac'].args.at(-1),'day-one-mac-mcp:0.1.0');
    assert.throws(()=>execFileSync(process.execPath,['dist/src/configure.js','--launch','docker'],{encoding:'utf8',env:{...process.env,PATH:''},stdio:['pipe','pipe','pipe']}));
  } finally {await fs.rm(dir,{recursive:true});}
});
