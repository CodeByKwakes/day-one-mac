#!/usr/bin/env node
'use strict';
// Bounded version probes only. No shell, account access, repair or output files.
const { spawnSync } = require('node:child_process');
const probes = [['Git', 'git', ['--version']], ['Node.js', 'node', ['--version']],
  ['pnpm', 'pnpm', ['--version']], ['Docker client', 'docker', ['--version']]];
function check(run = spawnSync) {
  return probes.map(([name, program, args]) => {
    const result = run(program, args, { encoding: 'utf8', timeout: 5000, maxBuffer: 16384, shell: false });
    const version = !result.error && result.status === 0 ? (result.stdout || '').match(/\b\d+\.\d+(?:\.\d+)?\b/)?.[0] : undefined;
    return { name, status: version ? 'available' : 'not available', ...(version ? { version } : {}) };
  });
}
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length && !(args.length === 1 && args[0] === '--help')) { console.error('Usage: node helpers/check.cjs [--help]'); process.exitCode = 1; }
  else if (args.length) console.log('Read-only platform and Git, Node.js, pnpm, Docker client version checks. No service or account probes.');
  else console.log(JSON.stringify({ platform: process.platform, architecture: process.arch, tools: check() }, null, 2));
}
module.exports = { check };
