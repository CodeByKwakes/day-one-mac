#!/usr/bin/env bash
# Reproduce review findings without changing the real workstation.
# Stub callbacks replace all phase application and evidence-writing actions.
# shellcheck disable=SC2329
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_TMP="$(mktemp -d /tmp/day-one-restructure-safety.XXXXXX)"
trap 'rm -rf "$TASK_TMP"' EXIT
cp -R "$ROOT/scripts" "$ROOT/src" "$ROOT/config" "$TASK_TMP/"
export HOME="$TASK_TMP/home" DAY_ONE_MAC_STATE_ROOT="$TASK_TMP/state"
mkdir -p "$HOME" "$TASK_TMP/.git"
source "$TASK_TMP/src/setup/setup.sh"
failures=0
fail() { printf 'FAIL: %s\n' "$*" >&2; failures=$((failures + 1)); }
TRACK=4 STACK=both GIT_NAME=Fixture GIT_EMAIL=fixture@example.com PRIMARY_IDE=keep
DOTFILES_VERSIONING=none SHELL_CHOICE=keep PROMPT_CHOICE=none AUTH_MODE=https
DRY_RUN=0
phase_02() { printf 'APPLIED\n' >> "$TASK_TMP/events"; }
ensure_state() { printf 'STATE\n' >> "$TASK_TMP/events"; }
day_one_write_state() { printf '%s\n' "$2" > "$1"; }
log_line() { printf '%s\n' "$*" >> "$TASK_TMP/events"; }
mkdir -p "$COMPLETED_DIR"
printf 'prior evidence\n' > "$COMPLETED_DIR/02"
cp "$COMPLETED_DIR/02" "$TASK_TMP/marker-before"
manifest="$TASK_TMP/config/catalogs/phase-dependencies.tsv"
cp "$manifest" "$TASK_TMP/manifest"
rm "$manifest"
if run_phase 02 > "$TASK_TMP/output" 2>&1; then fail 'missing manifest accepted by run_phase'; fi
trap 'rm -rf "$TASK_TMP"' EXIT
[[ ! -e "$TASK_TMP/events" ]] || fail 'phase or state mutation before dependency validation'
cmp -s "$COMPLETED_DIR/02" "$TASK_TMP/marker-before" || fail 'prior completion evidence replaced'
if mark_phase_done 02 >> "$TASK_TMP/output" 2>&1; then fail 'direct completion accepted missing fingerprint'; fi
cmp -s "$COMPLETED_DIR/02" "$TASK_TMP/marker-before" || fail 'direct completion replaced prior evidence'
if mark_installation_centre_done >> "$TASK_TMP/output" 2>&1; then fail 'installation centre accepted missing fingerprint'; fi
[[ ! -e "$COMPLETED_DIR/installation-centre" ]] || fail 'installation evidence written after fingerprint failure'
cp "$TASK_TMP/manifest" "$manifest"
# Every catalogue row and every phase implementation must be covered.
for invalid in malformed truncated duplicate unknown unsafe; do
  case "$invalid" in
    malformed) awk '$1 != "02"' "$TASK_TMP/manifest" > "$manifest"; printf '02 BROKEN src/setup/phases/02-foundation.sh\n' >> "$manifest" ;;
    truncated) printf '*\tsrc/core/project-paths.sh\n' > "$manifest" ;;
    duplicate) cat "$TASK_TMP/manifest" > "$manifest"; printf '02\tsrc/setup/phases/02-foundation.sh\n' >> "$manifest" ;;
    unknown) cat "$TASK_TMP/manifest" > "$manifest"; printf '99\tsrc/core/project-paths.sh\n' >> "$manifest" ;;
    unsafe) cat "$TASK_TMP/manifest" > "$manifest"; printf '02\tsrc/../src/core/project-paths.sh\n' >> "$manifest" ;;
  esac
  if phase_fingerprint 02 >/dev/null 2>&1; then fail "$invalid dependencies accepted"; fi
done
cp "$TASK_TMP/manifest" "$manifest"
# A missing application catalogue must not be hidden by hashing an empty stream.
application_catalog="$DAY_ONE_APP_CATALOG"
mv "$application_catalog" "$TASK_TMP/applications.tsv"
if phase_fingerprint 03 >/dev/null 2>&1; then fail 'missing application catalogue accepted by fingerprint'; fi
mv "$TASK_TMP/applications.tsv" "$application_catalog"
phase_02() { return 42; }
status=0
run_phase 02 >> "$TASK_TMP/output" 2>&1 || status=$?
trap 'rm -rf "$TASK_TMP"' EXIT
[[ "$status" == 42 ]] || fail 'phase failure lost before completion'
cmp -s "$COMPLETED_DIR/02" "$TASK_TMP/marker-before" || fail 'failed phase replaced prior evidence'
# Public and compatibility folders commands resolve outside the checkout.
for command in "$ROOT/scripts/day-one-mac" "$ROOT/scripts/configure-folders.sh"; do
  args=(--help)
  [[ "$command" != */day-one-mac ]] || args=(folders --help)
  if ! (cd "$TASK_TMP" && /bin/bash "$command" "${args[@]}") > "$TASK_TMP/folders" 2>&1; then fail 'folders help cannot resolve its runner'; fi
done
# The setup centre must open the maintained guide, not a compatibility stub.
source "$ROOT/src/core/wizard-centre.sh"
DOC_DIR="$ROOT/docs"
menu_count=0
select_one() {
  if [[ "$menu_count" == 0 ]]; then SINGLE_RESULT="${SINGLE_VALUES[1]}"; else SINGLE_RESULT=back; fi
  menu_count=$((menu_count + 1))
}
centre_guide() { printf '%s\n' "$1" > "$TASK_TMP/selected-guide"; }
centre_docs
[[ "$(cat "$TASK_TMP/selected-guide")" == "$ROOT/docs/shared/explanation/process-overview.md" ]] || fail 'setup centre opens a legacy guide stub'
printf '\nif then\n' >> "$TASK_TMP/src/setup/phases/03-security.sh"
if /bin/bash "$TASK_TMP/src/operations/verify.sh" > "$TASK_TMP/verification" 2>&1; then fail 'verification ignores invalid relocated phase syntax'; fi
[[ "$failures" == 0 ]] || exit 1
printf 'PASS: dependency validation precedes mutation, completion fails closed, folders resolve and runtime syntax is checked.\n'
