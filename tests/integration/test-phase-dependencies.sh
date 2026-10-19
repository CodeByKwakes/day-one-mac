#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_TMP="$(mktemp -d /tmp/day-one-phase-dependencies.XXXXXX)"
trap 'rm -rf "$TASK_TMP"' EXIT
cp -R "$ROOT/scripts" "$ROOT/src" "$ROOT/config" "$TASK_TMP/"
export HOME="$TASK_TMP/home" DAY_ONE_MAC_STATE_ROOT="$TASK_TMP/state" DAY_ONE_MAC_DISABLE_BREW_DISCOVERY=1
mkdir -p "$HOME"
source "$TASK_TMP/src/setup/setup.sh"
TRACK=4 STACK=both GIT_NAME=Fixture GIT_EMAIL=fixture@example.com PRIMARY_IDE=keep
DOTFILES_VERSIONING=none SHELL_CHOICE=keep PROMPT_CHOICE=none AUTH_MODE=https
before="$(phase_fingerprint 02)"
printf '\n# Unrelated optional helper change\n' >> "$TASK_TMP/src/core/ai-artifacts.sh"
[[ "$(phase_fingerprint 02)" == "$before" ]] || { printf "Unrelated helper invalidated phase 02\n" >&2; exit 1; }
printf '\n# Required implementation change\n' >> "$TASK_TMP/src/setup/phases/02-foundation.sh"
[[ "$(phase_fingerprint 02)" != "$before" ]] || exit 1
printf '02\tmissing-file.sh\n' >> "$TASK_TMP/config/catalogs/phase-dependencies.tsv"
if phase_fingerprint 02 >/dev/null 2>&1; then printf 'Missing dependency incorrectly accepted\n' >&2; exit 1; fi
printf 'Phase dependency isolation and missing-file rejection passed.\n'
