#!/usr/bin/env bash
# Regression tests for Phase 5's VS Code integration with chezmoi.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-mac-chezmoi-tools.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail_test() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

harness="$TEST_ROOT/harness.sh"
{
  printf '%s\n' \
    'set -euo pipefail' \
    'PRIMARY_IDE=vscode' \
    'DRY_RUN=0' \
    'EX_MANUAL=10' \
    'info(){ :; }' \
    'warn(){ :; }' \
    'ok(){ :; }' \
    'confirm(){ return 0; }' \
    'write_text_file(){ printf "%s" "$2" > "$1"; }'
  awk '/^chezmoi_text_diff\(\)/ { copy=1 } /^phase_05\(\)/ { copy=0 } copy' "$SCRIPT_DIR/setup.sh"
} > "$harness"

fake_bin="$TEST_ROOT/bin"
mkdir -p "$fake_bin"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$fake_bin/code"
printf '%s\n' \
  '#!/bin/sh' \
  'printf "%s\n" "$*" > "$CHEZMOI_ARGS_FILE"' > "$fake_bin/chezmoi"
chmod +x "$fake_bin/code" "$fake_bin/chezmoi"

config="$TEST_ROOT/chezmoi.toml"
printf '%s\n' '[data]' 'name = "Test User"' > "$config"
PATH="$fake_bin:$PATH" bash -c 'source "$1"; configure_chezmoi_vscode_tools "$2"' _ "$harness" "$config"

grep -Fq '[diff]' "$config" || fail_test 'missing VS Code diff section'
grep -Fq 'args = ["--wait", "--diff"]' "$config" || fail_test 'missing VS Code diff arguments'
grep -Fq '[merge]' "$config" || fail_test 'missing VS Code merge section'
grep -Fq 'code --new-window --wait --merge' "$config" || fail_test 'missing VS Code merge command'
python3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$config" \
  || fail_test 'generated chezmoi configuration is not valid TOML'

before="$(shasum -a 256 "$config" | awk '{print $1}')"
PATH="$fake_bin:$PATH" bash -c 'source "$1"; configure_chezmoi_vscode_tools "$2"' _ "$harness" "$config"
after="$(shasum -a 256 "$config" | awk '{print $1}')"
[[ "$before" == "$after" ]] || fail_test 'rerun duplicated or rewrote the VS Code tool sections'

custom="$TEST_ROOT/custom.toml"
printf '%s\n' \
  '[diff]' 'command = "meld"' \
  '[merge]' 'command = "nvim"' > "$custom"
before="$(shasum -a 256 "$custom" | awk '{print $1}')"
PATH="$fake_bin:$PATH" bash -c 'source "$1"; configure_chezmoi_vscode_tools "$2"' _ "$harness" "$custom"
after="$(shasum -a 256 "$custom" | awk '{print $1}')"
[[ "$before" == "$after" ]] || fail_test 'custom chezmoi tools were overwritten'

args_file="$TEST_ROOT/chezmoi-args"
CHEZMOI_ARGS_FILE="$args_file" PATH="$fake_bin:$PATH" \
  bash -c 'source "$1"; chezmoi_text_diff' _ "$harness"
grep -Fxq -- '--use-builtin-diff diff --no-pager' "$args_file" \
  || fail_test 'the Phase 5 drift gate did not force chezmoi built-in diff'

printf 'PASS: chezmoi VS Code diff and merge integration\n'
