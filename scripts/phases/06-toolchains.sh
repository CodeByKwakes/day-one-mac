#!/usr/bin/env bash
# Sourced phase implementation; shared runner context is supplied by setup.sh.

phase_06() {
  local fnm_dir pnpm_home uv_python_bin uv_python_dir selected_zsh
  selected_zsh="$(configuration_shell_target)"
  ui_title '6️⃣' 'Phase 06 — Language toolchains and pnpm'
  info "Guide: $(phase_doc 06)"
  if uses_node; then
    phase_next "Node LTS, npm and pnpm" "Review the Node steps, then ensure PNPM_HOME is exported by the selected shell configuration from Phase 5."
    if ! have fnm; then
      [[ "$DRY_RUN" == 1 ]] || { err "fnm is missing; complete Phase 4."; return "$EX_GATE"; }
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
      print_command fnm install --lts --use
      print_command mkdir -p "$HOME/Library/pnpm"
      print_command pnpm --version
      print_command pnpm store path
    else
      eval "$(fnm env --shell bash)"
      fnm_dir="${FNM_DIR:-$HOME/.local/share/fnm}"
      record_path_before_write "$fnm_dir"
      record_path_before_write "$HOME/.local/state/fnm_multishells"
      run fnm install --lts --use
      run fnm default "$(fnm current)"
      pnpm_home="$("$selected_zsh" -lc 'printf %s "${PNPM_HOME:-$HOME/Library/pnpm}"')"
      [[ "$pnpm_home" == "$HOME"/* ]] || {
        err "PNPM_HOME must be a specific path beneath HOME: $pnpm_home"; return "$EX_GATE"; }
      create_directory "$pnpm_home"
      export PNPM_HOME="$pnpm_home"
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac
      node --version
      npm --version
      pnpm --version
      (cd "$HOME" && pnpm store path)
      if ! "$selected_zsh" -lc '[[ -n "$PNPM_HOME" && -d "$PNPM_HOME" && ":$PATH:" == *":$PNPM_HOME:"* ]]'; then
        warn "Merge the Phase 5 PNPM_HOME block through the selected configuration owner, then rerun Phase 6."
        return "$EX_MANUAL"
      fi
    fi
    phase_step_done "Node LTS, npm and Homebrew-owned pnpm verified"
  fi
  if uses_python; then
    phase_next "uv-managed Python" "Complete the Python steps and rerun after uv can find an installed interpreter."
    if ! have uv; then
      [[ "$DRY_RUN" == 1 ]] || { err "uv is missing; complete Phase 4."; return "$EX_GATE"; }
    fi
    if [[ "$DRY_RUN" != 1 ]]; then
      uv_python_dir="$(uv python dir)"
      record_path_before_write "$uv_python_dir"
    fi
    run uv python install
    if [[ "$DRY_RUN" != 1 ]]; then
      uv_python_bin="$(uv python find)"
      "$uv_python_bin" --version
    fi
    phase_step_done "uv-managed Python verified"
  fi
  ok "selected language toolchains verified"
}
