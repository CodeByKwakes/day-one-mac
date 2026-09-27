# No package commands run when this file is sourced or when inspecting a project.
function day_one_pm_for_dir() {
  command -v node >/dev/null 2>&1 || { print -u2 'Install the required Node runtime first.'; return 1; }
  NODE_OPTIONS='' NODE_PATH='' NODE_V8_COVERAGE='' NODE_COMPILE_CACHE='' \
    NODE_REDIRECT_WARNINGS='' NODE_DISABLE_COMPILE_CACHE=1 command node <<'NODE'
const fs = require('node:fs');
function fail(message) { console.error(message); process.exit(1); }
if (Number(process.versions.node.split('.')[0]) < 22) fail('Node 22+ must already be on PATH.');
function regular(path) {
  try { const stat = fs.lstatSync(path); if (!stat.isFile()) fail('Refusing a non-regular project manifest/lockfile.'); return true; }
  catch (error) { if (error.code === 'ENOENT') return false; fail('Cannot inspect project metadata.'); }
}
if (!regular('package.json')) fail('No package.json in the current directory.');
let pkg;
try { pkg = JSON.parse(fs.readFileSync('package.json', 'utf8')); }
catch { fail('package.json is not readable JSON.'); }
if (!pkg || Array.isArray(pkg) || typeof pkg !== 'object') fail('package.json must be an object.');
const pnpm = regular('pnpm-lock.yaml');
const npmLock = regular('package-lock.json');
const npmShrinkwrap = regular('npm-shrinkwrap.json');
const npm = npmLock || npmShrinkwrap;
for (const file of ['yarn.lock', 'bun.lock', 'bun.lockb']) {
  if (regular(file)) fail('Unsupported lockfile; review the project manually.');
}
if (pnpm && npm) fail('Conflicting npm and pnpm lockfiles.');
let declared = '';
if (Object.hasOwn(pkg, 'packageManager')) {
  if (typeof pkg.packageManager !== 'string' || !/^(npm|pnpm)@\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/.test(pkg.packageManager)) {
    fail('Declare a supported npm or pnpm version; no tool will be downloaded.');
  }
  declared = pkg.packageManager.split('@')[0];
}
const locked = pnpm ? 'pnpm' : npm ? 'npm' : '';
if (declared && locked && declared !== locked) fail('packageManager conflicts with the lockfile.');
if (!declared && !locked) fail('No unambiguous package manager declaration or lockfile.');
console.log(declared || locked);
NODE
}

function day_one_pm_frozen_plan() {
  local manager
  manager="$(day_one_pm_for_dir)" || return
  case "$manager" in
    npm)
      [[ -f package-lock.json || -f npm-shrinkwrap.json ]] || { print -u2 'A committed npm lockfile is required.'; return 1; }
      print -r -- 'Review before running: npm ci' ;;
    pnpm)
      [[ -f pnpm-lock.yaml ]] || { print -u2 'A committed pnpm lockfile is required.'; return 1; }
      print -r -- 'Review before running: pnpm install --frozen-lockfile' ;;
  esac
}
