#!/usr/bin/env bash
# Compatibility entry point; implementation: tools/build-release.sh
set -euo pipefail
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tools/build-release.sh"
else
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tools/build-release.sh" "$@"
fi
