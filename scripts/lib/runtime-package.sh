#!/usr/bin/env bash
# The explicit file manifest is shared by release builds and local installations.
day_one_copy_runtime() {
  local source="$1" destination="$2" relative parent
  [[ -s "$source/config/runtime-files.txt" ]] || {
    printf 'Missing runtime file manifest: %s\n' "$source/config/runtime-files.txt" >&2; return 1;
  }
  mkdir -p "$destination"
  while IFS= read -r relative; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    case "$relative" in /*|../*|*/../*|*/..|.git|.git/*)
      printf 'Unsafe runtime manifest entry: %s\n' "$relative" >&2; return 1 ;;
    esac
    [[ -f "$source/$relative" && ! -L "$source/$relative" ]] || {
      printf 'Runtime entry must be a regular file: %s\n' "$relative" >&2; return 1;
    }
    # Reject symlink parents too: the allowlist must not copy outside the source.
    parent="$(dirname "$relative")"
    while [[ "$parent" != . ]]; do
      [[ ! -L "$source/$parent" ]] || return 1
      parent="$(dirname "$parent")"
    done
    mkdir -p "$destination/$(dirname "$relative")"
    cp -p "$source/$relative" "$destination/$relative" || return 1
  done < "$source/config/runtime-files.txt"
}

day_one_checksum_runtime() {
  (
    cd "$1" || exit 1
    find . -type f ! -name SHA256SUMS -print | LC_ALL=C sort |
      while IFS= read -r file; do shasum -a 256 "$file" || exit 1; done > SHA256SUMS
    shasum -a 256 -c SHA256SUMS >/dev/null
  )
}
