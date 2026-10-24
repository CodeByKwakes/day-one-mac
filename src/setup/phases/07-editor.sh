#!/usr/bin/env bash
# Sourced phase implementation; shared runner context is supplied by setup.sh.

# Checks only the Default profile's settings file.
# Verify policy and other profile overrides in VS Code.
verify_editor_settings() {
  command -v python3 >/dev/null 2>&1 || { warn 'Python 3 is needed to inspect JSONC; install it through the approved toolchain.'; return 1; }
  python3 -I -B "$SCRIPT_DIR/../src/core/editor-settings.py" "$HOME/Library/Application Support/Code/User/settings.json"
}

phase_07() {
  local settings settings_content
  if [[ "${PRESET:-recommended-productivity}" == core ]]; then
    info "Core preset: VS Code installation and configuration are not required."
    return 0
  fi
  ui_title '7️⃣' 'Phase 07 — VS Code base'
  info "Guide: $(phase_doc 07)"
  phase_next "Visual Studio Code application" "Complete Phase 4 or restore the approved company-managed VS Code application, then rerun Phase 7."
  if [[ "$DRY_RUN" != 1 ]]; then
    verify_application visual-studio-code || {
      day_one_app_detect visual-studio-code || true
      err "Visual Studio Code is unavailable or conflicts with the expected application identity."
      warn "$DAY_ONE_APP_REASON"
      return "$EX_GATE"
    }
    ok "Visual Studio Code — $(day_one_app_source_label "$DAY_ONE_APP_SOURCE")"
  fi
  phase_next "VS Code settings and command-line launcher" "Open VS Code, install the 'code' command in PATH, and keep both AI tool auto-approval settings false."
  settings="$HOME/Library/Application Support/Code/User/settings.json"
  settings_content=$'{\n  "editor.formatOnSave": true,\n  "files.insertFinalNewline": true,\n  "files.trimTrailingWhitespace": true,\n  "git.autofetch": true,\n  "terminal.integrated.defaultProfile.osx": "zsh",\n  "terminal.integrated.shellIntegration.enabled": true,\n  "terminal.integrated.suggest.enabled": true,\n  "terminal.integrated.suggest.upArrowNavigatesHistory": true,\n  "terminal.integrated.fontFamily": "\u0027JetBrainsMono Nerd Font\u0027",\n  "chat.tools.global.autoApprove": false,\n  "chat.tools.terminal.enableAutoApprove": false\n}\n'
  if [[ ! -e "$settings" ]]; then
    create_directory "$HOME/Library/Application Support/Code"
    create_directory "$HOME/Library/Application Support/Code/User"
    write_text_file "$settings" "$settings_content"
  fi
  if [[ "$DRY_RUN" == 1 ]]; then print_command code --version; return 0; fi
  have code || {
    warn "Open VS Code and run: Shell Command: Install 'code' command in PATH"
    return "$EX_MANUAL"
  }
  code --version >/dev/null
  verify_editor_settings || return "$EX_MANUAL"
  phase_step_done "VS Code CLI and default user-file approval settings verified"
  ok "minimal VS Code base verified; profiles and extension catalogues remain optional"
}
