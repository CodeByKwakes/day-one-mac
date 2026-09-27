#!/usr/bin/env bash
# Generate private review artifacts; never import, install, sync, upgrade or clean.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/module-execution.sh"
source "$SCRIPT_DIR/lib/audit-evidence.sh"
source "$SCRIPT_DIR/lib/ai-artifacts.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
MODULE="" ACTION="" INPUT="" YES=0 SELECTION="" PROFILE="" EXTENSIONS=""
CURRENT="" CURRENT_HASH="" ARTIFACT="" EVIDENCE="" DRIFT="" SOURCE_HASH=""
export NO_COLOR=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1

die() { printf '%s\n' "$1" >&2; exit "${2:-2}"; }
usage() {
  cat <<'EOF'
Usage: configure-artifacts.sh --module 11|12|14|21|22 --plan|--apply|--check|--resume
  --manifest PATH   Module 11 MCP, 12 profile or 22 governance TSV
  --yes             confirm artifact creation, never an import or installation

11 generates workspace MCP snippets, never activates clients or reads tokens.
12 generates a minimal .code-profile and reviewed extension list.
14 exports the bundled Warp directory. Both verify files, not application imports.
21 snapshots recorded setup evidence and selected executable-module checks.
22 snapshots explicitly selected skill trees and MCP metadata, never executes them.
Plan/check never save records or create temporary files. Apply/resume requires
Phase 8 and publishes a new private version; previous versions are preserved.
EOF
}
while (( $# )); do
  case "$1" in
    --module) [[ $# -ge 2 && -z "$MODULE" ]] || die '--module needs one ID'; MODULE="$2"; shift 2 ;;
    --plan|--apply|--check|--resume)
      [[ -z "$ACTION" ]] || die 'choose one action'; ACTION="${1#--}"; shift ;;
    --manifest) [[ $# -ge 2 && -n "$2" && -z "$INPUT" ]] || die '--manifest needs one path'; INPUT="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown artifact option: $1" ;;
  esac
done
[[ "$MODULE" =~ ^(11|12|14|21|22)$ && -n "$ACTION" ]] || die 'choose module 11, 12, 14, 21 or 22 and one action'
[[ "$MODULE" =~ ^(11|12|22)$ || -z "$INPUT" ]] || die '--manifest is only for Module 11, 12 or 22'
[[ "$ACTION" != resume || -z "$INPUT" ]] || die '--resume uses saved choices'
[[ "$YES" == 0 || "$ACTION" == apply || "$ACTION" == resume ]] || die '--yes is only for apply/resume'
SAVED="$STATE_DIR/artifact-$MODULE-selection.tsv"
POINTER="$STATE_DIR/artifact-$MODULE-current"
if [[ "$ACTION" == apply || "$ACTION" == resume ]]; then
  day_one_serialize artifacts "$0" "${ORIGINAL_ARGS[@]}"
  [[ -s "$STATE_DIR/completed/08" ]] || die 'Complete required Phase 8; --plan is available first.' 10
fi

# Do not follow a changed owned directory or a pointer out of the run namespace.
safe_path() {
  local path="$1"
  while [[ "$path" != / && "$path" != . ]]; do
    [[ ! -L "$path" ]] || return 1
    path="$(dirname "$path")"
  done
}
tree_hashes() {
  local root="$1" files file
  [[ -d "$root" ]] && safe_path "$root" || return 1
  files="$(find "$root" ! -type d ! -type f -print)" || return 1
  [[ -z "$files" ]] || return 1
  files="$(cd "$root" && find . -type f -print | LC_ALL=C sort)" || return 1
  [[ -n "$files" ]] || return 1
  while IFS= read -r file; do
    [[ "$file" != *$'\t'* && "$file" != *$'\r'* && -f "$root/$file" ]] || return 1
    (cd "$root" && shasum -a 256 "$file") || return 1
  done <<< "$files"
}
warp_hashes() {
  local path files
  # The runtime allowlist is authoritative; do not copy arbitrary added files.
  files="$(tree_hashes "$PROJECT_DIR/warp-drive/Day One Mac")" || return 1
  while IFS= read -r path; do
    [[ "$path" == 'warp-drive/Day One Mac/'* ]] || continue
    [[ -f "$PROJECT_DIR/$path" ]] && safe_path "$PROJECT_DIR/$path" || return 1
  done < "$PROJECT_DIR/config/runtime-files.txt"
  diff -u <(sed -n 's|^warp-drive/Day One Mac/|./|p' "$PROJECT_DIR/config/runtime-files.txt" | LC_ALL=C sort) \
    <(printf '%s\n' "$files" | sed 's/^[a-f0-9]*  //' | LC_ALL=C sort) >/dev/null || return 1
  printf '%s\n' "$files"
}
read_current() {
  local row run_id hash
  [[ -e "$POINTER" || -L "$POINTER" ]] || return 1
  safe_path "$POINTER" && [[ -f "$POINTER" ]] || die 'Unsafe artifact pointer; review it before continuing.' 1
  row="$(cat "$POINTER")"
  run_id="${row%%$'\t'*}"; hash="${row#*$'\t'}"
  [[ "$run_id" =~ ^[0-9]{8}T[0-9]{6}Z\.[A-Za-z0-9]+$ && "$hash" =~ ^[a-f0-9]{64}$ ]] || die 'Invalid artifact pointer.' 1
  CURRENT="$STATE_DIR/module-runs/$MODULE/$run_id/artifact"
  CURRENT_HASH="$hash"
  safe_path "$CURRENT" || die 'Unsafe artifact directory.' 1
}
verify_tree() {
  local hashes
  hashes="$(tree_hashes "$1")" || return 1
  [[ "$(printf '%s\n' "$hashes" | shasum -a 256 | awk '{print $1}')" == "$2" ]]
}
load_profile() {
  local row kind value
  [[ -n "$INPUT" ]] || INPUT="$SAVED"
  [[ -f "$INPUT" && -r "$INPUT" ]] || die 'Provide a reviewed Module 12 --manifest first.'
  while IFS= read -r row || [[ -n "$row" ]]; do
    [[ -n "$row" && "$row" != \#* ]] || continue
    [[ "$row" == *$'\t'* && "$row" != *$'\r'* ]] || die 'Expected two tab-separated fields.'
    kind="${row%%$'\t'*}"; value="${row#*$'\t'}"
    [[ -n "$value" && "$value" != *$'\t'* ]] || die 'Expected exactly two nonempty fields.'
    case "$kind" in
      profile)
        [[ -z "$PROFILE" && "${#value}" -le 64 && "$value" =~ ^[A-Za-z0-9][A-Za-z0-9\ ._-]*$ && "$value" != Default ]] || die 'Use one non-Default profile name (1–64 plain letters, digits, spaces, . _ -).'
        PROFILE="$value" ;;
      extension)
        [[ "$value" =~ ^[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9._-]*$ ]] || die 'Use lowercase publisher.name extension IDs, without versions or paths.'
        grep -Fxq "$value" <<< "$EXTENSIONS" || EXTENSIONS="${EXTENSIONS:+$EXTENSIONS$'\n'}$value" ;;
      *) die "Unsupported profile field: $kind" ;;
    esac
  done < "$INPUT"
  [[ -n "$PROFILE" ]] || die 'Manifest needs one profile row.'
  SELECTION="profile"$'\t'"$PROFILE"
  while IFS= read -r value; do
    [[ -z "$value" ]] || SELECTION="$SELECTION"$'\n'"extension"$'\t'"$value"
  done <<< "$EXTENSIONS"
}
profile_json() {
  local id extensions='[' separator=''
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    extensions="$extensions$separator{\"identifier\":{\"id\":\"$id\"}}"
    separator=,
  done <<< "$EXTENSIONS"
  extensions="$extensions]"
  # Inputs are restricted ASCII; the only inner JSON escapes needed are quotes.
  printf '{"name":"%s","extensions":"%s"}\n' "$PROFILE" "${extensions//\"/\\\"}"
}
manual_steps() {
  case "$MODULE" in
    11) printf '%s\n' 'Manual: review and merge snippets into the intended workspace client configuration. Do not overwrite existing configuration.' \
      'Codex entries are disabled. Tokens, OAuth, client activation and server trust approval remain manual. Integrity is not connectivity or trust.' ;;
    12) printf '%s\n' 'Manual: export your existing profile, review profile.code-profile, then import into a NEW profile in VS Code.' \
      'Import may download/run extensions. Review publisher trust and policy first. Accounts, settings and Settings Sync are not configured.' ;;
    14) printf '%s\n' 'Manual: open Warp, choose the intended workspace and import the exported Day One Mac directory.' \
      'Verify imported workflows in Warp; export integrity does not prove an import or cloud sync.' ;;
    21) printf '%s\n' 'Scope: recorded phase evidence, runtime entry points/integrity and saved executable selections only.' \
      'Phase record presence is not current machine health. Authentication, FileVault, Brewfile, repositories, upgrades, cleanup and rebuild remain separately reviewed.' ;;
    22) printf '%s\n' 'Scope: explicitly selected skill folders and Module 11 metadata manifests only; no live credential files.' \
      'Owner labels and hashes are inventory evidence, not signatures or trust certification. Review changes before accepting a new baseline.' ;;
  esac
}
compare_evidence() {
  local rc=0
  DRIFT='No previous snapshot.'
  if [[ -n "$CURRENT" ]]; then
    verify_tree "$CURRENT" "$CURRENT_HASH" || die 'Previous artifact failed integrity; preserve it and review before creating a replacement.' 1
    DRIFT="$(diff -u --label previous --label current "$CURRENT/evidence.tsv" <(printf '%s\n' "$EVIDENCE"))" || rc=$?
    [[ "$rc" -le 1 ]] || die 'Could not compare audit snapshots.' 1
    [[ -n "$DRIFT" ]] || DRIFT='No evidence drift.'
  fi
}

safe_path "$STATE_DIR" || die 'State directory must not traverse symlinks.' 1
case "$MODULE" in
  11) SELECTION="$(day_one_mcp_selection "${INPUT:-$SAVED}")" ;;
  22)
    SELECTION="$(day_one_governance_selection "${INPUT:-$SAVED}")"
    EVIDENCE="$(day_one_governance_evidence)" || die 'Governance evidence collection failed.' 1 ;;
  12) load_profile ;;
  14)
    hashes="$(warp_hashes)" || die 'Warp source inventory is unsafe or differs from the runtime allowlist.' 1
    SOURCE_HASH="$(printf '%s\n' "$hashes" | shasum -a 256 | awk '{print $1}')"
    SELECTION="warp-v1"$'\t'"$SOURCE_HASH"
    if [[ "$ACTION" == resume ]]; then
      [[ -f "$SAVED" && "$(cat "$SAVED")" == "$SELECTION" ]] || die 'Saved Warp source differs; review a new --plan and --apply instead of resuming.' 1
    fi ;;
  21)
    SELECTION=$'scope\taudit-evidence-v1'
    if [[ "$ACTION" == resume ]]; then
      [[ -f "$SAVED" && "$(cat "$SAVED")" == "$SELECTION" ]] || die 'No compatible audit selection to resume.' 1
    fi
    EVIDENCE="$(day_one_audit_evidence)" || die 'Evidence collection failed.' 1 ;;
esac
read_current || true
if [[ "$MODULE" == 21 || "$MODULE" == 22 ]]; then compare_evidence; fi
manual_steps
if [[ "$ACTION" == plan ]]; then
  printf 'Plan only: create a new private Module %s artifact under %s/module-runs/%s/.\n' "$MODULE" "$STATE_DIR" "$MODULE"
  printf 'Selection:\n%s\n' "$SELECTION"
  if [[ "$MODULE" == 12 ]]; then profile_json; fi
  if [[ "$MODULE" == 11 ]]; then
    for client in claude codex vscode; do
      if grep -q "^$client"$'\t' <<< "$SELECTION"; then printf '\n%s snippet:\n' "$client"; day_one_mcp_render "$client"; fi
    done
  fi
  if [[ "$MODULE" == 21 || "$MODULE" == 22 ]]; then printf '%s\n%s\n' "$EVIDENCE" "$DRIFT"; fi
  [[ -s "$STATE_DIR/completed/08" ]] || printf 'Blocked on apply: complete required Phase 8.\n'
  exit 0
fi
if [[ "$ACTION" == check ]]; then
  [[ -n "$CURRENT" ]] || die 'No published artifact; use --plan then --apply.' 1
  verify_tree "$CURRENT" "$CURRENT_HASH" || die 'Artifact integrity failed; no files changed.' 1
  [[ -f "$CURRENT/selection.tsv" && "$(cat "$CURRENT/selection.tsv")" == "$SELECTION" ]] || die 'Artifact does not match the current selection/source; review a new plan.' 1
  if [[ "$MODULE" == 12 ]]; then
    [[ "$(cat "$CURRENT/profile.code-profile")" == "$(profile_json)" ]] || die 'Profile content differs from its reviewed selection.' 1
  elif [[ "$MODULE" == 21 || "$MODULE" == 22 ]]; then
    printf '%s\n%s\n' "$EVIDENCE" "$DRIFT"
    if grep -q $'\tFAIL\t' <<< "$EVIDENCE" || [[ "$DRIFT" != 'No evidence drift.' ]]; then
      die 'Audit gate failure or evidence drift; review before accepting a new snapshot.' 1
    fi
  fi
  printf 'Artifact verified: %s\nNo manual checklist completion is implied.\n' "$CURRENT"
  exit 0
fi
if [[ "$YES" == 0 ]]; then
  [[ -t 0 ]] || die 'Apply requires terminal confirmation or --yes.' 10
  printf 'Save selection and create this private review artifact? [y/N]: '
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || exit 10
fi
safe_path "$STATE_DIR/module-runs/$MODULE" || die 'Unsafe run directory.' 1
day_one_module_begin "$MODULE" "$SELECTION" "$SAVED" "$POINTER"
day_one_write_state "$SAVED" "$SELECTION"
ARTIFACT="$MODULE_RUN/artifact"
mkdir "$ARTIFACT"
day_one_write_state "$ARTIFACT/selection.tsv" "$SELECTION"
cp "$PROJECT_DIR/VERSION" "$ARTIFACT/runtime-version"
manual_steps > "$ARTIFACT/manual-steps.txt"
day_one_module_event generating-artifact "$MODULE"
case "$MODULE" in
  11)
    for client in claude codex vscode; do
      if grep -q "^$client"$'\t' <<< "$SELECTION"; then
        suffix=json; [[ "$client" != codex ]] || suffix=toml
        day_one_mcp_render "$client" > "$ARTIFACT/$client-mcp.$suffix"
      fi
    done ;;
  12)
    profile_json > "$ARTIFACT/profile.code-profile"
    printf '%s\n' "$EXTENSIONS" > "$ARTIFACT/extensions.txt"
    [[ "$(cat "$ARTIFACT/profile.code-profile")" == "$(profile_json)" ]] || die 'Profile generation failed.' 1 ;;
  14)
    # This existing validator uses disposable scratch files, so it is apply-only.
    "$SCRIPT_DIR/validate-warp-drive.sh" > "$MODULE_RUN/source-validation.txt"
    mkdir "$ARTIFACT/Day One Mac"
    cp -R "$PROJECT_DIR/warp-drive/Day One Mac/." "$ARTIFACT/Day One Mac/"
    [[ "$(tree_hashes "$ARTIFACT/Day One Mac")" == "$hashes" ]] || die 'Warp source changed during export.' 1 ;;
  21|22)
    day_one_write_state "$ARTIFACT/evidence.tsv" "$EVIDENCE"
    {
      printf '# Module %s evidence\n\nGenerated: %s\n\n' "$MODULE" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
      printf '## Evidence\n\n```text\n%s\n```\n\n## Comparison with previous snapshot\n\n```diff\n%s\n```\n\n' "$EVIDENCE" "$DRIFT"
      manual_steps
    } > "$ARTIFACT/report.md" ;;
esac
hashes="$(tree_hashes "$ARTIFACT")" || die 'Generated artifact has unsafe entries.' 1
artifact_hash="$(printf '%s\n' "$hashes" | shasum -a 256 | awk '{print $1}')"
day_one_write_state "$MODULE_RUN/artifact.sha256" "$hashes"
verify_tree "$ARTIFACT" "$artifact_hash" || die 'Generated artifact failed verification.' 1
day_one_write_state "$POINTER" "${MODULE_RUN##*/}"$'\t'"$artifact_hash"
day_one_module_event published-artifact "$ARTIFACT"
printf 'Published artifact: %s\nPrevious versions retained. Imports and maintenance were not performed.\n' "$ARTIFACT"
if [[ "$MODULE" == 21 || "$MODULE" == 22 ]] && grep -q $'\tFAIL\t' <<< "$EVIDENCE"; then
  die 'Audit snapshot saved, but evidence gates failed. Review report.md; resume after resolving the failures.' 1
fi
MODULE_VERIFIED=1
