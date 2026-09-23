#!/usr/bin/env bash
# Early, optional macOS preference wizard for Day One Mac.
# Security controls are reviewed manually; only selected user preferences are written.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/platform.sh"

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
SETTINGS_DIR="$STATE_DIR/macos-settings"
SELECTION_FILE="$STATE_DIR/macos-settings-selection"
STATUS_FILE="$STATE_DIR/macos-settings-status"
BACKUP_FILE="$SETTINGS_DIR/original-values.tsv"
REPORT_FILE="$SETTINGS_DIR/report.md"

MODE=wizard
ASSUME_YES=0
SELECTED=""
SECURITY_FIREWALL=""
SECURITY_FILEVAULT=""
SECURITY_GATEKEEPER=""

usage() {
  cat <<'EOF'
Usage: ./configure-macos-settings.sh [options]

  --wizard    choose settings with Space and apply after review (default)
  --preview   show selected changes without writing anything
  --apply     apply the saved selection after confirmation
  --status    show the saved selection, completion and report location
  --restore   restore values captured before the first change
  --yes       accept the apply or restore confirmation
  -h, --help  show this help

The tool never disables Gatekeeper, FileVault or the firewall. Original scalar
preference values, including floating-point values, are saved under
~/.day-one-mac/macos-settings before writes.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }

contains_csv() {
  case ",$1," in *",$2,"*) return 0 ;; *) return 1 ;; esac
}

clear_screen() {
  [[ -t 1 ]] && printf '\033[2J\033[H'
}

OPTIONS=(
  finder-hidden finder-extensions finder-path finder-status finder-list finder-sizes finder-home-sidebar
  dock-size dock-right dock-magnification-off dock-autohide dock-scale-effect
  dock-minimize-into-app dock-no-launch-animation dock-show-indicators dock-no-recents
  battery-percentage
  keyboard-fast autocorrect-off tap-to-click natural-scrolling-off
  screenshot-location
)
# Do not call this array GROUPS. Bash reserves GROUPS for the current user's
# numeric supplementary group IDs, so using that name renders values such as
# 20 and 12 and fails under `set -u` once those IDs run out.
OPTION_GROUPS=(
  Finder Finder Finder Finder Finder Finder Finder
  Dock Dock Dock Dock Dock Dock Dock Dock Dock
  'Menu bar'
  'Keyboard and trackpad' 'Keyboard and trackpad' 'Keyboard and trackpad' 'Keyboard and trackpad'
  Screenshots
)
LABELS=(
  'Show hidden files permanently'
  'Show all filename extensions (recommended)'
  'Show the Finder path bar (recommended)'
  'Show the Finder status bar (recommended)'
  'Use Finder list view by default'
  'Calculate all folder sizes — manual; may slow large folders'
  'Show your home folder in the Finder sidebar — manual'
  'Use a compact Dock size of 44 (recommended)'
  'Place the Dock on the right (recommended)'
  'Turn Dock magnification off for stable icon positions'
  'Automatically hide and show the Dock'
  'Use the faster Scale minimisation effect'
  'Minimise windows into their application icon'
  'Turn application-opening animation off'
  'Show indicators beneath open applications'
  'Hide suggested and recent applications from the Dock'
  'Show battery percentage — manual System Settings step'
  'Use fast key repeat and a short delay'
  'Turn automatic spelling correction off'
  'Enable tap to click — manual System Settings step'
  'Turn Natural scrolling off — manual System Settings step'
  'Store screenshots in ~/Pictures/Screenshots'
)
DEFAULTS=(0 1 1 1 0 0 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 1)
SELECTED_FLAGS=()

validate_option_catalog() {
  local option_count="${#OPTIONS[@]}"
  if [[ "${#OPTION_GROUPS[@]}" -ne "$option_count" \
     || "${#LABELS[@]}" -ne "$option_count" \
     || "${#DEFAULTS[@]}" -ne "$option_count" ]]; then
    err 'The macOS settings menu catalogue is inconsistent; no preference was changed.'
    return 2
  fi
}

option_label() {
  local wanted="$1" index
  for ((index=0; index<${#OPTIONS[@]}; index++)); do
    [[ "${OPTIONS[$index]}" == "$wanted" ]] && { printf '%s' "${LABELS[$index]}"; return 0; }
  done
  printf '%s' "$wanted"
}

load_selection_flags() {
  local index
  [[ -n "$SELECTED" ]] || SELECTED="$(sed -n '1p' "$SELECTION_FILE" 2>/dev/null || true)"
  SELECTED_FLAGS=()
  for ((index=0; index<${#OPTIONS[@]}; index++)); do
    if [[ "$SELECTED" == none ]]; then
      SELECTED_FLAGS[$index]=0
    elif [[ -n "$SELECTED" ]]; then
      contains_csv "$SELECTED" "${OPTIONS[$index]}" && SELECTED_FLAGS[$index]=1 || SELECTED_FLAGS[$index]=0
    else
      SELECTED_FLAGS[$index]="${DEFAULTS[$index]}"
    fi
  done
}

choose_settings() {
  local cursor=0 key rest index marker check last_group=""
  [[ -t 0 && -t 1 ]] || { err 'The settings wizard requires an interactive terminal. Use --preview or --apply for automation.'; return 2; }
  load_selection_flags
  while :; do
    clear_screen
    ui_banner '⚙️' 'Early macOS Settings Wizard'
    printf 'Choose optional preferences. Required security gates remain separate.\n\n'
    printf '  Up/Down or j/k: move   Space: toggle   a: all   n: none\n'
    printf '  Enter: review          q: return without changing settings\n'
    for ((index=0; index<${#OPTIONS[@]}; index++)); do
      if [[ "${OPTION_GROUPS[$index]}" != "$last_group" ]]; then
        printf '\n  %s\n' "${OPTION_GROUPS[$index]}"
        last_group="${OPTION_GROUPS[$index]}"
      fi
      marker=' '; check='[ ]'
      [[ "$index" == "$cursor" ]] && marker='>'
      [[ "${SELECTED_FLAGS[$index]}" == 1 ]] && check='[x]'
      if [[ "$index" == "$cursor" ]]; then
        printf ' %s%s%s %s %s%s\n' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN" "$marker" "$check" "${LABELS[$index]}" "$DAY_ONE_UI_RESET"
      else
        printf ' %s %s %s\n' "$marker" "$check" "${LABELS[$index]}"
      fi
    done
    last_group=""
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then IFS= read -rsn2 rest || true; key="$key$rest"; fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#OPTIONS[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#OPTIONS[@]}" ]] || cursor=0 ;;
      ' ') [[ "${SELECTED_FLAGS[$cursor]}" == 1 ]] && SELECTED_FLAGS[$cursor]=0 || SELECTED_FLAGS[$cursor]=1 ;;
      a|A) for ((index=0; index<${#OPTIONS[@]}; index++)); do SELECTED_FLAGS[$index]=1; done ;;
      n|N) for ((index=0; index<${#OPTIONS[@]}; index++)); do SELECTED_FLAGS[$index]=0; done ;;
      q|Q) clear_screen; return 10 ;;
      '') break ;;
    esac
  done
  SELECTED=""
  for ((index=0; index<${#OPTIONS[@]}; index++)); do
    [[ "${SELECTED_FLAGS[$index]}" == 1 ]] || continue
    SELECTED="${SELECTED}${SELECTED:+,}${OPTIONS[$index]}"
  done
  clear_screen
}

confirm() {
  local prompt="$1" answer
  [[ "$ASSUME_YES" == 1 ]] && return 0
  [[ -t 0 ]] || { err "$prompt needs terminal input or --yes"; return 1; }
  printf '%s [y/N]: ' "$prompt"
  IFS= read -r answer
  case "$answer" in y|Y|yes|YES|Yes) return 0 ;; *) return 1 ;; esac
}

confirm_manual() {
  local prompt="$1" answer
  [[ -t 0 ]] || { err "$prompt requires an interactive confirmation"; return 1; }
  printf '%s [y/N]: ' "$prompt"
  IFS= read -r answer
  case "$answer" in y|Y|yes|YES|Yes) return 0 ;; *) return 1 ;; esac
}

ensure_state() {
  mkdir -p "$SETTINGS_DIR"
  chmod 700 "$STATE_DIR" "$SETTINGS_DIR"
}

save_selection() {
  local tmp
  ensure_state
  tmp="$(mktemp "$STATE_DIR/.macos-settings-selection.XXXXXX")"
  printf '%s\n' "${SELECTED:-none}" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$SELECTION_FILE"
}

is_manual_option() {
  case "$1" in finder-sizes|finder-home-sidebar|battery-percentage|tap-to-click|natural-scrolling-off) return 0 ;; *) return 1 ;; esac
}

preference_spec() {
  case "$1" in
    finder-hidden) printf 'com.apple.finder\tAppleShowAllFiles\tbool\t1' ;;
    finder-extensions) printf 'NSGlobalDomain\tAppleShowAllExtensions\tbool\t1' ;;
    finder-path) printf 'com.apple.finder\tShowPathbar\tbool\t1' ;;
    finder-status) printf 'com.apple.finder\tShowStatusBar\tbool\t1' ;;
    finder-list) printf 'com.apple.finder\tFXPreferredViewStyle\tstring\tNlsv' ;;
    dock-size) printf 'com.apple.dock\ttilesize\tfloat\t44' ;;
    dock-right) printf 'com.apple.dock\torientation\tstring\tright' ;;
    dock-magnification-off) printf 'com.apple.dock\tmagnification\tbool\t0' ;;
    dock-autohide) printf 'com.apple.dock\tautohide\tbool\t1' ;;
    dock-scale-effect) printf 'com.apple.dock\tmineffect\tstring\tscale' ;;
    dock-minimize-into-app) printf 'com.apple.dock\tminimize-to-application\tbool\t1' ;;
    dock-no-launch-animation) printf 'com.apple.dock\tlaunchanim\tbool\t0' ;;
    dock-show-indicators) printf 'com.apple.dock\tshow-process-indicators\tbool\t1' ;;
    dock-no-recents) printf 'com.apple.dock\tshow-recents\tbool\t0' ;;
    keyboard-fast) printf 'NSGlobalDomain\tKeyRepeat\tint\t2\nNSGlobalDomain\tInitialKeyRepeat\tint\t15' ;;
    autocorrect-off) printf 'NSGlobalDomain\tNSAutomaticSpellingCorrectionEnabled\tbool\t0' ;;
    screenshot-location) printf 'com.apple.screencapture\tlocation\tstring\t%s/Pictures/Screenshots' "$HOME" ;;
    *) return 1 ;;
  esac
}

print_security_review() {
  SECURITY_FIREWALL="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || printf 'Unavailable')"
  SECURITY_FILEVAULT="$(fdesetup status 2>/dev/null || printf 'Unavailable')"
  SECURITY_GATEKEEPER="$(spctl --status 2>/dev/null || printf 'Unavailable')"
  ui_section '🛡️' 'Security review — never changed automatically'
  printf '  Firewall:  %s\n' "$SECURITY_FIREWALL"
  printf '  FileVault: %s\n' "$SECURITY_FILEVAULT"
  printf '  Gatekeeper: %s\n' "$SECURITY_GATEKEEPER"
  printf '  File Sharing: review System Settings → General → Sharing\n'
  printf '  Gatekeeper must remain enabled; this tool never runs spctl --master-disable.\n'
}

print_plan() {
  local option specs domain key type value
  ui_title '🔎' 'macOS settings plan'
  print_security_review
  ui_section '🤖' 'Automated preferences'
  for option in ${SELECTED//,/ }; do
    is_manual_option "$option" && continue
    specs="$(preference_spec "$option" 2>/dev/null || true)"
    while IFS=$'\t' read -r domain key type value; do
      [[ -n "$domain" ]] || continue
      if [[ "$type" == bool ]]; then
        [[ "$value" == 1 ]] && value=true || value=false
      fi
      printf '  • %s\n    defaults write %s %s -%s %q\n' "$(option_label "$option")" "$domain" "$key" "$type" "$value"
    done <<<"$specs"
  done
  ui_section '👤' 'Manual preferences'
  for option in ${SELECTED//,/ }; do
    is_manual_option "$option" || continue
    printf '  • %s\n' "$(option_label "$option")"
  done
  [[ -n "$SELECTED" ]] || printf '  • No optional preferences selected.\n'
  printf '\nThe report will explain every manual System Settings path.\n'
}

capture_original() {
  local domain="$1" key="$2" type old_type value
  grep -Fq "$domain"$'\t'"$key"$'\t' "$BACKUP_FILE" 2>/dev/null && return 0
  old_type="$(defaults read-type "$domain" "$key" 2>/dev/null || true)"
  if [[ -z "$old_type" ]]; then
    printf '%s\t%s\tmissing\t-\n' "$domain" "$key" >> "$BACKUP_FILE"
    return 0
  fi
  case "$old_type" in
    *[Bb]oolean*) type=bool ;;
    *[Ii]nteger*) type=int ;;
    *[Ff]loat*) type=float ;;
    *[Ss]tring*) type=string ;;
    *) err "Unsupported existing preference type for $domain $key: $old_type"; return 1 ;;
  esac
  value="$(defaults read "$domain" "$key")"
  [[ "$value" != *$'\t'* && "$value" != *$'\n'* ]] || { err "Cannot safely record a multiline value for $domain $key"; return 1; }
  printf '%s\t%s\t%s\t%s\n' "$domain" "$key" "$type" "$value" >> "$BACKUP_FILE"
}

write_preference() {
  local domain="$1" key="$2" type="$3" value="$4" output first_line
  capture_original "$domain" "$key" || return 1
  [[ "$key" != location ]] || mkdir -p "$value"
  case "$type:$value" in
    bool:1|bool:true) value=true ;;
    bool:0|bool:false) value=false ;;
    bool:*) err "Invalid Boolean value for $domain $key: $value"; return 1 ;;
    int:*|float:*|string:*) ;;
    *) err "Unsupported preference type for $domain $key: $type"; return 1 ;;
  esac
  if ! output="$(defaults write "$domain" "$key" "-$type" "$value" 2>&1)"; then
    first_line="$(printf '%s\n' "$output" | sed -n '/[^[:space:]]/ { p; q; }')"
    err "Could not write $domain $key as $type${first_line:+: $first_line}"
    return 1
  fi
}

verify_preference() {
  local domain="$1" key="$2" type="$3" expected="$4" actual
  actual="$(defaults read "$domain" "$key" 2>/dev/null || true)"
  case "$type:$expected" in
    bool:1|bool:true) [[ "$actual" == 1 || "$actual" == true ]] ;;
    bool:0|bool:false) [[ "$actual" == 0 || "$actual" == false ]] ;;
    float:*) [[ "$actual" == "$expected" || "$actual" == "$expected.0" ]] ;;
    *) [[ "$actual" == "$expected" ]] ;;
  esac
}

manual_guidance() {
  local option="$1"
  case "$option" in
    finder-sizes) printf 'Finder → View → Show View Options → Calculate all sizes' ;;
    finder-home-sidebar) printf 'Finder → Settings → Sidebar → enable your home-folder name' ;;
    battery-percentage) printf 'System Settings → Menu Bar → Battery → Battery Options → Show Percentage' ;;
    tap-to-click) printf 'System Settings → Trackpad → Point & Click → Tap to click' ;;
    natural-scrolling-off) printf 'System Settings → Trackpad or Mouse → Scroll & Zoom → Natural scrolling: Off' ;;
  esac
}

write_report() {
  local option status="$1" specs domain key type value result manual_count=0 checkbox=' '
  [[ "$status" == completed ]] && checkbox=x
  ensure_state
  {
    printf '# Day One Mac — macOS settings report\n\n'
    printf -- '- Generated: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- Status: `%s`\n' "$status"
    printf -- '- Selection: `%s`\n\n' "${SELECTED:-none}"
    printf '## Security review\n\n'
    printf 'Security controls were inspected but not changed. Keep Gatekeeper enabled; verify Firewall, FileVault and File Sharing in System Settings.\n\n'
    printf '| Control | Observed status |\n|---|---|\n'
    printf '| Firewall | %s |\n' "${SECURITY_FIREWALL:-Not inspected}"
    printf '| FileVault | %s |\n' "${SECURITY_FILEVAULT:-Not inspected}"
    printf '| Gatekeeper | %s |\n\n' "${SECURITY_GATEKEEPER:-Not inspected}"
    printf '## Automated preferences\n\n| Setting | Verification |\n|---|---|\n'
    for option in ${SELECTED//,/ }; do
      is_manual_option "$option" && continue
      result=not-applied
      specs="$(preference_spec "$option" 2>/dev/null || true)"
      if [[ "$status" == completed || "$status" == manual-pending || "$status" == failed ]]; then
        result=pass
        while IFS=$'\t' read -r domain key type value; do
          [[ -n "$domain" ]] || continue
          verify_preference "$domain" "$key" "$type" "$value" || result=failed
        done <<<"$specs"
      fi
      printf '| %s | %s |\n' "$(option_label "$option")" "$result"
    done
    printf '\n## Manual follow-up\n\n'
    for option in ${SELECTED//,/ }; do
      is_manual_option "$option" || continue
      manual_count=$((manual_count + 1))
      printf -- '- [%s] %s: **%s**\n' "$checkbox" "$(option_label "$option")" "$(manual_guidance "$option")"
    done
    [[ "$manual_count" -gt 0 ]] || printf 'No manual preferences were selected.\n'
    printf '\n## Restore\n\nRun `day-one-mac macos-settings --restore` to restore captured scalar values.\n'
  } > "$REPORT_FILE"
  chmod 600 "$REPORT_FILE" "$BACKUP_FILE" 2>/dev/null || true
}

apply_selection() {
  local option specs domain key type value failures=0 manual_count=0
  print_plan
  confirm 'Apply the selected automated preferences?' || { warn 'Nothing was changed.'; return 10; }
  save_selection
  ensure_state
  touch "$BACKUP_FILE"; chmod 600 "$BACKUP_FILE"
  for option in ${SELECTED//,/ }; do
    is_manual_option "$option" && continue
    specs="$(preference_spec "$option" 2>/dev/null || true)"
    while IFS=$'\t' read -r domain key type value; do
      [[ -n "$domain" ]] || continue
      write_preference "$domain" "$key" "$type" "$value" || failures=$((failures + 1))
    done <<<"$specs"
  done
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
  if [[ "$failures" -gt 0 ]]; then
    write_report failed
    err "$failures preference write(s) failed; review $REPORT_FILE"
    return 1
  fi
  for option in ${SELECTED//,/ }; do
    if is_manual_option "$option"; then
      [[ "$manual_count" -gt 0 ]] || ui_section '👤' 'Complete the selected manual preferences'
      manual_count=$((manual_count + 1))
      printf '  • %s\n' "$(manual_guidance "$option")"
    fi
  done
  if [[ "$manual_count" -gt 0 ]] && ! confirm_manual 'Have you completed every selected manual preference?'; then
    write_report manual-pending
    printf 'manual-pending\n' > "$STATUS_FILE"; chmod 600 "$STATUS_FILE"
    warn "Manual selections remain. Review $REPORT_FILE, then rerun the wizard or choose skip in the main setup."
    return 10
  fi
  write_report completed
  printf 'completed\n' > "$STATUS_FILE"; chmod 600 "$STATUS_FILE"
  ok "settings applied and verified; report: $REPORT_FILE"
}

restore_originals() {
  local domain key type value failures=0
  [[ -s "$BACKUP_FILE" ]] || { err "No captured originals exist at $BACKUP_FILE"; return 1; }
  confirm 'Restore every preference captured by this tool?' || { warn 'Nothing was changed.'; return 10; }
  while IFS=$'\t' read -r domain key type value; do
    [[ -n "$domain" ]] || continue
    case "$type" in
      missing) defaults delete "$domain" "$key" 2>/dev/null || true ;;
      bool|int|float|string) write_preference "$domain" "$key" "$type" "$value" || failures=$((failures + 1)) ;;
      *) warn "Skipped unknown saved type '$type' for $domain $key"; failures=$((failures + 1)) ;;
    esac
  done < "$BACKUP_FILE"
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
  [[ "$failures" -eq 0 ]] || { err "$failures preference restore(s) failed."; return 1; }
  printf 'restored\n' > "$STATUS_FILE"; chmod 600 "$STATUS_FILE"
  ok 'captured macOS preference values restored'
}

show_status() {
  local status
  status="$(sed -n '1p' "$STATUS_FILE" 2>/dev/null || printf 'not run')"
  SELECTED="$(sed -n '1p' "$SELECTION_FILE" 2>/dev/null || true)"
  ui_title '📊' 'macOS settings status'
  printf '  Status: %s\n' "$status"
  printf '  Selection: %s\n' "${SELECTED:-none saved}"
  printf '  Report: %s\n' "$REPORT_FILE"
  printf '  Original values: %s\n' "$BACKUP_FILE"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wizard) MODE=wizard ;;
    --preview) MODE=preview ;;
    --apply) MODE=apply ;;
    --status) MODE=status ;;
    --restore) MODE=restore ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

day_one_require_apple_silicon || exit 2
validate_option_catalog || exit $?

case "$MODE" in
  wizard) choose_settings; apply_selection ;;
  preview) load_selection_flags; SELECTED=""; for ((i=0; i<${#OPTIONS[@]}; i++)); do [[ "${SELECTED_FLAGS[$i]}" == 1 ]] && SELECTED="${SELECTED}${SELECTED:+,}${OPTIONS[$i]}"; done; print_plan ;;
  apply) SELECTED="$(sed -n '1p' "$SELECTION_FILE" 2>/dev/null || true)"; [[ -n "$SELECTED" ]] || { err 'No saved selection exists. Run --wizard first.'; exit 1; }; [[ "$SELECTED" != none ]] || SELECTED=""; apply_selection ;;
  status) show_status ;;
  restore) restore_originals ;;
esac
