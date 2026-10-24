#!/usr/bin/env node
'use strict';
const assert = require('node:assert/strict');
const { check } = require('../../helpers/check.cjs');
const seen = [];
const results = check((program,args,options) => {
  seen.push([program,args]);
  assert.equal(options.shell,false);
  assert.equal(options.timeout,5000);
  if(program==='docker') return {status:1,stderr:'private account data'};
  return {status:0,stdout:'version 24.3.1 private-local-information'};
});
assert.equal(seen.length,4);
assert(seen.every(([,args])=>args.length===1 && args[0]==='--version'));
assert.equal(results[3].status,'not available');
assert(!JSON.stringify(results).includes('private'));
assert.equal(results[0].version,'24.3.1');
console.log('PASS: bounded read-only version checks redact unneeded command output');
