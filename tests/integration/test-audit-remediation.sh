#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fixture="$(mktemp -d /private/tmp/day-one-remediation.XXXXXX)"
trap 'rm -rf "$fixture"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }
pass() { :; }
# Exercise the actual fixture runner, including interpreter arguments.
eval "$(sed -n '/^run_fixture() {/,/^}/p' "$SCRIPT_DIR/../tools/validate.sh")"
printf '#!/bin/bash\nprintf executed > "%s/ran"\nexit 1\n' "$fixture" > "$fixture/sentinel.sh"
if run_fixture sentinel expected-failure /bin/bash "$fixture/sentinel.sh" > "$fixture/runner-output" 2>&1; then
  fail 'failing sentinel accepted'; exit 1
fi
[[ -s "$fixture/ran" ]]

source "$SCRIPT_DIR/../src/core/report-safety.sh"
for remote in 'https://user:SENTINEL@example.test/repo?token=SENTINEL#SENTINEL' \
  'ssh://user:SENTINEL@example.test/repo' 'https://user%3ASENTINEL%40example.test/repo' \
  $'https://example.test/repo\nSENTINEL'; do
  result="$(day_one_remote_display "$remote")"
  [[ "$result" != *SENTINEL* ]] || { fail 'credential copied into report'; exit 1; }
done
[[ "$(day_one_remote_display 'git@example.test:owner/repo.git')" == ssh://example.test/owner/repo.git ]]

cat > "$fixture/settings.json" <<'JSON'
{
 // "chat.tools.global.autoApprove": false
 // "chat.tools.terminal.enableAutoApprove": false
 "chat.tools.global.autoApprove": true,
 "chat.tools.terminal.enableAutoApprove": true
}
JSON
if python3 -I -B "$SCRIPT_DIR/../src/core/editor-settings.py" "$fixture/settings.json" >/dev/null 2>&1; then fail 'comments fooled editor check'; exit 1; fi
printf '{"chat.tools.global.autoApprove" : false, "chat.tools.terminal.enableAutoApprove": false,}\n' > "$fixture/settings.json"
python3 -I -B "$SCRIPT_DIR/../src/core/editor-settings.py" "$fixture/settings.json" >/dev/null

# Real Git transport, private provider response mocked. No network access.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null GIT_CONFIG_NOSYSTEM=1
git init -q --bare "$fixture/remote.git"
git -c init.templateDir= init -q "$fixture/working"
git -C "$fixture/working" config user.name 'Fixture'
git -C "$fixture/working" config user.email 'fixture@example.test'
git -C "$fixture/working" config commit.gpgsign false
git -C "$fixture/working" config core.hooksPath /dev/null
git -C "$fixture/working" config "url.$fixture/remote.git.insteadOf" 'https://github.com/example/fixture.git'
git -C "$fixture/working" commit -q --allow-empty -m fixture
git -C "$fixture/working" remote add origin https://github.com/example/fixture.git
git -C "$fixture/working" push -q -u origin HEAD
source "$SCRIPT_DIR/../src/core/deadline.sh"
source "$SCRIPT_DIR/../src/setup/phases/08-verification.sh"
git() {
  if [[ "${1:-}" == -C && "${3:-}" == remote && "${4:-}" == get-url ]]; then
    command git -C "$2" config --get remote.origin.url
  else command git "$@"; fi
}
chezmoi() { printf '%s\n' "$fixture/working"; }
gh() { printf 'PRIVATE\n'; }
phase_next() { :; }
phase_step_done() { :; }
warn() { :; }
err() { :; }
STATE_DIR="$fixture" TRACK=1 EX_GATE=11 EX_MANUAL=10
verify_dotfiles_remote
branch="$(git -C "$fixture/working" symbolic-ref --short HEAD)"
git --git-dir="$fixture/remote.git" update-ref -d "refs/heads/$branch"
if verify_dotfiles_remote; then fail 'deleted upstream passed'; exit 1; fi
git -C "$fixture/working" push -q origin HEAD
verify_dotfiles_remote
git -C "$fixture/working" commit -q --allow-empty -m newer
if verify_dotfiles_remote; then fail 'different remote commit passed'; exit 1; fi
unset -f git

# Current fingerprints work; stale/malformed ones do not.
"$SCRIPT_DIR/../tests/integration/seed-required-state.sh" "$fixture/state"
export DAY_ONE_MAC_STATE_ROOT="$fixture/state" DAY_ONE_MAC_STATE_DIR="$fixture/state"
source "$SCRIPT_DIR/../src/core/module-execution.sh"
day_one_phase_current 08
printf 'starship\n' > "$fixture/state/prompt-choice"
if day_one_phase_current 08; then fail 'changed selection accepted'; exit 1; fi
printf 'fixture\n' > "$fixture/state/completed/08"
if day_one_phase_current 08; then fail 'arbitrary marker accepted'; exit 1; fi
# Run actual audit helper bodies with failing probes and declined tools.
source "$SCRIPT_DIR/../src/core/configuration-choices.sh"
for helper in audit_selected_commands audit_brew_updates audit_chezmoi_status; do
  fixture_body="$(awk -v name="$helper" '$0 == name"() {" {capture=1} capture {print} capture && $0 == "}" {exit}' "$SCRIPT_DIR/../src/modules/advanced-audit.sh")"
  eval "$fixture_body"
done
pass_gate() { printf 'PASS:%s\n' "$1" >> "$fixture/audit-rows"; }
fail_gate() { printf 'FAIL:%s\n' "$1" >> "$fixture/audit-rows"; }
review_gate() { printf 'REVIEW:%s\n' "$1" >> "$fixture/audit-rows"; }
state_value() {
  case "$1" in
    configuration-schema) printf 1 ;; dotfiles-versioning) printf none ;;
    shell-choice) printf apple ;; prompt-choice) printf none ;; preset) printf core ;;
  esac
}
DOTFILES_VERSIONING='' SHELL_CHOICE='' PROMPT_CHOICE=''
audit_selected_commands
if grep -Eq '(chezmoi|starship|code) command' "$fixture/audit-rows"; then fail 'declined tool required by audit'; exit 1; fi
brew() { return 7; }
chezmoi() { return 8; }
TMP_ROOT="$fixture"
audit_brew_updates
audit_chezmoi_status
grep -Fxq 'FAIL:Homebrew updates' "$fixture/audit-rows"
grep -Fxq 'FAIL:chezmoi target drift' "$fixture/audit-rows"
# Personal setup must recognize an explicit unenrolled result, not just absence
# of a positive enrollment message. No real profiles or policies are changed.
fixture_body="$(awk '$0 == "deployment_preflight() {" {capture=1} capture {print} capture && $0 == "}" {exit}' "$SCRIPT_DIR/../src/setup/choices.sh")"
eval "$fixture_body"
DRY_RUN=0 DEPLOYMENT_MODE=personal WORKSTATION_POLICY=''
profiles() { printf '%s\n' "$enrollment_fixture"; return "$enrollment_status"; }
enrollment_fixture='MDM enrollment: No' enrollment_status=0
deployment_preflight
for enrollment_fixture in 'MDM enrollment: Yes' 'unexpected response'; do
  if deployment_preflight; then fail 'unsafe or unknown management status accepted'; exit 1; fi
done
enrollment_fixture='MDM enrollment: No' enrollment_status=1
if deployment_preflight; then fail 'failed enrollment probe accepted'; exit 1; fi
python3 -I -B "$SCRIPT_DIR/../tests/integration/test-workstation-readiness.py"
printf 'PASS: release candidate, fixture execution, URL redaction, JSONC, live remote, current prerequisites and policy evidence\n'
