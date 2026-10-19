#!/usr/bin/env bash
# Validate the self-contained second-brain project and an optional installed vault.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_PATH=""
THREE_VAULT_ROOT=""
FAILURES=0

usage() {
  printf '%s\n' \
    'Usage: ./scripts/validate.sh [--vault ABSOLUTE_PATH] [--three-vault-root ABSOLUTE_PATH]' \
    '' \
    'Without --vault, validates only this source project.' \
    'With --vault, also checks one installed vault.' \
    'With --three-vault-root, checks the three installed physical vaults.'
}

pass() { printf '  ✓ %s\n' "$*"; }
fail() { printf '  ✗ %s\n' "$*" >&2; FAILURES=$((FAILURES + 1)); }

# Link and wikilink checks below rely on ripgrep. Without it they would scan
# nothing and still report a pass, so stop rather than validate nothing.
if ! command -v rg >/dev/null 2>&1; then
  fail 'ripgrep (rg) is required by this validator but was not found on PATH.'
  printf 'Install it with '\''brew install ripgrep'\'', then rerun this validator.\n' >&2
  exit 1
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --vault)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      VAULT_PATH="$2"
      shift 2
      ;;
    --three-vault-root)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      THREE_VAULT_ROOT="$2"
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

printf '\nSecond Brain — Day One Mac validation\n'
printf '───────────────────────────────────\n'

required_files=(
  README.md
  GUIDE-1-OBSIDIAN-RAYCAST.md
  GUIDE-2-OBSIDIAN-CLAUDE-CODE.md
  GUIDE-3-OBSIDIAN-CODEX.md
  DYNAMIC-LAYOUT-MANAGER.md
  THREE-VAULT-ARCHITECTURE.md
  DASHBOARD.md
  OPERATING-SYSTEM.md
  ALTERNATIVE-STACKS.md
  CHECKLIST.md
  'assets/vault/CLAUDE.md'
  'assets/vault/AGENTS.md'
  'assets/vault/01 Dashboards/Second Brain HQ.md'
  'assets/vault/01 Dashboards/Development.base'
  'assets/vault/01 Dashboards/Software Content.base'
  'assets/vault/01 Dashboards/Tech Content.base'
  'assets/vault/01 Dashboards/All Knowledge.base'
  'assets/vault/99 Templates/Capture.md'
  'assets/vault/99 Templates/Development Note.md'
  'assets/vault/99 Templates/Project.md'
  'assets/vault/99 Templates/Software Content.md'
  'assets/vault/99 Templates/Tech Content.md'
  'assets/vault/99 Templates/Source.md'
  'assets/vault/99 Templates/Weekly Review.md'
  'assets/raycast/search-second-brain.sh'
  'assets/raycast/capture-second-brain.sh'
  'assets/raycast/open-second-brain-dashboard.sh'
  'assets/claude/second-brain-claude.sh'
  'assets/codex/second-brain-codex.sh'
  'assets/three-vaults/common/AGENTS.md'
  'assets/three-vaults/common/CLAUDE.md'
  'assets/three-vaults/development/01 Dashboard/Knowledge.base'
  'assets/three-vaults/software-content/01 Dashboard/Knowledge.base'
  'assets/three-vaults/tech-content/01 Dashboard/Knowledge.base'
  'assets/three-vaults/raycast/open-knowledge-vault.sh'
  'assets/three-vaults/raycast/search-knowledge-vault.sh'
  'assets/three-vaults/raycast/capture-knowledge-vault.sh'
  'assets/three-vaults/codex/second-brain-codex-three.sh'
  'assets/three-vaults/claude/second-brain-claude-three.sh'
  'assets/manager/codex/second-brain-codex.sh'
  'assets/manager/claude/second-brain-claude.sh'
  'assets/manager/raycast/open-knowledge-vault.sh'
  'assets/manager/raycast/search-knowledge-vault.sh'
  'assets/manager/raycast/capture-knowledge-vault.sh'
  'assets/manager/report/second-brain-report.sh'
  'scripts/second-brain-manager.sh'
  'scripts/setup-second-brain.sh'
  'scripts/setup-multi-vaults.sh'
  'scripts/setup-three-vaults.sh'
  'scripts/vault-health-report.sh'
  'scripts/three-vault-health-report.sh'
  'scripts/validate.sh'
  'scripts/tests/test-second-brain.sh'
  'scripts/tests/test-three-vaults.sh'
  'scripts/tests/test-second-brain-manager.sh'
)

missing=0
for relative in "${required_files[@]}"; do
  if [[ ! -s "$PROJECT_DIR/$relative" ]]; then
    fail "missing or empty: $relative"
    missing=1
  fi
done
[[ "$missing" == 0 ]] && pass 'all guides, starter files, and scripts are present'

syntax_failed=0
while IFS= read -r -d '' script; do
  if ! /bin/bash -n "$script"; then
    fail "shell syntax failed: ${script#"$PROJECT_DIR"/}"
    syntax_failed=1
  fi
done < <(find "$PROJECT_DIR/assets" "$PROJECT_DIR/scripts" -type f -name '*.sh' -print0)
[[ "$syntax_failed" == 0 ]] && pass 'all shell files pass bash -n'

executable_failed=0
for relative in \
  scripts/setup-second-brain.sh \
  scripts/setup-multi-vaults.sh \
  scripts/setup-three-vaults.sh \
  scripts/second-brain-manager.sh \
  scripts/vault-health-report.sh \
  scripts/three-vault-health-report.sh \
  scripts/validate.sh \
  scripts/tests/test-second-brain.sh \
  scripts/tests/test-three-vaults.sh \
  scripts/tests/test-second-brain-manager.sh \
  assets/raycast/search-second-brain.sh \
  assets/raycast/capture-second-brain.sh \
  assets/raycast/open-second-brain-dashboard.sh \
  assets/claude/second-brain-claude.sh; do
  if [[ ! -x "$PROJECT_DIR/$relative" ]]; then
    fail "not executable: $relative"
    executable_failed=1
  fi
done
for relative in \
  assets/codex/second-brain-codex.sh \
  assets/three-vaults/raycast/open-knowledge-vault.sh \
  assets/three-vaults/raycast/search-knowledge-vault.sh \
  assets/three-vaults/raycast/capture-knowledge-vault.sh \
  assets/three-vaults/codex/second-brain-codex-three.sh \
  assets/three-vaults/claude/second-brain-claude-three.sh; do
  if [[ ! -x "$PROJECT_DIR/$relative" ]]; then
    fail "not executable: $relative"
    executable_failed=1
  fi
done
while IFS= read -r -d '' relative_path; do
  relative="${relative_path#"$PROJECT_DIR"/}"
  if [[ ! -x "$relative_path" ]]; then
    fail "not executable: $relative"
    executable_failed=1
  fi
done < <(find "$PROJECT_DIR/assets/manager" -type f -name '*.sh' -print0)
[[ "$executable_failed" == 0 ]] && pass 'all runnable files are executable'

link_failed=0
while IFS= read -r link_record; do
  source_file="${link_record%%:*}"
  markdown_match="${link_record#*:}"
  link_target="$(printf '%s\n' "$markdown_match" | sed -E 's/^\]\(([^)#]+\.md).*/\1/')"
  case "$link_target" in http://*|https://*|mailto:*) continue ;; esac
  if [[ "$link_target" == /* ]]; then
    link_path="$link_target"
  else
    link_path="$(dirname "$source_file")/$link_target"
  fi
  if [[ ! -f "$link_path" ]]; then
    fail "broken Markdown link in ${source_file#"$PROJECT_DIR"/}: $link_target"
    link_failed=1
  fi
done < <(rg --no-heading -o '\]\([^)]*\.md(#[^)]*)?\)' "$PROJECT_DIR" --glob '*.md' || true)
[[ "$link_failed" == 0 ]] && pass 'all local Markdown navigation targets exist'

wikilink_failed=0
while IFS= read -r link_record; do
  source_file="${link_record%%:*}"
  wikilink="${link_record#*:}"
  wikilink="${wikilink#*\[\[}"
  wikilink="${wikilink%\]\]*}"
  wikilink="${wikilink%%|*}"
  wikilink="${wikilink%%#*}"
  [[ -n "$wikilink" ]] || continue
  case "$wikilink" in
    *.base) wikilink_path="$PROJECT_DIR/assets/vault/$wikilink" ;;
    *.md) wikilink_path="$PROJECT_DIR/assets/vault/$wikilink" ;;
    *) wikilink_path="$PROJECT_DIR/assets/vault/$wikilink.md" ;;
  esac
  if [[ ! -f "$wikilink_path" ]]; then
    fail "broken starter-vault wikilink in ${source_file#"$PROJECT_DIR"/}: $wikilink"
    wikilink_failed=1
  fi
done < <(rg --no-heading -o '\[\[[^]]+\]\]' "$PROJECT_DIR/assets/vault" --glob '*.md' || true)
[[ "$wikilink_failed" == 0 ]] && pass 'all starter-vault wikilinks resolve'

base_failed=0
while IFS= read -r -d '' base; do
  if ! grep -Fq 'views:' "$base" || ! grep -Fq 'filters:' "$base"; then
    fail "Base is missing filters or views: ${base#"$PROJECT_DIR"/}"
    base_failed=1
  fi
done < <(find "$PROJECT_DIR/assets/vault" "$PROJECT_DIR/assets/three-vaults" -type f -name '*.base' -print0)
[[ "$base_failed" == 0 ]] && pass 'all Obsidian Base files contain filters and views'

if grep -Fq 'Guide release 2.3.0.0' "$PROJECT_DIR/README.md" \
   && grep -Fq 'Raycast 2.3.x' "$PROJECT_DIR/GUIDE-1-OBSIDIAN-RAYCAST.md" \
   && grep -Fq 'No Obsidian AI' "$PROJECT_DIR/GUIDE-2-OBSIDIAN-CLAUDE-CODE.md" \
   && grep -Fq 'Obsidian AI plugin' "$PROJECT_DIR/GUIDE-3-OBSIDIAN-CODEX.md" \
   && grep -Fq 'ai_allowed' "$PROJECT_DIR/assets/vault/CLAUDE.md" \
   && grep -Fq 'ai_allowed' "$PROJECT_DIR/assets/vault/AGENTS.md" \
   && grep -Fq 'second-brain-manager.sh --guided' "$PROJECT_DIR/README.md" \
   && grep -Fq -- '--tools raycast' "$PROJECT_DIR/README.md" \
   && grep -Fq -- '--tools|--stack' "$SCRIPT_DIR/setup-second-brain.sh" \
   && grep -Fq 'Capture Knowledge Item' "$PROJECT_DIR/GUIDE-1-OBSIDIAN-RAYCAST.md" \
   && grep -Fq 'Open Knowledge Vault' "$PROJECT_DIR/GUIDE-1-OBSIDIAN-RAYCAST.md" \
   && ! grep -Fq 'all four starter Bases' "$PROJECT_DIR/CHECKLIST.md" \
   && grep -Fq 'updates only files bearing its ownership marker' "$PROJECT_DIR/README.md" \
   && grep -Fq 'unrecognised existing note' "$PROJECT_DIR/README.md" \
   && grep -Fq 'Sync alone is not treated as backup' "$PROJECT_DIR/README.md"; then
  pass 'version, integration, privacy, idempotency, and backup guidance is explicit'
else
  fail 'a core guide contract is missing'
fi

for template in "$PROJECT_DIR"/assets/vault/'99 Templates'/*.md; do
  for property in domain type status created sensitivity ai_allowed topics; do
    if ! grep -Eq "^${property}:" "$template"; then
      fail "template missing $property: ${template#"$PROJECT_DIR"/}"
    fi
  done
done

if "$SCRIPT_DIR/tests/test-second-brain.sh" >/dev/null; then
  pass 'preview, apply, idempotency, reporting, and path-safety fixture passes'
else
  fail 'second-brain regression fixture failed'
fi

if "$SCRIPT_DIR/tests/test-three-vaults.sh" >/dev/null; then
  pass 'multi-domain preview, apply, idempotency, reporting, and path-safety fixture passes'
else
  fail 'multi-domain regression fixture failed'
fi

if "$SCRIPT_DIR/tests/test-second-brain-manager.sh" >/dev/null; then
  pass 'dynamic manifest, custom domains, namespace migration, retained removals, migration blocking, and refresh fixture passes'
else
  fail 'dynamic Second Brain manager regression fixture failed'
fi

if [[ -n "$VAULT_PATH" ]]; then
  case "$VAULT_PATH" in /*) ;; *) fail '--vault is not absolute' ;; esac
  vault_missing=0
  for relative in \
    '00 Inbox' \
    '01 Dashboards' \
    '10 Software Development' \
    '20 Software Content' \
    '30 Tech Content' \
    '40 Sources' \
    '80 Attachments' \
    '90 System' \
    '99 Templates'; do
    if [[ ! -d "$VAULT_PATH/$relative" ]]; then
      fail "installed vault folder missing: $relative"
      vault_missing=1
    fi
  done
  for relative in '99 Templates/Capture.md'; do
    if [[ ! -s "$VAULT_PATH/$relative" ]]; then
      fail "installed vault starter missing: $relative"
      vault_missing=1
    fi
  done
  if [[ ! -s "$VAULT_PATH/01 Dashboards/Second Brain HQ.md" \
        && ! -s "$VAULT_PATH/01 Dashboards/Vault Dashboard.md" ]]; then
    fail 'installed vault dashboard is missing'
    vault_missing=1
  fi
  [[ "$vault_missing" == 0 ]] && pass 'installed vault contains the required common structure'
fi

if [[ -n "$THREE_VAULT_ROOT" ]]; then
  case "$THREE_VAULT_ROOT" in /*) ;; *) fail '--three-vault-root is not absolute' ;; esac
  three_missing=0
  for vault in 'Software Development' 'Software Content' 'Tech Content'; do
    for relative in '00 Inbox' '01 Dashboard' '80 Attachments' '90 System' '99 Templates'; do
      if [[ ! -d "$THREE_VAULT_ROOT/$vault/$relative" ]]; then
        fail "installed three-vault folder missing: $vault/$relative"
        three_missing=1
      fi
    done
    for relative in '00 Inbox/Inbox.md' '90 System/Knowledge System.md' '99 Templates/Capture.md'; do
      if [[ ! -s "$THREE_VAULT_ROOT/$vault/$relative" ]]; then
        fail "installed three-vault starter missing: $vault/$relative"
        three_missing=1
      fi
    done
    case "$vault" in
      'Software Development') base_name=development.base ;;
      'Software Content') base_name=software-content.base ;;
      'Tech Content') base_name=tech-content.base ;;
    esac
    if [[ ! -s "$THREE_VAULT_ROOT/$vault/01 Dashboard/Knowledge.base" \
          && ! -s "$THREE_VAULT_ROOT/$vault/01 Dashboard/$base_name" ]]; then
      fail "installed three-vault Base missing: $vault"
      three_missing=1
    fi
  done
  [[ "$three_missing" == 0 ]] && pass 'installed three-vault layout contains all common folders and starters'
fi

if [[ "$FAILURES" -gt 0 ]]; then
  printf '\nFAIL: %s validation check(s) need attention.\n' "$FAILURES" >&2
  exit 1
fi

printf '\nPASS: Second Brain — Day One Mac v2.3.0.0 is internally consistent.\n'
