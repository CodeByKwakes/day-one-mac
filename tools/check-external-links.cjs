#!/usr/bin/env node
'use strict';
// Contributor-only network check. Normal validation uses injected offline fixtures.
const fs = require('node:fs');
const path = require('node:path');
const markdown = require('./vendor/markdown-it/markdown-it.min.js')();

function publicUrl(value) {
  let url;
  try { url = new URL(value); } catch { return null; }
  if (!['https:', 'http:'].includes(url.protocol) || url.username || url.password) return null;
  const host = url.hostname.toLowerCase();
  if (!host.includes('.') || /(?:^|\.)(?:localhost|local|internal|test|invalid|example)$/.test(host)
      || /(?:^|\.)example\.(?:com|org|net)$/.test(host)) return null;
  if (/^(?:0|10|127)\.|^169\.254\.|^192\.168\.|^172\.(?:1[6-9]|2\d|3[01])\./.test(host)) return null;
  // IPv6 literals and documentation/address-only targets are not public reference pages.
  if (host.startsWith('[') || /^\d+(?:\.\d+){3}$/.test(host)) return null;
  url.hash = '';
  return url.href;
}

function collectLinks(documents) {
  const links = new Map();
  for (const [file, text] of documents) {
    if (file === 'CHANGELOG.md' || file.startsWith('maintainers/') || text.includes('<!-- day-one-mac:compatibility-guide -->')) continue;
    const visit = tokens => { for (const token of tokens) {
      const url = publicUrl(token.attrGet('href') || token.attrGet('src'));
      if (url) {
        if (!links.has(url)) links.set(url, new Set());
        links.get(url).add(file);
      }
      if (token.children) visit(token.children);
    } };
    visit(markdown.parse(text, {}));
  }
  return [...links].sort(([a], [b]) => a.localeCompare(b)).map(([url, files]) => ({url, files:[...files].sort()}));
}

async function checkLinks(links, {fetchImpl = globalThis.fetch, timeoutMs = 10000, concurrency = 6, maxRedirects = 5} = {}) {
  const results = new Array(links.length);
  let next = 0;
  async function check(link) {
    let current = publicUrl(link.url);
    if (!current) return {...link, status:'unverified', reason:'Excluded destination'};
    const signal = AbortSignal.timeout(timeoutMs);
    try {
      for (let redirects = 0; redirects <= maxRedirects; redirects++) {
        const response = await fetchImpl(current, {redirect:'manual', signal, headers:{'User-Agent':'DayOneMacDocumentationCheck/1.0'}});
        const status = response.status;
        const location = response.headers.get('location');
        await response.body?.cancel();
        if ([301,302,303,307,308].includes(status) && location) {
          const target = publicUrl(new URL(location, current).href);
          if (!target) return {...link, status:'unverified', reason:'Redirect to excluded destination'};
          current = target;
          continue;
        }
        return {...link, finalUrl:current, httpStatus:status,
          status:status >= 200 && status < 300 ? 'ok' : [404,410].includes(status) ? 'broken' : 'unverified'};
      }
      return {...link, status:'unverified', reason:'Redirect limit exceeded'};
    } catch (error) {
      return {...link, status:'unverified', reason:error.cause?.code || error.name || 'Network error'};
    }
  }
  async function worker() {
    while (next < links.length) {
      const index = next++;
      results[index] = await check(links[index]);
    }
  }
  await Promise.all(Array.from({length:Math.min(concurrency, links.length)}, worker));
  return results;
}

function exitStatus(results) {
  return results.some(r => r.status === 'broken') ? 1 : results.some(r => r.status === 'unverified') ? 2 : 0;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 1 && args[0] === '--help') {
    console.log('Usage: node tools/check-external-links.cjs [--json]\nChecks public Markdown links with six concurrent GET requests and a 10-second timeout per URL.\nExits: 0 reachable; 1 HTTP 404/410; 2 unverified response, network failure or usage error.');
    return;
  }
  if (args.length > 1 || (args.length && args[0] !== '--json')) throw Error('Usage: node tools/check-external-links.cjs [--json]');
  const root = path.resolve(__dirname, '..');
  const sources = fs.readFileSync(path.join(root, 'config/document-sources.txt'), 'utf8').split('\n')
    .filter(file => file && !file.startsWith('#') && file.endsWith('.md'));
  const documents = new Map(sources.map(file => [file, fs.readFileSync(path.join(root, file), 'utf8')]));
  const results = await checkLinks(collectLinks(documents));
  const summary = {checked:results.length, reachable:results.filter(r => r.status === 'ok').length,
    broken:results.filter(r => r.status === 'broken').length, unverified:results.filter(r => r.status === 'unverified').length};
  console.log(JSON.stringify({summary, results:args[0] === '--json' ? results : results.filter(r => r.status !== 'ok')}, null, 2));
  process.exitCode = exitStatus(results);
}
if (require.main === module) main().catch(error => {console.error(error.message); process.exitCode = 2;});
module.exports = {collectLinks, checkLinks, exitStatus};
