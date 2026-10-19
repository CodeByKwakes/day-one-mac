#!/usr/bin/env bash
# Compatibility wrapper: the dynamic manager owns all generated layouts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_SELECTION=both
VAULT_PATH="$HOME/Vaults/Second Brain"
APPLY=0
INSTALL_APPS=0
ASSUME_YES=0
APP_INSTALL_POLICY=""

usage() {
  printf '%s\n' \
    'Usage: ./scripts/setup-second-brain.sh [options]' \
    '' \
    'Compatibility shortcut for one vault with the three standard domains.' \
    'For dynamic vaults/domains, use second-brain-manager.sh --guided.' \
    '' \
    'Options:' \
    '  --tools raycast|claude|codex|both|raycast-codex|claude-codex|all' \
    '  --stack VALUE        compatibility alias for --tools' \
    '  --vault ABSOLUTE_PATH' \
    '  --apply' \
    '  --install-apps' \
    '  --app-install-policy prompt|homebrew|check-only' \
    '  --yes' \
    '  --help'
}
die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --tools|--stack) [[ "$#" -ge 2 ]] || die "$1 needs a value"; TOOLS_SELECTION="$2"; shift 2 ;;
    --vault) [[ "$#" -ge 2 ]] || die '--vault needs a path'; VAULT_PATH="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --install-apps) INSTALL_APPS=1; shift ;;
    --app-install-policy) [[ "$#" -ge 2 ]] || die '--app-install-policy needs a value'; APP_INSTALL_POLICY="$2"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

case "$TOOLS_SELECTION" in
  raycast|claude|codex) TOOLS="$TOOLS_SELECTION" ;;
  both) TOOLS='raycast,claude' ;;
  raycast-codex) TOOLS='raycast,codex' ;;
  claude-codex) TOOLS='claude,codex' ;;
  all) TOOLS='raycast,claude,codex' ;;
  *) die "invalid tool selection: $TOOLS_SELECTION" ;;
esac

args=(--preset unified --single-vault "$VAULT_PATH" --tools "$TOOLS")
[[ "$APPLY" == 1 ]] && args+=(--apply)
[[ "$INSTALL_APPS" == 1 ]] && args+=(--install-apps)
[[ -n "$APP_INSTALL_POLICY" ]] && args+=(--app-install-policy "$APP_INSTALL_POLICY")
[[ "$ASSUME_YES" == 1 ]] && args+=(--yes)

exec "$SCRIPT_DIR/second-brain-manager.sh" "${args[@]}"
