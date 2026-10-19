'use strict';
// Explicit regular-file restore only. Never interprets archives, SQL or scripts.
const { fs, path, need, safe, read, digest, fingerprint, rows, command, writeNew, openFile } = require('./review-io.cjs');
const crypto = require('node:crypto');
const [action, input, extra, manifest] = process.argv.slice(2);
function relative(value) {
  need(typeof value === 'string' && value.length > 0 && !/[\x00-\x1f\x7f\\]/.test(value) && !path.isAbsolute(value) && path.normalize(value) === value && value !== '.' && !value.startsWith('../') && !value.endsWith('/'), 'Use a plain relative file path without traversal.');
  // No hidden state, credentials, package trees or runtime storage in this scope.
  const excluded = /^(node_modules|venv|virtualenv|__pycache__|Cellar|Caskroom|Library|Caches|Keychains)$/i;
  need(value.split('/').every(part => !part.startsWith('.') && !excluded.test(part)), 'Hidden files, credential/state paths and package/cache trees are excluded from staging.');
  need(!/\.(pem|key|p12|pfx|kdbx|keychain|keychain-db)$/i.test(value) && !/^id_(rsa|dsa|ecdsa|ed25519)$/.test(path.basename(value)), 'Private-key and credential-container files are excluded.');
  return value;
}
function selection(text) {
  const selected = rows(text);
  if (selected.length === 1 && selected[0].join('\t') === 'mode\tno-restore') return { version: 1, mode: 'no-restore' };
  need(selected[0].length === 2 && selected[0][0] === 'source', 'Start with source<TAB>absolute backup root, or mode<TAB>no-restore alone.');
  const source = safe(selected[0][1]);
  need(source.startsWith('/Volumes/'), 'Backup root must be on an explicitly mounted volume under /Volumes.');
  const belowVolume = source.split('/').slice(3).join('/');
  if (belowVolume) relative(belowVolume);
  const files = selected.slice(1).map(row => {
    need(row.length === 4 && row[0] === 'file' && /^[a-f0-9]{64}$/.test(row[3]), 'Each file needs relative source, relative staging target and lowercase SHA-256.');
    return { source: relative(row[1]), target: relative(row[2]), sha256: row[3] };
  });
  need(files.length > 0, 'Select at least one checksummed file.');
  const sources = new Set(), targets = new Set();
  for (const file of files) {
    // Unicode/case-fold collision guard is deliberately conservative for macOS.
    const key = file.target.normalize('NFD').toLowerCase();
    need(!sources.has(file.source) && !targets.has(key), 'Duplicate source or colliding staging target.');
    for (const other of targets) need(!other.startsWith(key + '/') && !key.startsWith(other + '/'), 'File/directory staging target collision.');
    sources.add(file.source); targets.add(key);
  }
  return { version: 1, mode: 'stage', source, files };
}
function mountIdentity(source) {
  safe(source); need(fs.statSync(source).isDirectory(), 'Backup root is not a directory.');
  // POSIX df retains the whole mount path (including spaces) after capacity.
  const lines = command('df', ['-P', source], { env: { ...process.env, LC_ALL: 'C' } }).trimEnd().split('\n');
  const match = lines.at(-1).match(/^(.+?)\s+\d+\s+\d+\s+\d+\s+\d+%\s+(.+)$/);
  need(match, 'Cannot identify the mounted source using df -P.');
  const mount = safe(match[2]);
  need(mount.startsWith('/Volumes/') && (source === mount || source.startsWith(mount + '/')), 'Source is not on a mounted backup volume under /Volumes.');
  const root = fs.statSync(source), mounted = fs.statSync(mount);
  need(root.dev === mounted.dev, 'Backup root and selected mount differ.');
  return { filesystem: match[1], mount, device: root.dev, rootInode: root.ino };
}
function prepare(selected) {
  if (selected.mode === 'no-restore') return selected;
  const mount = mountIdentity(selected.source);
  const files = selected.files.map(file => {
    const observed = fingerprint(path.join(selected.source, file.source));
    need(observed.sha256 === file.sha256, `Source checksum mismatch: ${file.source}`);
    return { ...file, bytes: observed.bytes };
  });
  return { ...selected, mount, files, totalBytes: files.reduce((n, f) => n + f.bytes, 0) };
}
function separate(selected, destination) {
  safe(destination);
  if (selected.mode === 'stage') need(destination !== selected.source && !destination.startsWith(selected.source + '/') && !selected.source.startsWith(destination + '/'), 'Restore state/staging and backup source must not overlap.');
}
function intentAt(session, expected) {
  safe(session);
  need(/^[a-f0-9]{64}$/.test(expected), 'Invalid saved intent hash.');
  const text = read(path.join(session, 'intent.json'));
  need(digest(text) === expected, 'Restore intent integrity failed. Preserve the session for review.');
  const intent = JSON.parse(text);
  // Validate schema through the same parser, never trust saved paths as commands.
  const canonical = intent.mode === 'no-restore' ? 'mode\tno-restore' : `source\t${intent.source}\n${intent.files.map(f => `file\t${f.source}\t${f.target}\t${f.sha256}`).join('\n')}`;
  const current = prepare(selection(canonical));
  need(JSON.stringify(current) === JSON.stringify(intent), 'Backup identity, checksums or sizes changed; do not resume against a different source.');
  return intent;
}
function inspectTargets(session, intent, complete) {
  if (intent.mode === 'no-restore') return;
  const base = safe(path.join(session, 'files'));
  need(fs.statSync(base).isDirectory(), 'Staging files directory is missing.');
  const expected = new Map(intent.files.map(file => [file.target, file]));
  function walk(dir, prefix = '') {
    safe(dir);
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const rel = prefix + entry.name;
      const file = safe(path.join(base, rel));
      if (entry.isDirectory()) {
        need([...expected.keys()].some(key => key.startsWith(rel + '/')), `Unexpected staging directory: ${rel}`);
        walk(file, rel + '/');
      } else {
        need(entry.isFile() && expected.has(rel), `Unexpected staging entry: ${rel}`);
        const observed = fingerprint(file), selected = expected.get(rel);
        need(observed.sha256 === selected.sha256 && observed.bytes === selected.bytes, `Staged file conflict: ${rel}; nothing will be overwritten.`);
      }
    }
  }
  walk(base);
  for (const file of intent.files) {
    const target = safe(path.join(base, file.target));
    if (fs.existsSync(target)) need(fs.lstatSync(target).isFile(), `Staging target is not a regular file: ${file.target}`);
    else need(!complete, `Staged file missing: ${file.target}; resume the saved selection.`);
  }
}
function copyOne(session, intent, file) {
  const target = safe(path.join(session, 'files', file.target));
  if (fs.existsSync(target)) return;
  const incoming = safe(path.join(session, 'incoming'));
  const temporary = path.join(incoming, crypto.randomUUID());
  const source = path.join(intent.source, file.source);
  const sourceFd = openFile(source);
  let outputFd;
  try {
    outputFd = fs.openSync(temporary, 'wx', 0o600);
    const hash = crypto.createHash('sha256'), buffer = Buffer.alloc(1024 * 1024);
    let count, bytes = 0;
    while ((count = fs.readSync(sourceFd, buffer, 0, buffer.length, null))) {
      hash.update(buffer.subarray(0, count)); bytes += count;
      let offset = 0;
      while (offset < count) {
        const written = fs.writeSync(outputFd, buffer, offset, count - offset);
        need(written > 0, 'Transfer made no progress; incoming data retained for review.');
        offset += written;
      }
    }
    fs.fsyncSync(outputFd); fs.closeSync(outputFd); outputFd = undefined;
    need(hash.digest('hex') === file.sha256 && bytes === file.bytes, 'Source changed during transfer; partial data retained only in incoming.');
    need(fingerprint(source).sha256 === file.sha256, 'Source changed after transfer.');
    safe(path.dirname(target)); fs.mkdirSync(path.dirname(target), { recursive: true, mode: 0o700 });
    safe(target);
    // Hard-link publication is atomic and refuses an existing destination.
    // Interrupted incoming files are kept; retries never overwrite or reuse them.
    fs.linkSync(temporary, target);
    fs.unlinkSync(temporary);
  } finally { fs.closeSync(sourceFd); if (outputFd !== undefined) fs.closeSync(outputFd); }
}
try {
  need(Number(process.versions.node.split('.')[0]) >= 22, 'Node 22+ is required.');
  if (action === 'selection') {
    const selected = selection(read(input));
    process.stdout.write(selected.mode === 'no-restore' ? 'mode\tno-restore\n' : `source\t${selected.source}\n${selected.files.map(f => `file\t${f.source}\t${f.target}\t${f.sha256}`).join('\n')}\n`);
  } else if (action === 'plan') {
    const selected = selection(read(input)); separate(selected, extra);
    process.stdout.write(JSON.stringify(prepare(selected), null, 2) + '\n');
  } else if (action === 'prepare') {
    // This input was collected before confirmation; revalidate before publishing.
    const preview = JSON.parse(fs.readFileSync(0, 'utf8'));
    const current = prepare(selection(read(extra)));
    need(JSON.stringify(preview) === JSON.stringify(current), 'Source changed since the preview; review a new plan.');
    separate(current, input);
    safe(input); fs.mkdirSync(input, { mode: 0o700 });
    const serialized = JSON.stringify(current) + '\n';
    writeNew(path.join(input, 'intent.json'), serialized);
    fs.mkdirSync(path.join(input, 'files'), { mode: 0o700 });
    fs.mkdirSync(path.join(input, 'incoming'), { mode: 0o700 });
    process.stdout.write(digest(serialized) + '\n');
  } else if (action === 'stage' || action === 'check') {
    const intent = intentAt(input, extra);
    separate(intent, input);
    const selected = selection(read(manifest));
    const original = intent.mode === 'no-restore' ? intent : { version: 1, mode: 'stage', source: intent.source, files: intent.files.map(({ source, target, sha256 }) => ({ source, target, sha256 })) };
    need(JSON.stringify(selected) === JSON.stringify(original), 'Saved selection differs from the pinned staging intent.');
    inspectTargets(input, intent, action === 'check');
    if (action === 'stage' && intent.mode === 'stage') {
      for (const file of intent.files) copyOne(input, intent, file);
      // A disconnect or source change cannot be reported as verified success.
      intentAt(input, extra); inspectTargets(input, intent, true);
    }
    process.stdout.write(intent.mode === 'no-restore' ? 'Verified: explicit no-restore decision.\n' : `Verified: ${intent.files.length} staged files, ${intent.totalBytes} bytes.\nStaging: ${path.join(input, 'files')}\n`);
  } else throw new Error('Unknown restore action.');
} catch (error) { process.stderr.write(`${error.message}\n`); process.exitCode = 1; }
