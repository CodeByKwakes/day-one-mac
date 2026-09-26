#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/runtime-package.sh"
OUTPUT_DIR="${1:-$PROJECT_ROOT/dist}"
VERSION="$(sed -n '1p' "$PROJECT_ROOT/VERSION")"
[[ -n "$VERSION" ]] || { printf 'VERSION is empty.\n' >&2; exit 1; }

temporary="$(mktemp -d "${TMPDIR:-/tmp}/day-one-mac-release.XXXXXX")"
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
mkdir -p "$temporary/day-one-mac" "$OUTPUT_DIR"

day_one_copy_runtime "$PROJECT_ROOT" "$temporary/day-one-mac"
day_one_checksum_runtime "$temporary/day-one-mac"
tar -czf "$OUTPUT_DIR/day-one-mac-runtime.tar.gz" -C "$temporary" day-one-mac
(
  cd "$OUTPUT_DIR"
  shasum -a 256 day-one-mac-runtime.tar.gz \
    > day-one-mac-runtime.tar.gz.sha256
)
cp "$PROJECT_ROOT/install-day-one-mac" "$OUTPUT_DIR/install-day-one-mac"
chmod 700 "$OUTPUT_DIR/install-day-one-mac"

printf '✓ Built Day One Mac %s release assets in %s\n' "$VERSION" "$OUTPUT_DIR"
