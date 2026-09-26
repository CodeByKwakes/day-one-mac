#!/usr/bin/env bash
# macOS mv -h replaces the symlink itself with one same-filesystem rename.
# Callers serialize mutations using with-operation-lock.sh.
day_one_valid_version() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && "$1" != *..* ]]
}

day_one_activate_runtime() {
  local runtime="$1" version="$2" current previous='' temporary expected actual
  day_one_valid_version "$version" || { printf 'Invalid runtime version: %s\n' "$version" >&2; return 2; }
  current="$runtime/current"
  [[ -d "$runtime/releases/$version" && ! -L "$runtime/releases/$version" ]] || return 1
  [[ ! -e "$current" || -L "$current" ]] || {
    printf 'Refusing to replace a non-symlink runtime path: %s\n' "$current" >&2; return 1;
  }
  (cd "$runtime/releases/$version" && shasum -a 256 -c SHA256SUMS >/dev/null) || return 1
  [[ ! -L "$current" ]] || previous="$(readlink "$current")"
  if [[ "$previous" != "releases/$version" && -n "$previous" ]]; then
    # Write recovery history first. An interruption before rename leaves current
    # unchanged; default rollback rejects a previous entry equal to current.
    day_one_write_state "$runtime/previous" "$previous" || return 1
  fi
  temporary="$(mktemp -d "$runtime/.activate.XXXXXX")" || return 1
  ln -s "releases/$version" "$temporary/current" || { rmdir "$temporary"; return 1; }
  if ! /bin/mv -fh "$temporary/current" "$current"; then
    rm -f "$temporary/current"; rmdir "$temporary"; return 1
  fi
  rmdir "$temporary"
  expected="$(cd -P "$runtime/releases/$version" && pwd)"
  actual="$(cd -P "$current" && pwd)"
  [[ "$actual" == "$expected" ]]
}

# Replace the launcher as a complete file, never truncate a live executable.
day_one_install_launcher() {
  local source="$1" target="$2" temporary
  [[ ! -d "$target" ]] || return 1
  temporary="$(mktemp "$(dirname "$target")/.day-one-launcher.XXXXXX")" || return 1
  if ! { install -m 700 "$source" "$temporary" && /bin/mv -fh "$temporary" "$target"; }; then
    rm -f "$temporary"
    return 1
  fi
}
