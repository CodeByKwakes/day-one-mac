#!/usr/bin/env bash
set -euo pipefail

# A fixture must never block on an interactive prompt: the runner asks for
# input when stdin is a TTY, which hangs when this is run from a real terminal
# rather than CI. Detach stdin so every child takes the non-interactive path.
exec </dev/null

# The cleanup refuses to run inside Warp, because a real cleanup can uninstall
# the terminal it is running in. This fixture only ever acts on a sandboxed
# HOME, with brew off PATH so no cask can be uninstalled, and /Applications is
# only read for an inventory listing. Warp is a required app in this project,
# so Phase 8 is routinely run from it — clear the markers for the fixture.
# The guard itself is unchanged and still protects real runs.
unset TERM_PROGRAM WARP_IS_LOCAL_SHELL_SESSION

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Keep this path short enough for macOS's Unix-domain socket path limit. The
# socket regression below intentionally creates the same kind of IPC endpoint
# that Codex stores under ~/.codex/ipc.
TEST_ROOT="$(mktemp -d "/tmp/day-one-mac-test.XXXXXX")"
SOCKET_LISTENER_PID=""
SOCKET_TEST_SUPPORTED=0
cleanup_test() {
  if [[ -n "$SOCKET_LISTENER_PID" ]]; then
    kill "$SOCKET_LISTENER_PID" 2>/dev/null || true
    wait "$SOCKET_LISTENER_PID" 2>/dev/null || true
  fi
  rm -rf "$TEST_ROOT"
}
trap cleanup_test EXIT

# Most assertions here are bare `grep -Fq ...` lines relied on by `set -e`.
# When one fails the shell exits silently, so a failure used to say nothing
# about which check broke. Name the line and the command instead.
report_failed_assertion() {
  local status=$?
  printf '\nFAILED at %s line %s: %s\n' \
    "${BASH_SOURCE[1]##*/}" "${BASH_LINENO[0]}" "$BASH_COMMAND" >&2
  exit "$status"
}
trap report_failed_assertion ERR

TEST_HOME="$TEST_ROOT/home"
TEST_STATE_ROOT="$TEST_HOME/.day-one-mac"
TEST_STATE="$TEST_STATE_ROOT"
mkdir -p "$TEST_HOME" "$TEST_STATE/originals"
export DAY_ONE_MAC_APPLICATIONS_ROOT="$TEST_ROOT/no-applications"
export DAY_ONE_MAC_SYSTEM_FONTS_ROOT="$TEST_ROOT/no-system-fonts"
export DAY_ONE_MAC_USER_FONTS_ROOT="$TEST_ROOT/no-user-fonts"
export DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled
export DAY_ONE_MAC_APPLICATION_COMMAND_LOOKUP=disabled
export DAY_ONE_MAC_DISABLE_BREW_DISCOVERY=1

ui_output="$TEST_ROOT/terminal-ui.txt"
NO_COLOR=1 TERM=xterm /bin/bash -c 'source "$1"; ui_title "🧪" "UI test"; ui_success "complete"; ui_warning "review"' \
  _ "$SCRIPT_DIR/lib/terminal-ui.sh" > "$ui_output" 2>&1
grep -Fq '🧪 UI test' "$ui_output"
grep -Fq '✓ complete' "$ui_output"
grep -Fq '⚠ review' "$ui_output"
if LC_ALL=C grep -q $'\033' "$ui_output"; then
  printf 'FAIL: NO_COLOR output contains terminal escape codes\n' >&2
  exit 1
fi

"$SCRIPT_DIR/rollback-recorded-setup.sh" --help | grep -Fq -- '--all-recorded'
"$SCRIPT_DIR/rollback-recorded-setup.sh" --help | grep -Fq -- '--skip-packages'
"$SCRIPT_DIR/rollback-recorded-setup.sh" --help | grep -Fq -- '--skip-paths'
"$SCRIPT_DIR/remove-day-one-mac.sh" --help | grep -Fq -- '--sections CSV'
"$SCRIPT_DIR/remove-day-one-mac.sh" --help | grep -Fq -- '--developer MODE'
"$SCRIPT_DIR/finalize-setup.sh" --help | grep -Fq -- '--detach'
"$SCRIPT_DIR/finalize-setup.sh" --help | grep -Fq -- '--warp-handled'
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --help | grep -Fq 'open the interactive setup wizard'
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --help | grep -Fq -- '--new-dotfiles'
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --help | grep -Fq -- '--local-dotfiles'
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --help | grep -Fq -- '--dotfiles-versioning'
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --help | grep -Fq -- '--preflight'
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --help | grep -Fq -- '--safety-report'
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --help | grep -Fq -- '--prepare-existing'
"$SCRIPT_DIR/bootstrap-day-one-mac.sh" --help | grep -Fq -- '--optional [--guided]'
grep -Fq 'post_required_menu' "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq 'Checking for native Apple-silicon Homebrew before running an installer.' \
  "$SCRIPT_DIR/setup.sh"
grep -Fq 'Existing Homebrew found at' "$SCRIPT_DIR/setup.sh"
grep -Fq 'Do not install a second copy over it.' "$SCRIPT_DIR/setup.sh"
grep -Fq "MACOS_SETTINGS_PLAN=ask" "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq 'Optional setup remains locked until required Phase 8 is complete.' \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
! sed -n '/^configure_wizard()/,/^}/p' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
  | grep -Fq 'choose_optional_plan'
grep -Fq "omniroute) label='OmniRoute AI gateway'" "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq 'OmniRoute AI gateway — local Docker routing for selected AI clients' \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq 'without_csv_value "$OPTIONAL_MODULES" omniroute' \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq "raycast-ai) label='Raycast AI'" "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq 'Raycast AI — paid plan required for custom providers' \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq "copilot-app) label='GitHub Copilot app'" "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq 'GitHub Copilot app — standalone desktop client' \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
grep -Fq 'day-one-mac applications --id copilot-app' \
  "$SCRIPT_DIR/../docs/02-optional/10-ai-agents.md"
grep -Fq 'github-copilot-app' "$SCRIPT_DIR/../config/applications.tsv"
grep -Fq 'brew uninstall --cask github-copilot-app' \
  "$SCRIPT_DIR/../docs/02-optional/10-ai-agents.md"
grep -Fq 'docker context use orbstack' "$SCRIPT_DIR/../docs/02-optional/10a-omniroute.md"
grep -Fq 'Warp is the required graphical terminal' "$SCRIPT_DIR/../docs/02-optional/10a-omniroute.md"
grep -Fq 'There is no OmniRoute `.env` file' "$SCRIPT_DIR/../docs/02-optional/10a-omniroute.md"
grep -Fq 'optional/10a-omniroute.md' "$SCRIPT_DIR/validate.sh"
"$SCRIPT_DIR/clean-development-state.sh" --help | grep -Fq 'applications not installed by'
"$SCRIPT_DIR/clean-development-state.sh" --help | grep -Fq -- '--archive-ssh-private-keys'
"$SCRIPT_DIR/clean-development-state.sh" --help | grep -Fq -- '--prepare-keychain-reset'
"$SCRIPT_DIR/clean-development-state.sh" --help | grep -Fq -- '--archive-docker-data'
"$SCRIPT_DIR/clean-development-state.sh" --help | grep -Fq -- '--archive-orbstack-data'
"$SCRIPT_DIR/clean-development-state.sh" --help | grep -Fq -- '--archive-rebuildable-caches'
"$SCRIPT_DIR/clean-development-state.sh" --help | grep -Fq -- '--resume-snapshot'
"$SCRIPT_DIR/clean-development-state.sh" --help | grep -Fq -- '--resume-cleanup'
"$SCRIPT_DIR/configure-cli-tools.sh" --help | grep -Fq 'This script only installs selected formulae'
"$SCRIPT_DIR/configure-macos-settings.sh" --help | grep -Fq 'Original scalar'
"$SCRIPT_DIR/configure-macos-settings.sh" --help | grep -Fq 'floating-point values'
grep -Fq 'OPTION_GROUPS=(' "$SCRIPT_DIR/configure-macos-settings.sh"
! grep -Eq '^GROUPS=' "$SCRIPT_DIR/configure-macos-settings.sh"
grep -Fq 'validate_option_catalog' "$SCRIPT_DIR/configure-macos-settings.sh"
"$SCRIPT_DIR/application-inventory.sh" --help | grep -Fq 'application bundles'
"$SCRIPT_DIR/application-status.sh" --help | grep -Fq 'company-managed'
grep -Fq 'application-provenance.md' "$SCRIPT_DIR/application-status.sh"
"$SCRIPT_DIR/application-status.sh" --help | grep -Fq -- '--app-install-policy MODE'
grep -Fq 'build_application_review_cache' "$SCRIPT_DIR/bootstrap-day-one-mac.sh"
"$SCRIPT_DIR/advanced-audit.sh" --help | grep -Fq 'read-only'
"$SCRIPT_DIR/advanced-setup.sh" --list > "$TEST_ROOT/advanced-list.txt"
grep -Fq '22  Shared AI skills and MCP operations' "$TEST_ROOT/advanced-list.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/advanced-setup.sh" --status > "$TEST_ROOT/advanced-status.txt"
grep -Fq '○ pending  15' "$TEST_ROOT/advanced-status.txt"
mkdir -p "$TEST_STATE_ROOT/completed"
: > "$TEST_STATE_ROOT/completed/08"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/advanced-setup.sh" --complete 15 --yes >/dev/null
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/advanced-setup.sh" --status > "$TEST_ROOT/advanced-current.txt"
grep -Fq '✓ current  15' "$TEST_ROOT/advanced-current.txt"
printf 'outdated-guide-fingerprint\n' > "$TEST_STATE_ROOT/advanced/completed/15"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/advanced-setup.sh" --status > "$TEST_ROOT/advanced-review.txt"
grep -Fq '⚠ review  15' "$TEST_ROOT/advanced-review.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/advanced-setup.sh" --reset 15 --yes >/dev/null
[[ ! -e "$TEST_STATE_ROOT/advanced/completed/15" ]]
"$SCRIPT_DIR/validate-warp-drive.sh" >/dev/null
! grep -Eq '(^|[[:space:]])diskutil([[:space:]]|$)|eraseDisk|rm[[:space:]]+-rf' \
  "$SCRIPT_DIR/rollback-recorded-setup.sh" "$SCRIPT_DIR/clean-development-state.sh" \
  "$SCRIPT_DIR/remove-day-one-mac.sh"

# The new removal coordinator is read-only by default, exposes ownership and
# repository risks, and keeps Developer content unless explicitly selected.
remove_home="$TEST_ROOT/remove-home"
remove_state="$remove_home/.day-one-mac"
mkdir -p "$remove_state" "$remove_home/Developer"
printf 'brew-formula\tfixture\n' > "$remove_state/install-manifest.tsv"
printf 'created\t%s/.fixture\t-\n' "$remove_home" > "$remove_state/path-manifest.tsv"
HOME="$remove_home" DAY_ONE_MAC_STATE_ROOT="$remove_state" \
  "$SCRIPT_DIR/remove-day-one-mac.sh" --mode preview > "$TEST_ROOT/remove-preview.txt"
grep -Fq 'Mode: preview' "$TEST_ROOT/remove-preview.txt"
grep -Fq 'Applications not owned by Homebrew are preserved.' "$TEST_ROOT/remove-preview.txt"
[[ -s "$remove_state/install-manifest.tsv" ]]
HOME="$remove_home" DAY_ONE_MAC_STATE_ROOT="$remove_state" \
  "$SCRIPT_DIR/remove-day-one-mac.sh" --mode sections \
    --sections developer --developer keep > "$TEST_ROOT/remove-developer-keep.txt"
grep -Fq 'Developer: keep' "$TEST_ROOT/remove-developer-keep.txt"
grep -Fq 'Preview only' "$TEST_ROOT/remove-developer-keep.txt"
[[ -d "$remove_home/Developer" ]]

remove_exec_home="$TEST_ROOT/remove-exec-home"
remove_exec_state="$remove_exec_home/.day-one-mac"
remove_exec_recovery="$TEST_ROOT/remove-exec-recovery"
mkdir -p "$remove_exec_home/Developer/example" "$remove_exec_state" "$remove_exec_recovery"
printf 'keep me\n' > "$remove_exec_home/Developer/example/file.txt"
: > "$remove_exec_state/install-manifest.tsv"
: > "$remove_exec_state/path-manifest.tsv"
HOME="$remove_exec_home" DAY_ONE_MAC_STATE_ROOT="$remove_exec_state" \
  "$SCRIPT_DIR/remove-day-one-mac.sh" --mode sections --sections developer \
    --developer selected --developer-path "$remove_exec_home/Developer/example" \
    --archive-root "$remove_exec_recovery" --execute --yes \
    > "$TEST_ROOT/remove-execute.txt"
[[ ! -e "$remove_exec_home/Developer/example" ]]
find "$remove_exec_recovery" -name file.txt -type f | grep -q .
grep -Fq 'selected removal completed' "$TEST_ROOT/remove-execute.txt"

remove_state_home="$TEST_ROOT/remove-state-home"
remove_state_dir="$remove_state_home/.day-one-mac"
remove_state_recovery="$TEST_ROOT/remove-state-recovery"
mkdir -p "$remove_state_home/Developer" "$remove_state_home/.local/bin" \
  "$remove_state_dir" "$remove_state_recovery"
: > "$remove_state_dir/install-manifest.tsv"
: > "$remove_state_dir/path-manifest.tsv"
printf '#!/usr/bin/env bash\n' > "$remove_state_home/.local/bin/day-one-mac"
chmod +x "$remove_state_home/.local/bin/day-one-mac"
HOME="$remove_state_home" DAY_ONE_MAC_STATE_ROOT="$remove_state_dir" \
  "$SCRIPT_DIR/remove-day-one-mac.sh" --mode sections --sections state \
    --archive-root "$remove_state_recovery" --execute --yes \
    > "$TEST_ROOT/remove-state.txt"
[[ ! -e "$remove_state_dir" ]]
[[ ! -e "$remove_state_home/.local/bin/day-one-mac" ]]
find "$remove_state_recovery" -path '*/commands/day-one-mac' -type f | grep -q .

# Post-setup finalisation is preview-first. Compact mode preserves operational
# state; detach mode requires the Warp acknowledgement and moves all state and
# the portable command into a separately reviewable recovery directory.
finalize_home="$TEST_ROOT/finalize-home"
finalize_state="$finalize_home/.day-one-mac"
mkdir -p "$finalize_state/completed" "$finalize_state/originals" \
  "$finalize_state/completed-old" "$finalize_home/.local/bin"
printf 'phase-08-fingerprint\n' > "$finalize_state/completed/08"
printf '| Gate | Result |\n|---|---|\n| Fixture | PASS |\n' > "$finalize_state/verification.md"
printf 'formula\tfixture\n' > "$finalize_state/install-manifest.tsv"
printf 'created\t%s/example\t-\n' "$finalize_home" > "$finalize_state/path-manifest.tsv"
printf 'original fixture\n' > "$finalize_state/originals/example"
printf 'setup fixture\n' > "$finalize_state/setup.log"
printf 'old progress fixture\n' > "$finalize_state/completed-old/01"
printf '#!/usr/bin/env bash\n' > "$finalize_home/.local/bin/day-one-mac"
chmod +x "$finalize_home/.local/bin/day-one-mac"

HOME="$finalize_home" DAY_ONE_MAC_STATE_ROOT="$finalize_state" \
  "$SCRIPT_DIR/finalize-setup.sh" > "$TEST_ROOT/finalize-preview.txt"
grep -Fq 'Preview only' "$TEST_ROOT/finalize-preview.txt"
[[ ! -e "$finalize_state/finalized-at" ]]
[[ -d "$finalize_state/completed-old" ]]

HOME="$finalize_home" DAY_ONE_MAC_STATE_ROOT="$finalize_state" \
  "$SCRIPT_DIR/finalize-setup.sh" --execute --yes > "$TEST_ROOT/finalize-execute.txt"
[[ -s "$finalize_state/finalized-at" ]]
[[ -s "$finalize_state/finalization.md" ]]
grep -Fq 'FINALIZED evidence=' "$finalize_state/setup.log"
[[ ! -e "$finalize_state/completed-old" ]]
finalize_archives=("$finalize_state"/finalized/Day-One-Mac-Finalization-*)
[[ -s "${finalize_archives[0]}/evidence.tar.gz" ]]
(cd "${finalize_archives[0]}" && shasum -a 256 -c SHA256SUMS.txt >/dev/null)

HOME="$finalize_home" DAY_ONE_MAC_STATE_ROOT="$finalize_state" \
  "$SCRIPT_DIR/finalize-setup.sh" --status > "$TEST_ROOT/finalize-status.txt"
grep -Fq 'Phase 8 completion is recorded' "$TEST_ROOT/finalize-status.txt"
grep -Fq 'Finalised:' "$TEST_ROOT/finalize-status.txt"

detach_home="$TEST_ROOT/detach-home"
detach_state="$detach_home/.day-one-mac"
detach_recovery="$detach_home/recovery"
mkdir -p "$detach_state/completed" "$detach_state/originals" \
  "$detach_home/.local/bin" "$detach_recovery"
printf 'phase-08-fingerprint\n' > "$detach_state/completed/08"
printf '| Gate | Result |\n|---|---|\n| Fixture | PASS |\n' > "$detach_state/verification.md"
printf 'formula\tfixture\n' > "$detach_state/install-manifest.tsv"
printf 'created\t%s/example\t-\n' "$detach_home" > "$detach_state/path-manifest.tsv"
printf 'setup fixture\n' > "$detach_state/setup.log"
printf '#!/usr/bin/env bash\n' > "$detach_home/.local/bin/day-one-mac"
chmod +x "$detach_home/.local/bin/day-one-mac"

if HOME="$detach_home" DAY_ONE_MAC_STATE_ROOT="$detach_state" \
  "$SCRIPT_DIR/finalize-setup.sh" --detach --execute --yes \
  --archive-root "$detach_recovery" > "$TEST_ROOT/detach-without-warp.txt" 2>&1; then
  printf 'FAIL: detachment ran without --warp-handled\n' >&2
  exit 1
fi
grep -Fq 'Detach requires --warp-handled' "$TEST_ROOT/detach-without-warp.txt"
[[ -d "$detach_state" ]]
[[ -x "$detach_home/.local/bin/day-one-mac" ]]

HOME="$detach_home" DAY_ONE_MAC_STATE_ROOT="$detach_state" \
  "$SCRIPT_DIR/finalize-setup.sh" --detach --warp-handled --execute --yes \
  --archive-root "$detach_recovery" > "$TEST_ROOT/detach-execute.txt"
[[ ! -e "$detach_state" ]]
[[ ! -e "$detach_home/.local/bin/day-one-mac" ]]
detach_archives=("$detach_recovery"/Day-One-Mac-Detached-*)
[[ -s "${detach_archives[0]}/DETACHED.md" ]]
[[ -d "${detach_archives[0]}/day-one-mac-state" ]]
[[ -s "${detach_archives[0]}/day-one-mac-command" ]]
(cd "${detach_archives[0]}" && shasum -a 256 -c SHA256SUMS.txt >/dev/null)

dry_output="$TEST_ROOT/dry-run.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --dry-run --track 3 --stack both \
  --name 'Test User' --email test@example.com --yes > "$dry_output"
grep -Fq 'Day One Mac guided setup — 8 required phases' "$dry_output"
grep -Fq 'Optional databases, AI, MCP and VS Code profiles are not run here.' "$dry_output"
grep -Fq 'Phase 08 — Verify and reproduce' "$dry_output"
grep -Fq 'preview record compaction with: day-one-mac finalize' "$dry_output"
grep -Fq '$ '"$SCRIPT_DIR"'/validate.sh' "$dry_output"
grep -Fq 'would require a clean, pushed, private GitHub or Azure DevOps dotfiles origin' "$dry_output"
grep -Fq 'would run the optional macOS Settings Wizard before Phase 2' "$dry_output"
grep -Fq '$ '"$SCRIPT_DIR"'/configure-macos-settings.sh --wizard' "$dry_output"
grep -Fq '$ brew install starship' "$dry_output"
grep -Fq '$ brew install ghq' "$dry_output"
grep -Fq '$ brew install gh' "$dry_output"
grep -Fq '$ brew install azure-cli' "$dry_output"
grep -Fq '$ brew install pnpm' "$dry_output"
grep -Fq '$ brew install --cask font-jetbrains-mono-nerd-font' "$dry_output"
grep -Fq '$ brew install --cask raycast' "$dry_output"
grep -Fq '$ brew install --cask visual-studio-code' "$dry_output"
grep -Fq '$ brew install --cask warp' "$dry_output"
grep -Fq 'would ask whether to use Homebrew or another approved installer' "$dry_output"
ownership_line="$(grep -n -m1 'Application ownership — no changes yet' "$dry_output" | cut -d: -f1)"
formula_line="$(grep -n -m1 '\$ brew install chezmoi' "$dry_output" | cut -d: -f1)"
[[ -n "$ownership_line" && -n "$formula_line" && "$ownership_line" -lt "$formula_line" ]]
warp_scan_line="$(grep -n -m1 'Warp — missing' "$dry_output" | cut -d: -f1)"
phase4_cask_line="$(grep -n -m1 '\$ brew install --cask font-jetbrains-mono-nerd-font' "$dry_output" | cut -d: -f1)"
[[ -n "$warp_scan_line" && -n "$phase4_cask_line" && "$warp_scan_line" -lt "$phase4_cask_line" ]]
grep -Fq "would write $TEST_HOME/.config/chezmoi/chezmoi.toml" "$dry_output"
grep -Fq "would write $TEST_HOME/.config/starship.toml" "$dry_output"
grep -Fq "would write $TEST_HOME/.local/bin/day-one-mac" "$dry_output"
grep -Fq '$ pnpm --version' "$dry_output"
grep -Fq "$ mkdir -p $TEST_HOME/Library/pnpm" "$dry_output"
! grep -Fq '$ corepack enable' "$dry_output"
[[ ! -e "$TEST_STATE_ROOT/track" ]]

check_only_output="$TEST_ROOT/check-only-dry-run.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --dry-run --track 1 --stack node \
  --name 'Test User' --email test@example.com --app-install-policy check-only \
  > "$check_only_output"
grep -Fq 'check-only policy would stop with' "$check_only_output"
! grep -Fq '$ brew install --cask' "$check_only_output"

settings_preview="$TEST_ROOT/macos-settings-preview.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/configure-macos-settings.sh" --preview > "$settings_preview"
grep -Fq 'Security review — never changed automatically' "$settings_preview"
grep -Fq 'Show all filename extensions' "$settings_preview"
[[ ! -e "$TEST_STATE_ROOT/macos-settings-status" ]]

settings_bin="$TEST_ROOT/settings-bin"
settings_defaults_state="$TEST_ROOT/defaults-value"
mkdir -p "$settings_bin" "$TEST_STATE_ROOT"
printf '0\n' > "$settings_defaults_state"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'case "$1" in' \
  '  read-type) printf "Type is %s\\n" "${TEST_DEFAULTS_TYPE:-boolean}" ;;' \
  '  read) sed -n "1p" "$TEST_DEFAULTS_STATE" ;;' \
  '  write)' \
  '    value="${!#}"' \
  '    if [[ "$4" == -bool && "$value" != true && "$value" != false ]]; then exit 64; fi' \
  '    printf "%s\\n" "$value" > "$TEST_DEFAULTS_STATE"' \
  '    ;;' \
  '  delete) : > "$TEST_DEFAULTS_STATE" ;;' \
  '  *) exit 2 ;;' \
  'esac' > "$settings_bin/defaults"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$settings_bin/killall"
chmod +x "$settings_bin/defaults" "$settings_bin/killall"
printf 'finder-extensions\n' > "$TEST_STATE_ROOT/macos-settings-selection"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  TEST_DEFAULTS_STATE="$settings_defaults_state" PATH="$settings_bin:$PATH" \
  "$SCRIPT_DIR/configure-macos-settings.sh" --apply --yes > "$TEST_ROOT/macos-settings-apply.txt"
grep -Fxq 'true' "$settings_defaults_state"
grep -Fxq 'completed' "$TEST_STATE_ROOT/macos-settings-status"
grep -Fq $'NSGlobalDomain\tAppleShowAllExtensions\tbool\t0' \
  "$TEST_STATE_ROOT/macos-settings/original-values.tsv"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  TEST_DEFAULTS_STATE="$settings_defaults_state" PATH="$settings_bin:$PATH" \
  "$SCRIPT_DIR/configure-macos-settings.sh" --restore --yes > "$TEST_ROOT/macos-settings-restore.txt"
grep -Fxq 'false' "$settings_defaults_state"
grep -Fxq 'restored' "$TEST_STATE_ROOT/macos-settings-status"

# macOS 27 stores the Dock tile size as a float. Confirm that it can be
# captured, changed, verified and restored without touching real preferences.
rm -rf "$TEST_STATE_ROOT/macos-settings"
printf 'dock-size\n' > "$TEST_STATE_ROOT/macos-settings-selection"
printf '64.0\n' > "$settings_defaults_state"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  TEST_DEFAULTS_TYPE=float TEST_DEFAULTS_STATE="$settings_defaults_state" PATH="$settings_bin:$PATH" \
  "$SCRIPT_DIR/configure-macos-settings.sh" --apply --yes > "$TEST_ROOT/macos-settings-float-apply.txt"
grep -Fxq '44' "$settings_defaults_state"
grep -Fq $'com.apple.dock\ttilesize\tfloat\t64.0' \
  "$TEST_STATE_ROOT/macos-settings/original-values.tsv"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  TEST_DEFAULTS_TYPE=float TEST_DEFAULTS_STATE="$settings_defaults_state" PATH="$settings_bin:$PATH" \
  "$SCRIPT_DIR/configure-macos-settings.sh" --restore --yes > "$TEST_ROOT/macos-settings-float-restore.txt"
grep -Fxq '64.0' "$settings_defaults_state"
grep -Fxq 'restored' "$TEST_STATE_ROOT/macos-settings-status"

settings_skip="$TEST_ROOT/macos-settings-skip.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --dry-run --track 1 --stack node \
  --name 'Test User' --email test@example.com --new-dotfiles \
  --skip-macos-settings --yes > "$settings_skip"
grep -Fq 'Early macOS settings were intentionally skipped' "$settings_skip"
! grep -Fq 'would run the optional macOS Settings Wizard before Phase 2' "$settings_skip"

local_dotfiles_output="$TEST_ROOT/local-dotfiles.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --dry-run --track 1 --stack node \
  --name 'Test User' --email test@example.com --local-dotfiles --yes > "$local_dotfiles_output"
grep -Fq '$ chezmoi init' "$local_dotfiles_output"
grep -Fq 'would verify the local-only chezmoi source and skip Git remote requirements' "$local_dotfiles_output"
! grep -Fq 'would require a clean, pushed, private GitHub or Azure DevOps dotfiles origin' "$local_dotfiles_output"

track_output="$TEST_ROOT/track-2-python.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --dry-run --track 2 --stack python \
  --name 'Test User' --email test@example.com --yes > "$track_output"
grep -Fq '$ brew install azure-cli' "$track_output"
grep -Fq '$ brew install uv' "$track_output"
grep -Fq '$ brew install starship' "$track_output"
! grep -Fq '$ brew install gh' "$track_output"
! grep -Fq '$ brew install fnm' "$track_output"
! grep -Fq '$ brew install pnpm' "$track_output"

legacy_home="$TEST_ROOT/legacy-home"
mkdir -p "$legacy_home/.fresh-mac-setup"
printf '2\n' > "$legacy_home/.fresh-mac-setup/track"
if HOME="$legacy_home" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --dry-run --yes > "$TEST_ROOT/legacy-track.txt" 2>&1; then
  printf 'FAIL: runner silently reinterpreted a pre-schema track\n' >&2
  exit 1
fi
grep -Fq 'saved track predates the current track numbering' "$TEST_ROOT/legacy-track.txt"

compat_home="$TEST_ROOT/compat-home"
compat_state="$compat_home/custom-old-state"
mkdir -p "$compat_state"
HOME="$compat_home" FRESH_START_STATE_ROOT="$compat_state" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --status > "$TEST_ROOT/compat-state.txt"
grep -Fq "State: $compat_state" "$TEST_ROOT/compat-state.txt"

if HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --phase 09 --dry-run >/dev/null 2>&1; then
  printf 'FAIL: invalid day-one-mac Phase 09 was accepted\n' >&2
  exit 1
fi

failure_output="$TEST_ROOT/failed-phase.txt"
if HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --phase 04 --track 1 --stack node --yes \
  > "$failure_output" 2>&1; then
  printf 'FAIL: Phase 04 passed without the Phase 1 Git identity\n' >&2
  exit 1
fi
grep -Fq 'this phase was not marked complete' "$failure_output"
grep -Fq 'Completed in this attempt:' "$failure_output"
grep -Fq 'Still required:' "$failure_output"
grep -Fq 'Required Installation Centre' "$failure_output"
grep -Fq 'Next action:' "$failure_output"
[[ ! -e "$TEST_STATE/completed/04" ]]

status_output="$TEST_ROOT/status.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --status > "$status_output"
grep -Fq 'Track: 1' "$status_output"
grep -Fq 'Stack: node' "$status_output"
grep -Fq '○ pending  01' "$status_output"
grep -Fq 'Optional plan: none' "$status_output"

wizard_error="$TEST_ROOT/wizard-needs-terminal.txt"
if HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --wizard \
  </dev/null > "$wizard_error" 2>&1; then
  printf 'FAIL: wizard accepted a non-interactive terminal\n' >&2
  exit 1
fi
grep -Fq 'wizard requires an interactive terminal' "$wizard_error"

if "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --wizard --track 1 \
  > "$TEST_ROOT/wizard-mixed-options.txt" 2>&1; then
  printf 'FAIL: wizard silently ignored a direct setup option\n' >&2
  exit 1
fi
grep -Fq 'choose track, stack, identity and dotfiles inside the wizard' \
  "$TEST_ROOT/wizard-mixed-options.txt"

printf '%s\n' 'git@example.com:person/dotfiles.git' > "$TEST_STATE_ROOT/dotfiles-repo"
new_dotfiles_output="$TEST_ROOT/new-dotfiles.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/bootstrap-day-one-mac.sh" --phase 05 --dry-run --track 1 --stack node \
  --name 'Test User' --email test@example.com --new-dotfiles --yes > "$new_dotfiles_output"
grep -Fq '$ chezmoi init' "$new_dotfiles_output"
! grep -Fq 'person/dotfiles.git' "$new_dotfiles_output"

printf 'fresh value\n' > "$TEST_HOME/.zshrc"
printf 'changed value\n' > "$TEST_HOME/.gitconfig"
printf 'original value\n' > "$TEST_STATE/originals/gitconfig"
mkdir -p "$TEST_HOME/Developer/_sandbox"
printf 'keep me\n' > "$TEST_HOME/Developer/_sandbox/project.txt"
mkdir -p "$TEST_HOME/.empty-parent"
: > "$TEST_STATE/install-manifest.tsv"
{
  printf 'created\t%s\t-\n' "$TEST_HOME/.zshrc"
  printf 'modified\t%s\t%s\n' "$TEST_HOME/.gitconfig" "$TEST_STATE/originals/gitconfig"
  printf 'created-dir\t%s\t-\n' "$TEST_HOME/Developer"
  printf 'created-dir\t%s\t-\n' "$TEST_HOME/Developer/_sandbox"
  printf 'created-dir\t%s\t-\n' "$TEST_HOME/.empty-parent"
} > "$TEST_STATE/path-manifest.tsv"

preview_output="$TEST_ROOT/cleanup-preview.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/rollback-recorded-setup.sh" > "$preview_output"
grep -Fq 'Preview only.' "$preview_output"
grep -Fq "$TEST_HOME/.zshrc" "$preview_output"
[[ -f "$TEST_HOME/.zshrc" ]]

full_preview_output="$TEST_ROOT/clean-development-preview.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/clean-development-state.sh" > "$full_preview_output"
grep -Fq 'Disk erase/format: never' "$full_preview_output"
grep -Fq 'Non-Homebrew applications: preserved' "$full_preview_output"
grep -Fq 'Preview only.' "$full_preview_output"
grep -Fq 'All application bundles discovered' "$full_preview_output"

mkdir -p "$TEST_HOME/Library/Containers/com.docker.docker" "$TEST_HOME/.orbstack"
printf 'docker fixture\n' > "$TEST_HOME/Library/Containers/com.docker.docker/state.txt"
printf 'orbstack fixture\n' > "$TEST_HOME/.orbstack/state.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/clean-development-state.sh" --archive-docker-data \
  > "$TEST_ROOT/docker-only-preview.txt"
grep -Fq "ARCHIVE: $TEST_HOME/Library/Containers/com.docker.docker" "$TEST_ROOT/docker-only-preview.txt"
grep -Fq 'KEEP: OrbStack data' "$TEST_ROOT/docker-only-preview.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/clean-development-state.sh" --archive-orbstack-data \
  > "$TEST_ROOT/orbstack-only-preview.txt"
grep -Fq "ARCHIVE: $TEST_HOME/.orbstack" "$TEST_ROOT/orbstack-only-preview.txt"
grep -Fq 'KEEP: Docker Desktop data' "$TEST_ROOT/orbstack-only-preview.txt"

snapshot_parent="$TEST_ROOT/backup-snapshots"
snapshot_result="$TEST_ROOT/backup-snapshot-result"
mkdir -p "$snapshot_parent"
mkdir -p "$TEST_HOME/.codex/ipc"
mkdir -p "$TEST_HOME/Library/pnpm" "$TEST_HOME/Library/Application Support/Code/User" \
  "$TEST_HOME/Library/Application Support/Code/CachedData"
printf 'rebuildable pnpm store data\n' > "$TEST_HOME/Library/pnpm/store.bin"
printf '{"editor.fontSize": 13}\n' > "$TEST_HOME/Library/Application Support/Code/User/settings.json"
printf 'rebuildable VS Code cache\n' > "$TEST_HOME/Library/Application Support/Code/CachedData/cache.bin"
printf 'restorable Codex setting\n' > "$TEST_HOME/.codex/settings.json"
mkfifo "$TEST_HOME/.codex/ipc/events.fifo"
restricted_codex_cache="$TEST_HOME/.codex/.tmp/plugins/.git/objects/pack/pack-test.idx"
mkdir -p "$(dirname "$restricted_codex_cache")"
printf 'rebuildable temporary cache\n' > "$restricted_codex_cache"
chmod 000 "$restricted_codex_cache"
vendor_skill_file="$TEST_HOME/.codex/vendor_imports/skills/example-skill/SKILL.md"
restricted_vendor_metadata="$TEST_HOME/.codex/vendor_imports/skills/.git/objects/pack/pack-test.idx"
mkdir -p "$(dirname "$vendor_skill_file")" "$(dirname "$restricted_vendor_metadata")"
printf '# Imported skill working file\n' > "$vendor_skill_file"
printf 'rebuildable vendor Git metadata\n' > "$restricted_vendor_metadata"
chmod 000 "$restricted_vendor_metadata"
/usr/bin/nc -lU "$TEST_HOME/.codex/ipc/ipc.sock" > "$TEST_ROOT/socket-listener.log" 2>&1 &
SOCKET_LISTENER_PID=$!
for socket_wait in 1 2 3 4 5 6 7 8 9 10; do
  [[ -S "$TEST_HOME/.codex/ipc/ipc.sock" ]] && break
  sleep 0.1
done
if [[ -S "$TEST_HOME/.codex/ipc/ipc.sock" ]]; then
  SOCKET_TEST_SUPPORTED=1
else
  kill "$SOCKET_LISTENER_PID" 2>/dev/null || true
  wait "$SOCKET_LISTENER_PID" 2>/dev/null || true
  SOCKET_LISTENER_PID=""
fi
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$SCRIPT_DIR/clean-development-state.sh" --backup-only --yes \
  --archive-root "$snapshot_parent" --result-file "$snapshot_result" \
  > "$TEST_ROOT/backup-only.txt"
snapshot_dir="$(sed -n '1p' "$snapshot_result")"
[[ "$snapshot_dir" == "$snapshot_parent"/Day-One-Mac-Backup-Snapshot-* ]]
[[ -f "$snapshot_dir/home/.zshrc" ]]
[[ -f "$snapshot_dir/home/.codex/settings.json" ]]
[[ -f "$snapshot_dir/home/Library/Application Support/Code/User/settings.json" ]]
[[ ! -e "$snapshot_dir/home/Library/Application Support/Code/CachedData" ]]
[[ ! -e "$snapshot_dir/home/Library/pnpm" ]]
[[ -f "$snapshot_dir/reinstall-inventories/pnpm-global-packages.md" ]]
[[ -f "$snapshot_dir/reinstall-inventories/vscode-extensions.md" ]]
[[ ! -e "$snapshot_dir/home/.codex/ipc/events.fifo" ]]
if [[ "$SOCKET_TEST_SUPPORTED" == 1 ]]; then
  [[ ! -e "$snapshot_dir/home/.codex/ipc/ipc.sock" ]]
fi
[[ ! -e "$snapshot_dir/home/.codex/.tmp" ]]
[[ -f "$snapshot_dir/home/.codex/vendor_imports/skills/example-skill/SKILL.md" ]]
[[ ! -e "$snapshot_dir/home/.codex/vendor_imports/skills/.git" ]]
[[ -f "$TEST_HOME/.zshrc" ]]
grep -Fqx 'fresh value' "$TEST_HOME/.zshrc"
grep -Fq $'copy\t' "$snapshot_dir/operations.tsv"
grep -Fq $'skip-transient-pipe\t' "$snapshot_dir/operations.tsv"
if [[ "$SOCKET_TEST_SUPPORTED" == 1 ]]; then
  grep -Fq $'skip-transient-socket\t' "$snapshot_dir/operations.tsv"
fi
grep -Fq $'skip-transient-cache\t' "$snapshot_dir/operations.tsv"
grep -Fq $'skip-transient-metadata\t' "$snapshot_dir/operations.tsv"
if [[ "$SOCKET_TEST_SUPPORTED" == 1 ]]; then
  grep -Fq "$TEST_HOME/.codex/ipc/ipc.sock" "$snapshot_dir/transient-items-skipped.md"
fi
grep -Fq "$TEST_HOME/.codex/.tmp" "$snapshot_dir/transient-items-skipped.md"
grep -Fq "$TEST_HOME/.codex/ipc/events.fifo" "$snapshot_dir/transient-items-skipped.md"
grep -Fq 'named process pipe; contains no restorable data' "$snapshot_dir/transient-items-skipped.md"
grep -Fq "$TEST_HOME/.codex/vendor_imports/skills/.git" "$snapshot_dir/transient-items-skipped.md"
grep -Fq 'Codex temporary runtime/plugin cache; rebuilt automatically' "$snapshot_dir/transient-items-skipped.md"
grep -Fq 'imported skill working files were copied' "$snapshot_dir/transient-items-skipped.md"
grep -Fq 'starting copy:' "$TEST_ROOT/backup-only.txt"
grep -Fq 'source files, applications' "$snapshot_dir/README.md"
grep -Fq 'explicitly recognised rebuildable caches' "$snapshot_dir/README.md"
[[ ! -e "$snapshot_dir/INCOMPLETE.md" ]]
[[ -s "$snapshot_dir/SNAPSHOT-COMPLETE" ]]
(cd "$snapshot_dir" && shasum -a 256 -c SHA256SUMS.txt >/dev/null)
chmod 600 "$restricted_codex_cache"
chmod 600 "$restricted_vendor_metadata"
if [[ -n "$SOCKET_LISTENER_PID" ]]; then
  kill "$SOCKET_LISTENER_PID" 2>/dev/null || true
  wait "$SOCKET_LISTENER_PID" 2>/dev/null || true
fi
SOCKET_LISTENER_PID=""

# A copy-complete snapshot with an interrupted legacy checksum pass resumes
# without copying source data again and receives the new completion marker.
resume_parent="$TEST_ROOT/resume-snapshots"
resume_dir="$resume_parent/Day-One-Mac-Backup-Snapshot-resume-fixture"
resume_result="$TEST_ROOT/resume-result"
resume_progress="$TEST_ROOT/resume-progress"
mkdir -p "$resume_parent"
/usr/bin/ditto "$snapshot_dir" "$resume_dir"
rm -f "$resume_dir/SNAPSHOT-COMPLETE"
printf '# Interrupted fixture\n' > "$resume_dir/INCOMPLETE.md"
printf '%s\nfixture-scope\n' "$resume_dir" > "$resume_progress"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$SCRIPT_DIR/clean-development-state.sh" --backup-only --yes \
  --archive-root "$resume_parent" --resume-snapshot "$resume_dir" \
  --in-progress-file "$resume_progress" --result-file "$resume_result" \
  > "$TEST_ROOT/resume-output.txt"
[[ "$(sed -n '1p' "$resume_result")" == "$resume_dir" ]]
[[ ! -e "$resume_dir/INCOMPLETE.md" ]]
[[ ! -e "$resume_progress" ]]
[[ -s "$resume_dir/SNAPSHOT-COMPLETE" ]]
grep -Fq 'copied source data was reused' "$TEST_ROOT/resume-output.txt"
(cd "$resume_dir" && shasum -a 256 -c SHA256SUMS.txt >/dev/null)

# A checksum interrupted under the new batching format continues after its
# last atomically completed batch rather than hashing those files again.
sed 's/^[0-9a-f][0-9a-f]*  //' "$resume_dir/SHA256SUMS.txt" \
  | tr '\n' '\000' > "$resume_dir/.checksum-files.nul"
shasum -a 256 "$resume_dir/.checksum-files.nul" | awk '{print $1}' \
  > "$resume_dir/.checksum-files.nul.sha256"
sed -n '1,3p' "$resume_dir/SHA256SUMS.txt" > "$resume_dir/.SHA256SUMS.partial"
rm -f "$resume_dir/SHA256SUMS.txt" "$resume_dir/SNAPSHOT-COMPLETE"
printf '# Interrupted batched fixture\n' > "$resume_dir/INCOMPLETE.md"
printf '%s\nfixture-scope\n' "$resume_dir" > "$resume_progress"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$SCRIPT_DIR/clean-development-state.sh" --backup-only --yes \
  --archive-root "$resume_parent" --resume-snapshot "$resume_dir" \
  --in-progress-file "$resume_progress" --result-file "$resume_result" \
  > "$TEST_ROOT/batched-resume-output.txt"
grep -Fq 'resuming at file 4; 3 checksum(s) are already complete' "$TEST_ROOT/batched-resume-output.txt"
[[ -s "$resume_dir/SNAPSHOT-COMPLETE" ]]
(cd "$resume_dir" && shasum -a 256 -c SHA256SUMS.txt >/dev/null)

# The optional offline-style snapshot includes the otherwise rebuildable data.
cache_snapshot_parent="$TEST_ROOT/cache-snapshots"
cache_snapshot_result="$TEST_ROOT/cache-snapshot-result"
mkdir -p "$cache_snapshot_parent"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$SCRIPT_DIR/clean-development-state.sh" --backup-only --yes \
  --archive-rebuildable-caches --archive-root "$cache_snapshot_parent" \
  --result-file "$cache_snapshot_result" > "$TEST_ROOT/cache-snapshot-output.txt"
cache_snapshot_dir="$(sed -n '1p' "$cache_snapshot_result")"
[[ -f "$cache_snapshot_dir/home/Library/pnpm/store.bin" ]]
[[ -f "$cache_snapshot_dir/home/Library/Application Support/Code/CachedData/cache.bin" ]]
[[ -s "$cache_snapshot_dir/SNAPSHOT-COMPLETE" ]]

# Final cleanup moves display an immediate workload summary and per-item
# progress even when a small fixture finishes before the first heartbeat.
progress_home="$TEST_ROOT/archive-progress-home"
progress_state="$progress_home/.state"
progress_parent="$TEST_ROOT/archive-progress-recovery"
mkdir -p "$progress_home/.config/mcp" "$progress_state" "$progress_parent"
printf 'progress fixture\n' > "$progress_home/.zshrc"
printf '{"servers":{}}\n' > "$progress_home/.config/mcp/config.json"
HOME="$progress_home" DAY_ONE_MAC_STATE_ROOT="$progress_state" \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$SCRIPT_DIR/clean-development-state.sh" --execute --yes \
  --archive-root "$progress_parent" > "$TEST_ROOT/archive-progress-output.txt"
grep -Fq 'Step 5 archive progress' "$TEST_ROOT/archive-progress-output.txt"
grep -Fq 'estimated time remaining' "$TEST_ROOT/archive-progress-output.txt"
grep -Fq 'archive item 1/2:' "$TEST_ROOT/archive-progress-output.txt"
grep -Fq 'archive progress: item 2/2' "$TEST_ROOT/archive-progress-output.txt"
[[ ! -e "$progress_home/.zshrc" ]]
[[ ! -e "$progress_home/.config/mcp" ]]
progress_recovery_dirs=("$progress_parent"/Day-One-Mac-Clean-Recovery-*)
[[ -f "${progress_recovery_dirs[0]}/home/.zshrc" ]]
[[ -f "${progress_recovery_dirs[0]}/home/.config/mcp/config.json" ]]
[[ ! -e "${progress_recovery_dirs[0]}/INCOMPLETE.md" ]]

# Final cleanup must not run inside Warp because the same operation may remove
# the Warp cask and terminate its own terminal session part-way through.
warp_guard_home="$TEST_ROOT/warp-guard-home"
warp_guard_parent="$TEST_ROOT/warp-guard-recovery"
mkdir -p "$warp_guard_home" "$warp_guard_parent"
printf 'must remain in place\n' > "$warp_guard_home/.zshrc"
if HOME="$warp_guard_home" TERM_PROGRAM=WarpTerminal \
  DAY_ONE_MAC_STATE_ROOT="$warp_guard_home/.state" \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$SCRIPT_DIR/clean-development-state.sh" --execute --yes \
  --archive-root "$warp_guard_parent" > "$TEST_ROOT/warp-guard-output.txt" 2>&1; then
  printf 'FAIL: Step 5 cleanup ran inside Warp\n' >&2
  exit 1
fi
grep -Fq 'Step 5 cannot run inside Warp' "$TEST_ROOT/warp-guard-output.txt"
grep -Fq 'open Apple Terminal' "$TEST_ROOT/warp-guard-output.txt"
[[ -f "$warp_guard_home/.zshrc" ]]
warp_guard_recoveries=("$warp_guard_parent"/Day-One-Mac-Clean-Recovery-*)
[[ ! -e "${warp_guard_recoveries[0]}" ]]

# Step 5 may be launched while the terminal is inside a repository under
# ~/Developer. Homebrew must run from the external recovery folder before that
# project and the wizard state are moved; otherwise every brew call fails with
# "The current working directory must exist" and the dashboard loses its state.
ordering_home="$TEST_ROOT/cleanup-order-home"
ordering_state="$ordering_home/.day-one-mac"
ordering_parent="$TEST_ROOT/cleanup-order-recovery"
ordering_log="$TEST_ROOT/fake-homebrew.log"
ordering_brew_state="$TEST_ROOT/fake-homebrew-state"
fake_homebrew_bin="$SCRIPT_DIR/tests/fixtures/fake-homebrew/bin"
mkdir -p "$ordering_home/Developer/project" \
  "$ordering_home/Library/Application Support/Code" "$ordering_state" \
  "$ordering_parent" "$ordering_brew_state"
printf 'project fixture\n' > "$ordering_home/Developer/project/README.md"
printf 'saved wizard state\n' > "$ordering_state/progress"
printf 'shell fixture\n' > "$ordering_home/.zshrc"
printf 'original VS Code data\n' > "$ordering_home/Library/Application Support/Code/original.txt"
(
  cd "$ordering_home/Developer/project"
  HOME="$ordering_home" DAY_ONE_MAC_STATE_ROOT="$ordering_state" \
    DAY_ONE_TEST_BREW_LOG="$ordering_log" \
    DAY_ONE_TEST_BREW_STATE="$ordering_brew_state" \
    PATH="$fake_homebrew_bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$SCRIPT_DIR/clean-development-state.sh" --execute --yes \
    --archive-projects --archive-root "$ordering_parent" \
    > "$TEST_ROOT/cleanup-order-output.txt"
)
ordering_recovery_dirs=("$ordering_parent"/Day-One-Mac-Clean-Recovery-*)
ordering_recovery="${ordering_recovery_dirs[0]}"
ordering_recovery_physical="$(cd "$ordering_recovery" && pwd -P)"
grep -Fq $'brew-uninstall\t'"$ordering_recovery_physical" "$ordering_log"
grep -Fq $'homebrew-uninstaller\t'"$ordering_recovery_physical" "$ordering_log"
[[ ! -e "$ordering_home/Developer" ]]
[[ ! -e "$ordering_home/.day-one-mac" ]]
[[ -f "$ordering_recovery/home/Developer/project/README.md" ]]
[[ -f "$ordering_recovery/home/.day-one-mac/progress" ]]
[[ -f "$ordering_recovery/home/Library/Application Support/Code/original.txt" ]]
[[ -s "$ordering_recovery/cleanup-options.tsv" ]]
[[ -s "$ordering_recovery/SNAPSHOT-COMPLETE" ]]
[[ ! -e "$ordering_recovery/INCOMPLETE.md" ]]

# Newer incomplete recoveries refuse a resume command whose safety options do
# not match the options captured before the original cleanup started.
mismatch_cleanup="$ordering_parent/Day-One-Mac-Clean-Recovery-option-mismatch"
/usr/bin/ditto "$ordering_recovery" "$mismatch_cleanup"
rm -f "$mismatch_cleanup/SNAPSHOT-COMPLETE"
printf '# Interrupted cleanup fixture\n' > "$mismatch_cleanup/INCOMPLETE.md"
if HOME="$ordering_home" DAY_ONE_MAC_STATE_ROOT="$ordering_state" \
  DAY_ONE_TEST_BREW_LOG="$ordering_log" \
  DAY_ONE_TEST_BREW_STATE="$ordering_brew_state" \
  PATH="$fake_homebrew_bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  "$SCRIPT_DIR/clean-development-state.sh" --execute --yes \
  --resume-cleanup "$mismatch_cleanup" \
  > "$TEST_ROOT/cleanup-resume-mismatch.txt" 2>&1; then
  printf 'FAIL: cleanup resume accepted options that differ from cleanup-options.tsv\n' >&2
  exit 1
fi
grep -Fq 'do not match the options saved by the interrupted cleanup' \
  "$TEST_ROOT/cleanup-resume-mismatch.txt"

# A guarded resume reuses an incomplete cleanup folder, recognises casks that
# were already removed, and completes checksums without creating a second
# recovery directory or trying to move absent sources again.
resume_cleanup="$ordering_parent/Day-One-Mac-Clean-Recovery-resume-fixture"
/usr/bin/ditto "$ordering_recovery" "$resume_cleanup"
rm -f "$resume_cleanup/SNAPSHOT-COMPLETE" "$resume_cleanup/cleanup-options.tsv"
printf '# Interrupted cleanup fixture\n' > "$resume_cleanup/INCOMPLETE.md"
printf '2026-01-01T00:00:00Z\tuninstall-cask\told-failed-app\t-\tfailed\n' \
  >> "$resume_cleanup/operations.tsv"
mkdir -p "$ordering_home/Library/Application Support/Code"
printf 'recreated VS Code data\n' > "$ordering_home/Library/Application Support/Code/recreated.txt"
HOME="$ordering_home" DAY_ONE_MAC_STATE_ROOT="$ordering_state" \
  DAY_ONE_TEST_BREW_LOG="$ordering_log" \
  DAY_ONE_TEST_BREW_STATE="$ordering_brew_state" \
  DAY_ONE_MAC_DISABLE_BREW_DISCOVERY=0 \
  DAY_ONE_MAC_BREW_PATH="$fake_homebrew_bin/brew" \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$SCRIPT_DIR/clean-development-state.sh" --execute --yes \
  --resume-cleanup "$resume_cleanup" --archive-projects \
  > "$TEST_ROOT/cleanup-resume-output.txt" 2>&1
grep -Fq 'rediscovered Homebrew after shell settings were archived' "$TEST_ROOT/cleanup-resume-output.txt"
grep -Fq 'reusing the application and package inventories' "$TEST_ROOT/cleanup-resume-output.txt"
grep -Fq 'created by an older script and has no saved option manifest' "$TEST_ROOT/cleanup-resume-output.txt"
grep -Fq 'A source path was recreated after its original archive' "$TEST_ROOT/cleanup-resume-output.txt"
grep -Fq 'Step 5 resume result' "$TEST_ROOT/cleanup-resume-output.txt"
grep -Fq 'Earlier failures retained in the audit log: 1' "$TEST_ROOT/cleanup-resume-output.txt"
grep -Fq 'Failed during this resume: 0' "$TEST_ROOT/cleanup-resume-output.txt"
grep -Fq $'skip-absent-cask\tfake-app\t-\tcomplete' "$resume_cleanup/operations.tsv"
grep -Fq $'archive-resume-addition\t'"$ordering_home/Library/Application Support/Code" \
  "$resume_cleanup/operations.tsv"
resume_addition_files=("$resume_cleanup"/resume-additions/*/home/Library/Application\ Support/Code/recreated.txt)
[[ -f "${resume_addition_files[0]}" ]]
[[ -f "$resume_cleanup/home/Library/Application Support/Code/original.txt" ]]
[[ -s "$resume_cleanup/resume-summary.md" ]]
grep -Fq 'Outcome: **completed successfully**' "$resume_cleanup/resume-summary.md"
grep -Fq '`uninstall-cask` — `old-failed-app`' "$resume_cleanup/resume-summary.md"
grep -Fq '## Completed by this resume' "$resume_cleanup/resume-summary.md"
[[ -s "$resume_cleanup/SNAPSHOT-COMPLETE" ]]
[[ ! -e "$resume_cleanup/INCOMPLETE.md" ]]
(cd "$resume_cleanup" && shasum -a 256 -c SHA256SUMS.txt >/dev/null)

# A user-managed Git repository must never lose unreadable objects silently.
# In a non-interactive run the snapshot stops and directs the user back to the
# wizard, where an explicit administrator-assisted read can be approved.
permission_snapshot_parent="$TEST_ROOT/permission-backup-snapshots"
permission_snapshot_result="$TEST_ROOT/permission-backup-result"
permission_output="$TEST_ROOT/permission-backup.txt"
restricted_project_object="$TEST_HOME/Developer/github.com/example/project/.git/objects/00/object"
mkdir -p "$permission_snapshot_parent" "$(dirname "$restricted_project_object")"
printf 'unpublished Git object\n' > "$restricted_project_object"
chmod 000 "$restricted_project_object"
if HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$SCRIPT_DIR/clean-development-state.sh" --backup-only --yes --archive-projects \
  --archive-root "$permission_snapshot_parent" --result-file "$permission_snapshot_result" \
  </dev/null > "$permission_output" 2>&1; then
  printf 'FAIL: backup silently accepted an unreadable user-managed Git object\n' >&2
  exit 1
fi
grep -Fq 'cannot be read by this user account' "$permission_output"
grep -Fq 'The unreadable data will not be skipped' "$permission_output"
grep -Fq 'Run this step again from the guided wizard' "$permission_output"
[[ -f "$restricted_project_object" ]]
[[ ! -e "$permission_snapshot_result" ]]
permission_recovery_dirs=("$permission_snapshot_parent"/Day-One-Mac-Backup-Snapshot-*)
[[ -f "${permission_recovery_dirs[0]}/INCOMPLETE.md" ]]
chmod 600 "$restricted_project_object"

if HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/clean-development-state.sh" --archive-root "$TEST_HOME/Developer" \
  --archive-projects >/dev/null 2>&1; then
  printf 'FAIL: cleanup accepted a recovery archive inside ~/Developer while archiving it\n' >&2
  exit 1
fi

HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE_ROOT" \
  "$SCRIPT_DIR/rollback-recorded-setup.sh" --execute --yes \
  --archive-root "$TEST_ROOT/recovery" >/dev/null 2>&1

[[ ! -e "$TEST_HOME/.zshrc" ]]
grep -Fqx 'original value' "$TEST_HOME/.gitconfig"
[[ -f "$TEST_HOME/Developer/_sandbox/project.txt" ]]
[[ ! -d "$TEST_HOME/.empty-parent" ]]
recovery_dirs=("$TEST_ROOT"/recovery/Day-One-Mac-Recovery-*)
[[ -f "${recovery_dirs[0]}/cleanup.log" ]]
[[ -f "${recovery_dirs[0]}/manual-follow-up.md" ]]
[[ -f "${recovery_dirs[0]}/current/.zshrc" ]]
[[ -f "${recovery_dirs[0]}/current/.gitconfig" ]]

printf 'PASS: day-one-mac dry-run, copy-only backup, status and reversible cleanup\n'
