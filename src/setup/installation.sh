#!/usr/bin/env bash
# Required software selection, installation and provenance; consumes the runner context.
# Sourced by setup.sh after state, platform and ownership helpers.

required_formulae() {
  printf '%s\n' git jq ripgrep
  uses_chezmoi && printf '%s\n' chezmoi
  uses_starship && printf '%s\n' starship
  [[ "$SHELL_CHOICE" != homebrew ]] || printf '%s\n' zsh
  [[ "${GHQ_CHOICE:-}" != yes ]] || printf '%s\n' ghq
  if uses_node; then printf '%s\n' fnm pnpm; fi
  uses_python && printf '%s\n' uv
  uses_github && printf '%s\n' gh
  uses_azure && printf '%s\n' azure-cli
  return 0
}

installation_centre_fingerprint() {
  local application_catalog_hash formulae_hash implementation
  implementation="$(phase_fingerprint 04)" || return 1
  application_catalog_hash="$(awk -F '\t' '$0 !~ /^#/ && $2 == "required"' "$DAY_ONE_APP_CATALOG" | shasum -a 256 | awk '{print $1}')" || return 1
  formulae_hash="$(required_formulae | shasum -a 256 | awk '{print $1}')" || return 1
  {
    printf 'installation-centre-schema=%s\n' "$INSTALLATION_CENTRE_SCHEMA"
    printf 'track=%s\nstack=%s\n' "$TRACK" "$STACK"
    printf 'preset=%s\nauth=%s\n' "${PRESET:-recommended-productivity}" "$AUTH_MODE"
    printf 'implementation=%s\n' "$implementation"
    printf 'applications=%s\n' "$application_catalog_hash"
    printf 'formulae=%s\n' "$formulae_hash"
  } | shasum -a 256 | awk '{print $1}'
}

# Azure CLI migrated to a Homebrew cask. Preserve working legacy formula
# installs, and use the same package check in installation and later gates.
required_package_installed() {
  local token="$1"
  brew list --formula "$token" >/dev/null 2>&1 && return 0
  [[ "$token" == azure-cli ]] && brew list --cask "$token" >/dev/null 2>&1
}

installation_centre_components_ready() {
  local app_id formula application_list formula_list
  load_brew || return 1
  # Finish bounded catalogue reads before a check can return early. Process
  # substitution leaves a background writer on a pipe the caller may close.
  application_list="$(required_application_ids)" || return 1
  formula_list="$(required_formulae)" || return 1
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    day_one_app_detect "$app_id" || return 1
    day_one_app_is_satisfied || return 1
  done <<<"$application_list"
  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    if [[ "$formula" == ghq ]] && have ghq; then continue; fi
    required_package_installed "$formula" || {
      err "Required command-line package is unavailable: $formula (Azure CLI may be a formula or cask)."
      return 1
    }
  done <<<"$formula_list"
}

installation_centre_done() {
  local marker="$COMPLETED_DIR/installation-centre" expected
  expected="$(installation_centre_fingerprint)" || return 1
  [[ -n "$expected" ]] || return 1
  [[ -r "$marker" ]] \
    && [[ "$(sed -n '1p' "$marker")" == "$expected" ]] \
    && installation_centre_components_ready
}

mark_installation_centre_done() {
  local marker="$COMPLETED_DIR/installation-centre" fingerprint
  [[ "$DRY_RUN" == 1 ]] && { ok 'would mark the Installation Centre complete'; return 0; }
  fingerprint="$(installation_centre_fingerprint)" || return 1
  [[ -n "$fingerprint" ]] || return 1
  ensure_state || return 1
  day_one_write_state "$marker" "$fingerprint" || return 1
  log_line 'PASS installation-centre'
}

mark_phase_done() {
  local fingerprint
  [[ "$DRY_RUN" == 1 ]] && { ok "would mark Phase $1 complete"; return 0; }
  fingerprint="$(phase_fingerprint "$1")" || return 1
  [[ -n "$fingerprint" ]] || return 1
  ensure_state || return 1
  day_one_write_state "$COMPLETED_DIR/$1" "$fingerprint" || return 1
  log_line "PASS phase-$1"
}

brew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then printf '/opt/homebrew/bin/brew\n'
  elif have brew && [[ "$(command -v brew)" == /opt/homebrew/* ]]; then command -v brew
  else return 1
  fi
}

load_brew() {
  local brew_bin
  brew_bin="$(brew_path)" || return 1
  eval "$("$brew_bin" shellenv)"
}

record_package() {
  ensure_state
  append_unique "$INSTALL_MANIFEST" "$1"$'\t'"$2"
}

# List the installed formulae, distinguishing "none" from "could not ask".
# Returns 1 when Homebrew could not be queried at all.
brew_formula_snapshot() {
  local output status
  set +e
  output="$(brew list --formula 2>/dev/null)"
  status=$?
  set -e
  [[ "$status" -eq 0 ]] || return 1
  printf '%s\n' "$output" | sort
}

# Warn once when the pre-install baseline is unavailable. Without it, every
# formula on the Mac would look newly installed and be claimed as runner-owned,
# so a later rollback could uninstall software the user already had.
# Under-claiming leaves software in place and is the safe direction.
warn_unknown_dependency_baseline() {
  warn "Could not list the formulae installed before adding $1."
  warn "Only $1 is recorded as runner-owned; new dependencies are left unclaimed so rollback cannot remove pre-existing software."
}

install_formula() {
  local token="$1" before_formulae formula baseline=1
  if [[ "$DRY_RUN" == 1 ]]; then
    if [[ "$token" == azure-cli ]]; then print_command brew install --cask "$token"
    else print_command brew install "$token"; fi
    return 0
  fi
  if load_brew && required_package_installed "$token"; then info "package $token already installed"; return 0; fi
  if [[ "$token" == azure-cli ]]; then install_cask "$token"; return $?; fi
  before_formulae="$(brew_formula_snapshot)" || baseline=0
  run brew install "$token"
  record_package brew-formula "$token"
  [[ "$baseline" == 1 ]] || { warn_unknown_dependency_baseline "$token"; return 0; }
  while IFS= read -r formula; do
    [[ -n "$formula" && "$formula" != "$token" ]] || continue
    grep -Fqx "$formula" <<<"$before_formulae" || record_package brew-dependency "$formula"
  done < <(brew_formula_snapshot || true)
}

install_cask() {
  local token="$1" before_formulae formula baseline=1
  if [[ "$DRY_RUN" == 1 ]]; then print_command brew install --cask "$token"; return 0; fi
  if load_brew && brew list --cask "$token" >/dev/null 2>&1; then info "cask $token already installed"; return 0; fi
  before_formulae="$(brew_formula_snapshot)" || baseline=0
  [[ "$token" != git-credential-manager ]] || record_path_before_write "$HOME/.gitconfig"
  run brew install --cask "$token"
  record_package brew-cask "$token"
  [[ "$baseline" == 1 ]] || { warn_unknown_dependency_baseline "$token"; return 0; }
  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    grep -Fqx "$formula" <<<"$before_formulae" || record_package brew-dependency "$formula"
  done < <(brew_formula_snapshot || true)
}

record_application_status() {
  [[ "$DRY_RUN" == 1 ]] && return 0
  ensure_state
  day_one_app_record_current "$APPLICATION_PROVENANCE_TSV" \
    "$APPLICATION_PROVENANCE_REPORT" "$INSTALL_MANIFEST"
}

show_application_status() {
  local source_label
  source_label="$(day_one_app_source_label "$DAY_ONE_APP_SOURCE")"
  case "$DAY_ONE_APP_STATUS" in
    ready)
      ok "$DAY_ONE_APP_NAME — $source_label"
      [[ "$DAY_ONE_APP_FOUND_PATH" == - ]] || info "location: $DAY_ONE_APP_FOUND_PATH"
      ;;
    missing)
      ui_status pending "○ $DAY_ONE_APP_NAME — missing"
      info "available Homebrew cask: $DAY_ONE_APP_CASK"
      ;;
    review)
      err "$DAY_ONE_APP_NAME — needs review"
      warn "$DAY_ONE_APP_REASON"
      ;;
  esac
}

scan_applications() {
  local app_id review_count=0
  for app_id in "$@"; do
    day_one_app_detect "$app_id" || {
      err "Unknown application catalogue ID: $app_id"
      review_count=$((review_count + 1))
      continue
    }
    show_application_status
    record_application_status
    [[ "$DAY_ONE_APP_STATUS" != review ]] || review_count=$((review_count + 1))
  done
  if [[ "$review_count" -gt 0 ]]; then
    err "$review_count application result(s) need review; no missing application was installed."
    return "$EX_GATE"
  fi
}

wait_for_external_application() {
  local app_id="$1"
  while :; do
    day_one_app_prompt_external_action
    case "$DAY_ONE_APP_EXTERNAL_ACTION" in
      homebrew) return 20 ;;
      stop)
        warn "$DAY_ONE_APP_NAME remains pending. Rerun this phase after the approved installer finishes."
        return "$EX_MANUAL"
        ;;
      again)
        warn "Choose Enter, h, or s."
        continue
        ;;
    esac

    hash -r 2>/dev/null || true
    day_one_app_detect "$app_id"
    show_application_status
    record_application_status
    case "$DAY_ONE_APP_STATUS" in
      ready)
        ok "$DAY_ONE_APP_NAME was found and will remain managed by its external owner"
        return 0
        ;;
      review)
        err "$DAY_ONE_APP_NAME needs review before setup can continue."
        warn "$DAY_ONE_APP_REASON"
        return "$EX_GATE"
        ;;
      missing)
        warn "$DAY_ONE_APP_NAME is still missing. Finish the installer, choose Homebrew, or stop safely."
        ;;
    esac
  done
}

ensure_application() {
  local app_id="$1" already_shown="${2:-0}" external_rc
  day_one_app_detect "$app_id" || { err "Unknown application catalogue ID: $app_id"; return "$EX_GATE"; }
  [[ "$already_shown" == 1 ]] || show_application_status
  record_application_status
  case "$DAY_ONE_APP_STATUS" in
    ready) return 0 ;;
    review) return "$EX_GATE" ;;
  esac

  if [[ "$DRY_RUN" == 1 ]]; then
    case "$APP_INSTALL_POLICY" in
      homebrew)
        info "Homebrew policy selected for missing $DAY_ONE_APP_NAME"
        print_command brew install --cask "$DAY_ONE_APP_CASK"
        ;;
      check-only)
        info "check-only policy would stop with $DAY_ONE_APP_NAME still missing"
        ;;
      prompt)
        info "would ask whether to use Homebrew or another approved installer for $DAY_ONE_APP_NAME"
        print_command brew install --cask "$DAY_ONE_APP_CASK"
        ;;
    esac
    return 0
  fi

  if [[ "$APP_INSTALL_POLICY" == prompt && ! -t 0 ]]; then
    err "$DAY_ONE_APP_NAME is missing, but installation choice needs an interactive terminal."
    warn "Rerun interactively or pass --app-install-policy homebrew."
    return "$EX_MANUAL"
  fi
  day_one_app_choose_install_route "$APP_INSTALL_POLICY"
  case "$DAY_ONE_APP_INSTALL_CHOICE" in
    stop)
      day_one_app_show_install_requirements
      warn "$DAY_ONE_APP_NAME was not installed. No phase completion was recorded."
      return "$EX_MANUAL"
      ;;
    external)
      if wait_for_external_application "$app_id"; then
        return 0
      else
        external_rc=$?
        [[ "$external_rc" -eq 20 ]] || return "$external_rc"
      fi
      ;;
  esac

  install_cask "$DAY_ONE_APP_CASK"
  [[ "$DRY_RUN" == 1 ]] && return 0
  day_one_app_detect "$app_id"
  show_application_status
  record_application_status
  if ! day_one_app_is_satisfied; then
    err "$DAY_ONE_APP_NAME is still unavailable after Homebrew installation."
    warn "$DAY_ONE_APP_REASON"
    return "$EX_GATE"
  fi
}

verify_application() {
  local app_id="$1"
  day_one_app_detect "$app_id" || return 1
  record_application_status
  day_one_app_is_satisfied
}

choose_installation_centre_policy() {
  local missing_count="$1" answer
  INSTALLATION_CENTRE_POLICY="$APP_INSTALL_POLICY"
  [[ "$missing_count" -gt 0 && "$APP_INSTALL_POLICY" == prompt ]] || return 0
  [[ "$DRY_RUN" == 1 ]] && return 0
  [[ -t 0 ]] || { INSTALLATION_CENTRE_POLICY=check-only; return 0; }
  printf '\n%s required application(s) are missing.\n' "$missing_count"
  printf '[Enter] install every missing item with Homebrew   r review each item   q stop: '
  IFS= read -r answer || return "$EX_MANUAL"
  case "$answer" in
    '') INSTALLATION_CENTRE_POLICY=homebrew ;;
    r|R) INSTALLATION_CENTRE_POLICY=prompt ;;
    q|Q) return "$EX_MANUAL" ;;
    *)
      warn 'Enter installs all missing required items with Homebrew; r reviews each owner; q stops.'
      return "$EX_MANUAL"
      ;;
  esac
}

run_installation_centre() {
  local app_id formula rc missing_count=0 previous_policy="$APP_INSTALL_POLICY"
  local app_ids="" formulae="" application_list
  installation_centre_fingerprint >/dev/null || return 1
  folders_validate_choices || return $?
  folders_inspect_paths || return $?
  ui_title '📦' 'Required Installation Centre'
  info 'Applications are installed and ownership-checked here before configuration begins.'
  info "Guide: $DOC_DIR/setup/assisted/INSTALLATION-CENTRE.md"
  if ! load_brew; then
    [[ "$DRY_RUN" == 1 ]] || {
      err 'Homebrew is unavailable. Complete Phase 2 before opening the Installation Centre.'
      return "$EX_GATE"
    }
  fi

  ui_section '🔎' 'Application ownership — no changes yet'
  application_list="$(required_application_ids)" || return "$EX_GATE"
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    app_ids="${app_ids}${app_ids:+ }$app_id"
    day_one_app_detect "$app_id" || return "$EX_GATE"
    show_application_status
    record_application_status
    case "$DAY_ONE_APP_STATUS" in
      missing) missing_count=$((missing_count + 1)) ;;
      review)
        err 'Resolve the ownership conflict shown above before installing anything.'
        return "$EX_GATE"
        ;;
    esac
  done <<<"$application_list"

  choose_installation_centre_policy "$missing_count" || {
    warn 'No application was removed. Rerun the Installation Centre when ready.'
    return "$EX_MANUAL"
  }
  APP_INSTALL_POLICY="$INSTALLATION_CENTRE_POLICY"
  ui_section '📥' 'Required applications'
  for app_id in $app_ids; do
    if ensure_application "$app_id"; then
      :
    else
      rc=$?
      APP_INSTALL_POLICY="$previous_policy"
      return "$rc"
    fi
  done
  APP_INSTALL_POLICY="$previous_policy"
  update_homebrew_1password_if_needed || return $?

  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    formulae="${formulae}${formulae:+ }$formula"
  done < <(required_formulae)
  ui_section '🧰' 'Required command-line tools'
  info "selected for Track $TRACK and stack $STACK: $formulae"
  for formula in $formulae; do
    if [[ "$formula" == ghq ]] && have ghq; then info 'Reusing existing ghq; not claiming package ownership'; continue; fi
    install_formula "$formula"
  done
  [[ "$DRY_RUN" == 1 ]] || hash -r 2>/dev/null || true

  if [[ "$DRY_RUN" != 1 ]] && ! installation_centre_components_ready; then
    err 'One or more required applications or formulae are still unavailable.'
    warn 'Review the ownership report, finish any external installer, then rerun the Installation Centre.'
    return "$EX_GATE"
  fi
  mark_installation_centre_done || return $?
  INSTALLATION_CENTRE_RAN=1
  ok 'required applications and command-line tools are installed; configuration can begin'
}

report_application() {
  local label="$1" app_id="$2" result
  day_one_app_detect "$app_id" || {
    printf '| %s | FAIL — unknown catalogue entry |\n' "$label" >> "$STATE_DIR/verification.md"
    VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
    phase_gate_failed "$label"
    return 0
  }
  record_application_status
  result="$(day_one_app_source_label "$DAY_ONE_APP_SOURCE")"
  if day_one_app_is_satisfied; then
    printf '| %s | PASS — %s |\n' "$label" "$result" >> "$STATE_DIR/verification.md"
  else
    printf '| %s | FAIL — %s |\n' "$label" "$DAY_ONE_APP_REASON" >> "$STATE_DIR/verification.md"
    VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
    phase_gate_failed "$label"
  fi
}
