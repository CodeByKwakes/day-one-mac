#!/usr/bin/env bash
# Contributor checks only. No installed manager or live setup mutations.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
mode="${1:---all}"
[[ $# -le 1 ]] || { printf 'Usage: tools/validate.sh [--all|--static|--regressions]\n' >&2; exit 2; }
case "$mode" in --all|--static|--regressions) ;; *) exit 2 ;; esac
if [[ "$mode" == --all ]]; then pnpm run lint; fi
if [[ "$mode" != --regressions ]]; then
  node tools/check-project-layout.cjs
  node tools/sync-vscode-reference.cjs --check
  node tools/build-skills.cjs --check
  node tests/integration/test-no-runtime.cjs
  while IFS= read -r -d '' script; do bash -n "$script"; done < <(find tools helpers integrations extensions -type f -name '*.sh' -print0)
fi
if [[ "$mode" != --static ]]; then
  for test_file in tests/integration/test-*.cjs; do
    case "$test_file" in *test-skills-cli.cjs|*test-docs-reader.cjs) continue ;; esac
    node "$test_file"
  done
fi
printf 'Validation passed: %s\n' "$mode"
