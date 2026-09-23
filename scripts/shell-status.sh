#!/usr/bin/env bash
set -uo pipefail

# Read-only shell health report. This script never changes startup files,
# permissions, the login shell, or Homebrew packages.

green=$'\033[32m'
yellow=$'\033[33m'
red=$'\033[31m'
blue=$'\033[36m'
reset=$'\033[0m'
[[ -t 1 ]] || green='' yellow='' red='' blue='' reset=''

ok()   { printf '  %s✓%s %s\n' "$green" "$reset" "$*"; }
warn() { printf '  %s⚠%s %s\n' "$yellow" "$reset" "$*"; }
fail() { printf '  %s✗%s %s\n' "$red" "$reset" "$*"; failures=$((failures + 1)); }
info() { printf '  %sℹ%s %s\n' "$blue" "$reset" "$*"; }

failures=0
expected='/opt/homebrew/bin/zsh'
configured="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}' || true)"

printf '\n🐚 Day One Mac shell status\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'

[[ -x "$expected" ]] \
  && ok "Homebrew zsh: $expected ($("$expected" --version 2>/dev/null))" \
  || fail "Homebrew zsh is missing or cannot run: $expected"
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
  for command_name in zsh brew day-one-mac starship; do
    path="$(awk -F= -v key="$command_name" '$1 == key { print substr($0, index($0, "=") + 1); exit }' <<<"$clean_output")"
    [[ -n "$path" ]] && ok "clean login shell finds $command_name: $path" || fail "clean login shell cannot find $command_name"
  done
  resolved_zsh="$(awk -F= '$1 == "zsh" { print substr($0, index($0, "=") + 1); exit }' <<<"$clean_output")"
  [[ "$resolved_zsh" == "$expected" ]] || fail "PATH resolves zsh to ${resolved_zsh:-missing}; expected $expected"
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

  alias_output="$(env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" TERM="${TERM:-xterm-256color}" PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL="$expected" \
    "$expected" -lic 'alias cdayone gs gd gds gl gremotes cm cmstatus cmdiff cmverify cmdoctor brewcheck brewout brewcleanpreview brewautopreview' 2>/dev/null || true)"
  alias_count="$(printf '%s\n' "$alias_output" | awk 'NF { count++ } END { print count + 0 }')"
  [[ "$alias_count" == 15 ]] \
    && ok "15 safe Day One Mac aliases are loaded" \
    || fail "only $alias_count of 15 safe Day One Mac aliases are loaded"

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
  printf '\n%s✓ Shell status passed.%s\n' "$green" "$reset"
  exit 0
fi
printf '\n%s✗ Shell status found %d problem(s).%s\n' "$red" "$failures" "$reset"
exit 1
