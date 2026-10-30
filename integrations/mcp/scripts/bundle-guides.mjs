import { readFile, writeFile, mkdir, lstat, chmod } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../../../', import.meta.url));
const specificationPath = 'config/mcp/day-one-mac.json';
for (let p = specificationPath; p !== '.'; p = path.dirname(p)) {
  if ((await lstat(path.join(root, p))).isSymbolicLink()) throw Error(`Symlink source: ${specificationPath}`);
}
const specification = await readFile(path.join(root, specificationPath), 'utf8');
const spec = JSON.parse(specification);
if (spec.schema !== 1 || !spec.guides || typeof spec.guides !== 'object') throw Error('Invalid MCP guide specification.');
const sources = spec.guides;
const guides = {};
for (const [id, source] of Object.entries(sources)) {
  if (!/^[a-z][a-z0-9_-]*$/.test(id) || typeof source !== 'string' || !/^docs\/(?:[a-zA-Z0-9_-]+\/)*[a-zA-Z0-9_-]+\.md$/.test(source)) throw Error('Unsafe MCP guide source.');
  // Package only these reviewed public files; never discover host files.
  for (let p = source; p !== '.'; p = path.dirname(p)) {
    if ((await lstat(path.join(root, p))).isSymbolicLink()) throw Error(`Symlink source: ${source}`);
  }
  const text = await readFile(path.join(root, source), 'utf8');
  guides[id] = { id, source, title: text.match(/^# (.+)$/m)?.[1] ?? id, text };
}
await mkdir(new URL('../dist/', import.meta.url), { recursive: true });
await writeFile(new URL('../dist/guides.json', import.meta.url), JSON.stringify(guides));
await writeFile(new URL('../dist/server-spec.json', import.meta.url), specification);

await writeFile(new URL('../LICENSE', import.meta.url), await readFile(path.join(root, 'LICENSE')));
for (const entry of ['index.js', 'configure.js']) await chmod(new URL('../dist/src/' + entry, import.meta.url), 0o755);
