#!/usr/bin/env bash
set -uo pipefail

# Read-only shell health report. This script never changes startup files,
# permissions, the login shell, or Homebrew packages.
DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
source "$SCRIPT_DIR/../src/core/project-paths.sh"
source "$SCRIPT_DIR/../src/core/terminal-ui.sh"
source "$SCRIPT_DIR/../src/core/configuration-choices.sh"
STATE_DIR="$(day_one_state_dir "$(day_one_state_root)")"
COMPLETED_DIR="$STATE_DIR/completed"
DOTFILES_VERSIONING='' SHELL_CHOICE='' PROMPT_CHOICE=''
configuration_load_choices
configuration_validate_choices || exit 10

ok() { ui_success "$@"; }
fail() { ui_status error "$DAY_ONE_UI_ERROR $*"; failures=$((failures + 1)); }
info() { ui_info "$@"; }

failures=0
expected="$(configuration_shell_target 2>/dev/null || true)"
configured="$(configuration_login_shell 2>/dev/null || true)"

ui_title '🐚' 'Day One Mac shell status'

[[ -x "$expected" && "${expected##*/}" == zsh ]] || {
  fail "Selected zsh is missing or unsupported: ${expected:-unknown}"; exit 1; }
ok "Selected zsh: $expected ($("$expected" --version 2>/dev/null))"
[[ "$configured" == "$expected" ]] \
  && ok "configured login shell: $configured" \
  || fail "configured login shell is ${configured:-unknown}; expected $expected"
info "current process SHELL: ${SHELL:-not set}"
if [[ -n "${ZSH_VERSION:-}" ]]; then
  info "running interactive shell: zsh $ZSH_VERSION"
elif [[ -n "${BASH_VERSION:-}" ]]; then
  info "this read-only report runs under bash $BASH_VERSION"
else
  info "this read-only report runs under a non-zsh shell"
fi

for startup in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.config/zsh/path.zsh" "$HOME/.config/zsh/aliases.zsh"; do
  [[ -r "$startup" ]] && ok "readable: $startup" || fail "missing or unreadable: $startup"
done
for optional_startup in "$HOME/.zlogin" "$HOME/.zlogout"; do
  [[ -e "$optional_startup" ]] && info "optional startup file exists; review if unexpected: $optional_startup"
done

if [[ -e "$HOME/.zshenv" ]]; then
  if grep -Eq '(^|[[:space:]])(export[[:space:]]+)?ZDOTDIR=|(^|[[:space:]])unsetopt[[:space:]]+.*RCS' "$HOME/.zshenv"; then
    fail "~/.zshenv changes ZDOTDIR or disables Zsh startup files"
  else
    info "~/.zshenv exists and no known startup-file redirect was detected"
  fi
else
  ok "no ~/.zshenv override"
fi

if [[ -x "$expected" ]]; then
  clean_output="$(env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" TERM="${TERM:-xterm-256color}" PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL="$expected" \
    "$expected" -lic 'printf "zsh=%s\n" "$(command -v zsh 2>/dev/null)"; printf "brew=%s\n" "$(command -v brew 2>/dev/null)"; printf "day-one-mac=%s\n" "$(command -v day-one-mac 2>/dev/null)"; printf "starship=%s\n" "$(command -v starship 2>/dev/null)"; printf "fnm=%s\n" "$(command -v fnm 2>/dev/null)"; printf "node=%s\n" "$(command -v node 2>/dev/null)"; printf "pnpm=%s\n" "$(command -v pnpm 2>/dev/null)"; printf "pnpm_home=%s\n" "${PNPM_HOME:-}"' 2>/dev/null || true)"
  required_commands='brew day-one-mac'
  if uses_starship; then required_commands+=' starship'; else info 'Starship: not selected'; fi
  for command_name in $required_commands; do
    path="$(awk -F= -v key="$command_name" '$1 == key { print substr($0, index($0, "=") + 1); exit }' <<<"$clean_output")"
    [[ -n "$path" ]] && ok "clean login shell finds $command_name: $path" || fail "clean login shell cannot find $command_name"
  done
  resolved_zsh="$(awk -F= '$1 == "zsh" { print substr($0, index($0, "=") + 1); exit }' <<<"$clean_output")"
  info "Typing zsh resolves to ${resolved_zsh:-missing}; account shell is checked separately against $expected"
  while IFS= read -r optional; do
    path="$(awk -F= -v key="$optional" '$1 == key { print substr($0, index($0, "=") + 1); exit }' <<<"$clean_output")"
    [[ -n "$path" ]] && info "$optional: $path"
  done <<'TOOLS'
fnm
node
pnpm
TOOLS
  pnpm_home="$(awk -F= '$1 == "pnpm_home" { print substr($0, index($0, "=") + 1); exit }' <<<"$clean_output")"
  [[ -n "$pnpm_home" ]] && info "PNPM_HOME: $pnpm_home"

  required_aliases='cdayone gs gd gds gl gremotes brewcheck brewout brewcleanpreview brewautopreview'
  required_count=10
  if uses_chezmoi; then required_aliases+=' cm cmstatus cmdiff cmverify cmdoctor'; required_count=15; fi
  alias_output="$(env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" TERM="${TERM:-xterm-256color}" PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL="$expected" \
    "$expected" -lic "alias $required_aliases" 2>/dev/null || true)"
  alias_count="$(printf '%s\n' "$alias_output" | awk 'NF { count++ } END { print count + 0 }')"
  [[ "$alias_count" == "$required_count" ]] \
    && ok "$required_count selected safe Day One Mac aliases are loaded" \
    || fail "only $alias_count of $required_count selected safe Day One Mac aliases are loaded"
  if uses_chezmoi && "$expected" -lic 'alias cmdifftext cmmerge >/dev/null' 2>/dev/null; then
    info "VS Code chezmoi convenience aliases are loaded: cmdifftext, cmmerge"
  elif uses_chezmoi; then
    info "optional aliases cmdifftext and cmmerge can be adopted from the current Phase 5 baseline"
  fi

  completion_output="$(env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" TERM="${TERM:-xterm-256color}" PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL="$expected" \
    "$expected" -fc 'for dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do [[ -d "$dir" ]] && fpath=("$dir" $fpath); done; autoload -Uz compaudit; compaudit' 2>/dev/null || true)"
  if [[ -z "$completion_output" ]]; then
    ok "Zsh completion directories pass compaudit"
  else
    fail "Zsh completion directories need a permission review"
    printf '%s\n' "$completion_output" | sed 's/^/      /'
  fi
fi

if (( failures == 0 )); then
  ui_success 'Shell status passed.'
  exit 0
fi
ui_status error "$DAY_ONE_UI_ERROR Shell status found $failures problem(s)."
exit 1
