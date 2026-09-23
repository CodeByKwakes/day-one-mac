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
  sed -n '/^SECRET_SCAN_MATCHES=""/,/^}/p' "$SCRIPT_DIR/setup.sh"
  cat <<'EOS'
if ! scan_source_for_secrets "$1"; then
  printf 'SCAN_FAILED\n'
  exit 0
fi
if [[ -n "$SECRET_SCAN_MATCHES" ]]; then printf 'REVIEW\n'; else printf 'CLEAN\n'; fi
EOS
} > "$harness"

grep -Fq 'scan_source_for_secrets' "$harness" \
  || fail_test 'scan_source_for_secrets was not found in setup.sh'

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
  sed -n '/^ssh_config_block() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  sed -n '/^ssh_config_identity_lines() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  printf 'ssh_config_block\n'
} > "$ssh_block_harness"

grep -Fq 'ssh_config_block' "$ssh_block_harness" \
  || fail_test 'ssh_config_block was not found in setup.sh'

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
