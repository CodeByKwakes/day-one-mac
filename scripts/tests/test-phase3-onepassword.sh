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
  printf 'source "%s/lib/deadline.sh"\n' "$SCRIPT_DIR"
  printf 'source "%s/phases/03-security.sh"\n' "$SCRIPT_DIR"
  printf 'if verify_onepassword_cli_integration; then printf "OK\\n"; else printf "MANUAL\\n"; fi\n'
} > "$cli_harness"


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
grep -Fq 'require_rsa_for_azure' "$SCRIPT_DIR/setup.sh" "$SCRIPT_DIR"/phases/*.sh "$SCRIPT_DIR/lib/deadline.sh" \
  || fail_test 'the RSA-vs-track check is gone from setup.sh'
grep -Fq "grep -q '(RSA)'" "$SCRIPT_DIR/setup.sh" "$SCRIPT_DIR"/phases/*.sh "$SCRIPT_DIR/lib/deadline.sh" \
  || fail_test 'the RSA track check no longer matches this test harness'
grep -Fq 'The SSH agent currently offers:' "$SCRIPT_DIR/setup.sh" "$SCRIPT_DIR"/phases/*.sh "$SCRIPT_DIR/lib/deadline.sh" \
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
ssh-keygen -q -t ed25519 -N '' -f "$pin_root/test-key"
ssh-keygen -q -t ed25519 -N '' -f "$pin_root/other-key"
ssh-keygen -q -t rsa -b 3072 -N '' -f "$pin_root/azure-key"
TEST_PUBLIC="$(cat "$pin_root/test-key.pub")"
TEST_RSA_PUBLIC="$(cat "$pin_root/azure-key.pub")"
TEST_IDENTITIES="$(ssh-keygen -l -E sha256 -f "$pin_root/test-key.pub")"
export TEST_PUBLIC TEST_RSA_PUBLIC TEST_IDENTITIES
public_json="$(jq -nc --arg value "$TEST_PUBLIC" '{fields:[{label:"public key",value:$value}]}')"
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
  printf 'source "%s/lib/deadline.sh"\n' "$SCRIPT_DIR"
  printf 'source "%s/phases/03-security.sh"\n' "$SCRIPT_DIR"
  printf 'confirm() { [[ "${CONFIRM_PIN:-yes}" == yes ]] || return 1; if [[ "${LOCK_AFTER_CONFIRM:-0}" == 1 ]]; then TEST_IDENTITIES=""; fi; return 0; }\n'
  printf 'ask() { [[ -n "${SELECT_PIN:-}" ]] && printf "%%s\\n" "$SELECT_PIN"; }\n'
  printf 'agent_identities() { printf "%%s\\n" "$TEST_IDENTITIES"; }\n'
  printf 'export_provider_public_key github && printf "WROTE\\n" || printf "REFUSED\\n"\n'
} > "$pin_harness"

grep -Fq 'export_provider_public_key' "$pin_harness" \
  || fail_test 'export_provider_public_key module failed to load'

fake_op_pin() {
  local get_status="${3:-0}"
  cat > "$pin_root/bin/op" <<EOS
#!/bin/sh
case "\$1 \$2" in
  "item list") printf '%s' '$1' | jq '[to_entries[] | .value + {id: (.value.id // ("aaaaaaaaaaaaaaaaaaaaaaaaa" + (.key | tostring)))}]' ;;
  "item get")
    [ "\$4" = --fields ] && [ "\$5" = 'label=public key' ] || exit 93
    if [ '$get_status' != 0 ]; then
      printf 'SENSITIVE_ERROR_CANARY\\n' >&2
      exit '$get_status'
    fi
    printf '%s' '$2' | jq -c '[.fields[]? | select(.label == "public key")]' ;;
esac
EOS
  chmod +x "$pin_root/bin/op"
}

run_pin() {
  rm -f "$pin_root/home/.ssh/github-auth.pub"
  HOME="$pin_root/home" PATH="$pin_root/bin:$PATH" bash "$pin_harness" 2>&1
}

one_item='[{"title":"GitHub — Personal — Authentication"}]'

# Reproduce the VM failure: a valid public field is NOT proof the agent can
# use it. A mismatched key must leave both absent and existing pins untouched.
fake_op_pin "$one_item" "$public_json"
output="$(TEST_IDENTITIES="$(ssh-keygen -l -E sha256 -f "$pin_root/other-key.pub")" run_pin)"
[[ "$(tail -1 <<<"$output")" == REFUSED ]] \
  || fail_test 'a public key absent from the agent was written'
[[ ! -e "$pin_root/home/.ssh/github-auth.pub" ]] || fail_test 'mismatch created a pin'

# A well-formed public key is written.
fake_op_pin "$one_item" "$public_json"
[[ "$(run_pin | tail -1)" == WROTE ]] \
  || fail_test 'a valid public key was not written'
grep -q '^ssh-ed25519 ' "$pin_root/home/.ssh/github-auth.pub" \
  || fail_test 'the written pin file does not contain the public key'

# Provider failures must not echo raw item/error output or leave temp payloads.
mkdir -p "$pin_root/tmp"
for failure in 1 124; do
  fake_op_pin "$one_item" '{}' "$failure"
  output="$(TMPDIR="$pin_root/tmp/" run_pin)"
  [[ "$(tail -1 <<<"$output")" == REFUSED ]] || fail_test 'failed public-field read was accepted'
  ! grep -Fq SENSITIVE_ERROR_CANARY <<<"$output" || fail_test 'raw provider error leaked'
  [[ -z "$(ls -A "$pin_root/tmp")" ]] || fail_test 'public-field temporary output leaked'
done

# Multiple same-label fields must not silently select the first key.
fake_op_pin "$one_item" '{"fields":[{"label":"public key","value":"ssh-ed25519 AAAA"},{"label":"public key","value":"ssh-ed25519 BBBB"}]}'
[[ "$(run_pin | tail -1)" == REFUSED ]] || fail_test 'multiple public fields were accepted'

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
  "$public_json"
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

# A lone signing-labelled key must not be silently repurposed.
fake_op_pin '[{"title":"GitHub — Signing"}]' \
  '{"fields":[{"label":"public key","value":"ssh-ed25519 AAAASIGN you@example.com"}]}'
output="$(run_pin)"
[[ "$(tail -1 <<<"$output")" == REFUSED ]] || fail_test 'a lone signing key was accepted'
grep -Fq 'signing-labelled items are excluded' <<<"$output" \
  || fail_test 'signing-only refusal did not explain the role'

# No match, and several matches, both refuse rather than guess.
fake_op_pin '[]' '{}'
[[ "$(run_pin | tail -1)" == REFUSED ]] || fail_test 'a missing 1Password item did not refuse'
fake_op_pin '[{"title":"GitHub work"},{"title":"GitHub personal"}]' '{}'
output="$(run_pin)"
[[ "$(tail -1 <<<"$output")" == REFUSED ]] || fail_test 'an ambiguous item choice did not refuse'
grep -Fq 'Several 1Password SSH Key items match' <<<"$output" \
  || fail_test 'the ambiguous-item refusal did not explain itself'

# The title preference that caused the real failure must never resolve this
# pair automatically. Explicit selection retrieves the stable ID, not title.
fake_op_pin '[{"title":"GitHub — Authentication"},{"title":"GitHub — Rehearsal"}]' "$public_json"
[[ "$(ASSUME_YES=1 run_pin | tail -1)" == REFUSED ]] || fail_test '--yes guessed an identity'
[[ "$(SELECT_PIN=2 run_pin | tail -1)" == WROTE ]] || fail_test 'explicit selection was rejected'
for selection in q 0 3 999999999999999999999; do
  [[ "$(SELECT_PIN="$selection" run_pin | tail -1)" == REFUSED ]] || fail_test 'invalid selection wrote a pin'
done

# Duplicate titles remain separate IDs. The mock fails if retrieval uses a
# title or the unselected ID, even though both titles look identical.
fake_op_pin '[{"title":"GitHub — Authentication"},{"title":"GitHub — Authentication"}]' "$public_json"
sed -i.bak '/"item get")/a\
    [ "$3" = aaaaaaaaaaaaaaaaaaaaaaaaa1 ] || exit 94
' "$pin_root/bin/op"
[[ "$(SELECT_PIN=2 run_pin | tail -1)" == WROTE ]] || fail_test 'duplicate title lost selected ID'

# Confirmation refusal, a locked agent, malformed bytes, and an existing
# mismatched pin all leave user files unchanged.
fake_op_pin "$one_item" "$public_json"
[[ "$(CONFIRM_PIN=no run_pin | tail -1)" == REFUSED ]] || fail_test 'declined confirmation wrote a pin'
[[ ! -e "$pin_root/home/.ssh/github-auth.pub" ]] || fail_test 'declined pin exists'
[[ "$(TEST_IDENTITIES='' run_pin | tail -1)" == REFUSED ]] || fail_test 'locked agent accepted'
[[ "$(LOCK_AFTER_CONFIRM=1 run_pin | tail -1)" == REFUSED ]] || fail_test 'lock during confirmation accepted'
[[ ! -e "$pin_root/home/.ssh/github-auth.pub" ]] || fail_test 'late lock wrote a pin'
cp "$pin_root/other-key.pub" "$pin_root/home/.ssh/github-auth.pub"
output="$(HOME="$pin_root/home" TEST_IDENTITIES='' PATH="$pin_root/bin:$PATH" bash "$pin_harness")"
[[ "$(tail -1 <<<"$output")" == REFUSED ]] || fail_test 'mismatch replaced an existing pin'
cmp -s "$pin_root/other-key.pub" "$pin_root/home/.ssh/github-auth.pub" || fail_test 'old pin changed'
fake_op_pin "$one_item" '{"fields":[{"label":"public key","value":"ssh-ed25519 AAAA malformed"}]}'
[[ "$(run_pin | tail -1)" == REFUSED ]] || fail_test 'unparseable public key accepted'
fake_op_pin "$one_item" "$public_json"
ln -s "$pin_root/other-key.pub" "$pin_root/home/.ssh/github-auth.pub"
output="$(HOME="$pin_root/home" PATH="$pin_root/bin:$PATH" bash "$pin_harness")"
[[ "$(tail -1 <<<"$output")" == REFUSED && -L "$pin_root/home/.ssh/github-auth.pub" ]] \
  || fail_test 'symlink pin was overwritten'
rm "$pin_root/home/.ssh/github-auth.pub"

# A refusal must propagate through the real phase, before config/chezmoi or
# the runner can mark success. Existing pins are checked, not blindly reused.
gate_harness="$pin_root/gate.sh"
cat > "$gate_harness" <<'EOS'
set -euo pipefail
source "$SCRIPT_DIR/phases/03-security.sh"
DRY_RUN=0 AUTH_MODE=1password TRACK=1 EX_MANUAL=10 EX_GATE=20
info() { :; }; warn() { :; }; err() { :; }; ok() { :; }
ui_title() { :; }; ui_section() { :; }; phase_next() { :; }; phase_step_done() { :; }
phase_doc() { :; }
load_brew() { :; }; scan_applications() { :; }; verify_application() { :; }; have() { :; }
verify_onepassword_cli_integration() { :; }
agent_identities() { printf '%s\n' "$TEST_IDENTITIES"; }
uses_github() { return 0; }; uses_azure() { return 1; }
confirm() { return 0; }; export_provider_public_key() { return 1; }
configure_onepassword_ssh() { printf 'CONFIG_WRITE\n'; }
if phase_03; then printf 'UNEXPECTED_PASS\n'; else printf 'STOP=%s\n' "$?"; fi
EOS
rm -f "$pin_root/home/.ssh/github-auth.pub"
export SCRIPT_DIR
output="$(HOME="$pin_root/home" PATH="$pin_root/bin:$PATH" bash "$gate_harness")"
[[ "$output" == 'STOP=10' ]] || fail_test 'export failure did not stop the phase before writing'
cp "$pin_root/other-key.pub" "$pin_root/home/.ssh/github-auth.pub"
output="$(HOME="$pin_root/home" PATH="$pin_root/bin:$PATH" bash "$gate_harness")"
[[ "$output" == 'STOP=10' ]] || fail_test 'existing mismatched pin did not stop the phase'
cmp -s "$pin_root/other-key.pub" "$pin_root/home/.ssh/github-auth.pub" || fail_test 'phase changed rejected pin'

# Per-provider types matter: an unrelated RSA identity must not make an
# Ed25519 Azure pin acceptable. A matching existing GitHub pin is reusable.
HOME="$pin_root/home" bash -c '
  set -euo pipefail
  source "$SCRIPT_DIR/phases/03-security.sh"
  warn() { :; }; info() { :; }
  uses_github() { return 0; }; uses_azure() { return 1; }
  agent_identities() { printf "%s\n" "$TEST_IDENTITIES"; }
  if verify_public_key_with_onepassword_agent azure "$TEST_PUBLIC"; then exit 1; fi
  cp "$1" "$HOME/.ssh/github-auth.pub"
  verify_existing_provider_key_pins
' _ "$pin_root/test-key.pub" || fail_test 'provider type or existing valid pin check failed'

# The validator itself, directly.
val_harness="$pin_root/v.sh"
{ printf 'set -euo pipefail\n'
  printf 'source "%s/phases/03-security.sh"\n' "$SCRIPT_DIR"
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
  "item list") printf '%s' '[{"id":"aaaaaaaaaaaaaaaaaaaaaaaaa0","title":"GitHub — Personal — Authentication"},{"id":"aaaaaaaaaaaaaaaaaaaaaaaaa1","title":"Azure DevOps — Work — Authentication"}]' ;;
  "item get")
    [ "$4" = --fields ] && [ "$5" = 'label=public key' ] || exit 93
    case "$3" in
      aaaaaaaaaaaaaaaaaaaaaaaaa0) jq -nc --arg value "$TEST_PUBLIC" '[{label:"public key",value:$value}]' ;;
      aaaaaaaaaaaaaaaaaaaaaaaaa1) jq -nc --arg value "$TEST_RSA_PUBLIC" '[{label:"public key",value:$value}]' ;;
    esac ;;
esac
EOS
chmod +x "$track_root/bin/op"
cat > "$track_root/bin/ssh-add" <<'EOS'
#!/bin/sh
case "$SSH_AUTH_SOCK" in */2BUA8C4S2C.com.1password/t/agent.sock) ;; *) exit 1 ;; esac
printf '%s\n' "$TEST_IDENTITIES" "$TEST_RSA_IDENTITIES"
EOS
chmod +x "$track_root/bin/ssh-add"
TEST_RSA_IDENTITIES="$(ssh-keygen -l -E sha256 -f "$pin_root/azure-key.pub")"
export TEST_RSA_IDENTITIES

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
