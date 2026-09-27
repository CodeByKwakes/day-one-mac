#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/review-node.sh"
day_one_review_node "$SCRIPT_DIR/tests/test-review-and-restore.cjs"
