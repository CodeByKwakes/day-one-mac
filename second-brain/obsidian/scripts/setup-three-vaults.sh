#!/usr/bin/env bash
# Former command name retained so existing notes and automation still work.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/setup-multi-vaults.sh" "$@"
