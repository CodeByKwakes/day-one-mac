#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
STATE_ROOT="${DAY_ONE_MAC_STATE_ROOT:-$HOME/.day-one-mac}"
RUNTIME_HOME="${DAY_ONE_MAC_RUNTIME_HOME:-$HOME/.local/share/day-one-mac}"
CURRENT_LINK="$RUNTIME_HOME/current"
COMMAND="$HOME/.local/bin/day-one-mac"

usage() {
  cat <<'EOF'
Usage: day-one-mac runtime-status
       day-one-mac update
       day-one-mac rollback-runtime [--version VERSION] [--execute]
       day-one-mac uninstall-runtime [--execute]
       day-one-mac docs [--open]
EOF
}

verify_runtime() {
  [[ -s "$RUNTIME_ROOT/SHA256SUMS" ]] || return 2
  (cd "$RUNTIME_ROOT" && shasum -a 256 -c SHA256SUMS >/dev/null)
}

status() {
  local version='unknown' mode='linked checkout' integrity='not packaged'
  [[ -s "$RUNTIME_ROOT/VERSION" ]] && version="$(sed -n '1p' "$RUNTIME_ROOT/VERSION")"
  if [[ "$RUNTIME_ROOT" == "$RUNTIME_HOME"/releases/* ]]; then
    mode='standalone runtime'
  fi
  if [[ -s "$RUNTIME_ROOT/SHA256SUMS" ]]; then
    if verify_runtime; then integrity='verified'; else integrity='FAILED'; fi
  fi
  printf '%s\n' \
    'Day One Mac runtime' \
    "  Mode:      $mode" \
    "  Version:   $version" \
    "  Root:      $RUNTIME_ROOT" \
    "  Command:   $COMMAND" \
    "  Integrity: $integrity" \
    "  State:     $STATE_ROOT"
  [[ "$integrity" != FAILED ]]
}

rollback_runtime() {
  local execute=0 requested='' candidate='' current=''
  while (( $# )); do
    case "$1" in
      --version) requested="${2:?--version requires a value}"; shift 2 ;;
      --execute) execute=1; shift ;;
      -h|--help) usage; return 0 ;;
      *) printf 'Unknown rollback option: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  [[ -L "$CURRENT_LINK" && -d "$RUNTIME_HOME/releases" ]] || {
    printf 'No standalone runtime history is installed.\n' >&2; return 1; }
  current="$(basename "$(cd -P "$CURRENT_LINK" && pwd)")"
  if [[ -n "$requested" ]]; then
    candidate="$RUNTIME_HOME/releases/$requested"
  else
    for path in "$RUNTIME_HOME"/releases/*; do
      [[ -d "$path" && "$(basename "$path")" != "$current" ]] || continue
      candidate="$path"
    done
  fi
  [[ -n "$candidate" && -d "$candidate" && -s "$candidate/SHA256SUMS" ]] || {
    printf 'No previous verified runtime was found.\n' >&2; return 1; }
  (cd "$candidate" && shasum -a 256 -c SHA256SUMS >/dev/null) || {
    printf 'Candidate runtime failed checksum verification: %s\n' "$candidate" >&2; return 1; }
  printf 'Current:  %s\nCandidate:%s\n' "$current" " $(basename "$candidate")"
  [[ "$execute" == 1 ]] || {
    printf 'Preview only. Rerun with --execute to switch versions.\n'; return 0; }
  next="$RUNTIME_HOME/.current-$$"
  ln -s "releases/$(basename "$candidate")" "$next"
  mv -f "$next" "$CURRENT_LINK"
  install -m 700 "$CURRENT_LINK/scripts/day-one-mac" "$COMMAND"
  printf '%s\n' "$CURRENT_LINK" > "$STATE_ROOT/runtime-root"
  printf '✓ Runtime switched to %s\n' "$(basename "$candidate")"
}

uninstall_runtime() {
  local execute=0
  [[ "${1:-}" == --execute ]] && execute=1
  printf '%s\n' \
    'Day One Mac runtime removal' \
    "  Command: $COMMAND" \
    "  Runtime: $RUNTIME_HOME" \
    "  Preserved state: $STATE_ROOT" \
    '  Installed applications, packages, dotfiles and settings: preserved'
  [[ "$execute" == 1 ]] || {
    printf 'Preview only. Rerun with --execute to remove the command and runtime.\n'; return 0; }
  printf 'Type REMOVE DAY ONE MAC RUNTIME to continue: '
  IFS= read -r answer
  [[ "$answer" == 'REMOVE DAY ONE MAC RUNTIME' ]] || {
    printf 'Confirmation did not match; nothing changed.\n' >&2; return 10; }
  [[ "$COMMAND" != / && "$RUNTIME_HOME" != / && "$RUNTIME_HOME" != "$HOME" ]] || return 1
  rm -f "$COMMAND"
  rm -rf "$RUNTIME_HOME"
  rm -f "$STATE_ROOT/runtime-root"
  printf '✓ Runtime removed. Saved setup state was preserved.\n'
}

open_docs() {
  local index="$RUNTIME_ROOT/docs/START-HERE.md"
  [[ -f "$index" ]] || { printf 'Documentation is missing: %s\n' "$index" >&2; return 1; }
  if [[ "${1:-}" == --open ]]; then
    open "$index"
  else
    printf '%s\n' "$index"
  fi
}

case "${1:-status}" in
  status) shift || true; status "$@" ;;
  update)
    shift || true
    exec "$RUNTIME_ROOT/install-day-one-mac" --update "$@"
    ;;
  rollback) shift || true; rollback_runtime "$@" ;;
  uninstall) shift || true; uninstall_runtime "$@" ;;
  docs) shift || true; open_docs "$@" ;;
  -h|--help|help) usage ;;
  *) printf 'Unknown runtime action: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
