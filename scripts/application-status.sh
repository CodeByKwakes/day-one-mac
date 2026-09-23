#!/usr/bin/env bash
# Check application ownership and resolve only missing selected applications.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/application-ownership.sh"

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
INSTALL_MANIFEST="$STATE_DIR/install-manifest.tsv"
PROVENANCE_TSV="$STATE_DIR/application-provenance.tsv"
PROVENANCE_REPORT="$STATE_DIR/application-provenance.md"
SCOPE=all
INSTALL_MISSING=0
APP_INSTALL_POLICY=""
REQUESTED_IDS=()
MISSING_IDS=()
REVIEW_COUNT=0

usage() {
  cat <<'EOF'
Usage: ./application-status.sh [options]

  --required            check only required applications
  --optional            check only optional applications
  --id ID               check one catalogue ID; repeatable
  --install-missing     resolve only missing selected applications
  --app-install-policy MODE
                        prompt, homebrew, or check-only
  --yes                 retained for compatibility; does not choose an owner
  -h, --help            show this help

The check accepts valid Homebrew, Mac App Store, company-managed, and manual
installations. It never replaces or removes an existing external application.
The readable report is stored under ~/.day-one-mac/application-provenance.md.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }

ensure_state() {
  mkdir -p "$STATE_DIR"
  touch "$INSTALL_MANIFEST"
  chmod 700 "$STATE_DIR"
  chmod 600 "$INSTALL_MANIFEST"
}

append_unique() {
  local line="$1"
  grep -Fqx "$line" "$INSTALL_MANIFEST" 2>/dev/null || printf '%s\n' "$line" >> "$INSTALL_MANIFEST"
}

print_detected_application() {
  local source_label
  source_label="$(day_one_app_source_label "$DAY_ONE_APP_SOURCE")"
  case "$DAY_ONE_APP_STATUS" in
    ready)
      ok "$DAY_ONE_APP_NAME — $source_label"
      [[ "$DAY_ONE_APP_FOUND_PATH" == - ]] || info "location: $DAY_ONE_APP_FOUND_PATH"
      ;;
    missing)
      ui_status pending "○ $DAY_ONE_APP_NAME — missing"
      info "available Homebrew cask: $DAY_ONE_APP_CASK"
      ;;
    review)
      err "$DAY_ONE_APP_NAME — needs review"
      warn "$DAY_ONE_APP_REASON"
      ;;
  esac
}

record_current() {
  ensure_state
  day_one_app_record_current "$PROVENANCE_TSV" "$PROVENANCE_REPORT" "$INSTALL_MANIFEST"
}

install_missing_application() {
  local id="$1" brew_bin before_formulae formula
  day_one_app_detect "$id"
  [[ "$DAY_ONE_APP_STATUS" == missing ]] || return 0
  if [[ "$APP_INSTALL_POLICY" == prompt && ! -t 0 ]]; then
    err "$DAY_ONE_APP_NAME needs an interactive installation choice."
    warn 'Rerun in a terminal or pass --app-install-policy homebrew.'
    return 10
  fi
  day_one_app_choose_install_route "$APP_INSTALL_POLICY"
  case "$DAY_ONE_APP_INSTALL_CHOICE" in
    stop)
      day_one_app_show_install_requirements
      warn "$DAY_ONE_APP_NAME was not installed."
      return 10
      ;;
    external)
      while :; do
        day_one_app_prompt_external_action
        case "$DAY_ONE_APP_EXTERNAL_ACTION" in
          homebrew) break ;;
          stop) warn "$DAY_ONE_APP_NAME remains pending."; return 10 ;;
          again) warn 'Choose Enter, h, or s.'; continue ;;
        esac
        hash -r 2>/dev/null || true
        day_one_app_detect "$id"
        print_detected_application
        record_current
        case "$DAY_ONE_APP_STATUS" in
          ready) ok "$DAY_ONE_APP_NAME was found and remains externally managed"; return 0 ;;
          review) err "$DAY_ONE_APP_REASON"; return 1 ;;
          missing) warn "$DAY_ONE_APP_NAME is still missing." ;;
        esac
      done
      ;;
  esac
  [[ "$DAY_ONE_APP_CASK" != - ]] || { err "$DAY_ONE_APP_NAME has no Homebrew cask to install."; return 1; }
  brew_bin="$(day_one_app_brew_bin)" || { err 'Homebrew is required before installing missing applications.'; return 1; }
  before_formulae="$("$brew_bin" list --formula 2>/dev/null | LC_ALL=C sort || true)"
  ui_section '📥' "Installing $DAY_ONE_APP_NAME"
  "$brew_bin" install --cask "$DAY_ONE_APP_CASK"
  ensure_state
  append_unique "brew-cask"$'\t'"$DAY_ONE_APP_CASK"
  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    grep -Fqx "$formula" <<<"$before_formulae" || append_unique "brew-dependency"$'\t'"$formula"
  done < <("$brew_bin" list --formula 2>/dev/null | LC_ALL=C sort)
  day_one_app_detect "$id"
  record_current
  if day_one_app_is_satisfied; then
    ok "$DAY_ONE_APP_NAME installed and verified"
  else
    err "$DAY_ONE_APP_NAME installation completed, but verification failed."
    warn "$DAY_ONE_APP_REASON"
    return 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --required) SCOPE=required ;;
    --optional) SCOPE=optional ;;
    --id) shift; [[ $# -gt 0 ]] || { err '--id needs a catalogue ID'; exit 2; }; REQUESTED_IDS+=("$1") ;;
    --install-missing) INSTALL_MISSING=1 ;;
    --app-install-policy) shift; [[ $# -gt 0 ]] || { err '--app-install-policy needs prompt, homebrew, or check-only'; exit 2; }; APP_INSTALL_POLICY="$1" ;;
    --yes) : ;; # compatibility: approval never selects application ownership
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ -z "$APP_INSTALL_POLICY" ]]; then
  if [[ "$INSTALL_MISSING" == 1 && -t 0 ]]; then APP_INSTALL_POLICY=prompt
  else APP_INSTALL_POLICY=check-only
  fi
fi
[[ "$APP_INSTALL_POLICY" =~ ^(prompt|homebrew|check-only)$ ]] || {
  err '--app-install-policy must be prompt, homebrew, or check-only'
  exit 2
}

[[ -r "$DAY_ONE_APP_CATALOG" ]] || { err "application catalogue is missing: $DAY_ONE_APP_CATALOG"; exit 1; }
if [[ "${#REQUESTED_IDS[@]}" -eq 0 ]]; then
  while IFS= read -r app_id; do [[ -n "$app_id" ]] && REQUESTED_IDS+=("$app_id"); done \
    < <(day_one_app_catalog_ids "$SCOPE")
fi

ui_title '📦' 'Day One Mac application ownership check'
for app_id in "${REQUESTED_IDS[@]}"; do
  if ! day_one_app_detect "$app_id"; then
    err "unknown application catalogue ID: $app_id"
    REVIEW_COUNT=$((REVIEW_COUNT + 1))
    continue
  fi
  print_detected_application
  record_current
  case "$DAY_ONE_APP_STATUS" in
    missing) MISSING_IDS+=("$app_id") ;;
    review) REVIEW_COUNT=$((REVIEW_COUNT + 1)) ;;
  esac
done

info "report: $PROVENANCE_REPORT"
if [[ "$REVIEW_COUNT" -gt 0 ]]; then
  err "$REVIEW_COUNT application result(s) need review; nothing conflicting was installed."
  exit 1
fi

if [[ "$INSTALL_MISSING" == 1 && "${#MISSING_IDS[@]}" -gt 0 ]]; then
  for app_id in "${MISSING_IDS[@]}"; do install_missing_application "$app_id"; done
elif [[ "${#MISSING_IDS[@]}" -gt 0 ]]; then
  info "${#MISSING_IDS[@]} selected application(s) are missing. Add --install-missing to choose Homebrew, another approved installer, or a safe stop."
fi

ok 'ownership check complete; external applications were left unchanged'
