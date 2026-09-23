#!/usr/bin/env bash
# Minimal, resumable setup for a genuinely clean Mac.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DIR="$PROJECT_DIR/docs"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/application-ownership.sh"
source "$SCRIPT_DIR/lib/platform.sh"
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
RESET_PROGRESS=0
SSH_PIN_PROVIDER=""
RUN_INSTALLATION_CENTRE=0
INSTALLATION_CENTRE_RAN=0
GUIDED=1
REQUESTED_PHASES=""
TRACK=""
STACK=""
GIT_NAME=""
GIT_EMAIL=""
DOTFILES_REPO=""
DOTFILES_VERSIONING=""
AUTH_MODE=""
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

# Bump only the phase whose implementation contract changed. This avoids
# making all eight completed phases stale after an unrelated runner edit.
PHASE_SCHEMA_01=4
PHASE_SCHEMA_02=3
PHASE_SCHEMA_03=6
PHASE_SCHEMA_04=5
PHASE_SCHEMA_05=12
PHASE_SCHEMA_06=2
PHASE_SCHEMA_07=3
PHASE_SCHEMA_08=9

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

  --guided                    run the eight required phases (default)
  --phase NN                  run one required phase; repeatable
  --track 1|2|3               1 GitHub; 2 Azure DevOps; 3 both
  --stack node|python|both    language toolchain selection
  --auth-mode MODE            1password (default), keychain, external, or https
  --name "Full Name"          Git author name
  --email ADDRESS             primary Git author email
  --dotfiles-repo URL         apply an existing private chezmoi source
  --new-dotfiles              create or keep a new chezmoi source
  --dotfiles-versioning MODE  git (private remote) or local (no Git gate)
  --local-dotfiles            shorthand for --new-dotfiles --dotfiles-versioning local
  --macos-settings MODE       ask, configure, or skip the early settings wizard
  --skip-macos-settings       shorthand for --macos-settings skip
  --app-install-policy MODE   prompt, homebrew, or check-only for missing apps
  --install-centre            install/revalidate required apps and CLI tools, then exit
  --ssh-pin [PROVIDER]        save 1Password public keys to ~/.ssh, then exit
                              PROVIDER is github, azure, or both (default: the saved track)
  --status                    show selections and phase completion
  --reset-progress            archive completion markers; keep installed files
  --dry-run                   preview commands and write nothing
  --yes                       accept ordinary setup confirmations
  -h, --help                  show this help

Progress, logs, backups and the exact install manifest live under:
  ~/.day-one-mac/

An existing ~/.fresh-mac-setup directory is read as a compatibility fallback.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }

# macOS ships no timeout(1). Run a command with a deadline, writing its combined
# output to the file named first. Returns the command's exit status, or 124 when
# the deadline was reached and the command was killed. Used for calls that can
# raise a GUI prompt and would otherwise block the runner indefinitely.
run_with_deadline() {
  local output_file="$1" seconds="$2"
  shift 2
  local cmd_pid watch_pid status marker="${output_file}.deadline"
  rm -f "$marker"
  : > "$output_file"
  "$@" >"$output_file" 2>&1 &
  cmd_pid=$!
  # Record the deadline BEFORE signalling: the main shell's wait returns as soon
  # as the child dies, so writing the marker after the kill races against the
  # check below and intermittently reports a timeout as an ordinary failure.
  ( sleep "$seconds"
    if kill -0 "$cmd_pid" 2>/dev/null; then
      : > "$marker"
      kill -TERM "$cmd_pid" 2>/dev/null
    fi ) >/dev/null 2>&1 &
  watch_pid=$!
  set +e
  # The shell announces "Terminated" on stderr when it reaps a killed job;
  # silence that so a deadline reads as our own message, not shell noise.
  { wait "$cmd_pid"; status=$?; } 2>/dev/null
  kill -TERM "$watch_pid" >/dev/null 2>&1
  { wait "$watch_pid"; } >/dev/null 2>&1
  set -e
  if [[ -e "$marker" ]]; then
    rm -f "$marker"
    return 124
  fi
  return "$status"
}

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
  printf '%s\n' "$value" > "$STATE_DIR/$name"
  chmod 600 "$STATE_DIR/$name"
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
  esac
}

track_value() {
  case "$TRACK" in
    1) printf 'github\n' ;;
    2) printf 'azure\n' ;;
    3) printf 'github+azure\n' ;;
  esac
}

toml_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

uses_github() { [[ "$TRACK" == 1 || "$TRACK" == 3 ]]; }
uses_azure() { [[ "$TRACK" == 2 || "$TRACK" == 3 ]]; }
uses_node() { [[ "$STACK" == node || "$STACK" == both ]]; }
uses_python() { [[ "$STACK" == python || "$STACK" == both ]]; }

load_or_choose_selections() {
  local saved_track saved_track_schema
  if [[ -z "$TRACK" ]]; then
    saved_track="$(state_value track)"
    saved_track_schema="$(state_value track-schema-version)"
    if [[ -n "$saved_track" && "$saved_track_schema" != "$TRACK_SCHEMA_VERSION" ]]; then
      err "The saved track predates the current track numbering and cannot be reinterpreted safely."
      err "Choose it again explicitly: --track 1 (GitHub), 2 (Azure), or 3 (both)."
      exit 2
    fi
    TRACK="$saved_track"
  fi
  [[ -n "$STACK" ]] || STACK="$(state_value stack)"
  [[ -n "$GIT_NAME" ]] || GIT_NAME="$(state_value git-name)"
  [[ -n "$GIT_EMAIL" ]] || GIT_EMAIL="$(state_value git-email)"
  if [[ "$DOTFILES_EXPLICIT" != 1 && -z "$DOTFILES_REPO" ]]; then
    DOTFILES_REPO="$(state_value dotfiles-repo)"
  fi
  [[ -n "$DOTFILES_VERSIONING" ]] || DOTFILES_VERSIONING="$(state_value dotfiles-versioning)"
  # Existing saved setups predate this choice and always required private Git.
  [[ -n "$DOTFILES_VERSIONING" ]] || DOTFILES_VERSIONING=git
  [[ -n "$MACOS_SETTINGS_PLAN" ]] || MACOS_SETTINGS_PLAN="$(state_value macos-settings-plan)"
  [[ -n "$AUTH_MODE" ]] || AUTH_MODE="$(state_value auth-mode)"
  # Setups saved before this choice existed all used the 1Password agent.
  [[ -n "$AUTH_MODE" ]] || AUTH_MODE=1password

  [[ -n "$TRACK" ]] || TRACK="$(ask 'Hosting track: 1 GitHub, 2 Azure, 3 both' 1 '^[123]$')"
  [[ -n "$STACK" ]] || STACK="$(ask 'Stack: node, python, or both' both '^(node|python|both)$')"
  if [[ -z "$MACOS_SETTINGS_PLAN" ]]; then
    if [[ -n "$REQUESTED_PHASES" ]]; then MACOS_SETTINGS_PLAN=skip
    else MACOS_SETTINGS_PLAN="$(ask 'Early macOS settings: configure or skip' configure '^(configure|skip)$')"
    fi
  fi
  [[ "$TRACK" =~ ^[123]$ ]] || { err "track must be 1, 2, or 3"; exit 2; }
  [[ "$STACK" =~ ^(node|python|both)$ ]] || { err "stack must be node, python, or both"; exit 2; }
  [[ "$DOTFILES_VERSIONING" =~ ^(git|local)$ ]] || { err "dotfiles versioning must be git or local"; exit 2; }
  [[ "$MACOS_SETTINGS_PLAN" =~ ^(ask|configure|skip)$ ]] || { err "macOS settings choice must be ask, configure, or skip"; exit 2; }
  [[ "$AUTH_MODE" =~ ^(1password|keychain|external|https)$ ]] || {
    err "auth mode must be 1password, keychain, external, or https"; exit 2; }
  if [[ -n "$DOTFILES_REPO" && "$DOTFILES_VERSIONING" != git ]]; then
    err "--dotfiles-repo requires --dotfiles-versioning git"
    exit 2
  fi
}

phase_doc() {
  case "$1" in
    01) printf '%s/01-required/01-first-boot-and-decisions.md\n' "$DOC_DIR" ;;
    02) printf '%s/01-required/02-command-line-foundation.md\n' "$DOC_DIR" ;;
    03) printf '%s/01-required/03-security-and-ssh.md\n' "$DOC_DIR" ;;
    04) printf '%s/01-required/04-core-tools-and-hosting.md\n' "$DOC_DIR" ;;
    05) printf '%s/01-required/05-dotfiles-and-shell.md\n' "$DOC_DIR" ;;
    06) printf '%s/01-required/06-language-toolchains.md\n' "$DOC_DIR" ;;
    07) printf '%s/01-required/07-vscode-base.md\n' "$DOC_DIR" ;;
    08) printf '%s/01-required/08-verify-and-reproduce.md\n' "$DOC_DIR" ;;
  esac
}

phase_title() {
  case "$1" in
    01) printf 'First boot and decisions\n' ;;
    02) printf 'Command-line foundation\n' ;;
    03) printf 'Security and SSH\n' ;;
    04) printf 'Core tools and hosting\n' ;;
    05) printf 'Dotfiles and Starship\n' ;;
    06) printf 'Language toolchains and pnpm\n' ;;
    07) printf 'VS Code base\n' ;;
    08) printf 'Verify and reproduce\n' ;;
  esac
}

phase_fingerprint() {
  local doc doc_hash schema inputs application_catalog_hash
  doc="$(phase_doc "$1")"
  doc_hash="$(shasum -a 256 "$doc" | awk '{print $1}')"
  application_catalog_hash="$(shasum -a 256 "$DAY_ONE_APP_CATALOG" | awk '{print $1}')"
  eval "schema=\${PHASE_SCHEMA_$1}"
  case "$1" in
    01) inputs="$TRACK|$STACK|$GIT_NAME|$GIT_EMAIL" ;;
    02) inputs='foundation' ;;
    03) inputs="security|$AUTH_MODE|applications=$application_catalog_hash" ;;
    04) inputs="$TRACK|$STACK|$GIT_NAME|$GIT_EMAIL|$AUTH_MODE|applications=$application_catalog_hash" ;;
    05) inputs="$GIT_NAME|$GIT_EMAIL|$DOTFILES_REPO|$DOTFILES_VERSIONING" ;;
    06) inputs="$STACK" ;;
    07) inputs="vscode-base|applications=$application_catalog_hash" ;;
    08) inputs="$TRACK|$STACK|$DOTFILES_REPO|$DOTFILES_VERSIONING|applications=$application_catalog_hash" ;;
  esac
  { printf 'phase-schema=%s\n' "$schema"; printf 'document=%s\n' "$doc_hash";
    printf 'inputs=%s\n' "$inputs"; } \
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
  local marker="$COMPLETED_DIR/$1"
  [[ -r "$marker" ]] && [[ "$(sed -n '1p' "$marker")" == "$(phase_fingerprint "$1")" ]]
}

required_formulae() {
  printf '%s\n' chezmoi ghq git jq ripgrep starship zsh
  if uses_node; then printf '%s\n' fnm pnpm; fi
  uses_python && printf '%s\n' uv
  uses_github && printf '%s\n' gh
  uses_azure && printf '%s\n' azure-cli
  return 0
}

installation_centre_fingerprint() {
  local application_catalog_hash formulae_hash
  application_catalog_hash="$(awk -F '\t' '$0 !~ /^#/ && $2 == "required"' "$DAY_ONE_APP_CATALOG" | shasum -a 256 | awk '{print $1}')"
  formulae_hash="$(required_formulae | shasum -a 256 | awk '{print $1}')"
  {
    printf 'installation-centre-schema=%s\n' "$INSTALLATION_CENTRE_SCHEMA"
    printf 'track=%s\nstack=%s\n' "$TRACK" "$STACK"
    printf 'applications=%s\n' "$application_catalog_hash"
    printf 'formulae=%s\n' "$formulae_hash"
  } | shasum -a 256 | awk '{print $1}'
}

installation_centre_components_ready() {
  local app_id formula
  load_brew || return 1
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    day_one_app_detect "$app_id" || return 1
    day_one_app_is_satisfied || return 1
  done < <(required_application_ids)
  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    brew list --formula "$formula" >/dev/null 2>&1 || return 1
  done < <(required_formulae)
}

installation_centre_done() {
  local marker="$COMPLETED_DIR/installation-centre"
  [[ -r "$marker" ]] \
    && [[ "$(sed -n '1p' "$marker")" == "$(installation_centre_fingerprint)" ]] \
    && installation_centre_components_ready
}

mark_installation_centre_done() {
  local marker="$COMPLETED_DIR/installation-centre"
  [[ "$DRY_RUN" == 1 ]] && { ok 'would mark the Installation Centre complete'; return 0; }
  ensure_state
  installation_centre_fingerprint > "$marker"
  chmod 600 "$marker"
  log_line 'PASS installation-centre'
}

mark_phase_done() {
  [[ "$DRY_RUN" == 1 ]] && { ok "would mark Phase $1 complete"; return 0; }
  ensure_state
  phase_fingerprint "$1" > "$COMPLETED_DIR/$1"
  chmod 600 "$COMPLETED_DIR/$1"
  log_line "PASS phase-$1"
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

record_package() {
  ensure_state
  append_unique "$INSTALL_MANIFEST" "$1"$'\t'"$2"
}

# List the installed formulae, distinguishing "none" from "could not ask".
# Returns 1 when Homebrew could not be queried at all.
brew_formula_snapshot() {
  local output status
  set +e
  output="$(brew list --formula 2>/dev/null)"
  status=$?
  set -e
  [[ "$status" -eq 0 ]] || return 1
  printf '%s\n' "$output" | sort
}

# Warn once when the pre-install baseline is unavailable. Without it, every
# formula on the Mac would look newly installed and be claimed as runner-owned,
# so a later rollback could uninstall software the user already had.
# Under-claiming leaves software in place and is the safe direction.
warn_unknown_dependency_baseline() {
  warn "Could not list the formulae installed before adding $1."
  warn "Only $1 is recorded as runner-owned; new dependencies are left unclaimed so rollback cannot remove pre-existing software."
}

install_formula() {
  local token="$1" before_formulae formula baseline=1
  if [[ "$DRY_RUN" == 1 ]]; then print_command brew install "$token"; return 0; fi
  if load_brew && brew list --formula "$token" >/dev/null 2>&1; then info "formula $token already installed"; return 0; fi
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
  run brew install --cask "$token"
  record_package brew-cask "$token"
  [[ "$baseline" == 1 ]] || { warn_unknown_dependency_baseline "$token"; return 0; }
  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    grep -Fqx "$formula" <<<"$before_formulae" || record_package brew-dependency "$formula"
  done < <(brew_formula_snapshot || true)
}

record_application_status() {
  [[ "$DRY_RUN" == 1 ]] && return 0
  ensure_state
  day_one_app_record_current "$APPLICATION_PROVENANCE_TSV" \
    "$APPLICATION_PROVENANCE_REPORT" "$INSTALL_MANIFEST"
}

show_application_status() {
  local source_label
  source_label="$(day_one_app_source_label "$DAY_ONE_APP_SOURCE")"
  case "$DAY_ONE_APP_STATUS" in
    ready)
      ok "$DAY_ONE_APP_NAME — $source_label"
      [[ "$DAY_ONE_APP_FOUND_PATH" == - ]] || info "location: $DAY_ONE_APP_FOUND_PATH"
      ;;
    missing)
      ui_status pending "○ $DAY_ONE_APP_NAME — missing"
      info "available Homebrew cask: $DAY_ONE_APP_CASK"
      ;;
    review)
      err "$DAY_ONE_APP_NAME — needs review"
      warn "$DAY_ONE_APP_REASON"
      ;;
  esac
}

scan_applications() {
  local app_id review_count=0
  for app_id in "$@"; do
    day_one_app_detect "$app_id" || {
      err "Unknown application catalogue ID: $app_id"
      review_count=$((review_count + 1))
      continue
    }
    show_application_status
    record_application_status
    [[ "$DAY_ONE_APP_STATUS" != review ]] || review_count=$((review_count + 1))
  done
  if [[ "$review_count" -gt 0 ]]; then
    err "$review_count application result(s) need review; no missing application was installed."
    return "$EX_GATE"
  fi
}

wait_for_external_application() {
  local app_id="$1"
  while :; do
    day_one_app_prompt_external_action
    case "$DAY_ONE_APP_EXTERNAL_ACTION" in
      homebrew) return 20 ;;
      stop)
        warn "$DAY_ONE_APP_NAME remains pending. Rerun this phase after the approved installer finishes."
        return "$EX_MANUAL"
        ;;
      again)
        warn "Choose Enter, h, or s."
        continue
        ;;
    esac

    hash -r 2>/dev/null || true
    day_one_app_detect "$app_id"
    show_application_status
    record_application_status
    case "$DAY_ONE_APP_STATUS" in
      ready)
        ok "$DAY_ONE_APP_NAME was found and will remain managed by its external owner"
        return 0
        ;;
      review)
        err "$DAY_ONE_APP_NAME needs review before setup can continue."
        warn "$DAY_ONE_APP_REASON"
        return "$EX_GATE"
        ;;
      missing)
        warn "$DAY_ONE_APP_NAME is still missing. Finish the installer, choose Homebrew, or stop safely."
        ;;
    esac
  done
}

ensure_application() {
  local app_id="$1" already_shown="${2:-0}" external_rc
  day_one_app_detect "$app_id" || { err "Unknown application catalogue ID: $app_id"; return "$EX_GATE"; }
  [[ "$already_shown" == 1 ]] || show_application_status
  record_application_status
  case "$DAY_ONE_APP_STATUS" in
    ready) return 0 ;;
    review) return "$EX_GATE" ;;
  esac

  if [[ "$DRY_RUN" == 1 ]]; then
    case "$APP_INSTALL_POLICY" in
      homebrew)
        info "Homebrew policy selected for missing $DAY_ONE_APP_NAME"
        print_command brew install --cask "$DAY_ONE_APP_CASK"
        ;;
      check-only)
        info "check-only policy would stop with $DAY_ONE_APP_NAME still missing"
        ;;
      prompt)
        info "would ask whether to use Homebrew or another approved installer for $DAY_ONE_APP_NAME"
        print_command brew install --cask "$DAY_ONE_APP_CASK"
        ;;
    esac
    return 0
  fi

  if [[ "$APP_INSTALL_POLICY" == prompt && ! -t 0 ]]; then
    err "$DAY_ONE_APP_NAME is missing, but installation choice needs an interactive terminal."
    warn "Rerun interactively or pass --app-install-policy homebrew."
    return "$EX_MANUAL"
  fi
  day_one_app_choose_install_route "$APP_INSTALL_POLICY"
  case "$DAY_ONE_APP_INSTALL_CHOICE" in
    stop)
      day_one_app_show_install_requirements
      warn "$DAY_ONE_APP_NAME was not installed. No phase completion was recorded."
      return "$EX_MANUAL"
      ;;
    external)
      if wait_for_external_application "$app_id"; then
        return 0
      else
        external_rc=$?
        [[ "$external_rc" -eq 20 ]] || return "$external_rc"
      fi
      ;;
  esac

  install_cask "$DAY_ONE_APP_CASK"
  [[ "$DRY_RUN" == 1 ]] && return 0
  day_one_app_detect "$app_id"
  show_application_status
  record_application_status
  if ! day_one_app_is_satisfied; then
    err "$DAY_ONE_APP_NAME is still unavailable after Homebrew installation."
    warn "$DAY_ONE_APP_REASON"
    return "$EX_GATE"
  fi
}

verify_application() {
  local app_id="$1"
  day_one_app_detect "$app_id" || return 1
  record_application_status
  day_one_app_is_satisfied
}

choose_installation_centre_policy() {
  local missing_count="$1" answer
  INSTALLATION_CENTRE_POLICY="$APP_INSTALL_POLICY"
  [[ "$missing_count" -gt 0 && "$APP_INSTALL_POLICY" == prompt ]] || return 0
  [[ "$DRY_RUN" == 1 ]] && return 0
  [[ -t 0 ]] || { INSTALLATION_CENTRE_POLICY=check-only; return 0; }
  printf '\n%s required application(s) are missing.\n' "$missing_count"
  printf '[Enter] install every missing item with Homebrew   r review each item   q stop: '
  IFS= read -r answer || return "$EX_MANUAL"
  case "$answer" in
    '') INSTALLATION_CENTRE_POLICY=homebrew ;;
    r|R) INSTALLATION_CENTRE_POLICY=prompt ;;
    q|Q) return "$EX_MANUAL" ;;
    *)
      warn 'Enter installs all missing required items with Homebrew; r reviews each owner; q stops.'
      return "$EX_MANUAL"
      ;;
  esac
}

run_installation_centre() {
  local app_id formula rc missing_count=0 previous_policy="$APP_INSTALL_POLICY"
  local app_ids="" formulae=""
  ui_title '📦' 'Required Installation Centre'
  info 'Applications are installed and ownership-checked here before configuration begins.'
  info "Guide: $DOC_DIR/01-required/INSTALLATION-CENTRE.md"
  if ! load_brew; then
    [[ "$DRY_RUN" == 1 ]] || {
      err 'Homebrew is unavailable. Complete Phase 2 before opening the Installation Centre.'
      return "$EX_GATE"
    }
  fi

  ui_section '🔎' 'Application ownership — no changes yet'
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    app_ids="${app_ids}${app_ids:+ }$app_id"
    day_one_app_detect "$app_id" || return "$EX_GATE"
    show_application_status
    record_application_status
    case "$DAY_ONE_APP_STATUS" in
      missing) missing_count=$((missing_count + 1)) ;;
      review)
        err 'Resolve the ownership conflict shown above before installing anything.'
        return "$EX_GATE"
        ;;
    esac
  done < <(required_application_ids)

  choose_installation_centre_policy "$missing_count" || {
    warn 'No application was removed. Rerun the Installation Centre when ready.'
    return "$EX_MANUAL"
  }
  APP_INSTALL_POLICY="$INSTALLATION_CENTRE_POLICY"
  ui_section '📥' 'Required applications'
  for app_id in $app_ids; do
    if ensure_application "$app_id"; then
      :
    else
      rc=$?
      APP_INSTALL_POLICY="$previous_policy"
      return "$rc"
    fi
  done
  APP_INSTALL_POLICY="$previous_policy"
  update_homebrew_1password_if_needed || return $?

  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    formulae="${formulae}${formulae:+ }$formula"
  done < <(required_formulae)
  ui_section '🧰' 'Required command-line tools'
  info "selected for Track $TRACK and stack $STACK: $formulae"
  for formula in $formulae; do install_formula "$formula"; done
  [[ "$DRY_RUN" == 1 ]] || hash -r 2>/dev/null || true

  if [[ "$DRY_RUN" != 1 ]] && ! installation_centre_components_ready; then
    err 'One or more required applications or formulae are still unavailable.'
    warn 'Review the ownership report, finish any external installer, then rerun the Installation Centre.'
    return "$EX_GATE"
  fi
  mark_installation_centre_done
  INSTALLATION_CENTRE_RAN=1
  ok 'required applications and command-line tools are installed; configuration can begin'
}

report_application() {
  local label="$1" app_id="$2" result
  day_one_app_detect "$app_id" || {
    printf '| %s | FAIL — unknown catalogue entry |\n' "$label" >> "$STATE_DIR/verification.md"
    VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
    phase_gate_failed "$label"
    return 0
  }
  record_application_status
  result="$(day_one_app_source_label "$DAY_ONE_APP_SOURCE")"
  if day_one_app_is_satisfied; then
    printf '| %s | PASS — %s |\n' "$label" "$result" >> "$STATE_DIR/verification.md"
  else
    printf '| %s | FAIL — %s |\n' "$label" "$DAY_ONE_APP_REASON" >> "$STATE_DIR/verification.md"
    VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
    phase_gate_failed "$label"
  fi
}

record_path_before_write() {
  local target="$1" key backup
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

phase_01() {
  local default_name default_email
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
  default_name="$(git config --global user.name 2>/dev/null || id -F 2>/dev/null || id -un)"
  default_email="$(git config --global user.email 2>/dev/null || true)"
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
  phase_step_done "hosting, stack and Git identity recorded"
  ok "decisions recorded"
}

verify_apple_developer_tools() {
  local selected os_major clt_version clt_major
  selected="$(xcode-select -p 2>/dev/null || true)"
  [[ -n "$selected" && -d "$selected" ]] || return 1
  os_major="$(sw_vers -productVersion | awk -F. '{print $1}')"

  case "$selected" in
    /Applications/*.app/Contents/Developer)
      if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
        warn "Xcode still needs its licence or first-launch components."
        warn "Run 'sudo xcodebuild -license', review and accept the licence, then run 'sudo xcodebuild -runFirstLaunch'."
        return 1
      fi
      ;;
    /Library/Developer/CommandLineTools)
      clt_version="$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null \
        | awk -F': ' '$1 == "version" {print $2; exit}')"
      clt_major="${clt_version%%.*}"
      if [[ "$os_major" =~ ^[0-9]+$ && "$os_major" -ge 27 ]] \
         && { [[ ! "$clt_major" =~ ^[0-9]+$ ]] || [[ "$clt_major" -lt "$os_major" ]]; }; then
        warn "Command Line Tools $clt_version are older than macOS $(sw_vers -productVersion) and are likely stale."
        warn "The package version tracks Xcode, so a higher number is normal; a lower one is not."
        warn "Install the current tools from Software Update or rerun 'xcode-select --install'."
        return 1
      fi
      ;;
  esac
  xcrun --find clang >/dev/null 2>&1 && clang --version >/dev/null 2>&1
}

phase_02() {
  local detected_brew path_brew
  phase_next "Xcode Command Line Tools" "Complete the Apple installer window, then rerun Phase 2."
  ui_title '2️⃣' 'Phase 02 — Command-line foundation'
  info "Guide: $(phase_doc 02)"
  if ! xcode-select -p >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == 1 ]]; then print_command xcode-select --install; return 0; fi
    xcode-select --install || true
    warn "Finish the Command Line Tools installer, then rerun Phase 2."
    return "$EX_MANUAL"
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    print_command xcodebuild -checkFirstLaunchStatus
    print_command pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
  else
    verify_apple_developer_tools || {
      warn "Finish the matching Xcode or Command Line Tools setup, then rerun Phase 2."
      return "$EX_MANUAL"
    }
  fi
  phase_step_done "Xcode Command Line Tools available"
  ok "Xcode Command Line Tools available"
  phase_next "Homebrew installation and update" "Allow the official installer to finish, then rerun Phase 2 if it stops."
  info "Checking for native Apple-silicon Homebrew before running an installer."
  if detected_brew="$(brew_path 2>/dev/null)"; then
    ok "Existing Homebrew found at $detected_brew; the installer will be skipped."
  elif have brew; then
    path_brew="$(command -v brew)"
    err "Homebrew is on PATH at $path_brew, but Day One Mac requires /opt/homebrew/bin/brew."
    warn "This normally means an Intel/Rosetta Homebrew or an unsupported wrapper is active."
    warn "Do not install a second copy over it. Open a native arm64 terminal, review the existing installation, then rerun Phase 2."
    return "$EX_GATE"
  else
    info "Native Homebrew was not found at /opt/homebrew/bin/brew."
    if [[ "$DRY_RUN" == 1 ]]; then
      info "would run the official Homebrew installer from brew.sh"
      return 0
    fi
    confirm "Install Homebrew using its official installer?" || return "$EX_MANUAL"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ensure_state
    append_unique "$INSTALL_MANIFEST" $'component\thomebrew'
    ok "Homebrew was installed by Day One Mac and recorded for precise rollback."
  fi
  load_brew || { err "Homebrew was installed but is not discoverable."; return "$EX_GATE"; }
  if [[ "$DRY_RUN" == 1 ]]; then
    print_command brew update
    print_command brew --prefix
    print_command brew config
    print_command brew doctor
    phase_step_done "Homebrew installation, native prefix and diagnostics would be checked"
    return 0
  fi
  run brew update
  [[ "$(brew --prefix)" == /opt/homebrew ]] || {
    err "Apple-silicon Homebrew must use /opt/homebrew; found: $(brew --prefix)"
    return "$EX_GATE"
  }
  brew config
  if ! brew doctor; then
    warn "Homebrew reported diagnostics. Review them before installing packages."
  fi
  phase_step_done "Homebrew installed, discoverable and updated"
  ok "Homebrew ready at $(brew --prefix)"
}

# Emit the managed ~/.ssh/config body for the selected authentication mode.
#
# IdentitiesOnly is written only next to an IdentityFile, in every mode. On its
# own it confines OpenSSH to the default ~/.ssh/id_* files and the configured
# agent is never consulted.
ssh_config_block() {
  local github_public="$HOME/.ssh/github-auth.pub"
  local azure_public="$HOME/.ssh/azure-devops-auth.pub"
  local agent_line='    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'
  printf '%s\n' '# >>> Day One Mac: 1Password SSH agent >>>'
  printf '%s\n' "# Generated for auth mode '$AUTH_MODE' from the saved hosting track."
  if uses_github; then
    printf '%s\n' 'Host github.com'
    printf '%s\n' '    HostName github.com'
    printf '%s\n' '    User git'
    ssh_config_identity_lines "$AUTH_MODE" "$github_public" "$HOME/.ssh/id_ed25519" "$agent_line"
    printf '%s\n' '    ServerAliveInterval 60'
    printf '%s\n' '    ServerAliveCountMax 3'
  fi
  if uses_azure; then
    uses_github && printf '\n'
    printf '%s\n' 'Host ssh.dev.azure.com'
    printf '%s\n' '    HostName ssh.dev.azure.com'
    printf '%s\n' '    User git'
    ssh_config_identity_lines "$AUTH_MODE" "$azure_public" "$HOME/.ssh/id_rsa_azure" "$agent_line"
    printf '%s\n' '    ServerAliveInterval 60'
    printf '%s\n' '    ServerAliveCountMax 3'
  fi
  printf '%s\n' '# <<< Day One Mac: 1Password SSH agent <<<'
}

# The identity half of one Host block, which is all that varies by mode.
ssh_config_identity_lines() {
  local mode="$1" public_pin="$2" keychain_key="$3" agent_line="$4"
  case "$mode" in
    1password)
      printf '%s\n' "$agent_line"
      if [[ -f "$public_pin" ]]; then
        printf '%s\n' "    IdentityFile ~/${public_pin#"$HOME"/}"
        printf '%s\n' '    IdentitiesOnly yes'
      fi
      ;;
    keychain)
      # Apple's ssh stores the passphrase in the login keychain, so the key is
      # usable without retyping it. ssh -G does not echo UseKeychain; that is a
      # display quirk, not a sign it was rejected.
      printf '%s\n' '    UseKeychain yes'
      printf '%s\n' '    AddKeysToAgent yes'
      printf '%s\n' "    IdentityFile ~/${keychain_key#"$HOME"/}"
      printf '%s\n' '    IdentitiesOnly yes'
      ;;
    external)
      # Whatever agent the user already runs answers; pin only if they asked.
      if [[ -f "$public_pin" ]]; then
        printf '%s\n' "    IdentityFile ~/${public_pin#"$HOME"/}"
        printf '%s\n' '    IdentitiesOnly yes'
      fi
      ;;
  esac
}

update_homebrew_1password_if_needed() {
  local token outdated=""
  [[ "$DRY_RUN" == 1 ]] && return 0
  load_brew || return 0
  for token in 1password 1password-cli; do
    brew list --cask "$token" >/dev/null 2>&1 || continue
    if brew outdated --quiet --cask --greedy "$token" 2>/dev/null | grep -Fqx "$token"; then
      outdated="$outdated${outdated:+ }$token"
    fi
  done
  [[ -n "$outdated" ]] || return 0
  warn "Homebrew reports an available update for: $outdated"
  confirm "Upgrade the Homebrew-managed 1Password components now?" || {
    warn "Update the listed casks through their current owner, then rerun the Installation Centre."
    return "$EX_MANUAL"
  }
  for token in $outdated; do run brew upgrade --cask "$token"; done
}

# Phase 5 puts ~/.ssh/config under chezmoi. When Phase 3 is rerun afterwards —
# which Step 3.7 explicitly asks for — it edits the target directly, leaving the
# chezmoi source stale. A later 'chezmoi apply' would then silently revert the
# provider blocks. Re-add the file so source and target stay in agreement.
resync_managed_ssh_config() {
  local ssh_config="$1"
  command -v chezmoi >/dev/null 2>&1 || return 0
  chezmoi source-path "$ssh_config" >/dev/null 2>&1 || return 0
  if chezmoi add "$ssh_config" >/dev/null 2>&1; then
    info "refreshed the chezmoi source for $ssh_config"
  else
    warn "$ssh_config is managed by chezmoi but its source could not be refreshed."
    warn "Run 'chezmoi add $ssh_config' and review 'chezmoi diff' so a later apply does not revert these provider blocks."
  fi
}

# A pinned public key is what lets the SSH config carry an IdentityFile, which
# in turn is the only condition under which IdentitiesOnly is safe to write.
# The value is already reachable from 1Password, so copying it by hand is
# avoidable. Public keys only: anything that looks private is refused.
public_key_is_valid() {
  local value="$1"
  [[ -n "$value" ]] || return 1
  # A private key, or any multi-line blob, must never reach ~/.ssh.
  [[ "$value" != *'PRIVATE KEY'* ]] || return 1
  [[ "$value" != *$'\n'* ]] || return 1
  case "$value" in
    'ssh-ed25519 '*|'ssh-rsa '*) return 0 ;;
    *) return 1 ;;
  esac
}

# Print the 1Password SSH Key item titles that look like they belong to a
# provider. Matching is on the title, so the Step 3.4 naming convention
# ("GitHub — Personal — Authentication") is what makes this work.
onepassword_ssh_item_titles() {
  local pattern="$1"
  op item list --categories "SSH Key" --format json 2>/dev/null \
    | jq -r --arg p "$pattern" \
        '.[] | select((.title // "") | ascii_downcase | contains($p)) | .title' 2>/dev/null
}

# Save a provider's 1Password public key as the pinned ~/.ssh/<provider>-auth.pub.
export_provider_public_key() {
  local provider="$1" target pattern label titles narrowed narrowed_count title count value tmp status
  case "$provider" in
    github) target="$HOME/.ssh/github-auth.pub"; pattern=github; label='GitHub' ;;
    azure)  target="$HOME/.ssh/azure-devops-auth.pub"; pattern=azure; label='Azure DevOps' ;;
    *) err "Unknown provider for key export: $provider"; return 1 ;;
  esac

  have op || { warn "The 1Password CLI ('op') is required to export a public key."; return 1; }
  have jq || { warn "'jq' is required to export a public key; rerun the Installation Centre."; return 1; }

  titles="$(onepassword_ssh_item_titles "$pattern")"
  count="$(printf '%s' "$titles" | grep -c . || true)"
  if [[ "$count" -eq 0 ]]; then
    warn "No 1Password SSH Key item has '$pattern' in its title."
    warn "Create the key in Step 3.4 and name it by provider, for example '$label — Personal — Authentication'."
    return 1
  fi
  if [[ "$count" -gt 1 ]]; then
    # Holding both an authentication key and a signing key is normal and
    # correct — GitHub treats them as different key types. Only the
    # authentication key belongs in an IdentityFile, so narrow rather than
    # asking the user to rename a sensible pair.
    narrowed="$(printf '%s\n' "$titles" | grep -vi 'signing\|sign key' || true)"
    narrowed_count="$(printf '%s' "$narrowed" | grep -c . || true)"
    if [[ "$narrowed_count" -eq 1 ]]; then
      info "Ignoring the signing key; an IdentityFile pins the authentication key."
      titles="$narrowed"; count=1
    elif [[ "$narrowed_count" -gt 1 ]]; then
      # Still several: prefer an explicitly named authentication key.
      narrowed="$(printf '%s\n' "$narrowed" | grep -i 'auth' || true)"
      if [[ "$(printf '%s' "$narrowed" | grep -c . || true)" -eq 1 ]]; then
        titles="$narrowed"; count=1
      fi
    fi
  fi
  if [[ "$count" -gt 1 ]]; then
    warn "Several 1Password SSH Key items match '$pattern' and the authentication key is not obvious:"
    while IFS= read -r title; do [[ -z "$title" ]] || warn "  $title"; done <<<"$titles"
    warn "Add 'Authentication' to the title of the one Git should use, or save the public key manually with Step 3.7."
    return 1
  fi
  title="$(printf '%s' "$titles" | sed -n '1p')"
  info "Using the 1Password item: $title"
  # An IdentityFile selects the key Git authenticates with. A signing key is a
  # different role, so pinning one is almost certainly a mistake.
  case "$title" in
    *[Ss]igning*|*[Ss]ign\ [Kk]ey*)
      warn "'$title' looks like a signing key, not an authentication key."
      warn "If Git cannot authenticate afterwards, pin the authentication key instead."
      ;;
  esac

  tmp="$(mktemp -t day-one-mac-pubkey)"
  run_with_deadline "$tmp" 20 op item get "$title" --format json
  status=$?
  if [[ "$status" -ne 0 ]]; then
    [[ "$status" -eq 124 ]] \
      && warn "Reading '$title' from 1Password timed out; approve the prompt and retry." \
      || warn "Could not read '$title' from 1Password."
    while IFS= read -r line; do [[ -z "$line" ]] || warn "  $line"; done < "$tmp"
    rm -f "$tmp"
    return 1
  fi
  value="$(jq -r '.fields[]? | select((.label // "") == "public key") | .value' < "$tmp" 2>/dev/null | sed -n '1p')"
  rm -f "$tmp"
  value="${value%"${value##*[![:space:]]}"}"

  if ! public_key_is_valid "$value"; then
    warn "'$title' did not yield a usable public key."
    warn "Expected one line beginning 'ssh-ed25519 ' or 'ssh-rsa '. Nothing was written to ~/.ssh."
    warn "Check the item's field labels with: op item get \"$title\""
    return 1
  fi

  create_directory "$HOME/.ssh"
  write_text_file "$target" "$value"$'\n'
  [[ "$DRY_RUN" == 1 ]] || chmod 644 "$target"
  [[ "$DRY_RUN" == 1 ]] || chmod 700 "$HOME/.ssh"
  ok "saved the $label public key to $target"
  info "Rerun Phase 3 so the SSH config gains its IdentityFile line."
}

configure_onepassword_ssh() {
  local ssh_config="$HOME/.ssh/config"
  if [[ "$AUTH_MODE" == https ]]; then
    info "Auth mode 'https': no SSH config block is written."
    return 0
  fi
  local start_marker='# >>> Day One Mac: 1Password SSH agent >>>'
  local end_marker='# <<< Day One Mac: 1Password SSH agent <<<'
  local block remainder content current legacy has_start=0 has_end=0
  block="$(ssh_config_block)"
  legacy=$'Host *\n    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"\n    IdentitiesOnly yes\n    ServerAliveInterval 60\n    ServerAliveCountMax 3'

  create_directory "$HOME/.ssh"
  if [[ "$DRY_RUN" != 1 ]]; then chmod 700 "$HOME/.ssh"; fi

  if [[ -L "$ssh_config" ]]; then
    warn "$ssh_config is a symbolic link, so Phase 3 will not replace its source indirectly."
    warn "Add the provider blocks from Step 3.9 to the file managed by that link, then rerun Phase 3."
    return "$EX_MANUAL"
  fi

  if [[ ! -e "$ssh_config" ]]; then
    write_text_file "$ssh_config" "$block"$'\n'
  else
    current="$(cat "$ssh_config")"
    grep -Fqx "$start_marker" "$ssh_config" && has_start=1
    grep -Fqx "$end_marker" "$ssh_config" && has_end=1
    if [[ "$has_start" != "$has_end" ]]; then
      err "$ssh_config contains only one Day One Mac SSH marker."
      warn "Repair the incomplete marked block manually before rerunning Phase 3; no change was made."
      return "$EX_GATE"
    elif [[ "$has_start" == 1 ]]; then
      remainder="$(awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { skipping=1; next }
        $0 == end { skipping=0; next }
        !skipping { print }
      ' "$ssh_config")"
      content="$block"
      [[ -z "$remainder" ]] || content="$content"$'\n\n'"$remainder"
      [[ "$current" == "$content" ]] || write_text_file "$ssh_config" "$content"$'\n'
    elif [[ "$current" == "$legacy" ]]; then
      info "migrating the earlier Day One Mac Host * block to track-specific host blocks"
      write_text_file "$ssh_config" "$block"$'\n'
    else
      if [[ "$DRY_RUN" == 1 ]]; then
        info "would ask before adding a backed-up, track-specific $AUTH_MODE block to $ssh_config"
        return 0
      fi
      confirm "Back up $ssh_config and add the selected provider blocks at its beginning?" || {
        warn "The existing SSH config was not changed. Merge the block from Step 3.9, then rerun Phase 3."
        return "$EX_MANUAL"
      }
      content="$block"$'\n\n'"$current"
      write_text_file "$ssh_config" "$content"$'\n'
    fi
  fi

  [[ "$DRY_RUN" == 1 ]] && return 0
  chmod 600 "$ssh_config"
  [[ ! -f "$HOME/.ssh/github-auth.pub" ]] || chmod 644 "$HOME/.ssh/github-auth.pub"
  [[ ! -f "$HOME/.ssh/azure-devops-auth.pub" ]] || chmod 644 "$HOME/.ssh/azure-devops-auth.pub"
  resync_managed_ssh_config "$ssh_config"
  if uses_github; then ssh -G github.com >/dev/null 2>&1 || return "$EX_GATE"; fi
  if uses_azure; then ssh -G ssh.dev.azure.com >/dev/null 2>&1 || return "$EX_GATE"; fi
}

# Phase 3's checklist promises that `op account list` succeeds, so verify the
# desktop CLI integration itself rather than only that the `op` binary exists.
# The call can raise a biometric prompt, so it runs under a deadline.
verify_onepassword_cli_integration() {
  local tmp status line
  tmp="$(mktemp -t day-one-mac-op)"
  run_with_deadline "$tmp" 20 op account list
  status=$?
  if [[ "$status" -eq 124 ]]; then
    warn "'op account list' did not finish within 20 seconds."
    warn "Approve or dismiss the 1Password prompt, keep the app unlocked, then rerun Phase 3."
    rm -f "$tmp"
    return 1
  fi
  if [[ "$status" -ne 0 ]]; then
    warn "'op account list' failed, so the 1Password CLI integration is not usable yet:"
    while IFS= read -r line; do [[ -z "$line" ]] || warn "  $line"; done < "$tmp"
    warn "In 1Password -> Settings -> Developer, turn on 'Integrate with 1Password CLI',"
    warn "unlock the app, then rerun Phase 3. See Step 3.2 of the phase guide."
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
  return 0
}

ONEPASSWORD_AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# List the agent's identities. With a socket argument the named agent is asked;
# without one, whatever SSH_AUTH_SOCK already points at. Prints nothing when the
# agent is unreachable or holds no key, so callers test for an empty result.
agent_identities() {
  local sock="$1" out
  if [[ -n "$sock" ]]; then
    [[ -S "$sock" ]] || return 0
    out="$(env SSH_AUTH_SOCK="$sock" ssh-add -l 2>/dev/null || true)"
  else
    out="$(ssh-add -l 2>/dev/null || true)"
  fi
  case "$out" in *'no identities'*) out="" ;; esac
  printf '%s' "$out"
}

# Show what the agent holds, so fingerprints can be matched against the provider.
show_agent_identities() {
  local line
  info "The SSH agent currently offers:"
  while IFS= read -r line; do [[ -z "$line" ]] || info "  $line"; done <<<"$1"
}

# Azure DevOps accepts RSA only. Without this a Track 2 or 3 Mac passes Phase 3
# and fails Phase 4 on a misleading "Permission denied (publickey)".
require_rsa_for_azure() {
  uses_azure || return 0
  printf '%s\n' "$1" | grep -q '(RSA)' && return 0
  warn "Azure DevOps requires an RSA key, but the agent offers no RSA identity."
  warn "Create or import an RSA 3072-bit key using Step 3.4 of the phase guide, then rerun Phase 3."
  return 1
}

# Offer to write the provider key pins rather than writing them unasked.
offer_provider_key_pins() {
  local pinned=0
  if uses_github && [[ ! -f "$HOME/.ssh/github-auth.pub" ]]; then
    info "The GitHub public key is not pinned to ~/.ssh/github-auth.pub."
    info "Pinning adds an IdentityFile line, which is what makes IdentitiesOnly safe."
    if confirm "Save the GitHub public key from 1Password to ~/.ssh/github-auth.pub now?"; then
      export_provider_public_key github && pinned=1 || warn "Falling back to the manual route in Step 3.7."
    fi
  fi
  if uses_azure && [[ ! -f "$HOME/.ssh/azure-devops-auth.pub" ]]; then
    warn "The Azure public key is not pinned. Azure DevOps accepts only the first key offered,"
    warn "so pinning matters whenever the agent holds more than one identity."
    if confirm "Save the Azure DevOps public key from 1Password to ~/.ssh/azure-devops-auth.pub now?"; then
      export_provider_public_key azure && pinned=1 || warn "Falling back to the manual route in Step 3.7."
    fi
  fi
  [[ "$pinned" == 0 ]] || info "A pin was added; the SSH config below will include its IdentityFile."
  return 0
}

# Create a passphrase-protected key and hand it to the macOS Keychain.
# ssh-keygen prompts for the passphrase itself: the runner never sees or stores it.
generate_keychain_key() {
  local target="$1" type="$2" bits="$3"
  if [[ -f "$target" ]]; then
    info "reusing the existing key at $target"
  else
    warn "ssh-keygen will now ask for a passphrase. Choose one you can recall;"
    warn "the macOS Keychain stores it so you are not asked again on this Mac."
    record_path_before_write "$target"
    record_path_before_write "$target.pub"
    if [[ -n "$bits" ]]; then
      ssh-keygen -t "$type" -b "$bits" -f "$target" -C "day-one-mac $(id -un)@$(hostname -s)" || return 1
    else
      ssh-keygen -t "$type" -f "$target" -C "day-one-mac $(id -un)@$(hostname -s)" || return 1
    fi
    ok "created $target"
  fi
  chmod 600 "$target"
  [[ ! -f "$target.pub" ]] || chmod 644 "$target.pub"
  # --apple-use-keychain is Apple's flag; fall back for a non-Apple ssh-add.
  ssh-add --apple-use-keychain "$target" 2>/dev/null \
    || ssh-add -K "$target" 2>/dev/null \
    || warn "Could not add $target to the agent automatically; run 'ssh-add --apple-use-keychain $target'."
  info "Register the matching public key with your provider: $target.pub"
  return 0
}

# Required applications for this Mac. 1Password is required only when it is
# the chosen authentication mode; other modes must not be forced to install it.
required_application_ids() {
  local app_id
  while IFS= read -r app_id; do
    case "$app_id" in
      1password|1password-cli) [[ "$AUTH_MODE" == 1password ]] || continue ;;
    esac
    printf '%s\n' "$app_id"
  done < <(day_one_app_catalog_ids required)
}

# Git transport implied by the authentication mode.
git_protocol_for_mode() {
  [[ "$AUTH_MODE" == https ]] && printf 'https' || printf 'ssh'
}

# --- Phase 3 authentication modes -------------------------------------------
# Every mode ends with the same SSH config write and FileVault gate; they differ
# only in where the SSH identity comes from.

phase_03_onepassword() {
  local app_id key_guidance app_version cli_version identities line
  ui_section '📦' 'Required application ownership'
  scan_applications 1password 1password-cli || return $?
  if [[ "$DRY_RUN" != 1 ]]; then
    for app_id in 1password 1password-cli; do
      verify_application "$app_id" || {
        err 'A required 1Password component is missing or has an ownership conflict.'
        warn 'Rerun the Installation Centre; Phase 3 configures applications but no longer installs them.'
        return "$EX_GATE"
      }
    done
  fi
  [[ "$DRY_RUN" == 1 ]] && return 0
  have op || { err "1Password CLI is not available."; return "$EX_GATE"; }
  app_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    /Applications/1Password.app/Contents/Info.plist 2>/dev/null || true)"
  cli_version="$(op --version 2>/dev/null || true)"
  [[ -z "$app_version" ]] || info "1Password for Mac $app_version"
  [[ -z "$cli_version" ]] || info "1Password CLI $cli_version"
  phase_next "1Password CLI integration" "Turn on 'Integrate with 1Password CLI' in Settings -> Developer, then rerun Phase 3."
  verify_onepassword_cli_integration || return "$EX_MANUAL"
  phase_step_done "1Password CLI integration answers 'op account list'"
  case "$TRACK" in
    1) key_guidance="Create a new GitHub Ed25519 key or import the trusted existing GitHub key; then allow its vault." ;;
    2) key_guidance="Create a new Azure DevOps RSA 3072-bit key or import the trusted existing RSA key; then allow its vault." ;;
    3) key_guidance="Create/import the GitHub and Azure DevOps keys in Step 3.4; use RSA for Azure and pin separate keys to each provider." ;;
  esac
  phase_next "1Password SSH identity" "$key_guidance"
  identities="$(agent_identities "$ONEPASSWORD_AGENT_SOCK")"
  if [[ -z "$identities" ]]; then
    warn "$key_guidance"
    warn "Turn on 'Use the SSH agent' in Settings -> Developer, unlock 1Password, then rerun Phase 3."
    return "$EX_MANUAL"
  fi
  show_agent_identities "$identities"
  require_rsa_for_azure "$identities" || return "$EX_MANUAL"
  phase_step_done "1Password SSH agent exposes at least one usable identity"
  offer_provider_key_pins
}

phase_03_keychain() {
  local generated=0
  phase_next "on-disk SSH key held by the macOS Keychain" "Create the key when prompted and choose a passphrase you can recall."
  [[ "$DRY_RUN" == 1 ]] && return 0
  create_directory "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  uses_github && { generate_keychain_key "$HOME/.ssh/id_ed25519" ed25519 "" || return "$EX_MANUAL"; generated=1; }
  uses_azure && { generate_keychain_key "$HOME/.ssh/id_rsa_azure" rsa 3072 || return "$EX_MANUAL"; generated=1; }
  [[ "$generated" == 1 ]] || { err "No provider selected for a keychain key."; return "$EX_GATE"; }
  phase_step_done "keychain-backed SSH key present and loaded"
}

phase_03_external() {
  local identities
  phase_next "an SSH identity from your own agent" "Load a key into your agent, then rerun Phase 3."
  [[ "$DRY_RUN" == 1 ]] && return 0
  # Deliberately no socket override: whatever SSH_AUTH_SOCK already points at
  # is the agent being verified.
  identities="$(agent_identities "")"
  if [[ -z "$identities" ]]; then
    err "No SSH agent identity is available."
    warn "Auth mode 'external' means Day One Mac does not create or manage a key."
    warn "Start your agent and load a key so that 'ssh-add -l' lists it, then rerun Phase 3."
    return "$EX_MANUAL"
  fi
  show_agent_identities "$identities"
  require_rsa_for_azure "$identities" || return "$EX_MANUAL"
  phase_step_done "an external agent exposes at least one usable identity"
}

phase_03_https() {
  phase_next "HTTPS Git authentication" "Phase 4 configures the credential helper; no SSH key is needed."
  info "Auth mode 'https': Phase 3 configures no SSH key or agent."
  info "Git authenticates over HTTPS, set up in Phase 4."
  phase_step_done "HTTPS mode selected; SSH setup intentionally skipped"
}

phase_03() {
  ui_title '3️⃣' 'Phase 03 — Security and SSH'
  info "Guide: $(phase_doc 03)"
  info "Git authentication mode: $AUTH_MODE"
  phase_next "authentication setup and disk encryption" "Complete the steps for your chosen mode, then rerun Phase 3."
  if ! load_brew; then
    [[ "$DRY_RUN" == 1 ]] || { err "Complete Phase 2 first."; return "$EX_GATE"; }
  fi
  case "$AUTH_MODE" in
    1password) phase_03_onepassword || return $? ;;
    keychain)  phase_03_keychain    || return $? ;;
    external)  phase_03_external    || return $? ;;
    https)     phase_03_https       || return $? ;;
    *) err "Unknown authentication mode: $AUTH_MODE"; return "$EX_GATE" ;;
  esac
  configure_onepassword_ssh || return $?
  [[ "$DRY_RUN" == 1 ]] && return 0
  phase_next "FileVault disk encryption" "Open System Settings → Privacy & Security → FileVault, turn it on, and save the recovery method."
  fdesetup status 2>/dev/null | grep -q 'FileVault is On' || {
    warn "Enable FileVault in System Settings, save its recovery key, then rerun."
    return "$EX_MANUAL"
  }
  phase_step_done "FileVault is on"
  ok "Git authentication ($AUTH_MODE) and FileVault verified"
}

phase_04() {
  local app_id formula ssh_output
  ui_title '4️⃣' 'Phase 04 — Core tools and hosting'
  info "Guide: $(phase_doc 04)"
  phase_next "required tools and application ownership checks" "Complete the Installation Centre, then rerun Phase 4."
  if ! load_brew; then
    [[ "$DRY_RUN" == 1 ]] || { err "Complete Phase 2 first."; return "$EX_GATE"; }
  fi
  phase_next "saved Git identity" "Complete Phase 1 with a valid Git author name and email, then rerun Phase 4."
  if [[ -z "$GIT_NAME" || ! "$GIT_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
    err "Git name or email is missing; complete Phase 1 first."
    return "$EX_GATE"
  fi
  phase_next "required application ownership" "Rerun the Installation Centre if an application is missing or has changed owner."
  ui_section '📦' 'Required application ownership'
  scan_applications jetbrains-mono-nerd-font raycast visual-studio-code warp || return $?
  if [[ "$DRY_RUN" != 1 ]]; then
    for app_id in jetbrains-mono-nerd-font raycast visual-studio-code warp; do
      verify_application "$app_id" || {
        err 'A required desktop application or font is unavailable.'
        warn 'Rerun the Installation Centre; Phase 4 now performs configuration only.'
        return "$EX_GATE"
      }
    done
  fi
  phase_step_done "required application ownership verified"

  phase_next "required command-line tools" "Rerun the Installation Centre if a selected formula is missing."
  if [[ "$DRY_RUN" == 1 ]]; then
    info 'would verify every formula selected by the saved track and stack'
  else
    while IFS= read -r formula; do
      [[ -n "$formula" ]] || continue
      brew list --formula "$formula" >/dev/null 2>&1 || {
        err "required formula is missing: $formula"
        return "$EX_GATE"
      }
    done < <(required_formulae)
  fi
  phase_step_done "required command-line tools available"

  phase_next "development folders and Git defaults" "Review Steps 4.2–4.3 and correct the Git identity or ghq root."
  create_directory "$HOME/Developer"
  create_directory "$HOME/Developer/_sandbox"
  create_directory "$HOME/Developer/_archive"
  uses_github && create_directory "$HOME/Developer/github.com"
  uses_azure && create_directory "$HOME/Developer/dev.azure.com"

  if [[ "$DRY_RUN" != 1 ]]; then record_path_before_write "$HOME/.gitconfig"; fi
  run git config --global user.name "$GIT_NAME"
  run git config --global user.email "$GIT_EMAIL"
  run git config --global init.defaultBranch main
  run git config --global pull.ff only
  run git config --global fetch.prune true
  run git config --global ghq.root "$HOME/Developer"
  if [[ "$DRY_RUN" == 1 ]]; then
    uses_github && print_command gh auth login --git-protocol "$(git_protocol_for_mode)" --web --skip-ssh-key
    uses_azure && print_command az login
    print_command ghq root
    return 0
  fi
  [[ "$(ghq root 2>/dev/null | sed -n '1p')" == "$HOME/Developer" ]] || {
    err "ghq root is not $HOME/Developer"; return "$EX_GATE"; }
  phase_step_done "development folders, Git defaults and ghq root configured"
  phase_next "selected hosting account authentication" "Finish the browser sign-in, then confirm the matching SSH public key is registered with the provider."
  if uses_github; then
    record_path_before_write "$HOME/.config/gh"
    if ! gh auth status >/dev/null 2>&1; then
      warn "GitHub authentication is required for this track."
      # --skip-ssh-key matters: the key already lives in 1Password and was
      # registered in Phase 3. Without the flag, gh offers to generate one when
      # ~/.ssh contains no .pub file and defaults to yes, writing a plaintext
      # ~/.ssh/id_ed25519 and breaking this project's no-private-keys-on-disk
      # guarantee. It also avoids requesting the admin:public_key scope.
      gh auth login --git-protocol "$(git_protocol_for_mode)" --web --skip-ssh-key || return "$EX_MANUAL"
    fi
    run gh config set git_protocol "$(git_protocol_for_mode)"
    # In HTTPS mode gh itself becomes the credential helper, so no token is
    # ever typed or stored by hand.
    [[ "$AUTH_MODE" != https ]] || run gh auth setup-git
  fi
  if uses_azure; then
    record_path_before_write "$HOME/.azure"
    if ! az account show >/dev/null 2>&1; then
      warn "Azure authentication is required for this track."
      az login || return "$EX_MANUAL"
    fi
  fi
  if uses_azure && ! az extension show --name azure-devops >/dev/null 2>&1; then
    run az extension add --name azure-devops
  fi
  if [[ "$AUTH_MODE" == https ]]; then
    # Nothing to reach over SSH; the CLI sign-in above is the authentication.
    info "Auth mode 'https': skipping the SSH reachability tests."
    if uses_azure; then
      have git-credential-manager \
        || warn "Azure DevOps over HTTPS needs Git Credential Manager: brew install --cask git-credential-manager"
      warn "Azure DevOps HTTPS uses a Microsoft Entra ID token or a personal access token that you create and Git stores."
    fi
  else
    if uses_github; then
      ssh_output="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)"
      grep -Fq 'successfully authenticated' <<<"$ssh_output" || {
        err "GitHub did not accept the SSH identity: $ssh_output"; return "$EX_MANUAL"; }
    fi
    if uses_azure; then
      ssh_output="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -T git@ssh.dev.azure.com 2>&1 || true)"
      grep -Fq 'Shell access is not supported' <<<"$ssh_output" || {
        err "Azure DevOps did not accept the SSH identity: $ssh_output"; return "$EX_MANUAL"; }
    fi
  fi
  phase_step_done "selected hosting CLI and Git authentication passed"
  ok "Git and selected hosting services verified"
}

# Switch the login shell to the Homebrew zsh.
#
# This is the one place Day One Mac changes a macOS account setting, and it is
# the one change that can lock you out of a working login shell, so it is
# deliberately cautious: the binary must exist and actually run, /etc/shells is
# only appended to (never rewritten), and the user confirms before either sudo
# or chsh. Recovery is always `chsh -s /bin/zsh`.
switch_login_shell_to_homebrew_zsh() {
  local target current verified prefix
  prefix="$(brew --prefix 2>/dev/null || printf '/opt/homebrew')"
  target="$prefix/bin/zsh"

  if [[ ! -x "$target" ]]; then
    err "Homebrew zsh is not installed at $target; the required login-shell gate cannot pass."
    warn "Rerun the Installation Centre to install it, then rerun Phase 5."
    return "$EX_GATE"
  fi
  # Never point a login shell at something that cannot start.
  if ! "$target" -c 'exit 0' >/dev/null 2>&1; then
    err "$target did not run; refusing to make it your login shell."
    return "$EX_GATE"
  fi

  # Directory Services can be temporarily unavailable on a newly provisioned
  # or company-managed Mac. An unreadable current value is informational, not
  # permission to abort the phase; every later message already handles
  # `unknown`, and chsh remains explicitly confirmed.
  current="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}' || true)"
  [[ "$current" == "$target" ]] \
    && info "login shell is already $target" \
    || info "Current login shell: ${current:-unknown}"
  info "Homebrew zsh: $target ($("$target" --version 2>/dev/null))"
  # State the recovery path before anything changes, not just before chsh:
  # the /etc/shells step can fail, and the user should already know the way out.
  warn "Changing your login shell affects every new terminal."
  warn "If Homebrew zsh is ever removed, recover with: chsh -s /bin/zsh"

  if [[ "$DRY_RUN" == 1 ]]; then
    grep -Fqx "$target" /etc/shells 2>/dev/null || print_command sudo tee -a /etc/shells
    print_command chsh -s "$target"
    return 0
  fi

  if ! grep -Fqx "$target" /etc/shells 2>/dev/null; then
    warn "$target must be listed in /etc/shells before it can be a login shell."
    warn "This is the only step in Day One Mac that needs sudo; it appends one line."
    confirm "Append $target to /etc/shells with sudo?" || {
      warn "Left /etc/shells unchanged; the login shell was not switched."
      return "$EX_MANUAL"
    }
    record_path_before_write /etc/shells
    printf '%s\n' "$target" | sudo tee -a /etc/shells >/dev/null || {
      err "Could not write /etc/shells; the login shell was not switched."
      return "$EX_GATE"
    }
    ok "registered $target in /etc/shells"
  fi

  if [[ "$current" == "$target" ]]; then
    ok "gate: Directory Services login shell is $target"
    return 0
  fi

  confirm "Make $target your login shell now?" || {
    info "Login shell left as ${current:-unknown}."
    return "$EX_MANUAL"
  }
  save_state_value previous-login-shell "${current:-/bin/zsh}"
  if chsh -s "$target"; then
    ok "login shell changed to $target"
    info "Open a new terminal for it to take effect."
  else
    err "chsh did not complete; your login shell is unchanged (${current:-unknown})."
    return "$EX_GATE"
  fi

  verified="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}' || true)"
  if [[ "$verified" != "$target" ]]; then
    err "Directory Services reports ${verified:-unknown}, not the required login shell $target."
    warn "Open System Settings → Users & Groups → your account → Advanced Options only if chsh repeatedly fails."
    return "$EX_GATE"
  fi
  ok "gate: Directory Services login shell is $target"
  return 0
}

phase_05() {
  local chezmoi_config chezmoi_content escaped_email escaped_name managed_target
  local existing_managed_source=0 starship_config starship_content starship_created=0 chezmoi_source_dir
  local runner_wrapper runner_source runner_content runner_created=0 applications_case optional_case remove_case shell_status_case legacy_runner legacy_runner_content
  local legacy_runner_updated=0 zprofile zshrc zsh_path zsh_aliases bootstrap_zsh_path
  local zsh_config_dir zsh_path_file zsh_aliases_file ssh_config ssh_config_created=0 homebrew_zsh clean_shell_check compaudit_output
  ui_title '5️⃣' 'Phase 05 — Dotfiles and Starship'
  info "Guide: $(phase_doc 05)"
  phase_next "chezmoi command" "Complete Phase 4 so chezmoi is installed, then rerun Phase 5."
  if ! have chezmoi; then
    [[ "$DRY_RUN" == 1 ]] || { err "chezmoi is missing; complete Phase 4."; return "$EX_GATE"; }
  fi
  phase_next "chezmoi source review" "Review every path in the existing source and its full chezmoi diff before approving apply."
  if chezmoi source-path >/dev/null 2>&1 \
     && [[ -n "$(chezmoi managed 2>/dev/null || true)" ]]; then
    existing_managed_source=1
  fi
  # `chezmoi source-path` with no target only resolves and prints the configured
  # source directory: it exits 0 even when that directory does not exist. Using
  # its status as an existence test meant that on any Mac where chezmoi is
  # installed — which Phase 4 guarantees — `chezmoi init` was never run for a
  # brand-new source. Test the directory itself.
  chezmoi_source_dir="$(chezmoi source-path 2>/dev/null || true)"
  if [[ -z "$chezmoi_source_dir" || ! -d "$chezmoi_source_dir" ]]; then
    if [[ -z "$DOTFILES_REPO" && "$DOTFILES_EXPLICIT" != 1 && "$DRY_RUN" != 1 && -t 0 ]]; then
      printf 'Existing private dotfiles repository URL (Enter for a new source protected by private Git): '
      IFS= read -r DOTFILES_REPO
      save_state_value dotfiles-repo "$DOTFILES_REPO"
    fi
    if [[ -n "$DOTFILES_REPO" ]]; then run chezmoi init "$DOTFILES_REPO"
    else
      run chezmoi init
    fi
    [[ -n "$DOTFILES_REPO" ]] && existing_managed_source=1
  fi
  if [[ "$existing_managed_source" == 1 ]]; then
    if [[ "$DRY_RUN" == 1 ]]; then
      print_command chezmoi diff --no-pager
      print_command chezmoi apply
    elif [[ -n "$(chezmoi diff --no-pager)" ]]; then
      chezmoi diff --no-pager
      confirm "Apply the reviewed existing dotfiles source?" || return "$EX_MANUAL"
      record_managed_targets_before_apply || return $?
      run chezmoi apply
    else
      ok "existing dotfiles source already matches its targets"
    fi
  fi
  phase_step_done "chezmoi source initialised and any existing-source diff reviewed"
  phase_next "managed shell, Starship and portable command files" "Complete Steps 5.2–5.7 and merge any existing file instead of overwriting it blindly."
  chezmoi_config="$HOME/.config/chezmoi/chezmoi.toml"
  if [[ ! -e "$chezmoi_config" ]]; then
    create_directory "$HOME/.config"
    create_directory "$HOME/.config/chezmoi"
    escaped_name="$(toml_escape "$GIT_NAME")"
    escaped_email="$(toml_escape "$GIT_EMAIL")"
    printf -v chezmoi_content \
      '[edit]\ncommand = "code"\nargs = ["--wait"]\n\n[data]\ntrack = "%s"\nstack = "%s"\nname = "%s"\nemail = "%s"\n' \
      "$(track_value)" "$STACK" "$escaped_name" "$escaped_email"
    write_text_file "$chezmoi_config" "$chezmoi_content"
  fi
  starship_config="$HOME/.config/starship.toml"
  starship_content=$'add_newline = false\ncommand_timeout = 1000\n\n[character]\nsuccess_symbol = "[❯](bold green)"\nerror_symbol = "[❯](bold red)"\n'
  if [[ ! -e "$starship_config" ]]; then
    create_directory "$HOME/.config"
    write_text_file "$starship_config" "$starship_content"
    starship_created=1
  fi
  zsh_config_dir="$HOME/.config/zsh"
  zsh_path_file="$zsh_config_dir/path.zsh"
  zsh_aliases_file="$zsh_config_dir/aliases.zsh"
  ssh_config="$HOME/.ssh/config"
  zsh_path=$'# Shared PATH setup for login and non-login interactive zsh.\n# Keep this file idempotent: both ~/.zprofile and ~/.zshrc source it.\ntypeset -U path PATH\nif [[ -x /opt/homebrew/bin/brew ]] && {\n  [[ ${HOMEBREW_PREFIX:-} != /opt/homebrew ]] ||\n  [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] ||\n  [[ ":$PATH:" != *":/opt/homebrew/sbin:"* ]]\n}; then\n  eval "$(/opt/homebrew/bin/brew shellenv)"\nfi\n\ncase ":$PATH:" in\n  *":$HOME/.local/bin:"*) ;;\n  *) export PATH="$HOME/.local/bin:$PATH" ;;\nesac\n'
  bootstrap_zsh_path=$'# Day One Mac bootstrap PATH — Phase 5 expands and adopts this file.\ntypeset -U path PATH\ncase ":$PATH:" in\n  *":$HOME/.local/bin:"*) ;;\n  *) export PATH="$HOME/.local/bin:$PATH" ;;\nesac\n'
  if uses_node; then
    zsh_path+=$'\nexport PNPM_HOME="$HOME/Library/pnpm"\ncase ":$PATH:" in\n  *":$PNPM_HOME:"*) ;;\n  *) export PATH="$PNPM_HOME:$PATH" ;;\nesac\n'
  fi
  zsh_aliases=$'# Safe, readable aliases selected by Day One Mac.\n# Keep destructive, publishing, force-push and prune commands explicit.\nif command -v day-one-mac >/dev/null 2>&1; then\n  alias cdayone=\'cd "$(day-one-mac root)"\'\nfi\n\nif command -v git >/dev/null 2>&1; then\n  alias gs=\'git status --short --branch\'\n  alias gd=\'git diff\'\n  alias gds=\'git diff --staged\'\n  alias gl=\'git log --oneline --graph --decorate -20\'\n  alias gremotes=\'git remote --verbose\'\nfi\n\nif command -v chezmoi >/dev/null 2>&1; then\n  alias cm=\'chezmoi\'\n  alias cmstatus=\'chezmoi status\'\n  alias cmdiff=\'chezmoi diff --no-pager\'\n  alias cmverify=\'chezmoi verify\'\n  alias cmdoctor=\'chezmoi doctor\'\nfi\n\nif command -v brew >/dev/null 2>&1; then\n  alias brewcheck=\'brew bundle check --file="$HOME/Brewfile" --no-upgrade\'\n  alias brewout=\'brew outdated --greedy\'\n  alias brewcleanpreview=\'brew cleanup --dry-run\'\n  alias brewautopreview=\'brew autoremove --dry-run\'\nfi\n'
  create_directory "$zsh_config_dir"
  if [[ -f "$zsh_path_file" ]] \
     && grep -Fq '# Day One Mac bootstrap PATH — Phase 5 expands and adopts this file.' "$zsh_path_file"; then
    if cmp -s "$zsh_path_file" <(printf '%s' "$bootstrap_zsh_path"); then
      info "expanding the early portable-command PATH file for the full shell setup"
      write_text_file "$zsh_path_file" "$zsh_path"
    else
      err "$zsh_path_file contains the bootstrap marker plus user changes."
      warn "Merge those changes into the documented Phase 5 path.zsh, remove the marker, and rerun."
      return "$EX_MANUAL"
    fi
  fi
  [[ -e "$zsh_path_file" ]] || write_text_file "$zsh_path_file" "$zsh_path"
  [[ -e "$zsh_aliases_file" ]] || write_text_file "$zsh_aliases_file" "$zsh_aliases"
  # HTTPS authentication needs no SSH identity, but Phase 5 still keeps one
  # predictable ~/.ssh/config target in the dotfiles inventory. Create only a
  # comment when Phase 3 deliberately left the file absent; never replace an
  # existing personal or company SSH configuration.
  if [[ "$AUTH_MODE" == https && ! -e "$ssh_config" ]]; then
    create_directory "$HOME/.ssh"
    write_text_file "$ssh_config" $'# Day One Mac: HTTPS Git authentication selected; no SSH identity is configured.\n'
    [[ "$DRY_RUN" == 1 ]] || chmod 600 "$ssh_config"
    ssh_config_created=1
  fi
  runner_wrapper="$HOME/.local/bin/day-one-mac"
  # The same reviewed dispatcher is available before Phase 1 through
  # install-portable-command.sh. Phase 5 adopts that exact file into chezmoi.
  runner_source="$PROJECT_DIR/scripts/day-one-mac"
  [[ -r "$runner_source" ]] || { err "portable dispatcher is missing: $runner_source"; return "$EX_GATE"; }
  runner_content="$(<"$runner_source")"$'\n'
  if [[ ! -e "$runner_wrapper" ]]; then
    create_directory "$HOME/.local"
    create_directory "$HOME/.local/bin"
    write_text_file "$runner_wrapper" "$runner_content"
    [[ "$DRY_RUN" == 1 ]] || chmod 700 "$runner_wrapper"
    runner_created=1
  elif ! cmp -s "$runner_wrapper" <(printf '%s' "$runner_content"); then
    if [[ "$DRY_RUN" == 1 ]]; then
      info "would refresh the changed playbook-owned command: $runner_wrapper"
    else
      warn "$runner_wrapper differs from the current portable dispatcher."
      confirm "Back it up and replace it with the reviewed current dispatcher?" || return "$EX_MANUAL"
      write_text_file "$runner_wrapper" "$runner_content"
      chmod 700 "$runner_wrapper"
      runner_created=1
    fi
  fi
  legacy_runner="$HOME/.local/bin/fresh-start"
  legacy_runner_content=$'#!/usr/bin/env bash\nprintf "Compatibility command: use day-one-mac instead of fresh-start.\\n" >&2\nexec "$HOME/.local/bin/day-one-mac" "$@"\n'
  if [[ -f "$legacy_runner" ]] \
     && grep -Eq 'fresh-start commands:|fresh-start project location|day-one-mac commands:' "$legacy_runner"; then
    if [[ "$DRY_RUN" == 1 ]]; then
      info "would convert the old fresh-start command into a Day One Mac compatibility shim"
    else
      write_text_file "$legacy_runner" "$legacy_runner_content"
      chmod 700 "$legacy_runner"
      legacy_runner_updated=1
    fi
  fi
  if [[ "$existing_managed_source" == 0 ]]; then
    zprofile=$'[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"\n'
    zshrc=$'[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"\n\nHISTFILE="$HOME/.zsh_history"\nHISTSIZE=50000\nSAVEHIST=10000\nsetopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY\n\nfor completion_dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do\n  [[ -d "$completion_dir" ]] || continue\n  (( ${fpath[(Ie)$completion_dir]} )) || fpath=("$completion_dir" $fpath)\ndone\nunset completion_dir\nautoload -Uz compinit\ncompinit\n\nif command -v fnm >/dev/null 2>&1; then\n  eval "$(fnm env --use-on-cd --shell zsh)"\nfi\n\n[[ -r "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"\n\nif [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then\n  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh\nfi\n\nif command -v starship >/dev/null 2>&1; then\n  eval "$(starship init zsh)"\nfi\n\n# Syntax highlighting must be the final shell integration.\nif [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then\n  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\nfi\n'
    [[ -e "$HOME/.zprofile" ]] || write_text_file "$HOME/.zprofile" "$zprofile"
    [[ -e "$HOME/.zshrc" ]] || write_text_file "$HOME/.zshrc" "$zshrc"
    [[ "$DRY_RUN" == 1 ]] || run chezmoi add "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.ssh/config" "$starship_config" "$zsh_path_file" "$zsh_aliases_file" "$runner_wrapper"
  elif [[ "$DRY_RUN" != 1 ]]; then
    [[ "$starship_created" == 1 ]] && run chezmoi add "$starship_config"
    [[ "$runner_created" == 1 ]] && run chezmoi add "$runner_wrapper"
    [[ "$legacy_runner_updated" == 1 ]] && run chezmoi add "$legacy_runner"
    [[ "$ssh_config_created" == 1 ]] && run chezmoi add "$ssh_config"
    chezmoi source-path "$zsh_path_file" >/dev/null 2>&1 || run chezmoi add "$zsh_path_file"
    chezmoi source-path "$zsh_aliases_file" >/dev/null 2>&1 || run chezmoi add "$zsh_aliases_file"
  fi
  [[ "$DRY_RUN" == 1 ]] && return 0
  grep -Fq 'starship init zsh' "$HOME/.zshrc" || {
    warn "Add 'eval \"\$(starship init zsh)\"' to ~/.zshrc through chezmoi, then rerun Phase 5."
    return "$EX_MANUAL"
  }
  if [[ -e "$HOME/.zshenv" ]] && grep -Eq '(^|[[:space:]])(export[[:space:]]+)?ZDOTDIR=|(^|[[:space:]])unsetopt[[:space:]]+.*RCS' "$HOME/.zshenv"; then
    err "~/.zshenv changes ZDOTDIR or disables Zsh startup files, so Day One Mac cannot verify the managed shell safely."
    warn "Review ~/.zshenv, remove the conflicting directive through its owner, and rerun Phase 5."
    return "$EX_MANUAL"
  fi
  grep -Fq '.config/zsh/path.zsh' "$HOME/.zprofile" || {
    err "~/.zprofile must source ~/.config/zsh/path.zsh; merge the Phase 5 block through chezmoi."
    return "$EX_MANUAL"
  }
  grep -Fq '.config/zsh/path.zsh' "$HOME/.zshrc" || {
    err "~/.zshrc must source ~/.config/zsh/path.zsh; merge the Phase 5 block through chezmoi."
    return "$EX_MANUAL"
  }
  grep -Fq '.config/zsh/aliases.zsh' "$HOME/.zshrc" || {
    err "~/.zshrc must source ~/.config/zsh/aliases.zsh; merge the Phase 5 block through chezmoi."
    return "$EX_MANUAL"
  }
  chezmoi doctor >/dev/null
  for managed_target in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.ssh/config" "$starship_config" "$zsh_path_file" "$zsh_aliases_file" "$runner_wrapper"; do
    chezmoi source-path "$managed_target" >/dev/null 2>&1 || {
      err "$managed_target is not managed by chezmoi."; return "$EX_MANUAL"; }
  done
  phase_step_done "required dotfiles are under chezmoi management"
  phase_next "new login-shell verification" "Apply the reviewed source, open a new login shell, and resolve the first missing command it reports."
  STARSHIP_CONFIG="$starship_config" starship prompt >/dev/null
  [[ "$("$runner_wrapper" root 2>/dev/null)" == "$PROJECT_DIR" ]] || {
    err "$runner_wrapper does not resolve the current project root: $PROJECT_DIR"
    return "$EX_GATE"
  }
  homebrew_zsh="/opt/homebrew/bin/zsh"
  [[ -x "$homebrew_zsh" ]] || { err "Homebrew zsh is missing at $homebrew_zsh."; return "$EX_GATE"; }
  compaudit_output="$("$homebrew_zsh" -fc 'for dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do [[ -d "$dir" ]] && fpath=("$dir" $fpath); done; autoload -Uz compaudit; compaudit' 2>/dev/null || true)"
  if [[ -n "$compaudit_output" ]]; then
    err "Zsh completion directories have unsafe permissions:"
    printf '%s\n' "$compaudit_output" | sed 's/^/    /'
    warn "Review only the listed paths; do not recursively chmod /opt/homebrew or HOME."
    return "$EX_MANUAL"
  fi
  clean_shell_check='command -v brew git ghq chezmoi starship day-one-mac >/dev/null; [[ "$(command -v zsh)" == /opt/homebrew/bin/zsh ]]; alias cdayone gs gd gds gl gremotes cm cmstatus cmdiff cmverify cmdoctor brewcheck brewout brewcleanpreview brewautopreview >/dev/null; [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]'
  uses_node && clean_shell_check+='; [[ "$PNPM_HOME" == "$HOME/Library/pnpm" && ":$PATH:" == *":$PNPM_HOME:"* ]]'
  env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" TERM="${TERM:-xterm-256color}" PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL="$homebrew_zsh" \
    "$homebrew_zsh" -lic "$clean_shell_check" || {
      err "A clean Homebrew-zsh login shell did not load every required command and PATH entry."
      return "$EX_GATE"
    }
  # The same commands must resolve in a NON-login interactive shell too. That
  # is the case ~/.zprofile does not cover, and where a missing Starship prompt
  # or Python shim would otherwise go unnoticed until someone opened a tmux
  # pane or typed `zsh`.
  env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" TERM="${TERM:-xterm-256color}" PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL="$homebrew_zsh" \
    "$homebrew_zsh" -ic "$clean_shell_check" || {
    err "A non-login interactive shell cannot find Homebrew or Starship."
    warn "~/.zshrc should re-apply the Homebrew environment when it is missing; see Phase 5 Step 5.3."
    return "$EX_GATE"
  }
  phase_step_done "Starship and required commands work in login and non-login shells"
  phase_next "Homebrew zsh as the login shell" "Confirm the /etc/shells and chsh prompts, then open a new terminal."
  switch_login_shell_to_homebrew_zsh || return $?
  ok "chezmoi, managed Starship configuration and login shell verified"
}

phase_06() {
  local fnm_dir pnpm_home uv_python_bin uv_python_dir
  ui_title '6️⃣' 'Phase 06 — Language toolchains and pnpm'
  info "Guide: $(phase_doc 06)"
  if uses_node; then
    phase_next "Node LTS, npm and pnpm" "Review the Node steps, then ensure PNPM_HOME is exported by the chezmoi-managed .zprofile."
    if ! have fnm; then
      [[ "$DRY_RUN" == 1 ]] || { err "fnm is missing; complete Phase 4."; return "$EX_GATE"; }
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
      print_command fnm install --lts --use
      print_command mkdir -p "$HOME/Library/pnpm"
      print_command pnpm --version
      print_command pnpm store path
    else
      eval "$(fnm env --shell bash)"
      fnm_dir="${FNM_DIR:-$HOME/.local/share/fnm}"
      record_path_before_write "$fnm_dir"
      record_path_before_write "$HOME/.local/state/fnm_multishells"
      run fnm install --lts --use
      run fnm default "$(fnm current)"
      pnpm_home="$(zsh -lc 'printf %s "${PNPM_HOME:-$HOME/Library/pnpm}"')"
      [[ "$pnpm_home" == "$HOME"/* ]] || {
        err "PNPM_HOME must be a specific path beneath HOME: $pnpm_home"; return "$EX_GATE"; }
      create_directory "$pnpm_home"
      export PNPM_HOME="$pnpm_home"
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac
      node --version
      npm --version
      pnpm --version
      (cd "$HOME" && pnpm store path)
      if ! zsh -lc '[[ -n "$PNPM_HOME" && -d "$PNPM_HOME" && ":$PATH:" == *":$PNPM_HOME:"* ]]'; then
        warn "Add the PNPM_HOME block from Phase 5 to the chezmoi-managed .zprofile, apply it, then rerun Phase 6."
        return "$EX_MANUAL"
      fi
    fi
    phase_step_done "Node LTS, npm and Homebrew-owned pnpm verified"
  fi
  if uses_python; then
    phase_next "uv-managed Python" "Complete the Python steps and rerun after uv can find an installed interpreter."
    if ! have uv; then
      [[ "$DRY_RUN" == 1 ]] || { err "uv is missing; complete Phase 4."; return "$EX_GATE"; }
    fi
    if [[ "$DRY_RUN" != 1 ]]; then
      uv_python_dir="$(uv python dir)"
      record_path_before_write "$uv_python_dir"
    fi
    run uv python install
    if [[ "$DRY_RUN" != 1 ]]; then
      uv_python_bin="$(uv python find)"
      "$uv_python_bin" --version
    fi
    phase_step_done "uv-managed Python verified"
  fi
  ok "selected language toolchains verified"
}

phase_07() {
  local settings settings_content
  ui_title '7️⃣' 'Phase 07 — VS Code base'
  info "Guide: $(phase_doc 07)"
  phase_next "Visual Studio Code application" "Complete Phase 4 or restore the approved company-managed VS Code application, then rerun Phase 7."
  if [[ "$DRY_RUN" != 1 ]]; then
    verify_application visual-studio-code || {
      day_one_app_detect visual-studio-code || true
      err "Visual Studio Code is unavailable or conflicts with the expected application identity."
      warn "$DAY_ONE_APP_REASON"
      return "$EX_GATE"
    }
    ok "Visual Studio Code — $(day_one_app_source_label "$DAY_ONE_APP_SOURCE")"
  fi
  phase_next "VS Code settings and command-line launcher" "Open VS Code, install the 'code' command in PATH, and keep both AI tool auto-approval settings false."
  settings="$HOME/Library/Application Support/Code/User/settings.json"
  settings_content=$'{\n  "editor.formatOnSave": true,\n  "files.insertFinalNewline": true,\n  "files.trimTrailingWhitespace": true,\n  "git.autofetch": true,\n  "terminal.integrated.defaultProfile.osx": "zsh",\n  "terminal.integrated.fontFamily": "\u0027JetBrainsMono Nerd Font\u0027",\n  "chat.tools.global.autoApprove": false,\n  "chat.tools.terminal.enableAutoApprove": false\n}\n'
  if [[ ! -e "$settings" ]]; then
    create_directory "$HOME/Library/Application Support/Code"
    create_directory "$HOME/Library/Application Support/Code/User"
    write_text_file "$settings" "$settings_content"
  fi
  if [[ "$DRY_RUN" == 1 ]]; then print_command code --version; return 0; fi
  have code || {
    warn "Open VS Code and run: Shell Command: Install 'code' command in PATH"
    return "$EX_MANUAL"
  }
  code --version >/dev/null
  grep -Fq '"chat.tools.global.autoApprove": false' "$settings" || {
    warn "Keep chat.tools.global.autoApprove false in VS Code settings."; return "$EX_MANUAL"; }
  grep -Fq '"chat.tools.terminal.enableAutoApprove": false' "$settings" || {
    warn "Keep chat.tools.terminal.enableAutoApprove false in VS Code settings."; return "$EX_MANUAL"; }
  phase_step_done "VS Code opens from Terminal with the safe minimal settings"
  ok "minimal VS Code base verified; profiles and extension catalogues remain optional"
}

report_check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '| %s | PASS |\n' "$label" >> "$STATE_DIR/verification.md"
  else
    printf '| %s | FAIL |\n' "$label" >> "$STATE_DIR/verification.md"
    VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
    phase_gate_failed "$label"
  fi
}

# Scan a chezmoi source for obvious secret material.
#
# Results are returned through globals rather than stdout: a command
# substitution would run this in a subshell and discard SECRET_SCAN_ERROR.
#   SECRET_SCAN_MATCHES — newline-separated matching file paths, empty if clean
#   SECRET_SCAN_ERROR   — why the scan could not run
# Returns 0 when the scan ran (with or without matches) and 1 when the scan
# itself failed, so a broken or missing scanner is never read as a clean result.
#
# Each pattern is passed with -e because several of them begin with "-", which
# ripgrep would otherwise parse as a command-line flag.
SECRET_SCAN_MATCHES=""
SECRET_SCAN_ERROR=""
scan_source_for_secrets() {
  local source="$1" output status
  SECRET_SCAN_MATCHES=""
  SECRET_SCAN_ERROR=""

  if ! command -v rg >/dev/null 2>&1; then
    SECRET_SCAN_ERROR="ripgrep (rg) was not found on PATH. Install it with 'brew install ripgrep', then rerun Phase 8."
    return 1
  fi

  set +e
  output="$(rg -l --hidden -g '!.git/**' \
    -e '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----' \
    -e 'github_pat_[A-Za-z0-9_]{20,}' \
    -e 'ghp_[A-Za-z0-9]{20,}' \
    -e 'AKIA[0-9A-Z]{16}' \
    "$source" 2>&1)"
  status=$?
  set -e

  # ripgrep: 0 = matched, 1 = no match, 2 or higher = the scan failed.
  if [[ "$status" -gt 1 ]]; then
    SECRET_SCAN_ERROR="the secret scan could not run: $output"
    return 1
  fi

  [[ "$status" -eq 0 ]] && SECRET_SCAN_MATCHES="$output"
  return 0
}

verify_dotfiles_remote() {
  local source remote_url provider repo_slug visibility azure_path azure_org azure_project secret_matches behind ahead
  source="$(chezmoi source-path 2>/dev/null || true)"
  phase_next "private dotfiles repository" "Commit the reviewed chezmoi source, add a private origin remote for the selected track, push it, then rerun Phase 8."

  [[ -n "$source" && -d "$source" ]] || {
    err "chezmoi has no readable source directory."
    return "$EX_GATE"
  }
  git -C "$source" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    warn "The chezmoi source is not a Git repository yet: $source"
    warn "Follow Step 8.5 to initialise it, review it for secrets, commit, and add a private remote."
    return "$EX_MANUAL"
  }
  git -C "$source" rev-parse --verify HEAD >/dev/null 2>&1 || {
    warn "The chezmoi source has no commit yet. Review it, create the first commit, and rerun Phase 8."
    return "$EX_MANUAL"
  }

  if ! scan_source_for_secrets "$source"; then
    printf '| Dotfiles secret-pattern scan | FAIL — did not run |\n' >> "$STATE_DIR/verification.md"
    err "The dotfiles source was not scanned for secrets, so it cannot be approved."
    err "$SECRET_SCAN_ERROR"
    return "$EX_GATE"
  fi
  secret_matches="$SECRET_SCAN_MATCHES"
  if [[ -n "$secret_matches" ]]; then
    printf '| Dotfiles secret-pattern review | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "Possible secret material was found in these source files:"
    while IFS= read -r match; do warn "  ${match#"$source"/}"; done <<<"$secret_matches"
    warn "Remove false positives or real secrets safely, rotate exposed credentials, then rerun Phase 8."
    return "$EX_MANUAL"
  fi
  printf '| Dotfiles secret-pattern scan | PASS |\n' >> "$STATE_DIR/verification.md"

  if [[ -n "$(git -C "$source" status --porcelain)" ]]; then
    printf '| Dotfiles repository clean | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "The dotfiles source has uncommitted changes: $source"
    git -C "$source" status --short >&2
    warn "Review and commit the intended files before rerunning Phase 8."
    return "$EX_MANUAL"
  fi
  printf '| Dotfiles repository clean | PASS |\n' >> "$STATE_DIR/verification.md"

  remote_url="$(git -C "$source" remote get-url origin 2>/dev/null || true)"
  [[ -n "$remote_url" ]] || {
    printf '| Private dotfiles origin | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "The dotfiles source has no origin remote. Create a private repository, add origin, push, and rerun."
    return "$EX_MANUAL"
  }

  case "$remote_url" in
    *github.com:*.git|*github.com/*.git|*github.com:*|*github.com/*)
      provider=github
      repo_slug="$(printf '%s\n' "$remote_url" \
        | sed -E 's#^(ssh://)?git@github\.com[:/]##; s#^https://github\.com/##; s#\.git$##')"
      [[ "$TRACK" == 1 || "$TRACK" == 3 ]] || {
        err "A GitHub dotfiles remote does not match Track $TRACK."
        return "$EX_GATE"
      }
      visibility="$(gh repo view "$repo_slug" --json visibility --jq '.visibility' 2>/dev/null || true)"
      [[ "$visibility" == PRIVATE ]] || {
        printf '| Dotfiles remote privacy | FAIL |\n' >> "$STATE_DIR/verification.md"
        err "GitHub did not confirm that $repo_slug is private (reported: ${visibility:-unavailable})."
        return "$EX_GATE"
      }
      ;;
    *ssh.dev.azure.com*|*dev.azure.com/*/_git/*)
      provider=azure
      [[ "$TRACK" == 2 || "$TRACK" == 3 ]] || {
        err "An Azure DevOps dotfiles remote does not match Track $TRACK."
        return "$EX_GATE"
      }
      case "$remote_url" in
        *ssh.dev.azure.com*) azure_path="$(printf '%s\n' "$remote_url" | sed -E 's#^.*ssh\.dev\.azure\.com[:/]v3/##; s#\.git$##')" ;;
        *) azure_path="$(printf '%s\n' "$remote_url" | sed -E 's#^https://dev\.azure\.com/##; s#/_git/#/#; s#\.git$##')" ;;
      esac
      azure_org="${azure_path%%/*}"
      azure_path="${azure_path#*/}"
      azure_project="${azure_path%%/*}"
      azure_project="${azure_project//%20/ }"
      [[ -n "$azure_org" && -n "$azure_project" && "$azure_org" != "$azure_path" ]] || {
        err "Could not identify the Azure organisation and project from origin: $remote_url"
        return "$EX_MANUAL"
      }
      visibility="$(az devops project show --org "https://dev.azure.com/$azure_org" \
        --project "$azure_project" --query visibility -o tsv 2>/dev/null || true)"
      visibility="$(printf '%s' "$visibility" | tr '[:upper:]' '[:lower:]')"
      [[ "$visibility" == private ]] || {
        printf '| Dotfiles remote privacy | FAIL |\n' >> "$STATE_DIR/verification.md"
        err "Azure DevOps did not confirm that project '$azure_project' is private (reported: ${visibility:-unavailable})."
        return "$EX_GATE"
      }
      ;;
    *)
      printf '| Private dotfiles origin | REVIEW |\n' >> "$STATE_DIR/verification.md"
      warn "The origin host is not one this playbook can verify automatically: $remote_url"
      warn "Use a GitHub or Azure DevOps private remote that matches the selected track."
      return "$EX_MANUAL"
      ;;
  esac

  git -C "$source" ls-remote origin >/dev/null 2>&1 || {
    printf '| Dotfiles remote reachable | FAIL |\n' >> "$STATE_DIR/verification.md"
    err "The dotfiles origin is not reachable with the current authentication: $remote_url"
    return "$EX_GATE"
  }
  git -C "$source" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1 || {
    printf '| Dotfiles branch pushed | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "The current dotfiles branch has no upstream. Push it with -u, then rerun Phase 8."
    return "$EX_MANUAL"
  }
  read -r behind ahead <<<"$(git -C "$source" rev-list --left-right --count '@{upstream}...HEAD')"
  if [[ "$behind" != 0 || "$ahead" != 0 ]]; then
    printf '| Dotfiles branch pushed | REVIEW — behind %s, ahead %s |\n' "$behind" "$ahead" >> "$STATE_DIR/verification.md"
    warn "The dotfiles branch and its upstream differ (behind $behind, ahead $ahead)."
    warn "Review, reconcile and push the branch before rerunning Phase 8."
    return "$EX_MANUAL"
  fi
  printf '| Dotfiles remote provider | PASS — %s |\n' "$provider" >> "$STATE_DIR/verification.md"
  printf '| Dotfiles remote privacy | PASS |\n' >> "$STATE_DIR/verification.md"
  printf '| Dotfiles remote reachable | PASS |\n' >> "$STATE_DIR/verification.md"
  printf '| Dotfiles branch pushed | PASS |\n' >> "$STATE_DIR/verification.md"
  phase_step_done "dotfiles source is clean, secret-scanned, private, reachable and pushed"
}

verify_local_dotfiles_source() {
  local source secret_matches
  source="$(chezmoi source-path 2>/dev/null || true)"
  phase_next "local chezmoi source review" "Review the local source and ensure it is included in an encrypted backup."
  [[ -n "$source" && -d "$source" ]] || {
    err "chezmoi has no readable source directory."
    return "$EX_GATE"
  }
  if ! scan_source_for_secrets "$source"; then
    printf '| Dotfiles secret-pattern scan | FAIL — did not run |\n' >> "$STATE_DIR/verification.md"
    err "The dotfiles source was not scanned for secrets, so it cannot be approved."
    err "$SECRET_SCAN_ERROR"
    return "$EX_GATE"
  fi
  secret_matches="$SECRET_SCAN_MATCHES"
  if [[ -n "$secret_matches" ]]; then
    printf '| Dotfiles secret-pattern review | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "Possible secret material was found in these source files:"
    while IFS= read -r match; do warn "  ${match#"$source"/}"; done <<<"$secret_matches"
    warn "Remove real secrets, rotate exposed credentials, then rerun Phase 8."
    return "$EX_MANUAL"
  fi
  printf '| Dotfiles secret-pattern scan | PASS |\n' >> "$STATE_DIR/verification.md"
  printf '| Dotfiles versioning | PASS — local-only selected |\n' >> "$STATE_DIR/verification.md"
  printf '| Dotfiles remote | NOT REQUIRED — local-only selected |\n' >> "$STATE_DIR/verification.md"
  warn "chezmoi is local-only: $source"
  if [[ -d "$source/.git" ]]; then
    printf '| Existing dotfiles Git metadata | PRESENT — preserved, not deleted |\n' >> "$STATE_DIR/verification.md"
    warn "This source already contains Git metadata. Local-only mode skips commit and remote gates but never deletes existing history."
    warn "If you want a genuinely unversioned source, copy the reviewed files into a new source directory instead of deleting .git automatically."
  else
    printf '| Existing dotfiles Git metadata | NONE |\n' >> "$STATE_DIR/verification.md"
    warn "There is no Git history or remote recovery gate."
  fi
  warn "Include the chezmoi source directory in an encrypted backup."
  phase_step_done "local-only chezmoi source is readable and secret-scanned"
}

phase_08() {
  local brewfile="$HOME/Brewfile" brewfile_created=0 report="$STATE_DIR/verification.md" app_id
  local plaintext_keys plaintext_key
  ui_title '8️⃣' 'Phase 08 — Verify and reproduce'
  info "Guide: $(phase_doc 08)"
  if [[ "$DRY_RUN" == 1 ]]; then
    print_command "$SCRIPT_DIR/validate.sh"
    info "would write $report and verify the selected track and stack"
    info "would preserve an existing $brewfile, or create and manage it if absent"
    print_command brew bundle dump --file="$brewfile"
    print_command chezmoi add "$brewfile"
    if [[ "$DOTFILES_VERSIONING" == git ]]; then
      info "would require a clean, pushed, private GitHub or Azure DevOps dotfiles origin"
    else
      info "would verify the local-only chezmoi source and skip Git remote requirements"
    fi
    return 0
  fi
  phase_next "Day One Mac project validation" "Run scripts/validate.sh, fix the named structural or semantic failure, then rerun Phase 8."
  "$SCRIPT_DIR/validate.sh" || return "$EX_GATE"
  phase_step_done "Day One Mac project validation passed"
  ensure_state
  VERIFY_FAILURES=0
  phase_next "machine verification gates" "Open ~/.day-one-mac/verification.md and return to the phase that owns each failed row."
  {
    printf '# Day One Mac verification\n\n'
    printf -- '- Generated: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- Track: `%s — %s`\n' "$TRACK" "$(track_name)"
    printf -- '- Stack: `%s`\n' "$STACK"
    printf -- '- Dotfiles versioning: `%s`\n\n' "$DOTFILES_VERSIONING"
    printf '| Gate | Result |\n|---|---|\n'
  } > "$report"
  report_check "Apple-silicon native terminal" day_one_require_apple_silicon
  report_check "Xcode or Command Line Tools readiness" verify_apple_developer_tools
  report_check "Apple-silicon Homebrew prefix" bash -c '[[ "$(brew --prefix 2>/dev/null)" == /opt/homebrew ]]'
  report_check "Git identity" git config --global user.email
  report_check "ghq repository root" bash -c '[[ "$(ghq root 2>/dev/null | sed -n "1p")" == "$HOME/Developer" ]]'
  report_check "Day One Mac project root" bash -c '[[ "$(day-one-mac root)" == "$1" ]]' _ "$PROJECT_DIR"
  report_check "post-setup finalisation command" day-one-mac finalize --help
  report_check "advanced setup command" day-one-mac advanced --list
  report_check "advanced environment report command" day-one-mac advanced-audit --help
  report_check "existing-Mac safety report command" day-one-mac safety-report --plan
  report_check "existing-Mac Route A/Route B command" day-one-mac prepare-existing --help
  report_check "chezmoi" chezmoi doctor
  report_check "Starship" starship --version
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    day_one_app_load "$app_id" || continue
    report_application "$DAY_ONE_APP_NAME" "$app_id"
  done < <(required_application_ids)
  report_check "VS Code CLI" code --version
  report_check "FileVault" bash -c "fdesetup status 2>/dev/null | grep -q 'FileVault is On'"
  report_check "Gatekeeper" bash -c "spctl --status 2>/dev/null | grep -q 'assessments enabled'"
  uses_node && report_check "Node, npm and pnpm" zsh -lic 'node --version && npm --version && pnpm --version'
  uses_python && report_check "Python via uv" uv python find
  uses_github && report_check "GitHub CLI" gh auth status
  uses_azure && report_check "Azure CLI" az account show
  printf '| Git authentication mode | %s |\n' "$AUTH_MODE" >> "$report"
  # Ask the agent this mode actually uses. In 1password mode the agent is
  # reached through the IdentityAgent socket in ~/.ssh/config, not through
  # SSH_AUTH_SOCK, so a bare `ssh-add -l` queries the empty default agent and
  # reports a failure even when 1Password is serving keys correctly.
  case "$AUTH_MODE" in
    1password)
      if [[ -n "$(agent_identities "$ONEPASSWORD_AGENT_SOCK")" ]]; then
        printf '| SSH agent identity | PASS |\n' >> "$report"
      else
        printf '| SSH agent identity | FAIL |\n' >> "$report"
        VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
        phase_gate_failed "SSH agent identity"
      fi
      ;;
    keychain|external)
      if [[ -n "$(agent_identities "")" ]]; then
        printf '| SSH agent identity | PASS |\n' >> "$report"
      else
        printf '| SSH agent identity | FAIL |\n' >> "$report"
        VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
        phase_gate_failed "SSH agent identity"
      fi
      ;;
    https)
      printf '| SSH agent identity | NOT REQUIRED — https selected |\n' >> "$report"
      ;;
  esac
  # The no-plaintext-key guarantee holds for every mode except keychain, which
  # creates one on purpose; asserting it there would contradict the design.
  if [[ "$AUTH_MODE" == keychain ]]; then
    printf '| Plaintext private key in ~/.ssh | EXPECTED — keychain mode |\n' >> "$report"
  else
    # Name the offending files: "FAIL" alone leaves no way to tell which key
    # appeared, or whether it is one `gh auth login` created before the
    # --skip-ssh-key flag was added.
    plaintext_keys="$(find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' 2>/dev/null | LC_ALL=C sort || true)"
    if [[ -z "$plaintext_keys" ]]; then
      printf '| No plaintext private key in ~/.ssh | PASS |\n' >> "$report"
    else
      printf '| No plaintext private key in ~/.ssh | FAIL |\n' >> "$report"
      while IFS= read -r plaintext_key; do
        [[ -n "$plaintext_key" ]] || continue
        printf '| — unexpected private key | `%s` |\n' "${plaintext_key/#"$HOME"/~}" >> "$report"
        warn "Unexpected private key on disk: ${plaintext_key/#"$HOME"/~}"
      done <<<"$plaintext_keys"
      warn "Auth mode '$AUTH_MODE' keeps no private key in ~/.ssh."
      warn "If 'gh auth login' created it before --skip-ssh-key was added, remove it from GitHub, then delete it once 1Password's key is confirmed working."
      VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
      phase_gate_failed "No plaintext private key in ~/.ssh"
    fi
  fi
  chmod 600 "$report"
  info "report: $report"
  if [[ "$VERIFY_FAILURES" -gt 0 ]]; then
    err "$VERIFY_FAILURES verification gate(s) failed; review the report."
    return "$EX_GATE"
  fi
  phase_step_done "track- and stack-aware machine audit passed"
  phase_next "reviewed Brewfile under chezmoi management" "Review ~/Brewfile, add it to chezmoi if needed, and rerun Phase 8."
  if [[ ! -e "$brewfile" ]]; then
    record_path_before_write "$brewfile"
    run brew bundle dump --file="$brewfile"
    brewfile_created=1
    ok "recorded the installed Homebrew desired state in $brewfile"
  else
    info "preserved existing $brewfile"
  fi
  if ! chezmoi source-path "$brewfile" >/dev/null 2>&1; then
    if [[ "$brewfile_created" == 1 ]]; then
      run chezmoi add "$brewfile"
    else
      printf '| Brewfile managed by chezmoi | REVIEW |\n' >> "$report"
      warn "$brewfile already existed and is not managed by chezmoi."
      warn "Review it, run 'chezmoi add $brewfile', then rerun Phase 8."
      return "$EX_MANUAL"
    fi
  fi
  if chezmoi source-path "$brewfile" >/dev/null 2>&1; then
    printf '| Brewfile managed by chezmoi | PASS |\n' >> "$report"
  else
    printf '| Brewfile managed by chezmoi | FAIL |\n' >> "$report"
    err "Brewfile could not be added to chezmoi."
    return "$EX_GATE"
  fi
  phase_step_done "reviewed Brewfile is managed by chezmoi"
  if [[ "$DOTFILES_VERSIONING" == git ]]; then
    verify_dotfiles_remote || return $?
  else
    verify_local_dotfiles_source || return $?
  fi
  ok "Day One Mac base is complete; optional extras remain optional"
}

phase_exit_report() {
  local rc="$1" item
  [[ "$rc" -eq 0 ]] && return 0
  printf '\n%s%s⛔ Phase %s is incomplete%s\n' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_RED" "$CURRENT_PHASE" "$DAY_ONE_UI_RESET" >&2
  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$DAY_ONE_UI_DIM" "$DAY_ONE_UI_RESET" >&2
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
  local phase="$1"
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
  mark_phase_done "$phase"
  trap - EXIT
  CURRENT_PHASE=""
}

show_status() {
  local phase status
  ui_title '📊' 'Day One Mac status'
  printf '  Track: %s\n' "${TRACK:-not selected}"
  printf '  Stack: %s\n' "${STACK:-not selected}"
  printf '  Git authentication: %s\n' "${AUTH_MODE:-1password}"
  printf '  Dotfiles: %s\n' "${DOTFILES_VERSIONING:-git}"
  printf '  Early macOS settings: %s\n' "${MACOS_SETTINGS_PLAN:-not selected}"
  printf '  Optional plan: %s\n' "${OPTIONAL_MODULES:-none}"
  printf '  State: %s\n\n' "$STATE_DIR"
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

run_macos_settings_checkpoint() {
  local settings_script="$SCRIPT_DIR/configure-macos-settings.sh" settings_status rc answer
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --guided) GUIDED=1 ;;
    --phase)
      shift
      [[ $# -gt 0 && "$1" =~ ^0?[1-8]$ ]] || { err "--phase needs 01–08"; exit 2; }
      REQUESTED_PHASES="$REQUESTED_PHASES ${1#0}"
      GUIDED=0
      ;;
    --track) shift; [[ $# -gt 0 ]] || { err "--track needs 1, 2, or 3"; exit 2; }; TRACK="$1"; TRACK_EXPLICIT=1 ;;
    --stack) shift; [[ $# -gt 0 ]] || { err "--stack needs node, python, or both"; exit 2; }; STACK="$1" ;;
    --name) shift; [[ $# -gt 0 ]] || { err "--name needs a value"; exit 2; }; GIT_NAME="$1" ;;
    --email) shift; [[ $# -gt 0 ]] || { err "--email needs a value"; exit 2; }; GIT_EMAIL="$1" ;;
    --dotfiles-repo) shift; [[ $# -gt 0 ]] || { err "--dotfiles-repo needs a URL"; exit 2; }; DOTFILES_REPO="$1"; DOTFILES_VERSIONING=git; DOTFILES_EXPLICIT=1 ;;
    --new-dotfiles) DOTFILES_REPO=""; DOTFILES_EXPLICIT=1 ;;
    --dotfiles-versioning) shift; [[ $# -gt 0 ]] || { err "--dotfiles-versioning needs git or local"; exit 2; }; DOTFILES_VERSIONING="$1"; [[ "$1" != local ]] || { DOTFILES_REPO=""; DOTFILES_EXPLICIT=1; } ;;
    --local-dotfiles) DOTFILES_REPO=""; DOTFILES_VERSIONING=local; DOTFILES_EXPLICIT=1 ;;
    --auth-mode) shift; [[ $# -gt 0 ]] || { err "--auth-mode needs 1password, keychain, external, or https"; exit 2; }; AUTH_MODE="$1" ;;
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
    --status) SHOW_STATUS=1; GUIDED=0 ;;
    --reset-progress) RESET_PROGRESS=1; GUIDED=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

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
  warn "Using pre-rename setup state at $STATE_ROOT; saved progress remains valid."
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
      [[ "$TRACK" =~ ^[123]$ ]] || {
        err "No saved hosting track, so 'both' cannot decide which keys to pin."
        err "Name the provider instead: --ssh-pin github, or --ssh-pin azure."
        exit 2
      }
      if uses_github; then export_provider_public_key github || ssh_pin_failures=1; fi
      if uses_azure; then export_provider_public_key azure || ssh_pin_failures=1; fi
      ;;
  esac
  [[ "$ssh_pin_failures" == 0 ]] || { err "No public key was pinned."; exit 1; }
  exit 0
fi

if [[ "$SHOW_STATUS" == 1 ]]; then
  TRACK="${TRACK:-$(state_value track)}"
  STACK="${STACK:-$(state_value stack)}"
  GIT_NAME="${GIT_NAME:-$(state_value git-name)}"
  GIT_EMAIL="${GIT_EMAIL:-$(state_value git-email)}"
  DOTFILES_REPO="${DOTFILES_REPO:-$(state_value dotfiles-repo)}"
  DOTFILES_VERSIONING="${DOTFILES_VERSIONING:-$(state_value dotfiles-versioning)}"
  [[ -n "$DOTFILES_VERSIONING" ]] || DOTFILES_VERSIONING=git
  MACOS_SETTINGS_PLAN="${MACOS_SETTINGS_PLAN:-$(state_value macos-settings-plan)}"
  AUTH_MODE="${AUTH_MODE:-$(state_value auth-mode)}"
  [[ -n "$AUTH_MODE" ]] || AUTH_MODE=1password
  OPTIONAL_MODULES="$(state_value optional-modules)"
  if [[ -n "$TRACK" && "$(state_value track-schema-version)" != "$TRACK_SCHEMA_VERSION" && "$TRACK_EXPLICIT" != 1 ]]; then
    warn "Saved track uses the retired numbering; rerun with --track 1, 2, or 3."
  fi
  show_status
  exit 0
fi

load_or_choose_selections
save_state_value project-root "$PROJECT_DIR"
save_state_value track "$TRACK"
save_state_value track-schema-version "$TRACK_SCHEMA_VERSION"
save_state_value stack "$STACK"
[[ -n "$GIT_NAME" ]] && save_state_value git-name "$GIT_NAME"
[[ -n "$GIT_EMAIL" ]] && save_state_value git-email "$GIT_EMAIL"
if [[ "$DOTFILES_EXPLICIT" == 1 || -n "$DOTFILES_REPO" ]]; then
  save_state_value dotfiles-repo "$DOTFILES_REPO"
fi
save_state_value dotfiles-versioning "$DOTFILES_VERSIONING"
save_state_value macos-settings-plan "$MACOS_SETTINGS_PLAN"

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
