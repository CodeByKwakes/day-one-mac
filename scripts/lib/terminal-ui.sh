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
DAY_ONE_UI_INFO='ℹ'
DAY_ONE_UI_SUCCESS='✓'
DAY_ONE_UI_WARNING='⚠'
DAY_ONE_UI_ERROR='✗'
if [[ "${DAY_ONE_MAC_ASCII:-0}" == 1 ]]; then
  DAY_ONE_UI_INFO='[info]'
  DAY_ONE_UI_SUCCESS='[ok]'
  DAY_ONE_UI_WARNING='[warn]'
  DAY_ONE_UI_ERROR='[error]'
fi

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
  printf '  %s%s%s %s\n' "$DAY_ONE_UI_BLUE" "$DAY_ONE_UI_INFO" "$DAY_ONE_UI_RESET" "$*"
}

ui_success() {
  printf '  %s%s%s %s\n' "$DAY_ONE_UI_GREEN" "$DAY_ONE_UI_SUCCESS" "$DAY_ONE_UI_RESET" "$*"
}

ui_warning() {
  printf '  %s%s%s %s\n' "$DAY_ONE_UI_YELLOW" "$DAY_ONE_UI_WARNING" "$DAY_ONE_UI_RESET" "$*" >&2
}

ui_error() {
  printf '  %s%s%s %s\n' "$DAY_ONE_UI_RED" "$DAY_ONE_UI_ERROR" "$DAY_ONE_UI_RESET" "$*" >&2
}

ui_width() {
  local width="${COLUMNS:-}"
  if [[ -z "$width" && -t 1 && "${TERM:-dumb}" != dumb ]]; then
    width="$(tput cols 2>/dev/null || true)"
  fi
  [[ "$width" =~ ^[0-9]{1,4}$ ]] || width=80
  width=$((10#$width))
  [[ "$width" -gt 0 ]] || width=80
  [[ "$width" -le 72 ]] || width=72
  [[ "$width" -ge 12 ]] || width=12
  printf '%s' "$width"
}

ui_rule() {
  printf '%s' "$DAY_ONE_UI_DIM"
  printf '%*s' "$(ui_width)" '' | tr ' ' '-'
  printf '%s\n' "$DAY_ONE_UI_RESET"
}

ui_clear_screen() {
  if [[ -t 1 && "${TERM:-dumb}" != dumb ]]; then printf '\033[2J\033[H'; fi
}

# Wrap human labels at word boundaries. Never cut a token or a Unicode byte.
ui_text() {
  local text="$1" indent="${2-  }" width word line='' words=()
  local continuation="${3-$indent}"
  width="$(ui_width)"
  width=$((width - ${#indent}))
  IFS=' ' read -r -a words <<< "$text"
  for word in ${words[@]+"${words[@]}"}; do
    if [[ -n "$line" && $((${#line} + ${#word} + 1)) -gt "$width" ]]; then
      printf '%s%s\n' "$indent" "$line"
      indent="$continuation"
      line="$word"
    else line="${line}${line:+ }$word"; fi
  done
  printf '%s%s\n' "$indent" "$line"
}

# Shared viewport for selectors; keyboard navigation still uses the full list.
ui_menu_window() {
  local count="$1" cursor="$2" reserved="${3:-10}" rows="${LINES:-}" width capacity
  if [[ -z "$rows" && -t 1 && "${TERM:-dumb}" != dumb ]]; then
    rows="$(tput lines 2>/dev/null || true)"
  fi
  [[ "$rows" =~ ^[0-9]{1,4}$ ]] || rows=24
  rows=$((10#$rows))
  [[ "$rows" -gt 0 ]] || rows=24
  capacity=$((rows - reserved))
  width="$(ui_width)"
  if [[ "$width" -lt 60 ]]; then capacity=$((capacity / 3)); fi
  [[ "$capacity" -ge 1 ]] || capacity=1
  [[ "$capacity" -le 12 ]] || capacity=12
  DAY_ONE_UI_MENU_START=$((cursor / capacity * capacity))
  DAY_ONE_UI_MENU_END=$((DAY_ONE_UI_MENU_START + capacity))
  [[ "$DAY_ONE_UI_MENU_END" -le "$count" ]] || DAY_ONE_UI_MENU_END="$count"
}

ui_menu_position() {
  local count="$1" cursor="$2"
  ui_text "Item $((cursor + 1)) of $count (showing $((DAY_ONE_UI_MENU_START + 1))-$DAY_ONE_UI_MENU_END)"
}

ui_menu_item() {
  local index="$1" cursor="$2" check="$3" label="$4" marker=' ' prefix
  [[ "$index" != "$cursor" ]] || marker='>'
  if [[ -t 1 && "${TERM:-dumb}" != dumb && "${DAY_ONE_MAC_ASCII:-0}" != 1 ]]; then
    case "$check" in '(*)') check='●' ;; '( )') check='○' ;; esac
  fi
  if [[ "$index" == "$cursor" ]]; then printf '%s%s' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN"; fi
  prefix="  $marker $check "
  ui_text "$label" "$prefix" "$(printf '%*s' "${#prefix}" '')"
  printf '%s' "$DAY_ONE_UI_RESET"
}

# A small prompt symbol and one accent colour keep choices easy to scan.
ui_prompt() {
  local symbol='>'
  if [[ -t 1 && "${TERM:-dumb}" != dumb && "${DAY_ONE_MAC_ASCII:-0}" != 1 ]]; then symbol='◆'; fi
  printf '%s%s' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_MAGENTA"
  ui_text "$1" "  $symbol " '    '
  printf '%s' "$DAY_ONE_UI_RESET"
}

ui_menu_help() {
  printf '\n'
  case "$1" in
    single) ui_text 'Up/Down or j/k: move | Enter/Space: choose | q: quit' ;;
    simple-toggle)
      ui_text 'Up/Down or j/k: move | Space: toggle'
      ui_text 'Enter: review | q: quit' ;;
    recommended)
      ui_text 'Up/Down or j/k: move | Space: toggle'
      ui_text 'a: recommended | n: none | Enter: review | q: quit' ;;
    toggle)
      ui_text 'Up/Down or j/k: move | Space: toggle | a/n: all/none'
      ui_text "Enter: review | q: ${2:-quit}" ;;
    category)
      ui_text 'Left/Right or h/l: category | Up/Down or j/k: tool'
      ui_text 'Space: toggle | a/n: all/none in this category'
      ui_text 'Enter: review | b: back | q: quit' ;;
  esac
}

# Keep decoration in interactive terminals; logs retain plain, searchable titles.
ui_heading() {
  local icon="$1" title="$2" colour="$3"
  if [[ -n "$icon" && -t 1 && "${TERM:-dumb}" != dumb && "${DAY_ONE_MAC_ASCII:-0}" != 1 ]]; then
    title="$icon $title"
  fi
  printf '%s%s' "$DAY_ONE_UI_BOLD" "$colour"
  ui_text "$title" ''
  printf '%s' "$DAY_ONE_UI_RESET"
}

ui_title() {
  printf '\n'
  ui_heading "$1" "$2" "$DAY_ONE_UI_CYAN"
  ui_rule
}

ui_banner() {
  ui_heading "$1" "$2" "$DAY_ONE_UI_CYAN"
  ui_rule
}

ui_section() {
  printf '\n'
  ui_heading '' "$2" "$DAY_ONE_UI_BLUE"
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
