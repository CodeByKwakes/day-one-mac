#!/usr/bin/env bash
# Retired entry point. Never interpret old flags as approval for new operations.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec /bin/bash "$ROOT/src/operations/retired-setup.sh" "$@"
