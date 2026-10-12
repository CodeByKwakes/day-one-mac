#!/usr/bin/env bash
# Callback overrides below are invoked by the sourced setup-centre functions.
# shellcheck disable=SC2329
# Test import handoff without launching apps or changing a user's shortcuts.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-shortcuts.XXXXXX")"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/runtime with spaces/scripts" "$TEST_ROOT/runtime with spaces/config/shortcuts" "$TEST_ROOT/bin" "$TEST_ROOT/home"
cp "$SCRIPT_DIR/configure-shortcuts.sh" "$TEST_ROOT/runtime with spaces/scripts/"
cp "$SCRIPT_DIR/../config/shortcuts/Open in VS Code.shortcut" "$TEST_ROOT/runtime with spaces/config/shortcuts/"
export HOME="$TEST_ROOT/home" SHORTCUT_TEST_LOG="$TEST_ROOT/open.log"
export PATH="$TEST_ROOT/bin:$PATH"
cat > "$TEST_ROOT/bin/uname" <<'STUB'
#!/bin/bash
printf 'Darwin\n'
STUB
cat > "$TEST_ROOT/bin/open" <<'STUB'
#!/bin/bash
printf '%s\n' "$@" >> "$SHORTCUT_TEST_LOG"
exit "${SHORTCUT_TEST_OPEN_EXIT:-0}"
STUB
chmod +x "$TEST_ROOT/bin/"*
manager="$TEST_ROOT/runtime with spaces/scripts/configure-shortcuts.sh"
"$manager" > "$TEST_ROOT/out"
"$manager" --import --dry-run >> "$TEST_ROOT/out"
"$manager" --guided --dry-run </dev/null >> "$TEST_ROOT/out"
[[ ! -e "$SHORTCUT_TEST_LOG" ]]
"$manager" --import > "$TEST_ROOT/out"
printf '%s\n' '-a' 'Shortcuts' "$TEST_ROOT/runtime with spaces/config/shortcuts/Open in VS Code.shortcut" > "$TEST_ROOT/expected"
cmp "$SHORTCUT_TEST_LOG" "$TEST_ROOT/expected"
grep -Fq 'installation is not yet verified' "$TEST_ROOT/out"
[[ ! -e "$HOME/.day-one-mac" ]]
expect_failure() {
  local expected="$1" actual=0; shift
  "$manager" "$@" > "$TEST_ROOT/out" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || { cat "$TEST_ROOT/out"; exit 1; }
}
expect_failure 2 --plan --import
expect_failure 2 --unknown
expect_failure 2 --guided </dev/null
export SHORTCUT_TEST_OPEN_EXIT=7
expect_failure 7 --import
unset SHORTCUT_TEST_OPEN_EXIT
mv "$TEST_ROOT/runtime with spaces/config/shortcuts/Open in VS Code.shortcut" "$TEST_ROOT/original.shortcut"
expect_failure 1 --import
ln -s "$TEST_ROOT/original.shortcut" "$TEST_ROOT/runtime with spaces/config/shortcuts/Open in VS Code.shortcut"
expect_failure 1 --import
printf 'PASS: shortcut preview, import handoff, spaces, failure propagation, missing/symlink assets and no false installation state\n'

# The setup centre must preserve preview semantics before the import helper.
(
  source "$SCRIPT_DIR/lib/wizard-centre.sh"
  centre_pause() { :; }
  centre_command() { printf '%s\n' "$*" > "$TEST_ROOT/centre-command"; }
  select_one() {
    if [[ "$menu_calls" == 0 ]]; then SINGLE_RESULT=shortcuts
    else SINGLE_RESULT=back
    fi
    menu_calls=$((menu_calls + 1))
  }
  for mode in 0 1; do
    DRY_RUN="$mode" menu_calls=0
    centre_other_actions
    if [[ "$mode" == 1 ]]; then expected='shortcuts --plan'
    else expected='shortcuts --guided'
    fi
    [[ "$(cat "$TEST_ROOT/centre-command")" == "$expected" ]]
  done
)
printf 'PASS: setup centre uses guided import normally and preview during dry run\n'
