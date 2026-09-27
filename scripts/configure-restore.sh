#!/usr/bin/env bash
# Selected checksummed files into a fresh private staging area; never live restore.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/module-execution.sh"
source "$SCRIPT_DIR/lib/review-node.sh"
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
ORIGINAL_ARGS=("$@")
SAVED="$STATE_DIR/restore-20-selection.tsv"
POINTER="$STATE_DIR/restore-20-current"
ACTION='' INPUT='' YES=0
die() { printf '%s\n' "$1" >&2; exit "${2:-1}"; }
usage() {
  cat <<'EOF'
Usage: configure-restore.sh --plan|--apply|--check|--resume [--manifest PATH] [--yes]
Node 22+ is required. Manifest: source<TAB>/Volumes/Disk/backup, followed by
file<TAB>relative-source<TAB>relative-staging-target<TAB>sha256 rows.
Alternatively: mode<TAB>no-restore alone. No recursive or live restore.
Apply creates fresh private staging; resume fills missing files in the saved
session only. Changed sources or destinations block recovery, never overwrite.
Plan/check are read-only. Imports, credentials and live promotion remain manual.
EOF
}
while (( $# )); do
  case "$1" in
    --plan|--apply|--check|--resume) [[ -z "$ACTION" ]] || die 'Choose one action.' 2; ACTION="${1#--}"; shift ;;
    --manifest) [[ $# -ge 2 && -n "$2" && -z "$INPUT" ]] || die 'Manifest needs one path.' 2; INPUT="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die 'Unknown restore option.' 2 ;;
  esac
done
[[ -n "$ACTION" ]] || die 'Choose one action.' 2
[[ "$ACTION" != resume || -z "$INPUT" ]] || die 'Resume uses the saved selection.' 2
[[ "$YES" == 0 || "$ACTION" == apply || "$ACTION" == resume ]] || die '--yes is apply/resume only.' 2
safe_path() {
  local path="$1"
  [[ "$path" == /* && "$path" != *'/../'* && "$path" != *'/./'* && "$path" != */.. && "$path" != */. && "$path" != *//* ]] || return 1
  while [[ "$path" != / ]]; do
    [[ ! -L "$path" ]] || return 1
    path="$(dirname "$path")"
  done
}
safe_path "$STATE_DIR" && safe_path "$POINTER" && safe_path "$SAVED" && safe_path "$STATE_DIR/module-runs/20" || die 'Unsafe restore state path.'
if [[ "$ACTION" == apply || "$ACTION" == resume ]]; then
  day_one_serialize restore "$0" "${ORIGINAL_ARGS[@]}"
  [[ -s "$STATE_DIR/completed/08" ]] || die 'Complete required Phase 8 first; planning is available.' 10
fi
INPUT="${INPUT:-$SAVED}"
SELECTION="$(day_one_review_node "$SCRIPT_DIR/lib/restore-staging.cjs" selection "$INPUT")" || exit 2
PREVIEW=''
if [[ "$ACTION" == plan || "$ACTION" == apply ]]; then
  PREVIEW="$(day_one_review_node "$SCRIPT_DIR/lib/restore-staging.cjs" plan "$INPUT" "$STATE_DIR")" || exit 1
  printf '%s\n' "$PREVIEW"
  printf 'Fresh staging only: %s/module-runs/20/NEW-RUN/staging/files/\nNo live destination is touched; imports remain manual.\n' "$STATE_DIR"
fi
if [[ "$ACTION" == plan ]]; then
  [[ -s "$STATE_DIR/completed/08" ]] || printf 'Blocked on apply: complete Phase 8.\n'
  exit 0
fi
if [[ "$ACTION" == check || "$ACTION" == resume ]]; then
  [[ -f "$POINTER" && -f "$SAVED" ]] || die 'No saved restore session; plan and apply first.'
  [[ "$(cat "$SAVED")" == "$SELECTION" ]] || die 'Selection differs from saved restore choices.'
  row="$(cat "$POINTER")"; run_id="${row%%$'\t'*}"; intent_hash="${row#*$'\t'}"
  [[ "$run_id" =~ ^[0-9]{8}T[0-9]{6}Z\.[A-Za-z0-9]+$ && "$intent_hash" =~ ^[a-f0-9]{64}$ ]] || die 'Invalid restore pointer.'
  STAGING="$STATE_DIR/module-runs/20/$run_id/staging"
  safe_path "$STAGING" || die 'Unsafe staging path.'
fi
if [[ "$ACTION" == check ]]; then
  day_one_review_node "$SCRIPT_DIR/lib/restore-staging.cjs" check "$STAGING" "$intent_hash" "$INPUT"
  exit "$?"
fi
if [[ "$YES" == 0 ]]; then
  [[ -t 0 ]] || die 'Apply/resume requires terminal confirmation or --yes.' 10
  printf 'Save this selection and stage only its checked files? [y/N]: '
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || exit 10
fi
day_one_module_begin 20 "$SELECTION" "$SAVED" "$POINTER"
if [[ "$ACTION" == apply ]]; then
  STAGING="$MODULE_RUN/staging"
  intent_hash="$(printf '%s\n' "$PREVIEW" | day_one_review_node "$SCRIPT_DIR/lib/restore-staging.cjs" prepare "$STAGING" "$INPUT")"
  day_one_write_state "$SAVED" "$SELECTION"
  # Publish immutable intent before the first copy so an interrupted run resumes.
  day_one_write_state "$POINTER" "${MODULE_RUN##*/}"$'\t'"$intent_hash"
fi
day_one_module_event staging "$STAGING"
day_one_review_node "$SCRIPT_DIR/lib/restore-staging.cjs" stage "$STAGING" "$intent_hash" "$SAVED" 2>&1 | tee "$MODULE_RUN/restore-report.txt"
day_one_module_event verified-staging "$STAGING"
printf 'Manual: review staged data before live promotion or application/database import. Previous sessions and interrupted incoming files are retained.\n'
MODULE_VERIFIED=1
