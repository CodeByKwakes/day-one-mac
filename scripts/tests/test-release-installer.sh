#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-mac-release-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

"$SCRIPT_DIR/build-release.sh" "$TEST_ROOT/dist" >/dev/null
archive="$TEST_ROOT/dist/day-one-mac-runtime.tar.gz"
mkdir -p "$TEST_ROOT/temporary"
HOME="$TEST_ROOT/installed-home" TMPDIR="$TEST_ROOT/temporary" \
  "$PROJECT_ROOT/install-day-one-mac" --archive "$archive" >/dev/null
HOME="$TEST_ROOT/installed-home" "$TEST_ROOT/installed-home/.local/bin/day-one-mac" verify >/dev/null
[[ -z "$(find "$TEST_ROOT/temporary" -mindepth 1 -print -quit)" ]] || fail 'installer leaked extraction directory'

# Explicit archive must win over the checkout autodetection.
printf 'corrupted\n' >> "$archive"
if HOME="$TEST_ROOT/corrupt-home" "$PROJECT_ROOT/install-day-one-mac" --archive "$archive" >"$TEST_ROOT/result" 2>&1; then
  fail 'corrupt explicit archive was accepted or ignored'
fi
grep -Fq 'checksum verification failed' "$TEST_ROOT/result" || fail 'checksum failure was not explained'
[[ ! -e "$TEST_ROOT/corrupt-home/.local/bin/day-one-mac" ]] || fail 'corruption installed a launcher'

# Restore matching bytes/checksum, then reject provenance before extraction.
(cd "$TEST_ROOT/dist" && shasum -a 256 day-one-mac-runtime.tar.gz > day-one-mac-runtime.tar.gz.sha256)
mkdir -p "$TEST_ROOT/bin"
cat > "$TEST_ROOT/bin/gh" <<'FIXTURE'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$TEST_GH_LOG"
exit 1
FIXTURE
chmod +x "$TEST_ROOT/bin/gh"
if HOME="$TEST_ROOT/untrusted-home" TEST_GH_LOG="$TEST_ROOT/gh.log" PATH="$TEST_ROOT/bin:$PATH" \
  "$PROJECT_ROOT/install-day-one-mac" --archive "$archive" --require-attestation >"$TEST_ROOT/result" 2>&1; then
  fail 'failed attestation was accepted'
fi
grep -Fq 'attestation verify' "$TEST_ROOT/gh.log" || fail 'attestation verifier was not invoked'
grep -Fq -- '--signer-workflow CodeByKwakes/day-one-mac/.github/workflows/release.yml' "$TEST_ROOT/gh.log" || fail 'signer workflow not constrained'
[[ ! -e "$TEST_ROOT/untrusted-home/.local/bin/day-one-mac" ]] || fail 'untrusted archive installed a launcher'
if "$PROJECT_ROOT/install-day-one-mac" --source "$PROJECT_ROOT" --require-attestation >/dev/null 2>&1; then
  fail 'source mode bypassed required attestation'
fi
printf 'PASS: offline release install, extraction cleanup, checksum rejection and fail-closed provenance\n'
