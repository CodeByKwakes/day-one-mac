#!/usr/bin/env bash
set -euo pipefail

# Install a self-contained Day One Mac runtime. The Git checkout is only an
# installation source; the installed command runs from ~/.local/share.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/runtime-package.sh"
source "$SCRIPT_DIR/lib/runtime-activation.sh"
source "$SCRIPT_DIR/lib/operation-lock.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="${DAY_ONE_MAC_STATE_ROOT:-$HOME/.day-one-mac}"
RUNTIME_HOME="${DAY_ONE_MAC_RUNTIME_HOME:-$HOME/.local/share/day-one-mac}"
BIN_DIR="$HOME/.local/bin"
TARGET="$BIN_DIR/day-one-mac"
MODE=standalone
DRY_RUN=0
VERSION_OVERRIDE=""

usage() {
  cat <<'EOF'
Usage: ./install-portable-command.sh [options]

Install Day One Mac without making the command depend on this checkout.

  --source PATH       Day One Mac source root; defaults to this script's parent
  --version VERSION   runtime version label; normally detected automatically
  --standalone        copy a self-contained runtime (default)
  --linked            development mode: run directly from the source checkout
  --dry-run           show destinations without writing
  -h, --help          show this help
EOF
}

while (( $# )); do
  case "$1" in
    --source|--project-root) SOURCE_ROOT="${2:?$1 requires a path}"; shift 2 ;;
    --version) VERSION_OVERRIDE="${2:?--version requires a value}"; shift 2 ;;
    --standalone) MODE=standalone; shift ;;
    --linked) MODE=linked; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$SOURCE_ROOT" == /* && -x "$SOURCE_ROOT/scripts/bootstrap-day-one-mac.sh" ]] || {
  printf 'Invalid Day One Mac source root: %s\n' "$SOURCE_ROOT" >&2; exit 1; }

detect_version() {
  local value=''
  if [[ -n "$VERSION_OVERRIDE" ]]; then
    value="$VERSION_OVERRIDE"
  elif [[ -s "$SOURCE_ROOT/VERSION" ]]; then
    value="$(sed -n '1p' "$SOURCE_ROOT/VERSION")"
  elif git -C "$SOURCE_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    value="git-$(git -C "$SOURCE_ROOT" rev-parse --short=12 HEAD)"
  else
    value="local-$(date -u '+%Y%m%dT%H%M%SZ')"
  fi
  value="$(printf '%s' "$value" | tr -cs 'A-Za-z0-9._-' '-')"
  value="${value#-}"
  value="${value%-}"
  [[ -n "$value" ]] || value="local-$(date -u '+%Y%m%dT%H%M%SZ')"
  printf '%s\n' "$value"
}

write_shell_bootstrap() {
  local zsh_dir="$HOME/.config/zsh"
  local path_file="$zsh_dir/path.zsh"
  local zprofile="$HOME/.zprofile"
  local source_line='[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"'
  local content
  content=$'# Day One Mac bootstrap PATH — Phase 5 expands and adopts this file.\ntypeset -U path PATH\ncase ":$PATH:" in\n  *":$HOME/.local/bin:"*) ;;\n  *) export PATH="$HOME/.local/bin:$PATH" ;;\nesac\n'

  mkdir -p "$zsh_dir"
  if [[ ! -e "$path_file" ]]; then
    printf '%s' "$content" > "$path_file"
    chmod 600 "$path_file"
  fi
  if ! grep -Fqx "$source_line" "$zprofile" 2>/dev/null; then
    {
      [[ ! -s "$zprofile" ]] || printf '\n'
      printf '%s\n' '# Day One Mac shared shell path' "$source_line"
    } >> "$zprofile"
  fi
}

VERSION="$(detect_version)"
day_one_valid_version "$VERSION" || { printf 'Invalid runtime version: %s\n' "$VERSION" >&2; exit 2; }
RELEASE_DIR="$RUNTIME_HOME/releases/$VERSION"
CURRENT_LINK="$RUNTIME_HOME/current"
RECORDED_ROOT="$SOURCE_ROOT"

switch_current_runtime() {
  day_one_activate_runtime "$RUNTIME_HOME" "$VERSION"
}

if [[ "$MODE" == standalone ]]; then
  RECORDED_ROOT="$CURRENT_LINK"
fi

if [[ "$DRY_RUN" == 1 ]]; then
  printf 'Mode:           %s\n' "$MODE"
  printf 'Source:         %s\n' "$SOURCE_ROOT"
  [[ "$MODE" == standalone ]] && printf 'Runtime:        %s\n' "$RELEASE_DIR"
  printf 'Command:        %s\n' "$TARGET"
  printf 'Runtime record: %s\n' "$STATE_ROOT/runtime-root"
  exit 0
fi

day_one_serialize runtime "$0" "${ORIGINAL_ARGS[@]}"
mkdir -p "$BIN_DIR" "$STATE_ROOT"
chmod 700 "$STATE_ROOT"

if [[ "$MODE" == standalone ]]; then
  mkdir -p "$RUNTIME_HOME/releases"
  chmod 700 "$RUNTIME_HOME" "$RUNTIME_HOME/releases"
  staging="$RUNTIME_HOME/.install-$VERSION-$$"
  [[ ! -e "$staging" ]] || { printf 'Staging path already exists: %s\n' "$staging" >&2; exit 1; }
  trap 'rm -rf "$staging"' EXIT HUP INT TERM

  day_one_copy_runtime "$SOURCE_ROOT" "$staging"
  printf '%s\n' "$VERSION" > "$staging/VERSION"
  day_one_checksum_runtime "$staging"

  if [[ -e "$RELEASE_DIR" ]]; then
    if cmp -s "$staging/SHA256SUMS" "$RELEASE_DIR/SHA256SUMS"; then
      rm -rf "$staging"
    else
      printf 'Runtime version already exists with different contents: %s\n' "$RELEASE_DIR" >&2
      exit 1
    fi
  else
    mv "$staging" "$RELEASE_DIR"
  fi
  trap - EXIT HUP INT TERM

  switch_current_runtime
  day_one_install_launcher "$CURRENT_LINK/scripts/day-one-mac" "$TARGET"
else
  day_one_install_launcher "$SOURCE_ROOT/scripts/day-one-mac" "$TARGET"
fi

day_one_write_state "$STATE_ROOT/runtime-root" "$RECORDED_ROOT"
if [[ "$MODE" == linked ]]; then
  day_one_write_state "$STATE_ROOT/project-root" "$SOURCE_ROOT"
fi
write_shell_bootstrap

installed_status="$("$TARGET" runtime-status)"
printf '%s\n' "$installed_status" | grep -Fq "Version:   $VERSION" || {
  printf 'Installed launcher did not resolve the requested runtime version %s.\n' "$VERSION" >&2
  exit 1
}
if [[ "$MODE" == standalone ]]; then
printf '%s\n' "$installed_status" | grep -Fq 'Integrity: verified' || {
  printf 'Installed runtime did not pass its integrity check.\n' >&2
  exit 1
}
fi

printf '%s\n' \
  '' \
  '✓ Portable Day One Mac command installed.' \
  "  Mode:    $MODE" \
  "  Version: $VERSION" \
  "  Command: $TARGET" \
  "  Runtime: $RECORDED_ROOT" \
  '' \
  'Make it available in this terminal now:' \
  '  export PATH="$HOME/.local/bin:$PATH"' \
  '' \
  'Then run:' \
  '  day-one-mac runtime-status' \
  '  day-one-mac --wizard' \
  '' \
  'View the installed documentation:' \
  '  day-one-mac docs --list' \
  '  day-one-mac docs start --open'
