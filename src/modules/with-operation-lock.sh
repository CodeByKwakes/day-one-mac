#!/usr/bin/env bash
# Keep locks outside state/runtime directories, which cleanup may archive.
set -euo pipefail
lock="$1"
shift
[[ "$#" -gt 0 ]] || exit 2
if [[ "${DAY_ONE_OPERATION_LOCK:-}" == "$lock" &&
      -r "$lock/owner" && "$(cat "$lock/owner")" == "${DAY_ONE_OPERATION_OWNER:-}" ]]; then
  exec "$@"
fi
mkdir -p "$(dirname "$lock")"
if ! mkdir -m 700 "$lock" 2>/dev/null; then
  printf 'Another Day One Mac operation holds %s (PID %s).\n' "$lock" "$(cat "$lock/owner" 2>/dev/null || printf unknown)" >&2
  printf 'If that process has exited, remove only this lock directory and retry.\n' >&2
  exit 75
fi
cleanup_lock() { rm -f "$lock/owner"; rmdir "$lock"; }
trap cleanup_lock EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
printf '%s\n' "$$" > "$lock/owner"
export DAY_ONE_OPERATION_LOCK="$lock" DAY_ONE_OPERATION_OWNER="$$"
"$@"
