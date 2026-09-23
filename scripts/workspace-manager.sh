#!/usr/bin/env bash
# Create and open bounded Day One Mac projectless task workspaces.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/terminal-ui.sh"

PROJECTLESS_ROOT="${DAY_ONE_PROJECTLESS_ROOT:-$HOME/Developer/_Projectless}"
TASKS_ROOT="$PROJECTLESS_ROOT/tasks"
TEMPLATES_ROOT="$PROJECTLESS_ROOT/templates"
APP_STORAGE_ROOT="$PROJECTLESS_ROOT/app-storage"
QUIET=0

usage() {
  cat <<'EOF'
Usage: workspace-manager.sh [command] [options]

Commands:
  --guided, guided              create a task through plain-English prompts
  init                          create the projectless root and templates
  create-task                   create one immutable projectless task folder
  list                          list task folders and their saved status
  status [PATH]                 inspect a task (default: current directory)
  complete [PATH]               mark a task complete without moving it
  open-vscode [PATH]            open one task folder in a new VS Code window
  start-codex [PATH]            start approval-gated Codex in one task folder
  start-claude [PATH]           start Claude Code in Plan mode in one task folder

create-task options:
  --title TEXT                  task title (default: Untitled)
  --kind VALUE                  research, document, analysis, prototype, or other
  --client VALUE                codex, claude, vscode, or undecided
  --sensitivity VALUE           private, work-confidential, or public
  --open VALUE                  none, vscode, codex, or claude
  --quiet                       print only the created path; useful to Warp

The manager never initialises ~/Developer/_Projectless as a Git repository and
never moves an active task when its status changes. Existing legacy folders are
reported but are not changed automatically.
EOF
}

info() { [[ "$QUIET" == 1 ]] || ui_info "$@"; }
ok() { [[ "$QUIET" == 1 ]] || ui_success "$@"; }
warn() { ui_warning "$@"; }
die() { ui_error "$@"; exit 1; }

valid_choice() {
  local value="$1" allowed="$2"
  case " $allowed " in *" $value "*) return 0 ;; *) return 1 ;; esac
}

slugify() {
  local value
  value="$(printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs '[:alnum:]' '-' \
    | sed -e 's/^-*//' -e 's/-*$//' -e 's/--*/-/g')"
  [[ -n "$value" ]] || value=untitled
  printf '%.60s\n' "$value"
}

write_root_readme() {
  local target="$PROJECTLESS_ROOT/README.md"
  [[ -e "$target" ]] && return 0
  cat > "$target" <<'EOF'
# Projectless tasks

This directory contains bounded file-based tasks that do not belong to a Git
repository. Open one dated task folder at a time. Do not open this parent in an
AI client, and do not initialise this parent as a Git repository.

Each task keeps a stable path under `tasks/<year>/`. Change its status in
`TASK.md`; do not move an active folder merely to represent its status.

The `app-storage/` children are default destinations for projectless Codex and
Claude Cowork output. They are not substitutes for a bounded dated task, and
the complete `_Projectless` parent must not be granted as a trusted folder.

When work becomes maintained software, promote its reviewed files into a real
repository below `~/Developer/<provider>/<owner>/<repository>`.
EOF
}

write_templates() {
  local task_template="$TEMPLATES_ROOT/TASK.md" agents_template="$TEMPLATES_ROOT/AGENTS.md"
  if [[ ! -e "$task_template" ]]; then
    cat > "$task_template" <<'EOF'
---
title: Replace with a clear task title
status: inbox
kind: other
created: YYYY-MM-DDTHH:MM:SS+ZZZZ
primary_client: undecided
sensitivity: private
repository: none
---

# Task

## Outcome

Describe the result this task must produce.

## Inputs

List the files or sources placed in `input/`.

## Boundaries

- Work only inside this task folder.
- Treat `input/` as read-only.
- Do not store credentials in this folder.

## Done when

- [ ] The requested outcome is complete.
- [ ] Important claims or changes have been verified.
- [ ] Reviewed deliverables are in `output/`.

## Decisions and notes
EOF
  fi
  if [[ ! -e "$agents_template" ]]; then
    cat > "$agents_template" <<'EOF'
# Projectless task instructions

Read `TASK.md` before starting work.

- Work only inside this task folder.
- Treat `input/` as read-only source material.
- Put intermediate files in `working/`.
- Put reviewed deliverables in `output/`.
- Do not place credentials, tokens, or application state here.
- Record important decisions and verification in `TASK.md`.
- Ask before accessing a directory outside this task.
EOF
  fi
}

report_legacy_layout() {
  local found=0 name
  for name in 00_Inbox 01_Active 02_Experiments 03_Generated 99_Archive; do
    if [[ -d "$PROJECTLESS_ROOT/$name" ]]; then
      found=1
      break
    fi
  done
  if [[ "$found" == 1 ]]; then
    warn "Legacy _Projectless folders were found and left unchanged."
    warn "Finish live client sessions before adopting or moving any legacy task."
  fi
}

init_layout() {
  umask 077
  mkdir -p "$TASKS_ROOT" "$TEMPLATES_ROOT" \
    "$APP_STORAGE_ROOT/codex-projectless" \
    "$APP_STORAGE_ROOT/claude-cowork"
  chmod 700 "$PROJECTLESS_ROOT" "$TASKS_ROOT" "$TEMPLATES_ROOT" \
    "$APP_STORAGE_ROOT" \
    "$APP_STORAGE_ROOT/codex-projectless" \
    "$APP_STORAGE_ROOT/claude-cowork"
  write_root_readme
  write_templates
  report_legacy_layout
  ok "projectless workspace ready: $PROJECTLESS_ROOT"
}

metadata_value() {
  local file="$1" key="$2" value
  value="$(sed -n "s/^${key}:[[:space:]]*//p" "$file" | head -1)"
  case "$value" in
    \'*\')
      value="${value#\'}"
      value="${value%\'}"
      value="$(printf '%s' "$value" | sed "s/''/'/g")"
      ;;
  esac
  printf '%s\n' "$value"
}

yaml_single_quote() {
  printf '%s' "$1" | sed "s/'/''/g"
}

resolve_task_path() {
  local requested="${1:-$PWD}" resolved tasks_resolved
  [[ -d "$requested" ]] || die "task folder does not exist: $requested"
  resolved="$(cd "$requested" && pwd -P)"
  [[ -d "$TASKS_ROOT" ]] || die "projectless task root does not exist; run: day-one-mac workspace init"
  tasks_resolved="$(cd "$TASKS_ROOT" && pwd -P)"
  case "$resolved" in
    "$tasks_resolved"/*/*) ;;
    *) die "choose one task below $TASKS_ROOT/<year>/<task>; the parent is intentionally refused" ;;
  esac
  [[ -f "$resolved/TASK.md" ]] || die "TASK.md is missing: $resolved"
  [[ -f "$resolved/AGENTS.md" ]] || die "AGENTS.md is missing: $resolved"
  printf '%s\n' "$resolved"
}

create_task() {
  local title=Untitled kind=other client=undecided sensitivity=private open_with=none
  local slug year stamp task_dir suffix=1 created yaml_title
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title) shift; [[ $# -gt 0 ]] || die '--title needs text'; title="$1" ;;
      --kind) shift; [[ $# -gt 0 ]] || die '--kind needs a value'; kind="$1" ;;
      --client) shift; [[ $# -gt 0 ]] || die '--client needs a value'; client="$1" ;;
      --sensitivity) shift; [[ $# -gt 0 ]] || die '--sensitivity needs a value'; sensitivity="$1" ;;
      --open) shift; [[ $# -gt 0 ]] || die '--open needs a value'; open_with="$1" ;;
      --quiet) QUIET=1 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown create-task option: $1" ;;
    esac
    shift
  done
  [[ -n "$title" && "$title" != *$'\n'* && "$title" != *$'\r'* && "$title" != *$'\t'* ]] || die 'enter a one-line task title without tabs'
  valid_choice "$kind" 'research document analysis prototype other' || die 'kind must be research, document, analysis, prototype, or other'
  valid_choice "$client" 'codex claude vscode undecided' || die 'client must be codex, claude, vscode, or undecided'
  valid_choice "$sensitivity" 'private work-confidential public' || die 'sensitivity must be private, work-confidential, or public'
  valid_choice "$open_with" 'none vscode codex claude' || die 'open must be none, vscode, codex, or claude'

  init_layout
  year="$(date +%Y)"
  stamp="$(date +'%Y-%m-%d--%H%M%S')"
  created="$(date +'%Y-%m-%dT%H:%M:%S%z')"
  slug="$(slugify "$title")"
  yaml_title="$(yaml_single_quote "$title")"
  task_dir="$TASKS_ROOT/$year/$stamp--$slug"
  while [[ -e "$task_dir" ]]; do
    task_dir="$TASKS_ROOT/$year/$stamp--$slug-$suffix"
    suffix=$((suffix + 1))
  done

  umask 077
  mkdir -p "$task_dir/input" "$task_dir/working" "$task_dir/output"
  cat > "$task_dir/TASK.md" <<EOF
---
title: '$yaml_title'
status: inbox
kind: $kind
created: $created
primary_client: $client
sensitivity: $sensitivity
repository: none
---

# $title

## Outcome

Describe the result this task must produce.

## Inputs

List the files or sources placed in \`input/\`.

## Boundaries

- Work only inside this task folder.
- Treat \`input/\` as read-only.
- Do not store credentials in this folder.

## Done when

- [ ] The requested outcome is complete.
- [ ] Important claims or changes have been verified.
- [ ] Reviewed deliverables are in \`output/\`.

## Decisions and notes
EOF
  cp "$TEMPLATES_ROOT/AGENTS.md" "$task_dir/AGENTS.md"
  ln -s AGENTS.md "$task_dir/CLAUDE.md"
  chmod 700 "$task_dir" "$task_dir/input" "$task_dir/working" "$task_dir/output"
  chmod 600 "$task_dir/TASK.md" "$task_dir/AGENTS.md"

  if [[ "$QUIET" == 1 ]]; then
    printf '%s\n' "$task_dir"
  else
    ok "created projectless task"
    ui_label 'Folder' "$task_dir"
    ui_label 'Primary client' "$client"
    info 'The folder stays in this location; update TASK.md instead of moving it between status folders.'
  fi

  case "$open_with" in
    vscode) open_vscode "$task_dir" ;;
    codex) start_codex "$task_dir" ;;
    claude) start_claude "$task_dir" ;;
  esac
}

list_tasks() {
  local file title status client relative count=0
  init_layout
  printf 'STATUS\tCLIENT\tTASK\tPATH\n'
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    title="$(metadata_value "$file" title)"
    status="$(metadata_value "$file" status)"
    client="$(metadata_value "$file" primary_client)"
    relative="${file%/TASK.md}"
    relative="${relative#"$PROJECTLESS_ROOT"/}"
    printf '%s\t%s\t%s\t%s\n' "${status:-unknown}" "${client:-unknown}" "${title:-Untitled}" "$relative"
    count=$((count + 1))
  done < <(find "$TASKS_ROOT" -mindepth 3 -maxdepth 3 -type f -name TASK.md -print 2>/dev/null | LC_ALL=C sort)
  [[ "$count" -gt 0 ]] || info 'no projectless tasks have been created yet'
}

show_status() {
  local task_dir title status kind client sensitivity created
  task_dir="$(resolve_task_path "${1:-$PWD}")"
  title="$(metadata_value "$task_dir/TASK.md" title)"
  status="$(metadata_value "$task_dir/TASK.md" status)"
  kind="$(metadata_value "$task_dir/TASK.md" kind)"
  client="$(metadata_value "$task_dir/TASK.md" primary_client)"
  sensitivity="$(metadata_value "$task_dir/TASK.md" sensitivity)"
  created="$(metadata_value "$task_dir/TASK.md" created)"
  ui_title '🧭' 'Projectless task'
  ui_label 'Title' "${title:-Untitled}"
  ui_label 'Status' "${status:-unknown}"
  ui_label 'Kind' "${kind:-unknown}"
  ui_label 'Primary client' "${client:-unknown}"
  ui_label 'Sensitivity' "${sensitivity:-unknown}"
  ui_label 'Created' "${created:-unknown}"
  ui_label 'Folder' "$task_dir"
}

mark_complete() {
  local task_dir file tmp
  task_dir="$(resolve_task_path "${1:-$PWD}")"
  file="$task_dir/TASK.md"
  tmp="$(mktemp "$task_dir/.TASK.XXXXXX")"
  awk 'BEGIN { changed=0 }
       /^status:[[:space:]]*/ && changed == 0 { print "status: complete"; changed=1; next }
       { print }
       END { if (changed == 0) exit 2 }' "$file" > "$tmp" || {
    rm -f "$tmp"
    die 'TASK.md has no status field to update'
  }
  chmod 600 "$tmp"
  mv "$tmp" "$file"
  ok "marked complete without moving the folder: $task_dir"
}

open_vscode() {
  local task_dir
  task_dir="$(resolve_task_path "${1:-$PWD}")"
  command -v code >/dev/null 2>&1 || die "VS Code's 'code' command is unavailable; install it from the VS Code Command Palette"
  info 'Review the individual folder before granting Workspace Trust; never trust the _Projectless parent by default.'
  exec code -n "$task_dir"
}

start_codex() {
  local task_dir
  task_dir="$(resolve_task_path "${1:-$PWD}")"
  command -v codex >/dev/null 2>&1 || die 'Codex CLI is not installed or not on PATH'
  info "starting Codex in: $task_dir"
  exec codex -C "$task_dir" --sandbox workspace-write --ask-for-approval on-request
}

start_claude() {
  local task_dir session_name
  task_dir="$(resolve_task_path "${1:-$PWD}")"
  command -v claude >/dev/null 2>&1 || die 'Claude Code is not installed or not on PATH'
  session_name="$(basename "$task_dir" | sed -E 's/^[0-9-]+--[0-9]+--//')"
  cd "$task_dir"
  info "starting Claude Code in Plan mode: $task_dir"
  exec claude --permission-mode plan --name "$session_name"
}

choose_number() {
  local prompt="$1" default="$2" maximum="$3" answer
  while :; do
    printf '%s [%s]: ' "$prompt" "$default" >&2
    IFS= read -r answer
    answer="${answer:-$default}"
    case "$answer" in
      ''|*[!0-9]*) warn "enter a number from 1 to $maximum" ;;
      *) if [[ "$answer" -ge 1 && "$answer" -le "$maximum" ]]; then printf '%s\n' "$answer"; return 0; fi; warn "enter a number from 1 to $maximum" ;;
    esac
  done
}

guided_create() {
  local title kind_choice client_choice sensitivity_choice open_choice
  [[ -t 0 && -t 1 ]] || die 'guided mode needs an interactive terminal'
  ui_title '🧠' 'Create a bounded projectless task'
  printf 'Use this only when work needs files but does not belong to a repository.\n'
  printf 'Existing repository work should use a Git worktree instead.\n\n'
  printf 'Task title [Untitled]: '
  IFS= read -r title
  title="${title:-Untitled}"
  printf '\nKind\n  1) Research\n  2) Document\n  3) Analysis\n  4) Prototype\n  5) Other\n'
  kind_choice="$(choose_number 'Choice' 5 5)"
  case "$kind_choice" in 1) kind=research ;; 2) kind=document ;; 3) kind=analysis ;; 4) kind=prototype ;; 5) kind=other ;; esac
  printf '\nPrimary application\n  1) Codex\n  2) Claude Code\n  3) VS Code only\n  4) Decide later\n'
  client_choice="$(choose_number 'Choice' 4 4)"
  case "$client_choice" in 1) client=codex ;; 2) client=claude ;; 3) client=vscode ;; 4) client=undecided ;; esac
  printf '\nSensitivity\n  1) Private\n  2) Work confidential\n  3) Public\n'
  sensitivity_choice="$(choose_number 'Choice' 1 3)"
  case "$sensitivity_choice" in 1) sensitivity=private ;; 2) sensitivity=work-confidential ;; 3) sensitivity=public ;; esac
  printf '\nOpen after creation\n  1) Do not open yet\n  2) VS Code\n  3) Codex CLI\n  4) Claude Code\n'
  open_choice="$(choose_number 'Choice' 1 4)"
  case "$open_choice" in 1) open_with=none ;; 2) open_with=vscode ;; 3) open_with=codex ;; 4) open_with=claude ;; esac
  create_task --title "$title" --kind "$kind" --client "$client" --sensitivity "$sensitivity" --open "$open_with"
}

command="${1:---guided}"
[[ $# -eq 0 ]] || shift
case "$command" in
  --guided|guided) guided_create "$@" ;;
  init) init_layout ;;
  create-task) create_task "$@" ;;
  list) list_tasks ;;
  status) show_status "${1:-$PWD}" ;;
  complete) mark_complete "${1:-$PWD}" ;;
  open-vscode) open_vscode "${1:-$PWD}" ;;
  start-codex) start_codex "${1:-$PWD}" ;;
  start-claude) start_claude "${1:-$PWD}" ;;
  -h|--help|help) usage ;;
  *) die "unknown command: $command (run with --help)" ;;
esac
