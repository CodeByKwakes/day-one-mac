#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const { collectLinks, checkLinks, exitStatus } = require('../../tools/check-external-links.cjs');

async function main() {
  const docs = new Map([
    ['guide.md', '[One](https://vendor.dev/guide#one) [Two](https://vendor.dev/guide#two)\n' +
      '[Local](http://127.0.0.1:20128) [Private](http://192.168.1.2) [IPv6](http://[::1]) ' +
      '[Example](https://example.com/path) [Internal](http://desk.local)'],
    ['other.md', '[Again](https://vendor.dev/guide)'],
    ['old.md', '<!-- day-one-mac:compatibility-guide -->\n[Old](https://old.dev/)'],
    ['CHANGELOG.md', '[History](https://history.dev/)'],
  ]);
  const links = collectLinks(docs);
  assert.deepEqual(links, [{url:'https://vendor.dev/guide', files:['guide.md', 'other.md']}]);
  const calls = [];
  let cancelled = 0;
  const response = (status, location) => ({status, headers:{get:() => location}, body:{cancel:async () => {cancelled++;}}});
  const fetchImpl = async (url, options) => {
    calls.push(url);
    assert.equal(options.redirect, 'manual');
    assert(options.signal instanceof AbortSignal);
    if (url.endsWith('/redirect')) return response(302, '/guide');
    if (url.endsWith('/internal')) return response(302, 'http://127.0.0.1:20128/');
    if (url.endsWith('/loop')) return response(302, '/loop');
    if (url.endsWith('/missing')) return response(404);
    if (url.endsWith('/blocked')) return response(403);
    if (url.endsWith('/network')) throw new Error('network unavailable');
    return response(200);
  };
  const inputs = ['redirect','internal','loop','missing','blocked','network'].map(name => ({url:`https://vendor.dev/${name}`,files:['guide.md']}));
  const results = await checkLinks(inputs, {fetchImpl, maxRedirects:2, concurrency:2});
  assert.deepEqual(results.map(r => r.status), ['ok','unverified','unverified','broken','unverified','unverified']);
  assert.equal(results[0].finalUrl, 'https://vendor.dev/guide');
  assert(!calls.some(url => url.includes('127.0.0.1')), 'Redirects must not probe local services');
  assert(cancelled >= 7, 'Response bodies must be released without downloading entire pages');
  assert.equal(exitStatus(results), 1);
  assert.equal(exitStatus(results.filter(r => r.status !== 'broken')), 2);
  assert.equal(exitStatus([results[0]]), 0);
  console.log('PASS: external links deduplicate fragments, exclude local/example/history URLs, bound redirects and distinguish broken from unverified responses (offline fixtures)');
}
main().catch(error => {console.error(error); process.exitCode = 1;});
