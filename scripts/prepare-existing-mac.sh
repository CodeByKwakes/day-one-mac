#!/usr/bin/env bash
# Guided bridge from an existing account to the clean Day One Mac phases.
# Destructive work is delegated to clean-development-state.sh after additional
# backup, checksum and confirmation gates. Compatible with macOS Bash 3.2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLEAN_SCRIPT="$SCRIPT_DIR/clean-development-state.sh"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/apfs-volume.sh"
source "$SCRIPT_DIR/lib/container-data-paths.sh"
source "$SCRIPT_DIR/lib/rebuildable-paths.sh"
source "$SCRIPT_DIR/lib/platform.sh"

STATE_ROOT="$(day_one_state_root)"
BACKUP_SELECTION_FILE="$STATE_ROOT/existing-mac-backup-folder"
ROUTE_SELECTION_FILE="$STATE_ROOT/existing-mac-route"
SAFETY_REPORT_FILE="$STATE_ROOT/existing-mac-safety-report"
CLEANUP_OPTIONS_FILE="$STATE_ROOT/existing-mac-cleanup-options.tsv"
BACKUP_SNAPSHOT_FILE="$STATE_ROOT/existing-mac-backup-snapshot"
BACKUP_IN_PROGRESS_FILE="$STATE_ROOT/existing-mac-backup-in-progress"
RESTORE_CONFIRMATION_FILE="$STATE_ROOT/existing-mac-restore-confirmed"
PREVIEW_COMPLETION_FILE="$STATE_ROOT/existing-mac-cleanup-preview"
ROUTE_A_BACKUP_FILE="$STATE_ROOT/existing-mac-route-a-backup-confirmed"
LAST_RESULT_FILE="$STATE_ROOT/existing-mac-last-result"
REPORT_AUTODISCOVERY_DISABLED_FILE="$STATE_ROOT/existing-mac-report-autodiscovery-disabled"
GUIDED=0
MODE=preview
MODE_EXPLICIT=0
ARCHIVE_ROOT=""
REPORT_DIR=""
BACKUP_VOLUME=""
BACKUP_FOLDER_NAME=""
VERIFIED_MOUNT_POINT=""
ARCHIVE_PROJECTS=0
ARCHIVE_DOCKER_DATA=0
ARCHIVE_ORBSTACK_DATA=0
ARCHIVE_1PASSWORD_DATA=0
ARCHIVE_SSH_PRIVATE_KEYS=0
ARCHIVE_REBUILDABLE_CACHES=0
PREPARE_KEYCHAIN_RESET=0
ZAP_CASK_DATA=0

usage() {
  cat <<'EOF'
Usage: ./prepare-existing-mac.sh [options]

Recommended for everyone:

  ./prepare-existing-mac.sh --guided

The wizard first asks which result you want:

  Route A — erase the Mac with Apple's Erase All Content and Settings
  Route B — keep this macOS user account and remove known development setup

Both routes start with a safety report: a read-only list of applications,
repositories, packages, containers and important settings. Older documentation
may call this report a "preflight audit". It is a checklist, not a backup.

Friendly options:
  --guided                    open the resumable Route A / Route B dashboard;
                              it stays open after each safe step and detects
                              an incomplete Step 5 on mounted backup drives
  --status                    print saved Stage 0 gates and paths, then stop
  --safety-report             create the read-only safety report and stop
  --prepare-backup-folder     verify an external drive and create a backup folder
  --backup-volume ABS_PATH    mounted external volume used by the option above
  --backup-folder-name NAME   folder name; omit to use computer name and local time
  --dry-run                   preview Route B without changing anything (default)
  --apply                     perform cleanup after all safety gates pass
  --archive-root ABS_PATH     existing folder on an encrypted external APFS volume
  --preflight-report ABS_PATH completed safety report inside the archive root
  --archive-projects          move ~/Developer into the recovery archive
  --archive-docker-data       move known Docker Desktop data
  --archive-orbstack-data     move known OrbStack data
  --archive-container-data    compatibility alias that selects both options above
  --archive-1password-data    move known local 1Password application data
  --archive-ssh-private-keys  move detected private key files from ~/.ssh
  --archive-rebuildable-caches
                              include downloaded runtimes, package caches, pnpm
                              store and full VS Code local data in Step 3
  --prepare-keychain-reset    write manual Keychain reset instructions only
  --zap-cask-data             ask Homebrew to remove cask support-data paths
  -h, --help                  show this help

Compatibility options for older commands:
  --audit-only                same as --safety-report
  --audit ABS_PATH            same as --preflight-report

Important safety boundary:
This script never erases or formats a disk. Route A hands control to Apple's
System Settings. Route B preserves the user account, FileVault state and
applications that Homebrew does not own. Applying Route B archives known
development settings, removes Homebrew formulae and casks, then removes
Homebrew itself.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
die() {
  ui_error "$@"
  if [[ "${GUIDED:-0}" == 1 ]]; then
    record_last_result "✗ $*" 2>/dev/null || true
  fi
  exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

ensure_progress_state() {
  mkdir -p "$STATE_ROOT"
  chmod 700 "$STATE_ROOT"
}

save_progress_value() {
  local path="$1" value="$2" tmp
  ensure_progress_state
  tmp="$(mktemp "$STATE_ROOT/.existing-mac-progress.XXXXXX")"
  printf '%s\n' "$value" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$path"
}

progress_value() {
  [[ -r "$1" ]] && sed -n '1p' "$1" || true
}

checksum_directory_is_valid() {
  local directory="$1"
  [[ -d "$directory" && -s "$directory/SHA256SUMS.txt" ]] || return 1
  (cd "$directory" && shasum -a 256 -c SHA256SUMS.txt >/dev/null 2>&1)
}

safety_report_is_complete() {
  local directory="${1:-$(progress_value "$SAFETY_REPORT_FILE")}"
  [[ -n "$directory" && -s "$directory/SUMMARY.md" ]] || return 1
  checksum_directory_is_valid "$directory"
}

adopt_existing_safety_report() {
  local candidate search_root saved_root
  safety_report_is_complete && return 0
  [[ ! -e "$REPORT_AUTODISCOVERY_DISABLED_FILE" ]] || return 0
  saved_root="$(progress_value "$BACKUP_SELECTION_FILE")"
  for search_root in "$STATE_ROOT/preflight" "$saved_root"; do
    [[ -n "$search_root" && -d "$search_root" ]] || continue
    while IFS= read -r candidate; do
      [[ -n "$candidate" ]] || continue
      if safety_report_is_complete "$candidate"; then
        save_progress_value "$SAFETY_REPORT_FILE" "$candidate"
        ok "found and recorded an existing completed safety report: $candidate"
        return 0
      fi
    done < <(find "$search_root" -mindepth 1 -maxdepth 1 -type d \
      -name 'Safety Report - *' -print 2>/dev/null | LC_ALL=C sort -r)
  done
  return 0
}

cleanup_scope_fingerprint() {
  {
    printf 'projects=%s\n' "$ARCHIVE_PROJECTS"
    printf 'docker=%s\n' "$ARCHIVE_DOCKER_DATA"
    printf 'orbstack=%s\n' "$ARCHIVE_ORBSTACK_DATA"
    printf 'onepassword=%s\n' "$ARCHIVE_1PASSWORD_DATA"
    printf 'ssh=%s\n' "$ARCHIVE_SSH_PRIVATE_KEYS"
    printf 'rebuildable-caches=%s\n' "$ARCHIVE_REBUILDABLE_CACHES"
    printf 'keychain=%s\n' "$PREPARE_KEYCHAIN_RESET"
    printf 'zap=%s\n' "$ZAP_CASK_DATA"
    printf 'cleanup-script=%s\n' "$(shasum -a 256 "$CLEAN_SCRIPT" | awk '{print $1}')"
    printf 'container-paths=%s\n' "$(shasum -a 256 "$SCRIPT_DIR/lib/container-data-paths.sh" | awk '{print $1}')"
    printf 'rebuildable-paths=%s\n' "$(shasum -a 256 "$SCRIPT_DIR/lib/rebuildable-paths.sh" | awk '{print $1}')"
  } | shasum -a 256 | awk '{print $1}'
}

backup_snapshot_is_current() {
  local snapshot scope expected actual
  snapshot="$(progress_value "$BACKUP_SNAPSHOT_FILE")"
  scope="$(sed -n '2p' "$BACKUP_SNAPSHOT_FILE" 2>/dev/null || true)"
  [[ -n "$snapshot" && "$scope" == "$(cleanup_scope_fingerprint)" ]] || return 1
  [[ -s "$snapshot/README.md" && -s "$snapshot/SHA256SUMS.txt" \
     && -s "$snapshot/SNAPSHOT-COMPLETE" && ! -e "$snapshot/INCOMPLETE.md" ]] || return 1
  expected="$(awk -F '\t' '$1 == "manifest-sha256" { print $2; exit }' "$snapshot/SNAPSHOT-COMPLETE" 2>/dev/null || true)"
  actual="$(shasum -a 256 "$snapshot/SHA256SUMS.txt" 2>/dev/null | awk '{print $1}' || true)"
  [[ -n "$expected" && "$expected" == "$actual" ]]
}

restore_confirmation_is_current() {
  local expected
  backup_snapshot_is_current || return 1
  expected="$(progress_value "$BACKUP_SNAPSHOT_FILE")|$(cleanup_scope_fingerprint)"
  [[ "$(progress_value "$RESTORE_CONFIRMATION_FILE")" == "$expected" ]]
}

cleanup_preview_fingerprint() {
  printf '%s|%s|%s\n' "$(progress_value "$BACKUP_SELECTION_FILE")" \
    "$(progress_value "$SAFETY_REPORT_FILE")" "$(cleanup_scope_fingerprint)" \
    | shasum -a 256 | awk '{print $1}'
}

cleanup_preview_is_current() {
  [[ "$(progress_value "$PREVIEW_COMPLETION_FILE")" == "$(cleanup_preview_fingerprint)" ]]
}

record_last_result() {
  save_progress_value "$LAST_RESULT_FILE" "$1"
}

last_result_text() {
  [[ -r "$LAST_RESULT_FILE" ]] && /bin/cat "$LAST_RESULT_FILE" || true
}

backup_folder_status_reason() {
  local root report
  root="$(progress_value "$BACKUP_SELECTION_FILE")"
  report="$(progress_value "$SAFETY_REPORT_FILE")"
  if [[ -z "$root" ]]; then
    printf 'No backup folder was recorded. The drive or folder check stopped before completion.'
  elif [[ ! -d "$root" ]]; then
    printf 'The recorded backup folder is unavailable. Unlock or reconnect its drive: %s' "$root"
  elif [[ ! -w "$root" ]]; then
    printf 'The recorded backup folder is not writable: %s' "$root"
  elif [[ -z "$report" ]]; then
    printf 'No completed safety report is recorded. Re-run Step 1.'
  else
    case "$report/" in
      "$root/"*)
        if [[ ! -s "$report/SUMMARY.md" || ! -s "$report/SHA256SUMS.txt" ]]; then
          printf 'The report copy is incomplete inside the backup folder: %s' "$report"
        elif ! checksum_directory_is_valid "$report"; then
          printf 'The report copy failed checksum verification: %s' "$report"
        else
          printf 'The saved paths look complete; re-run Step 2 to repeat the external-drive verification.'
        fi
        ;;
      *) printf 'The current safety report was not copied inside the selected backup folder.' ;;
    esac
  fi
}

dashboard_status_text() {
  local route="$1" report_done backup_done snapshot_done restore_done preview_done full_done
  local saved_report saved_backup saved_snapshot saved_in_progress last_result incomplete_cleanup
  report_done=0; backup_done=0; snapshot_done=0; restore_done=0; preview_done=0; full_done=0
  safety_report_is_complete && report_done=1
  backup_folder_is_ready && backup_done=1
  backup_snapshot_is_current && snapshot_done=1
  restore_confirmation_is_current && restore_done=1
  cleanup_preview_is_current && preview_done=1
  route_a_backup_is_current && full_done=1
  saved_report="$(progress_value "$SAFETY_REPORT_FILE")"
  saved_backup="$(progress_value "$BACKUP_SELECTION_FILE")"
  saved_snapshot="$(progress_value "$BACKUP_SNAPSHOT_FILE")"
  saved_in_progress="$(progress_value "$BACKUP_IN_PROGRESS_FILE")"
  last_result="$(last_result_text)"

  printf 'Saved completion status\n'
  printf '  %s Step 1 — safety report\n' "$([[ "$report_done" == 1 ]] && printf '✓' || printf '○')"
  printf '  %s Step 2 — encrypted folder and verified report copy\n' "$([[ "$backup_done" == 1 ]] && printf '✓' || printf '○')"
  if [[ "$route" == route_b ]]; then
    printf '  %s Step 3a — copy-only snapshot\n' "$([[ "$snapshot_done" == 1 ]] && printf '✓' || printf '○')"
    printf '  %s Step 3b — restored sample confirmed\n' "$([[ "$restore_done" == 1 ]] && printf '✓' || printf '○')"
    printf '  %s Step 4 — cleanup preview\n' "$([[ "$preview_done" == 1 ]] && printf '✓' || printf '○')"
  else
    printf '  %s Step 3 — complete backup and restored sample confirmed\n' "$([[ "$full_done" == 1 ]] && printf '✓' || printf '○')"
  fi

  if [[ "$route" == route_b ]]; then
    printf '\nSelected backup and cleanup scope\n'
    printf '  [%s] ~/Developer\n' "$([[ "$ARCHIVE_PROJECTS" == 1 ]] && printf x || printf ' ')"
    printf '  [%s] Docker Desktop local data\n' "$([[ "$ARCHIVE_DOCKER_DATA" == 1 ]] && printf x || printf ' ')"
    printf '  [%s] OrbStack local data\n' "$([[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]] && printf x || printf ' ')"
    printf '  [%s] local 1Password application data\n' "$([[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && printf x || printf ' ')"
    printf '  [%s] detected SSH private keys\n' "$([[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]] && printf x || printf ' ')"
    printf '  [%s] rebuildable tool downloads and caches in Step 3\n' "$([[ "$ARCHIVE_REBUILDABLE_CACHES" == 1 ]] && printf x || printf ' ')"
  fi

  printf '\nSaved paths\n'
  if [[ -n "$saved_report" ]]; then printf '  Safety report: %s\n' "$saved_report"
  else printf '  Safety report: not recorded\n'; fi
  if [[ -n "$saved_backup" ]]; then printf '  Backup folder: %s\n' "$saved_backup"
  else printf '  Backup folder: not recorded\n'; fi
  if [[ "$route" == route_b && -n "$saved_snapshot" ]]; then
    printf '  Latest snapshot: %s\n' "$saved_snapshot"
  elif [[ "$route" == route_b && -n "$saved_in_progress" ]]; then
    printf '  Resumable incomplete snapshot: %s\n' "$saved_in_progress"
  fi
  if [[ "$route" == route_b ]]; then
    incomplete_cleanup="$(latest_incomplete_cleanup_path || true)"
    if [[ -n "$incomplete_cleanup" ]]; then
      printf '  Incomplete Step 5 recovery: %s\n' "$incomplete_cleanup"
    fi
  fi

  if [[ -n "$last_result" ]]; then
    printf '\nLast result\n  %s\n' "$last_result"
  fi
  if [[ "$report_done" == 1 && "$backup_done" != 1 ]]; then
    printf '\nWhy Step 2 is not complete\n  %s\n' "$(backup_folder_status_reason)"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --guided) GUIDED=1 ;;
    --status) MODE=status; MODE_EXPLICIT=1 ;;
    --safety-report|--audit-only) MODE=report; MODE_EXPLICIT=1 ;;
    --prepare-backup-folder) MODE=backup_folder; MODE_EXPLICIT=1 ;;
    --backup-volume)
      shift; [[ $# -gt 0 ]] || die '--backup-volume needs a path'; BACKUP_VOLUME="$1"
      ;;
    --backup-folder-name)
      shift; [[ $# -gt 0 ]] || die '--backup-folder-name needs a name'; BACKUP_FOLDER_NAME="$1"
      ;;
    --dry-run) MODE=preview; MODE_EXPLICIT=1 ;;
    --apply) MODE=apply; MODE_EXPLICIT=1 ;;
    --archive-root)
      shift; [[ $# -gt 0 ]] || die '--archive-root needs a path'; ARCHIVE_ROOT="$1"
      ;;
    --preflight-report|--audit)
      shift; [[ $# -gt 0 ]] || die '--preflight-report needs a path'; REPORT_DIR="$1"
      ;;
    --archive-projects) ARCHIVE_PROJECTS=1 ;;
    --archive-docker-data) ARCHIVE_DOCKER_DATA=1 ;;
    --archive-orbstack-data) ARCHIVE_ORBSTACK_DATA=1 ;;
    --archive-container-data) ARCHIVE_DOCKER_DATA=1; ARCHIVE_ORBSTACK_DATA=1 ;;
    --archive-1password-data) ARCHIVE_1PASSWORD_DATA=1 ;;
    --archive-ssh-private-keys) ARCHIVE_SSH_PRIVATE_KEYS=1 ;;
    --archive-rebuildable-caches) ARCHIVE_REBUILDABLE_CACHES=1 ;;
    --prepare-keychain-reset) PREPARE_KEYCHAIN_RESET=1 ;;
    --zap-cask-data) ZAP_CASK_DATA=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

day_one_require_apple_silicon || die 'Stage 0 supports native Apple-silicon Macs only.'
[[ -x "$CLEAN_SCRIPT" ]] || die "Cleanup engine is missing or not executable: $CLEAN_SCRIPT"

SINGLE_VALUES=()
SINGLE_LABELS=()
SINGLE_RESULT=""
select_one() {
  local heading="$1" default_index="$2" cursor key rest item marker radio
  cursor="$default_index"
  while :; do
    [[ -t 1 ]] && printf '\033[2J\033[H'
    ui_banner '🧭' 'Day One Mac — prepare an existing Mac'
    printf '%s\n\n' "$heading"
    printf '  Up/Down or j/k: move   Space or Enter: accept   q: quit\n\n'
    for ((item=0; item<${#SINGLE_VALUES[@]}; item++)); do
      marker=' '; radio='( )'
      [[ "$item" == "$cursor" ]] && marker='>' && radio='(●)'
      if [[ "$item" == "$cursor" ]]; then
        printf ' %s%s%s %s %s%s\n' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN" "$marker" "$radio" "${SINGLE_LABELS[$item]}" "$DAY_ONE_UI_RESET"
      else
        printf ' %s %s %s\n' "$marker" "$radio" "${SINGLE_LABELS[$item]}"
      fi
    done
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then IFS= read -rsn2 rest || true; key="$key$rest"; fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#SINGLE_VALUES[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#SINGLE_VALUES[@]}" ]] || cursor=0 ;;
      ' '|"") SINGLE_RESULT="${SINGLE_VALUES[$cursor]}"; [[ -t 1 ]] && printf '\033[2J\033[H'; return 0 ;;
      q|Q) exit 0 ;;
    esac
  done
}

MENU_VALUES=()
MENU_LABELS=()
MENU_SELECTED=()
select_toggles() {
  local heading="$1" cursor=0 key rest item marker check
  while :; do
    [[ -t 1 ]] && printf '\033[2J\033[H'
    ui_banner '🧭' 'Day One Mac — prepare an existing Mac'
    printf '%s\n\n' "$heading"
    printf '  Up/Down or j/k: move   Space: toggle   Enter: accept   q: quit\n\n'
    for ((item=0; item<${#MENU_VALUES[@]}; item++)); do
      marker=' '; check='[ ]'
      [[ "$item" == "$cursor" ]] && marker='>'
      [[ "${MENU_SELECTED[$item]}" == 1 ]] && check='[x]'
      if [[ "$item" == "$cursor" ]]; then
        printf ' %s%s%s %s %s%s\n' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN" "$marker" "$check" "${MENU_LABELS[$item]}" "$DAY_ONE_UI_RESET"
      else
        printf ' %s %s %s\n' "$marker" "$check" "${MENU_LABELS[$item]}"
      fi
    done
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then IFS= read -rsn2 rest || true; key="$key$rest"; fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#MENU_VALUES[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#MENU_VALUES[@]}" ]] || cursor=0 ;;
      ' ')
        if [[ "${MENU_SELECTED[$cursor]}" == 1 ]]; then MENU_SELECTED[$cursor]=0; else MENU_SELECTED[$cursor]=1; fi
        ;;
      "") [[ -t 1 ]] && printf '\033[2J\033[H'; return 0 ;;
      q|Q) exit 0 ;;
    esac
  done
}

count_lines() {
  local value="$1"
  [[ -n "$value" ]] || { printf '0'; return; }
  printf '%s\n' "$value" | awk 'NF { count++ } END { print count+0 }'
}

path_status() {
  if [[ -e "$1" || -L "$1" ]]; then
    du -sh "$1" 2>/dev/null | awk '{print $1}' || printf 'present'
  else
    printf 'not detected'
  fi
}

paths_status() {
  local target size total=0 found=0 unreadable=0
  for target in "$@"; do
    [[ -e "$target" || -L "$target" ]] || continue
    found=1
    size="$(du -sk "$target" 2>/dev/null | awk 'NR == 1 { print $1 }' || true)"
    case "$size" in
      ''|*[!0-9]*) unreadable=1 ;;
      *) total=$((total + size)) ;;
    esac
  done
  if [[ "$found" == 0 ]]; then
    printf 'not detected'
  elif [[ "$total" == 0 && "$unreadable" == 1 ]]; then
    printf 'present; size unavailable'
  else
    awk -v kb="$total" 'BEGIN {
      if (kb >= 1048576) printf "%.2f GiB", kb / 1048576;
      else if (kb >= 1024) printf "%.1f MiB", kb / 1024;
      else printf "%d KiB", kb;
    }'
    [[ "$unreadable" == 0 ]] || printf ' plus unreadable items'
  fi
}

print_route_a_handoff() {
  ui_title '🧼' 'Route A — erase the Mac with Apple'
  printf '\n'
  printf 'Use Route A when you want a truly clean account and do not need to keep\n'
  printf 'the current user, applications, settings or credentials on this Mac.\n\n'
  printf 'Before opening Apple\047s erase screen, confirm all of these:\n'
  printf '  [ ] The safety report was created and reviewed.\n'
  printf '  [ ] Important files are on an encrypted external backup.\n'
  printf '  [ ] You successfully restored a few sample files from that backup.\n'
  printf '  [ ] Dirty and NO-REMOTE Git repositories have a recovery plan.\n'
  printf '  [ ] You know the administrator and Apple Account passwords.\n\n'
  printf 'On macOS 26 or later, Apple also requires a repaired—or possibly repaired—\n'
  printf 'Apple-silicon Mac to finish Repair Assistant before erasing.\n\n'
  printf 'Then open:\n'
  printf '  System Settings > General > Transfer or Reset\n'
  printf '  > Erase All Content and Settings\n\n'
  printf 'This script cannot and will not press that button for you. After Apple\047s\n'
  printf 'Setup Assistant finishes, continue with Day One Mac Phase 1:\n'
  printf '  %s/required/01-first-boot-and-decisions.md\n' "$PROJECT_DIR"
}

confirm_repair_assistant_ready() {
  local answer
  printf '\nBefore the erase handoff, confirm that this Mac has no unfinished repair.\n'
  printf 'If it was repaired, or you are unsure, open Repair Assistant and complete it first.\n'
  printf 'Have you confirmed that no unfinished repair needs attention? [y/N]: '
  IFS= read -r answer
  case "$answer" in
    y|Y|yes|YES|Yes) return 0 ;;
    *) warn 'The erase handoff remains locked until the Repair Assistant check is complete.'; return 1 ;;
  esac
}

report_folder_stamp() {
  date '+%Y-%m-%d %H-%M-%S'
}

default_backup_folder_name() {
  local computer_name
  computer_name="$(/usr/sbin/scutil --get ComputerName 2>/dev/null || hostname -s 2>/dev/null || printf 'Mac')"
  computer_name="$(printf '%s' "$computer_name" | tr '/:\r\n\t' '-----' | sed -E 's/[[:space:]]+/ /g; s/^ +//; s/ +$//')"
  [[ -n "$computer_name" ]] || computer_name='Mac'
  printf '%s Backup - %s\n' "$computer_name" "$(date '+%Y-%m-%d %H-%M')"
}

load_cleanup_options_file() {
  local options_file="$1" key value legacy_container_data="" saw_docker=0 saw_orbstack=0
  [[ -r "$options_file" ]] || return 1
  while IFS=$'\t' read -r key value; do
    case "$value" in 0|1) ;; *) warn "Ignoring an invalid cleanup option in $options_file: $key"; return 2 ;; esac
    case "$key" in
      archive-projects) ARCHIVE_PROJECTS="$value" ;;
      archive-docker-data) ARCHIVE_DOCKER_DATA="$value"; saw_docker=1 ;;
      archive-orbstack-data) ARCHIVE_ORBSTACK_DATA="$value"; saw_orbstack=1 ;;
      archive-container-data) legacy_container_data="$value" ;;
      archive-1password-data) ARCHIVE_1PASSWORD_DATA="$value" ;;
      archive-ssh-private-keys) ARCHIVE_SSH_PRIVATE_KEYS="$value" ;;
      archive-rebuildable-caches) ARCHIVE_REBUILDABLE_CACHES="$value" ;;
      prepare-keychain-reset) PREPARE_KEYCHAIN_RESET="$value" ;;
      zap-cask-data) ZAP_CASK_DATA="$value" ;;
    esac
  done < "$options_file"
  # Older versions stored one combined choice. Adopt it only when the newer,
  # separate selections are absent so an in-progress Stage 0 remains safe.
  if [[ -n "$legacy_container_data" ]]; then
    [[ "$saw_docker" == 1 ]] || ARCHIVE_DOCKER_DATA="$legacy_container_data"
    [[ "$saw_orbstack" == 1 ]] || ARCHIVE_ORBSTACK_DATA="$legacy_container_data"
  fi
}

load_cleanup_options() {
  [[ -r "$CLEANUP_OPTIONS_FILE" ]] || return 0
  load_cleanup_options_file "$CLEANUP_OPTIONS_FILE"
}

reset_cleanup_options() {
  ARCHIVE_PROJECTS=0
  ARCHIVE_DOCKER_DATA=0
  ARCHIVE_ORBSTACK_DATA=0
  ARCHIVE_1PASSWORD_DATA=0
  ARCHIVE_SSH_PRIVATE_KEYS=0
  ARCHIVE_REBUILDABLE_CACHES=0
  PREPARE_KEYCHAIN_RESET=0
  ZAP_CASK_DATA=0
}

cleanup_recovery_is_resumable() {
  local recovery="$1"
  [[ -d "$recovery" && ! -L "$recovery" \
     && "$(basename "$recovery")" == Day-One-Mac-Clean-Recovery-* \
     && -s "$recovery/INCOMPLETE.md" \
     && -s "$recovery/operations.tsv" \
     && -s "$recovery/cleanup.log" \
     && -f "$recovery/homebrew-casks.txt" \
     && ! -e "$recovery/SNAPSHOT-COMPLETE" ]]
}

latest_incomplete_cleanup_path() {
  local saved_root search_root candidate candidate_mtime latest="" latest_mtime=0
  local candidates=()
  saved_root="$(progress_value "$BACKUP_SELECTION_FILE")"
  search_root="${DAY_ONE_MAC_RECOVERY_SEARCH_ROOT:-/Volumes}"
  if [[ -n "$saved_root" ]]; then
    candidates+=("$saved_root"/Day-One-Mac-Clean-Recovery-*)
  fi
  candidates+=(
    "$search_root"/Day-One-Mac-Clean-Recovery-*
    "$search_root"/*/Day-One-Mac-Clean-Recovery-*
    "$search_root"/*/*/Day-One-Mac-Clean-Recovery-*
  )
  for candidate in "${candidates[@]}"; do
    cleanup_recovery_is_resumable "$candidate" || continue
    candidate_mtime="$(/usr/bin/stat -f '%m' "$candidate/INCOMPLETE.md" 2>/dev/null || printf '0')"
    case "$candidate_mtime" in ''|*[!0-9]*) candidate_mtime=0 ;; esac
    if [[ "$candidate_mtime" -ge "$latest_mtime" ]]; then
      latest="$candidate"
      latest_mtime="$candidate_mtime"
    fi
  done
  [[ -n "$latest" ]] || return 1
  printf '%s\n' "$latest"
}

cleanup_options_source_for_recovery() {
  local recovery="$1" candidate
  for candidate in \
    "$recovery/cleanup-options.tsv" \
    "$recovery/home/.day-one-mac/existing-mac-cleanup-options.tsv" \
    "$recovery/home/.fresh-mac-setup/existing-mac-cleanup-options.tsv"; do
    [[ -s "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done
  return 1
}

load_cleanup_options_for_recovery() {
  local recovery="$1" options_source
  options_source="$(cleanup_options_source_for_recovery "$recovery" || true)"
  [[ -n "$options_source" ]] || return 1
  reset_cleanup_options
  load_cleanup_options_file "$options_source"
  info "restored the original cleanup choices from: $options_source"
}

save_cleanup_options() {
  local tmp
  ensure_progress_state
  tmp="$(mktemp "$STATE_ROOT/.existing-mac-options.XXXXXX")"
  {
    printf 'archive-projects\t%s\n' "$ARCHIVE_PROJECTS"
    printf 'archive-docker-data\t%s\n' "$ARCHIVE_DOCKER_DATA"
    printf 'archive-orbstack-data\t%s\n' "$ARCHIVE_ORBSTACK_DATA"
    # Compatibility record: older revisions safely select both when either
    # data set is selected. Current revisions use the two keys above.
    if [[ "$ARCHIVE_DOCKER_DATA" == 1 || "$ARCHIVE_ORBSTACK_DATA" == 1 ]]; then
      printf 'archive-container-data\t1\n'
    else
      printf 'archive-container-data\t0\n'
    fi
    printf 'archive-1password-data\t%s\n' "$ARCHIVE_1PASSWORD_DATA"
    printf 'archive-ssh-private-keys\t%s\n' "$ARCHIVE_SSH_PRIVATE_KEYS"
    printf 'archive-rebuildable-caches\t%s\n' "$ARCHIVE_REBUILDABLE_CACHES"
    printf 'prepare-keychain-reset\t%s\n' "$PREPARE_KEYCHAIN_RESET"
    printf 'zap-cask-data\t%s\n' "$ZAP_CASK_DATA"
  } > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$CLEANUP_OPTIONS_FILE"
}

choose_cleanup_scope() {
  local formula_count=0 cask_count=0 ssh_count=0
  load_cleanup_options
  if have brew; then
    formula_count="$(count_lines "$(HOMEBREW_NO_AUTO_UPDATE=1 brew list --formula 2>/dev/null || true)")"
    cask_count="$(count_lines "$(HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask 2>/dev/null || true)")"
  fi
  if [[ -d "$HOME/.ssh" ]]; then
    ssh_count="$(find "$HOME/.ssh" -type f -maxdepth 2 -exec sh -c 'grep -Il "BEGIN .*PRIVATE KEY" "$1" 2>/dev/null' _ {} \; 2>/dev/null | wc -l | tr -d ' ')"
  fi

  MENU_VALUES=(projects docker orbstack onepassword ssh caches keychain zap)
  MENU_LABELS=(
    "Include ~/Developer — $(path_status "$HOME/Developer")"
    "Include Docker Desktop local data — $(paths_status "${DAY_ONE_DOCKER_DATA_PATHS[@]}") across all known locations"
    "Include OrbStack local data — $(paths_status "${DAY_ONE_ORBSTACK_DATA_PATHS[@]}") across all known locations"
    "Include known local 1Password app data — $(path_status "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password")"
    "Include detected SSH private-key files — $ssh_count detected"
    "Include rebuildable tool downloads and caches — $(paths_status "${DAY_ONE_REBUILDABLE_DEV_PATHS[@]}"); optional and usually unnecessary"
    'Write the manual macOS login-Keychain reset guide (does not reset it)'
    "Use Homebrew cask zap lists during cleanup — $cask_count installed casks; review carefully"
  )
  MENU_SELECTED=("$ARCHIVE_PROJECTS" "$ARCHIVE_DOCKER_DATA" "$ARCHIVE_ORBSTACK_DATA" "$ARCHIVE_1PASSWORD_DATA" "$ARCHIVE_SSH_PRIVATE_KEYS" "$ARCHIVE_REBUILDABLE_CACHES" "$PREPARE_KEYCHAIN_RESET" "$ZAP_CASK_DATA")
  select_toggles "Choose the recovery scope. Most choices apply to backup and cleanup. The rebuildable-cache choice affects only Step 3 because final cleanup always moves those caches into recovery; $formula_count formulae and $cask_count casks are removed only during final apply:"
  ARCHIVE_PROJECTS="${MENU_SELECTED[0]}"
  ARCHIVE_DOCKER_DATA="${MENU_SELECTED[1]}"
  ARCHIVE_ORBSTACK_DATA="${MENU_SELECTED[2]}"
  ARCHIVE_1PASSWORD_DATA="${MENU_SELECTED[3]}"
  ARCHIVE_SSH_PRIVATE_KEYS="${MENU_SELECTED[4]}"
  ARCHIVE_REBUILDABLE_CACHES="${MENU_SELECTED[5]}"
  PREPARE_KEYCHAIN_RESET="${MENU_SELECTED[6]}"
  ZAP_CASK_DATA="${MENU_SELECTED[7]}"
  save_cleanup_options
}

guided_choices() {
  local saved_backup_root="" answer=""
  [[ "$GUIDED" == 1 ]] || return 0
  [[ -t 0 && -t 1 ]] || die '--guided requires an interactive terminal'

  [[ "$MODE" != report && "$MODE" != backup_folder ]] || return 0

  printf '\nRoute B selected — account-preserving development cleanup\n'
  printf 'The preview changes nothing. Apply requires the safety report, an encrypted\n'
  printf 'external APFS recovery folder, and a tested backup.\n'

  choose_cleanup_scope

  if [[ "$MODE" == apply ]]; then
    printf '\nStep 4 needs two folders that already exist on the same encrypted external drive:\n'
    printf '  1. recovery folder, for example /Volumes/Backup Drive/Day-One-Mac\n'
    printf '  2. safety-report folder copied inside that recovery folder\n'
    printf 'Enter each complete path without adding quote marks.\n\n'
    if [[ -z "$ARCHIVE_ROOT" && -s "$BACKUP_SELECTION_FILE" ]]; then
      saved_backup_root="$(sed -n '1p' "$BACKUP_SELECTION_FILE")"
      if [[ -d "$saved_backup_root" ]]; then
        printf 'Use the backup folder prepared in Step 2?\n  %s\nUse it? [Y/n]: ' "$saved_backup_root"
        IFS= read -r answer
        case "$answer" in n|N|no|NO|No) ;; *) ARCHIVE_ROOT="$saved_backup_root" ;; esac
      fi
    fi
    if [[ -z "$ARCHIVE_ROOT" ]]; then
      printf 'Recovery folder on the encrypted external APFS drive: '
      IFS= read -r ARCHIVE_ROOT
    fi
    if [[ -z "$REPORT_DIR" ]]; then
      printf 'Completed safety-report folder inside that recovery root: '
      IFS= read -r REPORT_DIR
    fi
  fi
}

validate_external_backup_root() {
  local missing_message="${1:-Enter a complete absolute path on the external backup drive.}"
  local plist container_plist whole_plist store_plist mount_point internal encrypted filesystem fs_lower
  local parent_disk physical physical_store store_parent container_reference mounted_device
  [[ -n "$ARCHIVE_ROOT" && "$ARCHIVE_ROOT" == /* ]] || die "$missing_message"
  [[ -d "$ARCHIVE_ROOT" && -w "$ARCHIVE_ROOT" ]] || die "Recovery root must already exist and be writable: $ARCHIVE_ROOT"
  ARCHIVE_ROOT="$(cd "$ARCHIVE_ROOT" && pwd -P)"
  [[ -x /usr/sbin/diskutil && -x /usr/bin/plutil ]] || die 'diskutil and plutil are required to verify the backup volume'
  mounted_device="$(mounted_device_for_path "$ARCHIVE_ROOT" || true)"
  [[ -n "$mounted_device" ]] \
    || die "Could not identify the mounted disk containing: $ARCHIVE_ROOT"
  plist="$(mktemp "${TMPDIR:-/tmp}/day-one-volume.XXXXXX")"
  if ! /usr/sbin/diskutil info -plist "$mounted_device" > "$plist" 2>/dev/null; then
    /bin/unlink "$plist" 2>/dev/null || true
    die "Could not inspect $mounted_device, which contains: $ARCHIVE_ROOT"
  fi
  mount_point="$(plist_raw "$plist" MountPoint)"
  internal="$(plist_raw "$plist" Internal)"
  encrypted="$(plist_raw "$plist" Encrypted)"
  [[ -n "$encrypted" ]] || encrypted="$(plist_raw "$plist" FileVault)"
  filesystem="$(plist_raw "$plist" FilesystemType)"
  [[ -n "$filesystem" ]] || filesystem="$(plist_raw "$plist" FileSystemPersonality)"
  parent_disk="$(plist_raw "$plist" ParentWholeDisk)"
  [[ -n "$parent_disk" ]] || parent_disk="$(plist_raw "$plist" DeviceIdentifier)"
  physical="$(plist_raw "$plist" VirtualOrPhysical)"
  physical_store="$(apfs_physical_store_from_plist "$plist" || true)"
  container_reference="$(plist_raw "$plist" APFSContainerReference)"
  container_plist="$(mktemp "${TMPDIR:-/tmp}/day-one-container-volume.XXXXXX")"
  whole_plist="$(mktemp "${TMPDIR:-/tmp}/day-one-whole-volume.XXXXXX")"
  store_plist="$(mktemp "${TMPDIR:-/tmp}/day-one-store-volume.XXXXXX")"

  # APFS volumes are presented through a synthesised virtual container even
  # when the storage is a real USB/Thunderbolt disk. Follow the APFS physical
  # store to its whole disk before deciding that the selected volume is a disk
  # image. Checking only ParentWholeDisk rejects valid external APFS drives.
  if [[ -z "$physical_store" && -n "$container_reference" ]] \
     && /usr/sbin/diskutil info -plist "$container_reference" > "$container_plist" 2>/dev/null; then
    physical_store="$(apfs_physical_store_from_plist "$container_plist" || true)"
  fi
  if [[ -n "$physical_store" ]] \
     && /usr/sbin/diskutil info -plist "$physical_store" > "$store_plist" 2>/dev/null; then
    store_parent="$(plist_raw "$store_plist" ParentWholeDisk)"
    [[ -n "$store_parent" ]] || store_parent="$(plist_raw "$store_plist" DeviceIdentifier)"
    if [[ -n "$store_parent" ]] \
       && /usr/sbin/diskutil info -plist "$store_parent" > "$whole_plist" 2>/dev/null; then
      internal="$(plist_raw "$whole_plist" Internal)"
      physical="$(plist_raw "$whole_plist" VirtualOrPhysical)"
    fi
  elif [[ -n "$parent_disk" ]] \
       && /usr/sbin/diskutil info -plist "$parent_disk" > "$whole_plist" 2>/dev/null; then
    internal="$(plist_raw "$whole_plist" Internal)"
    physical="$(plist_raw "$whole_plist" VirtualOrPhysical)"
  fi
  /bin/unlink "$plist" 2>/dev/null || true
  /bin/unlink "$container_plist" 2>/dev/null || true
  /bin/unlink "$whole_plist" 2>/dev/null || true
  /bin/unlink "$store_plist" 2>/dev/null || true
  fs_lower="$(printf '%s' "$filesystem" | tr '[:upper:]' '[:lower:]')"

  [[ "$mount_point" == /Volumes/* ]] || die "Recovery must be on a mounted external volume, not: ${mount_point:-unknown}"
  case "$internal" in false|0|No|NO|no) ;; *) die 'Recovery volume is reported as internal; use an external backup volume.' ;; esac
  if [[ "$physical" != Physical ]]; then
    if [[ -n "$container_reference" && -z "$physical_store" ]]; then
      die 'Could not identify the physical disk behind this APFS container. Keep the drive connected, run diskutil info for the selected volume, and retry; the safety check will not guess.'
    fi
    die 'The selected volume is backed by a virtual disk image, not a physical external drive. Choose the external APFS volume itself; valid APFS synthesised containers are followed to their physical store automatically.'
  fi
  case "$encrypted" in true|1|Yes|YES|yes) ;; *) die 'Recovery volume is not reported as encrypted.' ;; esac
  case "$fs_lower" in *apfs*) ;; *) die "Recovery volume must use encrypted APFS; detected: ${filesystem:-unknown}" ;; esac
  case "$ARCHIVE_ROOT/" in "$mount_point/"*) ;; *) die 'Recovery root is not below the verified mount point.' ;; esac
  VERIFIED_MOUNT_POINT="$mount_point"
  info "mounted disk: $mounted_device"
  [[ -z "$physical_store" ]] || info "APFS physical store: $physical_store"
  ok "encrypted external APFS recovery volume: $mount_point"
}

save_backup_root() {
  save_progress_value "$BACKUP_SELECTION_FILE" "$ARCHIVE_ROOT"
}

copy_safety_report_to_backup() {
  local source destination restore_probe
  source="$(progress_value "$SAFETY_REPORT_FILE")"
  if ! safety_report_is_complete "$source"; then
    warn 'No completed safety report is recorded yet; the backup folder is ready, but Step 1 must run before a snapshot can be created.'
    return 0
  fi
  case "$source/" in
    "$ARCHIVE_ROOT/"*) destination="$source" ;;
    *)
      destination="$ARCHIVE_ROOT/$(basename "$source")"
      if [[ -e "$destination" || -L "$destination" ]]; then
        if safety_report_is_complete "$destination"; then
          info "using the existing verified report copy: $destination"
        else
          destination="$ARCHIVE_ROOT/Safety Report - $(report_folder_stamp)"
          [[ ! -e "$destination" && ! -L "$destination" ]] \
            || die "A report destination already exists: $destination"
          /usr/bin/ditto "$source" "$destination"
        fi
      else
        /usr/bin/ditto "$source" "$destination"
      fi
      safety_report_is_complete "$destination" \
        || die 'The copied safety report failed checksum verification.'
      ok "copied and verified the safety report: $destination"
      ;;
  esac
  save_progress_value "$SAFETY_REPORT_FILE" "$destination"

  # Read one file back from the external volume into a temporary local file.
  # This catches a write-only or immediately unreadable destination without
  # pretending that it replaces the user's real project/document restore test.
  restore_probe="$(mktemp "${TMPDIR:-/tmp}/day-one-report-restore.XXXXXX")"
  /usr/bin/ditto "$destination/SUMMARY.md" "$restore_probe"
  cmp -s "$destination/SUMMARY.md" "$restore_probe" \
    || { /bin/unlink "$restore_probe" 2>/dev/null || true; die 'The automatic safety-report read-back test failed.'; }
  /bin/unlink "$restore_probe" 2>/dev/null || true
  ok 'automatic read-back test passed for the copied safety report'
}

prepare_backup_folder() {
  local action default_name target answer volume_list trimmed_name volume

  ui_title '🔐' 'Stage 0 Step 2 — prepare the encrypted backup folder'
  printf '\nThis step never formats or erases a drive. It checks that the selected\n'
  printf 'location is on a mounted, physical, external, encrypted APFS drive, then\n'
  printf 'creates or selects one folder for the Day One recovery data.\n\n'
  printf 'Need to encrypt or format a drive first? Read:\n'
  printf '  %s/preflight/ENCRYPTED-BACKUP-DRIVE.md\n\n' "$PROJECT_DIR"

  if [[ "$GUIDED" == 1 ]]; then
    SINGLE_VALUES=(create use_existing back)
    SINGLE_LABELS=(
      'Create a new named folder on the backup drive (recommended)'
      'Use an existing folder on the encrypted backup drive'
      'Return without creating or selecting a folder'
    )
    select_one 'Choose where Stage 0 should store the safety report and recovery data.' 0
    action="$SINGLE_RESULT"
    [[ "$action" != back ]] || exit 0
  else
    action=create
  fi

  if [[ "$action" == use_existing ]]; then
    [[ -t 0 && -t 1 ]] || die 'Selecting an existing folder requires an interactive terminal.'
    printf 'Complete existing folder path (for example /Volumes/Backup Drive/My Mac Backup): '
    IFS= read -r ARCHIVE_ROOT
    validate_external_backup_root
  else
    if [[ -z "$BACKUP_VOLUME" ]]; then
      [[ -t 0 && -t 1 ]] || die '--prepare-backup-folder needs --backup-volume outside the guided wizard'
      # Hidden service mounts such as /Volumes/.timemachine are not user backup
      # destinations and should never compete with a real external disk here.
      volume_list="$(find /Volumes -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print 2>/dev/null | LC_ALL=C sort || true)"
      SINGLE_VALUES=()
      SINGLE_LABELS=()
      if [[ -n "$volume_list" ]]; then
        while IFS= read -r volume; do
          [[ -n "$volume" ]] || continue
          SINGLE_VALUES+=("$volume")
          SINGLE_LABELS+=("$(basename "$volume") — $volume")
        done <<< "$volume_list"
      fi
      SINGLE_VALUES+=(manual_path back)
      SINGLE_LABELS+=(
        'Enter a different mounted-volume path'
        'Return without creating a folder'
      )
      select_one 'Select the mounted external backup drive. Its encryption and APFS status will be checked next.' 0
      case "$SINGLE_RESULT" in
        back) exit 0 ;;
        manual_path)
          printf 'Complete external volume path (for example /Volumes/Backup Drive): '
          IFS= read -r BACKUP_VOLUME
          ;;
        *) BACKUP_VOLUME="$SINGLE_RESULT" ;;
      esac
    fi

    ARCHIVE_ROOT="$BACKUP_VOLUME"
    validate_external_backup_root
    [[ "$ARCHIVE_ROOT" == "$VERIFIED_MOUNT_POINT" ]] \
      || die "Choose the volume itself, not a folder inside it: $VERIFIED_MOUNT_POINT"

    default_name="$(default_backup_folder_name)"
    if [[ -z "$BACKUP_FOLDER_NAME" ]]; then
      if [[ -t 0 && -t 1 ]]; then
        printf '\nBackup folder name [%s]: ' "$default_name"
        IFS= read -r BACKUP_FOLDER_NAME
      fi
      [[ -n "$BACKUP_FOLDER_NAME" ]] || BACKUP_FOLDER_NAME="$default_name"
    fi
    case "$BACKUP_FOLDER_NAME" in
      ''|.|..|*/*|*:*|*$'\n'*|*$'\r'*|*$'\t'*) die 'Folder name must be one plain name without /, :, tabs, or line breaks.' ;;
    esac
    trimmed_name="$(printf '%s' "$BACKUP_FOLDER_NAME" | sed -E 's/^ +//; s/ +$//')"
    [[ -n "$trimmed_name" && "$trimmed_name" == "$BACKUP_FOLDER_NAME" ]] \
      || die 'Folder name must not be empty or start or end with spaces.'
    target="$VERIFIED_MOUNT_POINT/$BACKUP_FOLDER_NAME"
    if [[ -e "$target" || -L "$target" ]]; then
      [[ -d "$target" && ! -L "$target" ]] || die "Backup target exists but is not a normal folder: $target"
      if [[ -t 0 && -t 1 ]]; then
        printf 'That folder already exists. Use it without replacing its contents? [y/N]: '
        IFS= read -r answer
        case "$answer" in y|Y|yes|YES|Yes) ;; *) die 'Existing folder was not selected; nothing was changed.' ;; esac
      else
        die "Backup folder already exists; select it interactively or choose another name: $target"
      fi
    else
      mkdir "$target"
      ok "created backup folder: $target"
    fi
    ARCHIVE_ROOT="$(cd "$target" && pwd -P)"
  fi

  save_backup_root
  copy_safety_report_to_backup
  printf '\n'
  ok 'backup folder is ready and saved'
  ui_label 'Folder' "$ARCHIVE_ROOT"
  ui_label 'Readable time' "$(date '+%Y-%m-%d %H:%M %Z')"
  printf '\nNext:\n'
  printf '  1. Choose the backup scope; the wizard will copy it without removing the source.\n'
  printf '  2. Restore and open at least one important project, document, or export.\n'
  printf '  3. Continue to the cleanup preview only after the restore test succeeds.\n'
}

offer_saved_backup_root_for_report() {
  local saved_backup_root answer
  [[ "$GUIDED" == 1 && -z "$ARCHIVE_ROOT" && -s "$BACKUP_SELECTION_FILE" ]] || return 0
  saved_backup_root="$(sed -n '1p' "$BACKUP_SELECTION_FILE")"
  [[ -d "$saved_backup_root" ]] || return 0
  printf '\nCreate this report directly in the backup folder prepared in Step 2?\n'
  printf '  %s\nUse it? [Y/n]: ' "$saved_backup_root"
  IFS= read -r answer
  case "$answer" in n|N|no|NO|No) ;; *) ARCHIVE_ROOT="$saved_backup_root" ;; esac
}

validate_safety_report() {
  [[ -n "$REPORT_DIR" && "$REPORT_DIR" == /* ]] \
    || die '--apply requires an absolute --preflight-report path (older name: --audit)'
  [[ -d "$REPORT_DIR" ]] || die "Safety report does not exist: $REPORT_DIR"
  REPORT_DIR="$(cd "$REPORT_DIR" && pwd -P)"
  case "$REPORT_DIR/" in "$ARCHIVE_ROOT/"*) ;; *) die 'The verified safety report must be stored inside the external recovery root.' ;; esac
  [[ -s "$REPORT_DIR/SUMMARY.md" && -s "$REPORT_DIR/SHA256SUMS.txt" ]] \
    || die 'The selected safety report is incomplete; SUMMARY.md or SHA256SUMS.txt is missing.'
  if ! (cd "$REPORT_DIR" && shasum -a 256 -c SHA256SUMS.txt >/dev/null); then
    die 'Safety-report checksum verification failed. Create or copy the report again.'
  fi
  ok 'safety report exists on the recovery volume and its checksums pass'
}

create_safety_report_step() {
  local output answer
  output="$STATE_ROOT/preflight/Safety Report - $(report_folder_stamp)"
  if safety_report_is_complete; then
    printf '\nA completed report is already recorded:\n  %s\n' "$(progress_value "$SAFETY_REPORT_FILE")"
    printf 'Create a new report and make it the current one? [y/N]: '
    IFS= read -r answer
    case "$answer" in y|Y|yes|YES|Yes) ;; *) return 0 ;; esac
  fi
  if DAY_ONE_MAC_EMBEDDED_PREFLIGHT=1 \
     "$SCRIPT_DIR/preflight-audit.sh" --guided --output "$output"; then
    if safety_report_is_complete "$output"; then
      save_progress_value "$SAFETY_REPORT_FILE" "$output"
      /bin/unlink "$REPORT_AUTODISCOVERY_DISABLED_FILE" 2>/dev/null || true
      ok 'Step 1 complete — safety report created, checked, and recorded'
      return 0
    else
      warn 'The report command ended without producing a complete report; Step 1 remains pending.'
      return 1
    fi
  else
    warn 'The safety report did not complete; no later step was unlocked.'
    return 1
  fi
}

reset_and_rerun_step_one() {
  local answer reset_dir marker moved=0
  printf '\nThis keeps every existing report and backup file. It only archives the\n'
  printf 'saved Step 1 marker and the later confirmations that depend on it.\n'
  printf 'Reset and immediately create a new safety report? [y/N]: '
  IFS= read -r answer
  case "$answer" in y|Y|yes|YES|Yes) ;; *) warn 'Step 1 was not reset.'; return 1 ;; esac

  ensure_progress_state
  reset_dir="$STATE_ROOT/reset-history/Step-1-$(date '+%Y-%m-%d-%H-%M-%S')-$$"
  mkdir -p "$reset_dir"
  chmod 700 "$STATE_ROOT/reset-history" "$reset_dir"
  for marker in \
    "$SAFETY_REPORT_FILE" "$BACKUP_SNAPSHOT_FILE" "$BACKUP_IN_PROGRESS_FILE" "$RESTORE_CONFIRMATION_FILE" \
    "$PREVIEW_COMPLETION_FILE" "$ROUTE_A_BACKUP_FILE"; do
    if [[ -e "$marker" || -L "$marker" ]]; then
      mv "$marker" "$reset_dir/$(basename "$marker")"
      moved=1
    fi
  done
  {
    printf 'Step 1 reset at %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf 'Only progress markers were archived. Report and backup payloads were preserved.\n'
  } > "$reset_dir/README.txt"
  chmod 600 "$reset_dir/README.txt"
  save_progress_value "$REPORT_AUTODISCOVERY_DISABLED_FILE" "$reset_dir"
  if [[ "$moved" == 1 ]]; then ok "archived old progress markers: $reset_dir"
  else info 'No older Step 1 progress marker was present.'; fi

  create_safety_report_step
}

build_cleanup_args() {
  local include_zap="${1:-1}"
  cleanup_args=(--archive-root "$ARCHIVE_ROOT")
  [[ "$ARCHIVE_PROJECTS" == 1 ]] && cleanup_args+=(--archive-projects)
  [[ "$ARCHIVE_DOCKER_DATA" == 1 ]] && cleanup_args+=(--archive-docker-data)
  [[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]] && cleanup_args+=(--archive-orbstack-data)
  [[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && cleanup_args+=(--archive-1password-data)
  [[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]] && cleanup_args+=(--archive-ssh-private-keys)
  [[ "$ARCHIVE_REBUILDABLE_CACHES" == 1 ]] && cleanup_args+=(--archive-rebuildable-caches)
  [[ "$PREPARE_KEYCHAIN_RESET" == 1 ]] && cleanup_args+=(--prepare-keychain-reset)
  [[ "$include_zap" == 1 && "$ZAP_CASK_DATA" == 1 ]] && cleanup_args+=(--zap-cask-data)
}

save_in_progress_snapshot() {
  local snapshot_path="$1" tmp
  ensure_progress_state
  tmp="$(mktemp "$STATE_ROOT/.existing-mac-in-progress.XXXXXX")"
  printf '%s\n%s\n' "$snapshot_path" "$(cleanup_scope_fingerprint)" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$BACKUP_IN_PROGRESS_FILE"
}

resumable_snapshot_path() {
  local candidate saved_scope
  candidate="$(progress_value "$BACKUP_IN_PROGRESS_FILE")"
  saved_scope="$(sed -n '2p' "$BACKUP_IN_PROGRESS_FILE" 2>/dev/null || true)"
  if [[ -n "$candidate" && "$saved_scope" == "$(cleanup_scope_fingerprint)" \
        && -d "$candidate" && -s "$candidate/README.md" \
        && -s "$candidate/operations.tsv" && ! -s "$candidate/SNAPSHOT-COMPLETE" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  # A legacy runner wrote the completed path only after its checksum process
  # exited. This makes the saved result safe to adopt even though that version
  # did not create the newer completion marker.
  candidate="$(progress_value "$BACKUP_SNAPSHOT_FILE")"
  if [[ -n "$candidate" && -d "$candidate" && -s "$candidate/README.md" \
        && -s "$candidate/operations.tsv" && -s "$candidate/SHA256SUMS.txt" \
        && ! -s "$candidate/SNAPSHOT-COMPLETE" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  # Compatibility for a checksum run interrupted under an older version that
  # did not yet record an in-progress path. Only copy-complete, explicitly
  # named snapshots directly inside the selected recovery folder are eligible.
  while IFS= read -r candidate; do
    [[ -d "$candidate" && -s "$candidate/README.md" \
       && -s "$candidate/operations.tsv" && ! -s "$candidate/SNAPSHOT-COMPLETE" ]] || continue
    if [[ -e "$candidate/INCOMPLETE.md" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(find "$ARCHIVE_ROOT" -mindepth 1 -maxdepth 1 -type d \
    -name 'Day-One-Mac-Backup-Snapshot-*' -print 2>/dev/null | LC_ALL=C sort -r)
  return 1
}

record_snapshot_scope() {
  local snapshot tmp
  snapshot="$(progress_value "$BACKUP_SNAPSHOT_FILE")"
  [[ -n "$snapshot" ]] || return 1
  tmp="$(mktemp "$STATE_ROOT/.existing-mac-snapshot.XXXXXX")"
  printf '%s\n%s\n' "$snapshot" "$(cleanup_scope_fingerprint)" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$BACKUP_SNAPSHOT_FILE"
}

confirm_backup_restore() {
  local snapshot probe answer expected
  backup_snapshot_is_current || { warn 'Create a current backup snapshot before confirming a restore.'; return 1; }
  snapshot="$(progress_value "$BACKUP_SNAPSHOT_FILE")"
  probe="$(mktemp "${TMPDIR:-/tmp}/day-one-snapshot-restore.XXXXXX")"
  /usr/bin/ditto "$snapshot/README.md" "$probe"
  if ! cmp -s "$snapshot/README.md" "$probe"; then
    /bin/unlink "$probe" 2>/dev/null || true
    warn 'The automatic snapshot read-back test failed.'
    return 1
  fi
  /bin/unlink "$probe" 2>/dev/null || true
  ok 'automatic read-back test passed for the backup snapshot'
  printf '\nNow restore and open at least one important project file, document, or\n'
  printf 'database export from this snapshot or your separate full backup.\n'
  printf 'Have you successfully opened a restored sample? [y/N]: '
  IFS= read -r answer
  case "$answer" in
    y|Y|yes|YES|Yes)
      expected="$snapshot|$(cleanup_scope_fingerprint)"
      save_progress_value "$RESTORE_CONFIRMATION_FILE" "$expected"
      ok 'restore test confirmed; Step 3 is complete'
      ;;
    *) warn 'Restore confirmation was not saved; cleanup remains locked.'; return 1 ;;
  esac
}

create_backup_snapshot_step() {
  local snapshot resume_snapshot answer snapshot_status
  ARCHIVE_ROOT="$(progress_value "$BACKUP_SELECTION_FILE")"
  REPORT_DIR="$(progress_value "$SAFETY_REPORT_FILE")"
  [[ -n "$ARCHIVE_ROOT" ]] || { warn 'Complete Step 2 before creating a snapshot.'; return 1; }
  validate_external_backup_root
  validate_safety_report
  choose_cleanup_scope
  build_cleanup_args 0
  printf '\nThis creates a second, copy-only snapshot. Source files and Homebrew remain unchanged.\n'
  resume_snapshot="$(resumable_snapshot_path || true)"
  if [[ -n "$resume_snapshot" ]]; then
    printf '\nA previous snapshot finished copying but its integrity checks did not finish:\n'
    printf '  %s\n' "$resume_snapshot"
    printf 'Resume its fast checksum pass without copying the source files again? [Y/n]: '
    IFS= read -r answer
    case "$answer" in
      n|N|no|NO|No) resume_snapshot="" ;;
      *) save_in_progress_snapshot "$resume_snapshot" ;;
    esac
  fi
  if [[ -z "$resume_snapshot" ]]; then save_in_progress_snapshot ''; fi

  if [[ -n "$resume_snapshot" ]]; then
    if "$CLEAN_SCRIPT" --backup-only --yes --resume-snapshot "$resume_snapshot" \
         --in-progress-file "$BACKUP_IN_PROGRESS_FILE" \
         --result-file "$BACKUP_SNAPSHOT_FILE" ${cleanup_args[@]+"${cleanup_args[@]}"}; then
      snapshot_status=0
    else
      snapshot_status=$?
    fi
  else
    if "$CLEAN_SCRIPT" --backup-only --in-progress-file "$BACKUP_IN_PROGRESS_FILE" \
         --result-file "$BACKUP_SNAPSHOT_FILE" ${cleanup_args[@]+"${cleanup_args[@]}"}; then
      snapshot_status=0
    else
      snapshot_status=$?
    fi
  fi
  if [[ "$snapshot_status" == 0 ]]; then
    record_snapshot_scope
    snapshot="$(progress_value "$BACKUP_SNAPSHOT_FILE")"
    if backup_snapshot_is_current; then
      ok "snapshot checksums pass: $snapshot"
      confirm_backup_restore || true
    else
      warn 'The snapshot finished but did not pass its recorded checksum gate.'
      return 1
    fi
  else
    if [[ -r "$BACKUP_IN_PROGRESS_FILE" ]]; then
      save_in_progress_snapshot "$(progress_value "$BACKUP_IN_PROGRESS_FILE")"
    fi
    warn 'The copy-only snapshot did not complete. No source file was removed.'
    return 1
  fi
}

preview_cleanup_step() {
  ARCHIVE_ROOT="$(progress_value "$BACKUP_SELECTION_FILE")"
  REPORT_DIR="$(progress_value "$SAFETY_REPORT_FILE")"
  restore_confirmation_is_current \
    || { warn 'Complete the copy-only snapshot and restore test before previewing cleanup.'; return 1; }
  validate_external_backup_root
  validate_safety_report
  build_cleanup_args 1
  if "$CLEAN_SCRIPT" ${cleanup_args[@]+"${cleanup_args[@]}"}; then
    save_progress_value "$PREVIEW_COMPLETION_FILE" "$(cleanup_preview_fingerprint)"
    ok 'cleanup preview complete and recorded; no source file was changed'
  else
    warn 'The cleanup preview failed and was not recorded as complete.'
    return 1
  fi
}

apply_cleanup_step() {
  local confirmation
  ARCHIVE_ROOT="$(progress_value "$BACKUP_SELECTION_FILE")"
  REPORT_DIR="$(progress_value "$SAFETY_REPORT_FILE")"
  restore_confirmation_is_current || die 'The current backup snapshot and restore test are incomplete.'
  cleanup_preview_is_current || die 'The cleanup scope changed or has not been previewed.'
  validate_external_backup_root
  validate_safety_report
  build_cleanup_args 1
  printf '\nThis is not a factory reset. It preserves the user account, macOS settings,\n'
  printf 'FileVault state and every application not owned by Homebrew.\n'
  printf 'Type ACCOUNT PRESERVING CLEANUP to continue to the cleanup engine: '
  IFS= read -r confirmation
  [[ "$confirmation" == 'ACCOUNT PRESERVING CLEANUP' ]] \
    || { warn 'Confirmation did not match; nothing was changed.'; return 1; }
  exec "$CLEAN_SCRIPT" --execute ${cleanup_args[@]+"${cleanup_args[@]}"}
}

resume_cleanup_step() {
  local recovery="$1" answer cleanup_status
  cleanup_recovery_is_resumable "$recovery" \
    || { warn 'The selected recovery is no longer incomplete or does not contain the required audit files.'; return 1; }
  ARCHIVE_ROOT="$(dirname "$recovery")"
  validate_external_backup_root

  ui_section '↻' 'Resume incomplete Step 5'
  printf '  Recovery: %s\n' "$recovery"
  if load_cleanup_options_for_recovery "$recovery"; then
    save_cleanup_options
  else
    warn 'The original cleanup choices could not be recovered automatically.'
    warn 'Review and select the exact choices used by the interrupted Step 5.'
    reset_cleanup_options
    choose_cleanup_scope
  fi
  printf '\nChoices that will be resumed\n'
  printf '  [%s] ~/Developer\n' "$([[ "$ARCHIVE_PROJECTS" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] Docker Desktop local data\n' "$([[ "$ARCHIVE_DOCKER_DATA" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] OrbStack local data\n' "$([[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] local 1Password application data\n' "$([[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] detected SSH private keys\n' "$([[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] manual Keychain reset guide\n' "$([[ "$PREPARE_KEYCHAIN_RESET" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] Homebrew cask zap\n' "$([[ "$ZAP_CASK_DATA" == 1 ]] && printf x || printf ' ')"
  printf '\nThis continues the same recovery folder. It does not repeat completed large moves.\n'
  printf 'Continue to the cleanup engine confirmations? [y/N]: '
  IFS= read -r answer
  case "$answer" in y|Y|yes|YES|Yes) ;; *) warn 'Resume cancelled; the recovery was not changed.'; return 10 ;; esac

  build_cleanup_args 1
  if "$CLEAN_SCRIPT" --execute --resume-cleanup "$recovery" ${cleanup_args[@]+"${cleanup_args[@]}"}; then
    ok 'The incomplete Step 5 cleanup resumed and completed successfully.'
    return 0
  else
    cleanup_status=$?
    warn 'Step 5 is still incomplete. Read the resume result shown above before retrying.'
    return "$cleanup_status"
  fi
}

backup_folder_is_ready() {
  local root report
  root="$(progress_value "$BACKUP_SELECTION_FILE")"
  report="$(progress_value "$SAFETY_REPORT_FILE")"
  [[ -d "$root" && -w "$root" ]] || return 1
  case "$report/" in "$root/"*) ;; *) return 1 ;; esac
  safety_report_is_complete "$report"
}

show_progress_details() {
  local value last_result
  printf '\nSaved completion status\n'
  if safety_report_is_complete; then printf '  ✓ Step 1 — safety report\n'; else printf '  ○ Step 1 — safety report\n'; fi
  if backup_folder_is_ready; then printf '  ✓ Step 2 — encrypted folder and report copy\n'; else printf '  ○ Step 2 — encrypted folder and report copy\n'; fi
  if backup_snapshot_is_current; then printf '  ✓ Step 3a — copy-only development snapshot\n'; else printf '  ○ Step 3a — copy-only development snapshot\n'; fi
  if restore_confirmation_is_current; then printf '  ✓ Step 3b — restore confirmed\n'; else printf '  ○ Step 3b — restore confirmation\n'; fi
  if cleanup_preview_is_current; then printf '  ✓ Step 4 — cleanup preview\n'; else printf '  ○ Step 4 — cleanup preview\n'; fi
  printf '\nSaved paths\n'
  value="$(progress_value "$SAFETY_REPORT_FILE")"
  [[ -n "$value" ]] && printf '  Safety report: %s\n' "$value"
  value="$(progress_value "$BACKUP_SELECTION_FILE")"
  [[ -n "$value" ]] && printf '  Backup folder: %s\n' "$value"
  value="$(progress_value "$BACKUP_SNAPSHOT_FILE")"
  [[ -n "$value" ]] && printf '  Latest snapshot: %s\n' "$value"
  last_result="$(last_result_text)"
  if [[ -n "$last_result" ]]; then
    printf '\nLast result\n  %s\n' "$last_result"
  fi
  if ! backup_folder_is_ready; then
    printf '\nWhy Step 2 is not complete\n  %s\n' "$(backup_folder_status_reason)"
  fi
  printf '\nSelected backup and cleanup scope\n'
  printf '  [%s] ~/Developer\n' "$([[ "$ARCHIVE_PROJECTS" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] Docker Desktop local data\n' "$([[ "$ARCHIVE_DOCKER_DATA" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] OrbStack local data\n' "$([[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] local 1Password application data\n' "$([[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] detected SSH private keys\n' "$([[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] manual Keychain reset guide\n' "$([[ "$PREPARE_KEYCHAIN_RESET" == 1 ]] && printf x || printf ' ')"
  printf '  [%s] Homebrew cask zap during final cleanup\n\n' "$([[ "$ZAP_CASK_DATA" == 1 ]] && printf x || printf ' ')"
}

prepare_or_recheck_backup_step() {
  local saved_root
  safety_report_is_complete || { warn 'Step 1 is required before preparing the backup folder.'; return 1; }
  saved_root="$(progress_value "$BACKUP_SELECTION_FILE")"
  if [[ -d "$saved_root" ]]; then
    (
      ARCHIVE_ROOT="$saved_root"
      validate_external_backup_root
      copy_safety_report_to_backup
      ok 'Step 2 complete — encrypted backup folder and safety report verified'
    ) || return 1
  else
    (prepare_backup_folder) || return 1
  fi
  backup_folder_is_ready
}

route_a_backup_is_current() {
  backup_folder_is_ready || return 1
  [[ "$(progress_value "$ROUTE_A_BACKUP_FILE")" == \
     "$(progress_value "$BACKUP_SELECTION_FILE")|$(progress_value "$SAFETY_REPORT_FILE")" ]]
}

confirm_route_a_backup() {
  local answer expected
  backup_folder_is_ready || { warn 'Complete Steps 1 and 2 before confirming the full Route A backup.'; return 1; }
  printf '\nRoute A erases this account, so the development snapshot alone is not enough.\n'
  printf 'Use Time Machine, Finder, or your approved backup tool to copy every important\n'
  printf 'document, photo, download, project, export, licence, and recovery record.\n'
  printf 'Have you restored and opened representative samples from that full backup? [y/N]: '
  IFS= read -r answer
  case "$answer" in
    y|Y|yes|YES|Yes)
      expected="$(progress_value "$BACKUP_SELECTION_FILE")|$(progress_value "$SAFETY_REPORT_FILE")"
      save_progress_value "$ROUTE_A_BACKUP_FILE" "$expected"
      ok 'Route A full-backup and restore confirmation recorded'
      ;;
    *) warn 'Confirmation was not saved; the Apple erase handoff remains locked.'; return 1 ;;
  esac
}

run_route_a_dashboard() {
  local report_done backup_done full_done default_index action heading
  while :; do
    report_done=0; backup_done=0; full_done=0
    safety_report_is_complete && report_done=1
    backup_folder_is_ready && backup_done=1
    route_a_backup_is_current && full_done=1
    SINGLE_VALUES=(report backup_folder full_backup handoff reset_step_one progress back exit)
    SINGLE_LABELS=(
      "$([[ "$report_done" == 1 ]] && printf '✓' || printf '○') Step 1 — create and review the safety report"
      "$([[ "$backup_done" == 1 ]] && printf '✓' || { [[ "$report_done" == 1 ]] && printf '○' || printf '🔒'; }) Step 2 — verify the encrypted drive and copy the report"
      "$([[ "$full_done" == 1 ]] && printf '✓' || { [[ "$backup_done" == 1 ]] && printf '○' || printf '🔒'; }) Step 3 — confirm the complete Route A backup and restore test"
      "$([[ "$full_done" == 1 ]] && printf '○' || printf '🔒') Step 4 — show Apple Erase All Content and Settings handoff"
      'Reset and re-run Step 1 — keeps old reports and backup files'
      'Show saved paths and completion details'
      'Change Route A / Route B choice'
      'Exit; progress remains saved'
    )
    if [[ "$report_done" != 1 ]]; then default_index=0
    elif [[ "$backup_done" != 1 ]]; then default_index=1
    elif [[ "$full_done" != 1 ]]; then default_index=2
    else default_index=3; fi
    heading="Route A progress — completed steps are marked ✓; locked steps are marked 🔒."
    heading="$heading"$'\n\n'"$(dashboard_status_text route_a)"
    select_one "$heading" "$default_index"
    action="$SINGLE_RESULT"
    case "$action" in
      report)
        record_last_result '⏳ Step 1 is running.'
        if create_safety_report_step; then record_last_result '✓ Step 1 completed and was recorded.'
        else
          [[ "$(last_result_text)" != '⏳ Step 1 is running.' ]] \
            || record_last_result '✗ Step 1 did not complete. Review the report error, then retry.'
        fi
        ;;
      backup_folder)
        record_last_result '⏳ Step 2 is checking the external drive and report copy.'
        if prepare_or_recheck_backup_step; then
          record_last_result '✓ Step 2 completed: the encrypted folder and report copy were verified.'
        else
          [[ "$(last_result_text)" != '⏳ Step 2 is checking the external drive and report copy.' ]] \
            || record_last_result "✗ Step 2 is incomplete. $(backup_folder_status_reason)"
        fi
        ;;
      full_backup)
        if confirm_route_a_backup; then record_last_result '✓ Step 3 completed: full backup and sample restore confirmed.'
        else record_last_result '⚠ Step 3 is incomplete: the full-backup restore confirmation was not saved.'; fi
        ;;
      handoff)
        if route_a_backup_is_current && confirm_repair_assistant_ready; then print_route_a_handoff; return 0
        else
          warn 'Complete Steps 1–3 and the Repair Assistant check before the erase handoff.'
          record_last_result '🔒 Step 4 is locked until backup and Repair Assistant checks are complete.'
        fi
        ;;
      reset_step_one)
        if reset_and_rerun_step_one; then
          record_last_result '✓ Step 1 was reset and a new safety report completed.'
        else
          [[ "$(last_result_text)" == '✓ Step 1 was reset and a new safety report completed.' ]] \
            || record_last_result '⚠ Step 1 reset/re-run did not complete. Existing reports and backup files were preserved.'
        fi
        ;;
      progress) show_progress_details; printf 'Press Enter to return: '; IFS= read -r _ ;;
      back) return 0 ;;
      exit) exit 0 ;;
    esac
  done
}

run_route_b_dashboard() {
  local report_done backup_done snapshot_done restore_done preview_done default_index action answer heading cleanup_status incomplete_cleanup
  while :; do
    load_cleanup_options
    report_done=0; backup_done=0; snapshot_done=0; restore_done=0; preview_done=0
    safety_report_is_complete && report_done=1
    backup_folder_is_ready && backup_done=1
    backup_snapshot_is_current && snapshot_done=1
    restore_confirmation_is_current && restore_done=1
    cleanup_preview_is_current && preview_done=1
    SINGLE_VALUES=(report backup_folder snapshot preview apply scope reset_step_one progress back exit)
    SINGLE_LABELS=(
      "$([[ "$report_done" == 1 ]] && printf '✓' || printf '○') Step 1 — create and review the safety report"
      "$([[ "$backup_done" == 1 ]] && printf '✓' || { [[ "$report_done" == 1 ]] && printf '○' || printf '🔒'; }) Step 2 — verify the encrypted drive and copy the report"
      "$([[ "$restore_done" == 1 ]] && printf '✓' || { [[ "$snapshot_done" == 1 ]] && printf '⚠' || { [[ "$backup_done" == 1 ]] && printf '○' || printf '🔒'; }; }) Step 3 — copy the selected backup snapshot and test a restore"
      "$([[ "$preview_done" == 1 ]] && printf '✓' || { [[ "$restore_done" == 1 ]] && printf '○' || printf '🔒'; }) Step 4 — preview exactly what cleanup would change"
      "$([[ "$preview_done" == 1 ]] && printf '○' || printf '🔒') Step 5 — apply the reviewed account-preserving cleanup"
      'Change what the backup snapshot and cleanup include'
      'Reset and re-run Step 1 — keeps old reports and backup files'
      'Show saved paths, scope, and completion details'
      'Change Route A / Route B choice'
      'Exit; progress remains saved'
    )
    incomplete_cleanup="$(latest_incomplete_cleanup_path || true)"
    if [[ -n "$incomplete_cleanup" ]]; then
      SINGLE_VALUES=(resume_cleanup "${SINGLE_VALUES[@]}")
      SINGLE_LABELS=("⚠ Resume latest incomplete Step 5 — $(basename "$incomplete_cleanup")" "${SINGLE_LABELS[@]}")
      default_index=0
    elif [[ "$report_done" != 1 ]]; then default_index=0
    elif [[ "$backup_done" != 1 ]]; then default_index=1
    elif [[ "$restore_done" != 1 ]]; then default_index=2
    elif [[ "$preview_done" != 1 ]]; then default_index=3
    else default_index=4; fi
    heading='Route B progress — the wizard stays open after each safe step. ✓ complete · ○ next · ⚠ needs confirmation · 🔒 locked'
    heading="$heading"$'\n\n'"$(dashboard_status_text route_b)"
    select_one "$heading" "$default_index"
    action="$SINGLE_RESULT"
    case "$action" in
      resume_cleanup)
        if (resume_cleanup_step "$incomplete_cleanup"); then
          exit 0
        else
          cleanup_status=$?
          warn 'The wizard is closing so it does not inspect paths that the resumed Step 5 may have archived.'
          exit "$cleanup_status"
        fi
        ;;
      report)
        record_last_result '⏳ Step 1 is running.'
        if create_safety_report_step; then record_last_result '✓ Step 1 completed and was recorded.'
        else
          [[ "$(last_result_text)" != '⏳ Step 1 is running.' ]] \
            || record_last_result '✗ Step 1 did not complete. Review the report error, then retry.'
        fi
        ;;
      backup_folder)
        record_last_result '⏳ Step 2 is checking the external drive and report copy.'
        if prepare_or_recheck_backup_step; then
          record_last_result '✓ Step 2 completed: the encrypted folder and report copy were verified.'
        else
          [[ "$(last_result_text)" != '⏳ Step 2 is checking the external drive and report copy.' ]] \
            || record_last_result "✗ Step 2 is incomplete. $(backup_folder_status_reason)"
        fi
        ;;
      snapshot)
        record_last_result '⏳ Step 3 is creating or checking the selected backup snapshot.'
        if backup_snapshot_is_current; then
          if restore_confirmation_is_current; then
            printf '\nThe current snapshot and restore confirmation already pass. Create a new snapshot? [y/N]: '
            IFS= read -r answer
            case "$answer" in y|Y|yes|YES|Yes) (create_backup_snapshot_step) || true ;; esac
          else
            (confirm_backup_restore) || true
          fi
        else
          (create_backup_snapshot_step) || true
        fi
        if restore_confirmation_is_current; then
          record_last_result '✓ Step 3 completed: snapshot checksums pass and a restored sample was confirmed.'
        elif backup_snapshot_is_current; then
          record_last_result '⚠ Step 3 needs confirmation: the snapshot passes, but a restored sample was not confirmed.'
        else
          [[ "$(last_result_text)" == '⏳ Step 3 is creating or checking the selected backup snapshot.' ]] \
            && record_last_result '✗ Step 3 did not produce a current verified snapshot.'
        fi
        ;;
      preview)
        record_last_result '⏳ Step 4 is creating a no-change cleanup preview.'
        if (preview_cleanup_step); then record_last_result '✓ Step 4 completed: cleanup was previewed without changing the Mac.'
        else
          [[ "$(last_result_text)" != '⏳ Step 4 is creating a no-change cleanup preview.' ]] \
            || record_last_result '✗ Step 4 did not complete. Finish the current backup and restore gates first.'
        fi
        ;;
      apply)
        if cleanup_preview_is_current && restore_confirmation_is_current; then
          if (apply_cleanup_step); then exit 0
          else
            cleanup_status=$?
            warn 'Cleanup did not complete. Review the final error and the INCOMPLETE.md recovery folder.'
            warn 'The wizard is closing now so it does not inspect paths that Step 5 may already have archived.'
            exit "$cleanup_status"
          fi
        else
          warn 'Complete Steps 1–4 with the current scope before applying cleanup.'
          record_last_result '🔒 Step 5 is locked until Steps 1–4 pass with the current cleanup scope.'
        fi
        ;;
      scope)
        choose_cleanup_scope
        warn 'Changing scope makes any older snapshot, restore confirmation, and preview stale.'
        record_last_result '⚠ Backup scope changed. Repeat Step 3 and Step 4 before cleanup can run.'
        ;;
      reset_step_one)
        if reset_and_rerun_step_one; then
          record_last_result '✓ Step 1 was reset and a new safety report completed.'
        else
          [[ "$(last_result_text)" == '✓ Step 1 was reset and a new safety report completed.' ]] \
            || record_last_result '⚠ Step 1 reset/re-run did not complete. Existing reports and backup files were preserved.'
        fi
        ;;
      progress) show_progress_details; printf 'Press Enter to return: '; IFS= read -r _ ;;
      back) return 0 ;;
      exit) exit 0 ;;
    esac
  done
}

run_guided_journey() {
  local saved_route default_index
  [[ -t 0 && -t 1 ]] || die '--guided requires an interactive terminal'
  adopt_existing_safety_report
  while :; do
    saved_route="$(progress_value "$ROUTE_SELECTION_FILE")"
    case "$saved_route" in route_a) default_index=0 ;; route_b) default_index=1 ;; *) default_index=2 ;; esac
    SINGLE_VALUES=(route_a route_b unsure exit)
    SINGLE_LABELS=(
      'Route A — erase the Mac and start with a blank account'
      'Route B — keep this user account and clean the development setup'
      'Not sure — create the safe, read-only report first'
      'Exit without changing anything'
    )
    select_one 'Choose the result you want. Saved progress is shown on the next screen.' "$default_index"
    case "$SINGLE_RESULT" in
      route_a) save_progress_value "$ROUTE_SELECTION_FILE" route_a; run_route_a_dashboard ;;
      route_b) save_progress_value "$ROUTE_SELECTION_FILE" route_b; run_route_b_dashboard ;;
      unsure) create_safety_report_step ;;
      exit) exit 0 ;;
    esac
  done
}

if [[ "$GUIDED" == 1 && "$MODE_EXPLICIT" != 1 ]]; then
  run_guided_journey
  exit 0
fi

if [[ "$MODE" == status ]]; then
  saved_status_route="$(progress_value "$ROUTE_SELECTION_FILE")"
  case "$saved_status_route" in
    route_a)
      status_route=route_a
      status_label='Route A — erase and start with a blank account'
      ;;
    route_b)
      status_route=route_b
      status_label='Route B — keep this account and clean development setup'
      ;;
    *)
      status_route=route_b
      status_label='No route saved yet — showing the longer Route B checklist'
      ;;
  esac
  load_cleanup_options
  ui_title '📍' 'Stage 0 saved progress'
  printf '  Route: %s\n\n' "$status_label"
  dashboard_status_text "$status_route"
  printf '\nRun ./prepare-existing-mac.sh --guided to continue.\n'
  exit 0
fi

guided_choices

if [[ "$MODE" == backup_folder ]]; then
  prepare_backup_folder
  exit 0
fi

if [[ "$MODE" == report ]]; then
  offer_saved_backup_root_for_report
  if [[ -n "$ARCHIVE_ROOT" ]]; then
    validate_external_backup_root
    if [[ "$GUIDED" == 1 ]]; then
      exec "$SCRIPT_DIR/preflight-audit.sh" --guided \
        --output "$ARCHIVE_ROOT/Safety Report - $(report_folder_stamp)"
    fi
    exec "$SCRIPT_DIR/preflight-audit.sh" \
      --output "$ARCHIVE_ROOT/Safety Report - $(report_folder_stamp)"
  fi
  if [[ "$GUIDED" == 1 ]]; then exec "$SCRIPT_DIR/preflight-audit.sh" --guided; fi
  exec "$SCRIPT_DIR/preflight-audit.sh"
fi

cleanup_args=()
[[ -n "$ARCHIVE_ROOT" ]] && cleanup_args+=(--archive-root "$ARCHIVE_ROOT")
[[ "$ARCHIVE_PROJECTS" == 1 ]] && cleanup_args+=(--archive-projects)
[[ "$ARCHIVE_DOCKER_DATA" == 1 ]] && cleanup_args+=(--archive-docker-data)
[[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]] && cleanup_args+=(--archive-orbstack-data)
[[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && cleanup_args+=(--archive-1password-data)
[[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]] && cleanup_args+=(--archive-ssh-private-keys)
[[ "$ARCHIVE_REBUILDABLE_CACHES" == 1 ]] && cleanup_args+=(--archive-rebuildable-caches)
[[ "$PREPARE_KEYCHAIN_RESET" == 1 ]] && cleanup_args+=(--prepare-keychain-reset)
[[ "$ZAP_CASK_DATA" == 1 ]] && cleanup_args+=(--zap-cask-data)

ui_title '📋' 'Existing-Mac preparation summary'
if [[ "$MODE" == preview ]]; then
  printf '  Route: B — keep this user account\n'
  printf '  Action: preview only; nothing will be changed\n'
else
  printf '  Route: B — keep this user account\n'
  printf '  Action: apply the reviewed cleanup\n'
fi
printf '  Startup disk erase/format: never\n'
printf '  Non-Homebrew applications: preserved\n'
printf '  Homebrew formulae and casks: removed only in apply mode\n'
printf '  Known development settings: archived only in apply mode\n'
printf '  ~/Developer: %s\n' "$([[ "$ARCHIVE_PROJECTS" == 1 ]] && printf 'archive' || printf 'keep')"
printf '  Docker Desktop data: %s\n' "$([[ "$ARCHIVE_DOCKER_DATA" == 1 ]] && printf 'archive' || printf 'keep')"
printf '  OrbStack data: %s\n' "$([[ "$ARCHIVE_ORBSTACK_DATA" == 1 ]] && printf 'archive' || printf 'keep')"
printf '  Local 1Password data: %s\n' "$([[ "$ARCHIVE_1PASSWORD_DATA" == 1 ]] && printf 'archive' || printf 'keep')"
printf '  SSH private keys: %s\n' "$([[ "$ARCHIVE_SSH_PRIVATE_KEYS" == 1 ]] && printf 'archive' || printf 'keep')"
printf '  Rebuildable tool caches in Step 3: %s\n' "$([[ "$ARCHIVE_REBUILDABLE_CACHES" == 1 ]] && printf 'include' || printf 'omit; reinstall inventories retained')"
printf '  Keychain: never changed automatically\n'

if [[ "$MODE" == preview ]]; then
  printf '\nThe cleanup engine will now print the exact current targets. Nothing is changed.\n'
  exec "$CLEAN_SCRIPT" ${cleanup_args[@]+"${cleanup_args[@]}"}
fi

validate_external_backup_root '--apply requires an absolute --archive-root'
validate_safety_report
[[ -t 0 && -t 1 ]] || die '--apply requires an interactive terminal'
printf '\nThis is not a factory reset. It preserves the user account, macOS settings,\n'
printf 'FileVault state and every application not owned by Homebrew.\n'
printf 'Type ACCOUNT PRESERVING CLEANUP to continue to the cleanup engine: '
IFS= read -r confirmation
[[ "$confirmation" == 'ACCOUNT PRESERVING CLEANUP' ]] || die 'Confirmation did not match; nothing was changed.'

exec "$CLEAN_SCRIPT" --execute ${cleanup_args[@]+"${cleanup_args[@]}"}
