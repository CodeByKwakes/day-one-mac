#!/usr/bin/env bash
# Preview and remove the development environment without erasing macOS.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/container-data-paths.sh"
source "$SCRIPT_DIR/lib/rebuildable-paths.sh"

EXECUTE=0
BACKUP_ONLY=0
ASSUME_YES=0
ZAP_CASK_DATA=0
ARCHIVE_PROJECTS=0
ARCHIVE_DOCKER_DATA=0
ARCHIVE_ORBSTACK_DATA=0
ARCHIVE_1PASSWORD_DATA=0
ARCHIVE_SSH_PRIVATE_KEYS=0
ARCHIVE_REBUILDABLE_CACHES=0
PREPARE_KEYCHAIN_RESET=0
ARCHIVE_ROOT="${DAY_ONE_MAC_CLEAN_ARCHIVE_ROOT:-${FRESH_CLEAN_ARCHIVE_ROOT:-$HOME}}"
STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
ARCHIVE_DIR=""
LOG_FILE=""
OPERATIONS_FILE=""
RESULT_FILE=""
IN_PROGRESS_FILE=""
RESUME_SNAPSHOT=""
RESUME_CLEANUP=""
RESUME_ADDITIONS_DIR=""
RESUME_OPERATIONS_BOUNDARY=0
CASK_FAILURES=0
SKIPPED_TRANSIENT_ITEMS_FILE=""
TRANSIENT_SKIP_COUNT=0
ADMIN_READ_COPY_COUNT=0
ARCHIVE_INITIALIZED=0
ARCHIVE_COMPLETE=0
ACTIVE_COPY_PID=""
CHECKSUM_LOCK_OWNED=0
ARCHIVE_TOTAL_ITEMS=0
ARCHIVE_CURRENT_ITEM=0
ARCHIVE_TOTAL_KB=0
ARCHIVE_COMPLETED_KB=0
ARCHIVE_PROGRESS_STARTED_AT=0
COPY_HEARTBEAT_SECONDS="${DAY_ONE_MAC_COPY_HEARTBEAT_SECONDS:-30}"
COPY_STALL_SECONDS="${DAY_ONE_MAC_COPY_STALL_SECONDS:-300}"
CHECKSUM_BATCH_SIZE="${DAY_ONE_MAC_CHECKSUM_BATCH_SIZE:-128}"

usage() {
  cat <<'EOF'
Usage: ./clean-development-state.sh [options]

Default behavior is a read-only inventory and preview. The execution removes
all Homebrew formulae, all Homebrew casks, and Homebrew itself; it also moves
known development configuration into a timestamped recovery archive.

  --execute                 perform the reviewed cleanup
  --backup-only             copy the selected recovery scope without removing
                            packages, applications, settings, or source files
  --yes                     skip the typed confirmation
  --archive-root PATH       recovery parent; must already exist
  --zap-cask-data           also ask Homebrew to remove each cask's declared
                            support files; may include real application data
  --archive-projects        include ~/Developer (copy in backup-only; otherwise move)
  --archive-docker-data     include known Docker Desktop data (copy or move)
  --archive-orbstack-data   include known OrbStack data (copy or move)
  --archive-container-data  compatibility alias that selects both options above
  --archive-1password-data  include known local 1Password data (copy or move) and
                            write cloud vault/key deletion steps
  --archive-ssh-private-keys
                            include detected private keys and matching .pub files
                            from ~/.ssh into recovery
  --archive-rebuildable-caches
                            with --backup-only, also copy downloaded runtimes,
                            package caches, pnpm store and full VS Code local data
  --prepare-keychain-reset  add Apple's manual login-Keychain reset procedure
                            to the recovery report; never resets it silently
  --result-file ABS_PATH    with --backup-only, write the completed snapshot
                            path here for the Stage 0 progress tracker
  --in-progress-file ABS_PATH
                            with --backup-only, record an interrupted snapshot
                            so its checksum pass can be resumed safely
  --resume-snapshot ABS_PATH
                            resume checksums for a copy-complete snapshot created
                            by an earlier interrupted backup-only run
  --resume-cleanup ABS_PATH resume an INCOMPLETE.md cleanup recovery directory;
                            requires --execute and the original archive flags
  -h, --help                show this help

Never touched: the startup disk, macOS, the user account, FileVault, Command
Line Tools, or applications not installed by Homebrew. Backup-only mode never
removes source data. During cleanup, projects, container data, local 1Password
data, and SSH private keys remain in place unless their explicit archive flags
are supplied. Cloud vault deletion and the macOS Keychain reset are always
manual, even when their reporting options are used.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }

discover_homebrew() {
  local candidate candidate_dir
  have brew && return 0
  # Test suites can isolate themselves from a developer workstation's real
  # Homebrew installation. Normal users never need to set this variable.
  [[ "${DAY_ONE_MAC_DISABLE_BREW_DISCOVERY:-0}" == 1 ]] && return 1
  for candidate in "${DAY_ONE_MAC_BREW_PATH:-}" /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    candidate_dir="$(dirname "$candidate")"
    PATH="$candidate_dir:$PATH"
    export PATH
    hash -r 2>/dev/null || true
    have brew && {
      info "rediscovered Homebrew after shell settings were archived: $candidate"
      return 0
    }
  done
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute) EXECUTE=1 ;;
    --backup-only) BACKUP_ONLY=1; EXECUTE=1 ;;
    --yes) ASSUME_YES=1 ;;
    --zap-cask-data) ZAP_CASK_DATA=1 ;;
    --archive-projects) ARCHIVE_PROJECTS=1 ;;
    --archive-docker-data) ARCHIVE_DOCKER_DATA=1 ;;
    --archive-orbstack-data) ARCHIVE_ORBSTACK_DATA=1 ;;
    --archive-container-data) ARCHIVE_DOCKER_DATA=1; ARCHIVE_ORBSTACK_DATA=1 ;;
    --archive-1password-data) ARCHIVE_1PASSWORD_DATA=1 ;;
    --archive-ssh-private-keys) ARCHIVE_SSH_PRIVATE_KEYS=1 ;;
    --archive-rebuildable-caches) ARCHIVE_REBUILDABLE_CACHES=1 ;;
    --prepare-keychain-reset) PREPARE_KEYCHAIN_RESET=1 ;;
    --archive-root)
      shift
      [[ $# -gt 0 ]] || { err "--archive-root needs a path"; exit 2; }
      ARCHIVE_ROOT="$1"
      ;;
    --result-file)
      shift
      [[ $# -gt 0 ]] || { err "--result-file needs a path"; exit 2; }
      RESULT_FILE="$1"
      ;;
    --in-progress-file)
      shift
      [[ $# -gt 0 ]] || { err "--in-progress-file needs a path"; exit 2; }
      IN_PROGRESS_FILE="$1"
      ;;
    --resume-snapshot)
      shift
      [[ $# -gt 0 ]] || { err "--resume-snapshot needs a path"; exit 2; }
      RESUME_SNAPSHOT="$1"
      ;;
    --resume-cleanup)
      shift
      [[ $# -gt 0 ]] || { err "--resume-cleanup needs a path"; exit 2; }
      RESUME_CLEANUP="$1"
      ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$(uname -s)" == Darwin ]] || { err "This cleanup supports macOS only."; exit 1; }
[[ "$HOME" == /* && "$HOME" != / && "$HOME" != /Users && "$HOME" != /tmp && "$HOME" != /private/tmp ]] \
  || { err "Unsafe HOME value: $HOME"; exit 1; }
[[ "$ARCHIVE_ROOT" == /* ]] || { err "--archive-root must be an absolute path"; exit 2; }
[[ "$ARCHIVE_ROOT" != / && "$ARCHIVE_ROOT" != /Users ]] || { err "Recovery parent is too broad: $ARCHIVE_ROOT"; exit 2; }
[[ -z "$RESULT_FILE" || "$RESULT_FILE" == /* ]] || { err "--result-file must be an absolute path"; exit 2; }
[[ -z "$IN_PROGRESS_FILE" || "$IN_PROGRESS_FILE" == /* ]] || { err "--in-progress-file must be an absolute path"; exit 2; }
[[ -z "$RESUME_SNAPSHOT" || "$RESUME_SNAPSHOT" == /* ]] || { err "--resume-snapshot must be an absolute path"; exit 2; }
[[ -z "$RESUME_CLEANUP" || "$RESUME_CLEANUP" == /* ]] || { err "--resume-cleanup must be an absolute path"; exit 2; }
[[ "$BACKUP_ONLY" == 1 || -z "$RESULT_FILE" ]] || { err "--result-file is only valid with --backup-only"; exit 2; }
[[ "$BACKUP_ONLY" == 1 || -z "$IN_PROGRESS_FILE" ]] || { err "--in-progress-file is only valid with --backup-only"; exit 2; }
[[ "$BACKUP_ONLY" == 1 || -z "$RESUME_SNAPSHOT" ]] || { err "--resume-snapshot is only valid with --backup-only"; exit 2; }
[[ -z "$RESUME_CLEANUP" || "$BACKUP_ONLY" != 1 ]] || { err "--resume-cleanup cannot be used with --backup-only"; exit 2; }
[[ -z "$RESUME_CLEANUP" || "$EXECUTE" == 1 ]] || { err "--resume-cleanup requires --execute"; exit 2; }
[[ -z "$RESUME_CLEANUP" || -z "$RESUME_SNAPSHOT" ]] || { err "cleanup and snapshot resume modes cannot be combined"; exit 2; }
[[ "$BACKUP_ONLY" != 1 || "$ZAP_CASK_DATA" != 1 ]] || { err "--zap-cask-data cannot be used with --backup-only"; exit 2; }
case "$COPY_HEARTBEAT_SECONDS" in ''|*[!0-9]*|0) err 'DAY_ONE_MAC_COPY_HEARTBEAT_SECONDS must be a positive whole number'; exit 2 ;; esac
case "$COPY_STALL_SECONDS" in ''|*[!0-9]*|0) err 'DAY_ONE_MAC_COPY_STALL_SECONDS must be a positive whole number'; exit 2 ;; esac
case "$CHECKSUM_BATCH_SIZE" in ''|*[!0-9]*|0) err 'DAY_ONE_MAC_CHECKSUM_BATCH_SIZE must be a positive whole number'; exit 2 ;; esac
if [[ -n "$RESUME_SNAPSHOT" ]]; then
  ARCHIVE_DIR="$RESUME_SNAPSHOT"
elif [[ -n "$RESUME_CLEANUP" ]]; then
  ARCHIVE_DIR="$RESUME_CLEANUP"
  ARCHIVE_ROOT="$(dirname "$RESUME_CLEANUP")"
elif [[ "$BACKUP_ONLY" == 1 ]]; then
  ARCHIVE_DIR="$ARCHIVE_ROOT/Day-One-Mac-Backup-Snapshot-$STAMP"
else
  ARCHIVE_DIR="$ARCHIVE_ROOT/Day-One-Mac-Clean-Recovery-$STAMP"
fi
[[ "$ARCHIVE_ROOT" == /* && "$ARCHIVE_ROOT" != / && "$ARCHIVE_ROOT" != /Users ]] \
  || { err "Unsafe recovery parent: $ARCHIVE_ROOT"; exit 2; }
discover_homebrew || true

# These paths are development configuration or caches, not arbitrary home
# directories. Each existing item is copied in backup-only mode or moved into
# recovery during cleanup, never recursively deleted. Do not add credential
# stores or broad parents to this list.
DEV_PATHS=(
  "$HOME/.profile"
  "$HOME/.bash_profile"
  "$HOME/.bashrc"
  "$HOME/.bash_logout"
  "$HOME/.zprofile"
  "$HOME/.zshenv"
  "$HOME/.zshrc"
  "$HOME/.zlogin"
  "$HOME/.zlogout"
  "$HOME/.gitconfig"
  "$HOME/.gitignore_global"
  "$HOME/.ssh/config"
  "$HOME/.ssh/known_hosts"
  "$HOME/.ssh/known_hosts.old"
  "$HOME/.ssh/allowed_signers"
  "$HOME/.npmrc"
  "$HOME/Brewfile"
  "$HOME/.config/chezmoi"
  "$HOME/.config/git"
  "$HOME/.config/starship.toml"
  "$HOME/.config/zsh"
  "$HOME/.config/pnpm"
  "$HOME/.config/yarn"
  "$HOME/.config/gh"
  "$HOME/.config/mcp"
  "$HOME/.config/pypoetry"
  "$HOME/.config/gcloud"
  "$HOME/.config/1Password/ssh/agent.toml"
  "$HOME/.local/share/chezmoi"
  "$HOME/.local/bin/day-one-mac"
  "$HOME/.local/bin/fresh-start"
  "$HOME/.config/second-brain"
  "$HOME/.local/share/second-brain"
  "$HOME/.local/state/second-brain"
  "$HOME/.config/second-brain-notion"
  "$HOME/.local/share/second-brain-notion"
  "$HOME/.local/state/second-brain-notion"
  # Pre-rename Second Brain namespaces are included for complete cleanup.
  "$HOME/.config/fresh-start-second-brain"
  "$HOME/.local/share/fresh-start-second-brain"
  "$HOME/.local/state/fresh-start-second-brain"
  "$HOME/.local/bin/second-brain-report"
  "$HOME/.local/bin/second-brain-claude"
  "$HOME/.local/bin/second-brain-codex"
  "$HOME/.local/bin/second-brain-report-three"
  "$HOME/.local/bin/second-brain-claude-three"
  "$HOME/.local/bin/second-brain-codex-three"
  "$HOME/.nvm"
  "$HOME/.nodenv"
  "$HOME/.volta"
  "$HOME/.asdf"
  "$HOME/.bun"
  "$HOME/.deno"
  "$HOME/.yarn"
  "$HOME/.pyenv"
  "$HOME/.virtualenvs"
  "$HOME/.poetry"
  "$HOME/.cargo"
  "$HOME/.rustup"
  "$HOME/.rbenv"
  "$HOME/.gem"
  "$HOME/.bundle"
  "$HOME/.sdkman"
  "$HOME/.gradle"
  "$HOME/.m2"
  "$HOME/.goenv"
  "$HOME/.terraform.d"
  "$HOME/.kube"
  "$HOME/.aws"
  "$HOME/.azure"
  "$HOME/.claude"
  "$HOME/.codex"
  "$HOME/.copilot"
  "$HOME/.agents"
  "$HOME/.mcp.json"
  "$HOME/.docker"
  "$HOME/Library/Preferences/com.microsoft.VSCode.plist"
  "$HOME/.day-one-mac"
  # State created before the Day One Mac rename.
  "$HOME/.fresh-mac-setup"
)

# The active path list differs only for the copy-only safety snapshot. A normal
# Route B cleanup still moves rebuildable data into recovery, so rollback stays
# possible. The default snapshot copies the small portable VS Code User folder
# and records reinstall inventories instead of duplicating downloaded caches.
ACTIVE_DEV_PATHS=("${DEV_PATHS[@]}")
if [[ "$BACKUP_ONLY" == 1 && "$ARCHIVE_REBUILDABLE_CACHES" == 0 ]]; then
  ACTIVE_DEV_PATHS+=("${DAY_ONE_PORTABLE_VSCODE_PATHS[@]}")
else
  ACTIVE_DEV_PATHS+=("${DAY_ONE_REBUILDABLE_DEV_PATHS[@]}")
fi

ONEPASSWORD_PATHS=(
  "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password"
  "$HOME/Library/Containers/com.1password.1password"
  "$HOME/Library/Application Support/1Password"
  "$HOME/Library/Caches/com.1password.1password"
  "$HOME/Library/HTTPStorages/com.1password.1password"
  "$HOME/Library/Preferences/com.1password.1password.plist"
)

SSH_KEY_PATHS=()
SSH_KEY_COUNT=0
collect_ssh_private_keys() {
  local candidate first_line public_key
  [[ -d "$HOME/.ssh" ]] || return 0
  for candidate in "$HOME/.ssh"/*; do
    [[ -f "$candidate" || -L "$candidate" ]] || continue
    case "$(basename "$candidate")" in
      *.pub|config|known_hosts|known_hosts.old|allowed_signers|authorized_keys|environment|rc) continue ;;
    esac
    first_line="$(LC_ALL=C sed -n '1p' "$candidate" 2>/dev/null || true)"
    case "$first_line" in
      *'PRIVATE KEY'*|'PuTTY-User-Key-File:'*)
        SSH_KEY_PATHS+=("$candidate")
        SSH_KEY_COUNT=$((SSH_KEY_COUNT + 1))
        public_key="$candidate.pub"
        if [[ -e "$public_key" || -L "$public_key" ]]; then
          SSH_KEY_PATHS+=("$public_key")
          SSH_KEY_COUNT=$((SSH_KEY_COUNT + 1))
        fi
        ;;
    esac
  done
}
collect_ssh_private_keys

# Never create recovery inside a directory that this invocation will move.
# That would attempt to move the archive into itself part-way through cleanup.
selected_archive_targets=("${ACTIVE_DEV_PATHS[@]}")
[[ "$ARCHIVE_PROJECTS" == 1 ]] && selected_archive_targets+=("$HOME/Developer")
[[ "$ARCHIVE_DOCKER_DATA" == 1 ]] && selected_archive_targets+=("${DAY_ONE_DOCKER_DATA_PATHS[@]}")
[[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]] && selected_archive_targets+=("${DAY_ONE_ORBSTACK_DATA_PATHS[@]}")
[[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && selected_archive_targets+=("${ONEPASSWORD_PATHS[@]}")
if [[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 && "$SSH_KEY_COUNT" -gt 0 ]]; then
  selected_archive_targets+=("${SSH_KEY_PATHS[@]}")
fi
for selected_target in "${selected_archive_targets[@]}"; do
  case "$ARCHIVE_DIR" in
    "$selected_target"|"$selected_target"/*)
      err "Recovery directory would be inside a selected cleanup target: $selected_target"
      err "Choose an --archive-root outside that path."
      exit 2
      ;;
  esac
done

safe_home_target() {
  local target="$1" parent
  case "$target" in *'/../'*|*'/..'|*'/./'*) return 1 ;; esac
  [[ "$target" == "$HOME"/* && "$target" != "$HOME" && "$target" != "$ARCHIVE_DIR" && "$target" != "$ARCHIVE_DIR"/* ]] || return 1
  parent="$(dirname "$target")"
  while [[ "$parent" == "$HOME"/* && "$parent" != "$HOME" ]]; do
    [[ ! -L "$parent" ]] || return 1
    parent="$(dirname "$parent")"
  done
}

relative_home_path() { printf '%s\n' "${1#"$HOME"/}"; }

is_deferred_cleanup_target() {
  case "$1" in
    "$HOME/.day-one-mac"|"$HOME/.fresh-mac-setup") return 0 ;;
    *) return 1 ;;
  esac
}

print_homebrew_inventory() {
  local item found=0
  if [[ "$BACKUP_ONLY" == 1 ]]; then printf '\nHomebrew formulae recorded in the snapshot\n'
  else printf '\nHomebrew formulae to remove\n'; fi
  if have brew; then
    while IFS= read -r item; do [[ -n "$item" ]] || continue; printf '  %s\n' "$item"; found=1; done < <(brew list --formula 2>/dev/null || true)
  fi
  [[ "$found" == 1 ]] || printf '  (none)\n'

  found=0
  if [[ "$BACKUP_ONLY" == 1 ]]; then printf '\nHomebrew casks/apps recorded in the snapshot\n'
  else printf '\nHomebrew casks/apps to remove\n'; fi
  if have brew; then
    while IFS= read -r item; do [[ -n "$item" ]] || continue; printf '  %s\n' "$item"; found=1; done < <(brew list --cask 2>/dev/null || true)
  fi
  [[ "$found" == 1 ]] || printf '  (none)\n'

  found=0
  if [[ "$BACKUP_ONLY" == 1 ]]; then printf '\nHomebrew taps recorded in the snapshot\n'
  else printf '\nHomebrew taps to remove with Homebrew\n'; fi
  if have brew; then
    while IFS= read -r item; do [[ -n "$item" ]] || continue; printf '  %s\n' "$item"; found=1; done < <(brew tap 2>/dev/null || true)
  fi
  [[ "$found" == 1 ]] || printf '  (none)\n'
}

print_application_inventory() {
  local root app found=0
  printf '\nAll application bundles discovered in standard locations\n'
  for root in /Applications "$HOME/Applications" /System/Applications; do
    [[ -d "$root" ]] || continue
    while IFS= read -r app; do
      [[ -n "$app" ]] || continue
      printf '  %s\n' "$app"
      found=1
    done < <(find "$root" -maxdepth 2 -type d -name '*.app' -prune 2>/dev/null | LC_ALL=C sort)
  done
  [[ "$found" == 1 ]] || printf '  (none discovered)\n'
  printf '  NOTE: Homebrew ownership is authoritative only in the cask list above.\n'
  printf '        Every non-Homebrew application bundle is preserved.\n'
}

print_path_inventory() {
  local target found=0 found_1password=0 selected_word='ARCHIVE'
  [[ "$BACKUP_ONLY" == 1 ]] && selected_word='COPY'
  printf '\nDevelopment configuration to %s\n' "$([[ "$BACKUP_ONLY" == 1 ]] && printf copy || printf archive)"
  for target in "${ACTIVE_DEV_PATHS[@]}"; do
    if [[ -e "$target" || -L "$target" ]]; then printf '  %s\n' "$target"; found=1; fi
  done
  [[ "$found" == 1 ]] || printf '  (none)\n'
  if [[ "$BACKUP_ONLY" == 1 && "$ARCHIVE_REBUILDABLE_CACHES" == 0 ]]; then
    printf '\nRebuildable downloads omitted from this portable snapshot\n'
    printf '  Package caches, downloaded runtimes, the pnpm store and installed VS Code\n'
    printf '  extensions are represented by reinstall inventories instead of copied files.\n'
    printf '  Use --archive-rebuildable-caches only when an offline byte-for-byte copy is needed.\n'
  fi

  printf '\nProtected user data\n'
  if [[ "$ARCHIVE_PROJECTS" == 1 ]]; then printf '  %s: %s\n' "$selected_word" "$HOME/Developer"
  else printf '  KEEP: %s (use --archive-projects to include it)\n' "$HOME/Developer"; fi
  printf '  KEEP: %s (knowledge-vault contents are user documents)\n' "$HOME/Vaults"
  if [[ "$ARCHIVE_DOCKER_DATA" == 1 ]]; then
    for target in "${DAY_ONE_DOCKER_DATA_PATHS[@]}"; do [[ -e "$target" || -L "$target" ]] && printf '  %s: %s\n' "$selected_word" "$target"; done
  else
    printf '  KEEP: Docker Desktop data (use --archive-docker-data to include it)\n'
  fi
  if [[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]]; then
    for target in "${DAY_ONE_ORBSTACK_DATA_PATHS[@]}"; do [[ -e "$target" || -L "$target" ]] && printf '  %s: %s\n' "$selected_word" "$target"; done
  else
    printf '  KEEP: OrbStack data (use --archive-orbstack-data to include it)\n'
  fi
  if [[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]]; then
    for target in "${ONEPASSWORD_PATHS[@]}"; do
      if [[ -e "$target" || -L "$target" ]]; then printf '  %s: %s\n' "$selected_word" "$target"; found_1password=1; fi
    done
    [[ "$found_1password" == 1 ]] || printf '  %s: no known local 1Password data paths were detected\n' "$selected_word"
    printf '  MANUAL: 1Password cloud vault/key deletion remains a provider action\n'
  else
    printf '  KEEP: local and cloud 1Password data (use --archive-1password-data for local data)\n'
  fi
  if [[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]]; then
    if [[ "$SSH_KEY_COUNT" -gt 0 ]]; then
      for target in "${SSH_KEY_PATHS[@]}"; do printf '  %s: %s\n' "$selected_word" "$target"; done
    else
      printf '  %s: no SSH private keys were detected\n' "$selected_word"
    fi
  else
    printf '  KEEP: SSH private keys (use --archive-ssh-private-keys to move detected keys)\n'
  fi
  if [[ "$PREPARE_KEYCHAIN_RESET" == 1 ]]; then
    printf '  MANUAL: add Apple login-Keychain reset steps to the final report\n'
  else
    printf '  KEEP: macOS Keychain data (use --prepare-keychain-reset for reviewed manual steps)\n'
  fi
  printf '  KEEP: applications not listed by Homebrew\n'
}

confirm_execute() {
  local answer expected prompt
  [[ "$ASSUME_YES" == 1 ]] && return 0
  [[ -t 0 ]] || { err "Execution needs a terminal, or --yes after reviewing the preview."; return 1; }
  if [[ "$BACKUP_ONLY" == 1 ]]; then
    expected='CREATE BACKUP SNAPSHOT'
    prompt='Type CREATE BACKUP SNAPSHOT to copy the selected files without removing anything: '
  else
    expected='CLEAN DEVELOPMENT STATE'
    prompt='Type CLEAN DEVELOPMENT STATE to continue: '
  fi
  printf '%s' "$prompt"
  IFS= read -r answer
  [[ "$answer" == "$expected" ]]
}

confirm_sensitive_archive() {
  local answer
  [[ "$ARCHIVE_1PASSWORD_DATA" == 1 || "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]] || return 0
  [[ -t 0 ]] || {
    err "Archiving local credential material requires an interactive terminal."
    return 1
  }
  if [[ "$BACKUP_ONLY" == 1 ]]; then
    printf 'Type COPY LOCAL CREDENTIALS to confirm the selected credential copies: '
  else
    printf 'Type ARCHIVE LOCAL CREDENTIALS to confirm the selected credential moves: '
  fi
  IFS= read -r answer
  if [[ "$BACKUP_ONLY" == 1 ]]; then
    [[ "$answer" == 'COPY LOCAL CREDENTIALS' ]]
  else
    [[ "$answer" == 'ARCHIVE LOCAL CREDENTIALS' ]]
  fi
}

log() { [[ -n "$LOG_FILE" ]] && printf '%s\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >> "$LOG_FILE"; }

record_operation() {
  [[ -n "$OPERATIONS_FILE" ]] || return 0
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1" "$2" "$3" "$4" >> "$OPERATIONS_FILE"
}

resume_operation_count() {
  local range="$1" status="$2"
  [[ -s "$OPERATIONS_FILE" ]] || { printf '0\n'; return 0; }
  case "$range" in
    historical)
      awk -F '\t' -v boundary="$RESUME_OPERATIONS_BOUNDARY" -v wanted="$status" \
        'NR > 1 && NR <= boundary && $5 == wanted { count++ } END { print count + 0 }' \
        "$OPERATIONS_FILE"
      ;;
    current)
      awk -F '\t' -v boundary="$RESUME_OPERATIONS_BOUNDARY" -v wanted="$status" \
        'NR > boundary && $5 == wanted { count++ } END { print count + 0 }' \
        "$OPERATIONS_FILE"
      ;;
  esac
}

write_resume_summary_report() {
  local outcome="$1" report_file="$ARCHIVE_DIR/resume-summary.md" report_tmp
  local historical_failures current_complete current_failures
  [[ -n "$RESUME_CLEANUP" && "$RESUME_OPERATIONS_BOUNDARY" -gt 0 && -s "$OPERATIONS_FILE" ]] || return 0
  historical_failures="$(resume_operation_count historical failed)"
  current_complete="$(resume_operation_count current complete)"
  current_failures="$(resume_operation_count current failed)"
  report_tmp="$ARCHIVE_DIR/.resume-summary.$$"
  {
    printf '# Step 5 resume summary\n\n'
    printf 'Outcome: **%s**\n\n' "$outcome"
    printf 'This report separates operations recorded before this resume from the actions\n'
    printf 'performed by the latest resume attempt. The full audit trail remains in\n'
    printf '`operations.tsv`.\n\n'
    printf '## Counts\n\n'
    printf -- '- Earlier failed operations: %s\n' "$historical_failures"
    printf -- '- Operations completed by this resume: %s\n' "$current_complete"
    printf -- '- Operations failed during this resume: %s\n\n' "$current_failures"
    printf '## Earlier failures\n\n'
    if [[ "$historical_failures" -gt 0 ]]; then
      awk -F '\t' -v boundary="$RESUME_OPERATIONS_BOUNDARY" \
        'NR > 1 && NR <= boundary && $5 == "failed" { printf "- `%s` — `%s`\n", $2, $3 }' \
        "$OPERATIONS_FILE"
    else
      printf 'None recorded.\n'
    fi
    printf '\n## Completed by this resume\n\n'
    if [[ "$current_complete" -gt 0 ]]; then
      awk -F '\t' -v boundary="$RESUME_OPERATIONS_BOUNDARY" \
        'NR > boundary && $5 == "complete" { printf "- `%s` — `%s`\n", $2, $3 }' \
        "$OPERATIONS_FILE"
    else
      printf 'None recorded.\n'
    fi
    printf '\n## Failed during this resume\n\n'
    if [[ "$current_failures" -gt 0 ]]; then
      awk -F '\t' -v boundary="$RESUME_OPERATIONS_BOUNDARY" \
        'NR > boundary && $5 == "failed" { printf "- `%s` — `%s`\n", $2, $3 }' \
        "$OPERATIONS_FILE"
    else
      printf 'None recorded.\n'
    fi
  } > "$report_tmp"
  chmod 600 "$report_tmp"
  mv "$report_tmp" "$report_file"
}

print_resume_summary() {
  [[ -n "$RESUME_CLEANUP" && "$RESUME_OPERATIONS_BOUNDARY" -gt 0 ]] || return 0
  ui_section '📋' 'Step 5 resume result'
  printf '  Earlier failures retained in the audit log: %s\n' "$(resume_operation_count historical failed)"
  printf '  Completed during this resume: %s\n' "$(resume_operation_count current complete)"
  printf '  Failed during this resume: %s\n' "$(resume_operation_count current failed)"
  printf '  Readable report: %s/resume-summary.md\n' "$ARCHIVE_DIR"
}

record_skipped_transient_item() {
  local item_path="$1" item_type="$2" reason="$3"
  TRANSIENT_SKIP_COUNT=$((TRANSIENT_SKIP_COUNT + 1))
  printf -- '- `%s` — %s\n' "$item_path" "$reason" >> "$SKIPPED_TRANSIENT_ITEMS_FILE"
  log "SKIP transient $item_type $item_path ($reason)"
  record_operation "skip-transient-$item_type" "$item_path" - omitted
}

copy_error_is_permission_related() {
  local error_file="$1"
  grep -Eiq 'Permission denied|Operation not permitted' "$error_file"
}

record_admin_read_copy() {
  local source_path="$1" destination_path="$2"
  local report_file="$ARCHIVE_DIR/administrator-read-access.md"
  if [[ ! -e "$report_file" ]]; then
    {
      printf '# Administrator-assisted backup copies\n\n'
      printf 'A normal copy could not read one or more source items. Nothing was omitted.\n'
      printf 'After explicit approval, macOS administrator access was used only to read\n'
      printf 'the source and complete the exact backup destination shown below. Source\n'
      printf 'ownership, permissions, files, and Git history were not changed.\n\n'
      printf 'The copied backup data was then assigned to the current user and given owner\n'
      printf 'read/write access so that checksums and restore tests can read it.\n\n'
    } > "$report_file"
    chmod 600 "$report_file"
  fi
  printf -- '- Source: `%s`\n  Backup copy: `%s`\n\n' \
    "$source_path" "$destination_path" >> "$report_file"
  ADMIN_READ_COPY_COUNT=$((ADMIN_READ_COPY_COUNT + 1))
  log "COPY administrator-read $source_path -> $destination_path"
  record_operation copy-admin-read "$source_path" "$destination_path" complete
}

normalise_admin_copy_for_current_user() {
  local destination="$1" owner_ids
  owner_ids="$(id -u):$(id -g)"
  if [[ -L "$destination" ]]; then
    /usr/bin/sudo /usr/sbin/chown -h "$owner_ids" "$destination"
    return
  fi
  /usr/bin/sudo /usr/sbin/chown -R -P "$owner_ids" "$destination" || return 1
  /usr/bin/sudo /bin/chmod -R -P u+rwX "$destination" || return 1
}

path_size_kb() {
  local target="$1" size
  size="$(du -sk "$target" 2>/dev/null | awk 'NR == 1 { print $1 }' || true)"
  case "$size" in ''|*[!0-9]*) printf '0\n' ;; *) printf '%s\n' "$size" ;; esac
}

human_size_from_kb() {
  awk -v kb="$1" 'BEGIN {
    if (kb >= 1048576) printf "%.2f GiB", kb / 1048576;
    else if (kb >= 1024) printf "%.1f MiB", kb / 1024;
    else printf "%d KiB", kb;
  }'
}

elapsed_label() {
  local total="$1" hours minutes seconds
  hours=$((total / 3600))
  minutes=$(((total % 3600) / 60))
  seconds=$((total % 60))
  if [[ "$hours" -gt 0 ]]; then printf '%dh %02dm %02ds' "$hours" "$minutes" "$seconds"
  elif [[ "$minutes" -gt 0 ]]; then printf '%dm %02ds' "$minutes" "$seconds"
  else printf '%ds' "$seconds"; fi
}

prepare_archive_progress() {
  local target
  ARCHIVE_TOTAL_ITEMS=0
  ARCHIVE_CURRENT_ITEM=0
  ARCHIVE_TOTAL_KB="$1"
  ARCHIVE_COMPLETED_KB=0
  ARCHIVE_PROGRESS_STARTED_AT="$(date +%s)"
  for target in "${selected_archive_targets[@]}"; do
    [[ -e "$target" || -L "$target" ]] || continue
    ARCHIVE_TOTAL_ITEMS=$((ARCHIVE_TOTAL_ITEMS + 1))
  done

  ui_section '📦' 'Step 5 archive progress'
  printf '  %s existing item(s), about %s total.\n' \
    "$ARCHIVE_TOTAL_ITEMS" "$(human_size_from_kb "$ARCHIVE_TOTAL_KB")"
  printf '  Long moves report item count, bytes, percentage, elapsed time and estimated time remaining every %s seconds.\n' \
    "$COPY_HEARTBEAT_SECONDS"
  printf '  If the destination does not grow for %s, the wizard asks whether to keep waiting or stop.\n' \
    "$(elapsed_label "$COPY_STALL_SECONDS")"
}

print_archive_progress() {
  local current_kb="$1" source_kb="$2" phase="${3:-active}"
  local now elapsed credited_kb processed_kb remaining_kb percent eta_seconds
  now="$(date +%s)"
  elapsed=$((now - ARCHIVE_PROGRESS_STARTED_AT))
  credited_kb="$current_kb"
  if [[ "$source_kb" -gt 0 && "$credited_kb" -gt "$source_kb" ]]; then
    credited_kb="$source_kb"
  fi
  processed_kb=$((ARCHIVE_COMPLETED_KB + credited_kb))
  if [[ "$phase" == complete && "$ARCHIVE_CURRENT_ITEM" -ge "$ARCHIVE_TOTAL_ITEMS" ]]; then
    processed_kb="$ARCHIVE_TOTAL_KB"
  elif [[ "$ARCHIVE_TOTAL_KB" -gt 0 && "$processed_kb" -gt "$ARCHIVE_TOTAL_KB" ]]; then
    processed_kb="$ARCHIVE_TOTAL_KB"
  fi

  if [[ "$ARCHIVE_TOTAL_KB" -gt 0 ]]; then
    remaining_kb=$((ARCHIVE_TOTAL_KB - processed_kb))
    percent="$(awk -v done="$processed_kb" -v total="$ARCHIVE_TOTAL_KB" \
      'BEGIN { if (total > 0) printf "%.1f", done * 100 / total; else printf "100.0" }')"
    if [[ "$remaining_kb" -le 0 ]]; then
      info "archive progress: item $ARCHIVE_CURRENT_ITEM/$ARCHIVE_TOTAL_ITEMS · $(human_size_from_kb "$processed_kb")/$(human_size_from_kb "$ARCHIVE_TOTAL_KB") ($percent%%) · $(elapsed_label "$elapsed") elapsed · complete"
    elif [[ "$processed_kb" -gt 0 && "$elapsed" -gt 0 ]]; then
      eta_seconds=$((remaining_kb * elapsed / processed_kb))
      info "archive progress: item $ARCHIVE_CURRENT_ITEM/$ARCHIVE_TOTAL_ITEMS · $(human_size_from_kb "$processed_kb")/$(human_size_from_kb "$ARCHIVE_TOTAL_KB") ($percent%%) · $(elapsed_label "$elapsed") elapsed · about $(elapsed_label "$eta_seconds") remaining"
    else
      info "archive progress: item $ARCHIVE_CURRENT_ITEM/$ARCHIVE_TOTAL_ITEMS · $(human_size_from_kb "$processed_kb")/$(human_size_from_kb "$ARCHIVE_TOTAL_KB") ($percent%%) · $(elapsed_label "$elapsed") elapsed · estimating time remaining"
    fi
  else
    info "archive progress: item $ARCHIVE_CURRENT_ITEM/$ARCHIVE_TOTAL_ITEMS · $(elapsed_label "$elapsed") elapsed · byte estimate unavailable"
  fi
}

stop_active_copy() {
  local pid="${ACTIVE_COPY_PID:-}"
  [[ -n "$pid" ]] || return 0
  /usr/bin/pkill -TERM -P "$pid" >/dev/null 2>&1 || true
  kill -TERM "$pid" >/dev/null 2>&1 || true
  wait "$pid" 2>/dev/null || true
  ACTIVE_COPY_PID=""
}

release_checksum_lock() {
  if [[ "$CHECKSUM_LOCK_OWNED" == 1 ]]; then
    /bin/unlink "$ARCHIVE_DIR/.checksum-running/pid" 2>/dev/null || true
    rmdir "$ARCHIVE_DIR/.checksum-running" 2>/dev/null || true
    CHECKSUM_LOCK_OWNED=0
  fi
}

run_copy_with_progress() {
  local target="$1" destination="$2" error_file="$3"
  local started_at now last_growth_at next_heartbeat last_kb current_kb elapsed answer status
  shift 3

  "$@" 2> "$error_file" &
  ACTIVE_COPY_PID=$!
  started_at="$(date +%s)"
  last_growth_at="$started_at"
  next_heartbeat=$((started_at + COPY_HEARTBEAT_SECONDS))
  last_kb="$(path_size_kb "$destination")"

  while kill -0 "$ACTIVE_COPY_PID" 2>/dev/null; do
    sleep 1
    now="$(date +%s)"
    if [[ "$now" -ge "$next_heartbeat" ]]; then
      # Measure only at the heartbeat interval. Running du continuously against
      # a large external snapshot would compete with the copy for disk access.
      current_kb="$(path_size_kb "$destination")"
      if [[ "$current_kb" -gt "$last_kb" ]]; then
        last_kb="$current_kb"
        last_growth_at="$now"
      fi
      elapsed=$((now - started_at))
      info "still copying $target — $(elapsed_label "$elapsed") elapsed; destination now $(human_size_from_kb "$current_kb")"
      if [[ $((now - last_growth_at)) -ge "$COPY_STALL_SECONDS" ]]; then
        warn "No measurable destination growth for $(elapsed_label "$COPY_STALL_SECONDS") while copying: $target"
        if [[ -t 0 && -t 1 ]]; then
          printf 'The copy process is still running. Continue waiting? [Y/n]: '
          IFS= read -r answer
          case "$answer" in
            n|N|no|NO|No)
              stop_active_copy
              printf 'Copy stopped by the user after no measurable destination growth.\n' >> "$error_file"
              return 124
              ;;
          esac
        else
          warn 'No interactive terminal is available, so the copy will continue; press Control-C to stop safely.'
        fi
        last_growth_at="$now"
        last_kb="$current_kb"
      fi
      next_heartbeat=$((now + COPY_HEARTBEAT_SECONDS))
    fi
  done

  if wait "$ACTIVE_COPY_PID"; then status=0; else status=$?; fi
  ACTIVE_COPY_PID=""
  return "$status"
}

run_archive_move_with_progress() {
  local target="$1" destination="$2" error_file="$3" source_kb="$4"
  local started_at now last_growth_at next_heartbeat last_kb current_kb answer status

  /bin/mv "$target" "$destination" 2> "$error_file" &
  ACTIVE_COPY_PID=$!
  started_at="$(date +%s)"
  last_growth_at="$started_at"
  next_heartbeat=$((started_at + COPY_HEARTBEAT_SECONDS))
  last_kb="$(path_size_kb "$destination")"

  while kill -0 "$ACTIVE_COPY_PID" 2>/dev/null; do
    sleep 1
    now="$(date +%s)"
    if [[ "$now" -ge "$next_heartbeat" ]]; then
      current_kb="$(path_size_kb "$destination")"
      if [[ "$current_kb" -gt "$last_kb" ]]; then
        last_kb="$current_kb"
        last_growth_at="$now"
      fi
      print_archive_progress "$current_kb" "$source_kb" active
      if [[ $((now - last_growth_at)) -ge "$COPY_STALL_SECONDS" ]]; then
        warn "No measurable destination growth for $(elapsed_label "$COPY_STALL_SECONDS") while archiving: $target"
        if [[ -t 0 && -t 1 ]]; then
          printf 'The archive move is still running. Continue waiting? [Y/n]: '
          IFS= read -r answer
          case "$answer" in
            n|N|no|NO|No)
              stop_active_copy
              printf 'Archive move stopped by the user after no measurable destination growth.\n' >> "$error_file"
              return 124
              ;;
          esac
        else
          warn 'No interactive terminal is available, so the archive move will continue; press Control-C to stop.'
        fi
        last_growth_at="$now"
        last_kb="$current_kb"
      fi
      next_heartbeat=$((now + COPY_HEARTBEAT_SECONDS))
    fi
  done

  if wait "$ACTIVE_COPY_PID"; then status=0; else status=$?; fi
  ACTIVE_COPY_PID=""
  return "$status"
}

checksum_list_count() {
  LC_ALL=C tr -cd '\000' < "$1" | wc -c | tr -d ' '
}

checksum_progress_count() {
  if [[ -f "$1" ]]; then wc -l < "$1" | tr -d ' '
  else printf '0\n'; fi
}

prepare_checksum_file_list() {
  local list_file="$ARCHIVE_DIR/.checksum-files.nul"
  local list_hash_file="$ARCHIVE_DIR/.checksum-files.nul.sha256"
  local list_tmp="$ARCHIVE_DIR/.checksum-files.nul.tmp"
  local started_at now next_heartbeat elapsed status expected_hash actual_hash

  if [[ -s "$list_file" && -s "$list_hash_file" ]]; then
    expected_hash="$(sed -n '1p' "$list_hash_file" 2>/dev/null || true)"
    actual_hash="$(shasum -a 256 "$list_file" 2>/dev/null | awk '{print $1}' || true)"
    if [[ -n "$expected_hash" && "$expected_hash" == "$actual_hash" ]]; then
      return 0
    fi
    warn 'The saved checksum file list is incomplete; rebuilding it without recopying the snapshot.'
  fi

  rm -f "$list_tmp" "$list_file" "$list_hash_file"
  info 'building the snapshot file list once; this replaces the old full sort'
  (
    cd "$ARCHIVE_DIR"
    find . -type f \
      ! -path './SHA256SUMS.txt' \
      ! -path './SNAPSHOT-COMPLETE' \
      ! -path './INCOMPLETE.md' \
      ! -path './cleanup.log' \
      ! -path './operations.tsv' \
      ! -path './resume-summary.md' \
      ! -path './.checksum-running/*' \
      ! -path './.checksum-files.nul' \
      ! -path './.checksum-files.nul.sha256' \
      ! -path './.checksum-files.nul.tmp' \
      ! -path './.SHA256SUMS.partial' \
      ! -path './.SHA256SUMS.interrupted' \
      ! -name '.checksum-completed*' \
      ! -name '.checksum-batch.*' \
      -print0 > .checksum-files.nul.tmp
    mv .checksum-files.nul.tmp .checksum-files.nul
    shasum -a 256 .checksum-files.nul | awk '{print $1}' > .checksum-files.nul.sha256
  ) &
  ACTIVE_COPY_PID=$!
  started_at="$(date +%s)"
  next_heartbeat=$((started_at + COPY_HEARTBEAT_SECONDS))
  while kill -0 "$ACTIVE_COPY_PID" 2>/dev/null; do
    sleep 1
    now="$(date +%s)"
    if [[ "$now" -ge "$next_heartbeat" ]]; then
      elapsed=$((now - started_at))
      info "still building the checksum file list — $(elapsed_label "$elapsed") elapsed"
      next_heartbeat=$((now + COPY_HEARTBEAT_SECONDS))
    fi
  done
  if wait "$ACTIVE_COPY_PID"; then status=0; else status=$?; fi
  ACTIVE_COPY_PID=""
  [[ "$status" == 0 && -s "$list_file" && -s "$list_hash_file" ]]
}

write_archive_checksums() {
  local list_file="$ARCHIVE_DIR/.checksum-files.nul"
  local partial_file="$ARCHIVE_DIR/.SHA256SUMS.partial"
  local interrupted_file="$ARCHIVE_DIR/.SHA256SUMS.interrupted"
  local completed_file="$ARCHIVE_DIR/.checksum-completed"
  local started_at now next_heartbeat elapsed completed_at_start checksum_count
  local processed_this_run remaining eta_seconds rate_per_minute percent total_files status
  local existing_lock_pid=""

  if ! mkdir "$ARCHIVE_DIR/.checksum-running" 2>/dev/null; then
    existing_lock_pid="$(sed -n '1p' "$ARCHIVE_DIR/.checksum-running/pid" 2>/dev/null || true)"
    if [[ -n "$existing_lock_pid" ]] && ! kill -0 "$existing_lock_pid" 2>/dev/null; then
      /bin/unlink "$ARCHIVE_DIR/.checksum-running/pid" 2>/dev/null || true
      rmdir "$ARCHIVE_DIR/.checksum-running" 2>/dev/null || true
    fi
    if ! mkdir "$ARCHIVE_DIR/.checksum-running" 2>/dev/null; then
      err 'Another checksum process appears to be using this snapshot.'
      err 'Wait for it to finish, or stop that process before retrying Step 3.'
      return 1
    fi
  fi
  CHECKSUM_LOCK_OWNED=1
  printf '%s\n' "$$" > "$ARCHIVE_DIR/.checksum-running/pid"

  # Older releases wrote directly to SHA256SUMS.txt. It may be partial after an
  # interruption and cannot be matched safely to the new NUL-delimited list, so
  # preserve it for the duration of this retry and start a fast batched pass.
  if [[ -s "$ARCHIVE_DIR/SHA256SUMS.txt" && ! -s "$ARCHIVE_DIR/SNAPSHOT-COMPLETE" ]]; then
    mv "$ARCHIVE_DIR/SHA256SUMS.txt" "$interrupted_file"
    rm -f "$partial_file" "$list_file" "$ARCHIVE_DIR/.checksum-files.nul.sha256" "$completed_file"
    info 'found an interrupted legacy checksum pass; the copied data will be reused and rehashed in batches'
  fi

  prepare_checksum_file_list || return 1
  total_files="$(checksum_list_count "$list_file")"
  checksum_count="$(checksum_progress_count "$partial_file")"
  checksum_count="${checksum_count:-0}"
  if [[ "$checksum_count" -gt "$total_files" ]]; then
    warn 'Saved checksum progress does not match the file list; restarting checksums without recopying data.'
    rm -f "$partial_file"
    checksum_count=0
  fi
  completed_at_start="$checksum_count"
  printf '%s\n' "$checksum_count" > "$completed_file"
  rm -f "$ARCHIVE_DIR"/.checksum-batch.*
  info "creating integrity checksums in batches of $CHECKSUM_BATCH_SIZE — $total_files file(s) total"
  [[ "$checksum_count" -gt 0 ]] && info "resuming at file $((checksum_count + 1)); $checksum_count checksum(s) are already complete"

  (
    cd "$ARCHIVE_DIR"
    batch=()
    seen=0
    completed_count="$completed_at_start"
    batch_file=".checksum-batch.$$"
    trap 'rm -f "$batch_file"' EXIT
    flush_batch() {
      [[ "${#batch[@]}" -gt 0 ]] || return 0
      shasum -a 256 "${batch[@]}" > "$batch_file" || return 1
      cat "$batch_file" >> .SHA256SUMS.partial
      completed_count=$((completed_count + ${#batch[@]}))
      printf '%s\n' "$completed_count" > .checksum-completed.tmp
      mv .checksum-completed.tmp .checksum-completed
      : > "$batch_file"
      batch=()
    }
    while IFS= read -r -d '' archived_file; do
      seen=$((seen + 1))
      [[ "$seen" -le "$completed_at_start" ]] && continue
      batch+=("$archived_file")
      if [[ "${#batch[@]}" -ge "$CHECKSUM_BATCH_SIZE" ]]; then flush_batch; fi
    done < .checksum-files.nul
    flush_batch
  ) &
  ACTIVE_COPY_PID=$!
  started_at="$(date +%s)"
  next_heartbeat=$((started_at + COPY_HEARTBEAT_SECONDS))
  while kill -0 "$ACTIVE_COPY_PID" 2>/dev/null; do
    sleep 1
    now="$(date +%s)"
    if [[ "$now" -ge "$next_heartbeat" ]]; then
      elapsed=$((now - started_at))
      checksum_count="$(sed -n '1p' "$completed_file" 2>/dev/null || printf '0')"
      checksum_count="${checksum_count:-0}"
      processed_this_run=$((checksum_count - completed_at_start))
      remaining=$((total_files - checksum_count))
      percent="$(awk -v done="$checksum_count" -v total="$total_files" 'BEGIN { if (total > 0) printf "%.1f", done * 100 / total; else printf "100.0" }')"
      if [[ "$processed_this_run" -gt 0 && "$elapsed" -gt 0 ]]; then
        eta_seconds=$((remaining * elapsed / processed_this_run))
        rate_per_minute=$((processed_this_run * 60 / elapsed))
        info "checksums: $checksum_count/$total_files ($percent%%) — $(elapsed_label "$elapsed") elapsed · about $(elapsed_label "$eta_seconds") remaining · $rate_per_minute files/min"
      else
        info "checksums: $checksum_count/$total_files ($percent%%) — $(elapsed_label "$elapsed") elapsed · estimating remaining time"
      fi
      next_heartbeat=$((now + COPY_HEARTBEAT_SECONDS))
    fi
  done
  if wait "$ACTIVE_COPY_PID"; then status=0; else status=$?; fi
  ACTIVE_COPY_PID=""
  [[ "$status" == 0 ]] || return "$status"

  checksum_count="$(checksum_progress_count "$partial_file")"
  [[ "${checksum_count:-0}" == "$total_files" ]] || {
    err "Checksum pass stopped at ${checksum_count:-0} of $total_files files."
    return 1
  }
  mv "$partial_file" "$ARCHIVE_DIR/SHA256SUMS.txt"
  rm -f "$list_file" "$ARCHIVE_DIR/.checksum-files.nul.sha256" "$interrupted_file" "$completed_file"
  release_checksum_lock
  ok "integrity manifest complete: $total_files file(s)"
}

write_snapshot_completion_marker() {
  local manifest_hash file_count marker_tmp
  manifest_hash="$(shasum -a 256 "$ARCHIVE_DIR/SHA256SUMS.txt" | awk '{print $1}')"
  file_count="$(wc -l < "$ARCHIVE_DIR/SHA256SUMS.txt" | tr -d ' ')"
  marker_tmp="$ARCHIVE_DIR/.SNAPSHOT-COMPLETE.tmp"
  {
    printf 'manifest-sha256\t%s\n' "$manifest_hash"
    printf 'files\t%s\n' "$file_count"
    printf 'completed-utc\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  } > "$marker_tmp"
  chmod 600 "$marker_tmp"
  mv "$marker_tmp" "$ARCHIVE_DIR/SNAPSHOT-COMPLETE"
  rm -f "$ARCHIVE_DIR/INCOMPLETE.md"
}

snapshot_completion_marker_is_valid() {
  local snapshot="$1" expected actual
  [[ -s "$snapshot/SHA256SUMS.txt" && -s "$snapshot/SNAPSHOT-COMPLETE" && ! -e "$snapshot/INCOMPLETE.md" ]] || return 1
  expected="$(awk -F '\t' '$1 == "manifest-sha256" { print $2; exit }' "$snapshot/SNAPSHOT-COMPLETE" 2>/dev/null || true)"
  actual="$(shasum -a 256 "$snapshot/SHA256SUMS.txt" 2>/dev/null | awk '{print $1}' || true)"
  [[ -n "$expected" && "$expected" == "$actual" ]]
}

record_in_progress_snapshot() {
  local scope_value="" tmp
  [[ -n "$IN_PROGRESS_FILE" ]] || return 0
  [[ -r "$IN_PROGRESS_FILE" ]] && scope_value="$(sed -n '2p' "$IN_PROGRESS_FILE" 2>/dev/null || true)"
  mkdir -p "$(dirname "$IN_PROGRESS_FILE")"
  tmp="$(mktemp "$(dirname "$IN_PROGRESS_FILE")/.day-one-in-progress.XXXXXX")"
  printf '%s\n%s\n' "$ARCHIVE_DIR" "$scope_value" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$IN_PROGRESS_FILE"
}

clear_in_progress_snapshot() {
  local saved
  [[ -n "$IN_PROGRESS_FILE" && -r "$IN_PROGRESS_FILE" ]] || return 0
  saved="$(sed -n '1p' "$IN_PROGRESS_FILE" 2>/dev/null || true)"
  [[ "$saved" == "$ARCHIVE_DIR" ]] && rm -f "$IN_PROGRESS_FILE"
}

write_completed_snapshot_result() {
  local result_tmp
  [[ -n "$RESULT_FILE" ]] || return 0
  mkdir -p "$(dirname "$RESULT_FILE")"
  result_tmp="$(mktemp "$(dirname "$RESULT_FILE")/.day-one-result.XXXXXX")"
  printf '%s\n' "$ARCHIVE_DIR" > "$result_tmp"
  chmod 600 "$result_tmp"
  mv "$result_tmp" "$RESULT_FILE"
}

validate_resumable_snapshot() {
  local archive_parent root_parent archive_name
  [[ -d "$ARCHIVE_DIR" ]] || { err "Interrupted snapshot is unavailable: $ARCHIVE_DIR"; return 1; }
  archive_parent="$(cd "$(dirname "$ARCHIVE_DIR")" && pwd -P)"
  root_parent="$(cd "$ARCHIVE_ROOT" && pwd -P)"
  archive_name="$(basename "$ARCHIVE_DIR")"
  [[ "$archive_parent" == "$root_parent" && "$archive_name" == Day-One-Mac-Backup-Snapshot-* ]] || {
    err 'Refusing to resume a directory that is not a Day One Mac snapshot directly inside the selected recovery folder.'
    return 1
  }
  [[ -s "$ARCHIVE_DIR/README.md" && -s "$ARCHIVE_DIR/operations.tsv" ]] || {
    err 'The interrupted snapshot did not finish copying its source paths, so only its generated checksums cannot be resumed.'
    err 'Keep it for review and start a new Step 3 snapshot; no source file was removed.'
    return 1
  }
  snapshot_completion_marker_is_valid "$ARCHIVE_DIR" && {
    err 'This snapshot is already complete; checksum resumption is not needed.'
    return 1
  }
  return 0
}

cleanup_options_tsv() {
  printf 'archive-projects\t%s\n' "$ARCHIVE_PROJECTS"
  printf 'archive-docker-data\t%s\n' "$ARCHIVE_DOCKER_DATA"
  printf 'archive-orbstack-data\t%s\n' "$ARCHIVE_ORBSTACK_DATA"
  printf 'archive-1password-data\t%s\n' "$ARCHIVE_1PASSWORD_DATA"
  printf 'archive-ssh-private-keys\t%s\n' "$ARCHIVE_SSH_PRIVATE_KEYS"
  printf 'prepare-keychain-reset\t%s\n' "$PREPARE_KEYCHAIN_RESET"
  printf 'zap-cask-data\t%s\n' "$ZAP_CASK_DATA"
}

write_cleanup_options() {
  cleanup_options_tsv > "$ARCHIVE_DIR/cleanup-options.tsv"
  chmod 600 "$ARCHIVE_DIR/cleanup-options.tsv"
}

validate_resumable_cleanup() {
  local archive_parent archive_name saved_options current_options
  [[ -d "$ARCHIVE_DIR" && ! -L "$ARCHIVE_DIR" && -w "$ARCHIVE_DIR" ]] || {
    err "Incomplete cleanup recovery must be an existing writable directory, not a symlink: $ARCHIVE_DIR"
    return 1
  }
  archive_parent="$(cd "$(dirname "$ARCHIVE_DIR")" && pwd -P)"
  archive_name="$(basename "$ARCHIVE_DIR")"
  [[ "$archive_parent" == "$(cd "$ARCHIVE_ROOT" && pwd -P)" \
     && "$archive_name" == Day-One-Mac-Clean-Recovery-* ]] || {
    err 'Refusing to resume a directory that is not a Day One Mac cleanup recovery folder.'
    return 1
  }
  [[ -s "$ARCHIVE_DIR/INCOMPLETE.md" \
     && -s "$ARCHIVE_DIR/operations.tsv" \
     && -s "$ARCHIVE_DIR/cleanup.log" \
     && -f "$ARCHIVE_DIR/homebrew-casks.txt" ]] || {
    err 'The selected folder does not contain the markers and inventories required for a safe cleanup resume.'
    return 1
  }
  [[ ! -e "$ARCHIVE_DIR/SNAPSHOT-COMPLETE" ]] || {
    err 'This cleanup recovery is already marked complete; it must not be resumed.'
    return 1
  }
  if [[ -s "$ARCHIVE_DIR/cleanup-options.tsv" ]]; then
    saved_options="$(cat "$ARCHIVE_DIR/cleanup-options.tsv")"
    current_options="$(cleanup_options_tsv)"
    [[ "$saved_options" == "$current_options" ]] || {
      err 'The supplied archive options do not match the options saved by the interrupted cleanup.'
      err "Review: $ARCHIVE_DIR/cleanup-options.tsv"
      return 1
    }
  else
    warn 'This recovery was created by an older script and has no saved option manifest.'
    warn 'The resume will use the archive and zap flags supplied on this command.'
  fi
}

write_reinstall_inventories() {
  local inventory_dir="$ARCHIVE_DIR/reinstall-inventories"
  mkdir -p "$inventory_dir"
  {
    printf '# Tool versions recorded before cleanup\n\n'
    printf 'Use these as a reference; prefer currently supported versions when rebuilding.\n\n'
    for tool in node npm pnpm fnm corepack python3 uv pip3 ruby cargo rustc go code; do
      if have "$tool"; then
        printf '## %s\n\n```text\n' "$tool"
        "$tool" --version 2>&1 || true
        printf '```\n\n'
      fi
    done
  } > "$inventory_dir/tool-versions.md"

  {
    printf '# npm global packages\n\n```text\n'
    if have npm; then npm list --global --depth=0 2>&1 || true; else printf 'npm was not available.\n'; fi
    printf '```\n'
  } > "$inventory_dir/npm-global-packages.md"
  {
    printf '# pnpm global packages\n\n```text\n'
    if have pnpm; then pnpm list --global --depth=0 2>&1 || true; else printf 'pnpm was not available.\n'; fi
    printf '```\n'
  } > "$inventory_dir/pnpm-global-packages.md"
  {
    printf '# fnm-managed Node versions\n\n```text\n'
    if have fnm; then NO_COLOR=1 fnm list 2>&1 || true; else printf 'fnm was not available.\n'; fi
    printf '```\n'
  } > "$inventory_dir/fnm-node-versions.md"
  {
    printf '# VS Code extensions\n\n'
    printf 'Reinstall an entry with `code --install-extension publisher.extension`.\n\n```text\n'
    if have code; then code --list-extensions --show-versions 2>&1 || true; else printf 'The code command was not available.\n'; fi
    printf '```\n'
  } > "$inventory_dir/vscode-extensions.md"
  chmod 600 "$inventory_dir"/*
  log 'REPORT reinstall inventories'
}

retry_copy_with_admin_read() {
  local target="$1" destination="$2" copy_method="$3" exclude_file="${4:-}"
  local answer

  warn "One or more items inside $target cannot be read by this user account."
  printf '  The unreadable data will not be skipped, and the source will not be changed.\n'
  printf '  Administrator access can retry only this copy into the recovery snapshot.\n'
  if [[ ! -t 0 ]]; then
    err 'Administrator-assisted retry needs an interactive terminal.'
    err 'Run this step again from the guided wizard and approve the retry when asked.'
    return 1
  fi
  printf 'Retry this copy with macOS administrator read access? [y/N]: '
  IFS= read -r answer
  case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *) err 'Administrator-assisted copy was not approved; the snapshot remains incomplete.'; return 1 ;;
  esac

  /usr/bin/sudo -v || { err 'Administrator access was not granted; the snapshot remains incomplete.'; return 1; }
  if [[ "$copy_method" == rsync ]]; then
    mkdir -p "$destination"
    run_copy_with_progress "$target" "$destination" /dev/stderr \
      /usr/bin/sudo /usr/bin/rsync -aE --exclude-from="$exclude_file" "$target/" "$destination/" \
      || { err "The administrator-assisted copy of $target failed."; return 1; }
  else
    run_copy_with_progress "$target" "$destination" /dev/stderr \
      /usr/bin/sudo /usr/bin/ditto "$target" "$destination" \
      || { err "The administrator-assisted copy of $target failed."; return 1; }
  fi
  normalise_admin_copy_for_current_user "$destination" \
    || { err "Could not make the backup copy readable by the current user: $destination"; return 1; }
  record_admin_read_copy "$target" "$destination"
  ok 'administrator-assisted read completed; the source was not modified'
}

copy_path_for_backup() {
  local target="$1" destination="$2" transient_list metadata_list exclude_file copy_error_file
  local transient_path metadata_path relative_path escaped_path
  local socket_count=0 pipe_count=0 known_cache_count=0 vendor_metadata_count=0 has_exclusions=0 retry_status=0

  # Unix sockets and named pipes are temporary endpoints used by running
  # processes. They cannot be restored and cause ditto to stop. Ordinary paths
  # continue to use ditto so their macOS metadata is preserved exactly.
  if [[ -S "$target" ]]; then
    record_skipped_transient_item "$target" socket 'live process endpoint; contains no restorable data'
    info "skipped one transient Unix socket: $target"
    return 0
  fi
  if [[ -p "$target" ]]; then
    record_skipped_transient_item "$target" pipe 'named process pipe; contains no restorable data'
    info "skipped one transient named pipe: $target"
    return 0
  fi
  if [[ ! -d "$target" || -L "$target" ]]; then
    copy_error_file="$(mktemp "${TMPDIR:-/tmp}/day-one-copy-error.XXXXXX")"
    if run_copy_with_progress "$target" "$destination" "$copy_error_file" \
      /usr/bin/ditto "$target" "$destination"; then
      rm -f "$copy_error_file"
      return 0
    fi
    cat "$copy_error_file" >&2
    if copy_error_is_permission_related "$copy_error_file"; then
      rm -f "$copy_error_file"
      retry_copy_with_admin_read "$target" "$destination" ditto
      return
    fi
    rm -f "$copy_error_file"
    err "Could not copy $target."
    return 1
  fi

  transient_list="$(mktemp "${TMPDIR:-/tmp}/day-one-transient-items.XXXXXX")"
  metadata_list="$(mktemp "${TMPDIR:-/tmp}/day-one-generated-metadata.XXXXXX")"
  exclude_file="$(mktemp "${TMPDIR:-/tmp}/day-one-rsync-excludes.XXXXXX")"
  copy_error_file="$(mktemp "${TMPDIR:-/tmp}/day-one-copy-error.XXXXXX")"

  # Codex owns durable configuration directly under ~/.codex, but .tmp is a
  # rebuildable runtime/plugin checkout. It may contain root- or process-owned
  # Git pack files that cannot be read. Exclude only this documented cache;
  # unreadable files anywhere else remain a hard failure rather than silently
  # weakening the snapshot.
  if [[ "$target" == "$HOME/.codex" ]]; then
    if [[ -e "$target/.tmp" || -L "$target/.tmp" ]]; then
      printf '/.tmp/\n' >> "$exclude_file"
      record_skipped_transient_item "$target/.tmp" cache 'Codex temporary runtime/plugin cache; rebuilt automatically'
      known_cache_count=1
      has_exclusions=1
    fi

    # Imported skill working files may still be useful for recovery, so retain
    # them. Only omit the nested Git metadata that Codex can regenerate and
    # that may contain unreadable process-owned pack indexes.
    if [[ -d "$target/vendor_imports" ]]; then
      if ! find "$target/vendor_imports" -type d -name .git -prune -print > "$metadata_list" 2>/dev/null; then
        rm -f "$transient_list" "$metadata_list" "$exclude_file" "$copy_error_file"
        err "Could not inspect $target/vendor_imports for generated Git metadata."
        return 1
      fi
      while IFS= read -r metadata_path; do
        [[ -n "$metadata_path" ]] || continue
        relative_path="${metadata_path#"$target"/}"
        escaped_path="$(printf '%s\n' "$relative_path" | sed 's/[][\\*?]/\\&/g')"
        printf '/%s/\n' "$escaped_path" >> "$exclude_file"
        record_skipped_transient_item "$metadata_path" metadata 'Codex vendor-import Git metadata; imported skill working files were copied'
        vendor_metadata_count=$((vendor_metadata_count + 1))
        has_exclusions=1
      done < "$metadata_list"
    fi

    if ! find "$target" \
      \( -path "$target/.tmp" -o \( -type d -name .git -path "$target/vendor_imports/*" \) \) -prune \
      -o \( -type s -o -type p \) -print > "$transient_list" 2>/dev/null; then
      rm -f "$transient_list" "$metadata_list" "$exclude_file" "$copy_error_file"
      err "Could not inspect $target for temporary process sockets and pipes."
      return 1
    fi
  elif ! find "$target" \( -type s -o -type p \) -print > "$transient_list" 2>/dev/null; then
    rm -f "$transient_list" "$metadata_list" "$exclude_file" "$copy_error_file"
    err "Could not inspect $target for temporary process sockets and pipes."
    return 1
  fi

  if [[ ! -s "$transient_list" && "$has_exclusions" == 0 ]]; then
    rm -f "$transient_list" "$metadata_list" "$exclude_file"
    if run_copy_with_progress "$target" "$destination" "$copy_error_file" \
      /usr/bin/ditto "$target" "$destination"; then
      rm -f "$copy_error_file"
      return 0
    fi
    cat "$copy_error_file" >&2
    if copy_error_is_permission_related "$copy_error_file"; then
      rm -f "$copy_error_file"
      retry_copy_with_admin_read "$target" "$destination" ditto
      return
    fi
    rm -f "$copy_error_file"
    err "Could not copy $target."
    return 1
  fi

  while IFS= read -r transient_path; do
    [[ -n "$transient_path" ]] || continue
    relative_path="${transient_path#"$target"/}"
    escaped_path="$(printf '%s\n' "$relative_path" | sed 's/[][\\*?]/\\&/g')"
    printf '/%s\n' "$escaped_path" >> "$exclude_file"
    if [[ -p "$transient_path" ]]; then
      record_skipped_transient_item "$transient_path" pipe 'named process pipe; contains no restorable data'
      pipe_count=$((pipe_count + 1))
    else
      record_skipped_transient_item "$transient_path" socket 'live process endpoint; contains no restorable data'
      socket_count=$((socket_count + 1))
    fi
  done < "$transient_list"

  mkdir -p "$destination"
  if ! run_copy_with_progress "$target" "$destination" "$copy_error_file" \
    /usr/bin/rsync -aE --exclude-from="$exclude_file" "$target/" "$destination/"; then
    cat "$copy_error_file" >&2
    if copy_error_is_permission_related "$copy_error_file"; then
      rm -f "$transient_list" "$metadata_list" "$copy_error_file"
      if retry_copy_with_admin_read "$target" "$destination" rsync "$exclude_file"; then
        retry_status=0
      else
        retry_status=$?
      fi
      rm -f "$exclude_file"
      return "$retry_status"
    fi
    rm -f "$transient_list" "$metadata_list" "$exclude_file" "$copy_error_file"
    err "Could not copy $target after excluding recognised temporary items."
    return 1
  fi
  rm -f "$transient_list" "$metadata_list" "$exclude_file" "$copy_error_file"
  info "skipped $socket_count socket(s), $pipe_count named pipe(s), $known_cache_count cache path(s), and $vendor_metadata_count vendor Git metadata path(s) under $target; durable files were copied"
}

mark_incomplete_on_exit() {
  local exit_code=$?
  trap - EXIT
  stop_active_copy
  release_checksum_lock
  if [[ "$ARCHIVE_INITIALIZED" == 1 && "$ARCHIVE_COMPLETE" != 1 && -d "$ARCHIVE_DIR" ]]; then
    {
      printf '# Incomplete Day One Mac operation\n\n'
      printf 'This folder was created, but the operation stopped before every verification passed.\n'
      printf 'Do not treat it as a completed recovery snapshot. Review `operations.tsv` and\n'
      printf '`cleanup.log` to see what finished.\n'
      if [[ "$BACKUP_ONLY" == 1 ]]; then
        printf '\nThis was a copy-only operation; no source file or application was removed.\n'
      else
        printf '\nThis was a cleanup operation. Check the recorded operations and the original\n'
        printf 'paths before retrying because some selected items may already have been moved.\n'
      fi
    } > "$ARCHIVE_DIR/INCOMPLETE.md" 2>/dev/null || true
    chmod 600 "$ARCHIVE_DIR/INCOMPLETE.md" 2>/dev/null || true
    if [[ -n "$RESUME_CLEANUP" && "$RESUME_OPERATIONS_BOUNDARY" -gt 0 ]]; then
      record_operation resume-attempt "$ARCHIVE_DIR" "$ARCHIVE_DIR" failed 2>/dev/null || true
      write_resume_summary_report 'incomplete — review the latest failed operation' 2>/dev/null || true
      print_resume_summary 2>/dev/null || true
    fi
  fi
  exit "$exit_code"
}

check_cleanup_terminal_host() {
  [[ "$BACKUP_ONLY" != 1 ]] || return 0
  if [[ "${TERM_PROGRAM:-}" == WarpTerminal || "${TERM_PROGRAM:-}" == Warp \
        || -n "${WARP_IS_LOCAL_SHELL_SESSION:-}" ]]; then
    err 'Step 5 cannot run inside Warp because this cleanup may uninstall Warp.'
    err 'Quit Warp, open Apple Terminal, move to a directory outside ~/Developer, and run the same command again.'
    err 'Nothing was copied, moved, or removed.'
    return 1
  fi
}

check_selected_apps_are_stopped() {
  if [[ "$ARCHIVE_DOCKER_DATA" == 1 ]] \
     && (pgrep -f '[D]ocker Desktop' >/dev/null 2>&1 || pgrep -f 'com\.docker\.backend' >/dev/null 2>&1); then
    err "Quit Docker Desktop completely before copying or archiving its VM data."
    err "Nothing was copied, moved, or removed."
    return 1
  fi
  if [[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]] && pgrep -f '[O]rbStack' >/dev/null 2>&1; then
    err "Quit OrbStack completely before copying or archiving its VM data."
    err "Nothing was copied, moved, or removed."
    return 1
  fi
  if [[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && pgrep -f '[1]Password' >/dev/null 2>&1; then
    err "Quit 1Password completely before copying or archiving its local application data."
    err "Nothing was copied, moved, or removed."
    return 1
  fi
}

archive_path() {
  local target="$1" destination original_destination source_kb move_error_file operation_action='archive'
  [[ -e "$target" || -L "$target" ]] || return 0
  safe_home_target "$target" || { warn "refusing unsafe target: $target"; return 1; }
  destination="$ARCHIVE_DIR/home/$(relative_home_path "$target")"
  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ -n "$RESUME_CLEANUP" ]]; then
      original_destination="$destination"
      if [[ -z "$RESUME_ADDITIONS_DIR" ]]; then
        RESUME_ADDITIONS_DIR="$ARCHIVE_DIR/resume-additions/$STAMP-$$"
      fi
      destination="$RESUME_ADDITIONS_DIR/home/$(relative_home_path "$target")"
      if [[ -e "$destination" || -L "$destination" ]]; then
        err "resume-addition destination already exists: $destination"
        return 1
      fi
      operation_action='archive-resume-addition'
      warn "A source path was recreated after its original archive. Preserving the new version separately: $target"
      info "original archived version: $original_destination"
      info "newly recreated version: $destination"
    else
      err "archive destination already exists: $destination"
      return 1
    fi
  fi
  mkdir -p "$(dirname "$destination")"
  if [[ "$BACKUP_ONLY" == 1 ]]; then
    source_kb="$(path_size_kb "$target")"
    info "starting copy: $target ($(human_size_from_kb "$source_kb"))"
    printf '  Destination: %s\n' "$destination"
    copy_path_for_backup "$target" "$destination"
    log "COPY $target -> $destination"
    record_operation copy "$target" "$destination" complete
    ok "copied $target"
  else
    source_kb="$(path_size_kb "$target")"
    ARCHIVE_CURRENT_ITEM=$((ARCHIVE_CURRENT_ITEM + 1))
    info "archive item $ARCHIVE_CURRENT_ITEM/$ARCHIVE_TOTAL_ITEMS: $target ($(human_size_from_kb "$source_kb"))"
    printf '  Destination: %s\n' "$destination"
    print_archive_progress 0 "$source_kb" active
    move_error_file="$(mktemp "${TMPDIR:-/tmp}/day-one-archive-error.XXXXXX")"
    if ! run_archive_move_with_progress "$target" "$destination" "$move_error_file" "$source_kb"; then
      cat "$move_error_file" >&2
      rm -f "$move_error_file"
      err "Could not archive $target. Review the incomplete recovery folder before retrying."
      return 1
    fi
    rm -f "$move_error_file"
    ARCHIVE_COMPLETED_KB=$((ARCHIVE_COMPLETED_KB + source_kb))
    if [[ "$ARCHIVE_TOTAL_KB" -gt 0 && "$ARCHIVE_COMPLETED_KB" -gt "$ARCHIVE_TOTAL_KB" ]]; then
      ARCHIVE_COMPLETED_KB="$ARCHIVE_TOTAL_KB"
    fi
    print_archive_progress 0 0 complete
    log "ARCHIVE $target -> $destination"
    record_operation "$operation_action" "$target" "$destination" complete
    ok "archived $target"
  fi
}

estimate_archive_kb() {
  local target size total=0
  for target in "${selected_archive_targets[@]}"; do
    [[ -e "$target" || -L "$target" ]] || continue
    size="$(du -sk "$target" 2>/dev/null | awk 'NR == 1 { print $1 }' || true)"
    case "$size" in ''|*[!0-9]*) continue ;; esac
    total=$((total + size))
  done
  printf '%s\n' "$total"
}

# Resume only the verification of a snapshot whose copies and reports already
# finished. Original source paths are not inspected or copied again here.
if [[ -n "$RESUME_SNAPSHOT" ]]; then
  [[ -d "$ARCHIVE_ROOT" && -w "$ARCHIVE_ROOT" ]] \
    || { err "Recovery parent must already exist and be writable: $ARCHIVE_ROOT"; exit 1; }
  validate_resumable_snapshot || exit 1
  ui_title '🧮' 'Resume backup integrity checks'
  printf '  Existing copied snapshot: %s\n' "$ARCHIVE_DIR"
  printf '  Source files: unchanged and not copied again\n'
  printf '  Progress: resumes from the last completed checksum batch\n'
  confirm_execute || { err 'confirmation did not match; the snapshot was not changed'; exit 10; }
  LOG_FILE="$ARCHIVE_DIR/cleanup.log"
  OPERATIONS_FILE="$ARCHIVE_DIR/operations.tsv"
  ARCHIVE_INITIALIZED=1
  trap mark_incomplete_on_exit EXIT
  log 'RESUME snapshot integrity checks'
  write_archive_checksums || { err 'Could not complete the resumed snapshot integrity checks.'; exit 1; }
  chmod 600 "$ARCHIVE_DIR/SHA256SUMS.txt"
  record_operation checksum "$ARCHIVE_DIR" "$ARCHIVE_DIR/SHA256SUMS.txt" complete
  write_snapshot_completion_marker
  write_completed_snapshot_result
  clear_in_progress_snapshot
  log 'PASS resumed development backup snapshot'
  ARCHIVE_COMPLETE=1
  trap - EXIT
  ok 'development backup snapshot complete; copied source data was reused'
  info "Backup snapshot: $ARCHIVE_DIR"
  exit 0
fi

if [[ "$BACKUP_ONLY" == 1 ]]; then
  ui_title '💾' 'Create a development backup snapshot'
else
  ui_title '🧹' 'Clean macOS development state'
fi
if [[ "$BACKUP_ONLY" == 1 ]]; then
  printf '  Mode: copy-only backup\n'
elif [[ -n "$RESUME_CLEANUP" ]]; then
  printf '  Mode: resume the selected incomplete cleanup\n'
else
  printf '  Mode: %s\n' "$([[ "$EXECUTE" == 1 ]] && printf execute || printf preview)"
fi
printf '  Recovery: %s\n' "$ARCHIVE_DIR"
if [[ "$BACKUP_ONLY" == 1 ]]; then
  printf '  Scope: selected development files plus package/application inventories\n'
else
  printf '  Scope: every Homebrew formula/cask plus known development configuration\n'
fi
printf '  Disk erase/format: never\n'
printf '  Non-Homebrew applications: preserved\n'
[[ "$ZAP_CASK_DATA" == 1 ]] && warn "Cask zap is selected; Homebrew may delete application support data after the configuration archive."

# Stop before the long inventory and before creating a recovery folder when a
# selected live-data source is still open. This makes retries short and leaves
# no normal-looking, empty snapshot directory behind.
if [[ "$EXECUTE" == 1 ]]; then
  check_cleanup_terminal_host || exit 1
  check_selected_apps_are_stopped || exit 1
fi

print_homebrew_inventory
print_application_inventory
print_path_inventory

archive_estimate_kb="$(estimate_archive_kb)"
ui_section '💾' 'Recovery capacity estimate'
printf '  Selected paths currently use about %s GiB.\n' "$(awk -v kb="$archive_estimate_kb" 'BEGIN { printf "%.2f", kb / 1048576 }')"
printf '  The destination also needs 10%% headroom plus 1 GiB for reports and package metadata.\n'

[[ "$EXECUTE" == 1 ]] || {
  printf '\nPreview only. Rerun with --execute after reviewing every item.\n'
  exit 0
}

if [[ "$BACKUP_ONLY" != 1 ]] && have brew; then
  installed_container_casks="$(brew list --cask 2>/dev/null | grep -E '^(docker|docker-desktop|orbstack)$' || true)"
  if [[ "$ARCHIVE_DOCKER_DATA" == 0 ]] && printf '%s\n' "$installed_container_casks" | grep -Eq '^(docker|docker-desktop)$'; then
    err "Docker Desktop is installed by Homebrew, and its uninstaller may remove VM data."
    err "Rerun with --archive-docker-data after reviewing the Docker Desktop paths."
    err "Nothing was changed."
    exit 2
  fi
  if [[ "$ARCHIVE_ORBSTACK_DATA" == 0 ]] && printf '%s\n' "$installed_container_casks" | grep -Eq '^orbstack$'; then
    err "OrbStack is installed by Homebrew, and its uninstaller may remove VM data."
    err "Rerun with --archive-orbstack-data after reviewing the OrbStack paths."
    err "Nothing was changed."
    exit 2
  fi
fi

[[ -d "$ARCHIVE_ROOT" && -w "$ARCHIVE_ROOT" ]] || { err "Recovery parent must already exist and be writable: $ARCHIVE_ROOT"; exit 1; }
if [[ -n "$RESUME_CLEANUP" ]]; then
  validate_resumable_cleanup || exit 1
else
  [[ ! -e "$ARCHIVE_DIR" ]] || { err "Recovery directory already exists: $ARCHIVE_DIR"; exit 1; }
fi
available_kb="$(df -Pk "$ARCHIVE_ROOT" 2>/dev/null | awk 'NR == 2 { print $4 }' || true)"
required_kb=$((archive_estimate_kb + archive_estimate_kb / 10 + 1048576))
case "$available_kb" in
  ''|*[!0-9]*) err "Could not determine free space for recovery parent: $ARCHIVE_ROOT"; exit 1 ;;
esac
if [[ "$available_kb" -lt "$required_kb" ]]; then
  err "Recovery volume does not have enough free space for the selected archive."
  err "Required with safety margin: $required_kb KiB; available: $available_kb KiB."
  exit 1
fi
confirm_execute || { err "confirmation did not match; nothing changed"; exit 10; }
confirm_sensitive_archive || { err "credential confirmation did not match; nothing changed"; exit 10; }

LOG_FILE="$ARCHIVE_DIR/cleanup.log"
OPERATIONS_FILE="$ARCHIVE_DIR/operations.tsv"
if [[ -n "$RESUME_CLEANUP" ]]; then
  log "RESUME incomplete clean development state"
  RESUME_OPERATIONS_BOUNDARY="$(wc -l < "$OPERATIONS_FILE" | tr -d ' ')"
  record_operation resume-attempt "$ARCHIVE_DIR" "$ARCHIVE_DIR" started
else
  mkdir -p "$ARCHIVE_DIR"
  chmod 700 "$ARCHIVE_DIR"
  : > "$LOG_FILE"
  chmod 600 "$LOG_FILE"
  printf 'timestamp\taction\tsource\tdestination\tstatus\n' > "$OPERATIONS_FILE"
  chmod 600 "$OPERATIONS_FILE"
  log "START clean development state"
  [[ "$BACKUP_ONLY" == 1 ]] || write_cleanup_options
fi
ARCHIVE_INITIALIZED=1
trap mark_incomplete_on_exit EXIT
[[ -n "$RESUME_CLEANUP" ]] || record_in_progress_snapshot

if [[ "$BACKUP_ONLY" == 1 ]]; then
  SKIPPED_TRANSIENT_ITEMS_FILE="$ARCHIVE_DIR/transient-items-skipped.md"
  {
    printf '# Transient items skipped\n\n'
    printf 'The paths below are known temporary process endpoints or rebuildable caches.\n'
    printf 'They contain no durable settings or documents and cannot or need not be restored.\n'
    printf 'Only these explicitly recognised items were omitted; other copy errors still stop the snapshot.\n\n'
  } > "$SKIPPED_TRANSIENT_ITEMS_FILE"
  chmod 600 "$SKIPPED_TRANSIENT_ITEMS_FILE"
  if [[ "$ARCHIVE_REBUILDABLE_CACHES" == 0 ]]; then
    for target in "${DAY_ONE_REBUILDABLE_DEV_PATHS[@]}"; do
      [[ -e "$target" || -L "$target" ]] || continue
      if [[ "$target" == "$HOME/Library/Application Support/Code" ]]; then
        record_skipped_transient_item "$target" cache 'rebuildable VS Code data omitted; portable User settings were copied separately'
      else
        record_skipped_transient_item "$target" cache 'rebuildable local download/cache; reinstall inventory retained'
      fi
    done
  fi
fi

if [[ -z "$RESUME_CLEANUP" ]]; then
  "$SCRIPT_DIR/application-inventory.sh" \
    --output "$ARCHIVE_DIR/application-inventory.md" >/dev/null
  log "REPORT application inventory"
  write_reinstall_inventories

  : > "$ARCHIVE_DIR/homebrew-formulae.txt"
  : > "$ARCHIVE_DIR/homebrew-casks.txt"
  : > "$ARCHIVE_DIR/homebrew-taps.txt"
  : > "$ARCHIVE_DIR/homebrew-cask-details.txt"
  if have brew; then
    brew list --formula > "$ARCHIVE_DIR/homebrew-formulae.txt" 2>/dev/null || true
    brew list --cask > "$ARCHIVE_DIR/homebrew-casks.txt" 2>/dev/null || true
    brew tap > "$ARCHIVE_DIR/homebrew-taps.txt" 2>/dev/null || true
    while IFS= read -r cask; do
      [[ -n "$cask" ]] || continue
      printf '\n===== %s =====\n' "$cask" >> "$ARCHIVE_DIR/homebrew-cask-details.txt"
      brew info --cask "$cask" >> "$ARCHIVE_DIR/homebrew-cask-details.txt" 2>&1 || true
    done < "$ARCHIVE_DIR/homebrew-casks.txt"
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file="$ARCHIVE_DIR/Brewfile.before-cleanup" --force >/dev/null 2>&1 \
      || warn "Homebrew could not create the optional Brewfile recovery snapshot."
    if [[ "$BACKUP_ONLY" != 1 ]]; then
      uninstaller="$ARCHIVE_DIR/homebrew-uninstall.sh"
      curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh -o "$uninstaller"
      chmod 700 "$uninstaller"
      log "DOWNLOAD official Homebrew uninstaller"
    fi
  fi
else
  info 'reusing the application and package inventories captured before the interrupted cleanup'
  uninstaller="$ARCHIVE_DIR/homebrew-uninstall.sh"
  if have brew && [[ ! -s "$uninstaller" ]]; then
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh -o "$uninstaller"
    chmod 700 "$uninstaller"
    log "DOWNLOAD official Homebrew uninstaller during resume"
  fi
fi

# The caller may be running this repository from inside ~/Developer. Move the
# process to the recovery folder before any selected source path is
# moved, so Homebrew and every later command always have a valid working
# directory. This also makes a resume independent of the replacement checkout.
if [[ "$BACKUP_ONLY" != 1 ]]; then
  cd "$ARCHIVE_DIR"
  log "WORKING DIRECTORY $ARCHIVE_DIR"
fi

if [[ "$BACKUP_ONLY" != 1 ]]; then
  prepare_archive_progress "$archive_estimate_kb"
fi

for target in "${ACTIVE_DEV_PATHS[@]}"; do
  if [[ "$BACKUP_ONLY" != 1 ]] && is_deferred_cleanup_target "$target"; then
    continue
  fi
  archive_path "$target"
done
if [[ "$BACKUP_ONLY" == 1 && "$ARCHIVE_PROJECTS" == 1 ]]; then
  archive_path "$HOME/Developer"
fi
if [[ "$ARCHIVE_DOCKER_DATA" == 1 ]]; then
  for target in "${DAY_ONE_DOCKER_DATA_PATHS[@]}"; do archive_path "$target"; done
fi
if [[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]]; then
  for target in "${DAY_ONE_ORBSTACK_DATA_PATHS[@]}"; do archive_path "$target"; done
fi
if [[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]]; then
  for target in "${ONEPASSWORD_PATHS[@]}"; do archive_path "$target"; done
fi
if [[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 && "$SSH_KEY_COUNT" -gt 0 ]]; then
  for target in "${SSH_KEY_PATHS[@]}"; do archive_path "$target"; done
fi

if [[ "$BACKUP_ONLY" != 1 ]] && have brew; then
  if brew services list >/dev/null 2>&1; then
    brew services stop --all >/dev/null 2>&1 || warn "One or more Homebrew services could not be stopped."
    log "STOP Homebrew services"
  fi
  while IFS= read -r cask; do
    [[ -n "$cask" ]] || continue
    if ! brew list --cask "$cask" >/dev/null 2>&1; then
      info "Homebrew cask is already absent; continuing: $cask"
      log "SKIP already-absent cask $cask"
      record_operation skip-absent-cask "$cask" - complete
      continue
    fi
    if [[ "$ZAP_CASK_DATA" == 1 && "$cask" == 1password && "$ARCHIVE_1PASSWORD_DATA" == 0 ]]; then
      warn "Removing the 1Password cask without --zap to preserve vault/key data."
      if brew uninstall --cask --force "$cask"; then
        log "UNINSTALL cask $cask zap=protected"
        record_operation uninstall-cask "$cask" - complete
      else
        warn "Homebrew could not uninstall cask: $cask"
        record_operation uninstall-cask "$cask" - failed
        CASK_FAILURES=$((CASK_FAILURES + 1))
      fi
    elif [[ "$ZAP_CASK_DATA" == 1 \
            && ( ( ( "$cask" == docker || "$cask" == docker-desktop ) && "$ARCHIVE_DOCKER_DATA" == 0 ) \
                 || ( "$cask" == orbstack && "$ARCHIVE_ORBSTACK_DATA" == 0 ) ) ]]; then
      warn "Removing $cask without --zap because container data is set to KEEP."
      if brew uninstall --cask --force "$cask"; then
        log "UNINSTALL cask $cask zap=container-data-protected"
        record_operation uninstall-cask "$cask" - complete
      else
        warn "Homebrew could not uninstall cask: $cask"
        record_operation uninstall-cask "$cask" - failed
        CASK_FAILURES=$((CASK_FAILURES + 1))
      fi
    elif [[ "$ZAP_CASK_DATA" == 1 ]]; then
      if brew uninstall --cask --zap --force "$cask"; then
        log "UNINSTALL cask $cask zap=$ZAP_CASK_DATA"
        record_operation uninstall-cask-zap "$cask" - complete
      else
        warn "Homebrew could not fully zap cask: $cask"
        record_operation uninstall-cask-zap "$cask" - failed
        CASK_FAILURES=$((CASK_FAILURES + 1))
      fi
    else
      if brew uninstall --cask --force "$cask"; then
        log "UNINSTALL cask $cask zap=$ZAP_CASK_DATA"
        record_operation uninstall-cask "$cask" - complete
      else
        warn "Homebrew could not uninstall cask: $cask"
        record_operation uninstall-cask "$cask" - failed
        CASK_FAILURES=$((CASK_FAILURES + 1))
      fi
    fi
  done < "$ARCHIVE_DIR/homebrew-casks.txt"

  if [[ "$CASK_FAILURES" -gt 0 ]]; then
    err "$CASK_FAILURES Homebrew cask removal(s) failed."
    err "Homebrew was preserved so the failed casks can be reviewed and retried."
    exit 1
  fi
  brew_executable="$(command -v brew 2>/dev/null || printf unknown)"
  NONINTERACTIVE=1 /bin/bash "$uninstaller"
  log "UNINSTALL Homebrew and all formulae"
  record_operation uninstall-homebrew "$brew_executable" - complete
fi

# Keep the project containing this script and the wizard's state in place until
# Homebrew work has either succeeded or failed. They are moved only after the
# package stage succeeds. The process is already working from ARCHIVE_DIR, so
# moving ~/Developer cannot invalidate the current directory.
if [[ "$BACKUP_ONLY" != 1 && "$ARCHIVE_PROJECTS" == 1 ]]; then
  archive_path "$HOME/Developer"
fi
if [[ "$BACKUP_ONLY" != 1 ]]; then
  for target in "$HOME/.day-one-mac" "$HOME/.fresh-mac-setup"; do
    archive_path "$target"
  done
fi

{
  printf '# Development settings scope\n\n'
  if [[ "$BACKUP_ONLY" == 1 ]]; then
    printf 'The backup snapshot copied the following development paths. The source files remain in place.\n\n'
  else
    printf 'The cleanup archived the following development paths that existed at execution time.\n\n'
  fi
  for target in "${ACTIVE_DEV_PATHS[@]}"; do
    destination="$ARCHIVE_DIR/home/$(relative_home_path "$target")"
    [[ -e "$destination" || -L "$destination" ]] && printf -- '- `%s`\n' "$target"
  done
  printf '\nIt did not reset macOS system preferences as a whole, erase settings for every\n'
  printf 'preserved non-Homebrew application, remove the user account, or alter iCloud.\n'
  if [[ "$BACKUP_ONLY" == 1 ]]; then
    printf 'No application or cask support data was removed while creating this snapshot.\n'
    if [[ "$ARCHIVE_REBUILDABLE_CACHES" == 0 ]]; then
      printf 'Rebuildable package caches, downloaded runtimes and full VS Code local data\n'
      printf 'were omitted; portable settings and reinstall inventories were retained.\n'
    fi
  else
    printf 'Cask support data was removed only when `--zap-cask-data` was selected;\n'
    printf 'review `homebrew-cask-details.txt` for the cask metadata captured first.\n'
  fi
} > "$ARCHIVE_DIR/settings-scope.md"
chmod 600 "$ARCHIVE_DIR/settings-scope.md"

{
  printf '# High-risk manual actions\n\n'
  if [[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]]; then
    printf '## 1Password account, vaults and keys\n\n'
    if [[ "$BACKUP_ONLY" == 1 ]]; then
      printf 'Known local 1Password data was copied into this recovery bundle. Cloud vaults,\n'
    else
      printf 'Known local 1Password data was moved into this recovery bundle. Cloud vaults,\n'
    fi
    printf 'items, SSH keys, passkeys, account recovery material and authorized devices still\n'
    printf 'exist in the 1Password account. '
    if [[ "$BACKUP_ONLY" == 1 ]]; then
      printf 'This snapshot does not request provider-side deletion.\n'
      printf 'If later cleanup is meant to retire this device, review exports, shared-vault\n'
      printf 'ownership, device revocation and item deletion separately before acting.\n\n'
    else
      printf 'Sign in to 1Password in a trusted browser, export\n'
      printf 'or transfer anything required, revoke this device, and delete only the selected\n'
      printf 'items or vaults. Account deletion is separate and should not be used merely to\n'
      printf 'clean one Mac. Confirm another owner can access shared vaults before deletion.\n\n'
    fi
  else
    printf '## 1Password\n\nNo local or cloud 1Password data removal was requested.\n\n'
  fi
  if [[ "$PREPARE_KEYCHAIN_RESET" == 1 ]]; then
    printf '## macOS login Keychain\n\n'
    printf 'The script did not alter the Keychain. After confirming that required passwords,\n'
    printf 'certificates, passkeys and secure notes are recoverable, open Keychain Access,\n'
    printf 'choose Keychain Access > Settings, choose Reset Default Keychains, then log out\n'
    printf 'and back in. Apple recommends manual reset only when advised by Apple Support.\n'
    printf 'Resetting the default keychain deletes locally saved keychain passwords and does\n'
    printf 'not constitute deletion of every credential synchronized through an account.\n\n'
    printf 'Apple guide: https://support.apple.com/guide/keychain-access/kyca2429/mac\n\n'
  else
    printf '## macOS Keychain\n\nNo Keychain reset was requested; Keychain data was preserved.\n\n'
  fi
  if [[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]]; then
    if [[ "$BACKUP_ONLY" == 1 ]]; then
      printf '## SSH keys\n\nDetected private keys and matching public-key files were copied under `home/.ssh`.\n'
    else
      printf '## SSH keys\n\nDetected private keys and matching public-key files were moved under `home/.ssh`.\n'
    fi
    printf 'Revoke their public keys separately at GitHub, Azure DevOps, servers and other\n'
    printf 'services if the intent is permanent retirement rather than local removal.\n'
  else
    printf '## SSH keys\n\nSSH private keys were preserved in the active account.\n'
  fi
} > "$ARCHIVE_DIR/high-risk-manual-actions.md"
chmod 600 "$ARCHIVE_DIR/high-risk-manual-actions.md"

{
  if [[ "$BACKUP_ONLY" == 1 ]]; then
    printf '# Development backup snapshot\n\n'
    printf 'This directory contains copies of the selected development configuration\n'
    printf 'plus package and application inventories. The source files, applications,\n'
    printf 'Homebrew installation, account, and startup disk were not changed.\n'
  else
    printf '# Development cleanup recovery\n\n'
    printf 'This directory contains development configuration moved out of the user\n'
    printf 'account plus package and application inventories captured before removal.\n'
    if [[ -d "$ARCHIVE_DIR/resume-additions" ]]; then
      printf 'Files recreated by applications after the first interrupted cleanup are kept\n'
      printf 'separately under `resume-additions/`; they do not overwrite the original archive.\n'
    fi
  fi
  printf 'Restore only files you have inspected. Read `settings-scope.md` for the exact\n'
  printf 'settings boundary and `high-risk-manual-actions.md` for credential actions the\n'
  printf 'script deliberately did not automate. Project, container, local 1Password,\n'
  printf 'and SSH key data were included only when their explicit options were selected.\n'
  if [[ "$BACKUP_ONLY" == 1 ]]; then
    printf 'Temporary process endpoints and explicitly recognised rebuildable caches were\n'
    printf 'omitted; review `transient-items-skipped.md` for the exact paths and reasons.\n'
    if [[ "$ADMIN_READ_COPY_COUNT" -gt 0 ]]; then
      printf 'Administrator read access was approved for one or more complete copies; review\n'
      printf '`administrator-read-access.md` for the exact sources and destinations.\n'
    fi
  fi
} > "$ARCHIVE_DIR/README.md"
chmod 600 "$ARCHIVE_DIR/README.md"

write_archive_checksums || { err 'Could not create the snapshot integrity checksums.'; exit 1; }
chmod 600 "$ARCHIVE_DIR/SHA256SUMS.txt"
record_operation checksum "$ARCHIVE_DIR" "$ARCHIVE_DIR/SHA256SUMS.txt" complete
write_snapshot_completion_marker

if [[ -n "$RESUME_CLEANUP" ]]; then
  record_operation resume-attempt "$ARCHIVE_DIR" "$ARCHIVE_DIR" complete
  write_resume_summary_report 'completed successfully' \
    || warn 'Cleanup completed, but resume-summary.md could not be written.'
  print_resume_summary
fi

if [[ "$BACKUP_ONLY" == 1 ]]; then
  log "PASS development backup snapshot"
  write_completed_snapshot_result
  clear_in_progress_snapshot
  ok "development backup snapshot complete"
  info "Backup snapshot: $ARCHIVE_DIR"
else
  log "PASS clean development state"
  ok "development cleanup complete"
  info "Recovery archive: $ARCHIVE_DIR"
fi
ARCHIVE_COMPLETE=1
trap - EXIT
if [[ "$BACKUP_ONLY" != 1 ]]; then
  [[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && warn "1Password cloud vaults/keys still require the reviewed provider-side actions in high-risk-manual-actions.md."
  [[ "$PREPARE_KEYCHAIN_RESET" == 1 ]] && warn "The macOS Keychain was preserved; follow high-risk-manual-actions.md only after confirming credential recovery."
  warn "Restart the terminal. Remove stale Dock icons manually if macOS retains them."
fi
