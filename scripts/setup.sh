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
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/operation-lock.sh"
source "$SCRIPT_DIR/lib/deadline.sh"
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
PRESET=""
PRIMARY_IDE=""
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

# Contract versions accompany hashes of the runner, shared libraries and phase
# implementation. Documentation edits do not invalidate required phases.
PHASE_SCHEMA_01=5
PHASE_SCHEMA_02=3
PHASE_SCHEMA_03=6
PHASE_SCHEMA_04=6
PHASE_SCHEMA_05=15
PHASE_SCHEMA_06=2
PHASE_SCHEMA_07=4
PHASE_SCHEMA_08=11

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
  --preset PRESET            core or recommended-productivity (default)
  --primary-ide IDE           vscode or other; controls Git editor integration
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
  [[ -n "$PRESET" ]] || PRESET="$(state_value preset)"
  PRESET="${PRESET:-recommended-productivity}"
  [[ "$PRESET" =~ ^(core|recommended-productivity)$ ]] || { err "preset must be core or recommended-productivity"; exit 2; }
  [[ -n "$PRIMARY_IDE" ]] || PRIMARY_IDE="$(state_value primary-ide)"
  [[ "$PRESET" != core ]] || PRIMARY_IDE=other
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
  if [[ -z "$PRIMARY_IDE" ]]; then
    if [[ "$DRY_RUN" == 1 || ! -t 0 ]]; then PRIMARY_IDE=vscode
    else PRIMARY_IDE="$(ask 'Use VS Code as the primary IDE? Enter vscode or other' vscode '^(vscode|other)$')"
    fi
  fi
  if [[ -z "$MACOS_SETTINGS_PLAN" ]]; then
    if [[ -n "$REQUESTED_PHASES" ]]; then MACOS_SETTINGS_PLAN=skip
    else MACOS_SETTINGS_PLAN="$(ask 'Early macOS settings: configure or skip' configure '^(configure|skip)$')"
    fi
  fi
  [[ "$TRACK" =~ ^[123]$ ]] || { err "track must be 1, 2, or 3"; exit 2; }
  [[ "$STACK" =~ ^(node|python|both)$ ]] || { err "stack must be node, python, or both"; exit 2; }
  [[ "$PRIMARY_IDE" =~ ^(vscode|other)$ ]] || { err "primary IDE must be vscode or other"; exit 2; }
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
  local schema inputs application_catalog_hash implementation
  local dependencies=("$SCRIPT_DIR/setup.sh" "$SCRIPT_DIR"/lib/*.sh "$SCRIPT_DIR"/phases/"$1"-*.sh)
  case "$1" in
    04|05) dependencies+=("$SCRIPT_DIR"/phases/03-*.sh) ;;
    08) dependencies+=("$SCRIPT_DIR"/phases/*.sh "$SCRIPT_DIR/verify.sh") ;;
  esac
  application_catalog_hash="$(awk -F '\t' '$2 == "required"' "$DAY_ONE_APP_CATALOG" | shasum -a 256 | awk '{print $1}')"
  eval "schema=\${PHASE_SCHEMA_$1}"
  implementation="$(
    shasum -a 256 "${dependencies[@]}" |
      awk '{print $1}' | shasum -a 256 | awk '{print $1}'
  )"
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
  { printf 'phase-schema=%s\n' "$schema"; printf 'implementation=%s\n' "$implementation";
    printf 'inputs=%s\n' "$inputs|preset=${PRESET:-recommended-productivity}"; } \
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
    printf 'preset=%s\nauth=%s\n' "${PRESET:-recommended-productivity}" "$AUTH_MODE"
    printf 'implementation=%s\n' "$(phase_fingerprint 04)"
    printf 'applications=%s\n' "$application_catalog_hash"
    printf 'formulae=%s\n' "$formulae_hash"
  } | shasum -a 256 | awk '{print $1}'
}

installation_centre_components_ready() {
  local app_id formula application_list formula_list
  load_brew || return 1
  # Finish bounded catalogue reads before a check can return early. Process
  # substitution leaves a background writer on a pipe the caller may close.
  application_list="$(required_application_ids)" || return 1
  formula_list="$(required_formulae)" || return 1
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    day_one_app_detect "$app_id" || return 1
    day_one_app_is_satisfied || return 1
  done <<<"$application_list"
  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    brew list --formula "$formula" >/dev/null 2>&1 || return 1
  done <<<"$formula_list"
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
  day_one_write_state "$marker" "$(installation_centre_fingerprint)"
  log_line 'PASS installation-centre'
}

mark_phase_done() {
  [[ "$DRY_RUN" == 1 ]] && { ok "would mark Phase $1 complete"; return 0; }
  ensure_state
  day_one_write_state "$COMPLETED_DIR/$1" "$(phase_fingerprint "$1")"
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
  local app_ids="" formulae="" application_list
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
  application_list="$(required_application_ids)" || return "$EX_GATE"
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
  done <<<"$application_list"

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

source "$SCRIPT_DIR/phases/01-decisions.sh"
source "$SCRIPT_DIR/phases/02-foundation.sh"
source "$SCRIPT_DIR/phases/03-security.sh"
source "$SCRIPT_DIR/phases/04-hosting.sh"
source "$SCRIPT_DIR/phases/05-dotfiles.sh"
source "$SCRIPT_DIR/phases/06-toolchains.sh"
source "$SCRIPT_DIR/phases/07-editor.sh"
source "$SCRIPT_DIR/phases/08-verification.sh"

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
  printf '  Preset: %s\n' "${PRESET:-recommended-productivity}"
  printf '  Primary IDE: %s\n' "${PRIMARY_IDE:-not selected}"
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

# Sourcing exposes the real runner/modules to tests without executing setup.
[[ "${BASH_SOURCE[0]}" == "$0" ]] || return 0

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
    --preset) shift; [[ $# -gt 0 ]] || { err "--preset needs core or recommended-productivity"; exit 2; }; PRESET="$1" ;;
    --primary-ide) shift; [[ $# -gt 0 ]] || { err "--primary-ide needs vscode or other"; exit 2; }; PRIMARY_IDE="$1" ;;
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
  PRESET="${PRESET:-$(state_value preset)}"
  PRESET="${PRESET:-recommended-productivity}"
  PRIMARY_IDE="${PRIMARY_IDE:-$(state_value primary-ide)}"
  [[ -n "$PRIMARY_IDE" ]] || PRIMARY_IDE=vscode
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
save_state_value preset "$PRESET"
save_state_value auth-mode "$AUTH_MODE"
save_state_value primary-ide "$PRIMARY_IDE"
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
