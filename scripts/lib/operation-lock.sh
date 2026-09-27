#!/usr/bin/env bash
# Re-enter only mutating commands under a supervisor so other EXIT traps remain
# independent. A lock inherited by child commands is reused.
day_one_serialize() {
  local script="$2"
  shift 2
  local lock="${STATE_ROOT:-${DAY_ONE_MAC_STATE_ROOT:-${FRESH_START_STATE_ROOT:-$HOME/.day-one-mac}}}.operation.lock"
  if [[ "${DAY_ONE_OPERATION_LOCK:-}" == "$lock" && -r "$lock/owner" &&
        "$(cat "$lock/owner")" == "${DAY_ONE_OPERATION_OWNER:-}" ]]; then
    return 0
  fi
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/with-operation-lock.sh" "$lock" /bin/bash "$script" "$@"
}
