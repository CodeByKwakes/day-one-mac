#!/usr/bin/env bash
# Guide and fingerprint tracker for optional advanced Day One Mac modules.
# It does not install packages or edit system/application configuration.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GUIDE_DIR="$PROJECT_DIR/docs/03-advanced"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
STATE_ROOT="$(day_one_state_root)"
ADVANCED_STATE="$STATE_ROOT/advanced"
COMPLETED_DIR="$ADVANCED_STATE/completed"
ARCHIVE_DIR="$ADVANCED_STATE/archive"

ACTION=guided
MODULE=""
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: ./advanced-setup.sh [option]

  --guided             walk through Modules 15–22 (default)
  --list               list modules and guide paths
  --status             show pending, current, or review-required state
  --module NN          read one module guide
  --complete NN        record its current guide fingerprint after verification
  --reset NN           archive its completion marker; change no configured state
  --yes                confirm --complete or --reset without prompting
  -h, --help           show this help

This is a documentation and progress tool. It never installs, removes, or
configures a feature. Complete the checklist in the selected guide first.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }

module_title() {
  case "$1" in
    15) printf 'Full dotfiles and bootstrap\n' ;;
    16) printf 'Brewfile, applications, and editor inventory\n' ;;
    17) printf 'Shell and package automation\n' ;;
    18) printf 'Hosting identities, Azure, and worktrees\n' ;;
    19) printf 'macOS, GUI, and local HTTPS\n' ;;
    20) printf 'Restore and migrate selected data\n' ;;
    21) printf 'Audit, maintenance, and rebuild\n' ;;
    22) printf 'Shared AI skills and MCP operations\n' ;;
    *) return 1 ;;
  esac
}

module_doc() {
  case "$1" in
    15) printf '%s/15-full-dotfiles-and-bootstrap.md\n' "$GUIDE_DIR" ;;
    16) printf '%s/16-brewfile-apps-and-editor.md\n' "$GUIDE_DIR" ;;
    17) printf '%s/17-shell-and-package-automation.md\n' "$GUIDE_DIR" ;;
    18) printf '%s/18-hosting-identities-azure-and-worktrees.md\n' "$GUIDE_DIR" ;;
    19) printf '%s/19-macos-gui-and-local-https.md\n' "$GUIDE_DIR" ;;
    20) printf '%s/20-restore-and-migrate.md\n' "$GUIDE_DIR" ;;
    21) printf '%s/21-audit-maintenance-and-rebuild.md\n' "$GUIDE_DIR" ;;
    22) printf '%s/22-ai-skills-and-mcp-operations.md\n' "$GUIDE_DIR" ;;
    *) return 1 ;;
  esac
}

validate_module() {
  [[ "$1" =~ ^(15|16|17|18|19|20|21|22)$ ]] || {
    err "module must be 15 through 22"
    exit 2
  }
}

guide_fingerprint() {
  shasum -a 256 "$(module_doc "$1")" | awk '{print $1}'
}

module_state() {
  local marker="$COMPLETED_DIR/$1" expected recorded
  [[ -f "$marker" ]] || { printf 'pending\n'; return; }
  expected="$(guide_fingerprint "$1")"
  recorded="$(sed -n '1p' "$marker")"
  if [[ "$expected" == "$recorded" ]]; then printf 'current\n'; else printf 'review\n'; fi
}

confirm() {
  local prompt="$1" answer
  [[ "$ASSUME_YES" == 1 ]] && return 0
  [[ -t 0 ]] || { err "$prompt needs an interactive terminal or --yes"; return 1; }
  printf '%s [y/N]: ' "$prompt"
  IFS= read -r answer || return 1
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]]
}

ensure_phase_eight() {
  if [[ ! -f "$STATE_ROOT/completed/08" ]]; then
    err "Required Phase 8 is not recorded complete. Finish and verify the base first."
    return 1
  fi
}

print_list() {
  local number
  ui_title '🧰' 'Advanced optional setup — Modules 15–22'
  for number in 15 16 17 18 19 20 21 22; do
    printf '  %s  %-48s %s\n' "$number" "$(module_title "$number")" "$(module_doc "$number")"
  done
}

print_status() {
  local number state marker
  ui_title '📊' 'Advanced optional progress'
  for number in 15 16 17 18 19 20 21 22; do
    state="$(module_state "$number")"
    case "$state" in
      current) marker='✓ current'; ui_status success "$(printf '%-9s  %s — %s' "$marker" "$number" "$(module_title "$number")")" ;;
      review) marker='⚠ review'; ui_status warning "$(printf '%-9s  %s — %s' "$marker" "$number" "$(module_title "$number")")" ;;
      *) marker='○ pending'; ui_status pending "$(printf '%-9s  %s — %s' "$marker" "$number" "$(module_title "$number")")" ;;
    esac
  done
}

read_module() {
  local document
  document="$(module_doc "$1")"
  [[ -s "$document" ]] || { err "module guide is missing: $document"; return 1; }
  info "$document"
  if [[ -t 0 && -t 1 && -x "$(command -v less 2>/dev/null || true)" ]]; then
    less "$document"
  else
    sed -n '1,$p' "$document"
  fi
}

complete_module() {
  ensure_phase_eight || return 1
  confirm "Have you completed and verified every applicable Module $1 checklist item?" || return 10
  mkdir -p "$COMPLETED_DIR" "$ARCHIVE_DIR"
  chmod 700 "$ADVANCED_STATE" "$COMPLETED_DIR" "$ARCHIVE_DIR"
  guide_fingerprint "$1" > "$COMPLETED_DIR/$1"
  chmod 600 "$COMPLETED_DIR/$1"
  ok "Module $1 recorded current"
}

reset_module() {
  local marker="$COMPLETED_DIR/$1" destination
  [[ -f "$marker" ]] || { info "Module $1 has no completion marker"; return 0; }
  confirm "Archive the Module $1 progress marker without undoing its configuration?" || return 10
  mkdir -p "$ARCHIVE_DIR"
  chmod 700 "$ADVANCED_STATE" "$ARCHIVE_DIR"
  destination="$ARCHIVE_DIR/$1-$(date -u '+%Y%m%dT%H%M%SZ')"
  mv "$marker" "$destination"
  ok "marker archived to $destination"
}

guided() {
  local number state answer
  print_status
  [[ -f "$STATE_ROOT/completed/08" ]] || warn "Phase 8 is not complete; guides may be read, but completion cannot be recorded yet."
  for number in 15 16 17 18 19 20 21 22; do
    state="$(module_state "$number")"
    [[ "$state" == current ]] && continue
    printf '\nModule %s — %s\n' "$number" "$(module_title "$number")"
    info "$(module_doc "$number")"
    [[ -t 0 ]] || { err "guided mode needs a terminal; use --module or --status"; return 2; }
    printf '[r] read  [c] mark complete  [s] skip  [q] quit: '
    IFS= read -r answer || return 10
    case "$answer" in
      r|R|'') read_module "$number" ;;
      c|C) complete_module "$number" || return $? ;;
      s|S) continue ;;
      q|Q) return 0 ;;
      *) warn "unknown choice; module left pending" ;;
    esac
  done
  print_status
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --guided) ACTION=guided ;;
    --list) ACTION=list ;;
    --status) ACTION=status ;;
    --module) ACTION=module; shift; [[ $# -gt 0 ]] || { err "--module needs 15–22"; exit 2; }; MODULE="$1" ;;
    --complete) ACTION=complete; shift; [[ $# -gt 0 ]] || { err "--complete needs 15–22"; exit 2; }; MODULE="$1" ;;
    --reset) ACTION=reset; shift; [[ $# -gt 0 ]] || { err "--reset needs 15–22"; exit 2; }; MODULE="$1" ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -z "$MODULE" ]] || validate_module "$MODULE"
case "$ACTION" in
  list) print_list ;;
  status) print_status ;;
  module) read_module "$MODULE" ;;
  complete) complete_module "$MODULE" ;;
  reset) reset_module "$MODULE" ;;
  guided) guided ;;
esac
