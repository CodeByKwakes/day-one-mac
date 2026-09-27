#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-preferences.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_STATE="$TEST_ROOT/state"
MOCK_PREFS="$TEST_ROOT/preferences"
export MOCK_PREFS
mkdir -p "$TEST_ROOT/bin" "$MOCK_PREFS"
cat > "$TEST_ROOT/bin/defaults" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_PREFS/calls"
case "$1" in
  export)
    [[ "${MOCK_READ_FAIL:-0}" == 0 ]] || exit 7
    if [[ "${MOCK_BAD_EXPORT:-0}" == 1 ]]; then printf '<plist version="1.0"><array/></plist>'; exit; fi
    cat "$MOCK_PREFS/$2.plist" ;;
  write)
    [[ "${MOCK_FAIL_KEY:-}" != "$3" ]] || exit 7
    type="${4#-}"; [[ "$type" != int ]] || type=integer
    if /usr/bin/plutil -type "$3" "$MOCK_PREFS/$2.plist" >/dev/null 2>&1; then verb=-replace; else verb=-insert; fi
    /usr/bin/plutil "$verb" "$3" "-$type" "$5" "$MOCK_PREFS/$2.plist"
    [[ "${MOCK_FAIL_AFTER_KEY:-}" != "$3" ]] || exit 7 ;;
  *) exit 99 ;;
esac
MOCK
cat > "$TEST_ROOT/bin/uname" <<'MOCK'
#!/usr/bin/env bash
case "$1" in -s) printf 'Darwin\n' ;; -m) printf 'arm64\n' ;; *) exit 99 ;; esac
MOCK
cat > "$TEST_ROOT/bin/killall" <<'MOCK'
#!/usr/bin/env bash
touch "$MOCK_PREFS/restarted"
exit 99
MOCK
chmod +x "$TEST_ROOT/bin/"*
for domain in com.apple.finder com.apple.dock NSGlobalDomain; do /usr/bin/plutil -create xml1 "$MOCK_PREFS/$domain.plist"; done
/usr/bin/plutil -insert tilesize -float 52.5 "$MOCK_PREFS/com.apple.dock.plist"
/usr/bin/plutil -insert orientation -string $'left\n' "$MOCK_PREFS/com.apple.dock.plist"
/usr/bin/plutil -insert KeyRepeat -integer 6 "$MOCK_PREFS/NSGlobalDomain.plist"
/usr/bin/plutil -insert InitialKeyRepeat -integer 30 "$MOCK_PREFS/NSGlobalDomain.plist"
run() { env PATH="$TEST_ROOT/bin:$PATH" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" DAY_ONE_MAC_STATE_DIR="$TEST_STATE" "$SCRIPT_DIR/day-one-mac" advanced --module 19 "$@"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
expect_failure() {
  local expected="$1" actual=0
  shift
  "$@" > "$TEST_ROOT/error" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || { cat "$TEST_ROOT/error"; fail "expected $expected got $actual"; }
}
printf 'setting\tfinder-path\nsetting\tdock-size\nsetting\tdock-right\nsetting\tkeyboard-fast\nsetting\tautocorrect-off\n' > "$TEST_ROOT/selection.tsv"
run --plan --manifest "$TEST_ROOT/selection.tsv" > "$TEST_ROOT/plan"
[[ ! -e "$TEST_STATE" && ! -e "$TEST_STATE.operation.lock" ]] || fail 'plan wrote state'
if grep -q '^write ' "$MOCK_PREFS/calls"; then fail 'plan wrote preferences'; fi
expect_failure 10 run --apply --manifest "$TEST_ROOT/selection.tsv" --yes
mkdir -p "$TEST_STATE/completed"
printf fixture > "$TEST_STATE/completed/08"
MOCK_READ_FAIL=1 expect_failure 1 run --apply --manifest "$TEST_ROOT/selection.tsv" --yes
MOCK_BAD_EXPORT=1 expect_failure 1 run --apply --manifest "$TEST_ROOT/selection.tsv" --yes
[[ ! -e "$TEST_STATE/preferences-19-selection.tsv" ]] || fail 'unreadable defaults treated as absence'
MOCK_FAIL_KEY=InitialKeyRepeat expect_failure 1 run --apply --manifest "$TEST_ROOT/selection.tsv" --yes
records="$TEST_STATE/preferences-19/keys"
grep -q $'\tpending$' "$records/NSGlobalDomain.InitialKeyRepeat.tsv" || fail 'pending intent missing'
grep -q $'\tmissing\t-\tbool\t' "$records/com.apple.finder.ShowPathbar.tsv" || fail 'absent original not recorded'
[[ "$(cut -f 4 "$records/com.apple.dock.tilesize.tsv" | base64 -D)" == 52.5 ]] || fail 'float original lost'
[[ "$(cut -f 4 "$records/com.apple.dock.orientation.tsv")" == "$(printf 'left\n' | base64)" ]] || fail 'string trailing newline lost'
grep -q $'\tpending$' "$records/NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled.tsv" || fail 'later key was not prepared before earlier writes'
/usr/bin/plutil -insert NSAutomaticSpellingCorrectionEnabled -bool true "$MOCK_PREFS/NSGlobalDomain.plist"
expect_failure 1 run --resume --yes
/usr/bin/plutil -remove NSAutomaticSpellingCorrectionEnabled "$MOCK_PREFS/NSGlobalDomain.plist"
MOCK_FAIL_AFTER_KEY=InitialKeyRepeat expect_failure 1 run --resume --yes
grep -q $'\tpending$' "$records/NSGlobalDomain.InitialKeyRepeat.tsv" || fail 'uncertain write lost its pending intent'
run --resume --yes > "$TEST_ROOT/resume"
[[ "$(grep -c '^write NSGlobalDomain InitialKeyRepeat ' "$MOCK_PREFS/calls")" == 2 ]] || fail 'completed but unacknowledged write was repeated'
run --check > "$TEST_ROOT/check"
writes="$(grep -c '^write ' "$MOCK_PREFS/calls")"
run --resume --yes > "$TEST_ROOT/repeat"
[[ "$writes" == "$(grep -c '^write ' "$MOCK_PREFS/calls")" ]] || fail 'idempotent resume rewrote preferences'
/usr/bin/plutil -replace KeyRepeat -integer 9 "$MOCK_PREFS/NSGlobalDomain.plist"
expect_failure 1 run --check
expect_failure 1 run --resume --yes
expect_failure 1 run --apply --manifest "$TEST_ROOT/selection.tsv" --yes
[[ "$writes" == "$(grep -c '^write ' "$MOCK_PREFS/calls")" ]] || fail 'external change overwritten'
/usr/bin/plutil -replace KeyRepeat -integer 2 "$MOCK_PREFS/NSGlobalDomain.plist"
run --check > "$TEST_ROOT/reconciled"
before="$(find "$TEST_STATE" -type f -exec shasum -a 256 {} + | sort)"
run --plan > "$TEST_ROOT/saved-plan"
run --check > "$TEST_ROOT/saved-check"
env PATH="$TEST_ROOT/bin:$PATH" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" DAY_ONE_MAC_STATE_DIR="$TEST_STATE" "$SCRIPT_DIR/optional-status.sh" > "$TEST_ROOT/status"
grep -Eq 'partial +19 —' "$TEST_ROOT/status" || fail 'manual GUI work falsely completed'
[[ "$before" == "$(find "$TEST_STATE" -type f -exec shasum -a 256 {} + | sort)" ]] || fail 'read-only action changed records'
mkdir "$TEST_STATE.operation.lock"
printf '%s\n' "$$" > "$TEST_STATE.operation.lock/owner"
expect_failure 75 run --resume --yes
run --check > "$TEST_ROOT/locked-check"
rm "$TEST_STATE.operation.lock/owner"
rmdir "$TEST_STATE.operation.lock"
for id in screenshot-location battery-percentage firewall finder-path$'\t'evil; do
  printf 'setting\t%s\n' "$id" > "$TEST_ROOT/invalid.tsv"
  expect_failure 2 run --plan --manifest "$TEST_ROOT/invalid.tsv"
done
mv "$records/com.apple.dock.tilesize.tsv" "$TEST_ROOT/original-record"
ln -s "$TEST_ROOT/original-record" "$records/com.apple.dock.tilesize.tsv"
expect_failure 1 run --resume --yes
[[ -L "$records/com.apple.dock.tilesize.tsv" && ! -e "$MOCK_PREFS/restarted" ]] || fail 'unsafe record replaced or GUI restarted'
printf 'PASS: typed originals, missing keys, interrupted writes, conflict refusal, idempotency, locks and no live defaults\n'
