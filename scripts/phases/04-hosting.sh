#!/usr/bin/env bash
# Sourced phase implementation; shared runner context is supplied by setup.sh.

phase_04() {
  local global_ignore global_ignore_content vscode_cli vscode_command
  local app_id formula ssh_output
  local FOLDERS_PHASE_PREPARED=1
  ui_title '4️⃣' 'Phase 04 — Core tools and hosting'
  info "Guide: $(phase_doc 04)"
  phase_next "required tools and application ownership checks" "Complete the Installation Centre, then rerun Phase 4."
  if ! load_brew; then
    [[ "$DRY_RUN" == 1 ]] || { err "Complete Phase 2 first."; return "$EX_GATE"; }
  fi
  phase_next "saved Git identity" "Complete Phase 1 with a valid Git author name and email, then rerun Phase 4."
  if [[ -z "$GIT_NAME" || ! "$GIT_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
    err "Git name or email is missing; complete Phase 1 first."
    return "$EX_GATE"
  fi
  phase_next "required application ownership" "Rerun the Installation Centre if an application is missing or has changed owner."
  ui_section '📦' 'Required application ownership'
  if [[ "${PRESET:-recommended-productivity}" != core ]]; then
    scan_applications jetbrains-mono-nerd-font raycast visual-studio-code warp || return $?
    if [[ "$DRY_RUN" != 1 ]]; then
      for app_id in jetbrains-mono-nerd-font raycast visual-studio-code warp; do
        verify_application "$app_id" || {
          err 'A required desktop application or font is unavailable.'
          warn 'Rerun the Installation Centre; Phase 4 now performs configuration only.'
          return "$EX_GATE"
        }
      done
    fi
  fi
  phase_step_done "required application ownership verified"

  phase_next "required command-line tools" "Rerun the Installation Centre if a selected formula is missing."
  if [[ "$DRY_RUN" == 1 ]]; then
    info 'would verify every formula selected by the saved track and stack'
  else
    while IFS= read -r formula; do
      [[ -n "$formula" ]] || continue
      if [[ "$formula" == ghq ]] && have ghq; then continue; fi
      brew list --formula "$formula" >/dev/null 2>&1 || {
        err "required formula is missing: $formula"
        return "$EX_GATE"
      }
    done < <(required_formulae)
  fi
  phase_step_done "required command-line tools available"

  phase_next "development folders and Git defaults" "Review Steps 4.2–4.3 and correct the Git identity or ghq root."
  folders_apply || return $?

  if [[ "$DRY_RUN" != 1 ]]; then record_path_before_write "$HOME/.gitconfig"; fi
  run git config --global user.name "$GIT_NAME"
  run git config --global user.email "$GIT_EMAIL"
  run git config --global init.defaultBranch main
  run git config --global pull.ff only
  run git config --global fetch.prune true
  run git config --global push.autoSetupRemote true
  run git config --global alias.lg "log --color --graph --decorate --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset %C(bold blue)<%an>%Creset' --abbrev-commit"
  global_ignore="$HOME/.gitignore_global"
  global_ignore_content=$'# Files created by macOS or temporary terminal editors.\n.DS_Store\n.AppleDouble\n.LSOverride\n._*\n.Trashes\n*.swp\n*.swo\n*~\n'
  if [[ ! -e "$global_ignore" ]]; then
    record_path_before_write "$global_ignore"
    write_text_file "$global_ignore" "$global_ignore_content"
  fi
  run git config --global core.excludesFile "$global_ignore"
  run git config --global merge.conflictStyle zdiff3
  if [[ "$PRIMARY_IDE" == vscode ]]; then
    vscode_cli="$(command -v code 2>/dev/null || true)"
    [[ -x "$vscode_cli" ]] || vscode_cli='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
    if [[ "$DRY_RUN" != 1 && ! -x "$vscode_cli" ]]; then
      err "VS Code was selected as the primary IDE, but its command-line program is unavailable."
      warn "Open VS Code and run 'Shell Command: Install code command in PATH', then rerun Phase 4."
      return "$EX_MANUAL"
    fi
    printf -v vscode_command "'%s'" "$vscode_cli"
    run git config --global core.editor "$vscode_command --wait"
    run git config --global merge.tool vscode
    run git config --global mergetool.vscode.cmd "$vscode_command --wait \"\$MERGED\""
    run git config --global diff.tool vscode
    run git config --global difftool.vscode.cmd "$vscode_command --wait --diff \"\$LOCAL\" \"\$REMOTE\""
    info "VS Code is the selected primary IDE; Git editor, merge and diff integration is configured."
  else
    info "VS Code is not the selected primary IDE; existing Git editor and tool settings were left unchanged."
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    uses_github && print_command gh auth login --git-protocol "$(git_protocol_for_mode)" --web --skip-ssh-key
    uses_azure && print_command az login
    [[ "$GHQ_CHOICE" != yes ]] || print_command ghq root
    return 0
  fi
  folders_check || return $?
  phase_step_done "selected development folders, Git defaults and optional ghq verified"
  phase_next "selected hosting account authentication" "Finish the browser sign-in, then confirm the matching SSH public key is registered with the provider."
  if uses_github; then
    record_path_before_write "$HOME/.config/gh"
    if ! gh auth status >/dev/null 2>&1; then
      warn "GitHub authentication is required for this track."
      # --skip-ssh-key matters: the key already lives in 1Password and was
      # registered in Phase 3. Without the flag, gh offers to generate one when
      # ~/.ssh contains no .pub file and defaults to yes, writing a plaintext
      # ~/.ssh/id_ed25519 and breaking this project's no-private-keys-on-disk
      # guarantee. It also avoids requesting the admin:public_key scope.
      gh auth login --git-protocol "$(git_protocol_for_mode)" --web --skip-ssh-key || return "$EX_MANUAL"
    fi
    run gh config set git_protocol "$(git_protocol_for_mode)"
    # In HTTPS mode gh itself becomes the credential helper, so no token is
    # ever typed or stored by hand.
    [[ "$AUTH_MODE" != https ]] || run gh auth setup-git
  fi
  if uses_azure; then
    record_path_before_write "$HOME/.azure"
    if ! az account show >/dev/null 2>&1; then
      warn "Azure authentication is required for this track."
      az login || return "$EX_MANUAL"
    fi
  fi
  if uses_azure && ! az extension show --name azure-devops >/dev/null 2>&1; then
    run az extension add --name azure-devops
  fi
  if [[ "$AUTH_MODE" == https ]]; then
    # Nothing to reach over SSH; the CLI sign-in above is the authentication.
    info "Auth mode 'https': skipping the SSH reachability tests."
    if uses_azure; then
      have git-credential-manager \
        || warn "Azure DevOps over HTTPS needs Git Credential Manager: brew install --cask git-credential-manager"
      warn "Azure DevOps HTTPS uses a Microsoft Entra ID token or a personal access token that you create and Git stores."
    fi
  else
    if uses_github; then
      ssh_output="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)"
      grep -Fq 'successfully authenticated' <<<"$ssh_output" || {
        err "GitHub did not accept the SSH identity: $ssh_output"; return "$EX_MANUAL"; }
    fi
    if uses_azure; then
      ssh_output="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -T git@ssh.dev.azure.com 2>&1 || true)"
      grep -Fq 'Shell access is not supported' <<<"$ssh_output" || {
        err "Azure DevOps did not accept the SSH identity: $ssh_output"; return "$EX_MANUAL"; }
    fi
  fi
  phase_step_done "selected hosting CLI and Git authentication passed"
  ok "Git and selected hosting services verified"
}
