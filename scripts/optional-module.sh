#!/usr/bin/env bash
# Explicit module operations; saved choices are not completion evidence.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
MODULE="" ACTION="" SELECTION="" SELECTOR="" ASSUME_YES=0 LIST=0
APP_POLICY=""

usage() {
  cat <<'EOF'
Usage: day-one-mac optional --module ID --plan|--apply|--check|--resume [selection]
       day-one-mac optional --list

  --module ID        09 databases, 10 AI, 10A gateway, 11 MCP, 12 profiles, 13 CLI,
                     14 Warp, 16 software, 21 audit, 22 governance
  --plan             inspect and print changes; never apply or save state
  --apply            apply selected work after confirmation
  --check            read-only verification; nonzero if missing/unhealthy
  --resume           apply the last saved selection; cannot change selection
  --services CSV     Module 09 services; otherwise use saved database selection
  --packages CSV     Module 13 formulae; otherwise use saved CLI selection
  --clients CSV      Module 10 client IDs; otherwise use saved AI selection
  --manifest PATH    Module 10A, 11, 12, 16 or 22 TSV; otherwise saved selection
  --inventory        Module 16 candidate TSV to stdout; never saves or applies
  --app-install-policy MODE
                     Module 10/16: prompt, homebrew, or check-only (default)
  --yes              accept apply/resume confirmation, not platform permissions
  --list             list optional and advanced capabilities, not completion
  -h, --help         show help

Apply/resume requires completed Phase 8. Planning is allowed before completion.
Existing databases and cli-tools commands remain supported.
EOF
}
die() { printf '%s\n' "$1" >&2; exit 2; }
while (( $# )); do
  case "$1" in
    --module) [[ $# -ge 2 && -z "$MODULE" ]] || die '--module needs one ID'; MODULE="$2"; shift 2 ;;
    --plan|--apply|--check|--resume|--inventory)
      [[ -z "$ACTION" ]] || die 'choose exactly one action'
      ACTION="${1#--}"; shift ;;
    --services|--packages|--clients|--manifest)
      [[ $# -ge 2 && -z "$SELECTOR" && -n "$2" ]] || die 'choose one nonempty selection'
      SELECTOR="$1"; SELECTION="$2"; shift 2 ;;
    --app-install-policy)
      [[ $# -ge 2 && -z "$APP_POLICY" ]] || die '--app-install-policy needs one value'
      APP_POLICY="$2"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --list) LIST=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown module option: $1" ;;
  esac
done
if [[ "$LIST" == 1 ]]; then
  [[ -z "$MODULE$ACTION$SELECTOR$APP_POLICY" && "$ASSUME_YES" == 0 ]] || die '--list cannot be combined with a module action'
  printf 'ID\tLayer\tExecution\tPrerequisite\tModule\n'
  awk -F '\t' 'BEGIN {OFS="\t"} !/^#/ {print $1,$2,$3,$4,$5}' "$PROJECT_DIR/config/modules.tsv"
  exit 0
fi
[[ -n "$MODULE" && -n "$ACTION" ]] || { usage >&2; exit 2; }
row="$(awk -F '\t' -v id="$MODULE" '!/^#/ && $1 == id {print}' "$PROJECT_DIR/config/modules.tsv")"
[[ -n "$row" ]] || die "unknown module: $MODULE"
IFS=$'\t' read -r id layer mode prerequisite title guide <<< "$row"
if [[ "$mode" != executable ]]; then
  printf 'Module %s is guided, not an executable setup module.\nGuide: %s/%s\n' "$id" "$PROJECT_DIR" "$guide" >&2
  exit 2
fi
if [[ "$ACTION" == resume && -n "$SELECTOR" ]]; then die '--resume uses saved choices; use --apply to change them'; fi
if [[ "$ASSUME_YES" == 1 && "$ACTION" != apply && "$ACTION" != resume ]]; then die '--yes is only valid with --apply or --resume'; fi
[[ -z "$APP_POLICY" || "$MODULE" == 10 || "$MODULE" == 16 ]] || die 'application policy is only supported for 10 and 16'
[[ "$ACTION" != inventory || ( "$MODULE" == 16 && -z "$SELECTOR$APP_POLICY" ) ]] || die '--inventory is only supported for Module 16 without other selections'
if [[ "$MODULE" =~ ^(11|12|14|21|22)$ ]]; then
  [[ -z "$SELECTOR" || ( "$MODULE" =~ ^(11|12|22)$ && "$SELECTOR" == --manifest ) ]] || die 'Only Modules 11, 12 and 22 accept an artifact manifest'
  artifact_args=(--module "$MODULE" "--$ACTION")
  [[ -z "$SELECTION" ]] || artifact_args+=(--manifest "$SELECTION")
  [[ "$ASSUME_YES" == 0 ]] || artifact_args+=(--yes)
  exec /bin/bash "$SCRIPT_DIR/configure-artifacts.sh" "${artifact_args[@]}"
fi
if [[ "$MODULE" == 10A ]]; then
  [[ -z "$SELECTOR" || "$SELECTOR" == --manifest ]] || die 'Module 10A accepts --manifest'
  gateway_args=("--$ACTION")
  [[ -z "$SELECTION" ]] || gateway_args+=(--manifest "$SELECTION")
  [[ "$ASSUME_YES" == 0 ]] || gateway_args+=(--yes)
  exec /bin/bash "$SCRIPT_DIR/configure-omniroute.sh" "${gateway_args[@]}"
fi
case "$MODULE" in
  09)
    [[ -z "$SELECTOR" || "$SELECTOR" == --services ]] || die 'Module 09 accepts --services, not --packages'
    script="$SCRIPT_DIR/configure-databases.sh"; SELECTOR=--services ;;
  10)
    [[ -z "$SELECTOR" || "$SELECTOR" == --clients ]] || die 'Module 10 accepts --clients'
    script="$SCRIPT_DIR/configure-software.sh"; SELECTOR=--clients ;;
  13)
    [[ -z "$SELECTOR" || "$SELECTOR" == --packages ]] || die 'Module 13 accepts --packages, not --services'
    script="$SCRIPT_DIR/configure-cli-tools.sh"; SELECTOR=--packages ;;
  16)
    [[ -z "$SELECTOR" || "$SELECTOR" == --manifest ]] || die 'Module 16 accepts --manifest'
    script="$SCRIPT_DIR/configure-software.sh"; SELECTOR=--manifest ;;
esac
if [[ "$MODULE" == 10 || "$MODULE" == 16 ]]; then
  software_args=(--module "$MODULE" "--$ACTION")
  [[ -z "$SELECTION" ]] || software_args+=("$SELECTOR" "$SELECTION")
  [[ -z "$APP_POLICY" ]] || software_args+=(--app-install-policy "$APP_POLICY")
  [[ "$ASSUME_YES" == 0 ]] || software_args+=(--yes)
  exec /bin/bash "$script" "${software_args[@]}"
fi
if [[ "$ACTION" == apply || "$ACTION" == resume ]]; then
  [[ -s "$STATE_DIR/completed/$prerequisite" ]] || {
    printf 'Required Phase %s is not recorded complete; apply is blocked. Use --plan to preview.\n' "$prerequisite" >&2
    exit 10
  }
fi
# Underlying installers read saved selections after acquiring the apply lock.
args=()
if [[ -n "$SELECTION" ]]; then args+=("$SELECTOR" "$SELECTION"); else args+=(--saved); fi
case "$ACTION" in
  plan) args+=(--dry-run) ;;
  check) args+=(--check) ;;
  apply|resume) [[ "$ASSUME_YES" == 0 ]] || args+=(--yes) ;;
esac
exec /bin/bash "$script" "${args[@]}"
