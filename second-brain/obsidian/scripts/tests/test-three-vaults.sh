#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/three-vault-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="$TEST_ROOT/home"
VAULT_ROOT="$TEST_HOME/Vaults"
mkdir -p "$TEST_HOME"

HOME="$TEST_HOME" "$SCRIPT_DIR/setup-multi-vaults.sh" \
  --tools all --root "$VAULT_ROOT" > "$TEST_ROOT/preview.txt"
grep -Fq 'Preview only.' "$TEST_ROOT/preview.txt"
[[ ! -e "$VAULT_ROOT/Software Development" ]]

HOME="$TEST_HOME" "$SCRIPT_DIR/setup-multi-vaults.sh" \
  --tools all --root "$VAULT_ROOT" --apply --yes > "$TEST_ROOT/apply.txt"

for vault in 'Software Development' 'Software Content' 'Tech Content'; do
  [[ -f "$VAULT_ROOT/$vault/00 Inbox/Inbox.md" ]]
  [[ -f "$VAULT_ROOT/$vault/01 Dashboard/Vault Dashboard.md" ]]
  [[ -f "$VAULT_ROOT/$vault/90 System/Knowledge System.md" ]]
  [[ -f "$VAULT_ROOT/$vault/99 Templates/Capture.md" ]]
  [[ -f "$VAULT_ROOT/$vault/AGENTS.md" ]]
  [[ -f "$VAULT_ROOT/$vault/CLAUDE.md" ]]
done
[[ -f "$VAULT_ROOT/Software Development/01 Dashboard/development.base" ]]
[[ -f "$VAULT_ROOT/Software Content/01 Dashboard/software-content.base" ]]
[[ -f "$VAULT_ROOT/Tech Content/01 Dashboard/tech-content.base" ]]

[[ -x "$TEST_HOME/.local/bin/second-brain-codex" ]]
[[ -x "$TEST_HOME/.local/bin/second-brain-claude" ]]
[[ -x "$TEST_HOME/.local/bin/second-brain-report" ]]
[[ -x "$TEST_HOME/.local/share/second-brain/raycast/search-knowledge-vault.sh" ]]
grep -Fq $'vault\tdevelopment\tSoftware Development' "$TEST_HOME/.config/second-brain/layout.tsv"

printf 'CUSTOM-MARKER\n' > "$VAULT_ROOT/Tech Content/Research/User note.md"
HOME="$TEST_HOME" "$SCRIPT_DIR/setup-multi-vaults.sh" \
  --tools all --root "$VAULT_ROOT" --apply --yes > "$TEST_ROOT/reapply.txt"
grep -Fq 'CUSTOM-MARKER' "$VAULT_ROOT/Tech Content/Research/User note.md"

HOME="$TEST_HOME" "$TEST_HOME/.local/bin/second-brain-report" > "$TEST_ROOT/report.md"
grep -Fq '# Second Brain health' "$TEST_ROOT/report.md"
grep -Fq '| Software Development |' "$TEST_ROOT/report.md"
grep -Fq '| Software Content |' "$TEST_ROOT/report.md"
grep -Fq '| Tech Content |' "$TEST_ROOT/report.md"

mkdir -p "$TEST_HOME/Developer"
if HOME="$TEST_HOME" "$SCRIPT_DIR/setup-multi-vaults.sh" \
  --tools none --root "$TEST_HOME/Developer/Knowledge" --apply --yes \
  >/dev/null 2>&1; then
  printf 'FAIL: setup accepted vaults inside ~/Developer\n' >&2
  exit 1
fi

HOME="$TEST_HOME" "$SCRIPT_DIR/setup-three-vaults.sh" \
  --tools none --root "$VAULT_ROOT" > "$TEST_ROOT/compatibility.txt"
grep -Fq 'multi-domain' "$TEST_ROOT/compatibility.txt"

printf 'PASS: multi-domain vault setup fixture\n'
