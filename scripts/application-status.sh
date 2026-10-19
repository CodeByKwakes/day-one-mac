#!/usr/bin/env bash
# Compatibility entry point; implementation: src/operations/application-status.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/application-status.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/application-status.sh" "$@"
fi
