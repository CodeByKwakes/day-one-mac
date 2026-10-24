#!/usr/bin/env bash
# Retained operations extracted from the retired whole-machine suite.
set -euo pipefail
exec </dev/null
unset TERM_PROGRAM WARP_IS_LOCAL_SHELL_SESSION
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-retained.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
trap 'printf "Retained operation test failed at line %s\n" "$LINENO" >&2' ERR
TEST_HOME="$TEST_ROOT/home"
TEST_STATE_ROOT="$TEST_HOME/.day-one-mac"
TEST_STATE="$TEST_STATE_ROOT"
mkdir -p "$TEST_STATE/originals" "$TEST_ROOT/bin"
printf '#!/bin/sh\nprintf "Enrolled via DEP: No\\nMDM enrollment: No\\n"\n' > "$TEST_ROOT/bin/profiles"
chmod +x "$TEST_ROOT/bin/profiles"
export PATH="$TEST_ROOT/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export DAY_ONE_MAC_DISABLE_BREW_DISCOVERY=1
settings_preview="$TEST_ROOT/macos-settings-preview.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" --preview > "$settings_preview"
grep -Fq 'Security review — never changed automatically' "$settings_preview"
grep -Fq 'Show all filename extensions' "$settings_preview"
[[ ! -e "$TEST_STATE_ROOT/macos-settings-status" ]]

settings_bin="$TEST_ROOT/settings-bin"
settings_defaults_state="$TEST_ROOT/defaults-value"
mkdir -p "$settings_bin" "$TEST_STATE_ROOT"
printf '0\n' > "$settings_defaults_state"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'case "$1" in' \
  '  read-type) printf "Type is %s\\n" "${TEST_DEFAULTS_TYPE:-boolean}" ;;' \
  '  read) sed -n "1p" "$TEST_DEFAULTS_STATE" ;;' \
  '  write)' \
  '    value="${!#}"' \
  '    if [[ "$4" == -bool && "$value" != true && "$value" != false ]]; then exit 64; fi' \
  '    printf "%s\\n" "$value" > "$TEST_DEFAULTS_STATE"' \
  '    ;;' \
  '  delete) : > "$TEST_DEFAULTS_STATE" ;;' \
  '  *) exit 2 ;;' \
  'esac' > "$settings_bin/defaults"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$settings_bin/killall"
chmod +x "$settings_bin/defaults" "$settings_bin/killall"
printf 'finder-extensions\n' > "$TEST_STATE_ROOT/macos-settings-selection"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  TEST_DEFAULTS_STATE="$settings_defaults_state" PATH="$settings_bin:$PATH" \
  "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" --apply --yes > "$TEST_ROOT/macos-settings-apply.txt"
grep -Fxq 'true' "$settings_defaults_state"
grep -Fxq 'completed' "$TEST_STATE_ROOT/macos-settings-status"
grep -Fq $'NSGlobalDomain\tAppleShowAllExtensions\tbool\t0' \
  "$TEST_STATE_ROOT/macos-settings/original-values.tsv"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  TEST_DEFAULTS_STATE="$settings_defaults_state" PATH="$settings_bin:$PATH" \
  "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" --restore --yes > "$TEST_ROOT/macos-settings-restore.txt"
grep -Fxq 'false' "$settings_defaults_state"
grep -Fxq 'restored' "$TEST_STATE_ROOT/macos-settings-status"

# macOS 27 stores the Dock tile size as a float. Confirm that it can be
# captured, changed, verified and restored without touching real preferences.
rm -rf "$TEST_STATE_ROOT/macos-settings"
printf 'dock-size\n' > "$TEST_STATE_ROOT/macos-settings-selection"
printf '64.0\n' > "$settings_defaults_state"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  TEST_DEFAULTS_TYPE=float TEST_DEFAULTS_STATE="$settings_defaults_state" PATH="$settings_bin:$PATH" \
  "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" --apply --yes > "$TEST_ROOT/macos-settings-float-apply.txt"
grep -Fxq '44' "$settings_defaults_state"
grep -Fq $'com.apple.dock\ttilesize\tfloat\t64.0' \
  "$TEST_STATE_ROOT/macos-settings/original-values.tsv"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  TEST_DEFAULTS_TYPE=float TEST_DEFAULTS_STATE="$settings_defaults_state" PATH="$settings_bin:$PATH" \
  "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" --restore --yes > "$TEST_ROOT/macos-settings-float-restore.txt"
grep -Fxq '64.0' "$settings_defaults_state"
grep -Fxq 'restored' "$TEST_STATE_ROOT/macos-settings-status"

printf 'fresh value\n' > "$TEST_HOME/.zshrc"
printf 'changed value\n' > "$TEST_HOME/.gitconfig"
printf 'original value\n' > "$TEST_STATE/originals/gitconfig"
mkdir -p "$TEST_HOME/Developer/_sandbox"
printf 'keep me\n' > "$TEST_HOME/Developer/_sandbox/project.txt"
mkdir -p "$TEST_HOME/.empty-parent"
: > "$TEST_STATE/install-manifest.tsv"
{
  printf 'created\t%s\t-\n' "$TEST_HOME/.zshrc"
  printf 'modified\t%s\t%s\n' "$TEST_HOME/.gitconfig" "$TEST_STATE/originals/gitconfig"
  printf 'created-dir\t%s\t-\n' "$TEST_HOME/Developer"
  printf 'created-dir\t%s\t-\n' "$TEST_HOME/Developer/_sandbox"
  printf 'created-dir\t%s\t-\n' "$TEST_HOME/.empty-parent"
} > "$TEST_STATE/path-manifest.tsv"

preview_output="$TEST_ROOT/cleanup-preview.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/../src/operations/rollback-recorded-setup.sh" > "$preview_output"
grep -Fq 'Preview only.' "$preview_output"
grep -Fq "$TEST_HOME/.zshrc" "$preview_output"
[[ -f "$TEST_HOME/.zshrc" ]]

HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/../src/operations/rollback-recorded-setup.sh" --execute --yes \
  --archive-root "$TEST_ROOT/recovery" >/dev/null 2>&1

[[ ! -e "$TEST_HOME/.zshrc" ]]
grep -Fqx 'original value' "$TEST_HOME/.gitconfig"
[[ -f "$TEST_HOME/Developer/_sandbox/project.txt" ]]
[[ ! -d "$TEST_HOME/.empty-parent" ]]
recovery_dirs=("$TEST_ROOT"/recovery/Day-One-Mac-Recovery-*)
[[ -f "${recovery_dirs[0]}/cleanup.log" ]]
[[ -f "${recovery_dirs[0]}/manual-follow-up.md" ]]
[[ -f "${recovery_dirs[0]}/current/.zshrc" ]]
[[ -f "${recovery_dirs[0]}/current/.gitconfig" ]]

printf 'PASS: scalar preference apply/restore and recorded rollback preserve originals and recovery\n'
