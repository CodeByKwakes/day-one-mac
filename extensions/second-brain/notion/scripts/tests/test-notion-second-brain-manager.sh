#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/notion-second-brain-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
mkdir -p "$HOME"

"$ROOT/scripts/notion-second-brain-manager.sh" \
  --usage separate \
  --domains 'Software Development,Software Content,Tech Content,Research' \
  --assistants 'claude,codex' \
  --raycast yes \
  --hq-url 'https://www.notion.so/example-hq' \
  --capture-url 'https://forms.notion.site/example-form' \
  --apply

CONFIG="$HOME/.config/second-brain-notion/config"
PLAN="$HOME/.local/state/second-brain-notion/setup-plan.md"
RAYCAST="$HOME/.local/share/second-brain-notion/raycast"

grep -Fq $'usage\tseparate' "$CONFIG"
grep -Fq $'domains\tSoftware Development,Software Content,Tech Content,Research' "$CONFIG"
grep -Fq 'Personal and work information use separate' "$PLAN"
grep -Fq '"Research"' "$HOME/.local/state/second-brain-notion/seeds/domains.csv"
grep -Fq '"First capture — Research"' "$HOME/.local/state/second-brain-notion/seeds/starter-knowledge.csv"
[[ -x "$RAYCAST/open-notion-second-brain.sh" ]]
[[ -x "$RAYCAST/capture-to-notion-second-brain.sh" ]]

"$ROOT/scripts/notion-second-brain-manager.sh" --validate
"$ROOT/scripts/notion-second-brain-manager.sh" --show | grep -Fq '# Notion Second Brain setup plan'

if "$ROOT/scripts/notion-second-brain-manager.sh" --assistants 'none,codex' >/dev/null 2>&1; then
  printf 'FAIL: invalid mixed none assistant selection was accepted\n' >&2
  exit 1
fi

printf 'PASS: Notion Second Brain manager fixture\n'
