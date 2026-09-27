#!/usr/bin/env bash
# Explicit scalar preferences only; no GUI restarts, security changes or restore.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/platform.sh"
source "$SCRIPT_DIR/lib/module-execution.sh"
source "$SCRIPT_DIR/lib/macos-preferences.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
SAVED="$STATE_DIR/preferences-19-selection.tsv"
RECORDS="$STATE_DIR/preferences-19/keys"
ACTION='' INPUT='' YES=0 SELECTION='' RESOLVED='' OBSERVED='' CONFLICTS=0
READ_TYPE='' READ_VALUE='' READ_B64='' OLD_TYPE='' OLD_B64='' RECORD_STATUS=''
die() { printf '%s\n' "$1" >&2; exit "${2:-1}"; }
usage() {
  cat <<'EOF'
Usage: configure-preferences.sh --plan|--apply|--check|--resume [--manifest PATH] [--yes]
Manifest rows: setting<TAB>ID, using scalar IDs from the existing macOS catalogue.
Screenshot location and manual GUI/security choices are excluded.
Plan/check write nothing. Apply/resume require Phase 8 and confirmation.
Typed originals and pending writes are saved before mutation. External changes
block retries; no automatic restore, GUI restart or security change is performed.
EOF
}
while (( $# )); do
  case "$1" in
    --plan|--apply|--check|--resume) [[ -z "$ACTION" ]] || die 'Choose one action.' 2; ACTION="${1#--}"; shift ;;
    --manifest) [[ $# -ge 2 && -z "$INPUT" && -n "$2" ]] || die 'Manifest needs one path.' 2; INPUT="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die 'Unknown preference option.' 2 ;;
  esac
done
[[ -n "$ACTION" ]] || die 'Choose one action.' 2
[[ "$ACTION" != resume || -z "$INPUT" ]] || die 'Resume uses saved choices.' 2
[[ "$YES" == 0 || "$ACTION" == apply || "$ACTION" == resume ]] || die '--yes is apply/resume only.' 2
if [[ "$ACTION" == apply || "$ACTION" == resume ]]; then
  day_one_serialize preferences "$0" "${ORIGINAL_ARGS[@]}"
  [[ -s "$STATE_DIR/completed/08" ]] || die 'Complete required Phase 8 first; planning is available.' 10
fi
safe_path() {
  local path="$1"
  while [[ "$path" != / && "$path" != . ]]; do
    [[ ! -L "$path" ]] || return 1
    path="$(dirname "$path")"
  done
}
safe_path "$STATE_DIR" && safe_path "$RECORDS" || die 'Unsafe preference state path.'
INPUT="${INPUT:-$SAVED}"
[[ -r "$INPUT" && -f "$INPUT" ]] && safe_path "$INPUT" || die 'Provide a reviewed preferences manifest.' 2
while IFS= read -r row || [[ -n "$row" ]]; do
  [[ -n "$row" && "$row" != \#* ]] || continue
  [[ "$row" == setting$'\t'* ]] || die 'Expected setting<TAB>ID.' 2
  id="${row#*$'\t'}"
  [[ "$id" != screenshot-location && "$id" =~ ^[a-z][a-z-]*$ ]] || die 'Only scalar preference IDs are supported.' 2
  specs="$(preference_spec "$id")" || die 'Unknown or manual preference ID.' 2
  ! grep -Fxq "$row" <<< "$SELECTION" || die 'Duplicate preference ID.' 2
  SELECTION="${SELECTION:+$SELECTION$'\n'}$row"
  RESOLVED="${RESOLVED:+$RESOLVED$'\n'}$specs"
done < "$INPUT"
[[ -n "$SELECTION" ]] || die 'Empty preference manifest.' 2
day_one_require_apple_silicon || exit 2
export LC_ALL=C
encode() {
  local encoded
  encoded="$(printf '%s' "$1" | base64 | tr -d '\n')" || return 1
  printf '%s' "${encoded:--}"
}
normalize() {
  local type="$1" value="$2"
  case "$type" in
    bool) case "$value" in 1|true) printf true ;; 0|false) printf false ;; *) return 1 ;; esac ;;
    int|integer) [[ "$value" =~ ^-?[0-9]+$ ]] || return 1; printf '%s' "$value" ;;
    float)
      [[ "$value" =~ ^-?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$ ]] || return 1
      awk -v number="$value" 'BEGIN {printf "%.17g", number}' ;;
    string) printf '%s' "$value" ;;
    *) return 1 ;;
  esac
}
read_preference() {
  local domain="$1" key="$2" exported xml value
  # Do not turn an unavailable domain/read failure into permission to overwrite.
  exported="$(defaults export "$domain" - 2>/dev/null)" || die "Cannot read preference domain $domain; open its owning application or inspect manually."
  xml="$(printf '%s' "$exported" | /usr/bin/plutil -convert xml1 -o - - 2>/dev/null)" || die 'Preference domain is not a readable property list.'
  awk '/^<plist / {getline; if ($0 ~ /^<dict(>|\/>)/) found=1} END {exit !found}' <<< "$xml" || die 'Preference domain must be a dictionary.'
  if ! READ_TYPE="$(printf '%s' "$xml" | /usr/bin/plutil -type "$key" - 2>/dev/null)"; then
    # Canonical XML spells our fixed ASCII key names literally. A present key
    # with a failed extraction is an error, not an absent scalar.
    ! grep -Fq "<key>$key</key>" <<< "$xml" || die 'Present preference key could not be inspected.'
    READ_TYPE=missing; READ_VALUE=''; READ_B64=-; return
  fi
  [[ "$READ_TYPE" =~ ^(bool|integer|float|string)$ ]] || die 'Refusing a non-scalar existing preference.'
  # Sentinel preserves trailing newlines in scalar strings for exact backups.
  value="$(printf '%s' "$xml" | /usr/bin/plutil -extract "$key" raw -expect "$READ_TYPE" -n -o - - || exit 1; printf '\001')" || die 'Cannot extract preference value.'
  value="${value%$'\001'}"
  if [[ "$READ_TYPE" == string ]]; then READ_VALUE="$value"
  else READ_VALUE="$(normalize "$READ_TYPE" "$value")" || die 'Invalid typed preference value.'; fi
  READ_B64="$(encode "$READ_VALUE")" || die 'Cannot encode preference value.'
}
record_path() { printf '%s/%s.%s.tsv' "$RECORDS" "$1" "$2"; }
read_record() {
  local file="$1" domain="$2" key="$3" type="$4" b64="$5" row_domain row_key new_type new_b64 extra decoded row
  RECORD_STATUS=absent; OLD_TYPE=''; OLD_B64=''
  [[ -e "$file" || -L "$file" ]] || return 0
  [[ -f "$file" && -r "$file" ]] && safe_path "$file" || die 'Unsafe preference record.'
  [[ "$(wc -l < "$file" | tr -d ' ')" == 1 ]] || die 'Invalid preference record length.'
  row="$(cat "$file")"
  [[ "$row" != $'\t'* && "$row" != *$'\t' && "$row" != *$'\t\t'* && "$row" != *$'\r'* ]] || die 'Malformed preference record fields.'
  IFS=$'\t' read -r row_domain row_key OLD_TYPE OLD_B64 new_type new_b64 RECORD_STATUS extra <<< "$row"
  [[ "$row_domain" == "$domain" && "$row_key" == "$key" && "$new_type" == "$type" && "$new_b64" == "$b64" && -z "$extra" ]] || die 'Preference record does not match the current catalogue.'
  [[ "$OLD_TYPE" =~ ^(missing|bool|integer|float|string)$ && ( "$OLD_B64" == - || "$OLD_B64" =~ ^[A-Za-z0-9+/]+={0,2}$ ) && "$RECORD_STATUS" =~ ^(pending|applied)$ ]] || die 'Invalid typed preference record.'
  [[ "$OLD_TYPE" != missing || "$OLD_B64" == - ]] || die 'Invalid missing-value record.'
  if [[ "$OLD_B64" != - ]]; then
    decoded="$(printf '%s' "$OLD_B64" | base64 -D 2>/dev/null || exit 1; printf '\001')" || die 'Invalid original-value encoding.'
    decoded="${decoded%$'\001'}"
    [[ "$(encode "$decoded")" == "$OLD_B64" ]] || die 'Original value encoding is not canonical.'
  else decoded=''; fi
  if [[ "$OLD_TYPE" != missing && "$OLD_TYPE" != string ]]; then
    normalize "$OLD_TYPE" "$decoded" >/dev/null || die 'Original value does not match its recorded type.'
  fi
}
write_record() {
  day_one_write_state "$file" "$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$domain" "$key" "$OLD_TYPE" "$OLD_B64" "$type" "$expected_b64" "$1")"
}
matches_expected() { [[ "$READ_TYPE" == "$type" && "$READ_B64" == "$expected_b64" ]]; }
matches_original() { [[ "$READ_TYPE" == "$OLD_TYPE" && "$READ_B64" == "$OLD_B64" ]]; }
targets=("$SAVED")
while IFS=$'\t' read -r domain key type expected; do
  [[ "$type" != int ]] || type=integer
  expected="$(normalize "$type" "$expected")" || die 'Invalid catalogue value.'
  expected_b64="$(encode "$expected")"
  file="$(record_path "$domain" "$key")"; targets+=("$file")
  read_record "$file" "$domain" "$key" "$type" "$expected_b64"
  read_preference "$domain" "$key"
  status=change
  if matches_expected; then status=matches
  elif [[ "$RECORD_STATUS" == applied ]] || { [[ "$RECORD_STATUS" == pending ]] && ! matches_original; }; then
    status=CONFLICT; CONFLICTS=1
  fi
  if [[ "$ACTION" == check && ( "$status" != matches || "$RECORD_STATUS" == absent ) ]]; then CONFLICTS=1; fi
  printf '%s %s/%s -> %s %s\n' "$status" "$domain" "$key" "$type" "$expected"
  OBSERVED="${OBSERVED:+$OBSERVED$'\n'}$(printf '%s\t%s\t%s\t%s' "$domain" "$key" "$READ_TYPE" "$READ_B64")"
done <<< "$RESOLVED"
printf 'Scope: selected scalar preferences only. GUI activation, permissions, security and certificates remain manual.\n'
printf 'Typed original records: %s\n' "$RECORDS"
[[ "$CONFLICTS" == 0 ]] || die 'Preference mismatch or external change detected; no writes performed. Review the typed records and current settings.'
if [[ "$ACTION" == plan ]]; then
  [[ -s "$STATE_DIR/completed/08" ]] || printf 'Blocked on apply: complete Phase 8.\n'
  exit 0
elif [[ "$ACTION" == check ]]; then exit 0
fi
if [[ "$YES" == 0 ]]; then
  [[ -t 0 ]] || die 'Apply needs terminal confirmation or --yes.' 10
  printf 'Save typed originals and apply only these scalar preferences? [y/N]: '
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || exit 10
fi
safe_path "$STATE_DIR/module-runs/19" || die 'Unsafe run directory.'
day_one_module_begin 19 "$SELECTION" "${targets[@]}"
day_one_write_state "$SAVED" "$SELECTION"
day_one_write_state "$MODULE_RUN/observed-before.tsv" "$OBSERVED"
# Prepare every selected key before the first preference write. Thus even a
# later, not-yet-attempted key retains its original across a partial run.
while IFS=$'\t' read -r domain key type expected; do
  [[ "$type" != int ]] || type=integer
  expected="$(normalize "$type" "$expected")"; expected_b64="$(encode "$expected")"
  file="$(record_path "$domain" "$key")"
  read_record "$file" "$domain" "$key" "$type" "$expected_b64"
  read_preference "$domain" "$key"
  if [[ "$RECORD_STATUS" == absent ]]; then
    original="$(awk -F '\t' -v domain="$domain" -v key="$key" '$1==domain && $2==key {print $3 "\t" $4}' <<< "$OBSERVED")"
    IFS=$'\t' read -r OLD_TYPE OLD_B64 <<< "$original"
    matches_original || die 'Preference changed after preview; pending work stopped without overwriting it.'
    write_record pending
    day_one_module_event prepared-preference "$domain/$key"
  elif ! matches_expected; then
    [[ "$RECORD_STATUS" == pending ]] && matches_original || die 'Preference changed during this run; stopped without overwriting it.'
  fi
done <<< "$RESOLVED"
while IFS=$'\t' read -r domain key type expected; do
  [[ "$type" != int ]] || type=integer
  expected="$(normalize "$type" "$expected")"; expected_b64="$(encode "$expected")"
  file="$(record_path "$domain" "$key")"
  read_record "$file" "$domain" "$key" "$type" "$expected_b64"
  [[ "$RECORD_STATUS" != absent ]] || die 'Prepared preference record disappeared; no new baseline accepted.'
  read_preference "$domain" "$key"
  if ! matches_expected; then
    [[ "$RECORD_STATUS" == pending ]] && matches_original || die 'Preference changed during this run; stopped without overwriting it.'
    day_one_module_event write-preference "$domain/$key"
    write_type="$type"; [[ "$write_type" != integer ]] || write_type=int
    defaults write "$domain" "$key" "-$write_type" "$expected" || die 'Preference write failed; originals and pending intent retained.'
    read_preference "$domain" "$key"
    matches_expected || die 'Preference verification failed; pending intent retained.'
  fi
  write_record applied
done <<< "$RESOLVED"
MODULE_VERIFIED=1
printf 'Selected preferences verified. No applications were restarted; reopen the relevant UI when ready.\n'
