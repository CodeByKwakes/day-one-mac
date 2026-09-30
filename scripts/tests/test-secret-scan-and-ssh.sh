#!/usr/bin/env bash
# Negative regression tests for three defects that previously passed silently:
#   1. the Phase 8 dotfiles secret scan never ran (ripgrep read the pattern as a flag)
#   2. the generated SSH config used IdentitiesOnly without an IdentityFile
#   3. validate.sh reported green for checks it skipped when ripgrep was absent
# Each test asserts the FAILURE path, because all three bugs looked like success.
set -euo pipefail

# A fixture must never block on an interactive prompt: the runner asks for
# input when stdin is a TTY, which hangs when this is run from a real terminal
# rather than CI. Detach stdin so every child takes the non-interactive path.
exec </dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "/tmp/day-one-mac-secret-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail_test() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. The secret scanner must detect a planted key, stay quiet on a clean
#    source, and refuse to report success when it cannot run.
# ---------------------------------------------------------------------------

# Load just the scanner out of setup.sh, without executing the rest of it.
harness="$TEST_ROOT/scanner.sh"
{
  printf 'set -euo pipefail\n'
  printf 'source "%s/phases/08-verification.sh"\n' "$SCRIPT_DIR"
  cat <<'EOS'
if ! scan_source_for_secrets "$1"; then
  printf 'SCAN_FAILED\n'
  exit 0
fi
if [[ -n "$SECRET_SCAN_MATCHES" ]]; then printf 'REVIEW\n'; else printf 'CLEAN\n'; fi
EOS
} > "$harness"


dirty="$TEST_ROOT/dirty"
mkdir -p "$dirty"
# A syntactically real key header plus token shapes the scanner must catch.
{
  printf '%s\n' '-----BEGIN OPENSSH '"PRIVATE KEY-----"
  printf '%s\n' 'b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gt'
  printf '%s\n' '-----END OPENSSH '"PRIVATE KEY-----"
} > "$dirty/dot_secret"

clean="$TEST_ROOT/clean"
mkdir -p "$clean"
printf 'export EDITOR=vim\n' > "$clean/dot_zshrc"

result="$(bash "$harness" "$dirty")"
[[ "$result" == REVIEW ]] \
  || fail_test "a planted private key was not detected (got: $result)"

result="$(bash "$harness" "$clean")"
[[ "$result" == CLEAN ]] \
  || fail_test "a clean source was reported as containing secrets (got: $result)"

# Each token shape individually, so a future edit cannot drop one unnoticed.
for token in 'ghp_''AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' \
             'github_pat_''AAAAAAAAAAAAAAAAAAAAAAAA' \
             'AKIA''AAAAAAAAAAAAAAAA'; do
  probe="$TEST_ROOT/probe"
  rm -rf "$probe"; mkdir -p "$probe"
  printf 'token = %s\n' "$token" > "$probe/dot_env"
  result="$(bash "$harness" "$probe")"
  [[ "$result" == REVIEW ]] \
    || fail_test "token shape ${token%%_*} was not detected (got: $result)"
done

# With ripgrep unavailable the scan must report failure, never CLEAN.
result="$(env PATH=/usr/bin:/bin bash "$harness" "$dirty")"
[[ "$result" == SCAN_FAILED ]] \
  || fail_test "a missing ripgrep was not treated as a scan failure (got: $result)"

# A path ripgrep cannot read is an error, not an empty clean result.
result="$(bash "$harness" "$TEST_ROOT/does-not-exist")"
[[ "$result" == SCAN_FAILED ]] \
  || fail_test "an unreadable source was not treated as a scan failure (got: $result)"

# ---------------------------------------------------------------------------
# 2. IdentitiesOnly must never appear without a matching IdentityFile.
#    On its own it confines OpenSSH to the default ~/.ssh/id_* files, which
#    this project never creates, so the 1Password agent is never offered.
# ---------------------------------------------------------------------------

ssh_block_harness="$TEST_ROOT/sshblock.sh"
{
  printf 'set -euo pipefail\n'
  printf 'uses_github() { [[ "${TRACK_GITHUB:-0}" == 1 ]]; }\n'
  printf 'uses_azure() { [[ "${TRACK_AZURE:-0}" == 1 ]]; }\n'
  printf 'AUTH_MODE="${AUTH_MODE:-1password}"\n'
  printf 'source "%s/phases/03-security.sh"\n' "$SCRIPT_DIR"
  printf 'ssh_config_block\n'
} > "$ssh_block_harness"


assert_pairing() {
  local label="$1" block="$2"
  if grep -q 'IdentitiesOnly' <<<"$block" && ! grep -q 'IdentityFile' <<<"$block"; then
    printf '%s\n' "$block" >&2
    fail_test "$label: IdentitiesOnly was written without an IdentityFile"
  fi
}

fake_home="$TEST_ROOT/sshhome"
mkdir -p "$fake_home/.ssh"

# No exported public keys: the block must omit IdentitiesOnly entirely.
for combo in '1 0:github only' '0 1:azure only' '1 1:both providers'; do
  flags="${combo%%:*}"; label="${combo#*:}"
  # shellcheck disable=SC2086 # deliberate split of the two flag values
  set -- $flags
  block="$(HOME="$fake_home" TRACK_GITHUB="$1" TRACK_AZURE="$2" bash "$ssh_block_harness")"
  assert_pairing "$label, no pinned keys" "$block"
  grep -q 'IdentityAgent' <<<"$block" \
    || fail_test "$label: the 1Password IdentityAgent line is missing"
done

# With the public keys present, both lines must appear together.
touch "$fake_home/.ssh/github-auth.pub" "$fake_home/.ssh/azure-devops-auth.pub"
block="$(HOME="$fake_home" TRACK_GITHUB=1 TRACK_AZURE=1 bash "$ssh_block_harness")"
assert_pairing 'both providers, pinned keys' "$block"
grep -q 'IdentityFile ~/.ssh/github-auth.pub' <<<"$block" \
  || fail_test 'the pinned GitHub IdentityFile line is missing'
grep -q 'IdentityFile ~/.ssh/azure-devops-auth.pub' <<<"$block" \
  || fail_test 'the pinned Azure IdentityFile line is missing'
[[ "$(grep -c 'IdentitiesOnly yes' <<<"$block")" == 2 ]] \
  || fail_test 'IdentitiesOnly should accompany each pinned IdentityFile'

# Every authentication mode must respect the IdentityFile pairing rule, and
# each must contribute only its own identity mechanism.
rm -f "$fake_home/.ssh/github-auth.pub" "$fake_home/.ssh/azure-devops-auth.pub"
for mode in 1password keychain external https; do
  block="$(HOME="$fake_home" AUTH_MODE="$mode" TRACK_GITHUB=1 TRACK_AZURE=1 bash "$ssh_block_harness")"
  assert_pairing "mode $mode, no pinned keys" "$block"
  case "$mode" in
    1password)
      grep -q 'IdentityAgent' <<<"$block" || fail_test 'the 1password mode lost its IdentityAgent line'
      grep -q 'UseKeychain'   <<<"$block" && fail_test 'the 1password mode must not use the macOS Keychain'
      ;;
    keychain)
      grep -q 'UseKeychain yes'   <<<"$block" || fail_test 'the keychain mode lost its UseKeychain line'
      grep -q 'AddKeysToAgent yes' <<<"$block" || fail_test 'the keychain mode lost its AddKeysToAgent line'
      grep -q 'IdentityFile'      <<<"$block" || fail_test 'the keychain mode must name its key file'
      grep -q 'IdentityAgent'     <<<"$block" && fail_test 'the keychain mode must not use the 1Password agent'
      ;;
    external)
      grep -q 'IdentityAgent' <<<"$block" && fail_test 'the external mode must not assume the 1Password agent'
      grep -q 'UseKeychain'   <<<"$block" && fail_test 'the external mode must not assume the macOS Keychain'
      ;;
    https)
      # https writes no identity lines; the block is host scaffolding only.
      grep -q 'IdentityAgent' <<<"$block" && fail_test 'the https mode must not configure an SSH identity'
      grep -q 'IdentityFile'  <<<"$block" && fail_test 'the https mode must not configure an SSH identity'
      ;;
  esac
done

# With pins present, the pairing rule must still hold in the modes that use them.
touch "$fake_home/.ssh/github-auth.pub" "$fake_home/.ssh/azure-devops-auth.pub"
for mode in 1password external; do
  block="$(HOME="$fake_home" AUTH_MODE="$mode" TRACK_GITHUB=1 TRACK_AZURE=1 bash "$ssh_block_harness")"
  assert_pairing "mode $mode, pinned keys" "$block"
  grep -q 'IdentityFile ~/.ssh/github-auth.pub' <<<"$block" \
    || fail_test "mode $mode did not pick up the GitHub pin"
done

# https must stay identity-free even when pin files happen to exist on disk,
# since those files are left behind by a previous mode.
block="$(HOME="$fake_home" AUTH_MODE=https TRACK_GITHUB=1 TRACK_AZURE=1 bash "$ssh_block_harness")"
grep -q 'IdentityFile' <<<"$block" \
  && fail_test 'the https mode configured an SSH identity from leftover pin files'
grep -q 'IdentitiesOnly' <<<"$block" \
  && fail_test 'the https mode emitted IdentitiesOnly'

# ---------------------------------------------------------------------------
# 3. validate.sh must refuse to run without ripgrep rather than report passes.
# ---------------------------------------------------------------------------

set +e
validate_output="$(env PATH=/usr/bin:/bin "$SCRIPT_DIR/validate.sh" 2>&1)"
validate_status=$?
set -e

[[ "$validate_status" -ne 0 ]] \
  || fail_test 'validate.sh exited 0 without ripgrep instead of refusing to run'
grep -q 'ripgrep' <<<"$validate_output" \
  || fail_test 'validate.sh did not explain that ripgrep is required'
if grep -q '✓' <<<"$validate_output"; then
  fail_test 'validate.sh reported passing checks while ripgrep was unavailable'
fi

printf 'PASS: secret scan, per-mode SSH config, IdentitiesOnly pairing, validator dependency\n'

# VM acceptance regressions: real disposable keys, never the user's SSH keys.
# ShellCheck cannot resolve callbacks in these independently sourced harnesses.
# shellcheck disable=SC2329
(
  export HOME="$TEST_ROOT/keychain-home"
  mkdir -p "$HOME/.ssh"
  source "$SCRIPT_DIR/phases/03-security.sh"
  info() { :; }; warn() { :; }; ok() { :; }; err() { :; }
  record_path_before_write() { :; }
  ssh-keygen -q -t ed25519 -N '' -f "$HOME/.ssh/plain"
  ssh-keygen -q -t ed25519 -N 'fixture-only-passphrase' -f "$HOME/.ssh/protected"
  ssh-keygen -q -t rsa -b 3072 -N 'fixture-only-passphrase' -f "$HOME/.ssh/rsa-protected"
  printf 'not a key\n' > "$HOME/.ssh/invalid"
  [[ "$(keychain_key_protection "$HOME/.ssh/plain")" == unprotected ]] || fail_test 'empty passphrase not detected'
  [[ "$(keychain_key_protection "$HOME/.ssh/protected")" == encrypted ]] || fail_test 'encrypted key not detected'
  [[ "$(keychain_key_protection "$HOME/.ssh/rsa-protected")" == encrypted ]] || fail_test 'encrypted RSA key not detected'
  for target in invalid absent; do
    [[ "$(keychain_key_protection "$HOME/.ssh/$target")" == unverifiable ]] || fail_test "$target key treated as protected"
  done
  ssh-add() { printf 'called\n' >> "$TEST_ROOT/agent-calls"; return "${ADD_STATUS:-0}"; }
  for target in plain invalid; do
    if generate_keychain_key "$HOME/.ssh/$target" ed25519 ''; then fail_test "$target key accepted"; fi
  done
  [[ ! -e "$TEST_ROOT/agent-calls" ]] || fail_test 'unsafe key reached ssh-add'
  # Simulate pressing Return at ssh-keygen's new-key passphrase prompts.
  ssh-keygen() {
    if [[ "$1" == -t ]]; then
      cp "$HOME/.ssh/plain" "$HOME/.ssh/new-key"
      cp "$HOME/.ssh/plain.pub" "$HOME/.ssh/new-key.pub"
    else
      command ssh-keygen "$@"
    fi
  }
  if generate_keychain_key "$HOME/.ssh/new-key" ed25519 ''; then fail_test 'new empty-passphrase key accepted'; fi
  cmp "$HOME/.ssh/plain" "$HOME/.ssh/new-key" || fail_test 'rejected new key was changed'
  [[ ! -e "$TEST_ROOT/agent-calls" ]] || fail_test 'new unsafe key reached ssh-add'
  generate_keychain_key "$HOME/.ssh/protected" ed25519 '' || fail_test 'protected key rejected'
  ADD_STATUS=1
  if generate_keychain_key "$HOME/.ssh/protected" ed25519 ''; then fail_test 'agent failure accepted'; fi

  source "$SCRIPT_DIR/phases/08-verification.sh"
  phase_gate_failed() { :; }
  VERIFY_FAILURES=0
  for target in protected plain invalid absent; do
    report_keychain_key_protection "$TEST_ROOT/key-report.md" "$HOME/.ssh/$target"
  done
  [[ "$VERIFY_FAILURES" == 3 ]] || fail_test 'key protection failures not counted'
  [[ "$(grep -c 'PASS' "$TEST_ROOT/key-report.md")" == 1 ]] || fail_test 'report gave unsafe keys a pass'
  grep -q 'FAIL — unprotected' "$TEST_ROOT/key-report.md" || fail_test 'empty passphrase not reported'
  grep -q 'FAIL — unverifiable' "$TEST_ROOT/key-report.md" || fail_test 'unverifiable key not reported'

  AUTH_MODE=keychain DRY_RUN=0 EX_GATE=3 EX_MANUAL=4
  uses_github() { return 0; }; uses_azure() { return 1; }
  create_directory() { mkdir -p "$1"; }
  write_text_file() { printf '%s' "$2" > "$1"; }
  resync_managed_ssh_config() { :; }; ssh() { return 0; }
  printf '%s\n' '# >>> Day One Mac: 1Password SSH agent >>>' 'Host github.com' '    User git' '# <<< Day One Mac: 1Password SSH agent <<<' 'Host example.test' '    User preserved' > "$HOME/.ssh/config"
  configure_onepassword_ssh
  grep -Fq '# >>> Day One Mac: SSH authentication >>>' "$HOME/.ssh/config" || fail_test 'legacy block not migrated'
  grep -Fq 'User preserved' "$HOME/.ssh/config" || fail_test 'unmanaged config lost'
  if grep -q '1Password SSH agent' "$HOME/.ssh/config"; then fail_test 'legacy label retained'; fi
  cp "$HOME/.ssh/config" "$TEST_ROOT/config-once"
  configure_onepassword_ssh
  cmp "$HOME/.ssh/config" "$TEST_ROOT/config-once" || fail_test 'config migration not idempotent'
  for malformed in nested reversed mixed; do
    case "$malformed" in
      nested) printf '%s\n' '# >>> Day One Mac: SSH authentication >>>' '# >>> Day One Mac: SSH authentication >>>' '# <<< Day One Mac: SSH authentication <<<' ;;
      reversed) printf '%s\n' '# <<< Day One Mac: SSH authentication <<<' '# >>> Day One Mac: SSH authentication >>>' ;;
      mixed) printf '%s\n' '# >>> Day One Mac: 1Password SSH agent >>>' '# <<< Day One Mac: SSH authentication <<<' ;;
    esac > "$HOME/.ssh/config"
    cp "$HOME/.ssh/config" "$TEST_ROOT/config-before"
    if configure_onepassword_ssh; then fail_test "$malformed markers accepted"; fi
    cmp "$HOME/.ssh/config" "$TEST_ROOT/config-before" || fail_test "$malformed config changed"
  done
)
printf 'PASS: passphrase enforcement, agent failure and SSH marker migration\n'

# Phase 8: authentication and legacy-key storage are independent gates.
# Callbacks below are invoked by the sourced phase functions.
# shellcheck disable=SC2329
(
  export HOME="$TEST_ROOT/storage home"
  mkdir -p "$HOME/.ssh/nested"
  source "$SCRIPT_DIR/phases/03-security.sh"
  source "$SCRIPT_DIR/phases/08-verification.sh"
  warn() { :; }; info() { :; }; phase_gate_failed() { :; }
  uses_github() { return 0; }; uses_azure() { return 1; }
  storage_report="$TEST_ROOT/storage-report.md"
  check_storage() {
    VERIFY_FAILURES=0 VERIFY_REVIEWS=0
    : > "$storage_report"
    report_ssh_key_storage "$storage_report"
  }
  # --yes and redirected input must not approve retention, even with the word.
  if ASSUME_YES=1 confirm_retained_ssh_key test <<<retain; then fail_test '--yes approved retention'; fi
  if ASSUME_YES=0 confirm_retained_ssh_key test <<<retain; then fail_test 'piped retention approved'; fi
  confirm_retained_ssh_key() { return 1; }
  for AUTH_MODE in 1password external https; do
    check_storage
    [[ "$VERIFY_FAILURES:$VERIFY_REVIEWS" == 0:0 ]] || fail_test 'empty physical tree failed'
  done
  AUTH_MODE=keychain
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'missing selected Keychain key passed'

  cp "$TEST_ROOT/keychain-home/.ssh/protected" "$HOME/.ssh/id_ed25519"
  baseline="$(shasum -a 256 "$HOME/.ssh/id_ed25519")"
  for AUTH_MODE in 1password external https; do
    check_storage
    [[ "$VERIFY_FAILURES:$VERIFY_REVIEWS" == 0:1 ]] || fail_test 'encrypted legacy key not REVIEW'
    grep -q 'REVIEW — encrypted' "$storage_report" || fail_test 'legacy key received a pass'
  done
  AUTH_MODE=keychain
  check_storage
  [[ "$VERIFY_FAILURES:$VERIFY_REVIEWS" == 0:0 ]] || fail_test 'expected encrypted Keychain key failed'
  AUTH_MODE=1password
  confirm_retained_ssh_key() { return 0; }
  check_storage
  [[ "$VERIFY_FAILURES:$VERIFY_REVIEWS" == 0:0 ]] || fail_test 'explicit retained key rejected'
  grep -q 'REVIEWED.*not vault-only' "$storage_report" || fail_test 'retention mislabeled as vault-only'
  [[ "$(shasum -a 256 "$HOME/.ssh/id_ed25519")" == "$baseline" ]] || fail_test 'retention changed the key'
  confirm_retained_ssh_key() { local answer; IFS= read -r answer; [[ "$answer" == fixture-review ]]; }
  check_storage <<<fixture-review
  [[ "$VERIFY_FAILURES:$VERIFY_REVIEWS" == 0:0 ]] || fail_test 'inventory consumed review stdin'
  confirm_retained_ssh_key() { printf 'changed\n' > "$HOME/.ssh/id_ed25519"; return 0; }
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'key changed during approval passed'
  rm "$HOME/.ssh/id_ed25519"

  # Renaming, nesting or using a .pub suffix must not hide private material.
  confirm_retained_ssh_key() { return 1; }
  for target in 'renamed key' 'nested/隠し鍵' 'misleading.pub'; do
    cp "$TEST_ROOT/keychain-home/.ssh/plain" "$HOME/.ssh/$target"
    check_storage
    [[ "$VERIFY_FAILURES" == 1 ]] || fail_test "unprotected $target passed"
    grep -q 'FAIL — unprotected' "$storage_report" || fail_test 'protection failure missing'
    rm "$HOME/.ssh/$target"
  done
  cp "$TEST_ROOT/keychain-home/.ssh/protected" "$HOME/.ssh/nested/.legacy"
  check_storage
  [[ "$VERIFY_REVIEWS" == 1 ]] || fail_test 'hidden encrypted key missed'
  rm "$HOME/.ssh/nested/.legacy"
  printf 'invalid\n' > "$HOME/.ssh/id_broken"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'malformed conventional key passed'
  rm "$HOME/.ssh/id_broken"
  printf '%s\n' '-----BEGIN OPENSSH PRIVATE KEY-----' > "$HOME/.ssh/broken"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'malformed renamed key passed'
  rm "$HOME/.ssh/broken"
  ln -s "$TEST_ROOT/keychain-home/.ssh/protected" "$HOME/.ssh/link"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'symlink was followed or ignored'
  rm "$HOME/.ssh/link"
  # A real Unix socket is an endpoint, not stored key bytes. Never exempt
  # its whole directory, follow a link to it, or connect to it for this audit.
  mkdir -p "$HOME/.ssh/agent"
  python3 - "$HOME/.ssh/agent/id_socket" <<'PY'
import socket
import sys

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as endpoint:
    endpoint.bind(sys.argv[1])
PY
  for AUTH_MODE in 1password external https; do
    check_storage
    [[ "$VERIFY_FAILURES:$VERIFY_REVIEWS" == 0:0 ]] || fail_test 'Unix socket treated as a key file'
    grep -q 'SKIP — Unix socket, not a key file' "$storage_report" || fail_test 'socket exclusion not reported'
  done
  AUTH_MODE=keychain
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'socket satisfied missing selected Keychain key'
  mv "$HOME/.ssh/agent/id_socket" "$HOME/.ssh/id_ed25519"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'socket replaced selected GitHub key'
  mv "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa_azure"
  uses_github() { return 1; }; uses_azure() { return 0; }
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'socket replaced selected Azure key'
  uses_github() { return 0; }; uses_azure() { return 1; }
  mv "$HOME/.ssh/id_rsa_azure" "$HOME/.ssh/agent/id_socket"
  AUTH_MODE=1password
  ln -s "$HOME/.ssh/agent/id_socket" "$HOME/.ssh/socket-link"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'symlink to socket accepted'
  rm "$HOME/.ssh/socket-link"
  cp "$TEST_ROOT/keychain-home/.ssh/plain" "$HOME/.ssh/agent/hidden-key"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'key beside agent socket ignored'
  rm "$HOME/.ssh/agent/hidden-key" "$HOME/.ssh/agent/id_socket"
  mkfifo "$HOME/.ssh/fifo"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'special file accepted'
  rm "$HOME/.ssh/fifo"
  cp "$TEST_ROOT/keychain-home/.ssh/protected.pub" "$HOME/.ssh/normal.pub"
  printf 'Host example.test\n' > "$HOME/.ssh/config"
  check_storage
  [[ "$VERIFY_FAILURES:$VERIFY_REVIEWS" == 0:0 ]] || fail_test 'ordinary public/config files failed'
  chmod 000 "$HOME/.ssh/config"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'unreadable file passed'
  chmod 600 "$HOME/.ssh/config"
  find() { return 1; }
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'failed inventory passed'
  unset -f find
  mv "$HOME/.ssh" "$HOME/ssh-original"
  ln -s "$HOME/ssh-original" "$HOME/.ssh"
  check_storage
  [[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'symlinked SSH root passed'
  rm "$HOME/.ssh"
  mv "$HOME/ssh-original" "$HOME/.ssh"

  # Simulated provider responses: no network, vault, credential or host changes.
  cp "$TEST_ROOT/keychain-home/.ssh/protected.pub" "$HOME/.ssh/github-auth.pub"
  ONEPASSWORD_AGENT_SOCK="$HOME/Library/Group Containers/test/agent.sock"
  fingerprint="$(ssh-keygen -lf "$HOME/.ssh/github-auth.pub" -E sha256 | awk '{print $2}')"
  agent_identities() { printf '256 %s fixture (ED25519)\n' "${AGENT_FP:-$fingerprint}"; }
  ssh() {
    if [[ "$1" == -G ]]; then
      printf 'identityfile %s\nidentityagent %s\nidentitiesonly yes\n' "${TEST_PIN:-$HOME/.ssh/github-auth.pub}" "${TEST_AGENT:-$ONEPASSWORD_AGENT_SOCK}"
    else
      [[ "$*" == *StrictHostKeyChecking=yes* && "$*" == *UpdateHostKeys=no* ]] || fail_test 'audit modifies trust'
      printf '%s\n' "${PROVIDER_REPLY:-Hi fixture! You have successfully authenticated, but shell access is not provided.}"
      return 1 # GitHub's successful SSH test returns 1, not 0.
    fi
  }
  verify_selected_ssh_provider github || fail_test 'valid pin/agent/provider rejected'
  AGENT_FP=SHA256:wrong
  if verify_selected_ssh_provider github; then fail_test 'wrong agent pin passed'; fi
  unset AGENT_FP
  TEST_PIN="$HOME/.ssh/id_ed25519"
  if verify_selected_ssh_provider github; then fail_test 'effective private-key fallback passed'; fi
  unset TEST_PIN
  TEST_AGENT=/wrong/socket
  if verify_selected_ssh_provider github; then fail_test 'wrong effective agent passed'; fi
  unset TEST_AGENT
  TEST_PIN="$HOME/.ssh/github-auth.pub"$'\nidentityfile /another/key'
  if verify_selected_ssh_provider github; then fail_test 'additional effective identity passed'; fi
  unset TEST_PIN
  PROVIDER_REPLY='Host key verification failed. secret-diagnostic-marker'
  if verify_selected_ssh_provider github > "$TEST_ROOT/auth-log" 2>&1; then fail_test 'untrusted host passed'; fi
  if grep -q secret-diagnostic-marker "$TEST_ROOT/auth-log"; then fail_test 'SSH diagnostics leaked'; fi
  unset PROVIDER_REPLY
  cp "$TEST_ROOT/keychain-home/.ssh/rsa-protected.pub" "$HOME/.ssh/azure-devops-auth.pub"
  TEST_PIN="$HOME/.ssh/azure-devops-auth.pub"
  AGENT_FP="$(ssh-keygen -lf "$TEST_PIN" -E sha256 | awk '{print $2}')"
  PROVIDER_REPLY='Shell access is not supported.'
  verify_selected_ssh_provider azure || fail_test 'valid Azure RSA pin rejected'
  cp "$HOME/.ssh/github-auth.pub" "$TEST_PIN"
  if verify_selected_ssh_provider azure; then fail_test 'Azure accepted non-RSA pin'; fi
  unset TEST_PIN AGENT_FP PROVIDER_REPLY
  for AUTH_MODE in keychain external; do
    verify_selected_ssh_provider github || fail_test "$AUTH_MODE provider check failed"
  done
  AUTH_MODE=1password
  rm "$HOME/.ssh/github-auth.pub"
  if verify_selected_ssh_provider github; then fail_test 'missing pin passed'; fi

  # Exercise the actual phase's stop/continue boundary with harmless callbacks.
  # No real packages, dotfiles, sessions or network are touched by this harness.
  SCRIPT_DIR="$TEST_ROOT/phase8-runtime"
  PROJECT_DIR="$TEST_ROOT"
  STATE_DIR="$TEST_ROOT/phase8-state"
  mkdir -p "$SCRIPT_DIR" "$STATE_DIR"
  printf '#!/bin/bash\nexit 0\n' > "$SCRIPT_DIR/verify.sh"
  chmod 700 "$SCRIPT_DIR/verify.sh"
  printf '# reviewed fixture\n' > "$HOME/Brewfile"
  DRY_RUN=0 EX_GATE=20 EX_MANUAL=10 TRACK=1 STACK=both DOTFILES_VERSIONING=local PRESET=core
  AUTH_MODE=https
  ui_title() { :; }; ok() { :; }; err() { :; }; phase_doc() { :; }
  phase_next() { :; }; phase_step_done() { :; }; ensure_state() { :; }
  track_name() { printf 'fixture\n'; }; report_check() { :; }
  required_application_ids() { :; }; uses_node() { return 1; }; uses_python() { return 1; }
  chezmoi() { return 0; }
  report_ssh_key_storage() { VERIFY_FAILURES="$TEST_FAILURES"; VERIFY_REVIEWS="$TEST_REVIEWS"; }
  verify_local_dotfiles_source() { touch "$TEST_ROOT/phase8-completed"; }
  for outcome in '0 1 10' '1 1 20' '0 0 0'; do
    read -r TEST_FAILURES TEST_REVIEWS expected_exit <<<"$outcome"
    phase_exit=0
    phase_08 || phase_exit=$?
    [[ "$phase_exit" == "$expected_exit" ]] || fail_test "phase returned $phase_exit, expected $expected_exit"
    if [[ "$expected_exit" != 0 && -e "$TEST_ROOT/phase8-completed" ]]; then fail_test 'incomplete audit reached completion'; fi
  done
  [[ -e "$TEST_ROOT/phase8-completed" ]] || fail_test 'reviewed audit could not reach completion'
)
printf 'PASS: Phase 8 separate SSH authentication and per-file legacy-key review\n'
