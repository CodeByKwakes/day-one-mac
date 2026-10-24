#!/usr/bin/env bash
# The former guided completion runner is retired; explicit tools use optional-module.sh.
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/src/operations/retired-setup.sh" "$@"
