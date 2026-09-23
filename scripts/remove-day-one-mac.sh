#!/usr/bin/env bash
# Guided, preview-first removal coordinator for Day One Mac.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/container-data-paths.sh"

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
INSTALL_MANIFEST="$STATE_DIR/install-manifest.tsv"
PATH_MANIFEST="$STATE_DIR/path-manifest.tsv"
APPLICATION_PROVENANCE="$STATE_DIR/application-provenance.tsv"
ROLLBACK_SCRIPT="$SCRIPT_DIR/rollback-recorded-setup.sh"
CLEAN_SCRIPT="$SCRIPT_DIR/clean-development-state.sh"
SETTINGS_SCRIPT="$SCRIPT_DIR/configure-macos-settings.sh"

MODE=""
SECTIONS=""
DEVELOPER_MODE=keep
DEVELOPER_SELECTIONS=""
ARCHIVE_ROOT="$HOME"
EXECUTE=0
ASSUME_YES=0
GUIDED=0
INVENTORY_ONLY=0
FULL_ZAP=0
FULL_DOCKER=0
FULL_ORBSTACK=0
FULL_1PASSWORD=0
FULL_SSH=0
FULL_KEYCHAIN=0
STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
SESSION_ROOT=""

usage() {
  cat <<'EOF'
Usage: ./remove-day-one-mac.sh [options]

Without --execute, every mode is a read-only preview.

  --guided                    choose the removal mode and sections interactively
  --inventory                 report Homebrew ownership and repository risks only
  --mode MODE                 preview, recorded, sections, or full
  --sections CSV              packages,config,dotfiles,macos,containers,developer,state
  --developer MODE            keep, setup-repo, selected, or all
  --developer-path PATH       add one path below ~/Developer (repeatable)
  --archive-root PATH         existing recovery parent; default: $HOME
  --zap-cask-data             full mode: ask Homebrew to remove cask support data
  --archive-docker-data       full mode: include Docker Desktop data
  --archive-orbstack-data     full mode: include OrbStack data
  --archive-1password-data    full mode: include local 1Password application data
  --archive-ssh-private-keys  full mode: include detected SSH private keys
  --prepare-keychain-reset    full mode: write reviewed manual Keychain steps
  --execute                   perform the reviewed plan
  --yes                       accept the final typed confirmation (automation only)
  -h, --help                  show this help

Recorded mode removes only manifest-owned setup changes. Full mode delegates to
the account-preserving development cleanup and removes every Homebrew package.
Non-Homebrew applications, cloud vaults, and macOS Keychain data are never
silently deleted. ~/Developer is kept unless explicitly selected.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }

contains_csv() {
  case ",$1," in *",$2,"*) return 0 ;; *) return 1 ;; esac
}

append_csv() {
  local current="$1" value="$2"
  contains_csv "$current" "$value" && { printf '%s' "$current"; return; }
  printf '%s%s%s' "$current" "${current:+,}" "$value"
}

clear_screen() { [[ -t 1 ]] && printf '\033[2J\033[H'; }

SINGLE_VALUES=()
SINGLE_LABELS=()
SINGLE_RESULT=""
select_one() {
  local heading="$1" cursor="${2:-0}" key rest item marker radio
  while :; do
    clear_screen
    ui_banner '🧹' 'Day One Mac removal wizard'
    printf '%s\n\n' "$heading"
    printf '  Up/Down or j/k: move   Space or Enter: accept   q: quit\n\n'
    for ((item=0; item<${#SINGLE_VALUES[@]}; item++)); do
      marker=' '; radio='( )'
      [[ "$item" == "$cursor" ]] && marker='>' && radio='(●)'
      printf ' %s %s %s\n' "$marker" "$radio" "${SINGLE_LABELS[$item]}"
    done
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then IFS= read -rsn2 rest || true; key="$key$rest"; fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#SINGLE_VALUES[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#SINGLE_VALUES[@]}" ]] || cursor=0 ;;
      ' '|'') SINGLE_RESULT="${SINGLE_VALUES[$cursor]}"; clear_screen; return ;;
      q|Q) clear_screen; exit 0 ;;
    esac
  done
}

MENU_VALUES=()
MENU_LABELS=()
MENU_SELECTED=()
MENU_RESULT=""
select_toggles() {
  local heading="$1" cursor=0 key rest item marker check
  while :; do
    clear_screen
    ui_banner '🧹' 'Day One Mac removal wizard'
    printf '%s\n\n' "$heading"
    printf '  Up/Down or j/k: move   Space: toggle   a: all   n: none\n'
    printf '  Enter: accept          q: quit\n\n'
    for ((item=0; item<${#MENU_VALUES[@]}; item++)); do
      marker=' '; check='[ ]'
      [[ "$item" == "$cursor" ]] && marker='>'
      [[ "${MENU_SELECTED[$item]}" == 1 ]] && check='[x]'
      printf ' %s %s %s\n' "$marker" "$check" "${MENU_LABELS[$item]}"
    done
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then IFS= read -rsn2 rest || true; key="$key$rest"; fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#MENU_VALUES[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#MENU_VALUES[@]}" ]] || cursor=0 ;;
      ' ') if [[ "${MENU_SELECTED[$cursor]}" == 1 ]]; then MENU_SELECTED[$cursor]=0; else MENU_SELECTED[$cursor]=1; fi ;;
      a|A) for ((item=0; item<${#MENU_VALUES[@]}; item++)); do MENU_SELECTED[$item]=1; done ;;
      n|N) for ((item=0; item<${#MENU_VALUES[@]}; item++)); do MENU_SELECTED[$item]=0; done ;;
      q|Q) clear_screen; exit 0 ;;
      '') break ;;
    esac
  done
  MENU_RESULT=""
  for ((item=0; item<${#MENU_VALUES[@]}; item++)); do
    [[ "${MENU_SELECTED[$item]}" == 1 ]] || continue
    MENU_RESULT="$(append_csv "$MENU_RESULT" "${MENU_VALUES[$item]}")"
  done
  clear_screen
}

manifest_owns_brew_item() {
  local kind="$1" token="$2"
  [[ -r "$INSTALL_MANIFEST" ]] || return 1
  awk -F '\t' -v kind="$kind" -v token="$token" '
    $2 == token && ((kind == "formula" && ($1 == "brew-formula" || $1 == "brew-dependency")) ||
                    (kind == "cask" && $1 == "brew-cask")) { found=1 }
    END { exit !found }
  ' "$INSTALL_MANIFEST"
}

print_homebrew_inventory() {
  local token owner
  printf '\nHomebrew ownership\n'
  if [[ "${DAY_ONE_MAC_DISABLE_BREW_DISCOVERY:-0}" == 1 ]]; then
    printf '  Homebrew discovery is disabled for this isolated run.\n'
    return
  fi
  if ! have brew; then printf '  Homebrew is not installed.\n'; return; fi
  printf '  Formulae\n'
  while IFS= read -r token; do
    [[ -n "$token" ]] || continue
    if manifest_owns_brew_item formula "$token"; then owner='Day One recorded'; else owner='pre-existing or unrecorded — preserve'; fi
    printf '    %-34s %s\n' "$token" "$owner"
  done < <(brew list --formula 2>/dev/null || true)
  printf '  Casks and fonts\n'
  while IFS= read -r token; do
    [[ -n "$token" ]] || continue
    if manifest_owns_brew_item cask "$token"; then owner='Day One recorded'; else owner='pre-existing or unrecorded — preserve'; fi
    printf '    %-34s %s\n' "$token" "$owner"
  done < <(brew list --cask 2>/dev/null || true)
}

developer_repositories() {
  [[ -d "$HOME/Developer" ]] || return 0
  if have ghq; then
    ghq list -p 2>/dev/null | awk -v root="$HOME/Developer/" 'index($0, root) == 1' | LC_ALL=C sort -u
    return
  fi
  find "$HOME/Developer" \
    \( -type d \( -name node_modules -o -name .venv -o -name vendor -o -name dist -o -name build -o -name .cache \) -prune \) -o \
    \( \( -type d -o -type f \) -name .git -print -prune \) 2>/dev/null \
    | while IFS= read -r marker; do dirname "$marker"; done | LC_ALL=C sort -u
}

print_developer_inventory() {
  local repo dirty remote relative repo_count=0
  printf '\nDeveloper folder review\n'
  if [[ ! -d "$HOME/Developer" ]]; then printf '  ~/Developer does not exist.\n'; return; fi
  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    repo_count=$((repo_count + 1))
    relative="${repo#"$HOME/Developer/"}"
    if [[ -n "$(git -C "$repo" status --porcelain -uno 2>/dev/null || true)" ]]; then dirty='DIRTY'; else dirty='clean'; fi
    remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
    [[ -n "$remote" ]] || remote='NO-REMOTE'
    printf '  %-52s %s · %s\n' "$relative" "$dirty" "$remote"
  done < <(developer_repositories)
  [[ "$repo_count" -gt 0 ]] || printf '  No Git repositories detected. Non-repository content may still exist.\n'
}

print_inventory() {
  ui_title '🔎' 'Day One Mac removal inventory'
  printf '  State: %s\n' "$STATE_DIR"
  printf '  Install manifest: %s\n' "$([[ -s "$INSTALL_MANIFEST" ]] && printf available || printf missing)"
  printf '  Path manifest: %s\n' "$([[ -s "$PATH_MANIFEST" ]] && printf available || printf missing)"
  print_homebrew_inventory
  if [[ -s "$APPLICATION_PROVENANCE" ]]; then
    printf '\nApplication ownership recorded by Day One Mac\n'
    awk -F '\t' 'NR > 1 {
      printf "  %-30s source=%-14s installed-by-day-one=%s\n", $4, $6, $12
    }' "$APPLICATION_PROVENANCE"
  else
    printf '\nApplication ownership report is not available; non-Homebrew apps still remain protected.\n'
  fi
  print_developer_inventory
  printf '\nApplications not owned by Homebrew are preserved.\n'
  printf 'Cloud 1Password data and macOS Keychain data are never deleted automatically.\n'
}

discover_developer_choices() {
  local path relative
  MENU_VALUES=(); MENU_LABELS=(); MENU_SELECTED=()
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    relative="${path#"$HOME/Developer/"}"
    MENU_VALUES[${#MENU_VALUES[@]}]="$path"
    MENU_LABELS[${#MENU_LABELS[@]}]="$relative — Git repository"
    MENU_SELECTED[${#MENU_SELECTED[@]}]=0
  done < <(developer_repositories)
  for relative in _Projectless _sandbox _archive; do
    path="$HOME/Developer/$relative"
    [[ -e "$path" ]] || continue
    MENU_VALUES[${#MENU_VALUES[@]}]="$path"
    MENU_LABELS[${#MENU_LABELS[@]}]="$relative — non-repository workspace"
    MENU_SELECTED[${#MENU_SELECTED[@]}]=0
  done
}

guided_choices() {
  [[ -t 0 ]] || { err '--guided requires an interactive terminal'; exit 10; }
  SINGLE_VALUES=(preview recorded sections full exit)
  SINGLE_LABELS=(
    'Preview inventories and safety risks; change nothing'
    'Remove only changes recorded as owned by Day One Mac'
    'Choose individual removal sections'
    'Full development reset — every Homebrew package and known development state'
    'Exit without changing anything'
  )
  select_one 'Choose the result you want:' 0
  MODE="$SINGLE_RESULT"
  [[ "$MODE" != exit ]] || exit 0
  if [[ "$MODE" == sections ]]; then
    MENU_VALUES=(packages config dotfiles macos containers developer state)
    MENU_LABELS=(
      'Recorded Homebrew formulae and casks'
      'Recorded configuration files and directories'
      'chezmoi-managed targets and source'
      'Restore captured macOS preference values'
      'Archive Docker Desktop and OrbStack local data'
      'Archive selected content from ~/Developer'
      'Archive Day One Mac records and disable its portable command'
    )
    MENU_SELECTED=(1 1 0 0 0 0 0)
    select_toggles 'Choose the sections to remove or restore:'
    SECTIONS="$MENU_RESULT"
  fi
  if [[ "$MODE" == full ]]; then
    MENU_VALUES=(zap developer docker orbstack onepassword ssh keychain)
    MENU_LABELS=(
      'Zap Homebrew cask support data'
      'Archive the complete ~/Developer folder'
      'Archive Docker Desktop local data'
      'Archive OrbStack local data'
      'Archive local 1Password application data'
      'Archive detected SSH private keys'
      'Write manual macOS Keychain reset instructions'
    )
    MENU_SELECTED=(0 0 0 0 0 0 0)
    select_toggles 'Choose additional full-reset data scopes:'
    contains_csv "$MENU_RESULT" zap && FULL_ZAP=1
    contains_csv "$MENU_RESULT" developer && DEVELOPER_MODE=all
    contains_csv "$MENU_RESULT" docker && FULL_DOCKER=1
    contains_csv "$MENU_RESULT" orbstack && FULL_ORBSTACK=1
    contains_csv "$MENU_RESULT" onepassword && FULL_1PASSWORD=1
    contains_csv "$MENU_RESULT" ssh && FULL_SSH=1
    contains_csv "$MENU_RESULT" keychain && FULL_KEYCHAIN=1
  elif [[ "$MODE" == sections ]] && contains_csv "$SECTIONS" developer; then
    SINGLE_VALUES=(keep setup-repo selected all)
    SINGLE_LABELS=(
      'Keep all Developer content'
      'Archive only the repository containing this Day One Mac checkout'
      'Select individual repositories and workspace folders'
      'Archive the complete Developer folder'
    )
    select_one 'What should happen to ~/Developer?' 0
    DEVELOPER_MODE="$SINGLE_RESULT"
    if [[ "$DEVELOPER_MODE" == selected ]]; then
      discover_developer_choices
      [[ "${#MENU_VALUES[@]}" -gt 0 ]] || { warn 'No selectable Developer content was found.'; DEVELOPER_MODE=keep; return; }
      select_toggles 'Choose Developer repositories and folders to archive:'
      DEVELOPER_SELECTIONS="${MENU_RESULT//,/$'\n'}"
    fi
  fi
  if [[ "$MODE" != preview ]]; then
    printf 'Recovery parent [%s]: ' "$ARCHIVE_ROOT"
    IFS= read -r answer
    ARCHIVE_ROOT="${answer:-$ARCHIVE_ROOT}"
  fi
}

safe_archive_root() {
  [[ "$ARCHIVE_ROOT" == /* && "$ARCHIVE_ROOT" != / && "$ARCHIVE_ROOT" != /Users ]] || return 1
  [[ -d "$ARCHIVE_ROOT" ]] || return 1
  case "$ARCHIVE_ROOT" in "$HOME/Developer"|"$HOME/Developer"/*) return 1 ;; esac
  case "$ARCHIVE_ROOT" in "$STATE_DIR"|"$STATE_DIR"/*) return 1 ;; esac
}

safe_developer_target() {
  local target="$1" target_physical developer_physical
  [[ "$target" == "$HOME/Developer"/* ]] || return 1
  case "$target" in *'/../'*|*'/..'|*'/./'*|*'/.' ) return 1 ;; esac
  [[ -d "$target" && ! -L "$target" ]] || return 1
  developer_physical="$(cd "$HOME/Developer" 2>/dev/null && pwd -P)" || return 1
  target_physical="$(cd "$target" 2>/dev/null && pwd -P)" || return 1
  [[ "$target_physical" == "$developer_physical"/* ]]
}

move_with_progress() {
  local source="$1" destination="$2" total_kb done_kb percent started elapsed eta move_pid
  total_kb="$(du -sk "$source" 2>/dev/null | awk '{print $1}')"
  total_kb="${total_kb:-0}"
  info "archiving $source (about $((total_kb / 1024)) MiB)"
  started="$(date '+%s')"
  mv "$source" "$destination" &
  move_pid=$!
  while kill -0 "$move_pid" 2>/dev/null; do
    sleep 10
    kill -0 "$move_pid" 2>/dev/null || break
    done_kb="$(du -sk "$destination" 2>/dev/null | awk '{print $1}')"
    done_kb="${done_kb:-0}"
    elapsed=$(( $(date '+%s') - started ))
    if [[ "$total_kb" -gt 0 && "$done_kb" -gt 0 ]]; then
      percent=$((done_kb * 100 / total_kb)); [[ "$percent" -le 100 ]] || percent=100
      eta=$((elapsed * (total_kb - done_kb) / done_kb)); [[ "$eta" -ge 0 ]] || eta=0
      info "archive progress: ${percent}% · elapsed ${elapsed}s · estimated ${eta}s remaining"
    else
      info "archive still running · elapsed ${elapsed}s"
    fi
  done
  wait "$move_pid"
}

archive_one_path() {
  local target="$1" destination relative
  [[ -e "$target" || -L "$target" ]] || { info "already absent: $target"; return; }
  if [[ "$target" == "$HOME/Developer" ]]; then
    relative='Developer'
  else
    safe_developer_target "$target" || { err "refusing unsafe Developer target: $target"; return 1; }
    relative="Developer/${target#"$HOME/Developer/"}"
  fi
  destination="$SESSION_ROOT/$relative"
  [[ ! -e "$destination" ]] || { err "archive destination already exists: $destination"; return 1; }
  mkdir -p "$(dirname "$destination")"
  move_with_progress "$target" "$destination"
  printf '%s\tarchive\t%s\t%s\tcomplete\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$target" "$destination" >> "$SESSION_ROOT/operations.tsv"
  ok "archived $target"
}

archive_container_data() {
  local target destination
  if pgrep -f '[D]ocker' >/dev/null 2>&1 || pgrep -f '[O]rbStack' >/dev/null 2>&1; then
    err 'Quit Docker Desktop and OrbStack before archiving container data.'
    return 1
  fi
  for target in "${DAY_ONE_DOCKER_DATA_PATHS[@]}" "${DAY_ONE_ORBSTACK_DATA_PATHS[@]}"; do
    [[ -e "$target" || -L "$target" ]] || continue
    destination="$SESSION_ROOT/home/${target#"$HOME/"}"
    mkdir -p "$(dirname "$destination")"
    move_with_progress "$target" "$destination"
    printf '%s\tarchive\t%s\t%s\tcomplete\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$target" "$destination" >> "$SESSION_ROOT/operations.tsv"
    ok "archived $target"
  done
}

archive_portable_commands() {
  local command_path destination
  for command_path in "$HOME/.local/bin/day-one-mac" "$HOME/.local/bin/fresh-start"; do
    [[ -e "$command_path" || -L "$command_path" ]] || continue
    if [[ "$(basename "$command_path")" == fresh-start ]] \
       && ! grep -Fq 'day-one-mac' "$command_path" 2>/dev/null; then
      info "kept unrelated compatibility command: $command_path"
      continue
    fi
    destination="$SESSION_ROOT/commands/$(basename "$command_path")"
    mkdir -p "$(dirname "$destination")"
    mv "$command_path" "$destination"
    printf '%s\tarchive\t%s\t%s\tcomplete\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$command_path" "$destination" >> "$SESSION_ROOT/operations.tsv"
    ok "archived portable command $command_path"
  done
}

print_plan() {
  ui_title '🧭' 'Day One Mac removal plan'
  printf '  Mode: %s\n' "$MODE"
  printf '  Action: %s\n' "$([[ "$EXECUTE" == 1 ]] && printf execute || printf preview)"
  printf '  Recovery parent: %s\n' "$ARCHIVE_ROOT"
  [[ "$MODE" == sections ]] && printf '  Sections: %s\n' "${SECTIONS:-none}"
  if [[ "$MODE" == full ]] || { [[ "$MODE" == sections ]] && contains_csv "$SECTIONS" developer; }; then
    printf '  Developer: %s\n' "$DEVELOPER_MODE"
  fi
  printf '\nSafety boundaries\n'
  printf '  • non-Homebrew applications are preserved\n'
  printf '  • unrecorded Homebrew packages are preserved except in full mode\n'
  printf '  • ~/Developer is preserved unless explicitly selected\n'
  printf '  • cloud vaults and macOS Keychain contents are never silently deleted\n'
  printf '  • removal archives configuration and selected user data before moving it off the active paths\n'
  print_inventory
}

confirm_execute() {
  local answer
  [[ "$ASSUME_YES" == 1 ]] && return 0
  [[ -t 0 ]] || { err 'Execution needs an interactive terminal or --yes after review.'; return 1; }
  printf '\nType REMOVE DAY ONE MAC to execute this reviewed plan: '
  IFS= read -r answer
  [[ "$answer" == 'REMOVE DAY ONE MAC' ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --guided) GUIDED=1 ;;
    --inventory) INVENTORY_ONLY=1 ;;
    --mode) shift; [[ $# -gt 0 ]] || { err '--mode needs a value'; exit 2; }; MODE="$1" ;;
    --sections) shift; [[ $# -gt 0 ]] || { err '--sections needs a CSV value'; exit 2; }; SECTIONS="$1" ;;
    --developer) shift; [[ $# -gt 0 ]] || { err '--developer needs a value'; exit 2; }; DEVELOPER_MODE="$1" ;;
    --developer-path) shift; [[ $# -gt 0 ]] || { err '--developer-path needs a path'; exit 2; }; DEVELOPER_SELECTIONS="${DEVELOPER_SELECTIONS}${DEVELOPER_SELECTIONS:+$'\n'}$1" ;;
    --archive-root) shift; [[ $# -gt 0 ]] || { err '--archive-root needs a path'; exit 2; }; ARCHIVE_ROOT="$1" ;;
    --zap-cask-data) FULL_ZAP=1 ;;
    --archive-docker-data) FULL_DOCKER=1 ;;
    --archive-orbstack-data) FULL_ORBSTACK=1 ;;
    --archive-1password-data) FULL_1PASSWORD=1 ;;
    --archive-ssh-private-keys) FULL_SSH=1 ;;
    --prepare-keychain-reset) FULL_KEYCHAIN=1 ;;
    --execute) EXECUTE=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$(uname -s)" == Darwin ]] || { err 'This removal tool supports macOS only.'; exit 1; }
[[ "$HOME" == /* && "$HOME" != / && "$HOME" != /Users ]] || { err "Unsafe HOME: $HOME"; exit 1; }

if [[ "$INVENTORY_ONLY" == 1 ]]; then print_inventory; exit 0; fi
if [[ "$GUIDED" == 1 || -z "$MODE" ]]; then guided_choices; fi
case "$MODE" in preview|recorded|sections|full) ;; *) err "invalid mode: $MODE"; exit 2 ;; esac
if [[ "$MODE" == sections ]]; then
  old_ifs="$IFS"; IFS=','
  for section in $SECTIONS; do
    case "$section" in packages|config|dotfiles|macos|containers|developer|state) ;; *) err "unknown section: $section"; exit 2 ;; esac
  done
  IFS="$old_ifs"
fi
case "$DEVELOPER_MODE" in keep|setup-repo|selected|all) ;; *) err "invalid Developer mode: $DEVELOPER_MODE"; exit 2 ;; esac
if [[ "$MODE" == full && "$DEVELOPER_MODE" != keep && "$DEVELOPER_MODE" != all ]]; then
  err 'Full mode supports --developer keep or --developer all. Use sectional mode for individual paths.'
  exit 2
fi
if [[ "$MODE" == sections ]] && contains_csv "$SECTIONS" developer \
   && [[ "$DEVELOPER_MODE" == selected && -z "$DEVELOPER_SELECTIONS" ]]; then
  err 'Developer mode selected needs at least one --developer-path or wizard selection.'
  exit 2
fi

print_plan
[[ "$MODE" != preview && "$EXECUTE" == 1 ]] || {
  printf '\nPreview only. Rerun with --execute after reviewing the inventory and plan.\n'
  exit 0
}
safe_archive_root || { err 'Recovery parent must be an existing absolute path outside ~/Developer.'; exit 2; }
confirm_execute || { err 'Confirmation did not match; nothing changed.'; exit 10; }

SESSION_ROOT="$ARCHIVE_ROOT/Day-One-Mac-Removal-$STAMP"
[[ ! -e "$SESSION_ROOT" ]] || { err "Recovery session already exists: $SESSION_ROOT"; exit 1; }
mkdir -p "$SESSION_ROOT"
chmod 700 "$SESSION_ROOT"
: > "$SESSION_ROOT/operations.tsv"
chmod 600 "$SESSION_ROOT/operations.tsv"
{
  printf '# Day One Mac removal\n\n'
  printf -- '- Started: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf -- '- Mode: `%s`\n' "$MODE"
  printf -- '- Sections: `%s`\n' "${SECTIONS:-all owned by selected mode}"
  printf -- '- Developer choice: `%s`\n' "$DEVELOPER_MODE"
  printf -- '- Non-Homebrew applications: preserved\n'
  printf -- '- Cloud vault and Keychain contents: preserved\n'
} > "$SESSION_ROOT/README.md"

if [[ "$MODE" == full ]]; then
  args=(--execute --yes --archive-root "$SESSION_ROOT")
  [[ "$FULL_ZAP" == 1 ]] && args+=(--zap-cask-data)
  [[ "$DEVELOPER_MODE" == all ]] && args+=(--archive-projects)
  [[ "$FULL_DOCKER" == 1 ]] && args+=(--archive-docker-data)
  [[ "$FULL_ORBSTACK" == 1 ]] && args+=(--archive-orbstack-data)
  [[ "$FULL_1PASSWORD" == 1 ]] && args+=(--archive-1password-data)
  [[ "$FULL_SSH" == 1 ]] && args+=(--archive-ssh-private-keys)
  [[ "$FULL_KEYCHAIN" == 1 ]] && args+=(--prepare-keychain-reset)
  cd "$HOME"
  "$CLEAN_SCRIPT" "${args[@]}"
  ok 'full development reset completed through the broad cleanup engine'
  info "Recovery session: $SESSION_ROOT"
  exit 0
fi

if [[ "$MODE" == recorded ]] || { [[ "$MODE" == sections ]] && contains_csv "$SECTIONS" macos; }; then
  if [[ -d "$STATE_DIR/macos-settings" ]]; then
    "$SETTINGS_SCRIPT" --restore --yes
  else
    info 'no captured macOS preference values need restoration'
  fi
fi

if [[ "$MODE" == sections ]] && contains_csv "$SECTIONS" containers; then archive_container_data; fi

rollback_needed=0
rollback_args=(--execute --yes --archive-root "$SESSION_ROOT")
if [[ "$MODE" == recorded ]]; then
  rollback_args+=(--all-recorded)
  rollback_needed=1
else
  if contains_csv "$SECTIONS" packages; then rollback_needed=1; else rollback_args+=(--skip-packages); fi
  if contains_csv "$SECTIONS" config; then rollback_needed=1; else rollback_args+=(--skip-paths); fi
  if contains_csv "$SECTIONS" dotfiles; then rollback_args+=(--include-dotfiles-source); rollback_needed=1; fi
  if contains_csv "$SECTIONS" state; then rollback_args+=(--purge-state); rollback_needed=1; fi
fi
if [[ "$rollback_needed" == 1 ]]; then "$ROLLBACK_SCRIPT" "${rollback_args[@]}"; fi
if [[ "$MODE" == recorded ]] \
   || { [[ "$MODE" == sections ]] && contains_csv "$SECTIONS" state; }; then
  archive_portable_commands
fi

if [[ "$MODE" == sections ]] && contains_csv "$SECTIONS" developer; then
  cd "$HOME"
  case "$DEVELOPER_MODE" in
    keep) info '~/Developer was kept' ;;
    all) archive_one_path "$HOME/Developer" ;;
    setup-repo)
      setup_repo="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
      safe_developer_target "$setup_repo" || { err 'The current setup repository is not safely below ~/Developer.'; exit 1; }
      archive_one_path "$setup_repo"
      ;;
    selected)
      while IFS= read -r target; do [[ -n "$target" ]] && archive_one_path "$target"; done <<<"$DEVELOPER_SELECTIONS"
      ;;
  esac
fi

{
  printf '\n## Completion\n\n'
  printf -- '- Completed: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf -- '- Operation log: `operations.tsv`\n'
  printf -- '- Review any nested recovery directories created by the rollback engine.\n'
} >> "$SESSION_ROOT/README.md"
ok 'selected removal completed'
info "Recovery session: $SESSION_ROOT"
warn 'Restart Terminal. If ~/Developer moved, the current parent shell may still point to its former location; run cd "$HOME".'
