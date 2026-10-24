'use strict';
// Shared, bounded filesystem reads. Nothing in inspected repositories is loaded.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
function need(ok, message) { if (!ok) throw new Error(message); }
function plain(value) { return typeof value === 'string' && value.length > 0 && !/[\x00-\x1f\x7f]/.test(value); }
function absolute(value) {
  need(plain(value) && path.isAbsolute(value) && path.normalize(value) === value && value !== '/' && !value.endsWith('/'), 'Use a canonical absolute path, without control characters or traversal.');
  return value;
}
function safe(value) {
  absolute(value);
  for (let p = value; p !== '/'; p = path.dirname(p)) {
    try { need(!fs.lstatSync(p).isSymbolicLink(), `Symlink refused: ${p}`); }
    catch (e) { if (e.code !== 'ENOENT') throw e; }
  }
  return value;
}
function openFile(value) {
  safe(value);
  const fd = fs.openSync(value, fs.constants.O_RDONLY | fs.constants.O_NOFOLLOW | fs.constants.O_NONBLOCK);
  try { need(fs.fstatSync(fd).isFile(), `Not a regular file: ${value}`); return fd; }
  catch (e) { fs.closeSync(fd); throw e; }
}
function read(value, limit = 1024 * 1024) {
  const fd = openFile(value);
  try { need(fs.fstatSync(fd).size <= limit, 'Metadata file exceeds the size limit.'); return fs.readFileSync(fd, 'utf8'); }
  finally { fs.closeSync(fd); }
}
function digest(text) { return crypto.createHash('sha256').update(text).digest('hex'); }
function fingerprint(value) {
  const fd = openFile(value);
  try {
    const before = fs.fstatSync(fd), hash = crypto.createHash('sha256'), buffer = Buffer.alloc(1024 * 1024);
    let count;
    while ((count = fs.readSync(fd, buffer, 0, buffer.length, null))) hash.update(buffer.subarray(0, count));
    const after = fs.fstatSync(fd), current = fs.lstatSync(value);
    need(['dev', 'ino', 'size', 'mtimeMs', 'ctimeMs'].every(k => before[k] === after[k] && after[k] === current[k]), `File changed while reading: ${value}`);
    return { bytes: after.size, sha256: hash.digest('hex') };
  } finally { fs.closeSync(fd); }
}
function rows(text) {
  need(!/[\x00-\x08\x0b-\x1f\x7f]/.test(text), 'Manifest contains unsupported control characters; use LF line endings.');
  const result = text.split('\n').filter(line => line && !line.startsWith('#')).map(line => line.split('\t'));
  need(result.length > 0 && result.length <= 1000 && result.every(row => row.every(plain)), 'Use 1–1000 rows with nonempty tab-separated fields.');
  return result;
}
function command(program, args, options = {}) {
  const result = spawnSync(program, args, { encoding: 'utf8', timeout: 15000, maxBuffer: 4 * 1024 * 1024, ...options });
  need(!result.error && result.status === 0, `${path.basename(program)} inspection failed (no command output retained).`);
  return result.stdout;
}
function writeNew(file, value) { safe(file); fs.writeFileSync(file, value, { flag: 'wx', mode: 0o600 }); }
module.exports = { fs, path, need, plain, absolute, safe, read, digest, fingerprint, rows, command, writeNew, openFile };
