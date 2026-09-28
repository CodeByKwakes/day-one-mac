'use strict';
const { fs, path, need, execute, write, installCandidate, stateSnapshot } = require('../lib/acceptance-helpers.cjs');
const root = fs.mkdtempSync('/private/tmp/day-one-packaged-acceptance.');
try {
  need(process.argv.length === 2 || (process.argv.length === 4 && process.argv[2] === '--archive'), 'Only --archive ABSOLUTE-PATH is supported.');
  const { cli, runtime, state, env } = installCandidate(root, process.argv[3]);
  const run = (args, expected = 0) => execute(cli, args, { env, cwd: root, expected });
  const git = args => execute('git', ['-c', 'core.hooksPath=/dev/null', ...args], { env, cwd: root });
  const modules = run(['optional', '--list']).trim().split('\n').slice(1).map(row => row.split('\t'));
  need(modules.length === 15 && modules.every(row => row[2] === 'executable'), 'Packaged capability registry is incomplete.');
  need(!fs.existsSync(path.join(runtime, 'node_modules')) && !fs.existsSync(path.join(runtime, '.git')), 'Package contains development dependencies or Git metadata.');
  const repos = path.join(root, 'repositories'), repo = path.join(repos, 'primary'), linked = path.join(repos, 'linked');
  git(['-c', 'init.templateDir=', 'init', '-q', repo]);
  git(['-C', repo, 'config', 'user.name', 'Packaged Fixture']);
  git(['-C', repo, 'config', 'user.email', 'packaged@example.test']);
  git(['-C', repo, 'config', 'commit.gpgsign', 'false']);
  git(['-C', repo, 'commit', '-q', '--allow-empty', '-m', 'fixture']);
  git(['-C', repo, 'worktree', 'add', '-q', '-b', 'linked-fixture', linked]);
  const identities = path.join(root, 'identities.tsv'), helpers = path.join(root, 'helpers.tsv'), restore = path.join(root, 'restore.tsv');
  write(identities, [repo, linked].map(checkout => `repository\t${checkout}\tPackaged Fixture\tpackaged@example.test\toff\t${repos}`).join('\n') + '\n');
  write(helpers, 'helper\tnavigation\nhelper\tpackages\n');
  write(restore, 'mode\tno-restore\n');
  const installedState = stateSnapshot(state);
  need(run(['--version']).trim() === `day-one-mac ${fs.readFileSync(path.join(runtime, 'VERSION'), 'utf8').trim()}`, 'Packaged version is incorrect.');
  const requiredPlan = JSON.parse(run(['setup', '--plan', '--track', '1', '--stack', 'both', '--json']));
  need(requiredPlan.schema_version === 1 && requiredPlan.phases.length === 8, 'Packaged required-phase plan is incomplete.');
  const requiredCheck = JSON.parse(run(['setup', '--check', '--phase', '05', '--track', '1', '--stack', 'both', '--json'], 11));
  need(requiredCheck.phases[0].live === 'fail' && requiredCheck.checked_at, 'Packaged checks must detect the empty fixture home.');
  need(stateSnapshot(state) === installedState, 'Packaged required-phase inspection changed installer state.');
  for (const [id, manifest] of [['17', helpers], ['18', identities], ['20', restore]]) run(['advanced', '--module', id, '--plan', '--manifest', manifest]);
  need(stateSnapshot(state) === installedState, 'Packaged plans changed installer state.');
  run(['advanced', '--module', '20', '--apply', '--manifest', restore, '--yes'], 10);
  // These markers are fixture-only, not evidence that machine onboarding ran.
  for (const phase of ['01','02','03','04','05','06','07','08']) write(path.join(state, 'completed', phase), 'acceptance fixture only\n');
  for (const [id, manifest] of [['17', helpers], ['18', identities], ['20', restore]]) {
    run(['advanced', '--module', id, '--apply', '--manifest', manifest, '--yes']);
    run(['advanced', '--module', id, '--check']);
    run(['advanced', '--module', id, '--resume', '--yes']);
  }
  git(['-C', repo, 'config', 'user.email', 'drift@example.test']);
  run(['advanced', '--module', '18', '--check'], 1);
  git(['-C', repo, 'config', 'user.email', 'packaged@example.test']);
  run(['advanced', '--module', '21', '--apply', '--yes']);
  run(['advanced', '--module', '21', '--check']);
  const before = stateSnapshot(state);
  const dashboard = run(['optional', '--status']);
  for (const id of ['17','18','20','21']) need(new RegExp(`partial +${id} —`).test(dashboard), 'Package claimed manual work was complete.');
  need(stateSnapshot(state) === before, 'Packaged dashboard changed setup state.');
  run(['verify']);
  console.log('PASS: archive installation, 15 capabilities, packaged Node helpers, plan/apply/check/resume, drift and bounded audit');
} finally { fs.rmSync(root, { recursive: true, force: true }); }
