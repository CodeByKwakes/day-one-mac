#!/usr/bin/env bash
# Validate the self-contained Day One Mac project without changing the Mac.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
FAILURES=0

pass() { ui_success "$@"; }
fail() { ui_error "$@"; FAILURES=$((FAILURES + 1)); }

# Run a ripgrep scan, keeping "no matches" distinct from "the scan failed".
# Results are returned through globals because a command substitution would run
# this in a subshell and lose both the status and any FAILURES increment.
#   RG_OUTPUT — matching lines, empty when there were none
#   RG_STATUS — 0 matched, 1 no match, 2 or higher the scan itself failed
RG_OUTPUT=""
RG_STATUS=0
rg_scan() {
  set +e
  RG_OUTPUT="$(rg --glob '!node_modules/**' "$@" 2>&1)"
  RG_STATUS=$?
  set -e
  if [[ "$RG_STATUS" -gt 1 ]]; then
    fail "ripgrep scan failed (rg $*): $RG_OUTPUT"
    RG_OUTPUT=""
    return 1
  fi
  [[ "$RG_STATUS" -eq 0 ]] || RG_OUTPUT=""
  return 0
}

# Run a regression fixture. On failure, show its output: a bare "fixture
# failed" line leaves the reader — and Phase 8, which runs this validator —
# with nothing to act on.
run_fixture() {
  local pass_label="$1" fail_label="$2" script="$3" output status
  set +e
  # </dev/null as well as the fixture's own guard: a fixture that blocks on a
  # prompt would hang the validator, and Phase 8 runs this from a real
  # terminal where stdin is a TTY.
  output="$("$script" 2>&1 </dev/null)"
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    pass "$pass_label"
    return 0
  fi
  fail "$fail_label"
  printf '%s\n' "$output" | tail -20 | sed 's/^/      /' >&2
  printf '      (rerun it directly for the full output: %s)\n' "${script#"$PROJECT_DIR"/}" >&2
  return 1
}

ui_title '🧪' 'Day One Mac project validation'

# Several checks below use ripgrep. Without it they would silently examine
# nothing and still report a pass, so stop here instead of validating nothing.
if ! command -v rg >/dev/null 2>&1; then
  fail "ripgrep (rg) is required by this validator but was not found on PATH."
  printf 'Install it with '\''brew install ripgrep'\'', then rerun this validator.\n' >&2
  exit 1
fi

required_docs=(
  README.md
  VERSION
  .release-please-manifest.json
  release-please-config.json
  package.json
  pnpm-lock.yaml
  commitlint.config.cjs
  .markdownlint-cli2.jsonc
  .husky/commit-msg
  .husky/pre-commit
  .husky/pre-push
  LICENSE
  SECURITY.md
  CONTRIBUTING.md
  install-day-one-mac
  README.md
  docs/README.md
  docs/START-HERE.md
  docs/PROCESS-OVERVIEW.md
  docs/NEW-DEVICE-SETUP-BLUEPRINT.md
  docs/PROJECT-GUIDE.md
  docs/GIT-WORKFLOW.md
  docs/CONTRIBUTOR-TOOLING.md
  docs/RELEASE-TOKEN-SETUP.md
  docs/01-required/README.md
  docs/01-required/MACOS-SETTINGS.md
  docs/01-required/01-first-boot-and-decisions.md
  docs/01-required/02-command-line-foundation.md
  docs/01-required/INSTALLATION-CENTRE.md
  docs/01-required/03-security-and-ssh.md
  docs/01-required/04-core-tools-and-hosting.md
  docs/01-required/05-dotfiles-and-shell.md
  docs/01-required/06-language-toolchains.md
  docs/01-required/07-vscode-base.md
  docs/01-required/08-verify-and-reproduce.md
  docs/20-reference/README.md
  docs/20-reference/COMMAND-REFERENCE.md
  docs/20-reference/OPTIONAL-STATUS.md
  docs/20-reference/UPGRADE-NOTES.md
  docs/20-reference/GLOSSARY.md
  docs/20-reference/GITHUB-PRIVATE-REPOSITORY.md
  docs/20-reference/APPLICATION-OWNERSHIP.md
  docs/20-reference/AI-WORKSPACES.md
  docs/20-reference/EXPECTED-LAYOUT.md
  docs/20-reference/NOTION-SETUP-GUIDE.md
  docs/20-reference/CHEZMOI-SETUP-TUTORIAL.md
  docs/20-reference/CHEZMOI-COMMAND-REFERENCE.md
  docs/20-reference/CHEZMOI-CONCEPTS-AND-BOUNDARIES.md
  docs/20-reference/MANAGING-DOTFILES-WITH-CHEZMOI.md
  docs/20-reference/phase-05-shell-files/README.md
  docs/04-operations/README.md
  docs/04-operations/FINALIZE.md
  docs/04-operations/REMOVE-DAY-ONE-MAC.md
  docs/04-operations/ROLLBACK.md
  docs/99-maintenance/README.md
  docs/99-maintenance/DOCUMENTATION-AUDIT.md
  docs/10-app-guides/README.md
  docs/10-app-guides/KEYBOARD-SHORTCUTS.md
  docs/10-app-guides/RAYCAST.md
  docs/10-app-guides/RAYCAST-COMMANDS.md
  docs/10-app-guides/RAYCAST-AI-PROVIDERS.md
  docs/10-app-guides/VSCODE.md
  docs/10-app-guides/WARP.md
  docs/10-app-guides/1PASSWORD-SSH-APPROVAL.md
  docs/00-preflight/README.md
  docs/00-preflight/00-existing-mac-decision.md
  docs/00-preflight/01-private-inventory.md
  docs/00-preflight/ENCRYPTED-BACKUP-DRIVE.md
  docs/00-preflight/02-backup-readiness.md
  docs/00-preflight/03-account-preserving-cleanup.md
  docs/00-preflight/04-handoff-to-day-one.md
  docs/02-optional/09-databases.md
  docs/02-optional/README.md
  docs/02-optional/10-ai-agents.md
  docs/02-optional/10a-omniroute.md
  docs/02-optional/11-mcp-servers.md
  docs/02-optional/12-vscode-profiles.md
  docs/02-optional/13-enhanced-cli-tools.md
  docs/02-optional/14-warp-drive.md
  docs/03-advanced/README.md
  docs/03-advanced/15-full-dotfiles-and-bootstrap.md
  docs/03-advanced/16-brewfile-apps-and-editor.md
  docs/03-advanced/17-shell-and-package-automation.md
  docs/03-advanced/18-hosting-identities-azure-and-worktrees.md
  docs/03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md
  docs/03-advanced/19-macos-gui-and-local-https.md
  docs/03-advanced/20-restore-and-migrate.md
  docs/03-advanced/21-audit-maintenance-and-rebuild.md
  docs/03-advanced/22-ai-skills-and-mcp-operations.md
  second-brain/README.md
  second-brain/obsidian/README.md
  second-brain/notion/README.md
  second-brain/notion/01-PREREQUISITES.md
  second-brain/notion/02-WORKSPACE-AND-DOMAINS.md
  second-brain/notion/03-DATABASES-AND-PROPERTIES.md
  second-brain/notion/04-TEMPLATES.md
  second-brain/notion/05-DASHBOARD.md
  second-brain/notion/06-RAYCAST-INTEGRATION.md
  second-brain/notion/07-AI-INTEGRATION.md
  second-brain/notion/08-OPERATING-WORKFLOW.md
  second-brain/notion/09-BACKUP-AND-EXPORT.md
  second-brain/notion/CHECKLIST.md
  "warp-drive/Day One Mac/00 Day One Mac Command Catalogue.md"
  config/applications.tsv
  config/optional-formulae.tsv
  config/raycast-commands.tsv
  config/raycast-extensions.tsv
)

missing=0
for relative in "${required_docs[@]}"; do
  if [[ ! -s "$PROJECT_DIR/$relative" ]]; then
    fail "missing or empty document: $relative"
    missing=1
  fi
done
[[ "$missing" == 0 ]] && pass "all required and optional documents are present"

# Keep the eight required phase guides predictable for readers at every skill
# level. START-HERE promises this exact structure, so drift is a usability bug.
phase_structure_failed=0
for phase_doc in "$PROJECT_DIR"/docs/01-required/0[1-8]-*.md; do
  if ! grep -Fq '## Outcome' "$phase_doc" \
     || ! grep -Fq '## How to use this phase' "$phase_doc" \
     || ! grep -Eq '^## (Permission and network recovery|Troubleshooting)$' "$phase_doc" \
     || ! grep -Eq '^## Phase [1-8] completion checklist 🚦$' "$phase_doc"; then
    fail "required phase guide lacks the standard reader path: ${phase_doc#"$PROJECT_DIR"/}"
    phase_structure_failed=1
  fi
done
[[ "$phase_structure_failed" == 0 ]] \
  && pass "all required phase guides use the same outcome, steps, recovery, and checklist structure"

catalog_failed=0
if ! awk -F '\t' '
  /^#/ {next}
  NF != 9 {exit 1}
  $1 == "" || seen[$1]++ {exit 1}
  $2 != "required" && $2 != "optional" {exit 1}
  $3 == "" || $4 == "" || $5 == "" {exit 1}
  $6 != "app" && $6 != "cli" && $6 != "font" {exit 1}
  $6 == "app" && $7 !~ /^\/Applications\/.*\.app$/ {exit 1}
  $6 == "cli" && $9 == "-" {exit 1}
  END {if (NR < 2) exit 1}
' "$PROJECT_DIR/config/applications.tsv"; then
  fail "application catalogue has an invalid, duplicate, or incomplete row"
  catalog_failed=1
fi

if rg_scan -n -i \
  -e 'fresh-start|fresh[ -]mac|\.fresh-mac-setup|FRESH_START|older 20-phase|legacy playbook|zam-state|mac-setup' \
  "$PROJECT_DIR/docs" "$PROJECT_DIR/second-brain" \
  --glob '*.md' --glob '!UPGRADE-NOTES.md'; then
  if [[ "$RG_STATUS" -eq 0 ]]; then
    fail "normal guides contain retired project names that belong only in UPGRADE-NOTES.md"
    printf '%s\n' "$RG_OUTPUT" | sed 's/^/      /' >&2
  else
    pass "retired project names are isolated in the upgrade-only reference"
  fi
fi
for app_id in 1password 1password-cli jetbrains-mono-nerd-font raycast visual-studio-code warp \
              orbstack dbeaver-community claude-code codex copilot-app copilot-cli obsidian purge; do
  if ! awk -F '\t' -v wanted="$app_id" '$0 !~ /^#/ && $1 == wanted {found=1} END {exit !found}' \
      "$PROJECT_DIR/config/applications.tsv"; then
    fail "application catalogue is missing: $app_id"
    catalog_failed=1
  fi
done

if awk -F '\t' '
  $1 == "purge" && $2 == "optional" && $3 == "21" \
    && $5 == "jithin-sabu/tap/purge" && $6 == "app" \
    && $7 == "/Applications/Purge.app" && $8 == "io.getpurge.app" {found=1}
  END {exit !found}
' "$PROJECT_DIR/config/applications.tsv" \
   && grep -Fq 'Leave scheduled cleaning disabled.' \
      "$PROJECT_DIR/docs/03-advanced/21-audit-maintenance-and-rebuild.md" \
   && grep -Fq 'Purge is never invoked by a Day One Mac script' \
      "$PROJECT_DIR/docs/03-advanced/21-audit-maintenance-and-rebuild.md"; then
  pass "Purge remains optional, fully qualified, and manual at every destructive boundary"
else
  fail "Purge catalogue identity or manual-only safety guidance has drifted"
  catalog_failed=1
fi

for formula in actionlint mas; do
  if ! awk -F '\t' -v wanted="$formula" \
      '$0 !~ /^#/ && $2 == wanted {found=1} END {exit !found}' \
      "$PROJECT_DIR/config/optional-formulae.tsv"; then
    fail "optional formula catalogue is missing: $formula"
    catalog_failed=1
  fi
done
[[ "$catalog_failed" == 0 ]] \
  && pass "application and optional formula catalogues have valid required entries"

link_failed=0
rg_scan --no-heading -o '\]\([^)]*\.md(#[^)]*)?\)' "$PROJECT_DIR" --glob '*.md' || link_failed=1
while IFS= read -r link_record; do
  [[ -n "$link_record" ]] || continue
  source_file="${link_record%%:*}"
  markdown_match="${link_record#*:}"
  link_target="$(printf '%s\n' "$markdown_match" | sed -E 's/^\]\(([^)#]+\.md).*/\1/')"
  case "$link_target" in http://*|https://*|mailto:*) continue ;; esac
  if [[ "$link_target" == /* ]]; then
    link_path="$link_target"
  else
    link_path="$(dirname "$source_file")/$link_target"
  fi
  if [[ ! -f "$link_path" ]]; then
    fail "broken Markdown link in ${source_file#"$PROJECT_DIR"/}: $link_target"
    link_failed=1
  fi
done <<<"$RG_OUTPUT"
[[ "$link_failed" == 0 ]] && pass "all local Markdown navigation targets exist"

markdown_anchor_exists() {
  local file="$1" wanted="$2"
  LC_ALL=C awk -v wanted="$wanted" '
    /^#{1,6}[ \t]+/ {
      heading=$0
      sub(/^#+[ \t]+/, "", heading)
      sub(/[ \t]+#+[ \t]*$/, "", heading)
      slug=tolower(heading)
      gsub(/[^[:alnum:] _-]/, "", slug)
      gsub(/[ \t]/, "-", slug)
      base=slug
      if (seen[base]++) slug=base "-" (seen[base] - 1)
      if (slug == wanted) found=1
    }
    END {exit !found}
  ' "$file"
}

anchor_failed=0
rg_scan --no-heading -o '\]\(([^)]*\.md)?#[^)]*\)' "$PROJECT_DIR" --glob '*.md' || anchor_failed=1
while IFS= read -r link_record; do
  [[ -n "$link_record" ]] || continue
  source_file="${link_record%%:*}"
  markdown_match="${link_record#*:}"
  link_target="$(printf '%s\n' "$markdown_match" | sed -E 's/^\]\(([^#)]*)#[^)]*\)$/\1/')"
  link_fragment="$(printf '%s\n' "$markdown_match" | sed -E 's/^\]\([^#)]*#([^)]*)\)$/\1/')"
  case "$link_target" in http://*|https://*|mailto:*) continue ;; esac
  if [[ -z "$link_target" ]]; then
    link_path="$source_file"
  elif [[ "$link_target" == /* ]]; then
    link_path="$link_target"
  else
    link_path="$(dirname "$source_file")/$link_target"
  fi
  [[ -f "$link_path" ]] || continue # Missing files are reported by the prior check.
  if ! markdown_anchor_exists "$link_path" "$link_fragment"; then
    fail "broken Markdown section link in ${source_file#"$PROJECT_DIR"/}: ${link_target}#${link_fragment}"
    anchor_failed=1
  fi
done <<<"$RG_OUTPUT"
[[ "$anchor_failed" == 0 ]] && pass "all local Markdown section links resolve"

# The pinned 1Password version statement in Phase 3 goes stale quietly. Print a
# reminder once it is over six months old. This never fails the build: the
# numbers are documentation, not a gate, and a date should not break CI.
version_review_date="$(sed -n 's/.*day-one-mac:version-review \([0-9-]*\).*/\1/p' \
  "$PROJECT_DIR/docs/01-required/03-security-and-ssh.md" | head -1)"
if [[ -z "$version_review_date" ]]; then
  fail "Phase 3 has no day-one-mac:version-review marker to date its pinned versions"
else
  review_epoch="$(date -j -f '%Y-%m-%d' "$version_review_date" '+%s' 2>/dev/null || true)"
  if [[ -z "$review_epoch" ]]; then
    fail "the day-one-mac:version-review marker is not a YYYY-MM-DD date: $version_review_date"
  elif [[ "$(( ( $(date '+%s') - review_epoch ) / 86400 ))" -gt 183 ]]; then
    ui_warning "Phase 3's pinned 1Password versions were last reviewed on $version_review_date; recheck them and update the marker."
  else
    pass "the pinned 1Password version statement was reviewed within the last six months"
  fi
fi

required_scripts=(
  setup.sh
  bootstrap-day-one-mac.sh
  clean-development-state.sh
  application-status.sh
  application-inventory.sh
  preflight-audit.sh
  prepare-existing-mac.sh
  day-one-mac
  install-portable-command.sh
  runtime-manager.sh
  build-release.sh
  advanced-audit.sh
  advanced-setup.sh
  configure-databases.sh
  optional-status.sh
  configure-cli-tools.sh
  configure-macos-settings.sh
  workspace-manager.sh
  finalize-setup.sh
  remove-day-one-mac.sh
  rollback-recorded-setup.sh
  validate-warp-drive.sh
  validate.sh
  lint.sh
  lib/apfs-volume.sh
  lib/project-paths.sh
  lib/application-ownership.sh
  lib/container-data-paths.sh
  lib/platform.sh
  lib/terminal-ui.sh
  tests/test-application-ownership.sh
  tests/test-configure-databases.sh
  tests/test-optional-status.sh
  tests/test-chezmoi-vscode-tools.sh
  tests/test-day-one-mac.sh
  tests/test-preflight.sh
  tests/test-secret-scan-and-ssh.sh
  tests/test-phase3-onepassword.sh
  tests/test-portable-command.sh
  tests/test-shell-environment.sh
  tests/test-workspace-manager.sh
)

syntax_failed=0
for relative in "${required_scripts[@]}"; do
  path="$SCRIPT_DIR/$relative"
  if [[ ! -x "$path" ]]; then
    fail "script is not executable: scripts/$relative"
    syntax_failed=1
  elif ! /bin/bash -n "$path"; then
    fail "shell syntax failed: scripts/$relative"
    syntax_failed=1
  fi
done
[[ "$syntax_failed" == 0 ]] && pass "all project scripts are executable and pass bash -n"

if rg_scan -n \
  -e 'FRESH-START-PLAYBOOK|\.zam-state|\.\./.*mac-setup|(^|[/(])mac-setup/|scripts/(day-one-mac|cleanup-previous-setup|remove-development-setup)\.sh|\./run\.sh' \
  "$PROJECT_DIR" --glob '*.md' --glob '*.sh' --glob '!validate.sh'; then
  if [[ "$RG_STATUS" -eq 0 ]]; then
    fail "day-one-mac contains a retired playbook, state, or script reference"
  else
    pass "documents and scripts are independent of the retired monorepo playbook"
  fi
fi

if grep -Fq 'exec bash "$HERE/setup.sh" "$@"' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq 'select_toggles()' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq 'Space or Enter: accept' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq "' ') SINGLE_RESULT=" "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq '🔒 Phase 1' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq 'Save choices and begin or resume setup' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq 'wizard-selections.md' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq 'post_required_menu' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq 'Optional setup remains locked until required Phase 8 is complete.' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && ! sed -n '/^configure_wizard()/,/^}/p' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" | grep -Fq 'choose_optional_plan' \
   && grep -Fq -- '--new-dotfiles' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq -- '--local-dotfiles' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'day_one_require_apple_silicon' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'verify_apple_developer_tools' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'for phase in 01 02 03 04 05 06 07 08' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'printf '\''%s\n'\'' chezmoi ghq git jq ripgrep starship zsh' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'git config --global ghq.root' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'git config --global push.autoSetupRemote true' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'git config --global core.excludesFile' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'if [[ "$PRIMARY_IDE" == vscode ]]' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'Use Visual Studio Code as the primary IDE on this Mac?' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq '"$HOME/.gitignore_global"' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq '2) printf '\''Azure DevOps only' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq '3) printf '\''GitHub + Azure DevOps' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'run_installation_centre()' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'installation_centre_done()' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq -- '--install-centre' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'Required Installation Centre' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'day_one_app_catalog_ids required' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'report_application "$DAY_ONE_APP_NAME" "$app_id"' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'applications) shift; exec' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'install) shift; exec' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'External installation (Company Portal or manual)' "$SCRIPT_DIR/lib/application-ownership.sh" \
   && grep -Fq 'existing_managed_source=1' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'eval "$(starship init zsh)"' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'runner_wrapper="$HOME/.local/bin/day-one-mac"' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'migrate_legacy_managed_launcher' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'run chezmoi forget "$target"' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'safety-report|preflight) shift; exec' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'prepare-existing|prepare-reset)' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'macos-settings) shift; exec "$PROJECT_ROOT/scripts/configure-macos-settings.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'workspace) shift; exec "$PROJECT_ROOT/scripts/workspace-manager.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'raycast) shift; exec "$PROJECT_ROOT/scripts/configure-raycast.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'shell-status) shift; exec "$PROJECT_ROOT/scripts/shell-status.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'exec "$PROJECT_ROOT/scripts/bootstrap-day-one-mac.sh" --optional "$@"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'finalize) shift; exec "$PROJECT_ROOT/scripts/finalize-setup.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'remove) shift; exec "$PROJECT_ROOT/scripts/remove-day-one-mac.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'runtime-status) shift; exec "$PROJECT_ROOT/scripts/runtime-manager.sh" status' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'RUNTIME_FILE="$STATE_ROOT/runtime-root"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'DAY_ONE_MAC_STATE_ROOT' "$SCRIPT_DIR/lib/project-paths.sh" \
   && grep -Fq 'NO_COLOR' "$SCRIPT_DIR/lib/terminal-ui.sh" \
   && grep -Fq 'ui_title()' "$SCRIPT_DIR/lib/terminal-ui.sh" \
   && grep -Fq 'FRESH_START_STATE_ROOT' "$SCRIPT_DIR/lib/project-paths.sh" \
   && grep -Fq 'legacy_runner="$HOME/.local/bin/fresh-start"' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'save_state_value project-root "$PROJECT_DIR"' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'advanced) shift; exec "$PROJECT_ROOT/scripts/advanced-setup.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'advanced-audit|audit) shift; exec' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'PHASE_SCHEMA_05=15' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'PHASE_SCHEMA_08=11' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'PHASE_SCHEMA_01=5' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq '.config/zsh/path.zsh' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq '.config/zsh/aliases.zsh' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'HTTPS Git authentication selected; no SSH identity is configured.' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'Directory Services login shell' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'run_macos_settings_checkpoint' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'verify_dotfiles_remote' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'verify_local_dotfiles_source' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq '"$SCRIPT_DIR/validate.sh" || return "$EX_GATE"' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'Completed in this attempt:' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'Still required:' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'preview record compaction with: day-one-mac finalize' "$SCRIPT_DIR/setup.sh" \
   && grep -Fq 'Optional databases, AI, MCP and VS Code profiles are not run here.' "$SCRIPT_DIR/setup.sh"; then
  pass "wizard feeds the resumable eight-phase runner and keeps chezmoi, Starship and pnpm in the base"
else
  fail "wizard, runner phase flow, or required base components are incomplete"
fi

semantic_failed=0
release_manifest_version="$(sed -n 's/^[[:space:]]*"\.":[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$PROJECT_DIR/.release-please-manifest.json")"
project_version="$(sed -n '1p' "$PROJECT_DIR/VERSION")"
if [[ "$release_manifest_version" != "$project_version" ]] \
   || ! grep -Fq 'workflows: [Validate]' "$PROJECT_DIR/.github/workflows/release.yml" \
   || ! grep -Fq "github.event.workflow_run.conclusion == 'success'" "$PROJECT_DIR/.github/workflows/release.yml" \
   || ! grep -Fq 'googleapis/release-please-action@5c625bfb5d1ff62eadeeb3772007f7f66fdcf071' "$PROJECT_DIR/.github/workflows/release.yml" \
   || ! grep -Fq 'token: ${{ secrets.RELEASE_PLEASE_TOKEN }}' "$PROJECT_DIR/.github/workflows/release.yml" \
   || ! grep -Fq 'steps.release.outputs.release_created' "$PROJECT_DIR/.github/workflows/release.yml" \
   || ! grep -Fq 'gh release upload "$RELEASE_TAG"' "$PROJECT_DIR/.github/workflows/release.yml" \
   || ! grep -Fq '"version-file": "VERSION"' "$PROJECT_DIR/release-please-config.json"; then
  fail "Release Please versioning, validation gate, action pin, or asset publication is incomplete"
  semantic_failed=1
else
  pass "Release Please waits for main validation and owns version, tag, release, and asset publication"
fi
if grep -Fq '"prepare": "husky"' "$PROJECT_DIR/package.json" \
   && grep -Fq '"*.{md,mdx}": "markdownlint-cli2"' "$PROJECT_DIR/package.json" \
   && grep -Fq 'node_modules/.bin/commitlint --edit "$1"' "$PROJECT_DIR/.husky/commit-msg" \
   && grep -Fq 'node_modules/.bin/lint-staged' "$PROJECT_DIR/.husky/pre-commit" \
   && grep -Fq 'scripts/validate.sh' "$PROJECT_DIR/.husky/pre-push" \
   && grep -Fq 'pnpm exec commitlint' "$PROJECT_DIR/.github/workflows/validate.yml" \
   && grep -Fq 'run: pnpm run lint' "$PROJECT_DIR/.github/workflows/validate.yml"; then
  pass "contributor hooks and CI enforce conventional commits and delegated linting"
else
  fail "contributor hook or CI lint integration has drifted"
  semantic_failed=1
fi
if rg -n 'raw\.githubusercontent\.com/CodeByKwakes/day-one-mac/main/install-day-one-mac|CodeByKwakes/MacOS|└── MacOS/' \
  "$PROJECT_DIR" --glob '*.md' --glob '!node_modules/**' >/dev/null 2>&1; then
  fail "a guide still uses the moving main-branch installer or the retired monorepo layout"
  semantic_failed=1
fi
if rg -n '\./(bootstrap-day-one-mac|setup|prepare-existing-mac|preflight-audit|configure-macos-settings|configure-cli-tools|application-status|workspace-manager|remove-day-one-mac)\.sh' \
  "$PROJECT_DIR/docs/00-preflight" \
  "$PROJECT_DIR/docs/01-required" \
  "$PROJECT_DIR/docs/02-optional" \
  "$PROJECT_DIR/docs/10-app-guides" \
  --glob '*.md' --glob '!03-account-preserving-cleanup.md' >/dev/null 2>&1; then
  fail "a normal user guide bypasses the standalone day-one-mac command"
  semantic_failed=1
fi
if ! grep -Fq 'releases/latest/download/install-day-one-mac' "$PROJECT_DIR/README.md" \
   || ! grep -Fq 'Move an already-completed Mac to standalone mode' \
      "$PROJECT_DIR/docs/20-reference/PORTABLE-COMMAND.md" \
   || ! grep -Fq 'active versioned runtime' \
      "$PROJECT_DIR/docs/01-required/08-verify-and-reproduce.md"; then
  fail "standalone installation, migration, or Phase 8 runtime guidance is incomplete"
  semantic_failed=1
fi
if rg -n '^cd day-one-mac/' "$PROJECT_DIR" \
  --glob '*.md' --glob '!node_modules/**' >/dev/null 2>&1; then
  fail "a guide still assumes the reader's current directory with 'cd day-one-mac/...'"
  semantic_failed=1
fi
# Numbered documentation folders are part of the navigation contract. Reject
# stale script paths and Markdown links instead of allowing two competing
# structures to reappear.
if rg -n 'docs/(preflight|required|optional|advanced|operations|app-guides|reference|maintenance)/|\]\((\.\./){0,2}(preflight|required|optional|advanced|operations|app-guides|reference|maintenance)/' \
  "$PROJECT_DIR" --glob '*.md' --glob '*.sh' \
  --glob '!node_modules/**' >/dev/null 2>&1; then
  fail "a script or guide still refers to a retired unnumbered documentation folder"
  semantic_failed=1
fi
for retired_docs_dir in preflight required optional advanced operations app-guides reference maintenance; do
  if [[ -e "$PROJECT_DIR/docs/$retired_docs_dir" ]]; then
    fail "retired documentation folder still exists: docs/$retired_docs_dir"
    semantic_failed=1
  fi
done
if grep -Fq '~/.config/Code/User/settings.json' \
  "$PROJECT_DIR/docs/03-advanced/15-full-dotfiles-and-bootstrap.md"; then
  fail "the advanced dotfiles guide still uses the non-macOS VS Code settings path"
  semantic_failed=1
fi
if grep -Fq 'Capture to Second Brain' "$PROJECT_DIR/second-brain/obsidian/GUIDE-1-OBSIDIAN-RAYCAST.md" \
   || grep -Fq 'Open Second Brain Dashboard' "$PROJECT_DIR/second-brain/obsidian/GUIDE-1-OBSIDIAN-RAYCAST.md"; then
  fail "the Raycast guide still uses retired dynamic command names"
  semantic_failed=1
fi
if grep -Fq 'The user request' "$PROJECT_DIR/docs/04-operations/ROLLBACK.md" \
   || ! grep -Fq 'cp -p "$RECOVERY/home/.config/starship.toml"' "$PROJECT_DIR/docs/04-operations/ROLLBACK.md"; then
  fail "rollback guidance contains conversation residue or removes its recovery copy"
  semantic_failed=1
fi
if ! grep -Fq 'docker inspect --format=' "$PROJECT_DIR/docs/02-optional/09-databases.md" \
   || ! grep -Fq -- "--health-cmd='mongosh" "$PROJECT_DIR/docs/02-optional/09-databases.md"; then
  fail "MongoDB documentation promises health without defining and inspecting a health check"
  semantic_failed=1
fi
if ! grep -Fq -- '--tools raycast' "$PROJECT_DIR/second-brain/obsidian/README.md" \
   || ! grep -Fq -- '--tools|--stack' "$PROJECT_DIR/second-brain/obsidian/scripts/setup-second-brain.sh" \
   || grep -Fq '| **Multi domain**' "$PROJECT_DIR/second-brain/obsidian/README.md"; then
  fail "Second Brain user-facing commands or layout names have drifted from the dynamic manager"
  semantic_failed=1
fi
# Phase 3 must still state the recommended default and point at the reference.
if ! grep -Fq 'Application and terminal session' "$PROJECT_DIR/docs/01-required/03-security-and-ssh.md" \
   || ! grep -Fq 'Until 1Password locks' "$PROJECT_DIR/docs/01-required/03-security-and-ssh.md" \
   || ! grep -Fq '../10-app-guides/1PASSWORD-SSH-APPROVAL.md' "$PROJECT_DIR/docs/01-required/03-security-and-ssh.md"; then
  fail "Phase 3 does not state the SSH approval default or link to the approval guide"
  semantic_failed=1
fi
# The full approval reference moved out of Phase 3; it must survive intact.
approval_guide="$PROJECT_DIR/docs/10-app-guides/1PASSWORD-SSH-APPROVAL.md"
if ! grep -Fq 'Application and terminal session' "$approval_guide" \
   || ! grep -Fq 'Until 1Password locks' "$approval_guide" \
   || ! grep -Fq '4, 12, or 24 hours' "$approval_guide" \
   || ! grep -Fq '10 minutes of inactivity' "$approval_guide" \
   || ! grep -Fq 'hard 12-hour limit' "$approval_guide" \
   || ! grep -Fq 'not an application allow-list' "$approval_guide" \
   || ! grep -Fq 'Change the approval settings later' "$approval_guide" \
   || ! grep -Fq 'git fetch --dry-run' "$approval_guide" \
   || ! grep -Fq 'quit 1Password completely' "$approval_guide"; then
  fail "the 1Password approval guide is missing scope, duration, revocation, or separate CLI session guidance"
  semantic_failed=1
fi
if ! grep -Fq 'Import Profile…' "$PROJECT_DIR/docs/10-app-guides/VSCODE.md" \
   || ! grep -Fq '.code-profile' "$PROJECT_DIR/docs/10-app-guides/VSCODE.md" \
   || ! grep -Fq 'clear all cloud data' "$PROJECT_DIR/docs/10-app-guides/VSCODE.md" \
   || ! grep -Fq 'Settings Sync is intentionally on or intentionally off' "$PROJECT_DIR/docs/10-app-guides/VSCODE.md"; then
  fail "VS Code app guide is missing selective import, export, sync reset, or verification guidance"
  semantic_failed=1
fi
if ! grep -Fq 'Security controls are reviewed manually' "$SCRIPT_DIR/configure-macos-settings.sh" \
   || ! grep -Fq 'spctl --master-disable' "$PROJECT_DIR/docs/01-required/MACOS-SETTINGS.md" \
   || ! grep -Fq 'OPTION_GROUPS=(' "$SCRIPT_DIR/configure-macos-settings.sh" \
   || grep -Eq '^GROUPS=' "$SCRIPT_DIR/configure-macos-settings.sh" \
   || ! grep -Fq 'validate_option_catalog' "$SCRIPT_DIR/configure-macos-settings.sh" \
   || ! grep -Fq '*[Ff]loat*) type=float' "$SCRIPT_DIR/configure-macos-settings.sh" \
   || ! grep -Fq 'bool:1|bool:true) value=true' "$SCRIPT_DIR/configure-macos-settings.sh" \
   || grep -Eq '^[[:space:]]*spctl[[:space:]]+--master-disable' "$SCRIPT_DIR/configure-macos-settings.sh" \
   || ! grep -Fq -- '--restore' "$SCRIPT_DIR/configure-macos-settings.sh" \
   || ! grep -Fq 'macos-settings-status' "$SCRIPT_DIR/setup.sh"; then
  fail "early macOS settings wizard, security boundary, or restore path is incomplete"
  semantic_failed=1
fi
if ! grep -Fq 'Create a new GitHub Ed25519 key' "$SCRIPT_DIR/setup.sh" \
   || ! grep -Fq 'Azure DevOps RSA 3072-bit key' "$SCRIPT_DIR/setup.sh" \
   || ! grep -Fq '# >>> Day One Mac: 1Password SSH agent >>>' "$SCRIPT_DIR/setup.sh" \
   || ! grep -Fq 'Host github.com' "$SCRIPT_DIR/setup.sh" \
   || ! grep -Fq 'Host ssh.dev.azure.com' "$SCRIPT_DIR/setup.sh" \
   || ! grep -Fq 'configure_onepassword_ssh' "$SCRIPT_DIR/setup.sh" \
   || ! grep -Fq 'update_homebrew_1password_if_needed' "$SCRIPT_DIR/setup.sh" \
   || ! grep -Fq 'Step 3.4c — Import an existing GitHub or Azure key' "$PROJECT_DIR/docs/01-required/03-security-and-ssh.md" \
   || ! grep -Fq 'Step 3.7 — Pin provider keys when needed' "$PROJECT_DIR/docs/01-required/03-security-and-ssh.md" \
   || ! grep -Fq 'Azure DevOps does not accept Ed25519' "$PROJECT_DIR/docs/20-reference/NOTION-SETUP-GUIDE.md" \
   || ! grep -Fq -- '--web --skip-ssh-key' "$SCRIPT_DIR/setup.sh" \
   || grep -Eq 'gh auth login .*--web[[:space:]]*$' "$SCRIPT_DIR/setup.sh"; then
  fail "Phase 3 does not cover provider-compatible new keys, existing-key import, and Track 3 routing"
  semantic_failed=1
fi
if ! grep -Fq 'Export Settings & Data' "$PROJECT_DIR/docs/10-app-guides/RAYCAST.md" \
   || ! grep -Fq '.rayconfig' "$PROJECT_DIR/docs/10-app-guides/RAYCAST.md" \
   || ! grep -Fq 'import is additive' "$PROJECT_DIR/docs/10-app-guides/RAYCAST.md" \
   || ! grep -Fq 'Replace the Spotlight launcher with Raycast' "$PROJECT_DIR/docs/10-app-guides/RAYCAST.md" \
   || ! grep -Fq 'Leave Spotlight indexing enabled' "$PROJECT_DIR/docs/10-app-guides/RAYCAST.md" \
   || ! grep -Fq 'Globally Allowed Tools' "$PROJECT_DIR/docs/10-app-guides/RAYCAST.md"; then
  fail "Raycast app guide is missing shortcut replacement, indexing, export, import, or permission guidance"
  semantic_failed=1
fi
if ! grep -Fq 'Install the official download manually' "$PROJECT_DIR/docs/10-app-guides/RAYCAST.md" \
   || ! grep -Fq 'External installation' "$PROJECT_DIR/docs/10-app-guides/RAYCAST.md" \
   || ! grep -Fq 'raycast-manual' "$PROJECT_DIR/docs/10-app-guides/RAYCAST-COMMANDS.md" \
   || ! grep -Fq 'Never add `--execute`' "$PROJECT_DIR/docs/10-app-guides/RAYCAST-COMMANDS.md" \
   || ! grep -Fq 'Bring Your Own Key' "$PROJECT_DIR/docs/10-app-guides/RAYCAST-AI-PROVIDERS.md" \
   || ! grep -Fq 'http://127.0.0.1:20128/v1' "$PROJECT_DIR/docs/10-app-guides/RAYCAST-AI-PROVIDERS.md" \
   || ! grep -Fq '.config/raycast/ai/providers.yaml' "$PROJECT_DIR/docs/10-app-guides/RAYCAST-AI-PROVIDERS.md"; then
  fail "Raycast manual installation, command, or provider guidance is incomplete"
  semantic_failed=1
fi
if ! grep -Fq 'Recommended global shortcut ownership' "$PROJECT_DIR/docs/10-app-guides/KEYBOARD-SHORTCUTS.md" \
   || ! grep -Fq 'That conflicts with 1Password' "$PROJECT_DIR/docs/10-app-guides/KEYBOARD-SHORTCUTS.md" \
   || ! grep -Fq 'Spotlight indexing remains enabled' "$PROJECT_DIR/docs/10-app-guides/KEYBOARD-SHORTCUTS.md" \
   || ! grep -Fq '⌘K ⌘S' "$PROJECT_DIR/docs/10-app-guides/KEYBOARD-SHORTCUTS.md"; then
  fail "application keyboard-shortcut reference is missing ownership, conflict, Spotlight, or editor guidance"
  semantic_failed=1
fi
if ! grep -Fq 'day-one-mac workspace --guided' "$PROJECT_DIR/docs/20-reference/AI-WORKSPACES.md" \
   || ! grep -Fq 'app-storage/codex-projectless' "$PROJECT_DIR/docs/20-reference/AI-WORKSPACES.md" \
   || ! grep -Fq 'app-storage/claude-cowork' "$PROJECT_DIR/docs/20-reference/AI-WORKSPACES.md" \
   || ! grep -Fq 'do not permanently add `~/Developer`' "$PROJECT_DIR/docs/20-reference/AI-WORKSPACES.md" \
   || ! grep -Fq 'CLAUDE.md -> AGENTS.md' "$PROJECT_DIR/docs/20-reference/AI-WORKSPACES.md" \
   || ! grep -Fq 'only one client should actively modify it at a time' "$PROJECT_DIR/docs/20-reference/AI-WORKSPACES.md" \
   || ! grep -Fq 'project.worktrees/' "$PROJECT_DIR/docs/03-advanced/18-hosting-identities-azure-and-worktrees.md" \
   || ! grep -Fq 'One AI client is the primary writer' "$PROJECT_DIR/docs/03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md" \
   || ! grep -Fq 'never moves an active task' "$SCRIPT_DIR/workspace-manager.sh"; then
  fail "projectless-task and worktree documentation or manager semantics have drifted"
  semantic_failed=1
fi
if ! grep -Fq '## Complete portable command list' "$PROJECT_DIR/docs/20-reference/COMMAND-REFERENCE.md" \
   || ! grep -Fq '`day-one-mac safety-report [options]`' "$PROJECT_DIR/docs/20-reference/COMMAND-REFERENCE.md" \
   || ! grep -Fq '`day-one-mac workspace [command]`' "$PROJECT_DIR/docs/20-reference/COMMAND-REFERENCE.md" \
   || ! grep -Fq '`./validate-warp-drive.sh`' "$PROJECT_DIR/docs/20-reference/COMMAND-REFERENCE.md" \
   || ! grep -Fq '[Upgrade notes](UPGRADE-NOTES.md)' "$PROJECT_DIR/docs/20-reference/COMMAND-REFERENCE.md"; then
  fail "command reference is missing portable, direct-script, maintenance, or upgrade coverage"
  semantic_failed=1
fi
if ! grep -Fq 'Shell (PS1)' "$PROJECT_DIR/docs/10-app-guides/WARP.md" \
   || ! grep -Fq 'Settings Sync' "$PROJECT_DIR/docs/10-app-guides/WARP.md" \
   || ! grep -Fq 'Export all Warp Drive objects' "$PROJECT_DIR/docs/10-app-guides/WARP.md" \
   || ! grep -Fq 'plain `.env`' "$PROJECT_DIR/docs/10-app-guides/WARP.md" \
   || ! grep -Fq 'claude auth status --text' "$PROJECT_DIR/docs/10-app-guides/WARP.md" \
   || ! grep -Fq 'codex login status' "$PROJECT_DIR/docs/10-app-guides/WARP.md" \
   || ! grep -Fq 'copilot login' "$PROJECT_DIR/docs/10-app-guides/WARP.md"; then
  fail "Warp app guide is missing Starship, sync, export, or secret-handling guidance"
  semantic_failed=1
fi
if ! grep -Fq 'For the script-assisted route, start the Day One Mac wizard' "$PROJECT_DIR/docs/01-required/01-first-boot-and-decisions.md" \
   || ! grep -Fq '[Continue to early macOS settings →](MACOS-SETTINGS.md)' "$PROJECT_DIR/docs/01-required/01-first-boot-and-decisions.md" \
   || ! grep -Fq '[← Early macOS settings](MACOS-SETTINGS.md)' "$PROJECT_DIR/docs/01-required/02-command-line-foundation.md" \
   || ! grep -Fq 'Existing Homebrew found at' "$SCRIPT_DIR/setup.sh" \
   || ! grep -Fq 'Choose one setup route' "$PROJECT_DIR/docs/START-HERE.md" \
   || ! grep -Fq 'day-one-mac finalize' "$PROJECT_DIR/docs/01-required/05-dotfiles-and-shell.md" \
   || ! grep -Fq 'Read **Outcome** and **How to use this phase**' "$PROJECT_DIR/docs/START-HERE.md" \
   || ! grep -Fq 'report_check "post-setup finalisation command" day-one-mac finalize --help' "$SCRIPT_DIR/setup.sh"; then
  fail "required-phase navigation, finalisation, or onboarding wording has drifted"
  semantic_failed=1
fi
if rg_scan -n -e 'Tracks 2–3|Track 2–3|Step 1\.7\. The wizard|README\.md#choose-a-guide' \
  "$PROJECT_DIR" --glob '*.md' --glob '!DOCUMENTATION-AUDIT.md'; then
  if [[ "$RG_STATUS" -eq 0 ]]; then
    fail "active guides contain retired track wording, step numbers, or section links"
    semantic_failed=1
  fi
else
  semantic_failed=1
fi
[[ "$semantic_failed" == 0 ]] && pass "high-risk documentation and runner semantics are aligned"

advanced_docs=0
for advanced_doc in "$PROJECT_DIR"/docs/03-advanced/[1-2][0-9]-*.md; do
  [[ -s "$advanced_doc" ]] && advanced_docs=$((advanced_docs + 1))
done
if [[ "$advanced_docs" == 8 ]] \
   && grep -Fq 'Capability placement' "$PROJECT_DIR/docs/03-advanced/README.md" \
   && grep -Fq 'Modules 15–22' "$SCRIPT_DIR/advanced-setup.sh" \
   && grep -Fq 'advanced-audit.md' "$SCRIPT_DIR/advanced-audit.sh" \
   && grep -Fq 'repository-audit.tsv' "$SCRIPT_DIR/advanced-audit.sh"; then
  pass "advanced Modules 15–22 have a complete crosswalk, tracker, and private audit"
else
  fail "advanced module documentation, tracker, or audit is incomplete"
fi

if grep -Fq 'all Homebrew formulae, all Homebrew casks' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'NONINTERACTIVE=1 /bin/bash "$uninstaller"' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'applications not installed by' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq '"$cask" == 1password' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq '"$cask" == docker-desktop' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq -- '--archive-1password-data' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq -- '--archive-ssh-private-keys' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq -- '--prepare-keychain-reset' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'application-inventory.md' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'Step 5 archive progress' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'archive progress: item' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq -- '--resume-cleanup' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'cd "$ARCHIVE_DIR"' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'moving ~/Developer cannot invalidate the current directory' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'Preview only.' "$SCRIPT_DIR/clean-development-state.sh" \
   && grep -Fq 'Refusing to guess which packages or files belong to the playbook.' "$SCRIPT_DIR/rollback-recorded-setup.sh" \
   && grep -Fq 'pre-existing or unrecorded — preserve' "$SCRIPT_DIR/remove-day-one-mac.sh" \
   && grep -Fq 'DEVELOPER_MODE=keep' "$SCRIPT_DIR/remove-day-one-mac.sh" \
   && grep -Fq 'REMOVE DAY ONE MAC' "$SCRIPT_DIR/remove-day-one-mac.sh" \
   && ! grep -Eq '(^|[[:space:]])diskutil([[:space:]]|$)|eraseDisk|rm[[:space:]]+-rf' \
        "$SCRIPT_DIR/clean-development-state.sh" "$SCRIPT_DIR/rollback-recorded-setup.sh" \
        "$SCRIPT_DIR/remove-day-one-mac.sh"; then
  pass "cleanup is preview-first, recoverable, and contains no disk-erasure command"
else
  fail "cleanup scope or safety guards are incomplete"
fi

if grep -Fq 'applications.tsv' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq $'category\\tname\\tversion\\tbundle_id\\tpath\\thomebrew_cask' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq "render_application_group 'Homebrew Applications'" "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq "render_application_group 'System Applications'" "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq "render_application_group 'Embedded or Other Bundles'" "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq 'repositories.tsv' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq 'NO-REMOTE' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq 'SHA256SUMS.txt' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq -- '--check-time-machine-latest' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq 'Stage 0 Step 1 — safety report preview' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq 'Review the completed safety report now?' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq '## Complete report index' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq '[Repository review](repositories.md)' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq '[Checksums](SHA256SUMS.txt)' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq '[[ "$GUIDED" == 1 && -t 0 && -t 1 ]] || return 0' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq 'SINGLE_VALUES=(route_a route_b unsure exit)' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq -- '--safety-report' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq -- '--status' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq -- '--prepare-backup-folder' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'Step 2 — verify the encrypted drive and copy the report' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'Step 3 — copy the selected backup snapshot and test a restore' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'Step 4 — preview exactly what cleanup would change' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'Step 5 — apply the reviewed account-preserving cleanup' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'APFSContainerReference' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'APFSPhysicalStores.0.APFSPhysicalStore' "$SCRIPT_DIR/lib/apfs-volume.sh" \
   && grep -Fq 'PhysicalStores.0.DeviceIdentifier' "$SCRIPT_DIR/lib/apfs-volume.sh" \
   && grep -Fq 'DesignatedPhysicalStore' "$SCRIPT_DIR/lib/apfs-volume.sh" \
   && grep -Fq 'mounted_device_for_path' "$SCRIPT_DIR/lib/apfs-volume.sh" \
   && grep -Fq 'diskutil info -plist "$mounted_device"' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq -- '--backup-only --in-progress-file' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq -- '--resume-snapshot' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'The wizard is closing now so it does not inspect paths that Step 5 may already have archived.' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'existing-mac-restore-confirmed' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'existing-mac-backup-folder' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'existing-mac-last-result' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'Saved completion status' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'backup_folder_status_reason' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'Reset and re-run Step 1 — keeps old reports and backup files' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'reset-history/Step-1-' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'Safety Report - $STAMP' "$SCRIPT_DIR/preflight-audit.sh" \
   && grep -Fq -- '--preflight-report' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'encrypted external APFS' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'ACCOUNT PRESERVING CLEANUP' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'confirm_repair_assistant_ready' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && grep -Fq 'Repair Assistant' "$PROJECT_DIR/docs/00-preflight/00-existing-mac-decision.md" \
   && grep -Fq 'exec "$CLEAN_SCRIPT" --execute' "$SCRIPT_DIR/prepare-existing-mac.sh" \
   && ! grep -Eq 'eraseDisk|diskutil[[:space:]]+erase|rm[[:space:]]+-rf|brew[[:space:]]+uninstall|docker[[:space:]]+(stop|rm)' \
        "$SCRIPT_DIR/preflight-audit.sh" "$SCRIPT_DIR/prepare-existing-mac.sh" "$SCRIPT_DIR/lib/apfs-volume.sh"; then
  pass "Stage 0 is private, report-first, backup-gated, and delegates cleanup safely"
else
  fail "Stage 0 inventory, backup gates, reporting, or safety boundary is incomplete"
fi

if grep -Fq $'Navigation\teza\t' "$PROJECT_DIR/config/optional-formulae.tsv" \
   && grep -Fq $'Shell\tzsh-autosuggestions\t' "$PROJECT_DIR/config/optional-formulae.tsv" \
   && grep -Fq $'Containers\tlazydocker\t' "$PROJECT_DIR/config/optional-formulae.tsv" \
   && grep -Fq 'This script only installs selected formulae' "$SCRIPT_DIR/configure-cli-tools.sh"; then
  pass "optional CLI catalogue includes requested tools and is installation-only"
else
  fail "optional CLI catalogue or selector policy is incomplete"
fi

if grep -Fq 'databases) shift; exec "$PROJECT_ROOT/scripts/configure-databases.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq -- '--services CSV' "$SCRIPT_DIR/configure-databases.sh" \
   && grep -Fq 'Existing containers and named volumes are preserved.' "$SCRIPT_DIR/configure-databases.sh" \
   && grep -Fq 'Install or resume the selected database services now' "$SCRIPT_DIR/bootstrap-day-one-mac.sh" \
   && grep -Fq "optional) target=\"\$RUNTIME_ROOT/docs/02-optional/README.md\"" "$SCRIPT_DIR/runtime-manager.sh"; then
  pass "optional database selections have a resumable installer and explicit verification"
else
  fail "optional database installer or selector handoff is incomplete"
fi

if grep -Fq 'if [[ "${1:-}" == --status ]]' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'optional-status|modules) shift; exec "$PROJECT_ROOT/scripts/optional-status.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq -- '--audit' "$SCRIPT_DIR/optional-status.sh" \
   && grep -Fq 'Modules 09–22' "$SCRIPT_DIR/optional-status.sh" \
   && grep -Fq 'OPTIONAL-STATUS.md' "$PROJECT_DIR/docs/20-reference/README.md"; then
  pass "Modules 09–22 have one read-only status and audit dashboard"
else
  fail "unified optional and advanced status dashboard is incomplete"
fi

if grep -Fq $'core\talways\tstatus\tDay One · Status\td1s\t' "$PROJECT_DIR/config/raycast-commands.tsv" \
   && grep -Fq $'Recommended\tEveryone\tWarp\twarpdotdev\t' "$PROJECT_DIR/config/raycast-extensions.tsv" \
   && grep -Fq -- '--remove-generated' "$SCRIPT_DIR/configure-raycast.sh" \
   && grep -Fq 'refusing to replace an unmanaged directory' "$SCRIPT_DIR/configure-raycast.sh" \
   && grep -Fq 'No generated command contains --execute' "$SCRIPT_DIR/configure-raycast.sh" \
   && ! grep -Eq 'brew[[:space:]]+uninstall|diskutil[[:space:]]+erase' "$SCRIPT_DIR/configure-raycast.sh"; then
  pass "Raycast command catalogue is selection-aware, managed, and preview-safe"
else
  fail "Raycast command manager, extension catalogue, or safety boundary is incomplete"
fi

run_fixture "Day One Mac regression fixture passes" \
  "Day One Mac regression fixture failed" \
  "$SCRIPT_DIR/tests/test-day-one-mac.sh" || true

run_fixture "optional database installer is idempotent and diagnostic" \
  "optional database installer regression fixture failed" \
  "$SCRIPT_DIR/tests/test-configure-databases.sh" || true

run_fixture "unified optional and advanced dashboard reports evidence safely" \
  "unified optional and advanced dashboard fixture failed" \
  "$SCRIPT_DIR/tests/test-optional-status.sh" || true

run_fixture "Homebrew, external, App Store, missing, and conflict application fixtures pass" \
  "application ownership and provenance regression fixture failed" \
  "$SCRIPT_DIR/tests/test-application-ownership.sh" || true

run_fixture "Stage 0 preflight regression fixture passes" \
  "Stage 0 preflight regression fixture failed" \
  "$SCRIPT_DIR/tests/test-preflight.sh" || true

run_fixture "secret scan, SSH identity pairing, and validator dependency fixtures pass" \
  "secret scan, SSH identity pairing, or validator dependency fixture failed" \
  "$SCRIPT_DIR/tests/test-secret-scan-and-ssh.sh" || true

run_fixture "1Password CLI integration, deadline, and track key-type fixtures pass" \
  "1Password CLI integration, deadline, or track key-type fixture failed" \
  "$SCRIPT_DIR/tests/test-phase3-onepassword.sh" || true

run_fixture "standalone runtime installs before Phase 1 and survives source removal" \
  "portable dispatcher installation or checkout resolution fixture failed" \
  "$SCRIPT_DIR/tests/test-portable-command.sh" || true

run_fixture "chezmoi preserves custom tools and uses VS Code only for human review" \
  "chezmoi VS Code diff and merge regression fixture failed" \
  "$SCRIPT_DIR/tests/test-chezmoi-vscode-tools.sh" || true

run_fixture "login and non-login shell PATH and the login-shell switch pass" \
  "shell PATH or login-shell switch fixture failed" \
  "$SCRIPT_DIR/tests/test-shell-environment.sh" || true

run_fixture "immutable projectless task creation, metadata, and boundaries pass" \
  "projectless workspace manager regression fixture failed" \
  "$SCRIPT_DIR/tests/test-workspace-manager.sh" || true

run_fixture "track-aware Raycast commands and extension catalogue pass" \
  "Raycast command manager regression fixture failed" \
  "$SCRIPT_DIR/tests/test-raycast-manager.sh" || true

if "$SCRIPT_DIR/validate-warp-drive.sh" >/dev/null; then
  pass "Day One Mac Warp Drive bundle passes its safety and drift checks"
else
  fail "Day One Mac Warp Drive bundle validation failed"
fi

if "$PROJECT_DIR/second-brain/obsidian/scripts/validate.sh" >/dev/null; then
  pass "Obsidian Second Brain guides, assets, and setup fixture pass"
else
  fail "Obsidian Second Brain validation failed"
fi

if "$PROJECT_DIR/second-brain/notion/scripts/tests/test-notion-second-brain-manager.sh" >/dev/null; then
  pass "Notion Second Brain planner and generated helper fixture pass"
else
  fail "Notion Second Brain validation failed"
fi

if [[ "$FAILURES" -gt 0 ]]; then
  ui_error "$FAILURES validation check(s) need attention."
  exit 1
fi

ui_success 'Structural and targeted semantic validation passed for Day One Mac.'
