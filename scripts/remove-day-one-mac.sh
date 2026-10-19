#!/usr/bin/env bash
# Compatibility entry point; implementation: src/operations/remove-day-one-mac.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/remove-day-one-mac.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/remove-day-one-mac.sh" "$@"
fi
