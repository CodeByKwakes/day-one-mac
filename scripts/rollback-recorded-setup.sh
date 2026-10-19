#!/usr/bin/env bash
# Compatibility entry point; implementation: src/operations/rollback-recorded-setup.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/rollback-recorded-setup.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/rollback-recorded-setup.sh" "$@"
fi
