'use strict';
const { fs, path, need, execute, write, newOutput, installCandidate, stateSnapshot, digest } = require('./acceptance-helpers.cjs');
const crypto = require('node:crypto');
let action, output, archive;
for (let i = 2; i < process.argv.length; i++) {
  const arg = process.argv[i];
  if (['--plan','--run','--help'].includes(arg) && !action) action = arg;
  else if (arg === '--output-dir' && !output && process.argv[i + 1]) output = process.argv[++i];
  else if (arg === '--archive' && !archive && process.argv[i + 1]) archive = process.argv[++i];
  else { console.error('Choose --plan or --run, with --output-dir NEW-ABSOLUTE-DIRECTORY for run.'); process.exit(2); }
}
if (action === '--help') { console.log('Usage: rehearse-mounted-restore.sh --plan|--run [--output-dir NEW-ABSOLUTE-DIRECTORY] [--archive LOCAL-CANDIDATE]\nCreates one disposable APFS disk image; never accepts an existing disk or backup.'); process.exit(0); }
if (!action || (action === '--run' && !output)) { console.error('A run requires a new output directory.'); process.exit(2); }
if (action === '--plan') {
  console.log('Plan only: build/install candidate into disposable HOME; create a 64 MiB APFS disk image in the new output directory; mount at a unique /Volumes/DayOneAcceptance-* path; exercise Module 20 checksummed staging, missing-file resume, source/destination conflicts and offline-source refusal; detach only that image. No live backup, user configuration or credentials are used. Image and evidence are retained; no force-detach or recursive cleanup.');
  process.exit(0);
}
let image, mount, diskAttached = false, interrupted = false, ownsOutput = false;
const result = { schema: 1, scope: 'disposable-apfs-restore-rehearsal', status: 'running', cleanup: 'not-started', checks: [] };
function jsonPlist(xml) { return JSON.parse(execute('/usr/bin/plutil', ['-convert', 'json', '-o', '-', '-'], { input: xml })); }
function matchingImage() {
  const info = jsonPlist(execute('/usr/bin/hdiutil', ['info', '-plist']));
  return (info.images || []).find(entry => entry['image-path'] === image);
}
function detachOwned() {
  if (!image) return;
  const owned = matchingImage();
  if (!owned) { diskAttached = false; result.cleanup = 'detached'; return; }
  const entity = (owned['system-entities'] || []).find(entry => entry['mount-point'] === mount);
  need(entity && /^\/dev\/disk\d+(s\d+)*$/.test(entity['dev-entry']), 'Cannot safely identify the owned image mount; retain it for manual cleanup.');
  execute('/usr/bin/hdiutil', ['detach', entity['dev-entry']]);
  need(!matchingImage(), 'Disk image remains attached; preserve evidence and detach it manually.');
  diskAttached = false; result.cleanup = 'detached';
}
function save() { fs.writeFileSync(path.join(output, 'native-result.json'), JSON.stringify(result, null, 2) + '\n', { mode: 0o600 }); }
for (const signal of ['SIGINT','SIGTERM','SIGHUP']) process.once(signal, () => {
  interrupted = true; result.status = 'interrupted';
  try { detachOwned(); } catch (e) { result.cleanup = 'manual-required'; result.cleanupError = e.message; }
  if (ownsOutput) save();
  process.exit(signal === 'SIGINT' ? 130 : 143);
});
try {
  need(Number(process.versions.node.split('.')[0]) >= 22, 'Node 22+ is required.');
  need(process.platform === 'darwin' && process.arch === 'arm64', 'Native Apple-silicon macOS is required; no platform simulation is accepted.');
  newOutput(output); ownsOutput = true;
  write(path.join(output, 'native-result.json'), JSON.stringify(result) + '\n');
  const candidate = installCandidate(output, archive);
  result.archiveSha256 = candidate.archiveSha256;
  result.osVersion = execute('/usr/bin/sw_vers', ['-productVersion']).trim();
  result.arch = process.arch;
  const run = (args, expected = 0) => execute(candidate.cli, args, { env: candidate.env, cwd: output, expected });
  image = path.join(output, 'fixture.dmg');
  mount = `/Volumes/DayOneAcceptance-${crypto.randomUUID()}`;
  need(!fs.existsSync(mount), 'Generated mount path already exists.');
  result.image = image; result.mount = mount; save();
  execute('/usr/bin/hdiutil', ['create', '-size', '64m', '-fs', 'APFS', '-volname', path.basename(mount), image]);
  diskAttached = true; // Cleanup also inspects hdiutil info after a partial attach.
  const attached = jsonPlist(execute('/usr/bin/hdiutil', ['attach', image, '-nobrowse', '-noautoopen', '-mountpoint', mount, '-plist']));
  need((attached['system-entities'] || []).some(entry => entry['mount-point'] === mount), 'Image mounted at an unexpected location.');
  const one = 'Disposable acceptance document one\n', two = 'Disposable acceptance document two\n';
  write(path.join(mount, 'exports/one.txt'), one); write(path.join(mount, 'exports/two.txt'), two);
  const manifest = path.join(output, 'restore.tsv');
  write(manifest, `source\t${mount}/exports\nfile\tone.txt\tone.txt\t${digest(one)}\nfile\ttwo.txt\ttwo.txt\t${digest(two)}\n`);
  const installedState = stateSnapshot(candidate.state);
  run(['advanced','--module','20','--plan','--manifest',manifest]);
  need(stateSnapshot(candidate.state) === installedState, 'Plan changed installer state.'); result.checks.push('read-only-plan');
  run(['advanced','--module','20','--apply','--manifest',manifest,'--yes'], 10); result.checks.push('phase-8-gate');
  write(path.join(candidate.state, 'completed/08'), 'native fixture only; not a machine verification\n');
  run(['advanced','--module','20','--apply','--manifest',manifest,'--yes']); run(['advanced','--module','20','--check']);
  const session = fs.readFileSync(path.join(candidate.state, 'restore-20-current'), 'utf8').split('\t')[0];
  const staging = path.join(candidate.state, 'module-runs/20', session, 'staging/files');
  need(fs.readFileSync(path.join(staging, 'one.txt'), 'utf8') === one, 'Native file transfer differs.'); result.checks.push('native-mounted-copy-and-check');
  const before = stateSnapshot(candidate.state); run(['advanced','--module','20','--check']);
  need(stateSnapshot(candidate.state) === before, 'Check changed setup state.'); result.checks.push('read-only-check');
  // Move only this fixture's staged file, preserving it as evidence of a missing target.
  fs.renameSync(path.join(staging, 'two.txt'), path.join(output, 'preserved-two.txt'));
  run(['advanced','--module','20','--check'], 1); run(['advanced','--module','20','--resume','--yes']); result.checks.push('missing-target-resume');
  fs.writeFileSync(path.join(staging, 'two.txt'), 'fixture destination conflict');
  run(['advanced','--module','20','--resume','--yes'], 1);
  need(fs.readFileSync(path.join(staging, 'two.txt'), 'utf8') === 'fixture destination conflict', 'Conflict was overwritten.'); result.checks.push('destination-conflict-preserved');
  fs.writeFileSync(path.join(mount, 'exports/one.txt'), 'fixture source drift');
  run(['advanced','--module','20','--check'], 1); result.checks.push('source-drift-refused');
  detachOwned(); run(['advanced','--module','20','--check'], 1); result.checks.push('unmounted-source-refused');
  result.status = 'passed';
} catch (error) { result.status = 'failed'; result.error = error.message; console.error(error.message); process.exitCode = 1; }
finally {
  if (!interrupted && diskAttached) { try { detachOwned(); } catch (error) { result.status = 'failed'; result.cleanup = 'manual-required'; result.cleanupError = error.message; process.exitCode = 1; } }
  if (ownsOutput) { save(); console.log(`Native rehearsal: ${result.status}; cleanup: ${result.cleanup}\nEvidence retained: ${output}`); }
}
