#!/usr/bin/env bash
# Configuration choices shared by the wizard and runner. No writes on load.

configuration_load_choices() {
  DOTFILES_VERSIONING="${DOTFILES_VERSIONING:-$(state_value dotfiles-versioning)}"
  SHELL_CHOICE="${SHELL_CHOICE:-$(state_value shell-choice)}"
  PROMPT_CHOICE="${PROMPT_CHOICE:-$(state_value prompt-choice)}"
  # Only recorded pre-choice setups inherit the old contract. A fresh --yes
  # invocation is not consent to install chezmoi, Homebrew zsh or Starship.
  if [[ -z "$(state_value configuration-schema)" ]] && {
    [[ "$(state_value dotfiles-versioning)" =~ ^(git|local)$ ]] || [[ -f "$COMPLETED_DIR/05" && -z "$(state_value dotfiles-versioning)" ]];
  }; then
    DOTFILES_VERSIONING="${DOTFILES_VERSIONING:-git}"
    SHELL_CHOICE="${SHELL_CHOICE:-homebrew}"
    PROMPT_CHOICE="${PROMPT_CHOICE:-starship}"
  fi
}

configuration_validate_choices() {
  case "${DOTFILES_VERSIONING:-}" in none|local|git) ;; *)
    err 'Choose --dotfiles-versioning none, local, or git (no configuration manager is preselected).'; return 2 ;; esac
  case "${SHELL_CHOICE:-}" in keep|apple|homebrew) ;; *)
    err 'Choose --shell keep, apple, or homebrew.'; return 2 ;; esac
  case "${PROMPT_CHOICE:-}" in none|starship) ;; *)
    err 'Choose --prompt none or starship.'; return 2 ;; esac
  if [[ -n "${DOTFILES_REPO:-}" && "$DOTFILES_VERSIONING" != git ]]; then
    err '--dotfiles-repo requires --dotfiles-versioning git.'; return 2
  fi
}

uses_chezmoi() { [[ "${DOTFILES_VERSIONING:-}" == git || "${DOTFILES_VERSIONING:-}" == local ]]; }
uses_starship() { [[ "${PROMPT_CHOICE:-}" == starship ]]; }

# Do not execute chezmoi to inspect an unmanaged choice: even inspection can
# open its state. Existing/custom ownership needs a deliberate manual handoff.
configuration_unmanaged_preflight() {
  local candidate
  uses_chezmoi && return 0
  for candidate in "$HOME/.local/share/chezmoi" "${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi" \
    "$HOME/.config/chezmoi" "${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"; do
    if [[ -e "$candidate" || -L "$candidate" ]]; then
      err "Existing chezmoi configuration/source needs an ownership review: $candidate"
      warn 'Unmanaged mode does not detach, delete or overwrite a source. Back it up and complete the manual ownership handoff first.'
      return 10
    fi
  done
  if [[ -n "${CHEZMOI_SOURCE_DIR:-}${CHEZMOI_CONFIG_FILE:-}" ]]; then
    err 'A custom chezmoi environment is present; resolve configuration ownership manually first.'; return 10
  fi
}

configuration_login_shell() {
  dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '$1 == "UserShell:" {print $2}'
}

configuration_shell_target() {
  case "${SHELL_CHOICE:-}" in
    apple) printf '/bin/zsh\n' ;;
    homebrew) printf '/opt/homebrew/bin/zsh\n' ;;
    keep) configuration_login_shell ;;
    *) return 2 ;;
  esac
}

verify_configuration_login_shell() {
  local target current
  target="$(configuration_shell_target)" || return 1
  current="$(configuration_login_shell)" || return 1
  [[ -n "$target" && "$current" == "$target" && -x "$target" && "${target##*/}" == zsh ]]
}
