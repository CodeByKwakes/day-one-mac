#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const source = path.join(root, 'integrations/shortcuts/send-to-archive.applescript');
assert(fs.existsSync(source), 'Portable archive source must exist');
assert(!/\/Users\/|shortcutIdentifier/.test(fs.readFileSync(source, 'utf8')));
const { catalogue, plan } = require('../../helpers/shortcuts/build.cjs');
const entry = catalogue(root).quickActions.find(item => item.id === 'send-to-archive');
assert.equal(entry.format, 'automator-quick-action');
assert.deepEqual(entry.sources, ['send-to-archive.applescript']);
assert(!plan(root, 'all', path.join(os.tmpdir(), `archive-preview-${process.pid}`)).recipes.some(item => item.id === entry.id), 'The app builder must not compile a Finder service as an app');
if (process.platform !== 'darwin') {
  console.log('SKIP: archive compilation and Foundation fixtures require macOS');
  process.exit(0);
}
const temp = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-archive-')));
const literal = value => '"' + value.replaceAll('\\', '\\\\').replaceAll('"', '\\"') + '"';
const list = values => '{' + values.map(literal).join(', ') + '}';
try {
  const compiled = path.join(temp, 'archive.scpt');
  const compile = spawnSync('/usr/bin/osacompile', ['-o', compiled, source], { encoding: 'utf8' });
  assert.equal(compile.status, 0, compile.stderr);
  const call = (expression, fail = false) => {
    const result = spawnSync('/usr/bin/osascript', ['-'], {
      input: `set fixture to load script POSIX file ${literal(compiled)}\nreturn ${expression}\n`,
      encoding: 'utf8', timeout: 30000,
    });
    assert.equal(result.status === 0, !fail, result.stdout + result.stderr);
    return result.stdout.trim();
  };
  const archive = path.join(temp, 'Archive'); fs.mkdirSync(archive);
  const category = 'Projects é';
  const day = path.join(archive, category, '2026-10-27');
  const folder = name => { const p = path.join(temp, name); fs.mkdirSync(p); return p; };
  const one = folder("Project one's é $(literal)");
  const two = folder('Project Two');
  fs.writeFileSync(path.join(one, 'keep.txt'), 'one');
  fs.mkdirSync(path.join(two, '.git'));
  fs.writeFileSync(path.join(two, '.git/HEAD'), 'ref: refs/heads/main\n');
  const invoke = (method, paths, cat = category, date = '2026-10-27', fail = false) => call(`fixture's ${method}(${list(paths)}, ${literal(archive)}, ${literal(cat)}, ${literal(date)})`, fail);
  invoke('planMoves', [one, two]);
  assert(!fs.existsSync(day), 'Planning and cancellation before confirmation create nothing');
  invoke('executeMoves', [one, two]);
  assert(!fs.existsSync(one) && !fs.existsSync(two));
  assert.equal(fs.readFileSync(path.join(day, path.basename(one), 'keep.txt'), 'utf8'), 'one');
  assert.equal(fs.readFileSync(path.join(day, path.basename(two), '.git/HEAD'), 'utf8'), 'ref: refs/heads/main\n');
  const records = () => fs.readdirSync(day).filter(name => /^\.archive-move-.*\.json$/.test(name));
  assert.equal(records().length, 1);
  const recordPath = path.join(day, records()[0]);
  const record = JSON.parse(fs.readFileSync(recordPath));
  // Foundation may render /private/tmp as /tmp; both refer to the same parent.
  const physical = value => path.join(fs.realpathSync(path.dirname(value)), path.basename(value));
  assert.deepEqual(record.originalFolders.map(physical), [one, two]);
  assert.equal(record.completedMoves.length, 2);
  assert.equal(fs.statSync(recordPath).mode & 0o777, 0o600);
  fs.mkdirSync(one); fs.writeFileSync(path.join(one, 'keep.txt'), 'new');
  invoke('planMoves', [one], category, '2026-10-27', true);
  assert.equal(fs.readFileSync(path.join(one, 'keep.txt'), 'utf8'), 'new');
  const parent = folder('Parent'); const child = path.join(parent, 'Child'); fs.mkdirSync(child);
  for (const paths of [[parent, child], [archive], [temp], []]) invoke('planMoves', paths, category, '2026-10-27', true);
  const file = path.join(temp, 'file.txt'); fs.writeFileSync(file, 'keep');
  invoke('planMoves', [file], category, '2026-10-27', true);
  for (const cat of ['../escape', 'a/b', '.hidden', 'a:b', '']) invoke('planMoves', [parent], cat, '2026-10-27', true);
  for (const date of ['../escape/', '2026/10/27', 'xxxxxxxxxx']) invoke('planMoves', [parent], category, date, true);
  const worktree = folder('Linked worktree'); fs.writeFileSync(path.join(worktree, '.git'), 'gitdir: /missing/example\n');
  const main = folder('Main repo'); fs.mkdirSync(path.join(main, '.git/worktrees'), { recursive: true });
  for (const p of [worktree, main]) invoke('planMoves', [p], category, '2026-10-27', true);
  const link = path.join(temp, 'Alias'); fs.symlinkSync(parent, link);
  assert.equal(call(`fixture's selectionPaths({POSIX file ${literal(link)}})`), link, 'Input conversion must preserve a selected symlink path');
  call(`fixture's planMoves(fixture's selectionPaths({POSIX file ${literal(link)}}), ${literal(archive)}, ${literal(category)}, "2026-10-27")`, true);
  invoke('planMoves', [link], category, '2026-10-27', true);
  fs.symlinkSync(parent, path.join(archive, 'Outside'));
  invoke('planMoves', [parent], 'Outside', '2026-10-27', true);
  const other = folder('Other'); const duplicate = path.join(other, path.basename(one)); fs.mkdirSync(duplicate);
  invoke('planMoves', [one, duplicate], category, '2026-10-27', true);
  invoke('executeMoves', [parent]);
  assert(fs.existsSync(path.join(day, 'Parent/Child')));
  assert.equal(records().length, 2);
  const drift = folder('Drift');
  const identity = call(`fixture's folderIdentity(${literal(drift)})`);
  call(`fixture's verifyFolderIdentity(${literal(drift)}, ${literal(identity)})`);
  fs.renameSync(drift, drift + '-original'); fs.mkdirSync(drift);
  call(`fixture's verifyFolderIdentity(${literal(drift)}, ${literal(identity)})`, true);
  if (process.getuid() !== 0) {
    const first = folder('FirstPartial');
    const locked = folder('Locked'); const second = path.join(locked, 'SecondPartial'); fs.mkdirSync(second);
    fs.chmodSync(locked, 0o500);
    try {
      invoke('executeMoves', [first, second], category, '2026-10-27', true);
      assert(!fs.existsSync(first) && fs.existsSync(path.join(day, 'FirstPartial')));
      assert(fs.existsSync(second) && !fs.existsSync(path.join(day, 'SecondPartial')));
      const partial = records().map(name => JSON.parse(fs.readFileSync(path.join(day, name)))).find(record => record.originalFolders[0].endsWith('/FirstPartial'));
      assert(partial, 'A partial move must retain its recovery record');
      assert.equal(partial.originalFolders.length, 2);
      assert.equal(partial.completedMoves.length, 1);
    } finally { fs.chmodSync(locked, 0o700); }
  }
  console.log('PASS: archive preview, Unicode/quoting, multi-folder moves, recovery records, collisions, containment, dates, symlinks and Git worktree guards; no UI or real projects used');
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
