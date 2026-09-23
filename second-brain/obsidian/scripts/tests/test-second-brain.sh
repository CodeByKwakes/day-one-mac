#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/second-brain-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="$TEST_ROOT/home"
TEST_VAULT="$TEST_HOME/Vaults/Second Brain"
mkdir -p "$TEST_HOME"

"$SCRIPT_DIR/setup-second-brain.sh" --help | grep -Fq -- '--app-install-policy'
"$SCRIPT_DIR/second-brain-manager.sh" --help | grep -Fq -- '--app-install-policy MODE'

preview="$TEST_ROOT/preview.txt"
HOME="$TEST_HOME" "$SCRIPT_DIR/setup-second-brain.sh" \
  --tools both --vault "$TEST_VAULT" > "$preview"
grep -Fq 'Preview only.' "$preview"
[[ ! -e "$TEST_VAULT" ]]

HOME="$TEST_HOME" "$SCRIPT_DIR/setup-second-brain.sh" \
  --tools both --vault "$TEST_VAULT" --apply --yes > "$TEST_ROOT/apply.txt"

[[ -f "$TEST_VAULT/01 Dashboards/Vault Dashboard.md" ]]
[[ -f "$TEST_VAULT/01 Dashboards/development.base" ]]
[[ -f "$TEST_VAULT/99 Templates/Software Development.md" ]]
[[ -f "$TEST_VAULT/CLAUDE.md" ]]
[[ -x "$TEST_HOME/.local/bin/second-brain-claude" ]]
[[ -x "$TEST_HOME/.local/bin/second-brain-report" ]]
[[ -x "$TEST_HOME/.local/share/second-brain/raycast/search-knowledge-vault.sh" ]]
grep -Fq $'vault\tsecond-brain\tSecond Brain' "$TEST_HOME/.config/second-brain/layout.tsv"

printf 'CUSTOM-MARKER\n' > "$TEST_VAULT/10 Software Development/Learning/User note.md"
HOME="$TEST_HOME" "$SCRIPT_DIR/setup-second-brain.sh" \
  --tools both --vault "$TEST_VAULT" --apply --yes > "$TEST_ROOT/reapply.txt"
grep -Fq 'CUSTOM-MARKER' "$TEST_VAULT/10 Software Development/Learning/User note.md"

HOME="$TEST_HOME" "$SCRIPT_DIR/vault-health-report.sh" \
  --vault "$TEST_VAULT" > "$TEST_ROOT/report.md"
grep -Fq '# Vault health' "$TEST_ROOT/report.md"
grep -Fq '| Software development Markdown files |' "$TEST_ROOT/report.md"
[[ ! -e "$TEST_VAULT/90 System/Reports/$(date '+%Y-%m-%d')-vault-health.md" ]]

HOME="$TEST_HOME" "$SCRIPT_DIR/vault-health-report.sh" \
  --vault "$TEST_VAULT" --write > "$TEST_ROOT/report-write.txt"
find "$TEST_VAULT/90 System/Reports" -type f -name '*-vault-health.md' | grep -q .

mkdir -p "$TEST_HOME/Developer"
if HOME="$TEST_HOME" "$SCRIPT_DIR/setup-second-brain.sh" \
  --tools raycast --vault "$TEST_HOME/Developer/Brain" --apply --yes \
  >/dev/null 2>&1; then
  printf 'FAIL: setup accepted a vault inside ~/Developer\n' >&2
  exit 1
fi

CODEX_HOME="$TEST_ROOT/codex-home"
CODEX_VAULT="$CODEX_HOME/Vaults/Codex Brain"
mkdir -p "$CODEX_HOME"
HOME="$CODEX_HOME" "$SCRIPT_DIR/setup-second-brain.sh" \
  --tools codex --vault "$CODEX_VAULT" --apply --yes > "$TEST_ROOT/codex.txt"
[[ -f "$CODEX_VAULT/AGENTS.md" ]]
[[ ! -e "$CODEX_VAULT/CLAUDE.md" ]]
[[ -x "$CODEX_HOME/.local/bin/second-brain-codex" ]]
[[ ! -e "$CODEX_HOME/.local/bin/second-brain-claude" ]]

printf 'PASS: second-brain setup fixture\n'
