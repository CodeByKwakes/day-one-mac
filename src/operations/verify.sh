#!/usr/bin/env bash
# Packaged-runtime checks; actual machine checks belong to each capability.
set -euo pipefail
DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../src/core/runtime-package.sh"
case "${1:-}" in
  -h|--help) printf '%s\n' 'Usage: day-one-mac verify' 'Check runtime integrity and executable entry points without changing setup state.'; exit 0 ;;
  '') ;;
  *) printf 'Unknown verification option: %s\n' "$1" >&2; exit 2 ;;
esac
if [[ -s "$ROOT/SHA256SUMS" ]]; then
  day_one_verify_runtime "$ROOT"
elif [[ -e "$ROOT/.git" ]]; then
  printf 'Development checkout: no packaged integrity manifest.\n'
else
  printf 'Runtime integrity manifest is missing. Reinstall the runtime.\n' >&2
  exit 1
fi
for script in day-one-mac bootstrap-day-one-mac.sh setup.sh runtime-manager.sh; do
  [[ -x "$SCRIPT_DIR/$script" ]] || { printf 'Missing executable: %s\n' "$script" >&2; exit 1; }
  /bin/bash -n "$SCRIPT_DIR/$script"
done
while IFS= read -r -d '' script; do
  /bin/bash -n "$script"
done < <(find "$ROOT/src" "$SCRIPT_DIR/lib" -type f -name '*.sh' -print0)
printf '✓ Runtime verification passed. Use each selected capability guide for machine verification.\n'
