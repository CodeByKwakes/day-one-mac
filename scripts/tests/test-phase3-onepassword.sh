#!/usr/bin/env bash
# Regression tests for the three Phase 3 checks added after the 1Password review:
#   1. the CLI integration is verified by really running `op account list`
#   2. the agent's key types are checked against the selected hosting track
#   3. a hanging `op` hits a deadline instead of blocking the runner
# Each asserts a FAILURE path, because the gap these close was a silent pass.
set -euo pipefail

# A fixture must never block on an interactive prompt: the runner asks for
# input when stdin is a TTY, which hangs when this is run from a real terminal
# rather than CI. Detach stdin so every child takes the non-interactive path.
exec </dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "/tmp/day-one-mac-phase3-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail_test() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

mkdir -p "$TEST_ROOT/bin"
fake_op() { printf '#!/bin/sh\n%s\n' "$1" > "$TEST_ROOT/bin/op"; chmod +x "$TEST_ROOT/bin/op"; }

# ---------------------------------------------------------------------------
# 1 + 3. The CLI integration check, including its deadline.
# ---------------------------------------------------------------------------

cli_harness="$TEST_ROOT/cli.sh"
{
  printf 'set -euo pipefail\n'
  printf 'warn() { printf "warn: %%s\\n" "$*"; }\n'
  sed -n '/^run_with_deadline() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  sed -n '/^verify_onepassword_cli_integration() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  printf 'if verify_onepassword_cli_integration; then printf "OK\\n"; else printf "MANUAL\\n"; fi\n'
} > "$cli_harness"

grep -Fq 'verify_onepassword_cli_integration' "$cli_harness" \
  || fail_test 'verify_onepassword_cli_integration was not found in setup.sh'
grep -Fq 'run_with_deadline' "$cli_harness" \
  || fail_test 'run_with_deadline was not found in setup.sh'

fake_op 'echo "URL EMAIL USER ID"; echo "my.1password.com you@example.com ABC"; exit 0'
result="$(PATH="$TEST_ROOT/bin:$PATH" bash "$cli_harness" | tail -1)"
[[ "$result" == OK ]] \
  || fail_test "a working 1Password CLI integration was rejected (got: $result)"

# Desktop integration switched off: op exists but cannot reach the app.
fake_op 'echo "[ERROR] connecting to desktop app: not enabled" >&2; exit 1'
output="$(PATH="$TEST_ROOT/bin:$PATH" bash "$cli_harness")"
[[ "$(tail -1 <<<"$output")" == MANUAL ]] \
  || fail_test 'a broken 1Password CLI integration was reported as working'
grep -Fq 'Integrate with 1Password CLI' <<<"$output" \
  || fail_test 'the CLI integration failure did not name the setting to turn on'

# A prompt left unanswered must not hang the runner forever.
fake_op 'sleep 60'
start="$(date +%s)"
output="$(PATH="$TEST_ROOT/bin:$PATH" bash "$cli_harness")"
elapsed=$(( $(date +%s) - start ))
[[ "$(tail -1 <<<"$output")" == MANUAL ]] \
  || fail_test 'a hanging op was not treated as a failure'
grep -Fq 'did not finish within' <<<"$output" \
  || fail_test 'a hanging op did not report a deadline'
[[ "$elapsed" -lt 40 ]] \
  || fail_test "the deadline did not fire promptly (took ${elapsed}s)"
grep -Fq 'Terminated' <<<"$output" \
  && fail_test 'shell job-control noise leaked into the deadline message'

# ---------------------------------------------------------------------------
# 2. Key type must match the selected track. Azure DevOps accepts RSA only, so
#    an Ed25519-only agent has to stop Phase 3 rather than fail later in Phase 4.
# ---------------------------------------------------------------------------

key_harness="$TEST_ROOT/keytype.sh"
cat > "$key_harness" <<'EOS'
set -euo pipefail
warn() { printf 'warn: %s\n' "$*"; }
info() { printf 'info: %s\n' "$*"; }
uses_azure() { [[ "${TRACK_AZURE:-0}" == 1 ]]; }
identities="$1"
info "The 1Password SSH agent currently offers:"
while IFS= read -r line; do [[ -z "$line" ]] || info "  $line"; done <<<"$identities"
if uses_azure && ! printf '%s\n' "$identities" | grep -q '(RSA)'; then
  warn "Azure DevOps requires an RSA key, but the agent offers no RSA identity."
  printf 'MANUAL\n'; exit 0
fi
printf 'PASS\n'
EOS

# The harness must mirror setup.sh, or it proves nothing.
grep -Fq 'require_rsa_for_azure' "$SCRIPT_DIR/setup.sh" \
  || fail_test 'the RSA-vs-track check is gone from setup.sh'
grep -Fq "grep -q '(RSA)'" "$SCRIPT_DIR/setup.sh" \
  || fail_test 'the RSA track check no longer matches this test harness'
grep -Fq 'The SSH agent currently offers:' "$SCRIPT_DIR/setup.sh" \
  || fail_test 'setup.sh no longer prints the agent identities'

ed='256 SHA256:AAAA GitHub — Personal (ED25519)'
rsa='3072 SHA256:BBBB Azure DevOps — Work (RSA)'

result="$(TRACK_AZURE=0 bash "$key_harness" "$ed" | tail -1)"
[[ "$result" == PASS ]] || fail_test "Track 1 with an Ed25519 key was rejected (got: $result)"

result="$(TRACK_AZURE=1 bash "$key_harness" "$ed" | tail -1)"
[[ "$result" == MANUAL ]] \
  || fail_test "an Azure track with no RSA key was allowed through (got: $result)"

result="$(TRACK_AZURE=1 bash "$key_harness" "$rsa" | tail -1)"
[[ "$result" == PASS ]] || fail_test "Track 2 with an RSA key was rejected (got: $result)"

result="$(TRACK_AZURE=1 bash "$key_harness" "$ed
$rsa" | tail -1)"
[[ "$result" == PASS ]] || fail_test "Track 3 with both key types was rejected (got: $result)"

# The identities must be echoed so fingerprints can be compared with the provider.
output="$(TRACK_AZURE=0 bash "$key_harness" "$ed")"
grep -Fq 'SHA256:AAAA' <<<"$output" \
  || fail_test 'the agent identities were not shown to the user'

printf 'PASS: 1Password CLI integration, deadline, and track key-type checks\n'

# ---------------------------------------------------------------------------
# 4. The public-key exporter must never put private material in ~/.ssh, and
#    must refuse rather than guess when the 1Password item is ambiguous.
# ---------------------------------------------------------------------------

pin_root="$TEST_ROOT/pin"
mkdir -p "$pin_root/bin" "$pin_root/home/.ssh"
pin_harness="$pin_root/h.sh"
{
  printf 'set -euo pipefail\n'
  printf 'DRY_RUN=0\n'
  printf 'err() { printf "err: %%s\\n" "$*"; }\n'
  printf 'warn() { printf "warn: %%s\\n" "$*"; }\n'
  printf 'info() { printf "info: %%s\\n" "$*"; }\n'
  printf 'ok() { printf "ok: %%s\\n" "$*"; }\n'
  printf 'have() { command -v "$1" >/dev/null 2>&1; }\n'
  printf 'create_directory() { mkdir -p "$1"; }\n'
  printf 'write_text_file() { mkdir -p "$(dirname "$1")"; printf "%%s" "$2" > "$1"; }\n'
  sed -n '/^run_with_deadline() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  sed -n '/^public_key_is_valid() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  sed -n '/^onepassword_ssh_item_titles() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  sed -n '/^export_provider_public_key() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  printf 'export_provider_public_key github && printf "WROTE\\n" || printf "REFUSED\\n"\n'
} > "$pin_harness"

grep -Fq 'export_provider_public_key' "$pin_harness" \
  || fail_test 'export_provider_public_key was not found in setup.sh'

fake_op_pin() {
  cat > "$pin_root/bin/op" <<EOS
#!/bin/sh
case "\$1 \$2" in
  "item list") printf '%s' '$1' ;;
  "item get")  printf '%s' '$2' ;;
esac
EOS
  chmod +x "$pin_root/bin/op"
}

run_pin() {
  rm -f "$pin_root/home/.ssh/github-auth.pub"
  HOME="$pin_root/home" PATH="$pin_root/bin:$PATH" bash "$pin_harness" 2>&1
}

one_item='[{"title":"GitHub — Personal — Authentication"}]'

# A well-formed public key is written.
fake_op_pin "$one_item" '{"fields":[{"label":"public key","value":"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample you@example.com"}]}'
[[ "$(run_pin | tail -1)" == WROTE ]] \
  || fail_test 'a valid public key was not written'
grep -q '^ssh-ed25519 ' "$pin_root/home/.ssh/github-auth.pub" \
  || fail_test 'the written pin file does not contain the public key'

# Private material must never land in ~/.ssh, whatever the field says. Build
# the marker at runtime so the public repository does not contain a key block.
private_key_json='{"fields":[{"label":"public key","value":"-----BEGIN OPENSSH '"PRIVATE KEY"'-----\nb3Blbg==\n-----END OPENSSH '"PRIVATE KEY"'-----"}]}'
fake_op_pin "$one_item" "$private_key_json"
[[ "$(run_pin | tail -1)" == REFUSED ]] \
  || fail_test 'a private key was accepted as a public key'
[[ ! -f "$pin_root/home/.ssh/github-auth.pub" ]] \
  || fail_test 'a file was written from private key material'

# A missing public-key field is a refusal, not an empty file.
fake_op_pin "$one_item" '{"fields":[{"label":"private key","value":"secret"}]}'
[[ "$(run_pin | tail -1)" == REFUSED ]] \
  || fail_test 'a missing public key field did not refuse'
[[ ! -f "$pin_root/home/.ssh/github-auth.pub" ]] \
  || fail_test 'an empty pin file was written'

# Holding an authentication key AND a signing key is a normal, correct GitHub
# setup. Pinning is for authentication, so the signing key must be ignored
# rather than the user being told to rename a sensible pair.
fake_op_pin '[{"title":"GitHub — Authentication"},{"title":"GitHub — Signing"}]' \
  '{"fields":[{"label":"public key","value":"ssh-ed25519 AAAAAUTH you@example.com"}]}'
output="$(run_pin)"
[[ "$(tail -1 <<<"$output")" == WROTE ]] \
  || fail_test 'an authentication key alongside a signing key was not resolved'
grep -Fq 'GitHub — Authentication' <<<"$output" \
  || fail_test 'the authentication key was not the one chosen'

# Two genuine authentication keys stay ambiguous: choosing for the user there
# would silently pin the wrong identity.
fake_op_pin '[{"title":"GitHub — Personal — Authentication"},{"title":"GitHub — Work — Authentication"}]' '{}'
[[ "$(run_pin | tail -1)" == REFUSED ]] \
  || fail_test 'two authentication keys should stay ambiguous'

# A lone signing key is used, but the mismatch is called out.
fake_op_pin '[{"title":"GitHub — Signing"}]' \
  '{"fields":[{"label":"public key","value":"ssh-ed25519 AAAASIGN you@example.com"}]}'
output="$(run_pin)"
grep -Fq 'looks like a signing key' <<<"$output" \
  || fail_test 'pinning a lone signing key did not warn about the key role'

# No match, and several matches, both refuse rather than guess.
fake_op_pin '[]' '{}'
[[ "$(run_pin | tail -1)" == REFUSED ]] || fail_test 'a missing 1Password item did not refuse'
fake_op_pin '[{"title":"GitHub work"},{"title":"GitHub personal"}]' '{}'
output="$(run_pin)"
[[ "$(tail -1 <<<"$output")" == REFUSED ]] || fail_test 'an ambiguous item choice did not refuse'
grep -Fq 'Several 1Password SSH Key items match' <<<"$output" \
  || fail_test 'the ambiguous-item refusal did not explain itself'

# The validator itself, directly.
val_harness="$pin_root/v.sh"
{ printf 'set -euo pipefail\n'
  sed -n '/^public_key_is_valid() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  printf 'public_key_is_valid "$1" && printf "VALID\\n" || printf "INVALID\\n"\n'
} > "$val_harness"
check_key() { bash "$val_harness" "$1"; }
[[ "$(check_key 'ssh-ed25519 AAAA test')" == VALID ]]   || fail_test 'a valid ed25519 key was rejected'
[[ "$(check_key 'ssh-rsa AAAA test')" == VALID ]]       || fail_test 'a valid rsa key was rejected'
[[ "$(check_key '')" == INVALID ]]                      || fail_test 'an empty value was accepted'
[[ "$(check_key 'ecdsa-sha2-nistp256 AAAA')" == INVALID ]] || fail_test 'an unexpected key type was accepted'
# Isolates the PRIVATE KEY guard: single line, valid prefix, so neither the
# multi-line nor the prefix check would reject this on its own.
private_key_line='ssh-ed25519 AAAA -----BEGIN OPENSSH '"PRIVATE KEY"'-----'
[[ "$(check_key "$private_key_line")" == INVALID ]] \
  || fail_test 'a single-line value naming a PRIVATE KEY was accepted'
[[ "$(check_key "ssh-ed25519 AAAA
ssh-rsa BBBB")" == INVALID ]]                           || fail_test 'a multi-line value was accepted'

# ---------------------------------------------------------------------------
# 5. Pinning must follow the saved hosting track, not assume GitHub.
# ---------------------------------------------------------------------------

track_root="$TEST_ROOT/tracks"
mkdir -p "$track_root/bin"
cat > "$track_root/bin/op" <<'EOS'
#!/bin/sh
case "$1 $2" in
  "item list") printf '%s' '[{"title":"GitHub — Personal — Authentication"},{"title":"Azure DevOps — Work — Authentication"}]' ;;
  "item get")
    case "$3" in
      *GitHub*) printf '%s' '{"fields":[{"label":"public key","value":"ssh-ed25519 AAAAGH you@example.com"}]}' ;;
      *Azure*)  printf '%s' '{"fields":[{"label":"public key","value":"ssh-rsa AAAAAZ work@example.com"}]}' ;;
    esac ;;
esac
EOS
chmod +x "$track_root/bin/op"

pin_for_track() {
  local track="$1" home="$track_root/h$1" state="$track_root/s$1"
  rm -rf "$home" "$state"
  mkdir -p "$home/.ssh" "$state"
  HOME="$home" DAY_ONE_MAC_STATE_ROOT="$state" PATH="$track_root/bin:$PATH" \
    "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --ssh-pin --track "$track" --stack node --yes \
    >/dev/null 2>&1 || true
  find "$home/.ssh" -maxdepth 1 -type f -name '*.pub' -exec basename {} \; 2>/dev/null \
    | sort | tr '\n' ' '
}

result="$(pin_for_track 1)"
[[ "$result" == "github-auth.pub " ]] \
  || fail_test "Track 1 should pin only the GitHub key (got: $result)"

result="$(pin_for_track 2)"
[[ "$result" == "azure-devops-auth.pub " ]] \
  || fail_test "Track 2 should pin only the Azure key, not GitHub (got: $result)"

result="$(pin_for_track 3)"
[[ "$result" == "azure-devops-auth.pub github-auth.pub " ]] \
  || fail_test "Track 3 should pin both keys (got: $result)"

printf 'PASS: public-key exporter writes only validated public keys, per track\n'
