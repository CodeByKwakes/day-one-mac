/* Offline reader. No requests, storage, analytics, or command execution. */
'use strict';

function documentationRenderer(markdownIt, documents, currentPath) {
  const md = markdownIt({ html: false, linkify: false, typographer: false });
  const slugs = new Map();
  md.renderer.rules.heading_open = (tokens, index, options, env, self) => {
    const base = tokens[index + 1].content.toLowerCase().replace(/[^a-z0-9 _-]/g, '').replace(/[ \t]/g, '-');
    const count = slugs.get(base) || 0;
    slugs.set(base, count + 1);
    tokens[index].attrSet('id', count ? `${base}-${count}` : base);
    return self.renderToken(tokens, index, options);
  };
  md.renderer.rules.link_open = (tokens, index, options, env, self) => {
    const token = tokens[index];
    const href = token.attrGet('href');
    if (href && !/^[a-z][a-z0-9+.-]*:|^\/\//i.test(href)) {
      const url = new URL(href, `https://docs.invalid/${currentPath}`);
      const path = decodeURIComponent(url.pathname.slice(1));
      if (documents.has(path)) token.attrSet('href', `#${path}${url.hash}`);
      else if (url.origin === 'https://docs.invalid') token.attrSet('href', `./${url.pathname.slice(1)}${url.hash}`);
    } else {
      token.attrSet('rel', 'noopener noreferrer');
    }
    return self.renderToken(tokens, index, options);
  };
  // Never load remote images or tracking pixels while reading offline.
  md.renderer.rules.image = (tokens, index) => `[Image: ${md.utils.escapeHtml(tokens[index].content)}]`;
  return md;
}

if (typeof module !== 'undefined') module.exports = { documentationRenderer };

if (typeof document !== 'undefined') {
  const documents = new Map(Array.from(document.querySelectorAll('.document-data'), node => [
    node.dataset.path, new TextDecoder().decode(Uint8Array.from(atob(node.textContent.trim()), c => c.charCodeAt(0))),
  ]));
  const content = document.getElementById('content');
  const bundleVersion = document.getElementById('bundle-version').textContent;
  document.getElementById('version').textContent = `Bundled version ${bundleVersion}`;
  document.getElementById('print').addEventListener('click', () => window.print());
  const titles = new Map(Array.from(documents, ([path, text]) => [path, text.match(/^# (.+)$/m)?.[1] || path]));
  function showPage() {
    if (location.hash === '#content') { content.focus(); return; }
    const [rawPath, rawAnchor = ''] = location.hash.slice(1).split('#');
    let path, anchor;
    try { path = decodeURIComponent(rawPath || 'docs/START-HERE.md'); anchor = decodeURIComponent(rawAnchor); }
    catch { content.textContent = 'Invalid documentation link.'; return; }
    if (!documents.has(path)) { content.textContent = 'This guide is not in this bundle. Use All documentation to choose a bundled guide.'; return; }
    content.innerHTML = documentationRenderer(window.markdownit, documents, path).render(documents.get(path));
    const provenance = document.createElement('p');
    provenance.className = 'source-path';
    provenance.textContent = `Day One Mac ${bundleVersion} · ${path}`;
    content.prepend(provenance);
    document.title = `${titles.get(path)} — Day One Mac ${bundleVersion}`;
    const heading = anchor && document.getElementById(anchor);
    if (heading) heading.scrollIntoView();
    else window.scrollTo(0, 0);
    content.focus({ preventScroll: true });
  }
  document.getElementById('search').addEventListener('input', event => {
    const query = event.target.value.trim().toLowerCase();
    const results = document.getElementById('results');
    results.replaceChildren();
    if (!query) return;
    for (const [path, title] of titles) {
      if (!`${title} ${path}`.toLowerCase().includes(query)) continue;
      const link = document.createElement('a');
      link.href = `#${path}`; link.textContent = title; results.append(link);
    }
  });
  window.addEventListener('hashchange', showPage);
  showPage();
}
