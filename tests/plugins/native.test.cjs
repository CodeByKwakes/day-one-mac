const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const {createHash} = require('node:crypto');
const {createRequire} = require('node:module');
const {execFile} = require('node:child_process');
const {promisify} = require('node:util');
const exec = promisify(execFile);
const root = path.resolve(__dirname, '../..');
const mcpRequire = createRequire(path.join(root, 'integrations/mcp/package.json'));
const {Client} = mcpRequire('@modelcontextprotocol/client');
const {StdioClientTransport} = mcpRequire('@modelcontextprotocol/client/stdio');
const {buildPlugins} = require('../../tools/build-plugins.cjs');

test('native plugin artifacts relocate without checkout/dependencies, preserve licenses and expose only read-only MCP', async () => {
  const temp = await fs.realpath(await fs.mkdtemp(path.join(os.tmpdir(), 'day-one-plugins-')));
  try {
    const output = path.join(temp, 'Plugin output é');
    const built = await buildPlugins(output);
    const fixtureMarketplace = `day-one-mac-fixture-${process.pid}`;
    for (const [platform, relative] of [['codex','.agents/plugins/marketplace.json'], ['claude','.claude-plugin/marketplace.json']]) {
      const file = path.join(output,platform,relative);
      const catalog = JSON.parse(await fs.readFile(file,'utf8'));
      catalog.name = fixtureMarketplace;
      await fs.writeFile(file, JSON.stringify(catalog));
    }
    await assert.rejects(buildPlugins(output), /EEXIST/);
    await assert.rejects(buildPlugins(path.join(root, 'private-plugin-output')), /outside the checkout/);
    const alias = path.join(temp, 'existing-output-link'); await fs.symlink(output, alias);
    await assert.rejects(buildPlugins(alias), /EEXIST/);
    for (const platform of ['codex', 'claude']) {
      const folder = path.join(temp, `Relocated ${platform} é with spaces`);
      await fs.cp(built[platform], folder, {recursive:true});
      const artifact = JSON.parse(await fs.readFile(path.join(folder,'artifact.json'), 'utf8'));
      const walk = async directory => (await Promise.all((await fs.readdir(directory, {withFileTypes:true})).map(async entry => {
        const file = path.join(directory,entry.name);
        assert(!entry.isSymbolicLink(), `Packaged symlink: ${file}`);
        return entry.isDirectory() ? walk(file) : [path.relative(folder,file).split(path.sep).join('/')];
      }))).flat();
      assert.deepEqual((await walk(folder)).sort(), [...Object.keys(artifact.files),'artifact.json'].sort());
      for (const [name, expected] of Object.entries(artifact.files)) {
        const file = path.join(folder, name);
        assert((await fs.lstat(file)).isFile(), name);
        const bytes = await fs.readFile(file);
        assert.equal(createHash('sha256').update(bytes).digest('hex'), expected);
        if (/\.(md|json|js|toml)$/.test(name)) assert(!bytes.toString().includes(os.homedir() + '/'), `Private path in ${name}`);
      }
      for (const excluded of ['agents', 'hooks', 'node_modules', '.agents', '.claude', '.codex']) await assert.rejects(fs.lstat(path.join(folder,excluded)));
      assert(await fs.stat(path.join(folder,'skills/day-one-mac/SKILL.md')));
      const licenses = JSON.parse(await fs.readFile(path.join(folder,'runtime/licenses/dependencies.json'), 'utf8'));
      assert(licenses.some(entry => entry.name === '@modelcontextprotocol/server'));
      assert(licenses.some(entry => entry.name === 'zod'));
      const manifest = JSON.parse(await fs.readFile(path.join(folder, platform === 'codex' ? '.codex-plugin/plugin.json' : '.claude-plugin/plugin.json'),'utf8'));
      assert.equal(manifest.name, 'day-one-mac'); assert.equal(manifest.version, '0.1.0');
      assert(!manifest.agents && !manifest.hooks);
      const config = JSON.parse(await fs.readFile(path.join(folder,'.mcp.json'),'utf8')).mcpServers[platform === 'codex' ? 'day_one_mac' : 'day-one-mac'];
      const variable = platform === 'codex' ? '${PLUGIN_ROOT}' : '${CLAUDE_PLUGIN_ROOT}';
      assert.equal(config.args.length, 1);
      assert(config.args[0].startsWith(variable + '/'));
      const transport = new StdioClientTransport({command:config.command, args:config.args.map(arg => arg.replace(variable,folder)), cwd:temp, stderr:'pipe', env:{PATH:path.dirname(process.execPath)}});
      const client = new Client({name:'day-one-plugin-fixture',version:'0.1.0'});
      try {
        await client.connect(transport);
        const tools = (await client.listTools()).tools;
        assert.equal(tools.length,5); assert(tools.every(tool => tool.annotations?.readOnlyHint));
        assert(!tools.some(tool => tool.name === 'apply_desktop_click'));
        const read = await client.callTool({name:'read_guide',arguments:{id:'shortcuts'}});
        assert.match(JSON.parse(read.content[0].text).text, /Send to Archive/);
      } finally {await client.close(); await transport.close();}
      if (platform === 'claude' && process.env.DAY_ONE_CLAUDE_BIN) {
        const result = await exec(process.env.DAY_ONE_CLAUDE_BIN, ['plugin','validate',folder,'--strict'], {timeout:30000,
          env:{...process.env, CLAUDE_CONFIG_DIR:path.join(temp,'claude-config'), DISABLE_AUTOUPDATER:'1', CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:'1'}});
        assert.match(result.stdout, /Validation passed/);
      }
    }
    if (process.env.DAY_ONE_CLAUDE_BIN) {
      const report = await exec(process.env.DAY_ONE_CLAUDE_BIN, ['plugin','validate',path.join(output,'claude'),'--strict'], {timeout:30000,
        env:{...process.env, CLAUDE_CONFIG_DIR:path.join(temp,'claude-config'), DISABLE_AUTOUPDATER:'1', CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:'1'}});
      assert.match(report.stdout, /Validation passed/);
      const roles = path.join(temp,'role-validation-only');
      await fs.mkdir(path.join(roles,'.claude-plugin'), {recursive:true});
      await fs.writeFile(path.join(roles,'.claude-plugin/plugin.json'), JSON.stringify({name:'day-one-role-validation',version:'0.1.0',description:'Temporary role format validation',author:{name:'Day One Mac contributors'}}));
      await fs.cp(path.join(root,'templates/agents/claude'),path.join(roles,'agents'),{recursive:true});
      await exec(process.env.DAY_ONE_CLAUDE_BIN,['plugin','validate',roles,'--strict'],{timeout:30000,
        env:{...process.env,CLAUDE_CONFIG_DIR:path.join(temp,'claude-config'),DISABLE_AUTOUPDATER:'1',CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:'1'}});
    }
    if (process.env.DAY_ONE_CODEX_BIN) {
      const catalog = await exec(process.env.DAY_ONE_CODEX_BIN, ['plugin','list','--available','--json','--marketplace',fixtureMarketplace,
        '-c',`marketplaces.${fixtureMarketplace}.source_type="local"`, '-c',`marketplaces.${fixtureMarketplace}.source=${JSON.stringify(path.join(output,'codex'))}`], {timeout:30000});
      const entry = JSON.parse(catalog.stdout).available.find(plugin => plugin.pluginId === `day-one-mac@${fixtureMarketplace}`);
      assert(entry, 'Codex did not discover the native package');
      assert.equal(entry.installed,false); assert.equal(entry.enabled,false);
    }
  } finally {await fs.rm(temp, {recursive:true, force:true});}
});
