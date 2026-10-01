#!/usr/bin/env bash
# Selection/ownership fixtures. No real account, package or provider changes.
set -euo pipefail
exec </dev/null
TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-choices.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
trap 'printf "Configuration-choice test failed at line %s\n" "$LINENO" >&2' ERR
export HOME="$TEST_ROOT/home"
export DAY_ONE_MAC_STATE_ROOT="$HOME/state"
mkdir -p "$HOME"
source "$TEST_SCRIPT_DIR/setup.sh"

# New callers must choose; --yes is not consent. Old saved setups retain their
# contract without rewriting any recorded markers or state during inspection.
configuration_load_choices
[[ -z "$DOTFILES_VERSIONING$SHELL_CHOICE$PROMPT_CHOICE" ]]
if configuration_validate_choices; then exit 1; else [[ "$?" == 2 ]]; fi
mkdir -p "$STATE_DIR"
printf 'local\n' > "$STATE_DIR/dotfiles-versioning"
configuration_load_choices
[[ "$DOTFILES_VERSIONING:$SHELL_CHOICE:$PROMPT_CHOICE" == local:homebrew:starship ]]
DOTFILES_VERSIONING=none SHELL_CHOICE=keep PROMPT_CHOICE=none
configuration_load_choices
[[ "$DOTFILES_VERSIONING:$SHELL_CHOICE:$PROMPT_CHOICE" == none:keep:none ]]
configuration_validate_choices

TRACK=1 STACK=node GHQ_CHOICE=no PRESET=core PRIMARY_IDE=other AUTH_MODE=https
GIT_NAME=Fixture GIT_EMAIL=fixture@example.invalid
formulae="$(required_formulae)"
! grep -Eq '^(chezmoi|starship|zsh|ghq)$' <<<"$formulae"
grep -qx fnm <<<"$formulae"
baseline="$(phase_fingerprint 05)"
PROMPT_CHOICE=starship
[[ "$(phase_fingerprint 05)" != "$baseline" ]]
grep -qx starship <<<"$(required_formulae)"
DOTFILES_VERSIONING=local SHELL_CHOICE=homebrew
grep -qx chezmoi <<<"$(required_formulae)"
grep -qx zsh <<<"$(required_formulae)"

# Exercise the real Phase 5 writer. External integrations are doubles; shell
# startup itself is separately tested by test-shell-environment.sh.
env() { printf '%s\n' "$*" >> "$HOME/shell-checks"; return 0; }
switch_login_shell_to_homebrew_zsh() { printf '%s\n' "$SHELL_CHOICE" >> "$HOME/switch-request"; }
configuration_login_shell() { printf '/bin/zsh\n'; }
starship() { printf '%s\n' "$*" >> "$HOME/starship-calls"; }
chezmoi() {
  [[ "$DOTFILES_VERSIONING" != none ]] || { printf 'Unexpected chezmoi call\n' >&2; return 98; }
  printf '%s\n' "$*" >> "$HOME/chezmoi-calls"
  case "$1" in
    source-path)
      if [[ $# == 1 ]]; then printf '%s\n' "$HOME/.local/share/chezmoi"
      elif [[ -f "$HOME/managed" ]] && grep -Fxq "$2" "$HOME/managed"; then printf '%s\n' "$HOME/.local/share/chezmoi/fixture"
      else return 1; fi ;;
    managed) [[ ! -f "$HOME/managed" ]] || cat "$HOME/managed" ;;
    init) mkdir -p "$HOME/.local/share/chezmoi" ;;
    add) shift; printf '%s\n' "$@" >> "$HOME/managed" ;;
    doctor|--use-builtin-diff|apply) return 0 ;;
    *) printf 'Unexpected fixture command: %s\n' "$*" >&2; return 97 ;;
  esac
}
mkdir -p "$TEST_ROOT/runtime"
printf '#!/bin/sh\nexit 0\n' > "$TEST_ROOT/runtime/verify.sh"
chmod +x "$TEST_ROOT/runtime/verify.sh"
# Unrelated machine/provider checks are doubles. Exercise the real Phase 8
# selection, Brewfile ownership, and report paths without contacting accounts.
report_check() {
  local label="$1"; shift
  case "$label" in chezmoi|Starship|'Selected login shell') "$@" ;; esac
  printf '| %s | PASS |\n' "$label" >> "$STATE_DIR/verification.md"
}
report_ssh_key_storage() { :; }
verify_dotfiles_remote() { printf 'private\n' >> "$HOME/protection-checks"; }
verify_local_dotfiles_source() { printf 'local\n' >> "$HOME/protection-checks"; }
brew() {
  [[ "$1:$2:$3" == bundle:dump:--file=* ]] || return 97
  printf 'brew "git"\n' > "${3#--file=}"
}
for ownership in none local git; do
  for prompt in none starship; do
    export HOME="$TEST_ROOT/$ownership-$prompt"
    STATE_DIR="$HOME/state" COMPLETED_DIR="$HOME/state/completed"
    INSTALL_MANIFEST="$STATE_DIR/install-manifest.tsv" PATH_MANIFEST="$STATE_DIR/path-manifest.tsv"
    ORIGINALS_DIR="$STATE_DIR/originals" LOG_FILE="$STATE_DIR/setup.log"
    mkdir -p "$HOME/.local/bin"
    printf '#!/bin/sh\nprintf "%%s\\n" "%s"\n' "$PROJECT_DIR" > "$HOME/.local/bin/day-one-mac"
    chmod +x "$HOME/.local/bin/day-one-mac"
    printf '[user]\nname = Fixture\n' > "$HOME/.gitconfig"
    printf '.DS_Store\n' > "$HOME/.gitignore_global"
    DOTFILES_VERSIONING="$ownership" SHELL_CHOICE=apple PROMPT_CHOICE="$prompt"
    DRY_RUN=0 ASSUME_YES=1 DOTFILES_EXPLICIT=1 DOTFILES_REPO=''
    phase_05 > "$HOME/result"
    before="$(shasum -a 256 "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.config/zsh/path.zsh" "$HOME/.config/zsh/aliases.zsh")"
    phase_05 >> "$HOME/result"
    [[ "$before" == "$(shasum -a 256 "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.config/zsh/path.zsh" "$HOME/.config/zsh/aliases.zsh")" ]]
    if [[ "$ownership" == none ]]; then
      [[ ! -e "$HOME/chezmoi-calls" && ! -e "$HOME/.config/chezmoi" && ! -e "$HOME/.local/share/chezmoi" ]]
      resync_managed_ssh_config "$HOME/.ssh/config"
      [[ ! -e "$HOME/chezmoi-calls" ]]
    else
      grep -qx doctor "$HOME/chezmoi-calls"
      grep -Fxq "$HOME/.zshrc" "$HOME/managed"
    fi
    if [[ "$prompt" == none ]]; then
      [[ ! -e "$HOME/.config/starship.toml" && ! -e "$HOME/starship-calls" ]]
      ! grep -q 'starship init' "$HOME/.zshrc"
    else
      [[ -f "$HOME/.config/starship.toml" ]]
      grep -q 'starship init' "$HOME/.zshrc"
    fi
    grep -q '/bin/zsh -lic' "$HOME/shell-checks"
    grep -q '/bin/zsh -ic' "$HOME/shell-checks"
    SCRIPT_DIR="$TEST_ROOT/runtime"
    phase_08 >> "$HOME/result"
    printf '# user choice\n' >> "$HOME/Brewfile"
    before="$(shasum -a 256 "$HOME/Brewfile")"
    phase_08 >> "$HOME/result"
    [[ "$before" == "$(shasum -a 256 "$HOME/Brewfile")" ]]
    if [[ "$ownership" == none ]]; then
      [[ ! -e "$HOME/chezmoi-calls" && ! -e "$HOME/protection-checks" ]]
      grep -q 'NOT SELECTED — user-owned files' "$STATE_DIR/verification.md"
    else
      [[ -s "$HOME/protection-checks" ]]
      grep -Fxq "$HOME/Brewfile" "$HOME/managed"
    fi
    SCRIPT_DIR="$TEST_SCRIPT_DIR"
  done
done

# Existing customization survives byte-for-byte. An incomplete integration
# returns manual, rather than overwriting it or marking the phase complete.
export HOME="$TEST_ROOT/none-none"
STATE_DIR="$HOME/state" LOG_FILE="$STATE_DIR/setup.log"
DOTFILES_VERSIONING=none SHELL_CHOICE=keep PROMPT_CHOICE=none
printf 'PROMPT="mine> "\n' > "$HOME/.zshrc"
before="$(shasum -a 256 "$HOME/.zshrc")"
if phase_05 > "$HOME/conflict"; then exit 1; else [[ "$?" == "$EX_MANUAL" ]]; fi
[[ "$before" == "$(shasum -a 256 "$HOME/.zshrc")" ]]
mkdir -p "$HOME/.config/chezmoi"
if configuration_unmanaged_preflight; then exit 1; else [[ "$?" == 10 ]]; fi

export HOME="$TEST_ROOT/unsupported"
mkdir -p "$HOME"
configuration_login_shell() { printf '/bin/bash\n'; }
if phase_05 > "$HOME/result"; then exit 1; else [[ "$?" == "$EX_MANUAL" ]]; fi
[[ ! -e "$HOME/.config" && ! -e "$HOME/.zshrc" ]]
configuration_login_shell() { printf '/bin/zsh\n'; }
ln -s "$TEST_ROOT/none-none/.zshrc" "$HOME/.zshrc"
if phase_05 > "$HOME/result"; then exit 1; else [[ "$?" == "$EX_MANUAL" ]]; fi
[[ -L "$HOME/.zshrc" && ! -e "$HOME/.config" ]]

# Read-only plan exposes selected ownership; it never initializes a source.
HOME="$TEST_ROOT/plan" DAY_ONE_MAC_STATE_ROOT="$TEST_ROOT/plan/state" /bin/bash "$TEST_SCRIPT_DIR/setup.sh" \
  --plan --track 1 --stack python --dotfiles-versioning none --shell apple --prompt none --json > "$TEST_ROOT/plan.json"
node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1])); if(r.selection.dotfiles_versioning!=="none" || r.selection.shell!=="apple" || r.selection.prompt!=="none") process.exit(1)' "$TEST_ROOT/plan.json"
[[ ! -e "$TEST_ROOT/plan" ]]
printf 'Configuration ownership, selection, preservation and rerun fixtures passed.\n'
