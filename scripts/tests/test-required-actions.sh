#!/usr/bin/env bash
# Read-only action and compatibility regressions; never operate on the real HOME.
# The real function is sourced before the deliberate resume-test overrides.
# shellcheck disable=SC2218
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-actions.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
trap 'printf "Required-action test failed at line %s\n" "$LINENO" >&2' ERR
export HOME="$TEST_ROOT/home"
export DAY_ONE_MAC_STATE_ROOT="$HOME/state"
export DAY_ONE_MAC_DISABLE_BREW_DISCOVERY=1
mkdir -p "$HOME"

expect_exit() {
  local expected="$1" actual=0; shift
  "$@" > "$TEST_ROOT/output" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || {
    cat "$TEST_ROOT/output" >&2
    printf 'Expected exit %s, got %s\n' "$expected" "$actual" >&2; exit 1; }
}

expect_exit 0 "$SCRIPT_DIR/day-one-mac" --version
grep -Fq "day-one-mac $(cat "$SCRIPT_DIR/../VERSION")" "$TEST_ROOT/output"
expect_exit 2 "$SCRIPT_DIR/day-one-mac" nonsense
grep -Fq 'Unknown command' "$TEST_ROOT/output"
expect_exit 2 "$SCRIPT_DIR/day-one-mac" optional --check --status --module 09
expect_exit 2 /bin/bash "$SCRIPT_DIR/setup.sh" --plan --apply
expect_exit 2 /bin/bash "$SCRIPT_DIR/setup.sh" --check --yes
expect_exit 2 /bin/bash "$SCRIPT_DIR/setup.sh" --plan --install-centre
expect_exit 2 /bin/bash "$SCRIPT_DIR/setup.sh" --apply --json
expect_exit 2 /bin/bash "$SCRIPT_DIR/setup.sh" --resume --stack node
expect_exit 2 /bin/bash "$SCRIPT_DIR/setup.sh" --resume --azure-clone-dir none
expect_exit 2 /bin/bash "$SCRIPT_DIR/setup.sh" --resume
expect_exit 2 /bin/bash "$SCRIPT_DIR/setup.sh" --check
expect_exit 10 /bin/bash "$SCRIPT_DIR/setup.sh" --apply --yes --track 1 --stack both
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT" ]]

expect_exit 0 /bin/bash "$SCRIPT_DIR/setup.sh" --plan --phase 04 --track 2 --stack both --auth-mode https \
  --azure-repo 'https://dev.azure.com/ORG/PROJECT/_git/REPO' \
  --azure-clone-dir "$HOME/clone with spaces" --json
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(!JSON.stringify(r.phases[0]).includes("clone with spaces")) process.exit(1)' "$TEST_ROOT/output"
[[ ! -e "$HOME/clone with spaces" && ! -e "$DAY_ONE_MAC_STATE_ROOT" ]]

expect_exit 0 /bin/bash "$SCRIPT_DIR/setup.sh" --plan --track 4 --stack both --json
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.selection.track!=="4" || r.selection.auth_mode!=="https") process.exit(1)' "$TEST_ROOT/output"
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT" ]]

expect_exit 0 /bin/bash "$SCRIPT_DIR/setup.sh" --plan --track 1 --stack both --json
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.schema_version!==1 || r.action!=="plan" || r.phases.length!==8 || r.phases[7].live!=="not-checked") process.exit(1)' "$TEST_ROOT/output"
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT" ]]
expect_exit 11 /bin/bash "$SCRIPT_DIR/setup.sh" --check --phase 05 --track 1 --stack both --json
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.phases[0].live!=="fail" || !r.checked_at || r.scope!=="local-read-only") process.exit(1)' "$TEST_ROOT/output"
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT" ]]
# Preserve existing evidence byte-for-byte, including stale completion and logs.
mkdir -p "$DAY_ONE_MAC_STATE_ROOT/completed"
printf 'old marker\n' > "$DAY_ONE_MAC_STATE_ROOT/completed/05"
printf 'private report\n' > "$DAY_ONE_MAC_STATE_ROOT/verification.md"
printf 'private log\n' > "$DAY_ONE_MAC_STATE_ROOT/setup.log"
before="$(find "$DAY_ONE_MAC_STATE_ROOT" -type f -exec shasum -a 256 {} \; | sort)"
expect_exit 11 /bin/bash "$SCRIPT_DIR/setup.sh" --phase 05 --check --track 1 --stack both --json
after="$(find "$DAY_ONE_MAC_STATE_ROOT" -type f -exec shasum -a 256 {} \; | sort)"
[[ "$before" == "$after" && ! -e "${DAY_ONE_MAC_STATE_ROOT}.operation.lock" ]]
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.phases[0].recorded!=="changed") process.exit(1)' "$TEST_ROOT/output"
rm "$DAY_ONE_MAC_STATE_ROOT/completed/05"
before="$(find "$DAY_ONE_MAC_STATE_ROOT" -type f -exec shasum -a 256 {} \; | sort)"
expect_exit 11 /bin/bash "$SCRIPT_DIR/setup.sh" --check --track 1 --stack both --json
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.phases.length!==8 || r.phases[7].live!=="fail") process.exit(1)' "$TEST_ROOT/output"
after="$(find "$DAY_ONE_MAC_STATE_ROOT" -type f -exec shasum -a 256 {} \; | sort)"
[[ "$before" == "$after" && ! -e "${DAY_ONE_MAC_STATE_ROOT}.operation.lock" ]]
expect_exit 10 /bin/bash "$SCRIPT_DIR/setup.sh" --check --phase 01 --track 1 --stack both --name Fixture --email fixture@example.com --json
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.phases[0].live!=="manual") process.exit(1)' "$TEST_ROOT/output"
expect_exit 0 /bin/bash "$SCRIPT_DIR/setup.sh" --check --phase 07 --track 1 --stack both --preset core --json
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.phases[0].live!=="not-required") process.exit(1)' "$TEST_ROOT/output"
expect_exit 0 /bin/bash "$SCRIPT_DIR/setup.sh" --status --json
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.checked_at!==null || r.phases.some(p=>p.recorded!=="pending" || p.live!=="not-checked")) process.exit(1)' "$TEST_ROOT/output"
expect_exit 0 "$SCRIPT_DIR/day-one-mac" optional --status
expect_exit 0 "$SCRIPT_DIR/day-one-mac" optional --check --status
cp "$TEST_ROOT/output" "$TEST_ROOT/dashboard-check"
expect_exit 0 "$SCRIPT_DIR/day-one-mac" optional --status --check
cmp "$TEST_ROOT/output" "$TEST_ROOT/dashboard-check"

# Resetting progress must not reset the track or discard ownership evidence.
printf '2\n' > "$DAY_ONE_MAC_STATE_ROOT/track"
printf '2\n' > "$DAY_ONE_MAC_STATE_ROOT/track-schema-version"
printf 'phase fixture\n' > "$DAY_ONE_MAC_STATE_ROOT/completed/04"
printf 'owned fixture\n' > "$DAY_ONE_MAC_STATE_ROOT/path-manifest.tsv"
expect_exit 0 /bin/bash "$SCRIPT_DIR/setup.sh" --reset-progress --dry-run
[[ -f "$DAY_ONE_MAC_STATE_ROOT/completed/04" ]]
expect_exit 0 /bin/bash "$SCRIPT_DIR/setup.sh" --reset-progress
[[ ! -f "$DAY_ONE_MAC_STATE_ROOT/completed/04" ]]
[[ "$(cat "$DAY_ONE_MAC_STATE_ROOT/track")" == 2 ]]
grep -Fqx 'owned fixture' "$DAY_ONE_MAC_STATE_ROOT/path-manifest.tsv"
find "$DAY_ONE_MAC_STATE_ROOT" -path '*/completed-*/04' -type f | grep -q .
rm "$DAY_ONE_MAC_STATE_ROOT/track" "$DAY_ONE_MAC_STATE_ROOT/track-schema-version" "$DAY_ONE_MAC_STATE_ROOT/path-manifest.tsv"

# Source the real runner: fail immediately if inspection touches a write hook.
source "$SCRIPT_DIR/setup.sh"
ensure_state() { printf 'unexpected write\n' >&2; exit 99; }
run() { printf 'unexpected mutation\n' >&2; exit 99; }
save_state_value() { printf 'unexpected state write\n' >&2; exit 99; }
# Real Git URL matching, isolated from the user's configuration and network.
(
  export GIT_CONFIG_NOSYSTEM=1
  DRY_RUN=0 GHQ_CHOICE=yes AUTH_MODE=https
  run() { "$@"; }
  record_path_before_write() { printf '%s\n' "$1" >> "$TEST_ROOT/git-recorded"; }
  for TRACK in 1 2 3 4; do
    rm -f "$HOME/.gitconfig" "$TEST_ROOT/git-recorded"
    : > "$HOME/.gitconfig"
    configure_track_git_settings
    case "$TRACK" in 1) expected=2 ;; 2) expected=3 ;; 3) expected=5 ;; 4) expected=0 ;; esac
    actual="$(git config --global --list 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$actual" == "$expected" ]]
    if uses_github; then
      [[ "$(git config --global --get-urlmatch ghq.vcs https://github.com/OWNER/REPO)" == git ]]
      [[ "$(git config --global --get-urlmatch ghq.vcs ssh://git@github.com/OWNER/REPO)" == git ]]
    fi
    if uses_azure; then
      [[ "$(git config --global --get-urlmatch ghq.vcs https://ORG@dev.azure.com/ORG/PROJECT/_git/REPO)" == git ]]
      [[ "$(git config --global --get-urlmatch ghq.vcs ssh://git@ssh.dev.azure.com/v3/ORG/PROJECT/REPO)" == git ]]
      [[ "$(git config --global --get-urlmatch credential.useHttpPath https://dev.azure.com/ORG/PROJECT/_git/REPO)" == true ]]
    fi
    before="$(cat "$HOME/.gitconfig" 2>/dev/null || true)"
    rm -f "$TEST_ROOT/git-recorded"
    configure_track_git_settings
    [[ ! -e "$TEST_ROOT/git-recorded" && "$before" == "$(cat "$HOME/.gitconfig" 2>/dev/null || true)" ]]
  done
  TRACK=3 GHQ_CHOICE=no AUTH_MODE=keychain
  [[ -z "$(track_git_settings)" ]]
  GHQ_CHOICE=yes
  [[ "$(track_git_settings | wc -l | tr -d ' ')" == 4 ]]
  # A later conflict must stop before writing an earlier missing setting.
  git config --global ghq.https://dev.azure.com.vcs svn
  before="$(cat "$HOME/.gitconfig")"
  result=0
  configure_track_git_settings > "$TEST_ROOT/git-conflict" 2>&1 || result=$?
  [[ "$result" == "$EX_MANUAL" && "$before" == "$(cat "$HOME/.gitconfig")" ]]
  grep -Fq 'configuration owner' "$TEST_ROOT/git-conflict"
  # Changing tracks preserves settings belonging to the previous provider.
  git config --global --unset ghq.https://dev.azure.com.vcs
  TRACK=2 AUTH_MODE=https
  configure_track_git_settings
  TRACK=1
  configure_track_git_settings
  [[ "$(git config --global --get ghq.https://dev.azure.com.vcs)" == git ]]
  DRY_RUN=1
  run() { printf '%s\n' "$*"; }
  before="$(cat "$HOME/.gitconfig")"
  configure_track_git_settings > "$TEST_ROOT/git-plan"
  grep -Fq 'ghq.https://github.com.vcs git' "$TEST_ROOT/git-plan"
  [[ "$before" == "$(cat "$HOME/.gitconfig")" ]]
  rm -f "$HOME/.gitconfig"
)
# The same Azure package probe must accept casks and legacy formulae in the
# Centre and Phase 4, without adopting an existing package as runner-owned.
(
  DRY_RUN=0
  FIXTURE_AZURE_PACKAGE=cask
  load_brew() { return 0; }
  required_application_ids() { :; }
  required_formulae() { printf 'azure-cli\n'; }
  brew() {
    case "$*" in
      'list --formula azure-cli') [[ "$FIXTURE_AZURE_PACKAGE" == formula ]] ;;
      'list --cask azure-cli') [[ "$FIXTURE_AZURE_PACKAGE" == cask ]] ;;
      'list --formula') printf 'git\n' ;;
      'install --cask azure-cli') FIXTURE_AZURE_PACKAGE=cask ;;
      *) printf 'Unexpected brew probe: %s\n' "$*" >&2; return 99 ;;
    esac
  }
  record_package() { printf '%s\t%s\n' "$1" "$2" >> "$TEST_ROOT/azure-ownership"; }
  run() { printf '%s\n' "$*" >> "$TEST_ROOT/azure-commands"; "$@"; }
  installation_centre_components_ready
  install_formula azure-cli
  [[ ! -e "$TEST_ROOT/azure-ownership" && ! -e "$TEST_ROOT/azure-commands" ]]
  FIXTURE_AZURE_PACKAGE=formula
  installation_centre_components_ready
  install_formula azure-cli
  [[ ! -e "$TEST_ROOT/azure-ownership" && ! -e "$TEST_ROOT/azure-commands" ]]
  FIXTURE_AZURE_PACKAGE=missing
  if installation_centre_components_ready; then
    printf 'Missing Azure package was accepted\n' >&2; exit 1
  fi
  install_formula azure-cli
  installation_centre_components_ready
  grep -Fxq 'brew install --cask azure-cli' "$TEST_ROOT/azure-commands"
  grep -Fxq $'brew-cask\tazure-cli' "$TEST_ROOT/azure-ownership"
  ! grep -Fq brew-formula "$TEST_ROOT/azure-ownership"
)

TRACK=1 STACK=both PRESET=core PRIMARY_IDE=other AUTH_MODE=keychain
DOTFILES_VERSIONING=local GIT_NAME='Fixture' GIT_EMAIL='fixture@example.com'
check_required_phase 07
[[ "$CHECK_RESULT" == not-required ]]
check_required_phase 05
[[ "$CHECK_RESULT" == fail ]]
check_required_phase 01
[[ "$CHECK_RESULT" == manual ]]
GIT_EMAIL=invalid
check_required_phase 01
[[ "$CHECK_RESULT" == fail ]]
# Round-trip, not just parse: Bash 3.2 can treat UTF-8 bytes as negative
# character codes in a byte locale, producing parseable but corrupted JSON.
(
  json_value=$'quote" slash\\ tab\t line\n control\001 ✓ — café 日本語 🔒'
  for control in {1..31}; do
    printf -v octal '%03o' "$control"
    printf -v character '%b' "\\$octal"
    json_value+="$character"
  done
  export EXPECTED_JSON_VALUE="$json_value"
  for json_locale in C C.UTF-8 en_US.UTF-8; do
    LC_ALL="$json_locale" required_json_string "$json_value" > "$TEST_ROOT/string.json"
    node -e 'const actual=JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); if(actual!==process.env.EXPECTED_JSON_VALUE) { console.error("JSON string did not round-trip"); process.exit(1); }' "$TEST_ROOT/string.json"
  done
)

# These are the real read-only phase checks, with machine/account probes
# stubbed. No sign-in, network access, key inspection or setup writes run.
(
  fdesetup() { printf 'FileVault is On.\n'; }
  required_check_file() { :; }
  required_check_command() { :; }
  required_check_app() { :; }
  keychain_key_protection() { printf encrypted; }
  required_formulae() { :; }
  required_application_ids() { :; }
  folders_check() { printf '✓ Selected folders checked\n'; }
  xcode-select() { printf '%s\n' "$TEST_ROOT"; }
  git() { case "$*" in *user.name*) printf '%s' "$GIT_NAME" ;; *user.email*) printf '%s' "$GIT_EMAIL" ;; esac; }
  GIT_EMAIL=fixture@example.com
  for AUTH_MODE in https keychain 1password external; do
    check_required_phase 03
    [[ "$CHECK_RESULT" == manual && "$CHECK_DETAILS" == *'recovery-key custody'* ]]
    if [[ "$AUTH_MODE" == https ]]; then
      [[ "$CHECK_DETAILS" == *'SSH key and agent checks are not required'* && "$CHECK_DETAILS" != *'signing'* ]]
      [[ "$(required_phase_impact 03)" == *'no SSH key or agent configuration for HTTPS'* ]]
    else
      [[ "$CHECK_DETAILS" == *'Agent access, provider registration, signing'* ]]
    fi
    check_required_phase 04
    [[ "$CHECK_DETAILS" == *'no login or network probe ran'* ]]
    if [[ "$AUTH_MODE" == https ]]; then
      [[ "$CHECK_DETAILS" == *'HTTPS hosting sessions'* && "$CHECK_DETAILS" != *'SSH reachability'* ]]
    else [[ "$CHECK_DETAILS" == *'SSH reachability'* ]]; fi
  done
  AUTH_MODE=https
  fdesetup() { printf 'FileVault is Off.\n'; }
  check_required_phase 03
  [[ "$CHECK_RESULT" == fail && "$CHECK_DETAILS" == *'FileVault is not confirmed on'* ]]
  fdesetup() { printf 'FileVault is On.\n'; }
  for DOTFILES_VERSIONING in none local git; do
    check_required_phase 08
    final_note="${CHECK_DETAILS##*$'\n'}"
    impact="$(required_phase_impact 08)"
    [[ "$final_note" == manual:* && "$final_note" == *'no report or source was modified'* ]]
    case "$DOTFILES_VERSIONING" in
      none) [[ "$final_note" == *'user-owned configuration and Brewfile backup'* && "$final_note" != *'source secrets'* && "$final_note" != *'remote'* ]]
        [[ "$impact" == *'without chezmoi adoption'* && "$impact" != *'signing'* ]] ;;
      local) [[ "$final_note" == *'source secrets, local backup and Brewfile management'* && "$final_note" != *'remote'* ]]
        [[ "$impact" == *'no remote required'* ]] ;;
      git) [[ "$final_note" == *'source secrets, remote privacy/push state and Brewfile management'* ]]
        [[ "$impact" == *'verify private remote and push state'* ]] ;;
    esac
  done
)

# Resume requires both a current marker AND a successful live check. It must
# never skip on an old successful report, missing tools, or manual-only evidence.
ran=0
phase_done() { return 0; }
check_required_phase() { CHECK_RESULT=fail; }
run_phase() { ran=$((ran + 1)); }
run_required_action_phase 06 resume
[[ "$ran" == 1 ]]
check_required_phase() { CHECK_RESULT=pass; }
run_required_action_phase 06 resume
[[ "$ran" == 1 ]]
check_required_phase() { CHECK_RESULT=manual; }
run_required_action_phase 06 resume
[[ "$ran" == 2 ]]
phase_done() { return 1; }
check_required_phase() { CHECK_RESULT=pass; }
run_required_action_phase 06 resume
[[ "$ran" == 3 ]]
run_required_action_phase 06 apply
[[ "$ran" == 4 ]]
printf 'Required setup action regressions passed.\n'
