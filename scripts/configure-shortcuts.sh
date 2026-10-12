#!/usr/bin/env bash
# Open Apple's reviewed import flow; never write the Shortcuts database.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  printf '%s\n' \
    'Usage: day-one-mac shortcuts [--plan | --import | --guided] [--dry-run]' \
    '' \
    'Default: preview the bundled Open in VS Code Finder shortcut.' \
    '--import opens the signed file in Shortcuts; review and click Add Shortcut.' \
    '--guided asks before opening the import screen.' \
    '--dry-run previews only, including with --import or --guided.' \
    'Existing shortcuts and global hotkeys are not changed by this command.' \
    'Guide: day-one-mac docs shortcuts --browser'
}

main() {
  local action=plan selected=0 dry_run=0 answer='' asset
  while (( $# )); do
    case "$1" in
      --plan|--import|--guided)
        [[ "$selected" == 0 ]] || { usage >&2; return 2; }
        action="${1#--}"; selected=1 ;;
      --dry-run) dry_run=1 ;;
      -h|--help) usage; return 0 ;;
      *) printf 'Unknown shortcuts option: %s\n' "$1" >&2; usage >&2; return 2 ;;
    esac
    shift
  done
  asset="$ROOT/config/shortcuts/Open in VS Code.shortcut"
  [[ -s "$asset" && ! -L "$asset" && ! -L "$ROOT/config/shortcuts" ]] || {
    printf 'Bundled shortcut is missing or is a symlink. Repair the runtime.\n' >&2; return 1; }
  printf '%s\n' \
    'Open in VS Code · optional Finder Quick Action' \
    'Input: selected folder. Action: Open File in Visual Studio Code.' \
    'No shell script, fixed folder path, global hotkey, or setup-state write.' \
    "Import file: $asset" \
    'In Shortcuts, review the action and click Add Shortcut.' \
    'If a shortcut with this name already exists, cancel to keep your version.' \
    'Then test Finder → right-click a folder → Quick Actions → Open in VS Code.'
  if [[ "$action" == plan || "$dry_run" == 1 ]]; then
    printf 'Preview only. Use day-one-mac shortcuts --import to open the import screen.\n'
    return 0
  fi
  [[ "$(uname -s)" == Darwin ]] || { printf 'Shortcut import requires macOS.\n' >&2; return 1; }
  command -v open >/dev/null 2>&1 || { printf 'The macOS open command is unavailable.\n' >&2; return 1; }
  if [[ "$action" == guided ]]; then
    [[ -t 0 ]] || { printf 'Use --import explicitly outside an interactive terminal.\n' >&2; return 2; }
    printf 'Open the Shortcuts import screen? [y/N] '
    IFS= read -r answer || return 0
    case "$answer" in y|Y|yes|YES) ;; *) printf 'Nothing changed.\n'; return 0 ;; esac
  fi
  open -a Shortcuts "$asset"
  printf 'Import screen requested; installation is not yet verified. Finish in Shortcuts, then test in Finder.\n'
}
main "$@"
