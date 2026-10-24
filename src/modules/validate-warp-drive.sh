#!/usr/bin/env bash
# Validate the self-contained Day One Mac Warp Drive import.
# Read-only and compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../src/core/terminal-ui.sh"
BUNDLE="$PROJECT_DIR/integrations/warp/Day One Mac"
NOTEBOOK="$BUNDLE/00 Day One Mac Command Catalogue.md"
IMPORT_GUIDE="$PROJECT_DIR/docs/shared/tools/14-warp-drive.md"
FAILURES=0

pass() { ui_success "$@"; }
fail() { ui_error "$@"; FAILURES=$((FAILURES + 1)); }

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-mac-warp.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

ui_title '🛸' 'Day One Mac Warp Drive validation'

if [[ -d "$BUNDLE" && -s "$NOTEBOOK" && -s "$IMPORT_GUIDE" ]]; then
  pass "import directory, Notebook, and optional setup guide exist"
else
  fail "import directory, Notebook, or optional setup guide is missing"
fi

find "$BUNDLE" -type f -name '*.yaml' -print | LC_ALL=C sort > "$TMP_ROOT/yaml-files"
WORKFLOW_COUNT="$(wc -l < "$TMP_ROOT/yaml-files" | tr -d ' ')"
if [[ "$WORKFLOW_COUNT" == 63 ]]; then
  pass "bundle contains 63 workflows"
else
  fail "bundle must contain exactly 63 workflows (found $WORKFLOW_COUNT)"
fi

FOLDER_COUNT=0
for directory in "$BUNDLE"/*/; do
  [[ -d "$directory" ]] && FOLDER_COUNT=$((FOLDER_COUNT + 1))
done
if [[ "$FOLDER_COUNT" == 7 ]]; then
  pass "bundle contains seven workflow folders"
else
  fail "bundle must contain exactly seven workflow folders (found $FOLDER_COUNT)"
fi

: > "$TMP_ROOT/names"
while IFS= read -r workflow; do
  relative="${workflow#"$PROJECT_DIR"/}"
  NAME_COUNT="$(grep -c '^name: ' "$workflow" || true)"
  COMMAND_COUNT="$(grep -c '^command: ' "$workflow" || true)"
  SHELL_COUNT="$(grep -c '^shells: \["zsh"\]$' "$workflow" || true)"

  if [[ "$NAME_COUNT" != 1 || "$COMMAND_COUNT" != 1 || "$SHELL_COUNT" != 1 ]]; then
    fail "$relative must declare exactly one name, command, and zsh shell"
    continue
  fi

  sed -n 's/^name: //p' "$workflow" >> "$TMP_ROOT/names"
  COMMAND_LINE="$(sed -n 's/^command: //p' "$workflow")"

  if ! grep -Fq '"day-one-mac"' "$workflow"; then
    fail "$relative is missing the day-one-mac search tag"
  fi

  if grep -Eq -- '--execute|brew[[:space:]]+uninstall|rm[[:space:]]+-[A-Za-z]*r[A-Za-z]*f|security[[:space:]]+delete|docker[[:space:]]+(system|volume)[[:space:]]+prune' <<<"$COMMAND_LINE"; then
    fail "$relative exposes a destructive command instead of a preview"
  fi

  if grep -Eqi 'op://|api[_ -]?key|github_pat_|ghp_|BEGIN .*PRIVATE KEY|(^|[^a-z])pat([^a-z]|$)|token|secret' <<<"$COMMAND_LINE"; then
    fail "$relative embeds or requests secret material"
  fi

  grep -oE '\{\{[A-Za-z][A-Za-z0-9_]*\}\}' "$workflow" 2>/dev/null \
    | tr -d '{}' | LC_ALL=C sort -u > "$TMP_ROOT/placeholders" || true
  sed -n 's/^  - name: \([A-Za-z][A-Za-z0-9_]*\)$/\1/p' "$workflow" \
    | LC_ALL=C sort -u > "$TMP_ROOT/arguments"
  if ! cmp -s "$TMP_ROOT/placeholders" "$TMP_ROOT/arguments"; then
    fail "$relative has unmatched placeholders and argument declarations"
  fi
done < "$TMP_ROOT/yaml-files"

if [[ -s "$TMP_ROOT/names" ]] \
   && ! LC_ALL=C sort "$TMP_ROOT/names" | uniq -d | grep -q .; then
  pass "workflow display names are unique"
else
  fail "workflow display names are empty or duplicated"
fi

if ! grep -Eq '^name: "ZAM([[:space:]·:_-]|\")' "$BUNDLE"/*/*.yaml; then
  pass "workflow display names do not use the retired ZAM prefix"
else
  fail "workflow display names must not use the ZAM prefix"
fi

EXPECTED_COMMANDS_OK=1
assert_command() {
  local relative="$1" expected="$2"
  if [[ ! -f "$BUNDLE/$relative" ]] \
     || [[ "$(sed -n 's/^command: //p' "$BUNDLE/$relative")" != "$expected" ]]; then
    fail "workflow is missing or has the wrong command: $relative"
    EXPECTED_COMMANDS_OK=0
  fi
}

assert_command '01 Setup and Audit/02-validate.yaml' '"day-one-mac validate"'
assert_command '01 Setup and Audit/10-advanced-status.yaml' '"day-one-mac advanced --status"'
assert_command '01 Setup and Audit/13-advanced-audit.yaml' '"day-one-mac advanced-audit"'
assert_command '03 Repositories and Hosting/01-ghq-root.yaml' '"ghq root"'
assert_command '04 Dotfiles/02-chezmoi-diff.yaml' '"chezmoi diff"'
assert_command '05 Toolchains/06-pnpm-install-frozen.yaml' '"pnpm install --frozen-lockfile"'
assert_command '06 Homebrew/05-cleanup-preview.yaml' '"brew cleanup --dry-run"'
assert_command '07 AI Workspaces/03-list-tasks.yaml' "'day-one-mac workspace list'"
assert_command '07 AI Workspaces/04-open-vscode-here.yaml' "'day-one-mac workspace open-vscode \"\$PWD\"'"
assert_command '07 AI Workspaces/05-start-codex-here.yaml' "'day-one-mac workspace start-codex \"\$PWD\"'"
assert_command '07 AI Workspaces/06-start-claude-here.yaml' "'day-one-mac workspace start-claude \"\$PWD\"'"
assert_command '07 AI Workspaces/07-start-copilot-cli-here.yaml' "'day-one-mac workspace status \"\$PWD\" >/dev/null && copilot -C \"\$PWD\"'"
if [[ "$EXPECTED_COMMANDS_OK" == 1 ]]; then
  pass "core setup, safety, ghq, chezmoi, toolchain, and Homebrew workflows match policy"
fi

if grep -Eq 'day-one-mac (setup|clean|remove|finalize|--status|--reset|optional --guided|advanced --guided)([ "]|$)' "$BUNDLE"/*/*.yaml; then
  fail "workflow still invokes a retired setup action"
else
  pass "workflows exclude retired setup and broad cleanup actions"
fi

if [[ "$FAILURES" -gt 0 ]]; then
  ui_error "$FAILURES Warp Drive validation check(s) need attention."
  exit 1
fi

ui_success 'The Day One Mac Warp Drive bundle is internally consistent.'
