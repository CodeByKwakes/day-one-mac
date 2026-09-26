#!/usr/bin/env bash
# Behavioral audit regressions: source real production functions, never copied bodies.
set -euo pipefail
TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_PROJECT="$(cd "$TEST_SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-mac-audit-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
source "$TEST_SCRIPT_DIR/lib/runtime-package.sh"
source "$TEST_SCRIPT_DIR/lib/state.sh"

# Unlisted files, including credentials and contributor instructions, never ship.
day_one_copy_runtime "$TEST_PROJECT" "$TEST_ROOT/source"
printf 'canary-do-not-ship\n' > "$TEST_ROOT/source/.env"
mkdir -p "$TEST_ROOT/source/.agents" "$TEST_ROOT/source/scripts/tests"
printf 'canary\n' > "$TEST_ROOT/source/.agents/private.md"
printf 'canary\n' > "$TEST_ROOT/source/scripts/tests/private.sh"
day_one_copy_runtime "$TEST_ROOT/source" "$TEST_ROOT/package"
for excluded in .env .agents scripts/tests scripts/validate.sh scripts/lint.sh; do
  [[ ! -e "$TEST_ROOT/package/$excluded" ]] || fail "package leaked $excluded"
done
day_one_checksum_runtime "$TEST_ROOT/package"
"$TEST_ROOT/package/scripts/verify.sh" >/dev/null
"$TEST_ROOT/package/scripts/day-one-mac" validate >/dev/null
"$TEST_ROOT/package/scripts/validate-warp-drive.sh" >/dev/null
printf '\n# corruption\n' >> "$TEST_ROOT/package/scripts/phases/06-toolchains.sh"
if "$TEST_ROOT/package/scripts/verify.sh" >/dev/null 2>&1; then fail 'corrupt runtime accepted'; fi

# Reject manifest escape paths even when they exist locally.
printf '../secret\n' >> "$TEST_ROOT/source/config/runtime-files.txt"
if day_one_copy_runtime "$TEST_ROOT/source" "$TEST_ROOT/unsafe" >/dev/null 2>&1; then fail 'unsafe manifest accepted'; fi

# Scalar state is replaced, with private mode, and never follows a symlink.
day_one_write_state "$TEST_ROOT/state/value" first
day_one_write_state "$TEST_ROOT/state/value" second
[[ "$(cat "$TEST_ROOT/state/value")" == second ]] || fail 'state replacement failed'
[[ "$(stat -f %Lp "$TEST_ROOT/state/value")" == 600 ]] || fail 'state is not private'
ln -s "$TEST_ROOT/state/value" "$TEST_ROOT/state/link"
if day_one_write_state "$TEST_ROOT/state/link" unsafe >/dev/null 2>&1; then fail 'state symlink accepted'; fi

# Keep the first process blocked on a FIFO while attempting a competing writer.
mkfifo "$TEST_ROOT/gate"
"$TEST_SCRIPT_DIR/with-operation-lock.sh" "$TEST_ROOT/operation.lock" /bin/bash -c \
  'printf ready > "$1"; read -r answer < "$2"' _ "$TEST_ROOT/ready" "$TEST_ROOT/gate" &
holder=$!
for ((attempt=0; attempt<100; attempt++)); do
  [[ ! -f "$TEST_ROOT/ready" ]] || break
  sleep 0.02
done
[[ -f "$TEST_ROOT/ready" ]] || fail 'lock holder did not start'
if "$TEST_SCRIPT_DIR/with-operation-lock.sh" "$TEST_ROOT/operation.lock" /usr/bin/true 2>/dev/null; then
  fail 'concurrent writer acquired the same lock'
else
  [[ "$?" == 75 ]] || fail 'lock contention did not return EX_TEMPFAIL'
fi
printf 'release\n' > "$TEST_ROOT/gate"
wait "$holder"
[[ ! -d "$TEST_ROOT/operation.lock" ]] || fail 'lock not released'
if "$TEST_SCRIPT_DIR/with-operation-lock.sh" "$TEST_ROOT/operation.lock" /bin/bash -c 'exit 23'; then
  fail 'supervisor swallowed child failure'
else
  [[ "$?" == 23 ]] || fail 'supervisor changed child exit status'
fi
[[ ! -d "$TEST_ROOT/operation.lock" ]] || fail 'failed command leaked lock'

# Fingerprints follow behavior and selections, not documentation wording.
# Importing setup defines functions but performs no setup or platform mutation.
source "$TEST_ROOT/source/scripts/setup.sh"
TRACK=1 STACK=node GIT_NAME='Test Developer' GIT_EMAIL='test@example.invalid'
AUTH_MODE=https PRIMARY_IDE=other PRESET=core DOTFILES_REPO='' DOTFILES_VERSIONING=local
baseline="$(phase_fingerprint 06)"
security="$(phase_fingerprint 03)"
printf '\nEditorial change.\n' >> "$DOC_DIR/01-required/06-language-toolchains.md"
[[ "$(phase_fingerprint 06)" == "$baseline" ]] || fail 'docs invalidated phase'
printf '\n# implementation change\n' >> "$SCRIPT_DIR/phases/06-toolchains.sh"
[[ "$(phase_fingerprint 06)" != "$baseline" ]] || fail 'implementation did not invalidate phase'
[[ "$(phase_fingerprint 03)" == "$security" ]] || fail 'unrelated phase invalidated security'
TRACK=3
[[ "$(phase_fingerprint 03)" != "$security" ]] || fail 'track did not invalidate SSH phase'
[[ -z "$(required_application_ids)" ]] || fail 'core HTTPS unexpectedly requires desktop applications'
AUTH_MODE=1password
[[ "$(required_application_ids)" == $'1password\n1password-cli' ]] || fail 'core 1Password selection is wrong'
PRESET=recommended-productivity AUTH_MODE=https
grep -Fqx visual-studio-code <<<"$(required_application_ids)" || fail 'default preset lost VS Code'
# CLI preview must honor core all the way through installation and Phase 7.
preview="$(HOME="$TEST_ROOT/preview-home" "$TEST_SCRIPT_DIR/setup.sh" --dry-run --preset core --auth-mode https --track 1 --stack node --name 'Test Developer' --email test@example.invalid --local-dotfiles --skip-macos-settings)"
grep -Fq 'Core preset: VS Code installation and configuration are not required.' <<<"$preview" || fail 'core CLI preview did not skip editor'
if grep -Eq 'brew install --cask (visual-studio-code|warp|raycast|1password)' <<<"$preview"; then fail 'core preview installs desktop casks'; fi
[[ ! -e "$TEST_ROOT/preview-home/.day-one-mac" ]] || fail 'preview wrote setup state'
day_one_write_state "$TEST_ROOT/preview-home/.day-one-mac/preset" core
day_one_write_state "$TEST_ROOT/preview-home/.day-one-mac/auth-mode" https
ownership="$(HOME="$TEST_ROOT/preview-home" "$TEST_SCRIPT_DIR/application-status.sh" --required)"
grep -Fq 'No applications are required' <<<"$ownership" || fail 'required-app status ignored saved preset'
printf 'PASS: allowlisted packaging, runtime verification, atomic state, operation locks, phase fingerprints and presets\n'
