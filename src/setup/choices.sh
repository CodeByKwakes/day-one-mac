#!/usr/bin/env bash
# Load and validate saved or supplied setup choices; consumes the runner context.
# Sourced by setup.sh after state, platform and ownership helpers.

load_or_choose_selections() {
  local saved_track saved_track_schema
  folders_load_choices
  if [[ -n "$FOLDER_LAYOUT" || -n "$GHQ_CHOICE" || -n "$FOLDER_GHQ_ROOT" ]]; then
    folders_validate_choices || return $?
  fi
  if [[ -z "$TRACK" ]]; then
    saved_track="$(state_value track)"
    saved_track_schema="$(state_value track-schema-version)"
    if [[ -n "$saved_track" && "$saved_track_schema" != "$TRACK_SCHEMA_VERSION" ]]; then
      err "The saved track predates the current track numbering and cannot be reinterpreted safely."
      err "Choose it again explicitly: --track 1 (GitHub), 2 (Azure), 3 (both), or 4 (custom)."
      exit 2
    fi
    TRACK="$saved_track"
  fi
  [[ -n "$STACK" ]] || STACK="$(state_value stack)"
  [[ -n "$GIT_NAME" ]] || GIT_NAME="$(state_value git-name)"
  [[ -n "$GIT_EMAIL" ]] || GIT_EMAIL="$(state_value git-email)"
  [[ -n "$PRESET" ]] || PRESET="$(state_value preset)"
  DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-$(state_value deployment-mode)}"
  DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-personal}"
  WORKSTATION_POLICY="${WORKSTATION_POLICY:-$(state_value workstation-policy)}"
  [[ "$DEPLOYMENT_MODE" =~ ^(personal|managed)$ ]] || { err 'deployment must be personal or managed'; return 2; }
  PRESET="${PRESET:-recommended-productivity}"
  [[ "$PRESET" =~ ^(core|recommended-productivity)$ ]] || { err "preset must be core or recommended-productivity"; exit 2; }
  [[ -n "$PRIMARY_IDE" ]] || PRIMARY_IDE="$(state_value primary-ide)"
  [[ "$PRESET" != core ]] || PRIMARY_IDE=other
  if [[ "$DOTFILES_EXPLICIT" != 1 && -z "$DOTFILES_REPO" ]]; then
    DOTFILES_REPO="$(state_value dotfiles-repo)"
  fi
  configuration_load_choices
  [[ -n "$MACOS_SETTINGS_PLAN" ]] || MACOS_SETTINGS_PLAN="$(state_value macos-settings-plan)"
  [[ -n "$AUTH_MODE" ]] || AUTH_MODE="$(state_value auth-mode)"
  # Setups saved before this choice existed all used the 1Password agent.
  [[ -n "$TRACK" ]] || TRACK="$(ask 'Hosting track: 1 GitHub, 2 Azure, 3 both, 4 none of the above' 1 '^[1234]$')"
  if [[ -z "$AUTH_MODE" ]]; then
    if [[ "$TRACK" == 4 ]]; then AUTH_MODE=https; else AUTH_MODE=1password; fi
  fi
  [[ -n "$STACK" ]] || STACK="$(ask 'Stack: node, python, or both' both '^(node|python|both)$')"
  if [[ -z "$PRIMARY_IDE" ]]; then
    if [[ "$DRY_RUN" == 1 || ! -t 0 ]]; then PRIMARY_IDE=vscode
    else PRIMARY_IDE="$(ask 'Use VS Code as the primary IDE? Enter vscode or other' vscode '^(vscode|other)$')"
    fi
  fi
  if [[ -z "$MACOS_SETTINGS_PLAN" ]]; then
    if [[ -n "$REQUESTED_PHASES" ]]; then MACOS_SETTINGS_PLAN=skip
    else MACOS_SETTINGS_PLAN="$(ask 'Early macOS settings: configure or skip' configure '^(configure|skip)$')"
    fi
  fi
  [[ "$TRACK" =~ ^[1234]$ ]] || { err "track must be 1, 2, 3, or 4"; exit 2; }
  [[ "$STACK" =~ ^(node|python|both)$ ]] || { err "stack must be node, python, or both"; exit 2; }
  [[ "$PRIMARY_IDE" =~ ^(vscode|other)$ ]] || { err "primary IDE must be vscode or other"; exit 2; }
  [[ -z "$DOTFILES_VERSIONING" || "$DOTFILES_VERSIONING" =~ ^(none|git|local)$ ]] || { err "dotfiles versioning must be none, git or local"; exit 2; }
  [[ -z "$SHELL_CHOICE" || "$SHELL_CHOICE" =~ ^(keep|apple|homebrew)$ ]] || { err "shell must be keep, apple or homebrew"; exit 2; }
  [[ -z "$PROMPT_CHOICE" || "$PROMPT_CHOICE" =~ ^(none|starship)$ ]] || { err "prompt must be none or starship"; exit 2; }
  [[ "$MACOS_SETTINGS_PLAN" =~ ^(ask|configure|skip)$ ]] || { err "macOS settings choice must be ask, configure, or skip"; exit 2; }
  [[ "$AUTH_MODE" =~ ^(1password|keychain|external|https)$ ]] || {
    err "auth mode must be 1password, keychain, external, or https"; exit 2; }
  hosting_load_choices
  hosting_validate_choices || exit $?
  if [[ -n "$DOTFILES_REPO" && "$DOTFILES_VERSIONING" != git ]]; then
    err "--dotfiles-repo requires --dotfiles-versioning git"
    exit 2
  fi
}

required_load_recorded_choices() {
  folders_load_choices
  TRACK="${TRACK:-$(state_value track)}"
  STACK="${STACK:-$(state_value stack)}"
  GIT_NAME="${GIT_NAME:-$(state_value git-name)}"
  GIT_EMAIL="${GIT_EMAIL:-$(state_value git-email)}"
  PRESET="${PRESET:-$(state_value preset)}"
  DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-$(state_value deployment-mode)}"
  DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-personal}"
  WORKSTATION_POLICY="${WORKSTATION_POLICY:-$(state_value workstation-policy)}"
  [[ "$DEPLOYMENT_MODE" =~ ^(personal|managed)$ ]] || { err 'deployment must be personal or managed'; return 2; }
  PRESET="${PRESET:-recommended-productivity}"
  PRIMARY_IDE="${PRIMARY_IDE:-$(state_value primary-ide)}"
  [[ -n "$PRIMARY_IDE" ]] || PRIMARY_IDE=vscode
  DOTFILES_REPO="${DOTFILES_REPO:-$(state_value dotfiles-repo)}"
  DOTFILES_VERSIONING="${DOTFILES_VERSIONING:-$(state_value dotfiles-versioning)}"
  configuration_load_choices
  MACOS_SETTINGS_PLAN="${MACOS_SETTINGS_PLAN:-$(state_value macos-settings-plan)}"
  AUTH_MODE="${AUTH_MODE:-$(state_value auth-mode)}"
  [[ -n "$AUTH_MODE" ]] || AUTH_MODE=1password
  hosting_load_choices
  OPTIONAL_MODULES="$(state_value optional-modules)"
}

deployment_preflight() {
  local enrollment policy_args=(--mode "$DEPLOYMENT_MODE")
  [[ -z "$WORKSTATION_POLICY" ]] || policy_args+=(--policy "$WORKSTATION_POLICY")
  if [[ "$DRY_RUN" == 1 ]]; then
    info "Deployment: $DEPLOYMENT_MODE; applicable workstation evidence is required before completion."
    return 0
  fi
  if [[ "$DEPLOYMENT_MODE" == managed ]]; then
    [[ -n "$WORKSTATION_POLICY" && -r "$WORKSTATION_POLICY" ]] || {
      err 'Managed setup needs --policy with an approved policy. See the managed workstation guide.'; return "$EX_MANUAL";
    }
    "$SCRIPT_DIR/../src/operations/workstation-readiness.sh" --preflight "${policy_args[@]}" || return "$EX_MANUAL"
  else
    enrollment="$(profiles status -type enrollment 2>/dev/null)" || {
      err 'Management status is unknown. Ask IT to confirm ownership before continuing.'; return "$EX_MANUAL";
    }
    if [[ "$enrollment" == *'MDM enrollment: Yes'* ]]; then
      err 'This Mac is enrolled. Use --deployment managed and its approved policy; local setup must respect management ownership.'
      return "$EX_MANUAL"
    fi
    if [[ "$enrollment" != *'MDM enrollment: No'* ]]; then
      err 'Management status is unknown. Ask IT to confirm ownership before continuing.'
      return "$EX_MANUAL"
    fi
  fi
}
