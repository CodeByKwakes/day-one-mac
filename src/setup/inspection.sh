#!/usr/bin/env bash
# Read-only phase impact and live checks; never records completion or applies setup.
# Sourced by setup.sh after state, platform and ownership helpers.

required_phase_impact() {
  case "$1" in
    01) printf 'Record track, stack and Git identity. Manual: confirm macOS update and verified backup or disposable data.' ;;
    02) printf 'Install/verify Apple developer tools and native Homebrew; update Homebrew. Manual: Apple installer, licence and administrator approval.' ;;
    03) if [[ "$AUTH_MODE" == https ]]; then
          printf 'Require Installation Centre and FileVault; no SSH key or agent configuration for HTTPS. Manual: FileVault recovery method; provider sign-in belongs to Phase 4.'
        else printf 'Require Installation Centre; configure selected %s authentication and SSH; require FileVault. Manual: account/key approval and recovery method.' "$AUTH_MODE"; fi ;;
    04) printf 'Require Installation Centre; configure shared and track-aware provider Git defaults and Developer layout %s; ghq %s; HTTPS helper %s. Verify selected repositories with bounded, noninteractive Git read checks. Optional clone destinations: GitHub %s; Azure %s (none means verify only). Manual: first provider sign-in.' "${FOLDER_LAYOUT:-unselected}" "${GHQ_CHOICE:-unselected}" "${HTTPS_HELPER:-existing}" "${GITHUB_CLONE_DIR:-none}" "${AZURE_CLONE_DIR:-none}" ;;
    05) printf 'Require Installation Centre; configuration owner %s, shell %s, prompt %s. Preserve existing files; review ownership conflicts. Unselected choices block apply; none does not remove existing tools.' "${DOTFILES_VERSIONING:-unselected}" "${SHELL_CHOICE:-unselected}" "${PROMPT_CHOICE:-unselected}" ;;
    06) printf 'Require Installation Centre; install/update %s toolchains (Node LTS via fnm and/or Python via uv); configure pnpm when selected.' "$STACK" ;;
    07) if [[ "$PRESET" == core ]]; then printf 'Not required for core preset.'
        else printf 'Require Installation Centre; create missing VS Code settings; verify launcher and safe AI approval settings. Manual: GUI launcher installation.'; fi ;;
    08)
      printf 'Require Installation Centre; run selected machine checks and WRITE verification.md. '
      case "$DOTFILES_VERSIONING" in
        none) printf 'Create a missing user-owned Brewfile without chezmoi adoption. Manual: verify backups of user-owned configuration and Brewfile.' ;;
        local) printf 'Create/manage a missing Brewfile with chezmoi; no remote required. Manual: review local source and verify its backup.' ;;
        git) printf 'Create/manage a missing Brewfile with chezmoi; verify private remote and push state. Manual: review source and recovery.' ;;
        *) printf 'Select configuration ownership before deciding Brewfile management and recovery checks.' ;;
      esac ;;
  esac
}

required_json_string() {
  local value="$1" char number i
  printf '"'
  for ((i=0; i<${#value}; i++)); do
    char="${value:i:1}"
    case "$char" in
      '"') printf '%s' '\"' ;; \\) printf '%s' "\\\\" ;;
      *) printf -v number '%d' "'$char"
         # Bash 3.2 may report high UTF-8 bytes as negative in byte locales.
         # Only ASCII control characters need escaping; preserve UTF-8 bytes.
         if (( number >= 0 && number < 32 )); then printf '\\u%04x' "$number"; else printf '%s' "$char"; fi ;;
    esac
  done
  printf '"'
}

# A check is deliberately local and non-interactive. No phase_XX function,
# shell startup, chezmoi template, auth client or report writer is called here.
# Only explicit read probes are allowed. A limited probe is never proof that
# its untested manual/network gates passed.
required_check_note() {
  local result="$1" message="$2"
  CHECK_DETAILS="${CHECK_DETAILS}${CHECK_DETAILS:+$'\n'}$result: $message"
  case "$result:$CHECK_RESULT" in
    fail:*) CHECK_RESULT=fail ;;
    manual:pass) CHECK_RESULT=manual ;;
  esac
}

required_check_file() {
  if [[ -f "$1" && -r "$1" ]]; then required_check_note pass "$2 exists"
  else required_check_note fail "$2 is missing or unreadable"; fi
}

required_check_command() {
  if have "$1"; then required_check_note pass "$1 is on the current PATH"
  else required_check_note fail "$1 is missing from the current PATH"; fi
}

required_check_app() {
  # Payload inspection only: do not invoke brew or produce provenance reports.
  local DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled
  if day_one_app_detect "$1" && day_one_app_is_satisfied; then
    required_check_note pass "$1 payload is present"
  else required_check_note fail "$1 payload is missing or has an unexpected identity"; fi
}

check_required_phase() {
  local phase="$1" selected command_name target key component result details
  CHECK_RESULT=pass CHECK_DETAILS=''
  case "$phase" in
    01)
      if [[ -n "$GIT_NAME" && "$GIT_NAME" != *$'\n'* && "$GIT_NAME" != *$'\r'* \
         && "$GIT_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
        required_check_note pass 'Git author choices are populated'
      else required_check_note fail 'Supply a single-line author name and valid email in Phase 1'; fi
      required_check_note manual 'Confirm current macOS update and readable backup/disposable data; saved completion cannot prove either'
      ;;
    02)
      selected="$(xcode-select -p 2>/dev/null || true)"
      if [[ -n "$selected" && -d "$selected" ]]; then
        required_check_note pass 'Apple developer-tools directory is selected'
      else required_check_note fail 'Complete the Apple Command Line Tools installation'; fi
      if [[ -x /opt/homebrew/bin/brew ]]; then required_check_note pass 'Native Homebrew executable exists'
      else required_check_note fail 'Native Homebrew is missing'; fi
      required_check_note manual 'Phase 2 must verify tool compatibility/licence and Homebrew health; no installer or update ran'
      ;;
    03)
      if fdesetup status 2>/dev/null | grep -q 'FileVault is On'; then required_check_note pass 'FileVault is on'
      else required_check_note fail 'FileVault is not confirmed on'; fi
      if [[ "$AUTH_MODE" != https ]]; then required_check_file "$HOME/.ssh/config" 'SSH configuration'; fi
      case "$AUTH_MODE" in
        keychain)
          for component in github azure; do
            case "$component" in
              github) uses_github || continue; key="$HOME/.ssh/id_ed25519" ;;
              azure) uses_azure || continue; key="$HOME/.ssh/id_rsa_azure" ;;
            esac
            if [[ "$(keychain_key_protection "$key")" == encrypted ]]; then
              required_check_note pass "$component key is passphrase protected"
            else required_check_note fail "$component key is missing, unprotected or unverifiable"; fi
          done ;;
        1password) required_check_app 1password; required_check_command op ;;
      esac
      if [[ "$AUTH_MODE" == https ]]; then
        required_check_note pass 'HTTPS selected; SSH key and agent checks are not required'
        required_check_note manual 'FileVault recovery-key custody needs manual confirmation; HTTPS provider sessions are checked separately in Phase 4'
      else
        required_check_note manual 'Agent access, provider registration, signing and recovery-key custody need interactive verification'
      fi
      ;;
    04)
      while IFS= read -r command_name; do
        case "$command_name" in ripgrep) command_name=rg ;; azure-cli) command_name=az ;; esac
        required_check_command "$command_name"
      done < <(required_formulae)
      # Guard the Apple Git shim on fresh Macs: do not trigger CLT installation.
      selected="$(xcode-select -p 2>/dev/null || true)"
      if [[ -n "$selected" && -d "$selected" ]] && have git; then
        for key in user.name user.email; do
          case "$key" in user.name) target="$GIT_NAME" ;; user.email) target="$GIT_EMAIL" ;; esac
          if [[ -n "$target" && "$(git config --global --get "$key" 2>/dev/null || true)" == "$target" ]]; then
            required_check_note pass "Git $key matches selection"
          else required_check_note fail "Git $key is missing or differs from selection"; fi
        done
        while IFS=$'\t' read -r key target; do
          if [[ "$(git config --global --get "$key" 2>/dev/null || true)" == "$target" ]]; then
            required_check_note pass "Git $key matches the selected track"
          else required_check_note fail "Git $key is missing or differs from the selected track"; fi
        done < <(track_git_settings)
      else required_check_note fail 'Git configuration cannot be checked until developer tools are ready'; fi
      if details="$(folders_check 2>&1)"; then required_check_note pass "$details"
      else required_check_note fail "$details"; fi
      while IFS= read -r component; do required_check_app "$component"; done < <(required_application_ids)
      if [[ "$AUTH_MODE" == https ]]; then
        required_check_note manual 'HTTPS hosting sessions and full Git defaults require Phase 4; no login or network probe ran'
      else
        required_check_note manual 'Hosting sessions, SSH reachability and full Git defaults require Phase 4; no login or network probe ran'
      fi
      while IFS= read -r component; do
        target="$(hosting_repo_url "$component")"
        if [[ -n "$target" ]]; then required_check_note manual "$component Git access needs Phase 4's live repository check"
        else required_check_note fail "$component verification repository is missing (--$component-repo)"; fi
      done < <(hosting_provider_ids)
      while IFS= read -r component; do
        target="$(hosting_clone_dir "$component")"
        [[ "$target" != none ]] || continue
        if [[ -n "$selected" && -d "$selected" ]] && have git && hosting_clone_matches "$target" "$(hosting_repo_url "$component")"; then
          required_check_note pass "$component selected clone exists with the expected origin"
        else
          required_check_note fail "$component selected clone is missing or does not match; rerun Phase 4 or choose none"
        fi
      done < <(hosting_provider_ids)
      ;;
    05)
      if ! details="$(configuration_validate_choices 2>&1)"; then required_check_note fail "$details"; fi
      if uses_chezmoi; then required_check_command chezmoi
      else required_check_note pass 'chezmoi not selected; no source or remote is required'
        if ! details="$(configuration_unmanaged_preflight 2>&1)"; then required_check_note manual "$details"; fi
      fi
      if uses_starship; then
        required_check_command starship
        required_check_file "$HOME/.config/starship.toml" 'Starship configuration'
      else required_check_note pass 'Starship not selected; existing prompt is not changed'; fi
      for target in .zprofile .zshrc .gitconfig .gitignore_global .config/zsh/path.zsh .config/zsh/aliases.zsh; do
        required_check_file "$HOME/$target" "$target"
      done
      target="$(configuration_shell_target 2>/dev/null || true)"
      if [[ -n "$target" && -x "$target" && "${target##*/}" == zsh ]]; then
        required_check_note pass 'Selected zsh executable exists'
        if [[ "$(configuration_login_shell 2>/dev/null || true)" != "$target" ]]; then required_check_note manual 'Selected login shell is not active'; fi
      else required_check_note fail 'Selected shell is unavailable or is not zsh; manual shell setup is needed'; fi
      if [[ -x "$HOME/.local/bin/day-one-mac" ]]; then required_check_note pass 'Portable launcher exists'
      else required_check_note fail 'Portable launcher is missing'; fi
      required_check_note manual 'Review selected configuration ownership and clean-shell behaviour in Phase 5; checks do not render templates or execute startup files'
      ;;
    06)
      if uses_node; then
        for command_name in fnm node npm pnpm; do required_check_command "$command_name"; done
        [[ -d "$HOME/Library/pnpm" ]] || required_check_note fail 'pnpm home directory is missing'
      fi
      uses_python && required_check_command uv
      required_check_note manual 'Verify selected runtime versions in Phase 6; command presence does not prove Node LTS or uv-managed Python is ready'
      ;;
    07)
      if [[ "$PRESET" == core ]]; then
        CHECK_RESULT=not-required; CHECK_DETAILS='VS Code is not required for the core preset'
      else
        required_check_app visual-studio-code
        required_check_command code
        required_check_file "$HOME/Library/Application Support/Code/User/settings.json" 'VS Code settings'
        required_check_note manual 'Verify effective auto-approval settings and GUI launch in Phase 7; no editor process was launched'
      fi
      ;;
    08)
      result=pass details=''
      for component in 01 02 03 04 05 06 07; do
        check_required_phase "$component"
        details="${details}${details:+$'\n'}$component $CHECK_RESULT: $CHECK_DETAILS"
        if [[ "$CHECK_RESULT" == fail ]]; then result=fail
        elif [[ "$CHECK_RESULT" == manual && "$result" == pass ]]; then result=manual; fi
      done
      CHECK_RESULT="$result" CHECK_DETAILS="$details"
      if "$SCRIPT_DIR/../src/operations/verify.sh" >/dev/null 2>&1; then required_check_note pass 'Runtime verification passed'
      else required_check_note fail 'Runtime verification failed; run day-one-mac verify'; fi
      required_check_file "$HOME/Brewfile" 'Brewfile'
      case "$DOTFILES_VERSIONING" in
        none) required_check_note manual 'Review user-owned configuration and Brewfile backup separately; no backup was verified and no report or source was modified' ;;
        local) required_check_note manual 'Review source secrets, local backup and Brewfile management through Phase 8 and a separate backup check; no backup was verified and no report or source was modified' ;;
        git) required_check_note manual 'Phase 8 must verify source secrets, remote privacy/push state and Brewfile management; no report or source was modified' ;;
        *) required_check_note manual 'Select configuration ownership before Phase 8; no report or source was modified' ;;
      esac
      ;;
  esac
  return 0
}

inspect_required_actions() {
  local action="$1" phase recorded checked_at='' first=1 result=0 impact
  [[ "$action" != check ]] || checked_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  if [[ "$JSON_OUTPUT" == 1 ]]; then
    printf '{"schema_version":1,"action":"%s","scope":"local-read-only","checked_at":' "$action"
    if [[ -n "$checked_at" ]]; then required_json_string "$checked_at"; else printf null; fi
    printf ',"selection":{"track":'; required_json_string "$TRACK"
    printf ',"stack":'; required_json_string "$STACK"
    printf ',"folder_layout":'; required_json_string "${FOLDER_LAYOUT:-}"
    printf ',"ghq":'; required_json_string "${GHQ_CHOICE:-}"
    printf ',"ghq_root":'; required_json_string "${FOLDER_GHQ_ROOT:-}"
    printf ',"deployment":'; required_json_string "${DEPLOYMENT_MODE:-personal}"
    printf ',"preset":'; required_json_string "$PRESET"
    printf ',"auth_mode":'; required_json_string "$AUTH_MODE"
    printf ',"https_helper":'; required_json_string "${HTTPS_HELPER:-existing}"
    printf ',"primary_ide":'; required_json_string "$PRIMARY_IDE"
    printf ',"macos_settings":'; required_json_string "$MACOS_SETTINGS_PLAN"
    printf ',"dotfiles_versioning":'; required_json_string "$DOTFILES_VERSIONING"
    printf ',"shell":'; required_json_string "$SHELL_CHOICE"
    printf ',"prompt":'; required_json_string "$PROMPT_CHOICE"
    printf '},"phases":['
  else
    printf 'Required setup %s — local read-only inspection\n' "$action"
    printf 'Track: %s | Stack: %s | Preset: %s | Authentication: %s | Dotfiles: %s\n' "$TRACK" "$STACK" "$PRESET" "$AUTH_MODE" "$DOTFILES_VERSIONING"
    printf 'Primary IDE: %s | Early macOS settings: %s\n' "$PRIMARY_IDE" "$MACOS_SETTINGS_PLAN"
    printf 'Shell: %s | Prompt: %s\n' "${SHELL_CHOICE:-unselected}" "${PROMPT_CHOICE:-unselected}"
    printf 'Developer layout: %s | ghq: %s\n' "${FOLDER_LAYOUT:-unselected}" "${GHQ_CHOICE:-unselected}"
    printf 'Recorded completion is not live health. Manual/network/GUI checks are not automated here.\n'
    [[ -z "$checked_at" ]] || printf 'Checked at: %s\n' "$checked_at"
  fi
  for phase in 01 02 03 04 05 06 07 08; do
    required_phase_selected "$phase" || continue
    recorded=pending
    if phase_done "$phase"; then recorded=current
    elif [[ -e "$COMPLETED_DIR/$phase" ]]; then recorded=changed; fi
    CHECK_RESULT=not-checked CHECK_DETAILS=''
    [[ "$action" != check ]] || check_required_phase "$phase"
    if [[ "$CHECK_RESULT" == fail ]]; then result="$EX_GATE"
    elif [[ "$CHECK_RESULT" == manual && "$result" == 0 ]]; then result="$EX_MANUAL"; fi
    impact="$(required_phase_impact "$phase")"
    if [[ "$JSON_OUTPUT" == 1 ]]; then
      [[ "$first" == 1 ]] || printf ','; first=0
      printf '{"phase":"%s","recorded":"%s","live":"%s","impact":' "$phase" "$recorded" "$CHECK_RESULT"
      required_json_string "$impact"
      printf ',"details":'; required_json_string "$CHECK_DETAILS"; printf '}'
    else
      printf '\n%s — %s\n  Recorded: %s | Local check: %s\n' "$phase" "$(phase_title "$phase")" "$recorded" "$CHECK_RESULT"
      if [[ "$action" == plan ]]; then printf '  Apply impact: %s\n  Guide: %s\n' "$impact" "$(phase_doc "$phase")"; fi
      [[ -z "$CHECK_DETAILS" ]] || printf '%s\n' "$CHECK_DETAILS" | sed 's/^/  /'
    fi
  done
  if [[ "$JSON_OUTPUT" == 1 ]]; then printf '],"exit_code":%s}\n' "$result"
  elif [[ "$action" == plan ]]; then
    printf '\nPlan only: nothing saved or executed. Apply the same selection flags explicitly.\n'
    printf 'All-phase apply also runs the optional macOS settings checkpoint after 01 and the Installation Centre after 02.\n'
    printf 'Phases 03–08 can run the Installation Centre automatically when it is not current.\n'
  fi
  return "$result"
}
