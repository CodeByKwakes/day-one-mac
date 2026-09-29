#!/usr/bin/env bash
# Standalone capability; reuse setup's journal, lock and package ownership helpers.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup.sh"
FOLDER_LAYOUT='' GHQ_CHOICE='' FOLDER_GHQ_ROOT='' INSTALL_GHQ=0
action='' choices_explicit=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan|--apply|--check|--resume)
      [[ -z "$action" ]] || { err 'Choose one action.'; exit 2; }; action="${1#--}" ;;
    --layout|--ghq|--ghq-root)
      option="$1"; shift
      [[ $# -gt 0 && -n "$1" ]] || { err "$option needs a value."; exit 2; }
      case "$option" in --layout) FOLDER_LAYOUT="$1" ;; --ghq) GHQ_CHOICE="$1" ;; --ghq-root) FOLDER_GHQ_ROOT="$1" ;; esac
      choices_explicit=1 ;;
    --install-ghq) INSTALL_GHQ=1 ;;
    -h|--help)
      printf '%s\n' \
        'Usage: day-one-mac folders --plan|--apply|--check|--resume [choices]' \
        '  --layout none|repository|purpose|existing' \
        '  --ghq no|yes                  opt-in; does not imply installation' \
        '  --ghq-root /absolute/path     confirmed primary root for existing + ghq yes' \
        '  --install-ghq                 approve missing ghq via existing Homebrew (apply/resume only)' \
        'Plan/check never save choices or install software. Apply is explicit approval.' \
        'Resume rechecks saved choices and repairs missing selected directories; never moves repositories.' \
        'Exit: 0 success, 2 invalid/missing choices, 10 manual review, 11 failed check.'
      exit 0 ;;
    *) err "Unknown folders option: $1"; exit 2 ;;
  esac
  shift
done
[[ -n "$action" ]] || { err 'Choose --plan, --apply, --check, or --resume.'; exit 2; }
[[ "$action" != resume || "$choices_explicit" == 0 ]] || { err 'Resume reuses saved choices; use plan/apply to change them.'; exit 2; }
if [[ "$action" == plan || "$action" == check ]]; then
  [[ "$INSTALL_GHQ" == 0 ]] || { err '--install-ghq is an apply/resume option.'; exit 2; }
fi
# An explicit layout/no-ghq selection must not inherit an unrelated old root.
if [[ "$choices_explicit" == 0 ]]; then folders_load_choices; fi
folders_validate_choices
[[ "$INSTALL_GHQ" == 0 || "$GHQ_CHOICE" == yes ]] || { err '--install-ghq requires --ghq yes.'; exit 2; }
case "$action" in
  plan) folders_plan ;;
  check) folders_check ;;
  apply|resume)
    day_one_require_apple_silicon || exit 2
    day_one_safe_state_path "$STATE_DIR" || exit 11
    day_one_serialize folders "$0" "${ORIGINAL_ARGS[@]}"
    folders_apply ;;
esac
