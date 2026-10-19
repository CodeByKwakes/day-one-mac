#!/usr/bin/env bash
set -euo pipefail
DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
source "$SCRIPT_DIR/../src/core/review-node.sh"
day_one_review_node "$SCRIPT_DIR/../tools/lib/release-readiness.cjs" "$@"
