'use strict';
const assert = require('node:assert/strict');
const { fs, path, project, execute, write, newOutput } = require('../lib/acceptance-helpers.cjs');
const { parse, summarize } = require('../lib/release-readiness.cjs');
const root = fs.mkdtempSync('/private/tmp/day-one-acceptance-contract.');
try {
  assert.equal(parse(['--plan']).action, '--plan');
  assert(parse(['--run','--output-dir',`${root}/new`,'--native-volume']).native);
  for (const args of [[], ['--run'], ['--plan','--run'], ['--run','--output-dir','--native-volume'], ['--plan','--native-volume','--native-volume']]) assert.throws(() => parse(args));
  const gates = ['build','lint','workflow-lint','validation','packaged-runtime','native-volume'].map(id => ({ id, status: 'passed' }));
  assert(summarize(gates, true, true).candidateChecksPassed);
  assert.equal(summarize(gates, true, true).releaseApproved, false);
  assert(!summarize([], true, true).automatedPassed);
  assert(!summarize(gates.filter(g => g.id !== 'lint'), true, true).automatedPassed);
  assert(!summarize(gates, false, true).candidateChecksPassed);
  assert(!summarize(gates, true, false).candidateChecksPassed);
  gates.at(-1).status = 'skipped';
  assert(summarize(gates, true, true).automatedPassed);
  assert(!summarize(gates, true, true).candidateChecksPassed);
  gates[1].status = 'failed'; assert(!summarize(gates, true, true).automatedPassed);
  gates[1].status = 'running'; assert(!summarize(gates, true, true).automatedPassed);
  const output = path.join(root, 'must-not-exist');
  for (const script of ['release-readiness.sh','rehearse-mounted-restore.sh']) {
    const printed = execute(path.join(project, 'scripts', script), ['--plan','--output-dir',output]);
    assert(printed.includes('Plan only')); assert(!fs.existsSync(output));
  }
  newOutput(output); write(path.join(output, 'native-result.json'), 'existing evidence\n');
  assert.throws(() => newOutput(output));
  for (const script of ['release-readiness.sh','rehearse-mounted-restore.sh']) {
    execute(path.join(project, 'scripts', script), ['--run','--output-dir',output], { expected: 1 });
    assert.equal(fs.readFileSync(path.join(output, 'native-result.json'), 'utf8'), 'existing evidence\n');
  }
  fs.symlinkSync(output, path.join(root, 'alias'));
  assert.throws(() => newOutput(path.join(root, 'alias/new')));
  console.log('PASS: read-only acceptance plans, strict CLI parsing, no-overwrite outputs and honest gate classification');
} finally { fs.rmSync(root, { recursive: true, force: true }); }
