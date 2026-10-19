#!/usr/bin/env bash
# The explicit file manifest is shared by release builds and local installations.

# Checksums alone do not detect added files. Validate the allowlist, all object
# types, and the checksum inventory before reading any checksum target. This
# detects modified installations; authenticity still relies on release provenance.
day_one_verify_runtime() (
  local relative parent line files='' entries='./SHA256SUMS' listed='' expected actual
  local checksum_pattern='^[0-9a-f]{64}  \./(.+)$'
  export LC_ALL=C
  set -o pipefail
  cd -P "$1" || return 1
  [[ -d config && ! -L config && -f config/runtime-files.txt && ! -L config/runtime-files.txt &&
     -s SHA256SUMS && -f SHA256SUMS && ! -L SHA256SUMS ]] || {
    printf 'Runtime requires regular allowlist and checksum files.\n' >&2; return 1;
  }
  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    case "$relative" in
      /*|.|..|./*|../*|*/./*|*/../*|*/.|*/..|*//*|*/|SHA256SUMS|*[[:cntrl:]]*)
        printf 'Unsafe runtime allowlist entry: %s\n' "$relative" >&2; return 1 ;;
    esac
    [[ "$files" != *$'\n'"./$relative"$'\n'* ]] || {
      printf 'Duplicate runtime allowlist entry: %s\n' "$relative" >&2; return 1;
    }
    [[ -f "$relative" && ! -L "$relative" ]] || {
      printf 'Runtime entry must be a regular file: %s\n' "$relative" >&2; return 1;
    }
    files+=$'\n'"./$relative"$'\n'
    entries+=$'\n'"./$relative"
    parent="$relative"
    while [[ "$parent" == */* ]]; do
      parent="${parent%/*}"
      [[ -d "$parent" && ! -L "$parent" ]] || {
        printf 'Runtime parent must be a real directory: %s\n' "$parent" >&2; return 1;
      }
      entries+=$'\n'"./$parent"
    done
  done < config/runtime-files.txt
  [[ -n "$files" ]] || return 1
  expected="$(printf '%s\n' "$entries" | sort -u)" || return 1
  actual="$(find . -mindepth 1 -print | sort)" || return 1
  [[ "$actual" == "$expected" ]] || {
    printf 'Runtime inventory does not match the allowlist; reinstall the runtime.\n' >&2; return 1;
  }
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ $checksum_pattern ]] || {
      printf 'Malformed runtime checksum entry.\n' >&2; return 1;
    }
    relative="${BASH_REMATCH[1]}"
    [[ "$files" == *$'\n'"./$relative"$'\n'* ]] || {
      printf 'Checksum target is not allowlisted: %s\n' "$relative" >&2; return 1;
    }
    listed+="./$relative"$'\n'
  done < SHA256SUMS
  expected="$(printf '%s' "$files" | sed '/^$/d' | sort)" || return 1
  actual="$(printf '%s' "$listed" | sed '/^$/d' | sort)" || return 1
  [[ "$actual" == "$expected" ]] || {
    printf 'Runtime checksums must cover every allowlisted file exactly once.\n' >&2; return 1;
  }
  shasum -a 256 -c SHA256SUMS >/dev/null
)

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
