#!/usr/bin/env bash
# Optional bootstrap checkpoint; independent of required phase completion.
set -euo pipefail
AI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$AI_ROOT/src/core/project-paths.sh"
source "$AI_ROOT/src/core/state.sh"
source "$AI_ROOT/src/core/platform.sh"
source "$AI_ROOT/src/core/operation-lock.sh"
source "$AI_ROOT/src/core/deadline.sh"
source "$AI_ROOT/src/core/application-ownership.sh"
STATE_ROOT="$(day_one_state_root)"
AI_STATE="$STATE_ROOT/ai-setup"

ai_usage() {
  cat <<'EOF'
Usage: day-one-mac ai-setup [options]
  (no options)       choose optional assistance before Phase 1
  --plan             inspect the proposed choice without writes or downloads
  --check            inspect saved choice and executable presence; no client run
  --apply            save a choice and prepare a private assistant handoff
  --mode MODE        none, guide, or execute
  --client CLIENT    codex, claude, or existing (guidance with another app/browser)
  --install          with --apply: review/install a missing native CLI interactively
  -h, --help         show help

AI remains optional. No Phase 8 prerequisite or required phase marker is used.
Installation needs an interactive terminal and explicit review of the download.
Check does not verify account access, billing, permissions or live tool use.
Apply never launches an AI session or edits personal client configuration.
EOF
}

ai_load_client() {
  local row
  [[ "$AI_CLIENT" == codex || "$AI_CLIENT" == claude ]] || return 1
  row="$(awk -F '\t' -v id="$AI_CLIENT" '$1 == id {print; n++} END {if(n != 1) exit 1}' "$AI_ROOT/config/catalogs/setup-assistants.tsv")" || return 1
  IFS=$'\t' read -r AI_ID AI_COMMAND AI_URL AI_SHELL AI_APP extra <<< "$row"
  [[ -z "${extra:-}" && "$AI_COMMAND" == "$AI_CLIENT" ]] || return 1
  case "$AI_CLIENT:$AI_URL:$AI_SHELL:$AI_APP" in
    codex:https://chatgpt.com/codex/install.sh:/bin/sh:codex|claude:https://claude.ai/install.sh:/bin/bash:claude-code) ;;
    *) printf 'Unsupported assistant installer metadata.\n' >&2; return 1 ;;
  esac
}

ai_find_client() {
  AI_BINARY='' AI_CONFLICT=''
  if day_one_app_resolve_cli "$AI_APP" "$AI_COMMAND" -; then
    AI_BINARY="$DAY_ONE_CLI_PATH"
    return 0
  fi
  AI_CONFLICT="$DAY_ONE_CLI_CONFLICT"
  if [[ -n "$AI_CONFLICT" ]]; then
    printf 'Existing client path needs review: %s\nPreserve it and follow the original installer recovery instructions before retrying.\n' "$AI_CONFLICT" >&2
  fi
  return 1
}

ai_load_selection() {
  day_one_safe_state_path "$AI_STATE/selection.tsv" || return 10
  [[ -f "$AI_STATE/selection.tsv" && ! -L "$AI_STATE/selection.tsv" ]] || return 10
  AI_MODE="$(awk -F '\t' '$1 == "mode" {print $2}' "$AI_STATE/selection.tsv")"
  AI_CLIENT="$(awk -F '\t' '$1 == "client" {print $2}' "$AI_STATE/selection.tsv")"
}

ai_validate_choice() {
  case "$AI_MODE:$AI_CLIENT" in
    none:none|guide:existing|guide:codex|guide:claude|execute:codex|execute:claude) ;;
    *) printf 'Choose --mode none, or guide/execute with a supported --client. Existing app/browser supports guide only.\n' >&2; return 2 ;;
  esac
}

ai_confirm() {
  local expected="$1" answer
  printf 'Type "%s" to continue: ' "$expected"
  IFS= read -r answer && [[ "$answer" == "$expected" ]]
}

ai_require_terminal() {
  [[ -t 0 && -t 1 ]] || { printf 'Installer review requires an interactive terminal; run day-one-mac ai-setup.\n' >&2; return 10; }
}

ai_review_installer() {
  LESSSECURE=1 LESS='' LESSOPEN='' LESSCLOSE='' /usr/bin/less "$1"
}

ai_install_client() {
  local review_dir before after
  if ai_find_client; then return 0; fi
  [[ -z "$AI_CONFLICT" ]] || return 1
  ai_require_terminal || return $?
  printf '\nSelected native installer: %s\n' "$AI_URL"
  printf 'Confirm device policy permits this install. Review account access before installing.\n'
  ai_confirm "download $AI_CLIENT" || return 10
  day_one_state_directory "$AI_STATE" || return 1
  chmod 700 "$AI_STATE"
  review_dir="$(mktemp -d "$AI_STATE/installer.XXXXXX")" || return 1
  chmod 700 "$review_dir"
  if ! curl --proto '=https' --proto-redir '=https' --tlsv1.2 -fL --connect-timeout 15 --max-time 180 \
      "$AI_URL" -o "$review_dir/install.sh"; then
    printf 'Download failed; no installer ran. Review retained files in %s\n' "$review_dir" >&2
    return 1
  fi
  [[ -s "$review_dir/install.sh" ]] || { printf 'Empty installer refused.\n' >&2; return 1; }
  chmod 600 "$review_dir/install.sh"
  "$AI_SHELL" -n "$review_dir/install.sh" || return 1
  before="$(shasum -a 256 "$review_dir/install.sh")"
  printf '\nDownloaded installer: %s\nSHA-256: %s\n' "$review_dir/install.sh" "${before%% *}"
  printf 'Read the installer below; press q to leave the viewer. The hash identifies these bytes, not publisher authenticity.\n'
  ai_review_installer "$review_dir/install.sh" || return 10
  ai_confirm "install $AI_CLIENT" || return 10
  [[ ! -L "$review_dir/install.sh" && -f "$review_dir/install.sh" ]] || return 1
  after="$(shasum -a 256 "$review_dir/install.sh")"
  [[ "$before" == "$after" ]] || { printf 'Installer changed after review; refusing execution.\n' >&2; return 1; }
  # Recheck after review in case another installer or user changed the target.
  if ai_find_client; then printf 'Client now exists; preserving it.\n'; return 0; fi
  [[ -z "$AI_CONFLICT" ]] || return 1
  # Vendor installers own their binaries and updates. They are not Homebrew or
  # Day One Mac-owned package records, and are never silently uninstalled here.
  /usr/bin/env -u BASH_ENV -u ENV "$AI_SHELL" "$review_dir/install.sh" || {
    printf 'Installer failed; inspect its output and existing files before retrying.\n' >&2; return 1; }
  ai_find_client || { printf 'Installer returned but the client is unavailable. Check PATH and the vendor instructions.\n' >&2; return 1; }
}

ai_prepare_handoff() {
  local handoff selection
  day_one_state_directory "$AI_STATE" || return 1
  chmod 700 "$AI_STATE"
  if [[ "$AI_MODE" != none ]]; then
    handoff="$(mktemp -d "$AI_STATE/handoff.XXXXXX")" || return 1
    mkdir -p "$handoff/.agents/skills/day-one-mac-assistant" || return 1
    cp "$AI_ROOT/templates/ai-setup-assistant/SKILL.md" "$handoff/.agents/skills/day-one-mac-assistant/SKILL.md" || return 1
    {
      printf '# Day One Mac setup task\n\n'
      printf 'Assistance mode: %s. Setup route: scripted (assisted).\n\n' "$AI_MODE"
      printf 'Read `.agents/skills/day-one-mac-assistant/SKILL.md` before planning.\n'
      printf 'Documentation root: `%s/docs`. Read its START-HERE.md and assisted AI guide.\n' "$AI_ROOT"
      printf 'Use the installed public day-one-mac command. Request only needed read access to that runtime.\n'
      printf 'First inspect and propose a plan. This file does not approve setup changes.\n'
      printf 'Account and permissions: manual verification required.\n'
      printf 'Do not read credentials or change client approval settings.\n'
      [[ "$AI_MODE" != guide ]] || printf 'Guidance only: explain commands; the user executes them.\n'
    } > "$handoff/AGENTS.md"
    printf '@AGENTS.md\n' > "$handoff/CLAUDE.md"
    chmod 600 "$handoff/AGENTS.md" "$handoff/CLAUDE.md" "$handoff/.agents/skills/day-one-mac-assistant/SKILL.md"
    day_one_write_state "$AI_STATE/current" "${handoff##*/}" || return 1
    printf 'Private handoff: %s\n' "$handoff"
    printf 'Open this folder in your client; attach AGENTS.md and the skill if automatic discovery is unavailable.\n'
    printf 'Account and permissions: manual verification required.\n'
    printf 'Follow %s/docs/setup/manual/ai/setup-assistant.md for sign-in and the harmless tool test.\n' "$AI_ROOT"
  fi
  selection="$(printf 'mode\t%s\nclient\t%s' "$AI_MODE" "$AI_CLIENT")"
  day_one_write_state "$AI_STATE/selection.tsv" "$selection"
  printf 'Saved assistance choice: %s (%s). Required phase evidence is unchanged.\n' "$AI_MODE" "$AI_CLIENT"
}

ai_guided() {
  local answer install_choice=''
  [[ -t 0 && -t 1 ]] || { ai_usage; return 10; }
  printf '\nOptional AI setup assistant (before Phase 1)\n'
  printf 'Use browser guidance until any planned reset is complete. Respect managed-device policy.\n'
  printf '1. Continue without AI\n2. AI guidance only\n3. AI-assisted execution\nq. Back\nChoice [1]: '
  IFS= read -r answer || return 20
  case "$answer" in
    ''|1) AI_MODE=none AI_CLIENT=none ;;
    2) AI_MODE=guide ;;
    3) AI_MODE=execute ;;
    q|Q) return 20 ;;
    *) printf 'Choose 1, 2 or 3.\n'; return 10 ;;
  esac
  if [[ "$AI_MODE" != none ]]; then
    printf 'Client: 1 Codex, 2 Claude Code'
    [[ "$AI_MODE" != guide ]] || printf ', 3 existing app/browser'
    printf ': '
    IFS= read -r answer || return 20
    case "$answer" in 1) AI_CLIENT=codex ;; 2) AI_CLIENT=claude ;; 3) AI_CLIENT=existing ;; *) return 10 ;; esac
    ai_validate_choice || return $?
    if [[ "$AI_CLIENT" != existing ]]; then
      ai_load_client || return 1
      if ! ai_find_client; then
        [[ -z "$AI_CONFLICT" ]] || return 1
        printf 'Client missing. i: review native installation; any other key: return without changes: '
        IFS= read -r answer || return 20
        [[ "$answer" == i ]] || return 20
        install_choice=--install
      fi
    fi
  fi
  # Re-enter with exact choices so the shared lock supervisor can own apply.
  if [[ -n "$install_choice" ]]; then
    /bin/bash "$AI_ROOT/src/setup/ai-setup.sh" --apply --mode "$AI_MODE" --client "$AI_CLIENT" --install || return $?
  else
    /bin/bash "$AI_ROOT/src/setup/ai-setup.sh" --apply --mode "$AI_MODE" --client "$AI_CLIENT" || return $?
  fi
  [[ "$AI_MODE" != none ]] || return 0
  printf 'Complete the client sign-in/tool test, then return here or let the client guide setup.\n'
  printf 'Continue required setup in this terminal now? [y/N]: '
  IFS= read -r answer && [[ "$answer" == y || "$answer" == Y ]] || return 20
}

ai_main() {
  local action='' install=0 checkpoint=0 choice_set=0 original=("$@") arg version_dir
  AI_MODE='' AI_CLIENT=none
  while (( $# )); do
    case "$1" in
      --plan|--check|--apply)
        [[ -z "$action" ]] || { printf 'Choose one action.\n' >&2; return 2; }
        action="${1#--}"; shift ;;
      --mode|--client)
        arg="$1"; [[ $# -ge 2 ]] || return 2
        if [[ "$arg" == --mode ]]; then AI_MODE="$2"; else AI_CLIENT="$2"; fi
        choice_set=1; shift 2 ;;
      --install) install=1; shift ;;
      --checkpoint) checkpoint=1; shift ;;
      -h|--help) ai_usage; return 0 ;;
      *) printf 'Unknown AI setup option: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  if [[ "$install" == 1 && "$action" != apply ]]; then printf '%s\n' '--install requires --apply.' >&2; return 2; fi
  [[ -n "$action" || "$choice_set" == 0 ]] || { printf 'Use --plan or --apply with a choice.\n' >&2; return 2; }
  if [[ "$checkpoint" == 1 ]]; then
    [[ -z "$action" && "$choice_set" == 0 ]] || return 2
    if ai_load_selection; then
      ai_validate_choice || return $?
      printf 'Saved AI choice: %s (%s). Revisit with day-one-mac ai-setup.\n' "$AI_MODE" "$AI_CLIENT"
      [[ "$AI_MODE" == none ]] || printf 'Client/account readiness must be checked separately; required setup remains available.\n'
      return 0
    fi
  fi
  [[ -n "$action" ]] || { day_one_require_apple_silicon || return 2; ai_guided; return $?; }
  if [[ "$choice_set" == 0 ]]; then
    if ! ai_load_selection; then
      [[ "$action" == plan ]] || { printf 'No saved AI choice. Run day-one-mac ai-setup.\n'; return 10; }
      printf 'Optional AI checkpoint: choose none, guide or execute. No files or software changed.\n'; return 0
    fi
  fi
  ai_validate_choice || return $?
  [[ "$install" == 0 || "$AI_CLIENT" == codex || "$AI_CLIENT" == claude ]] || return 2
  if [[ "$AI_CLIENT" != none && "$AI_CLIENT" != existing ]]; then ai_load_client || return 1; fi
  if [[ "$action" == plan ]]; then
    printf 'Proposed assistance: %s (%s). No files, client processes or downloads.\n' "$AI_MODE" "$AI_CLIENT"
    [[ "$AI_MODE" == none ]] || printf 'Apply prepares a private handoff. Sign-in and permissions remain manual.\n'
    if [[ "$AI_CLIENT" == codex || "$AI_CLIENT" == claude ]]; then
      if ai_find_client; then printf 'Reuse existing executable: %s\n' "$AI_BINARY"
      else
        [[ -z "$AI_CONFLICT" ]] || return 1
        printf 'Missing executable; optional reviewed native installer: %s\n' "$AI_URL"
      fi
    fi
    return 0
  fi
  if [[ "$action" == check ]]; then
    [[ "$AI_MODE" != none ]] || { printf 'AI intentionally skipped.\n'; return 0; }
    [[ "$AI_CLIENT" != existing ]] || { printf 'Existing app/browser requires manual verification.\n'; return 10; }
    if ! ai_find_client; then
      [[ -z "$AI_CONFLICT" ]] || return 1
      printf 'Selected client is missing; retry setup or continue without AI.\n'; return 10
    fi
    printf 'Executable present: %s\nAccount, billing, permissions and live tools: not checked.\n' "$AI_BINARY"
    return 0
  fi
  day_one_require_apple_silicon || return 2
  day_one_safe_state_path "$AI_STATE/selection.tsv" || return 1
  day_one_serialize ai-setup "$AI_ROOT/src/setup/ai-setup.sh" "${original[@]}"
  umask 077
  if [[ "$AI_CLIENT" == codex || "$AI_CLIENT" == claude ]]; then
    if ! ai_find_client; then
      [[ -z "$AI_CONFLICT" ]] || return 1
      [[ "$install" == 1 ]] || { printf 'Client missing. Use the manual guide or review --apply --install in a terminal.\n'; return 10; }
      ai_install_client || return $?
    fi
    # A working version command is still not authentication or tool approval.
    day_one_state_directory "$AI_STATE" || return 1
    chmod 700 "$AI_STATE"
    version_dir="$(mktemp -d "$AI_STATE/version.XXXXXX")" || return 1
    run_with_deadline "$version_dir/output.txt" 20 "$AI_BINARY" --version || {
      printf 'Client version check failed or timed out; inspect %s. No successful choice saved.\n' "$version_dir" >&2; return 1; }
    cat "$version_dir/output.txt"
  fi
  ai_prepare_handoff
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then ai_main "$@"; fi
