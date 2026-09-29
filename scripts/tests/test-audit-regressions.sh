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
source "$TEST_SCRIPT_DIR/lib/runtime-activation.sh"

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

# Added files/types and incomplete checksum lists must fail every integrity entry
# point, without changing activation history. Keep spaces in the real allowlist.
mkdir -p "$TEST_ROOT/runtime/releases"
cp -R "$TEST_ROOT/package" "$TEST_ROOT/runtime/releases/candidate"
ln -s releases/old "$TEST_ROOT/runtime/current"
printf 'releases/older\n' > "$TEST_ROOT/runtime/previous"
candidate="$TEST_ROOT/runtime/releases/candidate"
reject_runtime() {
  if "$candidate/scripts/verify.sh" >/dev/null 2>&1; then fail 'verify accepted a modified inventory'; fi
  if DAY_ONE_MAC_RUNTIME_HOME="$TEST_ROOT/runtime" "$candidate/scripts/runtime-manager.sh" status >/dev/null 2>&1; then
    fail 'runtime-status accepted a modified inventory'
  fi
  if day_one_activate_runtime "$TEST_ROOT/runtime" candidate >/dev/null 2>&1; then fail 'activation accepted a modified inventory'; fi
  [[ "$(readlink "$TEST_ROOT/runtime/current")" == releases/old ]] || fail 'rejection changed current'
  [[ "$(cat "$TEST_ROOT/runtime/previous")" == releases/older ]] || fail 'rejection changed history'
}
printf '#!/bin/bash\nexit 0\n' > "$candidate/scripts/unlisted.sh"
chmod +x "$candidate/scripts/unlisted.sh"
reject_runtime
rm "$candidate/scripts/unlisted.sh"
ln -s VERSION "$candidate/unlisted-link"
reject_runtime
rm "$candidate/unlisted-link"
mkfifo "$candidate/unlisted-pipe"
reject_runtime
rm "$candidate/unlisted-pipe"
mkdir "$candidate/unlisted-directory"
reject_runtime
rmdir "$candidate/unlisted-directory"
mv "$candidate/README.md" "$TEST_ROOT/readme"
ln -s "$TEST_ROOT/readme" "$candidate/README.md"
reject_runtime
rm "$candidate/README.md"
mv "$TEST_ROOT/readme" "$candidate/README.md"
mv "$candidate/README.md" "$TEST_ROOT/readme"
reject_runtime
mv "$TEST_ROOT/readme" "$candidate/README.md"
mv "$candidate/config" "$TEST_ROOT/config"
ln -s "$TEST_ROOT/config" "$candidate/config"
reject_runtime
rm "$candidate/config"
mv "$TEST_ROOT/config" "$candidate/config"
cp "$candidate/SHA256SUMS" "$TEST_ROOT/checksums"
sed '/  \.\/README.md$/d' "$TEST_ROOT/checksums" > "$candidate/SHA256SUMS"
reject_runtime
cp "$TEST_ROOT/checksums" "$candidate/SHA256SUMS"
sed -n '1p' "$TEST_ROOT/checksums" >> "$candidate/SHA256SUMS"
reject_runtime
cp "$TEST_ROOT/checksums" "$candidate/SHA256SUMS"
printf '%064d  ../escape\n' 0 >> "$candidate/SHA256SUMS"
reject_runtime
cp "$TEST_ROOT/checksums" "$candidate/SHA256SUMS"
rm "$candidate/SHA256SUMS"
ln -s "$TEST_ROOT/checksums" "$candidate/SHA256SUMS"
reject_runtime
rm "$candidate/SHA256SUMS"
cp "$TEST_ROOT/checksums" "$candidate/SHA256SUMS"
"$candidate/scripts/verify.sh" >/dev/null
day_one_activate_runtime "$TEST_ROOT/runtime" candidate || fail 'intact candidate rejected'
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

# Reject parent links before mkdir/mktemp, including dangling links, and retain
# normal nested writes through macOS's system /tmp alias.
mkdir "$TEST_ROOT/outside"
ln -s "$TEST_ROOT/outside" "$TEST_ROOT/state/parent-link"
if day_one_write_state "$TEST_ROOT/state/parent-link/new/value" unsafe >/dev/null 2>&1; then fail 'state parent symlink accepted'; fi
[[ -z "$(ls -A "$TEST_ROOT/outside")" ]] || fail 'state write escaped through parent'
ln -s "$TEST_ROOT/missing" "$TEST_ROOT/state/dangling"
if day_one_write_state "$TEST_ROOT/state/dangling/value" unsafe >/dev/null 2>&1; then fail 'dangling parent accepted'; fi
mkfifo "$TEST_ROOT/state/fifo"
if day_one_write_state "$TEST_ROOT/state/fifo" unsafe >/dev/null 2>&1; then fail 'non-regular state accepted'; fi
day_one_write_state "$TEST_ROOT/state/nested/new/value" safe
[[ "$(cat "$TEST_ROOT/state/nested/new/value")" == safe ]] || fail 'safe nested write failed'

source "$TEST_SCRIPT_DIR/lib/module-execution.sh"
reject_module() {
  if ( STATE_DIR="$1"; day_one_module_begin 10 selection ); then fail 'module accepted symlinked state'; fi
  [[ -z "$(ls -A "$TEST_ROOT/outside")" ]] || fail 'module created records outside state'
}
ln -s "$TEST_ROOT/outside" "$TEST_ROOT/linked-state"
reject_module "$TEST_ROOT/linked-state"
mkdir "$TEST_ROOT/module-state"
ln -s "$TEST_ROOT/outside" "$TEST_ROOT/module-state/module-runs"
reject_module "$TEST_ROOT/module-state"
rm "$TEST_ROOT/module-state/module-runs"
mkdir "$TEST_ROOT/module-state/module-runs"
ln -s "$TEST_ROOT/outside" "$TEST_ROOT/module-state/module-runs/10"
reject_module "$TEST_ROOT/module-state"
if ( STATE_DIR="$TEST_ROOT/safe-module"; day_one_module_begin ../escape selection ); then fail 'module ID traversal accepted'; fi
[[ ! -e "$TEST_ROOT/safe-module" ]] || fail 'invalid module ID wrote state'
if ( STATE_DIR="$TEST_ROOT/safe-module"; day_one_module_begin 10 selection "$TEST_ROOT/state/parent-link/record" ); then
  fail 'module accepted redirected backup record'
fi
[[ ! -e "$TEST_ROOT/safe-module" ]] || fail 'invalid backup record created a run'

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
preview="$(HOME="$TEST_ROOT/preview-home" "$TEST_SCRIPT_DIR/setup.sh" --dry-run --preset core --auth-mode https --track 1 --stack node --layout none --ghq no --name 'Test Developer' --email test@example.invalid --local-dotfiles --skip-macos-settings)"
grep -Fq 'Core preset: VS Code installation and configuration are not required.' <<<"$preview" || fail 'core CLI preview did not skip editor'
if grep -Eq 'brew install --cask (visual-studio-code|warp|raycast|1password)' <<<"$preview"; then fail 'core preview installs desktop casks'; fi
[[ ! -e "$TEST_ROOT/preview-home/.day-one-mac" ]] || fail 'preview wrote setup state'
day_one_write_state "$TEST_ROOT/preview-home/.day-one-mac/preset" core
day_one_write_state "$TEST_ROOT/preview-home/.day-one-mac/auth-mode" https
ownership="$(HOME="$TEST_ROOT/preview-home" "$TEST_SCRIPT_DIR/application-status.sh" --required)"
grep -Fq 'No applications are required' <<<"$ownership" || fail 'required-app status ignored saved preset'
# Fresh-user decisions must not launch Apple's Git shim before Phase 2.
# Overrides below are called by the imported production functions.
# shellcheck disable=SC2329
(
  phase_next() { :; }; phase_step_done() { :; }; ui_title() { :; }
  info() { :; }; ok() { :; }; confirm() { return 0; }
  day_one_require_apple_silicon() { return 0; }; save_state_value() { :; }
  git() { printf '%s\n' "$*" >> "$TEST_ROOT/git-default-queries"; printf 'saved-value\n'; }
  xcode-select() { return 1; }
  ask() { printf '%s\n' "${2:-fixture@example.invalid}"; }
  GIT_NAME='Provided Name' GIT_EMAIL=provided@example.invalid DRY_RUN=0
  phase_01
  [[ ! -e "$TEST_ROOT/git-default-queries" ]] || fail 'explicit identity queried Git'
  GIT_NAME='' GIT_EMAIL=''
  phase_01
  [[ ! -e "$TEST_ROOT/git-default-queries" ]] || fail 'fresh user queried Git before developer tools'
  xcode-select() { printf '%s\n' "$TEST_ROOT"; }
  GIT_NAME='Provided Name' GIT_EMAIL=''
  phase_01
  [[ "$GIT_NAME" == 'Provided Name' && "$GIT_EMAIL" == saved-value ]] || fail 'identity default selection failed'
  [[ "$(cat "$TEST_ROOT/git-default-queries")" == 'config --global user.email' ]] || fail 'queried an already supplied identity field'
)

# Early validation failure must not leave a producer writing to a closed pipe.
# Overrides below are called by the imported production functions.
# shellcheck disable=SC2329
(
  load_brew() { return 0; }
  day_one_app_detect() { return 1; }
  required_application_ids() {
    printf 'raycast\n'
    sleep 0.05
    printf 'warp\n'
    printf 'complete\n' > "$TEST_ROOT/application-list-completed"
  }
  if installation_centre_components_ready; then fail 'missing app accepted'; fi
  [[ -f "$TEST_ROOT/application-list-completed" ]] || fail 'status returned before its application producer finished'
  required_application_ids() { return 23; }
  if installation_centre_components_ready; then fail 'failed application enumeration accepted'; fi
)
printf 'PASS: packaging, state, fingerprints, presets, fresh-user identity and complete status enumeration\n'
