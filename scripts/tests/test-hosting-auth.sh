#!/usr/bin/env bash
# No real accounts, repositories, credentials or package installation.
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-hosting.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
export HOME="$TEST_ROOT/home" GIT_CONFIG_NOSYSTEM=1
export TMPDIR="$TEST_ROOT/tmp/" DAY_ONE_MAC_DISABLE_BREW_DISCOVERY=1
mkdir -p "$HOME" "$TMPDIR" "$TEST_ROOT/command bin"
source "$SCRIPT_DIR/setup.sh"
# Bash 3.2 does not stop on every failed [[ ... ]] under set -e. Give each
# assertion an explicit failure path, including negated privacy checks.
fail_test() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
export PATH="$TEST_ROOT/command bin:/usr/bin:/bin:/usr/sbin:/sbin"
export GIT_FIXTURE_LOG="$TEST_ROOT/transport" GIT_FIXTURE_EXIT=0
cat > "$TEST_ROOT/command bin/git" <<'EOF'
#!/bin/bash
case "$*" in
  *'clone -- '*)
    printf '%s\t%s\t%s\n' "${GIT_TERMINAL_PROMPT:-}" "${GCM_INTERACTIVE:-}" "${GIT_SSH_COMMAND:-}" >> "$GIT_FIXTURE_LOG.clone"
    while [[ "$1" != clone ]]; do shift; done
    shift 2
    if [[ "${GIT_FIXTURE_PARTIAL:-0}" == 1 ]]; then
      mkdir -p "$2"
      printf 'partial clone\n' > "$2/partial"
    fi
    [[ "${GIT_FIXTURE_EXIT:-0}" == 0 ]] || exit "$GIT_FIXTURE_EXIT"
    [[ "${GIT_FIXTURE_NO_CLONE:-0}" != 1 ]] || exit 0
    /usr/bin/git init -q "$2" || exit 1
    /usr/bin/git -C "$2" remote add origin "$1"
    exit $? ;;
  *ls-remote*)
    printf '%s\t%s\t%s\n' "${GIT_TERMINAL_PROMPT:-}" "${GCM_INTERACTIVE:-}" "${GIT_SSH_COMMAND:-}" >> "$GIT_FIXTURE_LOG"
    printf 'private fixture refs or authentication output\n'
    exit "$GIT_FIXTURE_EXIT" ;;
  *) exec /usr/bin/git "$@" ;;
esac
EOF
cat > "$TEST_ROOT/command bin/git-credential-manager" <<'EOF'
#!/bin/bash
case "$1" in
  --version) exit 0 ;;
  get) cat >/dev/null; printf 'username=fixture\npassword=fixture\n' ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TEST_ROOT/command bin/"*
DRY_RUN=0 TRACK=2 AUTH_MODE=https HTTPS_HELPER=gcm GHQ_CHOICE=yes
AZURE_REPO='https://ORG@dev.azure.com/ORG/PROJECT/_git/REPO'
GITHUB_REPO=''
run() { "$@"; }
record_path_before_write() { printf '%s\n' "$1" >> "$TEST_ROOT/recorded"; }

hosting_validate_choices
for invalid in 'https://token:secret@dev.azure.com/ORG/PROJECT/_git/REPO' \
  'https://dev.azure.com.evil.example/ORG/PROJECT/_git/REPO' \
  'https://dev.azure.com/ORG/PROJECT/_git/REPO?token=secret' \
  'file:///tmp/repo' '-option' $'https://dev.azure.com/ORG/PROJECT/_git/REPO\n'; do
  if hosting_repo_valid azure "$invalid" https; then exit 1; fi
done
if hosting_repo_valid github "$AZURE_REPO" https; then exit 1; fi
hosting_repo_valid azure 'git@ssh.dev.azure.com:v3/ORG/PROJECT/REPO' keychain
hosting_repo_valid github 'ssh://git@github.com/OWNER/REPO.git' external

git config --global credential.helper osxkeychain
git config --global credential.https://github.com.helper keep-github
hosting_configure_helper
[[ "$(git config --global credential.helper)" == osxkeychain ]] || fail_test 'global helper changed'
[[ "$(git config --global credential.https://github.com.helper)" == keep-github ]] || fail_test 'unselected GitHub helper changed'
printf -v expected '!%q' "$(hosting_gcm_path)"
[[ "$(git config --global --get-all credential.https://dev.azure.com.helper)" == $'\n'"$expected" ]] || fail_test 'Azure GCM helper chain differs'
printf 'protocol=https\nhost=dev.azure.com\n\n' | git credential fill > "$TEST_ROOT/fake-credential"
grep -Fqx 'username=fixture' "$TEST_ROOT/fake-credential"
hosting_configure_helper
[[ "$(git config --global --get-all credential.https://dev.azure.com.helper | wc -l | tr -d ' ')" == 2 ]] || fail_test 'GCM helper chain duplicated'
[[ -s "$TEST_ROOT/recorded" ]] || fail_test 'Git configuration original not recorded'
before="$(cat "$HOME/.gitconfig")"
HTTPS_HELPER=existing
hosting_configure_helper
[[ "$before" == "$(cat "$HOME/.gitconfig")" ]] || fail_test 'existing route changed helper configuration'
HTTPS_HELPER=gcm
AUTH_MODE=external
if hosting_validate_choices >/dev/null 2>&1; then exit 1; fi
AUTH_MODE=https

HTTPS_HELPER=gcm
PRESET=core
required_application_ids | grep -Fqx git-credential-manager
HTTPS_HELPER=existing
if required_application_ids | grep -Fqx git-credential-manager; then exit 1; fi
HTTPS_HELPER=gcm

# A read-only transport check suppresses prompts, emits no refs and leaves no
# private temporary output. A CLI session is never sufficient for this gate.
hosting_verify_selected_repos > "$TEST_ROOT/output" 2>&1
[[ ! -s "$TEST_ROOT/output" ]] || fail_test 'successful Git probe emitted output'
grep -Fq $'0\tnever' "$GIT_FIXTURE_LOG"
[[ "$(find "$TMPDIR" -type f -name 'day-one-git-access.*' | wc -l | tr -d ' ')" == 0 ]] || fail_test 'successful probe left temporary output'
export GIT_FIXTURE_EXIT=128
result=0
hosting_verify_selected_repos > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_MANUAL" ]] || fail_test 'denied Git access passed'
grep -Fq 'Git repository access failed' "$TEST_ROOT/output"
if grep -Fq 'private fixture' "$TEST_ROOT/output"; then fail_test 'Git diagnostics leaked'; fi
[[ "$(find "$TMPDIR" -type f -name 'day-one-git-access.*' | wc -l | tr -d ' ')" == 0 ]] || fail_test 'failed probe left temporary output'
AZURE_REPO=''
result=0
hosting_verify_selected_repos > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_MANUAL" ]] || fail_test 'missing verification URL passed'
grep -Fq -- '--azure-repo' "$TEST_ROOT/output"
TRACK=4
hosting_verify_selected_repos
export GIT_FIXTURE_EXIT=0
TRACK=3
GITHUB_REPO='https://github.com/OWNER/REPO'
AZURE_REPO='https://dev.azure.com/ORG/PROJECT/_git/REPO'
: > "$GIT_FIXTURE_LOG"
hosting_verify_selected_repos
[[ "$(wc -l < "$GIT_FIXTURE_LOG" | tr -d ' ')" == 2 ]] || fail_test 'Track 3 did not probe both providers'
TRACK=2 AUTH_MODE=keychain HTTPS_HELPER=existing
AZURE_REPO='git@ssh.dev.azure.com:v3/ORG/PROJECT/REPO'
hosting_verify_selected_repos
grep -Fq 'StrictHostKeyChecking=yes' "$GIT_FIXTURE_LOG"

# Successful Azure CLI/extension responses must not let Phase 4 skip Git.
load_brew() { :; }
required_formulae() { :; }
folders_apply() { :; }
folders_check() { :; }
az() { return 0; }
TRACK=2 AUTH_MODE=https HTTPS_HELPER=existing GHQ_CHOICE=no
PRESET=core PRIMARY_IDE=other GIT_NAME=Fixture GIT_EMAIL=fixture@example.invalid
AZURE_REPO='https://dev.azure.com/ORG/PROJECT/_git/REPO'
export GIT_FIXTURE_EXIT=128
result=0
phase_04 > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_MANUAL" ]] || fail_test 'Phase 4 passed with CLI login but denied Git access'
grep -Fq 'Git repository access failed' "$TEST_ROOT/output"
if grep -Fq 'selected hosting gates verified' "$TEST_ROOT/output"; then fail_test 'failed Phase 4 claimed success'; fi
export GIT_FIXTURE_EXIT=0
phase_04 > "$TEST_ROOT/output" 2>&1
grep -Fq 'selected hosting gates verified' "$TEST_ROOT/output"

# Phase 8 must expose the transport failure as its own report gate.
mkdir -p "$STATE_DIR"
VERIFY_FAILURES=0
export GIT_FIXTURE_EXIT=128
report_check 'Azure Git repository access' hosting_verify_repo azure
[[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'Phase 8 did not count failed Git access'
grep -Fqx '| Azure Git repository access | FAIL |' "$STATE_DIR/verification.md"
export GIT_FIXTURE_EXIT=0
report_check 'Azure Git repository access' hosting_verify_repo azure
[[ "$VERIFY_FAILURES" == 1 ]] || fail_test 'successful Git access added a failure'
grep -Fqx '| Azure Git repository access | PASS |' "$STATE_DIR/verification.md"

# A first GitHub CLI login can configure its own HTTPS helper. The selected
# GCM chain must be the final configuration before the repository gate runs.
gh() {
  case "$1:$2" in
    auth:status) return 1 ;;
    auth:login) git config --global --replace-all credential.https://github.com.helper fixture-gh-helper ;;
    auth:setup-git) printf 'unexpected setup-git\n' >> "$TEST_ROOT/gh-helper-calls" ;;
    config:set) return 0 ;;
    *) return 97 ;;
  esac
}
TRACK=1 HTTPS_HELPER=gcm
GITHUB_REPO='https://github.com/OWNER/REPO'
phase_04 > "$TEST_ROOT/output" 2>&1
[[ "$(git config --global --get-all credential.https://github.com.helper)" == $'\n'"$expected" ]] || {
  printf 'FAIL: GitHub CLI login replaced the selected GCM helper\n' >&2; exit 1; }
[[ ! -e "$TEST_ROOT/gh-helper-calls" ]] || fail_test 'GCM route called gh auth setup-git'

# Clone consent is separate from access verification, defaults off, and never
# overwrites existing data. Fixtures use local repositories only.
TRACK=2 HTTPS_HELPER=existing AUTH_MODE=https
GITHUB_CLONE_DIR=none AZURE_CLONE_DIR=none
hosting_clone_selected_repos
[[ ! -e "$GIT_FIXTURE_LOG.clone" ]] || fail_test 'verify-only selection cloned'
AZURE_CLONE_DIR="$HOME/Projects with spaces/scaffold"
hosting_validate_choices
DRY_RUN=1
hosting_clone_selected_repos > "$TEST_ROOT/clone-preview"
[[ ! -e "$HOME/Projects with spaces" && ! -e "$GIT_FIXTURE_LOG.clone" ]] || fail_test 'clone preview wrote files'
DRY_RUN=0
export GIT_FIXTURE_EXIT=128
result=0
phase_04 > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_MANUAL" && ! -e "$GIT_FIXTURE_LOG.clone" ]] || fail_test 'denied access reached cloning'
export GIT_FIXTURE_EXIT=0
phase_04 > "$TEST_ROOT/output" 2>&1
hosting_clone_matches "$AZURE_CLONE_DIR" "$AZURE_REPO" || fail_test 'clone payload was not verified'
grep -Fq $'0\tnever' "$GIT_FIXTURE_LOG.clone" || fail_test 'clone allowed interactive credentials'
printf 'keep my work\n' > "$AZURE_CLONE_DIR/local-file"
hosting_clone_selected_repos > "$TEST_ROOT/output" 2>&1
[[ "$(wc -l < "$GIT_FIXTURE_LOG.clone" | tr -d ' ')" == 1 ]] || fail_test 'resume cloned twice'
[[ "$(cat "$AZURE_CLONE_DIR/local-file")" == 'keep my work' ]] || fail_test 'resume modified work'
AZURE_CLONE_DIR="$HOME/occupied"
mkdir -p "$AZURE_CLONE_DIR"
printf 'keep\n' > "$AZURE_CLONE_DIR/file"
result=0
hosting_clone_selected_repos > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_MANUAL" && "$(cat "$AZURE_CLONE_DIR/file")" == keep ]] || fail_test 'occupied destination overwritten'
ln -s "$HOME/occupied" "$HOME/linked-clone"
if hosting_clone_dir_valid "$HOME/linked-clone"; then fail_test 'clone followed symlink'; fi
if hosting_clone_dir_valid "$HOME/../escape"; then fail_test 'clone allowed parent traversal'; fi
AZURE_CLONE_DIR="$HOME/failure"
export GIT_FIXTURE_EXIT=128 GIT_FIXTURE_PARTIAL=1
result=0
hosting_clone_selected_repos > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_MANUAL" ]] || fail_test 'failed clone passed'
[[ "$(cat "$HOME/failure/partial")" == 'partial clone' ]] || fail_test 'failed clone discarded partial data'
unset GIT_FIXTURE_PARTIAL
AZURE_CLONE_DIR="$HOME/missing-payload"
export GIT_FIXTURE_EXIT=0 GIT_FIXTURE_NO_CLONE=1
result=0
hosting_clone_selected_repos > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_GATE" ]] || fail_test 'missing clone payload passed'
unset GIT_FIXTURE_NO_CLONE
AUTH_MODE=keychain AZURE_REPO='git@ssh.dev.azure.com:v3/ORG/PROJECT/REPO'
hosting_clone_selected_repos > "$TEST_ROOT/output" 2>&1
grep -Fq 'BatchMode=yes' "$GIT_FIXTURE_LOG.clone" || fail_test 'SSH clone allowed interactive authentication'
AZURE_CLONE_DIR=none
hosting_clone_selected_repos
[[ -d "$HOME/missing-payload/.git" ]] || fail_test 'disabling clone removed repository'
TRACK=3 AUTH_MODE=https
GITHUB_CLONE_DIR="$HOME/github-clone" AZURE_CLONE_DIR="$HOME/azure-clone"
AZURE_REPO='https://dev.azure.com/ORG/PROJECT/_git/REPO'
hosting_validate_choices
hosting_clone_selected_repos > "$TEST_ROOT/output" 2>&1
hosting_clone_matches "$GITHUB_CLONE_DIR" "$GITHUB_REPO" || fail_test 'Track 3 GitHub clone missing'
hosting_clone_matches "$AZURE_CLONE_DIR" "$AZURE_REPO" || fail_test 'Track 3 Azure clone missing'
AZURE_CLONE_DIR="$GITHUB_CLONE_DIR"
if hosting_validate_choices >/dev/null 2>&1; then fail_test 'duplicate destinations accepted'; fi
save_state_value github-clone-dir "$HOME/github-clone"
save_state_value azure-clone-dir none
GITHUB_CLONE_DIR='' AZURE_CLONE_DIR=''
hosting_load_choices
[[ "$GITHUB_CLONE_DIR" == "$HOME/github-clone" && "$AZURE_CLONE_DIR" == none ]] || fail_test 'clone choices did not resume'
printf 'PASS: optional clones, consent, preview, verification, preservation and resume\n'

# Exercise the actual wizard functions with person-input on stdin. Provider
# enumeration must not steal menu choices or URL/destination responses.
sed -n '/^prompt_value()/,/^}/p' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" > "$TEST_ROOT/wizard-functions.sh"
sed -n '/^choose_verification_repos()/,/^}/p' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" >> "$TEST_ROOT/wizard-functions.sh"
# The extracted functions are linted in bootstrap-day-one-mac.sh itself.
# shellcheck source=/dev/null
source "$TEST_ROOT/wizard-functions.sh"
select_one() {
  printf 'QUESTION: %s\n' "$1"
  IFS= read -r SINGLE_RESULT || fail_test 'wizard read provider stream instead of person-input'
  case "$SINGLE_RESULT" in none|clone) ;; *) fail_test 'wizard consumed responses out of order' ;; esac
}
TRACK=2 AUTH_MODE=https GITHUB_REPO='' AZURE_REPO='' AZURE_CLONE_DIR=none
choose_verification_repos > "$TEST_ROOT/wizard" <<EOF
clone
https://dev.azure.com/ORG/PROJECT/_git/REPO
$HOME/wizard clone
EOF
[[ "$AZURE_REPO" == 'https://dev.azure.com/ORG/PROJECT/_git/REPO' && "$AZURE_CLONE_DIR" == "$HOME/wizard clone" ]] || fail_test 'wizard clone responses lost'
grep -Fq 'Would you like to clone a repository from Azure DevOps to verify access?' "$TEST_ROOT/wizard" || fail_test 'clone question missing'
[[ ! -e "$HOME/wizard clone" ]] || fail_test 'wizard cloned before review'
TRACK=3 GITHUB_REPO='' AZURE_REPO=''
choose_verification_repos > "$TEST_ROOT/wizard" <<EOF
none
https://github.com/OWNER/REPO
none
https://dev.azure.com/ORG/PROJECT/_git/REPO
EOF
[[ "$GITHUB_REPO" == 'https://github.com/OWNER/REPO' && "$AZURE_REPO" == 'https://dev.azure.com/ORG/PROJECT/_git/REPO' ]] || fail_test 'wizard lost a provider response'
[[ "$GITHUB_CLONE_DIR" == none && "$AZURE_CLONE_DIR" == none ]] || fail_test 'verify-only wizard selected cloning'
printf 'PASS: wizard clone question precedes URL entry and provider enumeration preserves stdin\n'

printf 'PASS: GCM selection, scoped helpers, URL validation and real Git access gates\n'
