#!/usr/bin/env bash
# Compatibility entry point; implementation: tools/release-readiness.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tools/release-readiness.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tools/release-readiness.sh" "$@"
fi
