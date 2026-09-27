'use strict';
const { fs, path, need, plain, safe, read, rows, command, writeNew } = require('./review-io.cjs');
need(Number(process.versions.node.split('.')[0]) >= 22, 'Node 22+ is required.');
const [action, target] = process.argv.slice(2);
function selection(text) {
  const selected = rows(text), seen = new Set();
  for (const row of selected) {
    need(row.length === 6 && row[0] === 'repository', 'Expected repository, checkout, name, email, signing (ssh/openpgp/off), layout root.');
    const [, repo, name, email, signing, root] = row;
    safe(repo); safe(root);
    need(name.length <= 200 && /^[^\s@]+@[^\s@]+$/.test(email) && ['ssh', 'openpgp', 'off'].includes(signing), 'Invalid expected identity/signing policy.');
    need(!seen.has(repo), 'Duplicate repository selection.'); seen.add(repo);
    need(repo.startsWith(root + '/'), 'Selected checkout must be below the explicit layout root.');
  }
  return selected;
}
// Ignore caller Git overrides, but retain real system/global/local includes.
// Only fixed built-in metadata commands: no status, hooks, aliases or signing.
const gitEnv = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith('GIT_')));
Object.assign(gitEnv, { GIT_OPTIONAL_LOCKS: '0', GIT_TERMINAL_PROMPT: '0', GIT_PAGER: 'cat', LC_ALL: 'C' });
function git(repo, ...args) { return command('git', ['-C', repo, ...args], { env: gitEnv }); }
function config(repo, key, bool = false) {
  // --get absent exits 1; inspect only this fixed key.
  const { spawnSync } = require('node:child_process');
  const r = spawnSync('git', ['-C', repo, 'config', ...(bool ? ['--bool'] : []), '--get', key], { env: gitEnv, encoding: 'utf8', timeout: 15000, maxBuffer: 1024 * 1024 });
  need(!r.error && (r.status === 0 || r.status === 1), 'Cannot read effective Git setting.');
  if (r.status === 1) return '';
  const value = r.stdout.replace(/\n$/, '');
  need(plain(value) || value === '', 'Git setting contains unsafe control characters.');
  return value;
}
function inspect(row) {
  const [, repo, name, email, signing, root] = row;
  safe(repo);
  need(fs.statSync(repo).isDirectory(), 'Checkout is not a directory.');
  need(git(repo, 'rev-parse', '--show-toplevel').trimEnd() === repo, 'Select the checkout root, not a nested directory or bare repository.');
  const gitdir = git(repo, 'rev-parse', '--absolute-git-dir').trimEnd(); safe(gitdir);
  const actualName = config(repo, 'user.name'), actualEmail = config(repo, 'user.email');
  const enabled = config(repo, 'commit.gpgsign', true) === 'true';
  const format = config(repo, 'gpg.format') || 'openpgp';
  const keyConfigured = !!config(repo, 'user.signingkey');
  let signersReadable = false;
  if (enabled && format === 'ssh') {
    let signers = config(repo, 'gpg.ssh.allowedSignersFile');
    if (signers.startsWith('~/')) signers = path.join(process.env.HOME, signers.slice(2));
    if (signers) { safe(signers); const fd = require('./review-io.cjs').openFile(signers); fs.closeSync(fd); signersReadable = true; }
  }
  const raw = git(repo, 'worktree', 'list', '--porcelain', '-z').split('\0');
  const worktrees = []; let item;
  for (const field of raw) {
    if (field.startsWith('worktree ')) { item = { path: field.slice(9), detached: false, prunable: false, locked: false }; worktrees.push(item); }
    else if (item && field === 'detached') item.detached = true;
    else if (item && (field === 'prunable' || field.startsWith('prunable '))) item.prunable = true;
    else if (item && (field === 'locked' || field.startsWith('locked '))) item.locked = true;
  }
  need(worktrees.length > 0, 'No worktree metadata was returned.');
  for (const wt of worktrees) {
    safe(wt.path);
    wt.inLayout = wt.path.startsWith(root + '/');
    wt.exists = fs.existsSync(wt.path) && fs.statSync(wt.path).isDirectory();
  }
  const identityMatches = actualName === name && actualEmail === email;
  const signingMatches = signing === 'off' ? !enabled : enabled && format === signing && keyConfigured && (signing !== 'ssh' || signersReadable);
  const layoutMatches = worktrees.every(wt => wt.inLayout && wt.exists && !wt.detached && !wt.prunable);
  return { repository: repo, gitdir, result: identityMatches && signingMatches && layoutMatches ? 'PASS' : 'FAIL', actualName, actualEmail, identityMatches, signingMatches, signingEnabled: enabled, signingFormat: format, keyConfigured, signersReadable, layoutMatches, worktrees };
}
try {
  if (action === 'selection') {
    process.stdout.write(selection(read(target)).map(row => row.join('\t')).join('\n') + '\n');
  } else {
    const selected = selection(fs.readFileSync(0, 'utf8'));
    const evidence = selected.map(row => { try { return inspect(row); } catch (error) { return { repository: row[1], result: 'FAIL', reason: error.message }; } });
    if (action === 'evidence') {
      for (const item of evidence) process.stdout.write(`repository\t${item.repository}\t${item.result}\t${JSON.stringify(item)}\n`);
    } else if (action === 'outputs') {
      const proposals = selected.map((row, i) => ({ checkout: row[1], observedGitDirectory: evidence[i].gitdir || null, expectedName: row[2], expectedEmail: row[3], expectedSigning: row[4], layoutRoot: row[5], fragment: `identity-${i + 1}.gitconfig`, review: 'Review existing configuration ownership and includeIf gitdir routing, including linked-worktree Git directories. Do not replace global/local configuration. Signing keys, allowed signers and provider authentication remain manual.' }));
      writeNew(path.join(target, 'identity-proposals.json'), JSON.stringify(proposals, null, 2) + '\n');
      for (const proposal of proposals) {
        const quote = value => '"' + value.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"';
        let fragment = `# REVIEW ONLY: merge deliberately; do not replace existing configuration.\n[user]\n\tname = ${quote(proposal.expectedName)}\n\temail = ${quote(proposal.expectedEmail)}\n[commit]\n\tgpgsign = ${proposal.expectedSigning !== 'off'}\n`;
        if (proposal.expectedSigning !== 'off') fragment += `[gpg]\n\tformat = ${proposal.expectedSigning}\n# Signing key and allowed signers must be reviewed separately.\n`;
        writeNew(path.join(target, proposal.fragment), fragment);
      }
    } else throw new Error('Unknown identity action.');
  }
} catch (error) { process.stderr.write(`${error.message}\n`); process.exitCode = 1; }
