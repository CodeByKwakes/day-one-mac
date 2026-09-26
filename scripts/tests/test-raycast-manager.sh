#!/usr/bin/env bash
# Regression fixture for the track-aware Raycast Script Command generator.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-raycast-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
export DAY_ONE_MAC_STATE_ROOT="$HOME/.day-one-mac"
export DAY_ONE_RAYCAST_COMMAND_DIR="$HOME/.local/share/day-one-mac/raycast"
mkdir -p "$HOME/.local/bin" "$DAY_ONE_MAC_STATE_ROOT"
printf '3\n' > "$DAY_ONE_MAC_STATE_ROOT/track"
printf 'claude,codex,copilot-app,copilot-cli,raycast-ai\n' > "$DAY_ONE_MAC_STATE_ROOT/ai-clients"

cat > "$HOME/.local/bin/day-one-mac" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  root) printf '%s\n' '/tmp/day-one-mac-fixture' ;;
  *) printf 'fixture command: %s\n' "$*" ;;
esac
EOF
chmod 700 "$HOME/.local/bin/day-one-mac"

preview="$("$SCRIPT_DIR/configure-raycast.sh" --groups core,documentation,ai,hosting,safety --preview)"
grep -Fq 'Raycast alongside Spotlight' <<<"$preview"
grep -Fq 'Raycast Root Search: ⌥Space' <<<"$preview"
grep -Fq 'Spotlight Search:    ⌘Space (keep enabled)' <<<"$preview"
grep -Fq 'GitHub · Authentication Status' <<<"$preview"
grep -Fq 'Azure · Active Account' <<<"$preview"
grep -Fq 'AI · New Codex Task' <<<"$preview"
grep -Fq 'AI · New Claude Code Task' <<<"$preview"
grep -Fq 'AI · New Copilot CLI Task' <<<"$preview"
grep -Fq 'Day One · Preview Broad Cleanup' <<<"$preview"

raycast_only="$("$SCRIPT_DIR/configure-raycast.sh" --launcher-mode raycast-only --preview)"
grep -Fq 'Raycast-only launcher' <<<"$raycast_only"
grep -Fq 'disabled shortcut; ⌘Space remains unassigned' <<<"$raycast_only"
grep -Fq 'Spotlight indexing:  enabled' <<<"$raycast_only"
grep -Fq 'Raycast Quick AI:    no default global shortcut' <<<"$raycast_only"

"$SCRIPT_DIR/configure-raycast.sh" \
  --groups core,documentation,ai,hosting,safety \
  --launcher-mode alongside-spotlight \
  --apply --yes >/dev/null

[[ -f "$DAY_ONE_RAYCAST_COMMAND_DIR/.day-one-raycast-managed" ]]
[[ -f "$DAY_ONE_RAYCAST_COMMAND_DIR/_day-one-raycast-lib.sh" ]]
grep -Fq 'track=3' "$DAY_ONE_RAYCAST_COMMAND_DIR/.day-one-raycast-managed"
grep -Fq 'ai_clients=claude,codex,copilot-app,copilot-cli,raycast-ai' \
  "$DAY_ONE_RAYCAST_COMMAND_DIR/.day-one-raycast-managed"
grep -Fq 'launcher_mode=alongside-spotlight' \
  "$DAY_ONE_RAYCAST_COMMAND_DIR/.day-one-raycast-managed"
grep -Fqx 'alongside-spotlight' "$DAY_ONE_MAC_STATE_ROOT/raycast-launcher-mode"
grep -Flq '# @raycast.title GitHub · Authentication Status' "$DAY_ONE_RAYCAST_COMMAND_DIR"/*.sh
grep -Flq '# @raycast.title Azure · Active Account' "$DAY_ONE_RAYCAST_COMMAND_DIR"/*.sh
grep -Flq '# @raycast.title AI · New Codex Task' "$DAY_ONE_RAYCAST_COMMAND_DIR"/*.sh
grep -Flq '# Suggested alias: d1s' "$DAY_ONE_RAYCAST_COMMAND_DIR"/*.sh
grep -Flq 'source "$COMMAND_DIR/_day-one-raycast-lib.sh"' "$DAY_ONE_RAYCAST_COMMAND_DIR"/*.sh

if rg -n --glob '*.sh' -- '--execute|brew[[:space:]]+uninstall|rm[[:space:]]+-rf' \
  "$DAY_ONE_RAYCAST_COMMAND_DIR" >/dev/null; then
  printf 'generated Raycast commands contain a prohibited execution path\n' >&2
  exit 1
fi

for command_file in "$DAY_ONE_RAYCAST_COMMAND_DIR"/*.sh; do
  bash -n "$command_file"
done

second_apply="$("$SCRIPT_DIR/configure-raycast.sh" \
  --groups core,documentation,ai,hosting,safety \
  --apply --yes)"
grep -Fq 'already current' <<<"$second_apply"

status="$("$SCRIPT_DIR/configure-raycast.sh" --status)"
grep -Fq 'generated commands are present' <<<"$status"
grep -Fq 'Saved launcher guidance' <<<"$status"
grep -Fq 'Raycast alongside Spotlight' <<<"$status"

extensions="$("$SCRIPT_DIR/configure-raycast.sh" --extensions)"
grep -Fq 'Warp' <<<"$extensions"
grep -Fq 'Visual Studio Code' <<<"$extensions"
grep -Fq 'GitHub Copilot' <<<"$extensions"
grep -Fq 'Obsidian' <<<"$extensions"

"$SCRIPT_DIR/configure-raycast.sh" --remove-generated --yes >/dev/null
[[ ! -e "$DAY_ONE_RAYCAST_COMMAND_DIR" ]]
find "$DAY_ONE_MAC_STATE_ROOT/raycast-command-backups" -maxdepth 1 \
  -type d -name 'removed-*' | grep -q .

printf 'Raycast manager fixture passed\n'
