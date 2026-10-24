#!/usr/bin/env bash
# State/ownership context for the standalone folder capability.
DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
source "$DAY_ONE_ROOT/src/core/project-paths.sh"
source "$DAY_ONE_ROOT/src/core/terminal-ui.sh"
source "$DAY_ONE_ROOT/src/core/platform.sh"
source "$DAY_ONE_ROOT/src/core/state.sh"
source "$DAY_ONE_ROOT/src/core/operation-lock.sh"
source "$DAY_ONE_ROOT/src/core/developer-folders.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
COMPLETED_DIR="$STATE_DIR/completed"
ORIGINALS_DIR="$STATE_DIR/originals"
INSTALL_MANIFEST="$STATE_DIR/install-manifest.tsv"
PATH_MANIFEST="$STATE_DIR/path-manifest.tsv"
LOG_FILE="$STATE_DIR/setup.log"
DRY_RUN=0
info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }





ensure_state() {
  [[ "$DRY_RUN" == 1 ]] && return 0
  mkdir -p "$ORIGINALS_DIR"
  touch "$INSTALL_MANIFEST" "$PATH_MANIFEST" "$LOG_FILE"
  chmod 700 "$STATE_DIR" "$ORIGINALS_DIR"
  chmod 600 "$INSTALL_MANIFEST" "$PATH_MANIFEST" "$LOG_FILE"
}

log_line() {
  [[ "$DRY_RUN" == 1 ]] && return 0
  ensure_state
  printf '%s\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >> "$LOG_FILE"
}

print_command() {
  local arg
  printf '  $'
  for arg in "$@"; do printf ' %q' "$arg"; done
  printf '\n'
}

run() {
  if [[ "$DRY_RUN" == 1 ]]; then print_command "$@"; return 0; fi
  log_line "RUN $(printf '%q ' "$@")"
  "$@"
}

state_value() {
  [[ -r "$STATE_DIR/$1" ]] && sed -n '1p' "$STATE_DIR/$1" || true
}

save_state_value() {
  local name="$1" value="$2"
  if [[ "$DRY_RUN" == 1 ]]; then info "would save $name=$value"; return 0; fi
  ensure_state
  day_one_write_state "$STATE_DIR/$name" "$value"
}

append_unique() {
  local file="$1" line="$2"
  [[ "$DRY_RUN" == 1 ]] && return 0
  grep -Fqx "$line" "$file" 2>/dev/null || printf '%s\n' "$line" >> "$file"
}

record_path_before_write() {
  local target="$1" key backup
  [[ "$DRY_RUN" == 1 ]] && return 0
  ensure_state
  if awk -F '\t' -v target="$target" '$2 == target {found=1} END {exit !found}' "$PATH_MANIFEST"; then return 0; fi
  if [[ -e "$target" || -L "$target" ]]; then
    key="$(printf '%s' "$target" | shasum -a 256 | awk '{print $1}')"
    backup="$ORIGINALS_DIR/$key"
    cp -pR "$target" "$backup"
    printf 'modified\t%s\t%s\n' "$target" "$backup" >> "$PATH_MANIFEST"
  else
    printf 'created\t%s\t-\n' "$target" >> "$PATH_MANIFEST"
  fi
}

write_text_file() {
  local target="$1" content="$2" tmp
  if [[ "$DRY_RUN" == 1 ]]; then info "would write $target"; return 0; fi
  record_path_before_write "$target"
  mkdir -p "$(dirname "$target")"
  tmp="$(mktemp "$(dirname "$target")/.day-one-mac.XXXXXX")"
  printf '%s' "$content" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$target"
  log_line "WRITE $target"
}

create_directory() {
  local target="$1"
  [[ -d "$target" ]] && return 0
  if [[ "$DRY_RUN" == 1 ]]; then print_command mkdir -p "$target"; return 0; fi
  run mkdir -p "$target"
  ensure_state
  append_unique "$PATH_MANIFEST" "created-dir"$'\t'"$target"$'\t-'
}

brew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then printf '/opt/homebrew/bin/brew\n'
  elif have brew && [[ "$(command -v brew)" == /opt/homebrew/* ]]; then command -v brew
  else return 1
  fi
}

load_brew() {
  local brew_bin
  brew_bin="$(brew_path)" || return 1
  eval "$("$brew_bin" shellenv)"
}

required_package_installed() {
  local token="$1"
  brew list --formula "$token" >/dev/null 2>&1 && return 0
  [[ "$token" == azure-cli ]] && brew list --cask "$token" >/dev/null 2>&1
}

record_package() {
  ensure_state
  append_unique "$INSTALL_MANIFEST" "$1"$'\t'"$2"
}

brew_formula_snapshot() {
  local output status
  set +e
  output="$(brew list --formula 2>/dev/null)"
  status=$?
  set -e
  [[ "$status" -eq 0 ]] || return 1
  printf '%s\n' "$output" | sort
}

warn_unknown_dependency_baseline() {
  warn "Could not list the formulae installed before adding $1."
  warn "Only $1 is recorded as runner-owned; new dependencies are left unclaimed so rollback cannot remove pre-existing software."
}

install_formula() {
  local token="$1" before_formulae formula baseline=1
  if [[ "$DRY_RUN" == 1 ]]; then
    if [[ "$token" == azure-cli ]]; then print_command brew install --cask "$token"
    else print_command brew install "$token"; fi
    return 0
  fi
  if load_brew && required_package_installed "$token"; then info "package $token already installed"; return 0; fi
  if [[ "$token" == azure-cli ]]; then install_cask "$token"; return $?; fi
  before_formulae="$(brew_formula_snapshot)" || baseline=0
  run brew install "$token"
  record_package brew-formula "$token"
  [[ "$baseline" == 1 ]] || { warn_unknown_dependency_baseline "$token"; return 0; }
  while IFS= read -r formula; do
    [[ -n "$formula" && "$formula" != "$token" ]] || continue
    grep -Fqx "$formula" <<<"$before_formulae" || record_package brew-dependency "$formula"
  done < <(brew_formula_snapshot || true)
}

install_cask() {
  local token="$1" before_formulae formula baseline=1
  if [[ "$DRY_RUN" == 1 ]]; then print_command brew install --cask "$token"; return 0; fi
  if load_brew && brew list --cask "$token" >/dev/null 2>&1; then info "cask $token already installed"; return 0; fi
  before_formulae="$(brew_formula_snapshot)" || baseline=0
  [[ "$token" != git-credential-manager ]] || record_path_before_write "$HOME/.gitconfig"
  run brew install --cask "$token"
  record_package brew-cask "$token"
  [[ "$baseline" == 1 ]] || { warn_unknown_dependency_baseline "$token"; return 0; }
  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    grep -Fqx "$formula" <<<"$before_formulae" || record_package brew-dependency "$formula"
  done < <(brew_formula_snapshot || true)
}
