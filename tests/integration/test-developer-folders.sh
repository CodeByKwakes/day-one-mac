#!/usr/bin/env bash
# Isolated capability tests; never install packages or modify the real HOME.
# These test doubles are called indirectly by the sourced capability.
# shellcheck disable=SC2329
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-folders.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
trap 'printf "Folder test failed at line %s\n" "$LINENO" >&2' ERR
export HOME="$TEST_ROOT/home with spaces é"
export DAY_ONE_MAC_STATE_ROOT="$HOME/state"
mkdir -p "$HOME"
unset GHQ_ROOT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_COUNT || true
export GIT_CONFIG_NOSYSTEM=1
export XDG_CONFIG_HOME="$HOME/.config"
source "$SCRIPT_DIR/../src/setup/setup.sh"

expect_exit() {
  local expected="$1" actual=0; shift
  "$@" > "$TEST_ROOT/output" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || { cat "$TEST_ROOT/output" >&2; printf 'Expected %s, got %s\n' "$expected" "$actual" >&2; exit 1; }
}

# A folders-only plan/apply/check must not touch any unrelated tool.
have() { return 1; }
load_brew() { printf 'unexpected Homebrew probe\n' >&2; exit 99; }
install_formula() { printf 'unexpected package installation\n' >&2; exit 99; }
FOLDER_LAYOUT=none GHQ_CHOICE=no FOLDER_GHQ_ROOT=''
expect_exit 0 folders_plan
[[ ! -e "$HOME/Developer" && ! -e "$STATE_DIR" ]]
expect_exit 11 folders_check
expect_exit 0 folders_apply
[[ -d "$HOME/Developer" && ! -e "$HOME/.gitconfig" ]]
expect_exit 0 folders_check
before="$(shasum -a 256 "$PATH_MANIFEST")"
expect_exit 0 folders_apply
[[ "$before" == "$(shasum -a 256 "$PATH_MANIFEST")" ]]

# Purpose folders are additive; old numbered folders and arbitrary files survive.
mkdir -p "$HOME/Developer/03_Resources" "$HOME/Developer/Projects"
mkdir -p "$HOME/Developer/Resources/VSCode/Profiles"
printf 'keep profile\n' > "$HOME/Developer/Resources/VSCode/Profiles/personal.code-profile"
printf 'keep\n' > "$HOME/Developer/Projects/notes"
FOLDER_LAYOUT=purpose
expect_exit 0 folders_apply
for name in Projects Sandbox Resources Archive; do [[ -d "$HOME/Developer/$name" ]]; done
for name in Project-Materials Shared-Assets Datasets Templates Reference Scripts VSCode Warp Raycast; do
  [[ -d "$HOME/Developer/Resources/$name" ]]
done
for name in Settings Profiles Extensions Snippets Themes Workspaces; do
  [[ -d "$HOME/Developer/Resources/VSCode/$name" ]]
done
for name in Themes Workflows Launch-Configurations Exports; do
  [[ -d "$HOME/Developer/Resources/Warp/$name" ]]
done
for name in Script-Commands Quicklinks Snippets Exports; do
  [[ -d "$HOME/Developer/Resources/Raycast/$name" ]]
done
for name in Projects Experiments Project-Materials Exports; do
  [[ -d "$HOME/Developer/Archive/$name" ]]
done
[[ "$(cat "$HOME/Developer/Resources/VSCode/Profiles/personal.code-profile")" == 'keep profile' ]]
! grep -Fq "$HOME/Developer/Resources/VSCode/Profiles" "$PATH_MANIFEST"
cmp "$SCRIPT_DIR/../docs/setup/manual/development/resources.md" "$HOME/Developer/Resources/README.md"
grep -Fq "$HOME/Developer/Resources/README.md" "$PATH_MANIFEST"
[[ ! -e "$HOME/Developer/Resources/Project-Materials/example-app" ]]
before="$(shasum -a 256 "$PATH_MANIFEST" "$HOME/Developer/Resources/README.md")"
expect_exit 0 folders_apply
[[ "$before" == "$(shasum -a 256 "$PATH_MANIFEST" "$HOME/Developer/Resources/README.md")" ]]
printf 'My own guide\n' > "$HOME/Developer/Resources/README.md"
expect_exit 0 folders_apply
[[ "$(cat "$HOME/Developer/Resources/README.md")" == 'My own guide' ]]
[[ -f "$HOME/Developer/Projects/notes" && -d "$HOME/Developer/03_Resources" ]]
! grep -Fq "$HOME/Developer/Projects" "$PATH_MANIFEST"
FOLDER_LAYOUT=repository
expect_exit 0 folders_check
FOLDER_LAYOUT=existing
expect_exit 0 folders_check

# All path conflicts are caught before any directory/config write.
mv "$HOME/Developer" "$HOME/kept-developer"
ln -s "$HOME/kept-developer" "$HOME/Developer"
expect_exit 11 folders_apply
rm "$HOME/Developer"
printf 'collision\n' > "$HOME/Developer"
expect_exit 11 folders_apply
rm "$HOME/Developer"
mkdir -p "$HOME/Developer"
printf 'collision\n' > "$HOME/Developer/Archive"
FOLDER_LAYOUT=purpose
expect_exit 11 folders_apply
[[ ! -e "$HOME/Developer/Projects" ]]
rm "$HOME/Developer/Archive"

# Nested conflicts and unsafe README targets also stop before creating folders.
mkdir -p "$HOME/Developer/Resources"
printf 'collision\n' > "$HOME/Developer/Resources/Datasets"
expect_exit 11 folders_apply
[[ ! -e "$HOME/Developer/Projects" ]]
rm "$HOME/Developer/Resources/Datasets"
mkdir -p "$HOME/Developer/Resources/Warp"
printf 'collision\n' > "$HOME/Developer/Resources/Warp/Themes"
expect_exit 11 folders_apply
[[ ! -e "$HOME/Developer/Projects" && ! -e "$HOME/Developer/Resources/VSCode" ]]
rm "$HOME/Developer/Resources/Warp/Themes"
mkdir "$HOME/Developer/Resources/README.md"
expect_exit 11 folders_apply
[[ ! -e "$HOME/Developer/Projects" ]]
rmdir "$HOME/Developer/Resources/README.md"
printf 'keep\n' > "$HOME/external-readme"
ln -s "$HOME/external-readme" "$HOME/Developer/Resources/README.md"
expect_exit 11 folders_apply
[[ ! -e "$HOME/Developer/Projects" && "$(cat "$HOME/external-readme")" == keep ]]
rm "$HOME/Developer/Resources/README.md"
DRY_RUN=1
expect_exit 0 folders_apply
[[ ! -e "$HOME/Developer/Resources/README.md" && ! -e "$HOME/Developer/Resources/Datasets" ]]
DRY_RUN=0

# Unknown choices and incomplete historic state never imply ghq consent.
FOLDER_LAYOUT='' GHQ_CHOICE=''
expect_exit 2 folders_validate_choices
expect_exit 2 /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --plan --layout purpose
expect_exit 2 /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --resume --ghq no
expect_exit 2 /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --plan --install-ghq

# Controlled ghq exposes Git's global roots; explicit overrides mirror ghq.
ghq_present=1 chezmoi_present=0
have() {
  case "$1" in git) return 0 ;; ghq) [[ "$ghq_present" == 1 ]] ;; chezmoi) [[ "$chezmoi_present" == 1 ]] ;; *) return 1 ;; esac
}
ghq() {
  local roots
  [[ "$1" == root ]] || return 1
  roots="${GHQ_ROOT:-$(git config --global --get-all ghq.root || true)}"
  roots="${roots:-$HOME/ghq}"
  if [[ "${2:-}" == --all ]]; then printf '%s\n' "$roots"; else printf '%s\n' "$roots" | tail -1; fi
}
chezmoi() { printf 'unexpected chezmoi execution\n' >&2; exit 99; }
FOLDER_LAYOUT=purpose GHQ_CHOICE=yes FOLDER_GHQ_ROOT=''
mkdir -p "$HOME/ghq/keep-me"
expect_exit 10 folders_plan
[[ ! -e "$HOME/.gitconfig" && -d "$HOME/ghq/keep-me" ]]
rmdir "$HOME/ghq/keep-me" "$HOME/ghq"
expect_exit 0 folders_plan
[[ ! -e "$HOME/.gitconfig" ]]
expect_exit 0 folders_apply
[[ "$(git config --global ghq.root)" == "$HOME/Developer/Projects" ]]
expect_exit 0 folders_check
before="$(shasum -a 256 "$HOME/.gitconfig" "$PATH_MANIFEST")"
expect_exit 0 folders_apply
[[ "$before" == "$(shasum -a 256 "$HOME/.gitconfig" "$PATH_MANIFEST")" ]]

# Declining ghq never reads or alters its configuration, even when installed.
GHQ_CHOICE=no
expect_exit 0 folders_apply
[[ "$before" == "$(shasum -a 256 "$HOME/.gitconfig" "$PATH_MANIFEST")" ]]
GHQ_CHOICE=yes FOLDER_LAYOUT=repository
expect_exit 10 folders_apply
[[ "$(git config --global ghq.root)" == "$HOME/Developer/Projects" ]]

# Keep existing preserves several roots, including paths outside Developer.
mkdir -p "$HOME/external projects"
git config --global --add ghq.root "$HOME/external projects"
FOLDER_LAYOUT=existing FOLDER_GHQ_ROOT="$HOME/external projects"
before="$(shasum -a 256 "$HOME/.gitconfig")"
expect_exit 0 folders_apply
expect_exit 0 folders_check
[[ "$before" == "$(shasum -a 256 "$HOME/.gitconfig")" ]]
FOLDER_GHQ_ROOT="$HOME/Developer"
expect_exit 10 folders_apply
expect_exit 11 folders_check

# Environment precedence is observed only; never persist/replace it silently.
export GHQ_ROOT="$HOME/external projects"
FOLDER_GHQ_ROOT="$GHQ_ROOT"
expect_exit 0 folders_apply
FOLDER_LAYOUT=purpose FOLDER_GHQ_ROOT=''
expect_exit 10 folders_apply
unset GHQ_ROOT

# Managed Git source, symlink config, includes and URL roots require manual review.
git config --global --unset-all ghq.root
chezmoi_present=1
mkdir -p "$HOME/.config/chezmoi"
expect_exit 10 folders_apply
rmdir "$HOME/.config/chezmoi"
chezmoi_present=0
mv "$HOME/.gitconfig" "$HOME/config-original"
ln -s "$HOME/config-original" "$HOME/.gitconfig"
expect_exit 10 folders_apply
rm "$HOME/.gitconfig"
mv "$HOME/config-original" "$HOME/.gitconfig"
git config --global include.path "$HOME/extra-git-config"
expect_exit 10 folders_apply
git config --global --unset-all include.path
git config --global ghq.https://example.com.root "$HOME/external projects"
expect_exit 10 folders_apply
git config --global --unset-all ghq.https://example.com.root

# Missing ghq does not implicitly install it or bootstrap prerequisites.
ghq_present=0
expect_exit 10 folders_apply
[[ -z "$(git config --global --get-all ghq.root || true)" ]]
installed=0
load_brew() { return 0; }
install_formula() { [[ "$1" == ghq ]]; installed=$((installed + 1)); ghq_present=1; }
INSTALL_GHQ=1
expect_exit 0 folders_apply
[[ "$installed" == 1 ]]
expect_exit 0 folders_apply
[[ "$installed" == 1 ]]

# Required package and fingerprint gates depend on selections, not installation.
TRACK=1 STACK=python PRESET=core PRIMARY_IDE=other AUTH_MODE=keychain
GHQ_CHOICE=no
! required_formulae | grep -Fxq ghq
first="$(phase_fingerprint 04)"
GHQ_CHOICE=yes
required_formulae | grep -Fxq ghq
[[ "$first" != "$(phase_fingerprint 04)" ]]

# Saved choices support read-only checks; explicit incompatible roots are rejected.
expect_exit 0 /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --plan --layout none --ghq no
expect_exit 2 /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --plan --layout none --ghq no --ghq-root /tmp

# Exercise the real command/lock/journal, including live repair on resume.
existing_home="$TEST_ROOT/existing resources"
mkdir -p "$existing_home/Developer/Resources"
printf 'User-owned instructions\n' > "$existing_home/Developer/Resources/README.md"
expect_exit 0 env HOME="$existing_home" DAY_ONE_MAC_STATE_ROOT="$existing_home/state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --apply --layout purpose --ghq no
[[ "$(cat "$existing_home/Developer/Resources/README.md")" == 'User-owned instructions' ]]
! grep -Fq "$existing_home/Developer/Resources/README.md" "$existing_home/state/path-manifest.tsv"

cli_home="$TEST_ROOT/cli home é"
cli_state="$cli_home/state"
mkdir -p "$cli_home"
expect_exit 2 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --resume
[[ ! -e "$cli_state" ]]
expect_exit 0 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --plan --layout purpose --ghq no
[[ ! -e "$cli_state" && ! -e "$cli_home/Developer" ]]
expect_exit 0 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --apply --layout purpose --ghq no
[[ ! -e "$cli_state.operation.lock" && ! -e "$cli_home/.gitconfig" ]]
rmdir "$cli_home/Developer/Resources/VSCode/Snippets"
expect_exit 11 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --check
expect_exit 0 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --resume
[[ -d "$cli_home/Developer/Resources/VSCode/Snippets" ]]
rm "$cli_home/Developer/Resources/README.md"
expect_exit 11 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --check
expect_exit 0 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --resume
cmp "$SCRIPT_DIR/../docs/setup/manual/development/resources.md" "$cli_home/Developer/Resources/README.md"
before="$(shasum -a 256 "$cli_state/path-manifest.tsv" "$cli_state/setup.log")"
expect_exit 0 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" "$SCRIPT_DIR/day-one-mac" folders --check
[[ "$before" == "$(shasum -a 256 "$cli_state/path-manifest.tsv" "$cli_state/setup.log")" ]]
mv "$cli_state/path-manifest.tsv" "$cli_state/path-original.tsv"
ln -s "$cli_state/path-original.tsv" "$cli_state/path-manifest.tsv"
rmdir "$cli_home/Developer/Resources/Datasets"
expect_exit 11 env HOME="$cli_home" DAY_ONE_MAC_STATE_ROOT="$cli_state" /bin/bash "$SCRIPT_DIR/../src/modules/configure-folders.sh" --resume
[[ ! -e "$cli_home/Developer/Resources/Datasets" ]]
# An interrupted choice update is explicitly incomplete, never mixed consent.
(
  save_state_value() {
    [[ "$1" != folder-ghq-root ]] || return 23
    day_one_write_state "$STATE_DIR/$1" "$2"
  }
  expect_exit 23 folders_save_choices
  [[ "$(state_value ghq-choice)" == pending ]]
)
printf 'Developer folders and optional ghq regressions passed.\n'
