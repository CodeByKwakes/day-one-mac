#!/usr/bin/env bash
# Bounded app build entry point; no installation or application launch.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
exec node "$HERE/build.cjs" "$@"
