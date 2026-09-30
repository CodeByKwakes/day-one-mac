#!/usr/bin/env node
'use strict';
// Dependency-free interaction fixture. Exercises production event handlers;
// this is deliberately not a substitute for browser layout/accessibility QA.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../..');
const markdownit = require('../vendor/markdown-it/markdown-it.min.js');
const decode = text => text.replace(/&(?:amp|lt|gt|quot|#39);/g, value => ({ '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&#39;': "'" })[value]);

class Node {
  constructor(tag, owner) { this.tagName = tag.toUpperCase(); this.owner = owner; this.children = []; this.attributes = {}; this.events = {}; this._text = ''; this.hidden = false; this.open = false; }
  setAttribute(name, value) { this.attributes[name] = String(value); }
  getAttribute(name) { return this.attributes[name] ?? null; }
  removeAttribute(name) { delete this.attributes[name]; }
  get id() { return this.getAttribute('id') || ''; }
  get className() { return this.getAttribute('class') || ''; }
  set className(value) { this.setAttribute('class', value); }
  get href() { return this.getAttribute('href'); }
  set href(value) { this.setAttribute('href', value); }
  get dataset() { return { path: this.getAttribute('data-path') }; }
  get textContent() { return this._text + this.children.map(child => child.textContent).join(''); }
  set textContent(value) { this.children = []; this._text = String(value); }
  append(...nodes) {
    for (const node of nodes) {
      if (node.parent) node.parent.children = node.parent.children.filter(child => child !== node);
      node.parent = this; this.children.push(node);
    }
  }
  prepend(node) { this.append(node); this.children.unshift(this.children.pop()); }
  before(node) { const parent = this.parent; parent.append(node); parent.children.pop(); parent.children.splice(parent.children.indexOf(this), 0, node); }
  replaceChildren(...nodes) { this.children = []; this._text = ''; this.append(...nodes); }
  matches(selector) { return selector === '[id]' ? !!this.id : selector.startsWith('.') ? this.className.split(' ').includes(selector.slice(1)) : this.tagName === selector.toUpperCase(); }
  querySelectorAll(selectors) {
    const values = selectors.split(',').map(value => value.trim());
    const result = [];
    const visit = node => { for (const child of node.children) { if (values.some(value => child.matches(value))) result.push(child); visit(child); } };
    visit(this); return result;
  }
  querySelector(selector) { return this.querySelectorAll(selector)[0] || null; }
  closest(selector) { return this.matches(selector) ? this : this.parent?.closest(selector); }
  contains(node) { return node === this || this.children.some(child => child.contains(node)); }
  get classList() { return { toggle: name => { const values = new Set(this.className.split(' ').filter(Boolean)); const add = !values.has(name); if (add) values.add(name); else values.delete(name); this.className = [...values].join(' '); return add; } }; }
  addEventListener(type, callback) { this.events[type] = callback; }
  fire(type, event = {}) { return this.events[type]?.({ target: this, ...event }); }
  focus() { this.owner.activeElement = this; }
  scrollIntoView() { this.owner.scrolled = this; }
  set innerHTML(html) {
    this.replaceChildren();
    const stack = [this];
    for (const part of html.match(/<!--[\s\S]*?-->|<![^>]*>|<[^>]*>|[^<]+/g) || []) {
      if (part.startsWith('<!')) continue;
      if (part.startsWith('</')) { if (stack.length > 1) stack.pop(); continue; }
      if (part.startsWith('<')) {
        const tag = part.match(/^<([\w-]+)/)?.[1];
        if (!tag) continue;
        const node = new Node(tag, this.owner);
        for (const attr of part.matchAll(/([\w-]+)="([^"]*)"/g)) node.setAttribute(attr[1], decode(attr[2]));
        stack.at(-1).append(node);
        if (!['meta', 'input', 'br', 'hr', 'img', 'link'].includes(tag)) stack.push(node);
      } else {
        const text = new Node('#text', this.owner); text.textContent = decode(part); stack.at(-1).append(text);
      }
    }
  }
}

async function run() {
  const document = {
    createElement(tag) { return new Node(tag, this); },
    querySelectorAll(selector) { return this.body.querySelectorAll(selector); },
    getElementById(id) { return this.body.querySelectorAll('[id]').find(node => node.id === id); },
    createRange() { return { selectNodeContents: node => { document.selected = node; } }; },
  };
  document.body = new Node('body', document);
  document.body.innerHTML = fs.readFileSync(path.join(root, 'scripts/lib/docs-browser.html'), 'utf8');
  const version = document.createElement('div'); version.setAttribute('id', 'bundle-version'); version.textContent = 'test'; document.body.append(version);
  const pages = {
    'docs/START-HERE.md': '[All documentation](README.md)\n\n# Start\n\n## Choose a route\n\nRead the guide.\n\n### Manual\n\n```sh\necho "safe"\n```',
    'docs/README.md': '# All documentation',
    'docs/01-required/01-first-boot-and-decisions.md': '# Phase 1',
    'docs/01-required/MACOS-SETTINGS.md': '# Settings checkpoint',
    'docs/01-required/02-command-line-foundation.md': '# Phase 2',
    'docs/02-optional/09-databases.md': '# Databases',
  };
  for (const [file, text] of Object.entries(pages)) {
    const node = document.createElement('script'); node.className = 'document-data'; node.setAttribute('data-path', file); node.textContent = Buffer.from(text).toString('base64'); document.body.append(node);
  }
  const media = new Map(); const events = {}; const clipboard = [];
  const window = {
    markdownit,
    matchMedia(query) { const value = { matches: query.includes('min-width'), addEventListener: (type, handler) => { value.change = handler; } }; media.set(query, value); return value; },
    addEventListener: (type, handler) => { events[type] = handler; },
    scrollTo() {},
    print() { window.printed = true; },
    getSelection: () => ({ removeAllRanges() {}, addRange() {} }),
  };
  const location = { hash: '' };
  const navigator = { clipboard: { writeText: async text => clipboard.push(text) } };
  const context = vm.createContext({ document, window, location, navigator, URL, TextDecoder, Uint8Array, atob });
  vm.runInContext(fs.readFileSync(path.join(root, 'scripts/lib/docs-browser.js'), 'utf8'), context);
  const get = id => document.getElementById(id);
  const navigate = hash => { location.hash = hash; events.hashchange(); };
  const active = () => get('chapters').querySelectorAll('a').filter(node => node.getAttribute('aria-current') === 'page');

  assert.equal(active().length, 1);
  assert.equal(active()[0].href, '#docs/START-HERE.md');
  assert.equal(document.activeElement, undefined, 'Initial rendering does not steal focus');
  const visibleBlocks = () => get('article').children.filter(node => node.tagName !== '#TEXT');
  assert.equal(visibleBlocks()[0].className, 'source-path');
  assert.equal(visibleBlocks()[1].tagName, 'H1', 'Title appears before legacy guide navigation');
  assert.equal(visibleBlocks()[2].querySelector('a').href, '#docs/README.md', 'Original navigation survives title normalization');
  assert.equal(get('article').querySelectorAll('h1').length, 1, 'Title is moved, never duplicated');
  assert.deepEqual(get('breadcrumbs').querySelectorAll('li').map(node => node.textContent), ['Handbook', 'Start here']);
  assert.equal(get('breadcrumbs').querySelectorAll('li').at(-1).getAttribute('aria-current'), 'page');
  assert.equal(get('toc-links').children.length, 2);
  assert.equal(get('page-toc').open, true);
  const code = get('article').querySelector('code');
  const buttons = get('article').querySelectorAll('button');
  buttons[0].fire('click'); assert.equal(buttons[0].getAttribute('aria-pressed'), 'true');
  await buttons[1].fire('click'); assert.equal(clipboard[0], 'echo "safe"\n');
  navigator.clipboard.writeText = async () => { throw Error('clipboard denied'); };
  await buttons[1].fire('click'); assert.equal(document.selected, code); assert.match(get('reader-status').textContent, /Command\+C/);

  const search = get('search'); search.value = 'phase'; search.fire('input');
  assert.equal(get('results').children.length, 2); assert.match(get('search-status').textContent, /2 guides/);
  search.value = '<script>'; search.fire('input'); assert.equal(get('results').children.length, 0); assert.match(get('search-status').textContent, /No matching/);
  search.value = ''; search.fire('input'); assert.equal(get('search-status').textContent, '');

  navigate('#docs/START-HERE.md#manual'); assert.equal(document.scrolled.id, 'manual');
  assert.equal(document.activeElement.id, 'manual');
  assert.equal(get('article').querySelectorAll('button').length, 2, 'Anchor navigation does not duplicate code controls');
  navigate('#docs/START-HERE.md#missing'); assert.match(get('reader-status').textContent, /not in this guide/);
  navigate('#docs/01-required/01-first-boot-and-decisions.md');
  assert.equal(visibleBlocks()[1].tagName, 'H1', 'Title-first source guides use the same browser order');
  assert.equal(document.activeElement, get('article').querySelector('h1'), 'Guide navigation focuses its heading, not the reading pane');
  assert.equal(get('page-sequence').querySelector('a').href, '#docs/01-required/MACOS-SETTINGS.md');
  assert.equal(get('page-toc').hidden, true);
  navigate('#docs/02-optional/09-databases.md'); assert.equal(get('page-sequence').hidden, true);
  assert.match(get('breadcrumbs').textContent, /Customisation/);
  assert.equal(active().length, 1);
  navigate('#missing.md'); assert.match(get('article').textContent, /Guide unavailable/); assert.equal(active().length, 0);
  assert.equal(document.activeElement, get('article').querySelector('h1'));
  navigate('#%ZZ'); assert.match(get('article').textContent, /malformed/);
  navigate('#docs/START-HERE.md'); assert.equal(active().length, 1);

  const narrow = media.get('(max-width: 760px)'); narrow.matches = true; narrow.change();
  assert.equal(get('sidebar').hidden, true);
  get('menu-toggle').fire('click'); assert.equal(get('sidebar').hidden, false); assert.equal(get('menu-toggle').getAttribute('aria-expanded'), 'true');
  get('sidebar').fire('keydown', { key: 'Escape' }); assert.equal(get('sidebar').hidden, true); assert.equal(document.activeElement, get('menu-toggle'));
  get('menu-toggle').fire('click'); navigate('#docs/01-required/02-command-line-foundation.md'); assert.equal(get('sidebar').hidden, true);
  get('menu-toggle').fire('click'); get('sidebar').fire('click', { target: active()[0] });
  assert.equal(get('sidebar').hidden, true);
  assert.equal(document.activeElement, get('article').querySelector('h1'), 'Selecting the current mobile guide restores heading focus');
  narrow.matches = false; narrow.change(); assert.equal(get('sidebar').hidden, false);
  get('print').fire('click'); assert.equal(window.printed, true);
  navigate('#content'); assert.equal(document.activeElement, get('content'));
  console.log('PASS: offline reader navigation, anchors, search feedback, menu, copy fallback, wrapping and print events (DOM fixture)');
}
run().catch(error => { console.error(error); process.exitCode = 1; });
