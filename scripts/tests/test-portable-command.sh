#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-mac-portable-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail_test() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

test_home="$TEST_ROOT/home"
mkdir -p "$test_home"

HOME="$test_home" "$SCRIPT_DIR/install-portable-command.sh" \
  --source "$PROJECT_ROOT" --standalone >/dev/null

portable="$test_home/.local/bin/day-one-mac"
runtime="$test_home/.local/share/day-one-mac/current"
[[ -x "$portable" ]] || fail_test 'portable dispatcher was not installed executable'
[[ -L "$runtime" ]] || fail_test 'standalone current runtime link was not installed'
[[ "$(HOME="$test_home" "$portable" root)" == "$runtime" ]] \
  || fail_test 'portable dispatcher did not resolve the standalone runtime'
HOME="$test_home" "$portable" runtime-status | grep -Fq 'Integrity: verified' \
  || fail_test 'installed runtime did not pass checksum verification'
[[ "$(HOME="$test_home" "$portable" docs)" == *'/docs/START-HERE.md' ]] \
  || fail_test 'installed runtime did not resolve its documentation'
grep -Fqx '[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"' "$test_home/.zprofile" \
  || fail_test 'installer did not add the shared PATH source to .zprofile'
grep -Fq '# Day One Mac bootstrap PATH' "$test_home/.config/zsh/path.zsh" \
  || fail_test 'installer did not create the bootstrap PATH file'
grep -Fq 'runtime-status    show and verify' < <(HOME="$test_home" "$portable" --help) \
  || fail_test 'portable command help does not document the standalone runtime'

# Reinstallation is idempotent: one source line and one stable runtime record.
HOME="$test_home" "$SCRIPT_DIR/install-portable-command.sh" \
  --source "$PROJECT_ROOT" --standalone >/dev/null
[[ "$(grep -Fc '.config/zsh/path.zsh' "$test_home/.zprofile")" == 1 ]] \
  || fail_test 'reinstall duplicated the .zprofile source line'
[[ "$(wc -l < "$test_home/.day-one-mac/runtime-root" | tr -d ' ')" == 1 ]] \
  || fail_test 'recorded runtime root is not one line'

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
mkdir -p "$fixture_repo/scripts" "$fixture_repo/docs" "$bootstrap_home"
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
