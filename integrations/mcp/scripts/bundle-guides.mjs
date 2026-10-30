import { readFile, writeFile, mkdir, lstat, chmod } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../../../', import.meta.url));
const sources = {
  macos: 'docs/setup/manual/macos.md',
  homebrew: 'docs/setup/manual/homebrew.md',
  shell: 'docs/setup/manual/shell/zsh.md',
  git: 'docs/setup/manual/git/setup.md',
  vscode: 'docs/setup/manual/editors/vscode.md',
  apps: 'docs/setup/manual/apps/README.md',
  verification: 'docs/shared/verification.md'
};
const guides = {};
for (const [id, source] of Object.entries(sources)) {
  // Package only these reviewed public files; never discover host files.
  for (let p = source; p !== '.'; p = path.dirname(p)) {
    if ((await lstat(path.join(root, p))).isSymbolicLink()) throw Error(`Symlink source: ${source}`);
  }
  const text = await readFile(path.join(root, source), 'utf8');
  guides[id] = { id, source, title: text.match(/^# (.+)$/m)?.[1] ?? id, text };
}
await mkdir(new URL('../dist/', import.meta.url), { recursive: true });
await writeFile(new URL('../dist/guides.json', import.meta.url), JSON.stringify(guides));

await writeFile(new URL('../LICENSE', import.meta.url), await readFile(path.join(root, 'LICENSE')));
for (const entry of ['index.js', 'configure.js']) await chmod(new URL('../dist/src/' + entry, import.meta.url), 0o755);
