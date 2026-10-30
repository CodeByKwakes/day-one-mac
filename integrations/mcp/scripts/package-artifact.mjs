import { readFile, mkdir, open } from 'node:fs/promises';
import { promisify } from 'node:util';
import { execFile } from 'node:child_process';
import { createReadStream } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const pkg = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
const [output] = process.argv.slice(2);
if (process.argv.length !== 3 || !output || !path.isAbsolute(output)) throw Error('Usage: package-artifact.mjs NEW_ABSOLUTE_DIRECTORY');
if (!process.env.npm_execpath) throw Error('Run through npm run package:local');
await mkdir(output, { mode: 0o700 });
const result = await promisify(execFile)(process.execPath, [process.env.npm_execpath, 'pack', '--ignore-scripts', '--json', '--pack-destination', output], { cwd: root, timeout: 60000, maxBuffer: 1024 * 1024 });
const records = JSON.parse(result.stdout);
if (records.length !== 1 || records[0].name !== pkg.name || records[0].version !== pkg.version || path.basename(records[0].filename) !== records[0].filename) throw Error('Unexpected package identity; inspect the reserved artifact directory.');
for (const { path: file } of records[0].files) {
  if (!/^(package\.json|npm-shrinkwrap\.json|README\.md|LICENSE|dist\/guides\.json|dist\/src\/[a-z-]+\.(js|d\.ts))$/.test(file)) throw Error(`Unexpected packed file: ${file}`);
}
const file = path.join(output, records[0].filename);
const hash = createHash('sha256'); for await (const block of createReadStream(file)) hash.update(block);
const checksum = await open(file + '.sha256', 'wx', 0o600);
try { await checksum.writeFile(hash.digest('hex') + '  ' + path.basename(file) + '\n'); } finally { await checksum.close(); }
console.log(`Local package: ${file}`);
