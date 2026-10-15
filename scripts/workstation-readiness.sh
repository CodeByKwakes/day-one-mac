#!/usr/bin/env bash
# Read-only by default; explicit snapshot/template actions create private files.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
STATE_DIR="$(day_one_state_dir "$(day_one_state_root)")"
mode=personal
[[ ! -r "$STATE_DIR/deployment-mode" ]] || mode="$(cat "$STATE_DIR/deployment-mode")"
args=(--mode "$mode" --evidence "$STATE_DIR/workstation-evidence.json")
if [[ -s "$STATE_DIR/workstation-policy" ]]; then args+=(--policy "$(cat "$STATE_DIR/workstation-policy")"); fi
command -v python3 >/dev/null 2>&1 || { printf 'Python 3 is required for workstation evidence checks. Use the approved toolchain.\n' >&2; exit 10; }
exec python3 -I -B "$SCRIPT_DIR/lib/workstation-readiness.py" "${args[@]}" "$@"
