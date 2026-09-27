#!/usr/bin/env bash
# Packaged-runtime checks. Phase 8 adds the track/stack-specific machine checks.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/runtime-package.sh"
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
done < <(find "$SCRIPT_DIR/lib" "$SCRIPT_DIR/phases" -type f -name '*.sh' -print0)
printf '✓ Runtime verification passed. Run setup --phase 08 for machine verification.\n'
