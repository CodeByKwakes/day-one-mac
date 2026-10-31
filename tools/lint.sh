#!/usr/bin/env bash
# Lint every shell script in this project with ShellCheck.
# Read-only: it never changes the Mac or the project.
set -euo pipefail

DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$DAY_ONE_ROOT"

usage() {
  printf '%s\n' \
    'Usage: ./tools/lint.sh [--severity LEVEL] [--format FORMAT]' \
    '' \
    '  --severity  error, warning, info or style (default: style, the strictest)' \
    '  --format    tty, gcc, json or checkstyle (default: tty)' \
    '' \
    'Configuration lives in .shellcheckrc at the project root. Document verified' \
    'false positives with narrowly scoped inline suppressions.'
}

severity='style'
format='tty'
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --severity) [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }; severity="$2"; shift 2 ;;
    --format)   [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }; format="$2"; shift 2 ;;
    --help|-h)  usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

if ! command -v shellcheck >/dev/null 2>&1; then
  printf 'shellcheck was not found on PATH.\n' >&2
  printf "Install it with 'brew install shellcheck', then rerun this script.\n" >&2
  exit 1
fi

# Collect scripts deterministically, skipping Git metadata and third-party
# dependencies. Optional repo-local gstack has its own upstream conventions;
# skills-lock.json records its source. Other local skills remain in scope.
scripts=()
while IFS= read -r -d '' script; do
  scripts+=("$script")
done < <(find "$PROJECT_DIR" \
  \( -name '.git' -o -name 'node_modules' -o -path '*/.husky/_' \
     -o -path "$PROJECT_DIR/.agents/skills/gstack" \) -prune \
  -o -type f -name '*.sh' -print0 | sort -z)

if [[ "${#scripts[@]}" -eq 0 ]]; then
  printf 'No shell scripts were found under %s\n' "$PROJECT_DIR" >&2
  exit 1
fi

printf 'Linting %s shell scripts with %s (severity: %s)\n\n' \
  "${#scripts[@]}" "$(shellcheck --version | awk '/^version:/ {print "ShellCheck " $2}')" "$severity"

# cd so ShellCheck picks up .shellcheckrc and resolves source-path entries.
cd "$PROJECT_DIR"
if shellcheck --severity="$severity" --format="$format" -- "${scripts[@]}"; then
  printf '\n✓ ShellCheck reported no findings in %s scripts.\n' "${#scripts[@]}"
  exit 0
fi

printf '\n✗ ShellCheck reported findings. Fix them, or — if a finding is genuinely\n' >&2
printf '  a false positive — add a narrowly scoped inline\n' >&2
printf '  "# shellcheck disable=SCxxxx" comment explaining why.\n' >&2
exit 1
