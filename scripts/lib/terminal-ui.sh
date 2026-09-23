#!/usr/bin/env bash
# Shared, accessible terminal styling for Day One Mac.
#
# Colour is enabled only when standard output is an interactive terminal.
# Set NO_COLOR to any value, or use TERM=dumb, to force plain output. Icons and
# text remain present without colour so meaning never depends on colour alone.
# Compatible with the Bash 3.2 shipped by macOS.

DAY_ONE_UI_RESET=""
DAY_ONE_UI_BOLD=""
DAY_ONE_UI_DIM=""
DAY_ONE_UI_BLUE=""
DAY_ONE_UI_CYAN=""
DAY_ONE_UI_GREEN=""
DAY_ONE_UI_YELLOW=""
DAY_ONE_UI_RED=""
DAY_ONE_UI_MAGENTA=""

if [[ -t 1 && -z "${NO_COLOR+x}" && "${TERM:-dumb}" != dumb ]]; then
  DAY_ONE_UI_RESET=$'\033[0m'
  DAY_ONE_UI_BOLD=$'\033[1m'
  DAY_ONE_UI_DIM=$'\033[2m'
  DAY_ONE_UI_BLUE=$'\033[34m'
  DAY_ONE_UI_CYAN=$'\033[36m'
  DAY_ONE_UI_GREEN=$'\033[32m'
  DAY_ONE_UI_YELLOW=$'\033[33m'
  DAY_ONE_UI_RED=$'\033[31m'
  DAY_ONE_UI_MAGENTA=$'\033[35m'
fi

ui_info() {
  printf '  %sℹ%s  %s\n' "$DAY_ONE_UI_BLUE" "$DAY_ONE_UI_RESET" "$*"
}

ui_success() {
  printf '  %s✓%s %s\n' "$DAY_ONE_UI_GREEN" "$DAY_ONE_UI_RESET" "$*"
}

ui_warning() {
  printf '  %s⚠%s %s\n' "$DAY_ONE_UI_YELLOW" "$DAY_ONE_UI_RESET" "$*" >&2
}

ui_error() {
  printf '  %s✗%s %s\n' "$DAY_ONE_UI_RED" "$DAY_ONE_UI_RESET" "$*" >&2
}

ui_title() {
  local icon="$1" title="$2"
  printf '\n%s%s%s %s%s\n' \
    "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN" "$icon" "$title" "$DAY_ONE_UI_RESET"
  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' \
    "$DAY_ONE_UI_DIM" "$DAY_ONE_UI_RESET"
}

ui_banner() {
  local icon="$1" title="$2"
  printf '%s%s%s %s%s\n' \
    "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN" "$icon" "$title" "$DAY_ONE_UI_RESET"
  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n' \
    "$DAY_ONE_UI_DIM" "$DAY_ONE_UI_RESET"
}

ui_section() {
  local icon="$1" title="$2"
  printf '\n%s%s%s %s%s\n' \
    "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_MAGENTA" "$icon" "$title" "$DAY_ONE_UI_RESET"
}

ui_label() {
  local label="$1"
  shift
  printf '  %s%s:%s %s\n' "$DAY_ONE_UI_BOLD" "$label" "$DAY_ONE_UI_RESET" "$*"
}

ui_status() {
  local kind="$1" colour=""
  shift
  case "$kind" in
    success) colour="$DAY_ONE_UI_GREEN" ;;
    warning) colour="$DAY_ONE_UI_YELLOW" ;;
    error) colour="$DAY_ONE_UI_RED" ;;
    pending) colour="$DAY_ONE_UI_DIM" ;;
    locked) colour="$DAY_ONE_UI_CYAN" ;;
  esac
  printf '  %s%s%s\n' "$colour" "$*" "$DAY_ONE_UI_RESET"
}
