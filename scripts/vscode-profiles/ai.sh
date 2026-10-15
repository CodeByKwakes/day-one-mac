#!/usr/bin/env bash
# Generate review files; pass --install-extensions for explicit CLI installation.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_DIR/build.cjs" ai "$@"
