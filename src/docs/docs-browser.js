/* Offline reader. No requests, storage, analytics, or command execution. */
'use strict';

function documentationRenderer(markdownIt, documents, currentPath) {
  const md = markdownIt({ html: false, linkify: false, typographer: false });
  // Recognize only a list item's leading Markdown task marker. These symbols
  // describe the source document; they are not controls or live setup evidence.
  md.core.ruler.after('inline', 'document_checklists', state => {
    for (let index = 2; index < state.tokens.length; index++) {
      const token = state.tokens[index];
      if (token.type !== 'inline' || state.tokens[index - 1].type !== 'paragraph_open'
          || state.tokens[index - 2].type !== 'list_item_open') continue;
      if (!/^\[([ xX])\](?:\s|$)/.test(token.content)) continue;
      const first = token.children?.[0];
      const match = first?.type === 'text' && first.content.match(/^\[([ xX])\](?:[ \t]+|$)/);
      if (!match) continue;
      const checked = match[1].toLowerCase() === 'x';
      const marker = new state.Token('html_inline', '', 0);
      marker.content = `<span class="task-marker${checked ? ' task-checked' : ''}" role="img" aria-label="${checked ? 'Checked' : 'Unchecked'} checklist item (documented state)"></span>`;
      first.content = first.content.slice(match[0].length);
      token.children.unshift(marker);
      state.tokens[index - 2].attrJoin('class', 'task-item');
    }
  });
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

// Reader metadata never changes guide paths or the CLI's setup state. Only the
// script-assisted core has a sequence; optional guides are not a checklist.
function requiredSequence(documents) {
  const phases = Array.from(documents.keys()).filter(file => /^docs\/setup\/assisted\/0[1-8]-[^/]+\.md$/.test(file)).sort();
  const sequence = ['docs/setup/assisted/README.md', 'docs/setup/assisted/ai-setup-assistant.md'];
  for (const file of phases) {
    sequence.push(file);
    if (file.includes('/01-')) sequence.push('docs/setup/assisted/MACOS-SETTINGS.md');
    if (file.includes('/02-')) sequence.push('docs/setup/assisted/INSTALLATION-CENTRE.md');
  }
  return sequence.filter(file => documents.has(file));
}
function resolveDocumentationRoute(path, anchor, documents) {
  const text = documents.get(path) || '';
  if (!text.includes('<!-- day-one-mac:compatibility-guide -->')) return { path, anchor };
  let body = text;
  if (anchor) {
    const counts = new Map();
    const lines = text.split('\n');
    const index = lines.findIndex(line => {
      if (!/^#+ /.test(line)) return false;
      const base = line.replace(/^#+ /, '').toLowerCase().replace(/[^a-z0-9 _-]/g, '').replace(/[ \t]/g, '-');
      const count = counts.get(base) || 0; counts.set(base, count + 1);
      return (count ? `${base}-${count}` : base) === anchor;
    });
    if (index >= 0) body = lines.slice(index + 1).join('\n');
  }
  const target = body.match(/\]\(([^)]+)\)/)?.[1];
  if (!target) return { path, anchor };
  const url = new URL(target, `https://docs.invalid/${path}`);
  const destination = decodeURIComponent(url.pathname.slice(1));
  return url.origin === 'https://docs.invalid' && documents.has(destination)
    ? { path: destination, anchor: url.hash ? decodeURIComponent(url.hash.slice(1)) : '' }
    : { path, anchor };
}

function documentationNavigation(documents) {
  const claimed = new Set();
  const coreSequence = requiredSequence(documents);
  const canonical = file => !documents.get(file)?.includes('<!-- day-one-mac:compatibility-guide -->');
  const titles = new Map(Array.from(documents).filter(([file]) => canonical(file))
    .map(([file, text]) => [file, text.match(/^# (.+)$/m)?.[1] || file]));
  const entries = paths => paths.filter(file => documents.has(file) && canonical(file) && !claimed.has(file)).map(file => {
    claimed.add(file);
    return { path: file, label: titles.get(file) };
  });
  const matching = prefix => Array.from(documents.keys()).filter(file => file.startsWith(prefix))
    .sort((a, b) => Number(!a.endsWith('/README.md')) - Number(!b.endsWith('/README.md')) || a.localeCompare(b, 'en', { numeric: true }));
  const group = (label, sections) => ({ label, sections: sections.map(([name, paths]) => ({ label: name, entries: entries(paths) })) });
  const groups = [
    group('Start here', [['', ['docs/START-HERE.md', 'docs/README.md']]]),
    group('Scripted (Assisted) Setup', [
      ['Install and prepare', ['docs/setup/assisted/runtime.md', ...matching('docs/setup/assisted/existing-mac/')]],
      ['Required phases and checkpoints', coreSequence],
      ['Optional operations', matching('docs/setup/assisted/optional/')],
      ['Advanced operations', matching('docs/setup/assisted/advanced/')],
      ['Integrations', matching('docs/setup/assisted/integrations/')],
      ['Recovery', matching('docs/setup/assisted/recovery/')],
      ['Command and state reference', matching('docs/setup/assisted/reference/')],
      ['Other assisted tasks', matching('docs/setup/assisted/')],
    ]),
    group('Manual Setup', [
      ['Base setup', ['docs/setup/manual/README.md', 'docs/setup/manual/macos.md', 'docs/setup/manual/homebrew.md',
        'docs/setup/manual/languages.md', 'docs/setup/manual/backup-and-restore.md', 'docs/setup/manual/maintenance.md']],
      ['Preparation and security', [...matching('docs/setup/manual/preparation/'), ...matching('docs/setup/manual/security/')]],
      ['Git and providers', matching('docs/setup/manual/git/')],
      ['Shell and terminals', [...matching('docs/setup/manual/shell/'), ...matching('docs/setup/manual/terminals/')]],
      ['Editors and applications', [...matching('docs/setup/manual/editors/'), ...matching('docs/setup/manual/apps/')]],
      ['Databases', matching('docs/setup/manual/databases/')],
      ['AI, agents, skills and MCP', matching('docs/setup/manual/ai/')],
      ['Git worktrees', matching('docs/setup/manual/development/worktrees/')],
      ['Development workflows', matching('docs/setup/manual/development/')],
      ['Second Brain', matching('docs/setup/manual/second-brain/')],
      ['Other manual tasks', matching('docs/setup/manual/')],
    ]),
    group('Shared library', [
      ['Prerequisites, choices and help', matching('docs/shared/')],
      ['Bundled templates and project information', Array.from(documents.keys())],
    ]),
  ];
  return { groups, titles, coreSequence };
}

function findDocumentation(titles, query) {
  const term = query.trim().toLowerCase();
  return term ? Array.from(titles).filter(([path, title]) => `${title} ${path}`.toLowerCase().includes(term)) : [];
}

if (typeof module !== 'undefined') module.exports = { documentationRenderer, documentationNavigation, findDocumentation, requiredSequence, resolveDocumentationRoute };

if (typeof document !== 'undefined') {
  const documents = new Map(Array.from(document.querySelectorAll('.document-data'), node => [
    node.dataset.path, new TextDecoder().decode(Uint8Array.from(atob(node.textContent.trim()), c => c.charCodeAt(0))),
  ]));
  const content = document.getElementById('content');
  const article = document.getElementById('article');
  const sidebar = document.getElementById('sidebar');
  const menuToggle = document.getElementById('menu-toggle');
  const pageToc = document.getElementById('page-toc');
  const tocLinks = document.getElementById('toc-links');
  const readerStatus = document.getElementById('reader-status');
  const bundleVersion = document.getElementById('bundle-version').textContent;
  document.getElementById('version').textContent = `Bundled version ${bundleVersion}`;
  document.getElementById('print').addEventListener('click', () => window.print());
  const { groups, titles, coreSequence } = documentationNavigation(documents);
  const narrow = window.matchMedia('(max-width: 760px)');
  const wide = window.matchMedia('(min-width: 1200px)');
  const trails = new Map();
  const navigationLinks = [];
  let currentPath = '';

  function element(tag, text, className) {
    const node = document.createElement(tag);
    if (text !== undefined) node.textContent = text;
    if (className) node.className = className;
    return node;
  }
  function guideLink(path, label) {
    const link = element('a', label);
    link.href = `#${path}`;
    return link;
  }
  function disclosure(label, className) {
    const details = element('details', undefined, className);
    details.append(element('summary', label));
    return details;
  }
  for (const group of groups) {
    const groupNode = disclosure(group.label, 'chapter-group');
    for (const section of group.sections) {
      if (!section.entries.length) continue;
      const sectionNode = section.label ? disclosure(section.label, 'chapter-section') : groupNode;
      const list = element('ul');
      for (const entry of section.entries) {
        const link = guideLink(entry.path, entry.label);
        const item = element('li'); item.append(link); list.append(item);
        navigationLinks.push({ path: entry.path, link, groupNode, sectionNode });
        trails.set(entry.path, { group: group.label, section: section.label, label: entry.label });
      }
      sectionNode.append(list);
      if (sectionNode !== groupNode) groupNode.append(sectionNode);
    }
    document.getElementById('chapters').append(groupNode);
  }

  function closeMenu() {
    sidebar.hidden = narrow.matches;
    menuToggle.setAttribute('aria-expanded', 'false');
    menuToggle.textContent = 'Browse guides';
  }
  function focusGuide() {
    const target = article.querySelector('h1') || content;
    target.setAttribute('tabindex', '-1');
    target.focus({ preventScroll: true });
  }
  function adaptLayout() {
    const focusWasInSidebar = sidebar.contains(document.activeElement);
    closeMenu();
    if (narrow.matches && focusWasInSidebar) menuToggle.focus();
    pageToc.open = wide.matches;
  }
  menuToggle.addEventListener('click', () => {
    const expanded = menuToggle.getAttribute('aria-expanded') !== 'true';
    sidebar.hidden = !expanded;
    menuToggle.setAttribute('aria-expanded', String(expanded));
    menuToggle.textContent = expanded ? 'Close guides' : 'Browse guides';
  });
  sidebar.addEventListener('keydown', event => {
    if (event.key === 'Escape' && narrow.matches) { closeMenu(); menuToggle.focus(); }
  });
  // Clicking the already-selected guide does not fire hashchange.
  sidebar.addEventListener('click', event => {
    const link = event.target.closest('a');
    if (link && link.getAttribute('href') === location.hash && narrow.matches) {
      closeMenu(); focusGuide();
    }
  });
  narrow.addEventListener('change', adaptLayout);
  wide.addEventListener('change', adaptLayout);
  adaptLayout();

  function updateNavigation(path) {
    for (const item of navigationLinks) {
      if (item.path === path) {
        item.link.setAttribute('aria-current', 'page');
        item.groupNode.open = true;
        item.sectionNode.open = true;
      } else item.link.removeAttribute('aria-current');
    }
    const crumbs = element('ol');
    const home = element('li'); home.append(guideLink('docs/START-HERE.md', 'Handbook')); crumbs.append(home);
    const trail = trails.get(path);
    if (trail) {
      // Keep the current page, but omit adjacent ancestors with the same label.
      const labels = [trail.group, trail.section, trail.label].filter(Boolean);
      const unique = labels.filter((label, index) => label !== labels[index + 1]);
      unique.forEach((label, index) => {
        const crumb = element('li', label);
        if (index === unique.length - 1) crumb.setAttribute('aria-current', 'page');
        crumbs.append(crumb);
      });
    }
    document.getElementById('breadcrumbs').replaceChildren(crumbs);
    closeMenu();
  }

  function buildContents(path) {
    tocLinks.replaceChildren();
    for (const heading of article.querySelectorAll('h1, h2, h3, h4, h5, h6')) heading.setAttribute('tabindex', '-1');
    const headings = article.querySelectorAll('h2, h3');
    for (const heading of headings) {
      const label = heading.textContent;
      const href = `#${path}#${encodeURIComponent(heading.id)}`;
      const link = element('a', label, heading.tagName === 'H3' ? 'toc-subsection' : '');
      link.href = href; tocLinks.append(link);
      const permalink = element('a', '#', 'heading-link');
      permalink.href = href; permalink.setAttribute('aria-label', `Link to ${label}`);
      heading.append(permalink);
    }
    pageToc.hidden = !headings.length;
  }

  function addCodeTools() {
    for (const pre of article.querySelectorAll('pre')) {
      const code = pre.querySelector('code');
      if (!code) continue;
      const wrapper = element('div', undefined, 'code-example');
      const tools = element('div', undefined, 'code-tools');
      const wrap = element('button', 'Wrap lines'); wrap.type = 'button'; wrap.setAttribute('aria-pressed', 'false');
      wrap.addEventListener('click', () => {
        const enabled = pre.classList.toggle('wrap');
        wrap.setAttribute('aria-pressed', String(enabled));
        wrap.textContent = enabled ? 'Unwrap lines' : 'Wrap lines';
      });
      const copy = element('button', 'Copy'); copy.type = 'button'; copy.setAttribute('aria-label', 'Copy code to clipboard');
      copy.addEventListener('click', async () => {
        copy.disabled = true;
        try {
          await navigator.clipboard.writeText(code.textContent);
          copy.textContent = 'Copied'; readerStatus.textContent = 'Code copied. Nothing was executed.';
        } catch {
          // Clipboard access varies under file://. Select only this block for
          // manual copying; never request permissions or execute its contents.
          const selection = window.getSelection();
          if (selection) {
            const range = document.createRange(); range.selectNodeContents(code);
            selection.removeAllRanges(); selection.addRange(range);
          }
          readerStatus.textContent = 'Automatic copy unavailable. Code selected; press Command+C or Control+C to copy.';
          copy.textContent = 'Select and copy';
        } finally { copy.disabled = false; }
      });
      tools.append(wrap, copy); pre.before(wrapper); wrapper.append(tools, pre);
    }
  }

  function buildSequence(path) {
    const sequence = document.getElementById('page-sequence'); sequence.replaceChildren();
    const index = coreSequence.indexOf(path);
    if (index !== -1) {
      for (const [offset, caption, className] of [[-1, 'Previous guide', 'previous'], [1, 'Next guide', 'next']]) {
        const target = coreSequence[index + offset];
        if (!target || !documents.has(target)) continue;
        const link = guideLink(target, trails.get(target)?.label || titles.get(target));
        link.className = className; link.prepend(element('span', caption)); sequence.append(link);
      }
    }
    sequence.hidden = !sequence.children.length;
  }

  function showError(message) {
    currentPath = '';
    article.replaceChildren(element('h1', 'Guide unavailable'), element('p', message), guideLink('docs/README.md', 'Browse all documentation'));
    pageToc.hidden = true;
    document.getElementById('page-sequence').hidden = true;
    updateNavigation(''); document.title = 'Guide unavailable — Day One Mac'; focusGuide();
  }

  function showPage(focus = true) {
    if (location.hash === '#content' && currentPath) { content.focus(); return; }
    const route = location.hash === '#content' ? '' : location.hash.slice(1);
    const [rawPath, rawAnchor = ''] = route.split('#');
    let path, anchor;
    try { path = decodeURIComponent(rawPath || 'docs/START-HERE.md'); anchor = decodeURIComponent(rawAnchor); }
    catch { showError('This documentation link is malformed. Choose a guide from the chapter list or search.'); return; }
    ({ path, anchor } = resolveDocumentationRoute(path, anchor, documents));
    if (!documents.has(path)) { showError('This guide is not in this bundle. Choose another guide or export a newer copy.'); return; }
    if (path !== currentPath) {
      article.innerHTML = documentationRenderer(window.markdownit, documents, path).render(documents.get(path));
      // Markdown guides keep their own navigation for standalone reading.
      // In the browser, place the title first and retain all other content in order.
      const title = Array.from(article.children).find(node => node.tagName === 'H1');
      if (title) article.prepend(title);
      article.prepend(element('p', `Day One Mac ${bundleVersion} · ${path}`, 'source-path'));
      buildContents(path); addCodeTools(); buildSequence(path);
      currentPath = path;
    }
    updateNavigation(path);
    document.title = `${titles.get(path)} — Day One Mac ${bundleVersion}`;
    const heading = anchor && Array.from(article.querySelectorAll('[id]')).find(node => node.id === anchor);
    for (const link of tocLinks.querySelectorAll('a')) {
      if (link.getAttribute('href') === `#${path}#${encodeURIComponent(anchor)}`) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    }
    if (heading) { heading.scrollIntoView(); heading.focus({ preventScroll: true }); }
    else { window.scrollTo(0, 0); if (focus) focusGuide(); }
    readerStatus.textContent = anchor && !heading ? 'That section is not in this guide. Showing the guide from the top.' : '';
  }
  document.getElementById('search').addEventListener('input', event => {
    const query = event.target.value.trim();
    const results = document.getElementById('results');
    results.replaceChildren();
    const status = document.getElementById('search-status');
    if (!query) { status.textContent = ''; return; }
    const matches = findDocumentation(titles, query);
    status.textContent = matches.length
      ? `${matches.length} ${matches.length === 1 ? 'guide matches' : 'guides match'} your title or path search.`
      : 'No matching guides. Try a shorter title or browse the chapters below.';
    for (const [path, title] of matches) {
      results.append(guideLink(path, title));
    }
  });
  window.addEventListener('hashchange', showPage);
  // Initial loading should not steal focus from browser or assistive controls.
  showPage(false);
}
