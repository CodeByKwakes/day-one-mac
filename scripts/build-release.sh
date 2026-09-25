#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-$PROJECT_ROOT/dist}"
VERSION="$(sed -n '1p' "$PROJECT_ROOT/VERSION")"
[[ -n "$VERSION" ]] || { printf 'VERSION is empty.\n' >&2; exit 1; }

temporary="$(mktemp -d "${TMPDIR:-/tmp}/day-one-mac-release.XXXXXX")"
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
mkdir -p "$temporary/day-one-mac" "$OUTPUT_DIR"

# Copy the runtime without Git metadata, build output, or contributor-only
# dependencies. Excluding node_modules during the copy keeps local release
# builds fast and prevents development packages from entering public assets.
rsync -a \
  --exclude '/.git/' \
  --exclude '/.github/' \
  --exclude '/dist/' \
  --exclude '/node_modules/' \
  "$PROJECT_ROOT/" "$temporary/day-one-mac/"

(
  cd "$temporary/day-one-mac"
  find . -type f ! -name SHA256SUMS -print | LC_ALL=C sort \
    | while IFS= read -r file; do shasum -a 256 "$file"; done \
    > SHA256SUMS
)
(cd "$temporary/day-one-mac" && shasum -a 256 -c SHA256SUMS >/dev/null)
tar -czf "$OUTPUT_DIR/day-one-mac-runtime.tar.gz" -C "$temporary" day-one-mac
(
  cd "$OUTPUT_DIR"
  shasum -a 256 day-one-mac-runtime.tar.gz \
    > day-one-mac-runtime.tar.gz.sha256
)
cp "$PROJECT_ROOT/install-day-one-mac" "$OUTPUT_DIR/install-day-one-mac"
chmod 700 "$OUTPUT_DIR/install-day-one-mac"

printf '✓ Built Day One Mac %s release assets in %s\n' "$VERSION" "$OUTPUT_DIR"
