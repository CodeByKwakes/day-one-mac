'use strict';
// Contributor-only helpers: never included in the installed runtime.
const { fs, path, need, safe, fingerprint, digest } = require('./review-io.cjs');
const { spawnSync } = require('node:child_process');
const project = path.resolve(__dirname, '../..');
function cleanEnv(home, state) {
  const env = { ...process.env };
  for (const key of Object.keys(env)) {
    if (/^(GIT_|DAY_ONE_|FRESH_START_|NODE_)/.test(key)) delete env[key];
  }
  return { ...env, HOME: home, XDG_CONFIG_HOME: path.join(home, '.config'), XDG_DATA_HOME: path.join(home, '.local/share'), XDG_CACHE_HOME: path.join(home, '.cache'), DAY_ONE_MAC_STATE_ROOT: state, DAY_ONE_MAC_STATE_DIR: state, NODE_DISABLE_COMPILE_CACHE: '1', NO_COLOR: '1' };
}
function execute(program, args, options = {}) {
  const { expected = 0, ...rest } = options;
  const r = spawnSync(program, args, { cwd: project, encoding: 'utf8', timeout: 120000, maxBuffer: 8 * 1024 * 1024, ...rest });
  need(!r.error && r.status === expected, `${path.basename(program)} failed: expected ${expected}, got ${r.status}.\n${r.stderr || ''}${r.stdout || ''}${r.error?.message || ''}`);
  return r.stdout || '';
}
function write(file, value) {
  safe(file); fs.mkdirSync(path.dirname(file), { recursive: true, mode: 0o700 });
  fs.writeFileSync(file, value, { flag: 'wx', mode: 0o600 });
}
function newOutput(directory) {
  safe(directory); need(!fs.existsSync(directory), 'Output must be a NEW directory; existing evidence is never overwritten.');
  fs.mkdirSync(directory, { mode: 0o700 });
}
function installCandidate(root, archiveInput) {
  const home = path.join(root, 'home'), state = path.join(root, 'state'), release = path.join(root, 'release');
  const env = cleanEnv(home, state);
  fs.mkdirSync(home, { mode: 0o700 });
  if (!archiveInput) execute(path.join(project, 'scripts/build-release.sh'), [release], { env });
  const archive = archiveInput ? safe(archiveInput) : path.join(release, 'day-one-mac-runtime.tar.gz');
  execute(path.join(project, 'install-day-one-mac'), ['--archive', archive], { env });
  const cli = path.join(home, '.local/bin/day-one-mac');
  execute(cli, ['verify'], { env });
  const runtime = fs.realpathSync(path.join(home, '.local/share/day-one-mac/current'));
  return { home, state, env, cli, runtime, archive, archiveSha256: fingerprint(archive).sha256 };
}
function stateSnapshot(root) {
  if (!fs.existsSync(root)) return 'absent';
  function walk(dir) {
    return fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name)).flatMap(entry => {
      const file = path.join(dir, entry.name); safe(file);
      return entry.isDirectory() ? walk(file) : [[path.relative(root, file), fingerprint(file).sha256]];
    });
  }
  return digest(JSON.stringify(walk(root)));
}
module.exports = { fs, path, need, safe, project, cleanEnv, execute, write, newOutput, installCandidate, stateSnapshot, fingerprint, digest };
