#!/usr/bin/env bash
# Clear Node preload and write-producing diagnostics before read-only inspection.
day_one_review_node() {
  command -v node >/dev/null 2>&1 || { printf 'Node 22+ is required on PATH; no runtime is installed automatically.\n' >&2; return 1; }
  env -u NODE_OPTIONS -u NODE_PATH -u NODE_V8_COVERAGE -u NODE_COMPILE_CACHE \
    -u NODE_REDIRECT_WARNINGS NODE_DISABLE_COMPILE_CACHE=1 node "$@"
}
