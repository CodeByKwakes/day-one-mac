#!/usr/bin/env bash
# Historical source fixture remains readable; direct orchestration is retired.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/setup/setup.sh"
else
  set -euo pipefail
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/operations/retired-setup.sh" "$@"
fi
