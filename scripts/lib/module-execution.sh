#!/usr/bin/env bash
# Apply-only records. Preview/check callers must never call begin.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/state.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/operation-lock.sh"
MODULE_RUN=""
MODULE_VERIFIED=0

day_one_module_begin() {
  local id="$1" selection="$2" target index=0
  shift 2
  [[ "$id" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || { printf 'Invalid module ID: %s\n' "$id" >&2; return 1; }
  # Validate records before creating any run or copying pre-existing content.
  for target in "$@"; do
    day_one_safe_state_path "$target" || return 1
    [[ ! -e "$target" || -f "$target" ]] || return 1
  done
  umask 077
  day_one_state_directory "$STATE_DIR/module-runs/$id" || return 1
  MODULE_RUN="$(mktemp -d "$STATE_DIR/module-runs/$id/$(date -u '+%Y%m%dT%H%M%SZ').XXXXXX")" || return 1
  MODULE_VERIFIED=0
  mkdir "$MODULE_RUN/before" || return 1
  day_one_write_state "$MODULE_RUN/selection" "$selection" || return 1
  day_one_write_state "$MODULE_RUN/result" running || return 1
  trap 'day_one_module_finish "$?"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  # Back up Day One-owned records, not application data or secrets.
  for target in "$@"; do
    [[ ! -L "$target" && ( ! -e "$target" || -f "$target" ) ]] || {
      printf 'Refusing non-regular module record: %s\n' "$target" >&2
      return 1
    }
    index=$((index + 1))
    if [[ -f "$target" ]]; then
      cp -p "$target" "$MODULE_RUN/before/$index"
      chmod 600 "$MODULE_RUN/before/$index"
      printf '%s\t%s\n' "$index" "$target" >> "$MODULE_RUN/backups.tsv"
    else
      printf '%s\n' "$target" >> "$MODULE_RUN/previously-absent.txt"
    fi
  done
  day_one_module_event begin "$id"
}

day_one_module_event() {
  [[ -n "${MODULE_RUN:-}" ]] || return 0
  printf '%s\t%s\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1" "$2" >> "$MODULE_RUN/journal.tsv"
}

day_one_module_finish() {
  local status="$1" result=incomplete
  trap - EXIT
  if [[ "$status" == 0 && "$MODULE_VERIFIED" == 1 ]]; then result=verified; fi
  day_one_write_state "$MODULE_RUN/result" "$result" || true
  day_one_module_event exit "$status" || true
  printf 'Module run: %s (%s)\n' "$MODULE_RUN" "$result" >&2
  if [[ "$result" != verified ]]; then
    printf 'Applied changes were retained. Review the journal and resume the saved selection; no automatic rollback was attempted.\n' >&2
  fi
  exit "$status"
}
