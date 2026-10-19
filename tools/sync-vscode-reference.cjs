#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const config = JSON.parse(fs.readFileSync(path.join(root, 'config/profiles/vscode/profiles.json'), 'utf8'));
const json = value => `\n\`\`\`json\n${JSON.stringify(value, null, 2)}\n\`\`\`\n`;
let text = '# VS Code profile configuration reference\n\n';
text += 'Generated from the versioned [profile configuration](../../config/profiles/vscode/profiles.json).\n';
text += 'Use the [profile guide](../how-to/apps/VSCODE-PROFILES.md) for selection, import and verification.\n';
text += 'Maintainers update this page with `node tools/sync-vscode-reference.cjs`; edit the configuration source first.\n\n';
text += '## Shared settings\n' + json(config.sharedSettings);
for (const [slug, profile] of Object.entries(config.profiles)) {
 text += `\n## ${profile.name}\n\n`;
 if (profile.extends) text += `Apply ${config.profiles[profile.extends].name} overrides before these overrides.\n\n`;
 text += '| Extension ID | Selection |\n| --- | --- |\n';
 for (const [key,label] of [['extensions','Recommended'],['optional','Optional']]) for (const id of profile[key]) text += `| \`${id}\` | ${label} |\n`;
 text += `\n### ${profile.name} overrides\n`+json(profile.settings);
}
text += '\n## Import keybindings\n'+json(config.keybindings.imports);
const target = path.join(root, 'docs/reference/VSCODE-PROFILE-DATA.md');
if (process.argv.includes('--check')) {
 if (!fs.existsSync(target) || fs.readFileSync(target, 'utf8') !== text) { console.error('VS Code configuration reference is stale. Run node tools/sync-vscode-reference.cjs.'); process.exitCode=1; }
} else fs.writeFileSync(target,text);
