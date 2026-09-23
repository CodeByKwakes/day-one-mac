#!/usr/bin/env bash
# Finalise a completed Day One Mac run without rolling back the environment.
# Preview-first and compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
COMPLETED_DIR="$STATE_DIR/completed"
PHASE_08_MARKER="$COMPLETED_DIR/08"
VERIFICATION_FILE="$STATE_DIR/verification.md"
DISPATCHER="$HOME/.local/bin/day-one-mac"
LEGACY_DISPATCHER="$HOME/.local/bin/fresh-start"
RUNTIME_HOME="${DAY_ONE_MAC_RUNTIME_HOME:-$HOME/.local/share/day-one-mac}"

EXECUTE=0
ASSUME_YES=0
DETACH=0
SHOW_STATUS=0
WARP_HANDLED=0
ARCHIVE_ROOT=""
STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
ARCHIVE_DIR=""

usage() {
  cat <<'EOF'
Usage: ./finalize-setup.sh [options]

Default behavior is a read-only compact-finalisation preview.

  --status             show Phase 8 and finalisation status
  --execute            create the reviewed evidence archive and compact logs
  --detach             archive all state and disable the portable command
  --warp-handled       confirm the Warp collection was removed or never imported
  --archive-root PATH  recovery parent; required outside state for custom detach
  --yes                accept the final confirmation (automation only)
  -h, --help           show this help

Normal finalisation keeps ~/.day-one-mac because the command, Warp workflows,
status, ownership checks, settings restore, and rollback evidence use it.
Detach mode moves the complete state into a recovery directory and disables
the portable command. It does not uninstall applications or undo settings.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) SHOW_STATUS=1 ;;
    --execute) EXECUTE=1 ;;
    --detach) DETACH=1 ;;
    --warp-handled) WARP_HANDLED=1 ;;
    --archive-root)
      shift
      [[ $# -gt 0 ]] || { err '--archive-root needs an absolute path'; exit 2; }
      ARCHIVE_ROOT="$1"
      ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

phase_08_recorded() {
  [[ -s "$PHASE_08_MARKER" ]]
}

verification_passed() {
  [[ -s "$VERIFICATION_FILE" ]] || return 1
  ! grep -Eq '\|[[:space:]]*(FAIL|REVIEW)([[:space:]]|—|\|)' "$VERIFICATION_FILE"
}

show_status() {
  ui_title '📦' 'Day One Mac finalisation status'
  if phase_08_recorded; then ok 'Phase 8 completion is recorded'; else warn 'Phase 8 completion is not recorded'; fi
  if verification_passed; then ok 'saved verification report has no failed or review gates'; else warn 'verification is missing or still needs review'; fi
  if [[ -r "$STATE_DIR/finalized-at" ]]; then
    printf '  Finalised: %s\n' "$(sed -n '1p' "$STATE_DIR/finalized-at")"
    printf '  Report: %s\n' "$STATE_DIR/finalization.md"
  else
    printf '  Finalised: not yet\n'
  fi
  printf '  State: %s\n' "$STATE_DIR"
}

[[ "$STATE_DIR" == /* && "$STATE_DIR" != / && "$STATE_DIR" != "$HOME" ]] \
  || { err "Unsafe state directory: $STATE_DIR"; exit 1; }
[[ "$STATE_DIR" == "$HOME"/* ]] \
  || { err "State directory must be a specific path below HOME: $STATE_DIR"; exit 1; }
[[ ! -L "$STATE_DIR" ]] \
  || { err "State directory must not be a symbolic link: $STATE_DIR"; exit 1; }

if [[ "$SHOW_STATUS" == 1 ]]; then
  show_status
  exit 0
fi

[[ -d "$STATE_DIR" ]] || { err "Day One Mac state does not exist: $STATE_DIR"; exit 1; }
STATE_DIR_PHYSICAL="$(cd "$STATE_DIR" && pwd -P)"
phase_08_recorded || {
  err 'Phase 8 is not recorded as complete. Finish or revalidate it before finalising.'
  exit 1
}
verification_passed || {
  err "The verification report is missing or contains FAIL/REVIEW gates: $VERIFICATION_FILE"
  exit 1
}
[[ -s "$STATE_DIR/install-manifest.tsv" && -s "$STATE_DIR/path-manifest.tsv" ]] || {
  err 'The install or path manifest is missing. Finalisation will not guess recovery ownership.'
  exit 1
}

if [[ -n "$ARCHIVE_ROOT" ]]; then
  [[ "$ARCHIVE_ROOT" == /* ]] || { err '--archive-root must be an absolute path'; exit 2; }
  [[ "$ARCHIVE_ROOT" != / ]] || { err '--archive-root cannot be the filesystem root'; exit 2; }
  [[ -d "$ARCHIVE_ROOT" ]] || { err "--archive-root must already exist and be mounted: $ARCHIVE_ROOT"; exit 2; }
  ARCHIVE_ROOT="$(cd "$ARCHIVE_ROOT" && pwd -P)"
elif [[ "$DETACH" == 1 ]]; then
  ARCHIVE_ROOT="$HOME"
else
  ARCHIVE_ROOT="$STATE_DIR/finalized"
fi

if [[ "$DETACH" == 1 ]]; then
  ARCHIVE_DIR="$ARCHIVE_ROOT/Day-One-Mac-Detached-$STAMP"
  [[ "$ARCHIVE_DIR" != "$STATE_DIR_PHYSICAL" && "$ARCHIVE_DIR" != "$STATE_DIR_PHYSICAL"/* ]] || {
    err 'A detached recovery archive must be outside ~/.day-one-mac.'
    exit 2
  }
  [[ "$ARCHIVE_DIR" != "$RUNTIME_HOME" && "$ARCHIVE_DIR" != "$RUNTIME_HOME"/* ]] || {
    err 'A detached recovery archive must be outside the installed runtime.'
    exit 2
  }
else
  ARCHIVE_DIR="$ARCHIVE_ROOT/Day-One-Mac-Finalization-$STAMP"
fi

ui_title '📦' 'Day One Mac finalisation plan'
printf '  Mode: %s\n' "$([[ "$DETACH" == 1 ]] && printf 'detach completely' || printf 'compact and retain operations')"
printf '  Action: %s\n' "$([[ "$EXECUTE" == 1 ]] && printf execute || printf preview)"
printf '  State: %s\n' "$STATE_DIR"
printf '  Evidence archive: %s\n\n' "$ARCHIVE_DIR"

printf 'Evidence snapshot\n'
printf '  • install and path manifests\n'
printf '  • originals captured before replacement\n'
printf '  • verification and application-ownership reports\n'
printf '  • setup selections and macOS settings recovery information\n'
printf '  • setup log before compaction\n'

if [[ "$DETACH" == 1 ]]; then
  printf '\nDetach actions\n'
  printf '  • move the complete state directory into the recovery archive\n'
  printf '  • move the portable day-one-mac command into the recovery archive\n'
  printf '  • move the standalone runtime into the recovery archive\n'
  printf '  • stop status, maintenance, restore, and Warp dispatcher workflows\n'
  printf '  • keep installed applications, packages, dotfiles, projects, and settings unchanged\n'
  printf '  • require the Warp Drive collection to be removed or confirmed absent\n'
else
  printf '\nRetained operational state\n'
  printf '  • project locator, selections, current phase fingerprints, and manifests\n'
  printf '  • originals, verification, ownership, and macOS restore records\n'
  printf '  • portable command and Warp workflow compatibility\n'
  printf '\nCompacted items\n'
  printf '  • archive then truncate setup.log\n'
  printf '  • move old completed-* progress directories into the evidence archive\n'
fi

[[ "$EXECUTE" == 1 ]] || {
  printf '\nPreview only. Rerun with --execute after reviewing this plan.\n'
  exit 0
}

if [[ "$DETACH" == 1 && "$WARP_HANDLED" != 1 ]]; then
  err 'Detach requires --warp-handled after removing the Day One Mac collection from Warp Drive, or confirming it was never imported.'
  exit 10
fi

if [[ "$ASSUME_YES" != 1 ]]; then
  [[ -t 0 ]] || { err 'Finalisation needs interactive input or --yes'; exit 10; }
  if [[ "$DETACH" == 1 ]]; then
    printf 'Type DETACH DAY ONE MAC to archive state and disable its command: '
    IFS= read -r answer
    [[ "$answer" == 'DETACH DAY ONE MAC' ]] || { err 'Confirmation did not match; nothing changed.'; exit 10; }
  else
    printf 'Create the final evidence archive and compact retained state? [y/N]: '
    IFS= read -r answer
    case "$answer" in y|Y|yes|YES|Yes) ;; *) warn 'Nothing changed.'; exit 10 ;; esac
  fi
fi

[[ ! -e "$ARCHIVE_DIR" ]] || { err "Archive already exists: $ARCHIVE_DIR"; exit 1; }
mkdir -p "$ARCHIVE_DIR"
chmod 700 "$ARCHIVE_DIR"

EVIDENCE_LIST="$ARCHIVE_DIR/evidence-files.txt"
: > "$EVIDENCE_LIST"
for relative in \
  install-manifest.tsv path-manifest.tsv originals verification.md \
  application-provenance.md application-provenance.tsv wizard-selections.md \
  track track-schema-version stack git-name git-email dotfiles-repo \
  dotfiles-versioning macos-settings-plan optional-modules ai-clients \
  database-services mcp-servers setup.log macos-settings finalized-at \
  finalization.md
do
  [[ -e "$STATE_DIR/$relative" || -L "$STATE_DIR/$relative" ]] \
    && printf '%s\n' "$relative" >> "$EVIDENCE_LIST"
done
chmod 600 "$EVIDENCE_LIST"
[[ -s "$EVIDENCE_LIST" ]] || { err 'No recovery evidence was found; refusing to continue.'; exit 1; }

tar -czf "$ARCHIVE_DIR/evidence.tar.gz" -C "$STATE_DIR" -T "$EVIDENCE_LIST"
chmod 600 "$ARCHIVE_DIR/evidence.tar.gz"
tar -tzf "$ARCHIVE_DIR/evidence.tar.gz" >/dev/null
(
  cd "$ARCHIVE_DIR"
  shasum -a 256 evidence.tar.gz > SHA256SUMS.txt
)
chmod 600 "$ARCHIVE_DIR/SHA256SUMS.txt"

if [[ "$DETACH" == 1 ]]; then
  if [[ -e "$DISPATCHER" || -L "$DISPATCHER" ]]; then
    mv "$DISPATCHER" "$ARCHIVE_DIR/day-one-mac-command"
  fi
  if [[ -f "$LEGACY_DISPATCHER" ]] && grep -Fq 'day-one-mac' "$LEGACY_DISPATCHER"; then
    mv "$LEGACY_DISPATCHER" "$ARCHIVE_DIR/fresh-start-compatibility-command"
  fi
  if [[ -d "$RUNTIME_HOME" && ! -L "$RUNTIME_HOME" ]]; then
    mv "$RUNTIME_HOME" "$ARCHIVE_DIR/day-one-mac-runtime"
  fi
  {
    printf '# Day One Mac detached\n\n'
    printf -- '- Detached: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- Original state: `%s`\n' "$STATE_DIR"
    printf -- '- Installed environment: preserved\n'
    printf -- '- Portable command: disabled and archived when present\n'
    printf -- '- Warp Drive: confirmed removed or never imported by the operator\n\n'
    printf 'The complete state is in `day-one-mac-state/`. Restore that directory to\n'
    printf '`%s` and restore the archived command and runtime only after reviewing them.\n' "$STATE_DIR"
    printf 'A future `chezmoi apply` may recreate the managed command; remove its source\n'
    printf 'entry deliberately if this detachment should be permanent.\n'
  } > "$ARCHIVE_DIR/DETACHED.md"
  chmod 600 "$ARCHIVE_DIR/DETACHED.md"
  mv "$STATE_DIR" "$ARCHIVE_DIR/day-one-mac-state"
  ok 'Day One Mac detached; installed environment was left unchanged'
  info "Recovery archive: $ARCHIVE_DIR"
  warn 'Keep the recovery archive until the Mac and dotfiles have been independently backed up and verified.'
  exit 0
fi

mkdir -p "$ARCHIVE_DIR/old-progress"
old_progress_count=0
for old_progress in "$STATE_DIR"/completed-*; do
  [[ -d "$old_progress" ]] || continue
  mv "$old_progress" "$ARCHIVE_DIR/old-progress/"
  old_progress_count=$((old_progress_count + 1))
done
[[ "$old_progress_count" -gt 0 ]] || rmdir "$ARCHIVE_DIR/old-progress"

if [[ -s "$STATE_DIR/setup.log" ]]; then
  cp -p "$STATE_DIR/setup.log" "$ARCHIVE_DIR/setup.log.before-finalize"
  chmod 600 "$ARCHIVE_DIR/setup.log.before-finalize"
fi
: > "$STATE_DIR/setup.log"
chmod 600 "$STATE_DIR/setup.log"
printf '%s\tFINALIZED evidence=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$ARCHIVE_DIR" > "$STATE_DIR/setup.log"

FINALIZED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf '%s\n' "$FINALIZED_AT" > "$STATE_DIR/finalized-at"
chmod 600 "$STATE_DIR/finalized-at"
{
  printf '# Day One Mac finalisation\n\n'
  printf -- '- Finalised: `%s`\n' "$FINALIZED_AT"
  printf -- '- Mode: compact; environment and operational state retained\n'
  printf -- '- Evidence archive: `%s`\n' "$ARCHIVE_DIR"
  printf -- '- Evidence checksum: `%s`\n\n' "$ARCHIVE_DIR/SHA256SUMS.txt"
  printf '## Retained\n\n'
  printf -- '- Phase fingerprints and setup selections\n'
  printf -- '- Install/path manifests and captured originals\n'
  printf -- '- Verification, application ownership, and settings-restore records\n'
  printf -- '- Project locator and portable command compatibility\n\n'
  printf '## Compacted\n\n'
  printf -- '- The previous setup log is archived and the active log restarted.\n'
  if [[ "$old_progress_count" == 1 ]]; then
    printf -- '- 1 old progress directory moved into the evidence archive.\n'
  else
    printf -- '- %s old progress directories moved into the evidence archive.\n' "$old_progress_count"
  fi
  printf '\nUse `day-one-mac finalize --status` to review this state.\n'
} > "$STATE_DIR/finalization.md"
chmod 600 "$STATE_DIR/finalization.md"

ok 'Day One Mac finalised; maintenance and rollback remain available'
info "Report: $STATE_DIR/finalization.md"
info "Evidence archive: $ARCHIVE_DIR"
