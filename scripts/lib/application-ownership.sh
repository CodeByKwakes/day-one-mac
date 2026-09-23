#!/usr/bin/env bash
# Shared application discovery and provenance helpers for Day One Mac.
# Source this file; it intentionally performs no work at load time.
# Compatible with the Bash 3.2 shipped by macOS.

DAY_ONE_APP_LIBRARY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAY_ONE_APP_PROJECT_DIR="$(cd "$DAY_ONE_APP_LIBRARY_DIR/../.." && pwd)"
DAY_ONE_APP_CATALOG="${DAY_ONE_MAC_APPLICATION_CATALOG:-$DAY_ONE_APP_PROJECT_DIR/config/applications.tsv}"

day_one_app_catalog_ids() {
  local scope="${1:-all}"
  awk -F '\t' -v scope="$scope" '
    $0 !~ /^#/ && NF >= 9 && (scope == "all" || $2 == scope) {print $1}
  ' "$DAY_ONE_APP_CATALOG"
}

day_one_app_load() {
  local wanted="$1" row
  row="$(awk -F '\t' -v wanted="$wanted" '$0 !~ /^#/ && $1 == wanted {print; exit}' "$DAY_ONE_APP_CATALOG")"
  [[ -n "$row" ]] || return 1
  IFS=$'\t' read -r DAY_ONE_APP_ID DAY_ONE_APP_SCOPE DAY_ONE_APP_PHASE \
    DAY_ONE_APP_NAME DAY_ONE_APP_CASK DAY_ONE_APP_KIND DAY_ONE_APP_EXPECTED_PATH \
    DAY_ONE_APP_EXPECTED_BUNDLE_ID DAY_ONE_APP_COMMAND <<<"$row"
}

day_one_app_brew_bin() {
  [[ "${DAY_ONE_MAC_APPLICATION_BREW_LOOKUP:-enabled}" != disabled ]] || return 1
  if command -v brew >/dev/null 2>&1; then command -v brew
  elif [[ -x /opt/homebrew/bin/brew ]]; then printf '/opt/homebrew/bin/brew\n'
  else return 1
  fi
}

day_one_app_brew_has_cask() {
  local cask="$1" brew_bin
  [[ "$cask" != - ]] || return 1
  brew_bin="$(day_one_app_brew_bin)" || return 1
  HOMEBREW_NO_AUTO_UPDATE=1 "$brew_bin" list --cask "$cask" >/dev/null 2>&1
}

day_one_app_resolve_expected_path() {
  local configured="$1" applications_root="${DAY_ONE_MAC_APPLICATIONS_ROOT:-/Applications}"
  if [[ "$configured" == /Applications/* ]]; then
    printf '%s/%s\n' "${applications_root%/}" "${configured#/Applications/}"
  else
    printf '%s\n' "$configured"
  fi
}

day_one_app_legacy_path() {
  local app_id="$1" applications_root="${DAY_ONE_MAC_APPLICATIONS_ROOT:-/Applications}"
  case "$app_id" in
    copilot-app)
      # GitHub's earlier standalone download used Copilot.app. Preserve a valid
      # existing copy instead of installing the renamed Homebrew app beside it.
      printf '%s/Copilot.app\n' "${applications_root%/}"
      ;;
    *) return 1 ;;
  esac
}

day_one_app_plist_value() {
  local plist="$1" key="$2"
  [[ -r "$plist" ]] || return 1
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || return 1
}

day_one_app_find_font() {
  local root match
  for root in "${DAY_ONE_MAC_SYSTEM_FONTS_ROOT:-/Library/Fonts}" \
              "${DAY_ONE_MAC_USER_FONTS_ROOT:-$HOME/Library/Fonts}"; do
    [[ -d "$root" ]] || continue
    match="$(find "$root" -maxdepth 1 -type f \
      \( -iname '*JetBrains*Mono*Nerd*' -o -iname '*JetBrainsMono*Nerd*' \) \
      -print -quit 2>/dev/null || true)"
    if [[ -n "$match" ]]; then printf '%s\n' "$match"; return 0; fi
  done
  return 1
}

day_one_app_source_label() {
  case "$1" in
    homebrew) printf 'Homebrew-managed' ;;
    app-store) printf 'Mac App Store' ;;
    external) printf 'External installation (Company Portal or manual)' ;;
    missing) printf 'Missing' ;;
    review) printf 'Needs review' ;;
    *) printf '%s' "$1" ;;
  esac
}

day_one_app_status_label() {
  case "$1" in
    ready) printf 'Ready' ;;
    missing) printf 'Missing' ;;
    review) printf 'Needs review' ;;
    *) printf '%s' "$1" ;;
  esac
}

day_one_app_show_install_requirements() {
  printf '\n%s is missing.\n' "$DAY_ONE_APP_NAME"
  case "$DAY_ONE_APP_KIND" in
    app)
      printf 'A valid installation must provide:\n'
      printf '  Application: %s\n' "$DAY_ONE_APP_EXPECTED_PATH"
      if [[ "$DAY_ONE_APP_EXPECTED_BUNDLE_ID" != - ]]; then
        printf '  Bundle ID:   %s\n' "$DAY_ONE_APP_EXPECTED_BUNDLE_ID"
      fi
      ;;
    cli)
      printf 'A valid installation must provide this Terminal command on PATH:\n'
      printf '  Command:     %s\n' "$DAY_ONE_APP_COMMAND"
      ;;
    font)
      printf 'A valid installation must place %s in the system or user Fonts folder.\n' "$DAY_ONE_APP_NAME"
      ;;
  esac
  if [[ "$DAY_ONE_APP_CASK" != - ]]; then
    printf '  Homebrew:    brew install --cask %s\n' "$DAY_ONE_APP_CASK"
  fi
}

# Set DAY_ONE_APP_INSTALL_CHOICE to homebrew, external, or stop. The caller
# performs the installation so its own manifest and rollback rules stay intact.
day_one_app_choose_install_route() {
  local policy="$1" answer
  case "$policy" in
    homebrew) DAY_ONE_APP_INSTALL_CHOICE=homebrew; return 0 ;;
    check-only) DAY_ONE_APP_INSTALL_CHOICE=stop; return 0 ;;
    prompt) ;;
    *) printf 'Unknown application installation policy: %s\n' "$policy" >&2; return 2 ;;
  esac

  day_one_app_show_install_requirements
  printf '\nChoose how to provide %s:\n' "$DAY_ONE_APP_NAME"
  printf '  1) Install with Homebrew\n'
  printf '  2) Use Company Portal, the App Store, or another approved installer\n'
  printf '  3) Stop safely and resume this phase later\n'
  while :; do
    printf 'Choice [1-3]: '
    IFS= read -r answer || { DAY_ONE_APP_INSTALL_CHOICE=stop; return 0; }
    case "$answer" in
      1) DAY_ONE_APP_INSTALL_CHOICE=homebrew; return 0 ;;
      2) DAY_ONE_APP_INSTALL_CHOICE=external; return 0 ;;
      3|q|Q) DAY_ONE_APP_INSTALL_CHOICE=stop; return 0 ;;
      *) printf 'Enter 1, 2, or 3.\n' >&2 ;;
    esac
  done
}

# Set DAY_ONE_APP_EXTERNAL_ACTION after the user has selected an external
# installer. Recheck is the default so Enter is enough after a graphical or
# company-managed installer finishes.
day_one_app_prompt_external_action() {
  local answer
  printf '\nInstall %s with Company Portal, the App Store, or another approved installer.\n' "$DAY_ONE_APP_NAME"
  printf 'The setup will not open, approve, or take ownership of that installer.\n'
  day_one_app_show_install_requirements
  printf '\n[Enter] installation finished — check again   h use Homebrew   s stop safely\n'
  printf '> '
  IFS= read -r answer || { DAY_ONE_APP_EXTERNAL_ACTION=stop; return 0; }
  case "$answer" in
    '') DAY_ONE_APP_EXTERNAL_ACTION=recheck ;;
    h|H) DAY_ONE_APP_EXTERNAL_ACTION=homebrew ;;
    s|S|q|Q) DAY_ONE_APP_EXTERNAL_ACTION=stop ;;
    *) DAY_ONE_APP_EXTERNAL_ACTION=again ;;
  esac
}

day_one_app_detect() {
  local wanted="$1" cask_present=0 payload_present=0 actual_bundle="" alternate_path="" used_legacy_path=0
  day_one_app_load "$wanted" || return 2

  DAY_ONE_APP_STATUS=missing
  DAY_ONE_APP_SOURCE=missing
  DAY_ONE_APP_FOUND_PATH=-
  DAY_ONE_APP_ACTUAL_BUNDLE_ID=-
  DAY_ONE_APP_VERSION=-
  DAY_ONE_APP_COMMAND_PATH=-
  DAY_ONE_APP_REASON='No matching application, command, font, or Homebrew cask was found.'

  day_one_app_brew_has_cask "$DAY_ONE_APP_CASK" && cask_present=1

  case "$DAY_ONE_APP_KIND" in
    app)
      DAY_ONE_APP_FOUND_PATH="$(day_one_app_resolve_expected_path "$DAY_ONE_APP_EXPECTED_PATH")"
      if [[ ! -e "$DAY_ONE_APP_FOUND_PATH" ]]; then
        alternate_path="$(day_one_app_legacy_path "$DAY_ONE_APP_ID" 2>/dev/null || true)"
        [[ -n "$alternate_path" && -e "$alternate_path" ]] \
          && { DAY_ONE_APP_FOUND_PATH="$alternate_path"; used_legacy_path=1; }
      fi
      if [[ ! -e "$DAY_ONE_APP_FOUND_PATH" && "$DAY_ONE_APP_EXPECTED_PATH" == /Applications/* ]]; then
        alternate_path="$HOME/Applications/${DAY_ONE_APP_EXPECTED_PATH#/Applications/}"
        [[ -e "$alternate_path" ]] && DAY_ONE_APP_FOUND_PATH="$alternate_path"
      fi
      if [[ -e "$DAY_ONE_APP_FOUND_PATH" ]]; then
        if [[ ! -d "$DAY_ONE_APP_FOUND_PATH" || ! -r "$DAY_ONE_APP_FOUND_PATH/Contents/Info.plist" ]]; then
          DAY_ONE_APP_STATUS=review
          DAY_ONE_APP_SOURCE=review
          DAY_ONE_APP_REASON="The expected path exists but is not a readable macOS application bundle: $DAY_ONE_APP_FOUND_PATH"
          return 0
        fi
        actual_bundle="$(day_one_app_plist_value "$DAY_ONE_APP_FOUND_PATH/Contents/Info.plist" CFBundleIdentifier || true)"
        DAY_ONE_APP_ACTUAL_BUNDLE_ID="${actual_bundle:--}"
        DAY_ONE_APP_VERSION="$(day_one_app_plist_value "$DAY_ONE_APP_FOUND_PATH/Contents/Info.plist" CFBundleShortVersionString || true)"
        DAY_ONE_APP_VERSION="${DAY_ONE_APP_VERSION:--}"
        if [[ "$DAY_ONE_APP_EXPECTED_BUNDLE_ID" != - \
           && "$actual_bundle" != "$DAY_ONE_APP_EXPECTED_BUNDLE_ID" ]]; then
          DAY_ONE_APP_STATUS=review
          DAY_ONE_APP_SOURCE=review
          DAY_ONE_APP_REASON="The bundle identifier is '${actual_bundle:-missing}', expected '$DAY_ONE_APP_EXPECTED_BUNDLE_ID'."
          return 0
        fi
        payload_present=1
      else
        DAY_ONE_APP_FOUND_PATH=-
      fi
      ;;
    cli)
      if [[ "${DAY_ONE_MAC_APPLICATION_COMMAND_LOOKUP:-enabled}" != disabled ]] \
         && command -v "$DAY_ONE_APP_COMMAND" >/dev/null 2>&1; then
        DAY_ONE_APP_COMMAND_PATH="$(command -v "$DAY_ONE_APP_COMMAND")"
        DAY_ONE_APP_FOUND_PATH="$DAY_ONE_APP_COMMAND_PATH"
        payload_present=1
      fi
      ;;
    font)
      if DAY_ONE_APP_FOUND_PATH="$(day_one_app_find_font)"; then payload_present=1
      else DAY_ONE_APP_FOUND_PATH=-
      fi
      ;;
    *)
      DAY_ONE_APP_STATUS=review
      DAY_ONE_APP_SOURCE=review
      DAY_ONE_APP_REASON="Unknown catalogue kind: $DAY_ONE_APP_KIND"
      return 0
      ;;
  esac

  if [[ "$cask_present" == 1 && "$used_legacy_path" == 1 ]]; then
    DAY_ONE_APP_STATUS=review
    DAY_ONE_APP_SOURCE=review
    DAY_ONE_APP_REASON="Homebrew records cask '$DAY_ONE_APP_CASK', but its current application is missing while a legacy external application exists at $DAY_ONE_APP_FOUND_PATH."
  elif [[ "$cask_present" == 1 && "$payload_present" == 1 ]]; then
    DAY_ONE_APP_STATUS=ready
    DAY_ONE_APP_SOURCE=homebrew
    DAY_ONE_APP_REASON="Homebrew owns cask '$DAY_ONE_APP_CASK' and its required payload is available."
  elif [[ "$cask_present" == 1 ]]; then
    DAY_ONE_APP_STATUS=review
    DAY_ONE_APP_SOURCE=review
    DAY_ONE_APP_REASON="Homebrew records cask '$DAY_ONE_APP_CASK', but its expected application, command, or font is unavailable."
  elif [[ "$payload_present" == 1 ]]; then
    DAY_ONE_APP_STATUS=ready
    if [[ "$DAY_ONE_APP_KIND" == app \
       && -f "$DAY_ONE_APP_FOUND_PATH/Contents/_MASReceipt/receipt" ]]; then
      DAY_ONE_APP_SOURCE=app-store
      DAY_ONE_APP_REASON='A valid Mac App Store application exists; Homebrew does not own it.'
    else
      DAY_ONE_APP_SOURCE=external
      DAY_ONE_APP_REASON='A valid existing installation is available; Homebrew does not own it.'
    fi
  fi
}

day_one_app_is_satisfied() {
  [[ "$DAY_ONE_APP_STATUS" == ready ]]
}

day_one_app_clean_field() {
  printf '%s' "$1" | tr '\t\r\n' '   '
}

day_one_app_render_provenance() {
  local tsv="$1" report="$2"
  local id scope phase name status source version path cask bundle command_path installed rollback required_label
  {
    printf '# Day One Mac application provenance\n\n'
    printf 'This report records how each checked application was supplied. An external\n'
    printf 'installation may come from a company portal, a signed installer, or another\n'
    printf 'approved source; Day One Mac preserves it and does not claim ownership.\n\n'
    printf -- '- Updated: `%s`\n\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf '| Application | Required? | Phase | Result | Installation source | Version | Location or command | Homebrew cask | Installed by Day One Mac | Rollback |\n'
    printf '|---|---|---:|---|---|---|---|---|---|---|\n'
    while IFS=$'\t' read -r id scope phase name status source version path cask bundle command_path installed rollback; do
      [[ "$id" != id && -n "$id" ]] || continue
      if [[ "$scope" == required ]]; then required_label=Yes; else required_label=No; fi
      printf '| %s | %s | %s | %s | %s | `%s` | `%s` | `%s` | %s | %s |\n' \
        "$name" "$required_label" "$phase" "$(day_one_app_status_label "$status")" "$(day_one_app_source_label "$source")" \
        "$version" "$path" "$cask" "$installed" "$rollback"
    done < "$tsv"
    printf '\n## Interpretation\n\n'
    printf -- '- **Homebrew-managed:** Homebrew owns the cask.\n'
    printf -- '- **External installation:** the app or command is valid, but Homebrew does not own it. It is never replaced or removed by this setup.\n'
    printf -- '- **Mac App Store:** the app contains an App Store receipt and is preserved.\n'
    printf -- '- **Needs review:** a receipt, path, bundle identity, or required payload conflicts with the catalogue.\n'
  } > "$report"
  chmod 600 "$report"
}

day_one_app_record_current() {
  local tsv="$1" report="$2" install_manifest="${3:-}" parent tmp installed=no rollback='preserved'
  local id scope phase name status source version path cask bundle command_path
  parent="$(dirname "$tsv")"
  mkdir -p "$parent"
  chmod 700 "$parent" 2>/dev/null || true
  [[ -e "$tsv" ]] || printf 'id\tscope\tphase\tname\tstatus\tsource\tversion\tpath\tcask\tbundle_id\tcommand_path\tinstalled_by_day_one_mac\trollback\n' > "$tsv"

  if [[ -n "$install_manifest" && "$DAY_ONE_APP_CASK" != - \
     && -r "$install_manifest" ]] \
     && grep -Fqx "brew-cask"$'\t'"$DAY_ONE_APP_CASK" "$install_manifest"; then
    installed=yes
    rollback='recorded Homebrew rollback'
  elif [[ "$DAY_ONE_APP_STATUS" != ready ]]; then
    rollback='not applicable'
  fi

  id="$(day_one_app_clean_field "$DAY_ONE_APP_ID")"
  scope="$(day_one_app_clean_field "$DAY_ONE_APP_SCOPE")"
  phase="$(day_one_app_clean_field "$DAY_ONE_APP_PHASE")"
  name="$(day_one_app_clean_field "$DAY_ONE_APP_NAME")"
  status="$(day_one_app_clean_field "$DAY_ONE_APP_STATUS")"
  source="$(day_one_app_clean_field "$DAY_ONE_APP_SOURCE")"
  version="$(day_one_app_clean_field "$DAY_ONE_APP_VERSION")"
  path="$(day_one_app_clean_field "$DAY_ONE_APP_FOUND_PATH")"
  cask="$(day_one_app_clean_field "$DAY_ONE_APP_CASK")"
  bundle="$(day_one_app_clean_field "$DAY_ONE_APP_ACTUAL_BUNDLE_ID")"
  command_path="$(day_one_app_clean_field "$DAY_ONE_APP_COMMAND_PATH")"

  tmp="$(mktemp "$parent/.application-provenance.XXXXXX")"
  awk -F '\t' -v wanted="$id" 'NR == 1 || $1 != wanted' "$tsv" > "$tmp"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" "$scope" "$phase" "$name" "$status" "$source" "$version" "$path" \
    "$cask" "$bundle" "$command_path" "$installed" "$rollback" >> "$tmp"
  mv "$tmp" "$tsv"
  chmod 600 "$tsv"
  day_one_app_render_provenance "$tsv" "$report"
}
