#!/usr/bin/env bash
# Compatibility entry point; implementation: src/modules/with-operation-lock.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/modules/with-operation-lock.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/modules/with-operation-lock.sh" "$@"
fi
