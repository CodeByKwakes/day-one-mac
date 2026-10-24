#!/usr/bin/env bash
# Minimal, resumable setup for a genuinely clean Mac.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail
# Retained only for historical evidence fixtures; excluded from runtime packages.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  exec /bin/bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/src/operations/retired-setup.sh" "$@"
fi

DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DIR="$PROJECT_DIR/docs"
source "$SCRIPT_DIR/../src/core/project-paths.sh"
source "$SCRIPT_DIR/../src/core/terminal-ui.sh"
source "$SCRIPT_DIR/../src/core/required-phase-catalog.sh"
source "$SCRIPT_DIR/../src/core/phase-dependencies.sh"
source "$SCRIPT_DIR/../src/core/application-ownership.sh"
source "$SCRIPT_DIR/../src/core/platform.sh"
source "$SCRIPT_DIR/../src/core/state.sh"
source "$SCRIPT_DIR/../src/core/operation-lock.sh"
source "$SCRIPT_DIR/../src/core/deadline.sh"
source "$SCRIPT_DIR/../src/core/developer-folders.sh"
source "$SCRIPT_DIR/../src/core/configuration-choices.sh"
source "$SCRIPT_DIR/../src/core/hosting-auth.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
COMPLETED_DIR="$STATE_DIR/completed"
INSTALL_MANIFEST="$STATE_DIR/install-manifest.tsv"
PATH_MANIFEST="$STATE_DIR/path-manifest.tsv"
ORIGINALS_DIR="$STATE_DIR/originals"
LOG_FILE="$STATE_DIR/setup.log"
APPLICATION_PROVENANCE_TSV="$STATE_DIR/application-provenance.tsv"
APPLICATION_PROVENANCE_REPORT="$STATE_DIR/application-provenance.md"

DRY_RUN=0
ASSUME_YES=0
SHOW_STATUS=0
SETUP_ACTION=""
JSON_OUTPUT=0
ACCEPT_PREPARATION=0
RESET_PROGRESS=0
SSH_PIN_PROVIDER=""
RUN_INSTALLATION_CENTRE=0
INSTALLATION_CENTRE_RAN=0
GUIDED=1
REQUESTED_PHASES=""
TRACK=""
FOLDER_LAYOUT=""
GHQ_CHOICE=""
FOLDER_GHQ_ROOT=""
FOLDER_CHOICES_EXPLICIT=0
STACK=""
GIT_NAME=""
GIT_EMAIL=""
PRESET=""
DEPLOYMENT_MODE=""
WORKSTATION_POLICY=""
PRIMARY_IDE=""
DOTFILES_REPO=""
DOTFILES_VERSIONING=""
SHELL_CHOICE=""
PROMPT_CHOICE=""
AUTH_MODE=""
HTTPS_HELPER=""
GITHUB_REPO=""
AZURE_REPO=""
GITHUB_CLONE_DIR=""
AZURE_CLONE_DIR=""
MACOS_SETTINGS_PLAN=""
OPTIONAL_MODULES=""
APP_INSTALL_POLICY=""
TRACK_EXPLICIT=0
DOTFILES_EXPLICIT=0
TRACK_SCHEMA_VERSION=2
INSTALLATION_CENTRE_SCHEMA=1

EX_MANUAL=10
EX_GATE=11

# Human-readable progress for a failed phase. These values are intentionally
# kept in memory: the phase completion marker remains the only durable claim
# that every gate passed.
PHASE_COMPLETED_ITEMS=""
PHASE_FAILED_ITEMS=""
PHASE_PENDING_ITEM=""
PHASE_NEXT_ACTION=""

# Contract versions accompany hashes of the runner, shared libraries and phase
# implementation. Documentation edits do not invalidate required phases.
PHASE_SCHEMA_01=5
PHASE_SCHEMA_02=3
PHASE_SCHEMA_03=6
PHASE_SCHEMA_04=6
PHASE_SCHEMA_05=16
PHASE_SCHEMA_06=2
PHASE_SCHEMA_07=4
PHASE_SCHEMA_08=12

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

  --plan                      read-only impact plan; no setup commands executed
  --apply                     explicitly run selected phases (all eight by default)
  --check                     read-only local checks; manual gates remain explicit
  --resume                    reuse saved choices; recheck before skipping phases
  --json                      schema v1 output for --plan, --check, or --status
  --accept-preparation        attest updated macOS and verified backup/disposable data
                              required with --yes when explicit actions run Phase 1
  --guided                    run the eight required phases (default)
  --phase NN                  run one required phase; repeatable
  --track 1|2|3|4             1 GitHub; 2 Azure DevOps; 3 both; 4 none of the above
  --stack node|python|both    language toolchain selection
  --layout LAYOUT             none, repository, purpose, or existing
  --ghq no|yes                optional ghq; yes approves installation in the Centre
  --ghq-root PATH             confirmed primary root for existing layout + ghq yes
  --auth-mode MODE            1password (default), keychain, external, or https
  --https-helper MODE         gcm, or existing (GitHub CLI / existing Azure helper)
  --github-repo URL           GitHub clone URL for the required Git access check
  --azure-repo URL            Azure clone URL for the required Git access check
  --github-clone-dir PATH     optionally clone after Git access passes; none disables
  --azure-clone-dir PATH      optionally clone after Git access passes; none disables
  --name "Full Name"          Git author name
  --email ADDRESS             primary Git author email
  --deployment MODE          personal (default) or managed
  --policy PATH              approved workstation policy JSON for managed mode
  --preset PRESET            core or recommended-productivity (default)
  --primary-ide IDE           vscode or other; controls Git editor integration
  --dotfiles-repo URL         apply an existing private chezmoi source
  --new-dotfiles              create or keep a new chezmoi source
  --dotfiles-versioning MODE  none (unmanaged), local (chezmoi), or git (private repo)
  --local-dotfiles            shorthand for --new-dotfiles --dotfiles-versioning local
  --shell MODE                keep the current zsh, apple zsh, or homebrew zsh
  --prompt MODE               none (leave existing prompt alone) or starship
  --macos-settings MODE       ask, configure, or skip the early settings wizard
  --skip-macos-settings       shorthand for --macos-settings skip
  --app-install-policy MODE   prompt, homebrew, or check-only for missing apps
  --install-centre            install/revalidate required apps and CLI tools, then exit
  --ssh-pin [PROVIDER]        save 1Password public keys to ~/.ssh, then exit
                              PROVIDER is github, azure, or both (default: the saved track)
  --status                    show recorded completion, not current machine health
  --reset-progress            archive completion markers; keep installed files
  --dry-run                   preview commands and write nothing
  --yes                       accept ordinary setup confirmations
  -h, --help                  show this help

Progress, logs, backups and the exact install manifest live under:
  ~/.day-one-mac/

An existing ~/.fresh-mac-setup directory is read as a compatibility fallback.
Plan/check never write reports, save choices, unlock agents, or sign in.
Exit codes: 0 success, 2 invalid usage, 10 manual action, 11 failed gate.
Legacy --dry-run and implicit apply commands remain supported.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }

ensure_state() {
  [[ "$DRY_RUN" == 1 ]] && return 0
  mkdir -p "$COMPLETED_DIR" "$ORIGINALS_DIR"
  touch "$INSTALL_MANIFEST" "$PATH_MANIFEST" "$LOG_FILE"
  chmod 700 "$STATE_DIR" "$COMPLETED_DIR" "$ORIGINALS_DIR"
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

confirm() {
  local prompt="$1" answer
  [[ "$DRY_RUN" == 1 || "$ASSUME_YES" == 1 ]] && return 0
  [[ -t 0 ]] || { err "$prompt needs terminal input"; return 1; }
  printf '%s [y/N]: ' "$prompt"
  IFS= read -r answer || return 1
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]]
}

confirm_phase_run() {
  local phase="$1" answer
  [[ "$DRY_RUN" == 1 || "$ASSUME_YES" == 1 ]] && return 0
  [[ -t 0 ]] || { err "Phase $phase approval needs terminal input"; return 1; }
  printf 'Run Phase %s now? [Enter] run  q quit: ' "$phase"
  IFS= read -r answer || return 1
  [[ -z "$answer" || "$answer" == y || "$answer" == Y ]] && return 0
  [[ "$answer" == q || "$answer" == Q ]] && return 1
  warn "Enter runs the phase; q stops safely."
  return 1
}

ask() {
  local prompt="$1" default="$2" pattern="$3" answer
  if [[ "$DRY_RUN" == 1 ]]; then printf '%s\n' "$default"; return 0; fi
  [[ -t 0 ]] || { err "$prompt needs terminal input"; return 1; }
  while :; do
    printf '%s [%s]: ' "$prompt" "$default" >&2
    IFS= read -r answer || return 1
    [[ -n "$answer" ]] || answer="$default"
    if [[ "$answer" =~ $pattern ]]; then printf '%s\n' "$answer"; return 0; fi
    warn "Enter a valid value."
  done
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

track_name() {
  case "$TRACK" in
    1) printf 'GitHub only\n' ;;
    2) printf 'Azure DevOps only\n' ;;
    3) printf 'GitHub + Azure DevOps\n' ;;
    4) printf 'None of the above (self-managed authentication)\n' ;;
  esac
}

track_value() {
  case "$TRACK" in
    1) printf 'github\n' ;;
    2) printf 'azure\n' ;;
    3) printf 'github+azure\n' ;;
    4) printf 'custom\n' ;;
  esac
}

toml_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

uses_github() { [[ "$TRACK" == 1 || "$TRACK" == 3 ]]; }
uses_azure() { [[ "$TRACK" == 2 || "$TRACK" == 3 ]]; }
uses_node() { [[ "$STACK" == node || "$STACK" == both ]]; }
uses_python() { [[ "$STACK" == python || "$STACK" == both ]]; }

source "$PROJECT_DIR/src/setup/choices.sh"

phase_fingerprint() {
  local schema inputs application_catalog_hash implementation policy_hash=none
  application_catalog_hash="$(awk -F '\t' '$2 == "required"' "$DAY_ONE_APP_CATALOG" | shasum -a 256 | awk '{print $1}')" || return 1
  [[ -z "${WORKSTATION_POLICY:-}" || ! -r "$WORKSTATION_POLICY" ]] || policy_hash="$(shasum -a 256 "$WORKSTATION_POLICY" | awk '{print $1}')"
  eval "schema=\${PHASE_SCHEMA_$1}"
  implementation="$(day_one_phase_implementation_hash "$PROJECT_DIR" "$1")" || return 1
  case "$1" in
    01) inputs="$TRACK|$STACK|$GIT_NAME|$GIT_EMAIL|$PRIMARY_IDE" ;;
    02) inputs='foundation' ;;
    03) inputs="security|$TRACK|$AUTH_MODE|applications=$application_catalog_hash" ;;
    04) inputs="$TRACK|$STACK|$GIT_NAME|$GIT_EMAIL|$PRIMARY_IDE|$AUTH_MODE|applications=$application_catalog_hash" ;;
    05) inputs="$TRACK|$AUTH_MODE|$GIT_NAME|$GIT_EMAIL|$PRIMARY_IDE|$DOTFILES_REPO|$DOTFILES_VERSIONING" ;;
    06) inputs="$STACK" ;;
    07) inputs="vscode-base|primary-ide=$PRIMARY_IDE|applications=$application_catalog_hash" ;;
    08) inputs="$TRACK|$STACK|$GIT_NAME|$GIT_EMAIL|$PRIMARY_IDE|$AUTH_MODE|$DOTFILES_REPO|$DOTFILES_VERSIONING|applications=$application_catalog_hash" ;;
  esac
  case "$1" in 04|08) inputs+="|https-helper=${HTTPS_HELPER:-existing}|github-repo=${GITHUB_REPO:-}|azure-repo=${AZURE_REPO:-}" ;; esac
  [[ "$1" != 04 ]] || inputs+="|github-clone-dir=${GITHUB_CLONE_DIR:-none}|azure-clone-dir=${AZURE_CLONE_DIR:-none}"
  { printf 'dependency-schema=2\n'; printf 'phase-schema=%s\n' "$schema"; printf 'implementation=%s\n' "$implementation";
    printf 'inputs=%s\n' "$inputs|deployment=${DEPLOYMENT_MODE:-personal}|policy=$policy_hash|preset=${PRESET:-recommended-productivity}|layout=${FOLDER_LAYOUT:-}|ghq=${GHQ_CHOICE:-}|root=${FOLDER_GHQ_ROOT:-}|dotfiles=$DOTFILES_VERSIONING|shell=$SHELL_CHOICE|prompt=$PROMPT_CHOICE"; } \
    | shasum -a 256 | awk '{print $1}'
}

phase_next() {
  PHASE_PENDING_ITEM="$1"
  PHASE_NEXT_ACTION="${2:-Review the named step in the phase guide, complete it, and rerun this phase.}"
}

phase_step_done() {
  PHASE_COMPLETED_ITEMS="${PHASE_COMPLETED_ITEMS}${PHASE_COMPLETED_ITEMS:+$'\n'}$1"
  PHASE_PENDING_ITEM=""
  PHASE_NEXT_ACTION=""
}

phase_gate_failed() {
  PHASE_FAILED_ITEMS="${PHASE_FAILED_ITEMS}${PHASE_FAILED_ITEMS:+$'\n'}$1"
}

phase_done() {
  local marker="$COMPLETED_DIR/$1" expected
  [[ -r "$marker" ]] || return 1
  expected="$(phase_fingerprint "$1")" || return 1
  [[ -n "$expected" && "$(sed -n '1p' "$marker")" == "$expected" ]]
}

source "$PROJECT_DIR/src/setup/installation.sh"

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

record_managed_targets_before_apply() {
  local managed_output target source_entry
  managed_output="$(chezmoi managed -p absolute)" || {
    err "Could not enumerate the existing dotfiles source; nothing was applied."
    return "$EX_GATE"
  }
  [[ -n "$managed_output" ]] || {
    err "The existing dotfiles source has no managed targets; nothing was applied."
    return "$EX_GATE"
  }
  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    [[ "$target" == "$HOME"/* && "$target" != "$HOME" ]] || {
      err "Refusing to apply a chezmoi target outside HOME: $target"
      return "$EX_GATE"
    }
    source_entry="$(chezmoi source-path "$target" 2>/dev/null || true)"
    if [[ -d "$source_entry" && ! -L "$source_entry" ]]; then
      if [[ ! -d "$target" ]]; then
        ensure_state
        append_unique "$PATH_MANIFEST" "created-dir"$'\t'"$target"$'\t-'
      fi
    else
      record_path_before_write "$target"
    fi
  done <<<"$managed_output"
}

source "$SCRIPT_DIR/../src/setup/phases/01-decisions.sh"
source "$SCRIPT_DIR/../src/setup/phases/02-foundation.sh"
source "$SCRIPT_DIR/../src/setup/phases/03-security.sh"
source "$SCRIPT_DIR/../src/setup/phases/04-hosting.sh"
source "$SCRIPT_DIR/../src/setup/phases/05-dotfiles.sh"
source "$SCRIPT_DIR/../src/setup/phases/06-toolchains.sh"
source "$SCRIPT_DIR/../src/setup/phases/07-editor.sh"
source "$SCRIPT_DIR/../src/setup/phases/08-verification.sh"

phase_exit_report() {
  local rc="$1" item
  [[ "$rc" -eq 0 ]] && return 0
  printf '\n%s%s⛔ Phase %s is incomplete%s\n' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_RED" "$CURRENT_PHASE" "$DAY_ONE_UI_RESET" >&2
  ui_rule >&2
  if [[ -n "$PHASE_COMPLETED_ITEMS" ]]; then
    printf 'Completed in this attempt:\n' >&2
    while IFS= read -r item; do [[ -n "$item" ]] && printf '  %s✓%s %s\n' "$DAY_ONE_UI_GREEN" "$DAY_ONE_UI_RESET" "$item" >&2; done <<<"$PHASE_COMPLETED_ITEMS"
  else
    printf 'Completed in this attempt:\n  %sℹ%s  No phase gate completed before the stop.\n' "$DAY_ONE_UI_BLUE" "$DAY_ONE_UI_RESET" >&2
  fi
  printf 'Still required:\n' >&2
  if [[ -n "$PHASE_FAILED_ITEMS" ]]; then
    while IFS= read -r item; do [[ -n "$item" ]] && printf '  %s✗%s %s\n' "$DAY_ONE_UI_RED" "$DAY_ONE_UI_RESET" "$item" >&2; done <<<"$PHASE_FAILED_ITEMS"
  fi
  [[ -n "$PHASE_PENDING_ITEM" ]] && printf '  %s○ %s%s\n' "$DAY_ONE_UI_DIM" "$PHASE_PENDING_ITEM" "$DAY_ONE_UI_RESET" >&2
  printf 'Next action:\n  %s→%s %s\n' "$DAY_ONE_UI_YELLOW" "$DAY_ONE_UI_RESET" "${PHASE_NEXT_ACTION:-Open the phase guide and complete the first unchecked item.}" >&2
  printf 'Guide: %s\n' "$(phase_doc "$CURRENT_PHASE")" >&2
  printf 'Earlier completed phases remain saved; this phase was not marked complete.\n' >&2
}

run_phase() {
  local phase="$1" rc
  phase_fingerprint "$phase" >/dev/null || return 1
  CURRENT_PHASE="$phase"
  PHASE_COMPLETED_ITEMS=""
  PHASE_FAILED_ITEMS=""
  PHASE_PENDING_ITEM=""
  PHASE_NEXT_ACTION=""
  trap 'phase_exit_report "$?"' EXIT
  if [[ "$phase" =~ ^0[3-8]$ && "$INSTALLATION_CENTRE_RAN" != 1 ]] \
     && ! installation_centre_done; then
    phase_next "Required Installation Centre" \
      "Install or approve every required app and command-line tool, then rerun Phase $phase."
    warn "Required software must be ready before Phase $phase can configure it."
    run_installation_centre || return $?
  fi
  case "$phase" in
    01) phase_01 ;; 02) phase_02 ;; 03) phase_03 ;;
    04) phase_04 ;; 05) phase_05 ;; 06) phase_06 ;;
    07) phase_07 ;; 08) phase_08 ;;
    *) err "phase must be 01 through 08"; return 2 ;;
  esac
  rc=$?
  [[ "$rc" == 0 ]] || return "$rc"
  mark_phase_done "$phase" || return $?
  trap - EXIT
  CURRENT_PHASE=""
}

show_status() {
  local phase status
  ui_title '📊' 'Day One Mac status'
  printf '  Track: %s\n' "${TRACK:-not selected}"
  printf '  Stack: %s\n' "${STACK:-not selected}"
  printf '  Preset: %s\n' "${PRESET:-recommended-productivity}"
  printf '  Primary IDE: %s\n' "${PRIMARY_IDE:-not selected}"
  printf '  Git authentication: %s\n' "${AUTH_MODE:-1password}"
  [[ "$AUTH_MODE" != https ]] || printf '  HTTPS helper: %s\n' "${HTTPS_HELPER:-existing}"
  printf '  Dotfiles: %s\n' "${DOTFILES_VERSIONING:-not selected}"
  printf '  Shell: %s | Prompt: %s\n' "${SHELL_CHOICE:-not selected}" "${PROMPT_CHOICE:-not selected}"
  printf '  Early macOS settings: %s\n' "${MACOS_SETTINGS_PLAN:-not selected}"
  printf '  Optional plan: %s\n' "${OPTIONAL_MODULES:-none}"
  printf '  State: %s\n\n' "$STATE_DIR"
  info 'Phase markers are recorded completion, not a live health check. Use setup --check.'
  for phase in 01 02 03 04 05 06 07 08; do
    if phase_done "$phase"; then
      status='✓ done'; ui_status success "$status  $phase — $(phase_title "$phase")"
    elif [[ -f "$COMPLETED_DIR/$phase" ]]; then
      status='⚠ changed — revalidate'; ui_status warning "$status  $phase — $(phase_title "$phase")"
    else
      status='○ pending'; ui_status pending "$status  $phase — $(phase_title "$phase")"
    fi
    if [[ "$phase" == 02 ]]; then
      if installation_centre_done; then
        ui_status success '✓ done  Installation Centre — required software ready'
      elif [[ -f "$COMPLETED_DIR/installation-centre" ]]; then
        ui_status warning '⚠ changed — revalidate  Installation Centre — required software'
      else
        ui_status pending '○ pending  Installation Centre — required software'
      fi
    fi
  done
}

# Explicit required-phase actions stay in this runner so legacy phase execution
# and the new contract cannot acquire different mutation implementations.
set_setup_action() {
  [[ -z "$SETUP_ACTION" || "$SETUP_ACTION" == "$1" ]] || {
    err 'Choose only one of --plan, --apply, --check, --resume, or --status.'; exit 2; }
  SETUP_ACTION="$1"
}

required_phase_selected() {
  [[ -z "$REQUESTED_PHASES" || " $REQUESTED_PHASES " == *" ${1#0} "* ]]
}

configuration_preflight_for_selected_phases() {
  local phase
  # Installation Centre installs selected software, not configuration files.
  [[ "$RUN_INSTALLATION_CENTRE" != 1 ]] || return 0
  for phase in 03 04 05 06 07 08; do
    if required_phase_selected "$phase"; then
      configuration_unmanaged_preflight
      return $?
    fi
  done
  return 0
}

source "$PROJECT_DIR/src/setup/inspection.sh"

run_required_action_phase() {
  local phase="$1" action="$2"
  if [[ "$action" == resume ]] && phase_done "$phase"; then
    check_required_phase "$phase"
    if [[ "$CHECK_RESULT" == pass || "$CHECK_RESULT" == not-required ]]; then
      ok "Phase $phase recorded current and local check passed — skipping"
      return 0
    fi
    info "Phase $phase needs revalidation ($CHECK_RESULT); running its existing gates."
  fi
  run_phase "$phase"
}

run_macos_settings_checkpoint() {
  local settings_script="$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" settings_status rc answer
  if [[ "${DEPLOYMENT_MODE:-personal}" == managed ]]; then
    info 'Managed Mac: preferences remain with the policy owner; local checkpoint skipped.'; return 0
  fi
  settings_status="$(state_value macos-settings-status)"
  case "$MACOS_SETTINGS_PLAN" in
    ask)
      if [[ "$settings_status" == completed ]]; then
        ok "Early macOS settings already completed — use 'day-one-mac macos-settings --status' to review"
        return 0
      fi
      if [[ "$DRY_RUN" == 1 ]]; then
        info 'would ask after Phase 1 whether to configure or skip optional macOS preferences'
        return 0
      fi
      if [[ "$ASSUME_YES" == 1 ]]; then
        answer=configure
      else
        [[ -t 0 ]] || { err 'The macOS settings choice needs terminal input.'; return "$EX_MANUAL"; }
        printf '\nmacOS preferences are optional and run before development tools.\n'
        printf '[Enter] configure Finder, Dock, keyboard and trackpad   s skip   q stop: '
        IFS= read -r answer || return "$EX_MANUAL"
        case "$answer" in
          ''|c|C) answer=configure ;;
          s|S) answer=skip ;;
          q|Q) warn 'Stopped safely before the optional macOS settings choice.'; return "$EX_MANUAL" ;;
          *) warn 'Enter configures the preferences; s skips them; q stops safely.'; return "$EX_MANUAL" ;;
        esac
      fi
      MACOS_SETTINGS_PLAN="$answer"
      save_state_value macos-settings-plan "$MACOS_SETTINGS_PLAN"
      save_state_value auth-mode "$AUTH_MODE"
      run_macos_settings_checkpoint
      ;;
    skip)
      info "Early macOS settings were intentionally skipped; run 'day-one-mac macos-settings' later."
      save_state_value macos-settings-status skipped
      ;;
    configure)
      if [[ "$settings_status" == completed ]]; then
        ok "Early macOS settings already completed — use 'day-one-mac macos-settings --status' to review"
      elif [[ "$DRY_RUN" == 1 ]]; then
        print_command "$settings_script" --wizard
        info "would run the optional macOS Settings Wizard before Phase 2"
      else
        [[ -x "$settings_script" ]] || { err "macOS settings tool is missing or not executable: $settings_script"; return "$EX_GATE"; }
        if "$settings_script" --wizard; then rc=0; else rc=$?; fi
        if [[ "$rc" -ne 0 ]]; then
          warn "The optional settings wizard did not complete. Choose skip in the main wizard or rerun it."
          return "$EX_MANUAL"
        fi
      fi
      ;;
    *) err "Unknown early macOS settings choice: $MACOS_SETTINGS_PLAN"; return 2 ;;
  esac
}

# Sourcing exposes the real runner/modules to tests without executing setup.
[[ "${BASH_SOURCE[0]}" == "$0" ]] || return 0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan|--apply|--check|--resume) set_setup_action "${1#--}" ;;
    --json) JSON_OUTPUT=1 ;;
    --accept-preparation) ACCEPT_PREPARATION=1 ;;
    --guided) GUIDED=1 ;;
    --phase)
      shift
      [[ $# -gt 0 && "$1" =~ ^0?[1-8]$ ]] || { err "--phase needs 01–08"; exit 2; }
      REQUESTED_PHASES="$REQUESTED_PHASES ${1#0}"
      GUIDED=0
      ;;
    --track) shift; [[ $# -gt 0 ]] || { err "--track needs 1, 2, 3, or 4"; exit 2; }; TRACK="$1"; TRACK_EXPLICIT=1 ;;
    --stack) shift; [[ $# -gt 0 ]] || { err "--stack needs node, python, or both"; exit 2; }; STACK="$1" ;;
    --layout) shift; [[ $# -gt 0 ]] || exit 2; FOLDER_LAYOUT="$1"; FOLDER_CHOICES_EXPLICIT=1 ;;
    --ghq) shift; [[ $# -gt 0 ]] || exit 2; GHQ_CHOICE="$1"; FOLDER_CHOICES_EXPLICIT=1 ;;
    --ghq-root) shift; [[ $# -gt 0 ]] || exit 2; FOLDER_GHQ_ROOT="$1"; FOLDER_CHOICES_EXPLICIT=1 ;;
    --name) shift; [[ $# -gt 0 ]] || { err "--name needs a value"; exit 2; }; GIT_NAME="$1" ;;
    --email) shift; [[ $# -gt 0 ]] || { err "--email needs a value"; exit 2; }; GIT_EMAIL="$1" ;;
    --deployment) shift; [[ $# -gt 0 ]] || exit 2; DEPLOYMENT_MODE="$1" ;;
    --policy) shift; [[ $# -gt 0 ]] || exit 2; WORKSTATION_POLICY="$1" ;;
    --preset) shift; [[ $# -gt 0 ]] || { err "--preset needs core or recommended-productivity"; exit 2; }; PRESET="$1" ;;
    --primary-ide) shift; [[ $# -gt 0 ]] || { err "--primary-ide needs vscode or other"; exit 2; }; PRIMARY_IDE="$1" ;;
    --dotfiles-repo) shift; [[ $# -gt 0 ]] || { err "--dotfiles-repo needs a URL"; exit 2; }; DOTFILES_REPO="$1"; DOTFILES_VERSIONING=git; DOTFILES_EXPLICIT=1 ;;
    --new-dotfiles) DOTFILES_REPO=""; DOTFILES_EXPLICIT=1 ;;
    --dotfiles-versioning) shift; [[ $# -gt 0 ]] || { err "--dotfiles-versioning needs none, git or local"; exit 2; }; DOTFILES_VERSIONING="$1"; [[ "$1" == git ]] || { DOTFILES_REPO=""; DOTFILES_EXPLICIT=1; } ;;
    --local-dotfiles) DOTFILES_REPO=""; DOTFILES_VERSIONING=local; DOTFILES_EXPLICIT=1 ;;
    --shell) shift; [[ $# -gt 0 ]] || exit 2; SHELL_CHOICE="$1" ;;
    --prompt) shift; [[ $# -gt 0 ]] || exit 2; PROMPT_CHOICE="$1" ;;
    --auth-mode) shift; [[ $# -gt 0 ]] || { err "--auth-mode needs 1password, keychain, external, or https"; exit 2; }; AUTH_MODE="$1" ;;
    --https-helper) shift; [[ $# -gt 0 ]] || { err '--https-helper needs gcm or existing'; exit 2; }; HTTPS_HELPER="$1" ;;
    --github-repo) shift; [[ $# -gt 0 ]] || { err '--github-repo needs a clone URL'; exit 2; }; GITHUB_REPO="$1" ;;
    --azure-repo) shift; [[ $# -gt 0 ]] || { err '--azure-repo needs a clone URL'; exit 2; }; AZURE_REPO="$1" ;;
    --github-clone-dir) shift; [[ $# -gt 0 ]] || exit 2; GITHUB_CLONE_DIR="$1" ;;
    --azure-clone-dir) shift; [[ $# -gt 0 ]] || exit 2; AZURE_CLONE_DIR="$1" ;;
    --macos-settings) shift; [[ $# -gt 0 ]] || { err "--macos-settings needs ask, configure, or skip"; exit 2; }; MACOS_SETTINGS_PLAN="$1" ;;
    --skip-macos-settings) MACOS_SETTINGS_PLAN=skip ;;
    --app-install-policy) shift; [[ $# -gt 0 ]] || { err "--app-install-policy needs prompt, homebrew, or check-only"; exit 2; }; APP_INSTALL_POLICY="$1" ;;
    --install-centre) RUN_INSTALLATION_CENTRE=1; GUIDED=0 ;;
    --ssh-pin)
      # A bare --ssh-pin means "whatever my track needs", matching the
      # `day-one-mac ssh-pin` subcommand.
      if [[ $# -gt 1 && "$2" =~ ^(github|azure|both)$ ]]; then
        shift; SSH_PIN_PROVIDER="$1"
      elif [[ $# -gt 1 && "$2" != -* ]]; then
        err "--ssh-pin needs github, azure, or both"; exit 2
      else
        SSH_PIN_PROVIDER=both
      fi
      GUIDED=0
      ;;
    --status) set_setup_action status; SHOW_STATUS=1; GUIDED=0 ;;
    --reset-progress) RESET_PROGRESS=1; GUIDED=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

# Validate action combinations before locks, selections, installers or writes.
if [[ -n "$SETUP_ACTION" ]]; then
  if [[ "$RESET_PROGRESS" == 1 || "$RUN_INSTALLATION_CENTRE" == 1 || -n "$SSH_PIN_PROVIDER" || "$DRY_RUN" == 1 ]]; then
    err 'Required-phase actions cannot be combined with --dry-run, --reset-progress, --install-centre or --ssh-pin.'; exit 2
  fi
  case "$SETUP_ACTION" in
    plan|check|status)
      [[ "$ASSUME_YES" == 0 && "$ACCEPT_PREPARATION" == 0 ]] || {
        err '--yes and --accept-preparation are apply/resume options, not inspection options.'; exit 2; } ;;
  esac
fi
if [[ "$JSON_OUTPUT" == 1 && "$SETUP_ACTION" != plan && "$SETUP_ACTION" != check && "$SETUP_ACTION" != status ]]; then
  err '--json requires --plan, --check or --status.'; exit 2
fi
if [[ "$ACCEPT_PREPARATION" == 1 && "$SETUP_ACTION" != apply && "$SETUP_ACTION" != resume ]]; then
  err '--accept-preparation requires --apply or --resume.'; exit 2
fi
if [[ "$SETUP_ACTION" == resume ]]; then
  for option in "${ORIGINAL_ARGS[@]}"; do
    case "$option" in
      --deployment|--policy|--shell|--prompt|--layout|--ghq|--ghq-root|--track|--stack|--name|--email|--preset|--primary-ide|--dotfiles-repo|--new-dotfiles|--dotfiles-versioning|--local-dotfiles|--auth-mode|--https-helper|--github-repo|--azure-repo|--github-clone-dir|--azure-clone-dir|--macos-settings|--skip-macos-settings)
        err '--resume reuses saved choices; use --plan and --apply to change them.'; exit 2 ;;
    esac
  done
  for selection in folder-layout ghq-choice track stack git-name git-email preset primary-ide auth-mode dotfiles-versioning macos-settings-plan; do
    [[ -n "$(state_value "$selection")" ]] || {
      err "No complete saved selection ($selection is missing). Run --plan then --apply first."; exit 2; }
  done
fi
if [[ "$SETUP_ACTION" == plan || "$SETUP_ACTION" == check || "$SETUP_ACTION" == resume ]]; then
  [[ -n "${TRACK:-$(state_value track)}" && -n "${STACK:-$(state_value stack)}" ]] || {
    err 'Supply --track and --stack, or complete setup choices first. Inspection never guesses these selections.'; exit 2; }
  # Load and validate without prompting. Defaulted choices are shown in output;
  # Phase 1 reports missing identity instead of inventing one.
  DRY_RUN=1
  load_or_choose_selections
  DRY_RUN=0
fi
if [[ "$SETUP_ACTION" == plan || "$SETUP_ACTION" == check ]]; then
  if [[ "$SETUP_ACTION" == check ]]; then day_one_require_apple_silicon || exit 2; fi
  inspect_required_actions "$SETUP_ACTION"
  exit $?
fi

if [[ -z "$APP_INSTALL_POLICY" ]]; then
  if [[ "$DRY_RUN" == 1 ]]; then APP_INSTALL_POLICY=prompt
  elif [[ -t 0 ]]; then APP_INSTALL_POLICY=prompt
  else APP_INSTALL_POLICY=check-only
  fi
fi
[[ "$APP_INSTALL_POLICY" =~ ^(prompt|homebrew|check-only)$ ]] || {
  err "--app-install-policy must be prompt, homebrew, or check-only"
  exit 2
}

day_one_require_apple_silicon || exit 2

if day_one_uses_legacy_state; then
  warn "Using pre-rename setup state at $STATE_ROOT; saved progress remains valid." >&2
fi

if [[ "$SETUP_ACTION" == apply || "$SETUP_ACTION" == resume ]]; then
  if required_phase_selected 01 && [[ "$ASSUME_YES" == 1 && "$ACCEPT_PREPARATION" != 1 ]]; then
    err 'Phase 1 needs an explicit preparation attestation: --accept-preparation. --yes alone is not evidence of a backup.'
    exit "$EX_MANUAL"
  fi
fi

if [[ "$DRY_RUN" != 1 && "$SHOW_STATUS" != 1 ]]; then
  day_one_serialize setup "$0" "${ORIGINAL_ARGS[@]}"
fi

if [[ "$RESET_PROGRESS" == 1 ]]; then
  if [[ ! -d "$COMPLETED_DIR" ]]; then info "no day-one-mac progress exists"; exit 0; fi
  archive="$STATE_DIR/completed-$(date -u '+%Y%m%dT%H%M%SZ')"
  if [[ "$DRY_RUN" == 1 ]]; then info "would move $COMPLETED_DIR to $archive"; exit 0; fi
  mv "$COMPLETED_DIR" "$archive"
  mkdir -p "$COMPLETED_DIR"; chmod 700 "$COMPLETED_DIR"
  ok "completion markers archived to $archive"
  exit 0
fi

# Pinning is a standalone maintenance action: read the saved track rather than
# entering the selection wizard, so it never prompts for unrelated choices.
if [[ -n "$SSH_PIN_PROVIDER" ]]; then
  ui_title '📌' 'Pin a provider public key from 1Password'
  TRACK="${TRACK:-$(state_value track)}"
  ssh_pin_failures=0
  case "$SSH_PIN_PROVIDER" in
    github) export_provider_public_key github || ssh_pin_failures=1 ;;
    azure)  export_provider_public_key azure || ssh_pin_failures=1 ;;
    both)
      [[ "$TRACK" =~ ^[1234]$ ]] || {
        err "No saved hosting track, so 'both' cannot decide which keys to pin."
        err "Name the provider instead: --ssh-pin github, or --ssh-pin azure."
        exit 2
      }
      if uses_github; then export_provider_public_key github || ssh_pin_failures=1; fi
      if uses_azure; then export_provider_public_key azure || ssh_pin_failures=1; fi
      ;;
  esac
  [[ "$ssh_pin_failures" == 0 ]] || { err "At least one provider pin failed; review the per-provider results above."; exit 1; }
  exit 0
fi

if [[ "$SHOW_STATUS" == 1 ]]; then
  required_load_recorded_choices
  if [[ -n "$TRACK" && "$(state_value track-schema-version)" != "$TRACK_SCHEMA_VERSION" && "$TRACK_EXPLICIT" != 1 ]]; then
    warn "Saved track uses the retired numbering; rerun with --track 1, 2, 3, or 4." >&2
  fi
  if [[ "$JSON_OUTPUT" == 1 ]]; then inspect_required_actions status; else show_status; fi
  exit 0
fi

load_or_choose_selections
configuration_validate_choices || exit $?
deployment_preflight || exit $?
# Check ownership before Phase 3/4 can change shared SSH/Git targets, not just
# before Phase 5. Preparation-only runs do not change ownership. A manager
# opt-out is never an implicit detach operation.
configuration_preflight_for_selected_phases || exit $?
if [[ "$RUN_INSTALLATION_CENTRE" == 1 ]] || required_phase_selected 03 || required_phase_selected 04 \
    || required_phase_selected 05 || required_phase_selected 06 || required_phase_selected 07 || required_phase_selected 08; then
  folders_validate_choices
fi
if [[ -n "$FOLDER_LAYOUT" || -n "$GHQ_CHOICE" ]]; then
  folders_validate_choices
  folders_save_choices
fi
save_state_value project-root "$PROJECT_DIR"
save_state_value track "$TRACK"
save_state_value track-schema-version "$TRACK_SCHEMA_VERSION"
save_state_value stack "$STACK"
[[ -n "$GIT_NAME" ]] && save_state_value git-name "$GIT_NAME"
[[ -n "$GIT_EMAIL" ]] && save_state_value git-email "$GIT_EMAIL"
save_state_value deployment-mode "$DEPLOYMENT_MODE"
save_state_value workstation-policy "$WORKSTATION_POLICY"
save_state_value preset "$PRESET"
save_state_value auth-mode "$AUTH_MODE"
save_state_value https-helper "$HTTPS_HELPER"
save_state_value github-verification-repo "$GITHUB_REPO"
save_state_value azure-verification-repo "$AZURE_REPO"
save_state_value github-clone-dir "$GITHUB_CLONE_DIR"
save_state_value azure-clone-dir "$AZURE_CLONE_DIR"
save_state_value primary-ide "$PRIMARY_IDE"
if [[ "$DOTFILES_EXPLICIT" == 1 || -n "$DOTFILES_REPO" ]]; then
  save_state_value dotfiles-repo "$DOTFILES_REPO"
fi
save_state_value dotfiles-versioning "$DOTFILES_VERSIONING"
save_state_value shell-choice "$SHELL_CHOICE"
save_state_value prompt-choice "$PROMPT_CHOICE"
save_state_value configuration-schema 1
save_state_value macos-settings-plan "$MACOS_SETTINGS_PLAN"

if [[ "$SETUP_ACTION" == apply || "$SETUP_ACTION" == resume ]]; then
  for phase in 01 02 03 04 05 06 07 08; do
    required_phase_selected "$phase" || continue
    run_required_action_phase "$phase" "$SETUP_ACTION"
    # Selected phases stay bounded like legacy --phase; only a full run adds
    # the optional settings checkpoint and the post-foundation install stage.
    if [[ -z "$REQUESTED_PHASES" ]]; then
      if [[ "$phase" == 01 ]]; then run_macos_settings_checkpoint; fi
      if [[ "$phase" == 02 ]] && ! installation_centre_done; then run_installation_centre; fi
    fi
  done
  exit 0
fi

if [[ "$RUN_INSTALLATION_CENTRE" == 1 ]]; then
  run_installation_centre
  exit 0
fi

if [[ -n "$REQUESTED_PHASES" ]]; then
  for requested in $REQUESTED_PHASES; do printf -v phase '%02d' "$requested"; run_phase "$phase"; done
  exit 0
fi

ui_title '🚀' 'Day One Mac guided setup — 8 required phases'
info "Track $TRACK — $(track_name)"
info "Stack — $STACK"
info "Optional databases, AI, MCP and VS Code profiles are not run here."
for phase in 01 02 03 04 05 06 07 08; do
  if phase_done "$phase" && [[ "$DRY_RUN" != 1 ]]; then
    ok "Phase $phase already current — $(phase_title "$phase")"
  else
    if [[ "$DRY_RUN" != 1 ]] && ! confirm_phase_run "$phase"; then
      warn "Stopped before Phase $phase; no completion was recorded."
      exit "$EX_MANUAL"
    fi
    run_phase "$phase"
  fi
  if [[ "$phase" == 01 ]]; then run_macos_settings_checkpoint; fi
  if [[ "$phase" == 02 ]]; then
    if installation_centre_done && [[ "$DRY_RUN" != 1 ]]; then
      ok 'Installation Centre already current — required software is ready'
    else
      run_installation_centre
    fi
  fi
done
printf '\n'
ok "Required Day One Mac setup complete. Optional extras begin after Phase 8."
info "When the setup is stable, preview record compaction with: day-one-mac finalize"
info "Do not delete ~/.day-one-mac manually; read operations/FINALIZE.md before detaching it."
