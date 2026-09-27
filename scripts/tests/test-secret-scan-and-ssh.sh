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
