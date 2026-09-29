#!/usr/bin/env bash
# Offline documentation only: no setup state, credentials, or user dotfiles.
set -euo pipefail
umask 077
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

usage() {
  printf '%s\n' \
    'Usage: day-one-mac docs [TOPIC] --browser' \
    '       day-one-mac docs export --format html|markdown --output NEW_DIRECTORY' \
    'HTML is an offline browser reader. Print the current guide to save a PDF.' \
    'Exports contain bundled project documents and examples, never setup state.'
}

regular_source() {
  local relative="$1" parent
  [[ "$relative" =~ ^[a-zA-Z0-9_./\ -]+$ ]] || return 1
  case "$relative" in /*|.|..|./*|../*|*/../*|*/./*|*//*) return 1 ;; esac
  [[ -f "$ROOT/$relative" && ! -L "$ROOT/$relative" ]] || return 1
  parent="${relative%/*}"
  while [[ "$parent" != "$relative" && "$parent" != . ]]; do
    [[ -d "$ROOT/$parent" && ! -L "$ROOT/$parent" ]] || return 1
    relative="$parent"; parent="${parent%/*}"
  done
}

main() {
  local action="${1:-}" format='' output='' target='docs/START-HERE.md'
  local relative parent destination version files='' browser_dir='' browser_url
  shift || true
  case "$action" in
    --browser)
      [[ $# == 1 ]] || { usage >&2; return 2; }
      target="$1"; shift; format=html ;;
    export)
      while (( $# )); do
        case "$1" in
          --format|--output)
            [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { usage >&2; return 2; }
            if [[ "$1" == --format ]]; then
              [[ -z "$format" ]] || return 2
              format="$2"
            else
              [[ -z "$output" ]] || return 2
              output="$2"
            fi
            shift 2 ;;
          --help|-h) usage; return 0 ;;
          *) printf 'Unknown export option: %s\n' "$1" >&2; return 2 ;;
        esac
      done
      [[ -n "$output" ]] || { usage >&2; return 2; } ;;
    --help|-h) usage; return 0 ;;
    *) usage >&2; return 2 ;;
  esac
  case "$format" in html|markdown) ;; *) usage >&2; return 2 ;; esac

  # Validate the complete selection before creating the destination. Do not
  # discover files recursively: an untracked/private document is not a release.
  regular_source config/runtime-files.txt || return 1
  while IFS= read -r relative || [[ -n "$relative" ]]; do
    case "$relative" in
      docs/*|second-brain/*|warp-drive/*|README.md|CONTRIBUTING.md|CHANGELOG.md|SECURITY.md|LICENSE|VERSION)
        regular_source "$relative" || {
          printf 'Unsafe or missing bundled document: %s\n' "$relative" >&2; return 1; }
        files+="$relative"$'\n' ;;
    esac
  done < "$ROOT/config/runtime-files.txt"
  [[ "$files" == *$'\n'"$target"$'\n'* ]] || {
    printf 'Documentation topic is not bundled: %s\n' "$target" >&2; return 1; }
  version="$(head -n 1 "$ROOT/VERSION")"
  [[ "$version" =~ ^[a-zA-Z0-9.+-]+$ ]] || return 1
  if [[ "$format" == html ]]; then
    for relative in scripts/lib/docs-browser.html scripts/lib/docs-browser.css scripts/lib/docs-browser.js \
      scripts/vendor/markdown-it/markdown-it.min.js scripts/vendor/markdown-it/LICENSE; do
      regular_source "$relative" || { printf 'Browser asset missing or unsafe: %s\n' "$relative" >&2; return 1; }
    done
  fi

  if [[ "$action" == --browser ]]; then
    command -v open >/dev/null 2>&1 || { printf 'The macOS open command is unavailable. Use docs export instead.\n' >&2; return 1; }
    browser_dir="$(mktemp -d "${TMPDIR:-/tmp}/day-one-mac-docs.XXXXXX")"
    output="$browser_dir/reader"
  fi
  # The parent must already exist. Resolve it, but never reuse an existing
  # destination (including dangling symlinks). mkdir is the atomic reservation.
  parent="$(dirname "$output")"; destination="$(basename "$output")"
  [[ "$destination" != . && "$destination" != .. && -d "$parent" ]] || {
    printf 'Choose a new directory inside an existing parent.\n' >&2; return 2; }
  parent="$(cd "$parent" && pwd -P)"
  output="$parent/$destination"
  case "$output" in
    "$ROOT"|"$ROOT"/*)
      if [[ -e "$ROOT/SHA256SUMS" ]]; then
        printf 'Keep exports outside the installed runtime so its verified inventory stays intact.\n' >&2
        return 2
      fi ;;
  esac
  if ! mkdir -m 700 "$output"; then
    printf 'Export requires a new directory; nothing was overwritten.\n' >&2; return 1
  fi
  while IFS= read -r relative; do
    [[ -n "$relative" ]] || continue
    mkdir -p "$output/$(dirname "$relative")"
    cp "$ROOT/$relative" "$output/$relative"
  done <<< "$files"

  if [[ "$format" == html ]]; then
    # Base64 avoids script/HTML injection from document contents. Everything
    # needed for reading is inline; file:// works without fetch or a server.
    {
      cat "$ROOT/scripts/lib/docs-browser.html"
      printf '<style>\n'; cat "$ROOT/scripts/lib/docs-browser.css"; printf '\n</style>\n'
      printf '<div id="bundle-version" hidden>%s</div>\n' "$version"
      while IFS= read -r relative; do
        [[ "$relative" == *.md ]] || continue
        printf '<script type="text/plain" class="document-data" data-path="%s">' "$relative"
        base64 < "$ROOT/$relative" | tr -d '\r\n'
        printf '</script>\n'
      done <<< "$files"
      printf '<script>\n'; cat "$ROOT/scripts/vendor/markdown-it/markdown-it.min.js"; printf '\n</script>\n'
      printf '<script>\n'; cat "$ROOT/scripts/lib/docs-browser.js"; printf '\n</script>\n</body></html>\n'
    } > "$output/index.html"
    cp "$ROOT/scripts/vendor/markdown-it/LICENSE" "$output/markdown-it-LICENSE.txt"
  fi
  printf 'Exported bundled Day One Mac %s documentation (%s): %s\n' "$version" "$format" "$output"
  if [[ "$action" == --browser ]]; then
    printf 'Temporary reader; no server is running. Keep a durable copy with docs export.\n'
    browser_url="$(printf '%s' "$output/index.html" | sed 's/%/%25/g; s/ /%20/g; s/#/%23/g; s/?/%3F/g')"
    open "file://$browser_url#$target"
  fi
}

main "$@"
