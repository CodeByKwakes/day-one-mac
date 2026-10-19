#!/usr/bin/env bash
set -euo pipefail
exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/src/modules/vscode-profiles/operations.sh" "$@"
