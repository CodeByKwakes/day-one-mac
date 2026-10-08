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
export PATH="$TEST_ROOT/command bin:/usr/bin:/bin:/usr/sbin:/sbin"
export GIT_FIXTURE_LOG="$TEST_ROOT/transport" GIT_FIXTURE_EXIT=0
cat > "$TEST_ROOT/command bin/git" <<'EOF'
#!/bin/bash
case "$*" in
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
[[ "$(git config --global credential.helper)" == osxkeychain ]]
[[ "$(git config --global credential.https://github.com.helper)" == keep-github ]]
printf -v expected '!%q' "$(hosting_gcm_path)"
[[ "$(git config --global --get-all credential.https://dev.azure.com.helper)" == $'\n'"$expected" ]]
printf 'protocol=https\nhost=dev.azure.com\n\n' | git credential fill > "$TEST_ROOT/fake-credential"
grep -Fqx 'username=fixture' "$TEST_ROOT/fake-credential"
hosting_configure_helper
[[ "$(git config --global --get-all credential.https://dev.azure.com.helper | wc -l | tr -d ' ')" == 2 ]]
[[ -s "$TEST_ROOT/recorded" ]]
before="$(cat "$HOME/.gitconfig")"
HTTPS_HELPER=existing
hosting_configure_helper
[[ "$before" == "$(cat "$HOME/.gitconfig")" ]]
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
[[ ! -s "$TEST_ROOT/output" ]]
grep -Fq $'0\tnever' "$GIT_FIXTURE_LOG"
[[ "$(find "$TMPDIR" -type f | wc -l | tr -d ' ')" == 0 ]]
export GIT_FIXTURE_EXIT=128
result=0
hosting_verify_selected_repos > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_MANUAL" ]]
grep -Fq 'Git repository access failed' "$TEST_ROOT/output"
! grep -Fq 'private fixture' "$TEST_ROOT/output"
[[ "$(find "$TMPDIR" -type f | wc -l | tr -d ' ')" == 0 ]]
AZURE_REPO=''
result=0
hosting_verify_selected_repos > "$TEST_ROOT/output" 2>&1 || result=$?
[[ "$result" == "$EX_MANUAL" ]]
grep -Fq -- '--azure-repo' "$TEST_ROOT/output"
TRACK=4
hosting_verify_selected_repos
export GIT_FIXTURE_EXIT=0
TRACK=3
GITHUB_REPO='https://github.com/OWNER/REPO'
AZURE_REPO='https://dev.azure.com/ORG/PROJECT/_git/REPO'
: > "$GIT_FIXTURE_LOG"
hosting_verify_selected_repos
[[ "$(wc -l < "$GIT_FIXTURE_LOG" | tr -d ' ')" == 2 ]]
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
[[ "$result" == "$EX_MANUAL" ]]
grep -Fq 'Git repository access failed' "$TEST_ROOT/output"
! grep -Fq 'selected hosting gates verified' "$TEST_ROOT/output"
export GIT_FIXTURE_EXIT=0
phase_04 > "$TEST_ROOT/output" 2>&1
grep -Fq 'selected hosting gates verified' "$TEST_ROOT/output"

# Phase 8 must expose the transport failure as its own report gate.
mkdir -p "$STATE_DIR"
VERIFY_FAILURES=0
export GIT_FIXTURE_EXIT=128
report_check 'Azure Git repository access' hosting_verify_repo azure
[[ "$VERIFY_FAILURES" == 1 ]]
grep -Fqx '| Azure Git repository access | FAIL |' "$STATE_DIR/verification.md"
export GIT_FIXTURE_EXIT=0
report_check 'Azure Git repository access' hosting_verify_repo azure
[[ "$VERIFY_FAILURES" == 1 ]]
grep -Fqx '| Azure Git repository access | PASS |' "$STATE_DIR/verification.md"

printf 'PASS: GCM selection, scoped helpers, URL validation and real Git access gates\n'
