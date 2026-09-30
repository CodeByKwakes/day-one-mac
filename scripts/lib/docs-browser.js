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
const coreSequence = [
  'README.md', '01-first-boot-and-decisions.md', 'MACOS-SETTINGS.md',
  '02-command-line-foundation.md', 'INSTALLATION-CENTRE.md',
  '03-security-and-ssh.md', '04-core-tools-and-hosting.md',
  '05-dotfiles-and-shell.md', '06-language-toolchains.md',
  '07-vscode-base.md', '08-verify-and-reproduce.md',
].map(file => `docs/01-required/${file}`);

function documentationNavigation(documents) {
  const claimed = new Set();
  const titles = new Map(Array.from(documents, ([path, text]) => [path, text.match(/^# (.+)$/m)?.[1] || path]));
  const labels = {
    'docs/START-HERE.md': 'Start here',
    'docs/PROCESS-OVERVIEW.md': 'How setup fits together',
    'docs/00-preflight/README.md': 'Before changing an existing Mac',
    'docs/20-reference/TERMINAL-BASICS.md': 'Terminal basics',
    'docs/20-reference/MANUAL-SETUP-GUIDE.md': 'Manual walkthrough',
    'docs/01-required/README.md': 'Script-assisted overview',
    'docs/01-required/MACOS-SETTINGS.md': 'Checkpoint: macOS preferences (optional)',
    'docs/01-required/INSTALLATION-CENTRE.md': 'Checkpoint: Installation Centre',
    'docs/manual/README.md': 'Manual learning guides',
    'docs/manual/chezmoi.md': 'Chezmoi and dotfiles',
    'docs/manual/developer-folders.md': 'Developer folders and ghq',
    'docs/manual/second-brain.md': 'Second Brain setup',
    'docs/manual/security.md': 'Security, SSH and signing',
    'docs/manual/azure-artifacts-npm.md': 'Azure Artifacts: npm authentication',
  };
  const entries = paths => paths.filter(path => documents.has(path) && !claimed.has(path)).map(path => {
    claimed.add(path);
    return { path, label: labels[path] || titles.get(path) };
  });
  const matching = prefix => Array.from(documents.keys()).filter(path => path.startsWith(prefix))
    .sort((a, b) => Number(!a.endsWith('/README.md')) - Number(!b.endsWith('/README.md')) || a.localeCompare(b, 'en', { numeric: true }));
  const groups = [
    { label: 'Start here', sections: [{ label: '', entries: entries([
      'docs/START-HERE.md', 'docs/PROCESS-OVERVIEW.md', 'docs/00-preflight/README.md', 'docs/20-reference/TERMINAL-BASICS.md',
    ]) }] },
    { label: 'Core setup', sections: [
      { label: '', entries: entries(['docs/20-reference/MANUAL-SETUP-GUIDE.md']) },
      { label: 'Script-assisted phases', entries: entries(coreSequence) },
    ] },
    { label: 'Customisation', sections: [
      { label: 'Private package registries', entries: entries(['docs/manual/azure-artifacts-npm.md']) },
      { label: 'Manual learning guides', entries: entries(matching('docs/manual/')) },
      { label: 'Application guides', entries: entries(matching('docs/10-app-guides/')) },
      { label: 'Optional modules', entries: entries(matching('docs/02-optional/')) },
      { label: 'Advanced modules', entries: entries(matching('docs/03-advanced/')) },
    ] },
    { label: 'Reference and recovery', sections: [
      { label: 'Recovery and cleanup', entries: entries(matching('docs/04-operations/')) },
      { label: 'Reference library', entries: entries(matching('docs/20-reference/')) },
      { label: 'Second Brain library', entries: entries(matching('second-brain/')) },
      { label: 'More bundled guides', entries: entries(Array.from(documents.keys())) },
    ] },
  ];
  return { groups, titles };
}

function findDocumentation(titles, query) {
  const term = query.trim().toLowerCase();
  return term ? Array.from(titles).filter(([path, title]) => `${title} ${path}`.toLowerCase().includes(term)) : [];
}

if (typeof module !== 'undefined') module.exports = { documentationRenderer, documentationNavigation, findDocumentation, coreSequence };

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
  const { groups, titles } = documentationNavigation(documents);
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
