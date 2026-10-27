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
  profile.keybindings.unshift({ key: 'cmd+t', command: 'workbench.action.files.newUntitledFile' });
  profile.settings['chat.mcp.gallery.enabled'] = true;
  profile.settings['gitlens.ai.generateCommitMessage.customInstructions'] = 'Use Conventional Commits: type(scope): description, omitting the scope when unnecessary. Choose feat, fix, docs, refactor, perf, test, build, ci, chore, style, or revert according to the actual changes and repository conventions. Write a specific, imperative subject, preferably within 72 characters, without a trailing period. For substantial changes, add a blank line and a concise body explaining what changed and why, using only evidence from the diff and supplied context. Keep simple changes to a subject alone. Do not invent motivations, test results, issue references, or compatibility guarantees. Use ! and a BREAKING CHANGE footer only for actual breaking changes. Return only the commit message.';
  profile.extensions = profile.extensions.filter(id => id !== 'streetsidesoftware.code-spell-checker');
  profile.settings['explorer.compactFolders'] = false;
  profile.settings['explorer.openEditors.visible'] = 9;
  Object.assign(profile.settings, {
    'workbench.editor.showTabs': 'multiple',
    'workbench.editor.labelFormat': 'default',
    'workbench.editor.wrapTabs': true,
    'workbench.editor.tabSizing': 'fit',
    'workbench.editor.enablePreview': false,
    'workbench.editor.enablePreviewFromQuickOpen': false,
    'workbench.editor.openPositioning': 'right',
    'workbench.editor.limit.enabled': false,
    'workbench.editor.highlightModifiedTabs': true,
  });
  profile.settings['[markdown]']['editor.defaultFormatter'] = 'DavidAnson.vscode-markdownlint';
  profile.settings['markdownlint.configFile'] = '${userHome}/.config/markdownlint/config.json';
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
expected['full-stack'].extensions.splice(expected['full-stack'].extensions.indexOf('nrwl.angular-console') + 1, 0, 'luisclementdev.npm-visual-manager');
expected['full-stack'].optional = expected['full-stack'].optional.filter(id => id !== 'bradlc.vscode-tailwindcss');
expected.ai.optional.push('sleistner.vscode-fileutils');
expected.ai.optional.push('luisclementdev.npm-visual-manager');
expected.ai.optional.push('pranaygp.vscode-css-peek');
expected.ai.settings['chatgpt.reviewDelivery'] = 'inline';
for (const slug of ['full-stack', 'ai']) {
  expected[slug].extensions.push('bradlc.vscode-tailwindcss');
  expected[slug].extensions.push('imgildev.vscode-auto-barrel');
  expected[slug].extensions.push('tomwhite007.rename-angular-component');
  expected[slug].settings['files.associations']['*.css'] = 'tailwindcss';
  expected[slug].settings['[html]']['editor.quickSuggestions'] = { strings: 'on' };
  Object.assign(expected[slug].settings, {
    'npm-visual-manager.columns.type': true,
    'npm-visual-manager.columns.semverUpdate': true,
    'npm-visual-manager.columns.security': true,
    'npm-visual-manager.columns.lastUpdate': true,
    'npm-visual-manager.columns.size': false,
    'npm-visual-manager.badge.enabled': false,
    'npm-visual-manager.scan.maxDepth': 5,
    'npm-visual-manager.saveExact': false,
    '[tailwindcss]': { 'editor.defaultFormatter': 'esbenp.prettier-vscode', 'editor.formatOnSave': true },
    'prettier.documentSelectors': ['**/*.css'],
    'tailwindCSS.validate': true,
    'tailwindCSS.lint.invalidApply': 'error',
    'scss.lint.unknownAtRules': 'ignore',
    'cssPeek.supportTags': false,
    'cssPeek.peekToLinkedOnly': false,
    'cssPeek.respectGitignore': true,
    'cssPeek.enableTelemetry': false,
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
expected['full-stack'].extensions.push('pranaygp.vscode-css-peek');
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
  const sharedKeybindings = config.keybindings.shared;
  config.keybindings.shared = {};
  fs.writeFileSync(target, JSON.stringify(config));
  assert.throws(() => independent.recipe('default'), /keybindings/);
  delete config.keybindings.shared;
  fs.writeFileSync(target, JSON.stringify(config));
  assert.deepEqual(independent.recipe('default').keybindings, [], 'Existing configurations without shared shortcuts remain supported');
  assert.deepEqual(independent.recipe('full-stack').keybindings, expected['full-stack'].keybindings.slice(1));
  config.keybindings.shared = sharedKeybindings;
  config.profiles.default.optional.push('bad extension');
  fs.writeFileSync(target, JSON.stringify(config));
  assert.throws(() => independent.recipe('default'), /extension ID/);
  console.log('Profile configuration: baseline equivalence, no documentation dependency, invalid schema and invalid extension rejection passed.');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
