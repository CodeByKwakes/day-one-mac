#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/runtime-activation.sh"
source "$SCRIPT_DIR/lib/operation-lock.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="${DAY_ONE_MAC_STATE_ROOT:-$HOME/.day-one-mac}"
RUNTIME_HOME="${DAY_ONE_MAC_RUNTIME_HOME:-$HOME/.local/share/day-one-mac}"
CURRENT_LINK="$RUNTIME_HOME/current"
COMMAND="$HOME/.local/bin/day-one-mac"

usage() {
  cat <<'EOF'
Usage: day-one-mac runtime-status
       day-one-mac update
       day-one-mac rollback-runtime [--version VERSION] [--execute]
       day-one-mac uninstall-runtime [--execute]
       day-one-mac docs [TOPIC] [--open]
       day-one-mac docs --list
       day-one-mac docs --folder [--open]
EOF
}

verify_runtime() {
  [[ -s "$RUNTIME_ROOT/SHA256SUMS" ]] || return 2
  (cd "$RUNTIME_ROOT" && shasum -a 256 -c SHA256SUMS >/dev/null)
}

status() {
  local version='unknown' mode='linked checkout' integrity='not packaged'
  [[ -s "$RUNTIME_ROOT/VERSION" ]] && version="$(sed -n '1p' "$RUNTIME_ROOT/VERSION")"
  if [[ "$RUNTIME_ROOT" == "$RUNTIME_HOME"/releases/* ]]; then
    mode='standalone runtime'
  fi
  if [[ -s "$RUNTIME_ROOT/SHA256SUMS" ]]; then
    if verify_runtime; then integrity='verified'; else integrity='FAILED'; fi
  fi
  printf '%s\n' \
    'Day One Mac runtime' \
    "  Mode:      $mode" \
    "  Version:   $version" \
    "  Root:      $RUNTIME_ROOT" \
    "  Command:   $COMMAND" \
    "  Integrity: $integrity" \
    "  State:     $STATE_ROOT"
  [[ "$integrity" != FAILED ]]
}

rollback_runtime() {
  local execute=0 requested='' candidate='' current='' previous=''
  while (( $# )); do
    case "$1" in
      --version) requested="${2:?--version requires a value}"; shift 2 ;;
      --execute) execute=1; shift ;;
      -h|--help) usage; return 0 ;;
      *) printf 'Unknown rollback option: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  [[ -L "$CURRENT_LINK" && -d "$RUNTIME_HOME/releases" ]] || {
    printf 'No standalone runtime history is installed.\n' >&2; return 1; }
  [[ "$execute" != 1 ]] || day_one_serialize runtime "$0" "${ORIGINAL_ARGS[@]}"
  current="$(basename "$(cd -P "$CURRENT_LINK" && pwd)")"
  if [[ -n "$requested" ]]; then
    day_one_valid_version "$requested" || { printf 'Invalid version: %s\n' "$requested" >&2; return 2; }
    candidate="$RUNTIME_HOME/releases/$requested"
  else
    previous="$(sed -n '1p' "$RUNTIME_HOME/previous" 2>/dev/null || true)"
    case "$previous" in releases/*) requested="${previous#releases/}" ;; esac
    day_one_valid_version "$requested" && [[ "$requested" != "$current" ]] || {
      printf 'No previous activation is recorded; choose --version explicitly.\n' >&2; return 1;
    }
    candidate="$RUNTIME_HOME/releases/$requested"
  fi
  [[ -n "$candidate" && -d "$candidate" && -s "$candidate/SHA256SUMS" ]] || {
    printf 'No previous verified runtime was found.\n' >&2; return 1; }
  (cd "$candidate" && shasum -a 256 -c SHA256SUMS >/dev/null) || {
    printf 'Candidate runtime failed checksum verification: %s\n' "$candidate" >&2; return 1; }
  printf 'Current:  %s\nCandidate:%s\n' "$current" " $(basename "$candidate")"
  [[ "$execute" == 1 ]] || {
    printf 'Preview only. Rerun with --execute to switch versions.\n'; return 0; }
  day_one_activate_runtime "$RUNTIME_HOME" "$requested" || return $?
  day_one_install_launcher "$CURRENT_LINK/scripts/day-one-mac" "$COMMAND"
  day_one_write_state "$STATE_ROOT/runtime-root" "$CURRENT_LINK"
  printf '✓ Runtime switched to %s\n' "$(basename "$candidate")"
}

uninstall_runtime() {
  local execute=0
  while (( $# )); do
    case "$1" in
      --execute) execute=1 ;;
      -h|--help) usage; return 0 ;;
      *) printf 'Unknown uninstall option: %s\n' "$1" >&2; return 2 ;;
    esac
    shift
  done
  [[ "$execute" != 1 ]] || day_one_serialize runtime "$0" "${ORIGINAL_ARGS[@]}"
  printf '%s\n' \
    'Day One Mac runtime removal' \
    "  Command: $COMMAND" \
    "  Runtime: $RUNTIME_HOME" \
    "  Preserved state: $STATE_ROOT" \
    '  Installed applications, packages, dotfiles and settings: preserved'
  [[ "$execute" == 1 ]] || {
    printf 'Preview only. Rerun with --execute to remove the command and runtime.\n'; return 0; }
  printf 'Type REMOVE DAY ONE MAC RUNTIME to continue: '
  IFS= read -r answer
  [[ "$answer" == 'REMOVE DAY ONE MAC RUNTIME' ]] || {
    printf 'Confirmation did not match; nothing changed.\n' >&2; return 10; }
  # Accept only a directory with our releases/current ownership layout.
  [[ "$RUNTIME_HOME" == /* && "$RUNTIME_HOME" != "$HOME" && "$RUNTIME_HOME" != / &&
     ! -L "$RUNTIME_HOME" && -L "$CURRENT_LINK" && -d "$RUNTIME_HOME/releases" &&
     -s "$CURRENT_LINK/SHA256SUMS" ]] || { printf 'Unrecognized runtime directory; refusing removal.\n' >&2; return 1; }
  local physical
  physical="$(cd -P "$RUNTIME_HOME" && pwd)"
  case "$physical" in /|/Users|/tmp|/private/tmp|/var|/private/var) return 1 ;; esac
  [[ "$physical" != "$(cd -P "$HOME" && pwd)" ]] || return 1
  rm -f "$COMMAND"
  rm -rf "$RUNTIME_HOME"
  rm -f "$STATE_ROOT/runtime-root"
  printf '✓ Runtime removed. Saved setup state was preserved.\n'
}

open_docs() {
  local topic='start' target='' should_open=0 show_list=0 use_folder=0 topic_set=0
  while (( $# )); do
    case "$1" in
      --open) should_open=1; shift ;;
      --list) show_list=1; shift ;;
      --folder) use_folder=1; shift ;;
      -h|--help|help)
        printf '%s\n' \
          'Usage: day-one-mac docs [TOPIC] [--open]' \
          '       day-one-mac docs --list' \
          '       day-one-mac docs --folder [--open]' \
          '' \
          'Topics: start, index, manual, process, project, commands, chezmoi, status, optional, advanced, second-brain' \
          '' \
          'Without --open, the command prints the installed path.'
        return 0
        ;;
      --*) printf 'Unknown docs option: %s\n' "$1" >&2; return 2 ;;
      *)
        [[ "$topic_set" == 0 ]] || {
          printf 'Choose only one documentation topic.\n' >&2; return 2; }
        topic="$1"
        topic_set=1
        shift
        ;;
    esac
  done

  if [[ "$show_list" == 1 ]]; then
    printf '%-14s %s\n' \
      'TOPIC' 'INSTALLED DOCUMENT' \
      'start' "$RUNTIME_ROOT/docs/START-HERE.md" \
      'index' "$RUNTIME_ROOT/docs/README.md" \
      'manual' "$RUNTIME_ROOT/docs/20-reference/MANUAL-SETUP-GUIDE.md" \
      'process' "$RUNTIME_ROOT/docs/PROCESS-OVERVIEW.md" \
      'project' "$RUNTIME_ROOT/docs/PROJECT-GUIDE.md" \
      'commands' "$RUNTIME_ROOT/docs/20-reference/COMMAND-REFERENCE.md" \
      'chezmoi' "$RUNTIME_ROOT/docs/20-reference/CHEZMOI-SETUP-TUTORIAL.md" \
      'status' "$RUNTIME_ROOT/docs/20-reference/OPTIONAL-STATUS.md" \
      'optional' "$RUNTIME_ROOT/docs/02-optional/README.md" \
      'advanced' "$RUNTIME_ROOT/docs/03-advanced/README.md" \
      'second-brain' "$RUNTIME_ROOT/second-brain/README.md"
    return 0
  fi

  if [[ "$use_folder" == 1 ]]; then
    target="$RUNTIME_ROOT/docs"
  else
    case "$topic" in
      start) target="$RUNTIME_ROOT/docs/START-HERE.md" ;;
      index) target="$RUNTIME_ROOT/docs/README.md" ;;
      manual) target="$RUNTIME_ROOT/docs/20-reference/MANUAL-SETUP-GUIDE.md" ;;
      process) target="$RUNTIME_ROOT/docs/PROCESS-OVERVIEW.md" ;;
      project) target="$RUNTIME_ROOT/docs/PROJECT-GUIDE.md" ;;
      commands) target="$RUNTIME_ROOT/docs/20-reference/COMMAND-REFERENCE.md" ;;
      chezmoi) target="$RUNTIME_ROOT/docs/20-reference/CHEZMOI-SETUP-TUTORIAL.md" ;;
      status) target="$RUNTIME_ROOT/docs/20-reference/OPTIONAL-STATUS.md" ;;
      optional) target="$RUNTIME_ROOT/docs/02-optional/README.md" ;;
      advanced) target="$RUNTIME_ROOT/docs/03-advanced/README.md" ;;
      second-brain) target="$RUNTIME_ROOT/second-brain/README.md" ;;
      *)
        printf 'Unknown documentation topic: %s\n' "$topic" >&2
        printf 'Run `day-one-mac docs --list` to see available topics.\n' >&2
        return 2
        ;;
    esac
  fi

  [[ -e "$target" ]] || {
    printf 'Documentation is missing: %s\n' "$target" >&2; return 1; }
  if [[ "$should_open" == 1 ]]; then
    command -v open >/dev/null 2>&1 || {
      printf 'The macOS open command is unavailable. Document: %s\n' "$target" >&2
      return 1
    }
    open "$target"
  else
    printf '%s\n' "$target"
  fi
}

case "${1:-status}" in
  status) shift || true; status "$@" ;;
  update)
    shift || true
    exec "$RUNTIME_ROOT/install-day-one-mac" --update "$@"
    ;;
  rollback) shift || true; rollback_runtime "$@" ;;
  uninstall) shift || true; uninstall_runtime "$@" ;;
  docs) shift || true; open_docs "$@" ;;
  -h|--help|help) usage ;;
  *) printf 'Unknown runtime action: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
