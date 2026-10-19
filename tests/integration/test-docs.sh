#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../src/core/review-node.sh"
day_one_review_node "$SCRIPT_DIR/test-docs.cjs"
