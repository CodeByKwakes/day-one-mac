'use strict';
// Bounded local User-resource replacement. No profile database or extension edits.
const os = require('node:os');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const io = require('../../core/review-io.cjs');
const { fs, path, need, safe, read, digest, writeNew } = io;
const json = value => `${JSON.stringify(value, null, 2)}\n`;
const physical = value => value.replace(/^\/tmp(?=\/|$)/, '/private/tmp').replace(/^\/var(?=\/|$)/, '/private/var');
function snapshot(file) {
  safe(file);
  let stat;
  try { stat = fs.lstatSync(file); } catch (error) { if (error.code === 'ENOENT') return { path: file, exists: false }; throw error; }
  need(stat.isFile() && stat.nlink === 1 && stat.uid === process.getuid(), 'Target must be a regular, singly linked file owned by the current user.');
  const text = read(file), observed = io.fingerprint(file);
  need(digest(text) === observed.sha256 && Buffer.byteLength(text) === observed.bytes, 'Target changed while reading or is not UTF-8.');
  return { path: file, exists: true, mode: stat.mode & 0o777, ...observed,
    dev: stat.dev, ino: stat.ino, mtimeMs: stat.mtimeMs, ctimeMs: stat.ctimeMs };
}
function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }
function matches(actual, desired) {
  return actual.exists === desired.exists && (!actual.exists || (actual.sha256 === desired.sha256 && actual.mode === desired.mode));
}
function targetPaths(home, name, selected) {
  const user = path.join(home, 'Library/Application Support/Code/User');
  const file = selected === undefined ? path.join(user, 'settings.json') : physical(io.absolute(selected));
  const relative = path.relative(user, file).split(path.sep);
  if (name === 'Default') need(relative.length === 1 && relative[0] === 'settings.json', 'Default must target its documented User/settings.json file.');
  else need(selected && relative.length === 3 && relative[0] === 'profiles' && io.plain(relative[1])
    && relative[1] !== '.' && relative[1] !== '..' && relative[2] === 'settings.json',
  'For a named profile, supply --settings-file with its own Code/User/profiles/<id>/settings.json path copied from VS Code.');
  safe(file);
  const parent = fs.statSync(path.dirname(file));
  need(parent.isDirectory() && parent.uid === process.getuid(), 'The profile directory must already exist and belong to the current user.');
  return [file, path.join(path.dirname(file), 'keybindings.json')];
}
function atomic(file, expected, text, mode) {
  need(same(snapshot(file), expected), 'File changed after review; generate a fresh preview.');
  if (text === null) { if (expected.exists) fs.unlinkSync(file); return; }
  const temporary = path.join(path.dirname(file), `.day-one-profile-${crypto.randomBytes(12).toString('hex')}`);
  let created = false;
  try {
    writeNew(temporary, text);
    created = true;
    fs.chmodSync(temporary, mode);
    need(same(snapshot(file), expected), 'File changed while preparing replacement; generate a fresh preview.');
    fs.renameSync(temporary, file);
  } finally { if (created && fs.existsSync(temporary)) fs.unlinkSync(temporary); }
}
function saveRecord(backup, record) {
  const file = path.join(backup, 'record.json');
  const expected = snapshot(file);
  atomic(file, expected, json(record), 0o600);
}
function replacement(root, data, options) {
  const home = physical(io.absolute(os.homedir()));
  safe(home);
  const state = physical(io.absolute(io.command('/bin/bash', ['-c', 'source "$1"; day_one_state_root',
    'profile-state', path.join(root, 'src/core/project-paths.sh')]).trim()));
  const base = path.join(state, 'profile-replacements');
  safe(base);
  need(state !== root && !state.startsWith(root + '/'), 'Profile backups must stay outside the runtime/source directory.');
  const slug = Object.entries({ default: 'Default', 'full-stack': 'Full Stack', ai: 'AI', operations: 'Operations' })
    .find(([, name]) => name === data.name)[0];
  let record, backup, files;
  if (options.restore) {
    backup = physical(io.absolute(options.restore));
    need(path.dirname(backup) === base, 'Restore requires a recorded backup directly inside this state directory\'s profile-replacements folder.');
    safe(backup);
    need((fs.statSync(backup).mode & 0o777) === 0o700, 'Backup directory must remain private (0700).');
    try { record = JSON.parse(read(path.join(backup, 'record.json'))); }
    catch { throw new Error('Cannot read a valid private backup record.'); }
    need(record.version === 1 && record.slug === slug && record.name === data.name
      && Array.isArray(record.files) && record.files.length === 2, 'Invalid backup or profile mismatch.');
    const targets = targetPaths(home, data.name, record.files[0].path);
    files = record.files.map((entry, index) => {
      need(entry.path === targets[index], 'Backup target does not match the selected profile resources.');
      const beforeName = index === 0 ? 'settings.before' : 'keybindings.before';
      const afterName = index === 0 ? 'settings.after' : 'keybindings.after';
      const before = entry.before, after = entry.after;
      need(before && typeof before.exists === 'boolean' && after && after.exists === true
        && Number.isInteger(after.mode) && after.mode === 0o600, 'Invalid backup file metadata.');
      const afterText = read(path.join(backup, afterName));
      need(digest(afterText) === after.sha256 && Buffer.byteLength(afterText) === after.bytes, 'Replacement backup checksum mismatch.');
      let text = null;
      if (before.exists) {
        need(Number.isInteger(before.mode) && before.mode >= 0 && before.mode <= 0o777, 'Invalid original file mode.');
        text = read(path.join(backup, beforeName));
        need(digest(text) === before.sha256 && Buffer.byteLength(text) === before.bytes, 'Original backup checksum mismatch.');
      }
      const current = snapshot(entry.path);
      need(matches(current, before) || matches(current, after), 'Restore refused: a profile file has later edits. Merge its private backup manually.');
      return { path: entry.path, current, desired: before, text };
    });
  } else {
    const targets = targetPaths(home, data.name, options.settingsFile);
    files = targets.map((file, index) => {
      const text = json(index === 0 ? data.settings : data.keybindings);
      return { path: file, current: snapshot(file), desired: { exists: true, mode: 0o600, sha256: digest(text), bytes: Buffer.byteLength(text) }, text };
    });
  }
  const changed = files.filter(file => !matches(file.current, file.desired));
  const intent = { version: 1, action: options.restore ? 'restore' : 'replace', slug,
    backup: backup || null, recordDigest: record ? digest(json(record)) : null,
    files: files.map(({ path: file, current, desired }) => ({ path: file, current, desired })) };
  const hash = digest(json(intent));
  console.log(`${options.restore ? 'Restore' : 'Replace'} settings and shortcuts: ${data.name}`);
  for (const file of files) console.log(`Target: ${file.path} (${matches(file.current, file.desired) ? 'unchanged' : 'will change'})`);
  console.log('Extension inventory and separate account, snippet, task, MCP and layout storage are not edited.');
  console.log('Quit VS Code and pause Settings Sync before approving. Shared Default resources may affect other profiles.');
  if (!changed.length) { console.log(options.restore ? 'Already restored; no writes needed.' : 'Already matches; no writes needed.'); return; }
  console.log(`Approval hash: ${hash}`);
  if (!options.execute || options.dryRun) { console.log('Preview only: no files, backups or locks created.'); return; }
  need(options.approve === hash, 'Approval missing or stale. Preview again and supply --execute --approve <exact hash>.');
  const lock = `${state}.operation.lock`;
  let locked = false;
  if (process.env.DAY_ONE_OPERATION_LOCK === lock && process.env.DAY_ONE_OPERATION_OWNER) {
    try { locked = read(path.join(lock, 'owner'), 64).trim() === process.env.DAY_ONE_OPERATION_OWNER; } catch { /* Acquire through the core supervisor below. */ }
  }
  if (!locked) {
    const run = spawnSync('/bin/bash', [path.join(root, 'src/modules/with-operation-lock.sh'), lock,
      process.execPath, path.join(root, 'src/modules/vscode-profiles/build.cjs'), ...process.argv.slice(2)], { stdio: 'inherit' });
    need(!run.error, 'Could not start the operation lock supervisor.');
    process.exitCode = run.status === null ? 1 : run.status;
    return;
  }
  // Complete recovery evidence is written before either application file changes.
  if (!options.restore) {
    safe(base);
    fs.mkdirSync(base, { recursive: true, mode: 0o700 });
    fs.chmodSync(base, 0o700);
    backup = fs.mkdtempSync(path.join(base, `${slug}-`));
    record = { version: 1, slug, name: data.name, status: 'prepared', createdAt: new Date().toISOString(), files: [] };
    for (const [index, file] of files.entries()) {
      need(same(snapshot(file.path), file.current), 'File changed before backup; generate a fresh preview.');
      const kind = index === 0 ? 'settings' : 'keybindings';
      if (file.current.exists) {
        const original = read(file.path);
        need(digest(original) === file.current.sha256, 'File changed during backup.');
        writeNew(path.join(backup, `${kind}.before`), original);
      }
      writeNew(path.join(backup, `${kind}.after`), file.text);
      record.files.push({ path: file.path, before: file.current, after: file.desired });
    }
    writeNew(path.join(backup, 'record.json'), json(record));
  }
  try {
    for (const file of changed) atomic(file.path, file.current, file.text, file.desired.mode);
    for (const file of files) need(matches(snapshot(file.path), file.desired), 'Post-write verification failed.');
    record.status = options.restore ? 'restored' : 'replaced';
    saveRecord(backup, record);
  } catch (error) {
    console.error(`Recovery backup retained: ${backup}`);
    throw error;
  }
  console.log(`Backup: ${backup}`);
  console.log(options.restore ? 'Original files restored; originally absent files are absent again.' : 'Settings and shortcuts replaced. Use --restore <backup> to preview recovery.');
}
module.exports = { replacement };
