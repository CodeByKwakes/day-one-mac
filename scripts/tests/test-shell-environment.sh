#!/usr/bin/env bash
# Regression tests for the shell environment Phase 5 writes.
#
# The bug these close: Homebrew's PATH lived only in ~/.zprofile, which zsh
# reads for LOGIN shells only. Every guard in ~/.zshrc is `command -v`, so a
# non-login interactive shell silently started with no Starship prompt, no fnm
# and no pnpm — and made uv-installed Python invisible too.
set -euo pipefail

# A fixture must never block on an interactive prompt: the runner asks for
# input when stdin is a TTY, which hangs when this is run from a real terminal
# rather than CI. Detach stdin so every child takes the non-interactive path.
exec </dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "/tmp/day-one-mac-shell-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail_test() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# Extract the exact shell file bodies the runner writes.
extract_shell_file() {
  python3 - "$SCRIPT_DIR/setup.sh" "$1" <<'PY'
import re, sys
src, name = sys.argv[1], sys.argv[2]
s = open(src).read()
m = re.search(r"^[ ]+%s=\$'(.*?)'\n" % name, s, re.S | re.M)
if not m:
    sys.exit("could not find %s in setup.sh" % name)
value = m.group(1)
if name == "zsh_path":
    extra = re.search(r"^[ ]+zsh_path\+=\$'(.*?)'\n", s, re.S | re.M)
    if extra:
        value += extra.group(1)
sys.stdout.write(value.encode().decode('unicode_escape'))
PY
}

home="$TEST_ROOT/home"
prefix="$TEST_ROOT/brew"
mkdir -p "$home/.local/bin" "$home/.config/zsh" "$prefix/bin" "$prefix/sbin"

# A Homebrew prefix reachable only through `brew shellenv`, like the real one.
printf '#!/bin/sh\n[ "$1" = shellenv ] && printf "export HOMEBREW_PREFIX=\\"%s\\"\\nexport PATH=\\"%s/bin:%s/sbin:$PATH\\"\\n"\n' "$prefix" "$prefix" "$prefix" > "$prefix/bin/brew"
printf '#!/bin/sh\n[ "$1" = init ] && printf ":\\n"\n' > "$prefix/bin/starship"
printf '#!/bin/sh\n[ "$1" = root ] && printf "/tmp/day-one-mac\\n"\n' > "$home/.local/bin/day-one-mac"
printf '#!/bin/sh\nexit 0\n' > "$prefix/bin/git"
printf '#!/bin/sh\nexit 0\n' > "$prefix/bin/chezmoi"
chmod +x "$prefix/bin/brew" "$prefix/bin/starship" "$prefix/bin/git" "$prefix/bin/chezmoi"
chmod +x "$home/.local/bin/day-one-mac"

extract_shell_file zprofile > "$home/.zprofile"
extract_shell_file zshrc    > "$home/.zshrc"
extract_shell_file zsh_path > "$home/.config/zsh/path.zsh"
extract_shell_file zsh_aliases > "$home/.config/zsh/aliases.zsh"

# The human-readable Phase 5 reference must remain the same as the runner. The
# portable installer adds one optional explanatory comment to .zprofile, so
# compare its content from the second line onward.
reference="$SCRIPT_DIR/../docs/20-reference/phase-05-shell-files/home"
cmp -s "$home/.zshrc" "$reference/.zshrc" \
  || fail_test 'the .zshrc reference has drifted from the Phase 5 generator'
cmp -s "$home/.config/zsh/path.zsh" "$reference/.config/zsh/path.zsh" \
  || fail_test 'the path.zsh reference has drifted from the Phase 5 generator'
cmp -s "$home/.config/zsh/aliases.zsh" "$reference/.config/zsh/aliases.zsh" \
  || fail_test 'the aliases.zsh reference has drifted from the Phase 5 generator'
tail -n +2 "$reference/.zprofile" > "$TEST_ROOT/reference-zprofile"
cmp -s "$home/.zprofile" "$TEST_ROOT/reference-zprofile" \
  || fail_test 'the .zprofile reference has drifted from the Phase 5 generator'

grep -Fq '.config/zsh/path.zsh' "$home/.zprofile" \
  || fail_test '.zprofile no longer sources the shared PATH file'
grep -Fq '.config/zsh/path.zsh' "$home/.zshrc" \
  || fail_test '.zshrc no longer sources the shared PATH file'
grep -Fq 'brew shellenv' "$home/.config/zsh/path.zsh" \
  || fail_test 'path.zsh no longer configures Homebrew'
grep -Fq 'typeset -U path PATH' "$home/.config/zsh/path.zsh" \
  || fail_test 'path.zsh no longer deduplicates PATH safely'
grep -Fq '.local/bin' "$home/.config/zsh/path.zsh" \
  || fail_test 'path.zsh no longer guarantees ~/.local/bin'
grep -Fq 'alias cdayone=' "$home/.config/zsh/aliases.zsh" \
  || fail_test 'the safe Day One Mac navigation alias is missing'
grep -Fq 'HISTFILE=' "$home/.zshrc" || fail_test 'persistent zsh history is missing'
[[ "$(grep -c '^compinit$' "$home/.zshrc")" == 1 ]] || fail_test 'compinit must run exactly once'

# Point the generated files at the sandbox prefix.
sed -i '' "s|/opt/homebrew|$prefix|g" \
  "$home/.zshrc" "$home/.zprofile" "$home/.config/zsh/path.zsh" "$home/.config/zsh/aliases.zsh"

cat >> "$home/.zshrc" <<'EOS'
printf 'starship=%s\n' "$(command -v starship >/dev/null 2>&1 && echo yes || echo no)"
printf 'brewcount=%s\n' "$(printf '%s' "$PATH" | tr ':' '\n' | grep -cx "$DOM_PREFIX/bin" || true)"
printf 'localcount=%s\n' "$(printf '%s' "$PATH" | tr ':' '\n' | grep -cx "$HOME/.local/bin" || true)"
EOS

run_shell() {
  env -i HOME="$home" USER="$(id -un)" LOGNAME="$(id -un)" DOM_PREFIX="$prefix" \
    PATH='/usr/bin:/bin:/usr/sbin:/sbin' SHELL=/bin/zsh TERM=xterm-256color \
    /bin/zsh "$1" -c 'true' 2>/dev/null
}

# A login shell was always fine; it must stay fine and must not gain duplicates.
login="$(run_shell -lic)"
grep -Fqx 'starship=yes' <<<"$login" || fail_test 'a login shell cannot find starship'
grep -Fqx 'brewcount=1'  <<<"$login" || fail_test "a login shell has a duplicated Homebrew PATH entry: $(grep brewcount <<<"$login")"
grep -Fqx 'localcount=1' <<<"$login" || fail_test "a login shell has a duplicated ~/.local/bin entry: $(grep localcount <<<"$login")"

# The regression itself: a non-login interactive shell must work too.
nonlogin="$(run_shell -ic)"
grep -Fqx 'starship=yes' <<<"$nonlogin" \
  || fail_test 'a non-login interactive shell cannot find starship — the .zprofile-only PATH bug is back'
grep -Fqx 'brewcount=1'  <<<"$nonlogin" || fail_test "a non-login shell has a duplicated Homebrew PATH entry: $(grep brewcount <<<"$nonlogin")"
grep -Fqx 'localcount=1' <<<"$nonlogin" || fail_test "a non-login shell has a duplicated ~/.local/bin entry: $(grep localcount <<<"$nonlogin")"

# PNPM_HOME is owned by the shared path file so both shell kinds receive it
# without duplicating a PATH block in either startup file.
grep -Fq 'PNPM_HOME' "$home/.config/zsh/path.zsh" || fail_test 'path.zsh no longer exports PNPM_HOME'
grep -Fq 'PNPM_HOME' "$home/.zprofile" && fail_test '.zprofile must not duplicate PNPM_HOME'
grep -Fq 'PNPM_HOME' "$home/.zshrc" && fail_test '.zshrc must not duplicate PNPM_HOME'
alias_count="$(PATH="$home/.local/bin:$prefix/bin:$PATH" /bin/zsh -fc 'source "$1"; alias cdayone gs gd gds gl gremotes cm cmstatus cmdiff cmverify cmdoctor brewcheck brewout brewcleanpreview brewautopreview' _ "$home/.config/zsh/aliases.zsh" 2>/dev/null | awk 'NF { count++ } END { print count + 0 }')"
[[ "$alias_count" == 15 ]] || fail_test "only $alias_count of 15 safe aliases load in zsh"

# ---------------------------------------------------------------------------
# The login-shell switch must never leave an unusable shell behind.
# ---------------------------------------------------------------------------

sw_harness="$TEST_ROOT/switch.sh"
{
  printf 'set -euo pipefail\nDRY_RUN=0\nEX_GATE=20\nEX_MANUAL=21\n'
  printf 'err(){ printf "ERR %%s\\n" "$*"; }\nwarn(){ printf "WARN %%s\\n" "$*"; }\n'
  printf 'info(){ printf "INFO %%s\\n" "$*"; }\nok(){ printf "OK %%s\\n" "$*"; }\n'
  printf 'print_command(){ printf "CMD %%s\\n" "$*"; }\nconfirm(){ return 0; }\n'
  printf 'record_path_before_write(){ :; }\nsave_state_value(){ :; }\n'
  printf 'sudo(){ printf "SUDO-CALLED\\n"; return 1; }\nchsh(){ printf "CHSH-CALLED %%s\\n" "$*"; return 1; }\n'
  sed -n '/^switch_login_shell_to_homebrew_zsh() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  printf 'switch_login_shell_to_homebrew_zsh\n'
} > "$sw_harness"

grep -Fq 'switch_login_shell_to_homebrew_zsh' "$sw_harness" \
  || fail_test 'switch_login_shell_to_homebrew_zsh was not found in setup.sh'

sw_bin="$TEST_ROOT/swbin"
mkdir -p "$sw_bin" "$prefix/bin"
printf '#!/bin/sh\n[ "$1" = --prefix ] && echo "%s"\n' "$prefix" > "$sw_bin/brew"
chmod +x "$sw_bin/brew"

# No zsh in the prefix: decline, do not touch anything.
rm -f "$prefix/bin/zsh"
out="$(PATH="$sw_bin:$PATH" bash "$sw_harness" || true)"
grep -Fq 'CHSH-CALLED' <<<"$out" && fail_test 'chsh ran with no Homebrew zsh installed'
grep -Fq 'SUDO-CALLED' <<<"$out" && fail_test 'sudo ran with no Homebrew zsh installed'

# A zsh that does not start must never become the login shell.
printf '#!/bin/sh\nexit 1\n' > "$prefix/bin/zsh"; chmod +x "$prefix/bin/zsh"
out="$(PATH="$sw_bin:$PATH" bash "$sw_harness" || true)"
grep -Fq 'CHSH-CALLED' <<<"$out" && fail_test 'chsh ran for a zsh binary that does not start'
grep -Fq 'refusing'    <<<"$out" || fail_test 'a broken zsh binary was not refused'

# A working zsh: the recovery instruction must be shown before switching, and
# a failed chsh must fail the gate instead of silently completing Phase 5.
printf '#!/bin/sh\n[ "$1" = --version ] && echo "zsh 5.9.2"\nexit 0\n' > "$prefix/bin/zsh"
chmod +x "$prefix/bin/zsh"
out="$(PATH="$sw_bin:$PATH" bash "$sw_harness" || true)"
grep -Fq 'chsh -s /bin/zsh' <<<"$out" \
  || fail_test 'the switch did not tell the user how to recover a broken login shell'

# The function must verify Directory Services after a successful chsh.
sw_success="$TEST_ROOT/switch-success.sh"
{
  printf 'set -euo pipefail\nDRY_RUN=0\nEX_GATE=20\nEX_MANUAL=21\nCHANGED=0\n'
  printf 'err(){ printf "ERR %%s\\n" "$*"; }\nwarn(){ printf "WARN %%s\\n" "$*"; }\n'
  printf 'info(){ printf "INFO %%s\\n" "$*"; }\nok(){ printf "OK %%s\\n" "$*"; }\n'
  printf 'print_command(){ :; }\nconfirm(){ return 0; }\nrecord_path_before_write(){ :; }\nsave_state_value(){ :; }\n'
  printf 'sudo(){ return 0; }\ngrep(){ [[ "${*: -1}" == /etc/shells ]] && return 0; command grep "$@"; }\n'
  printf 'chsh(){ CHANGED=1; printf "CHSH-CALLED %%s\\n" "$*"; }\n'
  printf 'dscl(){ if [[ "$CHANGED" == 1 ]]; then printf "UserShell: %s\\n"; else printf "UserShell: /bin/zsh\\n"; fi; }\n' "$prefix/bin/zsh"
  sed -n '/^switch_login_shell_to_homebrew_zsh() {/,/^}/p' "$SCRIPT_DIR/setup.sh"
  printf 'switch_login_shell_to_homebrew_zsh\n'
} > "$sw_success"
out="$(PATH="$sw_bin:$PATH" bash "$sw_success")"
grep -Fq 'gate: Directory Services login shell' <<<"$out" \
  || fail_test 'a successful switch was not verified through Directory Services'

# A transient Directory Services lookup failure must not terminate the whole
# phase under `set -e`; the function already has an `unknown` display fallback.
grep -Fq '|| true)' "$sw_harness" \
  || fail_test 'the login-shell lookup no longer tolerates unavailable Directory Services'

printf 'PASS: managed shell files, clean PATHs, aliases and required login-shell gate work\n'
