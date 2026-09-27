#!/usr/bin/env bash
# Sourced phase implementation; shared runner context is supplied by setup.sh.

verify_apple_developer_tools() {
  local selected os_major clt_version clt_major
  selected="$(xcode-select -p 2>/dev/null || true)"
  [[ -n "$selected" && -d "$selected" ]] || return 1
  os_major="$(sw_vers -productVersion | awk -F. '{print $1}')"

  case "$selected" in
    /Applications/*.app/Contents/Developer)
      if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
        warn "Xcode still needs its licence or first-launch components."
        warn "Run 'sudo xcodebuild -license', review and accept the licence, then run 'sudo xcodebuild -runFirstLaunch'."
        return 1
      fi
      ;;
    /Library/Developer/CommandLineTools)
      clt_version="$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null \
        | awk -F': ' '$1 == "version" {print $2; exit}')"
      clt_major="${clt_version%%.*}"
      if [[ "$os_major" =~ ^[0-9]+$ && "$os_major" -ge 27 ]] \
         && { [[ ! "$clt_major" =~ ^[0-9]+$ ]] || [[ "$clt_major" -lt "$os_major" ]]; }; then
        warn "Command Line Tools $clt_version are older than macOS $(sw_vers -productVersion) and are likely stale."
        warn "The package version tracks Xcode, so a higher number is normal; a lower one is not."
        warn "Install the current tools from Software Update or rerun 'xcode-select --install'."
        return 1
      fi
      ;;
  esac
  xcrun --find clang >/dev/null 2>&1 && clang --version >/dev/null 2>&1
}

phase_02() {
  local detected_brew path_brew installer
  phase_next "Xcode Command Line Tools" "Complete the Apple installer window, then rerun Phase 2."
  ui_title '2️⃣' 'Phase 02 — Command-line foundation'
  info "Guide: $(phase_doc 02)"
  if ! xcode-select -p >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == 1 ]]; then print_command xcode-select --install; return 0; fi
    xcode-select --install || true
    warn "Finish the Command Line Tools installer, then rerun Phase 2."
    return "$EX_MANUAL"
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    print_command xcodebuild -checkFirstLaunchStatus
    print_command pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
  else
    verify_apple_developer_tools || {
      warn "Finish the matching Xcode or Command Line Tools setup, then rerun Phase 2."
      return "$EX_MANUAL"
    }
  fi
  phase_step_done "Xcode Command Line Tools available"
  ok "Xcode Command Line Tools available"
  phase_next "Homebrew installation and update" "Allow the official installer to finish, then rerun Phase 2 if it stops."
  info "Checking for native Apple-silicon Homebrew before running an installer."
  if detected_brew="$(brew_path 2>/dev/null)"; then
    ok "Existing Homebrew found at $detected_brew; the installer will be skipped."
  elif have brew; then
    path_brew="$(command -v brew)"
    err "Homebrew is on PATH at $path_brew, but Day One Mac requires /opt/homebrew/bin/brew."
    warn "This normally means an Intel/Rosetta Homebrew or an unsupported wrapper is active."
    warn "Do not install a second copy over it. Open a native arm64 terminal, review the existing installation, then rerun Phase 2."
    return "$EX_GATE"
  else
    info "Native Homebrew was not found at /opt/homebrew/bin/brew."
    if [[ "$DRY_RUN" == 1 ]]; then
      info "would run the official Homebrew installer from brew.sh"
      return 0
    fi
    confirm "Install Homebrew using its official installer?" || return "$EX_MANUAL"
    ensure_state
    installer="$(mktemp "$STATE_DIR/homebrew-installer.XXXXXX")"
    if ! curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"; then
      rm -f "$installer"
      err "Homebrew installer download failed; nothing was executed."
      return "$EX_GATE"
    fi
    chmod 600 "$installer"
    [[ -s "$installer" ]] && /bin/bash -n "$installer" || return "$EX_GATE"
    info "Downloaded Homebrew installer retained for review: $installer"
    shasum -a 256 "$installer"
    warn "The hash records downloaded bytes, not publisher identity. Inspect the file before approving."
    confirm "Run this downloaded official Homebrew installer?" || return "$EX_MANUAL"
    /bin/bash "$installer" || return "$EX_GATE"
    ensure_state
    append_unique "$INSTALL_MANIFEST" $'component\thomebrew'
    ok "Homebrew was installed by Day One Mac and recorded for precise rollback."
  fi
  load_brew || { err "Homebrew was installed but is not discoverable."; return "$EX_GATE"; }
  if [[ "$DRY_RUN" == 1 ]]; then
    print_command brew update
    print_command brew --prefix
    print_command brew config
    print_command brew doctor
    phase_step_done "Homebrew installation, native prefix and diagnostics would be checked"
    return 0
  fi
  run brew update
  [[ "$(brew --prefix)" == /opt/homebrew ]] || {
    err "Apple-silicon Homebrew must use /opt/homebrew; found: $(brew --prefix)"
    return "$EX_GATE"
  }
  brew config
  if ! brew doctor; then
    warn "Homebrew reported diagnostics. Review them before installing packages."
  fi
  phase_step_done "Homebrew installed, discoverable and updated"
  ok "Homebrew ready at $(brew --prefix)"
}
