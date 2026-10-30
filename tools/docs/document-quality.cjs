'use strict';
const path = require('node:path').posix;
const markdown = require('../vendor/markdown-it/markdown-it.min.js')();
const compatibilityMarker = '<!-- day-one-mac:compatibility-guide -->';

// These checks protect known reader failures, not a universal prose style.
function checkDocumentationQuality(documents, bundledFiles = null, nodeMinimum = null) {
  const errors = [];
  for (const [file, text] of documents) {
    if (text.includes(compatibilityMarker) || file.startsWith('maintainers/') || file === 'CHANGELOG.md') continue;
    if (nodeMinimum) {
      const required = nodeMinimum.split('.').map(Number);
      for (const match of text.matchAll(/Node(?:\.js)?\s+(22(?:\.\d+){0,2})(?:\s+or newer|\+)/g)) {
        const found = match[1].split('.').map(Number);
        while (found.length < 3) found.push(0);
        if (found[1] < required[1] || (found[1] === required[1] && found[2] < required[2])) {
          errors.push(`${file}: Node minimum ${match[1]} is below shared contract ${nodeMinimum}`);
        }
      }
    }
    const tokens = markdown.parse(text, {});
    const prose = tokens.filter(t => t.type === 'inline').map(t => t.content).join('\n');
    if (/\b(?:re)?run the (?:local )?planner\b|\bplanner (?:also )?writes\b|\bModule (?:09|11) (?:still )?(?:generates|provisions)\b|\bDay One Script Commands\b/i.test(prose)) {
      errors.push(`${file}: retired behaviour in current instructions`);
    }
    for (const token of tokens) {
      if (token.type === 'fence' && /^(?:bash|sh|zsh)\b/.test(token.info)
          && /brew install --cask docker-desktop/.test(token.content)
          && /brew install --cask orbstack/.test(token.content)) {
        errors.push(`${file}: separate alternative installers into different blocks`);
      }
    }
    const visit = nodes => { for (const node of nodes) {
      const href = node.attrGet('href') ?? node.attrGet('src');
      if (href === '') errors.push(`${file}: empty destination in a documentation link`);
      if (href && !/^[a-z][a-z\d+.-]*:|^\/\//i.test(href)) {
        const name = decodeURIComponent(href.split('#')[0]);
        if (name) {
          const target = path.normalize(path.join(path.dirname(file), name));
          if (documents.get(target)?.includes(compatibilityMarker)) errors.push(`${file}: current link to retired page ${target}`);
          if (bundledFiles && /^(config|templates|integrations|extensions)\//.test(target) && !bundledFiles.has(target)) {
            errors.push(`${file}: unbundled asset ${target}`);
          }
        }
      }
      if (node.children) visit(node.children);
    } };
    visit(tokens);
  }
  return errors;
}
module.exports = { checkDocumentationQuality };
