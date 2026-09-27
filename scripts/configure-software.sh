#!/usr/bin/env bash
# Selected software payloads only: no account, cleanup, Brewfile or sync changes.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/module-execution.sh"
source "$SCRIPT_DIR/lib/application-ownership.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
MODULE="" ACTION="" CLIENTS="" INPUT="" POLICY=check-only YES=0
SELECTION="" FORMULAE="" CASKS="" CASK_VERSIONS="" EXTENSIONS="" BREW_BIN=""
MISSING=0 CONFLICTS=0 NEED_BREW=0 NEED_CODE=0 NEED_APP=0 REPORT=""
MANIFEST="$STATE_DIR/install-manifest.tsv"
EXTENSION_LEDGER="$STATE_DIR/software-extension-installs.tsv"
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1

die() { printf '%s\n' "$1" >&2; exit "${2:-2}"; }
usage() {
  cat <<'EOF'
Usage: configure-software.sh --module 10|16 --plan|--apply|--check|--resume|--inventory
  --clients CSV       10: claude,codex,copilot-app,copilot-cli,copilot-vscode,raycast-ai
  --manifest PATH     16: reviewed two-column TSV: app ID, formula TOKEN, extension ID
  --app-install-policy prompt|homebrew|check-only
                      missing applications require an explicit ownership choice
  --yes               confirm this selection; does not choose application ownership

Omitted selections use saved state. Resume uses a saved snapshot, not the original
manifest. Inventory is Module 16 only and prints candidates, without saving them.
Extension operations target the Default VS Code profile. App Store purchases,
unrecognised casks, sign-in, settings, removals and authentication are not automated.
EOF
}
while (( $# )); do
  case "$1" in
    --module) [[ $# -ge 2 && -z "$MODULE" ]] || die '--module needs one ID'; MODULE="$2"; shift 2 ;;
    --plan|--apply|--check|--resume|--inventory)
      [[ -z "$ACTION" ]] || die 'choose one action'; ACTION="${1#--}"; shift ;;
    --clients) [[ $# -ge 2 && -n "$2" && -z "$CLIENTS" ]] || die '--clients needs one CSV'; CLIENTS="$2"; shift 2 ;;
    --manifest) [[ $# -ge 2 && -n "$2" && -z "$INPUT" ]] || die '--manifest needs one path'; INPUT="$2"; shift 2 ;;
    --app-install-policy) [[ $# -ge 2 ]] || die '--app-install-policy needs a value'; POLICY="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown software option: $1" ;;
  esac
done
[[ "$MODULE" == 10 || "$MODULE" == 16 ]] || die 'software module must be 10 or 16'
[[ -n "$ACTION" ]] || die 'choose an action'
[[ "$POLICY" == prompt || "$POLICY" == homebrew || "$POLICY" == check-only ]] || die 'invalid application policy'
[[ "$MODULE" != 10 || -z "$INPUT" ]] || die 'Module 10 accepts --clients, not --manifest'
[[ "$MODULE" != 16 || -z "$CLIENTS" ]] || die 'Module 16 accepts --manifest, not --clients'
[[ "$ACTION" != resume || -z "$CLIENTS$INPUT" ]] || die '--resume cannot change the saved selection'
[[ "$ACTION" != inventory || ( "$MODULE" == 16 && -z "$INPUT" && "$YES" == 0 ) ]] || die '--inventory accepts no selection or confirmation'
[[ "$YES" == 0 || "$ACTION" == apply || "$ACTION" == resume ]] || die '--yes is only for apply/resume'
if [[ "$ACTION" == apply || "$ACTION" == resume ]]; then
  day_one_serialize software "$0" "${ORIGINAL_ARGS[@]}"
  [[ -s "$STATE_DIR/completed/08" ]] || die 'Required Phase 8 is not recorded complete; use --plan first.' 10
fi
SAVED="$STATE_DIR/software-$MODULE.tsv"
CLIENT_FILE="$STATE_DIR/software-10-clients"
PAYLOAD_REPORT="$STATE_DIR/software-$MODULE-report.tsv"

add_row() {
  local row="$1"$'\t'"$2"
  grep -Fqx "$row" <<< "$SELECTION" || SELECTION="${SELECTION:+$SELECTION$'\n'}$row"
}

load_selection() {
  local client kind token extra row old_ifs
  if [[ "$MODULE" == 10 ]]; then
    if [[ -z "$CLIENTS" ]]; then
      if [[ -s "$CLIENT_FILE" ]]; then CLIENTS="$(sed -n '1p' "$CLIENT_FILE")"
      elif [[ "$ACTION" != resume ]]; then CLIENTS="$(sed -n '1p' "$STATE_DIR/ai-clients" 2>/dev/null || true)"
      fi
    fi
    [[ -n "$CLIENTS" && "$CLIENTS" != ,* && "$CLIENTS" != *, && "$CLIENTS" != *,,* ]] || die 'Select at least one AI client with --clients.'
    old_ifs="$IFS"; IFS=,
    for client in $CLIENTS; do
      IFS="$old_ifs"
      case "$client" in
        claude) add_row app claude-code ;;
        codex) add_row app codex ;;
        copilot-app|copilot-cli) add_row app "$client" ;;
        copilot-vscode) add_row app visual-studio-code ;;
        raycast-ai) add_row app raycast ;;
        *) die "unknown AI client: $client" ;;
      esac
      IFS=,
    done
    IFS="$old_ifs"
  else
    [[ -n "$INPUT" ]] || INPUT="$SAVED"
    [[ -f "$INPUT" && -r "$INPUT" ]] || die "Cannot read selection: $INPUT"
    while IFS= read -r row || [[ -n "$row" ]]; do
      [[ -n "$row" && "$row" != \#* ]] || continue
      [[ "$row" == *$'\t'* && "$row" != *$'\r'* ]] || die 'Expected two tab-separated fields per selection row.'
      kind="${row%%$'\t'*}"; token="${row#*$'\t'}"
      [[ -n "$token" && "$token" != *$'\t'* ]] || die 'Expected exactly two nonempty fields.'
      case "$kind" in
        app) [[ "$token" =~ ^[a-z0-9][a-z0-9-]*$ ]] && day_one_app_load "$token" || die "unknown application ID: $token" ;;
        formula)
          [[ "$token" =~ ^[a-z0-9][a-z0-9@+._-]*(/[a-z0-9][a-z0-9._-]*/[a-z0-9][a-z0-9@+._-]*)?$ && "$token" != *..* ]] || die "invalid formula token: $token" ;;
        extension) [[ "$token" =~ ^[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9._-]*$ ]] || die "invalid lowercase extension ID: $token" ;;
        *) die "unsupported selection kind: $kind (use app, formula, extension)" ;;
      esac
      add_row "$kind" "$token"
    done < "$INPUT"
    [[ -n "$SELECTION" ]] || die 'Selection is empty; nothing will be installed.'
  fi
}

load_inventory() {
  FORMULAE=""; CASKS=""; CASK_VERSIONS=""; EXTENSIONS=""
  BREW_BIN="$(day_one_app_brew_bin || true)"
  if [[ -n "$BREW_BIN" ]]; then
    FORMULAE="$("$BREW_BIN" list --formula)" || die 'Homebrew formula inventory failed; refusing to guess.' 1
    CASKS="$("$BREW_BIN" list --cask)" || die 'Homebrew cask inventory failed; refusing to guess ownership.' 1
    CASK_VERSIONS="$("$BREW_BIN" list --cask --versions)" || die 'Homebrew cask versions could not be inspected.' 1
  fi
  if [[ "$ACTION" == inventory ]] || grep -q $'^extension\t' <<< "$SELECTION"; then
    if command -v code >/dev/null 2>&1; then
      EXTENSIONS="$(code --profile Default --list-extensions --show-versions)" || die 'VS Code Default profile inventory failed.' 1
    fi
  fi
}

# Reuse ownership detection with a checked inventory instead of treating a
# failed per-cask Homebrew query as evidence of an external installation.
day_one_app_brew_has_cask() {
  grep -Fxq "$1" <<< "$CASKS" || grep -Fxq "${1##*/}" <<< "$CASKS"
}
formula_present() { grep -Fxq "$1" <<< "$FORMULAE" || grep -Fxq "${1##*/}" <<< "$FORMULAE"; }
extension_present() { cut -d @ -f 1 <<< "$EXTENSIONS" | grep -Fixq "$1"; }

detect_app() {
  day_one_app_detect "$1" || die "unknown application: $1"
  if [[ "$DAY_ONE_APP_VERSION" == - && "$DAY_ONE_APP_SOURCE" == homebrew ]]; then
    DAY_ONE_APP_VERSION="$(awk -v token="${DAY_ONE_APP_CASK##*/}" '$1 == token {print $2; exit}' <<< "$CASK_VERSIONS")"
    DAY_ONE_APP_VERSION="${DAY_ONE_APP_VERSION:--}"
  fi
}

inspect_selection() {
  local kind token state version source line
  MISSING=0; CONFLICTS=0; NEED_BREW=0; NEED_CODE=0; NEED_APP=0
  REPORT=$'kind\ttoken\tpayload\tversion\towner'
  while IFS=$'\t' read -r kind token; do
    state=missing; version=-; source=-
    case "$kind" in
      app)
        detect_app "$token"
        state="$DAY_ONE_APP_STATUS"; version="$DAY_ONE_APP_VERSION"; source="$DAY_ONE_APP_SOURCE"
        if [[ "$state" == missing ]]; then NEED_APP=1; fi
        if [[ "$state" == review ]]; then printf '%s: %s\n' "$token" "$DAY_ONE_APP_REASON" >&2; fi ;;
      formula)
        if formula_present "$token"; then state=ready; source=homebrew; else NEED_BREW=1; fi ;;
      extension)
        if extension_present "$token"; then
          state=ready; source=vscode-default
          version="$(awk -F @ -v token="$token" 'tolower($1) == token {print $2; exit}' <<< "$EXTENSIONS")"
        elif ! command -v code >/dev/null 2>&1; then NEED_CODE=1; fi ;;
    esac
    [[ "$state" != missing ]] || MISSING=$((MISSING + 1))
    [[ "$state" != review ]] || CONFLICTS=$((CONFLICTS + 1))
    line="$(printf '%s\t%s\t%s\t%s\t%s' "$kind" "$token" "$state" "$(day_one_app_clean_field "$version")" "$source")"
    REPORT="$REPORT"$'\n'"$line"
  done <<< "$SELECTION"
  printf '%s\n' "$REPORT"
}

manual_steps() {
  if [[ "$MODULE" == 10 ]]; then
    printf 'Manual: sign in to selected clients, choose accounts/providers, review permissions and subscriptions.\n'
    printf 'Copilot in VS Code uses its account/UI flow; no historical Copilot extensions are installed.\n'
    printf 'Authentication, paid-plan access and AI readiness are NOT checked or marked complete.\n'
  else
    printf 'Manual: review Brewfile declarations, licences, App Store installs and profile/sync settings separately.\n'
    printf 'Brewfile, settings, accounts and unselected software are never rewritten or removed.\n'
  fi
}

print_inventory() {
  local token id matched cask
  printf '# Candidate selection, not an instruction to install everything.\n# Keep only reviewed rows. Format: kind<TAB>token. Extensions target Default.\n'
  [[ -n "$BREW_BIN" ]] || printf '# Homebrew unavailable: formula and cask inventory is unknown.\n'
  while IFS= read -r token; do [[ -z "$token" ]] || printf 'formula\t%s\n' "$token"; done <<< "$FORMULAE"
  while IFS= read -r id; do
    detect_app "$id"
    if [[ "$DAY_ONE_APP_STATUS" == ready ]]; then printf 'app\t%s\n' "$id"
    else printf '# available app\t%s (%s)\n' "$id" "$DAY_ONE_APP_STATUS"
    fi
  done < <(day_one_app_catalog_ids all)
  while IFS= read -r token; do
    [[ -z "$token" ]] || printf 'extension\t%s\n' "${token%@*}" | LC_ALL=C tr '[:upper:]' '[:lower:]'
  done <<< "$EXTENSIONS"
  while IFS= read -r cask; do
    [[ -n "$cask" ]] || continue
    matched="$(awk -F '\t' -v cask="$cask" '!/^#/ {n=split($5,a,"/"); if ($5 == cask || a[n] == cask) print $1}' "$DAY_ONE_APP_CATALOG")"
    [[ -n "$matched" ]] || printf '# unmanaged catalogue entry: cask %s; review manually, never auto-reinstall\n' "$cask"
  done <<< "$CASKS"
  command -v code >/dev/null 2>&1 || printf '# VS Code CLI unavailable: extension inventory is unknown.\n'
  printf '# App Store and applications outside the catalogue remain manual; no Brewfile was read or evaluated.\n'
}

record_owned() {
  local path="$1" kind="$2" token="$3" content=""
  [[ ! -r "$path" ]] || content="$(cat "$path")"
  grep -Fxq "$kind"$'\t'"$token" <<< "$content" && return 0
  day_one_write_state "$path" "${content:+$content$'\n'}$kind"$'\t'"$token"
}

install_formula() {
  local token="$1" before after dependency rc=0
  before="$("$BREW_BIN" list --formula)" || return 1
  if grep -Fxq "${token##*/}" <<< "$before" || grep -Fxq "$token" <<< "$before"; then return 0; fi
  day_one_module_event installing-formula "$token"
  "$BREW_BIN" install --formula "$token" || rc=$?
  after="$("$BREW_BIN" list --formula)" || return 1
  while IFS= read -r dependency; do
    [[ -n "$dependency" ]] || continue
    grep -Fxq "$dependency" <<< "$before" && continue
    if [[ "$dependency" == "$token" || "$dependency" == "${token##*/}" ]]; then
      record_owned "$MANIFEST" brew-formula "$token"
    else record_owned "$MANIFEST" brew-dependency "$dependency"
    fi
  done <<< "$after"
  day_one_module_event formula-exit "$token:$rc"
  return "$rc"
}

install_extension() {
  local token="$1" before after added rc=0
  before="$(code --profile Default --list-extensions --show-versions)" || return 1
  if cut -d @ -f 1 <<< "$before" | grep -Fixq "$token"; then return 0; fi
  day_one_module_event installing-extension "$token"
  code --profile Default --install-extension "$token" || rc=$?
  after="$(code --profile Default --list-extensions --show-versions)" || return 1
  while IFS= read -r added; do
    [[ -n "$added" ]] || continue
    added="${added%@*}"
    if ! cut -d @ -f 1 <<< "$before" | grep -Fixq "$added"; then
      record_owned "$EXTENSION_LEDGER" Default "$added"
    fi
  done <<< "$after"
  day_one_module_event extension-exit "$token:$rc"
  return "$rc"
}

if [[ "$ACTION" == inventory ]]; then load_inventory; print_inventory; exit 0; fi
load_selection
load_inventory
inspect_selection
manual_steps
[[ "$CONFLICTS" == 0 ]] || die 'Conflicting ownership/configuration needs review; nothing was installed.' 1
if [[ "$ACTION" == check ]]; then
  [[ "$MISSING" == 0 ]] || die 'Selected payloads are missing; this is not an authentication check.' 1
  printf 'Selected payloads verified. Manual guide/checklist completion is separate.\n'
  exit 0
fi
if [[ "$ACTION" == plan ]]; then
  printf 'Plan only. Would install missing rows; preserve ready rows. Application policy: %s.\n' "$POLICY"
  while IFS=$'\t' read -r kind token payload version owner; do
    [[ "$payload" == missing ]] || continue
    case "$kind" in
      app) printf 'Would request: applications --id %s --install-missing --app-install-policy %s\n' "$token" "$POLICY" ;;
      formula) printf 'Would run: brew install --formula %s\n' "$token" ;;
      extension) printf 'Would run: code --profile Default --install-extension %s\n' "$token" ;;
    esac
  done <<< "$REPORT"
  [[ "$NEED_APP" == 0 ]] || printf 'Missing apps require an explicit installation route; --yes does not choose Homebrew.\n'
  [[ "$NEED_CODE" == 0 ]] || printf 'Blocked on apply: install/enable the VS Code CLI before selecting extensions.\n'
  [[ "$NEED_BREW" == 0 || -n "$BREW_BIN" ]] || printf 'Blocked on apply: Homebrew is required for selected formulae.\n'
  [[ -s "$STATE_DIR/completed/08" ]] || printf 'Blocked on apply: complete required Phase 8.\n'
  exit 0
fi
[[ "$NEED_CODE" == 0 ]] || die 'VS Code CLI is required before applying extensions.' 10
[[ "$NEED_BREW" == 0 || -n "$BREW_BIN" ]] || die 'Homebrew is required for selected formulae.' 10
if [[ "$YES" == 0 ]]; then
  [[ -t 0 ]] || die 'Apply requires terminal confirmation or --yes.' 10
  printf 'Save this selection and install missing payloads? [y/N]: '
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || exit 10
fi
day_one_module_begin "$MODULE" "$SELECTION" "$SAVED" "$STATE_DIR/ai-clients" \
  "$CLIENT_FILE" "$MANIFEST" "$EXTENSION_LEDGER" "$PAYLOAD_REPORT" \
  "$STATE_DIR/application-provenance.tsv" "$STATE_DIR/application-provenance.md"
day_one_write_state "$SAVED" "$SELECTION"
if [[ "$MODULE" == 10 ]]; then
  day_one_write_state "$CLIENT_FILE" "$CLIENTS"
  day_one_write_state "$STATE_DIR/ai-clients" "$CLIENTS"
fi
day_one_write_state "$MODULE_RUN/verification-scope" 'Selected software payloads only; accounts, permissions, configuration and guide completion are not verified.'
manual_steps > "$MODULE_RUN/manual-steps.txt"
for selected_kind in app formula extension; do
  while IFS=$'\t' read -r kind token; do
    [[ "$kind" == "$selected_kind" ]] || continue
    case "$kind" in
      app)
        detect_app "$token"
        [[ "$DAY_ONE_APP_STATUS" != review ]] || die "$token ownership changed; review before resuming." 1
        if [[ "$DAY_ONE_APP_STATUS" == missing ]]; then
          day_one_module_event installing-app "$token"
          "$SCRIPT_DIR/application-status.sh" --id "$token" --install-missing --app-install-policy "$POLICY"
          day_one_module_event installed-app "$token"
        else day_one_module_event preserved-app "$token"
        fi ;;
      formula) install_formula "$token" ;;
      extension) install_extension "$token" ;;
    esac
  done <<< "$SELECTION"
done
load_inventory
inspect_selection
day_one_write_state "$PAYLOAD_REPORT" "$REPORT"
[[ "$MISSING" == 0 && "$CONFLICTS" == 0 ]] || die 'Payload verification failed; inspect the journal and resume.' 1
MODULE_VERIFIED=1
printf 'Selected payloads verified; no guide completion marker was written.\n'
manual_steps
