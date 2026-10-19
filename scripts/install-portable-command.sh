#!/usr/bin/env bash
# Compatibility entry point; implementation: src/runtime/install-portable-command.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/runtime/install-portable-command.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/runtime/install-portable-command.sh" "$@"
fi
