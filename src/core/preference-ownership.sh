#!/usr/bin/env bash
# Preference writes require current evidence that management does not own them.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/state.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/deadline.sh"

day_one_require_personal_preferences() {
  local state="$1" probe output result=0
  day_one_safe_state_path "$state/deployment-mode" || return 10
  if [[ -e "$state/deployment-mode" && ! -f "$state/deployment-mode" ]]; then
    printf 'Resolve the invalid deployment ownership record before changing preferences.\n' >&2
    return 10
  fi
  if [[ -f "$state/deployment-mode" && "$(cat "$state/deployment-mode")" == managed ]]; then
    printf 'Managed preferences belong to the policy owner; use MDM/IT to change them.\n' >&2
    return 10
  fi
  command -v profiles >/dev/null 2>&1 || {
    printf 'Cannot inspect device management; no preferences changed.\n' >&2
    return 10
  }
  probe="$(mktemp "${TMPDIR:-/tmp}/day-one-management.XXXXXX")" || return 10
  if run_with_deadline "$probe" 15 env LC_ALL=C profiles status -type enrollment; then
    output="$(cat "$probe")"
    if grep -Eiq '(MDM enrollment|Enrolled via DEP):[[:space:]]*Yes' <<< "$output"; then
      printf 'Device management is active; use MDM/IT to change preferences.\n' >&2
      result=10
    elif ! grep -Eq '^MDM enrollment:[[:space:]]*No[[:space:]]*$' <<< "$output"; then
      printf 'Device management status is unknown; no preferences changed.\n' >&2
      result=10
    fi
  else
    printf 'Device management inspection failed; no preferences changed.\n' >&2
    result=10
  fi
  rm -f "$probe" "$probe.deadline"
  return "$result"
}
