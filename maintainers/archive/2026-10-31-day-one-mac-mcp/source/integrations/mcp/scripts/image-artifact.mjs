import { readFile, mkdir, open, rm, rename } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { createReadStream } from 'node:fs';
import { createHash, randomUUID } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const pkg = JSON.parse(await readFile(new URL('../package.json', import.meta.url), 'utf8'));
const tag = `day-one-mac-mcp:${pkg.version}`;
const root = fileURLToPath(new URL('../../../', import.meta.url));
const run = args => new Promise((resolve, reject) => {
  const child = spawn('docker', args, { stdio: 'inherit', cwd: root });
  child.on('error', reject); child.on('exit', code => code === 0 ? resolve() : reject(Error(`Docker exited ${code}`)));
});
const [mode, output] = process.argv.slice(2);
if (mode === 'build' && !output) {
  await run(['build', '-f', 'integrations/mcp/Dockerfile', '--build-arg', `VERSION=${pkg.version}`, '-t', tag, '-t', 'day-one-mac-mcp:local', '.']);
} else if (mode === 'export' && output && path.isAbsolute(output) && process.argv.length === 4) {
  // Reserve a new destination; retain existing artifacts rather than overwriting.
  await mkdir(output, { mode: 0o700 });
  const file = path.join(output, `day-one-mac-mcp-${pkg.version}-docker.tar`);
  const temporary = file + '.' + randomUUID() + '.tmp';
  try {
    const reserve = await open(temporary, 'wx', 0o600); await reserve.close();
    await run(['image', 'save', '--output', temporary, tag]);
    await rename(temporary, file);
    const hash = createHash('sha256'); for await (const block of createReadStream(file)) hash.update(block);
    const checksum = await open(file + '.sha256', 'wx', 0o600);
    try { await checksum.writeFile(hash.digest('hex') + '  ' + path.basename(file) + '\n'); } finally { await checksum.close(); }
    console.log(`Local image archive: ${file}`);
  } finally { await rm(temporary, { force: true }); }
} else throw Error('Usage: image-artifact.mjs build | export NEW_ABSOLUTE_DIRECTORY');
