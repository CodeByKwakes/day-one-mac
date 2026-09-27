#!/usr/bin/env bash
# Select and install optional command-line tools from the day-one-mac catalogue.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CATALOG="$PROJECT_DIR/config/optional-formulae.tsv"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/module-execution.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
SELECTION_FILE="$STATE_DIR/optional-cli-packages"
MANIFEST="$STATE_ROOT/install-manifest.tsv"
LOG_FILE="$STATE_ROOT/setup.log"
DRY_RUN=0
ASSUME_YES=0
LIST_ONLY=0
CHECK_ONLY=0
SELECT_ALL=0
PACKAGE_CSV=""
USE_SAVED=0

usage() {
  cat <<'EOF'
Usage: ./configure-cli-tools.sh [options]

Without selection options, an interactive grouped selector is shown.

  --list                 print the catalogue and installation state
  --check                report missing selected tools without installing
  --all                  select every optional formula
  --packages A,B,C       select only these formula tokens
  --saved                use the last applied selection, including failed runs
  --dry-run              print the brew commands without running them
  --yes                  skip the final ordinary confirmation
  -h, --help             show this help

This script only installs selected formulae. An unselected or toggled-off item
is never uninstalled. Use Homebrew directly when removal is intentional.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) LIST_ONLY=1 ;;
    --check) CHECK_ONLY=1 ;;
    --all) SELECT_ALL=1 ;;
    --saved) USE_SAVED=1 ;;
    --packages) shift; [[ $# -gt 0 ]] || { err "--packages needs a comma-separated list"; exit 2; }; PACKAGE_CSV="$1" ;;
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$USE_SAVED" == 0 || ( -z "$PACKAGE_CSV" && "$SELECT_ALL" == 0 ) ]] || {
  err '--saved cannot be combined with a new selection'; exit 2;
}
if [[ "$DRY_RUN" == 0 && "$CHECK_ONLY" == 0 && "$LIST_ONLY" == 0 ]]; then
  day_one_serialize cli-tools "$0" "${ORIGINAL_ARGS[@]}"
fi
if [[ "$USE_SAVED" == 1 ]]; then
  PACKAGE_CSV="$(sed -n '1p' "$SELECTION_FILE" 2>/dev/null || true)"
  [[ -n "$PACKAGE_CSV" ]] || { err 'No saved CLI selection; use --packages first.'; exit 2; }
fi

[[ -r "$CATALOG" ]] || { err "catalogue is missing: $CATALOG"; exit 1; }
[[ "$SELECT_ALL" != 1 || -z "$PACKAGE_CSV" ]] || { err "choose --all or --packages, not both"; exit 2; }
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1
INSTALLED_FORMULAE=""
if have brew; then
  INSTALLED_FORMULAE="$(brew list --formula | LC_ALL=C sort)" || {
    err 'Cannot inspect Homebrew inventory; refusing to guess what is installed.'; exit 1;
  }
elif [[ "$DRY_RUN" == 1 ]]; then
  warn 'Homebrew is missing; this is a conditional plan. Complete Phase 2 before applying.'
else
  err "Homebrew is required; complete day-one-mac Phase 2 first."; exit 1
fi

TOOL_GROUPS=()
FORMULAE=()
PURPOSES=()
SELECTED=()
while IFS=$'\t' read -r group formula purpose; do
  [[ -n "$group" && "${group#\#}" == "$group" ]] || continue
  [[ "$formula" =~ ^[a-z0-9@+._-]+$ ]] || { err "invalid formula token in catalogue: $formula"; exit 1; }
  TOOL_GROUPS+=("$group")
  FORMULAE+=("$formula")
  PURPOSES+=("$purpose")
  SELECTED+=(0)
done < "$CATALOG"

is_installed() { grep -Fqx "$1" <<<"$INSTALLED_FORMULAE"; }

print_catalogue() {
  local i last_group="" state
  ui_title '🧰' 'Optional command-line tools'
  printf 'Required and not toggleable here: chezmoi, ghq, git, jq, ripgrep, starship, zsh\n'
  for ((i=0; i<${#FORMULAE[@]}; i++)); do
    if [[ "${TOOL_GROUPS[$i]}" != "$last_group" ]]; then
      printf '\n%s\n' "${TOOL_GROUPS[$i]}"
      last_group="${TOOL_GROUPS[$i]}"
    fi
    if is_installed "${FORMULAE[$i]}"; then state='installed'; else state='not installed'; fi
    printf '  %2d. %-25s %-13s %s\n' "$((i + 1))" "${FORMULAE[$i]}" "[$state]" "${PURPOSES[$i]}"
  done
}

set_csv_selection() {
  local csv="$1" token i found
  csv="${csv//,/ }"
  for token in $csv; do
    found=0
    for ((i=0; i<${#FORMULAE[@]}; i++)); do
      if [[ "${FORMULAE[$i]}" == "$token" ]]; then SELECTED[$i]=1; found=1; break; fi
    done
    [[ "$found" == 1 ]] || { err "formula is not in the optional catalogue: $token"; exit 2; }
  done
}

interactive_select() {
  local cursor=0 key rest i check pointer state last_group
  [[ -t 0 ]] || { err "interactive selection needs a terminal; use --all or --packages"; exit 2; }
  while :; do
    printf '\033[2J\033[H'
    ui_banner '🎛️' 'Toggle selection — installation only'
    printf '  Up/Down or j/k: move   Space: toggle   a: all   n: none\n'
    printf '  Enter: review          q: quit\n\n'
    printf 'Required base — locked and not toggleable\n'
    printf '  🔒 chezmoi  🔒 ghq  🔒 git  🔒 jq  🔒 ripgrep  🔒 starship  🔒 zsh\n'
    last_group=""
    for ((i=0; i<${#FORMULAE[@]}; i++)); do
      if [[ "${TOOL_GROUPS[$i]}" != "$last_group" ]]; then printf '\n%s\n' "${TOOL_GROUPS[$i]}"; last_group="${TOOL_GROUPS[$i]}"; fi
      if is_installed "${FORMULAE[$i]}"; then state='installed'; else state='missing'; fi
      if [[ "${SELECTED[$i]}" == 1 ]]; then check='[x]'; else check='[ ]'; fi
      if [[ "$i" == "$cursor" ]]; then pointer='>'; else pointer=' '; fi
      if [[ "$i" == "$cursor" ]]; then
        printf ' %s%s%s %s %-25s %-11s %s%s\n' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN" "$pointer" "$check" "${FORMULAE[$i]}" "[$state]" "${PURPOSES[$i]}" "$DAY_ONE_UI_RESET"
      else
        printf ' %s %s %-25s %-11s %s\n' "$pointer" "$check" "${FORMULAE[$i]}" "[$state]" "${PURPOSES[$i]}"
      fi
    done
    IFS= read -rsn1 key || exit 10
    if [[ "$key" == $'\033' ]]; then
      IFS= read -rsn2 rest || true
      key="$key$rest"
    fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#FORMULAE[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#FORMULAE[@]}" ]] || cursor=0 ;;
      ' ') if [[ "${SELECTED[$cursor]}" == 1 ]]; then SELECTED[$cursor]=0; else SELECTED[$cursor]=1; fi ;;
      q|Q) exit 10 ;;
      a|A) for ((i=0; i<${#SELECTED[@]}; i++)); do SELECTED[$i]=1; done ;;
      n|N) for ((i=0; i<${#SELECTED[@]}; i++)); do SELECTED[$i]=0; done ;;
      '') printf '\033[2J\033[H'; return 0 ;;
    esac
  done
}

print_catalogue
[[ "$LIST_ONLY" == 1 ]] && exit 0
if [[ "$SELECT_ALL" == 1 ]]; then
  for ((i=0; i<${#SELECTED[@]}; i++)); do SELECTED[$i]=1; done
elif [[ -n "$PACKAGE_CSV" ]]; then
  set_csv_selection "$PACKAGE_CSV"
else
  interactive_select
fi

CHOSEN=()
MISSING=()
CHOSEN_COUNT=0
MISSING_COUNT=0
for ((i=0; i<${#FORMULAE[@]}; i++)); do
  [[ "${SELECTED[$i]}" == 1 ]] || continue
  CHOSEN+=("${FORMULAE[$i]}")
  CHOSEN_COUNT=$((CHOSEN_COUNT + 1))
  if ! is_installed "${FORMULAE[$i]}"; then
    MISSING+=("${FORMULAE[$i]}")
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

if [[ "$CHOSEN_COUNT" -gt 0 ]]; then printf '\nSelected: %s\n' "${CHOSEN[*]}"; else printf '\nSelected: (none)\n'; fi
if [[ "$MISSING_COUNT" -gt 0 ]]; then printf 'Missing:  %s\n' "${MISSING[*]}"; else printf 'Missing:  (none)\n'; fi
[[ "$CHECK_ONLY" == 1 ]] && { [[ "$MISSING_COUNT" -eq 0 ]]; exit $?; }
[[ "$CHOSEN_COUNT" -gt 0 ]] || { info "nothing selected; no changes made"; exit 0; }

if [[ "$DRY_RUN" == 1 ]]; then
  if [[ "$MISSING_COUNT" -gt 0 ]]; then
    for formula in "${MISSING[@]}"; do printf '  $ brew install %q\n' "$formula"; done
  else
    ok "every selected optional formula is already installed"
  fi
  info 'Plan only; selection, shell configuration and Brewfile were not changed.'
  exit 0
fi
if [[ "$ASSUME_YES" != 1 ]]; then
  [[ -t 0 ]] || { err "installation confirmation needs a terminal or --yes"; exit 10; }
  printf 'Save this selection and install any missing formulae? [y/N]: '
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]] || exit 10
fi

selected_csv="$(IFS=,; printf '%s' "${CHOSEN[*]}")"
day_one_module_begin 13 "$selected_csv" "$SELECTION_FILE" "$MANIFEST" "$LOG_FILE"
day_one_write_state "$SELECTION_FILE" "$selected_csv"
mkdir -p "$STATE_ROOT"
touch "$MANIFEST" "$LOG_FILE"
chmod 700 "$STATE_ROOT"
chmod 600 "$MANIFEST" "$LOG_FILE"
record_install() {
  local kind="$1" token="$2" content
  content="$(cat "$MANIFEST")"
  grep -Fqx "$kind"$'\t'"$token" "$MANIFEST" && return 0
  day_one_write_state "$MANIFEST" "${content:+$content$'\n'}$kind"$'\t'"$token"
}
if [[ "$MISSING_COUNT" -gt 0 ]]; then
for formula in "${MISSING[@]}"; do
  before="$(brew list --formula | LC_ALL=C sort)"
  if grep -Fqx "$formula" <<< "$before"; then
    day_one_module_event already-installed "$formula"
    continue
  fi
  install_status=0
  day_one_module_event installing-formula "$formula"
  brew install "$formula" || install_status=$?
  after="$(brew list --formula | LC_ALL=C sort)"
  if grep -Fqx "$formula" <<< "$after"; then record_install brew-formula "$formula"; fi
  while IFS= read -r dependency; do
    [[ -n "$dependency" && "$dependency" != "$formula" ]] || continue
    if ! grep -Fqx "$dependency" <<<"$before"; then
      record_install brew-dependency "$dependency"
    fi
  done <<< "$after"
  if [[ "$install_status" != 0 ]]; then
    day_one_module_event failed-formula "$formula"
    err "Installation failed for $formula; partial additions were recorded. Resume the saved selection."
    exit "$install_status"
  fi
  grep -Fqx "$formula" <<< "$after" || { err "Homebrew did not install $formula"; exit 1; }
  printf '%s\tINSTALL optional formula %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$formula" >> "$LOG_FILE"
  ok "installed $formula"
  day_one_module_event installed-formula "$formula"
done
fi

INSTALLED_FORMULAE="$(brew list --formula | LC_ALL=C sort)"
for formula in "${CHOSEN[@]}"; do
  is_installed "$formula" || { err "Verification failed: missing $formula"; exit 1; }
done
MODULE_VERIFIED=1
ok 'Selected optional formulae verified'

printf '\nShell integration is intentionally not edited automatically.\n'
printf 'Review docs/02-optional/13-enhanced-cli-tools.md for eza, zoxide and Zsh plugin snippets.\n'
if [[ -e "$HOME/Brewfile" ]]; then
  printf 'Add the selected declarations to the chezmoi-managed Brewfile after review:\n'
  for formula in "${CHOSEN[@]}"; do printf '  brew "%s"\n' "$formula"; done
fi
