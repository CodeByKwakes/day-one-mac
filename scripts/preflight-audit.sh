#!/usr/bin/env bash
# Build a private, read-only safety report before an existing Mac is cleaned or erased.
# The only change this script makes is creating the selected report directory.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"

STATE_ROOT="$(day_one_state_root)"
STAMP="$(date '+%Y-%m-%d %H-%M-%S')"
OUTPUT_DIR="$STATE_ROOT/preflight/Safety Report - $STAMP"
GUIDED=0
PLAN_ONLY=0
CHECK_LATEST_BACKUP=0
REPO_ROOTS=()
STATUS_FILE=""
COLLECTION_REVIEW=0

usage() {
  cat <<'EOF'
Usage: ./preflight-audit.sh [options]

Create the Stage 0 safety report before choosing either transition:

  Route A — erase the Mac with Apple's Erase All Content and Settings
  Route B — keep the user account and clean the known development setup

This read-only inventory is called a "preflight audit" in the script filename.
Here, audit simply means inspect and report. It does not remove applications,
change settings, stop containers, mount a backup, or copy file contents.

  --guided                    explain the safety report and ask before starting
  --output ABSOLUTE_PATH      private report directory (must be new or empty)
  --repo-root ABSOLUTE_PATH   repository search root; repeat for more roots
  --check-time-machine-latest also ask Time Machine for its latest backup;
                              this may mount the configured destination
  --plan                      explain what will be checked without writing a report
  -h, --help                  show this help

Without --repo-root, the report searches existing Developer, Projects, Code
and Sites folders. Reports contain usernames, paths, application names,
repository remotes and security status. Keep the directory private and never
commit it. This report is a checklist, not a backup.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
die() { ui_error "$@"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Guided runs end with a small, numbered menu rather than leaving the user to
# copy a generated path. Non-interactive runs never call this function, so
# automation keeps receiving ordinary output and cannot unexpectedly open an app.
review_completed_report() {
  local choice="" summary_file="$OUTPUT_DIR/SUMMARY.md"
  [[ "$GUIDED" == 1 && -t 0 && -t 1 ]] || return 0

  while :; do
    ui_title '📄' 'Review the completed safety report now?'
    printf '  1. Open SUMMARY.md in the default Mac app\n'
    printf '  2. Show SUMMARY.md here in Terminal\n'
    printf '  3. Finish without opening it\n\n'
    printf 'Choose 1, 2, or 3 [3]: '
    if ! IFS= read -r choice; then choice=3; fi
    case "$choice" in
      1)
        if /usr/bin/open "$summary_file"; then
          ok "opened: $summary_file"
        else
          warn 'The Mac could not open the report automatically.'
          info "Open it manually: $summary_file"
        fi
        return 0
        ;;
      2)
        printf '\n'
        /bin/cat "$summary_file"
        printf '\nEnd of safety report.\n'
        info "saved at: $summary_file"
        return 0
        ;;
      3|'')
        info "Report kept for later: $summary_file"
        return 0
        ;;
      *) warn 'Please type 1, 2, or 3.' ;;
    esac
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --guided) GUIDED=1 ;;
    --plan) PLAN_ONLY=1 ;;
    --check-time-machine-latest) CHECK_LATEST_BACKUP=1 ;;
    --output)
      shift
      [[ $# -gt 0 ]] || die '--output needs an absolute path'
      OUTPUT_DIR="$1"
      ;;
    --repo-root)
      shift
      [[ $# -gt 0 ]] || die '--repo-root needs an absolute path'
      [[ "$1" == /* ]] || die '--repo-root must be an absolute path'
      REPO_ROOTS+=("$1")
      ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

if [[ "$PLAN_ONLY" == 1 ]]; then
  ui_title '🛡️' 'Stage 0 Step 1 — safety report preview'
  printf 'Use this before Route A or Route B. It would create one private report containing:\n\n'
  printf '  • macOS, hardware, storage and FileVault status\n'
  printf '  • application bundles and Homebrew/package-manager inventory\n'
  printf '  • Git repositories, dirty worktrees and missing remotes\n'
  printf '  • startup items, system extensions and container metadata\n'
  printf '  • known configuration-path presence and collection status\n\n'
  printf 'It does not read personal-document or configuration contents, reveal environment-variable values,\n'
  printf 'mount Time Machine by default, stop software, or remove anything.\n'
  printf 'It is an inventory checklist, not a copy of your data and not proof of a usable backup.\n'
  printf '\nRecommended next command:\n  %s/prepare-existing-mac.sh --guided\n' "$SCRIPT_DIR"
  exit 0
fi

[[ "$(uname -s)" == Darwin ]] || die 'This audit supports macOS only.'
[[ "$HOME" == /* && "$HOME" != / && "$HOME" != /Users ]] || die "Unsafe HOME value: $HOME"
[[ "$OUTPUT_DIR" == /* ]] || die '--output must be an absolute path'
[[ "$OUTPUT_DIR" != / && "$OUTPUT_DIR" != /Users && "$OUTPUT_DIR" != "$HOME" ]] \
  || die "Report path is too broad: $OUTPUT_DIR"
case "$OUTPUT_DIR/" in
  "$PROJECT_DIR/"*) die 'Refusing to write a private audit inside the Git project.' ;;
esac

if [[ "${#REPO_ROOTS[@]}" -eq 0 ]]; then
  for candidate in "$HOME/Developer" "$HOME/Projects" "$HOME/Code" "$HOME/Sites" "$HOME/.local/share/chezmoi"; do
    [[ -d "$candidate" ]] && REPO_ROOTS+=("$candidate")
  done
fi

if [[ "$GUIDED" == 1 ]]; then
  [[ -t 0 && -t 1 ]] || die '--guided requires an interactive terminal'
  ui_title '🛡️' 'Stage 0 Step 1 — create the safety report'
  printf '\n'
  printf 'Use this step before either route:\n'
  printf '  Route A — erase the Mac and start with a blank account\n'
  printf '  Route B — keep this account and clean the development setup\n\n'
  printf '"Audit" in the filename means inspect and report. This step only creates\n'
  printf 'a private inventory; it does not clean, reset, or back up the Mac.\n\n'
  printf 'Report destination:\n  %s\n\n' "$OUTPUT_DIR"
  printf 'Create the safety report now? [Y/n]: '
  IFS= read -r answer
  case "$answer" in n|N|no|NO|No) exit 0 ;; esac
  if [[ "$CHECK_LATEST_BACKUP" != 1 ]]; then
    printf 'Allow Time Machine to check the latest backup? It may mount the destination. [y/N]: '
    IFS= read -r answer
    case "$answer" in y|Y|yes|YES|Yes) CHECK_LATEST_BACKUP=1 ;; esac
  fi
fi

if [[ -e "$OUTPUT_DIR" ]]; then
  [[ ! -L "$OUTPUT_DIR" ]] || die "Report directory must not be a symbolic link: $OUTPUT_DIR"
  [[ -d "$OUTPUT_DIR" ]] || die "Report path exists and is not a directory: $OUTPUT_DIR"
  [[ -z "$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]] \
    || die "Report directory is not empty: $OUTPUT_DIR"
else
  mkdir -p "$OUTPUT_DIR"
fi
chmod 700 "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd -P)"
case "$OUTPUT_DIR/" in
  "$PROJECT_DIR/"*) die 'Refusing to write a private audit inside the Git project.' ;;
esac
umask 077
STATUS_FILE="$OUTPUT_DIR/collection-status.tsv"
printf 'section\tstatus\tnote\n' > "$STATUS_FILE"

status() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$STATUS_FILE"
  [[ "$2" == PASS ]] || COLLECTION_REVIEW=$((COLLECTION_REVIEW + 1))
}

md_escape() {
  printf '%s' "$1" | tr '\t\r\n' '   ' | sed 's/|/\\|/g'
}

tsv_text() {
  printf '%s' "$1" | tr '\t\r\n' '   '
}

plist_value() {
  local plist="$1" key="$2" value=""
  if [[ -x /usr/bin/plutil ]]; then
    value="$(/usr/bin/plutil -extract "$key" raw -o - "$plist" 2>/dev/null || true)"
  fi
  if [[ -z "$value" && -x /usr/libexec/PlistBuddy ]]; then
    value="$(/usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true)"
  fi
  printf '%s' "$value"
}

ui_title '🔎' 'Stage 0 Step 1 — creating the safety report'
info 'read-only collection; no applications, settings, or data will be removed'
info "report: $OUTPUT_DIR"

{
  printf '# System and account\n\n'
  printf 'Collected: `%s`\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf '## macOS\n\n```text\n'
  sw_vers 2>/dev/null || true
  uname -m 2>/dev/null || true
  printf 'Computer name: %s\n' "$(scutil --get ComputerName 2>/dev/null || printf 'unavailable')"
  printf 'Account: %s\n' "$(id -un)"
  printf 'Groups: %s\n' "$(id -Gn 2>/dev/null || true)"
  printf '```\n\n## Hardware summary (identifiers redacted)\n\n```text\n'
  system_profiler SPHardwareDataType 2>/dev/null \
    | sed -E '/Serial Number|Hardware UUID|Provisioning UDID/d' || true
  printf '```\n\n## FileVault\n\n```text\n'
  fdesetup status 2>&1 || true
  printf '```\n\n## Mounted filesystems\n\n```text\n'
  df -h 2>&1 || true
  printf '```\n'
} > "$OUTPUT_DIR/system.md"
status system PASS 'system, account, FileVault and filesystem metadata collected'
ok 'system and account metadata'

APPLICATIONS_TSV="$OUTPUT_DIR/applications.tsv"
CASK_APP_MAP="$OUTPUT_DIR/.cask-app-map"
printf 'category\tname\tversion\tbundle_id\tpath\thomebrew_cask\n' > "$APPLICATIONS_TSV"
: > "$CASK_APP_MAP"
if have brew; then
  while IFS= read -r token; do
    while IFS= read -r cask_app; do
      printf '%s\t%s\n' "$(basename "$cask_app")" "$token" >> "$CASK_APP_MAP"
    done < <(HOMEBREW_NO_AUTO_UPDATE=1 brew info --cask "$token" 2>/dev/null \
      | sed -n 's/^[[:space:]]*\(.*\.app\) (App)$/\1/p' || true)
  done < <(HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask 2>/dev/null || true)
fi
app_count=0
homebrew_app_count=0
regular_app_count=0
user_app_count=0
system_app_count=0
other_app_count=0
for app_root in /Applications "$HOME/Applications" /System/Applications; do
  [[ -d "$app_root" ]] || continue
  while IFS= read -r app_path; do
    [[ -d "$app_path" ]] || continue
    plist="$app_path/Contents/Info.plist"
    name="$(plist_value "$plist" CFBundleDisplayName)"
    [[ -n "$name" ]] || name="$(plist_value "$plist" CFBundleName)"
    [[ -n "$name" ]] || name="$(basename "$app_path" .app)"
    version="$(plist_value "$plist" CFBundleShortVersionString)"
    [[ -n "$version" ]] || version="$(plist_value "$plist" CFBundleVersion)"
    bundle_id="$(plist_value "$plist" CFBundleIdentifier)"
    cask="$(awk -F $'\t' -v app="$(basename "$app_path")" '$1 == app { print $2; exit }' "$CASK_APP_MAP")"
    [[ -n "$cask" ]] || cask='-'
    if [[ "$cask" != '-' ]]; then
      category='Homebrew Applications'
      homebrew_app_count=$((homebrew_app_count + 1))
    elif [[ "$app_path" == /System/Applications/* ]]; then
      category='System Applications'
      system_app_count=$((system_app_count + 1))
    elif [[ "$app_path" == "$HOME/Applications/"* ]]; then
      category='User Applications'
      user_app_count=$((user_app_count + 1))
    elif [[ "$app_path" == /Applications/* ]]; then
      case "$app_path" in
        *'.app.back/'*|*'/Contents/'*)
          category='Embedded or Other Bundles'
          other_app_count=$((other_app_count + 1))
          ;;
        *)
          category='Applications'
          regular_app_count=$((regular_app_count + 1))
          ;;
      esac
    else
      category='Embedded or Other Bundles'
      other_app_count=$((other_app_count + 1))
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$category" "$(tsv_text "$name")" "$(tsv_text "${version:--}")" \
      "$(tsv_text "${bundle_id:--}")" "$(tsv_text "$app_path")" "$cask" >> "$APPLICATIONS_TSV"
    app_count=$((app_count + 1))
  done < <(find "$app_root" -type d -name '*.app' -prune 2>/dev/null | LC_ALL=C sort)
done

APPLICATIONS_SORTED="$OUTPUT_DIR/.applications-sorted"
{
  head -n 1 "$APPLICATIONS_TSV"
  tail -n +2 "$APPLICATIONS_TSV" | LC_ALL=C sort -f -t $'\t' -k1,1 -k2,2
} > "$APPLICATIONS_SORTED"
mv "$APPLICATIONS_SORTED" "$APPLICATIONS_TSV"

render_application_group() {
  local group="$1" count="$2"
  printf '## %s (%s)\n\n' "$group" "$count"
  if [[ "$count" -eq 0 ]]; then
    printf '_None detected._\n\n'
    return 0
  fi
  printf '| Application | Version | Bundle ID | Location | Homebrew cask |\n'
  printf '|---|---|---|---|---|\n'
  awk -F $'\t' -v wanted="$group" 'NR > 1 && $1 == wanted' "$APPLICATIONS_TSV" \
    | while IFS=$'\t' read -r app_category n v b p c; do
        printf '| %s | %s | `%s` | `%s` | `%s` |\n' \
          "$(md_escape "$n")" "$(md_escape "$v")" "$(md_escape "$b")" \
          "$(md_escape "$p")" "$(md_escape "$c")"
      done
  printf '\n'
}

{
  printf '# Installed applications\n\n'
  printf 'Each application appears in exactly one group. Homebrew ownership takes\n'
  printf 'priority; remaining bundles are grouped by location. The machine-readable\n'
  printf 'copy is `applications.tsv`, including the same `category` value. A Homebrew\n'
  printf 'cask value of `-` means the bundle is built into macOS, installed another\n'
  printf 'way, or could not be matched.\n\n'
  printf '## Category summary\n\n'
  printf '| Category | Count |\n|---|---:|\n'
  printf '| Homebrew Applications | %s |\n' "$homebrew_app_count"
  printf '| Applications | %s |\n' "$regular_app_count"
  printf '| User Applications | %s |\n' "$user_app_count"
  printf '| System Applications | %s |\n' "$system_app_count"
  printf '| Embedded or Other Bundles | %s |\n' "$other_app_count"
  printf '| **Total** | **%s** |\n\n' "$app_count"
  render_application_group 'Homebrew Applications' "$homebrew_app_count"
  render_application_group 'Applications' "$regular_app_count"
  render_application_group 'User Applications' "$user_app_count"
  render_application_group 'System Applications' "$system_app_count"
  render_application_group 'Embedded or Other Bundles' "$other_app_count"
} > "$OUTPUT_DIR/applications.md"
status applications PASS "$app_count application bundles inventoried in five groups"
ok "$app_count application bundles"

{
  printf '# Package managers and developer tools\n\n'
  for tool in brew git gh az ghq chezmoi starship fnm node npm pnpm uv python3 docker code; do
    printf '## %s\n\n```text\n' "$tool"
    if have "$tool"; then
      command -v "$tool"
      case "$tool" in
        brew)
          HOMEBREW_NO_AUTO_UPDATE=1 brew --version 2>&1 || true
          printf '\nFormulae:\n'; HOMEBREW_NO_AUTO_UPDATE=1 brew list --formula 2>&1 || true
          printf '\nCasks:\n'; HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask 2>&1 || true
          printf '\nTaps:\n'; HOMEBREW_NO_AUTO_UPDATE=1 brew tap 2>&1 || true
          ;;
        npm) npm --version 2>&1 || true; printf '\nGlobal packages:\n'; npm ls -g --depth=0 2>&1 || true ;;
        pnpm) pnpm --version 2>&1 || true; printf '\nGlobal packages:\n'; pnpm list -g --depth=0 2>&1 || true ;;
        docker) docker --version 2>&1 || true ;;
        *) "$tool" --version 2>&1 || "$tool" version 2>&1 || true ;;
      esac
    else
      printf 'not installed\n'
    fi
    printf '```\n\n'
  done
} > "$OUTPUT_DIR/packages.md"
if have brew; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file="$OUTPUT_DIR/Brewfile.snapshot" --force >/dev/null 2>&1 || true
fi
status packages PASS 'installed package-manager state collected without updating packages'
ok 'package managers and developer tools'

REPOS_TSV="$OUTPUT_DIR/repositories.tsv"
printf 'path\tbranch\tdirty_files\tremote\tupstream\tahead\tbehind\tstashes\n' > "$REPOS_TSV"
repo_candidates="$OUTPUT_DIR/.repository-candidates"
: > "$repo_candidates"
# Bash 3.2 treats an empty array expansion as unbound under `set -u`. A Mac
# with none of the default repository folders is valid, so avoid expanding the
# array until at least one search root exists.
if [[ "${#REPO_ROOTS[@]}" -gt 0 ]]; then
  for repo_root in "${REPO_ROOTS[@]}"; do
    [[ -d "$repo_root" ]] || { warn "repository root not found: $repo_root"; continue; }
    find "$repo_root" \
      \( -type d \( -name node_modules -o -name .cache -o -name Library -o -name .Trash \) -prune \) -o \
      \( -name .git -print \) 2>/dev/null \
      | while IFS= read -r git_marker; do dirname "$git_marker"; done >> "$repo_candidates"
  done
fi
LC_ALL=C sort -u "$repo_candidates" -o "$repo_candidates"
repo_count=0; dirty_count=0; no_remote_count=0
while IFS= read -r repo; do
  [[ -n "$repo" ]] || continue
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || continue
  branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null || printf 'detached')"
  dirty="$(git -C "$repo" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')"
  remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
  [[ -n "$remote" ]] || remote='NO-REMOTE'
  upstream="$(git -C "$repo" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || printf 'NO-UPSTREAM')"
  ahead='-'; behind='-'
  if [[ "$upstream" != NO-UPSTREAM ]]; then
    counts="$(git -C "$repo" rev-list --left-right --count "$upstream...HEAD" 2>/dev/null || true)"
    behind="${counts%%[[:space:]]*}"; ahead="${counts##*[[:space:]]}"
    [[ -n "$ahead" ]] || ahead='-'; [[ -n "$behind" ]] || behind='-'
  fi
  stashes="$(git -C "$repo" stash list 2>/dev/null | wc -l | tr -d ' ')"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(tsv_text "$repo")" "$(tsv_text "$branch")" "$dirty" "$(tsv_text "$remote")" \
    "$(tsv_text "$upstream")" "$ahead" "$behind" "$stashes" >> "$REPOS_TSV"
  repo_count=$((repo_count + 1))
  [[ "$dirty" -eq 0 ]] || dirty_count=$((dirty_count + 1))
  [[ "$remote" != NO-REMOTE ]] || no_remote_count=$((no_remote_count + 1))
done < "$repo_candidates"
{
  printf '# Repository readiness\n\n'
  printf '**%s repositories · %s dirty · %s with NO-REMOTE**\n\n' "$repo_count" "$dirty_count" "$no_remote_count"
  printf 'Dirty means uncommitted changes were found. NO-REMOTE means no `origin` URL is configured.\n\n'
  printf '| Repository | Branch | Dirty files | Remote | Upstream | Ahead / behind | Stashes |\n'
  printf '|---|---|---:|---|---|---:|---:|\n'
  tail -n +2 "$REPOS_TSV" | while IFS=$'\t' read -r p b d r u a bh s; do
    printf '| `%s` | `%s` | %s | `%s` | `%s` | %s / %s | %s |\n' \
      "$(md_escape "$p")" "$(md_escape "$b")" "$d" "$(md_escape "$r")" \
      "$(md_escape "$u")" "$a" "$bh" "$s"
  done
} > "$OUTPUT_DIR/repositories.md"
if [[ "$dirty_count" -gt 0 || "$no_remote_count" -gt 0 ]]; then
  status repositories REVIEW "$dirty_count dirty; $no_remote_count with NO-REMOTE"
  warn "repositories need review: $dirty_count dirty; $no_remote_count with NO-REMOTE"
else
  status repositories PASS "$repo_count repositories; no dirty or NO-REMOTE entries"
  ok "$repo_count repositories are ready for review"
fi

SECURITY_REVIEW=0
TM_INFO="$OUTPUT_DIR/.time-machine-info"
TM_STATUS="$OUTPUT_DIR/.time-machine-status"
PROFILE_STATUS="$OUTPUT_DIR/.profile-status"
SYSTEM_EXTENSIONS="$OUTPUT_DIR/.system-extensions"
BACKGROUND_ITEMS="$OUTPUT_DIR/.background-items"
if ! tmutil destinationinfo > "$TM_INFO" 2>&1; then SECURITY_REVIEW=$((SECURITY_REVIEW + 1)); fi
if ! tmutil status > "$TM_STATUS" 2>&1; then SECURITY_REVIEW=$((SECURITY_REVIEW + 1)); fi
if ! profiles status -type enrollment > "$PROFILE_STATUS" 2>&1; then SECURITY_REVIEW=$((SECURITY_REVIEW + 1)); fi
if ! systemextensionsctl list > "$SYSTEM_EXTENSIONS" 2>&1; then SECURITY_REVIEW=$((SECURITY_REVIEW + 1)); fi
if ! sfltool dumpbtm > "$BACKGROUND_ITEMS" 2>&1; then SECURITY_REVIEW=$((SECURITY_REVIEW + 1)); fi

{
  printf '# Security, startup and backup status\n\n'
  printf '## Time Machine configuration\n\n```text\n'
  cat "$TM_INFO"
  cat "$TM_STATUS"
  if [[ "$CHECK_LATEST_BACKUP" == 1 ]]; then
    printf '\nLatest-backup check was explicitly allowed:\n'
    tmutil latestbackup 2>&1 || true
  else
    printf '\nLatest-backup check skipped; it can mount the configured destination.\n'
  fi
  printf '```\n\n## Configuration profiles\n\n```text\n'
  cat "$PROFILE_STATUS"
  printf '```\n\n## System extensions\n\n```text\n'
  cat "$SYSTEM_EXTENSIONS"
  printf '```\n\n## Background task management\n\n```text\n'
  cat "$BACKGROUND_ITEMS"
  printf '```\n\n## User launch items (paths only)\n\n```text\n'
  for launch_root in "$HOME/Library/LaunchAgents" /Library/LaunchAgents /Library/LaunchDaemons; do
    [[ -d "$launch_root" ]] && find "$launch_root" -maxdepth 1 -name '*.plist' -print 2>/dev/null | LC_ALL=C sort
  done
  printf '```\n'
} > "$OUTPUT_DIR/security-startup-backup.md"
if [[ "$SECURITY_REVIEW" -gt 0 ]]; then
  status security REVIEW "$SECURITY_REVIEW metadata command(s) returned a non-zero status; inspect the report"
  warn "security/startup/backup metadata needs review: $SECURITY_REVIEW command(s) reported an issue"
else
  status security PASS 'security, startup and backup configuration metadata collected'
  ok 'security, startup and backup status'
fi

CONTAINER_REVIEW=0
{
  printf '# Container inventory\n\n'
  if have docker; then
    printf 'Docker command: `%s`\n\n' "$(command -v docker)"
    docker_endpoint="${DOCKER_HOST:-$(docker context inspect --format '{{.Endpoints.docker.Host}}' 2>/dev/null || true)}"
    [[ -n "$docker_endpoint" ]] || docker_endpoint='unix:///var/run/docker.sock'
    if [[ "$docker_endpoint" != unix://* ]]; then
      CONTAINER_REVIEW=1
      printf 'Container-engine collection was skipped because the active endpoint is not a local Unix socket: `%s`.\n' "${docker_endpoint:-unknown}"
      printf 'This prevents the safety report from querying a remote Docker host.\n'
    elif docker info >/dev/null 2>&1; then
      printf '## Containers\n\n```text\n'; docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>&1 || true; printf '```\n\n'
      printf '## Images\n\n```text\n'; docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}' 2>&1 || true; printf '```\n\n'
      printf '## Volumes\n\n```text\n'; docker volume ls 2>&1 || true; printf '```\n'
    else
      CONTAINER_REVIEW=1
      printf 'The Docker command exists, but its engine is not running. No engine state was changed.\n'
    fi
  else
    printf 'Docker is not installed.\n'
  fi
} > "$OUTPUT_DIR/containers.md"
if [[ "$CONTAINER_REVIEW" == 1 ]]; then
  status containers REVIEW 'Docker exists but its local engine could not be inventoried; inspect containers.md'
  warn 'container inventory needs review'
else
  status containers PASS 'container metadata collected when a running local engine was available'
  ok 'container inventory'
fi

CONFIG_PATHS=(
  "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.zlogin" "$HOME/.zlogout"
  "$HOME/.gitconfig" "$HOME/.ssh"
  "$HOME/.config" "$HOME/.local/share/chezmoi" "$HOME/.npmrc" "$HOME/Brewfile"
  "$HOME/Library/Application Support/Code/User" "$HOME/.docker" "$HOME/.orbstack"
  "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password"
)
{
  printf '# Configuration-path inventory\n\n'
  printf 'This is a presence-and-size report. The audit did not read these files.\n\n'
  printf '| Path | Present | Size |\n|---|---|---:|\n'
  for config_path in "${CONFIG_PATHS[@]}"; do
    if [[ -e "$config_path" || -L "$config_path" ]]; then
      size="$(du -sh "$config_path" 2>/dev/null | awk '{print $1}' || printf 'unavailable')"
      printf '| `%s` | yes | %s |\n' "$(md_escape "$config_path")" "$size"
    else
      printf '| `%s` | no | - |\n' "$(md_escape "$config_path")"
    fi
  done
  printf '\n## Environment variable names\n\nValues are deliberately excluded.\n\n```text\n'
  env | sed 's/=.*//' | LC_ALL=C sort
  printf '```\n'
} > "$OUTPUT_DIR/configuration-paths.md"
status configuration PASS 'known path presence, sizes and variable names collected; contents and values excluded'
ok 'configuration path presence'

/bin/unlink "$repo_candidates" 2>/dev/null || true
/bin/unlink "$CASK_APP_MAP" 2>/dev/null || true
for internal_report in "$TM_INFO" "$TM_STATUS" "$PROFILE_STATUS" "$SYSTEM_EXTENSIONS" "$BACKGROUND_ITEMS"; do
  /bin/unlink "$internal_report" 2>/dev/null || true
done

{
  printf '# Existing-Mac safety report\n\n'
  printf '> **Overall status: REVIEW REQUIRED.** This report is an inventory, not a\n'
  printf '> backup and not permission to erase or clean the Mac. Complete the review and\n'
  printf '> restore-test checklist below before completing the selected route.\n\n'

  printf '## Report details\n\n'
  printf '| Detail | Value |\n|---|---|\n'
  printf '| Created | `%s` |\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf '| Mac | `%s` |\n' "$(scutil --get ComputerName 2>/dev/null || hostname)"
  printf '| Report folder | `%s` |\n\n' "$OUTPUT_DIR"

  printf '## Findings that affect readiness\n\n'
  printf '| Check | Result | Where to review |\n|---|---:|---|\n'
  printf '| Git repositories found | %s | [Repository review](repositories.md) |\n' "$repo_count"
  printf '| Repositories with uncommitted changes (`DIRTY`) | **%s** | [Repository review](repositories.md) |\n' "$dirty_count"
  printf '| Repositories without an `origin` remote (`NO-REMOTE`) | **%s** | [Repository review](repositories.md) |\n' "$no_remote_count"
  printf '| Report sections needing attention | **%s** | [Collection status](collection-status.tsv) |\n' "$COLLECTION_REVIEW"
  printf '| Application bundles found | %s | [Application review](applications.md) |\n' "$app_count"
  printf '| Homebrew-owned applications | %s | [Application review](applications.md) |\n\n' "$homebrew_app_count"

  if [[ "$dirty_count" -gt 0 || "$no_remote_count" -gt 0 || "$COLLECTION_REVIEW" -gt 0 ]]; then
    printf '**Action needed:** one or more automated findings require review. Follow the\n'
    printf 'links in the table above before continuing. A non-zero number is not repaired\n'
    printf 'by this report.\n\n'
  else
    printf '**Automated findings:** no dirty repositories, missing remotes, or incomplete\n'
    printf 'collection sections were detected. Manual backup and restore checks are still\n'
    printf 'required.\n\n'
  fi

  printf '## Review the report in this order\n\n'
  printf '1. Open [Collection status](collection-status.tsv). Investigate every row marked `REVIEW`.\n'
  printf '2. Open [Repository review](repositories.md). Resolve every `DIRTY` and `NO-REMOTE` entry.\n'
  printf '3. Open [Application review](applications.md) and [package inventory](packages.md).\n'
  printf '   Decide which licences, profiles, settings, or app data need a separate export.\n'
  printf '4. Open [container inventory](containers.md). Export important databases and volumes.\n'
  printf '5. Open [security, startup, and backup status](security-startup-backup.md).\n'
  printf '6. Open [configuration-path inventory](configuration-paths.md). Decide what must be archived.\n'
  printf '7. Open [system and account details](system.md) for FileVault, storage, and Mac information.\n\n'

  printf '## Complete report index\n\n'
  printf '| File | What it contains |\n|---|---|\n'
  printf '| [Collection status](collection-status.tsv) | Pass/review status for each collection section |\n'
  printf '| [Repositories](repositories.md) | Readable Git repository readiness report |\n'
  printf '| [Repository data](repositories.tsv) | Spreadsheet-friendly repository data |\n'
  printf '| [Applications](applications.md) | Applications grouped by ownership and location |\n'
  printf '| [Application data](applications.tsv) | Spreadsheet-friendly application data |\n'
  printf '| [Packages](packages.md) | Homebrew and development-tool versions |\n'
  if [[ -s "$OUTPUT_DIR/Brewfile.snapshot" ]]; then
    printf '| [Brewfile snapshot](Brewfile.snapshot) | Homebrew formulae, casks, and related entries |\n'
  fi
  printf '| [Containers](containers.md) | Local Docker containers, images, and volumes when available |\n'
  printf '| [Security, startup, and backup](security-startup-backup.md) | Time Machine, profiles, extensions, and background items |\n'
  printf '| [Configuration paths](configuration-paths.md) | Presence and size of known settings locations |\n'
  printf '| [System and account](system.md) | macOS, hardware, FileVault, account, and mounted-storage details |\n'
  printf '| [Checksums](SHA256SUMS.txt) | SHA-256 values used to verify this report after copying |\n\n'

  printf '## Required backup and restore checklist\n\n'
  # macOS ships Bash 3.2, whose printf builtin treats a leading "-" in the
  # format string as an option. "--" keeps Markdown list items literal.
  printf -- '- [ ] I reviewed every report link above.\n'
  printf -- '- [ ] I resolved or made a recovery plan for every `DIRTY` repository.\n'
  printf -- '- [ ] I resolved or backed up every `NO-REMOTE` repository.\n'
  printf -- '- [ ] Guided Step 2 copied this complete report to an encrypted external drive.\n'
  printf -- '- [ ] Route B Step 3 copied the selected development snapshot, or Route A has a complete separate backup.\n'
  printf -- '- [ ] I verified the copied report with `shasum -a 256 -c SHA256SUMS.txt`.\n'
  printf -- '- [ ] I restored and opened representative files from the backup.\n'
  printf -- '- [ ] I tested any important database or container exports.\n'
  printf -- '- [ ] I confirmed required accounts and recovery information on another trusted device.\n\n'

  printf '## Continue only after the checklist passes\n\n'
  printf 'Run:\n\n```bash\n%s/prepare-existing-mac.sh --guided\n```\n\n' "$SCRIPT_DIR"
  printf 'The progress dashboard rechecks saved work and highlights the next incomplete\n'
  printf 'step. Route B requires the report copy, development snapshot, restore test, and\n'
  printf 'cleanup preview before apply. Route A requires a complete separate backup and\n'
  printf 'restore test before the Apple erase handoff.\n\n'
  printf 'Backup instructions: `%s/preflight/02-backup-readiness.md`  \n' "$PROJECT_DIR"
  printf 'Encrypted-drive instructions: `%s/preflight/ENCRYPTED-BACKUP-DRIVE.md`\n\n' "$PROJECT_DIR"

  printf '## Privacy\n\n'
  printf 'This report can contain account names, local paths, installed software, repository\n'
  printf 'remote URLs, and security status. It excludes environment-variable values and does\n'
  printf 'not copy configuration contents. Keep the whole folder private and outside Git.\n'
  printf 'Delete it only after the transition and recovery period are complete.\n'
} > "$OUTPUT_DIR/SUMMARY.md"

(
  cd "$OUTPUT_DIR"
  find . -type f ! -name SHA256SUMS.txt -print | LC_ALL=C sort | while IFS= read -r report_file; do
    shasum -a 256 "$report_file"
  done > SHA256SUMS.txt
)
find "$OUTPUT_DIR" -type f -exec chmod 600 {} \;

printf '\n'
ok 'safety report complete'
info "start with: $OUTPUT_DIR/SUMMARY.md"
info "verify later: cd \"$OUTPUT_DIR\" && shasum -a 256 -c SHA256SUMS.txt"
warn 'Next: review the report, make an encrypted backup, and test a restore.'
if [[ "${DAY_ONE_MAC_EMBEDDED_PREFLIGHT:-0}" == 1 ]]; then
  info 'When report review closes, the Stage 0 progress dashboard will continue automatically.'
else
  info "Then rerun: $SCRIPT_DIR/prepare-existing-mac.sh --guided"
fi
review_completed_report
