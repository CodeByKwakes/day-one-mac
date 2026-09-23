#!/usr/bin/env bash
# Fast, non-destructive regression checks for optional Stage 0.
set -euo pipefail

# A fixture must never block on an interactive prompt: the runner asks for
# input when stdin is a TTY, which hangs when this is run from a real terminal
# rather than CI. Detach stdin so every child takes the non-interactive path.
exec </dev/null

# The cleanup refuses to run inside Warp, because a real cleanup can uninstall
# the terminal it is running in. This fixture only ever acts on a sandboxed
# HOME, with brew off PATH so no cask can be uninstalled, and /Applications is
# only read for an inventory listing. Warp is a required app in this project,
# so Phase 8 is routinely run from it — clear the markers for the fixture.
# The guard itself is unchanged and still protects real runs.
unset TERM_PROGRAM WARP_IS_LOCAL_SHELL_SESSION

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-preflight-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
source "$SCRIPT_DIR/lib/apfs-volume.sh"

[[ "$(apfs_physical_store_from_plist "$SCRIPT_DIR/tests/fixtures/diskutil-info-apfs-physical-store.plist")" == disk7s2 ]]
[[ "$(apfs_physical_store_from_plist "$SCRIPT_DIR/tests/fixtures/diskutil-info-device-identifier.plist")" == disk8s2 ]]
UNICODE_TEST_FOLDER="$TEST_ROOT/Alex’s Backup Folder"
mkdir "$UNICODE_TEST_FOLDER"
[[ "$(mounted_device_for_path "$UNICODE_TEST_FOLDER")" == "$(mounted_device_for_path "$TEST_ROOT")" ]]

"$SCRIPT_DIR/preflight-audit.sh" --help | grep -Fq 'Stage 0 safety report'
"$SCRIPT_DIR/preflight-audit.sh" --help | grep -Fq 'Route A'
"$SCRIPT_DIR/preflight-audit.sh" --help | grep -Fq 'Route B'
"$SCRIPT_DIR/preflight-audit.sh" --help | grep -Fq -- '--check-time-machine-latest'
grep -Fq 'Review the completed safety report now?' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq 'Open SUMMARY.md in the default Mac app' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq 'Show SUMMARY.md here in Terminal' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '[[ "$GUIDED" == 1 && -t 0 && -t 1 ]] || return 0' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '## Findings that affect readiness' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '## Complete report index' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '[Repository review](repositories.md)' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '[Application review](applications.md)' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '[Collection status](collection-status.tsv)' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '[Checksums](SHA256SUMS.txt)' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '## Required backup and restore checklist' "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq '[[ "${#REPO_ROOTS[@]}" -gt 0 ]]' "$SCRIPT_DIR/preflight-audit.sh"
! grep -Fq '"${cleanup_args[@]}"' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq '${cleanup_args[@]+"${cleanup_args[@]}"}' "$SCRIPT_DIR/prepare-existing-mac.sh"
if grep -Eq "^[[:space:]]*printf[[:space:]]+['\"]-" "$SCRIPT_DIR/preflight-audit.sh"; then
  printf 'FAIL: preflight report contains printf format strings that begin with "-" without an option terminator\n' >&2
  exit 1
fi
"$SCRIPT_DIR/preflight-audit.sh" --plan > "$TEST_ROOT/audit-plan.txt"
grep -Fq 'does not read personal-document or configuration contents' "$TEST_ROOT/audit-plan.txt"
grep -Fq 'dirty worktrees and missing remotes' "$TEST_ROOT/audit-plan.txt"
grep -Fq 'inventory checklist, not a copy of your data' "$TEST_ROOT/audit-plan.txt"

"$SCRIPT_DIR/prepare-existing-mac.sh" --help > "$TEST_ROOT/prepare-help.txt"
grep -Fq 'Route A — erase the Mac' "$TEST_ROOT/prepare-help.txt"
grep -Fq 'Route B — keep this macOS user account' "$TEST_ROOT/prepare-help.txt"
grep -Fq -- '--safety-report' "$TEST_ROOT/prepare-help.txt"
grep -Fq 'an incomplete Step 5 on mounted backup drives' "$TEST_ROOT/prepare-help.txt"
grep -Fq -- '--status' "$TEST_ROOT/prepare-help.txt"
grep -Fq -- '--prepare-backup-folder' "$TEST_ROOT/prepare-help.txt"
grep -Fq -- '--backup-volume ABS_PATH' "$TEST_ROOT/prepare-help.txt"
grep -Fq -- '--preflight-report' "$TEST_ROOT/prepare-help.txt"
grep -Fq -- '--archive-docker-data' "$TEST_ROOT/prepare-help.txt"
grep -Fq -- '--archive-orbstack-data' "$TEST_ROOT/prepare-help.txt"
grep -Fq 'encrypted external APFS volume' "$TEST_ROOT/prepare-help.txt"
grep -Fq 'never erases or formats a disk' "$TEST_ROOT/prepare-help.txt"
grep -Fq "SINGLE_VALUES=(route_a route_b unsure exit)" "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Step 2 — verify the encrypted drive and copy the report' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Step 3 — copy the selected backup snapshot and test a restore' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Step 4 — preview exactly what cleanup would change' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Step 5 — apply the reviewed account-preserving cleanup' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Resume latest incomplete Step 5' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'load_cleanup_options_for_recovery' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'APFSContainerReference' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'APFSPhysicalStores.0.DeviceIdentifier' "$SCRIPT_DIR/lib/apfs-volume.sh"
grep -Fq 'APFSPhysicalStores.0.APFSPhysicalStore' "$SCRIPT_DIR/lib/apfs-volume.sh"
grep -Fq 'PhysicalStores.0.DeviceIdentifier' "$SCRIPT_DIR/lib/apfs-volume.sh"
grep -Fq 'DesignatedPhysicalStore' "$SCRIPT_DIR/lib/apfs-volume.sh"
grep -Fq 'mounted_device_for_path' "$SCRIPT_DIR/lib/apfs-volume.sh"
grep -Fq 'diskutil info -plist "$mounted_device"' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Could not identify the physical disk behind this APFS container' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq "! -name '.*'" "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq -- '--backup-only --in-progress-file' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq -- '--resume-snapshot' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'The wizard is closing now so it does not inspect paths that Step 5 may already have archived.' \
  "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq -- '--archive-rebuildable-caches' "$TEST_ROOT/prepare-help.txt"
grep -Fq 'existing-mac-backup-snapshot' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'existing-mac-restore-confirmed' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'existing-mac-cleanup-preview' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'existing-mac-last-result' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'existing-mac-report-autodiscovery-disabled' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Saved completion status' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Last result' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'backup_folder_status_reason' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Reset and re-run Step 1 — keeps old reports and backup files' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'reset-history/Step-1-' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Only progress markers were archived. Report and backup payloads were preserved.' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'adopt_existing_safety_report' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq "printf '%s Backup - %s" "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq "date '+%Y-%m-%d %H-%M'" "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'existing-mac-backup-folder' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq 'Safety Report - $(report_folder_stamp)' "$SCRIPT_DIR/prepare-existing-mac.sh"
grep -Fq "date '+%Y-%m-%d %H-%M-%S'" "$SCRIPT_DIR/preflight-audit.sh"
grep -Fq 'Safety Report - $STAMP' "$SCRIPT_DIR/preflight-audit.sh"
! grep -Fq "%Y%m%dT%H%M%SZ" "$SCRIPT_DIR/preflight-audit.sh" "$SCRIPT_DIR/prepare-existing-mac.sh"

# Exercise every saved gate without touching a real backup or cleanup target.
# The real copy-only operation and cleanup preview are covered by
# test-day-one-mac.sh; this block verifies that Stage 0 accepts current
# fingerprints and invalidates them whenever the selected scope changes.
PIPELINE_STATE="$TEST_ROOT/pipeline-state"
PIPELINE_BACKUP="$TEST_ROOT/External Backup/Alex’s Mac Backup"
PIPELINE_REPORT="$PIPELINE_BACKUP/Safety Report - 2026-09-13 19-06-00"
PIPELINE_SNAPSHOT="$PIPELINE_BACKUP/Day-One-Mac-Backup-Snapshot-test"
PIPELINE_CLEANUP="$PIPELINE_BACKUP/Day-One-Mac-Clean-Recovery-20260916T182209Z"
mkdir -p "$PIPELINE_STATE" "$PIPELINE_REPORT" "$PIPELINE_SNAPSHOT" "$PIPELINE_CLEANUP"
printf '# Safety report fixture\n' > "$PIPELINE_REPORT/SUMMARY.md"
(cd "$PIPELINE_REPORT" && shasum -a 256 SUMMARY.md > SHA256SUMS.txt)
printf '# Snapshot fixture\n' > "$PIPELINE_SNAPSHOT/README.md"
(cd "$PIPELINE_SNAPSHOT" && shasum -a 256 README.md > SHA256SUMS.txt)
snapshot_manifest_sha="$(shasum -a 256 "$PIPELINE_SNAPSHOT/SHA256SUMS.txt" | awk '{print $1}')"
printf 'manifest-sha256\t%s\nfiles\t1\n' "$snapshot_manifest_sha" > "$PIPELINE_SNAPSHOT/SNAPSHOT-COMPLETE"
printf '# Incomplete cleanup fixture\n' > "$PIPELINE_CLEANUP/INCOMPLETE.md"
printf 'cleanup fixture\n' > "$PIPELINE_CLEANUP/cleanup.log"
printf 'timestamp\taction\tsource\tdestination\tstatus\n' > "$PIPELINE_CLEANUP/operations.tsv"
: > "$PIPELINE_CLEANUP/homebrew-casks.txt"
printf 'archive-projects\t0\narchive-docker-data\t0\narchive-orbstack-data\t0\narchive-1password-data\t0\narchive-ssh-private-keys\t0\nprepare-keychain-reset\t0\nzap-cask-data\t0\n' \
  > "$PIPELINE_CLEANUP/cleanup-options.tsv"
printf '%s\n' route_b > "$PIPELINE_STATE/existing-mac-route"
printf '%s\n' "$PIPELINE_BACKUP" > "$PIPELINE_STATE/existing-mac-backup-folder"
printf '%s\n' "$PIPELINE_REPORT" > "$PIPELINE_STATE/existing-mac-safety-report"
cleanup_script_sha="$(shasum -a 256 "$SCRIPT_DIR/clean-development-state.sh" | awk '{print $1}')"
container_paths_sha="$(shasum -a 256 "$SCRIPT_DIR/lib/container-data-paths.sh" | awk '{print $1}')"
rebuildable_paths_sha="$(shasum -a 256 "$SCRIPT_DIR/lib/rebuildable-paths.sh" | awk '{print $1}')"
pipeline_scope="$({
  printf 'projects=0\ndocker=0\norbstack=0\nonepassword=0\nssh=0\nrebuildable-caches=0\nkeychain=0\nzap=0\n'
  printf 'cleanup-script=%s\n' "$cleanup_script_sha"
  printf 'container-paths=%s\n' "$container_paths_sha"
  printf 'rebuildable-paths=%s\n' "$rebuildable_paths_sha"
} | shasum -a 256 | awk '{print $1}')"
printf '%s\n%s\n' "$PIPELINE_SNAPSHOT" "$pipeline_scope" \
  > "$PIPELINE_STATE/existing-mac-backup-snapshot"
printf '%s|%s\n' "$PIPELINE_SNAPSHOT" "$pipeline_scope" \
  > "$PIPELINE_STATE/existing-mac-restore-confirmed"
pipeline_preview="$(printf '%s|%s|%s\n' "$PIPELINE_BACKUP" "$PIPELINE_REPORT" "$pipeline_scope" \
  | shasum -a 256 | awk '{print $1}')"
printf '%s\n' "$pipeline_preview" > "$PIPELINE_STATE/existing-mac-cleanup-preview"

DAY_ONE_MAC_STATE_ROOT="$PIPELINE_STATE" DAY_ONE_MAC_RECOVERY_SEARCH_ROOT="$PIPELINE_BACKUP" \
  "$SCRIPT_DIR/prepare-existing-mac.sh" --status \
  > "$TEST_ROOT/pipeline-current.txt"
grep -Fq 'Route B — keep this account' "$TEST_ROOT/pipeline-current.txt"
grep -Fq '✓ Step 1 — safety report' "$TEST_ROOT/pipeline-current.txt"
grep -Fq '✓ Step 2 — encrypted folder and verified report copy' "$TEST_ROOT/pipeline-current.txt"
grep -Fq '✓ Step 3a — copy-only snapshot' "$TEST_ROOT/pipeline-current.txt"
grep -Fq '✓ Step 3b — restored sample confirmed' "$TEST_ROOT/pipeline-current.txt"
grep -Fq '✓ Step 4 — cleanup preview' "$TEST_ROOT/pipeline-current.txt"
grep -Fq "Incomplete Step 5 recovery: $PIPELINE_CLEANUP" "$TEST_ROOT/pipeline-current.txt"

# An older interrupted cleanup may already have archived ~/.day-one-mac. The
# wizard must still discover the recovery directly from the mounted drive.
RECOVERY_ONLY_STATE="$TEST_ROOT/recovery-only-state"
mkdir -p "$RECOVERY_ONLY_STATE"
DAY_ONE_MAC_STATE_ROOT="$RECOVERY_ONLY_STATE" DAY_ONE_MAC_RECOVERY_SEARCH_ROOT="$PIPELINE_BACKUP" \
  "$SCRIPT_DIR/prepare-existing-mac.sh" --status > "$TEST_ROOT/recovery-only-status.txt"
grep -Fq 'No route saved yet' "$TEST_ROOT/recovery-only-status.txt"
grep -Fq "Incomplete Step 5 recovery: $PIPELINE_CLEANUP" "$TEST_ROOT/recovery-only-status.txt"

printf 'archive-projects\t1\n' > "$PIPELINE_STATE/existing-mac-cleanup-options.tsv"
DAY_ONE_MAC_STATE_ROOT="$PIPELINE_STATE" "$SCRIPT_DIR/prepare-existing-mac.sh" --status \
  > "$TEST_ROOT/pipeline-stale-scope.txt"
grep -Fq '✓ Step 2 — encrypted folder and verified report copy' "$TEST_ROOT/pipeline-stale-scope.txt"
grep -Fq '○ Step 3a — copy-only snapshot' "$TEST_ROOT/pipeline-stale-scope.txt"
grep -Fq '○ Step 3b — restored sample confirmed' "$TEST_ROOT/pipeline-stale-scope.txt"
grep -Fq '○ Step 4 — cleanup preview' "$TEST_ROOT/pipeline-stale-scope.txt"

# The old combined saved option remains readable. Both new choices are enabled
# so a partially completed flow from an older revision never omits data.
printf 'archive-container-data\t1\n' > "$PIPELINE_STATE/existing-mac-cleanup-options.tsv"
DAY_ONE_MAC_STATE_ROOT="$PIPELINE_STATE" "$SCRIPT_DIR/prepare-existing-mac.sh" --status \
  > "$TEST_ROOT/pipeline-legacy-container-scope.txt"
grep -Fq '[x] Docker Desktop local data' "$TEST_ROOT/pipeline-legacy-container-scope.txt"
grep -Fq '[x] OrbStack local data' "$TEST_ROOT/pipeline-legacy-container-scope.txt"

/bin/unlink "$PIPELINE_STATE/existing-mac-cleanup-options.tsv"
printf '%s\n' route_a > "$PIPELINE_STATE/existing-mac-route"
printf '%s|%s\n' "$PIPELINE_BACKUP" "$PIPELINE_REPORT" \
  > "$PIPELINE_STATE/existing-mac-route-a-backup-confirmed"
DAY_ONE_MAC_STATE_ROOT="$PIPELINE_STATE" "$SCRIPT_DIR/prepare-existing-mac.sh" --status \
  > "$TEST_ROOT/route-a-current.txt"
grep -Fq 'Route A — erase and start with a blank account' "$TEST_ROOT/route-a-current.txt"
grep -Fq '✓ Step 3 — complete backup and restored sample confirmed' "$TEST_ROOT/route-a-current.txt"

printf '%s\n' "$TEST_ROOT/missing-backup-folder" \
  > "$PIPELINE_STATE/existing-mac-backup-folder"
DAY_ONE_MAC_STATE_ROOT="$PIPELINE_STATE" "$SCRIPT_DIR/prepare-existing-mac.sh" --status \
  > "$TEST_ROOT/pipeline-missing-folder.txt"
grep -Fq '○ Step 2 — encrypted folder and verified report copy' "$TEST_ROOT/pipeline-missing-folder.txt"
grep -Fq 'The recorded backup folder is unavailable.' "$TEST_ROOT/pipeline-missing-folder.txt"

"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --safety-report --plan > "$TEST_ROOT/bootstrap-plan.txt"
grep -Fq 'Stage 0 Step 1 — safety report preview' "$TEST_ROOT/bootstrap-plan.txt"
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --preflight --plan > "$TEST_ROOT/bootstrap-compat-plan.txt"
grep -Fq 'Stage 0 Step 1 — safety report preview' "$TEST_ROOT/bootstrap-compat-plan.txt"

if "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --prepare-existing \
  > "$TEST_ROOT/prepare-needs-terminal.txt" 2>&1 </dev/null; then
  printf 'FAIL: friendly existing-Mac command did not open the guided route chooser\n' >&2
  exit 1
fi
grep -Fq -- '--guided requires an interactive terminal' "$TEST_ROOT/prepare-needs-terminal.txt"

if "$SCRIPT_DIR/prepare-existing-mac.sh" --apply \
  > "$TEST_ROOT/apply-refusal.txt" 2>&1 </dev/null; then
  printf 'FAIL: apply mode accepted a missing external recovery root\n' >&2
  exit 1
fi
grep -Fq -- '--apply requires an absolute --archive-root' "$TEST_ROOT/apply-refusal.txt"

! grep -Eq 'eraseDisk|diskutil[[:space:]]+erase|rm[[:space:]]+-rf|brew[[:space:]]+uninstall|docker[[:space:]]+(stop|rm)' \
  "$SCRIPT_DIR/preflight-audit.sh" "$SCRIPT_DIR/prepare-existing-mac.sh" "$SCRIPT_DIR/lib/apfs-volume.sh"

printf 'PASS: Stage 0 routes, APFS checks, resumable backup flow, preview and apply refusal\n'
