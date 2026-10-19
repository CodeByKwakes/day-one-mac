#!/usr/bin/env bash
# Compatibility entry point; implementation: src/operations/workstation-readiness.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/workstation-readiness.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/workstation-readiness.sh" "$@"
fi
