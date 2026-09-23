#!/usr/bin/env bash
# Shortcut for the standard multi-domain, one-vault-per-domain layout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH="$HOME/Vaults"
TOOLS=all
APPLY=0
ASSUME_YES=0

usage() {
  printf '%s\n' \
    'Usage: ./scripts/setup-multi-vaults.sh [options]' \
    '' \
    'Shortcut for the standard multi-domain physical-vault layout.' \
    'For selectable or custom domains, use second-brain-manager.sh --guided.' \
    '' \
    'Options:' \
    '  --root ABSOLUTE_PATH' \
    '  --tools none|raycast|claude|codex|all' \
    '  --apply' \
    '  --yes' \
    '  --help'
}
die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root) [[ "$#" -ge 2 ]] || die '--root needs a path'; ROOT_PATH="$2"; shift 2 ;;
    --tools) [[ "$#" -ge 2 ]] || die '--tools needs a value'; TOOLS="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

args=(--preset multi-domain --root "$ROOT_PATH" --tools "$TOOLS")
[[ "$APPLY" == 1 ]] && args+=(--apply)
[[ "$ASSUME_YES" == 1 ]] && args+=(--yes)
exec "$SCRIPT_DIR/second-brain-manager.sh" "${args[@]}"
