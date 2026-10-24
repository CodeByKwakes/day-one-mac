#!/usr/bin/env bash
# Compatibility fixture: the early scripted checkpoint is retired.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec node "$ROOT/tests/integration/test-ai-manual-contract.cjs"
