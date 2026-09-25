#!/usr/bin/env bash
# Generate a private, read-only audit of the required and optional Day One setup.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
STATE_ROOT="$(day_one_state_root)"
REPORT="${DAY_ONE_MAC_AUDIT_REPORT:-${FRESH_START_AUDIT_REPORT:-$STATE_ROOT/advanced-audit.md}}"
REPO_REPORT="${DAY_ONE_MAC_REPO_REPORT:-${FRESH_START_REPO_REPORT:-$STATE_ROOT/repository-audit.tsv}}"
CHECK_ONLY=0
PRINT_REPORT=0
FAILURES=0
REVIEWS=0

usage() {
  cat <<'EOF'
Usage: ./advanced-audit.sh [options]

  --check        exit non-zero when a required gate fails
  --stdout       print the completed report after writing it
  --report PATH  write the Markdown report to this path
  -h, --help     show this help

The audit is read-only apart from its private Markdown and repository-summary
reports. It never prints authentication tokens or AI client credential files.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
err() { ui_error "$@"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --stdout) PRINT_REPORT=1 ;;
    --report) shift; [[ $# -gt 0 ]] || { err "--report needs a path"; exit 2; }; REPORT="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

mkdir -p "$STATE_ROOT" "$(dirname "$REPORT")" "$(dirname "$REPO_REPORT")"
chmod 700 "$STATE_ROOT"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-mac-audit.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
ui_title '🩺' 'Advanced environment report'
info 'Read-only checks; installed tools and settings are not changed.'

escape_table() {
  printf '%s' "$1" | tr '\n' ' ' | sed 's/|/\\|/g'
}

row() {
  printf '| %s | %s | %s |\n' "$(escape_table "$1")" "$2" "$(escape_table "$3")" >> "$REPORT"
}

pass_gate() { row "$1" PASS "$2"; }
review_gate() { row "$1" REVIEW "$2"; REVIEWS=$((REVIEWS + 1)); }
fail_gate() { row "$1" FAIL "$2"; FAILURES=$((FAILURES + 1)); }

check_command() {
  local label="$1" detail="$2"
  shift 2
  if "$@" > "$TMP_ROOT/check.out" 2>&1; then pass_gate "$label" "$detail"
  else fail_gate "$label" "$detail"; fi
}

TRACK="$(sed -n '1p' "$STATE_ROOT/track" 2>/dev/null || true)"
STACK="$(sed -n '1p' "$STATE_ROOT/stack" 2>/dev/null || true)"

{
  printf '# Day One Mac advanced audit\n\n'
  printf -- '- Generated: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf -- '- Track: `%s`\n' "${TRACK:-not recorded}"
  printf -- '- Stack: `%s`\n' "${STACK:-not recorded}"
  printf -- '- Report: `%s`\n\n' "$REPORT"
  printf '| Gate | Result | Detail |\n'
  printf '|---|---|---|\n'
} > "$REPORT"

case "$TRACK" in 1|2|3) pass_gate "Track state" "Track $TRACK is recorded" ;; *) fail_gate "Track state" "Choose Track 1, 2, or 3 in required Phase 1" ;; esac
case "$STACK" in node|python|both) pass_gate "Stack state" "$STACK is recorded" ;; *) fail_gate "Stack state" "Choose node, python, or both in required Phase 1" ;; esac

for command_name in brew git ghq chezmoi starship day-one-mac code; do
  if command -v "$command_name" >/dev/null 2>&1; then
    pass_gate "$command_name command" "Available on PATH"
  else
    fail_gate "$command_name command" "Missing from PATH"
  fi
done

if /usr/bin/fdesetup status 2>/dev/null | grep -q 'FileVault is On'; then
  pass_gate "FileVault status" "On"
else
  fail_gate "FileVault status" "Not confirmed on"
fi

if [[ -f "$HOME/Brewfile" && -x "$(command -v brew 2>/dev/null || true)" ]]; then
  check_command "Brewfile desired state" "No installation or upgrade performed" brew bundle check --file="$HOME/Brewfile" --no-upgrade
  OUTDATED_COUNT="$( (brew outdated --greedy 2>/dev/null || true) | awk 'NF {n++} END {print n+0}')"
  if [[ "$OUTDATED_COUNT" -gt 0 ]]; then review_gate "Homebrew updates" "$OUTDATED_COUNT outdated item(s) need review"
  else pass_gate "Homebrew updates" "No outdated item reported"; fi
else
  fail_gate "Brewfile" "$HOME/Brewfile is missing"
fi

if command -v chezmoi >/dev/null 2>&1; then
  check_command "chezmoi doctor" "Configuration and dependencies" chezmoi doctor
  CHEZMOI_STATUS="$(chezmoi status 2>/dev/null || true)"
  if [[ -n "$CHEZMOI_STATUS" ]]; then review_gate "chezmoi target drift" "Managed targets differ; inspect chezmoi status and diff"
  else pass_gate "chezmoi target drift" "No target difference reported"; fi
fi

printf 'state\tremote\trepository\n' > "$REPO_REPORT"
chmod 600 "$REPO_REPORT"
if command -v ghq >/dev/null 2>&1; then
  GHQ_ROOT="$(ghq root 2>/dev/null | sed -n '1p' || true)"
  if [[ "$GHQ_ROOT" == "$HOME/Developer" ]]; then pass_gate "ghq root" "$GHQ_ROOT"
  else fail_gate "ghq root" "Expected $HOME/Developer; found ${GHQ_ROOT:-none}"; fi

  REPO_COUNT=0
  DIRTY_COUNT=0
  NO_REMOTE_COUNT=0
  AHEAD_COUNT=0
  while IFS= read -r repository; do
    [[ -n "$repository" ]] || continue
    directory="$GHQ_ROOT/$repository"
    git -C "$directory" rev-parse --git-dir >/dev/null 2>&1 || continue
    REPO_COUNT=$((REPO_COUNT + 1))
    state=CLEAN
    [[ -n "$(git -C "$directory" status --porcelain 2>/dev/null || true)" ]] && { state=DIRTY; DIRTY_COUNT=$((DIRTY_COUNT + 1)); }
    remote="$(git -C "$directory" remote get-url origin 2>/dev/null || true)"
    [[ -n "$remote" ]] || { remote=NO-REMOTE; NO_REMOTE_COUNT=$((NO_REMOTE_COUNT + 1)); }
    ahead="$(git -C "$directory" rev-list --count '@{upstream}..HEAD' 2>/dev/null || true)"
    if [[ "$ahead" =~ ^[0-9]+$ && "$ahead" -gt 0 ]]; then state="${state}+AHEAD($ahead)"; AHEAD_COUNT=$((AHEAD_COUNT + 1)); fi
    printf '%s\t%s\t%s\n' "$state" "$remote" "$repository" >> "$REPO_REPORT"
  done < <(ghq list 2>/dev/null || true)
  if [[ "$DIRTY_COUNT" -gt 0 || "$NO_REMOTE_COUNT" -gt 0 || "$AHEAD_COUNT" -gt 0 ]]; then
    review_gate "Repository risk" "$REPO_COUNT total; $DIRTY_COUNT dirty; $NO_REMOTE_COUNT without origin; $AHEAD_COUNT ahead"
  else
    pass_gate "Repository risk" "$REPO_COUNT repositories; none dirty, ahead, or without origin"
  fi
fi

if [[ "$STACK" == node || "$STACK" == both ]]; then
  check_command "Node stack" "fnm-managed Node plus npm and Homebrew pnpm" zsh -lic 'fnm current && node --version && npm --version && pnpm --version'
fi
if [[ "$STACK" == python || "$STACK" == both ]]; then
  check_command "Python stack" "uv can resolve an interpreter" uv python find
fi
if [[ "$TRACK" == 1 || "$TRACK" == 3 ]]; then
  check_command "GitHub authentication" "Required by selected track" gh auth status
fi
if [[ "$TRACK" == 2 || "$TRACK" == 3 ]]; then
  check_command "Azure authentication" "Required by selected track" az account show
fi

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    CONTAINER_COUNT="$( (docker ps -a --format '{{.Names}}' 2>/dev/null || true) | awk 'NF {n++} END {print n+0}')"
    pass_gate "Container runtime" "Available; $CONTAINER_COUNT container(s) recorded"
  else
    review_gate "Container runtime" "Docker command exists but its engine is not running"
  fi
else
  row "Container runtime" OPTIONAL "Not installed"
fi

AI_FOUND=0
for ai_command in claude codex copilot; do
  if command -v "$ai_command" >/dev/null 2>&1; then
    AI_FOUND=$((AI_FOUND + 1))
    if "$ai_command" --version >/dev/null 2>&1; then pass_gate "$ai_command client" "Installed"
    else review_gate "$ai_command client" "Command exists but version check failed"; fi
  fi
done
[[ "$AI_FOUND" -gt 0 ]] || row "AI clients" OPTIONAL "No terminal AI client discovered"

MCP_CONFIG_COUNT=0
for mcp_path in \
  "$HOME/.config/mcp/servers.md" \
  "$HOME/.mcp.json" \
  "$HOME/.copilot/mcp-config.json" \
  "$HOME/Library/Application Support/Code/User/mcp.json"; do
  [[ -f "$mcp_path" ]] && MCP_CONFIG_COUNT=$((MCP_CONFIG_COUNT + 1))
done
if [[ "$MCP_CONFIG_COUNT" -gt 0 ]]; then pass_gate "MCP configuration inventory" "$MCP_CONFIG_COUNT known configuration file(s); contents not printed"
else row "MCP configuration inventory" OPTIONAL "No known configuration file discovered"; fi

ADVANCED_CURRENT=0
ADVANCED_REVIEW=0
for module in 15 16 17 18 19 20 21 22; do
  marker="$STATE_ROOT/advanced/completed/$module"
  [[ -f "$marker" ]] || continue
  document=""
  case "$module" in
    15) document=15-full-dotfiles-and-bootstrap.md ;;
    16) document=16-brewfile-apps-and-editor.md ;;
    17) document=17-shell-and-package-automation.md ;;
    18) document=18-hosting-identities-azure-and-worktrees.md ;;
    19) document=19-macos-gui-and-local-https.md ;;
    20) document=20-restore-and-migrate.md ;;
    21) document=21-audit-maintenance-and-rebuild.md ;;
    22) document=22-ai-skills-and-mcp-operations.md ;;
  esac
  expected="$(shasum -a 256 "$SCRIPT_DIR/../docs/03-advanced/$document" | awk '{print $1}')"
  recorded="$(sed -n '1p' "$marker")"
  if [[ "$expected" == "$recorded" ]]; then ADVANCED_CURRENT=$((ADVANCED_CURRENT + 1))
  else ADVANCED_REVIEW=$((ADVANCED_REVIEW + 1)); fi
done
if [[ "$ADVANCED_REVIEW" -gt 0 ]]; then review_gate "Advanced module fingerprints" "$ADVANCED_CURRENT current; $ADVANCED_REVIEW need review"
else pass_gate "Advanced module fingerprints" "$ADVANCED_CURRENT completed module(s) current"; fi

{
  printf '\n## Summary\n\n'
  printf -- '- Required failures: **%s**\n' "$FAILURES"
  printf -- '- Review items: **%s**\n' "$REVIEWS"
  printf -- '- Private repository detail: `%s`\n' "$REPO_REPORT"
  printf '\nA REVIEW item is not automatically a defect. Inspect it before updates, cleanup, migration, or rebuild.\n'
} >> "$REPORT"

chmod 600 "$REPORT"
ok "advanced environment report: $REPORT"
info "repository summary: $REPO_REPORT"
[[ "$PRINT_REPORT" == 1 ]] && sed -n '1,$p' "$REPORT"

if [[ "$CHECK_ONLY" == 1 && "$FAILURES" -gt 0 ]]; then
  err "$FAILURES required audit gate(s) failed"
  exit 1
fi
