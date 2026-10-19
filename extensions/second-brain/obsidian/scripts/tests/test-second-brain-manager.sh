#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/second-brain-manager-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="$TEST_ROOT/home"
VAULT="$TEST_HOME/Vaults/Knowledge Hub"
LAYOUT_ONE="$TEST_ROOT/layout-one.tsv"
LAYOUT_TWO="$TEST_ROOT/layout-two.tsv"
LAYOUT_NONE="$TEST_ROOT/layout-none.tsv"
LAYOUT_MOVE="$TEST_ROOT/layout-move.tsv"
LAYOUT_UNSAFE="$TEST_ROOT/layout-unsafe.tsv"
LAYOUT_WORK="$TEST_ROOT/layout-work.tsv"
mkdir -p "$TEST_HOME"

write_layout() {
  target="$1"; engineering_folder="$2"; include_creator="$3"; vault_path="$4"
  tools="${5:-codex,raycast}"; vault_sensitivity="${6:-personal}"
  vault_name="${7:-Knowledge Hub}"
  {
    printf '# test layout\n'
    printf 'meta\tschema\t1\n'
    printf 'meta\tpreset\tcustom\n'
    printf 'meta\treasons\tpolicy-test\n'
    printf 'vault\tknowledge-hub\t%s\t%s\t%s\t%s\t01 Dashboards\n' "$vault_name" "$vault_path" "$vault_sensitivity" "$tools"
    printf 'domain\tengineering\tEngineering\tknowledge-hub\t%s\tdevelopment\t%s\ttrue\tProjects,Learning,Reference\n' "$engineering_folder" "$vault_sensitivity"
    if [[ "$include_creator" == 1 ]]; then
      printf 'domain\tcreator-notes\tCreator Notes\tknowledge-hub\t20 Creator Notes\tcontent\t%s\tfalse\tIdeas,Drafts,Published\n' "$vault_sensitivity"
    fi
  } > "$target"
}

write_layout "$LAYOUT_ONE" '10 Engineering' 1 "$VAULT"
HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --layout "$LAYOUT_ONE" > "$TEST_ROOT/preview.txt"
grep -Fq 'Preview only.' "$TEST_ROOT/preview.txt"
[[ ! -e "$VAULT" ]]

HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --layout "$LAYOUT_ONE" --apply --yes > "$TEST_ROOT/apply.txt"
[[ -f "$VAULT/01 Dashboards/Vault Dashboard.md" ]]
[[ -f "$VAULT/01 Dashboards/engineering.base" ]]
[[ -f "$VAULT/10 Engineering/Engineering.md" ]]
[[ "$(sed -n '1p' "$VAULT/10 Engineering/Engineering.md")" == '---' ]]
[[ "$(sed -n '1p' "$VAULT/99 Templates/Engineering.md")" == '---' ]]
[[ -d "$VAULT/10 Engineering/Projects" ]]
[[ -f "$VAULT/AGENTS.md" ]]
[[ ! -e "$VAULT/CLAUDE.md" ]]
[[ -x "$TEST_HOME/.local/bin/second-brain-codex" ]]
[[ -x "$TEST_HOME/.local/bin/second-brain-report" ]]

HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" --show > "$TEST_ROOT/show.md"
grep -Fq '| Engineering |' "$TEST_ROOT/show.md"
HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" --validate > "$TEST_ROOT/validate.txt"
grep -Fq 'PASS: saved Second Brain layout' "$TEST_ROOT/validate.txt"
HOME="$TEST_HOME" "$TEST_HOME/.local/bin/second-brain-report" --write > "$TEST_ROOT/report-write.txt"
find "$TEST_HOME/.local/state/second-brain/reports" -type f -name '*-health.md' | grep -q .

printf 'Retain me.\n' > "$VAULT/20 Creator Notes/Drafts/User draft.md"
write_layout "$LAYOUT_TWO" '10 Engineering' 0 "$VAULT"
HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --layout "$LAYOUT_TWO" --apply --yes > "$TEST_ROOT/reconfigure.txt"
[[ -f "$VAULT/20 Creator Notes/Drafts/User draft.md" ]]
grep -R -Fq 'Creator Notes' "$TEST_HOME/.local/state/second-brain/reports"

write_layout "$LAYOUT_NONE" '10 Engineering' 0 "$VAULT" none
HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --layout "$LAYOUT_NONE" --apply --yes > "$TEST_ROOT/disable-tools.txt"
[[ ! -e "$TEST_HOME/.local/bin/second-brain-codex" ]]
[[ ! -e "$TEST_HOME/.local/share/second-brain/raycast/open-knowledge-vault.sh" ]]
find "$TEST_HOME/.local/state/second-brain/backups" \
  -path '*/retired/.local/bin/second-brain-codex' | grep -q .

write_layout "$LAYOUT_MOVE" '30 Engineering Moved' 0 "$VAULT"
if HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --layout "$LAYOUT_MOVE" --apply --yes > "$TEST_ROOT/move.txt" 2>&1; then
  printf 'FAIL: manager allowed an implicit domain move\n' >&2
  exit 1
fi
grep -Fq $'domain\tengineering\tEngineering\tknowledge-hub\t10 Engineering' \
  "$TEST_HOME/.config/second-brain/layout.tsv"

write_layout "$LAYOUT_UNSAFE" '10 Engineering' 0 "$TEST_HOME/Developer/Knowledge Hub"
if HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --layout "$LAYOUT_UNSAFE" > "$TEST_ROOT/unsafe.txt" 2>&1; then
  printf 'FAIL: manager accepted a vault inside ~/Developer\n' >&2
  exit 1
fi

HOME="$TEST_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --refresh-integrations > "$TEST_ROOT/refresh.txt"
grep -Fq 'Preview only.' "$TEST_ROOT/refresh.txt"

WORK_HOME="$TEST_ROOT/work-home"
WORK_VAULT="$WORK_HOME/Vaults/Work Knowledge"
mkdir -p "$WORK_HOME"
write_layout "$LAYOUT_WORK" '10 Engineering' 0 "$WORK_VAULT" none work-confidential 'Work Knowledge'
HOME="$WORK_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --layout "$LAYOUT_WORK" --apply --yes > "$TEST_ROOT/work-apply.txt"
grep -Fq 'sensitivity: work-confidential' "$WORK_VAULT/00 Inbox/Inbox.md"
grep -Fq 'sensitivity: work-confidential' "$WORK_VAULT/99 Templates/Source.md"
grep -Fq 'sensitivity: work-confidential' "$WORK_VAULT/90 System/Knowledge System.md"
grep -Fq 'ai_allowed: false' "$WORK_VAULT/90 System/Knowledge System.md"

LEGACY_HOME="$TEST_ROOT/legacy-home"
LEGACY_VAULT="$LEGACY_HOME/Vaults/Legacy Brain"
LEGACY_LAYOUT="$LEGACY_HOME/.config/fresh-start-second-brain/layout.tsv"
mkdir -p "$(dirname "$LEGACY_LAYOUT")"
write_layout "$LEGACY_LAYOUT" '10 Engineering' 0 "$LEGACY_VAULT" none personal 'Legacy Brain'
HOME="$LEGACY_HOME" "$SCRIPT_DIR/second-brain-manager.sh" --show > "$TEST_ROOT/legacy-show.md"
HOME="$LEGACY_HOME" "$SCRIPT_DIR/second-brain-manager.sh" \
  --layout "$LEGACY_LAYOUT" --apply --yes > "$TEST_ROOT/legacy-migrate.txt"
[[ -f "$LEGACY_HOME/.config/second-brain/layout.tsv" ]]
[[ ! -e "$LEGACY_LAYOUT" ]]
find "$LEGACY_HOME/.local/state/second-brain/backups" \
  -path '*/retired/.config/fresh-start-second-brain/layout.tsv' | grep -q .
grep -Fq 'migrated the saved layout namespace' "$TEST_ROOT/legacy-migrate.txt"

printf 'PASS: dynamic Second Brain manager fixture\n'
