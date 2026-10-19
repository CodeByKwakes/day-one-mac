#!/usr/bin/env bash
# Supply an extracted previous source/runtime tree; no network or real HOME writes.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_SOURCE="${1:?Usage: test-runtime-upgrade.sh EXTRACTED_PREVIOUS_TREE}"
BASE_SOURCE="$(cd "$BASE_SOURCE" && pwd)"
TASK_TMP="$(mktemp -d /tmp/day-one-upgrade.XXXXXX)"
trap 'rm -rf "$TASK_TMP"' EXIT
export HOME="$TASK_TMP/home with spaces é" DAY_ONE_MAC_STATE_ROOT="$TASK_TMP/state"
export DAY_ONE_MAC_STATE_DIR="$DAY_ONE_MAC_STATE_ROOT"
unset DAY_ONE_MAC_RUNTIME_HOME DAY_ONE_MAC_PROJECT_ROOT DAY_ONE_MAC_ROOT || true
mkdir -p "$HOME" "$TASK_TMP/archive"
/bin/bash "$BASE_SOURCE/scripts/install-portable-command.sh" --source "$BASE_SOURCE" --version test-baseline --standalone > "$TASK_TMP/install-baseline.log"
# Produce genuine old-version fingerprints in an isolated fixture.
(
  source "$BASE_SOURCE/scripts/setup.sh"
  mkdir -p "$COMPLETED_DIR"
  TRACK=4 STACK=python PRESET=core PRIMARY_IDE=other AUTH_MODE=https
  DOTFILES_VERSIONING=none SHELL_CHOICE=apple PROMPT_CHOICE=none
  FOLDER_LAYOUT=none GHQ_CHOICE=no
  for phase in 01 02 03 04 05 06 07 08; do phase_fingerprint "$phase" > "$COMPLETED_DIR/$phase"; done
)
printf 'keep original ownership\n' > "$DAY_ONE_MAC_STATE_ROOT/ownership-fixture"
printf 'keep saved choice\n' > "$DAY_ONE_MAC_STATE_ROOT/choice-fixture"
cp -R "$DAY_ONE_MAC_STATE_ROOT/completed" "$TASK_TMP/completed-before"
cp "$HOME/.zprofile" "$TASK_TMP/zprofile-before"
cp "$HOME/.config/zsh/path.zsh" "$TASK_TMP/path-before"
# Build, extract and install the allowlisted candidate, not a linked checkout.
/bin/bash "$ROOT/tools/build-release.sh" "$TASK_TMP/archive" > "$TASK_TMP/build.log"
tar -xzf "$TASK_TMP/archive/day-one-mac-runtime.tar.gz" -C "$TASK_TMP"
candidate="$TASK_TMP/day-one-mac"
/bin/bash "$candidate/scripts/install-portable-command.sh" --source "$candidate" --version test-candidate --standalone > "$TASK_TMP/install-candidate.log"
portable="$HOME/.local/bin/day-one-mac"
"$portable" runtime-status > "$TASK_TMP/status"
grep -Fq 'Version:   test-candidate' "$TASK_TMP/status"
grep -Fq 'Integrity: verified' "$TASK_TMP/status"
"$portable" verify > "$TASK_TMP/verify"
"$portable" setup --status > "$TASK_TMP/setup-status"
grep -Fq 'changed — revalidate' "$TASK_TMP/setup-status"
"$portable" docs manual > "$TASK_TMP/docs-path"
grep -Fq '/docs/setup/manual/MANUAL-SETUP-GUIDE.md' "$TASK_TMP/docs-path"
[[ -f "$HOME/.local/share/day-one-mac/current/docs/how-to/databases/DATAGRIP.md" ]]
"$portable" vscode-profile full-stack --dry-run > "$TASK_TMP/profiles"
"$portable" folders --help > "$TASK_TMP/folders"
diff -r "$TASK_TMP/completed-before" "$DAY_ONE_MAC_STATE_ROOT/completed"
cmp "$TASK_TMP/zprofile-before" "$HOME/.zprofile"
cmp "$TASK_TMP/path-before" "$HOME/.config/zsh/path.zsh"
[[ "$(cat "$DAY_ONE_MAC_STATE_ROOT/ownership-fixture")" == 'keep original ownership' ]]
[[ "$(cat "$DAY_ONE_MAC_STATE_ROOT/choice-fixture")" == 'keep saved choice' ]]
"$portable" rollback-runtime --execute > "$TASK_TMP/rollback"
"$portable" runtime-status > "$TASK_TMP/status"
grep -Fq 'Version:   test-baseline' "$TASK_TMP/status"
grep -Fq 'Integrity: verified' "$TASK_TMP/status"
"$portable" verify > "$TASK_TMP/verify"
"$portable" docs manual > "$TASK_TMP/docs-path"
grep -Fq '/docs/20-reference/MANUAL-SETUP-GUIDE.md' "$TASK_TMP/docs-path"
diff -r "$TASK_TMP/completed-before" "$DAY_ONE_MAC_STATE_ROOT/completed"
printf 'PASS: previous layout → packaged candidate → rollback; state, ownership and shell files preserved.\n'
