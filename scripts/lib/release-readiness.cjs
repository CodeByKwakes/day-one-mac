'use strict';
const { fs, path, need, safe, project, execute, newOutput, fingerprint, digest } = require('./acceptance-helpers.cjs');
const { spawnSync } = require('node:child_process');
const crypto = require('node:crypto');
function parse(args) {
  const options = { native: false };
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (['--plan','--run','--help'].includes(arg) && !options.action) options.action = arg;
    else if (arg === '--native-volume' && !options.native) options.native = true;
    else if (arg === '--output-dir' && !options.output && args[i + 1] && !args[i + 1].startsWith('--')) options.output = args[++i];
    else throw new Error('Choose one action, one output directory, and optional --native-volume.');
  }
  need(options.action, 'Choose --plan or --run.');
  need(options.action !== '--run' || options.output, 'Run requires --output-dir NEW-ABSOLUTE-DIRECTORY.');
  return options;
}
function summarize(gates, clean, unchanged) {
  const automatedPassed = ['build','lint','workflow-lint','validation','packaged-runtime'].every(id => gates.some(g => g.id === id && g.status === 'passed'));
  const nativePassed = gates.some(g => g.id === 'native-volume' && g.status === 'passed');
  return { automatedPassed, nativePassed, sourceClean: clean, sourceUnchanged: unchanged,
    candidateChecksPassed: automatedPassed && nativePassed && clean && unchanged,
    releaseApproved: false,
    remainingManual: ['Fresh-user required Phases 1–8 rehearsal', 'Account authentication, trust, signing and GUI checks', 'Review candidate release notes and tested commit', 'Normal protected-branch CI and Release Please publication'] };
}
function sourceState() {
  const gitEnv = { ...process.env, GIT_OPTIONAL_LOCKS: '0' };
  for (const key of Object.keys(gitEnv)) if (key.startsWith('GIT_') && key !== 'GIT_OPTIONAL_LOCKS') delete gitEnv[key];
  const git = args => execute('git', ['-c', 'core.fsmonitor=false', ...args], { env: gitEnv });
  const files = git(['ls-files', '-z', '--cached', '--others', '--exclude-standard']).split('\0').filter(Boolean);
  // Local agent skills are not candidate runtime/test inputs. Report their dirty
  // status, but do not open potentially private skill trees for a code digest.
  const relevant = [...new Set(files)].filter(file => !/^\.(agents|claude)\//.test(file) && file !== 'skills-lock.json').sort();
  const records = relevant.map(file => {
    const absolute = path.join(project, file);
    try {
      const stat = fs.lstatSync(absolute);
      if (stat.isSymbolicLink()) return [file, 'symlink', fs.readlinkSync(absolute)];
      if (!stat.isFile()) return [file, 'non-regular'];
      return [file, stat.mode & 0o777, fingerprint(absolute).sha256];
    } catch (error) { if (error.code === 'ENOENT') return [file, 'missing']; throw error; }
  });
  return { head: git(['rev-parse','HEAD']).trim(), clean: git(['status','--porcelain','--untracked-files=normal']).trim() === '', digest: digest(JSON.stringify(records)) };
}
function save(output, report) {
  const summary = summarize(report.gates, report.sourceBefore?.clean === true && report.sourceAfter?.clean === true,
    !!report.sourceAfter && report.sourceBefore.digest === report.sourceAfter.digest && report.sourceBefore.head === report.sourceAfter.head);
  report.summary = summary;
  for (const [name, content] of [
    ['report.json', JSON.stringify(report, null, 2) + '\n'],
    ['report.md', '# Candidate release readiness\n\n' +
      `Commit: \`${report.sourceBefore?.head || 'unavailable'}\`\n\n` +
      '| Gate | Result | Log |\n|---|---|---|\n' + report.gates.map(g => `| ${g.id} | ${g.status} | ${g.log || 'not run'} |`).join('\n') +
      `\n\nAutomated checks passed: ${summary.automatedPassed}. Native volume passed: ${summary.nativePassed}.\n\nSource clean: ${summary.sourceClean}. Source unchanged during run: ${summary.sourceUnchanged}.\n\nCandidate checks passed: ${summary.candidateChecksPassed}. Release approved: **no**.\n\n` +
      '## Remaining human checks\n\n' + summary.remainingManual.map(line => `- ${line}`).join('\n') + '\n']
  ]) {
    const target = safe(path.join(output, name)), temporary = path.join(output, `.report-${crypto.randomUUID()}`);
    fs.writeFileSync(temporary, content, { flag: 'wx', mode: 0o600 }); fs.renameSync(temporary, target);
  }
}
function main(args) {
  const options = parse(args);
  const names = ['build','lint','workflow-lint','validation','packaged-runtime','native-volume'];
  if (options.action === '--help') { console.log('Usage: release-readiness.sh --plan|--run [--output-dir NEW-ABSOLUTE-DIRECTORY] [--native-volume]\nContributor-only; no publishing, package installation or live onboarding.'); return; }
  if (options.action === '--plan') {
    console.log(`Plan only; no files or locks created.\nGates: ${names.join(', ')}.\nNative volume: ${options.native ? 'explicitly selected; creates and detaches a disposable APFS image' : 'not selected; report will mark it skipped'}.\nRun keeps private logs, exact candidate archive/checksum, JSON and Markdown reports. Existing output directories are refused. Requires existing Node 22+, pnpm dependencies, actionlint, rg and ShellCheck. Manual setup checks and release approval are never inferred.`); return;
  }
  need(Number(process.versions.node.split('.')[0]) >= 22, 'Node 22+ is required.');
  safe(options.output);
  need(options.output !== project && !options.output.startsWith(project + '/'), 'Keep acceptance output outside the source checkout.');
  newOutput(options.output);
  const report = { schema: 1, started: new Date().toISOString(), gates: names.map(id => ({ id, status: 'pending' })) };
  const archive = path.join(options.output, 'release/day-one-mac-runtime.tar.gz');
  const commands = {
    build: [path.join(project, 'scripts/build-release.sh'), [path.join(options.output, 'release')]],
    lint: ['pnpm', ['run','lint']],
    'workflow-lint': ['actionlint', []],
    validation: [path.join(project, 'scripts/validate.sh'), []],
    'packaged-runtime': [path.join(project, 'scripts/tests/test-packaged-modules.sh'), ['--archive',archive]],
    'native-volume': [path.join(project, 'scripts/rehearse-mounted-restore.sh'), ['--run','--output-dir',path.join(options.output, 'native-volume'),'--archive',archive]]
  };
  try {
    report.sourceBefore = sourceState(); save(options.output, report);
    for (const gate of report.gates) {
      if (gate.id === 'native-volume' && !options.native) { gate.status = 'skipped'; save(options.output, report); continue; }
      if (['packaged-runtime','native-volume'].includes(gate.id) && report.gates[0].status !== 'passed') { gate.status = 'blocked'; save(options.output, report); continue; }
      gate.status = 'running'; gate.log = `${gate.id}.log`; save(options.output, report);
      console.log(`Running ${gate.id}; log: ${path.join(options.output, gate.log)}`);
      const fd = fs.openSync(path.join(options.output, gate.log), 'wx', 0o600);
      let result;
      try { result = spawnSync(commands[gate.id][0], commands[gate.id][1], { cwd: project, env: process.env, stdio: ['ignore',fd,fd], timeout: 30 * 60 * 1000 }); }
      finally { fs.closeSync(fd); }
      gate.status = !result.error && result.status === 0 ? 'passed' : 'failed';
      gate.exitCode = result.status; if (result.error) gate.error = result.error.message;
      if (gate.id === 'build' && gate.status === 'passed') report.archive = { path: archive, sha256: fingerprint(archive).sha256 };
      save(options.output, report); console.log(`${gate.id}: ${gate.status}`);
    }
    report.sourceAfter = sourceState(); report.finished = new Date().toISOString(); save(options.output, report);
    need(report.summary.sourceUnchanged, 'Candidate source changed during acceptance; rerun against one stable revision.');
    const failed = report.gates.some(gate => ['failed','blocked'].includes(gate.status));
    process.exitCode = failed ? 1 : 0;
    console.log(`Evidence: ${options.output}\nCandidate checks passed: ${report.summary.candidateChecksPassed}. Release approval remains manual.`);
  } catch (error) { report.error = error.message; save(options.output, report); throw error; }
}
module.exports = { parse, summarize, sourceState };
if (require.main === module) { try { main(process.argv.slice(2)); } catch (error) { console.error(error.message); process.exitCode = 1; } }
