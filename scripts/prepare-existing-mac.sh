#!/usr/bin/env bash
# Compatibility entry point; implementation: src/preflight/prepare-existing-mac.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/preflight/prepare-existing-mac.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/preflight/prepare-existing-mac.sh" "$@"
fi
