#!/usr/bin/env bash
# Sourced phase implementation; shared runner context is supplied by setup.sh.

# Switch the login shell to the selected Apple or Homebrew zsh.
#
# This is the one place Day One Mac changes a macOS account setting, and it is
# the one change that can lock you out of a working login shell, so it is
# deliberately cautious: the binary must exist and actually run, /etc/shells is
# only appended to (never rewritten), and the user confirms before either sudo
# or chsh. Recovery is always `chsh -s /bin/zsh`.
switch_login_shell_to_homebrew_zsh() {
  local target current verified prefix
  prefix="$(brew --prefix 2>/dev/null || printf '/opt/homebrew')"
  target="$prefix/bin/zsh"
  [[ "${SHELL_CHOICE:-homebrew}" != apple ]] || target=/bin/zsh
  if [[ "${SHELL_CHOICE:-homebrew}" == keep ]]; then
    info 'Keeping the current login shell; no /etc/shells or chsh change requested.'
    return 0
  fi

  if [[ ! -x "$target" ]]; then
    err "Selected zsh is not installed at $target; the login-shell gate cannot pass."
    warn "Rerun the Installation Centre to install it, then rerun Phase 5."
    return "$EX_GATE"
  fi
  # Never point a login shell at something that cannot start.
  if ! "$target" -c 'exit 0' >/dev/null 2>&1; then
    err "$target did not run; refusing to make it your login shell."
    return "$EX_GATE"
  fi

  # Directory Services can be temporarily unavailable on a newly provisioned
  # or company-managed Mac. An unreadable current value is informational, not
  # permission to abort the phase; every later message already handles
  # `unknown`, and chsh remains explicitly confirmed.
  current="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}' || true)"
  [[ "$current" == "$target" ]] \
    && info "login shell is already $target" \
    || info "Current login shell: ${current:-unknown}"
  info "Selected zsh: $target ($("$target" --version 2>/dev/null))"
  # State the recovery path before anything changes, not just before chsh:
  # the /etc/shells step can fail, and the user should already know the way out.
  warn "Changing your login shell affects every new terminal."
  if [[ "$target" != /bin/zsh ]]; then
    warn "If Homebrew zsh is ever removed, recover with: chsh -s /bin/zsh"
  fi

  if [[ "$DRY_RUN" == 1 ]]; then
    grep -Fqx "$target" /etc/shells 2>/dev/null || print_command sudo tee -a /etc/shells
    print_command chsh -s "$target"
    return 0
  fi

  if ! grep -Fqx "$target" /etc/shells 2>/dev/null; then
    warn "$target must be listed in /etc/shells before it can be a login shell."
    warn "This is the only step in Day One Mac that needs sudo; it appends one line."
    confirm "Append $target to /etc/shells with sudo?" || {
      warn "Left /etc/shells unchanged; the login shell was not switched."
      return "$EX_MANUAL"
    }
    record_path_before_write /etc/shells
    printf '%s\n' "$target" | sudo tee -a /etc/shells >/dev/null || {
      err "Could not write /etc/shells; the login shell was not switched."
      return "$EX_GATE"
    }
    ok "registered $target in /etc/shells"
  fi

  if [[ "$current" == "$target" ]]; then
    ok "gate: Directory Services login shell is $target"
    return 0
  fi

  confirm "Make $target your login shell now?" || {
    info "Login shell left as ${current:-unknown}."
    return "$EX_MANUAL"
  }
  save_state_value previous-login-shell "${current:-/bin/zsh}"
  if chsh -s "$target"; then
    ok "login shell changed to $target"
    info "Open a new terminal for it to take effect."
  else
    err "chsh did not complete; your login shell is unchanged (${current:-unknown})."
    return "$EX_GATE"
  fi

  verified="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}' || true)"
  if [[ "$verified" != "$target" ]]; then
    err "Directory Services reports ${verified:-unknown}, not the required login shell $target."
    warn "Open System Settings → Users & Groups → your account → Advanced Options only if chsh repeatedly fails."
    return "$EX_GATE"
  fi
  ok "gate: Directory Services login shell is $target"
  return 0
}

migrate_legacy_managed_launcher() {
  local target="$HOME/.local/bin/day-one-mac"
  local source_root source_entry relative backup_root backup_entry

  if ! chezmoi managed -p absolute 2>/dev/null | grep -Fqx "$target"; then
    return 0
  fi

  info "migrating a launcher managed by an earlier Day One Mac installation"
  info "the standalone runtime now owns $target; the live command will be preserved"
  if [[ "$DRY_RUN" == 1 ]]; then
    print_command chezmoi forget "$target"
    return 0
  fi

  source_root="$(chezmoi source-path)"
  source_entry="$(chezmoi source-path "$target")"
  [[ -n "$source_root" && -e "$source_entry" ]] || {
    err "Could not locate the earlier launcher in the chezmoi source."
    return "$EX_GATE"
  }
  relative="${source_entry#"$source_root"/}"
  backup_root="$STATE_DIR/migrations/phase-05-standalone-launcher"
  backup_entry="$backup_root/source/$relative"
  ensure_state
  if [[ ! -e "$backup_entry" ]]; then
    mkdir -p "$(dirname "$backup_entry")"
    ditto "$source_entry" "$backup_entry"
    printf '%s\n' \
      "Earlier source: $source_entry" \
      "Preserved target: $target" \
      "Migrated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      > "$backup_root/README.txt"
    chmod 600 "$backup_entry" "$backup_root/README.txt"
  fi

  run chezmoi forget "$target"
  [[ -x "$target" ]] || {
    err "chezmoi migration unexpectedly removed the live launcher: $target"
    return "$EX_GATE"
  }
  if chezmoi managed -p absolute 2>/dev/null | grep -Fqx "$target"; then
    err "chezmoi still reports the standalone launcher as managed."
    return "$EX_GATE"
  fi
  ok "earlier launcher removed from chezmoi; standalone runtime remains installed"
  info "migration backup: $backup_root"
}

migrate_legacy_gitconfig_source() {
  local target="$HOME/.gitconfig"
  local source_root source_entry relative backup_root backup_entry key live_value source_value
  local keys needs_update=0

  if ! chezmoi managed -p absolute 2>/dev/null | grep -Fqx "$target"; then
    return 0
  fi
  source_root="$(chezmoi source-path)"
  source_entry="$(chezmoi source-path "$target")"
  [[ -n "$source_root" && -e "$source_entry" ]] || return 0

  # ghq roots belong to the folder capability/user source; never flatten multiple roots.
  keys=$'user.name\nuser.email\ninit.defaultBranch\npull.ff\nfetch.prune\npush.autoSetupRemote\nalias.lg\ncore.excludesFile\nmerge.conflictStyle'
  if [[ "$PRIMARY_IDE" == vscode ]]; then
    keys+=$'\ncore.editor\nmerge.tool\nmergetool.vscode.cmd\ndiff.tool\ndifftool.vscode.cmd'
  fi
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    live_value="$(git config --global --get "$key" 2>/dev/null || true)"
    [[ -n "$live_value" ]] || continue
    source_value="$(git config --file "$source_entry" --get "$key" 2>/dev/null || true)"
    [[ "$source_value" == "$live_value" ]] || needs_update=1
  done <<<"$keys"
  [[ "$needs_update" == 1 ]] || return 0

  case "$source_entry" in
    *.tmpl)
      err "The existing ~/.gitconfig source is a template and needs a reviewed manual merge."
      warn "Run 'chezmoi edit ~/.gitconfig', add the Phase 4 Git settings shown in the guide, save, then rerun Phase 5."
      return "$EX_MANUAL"
      ;;
  esac

  info "merging the reviewed Phase 4 Git settings into the earlier chezmoi source"
  if [[ "$DRY_RUN" == 1 ]]; then
    info "would preserve unrelated source settings and add only the current Day One Mac Git keys"
    return 0
  fi

  relative="${source_entry#"$source_root"/}"
  backup_root="$STATE_DIR/migrations/phase-05-gitconfig"
  backup_entry="$backup_root/source/$relative"
  ensure_state
  if [[ ! -e "$backup_entry" ]]; then
    mkdir -p "$(dirname "$backup_entry")"
    ditto "$source_entry" "$backup_entry"
    printf '%s\n' \
      "Earlier source: $source_entry" \
      "Preserved target: $target" \
      "Migrated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      > "$backup_root/README.txt"
    chmod 600 "$backup_entry" "$backup_root/README.txt"
  fi
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    live_value="$(git config --global --get "$key" 2>/dev/null || true)"
    [[ -n "$live_value" ]] || continue
    git config --file "$source_entry" "$key" "$live_value"
  done <<<"$keys"
  ok "earlier ~/.gitconfig source updated without applying its stale version"
  info "migration backup: $backup_root"
}

# Phase gates must remain terminal-only even when the user has configured a
# graphical diff program. chezmoi's global --use-builtin-diff switch preserves
# the active source, template data, destination and persistent state while
# bypassing only diff.command.
chezmoi_text_diff() {
  chezmoi --use-builtin-diff diff --no-pager
}

chezmoi_config_has_tool() {
  local config="$1" tool="$2"
  [[ -f "$config" ]] || return 1
  grep -Eq "^[[:space:]]*\\[${tool}\\][[:space:]]*(#.*)?$|^[[:space:]]*${tool}([.]command)?[[:space:]]*=" "$config"
}

chezmoi_vscode_diff_block() {
  printf '%s\n' \
    '# Day One Mac: open reviewed dotfile comparisons in VS Code.' \
    '[diff]' \
    'command = "code"' \
    'args = ["--wait", "--diff"]'
}

chezmoi_vscode_merge_block() {
  printf '%s\n' \
    '# Day One Mac: use VS Code'"'"'s three-way merge editor.' \
    '[merge]' \
    'command = "bash"' \
    'args = [' \
    '  "-c",' \
    '  "cp {{ .Target | quote }} {{ printf \"%s.base\" .Target | quote }} && code --new-window --wait --merge {{ .Destination | quote }} {{ .Target | quote }} {{ printf \"%s.base\" .Target | quote }} {{ .Source | quote }}",' \
    ']'
}

configure_chezmoi_vscode_tools() {
  local config="$1" content missing="" addition=""
  [[ "$PRIMARY_IDE" == vscode ]] || return 0

  if chezmoi_config_has_tool "$config" diff; then
    info "preserving the existing chezmoi diff tool in $config"
  else
    missing="diff"
    addition+=$'\n\n'"$(chezmoi_vscode_diff_block)"$'\n'
  fi
  if chezmoi_config_has_tool "$config" merge; then
    info "preserving the existing chezmoi merge tool in $config"
  else
    missing="${missing}${missing:+ and }merge"
    addition+=$'\n'"$(chezmoi_vscode_merge_block)"$'\n'
  fi
  [[ -n "$missing" ]] || return 0

  if [[ "$DRY_RUN" == 1 ]]; then
    info "would add the official VS Code chezmoi $missing configuration to $config"
    return 0
  fi
  if ! command -v code >/dev/null 2>&1; then
    warn "VS Code is selected, but its 'code' command is not available yet."
    warn "Open VS Code, run 'Shell Command: Install code command in PATH', then rerun Phase 5."
    return "$EX_MANUAL"
  fi
  confirm "Configure VS Code as the missing chezmoi $missing tool?" || {
    warn "VS Code chezmoi integration was left unchanged. You can add it later with 'chezmoi edit-config'."
    return 0
  }
  content="$(cat "$config")"
  write_text_file "$config" "${content}${addition}"
  ok "VS Code configured for chezmoi $missing review"
}

# Check existing startup redirection before initialization, migration or adoption.
# This deliberately does not source user configuration just to inspect it.
phase_05_shell_preflight() {
  if [[ -e "$HOME/.zshenv" ]] && grep -Eq '(^|[[:space:]])(export[[:space:]]+)?ZDOTDIR=|(^|[[:space:]])unsetopt[[:space:]]+.*RCS' "$HOME/.zshenv"; then
    err "~/.zshenv changes ZDOTDIR or disables Zsh startup files, so Day One Mac cannot verify the managed shell safely."
    warn "Leave the existing layout intact and review it with its configuration owner before retrying Phase 5."
    return "$EX_MANUAL"
  fi
  return 0
}

phase_05_configuration_preflight() {
  local target path
  configuration_validate_choices || return $?
  configuration_unmanaged_preflight || return $?
  target="$(configuration_shell_target 2>/dev/null || true)"
  if [[ "$SHELL_CHOICE" == keep && ( -z "$target" || "${target##*/}" != zsh || ! -x "$target" ) ]]; then
    err 'Keep-shell requires a readable zsh login-shell setting. Other shells need a manual setup; no shell files were changed.'
    return "$EX_MANUAL"
  fi
  # Reject redirects before even creating a missing sibling file. Other
  # configuration managers commonly own startup files through symlinks.
  for path in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.config/zsh/path.zsh" "$HOME/.config/zsh/aliases.zsh"; do
    day_one_safe_state_path "$path" || return "$EX_MANUAL"
    [[ ! -e "$path" || -f "$path" ]] || { err "Not a regular shell file: $path"; return "$EX_MANUAL"; }
  done
  if uses_starship; then day_one_safe_state_path "$HOME/.config/starship.toml" || return "$EX_MANUAL"; fi
  phase_05_shell_preflight
}

phase_05() {
  local chezmoi_config chezmoi_content escaped_email escaped_name managed_target
  local existing_managed_source=0 starship_config starship_content starship_created=0 chezmoi_source_dir
  local runner_wrapper applications_case optional_case remove_case shell_status_case legacy_runner legacy_runner_content
  local legacy_runner_updated=0 zprofile zshrc zsh_path zsh_aliases bootstrap_zsh_path global_ignore
  local zsh_config_dir zsh_path_file zsh_aliases_file ssh_config ssh_config_created=0 homebrew_zsh clean_shell_check compaudit_output
  ui_title '5️⃣' 'Phase 05 — Configuration ownership, shell and prompt'
  info "Guide: $(phase_doc 05)"
  phase_next "existing shell compatibility" "Review custom Zsh startup redirection with its owner before adopting files."
  phase_05_configuration_preflight || return $?
  if uses_chezmoi; then
  phase_next "chezmoi command" "Complete Phase 4 so chezmoi is installed, then rerun Phase 5."
  if ! have chezmoi; then
    [[ "$DRY_RUN" == 1 ]] || { err "chezmoi is missing; complete Phase 4."; return "$EX_GATE"; }
  fi
  phase_next "chezmoi source review" "Review every path in the existing source and its full chezmoi diff before approving apply."
  if chezmoi source-path >/dev/null 2>&1 \
     && [[ -n "$(chezmoi managed 2>/dev/null || true)" ]]; then
    existing_managed_source=1
  fi
  # `chezmoi source-path` with no target only resolves and prints the configured
  # source directory: it exits 0 even when that directory does not exist. Using
  # its status as an existence test meant that on any Mac where chezmoi is
  # installed — which Phase 4 guarantees — `chezmoi init` was never run for a
  # brand-new source. Test the directory itself.
  chezmoi_source_dir="$(chezmoi source-path 2>/dev/null || true)"
  if [[ -z "$chezmoi_source_dir" || ! -d "$chezmoi_source_dir" ]]; then
    if [[ -n "$DOTFILES_REPO" ]]; then run chezmoi init "$DOTFILES_REPO"
    else
      run chezmoi init
    fi
    [[ -n "$DOTFILES_REPO" ]] && existing_managed_source=1
  fi
  # Configure the selected editor before reviewing or applying an existing
  # source. If apply encounters a conflict, its merge option is then already
  # backed by the reviewed VS Code three-way merge command.
  chezmoi_config="$HOME/.config/chezmoi/chezmoi.toml"
  if [[ ! -e "$chezmoi_config" ]]; then
    create_directory "$HOME/.config"
    create_directory "$HOME/.config/chezmoi"
    escaped_name="$(toml_escape "$GIT_NAME")"
    escaped_email="$(toml_escape "$GIT_EMAIL")"
    printf -v chezmoi_content \
      '[data]\ntrack = "%s"\nstack = "%s"\nname = "%s"\nemail = "%s"\n' \
      "$(track_value)" "$STACK" "$escaped_name" "$escaped_email"
    if [[ "$PRIMARY_IDE" == vscode ]]; then
      chezmoi_content=$'[edit]\ncommand = "code"\nargs = ["--wait"]\n\n'"$(chezmoi_vscode_diff_block)"$'\n\n'"$(chezmoi_vscode_merge_block)"$'\n\n'"$chezmoi_content"
    fi
    write_text_file "$chezmoi_config" "$chezmoi_content"
  fi
  configure_chezmoi_vscode_tools "$chezmoi_config" || return $?
  runner_wrapper="$HOME/.local/bin/day-one-mac"
  migrate_legacy_managed_launcher || return $?
  migrate_legacy_gitconfig_source || return $?
  if [[ "$existing_managed_source" == 1 ]]; then
    if [[ "$DRY_RUN" == 1 ]]; then
      print_command chezmoi --use-builtin-diff diff --no-pager
      print_command chezmoi apply
    elif [[ -n "$(chezmoi_text_diff)" ]]; then
      chezmoi_text_diff
      confirm "Apply the reviewed existing dotfiles source?" || return "$EX_MANUAL"
      record_managed_targets_before_apply || return $?
      run chezmoi apply
    else
      ok "existing dotfiles source already matches its targets"
    fi
  fi
  phase_step_done "chezmoi source initialised and any existing-source diff reviewed"
  else
    info 'Unmanaged configuration selected: no chezmoi initialization, apply, adoption or remote checks.'
    runner_wrapper="$HOME/.local/bin/day-one-mac"
  fi
  # An explicitly reviewed apply may have changed .zshenv; recheck before
  # creating or adopting the standard shell files as well.
  phase_05_configuration_preflight || return $?
  phase_next "selected shell, prompt and portable command files" "Complete the selected branches in Steps 5.2–5.7 and merge any existing file instead of overwriting it blindly."
  starship_config="$HOME/.config/starship.toml"
  starship_content=$'add_newline = false\ncommand_timeout = 1000\n\n[character]\nsuccess_symbol = "[❯](bold green)"\nerror_symbol = "[❯](bold red)"\n'
  if uses_starship && [[ ! -e "$starship_config" ]]; then
    create_directory "$HOME/.config"
    write_text_file "$starship_config" "$starship_content"
    starship_created=1
  fi
  zsh_config_dir="$HOME/.config/zsh"
  zsh_path_file="$zsh_config_dir/path.zsh"
  zsh_aliases_file="$zsh_config_dir/aliases.zsh"
  ssh_config="$HOME/.ssh/config"
  global_ignore="$HOME/.gitignore_global"
  zsh_path=$'# Shared PATH setup for login and non-login interactive zsh.\n# Keep this file idempotent: both ~/.zprofile and ~/.zshrc source it.\ntypeset -U path PATH\nif [[ -x /opt/homebrew/bin/brew ]] && {\n  [[ ${HOMEBREW_PREFIX:-} != /opt/homebrew ]] ||\n  [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] ||\n  [[ ":$PATH:" != *":/opt/homebrew/sbin:"* ]]\n}; then\n  eval "$(/opt/homebrew/bin/brew shellenv)"\nfi\n\ncase ":$PATH:" in\n  *":$HOME/.local/bin:"*) ;;\n  *) export PATH="$HOME/.local/bin:$PATH" ;;\nesac\n'
  bootstrap_zsh_path=$'# Day One Mac bootstrap PATH — Phase 5 expands and adopts this file.\ntypeset -U path PATH\ncase ":$PATH:" in\n  *":$HOME/.local/bin:"*) ;;\n  *) export PATH="$HOME/.local/bin:$PATH" ;;\nesac\n'
  if uses_node; then
    zsh_path+=$'\nexport PNPM_HOME="$HOME/Library/pnpm"\ncase ":$PATH:" in\n  *":$PNPM_HOME:"*) ;;\n  *) export PATH="$PNPM_HOME:$PATH" ;;\nesac\n'
  fi
  zsh_aliases=$'# Safe, readable aliases selected by Day One Mac.\n# Keep destructive, publishing, force-push and prune commands explicit.\nif command -v day-one-mac >/dev/null 2>&1; then\n  alias cdayone=\'cd "$(day-one-mac root)"\'\nfi\n\nif command -v git >/dev/null 2>&1; then\n  alias gs=\'git status --short --branch\'\n  alias gd=\'git diff\'\n  alias gds=\'git diff --staged\'\n  alias gl=\'git log --oneline --graph --decorate -20\'\n  alias gremotes=\'git remote --verbose\'\nfi\n\nif command -v chezmoi >/dev/null 2>&1; then\n  alias cm=\'chezmoi\'\n  alias cmstatus=\'chezmoi status\'\n  alias cmdiff=\'chezmoi diff\'\n  alias cmdifftext=\'chezmoi --use-builtin-diff diff --no-pager\'\n  alias cmmerge=\'chezmoi merge\'\n  alias cmverify=\'chezmoi verify\'\n  alias cmdoctor=\'chezmoi doctor\'\nfi\n\nif command -v brew >/dev/null 2>&1; then\n  alias brewcheck=\'brew bundle check --file="$HOME/Brewfile" --no-upgrade\'\n  alias brewout=\'brew outdated --greedy\'\n  alias brewcleanpreview=\'brew cleanup --dry-run\'\n  alias brewautopreview=\'brew autoremove --dry-run\'\nfi\n'
  create_directory "$zsh_config_dir"
  if [[ -f "$zsh_path_file" ]] \
     && grep -Fq '# Day One Mac bootstrap PATH — Phase 5 expands and adopts this file.' "$zsh_path_file"; then
    if cmp -s "$zsh_path_file" <(printf '%s' "$bootstrap_zsh_path"); then
      info "expanding the early portable-command PATH file for the full shell setup"
      write_text_file "$zsh_path_file" "$zsh_path"
    else
      err "$zsh_path_file contains the bootstrap marker plus user changes."
      warn "Merge those changes into the documented Phase 5 path.zsh, remove the marker, and rerun."
      return "$EX_MANUAL"
    fi
  fi
  [[ -e "$zsh_path_file" ]] || write_text_file "$zsh_path_file" "$zsh_path"
  [[ -e "$zsh_aliases_file" ]] || write_text_file "$zsh_aliases_file" "$zsh_aliases"
  # HTTPS authentication needs no SSH identity, but Phase 5 still keeps one
  # predictable ~/.ssh/config target in the dotfiles inventory. Create only a
  # comment when Phase 3 deliberately left the file absent; never replace an
  # existing personal or company SSH configuration.
  if uses_chezmoi && [[ "$AUTH_MODE" == https && ! -e "$ssh_config" ]]; then
    create_directory "$HOME/.ssh"
    write_text_file "$ssh_config" $'# Day One Mac: HTTPS Git authentication selected; no SSH identity is configured.\n'
    [[ "$DRY_RUN" == 1 ]] || chmod 600 "$ssh_config"
    ssh_config_created=1
  fi
  # The checksum-verified standalone installer is the sole owner of this
  # launcher. Keeping it out of chezmoi prevents an old dotfiles source from
  # downgrading a newly installed runtime during Phase 5.
  if [[ ! -x "$runner_wrapper" ]]; then
    if [[ "$DRY_RUN" == 1 ]]; then
      info "would require the standalone Day One Mac command at $runner_wrapper"
    else
      err "The standalone Day One Mac command is missing: $runner_wrapper"
      warn "Reinstall the latest public runtime, then rerun Phase 5."
      return "$EX_GATE"
    fi
  fi
  legacy_runner="$HOME/.local/bin/fresh-start"
  legacy_runner_content=$'#!/usr/bin/env bash\nprintf "Compatibility command: use day-one-mac instead of fresh-start.\\n" >&2\nexec "$HOME/.local/bin/day-one-mac" "$@"\n'
  if [[ -f "$legacy_runner" ]] \
     && grep -Eq 'fresh-start commands:|fresh-start project location|day-one-mac commands:' "$legacy_runner"; then
    if [[ "$DRY_RUN" == 1 ]]; then
      info "would convert the old fresh-start command into a Day One Mac compatibility shim"
    else
      write_text_file "$legacy_runner" "$legacy_runner_content"
      chmod 700 "$legacy_runner"
      legacy_runner_updated=1
    fi
  fi
  if [[ "$existing_managed_source" == 0 ]]; then
    zprofile=$'[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"\n'
    zshrc=$'[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"\n\nHISTFILE="$HOME/.zsh_history"\nHISTSIZE=50000\nSAVEHIST=10000\nsetopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY\n\nfor completion_dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do\n  [[ -d "$completion_dir" ]] || continue\n  (( ${fpath[(Ie)$completion_dir]} )) || fpath=("$completion_dir" $fpath)\ndone\nunset completion_dir\nautoload -Uz compinit\ncompinit\n\nif command -v fnm >/dev/null 2>&1; then\n  eval "$(fnm env --use-on-cd --shell zsh)"\nfi\n\n[[ -r "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"\n\nif [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then\n  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh\nfi\n\nif command -v starship >/dev/null 2>&1; then\n  eval "$(starship init zsh)"\nfi\n\n# Syntax highlighting must be the final shell integration.\nif [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then\n  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\nfi\n'
    if ! uses_starship; then
      local starship_init_block
      starship_init_block=$'if command -v starship >/dev/null 2>&1; then\n  eval "$(starship init zsh)"\nfi\n'
      zshrc="${zshrc/"$starship_init_block"/}"
    fi
    [[ -e "$HOME/.zprofile" ]] || write_text_file "$HOME/.zprofile" "$zprofile"
    [[ -e "$HOME/.zshrc" ]] || write_text_file "$HOME/.zshrc" "$zshrc"
    if uses_chezmoi && [[ "$DRY_RUN" != 1 ]]; then
      info 'Review adoption: .zprofile, .zshrc, .gitconfig, .gitignore_global, .ssh/config, and .config/zsh/{path,aliases}.zsh.'
      confirm 'Adopt these configuration files into the new chezmoi source?' || return "$EX_MANUAL"
      run chezmoi add "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.gitconfig" "$global_ignore" "$HOME/.ssh/config" "$zsh_path_file" "$zsh_aliases_file"
      if uses_starship; then run chezmoi add "$starship_config"; fi
    fi
  elif [[ "$DRY_RUN" != 1 ]]; then
    [[ "$starship_created" == 1 ]] && run chezmoi add "$starship_config"
    [[ "$legacy_runner_updated" == 1 ]] && run chezmoi add "$legacy_runner"
    [[ "$ssh_config_created" == 1 ]] && run chezmoi add "$ssh_config"
    chezmoi source-path "$global_ignore" >/dev/null 2>&1 || run chezmoi add "$global_ignore"
    chezmoi source-path "$zsh_path_file" >/dev/null 2>&1 || run chezmoi add "$zsh_path_file"
    chezmoi source-path "$zsh_aliases_file" >/dev/null 2>&1 || run chezmoi add "$zsh_aliases_file"
  fi
  [[ "$DRY_RUN" == 1 ]] && return 0
  if uses_starship; then
  grep -Fq 'starship init zsh' "$HOME/.zshrc" || {
    warn "Add 'eval \"\$(starship init zsh)\"' to ~/.zshrc using the selected configuration owner, then rerun Phase 5."
    return "$EX_MANUAL"
  }
  fi
  grep -Fq '.config/zsh/path.zsh' "$HOME/.zprofile" || {
    err "~/.zprofile must source ~/.config/zsh/path.zsh; merge the Phase 5 block using the selected configuration owner."
    return "$EX_MANUAL"
  }
  grep -Fq '.config/zsh/path.zsh' "$HOME/.zshrc" || {
    err "~/.zshrc must source ~/.config/zsh/path.zsh; merge the Phase 5 block using the selected configuration owner."
    return "$EX_MANUAL"
  }
  grep -Fq '.config/zsh/aliases.zsh' "$HOME/.zshrc" || {
    err "~/.zshrc must source ~/.config/zsh/aliases.zsh; merge the Phase 5 block using the selected configuration owner."
    return "$EX_MANUAL"
  }
  if uses_chezmoi; then
  chezmoi doctor >/dev/null
  for managed_target in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.gitconfig" "$global_ignore" "$HOME/.ssh/config" "$zsh_path_file" "$zsh_aliases_file"; do
    chezmoi source-path "$managed_target" >/dev/null 2>&1 || {
      err "$managed_target is not managed by chezmoi."; return "$EX_MANUAL"; }
  done
  if uses_starship; then
    chezmoi source-path "$starship_config" >/dev/null 2>&1 || { err 'Starship configuration is not managed by chezmoi.'; return "$EX_MANUAL"; }
  fi
  phase_step_done "required dotfiles are under chezmoi management"
  else
    phase_step_done 'configuration files remain user-owned; chezmoi not selected'
  fi
  phase_next "new login-shell verification" "Apply the reviewed source, open a new login shell, and resolve the first missing command it reports."
  if uses_starship; then STARSHIP_CONFIG="$starship_config" starship prompt >/dev/null; fi
  [[ "$("$runner_wrapper" root 2>/dev/null)" == "$PROJECT_DIR" ]] || {
    err "$runner_wrapper does not resolve the current project root: $PROJECT_DIR"
    return "$EX_GATE"
  }
  homebrew_zsh="$(configuration_shell_target)"
  [[ -x "$homebrew_zsh" ]] || { err "Selected zsh is missing at $homebrew_zsh."; return "$EX_GATE"; }
  compaudit_output="$("$homebrew_zsh" -fc 'for dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do [[ -d "$dir" ]] && fpath=("$dir" $fpath); done; autoload -Uz compaudit; compaudit' 2>/dev/null || true)"
  if [[ -n "$compaudit_output" ]]; then
    err "Zsh completion directories have unsafe permissions:"
    printf '%s\n' "$compaudit_output" | sed 's/^/    /'
    warn "Review only the listed paths; do not recursively chmod /opt/homebrew or HOME."
    return "$EX_MANUAL"
  fi
  # Keep the gate compatible with sources created before cmdifftext/cmmerge
  # were added. Those convenience aliases are in the current baseline, but a
  # visual-tool upgrade must not force-edit a user's versioned alias file.
  clean_shell_check='command -v brew git day-one-mac >/dev/null && alias cdayone gs gd gds gl gremotes brewcheck brewout brewcleanpreview brewautopreview >/dev/null && [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]'
  uses_chezmoi && clean_shell_check+=' && command -v chezmoi >/dev/null && alias cm cmstatus cmdiff cmverify cmdoctor >/dev/null'
  uses_starship && clean_shell_check+=' && command -v starship >/dev/null'
  [[ "${GHQ_CHOICE:-}" != yes ]] || clean_shell_check+=' && command -v ghq >/dev/null'
  uses_node && clean_shell_check+=' && [[ "$PNPM_HOME" == "$HOME/Library/pnpm" && ":$PATH:" == *":$PNPM_HOME:"* ]]'
  env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" TERM="${TERM:-xterm-256color}" PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL="$homebrew_zsh" \
    "$homebrew_zsh" -lic "$clean_shell_check" || {
      err "A clean selected-zsh login shell did not load every required command and PATH entry."
      return "$EX_GATE"
    }
  # The same commands must resolve in a NON-login interactive shell too. That
  # is the case ~/.zprofile does not cover, and where a missing Starship prompt
  # or Python shim would otherwise go unnoticed until someone opened a tmux
  # pane or typed `zsh`.
  env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" TERM="${TERM:-xterm-256color}" PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL="$homebrew_zsh" \
    "$homebrew_zsh" -ic "$clean_shell_check" || {
    err "A non-login interactive shell cannot find every selected command."
    warn "~/.zshrc should re-apply the Homebrew environment when it is missing; see Phase 5 Step 5.3."
    return "$EX_GATE"
  }
  phase_step_done "selected prompt and required commands work in login and non-login shells"
  phase_next "selected login shell" "Confirm any requested /etc/shells and chsh changes, then open a new terminal."
  switch_login_shell_to_homebrew_zsh || return $?
  ok "selected configuration ownership, prompt and login shell verified"
}
