#!/usr/bin/env bash
# Reversibly remove changes recorded by scripts/setup.sh.
# Preview is the default. Compatible with macOS Bash 3.2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
INSTALL_MANIFEST="$STATE_DIR/install-manifest.tsv"
PATH_MANIFEST="$STATE_DIR/path-manifest.tsv"
ORIGINALS_DIR="$STATE_DIR/originals"

EXECUTE=0
ASSUME_YES=0
INCLUDE_DOTFILES_SOURCE=0
REMOVE_HOMEBREW=0
PURGE_STATE=0
PROCESS_RECORDED_PACKAGES=1
PROCESS_RECORDED_PATHS=1
ARCHIVE_ROOT="${DAY_ONE_MAC_CLEANUP_ARCHIVE_ROOT:-${FRESH_START_CLEANUP_ARCHIVE_ROOT:-$HOME}}"
STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
ARCHIVE_DIR="$ARCHIVE_ROOT/Day-One-Mac-Recovery-$STAMP"
LOG_FILE=""
FOLLOW_UP_FILE=""

usage() {
  cat <<'EOF'
Usage: ./rollback-recorded-setup.sh [options]

Default behavior is a read-only preview.

  --execute                    perform the reviewed cleanup
  --yes                        skip the ordinary final confirmation
  --all-recorded               include dotfiles source, Homebrew (if this run
                               installed it), and saved day-one-mac state
  --include-dotfiles-source    archive managed targets and chezmoi source
  --remove-homebrew            run Homebrew's official uninstaller only when
                               day-one-mac installed it and no unrecorded
                               formulae or casks remain
  --purge-state                archive and remove day-one-mac state last
  --skip-packages              keep all recorded Homebrew formulae and casks
  --skip-paths                 keep recorded files and directories unchanged
  --archive-root PATH          recovery-directory parent (default: $HOME)
  -h, --help                   show this help

The script never erases or formats a drive, recursively deletes ~/Developer or
the home directory, or deletes database/container volumes. Current
configuration is archived before recorded files are removed or restored.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }

manifest_owns_brew_item() {
  local kind="$1" token="$2"
  awk -F '\t' -v kind="$kind" -v token="$token" '
    $2 == token && ((kind == "formula" && ($1 == "brew-formula" || $1 == "brew-dependency")) ||
                    (kind == "cask" && $1 == "brew-cask")) { found=1 }
    END { exit !found }
  ' "$INSTALL_MANIFEST" 2>/dev/null
}

list_unrecorded_brew_items() {
  local token
  have brew || return 0
  while IFS= read -r token; do
    [[ -n "$token" ]] || continue
    manifest_owns_brew_item formula "$token" || printf 'formula:%s\n' "$token"
  done < <(brew list --formula 2>/dev/null || true)
  while IFS= read -r token; do
    [[ -n "$token" ]] || continue
    manifest_owns_brew_item cask "$token" || printf 'cask:%s\n' "$token"
  done < <(brew list --cask 2>/dev/null || true)
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute) EXECUTE=1 ;;
    --yes) ASSUME_YES=1 ;;
    --all-recorded) INCLUDE_DOTFILES_SOURCE=1; REMOVE_HOMEBREW=1; PURGE_STATE=1 ;;
    --include-dotfiles-source) INCLUDE_DOTFILES_SOURCE=1 ;;
    --remove-homebrew) REMOVE_HOMEBREW=1 ;;
    --purge-state) PURGE_STATE=1 ;;
    --skip-packages) PROCESS_RECORDED_PACKAGES=0 ;;
    --skip-paths) PROCESS_RECORDED_PATHS=0 ;;
    --archive-root)
      shift
      [[ $# -gt 0 ]] || { err "--archive-root needs a path"; exit 2; }
      ARCHIVE_ROOT="$1"
      ARCHIVE_DIR="$ARCHIVE_ROOT/Day-One-Mac-Recovery-$STAMP"
      ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$(uname -s)" == Darwin ]] || { err "This cleanup supports macOS only."; exit 1; }
[[ "$HOME" == /* && "$HOME" != / && "$HOME" != /Users ]] \
  || { err "Unsafe HOME value: $HOME"; exit 1; }
[[ "$STATE_DIR" == "$HOME"/* && "$STATE_DIR" != "$HOME" ]] \
  || { err "State directory must be a specific path beneath HOME: $STATE_DIR"; exit 1; }
[[ "$ARCHIVE_ROOT" == /* && "$ARCHIVE_ROOT" != "$STATE_DIR" && "$ARCHIVE_ROOT" != "$STATE_DIR"/* ]] \
  || { err "Recovery archive must be an absolute path outside day-one-mac state: $ARCHIVE_ROOT"; exit 1; }
[[ -f "$INSTALL_MANIFEST" || -f "$PATH_MANIFEST" ]] || {
  err "No day-one-mac manifest exists at $STATE_DIR."
  err "Refusing to guess which packages or files belong to the playbook."
  exit 1
}

print_command() {
  local arg
  printf '  $'
  for arg in "$@"; do printf ' %q' "$arg"; done
  printf '\n'
}

log() {
  [[ "$EXECUTE" == 1 && -n "$LOG_FILE" ]] || return 0
  printf '%s\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >> "$LOG_FILE"
}

run() {
  if [[ "$EXECUTE" != 1 ]]; then print_command "$@"; return 0; fi
  log "RUN $(printf '%q ' "$@")"
  "$@"
}

confirm_execute() {
  local answer
  [[ "$ASSUME_YES" == 1 ]] && return 0
  [[ -t 0 ]] || { err "Execution confirmation needs a terminal, or pass --yes after reviewing."; return 1; }
  printf 'Type CLEAN DAY ONE MAC to execute this reviewed plan: '
  IFS= read -r answer
  [[ "$answer" == 'CLEAN DAY ONE MAC' ]]
}

safe_home_target() {
  local target="$1" parent
  case "$target" in *'/../'*|*'/..'|*'/./'*) return 1 ;; esac
  [[ "$target" == "$HOME"/* && "$target" != "$HOME/Developer" && "$target" != "$STATE_DIR" ]] || return 1
  parent="$(dirname "$target")"
  while [[ "$parent" == "$HOME"/* && "$parent" != "$HOME" ]]; do
    [[ ! -L "$parent" ]] || return 1
    parent="$(dirname "$parent")"
  done
}

archive_destination() {
  local target="$1" relative
  relative="${target#"$HOME"/}"
  printf '%s/current/%s\n' "$ARCHIVE_DIR" "$relative"
}

archive_current_path() {
  local target="$1" destination
  [[ -e "$target" || -L "$target" ]] || return 0
  safe_home_target "$target" || { warn "refusing broad or external target: $target"; return 1; }
  destination="$(archive_destination "$target")"
  if [[ "$EXECUTE" != 1 ]]; then
    info "would archive current $target to $destination"
    return 0
  fi
  mkdir -p "$(dirname "$destination")"
  if [[ -e "$destination" || -L "$destination" ]]; then
    destination="$destination.$(date '+%s')"
  fi
  mv "$target" "$destination"
  log "ARCHIVE $target -> $destination"
}

restore_original_path() {
  local target="$1" backup="$2"
  safe_home_target "$target" || { warn "refusing broad, external or symlink-traversing target: $target"; return 1; }
  [[ "$backup" == "$ORIGINALS_DIR"/* ]] || { warn "recorded original is outside the trusted backup directory: $backup"; return 1; }
  [[ -e "$backup" || -L "$backup" ]] || { warn "recorded original is missing: $backup"; return 1; }
  if [[ "$EXECUTE" != 1 ]]; then
    info "would restore original $target from $backup"
    return 0
  fi
  mkdir -p "$(dirname "$target")"
  cp -pR "$backup" "$target"
  log "RESTORE $backup -> $target"
}

print_plan() {
  local kind token action target backup unrecorded_brew
  ui_title '↩️' 'Day One Mac rollback plan'
  printf '  Mode: %s\n' "$([[ "$EXECUTE" == 1 ]] && printf execute || printf preview)"
  printf '  State: %s\n' "$STATE_DIR"
  printf '  Recovery archive: %s\n\n' "$ARCHIVE_DIR"

  printf 'Recorded Homebrew changes\n'
  if [[ "$PROCESS_RECORDED_PACKAGES" != 1 ]]; then
    printf '  KEEP: package removal was not selected\n'
  elif [[ -s "$INSTALL_MANIFEST" ]]; then
    while IFS=$'\t' read -r kind token; do
      case "$kind" in
        brew-formula) printf '  uninstall formula: %s\n' "$token" ;;
        brew-dependency) printf '  uninstall if now unused: %s\n' "$token" ;;
        brew-cask) printf '  uninstall cask:    %s\n' "$token" ;;
        component) printf '  installed component: %s\n' "$token" ;;
      esac
    done < "$INSTALL_MANIFEST"
  else
    printf '  (none recorded)\n'
  fi

  printf '\nRecorded paths\n'
  if [[ "$PROCESS_RECORDED_PATHS" != 1 ]]; then
    printf '  KEEP: recorded configuration rollback was not selected\n'
  elif [[ -s "$PATH_MANIFEST" ]]; then
    while IFS=$'\t' read -r action target backup; do
      case "$action" in
        created) printf '  archive created file: %s\n' "$target" ;;
        modified) printf '  archive current + restore original: %s\n' "$target" ;;
        created-dir) printf '  remove only if empty: %s\n' "$target" ;;
      esac
    done < "$PATH_MANIFEST"
  else
    printf '  (none recorded)\n'
  fi

  [[ "$INCLUDE_DOTFILES_SOURCE" == 1 ]] && printf '\n  EXTRA: archive chezmoi-managed targets and its source\n'
  if [[ "$INCLUDE_DOTFILES_SOURCE" == 1 ]] && have chezmoi; then
    printf '  chezmoi source: %s\n' "$(chezmoi source-path 2>/dev/null || printf 'unavailable')"
    while IFS= read -r target; do
      [[ -n "$target" ]] && printf '  archive managed target: %s\n' "$target"
    done < <(chezmoi managed -p absolute 2>/dev/null || true)
  fi
  if [[ "$REMOVE_HOMEBREW" == 1 ]]; then
    printf '  EXTRA: remove Homebrew only if recorded as installed by day-one-mac\n'
    unrecorded_brew="$(list_unrecorded_brew_items || true)"
    if [[ -n "$unrecorded_brew" ]]; then
      printf '  PRESERVE Homebrew while these unrecorded packages remain:\n'
      while IFS= read -r token; do printf '    %s\n' "$token"; done <<<"$unrecorded_brew"
    fi
  fi
  [[ "$PURGE_STATE" == 1 ]] && printf '  EXTRA: archive day-one-mac state after cleanup\n'
  printf '\nNever automated: macOS rollback, Command Line Tools removal, FileVault changes,\n'
  printf '1Password account/key deletion, ~/Developer recursive removal, or database volumes.\n'
}

print_plan
[[ "$EXECUTE" == 1 ]] || {
  printf '\nPreview only. Rerun with --execute after reviewing every line.\n'
  exit 0
}
confirm_execute || { err "confirmation did not match; nothing changed"; exit 10; }

[[ ! -e "$ARCHIVE_DIR" ]] || { err "Recovery archive already exists: $ARCHIVE_DIR"; exit 1; }

mkdir -p "$ARCHIVE_DIR"
chmod 700 "$ARCHIVE_DIR"
LOG_FILE="$ARCHIVE_DIR/cleanup.log"
: > "$LOG_FILE"
chmod 600 "$LOG_FILE"
FOLLOW_UP_FILE="$ARCHIVE_DIR/manual-follow-up.md"
{
  printf '# Day One Mac cleanup: manual system decisions\n\n'
  printf 'The development files and packages in the manifests were processed.\n'
  printf 'The following are intentionally not automated because they are system,\n'
  printf 'security, credential, or project-data decisions:\n\n'
  printf -- '- macOS updates cannot be rolled back by this playbook.\n'
  printf -- '- Keep Command Line Tools, or remove them only through a separately reviewed Apple-supported process.\n'
  printf -- '- To turn off FileVault, use System Settings and wait for decryption to complete.\n'
  printf -- '- Disable the 1Password SSH agent/CLI integration in 1Password if no longer wanted; account and key data was not deleted.\n'
  printf -- '- Remove database/container volumes only from the owning project after checking their backups.\n'
  printf -- '- Non-empty directories under `~/Developer` were preserved.\n'
} > "$FOLLOW_UP_FILE"
chmod 600 "$FOLLOW_UP_FILE"
cp "$INSTALL_MANIFEST" "$ARCHIVE_DIR/install-manifest.tsv" 2>/dev/null || true
cp "$PATH_MANIFEST" "$ARCHIVE_DIR/path-manifest.tsv" 2>/dev/null || true
log "START cleanup"

if [[ "$PROCESS_RECORDED_PACKAGES" == 1 ]] \
   && have brew \
   && grep -Eq '^brew-(formula|cask)[[:space:]]' "$INSTALL_MANIFEST" 2>/dev/null; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file="$ARCHIVE_DIR/Brewfile.before-cleanup" --force >/dev/null 2>&1 \
    || warn "could not create the optional pre-cleanup Brewfile snapshot"
fi

if [[ "$INCLUDE_DOTFILES_SOURCE" == 1 ]] && have chezmoi; then
  managed_list="$ARCHIVE_DIR/chezmoi-managed.txt"
  chezmoi managed -p absolute > "$managed_list" 2>/dev/null || : > "$managed_list"
  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    if [[ -f "$target" || -L "$target" ]]; then archive_current_path "$target" || true; fi
  done < "$managed_list"
fi

if [[ "$PROCESS_RECORDED_PATHS" == 1 && -s "$PATH_MANIFEST" ]]; then
  while IFS=$'\t' read -r action target backup; do
    case "$action" in
      created)
        archive_current_path "$target" || true
        ;;
      modified)
        archive_current_path "$target" || true
        restore_original_path "$target" "$backup" || true
        ;;
    esac
  done < "$PATH_MANIFEST"
  # Child files must move first. Then remove recorded directories from the
  # deepest/latest entry upward, and only while they are empty.
  while IFS=$'\t' read -r action target backup; do
    [[ "$action" == created-dir ]] || continue
    if [[ "$target" != "$HOME/Developer" ]] && ! safe_home_target "$target"; then
      warn "kept unsafe or external recorded directory: $target"
    elif [[ -d "$target" ]]; then
      if rmdir "$target" 2>/dev/null; then log "RMDIR $target"; ok "removed empty directory $target"
      else info "kept non-empty directory $target"; fi
    fi
  done < <(tail -r "$PATH_MANIFEST")
fi

if [[ "$INCLUDE_DOTFILES_SOURCE" == 1 ]] && have chezmoi; then
  source_path="$(chezmoi source-path 2>/dev/null || true)"
  if safe_home_target "$source_path" && [[ -d "$source_path" ]]; then
    source_destination="$ARCHIVE_DIR/chezmoi-source"
    mv "$source_path" "$source_destination"
    log "ARCHIVE $source_path -> $source_destination"
    ok "archived chezmoi source"
  else
    warn "chezmoi source is absent or outside HOME; it was not moved: $source_path"
  fi
fi

if [[ "$PROCESS_RECORDED_PACKAGES" == 1 ]] && have brew && [[ -s "$INSTALL_MANIFEST" ]]; then
  while IFS=$'\t' read -r kind token; do
    [[ "$kind" == brew-cask ]] || continue
    if brew list --cask "$token" >/dev/null 2>&1; then
      run brew uninstall --cask "$token" || warn "kept cask $token because Homebrew refused its removal"
    fi
  done < "$INSTALL_MANIFEST"
  while IFS=$'\t' read -r kind token; do
    [[ "$kind" == brew-formula ]] || continue
    if brew list --formula "$token" >/dev/null 2>&1; then
      run brew uninstall --formula "$token" || warn "kept formula $token because another installed package may need it"
    fi
  done < "$INSTALL_MANIFEST"
  # Dependencies are ownership-tracked separately and removed only when no
  # currently installed formula uses them. Reverse order handles most chains.
  while IFS=$'\t' read -r kind token; do
    [[ "$kind" == brew-dependency ]] || continue
    if brew list --formula "$token" >/dev/null 2>&1; then
      if [[ -z "$(brew uses --installed "$token" 2>/dev/null)" ]]; then
        run brew uninstall --formula "$token" || warn "kept dependency $token because Homebrew refused its removal"
      else
        info "kept dependency $token because an installed formula uses it"
      fi
    fi
  done < <(tail -r "$INSTALL_MANIFEST")
fi

if [[ "$REMOVE_HOMEBREW" == 1 && "$PROCESS_RECORDED_PACKAGES" != 1 ]]; then
  warn "Homebrew cannot be removed while recorded packages are being kept."
elif [[ "$REMOVE_HOMEBREW" == 1 ]]; then
  if grep -Fqx $'component\thomebrew' "$INSTALL_MANIFEST" 2>/dev/null; then
    if have brew; then
      unrecorded_brew="$(list_unrecorded_brew_items || true)"
      if [[ -n "$unrecorded_brew" ]]; then
        warn "Homebrew now contains packages outside the day-one-mac manifest; leaving Homebrew installed."
        log "KEEP Homebrew because unrecorded packages remain: $(printf '%s' "$unrecorded_brew" | tr '\n' ' ')"
      else
        warn "Starting Homebrew's official interactive uninstaller. Review its own plan."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
        log "UNINSTALL Homebrew official script completed"
      fi
    fi
  else
    warn "Homebrew was not recorded as installed by day-one-mac; leaving it in place."
  fi
fi

if [[ "$PURGE_STATE" == 1 && -d "$STATE_DIR" ]]; then
  mv "$STATE_DIR" "$ARCHIVE_DIR/day-one-mac-state"
  log "ARCHIVE state -> $ARCHIVE_DIR/day-one-mac-state"
fi

log "PASS cleanup"
ok "cleanup complete"
info "Recovery archive: $ARCHIVE_DIR"
info "Log: $LOG_FILE"
info "Manual system decisions: $FOLLOW_UP_FILE"
warn "Database/container volumes were not removed; use their project-specific compose cleanup if required."
