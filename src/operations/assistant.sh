#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/src/core/review-node.sh"
day_one_review_node "$ROOT/src/operations/assistant.cjs" "$@"
