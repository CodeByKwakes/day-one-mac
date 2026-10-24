#!/usr/bin/env node
'use strict';
// Contributor-only static export. Reads reviewed public sources, never HOME.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
function regular(name) {
  if (!name || name.split('/').includes('.DS_Store') || !/^[a-zA-Z0-9_./ -]+$/.test(name) || path.isAbsolute(name)
    || name.split('/').some(p => !p || p === '.' || p === '..')) throw new Error(`Unsafe source: ${name}`);
  for (let p = name; p !== '.'; p = path.dirname(p)) if (fs.lstatSync(path.join(root, p)).isSymbolicLink()) throw new Error(`Symlink source: ${name}`);
  if (!fs.statSync(path.join(root, name)).isFile()) throw new Error(`Not a file: ${name}`);
  return fs.readFileSync(path.join(root, name));
}
function main(args) {
  const options = {};
  while (args.length) {
    const key = args.shift();
    if (key === '--help') { console.log('Usage: node tools/export-docs.cjs --format html|markdown --output NEW_DIRECTORY'); return; }
    if (!['--format', '--output'].includes(key) || options[key] || !args.length) throw new Error('Use --format html|markdown and --output NEW_DIRECTORY once each.');
    options[key] = args.shift();
  }
  if (!['html','markdown'].includes(options['--format']) || !options['--output']) throw new Error('Choose a format and new output directory.');
  const files = regular('config/document-sources.txt').toString().split('\n').filter(s => s && !s.startsWith('#'));
  if (new Set(files).size !== files.length) throw new Error('Duplicate documentation source.');
  const contents = new Map(files.map(file => [file, regular(file)]));
  const html = options['--format'] === 'html';
  const assets = html ? new Map(['tools/docs/docs-browser.html', 'tools/docs/docs-browser.css', 'tools/docs/docs-browser.js',
    'tools/vendor/markdown-it/markdown-it.min.js', 'tools/vendor/markdown-it/LICENSE'].map(f => [f, regular(f)])) : new Map();
  const output = path.resolve(options['--output']);
  fs.mkdirSync(output, { mode: 0o700 }); // Atomic reservation; never reuse a destination.
  for (const [file, content] of contents) {
    fs.mkdirSync(path.dirname(path.join(output, file)), { recursive: true, mode: 0o700 });
    fs.writeFileSync(path.join(output, file), content, { flag: 'wx', mode: 0o600 });
  }
  if (html) {
    const read = name => assets.get(name).toString();
    const snapshot = crypto.createHash('sha256');
    for (const [file, content] of contents) snapshot.update(file).update('\0').update(content).update('\0');
    let text = read('tools/docs/docs-browser.html') + '<style>\n' + read('tools/docs/docs-browser.css') + '\n</style>\n';
    text += `<div id="bundle-version" hidden>snapshot ${snapshot.digest('hex').slice(0,12)}</div>\n`;
    for (const [file, content] of contents) if (file.endsWith('.md')) text += `<script type="text/plain" class="document-data" data-path="${file}">${content.toString('base64')}</script>\n`;
    text += '<script>\n' + read('tools/vendor/markdown-it/markdown-it.min.js') + '\n</script>\n<script>\n' + read('tools/docs/docs-browser.js') + '\n</script>\n</body></html>\n';
    fs.writeFileSync(path.join(output, 'index.html'), text, { flag: 'wx', mode: 0o600 });
    fs.writeFileSync(path.join(output, 'markdown-it-LICENSE.txt'), read('tools/vendor/markdown-it/LICENSE'), { flag: 'wx', mode: 0o600 });
  }
  console.log(`Exported static documentation: ${output}`);
}
if (require.main === module) { try { main(process.argv.slice(2)); } catch (e) { console.error(e.message); process.exitCode = 1; } }
module.exports = { regular, main };
