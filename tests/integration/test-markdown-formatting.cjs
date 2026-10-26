'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { markdownlintConfig } = require('../../config/profiles/vscode/profiles.json');
const cliDirectory = path.dirname(require.resolve('markdownlint-cli2'));
const cliPackage = JSON.parse(fs.readFileSync(path.join(cliDirectory, 'package.json')));
const cli = path.join(cliDirectory, cliPackage.bin['markdownlint-cli2']);
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-markdown-'));
try {
  const personal = path.join(tmp, 'personal rules.json');
  fs.writeFileSync(personal, JSON.stringify(markdownlintConfig));
  const project = path.join(tmp, 'Project é');
  fs.mkdirSync(project);
  const file = path.join(project, 'example.md');
  const hundredCharacters = 'word '.repeat(20).trimEnd() + '.';
  assert.equal(hundredCharacters.length, 100);
  const prefix = '# Example\n\nKeep this paragraph break\nwhere the author placed it.\n\n' + hundredCharacters + '\n\n';
  const compact = '| File | Change |\n| --- | --- |\n| `a\\|b` | Keep the escaped pipe. |\n'
    + '| long | ' + 'Keep this table cell readable. '.repeat(6).trimEnd() + ' |\n';
  const padded = '| Name   | Value   |\n| ------ | ------- |\n| short  | one     |\n';
  const fixed = '| Name | Value |\n| ------ | ------- |\n| short | one |\n';
  const code = '\n```typescript\nconst example={message:"hello",enabled:true};\n'
    + '// ' + 'Preserve the code example. '.repeat(6).trimEnd() + '\n```\n';
  const input = prefix + compact + '\n' + padded + code;
  const expected = prefix + compact + '\n' + fixed + code;
  fs.writeFileSync(file, input);
  const format = () => {
    const result = spawnSync(process.execPath, [cli, '--config', personal, '--fix', 'example.md'], {
      cwd: project, encoding: 'utf8', timeout: 30000,
    });
    assert.equal(result.status, 0, String(result.error || '') + result.stdout + result.stderr);
    return fs.readFileSync(file, 'utf8');
  };
  assert.equal(format(), expected, 'Compact tables, prose, code examples and delimiter lengths must survive formatting');
  assert.equal(format(), expected, 'Saving again must not change the result');
  const violations = [
    '# Line checks', '', hundredCharacters + ' More words.', '',
    '## ' + hundredCharacters + ' More words.', '',
    '```', 'echo hello', '```', '',
    'Use <App> as the placeholder.', '',
  ].join('\n');
  fs.writeFileSync(path.join(project, 'violations.md'), violations);
  const checked = spawnSync(process.execPath, [cli, '--config', personal, 'violations.md'], {
    cwd: project, encoding: 'utf8', timeout: 30000,
  });
  assert.equal(checked.status, 1, String(checked.error || '') + checked.stdout + checked.stderr);
  const diagnostics = checked.stdout + checked.stderr;
  assert.equal((diagnostics.match(/MD013\/line-length/g) || []).length, 2, diagnostics);
  assert.equal((diagnostics.match(/Expected: 100/g) || []).length, 2, diagnostics);
  assert.match(diagnostics, /MD033\/no-inline-html/);
  assert.match(diagnostics, /MD040\/fenced-code-language/);
  fs.writeFileSync(path.join(project, '.markdownlint-cli2.jsonc'), JSON.stringify({ config: { MD060: { style: 'any' } } }));
  fs.writeFileSync(file, input);
  assert.equal(format(), input, 'Project table rules must override personal defaults');
  console.log('PASS: compact tables and long code survive stable formatting; prose and headings use a 100-character limit, HTML and fence checks remain active, and project rules override personal defaults');
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}
