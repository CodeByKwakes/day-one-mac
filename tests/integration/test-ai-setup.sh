#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_TMP="$(mktemp -d /tmp/day-one-ai-setup.XXXXXX)"
trap 'rm -rf "$TASK_TMP"' EXIT
trap 'printf "AI checkpoint test failed at line %s\n" "$LINENO" >&2' ERR
export HOME="$TASK_TMP/home with spaces é"
export DAY_ONE_MAC_STATE_ROOT="$HOME/state"
export DAY_ONE_MAC_STATE_DIR="$DAY_ONE_MAC_STATE_ROOT"
export DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled
mkdir -p "$HOME" "$TASK_TMP/bin"
export PATH="$TASK_TMP/bin:/usr/bin:/bin:/usr/sbin:/sbin"
cat > "$TASK_TMP/bin/uname" <<'SH'
#!/bin/sh
case "$1" in -s) echo Darwin ;; -m) echo arm64 ;; *) /usr/bin/uname "$@" ;; esac
SH
printf '#!/bin/sh\necho 26.0\n' > "$TASK_TMP/bin/sw_vers"
chmod +x "$TASK_TMP/bin/"*
run() {
  local wanted="$1" actual=0; shift
  "$ROOT/scripts/day-one-mac" ai-setup "$@" > "$TASK_TMP/output" 2>&1 || actual=$?
  [[ "$actual" == "$wanted" ]] || { cat "$TASK_TMP/output"; printf 'Expected %s, got %s\n' "$wanted" "$actual"; exit 1; }
}
run 0 --plan --mode execute --client codex
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT" ]]
run 10 --check
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT" ]]
run 2 --plan --apply
run 2 --apply --mode execute --client existing
run 2 --plan --install --mode execute --client codex
run 10 --apply --mode execute --client codex
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT/ai-setup/selection.tsv" ]]
run 10 --apply --mode execute --client codex --install
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT/ai-setup/selection.tsv" ]]
run 0 --apply --mode none
grep -Fq $'mode\tnone' "$DAY_ONE_MAC_STATE_ROOT/ai-setup/selection.tsv"
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT/completed" ]]
run 0 --check
run 0 --apply --mode guide --client existing
grep -Fq 'Account and permissions: manual verification required' "$TASK_TMP/output"
run 10 --check
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/codex" <<'SH'
#!/bin/sh
[ "$1" = --version ] || exit 99
echo codex-fixture
SH
chmod +x "$HOME/.local/bin/codex"
run 0 --apply --mode execute --client codex
first="$(cat "$DAY_ONE_MAC_STATE_ROOT/ai-setup/current")"
handoff="$DAY_ONE_MAC_STATE_ROOT/ai-setup/$first"
[[ -f "$handoff/AGENTS.md" && -f "$handoff/CLAUDE.md" && -f "$handoff/.agents/skills/day-one-mac-assistant/SKILL.md" ]]
printf 'keep personal note\n' > "$handoff/personal-note.txt"
before="$(find "$DAY_ONE_MAC_STATE_ROOT" -type f -exec shasum -a 256 {} \; | sort)"
run 0 --check
run 0 --plan --mode none
[[ "$before" == "$(find "$DAY_ONE_MAC_STATE_ROOT" -type f -exec shasum -a 256 {} \; | sort)" ]]
run 0 --apply --mode execute --client codex
grep -Fqx 'keep personal note' "$handoff/personal-note.txt"
[[ ! -e "$DAY_ONE_MAC_STATE_ROOT/completed" ]]
# No overwriting an existing client configuration, nor borrowing a phase marker.
mkdir -p "$HOME/.codex"
printf 'keep config\n' > "$HOME/.codex/config.toml"
run 0 --apply --mode execute --client codex
grep -Fqx 'keep config' "$HOME/.codex/config.toml"
rm "$HOME/.local/bin/codex"
run 10 --check
# Damaged native targets must be preserved before any installer is offered.
for conflict in dangling non-executable directory; do
  case "$conflict" in
    dangling) ln -s "$HOME/missing-codex" "$HOME/.local/bin/codex" ;;
    non-executable) printf 'keep damaged file\n' > "$HOME/.local/bin/codex" ;;
    directory) mkdir "$HOME/.local/bin/codex" ;;
  esac
  run 1 --apply --mode execute --client codex --install
  grep -Fq 'Existing client path needs review' "$TASK_TMP/output"
  [[ -z "$(find "$DAY_ONE_MAC_STATE_ROOT/ai-setup" -maxdepth 1 -name 'installer.*' -print)" ]]
  case "$conflict" in
    dangling) [[ "$(readlink "$HOME/.local/bin/codex")" == "$HOME/missing-codex" ]] ;;
    non-executable) grep -Fqx 'keep damaged file' "$HOME/.local/bin/codex" ;;
    directory) [[ -d "$HOME/.local/bin/codex" ]] ;;
  esac
  if [[ -d "$HOME/.local/bin/codex" ]]; then rmdir "$HOME/.local/bin/codex"
  else rm "$HOME/.local/bin/codex"; fi
 done
# A failed handoff copy cannot create a saved successful selection.
(
  source "$ROOT/src/setup/ai-setup.sh"
  AI_STATE="$HOME/failed-handoff" AI_MODE=guide AI_CLIENT=existing
  cp() { return 1; }
  ai_prepare_handoff
) > "$TASK_TMP/handoff-output" 2>&1 && exit 1
[[ ! -e "$HOME/failed-handoff/selection.tsv" && ! -e "$HOME/failed-handoff/current" ]]
# Reject redirected state before writing anything into its target.
mkdir -p "$TASK_TMP/elsewhere" "$HOME/redirected"
ln -s "$TASK_TMP/elsewhere" "$HOME/redirected/ai-setup"
export DAY_ONE_MAC_STATE_ROOT="$HOME/redirected"
run 1 --apply --mode none
[[ -z "$(ls -A "$TASK_TMP/elsewhere")" ]]
# Exercise installer refusal paths with a local transport fixture. Only the
# terminal/viewer functions are replaced; production requires a real terminal.
(
  source "$ROOT/src/setup/ai-setup.sh"
  AI_STATE="$HOME/installer-tests" AI_CLIENT=codex AI_COMMAND=codex AI_APP=codex
  AI_URL=https://chatgpt.com/codex/install.sh AI_SHELL=/bin/sh
  ai_require_terminal() { :; }
  ai_review_installer() { [[ "$scenario" != changed ]] || printf '\n# changed\n' >> "$1"; return 0; }
  ai_confirm() { [[ "$scenario:$1" != 'cancel:install codex' ]]; }
  curl() {
    local destination=''
    while (( $# )); do
      if [[ "$1" == -o ]]; then destination="$2"; shift; fi
      shift
    done
    [[ "$scenario" != download-failure ]] || return 22
    if [[ "$scenario" == invalid ]]; then printf 'if then\n' > "$destination"
    elif [[ "$scenario" == installer-failure ]]; then printf 'exit 7\n' > "$destination"
    else printf 'touch "$HOME/installer-ran"\n' > "$destination"; fi
  }
  for scenario in download-failure invalid cancel changed installer-failure; do
    result=0
    ai_install_client > "$TASK_TMP/install-output" 2>&1 || result=$?
    [[ "$result" != 0 && ! -e "$HOME/installer-ran" && ! -e "$AI_STATE/selection.tsv" ]] || exit 1
  done
)
printf 'AI checkpoint preview, skip, missing-client, reuse, handoff and state boundaries passed.\n'
