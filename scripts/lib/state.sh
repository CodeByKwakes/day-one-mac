#!/usr/bin/env bash
# Atomic scalar state writes; callers hold the operation lock for read/modify/write.

# Inspect the lexical path before creating anything. Resolving the whole path
# first would hide redirected parents. Only macOS's fixed system aliases are
# accepted; user-created symlinks must be supplied as their physical paths.
# The operation lock serializes Day One writers, not hostile same-user races.
day_one_safe_state_path() {
  local path="$1" component current='' remaining
  [[ "$path" == /* ]] || path="$(pwd -P)/$path"
  remaining="${path#/}"
  while [[ -n "$remaining" ]]; do
    component="${remaining%%/*}"
    if [[ "$remaining" == */* ]]; then remaining="${remaining#*/}"; else remaining=''; fi
    case "$component" in ''|.) continue ;; ..) printf 'Refusing parent traversal in state path: %s\n' "$path" >&2; return 1 ;; esac
    current="$current/$component"
    if [[ -L "$current" ]]; then
      case "$current:$(readlink "$current")" in
        /tmp:private/tmp|/var:private/var|/etc:private/etc) ;;
        *) printf 'Refusing symlink in state path: %s\n' "$current" >&2; return 1 ;;
      esac
    fi
    if [[ -n "$remaining" && -e "$current" && ! -d "$current" ]]; then
      printf 'Refusing non-directory state parent: %s\n' "$current" >&2; return 1
    fi
  done
}

day_one_state_directory() {
  day_one_safe_state_path "$1/.day-one-path-check" || return 1
  mkdir -p "$1" || return 1
  day_one_safe_state_path "$1/.day-one-path-check"
}

day_one_write_state() {
  local target="$1" value="$2" temporary
  day_one_safe_state_path "$target" || return 1
  [[ ! -e "$target" || -f "$target" ]] || { printf 'Refusing non-regular state target: %s\n' "$target" >&2; return 1; }
  day_one_state_directory "$(dirname "$target")" || return 1
  temporary="$(mktemp "$(dirname "$target")/.state.XXXXXX")" || return 1
  if ! { printf '%s\n' "$value" > "$temporary" && chmod 600 "$temporary" && mv -f "$temporary" "$target"; }; then
    rm -f "$temporary"
    return 1
  fi
}
