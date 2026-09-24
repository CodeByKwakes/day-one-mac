#!/usr/bin/env bash
# Regression fixture for immutable projectless task workspaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-workspace-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
export DAY_ONE_PROJECTLESS_ROOT="$HOME/Developer/_Projectless"
mkdir -p "$HOME"

"$SCRIPT_DIR/workspace-manager.sh" init >/dev/null

[[ -d "$DAY_ONE_PROJECTLESS_ROOT/app-storage/codex-projectless" ]]
[[ -d "$DAY_ONE_PROJECTLESS_ROOT/app-storage/claude-cowork" ]]

first="$("$SCRIPT_DIR/workspace-manager.sh" create-task \
  --title 'Compare database clients' \
  --kind research \
  --client codex \
  --sensitivity private \
  --quiet)"
second="$("$SCRIPT_DIR/workspace-manager.sh" create-task \
  --title 'Compare database clients' \
  --kind research \
  --client claude \
  --sensitivity work-confidential \
  --quiet)"

[[ "$first" == "$DAY_ONE_PROJECTLESS_ROOT"/tasks/????/????-??-??--??????--compare-database-clients* ]]
[[ "$second" == "$DAY_ONE_PROJECTLESS_ROOT"/tasks/????/????-??-??--??????--compare-database-clients* ]]
[[ "$first" != "$second" ]]

for required in TASK.md AGENTS.md CLAUDE.md input working output; do
  [[ -e "$first/$required" ]]
done
[[ -L "$first/CLAUDE.md" ]]
[[ "$(readlink "$first/CLAUDE.md")" == AGENTS.md ]]
[[ ! -e "$DAY_ONE_PROJECTLESS_ROOT/.git" ]]

grep -Fq "title: 'Compare database clients'" "$first/TASK.md"
grep -Fq 'status: inbox' "$first/TASK.md"
grep -Fq 'primary_client: codex' "$first/TASK.md"
grep -Fq 'Treat `input/` as read-only' "$first/AGENTS.md"

quoted_title="$("$SCRIPT_DIR/workspace-manager.sh" create-task \
  --title "Review Codex: Alex's notes" \
  --kind document \
  --client vscode \
  --sensitivity private \
  --quiet)"
grep -Fq "title: 'Review Codex: Alex''s notes'" "$quoted_title/TASK.md"
quoted_status="$("$SCRIPT_DIR/workspace-manager.sh" status "$quoted_title")"
grep -Fq "Review Codex: Alex's notes" <<<"$quoted_status"

list_output="$("$SCRIPT_DIR/workspace-manager.sh" list)"
grep -Fq $'inbox\tcodex\tCompare database clients\t' <<<"$list_output"
grep -Fq $'inbox\tclaude\tCompare database clients\t' <<<"$list_output"

status_output="$("$SCRIPT_DIR/workspace-manager.sh" status "$first")"
grep -Fq 'Compare database clients' <<<"$status_output"
grep -Fq 'Primary client' <<<"$status_output"

"$SCRIPT_DIR/workspace-manager.sh" complete "$first" >/dev/null
grep -Fq 'status: complete' "$first/TASK.md"

if "$SCRIPT_DIR/workspace-manager.sh" status "$DAY_ONE_PROJECTLESS_ROOT" >/dev/null 2>&1; then
  printf 'workspace manager accepted the projectless parent as a task\n' >&2
  exit 1
fi

if "$SCRIPT_DIR/workspace-manager.sh" status "$DAY_ONE_PROJECTLESS_ROOT/tasks/$(date +%Y)" >/dev/null 2>&1; then
  printf 'workspace manager accepted a year container as a task\n' >&2
  exit 1
fi

mkdir -p "$DAY_ONE_PROJECTLESS_ROOT/00_Inbox/legacy-task"
legacy_output="$("$SCRIPT_DIR/workspace-manager.sh" init 2>&1)"
grep -Fq 'Folders created by an earlier _Projectless layout were found and left unchanged.' <<<"$legacy_output"
[[ -d "$DAY_ONE_PROJECTLESS_ROOT/00_Inbox/legacy-task" ]]

printf 'workspace manager fixture passed\n'
