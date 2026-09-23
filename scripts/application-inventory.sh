#!/usr/bin/env bash
# Create a read-only inventory of Homebrew packages and macOS applications.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/application-ownership.sh"
STATE_ROOT="$(day_one_state_root)"
OUTPUT="${DAY_ONE_MAC_APPLICATION_REPORT:-${FRESH_START_APPLICATION_REPORT:-$STATE_ROOT/application-inventory.md}}"

err() { ui_error "$@"; }

usage() {
  cat <<'EOF'
Usage: ./application-inventory.sh [--output /absolute/report.md]

Reports Homebrew formulae and casks, Mac App Store entries when `mas` is
available, and application bundles in standard system, local and user folders.
It changes no application or package-manager state.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) shift; [[ $# -gt 0 ]] || { err 'missing --output path'; exit 2; }; OUTPUT="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$(uname -s)" == Darwin ]] || { err 'macOS is required'; exit 1; }
[[ "$OUTPUT" == /* ]] || { err 'output must be an absolute path'; exit 2; }
mkdir -p "$(dirname "$OUTPUT")"

markdown_path() { printf '%s' "$1" | sed 's/`/\\`/g'; }

{
  printf '# macOS application and package inventory\n\n'
  printf -- '- Generated: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf -- '- Host: `%s`\n' "$(scutil --get ComputerName 2>/dev/null || hostname)"
  printf -- '- macOS: `%s`\n\n' "$(sw_vers -productVersion)"

  printf '## Homebrew formulae\n\n'
  if command -v brew >/dev/null 2>&1; then
    formulae="$(brew list --formula --versions 2>/dev/null | LC_ALL=C sort || true)"
    if [[ -n "$formulae" ]]; then
      while IFS= read -r item; do printf -- '- `%s`\n' "$item"; done <<<"$formulae"
    else
      printf '_None._\n'
    fi
  else
    printf '_Homebrew is not installed._\n'
  fi

  printf '\n## Homebrew casks and applications\n\n'
  if command -v brew >/dev/null 2>&1; then
    casks="$(brew list --cask --versions 2>/dev/null | LC_ALL=C sort || true)"
    if [[ -n "$casks" ]]; then
      while IFS= read -r item; do printf -- '- `%s`\n' "$item"; done <<<"$casks"
    else
      printf '_None._\n'
    fi
  else
    printf '_Homebrew is not installed._\n'
  fi

  printf '\n## Mac App Store applications\n\n'
  if command -v mas >/dev/null 2>&1; then
    mas_items="$(mas list 2>/dev/null | LC_ALL=C sort -f || true)"
    if [[ -n "$mas_items" ]]; then
      while IFS= read -r item; do printf -- '- `%s`\n' "$(markdown_path "$item")"; done <<<"$mas_items"
    else
      printf '_None reported._\n'
    fi
  else
    printf '_The optional `mas` command is unavailable; App Store receipt ownership was not queried._\n'
  fi

  printf '\n## Non-system application bundles\n\n'
  local_apps=""
  for root in /Applications "$HOME/Applications"; do
    [[ -d "$root" ]] || continue
    found="$(find "$root" -maxdepth 2 -type d -name '*.app' -prune 2>/dev/null || true)"
    [[ -z "$found" ]] || local_apps="${local_apps}${local_apps:+$'\n'}${found}"
  done
  if [[ -n "$local_apps" ]]; then
    while IFS= read -r item; do printf -- '- `%s`\n' "$(markdown_path "$item")"; done <<<"$(printf '%s\n' "$local_apps" | LC_ALL=C sort -fu)"
  else
    printf '_None discovered in `/Applications` or `~/Applications`._\n'
  fi
  printf '\nHomebrew casks are listed separately above. A bundle in this section may be\n'
  printf 'Homebrew-managed, App Store-managed, or manually installed; the cask receipt\n'
  printf 'is the authoritative Homebrew ownership record.\n'

  printf '\n## Apple system application bundles\n\n'
  system_apps="$(find /System/Applications -maxdepth 2 -type d -name '*.app' -prune 2>/dev/null | LC_ALL=C sort || true)"
  if [[ -n "$system_apps" ]]; then
    while IFS= read -r item; do printf -- '- `%s`\n' "$(markdown_path "$item")"; done <<<"$system_apps"
  else
    printf '_None discovered._\n'
  fi

  printf '\n## Day One Mac application ownership\n\n'
  printf 'These are the applications known to the required and optional setup. A valid\n'
  printf 'external installation is accepted and will not be replaced by Homebrew.\n\n'
  printf '| Application | Scope | Phase/module | Result | Source | Location or command | Homebrew cask |\n'
  printf '|---|---|---:|---|---|---|---|\n'
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    day_one_app_detect "$app_id"
    printf '| %s | %s | %s | %s | %s | `%s` | `%s` |\n' \
      "$DAY_ONE_APP_NAME" "$DAY_ONE_APP_SCOPE" "$DAY_ONE_APP_PHASE" \
      "$(day_one_app_status_label "$DAY_ONE_APP_STATUS")" "$(day_one_app_source_label "$DAY_ONE_APP_SOURCE")" \
      "$DAY_ONE_APP_FOUND_PATH" "$DAY_ONE_APP_CASK"
  done < <(day_one_app_catalog_ids all)

  printf '\n## Interpretation\n\n'
  printf -- '- Broad cleanup removes every item in the Homebrew cask list.\n'
  printf -- '- It preserves every non-Homebrew `.app` bundle.\n'
  printf -- '- It can archive development settings even when their non-Homebrew app remains installed.\n'
  printf -- '- Apple system applications are inventory-only and are never cleanup targets.\n'
} > "$OUTPUT"

chmod 600 "$OUTPUT"
ui_title '📦' 'Application inventory complete'
ui_success "report: $OUTPUT"
