#!/usr/bin/env bash
# Select and install optional command-line tools from the day-one-mac catalogue.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CATALOG="$PROJECT_DIR/config/catalogs/optional-formulae.tsv"
source "$SCRIPT_DIR/../src/core/project-paths.sh"
source "$SCRIPT_DIR/../src/core/terminal-ui.sh"
source "$SCRIPT_DIR/../src/core/module-execution.sh"
source "$SCRIPT_DIR/../src/core/configuration-choices.sh"
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
SETUP_ALIASES=0
ALIASES_TARGET=""
ALIASES_SOURCE=""

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
  --aliases              add guarded eza aliases using the Phase 5 owner
  --yes                  skip installation confirmation; does not select aliases
  -h, --help             show this help

Only selected formulae are installed. An unselected or toggled-off item
is never uninstalled. Optional aliases require --aliases or a separate yes.
Use Homebrew directly when removal is intentional.
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
    --aliases) SETUP_ALIASES=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$SETUP_ALIASES" == 0 || ( "$CHECK_ONLY" == 0 && "$LIST_ONLY" == 0 ) ]] || {
  err '--aliases is an apply/preview option; --check verifies packages only.'; exit 2;
}

[[ "$USE_SAVED" == 0 || ( -z "$PACKAGE_CSV" && "$SELECT_ALL" == 0 ) ]] || {
  err '--saved cannot be combined with a new selection'; exit 2;
}
if [[ "$DRY_RUN" == 0 && "$CHECK_ONLY" == 0 && "$LIST_ONLY" == 0 ]]; then
  # Bash 3.2 treats an empty array as unbound under set -u.
  day_one_serialize cli-tools "$0" ${ORIGINAL_ARGS[@]+"${ORIGINAL_ARGS[@]}"}
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
  printf 'Required setup tools are managed by Phases 2–8 and are not toggled here.\n'
  printf 'Optional ghq has its own selection: day-one-mac folders --help\n'
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
  local cursor=0 group_cursor=0 key rest i check state item group selected_count
  local groups=() visible=()
  for group in "${TOOL_GROUPS[@]}"; do
    if [[ "${#groups[@]}" == 0 || "$group" != "${groups[${#groups[@]} - 1]}" ]]; then
      groups+=("$group")
      [[ "$group" != Navigation ]] || group_cursor=$((${#groups[@]} - 1))
    fi
  done
  [[ -t 0 ]] || { err "interactive selection needs a terminal; use --all or --packages"; exit 2; }
  while :; do
    ui_clear_screen
    ui_banner '🎛️' 'Optional command-line tools'
    selected_count=0
    for i in "${SELECTED[@]}"; do selected_count=$((selected_count + i)); done
    ui_text "Selected: $selected_count across all categories"
    group="${groups[$group_cursor]}"
    ui_text "$group ($((group_cursor + 1))/${#groups[@]})"
    visible=()
    for ((i=0; i<${#FORMULAE[@]}; i++)); do
      [[ "${TOOL_GROUPS[$i]}" != "$group" ]] || visible+=("$i")
    done
    ui_menu_window "${#visible[@]}" "$cursor" 13
    for ((item=DAY_ONE_UI_MENU_START; item<DAY_ONE_UI_MENU_END; item++)); do
      i="${visible[$item]}"
      if is_installed "${FORMULAE[$i]}"; then state='installed'; else state='missing'; fi
      if [[ "${SELECTED[$i]}" == 1 ]]; then check='[x]'; else check='[ ]'; fi
      ui_menu_item "$item" "$cursor" "$check" "${FORMULAE[$i]} [$state]"
    done
    ui_text "${PURPOSES[${visible[$cursor]}]}"
    ui_menu_position "${#visible[@]}" "$cursor"
    ui_menu_help category
    IFS= read -rsn1 key || exit 10
    if [[ "$key" == $'\033' ]]; then
      IFS= read -rsn2 rest || true
      key="$key$rest"
    fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#visible[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#visible[@]}" ]] || cursor=0 ;;
      $'\033[D'|h|H) group_cursor=$((group_cursor - 1)); [[ "$group_cursor" -ge 0 ]] || group_cursor=$((${#groups[@]} - 1)); cursor=0 ;;
      $'\033[C'|l|L) group_cursor=$((group_cursor + 1)); [[ "$group_cursor" -lt "${#groups[@]}" ]] || group_cursor=0; cursor=0 ;;
      ' ') i="${visible[$cursor]}"; if [[ "${SELECTED[$i]}" == 1 ]]; then SELECTED[$i]=0; else SELECTED[$i]=1; fi ;;
      b|B|q|Q) exit 10 ;;
      a|A) for i in "${visible[@]}"; do SELECTED[$i]=1; done ;;
      n|N) for i in "${visible[@]}"; do SELECTED[$i]=0; done ;;
      '') ui_clear_screen; return 0 ;;
    esac
  done
}

state_value() { [[ ! -r "$STATE_DIR/$1" ]] || sed -n '1p' "$STATE_DIR/$1"; }

cli_aliases_block() {
  cat <<'EOF'
# Day One Mac optional eza aliases
if command -v eza >/dev/null 2>&1; then
  (( ${+aliases[ls]} || ${+functions[ls]} )) || alias ls='eza --group-directories-first'
  (( ${+aliases[ll]} || ${+functions[ll]} )) || alias ll='eza --long --all --git --group-directories-first'
  (( ${+aliases[lt]} || ${+functions[lt]} )) || alias lt='eza --tree'
fi
# End Day One Mac optional eza aliases
EOF
}

cli_aliases_prepare() {
  local COMPLETED_DIR="$STATE_DIR/completed" DOTFILES_VERSIONING='' SHELL_CHOICE='' PROMPT_CHOICE=''
  configuration_load_choices
  ALIASES_TARGET="$HOME/.config/zsh/aliases.zsh"
  ALIASES_SOURCE="$ALIASES_TARGET"
  day_one_safe_state_path "$HOME/.zshrc" && day_one_safe_state_path "$ALIASES_TARGET" || return 10
  [[ -f "$HOME/.zshrc" && -r "$HOME/.zshrc" ]] \
    && grep -Fq '.config/zsh/aliases.zsh' "$HOME/.zshrc" || {
    err 'Complete the Phase 5 aliases.zsh source line in ~/.zshrc before adding aliases.'; return 10;
  }
  case "$DOTFILES_VERSIONING" in
    none) configuration_unmanaged_preflight || return $? ;;
    local|git)
      have chezmoi || { err 'The selected configuration owner requires chezmoi.'; return 10; }
      ALIASES_SOURCE="$(chezmoi source-path "$ALIASES_TARGET")" || return 10
      [[ "$ALIASES_SOURCE" == /* && "$ALIASES_SOURCE" != *.tmpl && -f "$ALIASES_SOURCE" ]] \
        && day_one_safe_state_path "$ALIASES_SOURCE" && cmp -s "$ALIASES_SOURCE" "$ALIASES_TARGET" || {
        err 'Merge aliases with chezmoi edit ~/.config/zsh/aliases.zsh: templates or source/live drift need manual review.'; return 10;
      } ;;
    *) err 'Choose configuration ownership in Phase 5 before adding aliases.'; return 10 ;;
  esac
  [[ ! -e "$ALIASES_SOURCE" || ( -f "$ALIASES_SOURCE" && -r "$ALIASES_SOURCE" && -O "$ALIASES_SOURCE" ) ]] || {
    err 'The aliases source must be a readable regular file owned by you.'; return 10;
  }
}

cli_aliases_apply() {
  local temporary
  if [[ -f "$ALIASES_SOURCE" ]] && grep -Fq '# Day One Mac optional eza aliases' "$ALIASES_SOURCE"; then
    /bin/zsh -n "$ALIASES_SOURCE" || return 1
    info 'Existing Day One Mac eza alias block retained.'
    return 0
  fi
  day_one_state_directory "$(dirname "$ALIASES_SOURCE")" || return 1
  temporary="$(mktemp "$(dirname "$ALIASES_SOURCE")/.optional-aliases.XXXXXX")" || return 1
  if [[ -f "$ALIASES_SOURCE" ]]; then
    cp -p "$ALIASES_SOURCE" "$MODULE_RUN/before/optional-aliases.zsh" || { rm -f "$temporary"; return 1; }
    chmod 600 "$MODULE_RUN/before/optional-aliases.zsh"
    cp -p "$ALIASES_SOURCE" "$temporary" || { rm -f "$temporary"; return 1; }
  else chmod 600 "$temporary"; fi
  { printf '\n'; cli_aliases_block; } >> "$temporary"
  /bin/zsh -n "$temporary" || { rm -f "$temporary"; return 1; }
  mv -f "$temporary" "$ALIASES_SOURCE" || { rm -f "$temporary"; return 1; }
  day_one_module_event configured-aliases "$ALIASES_SOURCE"
  if [[ "$ALIASES_SOURCE" != "$ALIASES_TARGET" ]]; then
    chezmoi apply --exclude=scripts "$ALIASES_TARGET" || return $?
    cmp -s "$ALIASES_SOURCE" "$ALIASES_TARGET" || { err 'chezmoi did not apply the aliases file.'; return 1; }
  fi
  ok 'Optional eza aliases configured; open a new terminal to use them.'
  info "Source backup, when needed: $MODULE_RUN/before/optional-aliases.zsh"
}

if [[ "$LIST_ONLY" == 1 ]]; then print_catalogue; exit 0; fi
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

if [[ "$SETUP_ALIASES" == 1 ]]; then
  [[ " ${CHOSEN[*]} " == *' eza '* ]] || { err '--aliases currently supports eza; include eza in the selection.'; exit 2; }
  [[ "$DRY_RUN" == 1 ]] || cli_aliases_prepare
fi

if [[ "$DRY_RUN" == 1 ]]; then
  if [[ "$MISSING_COUNT" -gt 0 ]]; then
    for formula in "${MISSING[@]}"; do printf '  $ brew install %q\n' "$formula"; done
  else
    ok "every selected optional formula is already installed"
  fi
  if [[ "$SETUP_ALIASES" == 1 ]]; then
    ui_section '' 'Optional aliases for ~/.config/zsh/aliases.zsh (Phase 5 owner)'
    cli_aliases_block
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

day_one_phase_current 08 || { err 'Current Phase 8 completion is required; use --dry-run first.'; exit 10; }
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
ok 'Selected optional formulae verified'

if [[ "$SETUP_ALIASES" == 0 && "$ASSUME_YES" == 0 && -t 0 && -t 1 && " ${CHOSEN[*]} " == *' eza '* ]]; then
  ui_section '' 'Optional eza aliases'
  ui_text 'ls: directory listing | ll: detailed listing | lt: tree'
  ui_text 'Existing aliases and functions are preserved.'
  printf 'Add these aliases? [y/N]: '
  IFS= read -r answer || answer=''
  case "$answer" in y|Y|yes|YES) SETUP_ALIASES=1; cli_aliases_prepare ;; esac
fi
if [[ "$SETUP_ALIASES" == 1 ]]; then cli_aliases_apply; fi
MODULE_VERIFIED=1

printf '\nOther shell integrations remain manual. Use --aliases for optional eza aliases.\n'
printf 'Review docs/how-to/modules/optional/13-enhanced-cli-tools.md for eza, zoxide and Zsh plugin snippets.\n'
if [[ -e "$HOME/Brewfile" ]]; then
  printf 'Add the selected declarations to the chezmoi-managed Brewfile after review:\n'
  for formula in "${CHOSEN[@]}"; do printf '  brew "%s"\n' "$formula"; done
fi
