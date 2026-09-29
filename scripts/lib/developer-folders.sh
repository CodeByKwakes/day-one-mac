#!/usr/bin/env bash
# Shared folder/ghq capability. Runner supplies state, logging and journal hooks.
# No hosting, identity, shell or chezmoi setup is performed here.

folders_load_choices() {
  FOLDER_LAYOUT="${FOLDER_LAYOUT:-$(state_value folder-layout)}"
  GHQ_CHOICE="${GHQ_CHOICE:-$(state_value ghq-choice)}"
  if [[ "${FOLDER_CHOICES_EXPLICIT:-0}" == 0 ]]; then
    FOLDER_GHQ_ROOT="${FOLDER_GHQ_ROOT:-$(state_value folder-ghq-root)}"
  fi
}

folders_validate_choices() {
  case "${FOLDER_LAYOUT:-}" in none|repository|purpose|existing) ;; *)
    err 'Choose --layout none, repository, purpose, or existing. Old completion records are not layout consent.'; return 2 ;; esac
  case "${GHQ_CHOICE:-}" in yes|no) ;; *) err 'Choose --ghq yes or no; ghq is opt-in.'; return 2 ;; esac
  if [[ "$GHQ_CHOICE" == yes && "$FOLDER_LAYOUT" == existing ]]; then
    [[ "${FOLDER_GHQ_ROOT:-}" == /* && "$FOLDER_GHQ_ROOT" != *[$'\t\r\n']* ]] || {
      err 'Keep existing with ghq needs --ghq-root /absolute/primary/root, after reviewing ghq root --all.'; return 2; }
  elif [[ -n "${FOLDER_GHQ_ROOT:-}" ]]; then
    err '--ghq-root applies only to --layout existing --ghq yes.'; return 2
  fi
}

folders_target_root() {
  case "$FOLDER_LAYOUT" in
    purpose) printf '%s/Developer/Projects\n' "$HOME" ;;
    existing) printf '%s\n' "$FOLDER_GHQ_ROOT" ;;
    *) printf '%s/Developer\n' "$HOME" ;;
  esac
}

folders_paths() {
  printf '%s/Developer\n' "$HOME"
  if [[ "$FOLDER_LAYOUT" == purpose ]]; then
    printf '%s/Developer/%s\n' "$HOME" Projects "$HOME" Sandbox "$HOME" Resources "$HOME" Archive
  fi
}

folders_inspect_paths() {
  local path
  [[ "$HOME" == /* && "$HOME" != *[$'\t\r\n']* ]] || { err 'HOME must be an absolute, single-line path.'; return 11; }
  while IFS= read -r path; do
    day_one_safe_state_path "$path/.folder-check" || return 11
    [[ ! -e "$path" || -d "$path" ]] || { err "Not a directory: $path"; return 11; }
  done < <(folders_paths)
}

folders_git_ready() {
  have git || { err 'Install Git manually first (Apple Command Line Tools or Homebrew).'; return 10; }
  if [[ "$(command -v git)" == /usr/bin/git ]] && ! xcode-select -p >/dev/null 2>&1; then
    err 'Complete Command Line Tools first; no Apple installer was launched.'; return 10
  fi
}

# A project-local Git override must not masquerade as the machine-wide root.
folders_ghq() { (cd / && ghq "$@"); }

# Only an unambiguous, unmanaged global configuration may receive a new root.
# Existing/multi-root/URL-specific/environment-owned configuration is never rewritten.
folders_ghq_preflight() {
  local roots root target config_keys source_path
  FOLDERS_WRITE_ROOT=0
  [[ "$GHQ_CHOICE" == yes ]] || return 0
  folders_git_ready || return $?
  target="$(folders_target_root)"
  if have ghq; then
    roots="$(folders_ghq root --all 2>/dev/null)" || { err 'Cannot inspect ghq roots.'; return 11; }
    info "Existing effective ghq roots: $roots"
    if [[ "$FOLDER_LAYOUT" == existing ]]; then
      [[ "$(folders_ghq root 2>/dev/null)" == "$target" ]] || {
        err 'Confirmed primary root differs from ghq root; review all roots and choose again.'; return 10; }
      # External roots may be symlinks or on removable storage: observe, do not create or adopt them.
      [[ -d "$target" ]] || { err 'The confirmed existing root is unavailable; mount it or repair it manually.'; return 10; }
      return 0
    fi
    if [[ "$roots" == "$target" && "$(folders_ghq root 2>/dev/null)" == "$target" ]]; then return 0; fi
    while IFS= read -r root; do
      if [[ -e "$root" || -L "$root" ]]; then
        err 'A different ghq root already exists, including possibly the default ~/ghq. Keep existing or review routing manually.'; return 10
      fi
    done <<<"$roots"
  elif [[ "$FOLDER_LAYOUT" == existing ]]; then
    err 'Keep existing needs an available ghq to inspect its roots. Install it manually, then review ghq root --all.'; return 10
  fi
  [[ -z "${GHQ_ROOT:-}" && -z "${GIT_CONFIG_GLOBAL:-}" && -z "${GIT_CONFIG_SYSTEM:-}" && -z "${GIT_CONFIG_COUNT:-}" ]] || {
    err 'An environment override controls Git/ghq. Keep existing or resolve it manually.'; return 10; }
  # Run outside repositories: a project-local config is not a global placement decision.
  config_keys="$(cd / && git config --includes --list 2>/dev/null)" || { err 'Cannot read Git configuration.'; return 11; }
  if grep -Ei '^(ghq\.|include\.|includeif\.)' <<<"$config_keys" >/dev/null; then
    err 'Existing ghq/include configuration needs manual review; no root was replaced.'; return 10
  fi
  day_one_safe_state_path "$HOME/.gitconfig" || return 10
  [[ ! -e "$HOME/.gitconfig" || -f "$HOME/.gitconfig" ]] || { err 'Global Git config is not a regular file.'; return 10; }
  [[ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/git/config" ]] || {
    err 'XDG Git configuration exists; choose its owner and configure ghq manually.'; return 10; }
  # Do not execute chezmoi during a read-only plan: even managed can open
  # persistent state or load source templates. Presence is a review signal,
  # not proof that any particular target is managed.
  for source_path in "$HOME/.local/share/chezmoi" "${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi" \
      "$HOME/.config/chezmoi" "${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"; do
    if [[ -e "$source_path" || -L "$source_path" ]]; then
      err 'chezmoi source/configuration exists. Review .gitconfig ownership manually; set its ghq root in the owning source, then rerun.'; return 10
    fi
  done
  if compgen -v | grep '^CHEZMOI_' >/dev/null; then
    err 'A chezmoi environment override needs manual ownership review before changing Git configuration.'; return 10
  fi
  FOLDERS_WRITE_ROOT=1
}

folders_plan() {
  local path
  folders_validate_choices || return $?
  folders_inspect_paths || return $?
  info "Developer layout: $FOLDER_LAYOUT; ghq selected: $GHQ_CHOICE"
  while IFS= read -r path; do
    if [[ -d "$path" ]]; then info "Reuse (not adopted): $path"; else info "Create directory: $path"; fi
  done < <(folders_paths)
  info 'No repositories are moved, renamed, cloned or deleted. Other existing folders remain untouched.'
  if [[ "$GHQ_CHOICE" == no ]]; then
    info 'ghq installation and configuration are untouched.'
    return 0
  fi
  info "Selected primary ghq root: $(folders_target_root)"
  folders_ghq_preflight || return $?
  if ! have ghq; then
    info 'ghq is missing; apply needs --install-ghq to approve its Homebrew installation. No Homebrew bootstrap is performed.'
  fi
  [[ "$FOLDERS_WRITE_ROOT" == 0 ]] || info 'Set the previously unconfigured ghq.root in unmanaged ~/.gitconfig (with backup).'
  return 0
}

folders_check() {
  local path roots
  folders_validate_choices || return $?
  folders_inspect_paths || return $?
  while IFS= read -r path; do
    [[ -d "$path" ]] || { err "Missing selected directory: $path"; return 11; }
  done < <(folders_paths)
  if [[ "$GHQ_CHOICE" == yes ]]; then
    folders_git_ready || return $?
    have ghq || { err 'Selected ghq is unavailable.'; return 11; }
    roots="$(folders_ghq root --all 2>/dev/null)" || return 11
    [[ "$(folders_ghq root 2>/dev/null)" == "$(folders_target_root)" ]] || { err 'ghq primary root differs from selection.'; return 11; }
    if [[ "$FOLDER_LAYOUT" != existing && "$roots" != "$(folders_target_root)" ]]; then
      err 'Additional ghq roots need review with Keep existing.'; return 11
    fi
    [[ -d "$(folders_target_root)" ]] || { err 'Selected ghq root is unavailable.'; return 11; }
  fi
  ok 'Selected folders and optional ghq checks passed (no repository or authentication test).'
}

folders_save_choices() {
  # A stopped multi-file write must not combine a new layout with old installation consent.
  save_state_value ghq-choice pending || return $?
  save_state_value folder-layout "$FOLDER_LAYOUT" || return $?
  save_state_value folder-ghq-root "${FOLDER_GHQ_ROOT:-}" || return $?
  save_state_value ghq-choice "$GHQ_CHOICE"
}

folders_apply() {
  local path
  folders_plan || return $?
  for path in "$COMPLETED_DIR/.check" "$ORIGINALS_DIR/.check" "$INSTALL_MANIFEST" "$PATH_MANIFEST" "$LOG_FILE"; do
    day_one_safe_state_path "$path" || return 11
  done
  for path in "$INSTALL_MANIFEST" "$PATH_MANIFEST" "$LOG_FILE" \
      "$STATE_DIR/folder-layout" "$STATE_DIR/ghq-choice" "$STATE_DIR/folder-ghq-root"; do
    day_one_safe_state_path "$path" || return 11
    [[ ! -e "$path" || -f "$path" ]] || { err "Not a regular state file: $path"; return 11; }
  done
  if [[ "$GHQ_CHOICE" == yes ]] && ! have ghq && [[ "$DRY_RUN:${FOLDERS_PHASE_PREPARED:-0}" != 1:1 ]]; then
    [[ "${INSTALL_GHQ:-0}" == 1 ]] || { err 'Install ghq manually or explicitly approve --install-ghq.'; return 10; }
    load_brew || { err 'Homebrew is unavailable. Install it manually before selecting --install-ghq.'; return 10; }
  fi
  # All path/configuration conflicts are inspected before the first mutation.
  # Save intent before execution so interrupted work can resume; this is not completion evidence.
  folders_save_choices || return $?
  if [[ "$GHQ_CHOICE" == yes ]] && ! have ghq && [[ "$DRY_RUN:${FOLDERS_PHASE_PREPARED:-0}" != 1:1 ]]; then
    install_formula ghq || return $?
  fi
  while IFS= read -r path; do create_directory "$path" || return $?; done < <(folders_paths)
  if [[ "$GHQ_CHOICE" == yes && "$FOLDERS_WRITE_ROOT" == 1 ]]; then
    if [[ "$DRY_RUN" != 1 ]]; then record_path_before_write "$HOME/.gitconfig" || return $?; fi
    run git config --global ghq.root "$(folders_target_root)" || return $?
  fi
  [[ "$DRY_RUN" == 1 ]] || folders_check || return $?
  return 0
}
