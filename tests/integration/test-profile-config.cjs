'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const { recipe } = require('../../helpers/vscode/build.cjs');
const golden = require('../fixtures/vscode/recipes-v1.json');
// Keep the migration snapshot intact and enumerate supported differences explicitly.
const expected = structuredClone(golden);
for (const profile of Object.values(expected)) {
  profile.settings['chat.mcp.gallery.enabled'] = true;
  profile.extensions = profile.extensions.filter(id => id !== 'streetsidesoftware.code-spell-checker');
  profile.settings['explorer.compactFolders'] = false;
  profile.settings['explorer.openEditors.visible'] = 9;
  profile.settings['git.suggestSmartCommit'] = false;
  profile.settings['git.detectWorktrees'] = true;
  profile.settings['git.detectWorktreesLimit'] = 30;
  profile.settings['terminal.integrated.suggest.upArrowNavigatesHistory'] = true;
  profile.optional.push('natqe.reload');
}
for (const pattern of ['azure-pipelines.yml', 'azure-pipelines.yaml', '**/.azure-pipelines/**/*.yml', '**/.azure-pipelines/**/*.yaml']) {
  expected.ai.settings['files.associations'][pattern] = 'yaml';
}
expected['full-stack'].extensions.push('sleistner.vscode-fileutils');
expected['full-stack'].optional = expected['full-stack'].optional.filter(id => id !== 'bradlc.vscode-tailwindcss');
expected.ai.optional.push('sleistner.vscode-fileutils');
for (const slug of ['full-stack', 'ai']) {
  expected[slug].extensions.push('bradlc.vscode-tailwindcss');
  expected[slug].extensions.push('imgildev.vscode-auto-barrel');
  expected[slug].extensions.push('tomwhite007.rename-angular-component');
  expected[slug].settings['files.associations']['*.css'] = 'tailwindcss';
  expected[slug].settings['[html]']['editor.quickSuggestions'] = { strings: 'on' };
  Object.assign(expected[slug].settings, {
    '[tailwindcss]': { 'editor.defaultFormatter': 'esbenp.prettier-vscode', 'editor.formatOnSave': true },
    'prettier.documentSelectors': ['**/*.css'],
    'tailwindCSS.validate': true,
    'tailwindCSS.lint.invalidApply': 'error',
    'scss.lint.unknownAtRules': 'ignore',
    'renameAngularComponent.showWhatsNewPopup': false,
    'renameAngularComponent.debugLog': false,
    'renameAngularComponent.useLocalDirectPaths': false,
    'renameAngularComponent.followAngular20FolderAndSelectorNamingConvention': false,
    'autoBarrel.files.disableRecursiveBarrelling': false,
    'autoBarrel.files.maxSearchRecursionDepth': 3,
    'autoBarrel.files.supportsHiddenFiles': false,
    'autoBarrel.files.preserveGitignoreSettings': true,
    'autoBarrel.files.detectExportsInFiles': true,
    'autoBarrel.files.useNamedExports': true,
    'autoBarrel.formatting.useSingleQuotes': true,
    'autoBarrel.formatting.sortExports': 'alphabetical',
    'fileutils.inputBox.pathType': 'root',
    'fileutils.menus.context.explorer': ['moveFile', 'duplicateFile', 'copyFileName'],
    'fileutils.menus.context.editor': [],
    'fileutils.menus.context.editorTitle': ['moveFile', 'duplicateFile', 'copyFileName'],
  });
}
expected['full-stack'].settings['workbench.colorCustomizations']['titleBar.activeBackground'] = '#452568';
expected['full-stack'].settings['workbench.colorCustomizations']['activityBarBadge.background'] = '#9B6DDA';
expected.ai.settings['workbench.colorCustomizations']['titleBar.activeBackground'] = '#163A63';
expected.ai.settings['workbench.colorCustomizations']['activityBarBadge.background'] = '#2563EB';
for (const slug of Object.keys(expected)) assert.deepEqual(recipe(slug), expected[slug]);
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'day-one-profile-config-'));
try {
  fs.mkdirSync(path.join(tmp, 'helpers/vscode'), { recursive: true });
  fs.mkdirSync(path.join(tmp, 'config/profiles/vscode'), { recursive: true });
  fs.copyFileSync(path.join(root, 'helpers/vscode/build.cjs'), path.join(tmp, 'helpers/vscode/build.cjs'));
  const target = path.join(tmp, 'config/profiles/vscode/profiles.json');
  const config = JSON.parse(fs.readFileSync(path.join(root, 'config/profiles/vscode/profiles.json')));
  fs.writeFileSync(target, JSON.stringify(config));
  const independent = require(path.join(tmp, 'helpers/vscode/build.cjs'));
  for (const slug of Object.keys(expected)) assert.deepEqual(independent.recipe(slug), expected[slug]);
  config.schemaVersion = 99;
  fs.writeFileSync(target, JSON.stringify(config));
  assert.throws(() => independent.recipe('default'), /schema/);
  config.schemaVersion = 1;
  config.profiles.default.optional.push('bad extension');
  fs.writeFileSync(target, JSON.stringify(config));
  assert.throws(() => independent.recipe('default'), /extension ID/);
  console.log('Profile configuration: baseline equivalence, no documentation dependency, invalid schema and invalid extension rejection passed.');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
