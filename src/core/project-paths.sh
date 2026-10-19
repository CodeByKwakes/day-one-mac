#!/usr/bin/env bash
# Shared Day One Mac path resolution. The FRESH_START_* variables and
# ~/.fresh-mac-setup fallback are retained only for pre-rename installations.

day_one_state_root() {
  local canonical legacy
  canonical="$HOME/.day-one-mac"
  legacy="$HOME/.fresh-mac-setup"

  if [[ -n "${DAY_ONE_MAC_STATE_ROOT:-}" ]]; then
    printf '%s\n' "$DAY_ONE_MAC_STATE_ROOT"
  elif [[ -n "${FRESH_START_STATE_ROOT:-}" ]]; then
    printf '%s\n' "$FRESH_START_STATE_ROOT"
  elif [[ -e "$canonical" || ! -e "$legacy" ]]; then
    printf '%s\n' "$canonical"
  else
    printf '%s\n' "$legacy"
  fi
}

day_one_state_dir() {
  local state_root="$1"
  printf '%s\n' "${DAY_ONE_MAC_STATE_DIR:-${FRESH_START_STATE_DIR:-$state_root}}"
}

day_one_uses_legacy_state() {
  [[ "$(day_one_state_root)" == "$HOME/.fresh-mac-setup" ]]
}
