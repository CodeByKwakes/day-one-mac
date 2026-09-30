#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-mac-portable-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail_test() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# Reproduce Git's pre-push environment using disposable repositories only.
# A stub validator verifies isolation before creating its own fixture repository.
hook_parent="$TEST_ROOT/hook-parent"
hook_fixture="$TEST_ROOT/hook-fixture"
mkdir -p "$hook_parent" "$hook_fixture/scripts"
git -C "$hook_parent" init -q
cp "$hook_parent/.git/config" "$TEST_ROOT/hook-parent-config"
cat > "$hook_fixture/scripts/validate.sh" <<'HOOK_FIXTURE'
#!/usr/bin/env bash
set -euo pipefail
for git_env_name in $(git rev-parse --local-env-vars); do
  if printenv "$git_env_name" >/dev/null; then
    printf 'Repository-local variable leaked: %s\n' "$git_env_name" >&2
    exit 1
  fi
done
git init -q
[[ -d .git && "$(git rev-parse --is-bare-repository)" == false ]]
HOOK_FIXTURE
chmod +x "$hook_fixture/scripts/validate.sh"
(
  cd "$hook_fixture"
  GIT_DIR="$hook_parent/.git" GIT_WORK_TREE="$hook_parent" \
    GIT_COMMON_DIR="$hook_parent/.git" GIT_INDEX_FILE="$hook_parent/.git/index" \
    GIT_PREFIX=fixture/ GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0=core.bare GIT_CONFIG_VALUE_0=true \
    sh "$PROJECT_ROOT/.husky/pre-push"
) || fail_test 'pre-push leaked repository-local Git environment into validation'
cmp -s "$TEST_ROOT/hook-parent-config" "$hook_parent/.git/config" \
  || fail_test 'pre-push fixture changed the parent repository configuration'

test_home="$TEST_ROOT/home"
mkdir -p "$test_home"

HOME="$test_home" "$SCRIPT_DIR/install-portable-command.sh" \
  --source "$PROJECT_ROOT" --version test-1.0.0 --standalone >/dev/null

portable="$test_home/.local/bin/day-one-mac"
runtime="$test_home/.local/share/day-one-mac/current"
[[ -x "$portable" ]] || fail_test 'portable dispatcher was not installed executable'
[[ -L "$runtime" ]] || fail_test 'standalone current runtime link was not installed'
HOME="$test_home" "$portable" optional --list | grep -Fq $'13\toptional\texecutable' \
  || fail_test 'standalone runtime omitted the executable module registry'
HOME="$test_home" "$portable" optional --list | grep -Fq $'10\toptional\texecutable' \
  || fail_test 'standalone runtime omitted executable AI payloads'
HOME="$test_home" "$portable" optional --list | grep -Fq $'16\tadvanced\texecutable' \
  || fail_test 'standalone runtime omitted executable software selections'
[[ -x "$runtime/scripts/configure-software.sh" ]] \
  || fail_test 'standalone runtime omitted the software runner'
for module in 10A 11 12 14 15 17 18 19 20 21 22; do
  HOME="$test_home" "$portable" optional --list | grep -Eq "^${module}[[:space:]].*[[:space:]]executable[[:space:]]" \
    || fail_test "standalone runtime omitted artifact module $module"
done
HOME="$test_home" "$runtime/scripts/configure-omniroute.sh" --help | grep -Fq 'never adopts, replaces or deletes' \
  || fail_test 'standalone gateway runner cannot resolve its dependencies'
HOME="$test_home" "$runtime/scripts/configure-preferences.sh" --help | grep -Fq 'Typed originals' \
  || fail_test 'standalone preference runner cannot resolve its dependencies'
HOME="$test_home" "$runtime/scripts/configure-restore.sh" --help | grep -Fq 'No recursive or live restore' \
  || fail_test 'standalone restore runner cannot resolve its dependencies'
for helper in review-io.cjs identity-review.cjs restore-staging.cjs review-node.sh; do
  [[ -f "$runtime/scripts/lib/$helper" ]] || fail_test "standalone review helper missing: $helper"
done
[[ -f "$runtime/config/shell-helpers/packages.zsh" && -f "$runtime/config/shell-helpers/navigation.zsh" ]] \
  || fail_test 'standalone helper templates are missing'
HOME="$test_home" "$runtime/scripts/configure-artifacts.sh" --help | grep -Fq 'publishes a new private version' \
  || fail_test 'standalone artifact runner cannot resolve its dependencies'
HOME="$test_home" "$runtime/scripts/configure-software.sh" --help | grep -Fq 'Default VS Code profile' \
  || fail_test 'standalone software runner cannot resolve its dependencies'
[[ ! -e "$runtime/node_modules" ]] \
  || fail_test 'standalone runtime included contributor-only node_modules'
[[ "$(HOME="$test_home" "$portable" root)" == "$runtime" ]] \
  || fail_test 'portable dispatcher did not resolve the standalone runtime'
HOME="$test_home" "$portable" runtime-status | grep -Fq 'Integrity: verified' \
  || fail_test 'installed runtime did not pass checksum verification'
HOME="$test_home" "$portable" runtime-status | grep -Fq 'Version:   test-1.0.0' \
  || fail_test 'first runtime version was not activated'
[[ "$(HOME="$test_home" "$portable" docs)" == *'/docs/START-HERE.md' ]] \
  || fail_test 'installed runtime did not resolve its documentation'
docs_list="$(HOME="$test_home" "$portable" docs --list)"
grep -Fq 'manual' <<<"$docs_list" \
  || fail_test 'installed runtime did not list documentation topics'
grep -Fq 'chezmoi' <<<"$docs_list" \
  || fail_test 'installed runtime did not list the chezmoi documentation topic'
[[ "$(HOME="$test_home" "$portable" docs manual)" == *'/docs/20-reference/MANUAL-SETUP-GUIDE.md' ]] \
  || fail_test 'installed runtime did not resolve the manual setup guide'
[[ "$(HOME="$test_home" "$portable" docs chezmoi)" == *'/docs/20-reference/CHEZMOI-SETUP-TUTORIAL.md' ]] \
  || fail_test 'installed runtime did not resolve the chezmoi setup tutorial'
[[ "$(HOME="$test_home" "$portable" docs --folder)" == *'/docs' ]] \
  || fail_test 'installed runtime did not resolve the documentation folder'
docs_help="$(HOME="$test_home" "$portable" docs --help)"
grep -Fq 'Topics: start, index, manual' <<<"$docs_help" \
  || fail_test 'installed runtime documentation help is incomplete'
grep -Fqx '[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"' "$test_home/.zprofile" \
  || fail_test 'installer did not add the shared PATH source to .zprofile'
grep -Fq '# Day One Mac bootstrap PATH' "$test_home/.config/zsh/path.zsh" \
  || fail_test 'installer did not create the bootstrap PATH file'
grep -Fq 'runtime-status    show and verify' < <(HOME="$test_home" "$portable" --help) \
  || fail_test 'portable command help does not document the standalone runtime'
HOME="$test_home" "$portable" --help | awk '
  /  setup \[options\]/ { getline; if ($0 ~ /--phase NN selects phases/) found=1 }
  END { exit !found }
' || fail_test 'setup action help must stay under setup, not folders'

# Installing a second version must replace the current symlink itself. On
# macOS, a plain `mv -f next current` follows a directory symlink and silently
# leaves the old version active; this fixture prevents that regression.
HOME="$test_home" "$SCRIPT_DIR/install-portable-command.sh" \
  --source "$PROJECT_ROOT" --version test-2.0.0 --standalone >/dev/null
[[ "$(readlink "$runtime")" == 'releases/test-2.0.0' ]] \
  || fail_test 'second install did not switch the current runtime symlink'
HOME="$test_home" "$portable" runtime-status | grep -Fq 'Version:   test-2.0.0' \
  || fail_test 'second runtime version was not activated'
[[ "$(grep -Fc '.config/zsh/path.zsh' "$test_home/.zprofile")" == 1 ]] \
  || fail_test 'reinstall duplicated the .zprofile source line'
[[ "$(wc -l < "$test_home/.day-one-mac/runtime-root" | tr -d ' ')" == 1 ]] \
  || fail_test 'recorded runtime root is not one line'

# Rollback uses the same symlink replacement boundary and must also activate
# the requested verified version instead of moving a link into the old target.
HOME="$test_home" "$portable" rollback-runtime \
  --version test-1.0.0 --execute >/dev/null
[[ "$(readlink "$runtime")" == 'releases/test-1.0.0' ]] \
  || fail_test 'rollback did not switch the current runtime symlink'
HOME="$test_home" "$portable" runtime-status | grep -Fq 'Version:   test-1.0.0' \
  || fail_test 'rolled-back runtime version was not activated'

# Default rollback follows activation history, including a forward toggle.
HOME="$test_home" "$portable" rollback-runtime --execute >/dev/null
[[ "$(readlink "$runtime")" == 'releases/test-2.0.0' ]] || fail_test 'rollback guessed version order instead of previous activation'
if HOME="$test_home" "$portable" uninstall-runtime --execute --unexpected >/dev/null 2>&1; then
  fail_test 'uninstall accepted unknown trailing argument'
fi
[[ -x "$portable" ]] || fail_test 'invalid uninstall removed launcher'
if HOME="$test_home" "$portable" rollback-runtime --version ../escape --execute >/dev/null 2>&1; then
  fail_test 'rollback accepted a path traversal version'
fi
HOME="$TEST_ROOT/linked-home" "$SCRIPT_DIR/install-portable-command.sh" --source "$PROJECT_ROOT" --linked >/dev/null
[[ "$(HOME="$TEST_ROOT/linked-home" "$TEST_ROOT/linked-home/.local/bin/day-one-mac" root)" == "$PROJECT_ROOT" ]] || fail_test 'linked development installation failed'

# A downloaded dispatcher must explain installation without prior state.
downloaded="$TEST_ROOT/downloaded-day-one-mac"
cp "$SCRIPT_DIR/day-one-mac" "$downloaded"
chmod +x "$downloaded"
HOME="$TEST_ROOT/empty-home" "$downloaded" --help >/dev/null
set +e
missing_output="$(HOME="$TEST_ROOT/empty-home" "$downloaded" root 2>&1)"
missing_status=$?
set -e
[[ "$missing_status" != 0 ]] || fail_test 'downloaded dispatcher accepted root without a runtime'
grep -Fq './day-one-mac bootstrap' <<<"$missing_output" \
  || fail_test 'downloaded dispatcher did not explain how to bootstrap'

# Exercise download-before-clone without network access. The cloned source is
# separate from the installed runtime and may be removed after installation.
fixture_repo="$TEST_ROOT/bootstrap-source"
fixture_checkout="$TEST_ROOT/bootstrap-checkout"
bootstrap_home="$TEST_ROOT/bootstrap-home"
mkdir -p "$fixture_repo/scripts/lib" "$fixture_repo/docs" "$fixture_repo/config" "$bootstrap_home"
for helper in state runtime-package runtime-activation operation-lock; do
  cp "$SCRIPT_DIR/lib/$helper.sh" "$fixture_repo/scripts/lib/"
done
cp "$SCRIPT_DIR/with-operation-lock.sh" "$fixture_repo/scripts/"
printf '%s\n' VERSION docs/START-HERE.md config/runtime-files.txt \
  scripts/day-one-mac scripts/install-portable-command.sh scripts/runtime-manager.sh \
  scripts/bootstrap-day-one-mac.sh scripts/with-operation-lock.sh \
  scripts/lib/state.sh scripts/lib/runtime-package.sh scripts/lib/runtime-activation.sh \
  scripts/lib/operation-lock.sh > "$fixture_repo/config/runtime-files.txt"
cp "$SCRIPT_DIR/day-one-mac" "$fixture_repo/scripts/day-one-mac"
cp "$SCRIPT_DIR/install-portable-command.sh" "$fixture_repo/scripts/install-portable-command.sh"
cp "$SCRIPT_DIR/runtime-manager.sh" "$fixture_repo/scripts/runtime-manager.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$fixture_repo/scripts/bootstrap-day-one-mac.sh"
printf '# Test\n' > "$fixture_repo/docs/START-HERE.md"
printf 'test-1.0.0\n' > "$fixture_repo/VERSION"
chmod +x "$fixture_repo/scripts/"*.sh "$fixture_repo/scripts/day-one-mac"
git -C "$fixture_repo" init -q
git -C "$fixture_repo" add .
git -C "$fixture_repo" -c user.name='Day One Test' -c user.email='test@example.invalid' \
  commit -qm 'fixture'
HOME="$bootstrap_home" "$downloaded" bootstrap \
  --repository "$fixture_repo" --checkout "$fixture_checkout" >/dev/null
bootstrapped="$bootstrap_home/.local/bin/day-one-mac"
[[ -x "$bootstrapped" ]] || fail_test 'downloaded dispatcher did not install itself after cloning'
rm -rf "$fixture_checkout"
HOME="$bootstrap_home" "$bootstrapped" runtime-status | grep -Fq 'Integrity: verified' \
  || fail_test 'standalone runtime stopped working after its cloned source was removed'

printf 'PASS: standalone portable runtime is verified, idempotent and checkout-independent\n'
