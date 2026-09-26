#!/usr/bin/env bash
# Atomic scalar state writes; callers hold the operation lock for read/modify/write.

day_one_write_state() {
  local target="$1" value="$2" temporary
  [[ ! -d "$target" && ! -L "$target" ]] || { printf 'Refusing non-regular state target: %s\n' "$target" >&2; return 1; }
  mkdir -p "$(dirname "$target")"
  temporary="$(mktemp "$(dirname "$target")/.state.XXXXXX")" || return 1
  if ! { printf '%s\n' "$value" > "$temporary" && chmod 600 "$temporary" && mv -f "$temporary" "$target"; }; then
    rm -f "$temporary"
    return 1
  fi
}
