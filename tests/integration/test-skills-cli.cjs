#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const { validatePackage } = require('./test-skills-package.cjs');
const root = path.resolve(__dirname, '../..');
const catalogue = JSON.parse(fs.readFileSync(path.join(root, 'config/catalogs/assistant-skills.json')));
const cli = process.argv[2] || process.env.DAY_ONE_SKILLS_CLI;
assert(cli && path.isAbsolute(cli) && fs.existsSync(cli), 'Pass the absolute bin/cli.mjs path from an installed skills@1.7.4 package.');
const installed = JSON.parse(fs.readFileSync(path.resolve(cli, '../../package.json')));
assert.equal(installed.version, catalogue.cliVersion, 'Test the documented CLI version.');
const temp = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-cli-')));
function environment(home) {
  return { ...process.env, HOME: home, CODEX_HOME: path.join(home, '.codex'),
    CLAUDE_CONFIG_DIR: path.join(home, '.claude'), XDG_CONFIG_HOME: path.join(home, '.config'),
    XDG_CACHE_HOME: path.join(home, '.cache'), DO_NOT_TRACK: '1', DISABLE_TELEMETRY: '1',
    GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_SYSTEM: '/dev/null', GIT_CONFIG_NOSYSTEM: '1', CI: '1' };
}
function run(args, cwd, env) {
  const result = spawnSync(process.execPath, [cli, ...args], { cwd, env, encoding: 'utf8', timeout: 60000 });
  assert.equal(result.status, 0, `${args.join(' ')}\n${result.error || ''}\n${result.stdout}\n${result.stderr}`);
  return result.stdout;
}
try {
  const rootHome = path.join(temp, 'root-home'), rootProject = path.join(temp, 'root-project');
  fs.mkdirSync(rootHome); fs.mkdirSync(rootProject);
  run(['add', root, '--skill', 'day-one-mac', '--agent', 'codex', '--yes'], rootProject, environment(rootHome));
  validatePackage(path.join(rootProject, '.agents/skills/day-one-mac'));
  console.log('PASS: repository-root discovery selects the portable main package');
  const source = path.join(temp, 'Source é with spaces');
  fs.cpSync(path.join(root, 'skills'), source, { recursive: true });
  let installs = 0;
  for (const global of [false, true]) {
    for (const agent of ['codex', 'github-copilot', 'claude-code']) {
      for (const spec of catalogue.skills) {
        const base = path.join(temp, `${agent}-${global}-${spec.name}`);
        const home = path.join(base, 'home'), project = path.join(base, 'workspace é');
        fs.mkdirSync(home, { recursive: true }); fs.mkdirSync(project);
        fs.mkdirSync(path.join(project, '.claude'));
        const env = environment(home);
        // CLI 1.7.4 copies directly when only one destination is selected.
        const canonicalBase = path.join(global ? home : project, agent === 'claude-code' ? '.claude/skills' : '.agents/skills');
        fs.mkdirSync(path.join(canonicalBase, 'unrelated'), { recursive: true });
        fs.writeFileSync(path.join(canonicalBase, 'unrelated/keep.txt'), 'keep');
        run(['add', source, '--skill', spec.name, '--agent', agent, '--yes', ...(global ? ['--global'] : [])], project, env);
        const folder = path.join(canonicalBase, spec.name);
        validatePackage(folder);
        assert.deepEqual(fs.readdirSync(canonicalBase).sort(), [spec.name, 'unrelated'].sort());
        // Reinstallation is the documented local-source update path.
        run(['add', source, '--skill', spec.name, '--agent', agent, '--yes', ...(global ? ['--global'] : [])], project, env);
        validatePackage(folder);
        // A source checkout can disappear without breaking the installed references.
        fs.renameSync(source, source + '-hidden');
        validatePackage(folder);
        fs.renameSync(source + '-hidden', source);
        run(['remove', spec.name, '--agent', agent, '--yes', ...(global ? ['--global'] : [])], project, env);
        assert(!fs.existsSync(folder), `Removal left ${folder}`);
        assert.equal(fs.readFileSync(path.join(canonicalBase, 'unrelated/keep.txt'), 'utf8'), 'keep');
        installs++;
      }
    }
  }
  for (const global of [false, true]) {
    const base = path.join(temp, `combined-${global}`), home = path.join(base, 'home'), project = path.join(base, 'project');
    fs.mkdirSync(home, { recursive: true }); fs.mkdirSync(project);
    const env = environment(home);
    run(['add', source, '--skill', 'day-one-mac', '--agent', 'codex', 'github-copilot', 'claude-code', '--yes', ...(global ? ['--global'] : [])], project, env);
    const folder = path.join(global ? home : project, '.agents/skills/day-one-mac');
    validatePackage(folder);
    assert.deepEqual(fs.readdirSync(path.dirname(folder)), ['day-one-mac']);
    const link = path.join(global ? home : project, '.claude/skills/day-one-mac');
    assert(fs.lstatSync(link).isSymbolicLink());
    assert.equal(fs.realpathSync(link), fs.realpathSync(folder));
  }
  console.log(`PASS: ${installs} actual Skills CLI installations; ${catalogue.skills.length} skills, three clients, two scopes, reinstall, source removal and bounded uninstall`);
  console.log('PASS: combined-client project/global installs share the main skill through Claude symlinks');
  const gitSource = path.join(temp, 'git-source'), gitProject = path.join(temp, 'git-project'), gitHome = path.join(temp, 'git-home');
  fs.mkdirSync(gitSource); fs.mkdirSync(gitProject); fs.mkdirSync(gitHome);
  fs.cpSync(path.join(source, 'day-one-mac'), path.join(gitSource, 'skills/day-one-mac'), { recursive: true });
  fs.mkdirSync(path.join(gitSource, 'skills/unrelated'));
  fs.writeFileSync(path.join(gitSource, 'skills/unrelated/SKILL.md'), '---\nname: unrelated\ndescription: Unrelated test skill.\n---\nTest fixture.\n');
  fs.writeFileSync(path.join(gitSource, 'skills/unrelated/value.txt'), 'original');
  const env = environment(gitHome);
  const git = args => {
    const result = spawnSync('git', ['-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null', ...args], { cwd: gitSource, env, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  };
  git(['init', '-q']); git(['add', '.']);
  git(['-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.test', 'commit', '-qm', 'fixture']);
  const gitRemote = path.join(temp, 'skills-remote.git');
  git(['clone', '--bare', gitSource, gitRemote]);
  run(['add', `file://${gitRemote}`, '--skill', 'day-one-mac', '--agent', 'codex', '--yes'], gitProject, env);
  run(['add', `file://${gitRemote}`, '--skill', 'unrelated', '--agent', 'codex', '--yes'], gitProject, env);
  validatePackage(path.join(gitProject, '.agents/skills/day-one-mac'));
  console.log('PASS: Git-source installation from a temporary local remote (no GitHub publication claimed)');
  const updated = path.join(gitSource, 'skills/day-one-mac');
  fs.writeFileSync(path.join(updated, 'fixture-marker.txt'), 'reviewed update');
  const manifestPath = path.join(updated, 'bundle.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath));
  manifest.files['fixture-marker.txt'] = crypto.createHash('sha256').update('reviewed update').digest('hex');
  fs.writeFileSync(manifestPath, JSON.stringify(manifest));
  fs.writeFileSync(path.join(gitSource, 'skills/unrelated/value.txt'), 'must not install');
  git(['add', '.']);
  git(['-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.test', 'commit', '-qm', 'reviewed update']);
  git(['push', gitRemote, 'HEAD']);
  const guide = fs.readFileSync(path.join(root, 'docs/setup/manual/ai/day-one-skills.md'), 'utf8');
  const recipe = guide.split('## Update and remove')[1].match(/```bash\n([\s\S]+?)```/)[1].trim().split('\n');
  for (const command of recipe) {
    assert(command.startsWith('npx skills@1.7.4 '));
    run(command.replace('npx skills@1.7.4 ', '').split(/\s+/), gitProject, env);
  }
  validatePackage(path.join(gitProject, '.agents/skills/day-one-mac'));
  assert.equal(fs.readFileSync(path.join(gitProject, '.agents/skills/day-one-mac/fixture-marker.txt'), 'utf8'), 'reviewed update');
  assert.equal(fs.readFileSync(path.join(gitProject, '.agents/skills/unrelated/value.txt'), 'utf8'), 'original', 'Documented update changed an unrelated skill');
  console.log('PASS: documented update recipe changes only the selected skill');
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
