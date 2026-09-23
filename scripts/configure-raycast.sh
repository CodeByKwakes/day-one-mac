#!/usr/bin/env bash
# Generate a track-aware, AI-aware Raycast Script Command directory.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
CATALOG="$PROJECT_DIR/config/raycast-commands.tsv"
EXTENSIONS="$PROJECT_DIR/config/raycast-extensions.tsv"
TARGET_DIR="${DAY_ONE_RAYCAST_COMMAND_DIR:-$HOME/.local/share/day-one-mac/raycast}"
BACKUP_ROOT="$STATE_ROOT/raycast-command-backups"
MANAGED_MARKER='.day-one-raycast-managed'
ASSUME_YES=0
MODE=wizard
GROUP_CSV=""

GROUP_IDS=(core documentation ai hosting safety second-brain)
GROUP_LABELS=(
  'Required Day One health commands'
  'Guides, project and terminal launchers'
  'Selected AI clients and projectless tasks'
  'Saved GitHub or Azure hosting track'
  'Cleanup and rollback previews only'
  'Second Brain guide launcher'
)
GROUP_SELECTED=(1 1 1 1 0 0)

usage() {
  cat <<'EOF'
Usage: ./configure-raycast.sh [options]

  --wizard                 toggle command groups and apply after review (default)
  --preview                show the default generated command plan; change nothing
  --apply                  apply the default plan after confirmation
  --groups A,B             use selected groups non-interactively
                           core,documentation,ai,hosting,safety,second-brain
  --status                 show the managed directory and saved machine choices
  --extensions             print the reviewed Raycast extension recommendations
  --remove-generated       archive the Day One generated directory
  --yes                    accept the ordinary apply/remove confirmation
  -h, --help               show this help

The script never installs Store extensions, changes Raycast's private database,
adds destructive --execute commands, or writes a credential into a command.
After applying once, add the printed directory in Raycast Settings under Script
Commands. Raycast detects later safe refreshes automatically.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
die() { ui_error "$@"; exit 1; }

state_value() {
  [[ -r "$STATE_DIR/$1" ]] && sed -n '1p' "$STATE_DIR/$1" || true
}

contains_csv() {
  case ",$1," in *",$2,"*) return 0 ;; *) return 1 ;; esac
}

group_index() {
  local requested="$1" i
  for ((i=0; i<${#GROUP_IDS[@]}; i++)); do
    [[ "${GROUP_IDS[$i]}" == "$requested" ]] && { printf '%s\n' "$i"; return 0; }
  done
  return 1
}

set_group_csv() {
  local value index i old_ifs="$IFS"
  for ((i=0; i<${#GROUP_SELECTED[@]}; i++)); do GROUP_SELECTED[$i]=0; done
  IFS=','
  for value in $GROUP_CSV; do
    IFS="$old_ifs"
    index="$(group_index "$value")" || die "unknown Raycast command group: $value"
    GROUP_SELECTED[$index]=1
    IFS=','
  done
  IFS="$old_ifs"
}

group_enabled() {
  local index
  index="$(group_index "$1")" || return 1
  [[ "${GROUP_SELECTED[$index]}" == 1 ]]
}

condition_matches() {
  local condition="$1" track="$2" ai_clients="$3"
  case "$condition" in
    always) return 0 ;;
    track-github) [[ "$track" == 1 || "$track" == 3 ]] ;;
    track-azure) [[ "$track" == 2 || "$track" == 3 ]] ;;
    ai-codex) contains_csv "$ai_clients" codex ;;
    ai-claude) contains_csv "$ai_clients" claude ;;
    ai-copilot-cli) contains_csv "$ai_clients" copilot-cli ;;
    ai-copilot-app) contains_csv "$ai_clients" copilot-app ;;
    ai-raycast-ai) contains_csv "$ai_clients" raycast-ai ;;
    *) die "unknown condition in Raycast catalogue: $condition" ;;
  esac
}

print_extensions() {
  local tier scope name publisher purpose url review last_tier=""
  ui_title '🧩' 'Recommended Raycast extensions'
  printf 'Store extensions are suggestions, not Day One requirements. Review the\n'
  printf 'publisher, source, requested access and company policy before installing.\n'
  while IFS=$'\t' read -r tier scope name publisher purpose url review; do
    [[ -n "$tier" && "${tier#\#}" == "$tier" ]] || continue
    if [[ "$tier" != "$last_tier" ]]; then printf '\n%s\n' "$tier"; last_tier="$tier"; fi
    printf '  • %s — %s\n' "$name" "$purpose"
    printf '    Scope: %s · Publisher: %s\n' "$scope" "$publisher"
    printf '    Review: %s\n' "$review"
    printf '    %s\n' "$url"
  done < "$EXTENSIONS"
}

selected_count() {
  local track="$1" ai_clients="$2" group condition id title alias mode action description count=0
  while IFS=$'\t' read -r group condition id title alias mode action description; do
    [[ -n "$group" && "${group#\#}" == "$group" ]] || continue
    group_enabled "$group" || continue
    condition_matches "$condition" "$track" "$ai_clients" || continue
    count=$((count + 1))
  done < "$CATALOG"
  printf '%s\n' "$count"
}

print_plan() {
  local track="$1" ai_clients="$2" group condition id title alias mode action description last_group=""
  ui_title '🚀' 'Raycast command plan'
  ui_label 'Track' "${track:-not selected}"
  ui_label 'AI clients' "${ai_clients:-none selected}"
  ui_label 'Managed directory' "$TARGET_DIR"
  while IFS=$'\t' read -r group condition id title alias mode action description; do
    [[ -n "$group" && "${group#\#}" == "$group" ]] || continue
    group_enabled "$group" || continue
    condition_matches "$condition" "$track" "$ai_clients" || continue
    if [[ "$group" != "$last_group" ]]; then printf '\n%s\n' "$group"; last_group="$group"; fi
    printf '  %-38s alias %-6s %s\n' "$title" "$alias" "$description"
  done < "$CATALOG"
  printf '\nNo generated command contains --execute or installs/uninstalls software.\n'
}

interactive_groups() {
  local cursor=0 key rest i pointer check
  [[ -t 0 && -t 1 ]] || die 'the Raycast wizard needs a terminal; use --preview or --groups with --apply'
  while :; do
    printf '\033[2J\033[H'
    ui_banner '🚀' 'Choose Raycast command groups'
    printf '  Up/Down or j/k: move   Space: toggle   a: recommended   n: none\n'
    printf '  Enter: review          q: quit\n\n'
    for ((i=0; i<${#GROUP_IDS[@]}; i++)); do
      [[ "${GROUP_SELECTED[$i]}" == 1 ]] && check='[x]' || check='[ ]'
      [[ "$i" == "$cursor" ]] && pointer='>' || pointer=' '
      printf ' %s %s %-14s %s\n' "$pointer" "$check" "${GROUP_IDS[$i]}" "${GROUP_LABELS[$i]}"
    done
    IFS= read -rsn1 key || exit 10
    if [[ "$key" == $'\033' ]]; then IFS= read -rsn2 rest || true; key="$key$rest"; fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#GROUP_IDS[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#GROUP_IDS[@]}" ]] || cursor=0 ;;
      ' ') [[ "${GROUP_SELECTED[$cursor]}" == 1 ]] && GROUP_SELECTED[$cursor]=0 || GROUP_SELECTED[$cursor]=1 ;;
      a|A) GROUP_SELECTED=(1 1 1 1 0 0) ;;
      n|N) GROUP_SELECTED=(0 0 0 0 0 0) ;;
      q|Q) exit 10 ;;
      '') return 0 ;;
    esac
  done
}

write_library() {
  local destination="$1"
  cat > "$destination/_day-one-raycast-lib.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

day_one() {
  local command="$HOME/.local/bin/day-one-mac"
  [[ -x "$command" ]] || {
    printf 'The portable day-one-mac command is unavailable. Complete Phase 5 or rerun it.\n' >&2
    exit 1
  }
  "$command" "$@"
}

day_one_project_root() { day_one root; }

open_code() {
  local target="$1"
  if command -v code >/dev/null 2>&1; then code -n "$target"; else open -a 'Visual Studio Code' "$target"; fi
}

uri_encode() {
  local jq_command
  jq_command="$(command -v jq 2>/dev/null || true)"
  [[ -n "$jq_command" ]] || jq_command=/opt/homebrew/bin/jq
  [[ -x "$jq_command" ]] || { printf 'jq is required; rerun Day One Mac Phase 4.\n' >&2; exit 1; }
  printf '%s' "$1" | "$jq_command" -sRr @uri
}

open_warp_path() {
  local encoded
  encoded="$(uri_encode "$1")"
  open "warp://action/new_tab?path=$encoded"
}

copy_launch_command() {
  printf '%s' "$1" | pbcopy
  /usr/bin/osascript -e 'display notification "The reviewed launch command is on the clipboard. Paste it into the new Warp tab when ready." with title "Day One Mac"' >/dev/null
}

create_ai_task() {
  local client="$1" title="$2" task_path launch
  case "$client" in
    codex)
      task_path="$(day_one workspace create-task --title "$title" --kind other --client codex --sensitivity private --quiet)"
      printf -v launch 'day-one-mac workspace start-codex %q' "$task_path"
      ;;
    claude)
      task_path="$(day_one workspace create-task --title "$title" --kind other --client claude --sensitivity private --quiet)"
      printf -v launch 'day-one-mac workspace start-claude %q' "$task_path"
      ;;
    copilot)
      task_path="$(day_one workspace create-task --title "$title" --kind other --client undecided --sensitivity private --quiet)"
      printf -v launch 'cd %q && copilot' "$task_path"
      ;;
    *) printf 'Unsupported AI task client: %s\n' "$client" >&2; exit 2 ;;
  esac
  open_warp_path "$task_path"
  copy_launch_command "$launch"
}
EOF
  chmod 600 "$destination/_day-one-raycast-lib.sh"
}

write_action_body() {
  local file="$1" action="$2"
  case "$action" in
    status) printf '%s\n' 'day_one --status' >> "$file" ;;
    applications) printf '%s\n' 'day_one applications --required' >> "$file" ;;
    inventory) printf '%s\n' 'day_one inventory' >> "$file" ;;
    validate) printf '%s\n' 'day_one validate' >> "$file" ;;
    finalize-status) printf '%s\n' 'day_one finalize --status' >> "$file" ;;
    open-start) printf '%s\n' 'open_code "$(day_one_project_root)/START-HERE.md"' >> "$file" ;;
    open-command-reference) printf '%s\n' 'open_code "$(day_one_project_root)/reference/COMMAND-REFERENCE.md"' >> "$file" ;;
    open-project) printf '%s\n' 'open_code "$(day_one_project_root)"' >> "$file" ;;
    open-project-terminal) printf '%s\n' 'open_warp_path "$(day_one_project_root)"' >> "$file" ;;
    open-optional) printf '%s\n' 'open_code "$(day_one_project_root)/optional/README.md"' >> "$file" ;;
    removal-inventory) printf '%s\n' 'day_one remove --inventory' >> "$file" ;;
    rollback-preview) printf '%s\n' 'day_one rollback' >> "$file" ;;
    cleanup-preview) printf '%s\n' 'day_one clean' >> "$file" ;;
    workspace-list) printf '%s\n' 'day_one workspace list' >> "$file" ;;
    workspace-folder) printf '%s\n' 'mkdir -p "$HOME/Developer/_Projectless/tasks"' 'open "$HOME/Developer/_Projectless/tasks"' >> "$file" ;;
    workspace-guide) printf '%s\n' 'open_code "$(day_one_project_root)/reference/AI-WORKSPACES.md"' >> "$file" ;;
    new-codex-task) printf '%s\n' 'create_ai_task codex "${1:-Untitled}"' >> "$file" ;;
    new-claude-task) printf '%s\n' 'create_ai_task claude "${1:-Untitled}"' >> "$file" ;;
    new-copilot-task) printf '%s\n' 'create_ai_task copilot "${1:-Untitled}"' >> "$file" ;;
    open-copilot-app) printf '%s\n' 'if [[ -d "/Applications/GitHub Copilot.app" ]]; then open -a "GitHub Copilot"; else open -a Copilot; fi' >> "$file" ;;
    raycast-ai-guide) printf '%s\n' 'open_code "$(day_one_project_root)/optional/10-ai-agents.md"' >> "$file" ;;
    github-auth) printf '%s\n' 'command -v gh >/dev/null 2>&1 || { echo "gh is unavailable; rerun Phase 4." >&2; exit 1; }' 'gh auth status' >> "$file" ;;
    github-repository) cat >> "$file" <<'EOF'
root="$(day_one_project_root)"
remote="$(git -C "$(dirname "$root")" remote get-url origin 2>/dev/null || git -C "$root" remote get-url origin 2>/dev/null || true)"
case "$remote" in
  git@github.com:*) url="https://github.com/${remote#git@github.com:}" ;;
  https://github.com/*) url="$remote" ;;
  *) printf 'The recorded checkout has no GitHub origin remote.\n' >&2; exit 1 ;;
esac
open "${url%.git}"
EOF
      ;;
    azure-account) printf '%s\n' 'command -v az >/dev/null 2>&1 || { echo "az is unavailable; rerun Phase 4." >&2; exit 1; }' 'az account show --output table' >> "$file" ;;
    azure-repositories) printf '%s\n' 'command -v az >/dev/null 2>&1 || { echo "az is unavailable; rerun Phase 4." >&2; exit 1; }' 'az repos list --output table' >> "$file" ;;
    second-brain-guide) printf '%s\n' 'open_code "$(day_one_project_root)/second-brain/README.md"' >> "$file" ;;
    *) die "unknown Raycast catalogue action: $action" ;;
  esac
}

write_command() {
  local destination="$1" number="$2" id="$3" title="$4" alias="$5" mode="$6" action="$7" description="$8"
  local file
  file="$destination/$(printf '%02d' "$number")-$id.sh"
  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' '# @raycast.schemaVersion 1'
    printf '# @raycast.title %s\n' "$title"
    printf '# @raycast.mode %s\n' "$mode"
    printf '%s\n' '# @raycast.packageName Day One Mac'
    printf '# @raycast.description %s\n' "$description"
    printf '# Suggested alias: %s (assign in Raycast Settings → Shortcuts)\n' "$alias"
    case "$action" in
      new-codex-task|new-claude-task|new-copilot-task)
        printf '%s\n' '# @raycast.argument1 { "type": "text", "placeholder": "Task title", "optional": true }'
        ;;
    esac
    printf '\nset -euo pipefail\n'
    printf '%s\n' 'COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
    printf '%s\n' 'source "$COMMAND_DIR/_day-one-raycast-lib.sh"'
  } > "$file"
  write_action_body "$file" "$action"
  chmod 700 "$file"
}

generate_directory() {
  local destination="$1" track="$2" ai_clients="$3" group condition id title alias mode action description count=0
  mkdir -p "$destination"
  chmod 700 "$destination"
  write_library "$destination"
  while IFS=$'\t' read -r group condition id title alias mode action description; do
    [[ -n "$group" && "${group#\#}" == "$group" ]] || continue
    group_enabled "$group" || continue
    condition_matches "$condition" "$track" "$ai_clients" || continue
    count=$((count + 1))
    write_command "$destination" "$count" "$id" "$title" "$alias" "$mode" "$action" "$description"
  done < "$CATALOG"
  printf 'schema=1\ntrack=%s\nai_clients=%s\ncommands=%s\n' \
    "$track" "$ai_clients" "$count" > "$destination/$MANAGED_MARKER"
  chmod 600 "$destination/$MANAGED_MARKER"
}

confirm_action() {
  local prompt="$1" answer
  [[ "$ASSUME_YES" == 1 ]] && return 0
  [[ -t 0 ]] || die "$prompt needs a terminal or --yes"
  printf '%s [y/N]: ' "$prompt"
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]]
}

apply_plan() {
  local track="$1" ai_clients="$2" temporary backup stamp count
  [[ -x "$HOME/.local/bin/day-one-mac" ]] || die 'complete or rerun Phase 5 before applying Raycast commands; the portable day-one-mac command is required'
  count="$(selected_count "$track" "$ai_clients")"
  [[ "$count" -gt 0 ]] || die 'no Raycast commands are selected'
  if [[ -d "$TARGET_DIR" && ! -f "$TARGET_DIR/$MANAGED_MARKER" ]]; then
    die "refusing to replace an unmanaged directory: $TARGET_DIR"
  fi
  temporary="$(mktemp -d "${TMPDIR:-/tmp}/day-one-raycast.XXXXXX")"
  generate_directory "$temporary" "$track" "$ai_clients"
  if [[ -d "$TARGET_DIR" ]] && diff -qr "$TARGET_DIR" "$temporary" >/dev/null 2>&1; then
    rm -rf "$temporary"
    ok "Raycast command directory is already current"
    return 0
  fi
  mkdir -p "$(dirname "$TARGET_DIR")" "$BACKUP_ROOT"
  chmod 700 "$(dirname "$TARGET_DIR")" "$BACKUP_ROOT"
  if [[ -d "$TARGET_DIR" ]]; then
    stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
    backup="$BACKUP_ROOT/raycast-$stamp"
    mv "$TARGET_DIR" "$backup"
    info "previous generated commands archived at $backup"
  fi
  mv "$temporary" "$TARGET_DIR"
  ok "generated $count Raycast commands in $TARGET_DIR"
  printf '\nOne-time Raycast step:\n'
  printf '  1. Open Raycast Settings → Extensions → Script Commands.\n'
  printf '  2. Choose Add Script Directory.\n'
  printf '  3. Select %s\n' "$TARGET_DIR"
  printf '  4. Open Settings → Shortcuts and audit the generated aliases.\n'
}

show_status() {
  local track ai_clients count=0
  track="$(state_value track)"
  ai_clients="$(state_value ai-clients)"
  ui_title '🚀' 'Raycast command status'
  ui_label 'Track' "${track:-not selected}"
  ui_label 'AI clients' "${ai_clients:-none selected}"
  ui_label 'Managed directory' "$TARGET_DIR"
  if [[ -f "$TARGET_DIR/$MANAGED_MARKER" ]]; then
    count="$(find "$TARGET_DIR" -maxdepth 1 -type f -name '*.sh' -perm -100 ! -name '_*' | wc -l | tr -d ' ')"
    ok "$count generated commands are present"
    sed 's/^/  /' "$TARGET_DIR/$MANAGED_MARKER"
  elif [[ -d "$TARGET_DIR" ]]; then
    warn 'the target directory exists but is not Day One managed; it will not be changed'
  else
    info 'no generated command directory exists yet'
  fi
}

remove_generated() {
  local stamp destination
  [[ -d "$TARGET_DIR" ]] || { info 'no generated Raycast directory exists'; return 0; }
  [[ -f "$TARGET_DIR/$MANAGED_MARKER" ]] || die "refusing to remove an unmanaged directory: $TARGET_DIR"
  confirm_action 'Archive the generated Day One Raycast commands?' || { info 'nothing changed'; return 0; }
  mkdir -p "$BACKUP_ROOT"
  chmod 700 "$BACKUP_ROOT"
  stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  destination="$BACKUP_ROOT/removed-$stamp"
  mv "$TARGET_DIR" "$destination"
  ok "generated commands archived at $destination"
  printf 'Remove the old Script Directory entry from Raycast Settings if it remains visible.\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wizard) MODE=wizard ;;
    --preview) MODE=preview ;;
    --apply) MODE=apply ;;
    --groups) shift; [[ $# -gt 0 ]] || die '--groups needs a comma-separated value'; GROUP_CSV="$1" ;;
    --status) MODE=status ;;
    --extensions) MODE=extensions ;;
    --remove-generated) MODE=remove ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

[[ -r "$CATALOG" ]] || die "Raycast command catalogue is missing: $CATALOG"
[[ -r "$EXTENSIONS" ]] || die "Raycast extension catalogue is missing: $EXTENSIONS"
[[ -n "$GROUP_CSV" ]] && set_group_csv

TRACK="$(state_value track)"
AI_CLIENTS="$(state_value ai-clients)"

case "$MODE" in
  status) show_status ;;
  extensions) print_extensions ;;
  remove) remove_generated ;;
  preview) print_plan "$TRACK" "$AI_CLIENTS" ;;
  apply)
    print_plan "$TRACK" "$AI_CLIENTS"
    confirm_action 'Write this Raycast command directory?' || { info 'nothing changed'; exit 10; }
    apply_plan "$TRACK" "$AI_CLIENTS"
    ;;
  wizard)
    interactive_groups
    print_plan "$TRACK" "$AI_CLIENTS"
    confirm_action 'Write this Raycast command directory?' || { info 'nothing changed'; exit 10; }
    apply_plan "$TRACK" "$AI_CLIENTS"
    ;;
esac
