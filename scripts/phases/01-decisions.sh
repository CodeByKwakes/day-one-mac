#!/usr/bin/env bash
# Sourced phase implementation; shared runner context is supplied by setup.sh.

phase_01() {
  local default_name='' default_email='' developer_dir=''
  phase_next "macOS update and backup readiness" "Finish Software Update, open several files in the separate backup, then rerun Phase 1."
  day_one_require_apple_silicon || return "$EX_GATE"
  ui_title '1️⃣' 'Phase 01 — First boot and decisions'
  info "Guide: $(phase_doc 01)"
  info "Track $TRACK — $(track_name)"
  info "Stack — $STACK"
  confirm "Is macOS fully updated, and is all prior data already in a verified backup?" \
    || { warn "Finish the Phase 1 preparation and rerun."; return "$EX_MANUAL"; }
  phase_step_done "macOS update and readable backup confirmed"
  phase_next "Git identity and setup choices" "Enter a valid author name and email, then review the saved hosting and stack choices."
  # Apple's Git shim can open the CLT installer on a fresh Mac. Explicit
  # identity needs no lookup; missing defaults wait until tools are present.
  if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    developer_dir="$(xcode-select -p 2>/dev/null || true)"
    if [[ -n "$developer_dir" && -d "$developer_dir" ]]; then
      [[ -n "$GIT_NAME" ]] || default_name="$(git config --global user.name 2>/dev/null || true)"
      [[ -n "$GIT_EMAIL" ]] || default_email="$(git config --global user.email 2>/dev/null || true)"
    fi
    if [[ -z "$GIT_NAME" && -z "$default_name" ]]; then
      default_name="$(id -F 2>/dev/null || id -un)"
    fi
  fi
  [[ "$DRY_RUN" == 1 && -z "$default_email" ]] && default_email=developer@example.com
  [[ -n "$GIT_NAME" ]] || GIT_NAME="$(ask 'Git author name' "$default_name" '^.+$')"
  [[ -n "$GIT_EMAIL" ]] || GIT_EMAIL="$(ask 'Primary Git email' "$default_email" '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')"
  [[ "$GIT_NAME" != *$'\n'* && "$GIT_NAME" != *$'\r'* ]] || {
    err "Git author name must be one line."; return "$EX_GATE"; }
  save_state_value track "$TRACK"
  save_state_value track-schema-version "$TRACK_SCHEMA_VERSION"
  save_state_value stack "$STACK"
  save_state_value git-name "$GIT_NAME"
  save_state_value git-email "$GIT_EMAIL"
  save_state_value primary-ide "$PRIMARY_IDE"
  phase_step_done "hosting, stack and Git identity recorded"
  ok "decisions recorded"
}
