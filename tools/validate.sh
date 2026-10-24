#!/usr/bin/env bash
# Validate the self-contained Day One Mac project without changing the Mac.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../src/core/terminal-ui.sh"
FAILURES=0
source "$PROJECT_DIR/tools/validation/inventory.sh"
VALIDATION_MODE="${1:---all}"
case "$VALIDATION_MODE" in --all|--static|--regressions) ;; *) printf 'Usage: tools/validate.sh [--all|--static|--regressions]\n' >&2; exit 2 ;; esac
[[ $# -le 1 ]] || exit 2
STANDALONE_RUNTIME=0
if [[ -f "$PROJECT_DIR/SHA256SUMS" && ! -d "$PROJECT_DIR/.git" ]]; then
  STANDALONE_RUNTIME=1
fi

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
  shift 2
  set +e
  # </dev/null as well as the fixture's own guard: a fixture that blocks on a
  # prompt would hang the validator, and Phase 8 runs this from a real
  # terminal where stdin is a TTY.
  output="$("$@" 2>&1 </dev/null)"
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

if [[ "$VALIDATION_MODE" == --regressions ]]; then
  source "$PROJECT_DIR/tools/validation/regressions.sh"
  [[ "$FAILURES" == 0 ]] || exit 1
  ui_success 'Integration regressions passed for Day One Mac.'
  exit 0
fi
ui_title '🧪' 'Day One Mac static validation'

# Several checks below use ripgrep. Without it they would silently examine
# nothing and still report a pass, so stop here instead of validating nothing.
if ! command -v rg >/dev/null 2>&1; then
  fail "ripgrep (rg) is required by this validator but was not found on PATH."
  printf 'Install it with '\''brew install ripgrep'\'', then rerun this validator.\n' >&2
  exit 1
fi


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
for phase_doc in "$PROJECT_DIR"/docs/setup/assisted/0[1-8]-*.md; do
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
' "$PROJECT_DIR/config/catalogs/applications.tsv"; then
  fail "application catalogue has an invalid, duplicate, or incomplete row"
  catalog_failed=1
fi

if rg_scan -n -i \
  -e 'fresh-start|fresh[ -]mac|\.fresh-mac-setup|FRESH_START|older 20-phase|legacy playbook|zam-state|mac-setup' \
  "$PROJECT_DIR/docs" "$PROJECT_DIR/second-brain" \
  --glob '*.md' --glob '!UPGRADE-NOTES.md' --glob '!upgrade-notes.md'; then
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
      "$PROJECT_DIR/config/catalogs/applications.tsv"; then
    fail "application catalogue is missing: $app_id"
    catalog_failed=1
  fi
done

if awk -F '\t' '
  $1 == "purge" && $2 == "optional" && $3 == "21" \
    && $5 == "jithin-sabu/tap/purge" && $6 == "app" \
    && $7 == "/Applications/Purge.app" && $8 == "io.getpurge.app" {found=1}
  END {exit !found}
' "$PROJECT_DIR/config/catalogs/applications.tsv" \
   && grep -Fq 'Leave scheduled cleaning disabled.' \
      "$PROJECT_DIR/docs/setup/assisted/advanced/21-audit-maintenance-and-rebuild.md" \
   && grep -Fq 'Purge is never invoked by a Day One Mac script' \
      "$PROJECT_DIR/docs/setup/assisted/advanced/21-audit-maintenance-and-rebuild.md"; then
  pass "Purge remains optional, fully qualified, and manual at every destructive boundary"
else
  fail "Purge catalogue identity or manual-only safety guidance has drifted"
  catalog_failed=1
fi

if [[ "$(sed -n '1p' "$PROJECT_DIR/config/catalogs/optional-formulae.tsv")" != $'# group\tformula\tpurpose' ]] \
   || ! awk -F '\t' '
      NR == 1 {next}
      NF != 3 {exit 1}
      $1 == "" || $2 !~ /^[a-z0-9@+._-]+$/ || $3 == "" {exit 1}
      seen[$2]++ {exit 1}
      END {if (NR < 2) exit 1}
    ' "$PROJECT_DIR/config/catalogs/optional-formulae.tsv"; then
  fail "optional formula catalogue must have its canonical tab-separated header and three complete columns"
  catalog_failed=1
fi

for formula in actionlint mas; do
  if ! awk -F '\t' -v wanted="$formula" \
      '$0 !~ /^#/ && $2 == wanted {found=1} END {exit !found}' \
      "$PROJECT_DIR/config/catalogs/optional-formulae.tsv"; then
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

# Vendor patch numbers are no longer setup prerequisites. Keep the provider's
# authoritative instructions next to the manually owned authentication task.
if grep -Fq 'https://developer.1password.com/docs/ssh/agent/config/' \
  "$PROJECT_DIR/docs/setup/manual/security/1password.md"; then
  pass "manual authentication task links to current provider configuration documentation"
else
  fail "manual authentication task lacks its provider configuration source"
fi


while IFS= read -r -d '' source_script; do
  required_scripts+=("../${source_script#"$PROJECT_DIR"/}")
done < <(find "$PROJECT_DIR/src" -type f -name '*.sh' -print0)

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

if grep -Fq 'exec bash "$HERE/../src/setup/setup.sh" "$@"' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq 'select_toggles()' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq 'ui_menu_help single' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq 'Enter/Space: choose' "$SCRIPT_DIR/../src/core/terminal-ui.sh" \
   && grep -Fq "' ') SINGLE_RESULT=" "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq '🔒 Phase 1' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq 'Save choices and begin or resume setup' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq 'wizard-selections.md' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq 'post_required_menu' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq 'Optional setup remains locked until required Phase 8 is complete.' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && ! sed -n '/^configure_wizard()/,/^}/p' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" | grep -Fq 'choose_optional_plan' \
   && grep -Fq -- '--new-dotfiles' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq -- '--local-dotfiles' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'day_one_require_apple_silicon' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'verify_apple_developer_tools' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'for phase in 01 02 03 04 05 06 07 08' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'uses_chezmoi && printf' "$PROJECT_DIR"/src/setup/*.sh \
   && grep -Fq 'uses_starship && printf' "$PROJECT_DIR"/src/setup/*.sh \
   && grep -Fq 'configuration_validate_choices' "$PROJECT_DIR"/src/setup/*.sh \
   && grep -Fq 'folders_apply' "$SCRIPT_DIR/../src/setup/phases/04-hosting.sh" \
   && grep -Fq 'git config --global push.autoSetupRemote true' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'git config --global core.excludesFile' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'if [[ "$PRIMARY_IDE" == vscode ]]' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'Use VS Code for Git and chezmoi editing?' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq '"$HOME/.gitignore_global"' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq '2) printf '\''Azure DevOps only' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq '3) printf '\''GitHub + Azure DevOps' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'run_installation_centre()' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'installation_centre_done()' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq -- '--install-centre' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'Required Installation Centre' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'day_one_required_application_ids' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'report_application "$DAY_ONE_APP_NAME" "$app_id"' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'applications) shift; exec' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'install) shift; exec' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'External installation (Company Portal or manual)' "$SCRIPT_DIR/../src/core/application-ownership.sh" \
   && grep -Fq 'existing_managed_source=1' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'eval "$(starship init zsh)"' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'runner_wrapper="$HOME/.local/bin/day-one-mac"' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'migrate_legacy_managed_launcher' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'run chezmoi forget "$target"' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
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
   && grep -Fq 'DAY_ONE_MAC_STATE_ROOT' "$SCRIPT_DIR/../src/core/project-paths.sh" \
   && grep -Fq 'NO_COLOR' "$SCRIPT_DIR/../src/core/terminal-ui.sh" \
   && grep -Fq 'ui_title()' "$SCRIPT_DIR/../src/core/terminal-ui.sh" \
   && grep -Fq 'FRESH_START_STATE_ROOT' "$SCRIPT_DIR/../src/core/project-paths.sh" \
   && grep -Fq 'legacy_runner="$HOME/.local/bin/fresh-start"' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'save_state_value project-root "$PROJECT_DIR"' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'exec "$PROJECT_ROOT/scripts/advanced-setup.sh" "$@"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'advanced-audit|audit) shift; exec' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'PHASE_SCHEMA_05=16' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'PHASE_SCHEMA_08=12' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'PHASE_SCHEMA_01=5' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq '.config/zsh/path.zsh' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq '.config/zsh/aliases.zsh' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'HTTPS Git authentication selected; no SSH identity is configured.' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'Directory Services login shell' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'run_macos_settings_checkpoint' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'verify_dotfiles_remote' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'verify_local_dotfiles_source' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq '"$SCRIPT_DIR/../src/operations/verify.sh" || return "$EX_GATE"' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'Completed in this attempt:' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'Still required:' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'preview record compaction with: day-one-mac finalize' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   && grep -Fq 'Optional databases, AI, MCP and VS Code profiles are not run here.' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh; then
  pass "wizard feeds the resumable runner with independent configuration, shell and prompt choices"
else
  fail "wizard, runner phase flow, or required base components are incomplete"
fi

semantic_failed=0
release_manifest_version="$(sed -n 's/^[[:space:]]*"\.":[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$PROJECT_DIR/.release-please-manifest.json")"
project_version="$(sed -n '1p' "$PROJECT_DIR/VERSION")"
package_version="$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$PROJECT_DIR/package.json" | head -1)"
if [[ "$release_manifest_version" != "$project_version" ]] \
   || [[ "$package_version" != "$project_version" ]] \
   || ! grep -Fq '"version-file": "VERSION"' "$PROJECT_DIR/release-please-config.json" \
   || ! grep -Fq '"path": "package.json"' "$PROJECT_DIR/release-please-config.json" \
   || ! grep -Fq '"jsonpath": "$.version"' "$PROJECT_DIR/release-please-config.json"; then
  fail "Release Please version records are incomplete or disagree"
  semantic_failed=1
else
  pass "Release Please version records agree"
fi

if [[ "$STANDALONE_RUNTIME" == 1 ]]; then
  pass "standalone runtime correctly omits repository-only Release Please workflow metadata"
elif grep -Fq 'workflows: [Validate]' "$PROJECT_DIR/.github/workflows/release.yml" \
   && grep -Fq "github.event.workflow_run.conclusion == 'success'" "$PROJECT_DIR/.github/workflows/release.yml" \
   && grep -Fq 'googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7' "$PROJECT_DIR/.github/workflows/release.yml" \
   && grep -Fq 'token: ${{ secrets.RELEASE_PLEASE_TOKEN }}' "$PROJECT_DIR/.github/workflows/release.yml" \
   && grep -Fq 'steps.candidate.outputs.ready' "$PROJECT_DIR/.github/workflows/release.yml" \
   && grep -Fq 'gh release upload "$RELEASE_TAG"' "$PROJECT_DIR/.github/workflows/release.yml"; then
  pass "Release Please drafts candidates; exact-candidate validation gates publication"
else
  fail "Release Please validation gate, action pin, or asset publication has drifted"
  semantic_failed=1
fi

if grep -Fq '"prepare": "husky"' "$PROJECT_DIR/package.json" \
   && grep -Fq '"*.{md,mdx}": "markdownlint-cli2"' "$PROJECT_DIR/package.json" \
   && grep -Fq '"CHANGELOG.md"' "$PROJECT_DIR/.markdownlint-cli2.jsonc" \
   && grep -Fq 'node_modules/.bin/commitlint --edit "$1"' "$PROJECT_DIR/.husky/commit-msg" \
   && grep -Fq 'node_modules/.bin/lint-staged' "$PROJECT_DIR/.husky/pre-commit" \
   && grep -Fq 'tools/validate.sh' "$PROJECT_DIR/.husky/pre-push"; then
  pass "contributor hooks enforce conventional commits and delegated linting"
else
  fail "contributor hook or lint integration has drifted"
  semantic_failed=1
fi

if [[ "$STANDALONE_RUNTIME" == 1 ]]; then
  pass "standalone runtime correctly omits repository-only CI workflow metadata"
elif grep -Fq 'pnpm exec commitlint' "$PROJECT_DIR/.github/workflows/validate.yml" \
   && grep -Fq 'run: pnpm run lint' "$PROJECT_DIR/.github/workflows/validate.yml"; then
  pass "CI enforces conventional commits and delegated linting"
else
  fail "CI conventional-commit or lint integration has drifted"
  semantic_failed=1
fi
if rg -n 'raw\.githubusercontent\.com/CodeByKwakes/day-one-mac/main/install-day-one-mac|CodeByKwakes/MacOS|└── MacOS/' \
  "$PROJECT_DIR" --glob '*.md' --glob '!node_modules/**' >/dev/null 2>&1; then
  fail "a guide still uses the moving main-branch installer or the retired monorepo layout"
  semantic_failed=1
fi
if rg -n '\./(bootstrap-day-one-mac|setup|prepare-existing-mac|preflight-audit|configure-macos-settings|configure-cli-tools|application-status|workspace-manager|remove-day-one-mac)\.sh' \
  "$PROJECT_DIR/docs/setup/existing-mac" \
  "$PROJECT_DIR/docs/setup/assisted" \
  "$PROJECT_DIR/docs/how-to/modules/optional" \
  "$PROJECT_DIR/docs/how-to/apps" \
  --glob '*.md' --glob '!03-account-preserving-cleanup.md' --glob '!command-reference.md' >/dev/null 2>&1; then
  fail "a normal user guide bypasses the standalone day-one-mac command"
  semantic_failed=1
fi
if ! grep -Fq 'releases/latest/download/install-day-one-mac' "$PROJECT_DIR/docs/setup/assisted/runtime.md" \
   || ! grep -Fq 'Move an already-completed Mac to standalone mode' \
      "$PROJECT_DIR/docs/setup/assisted/runtime.md" \
   || ! grep -Fq 'active versioned runtime' \
      "$PROJECT_DIR/docs/setup/assisted/08-verify-and-reproduce.md"; then
  fail "standalone installation, migration, or Phase 8 runtime guidance is incomplete"
  semantic_failed=1
fi
if rg -n '^cd day-one-mac/' "$PROJECT_DIR" \
  --glob '*.md' --glob '!node_modules/**' >/dev/null 2>&1; then
  fail "a guide still assumes the reader's current directory with 'cd day-one-mac/...'"
  semantic_failed=1
fi
if node "$PROJECT_DIR/tools/check-project-layout.cjs"; then
  pass "canonical paths, compatibility guides and runtime inventory agree"
else
  fail "project layout or catalogue validation failed"
fi
if node "$PROJECT_DIR/tools/sync-vscode-reference.cjs" --check; then
  pass "generated profile reference matches canonical configuration"
else
  fail "generated profile reference is stale"
fi
if grep -Fq '~/.config/Code/User/settings.json' \
  "$PROJECT_DIR/docs/setup/assisted/advanced/15-full-dotfiles-and-bootstrap.md"; then
  fail "the advanced dotfiles guide still uses the non-macOS VS Code settings path"
  semantic_failed=1
fi
if grep -Fq 'Capture to Second Brain' "$PROJECT_DIR/docs/setup/manual/second-brain/obsidian/raycast.md" \
   || grep -Fq 'Open Second Brain Dashboard' "$PROJECT_DIR/docs/setup/manual/second-brain/obsidian/raycast.md"; then
  fail "the Raycast guide still uses retired dynamic command names"
  semantic_failed=1
fi
if grep -Fq 'The user request' "$PROJECT_DIR/docs/setup/assisted/recovery/rollback.md" \
   || ! grep -Fq 'cp -p "$RECOVERY/home/.config/starship.toml"' "$PROJECT_DIR/docs/setup/assisted/recovery/rollback.md"; then
  fail "rollback guidance contains conversation residue or removes its recovery copy"
  semantic_failed=1
fi
if ! grep -Fq 'docker inspect --format=' "$PROJECT_DIR/docs/setup/manual/databases/containers.md" \
   || ! grep -Fq -- "--health-cmd='mongosh" "$PROJECT_DIR/docs/setup/manual/databases/containers.md"; then
  fail "MongoDB documentation promises health without defining and inspecting a health check"
  semantic_failed=1
fi
if ! grep -Fq -- '--tools raycast' "$PROJECT_DIR/docs/setup/assisted/optional/second-brain.md" \
   || ! grep -Fq -- '--tools|--stack' "$PROJECT_DIR/extensions/second-brain/obsidian/scripts/setup-second-brain.sh" \
   || grep -Fq '| **Multi domain**' "$PROJECT_DIR/docs/setup/assisted/optional/second-brain.md"; then
  fail "Second Brain user-facing commands or layout names have drifted from the dynamic manager"
  semantic_failed=1
fi
# Phase 3 must still state the recommended default and point at the reference.
if ! grep -Fq 'Application and terminal session' "$PROJECT_DIR/docs/setup/manual/security/1password.md" \
   || ! grep -Fq 'Until 1Password locks' "$PROJECT_DIR/docs/setup/manual/security/1password.md" \
   || ! grep -Fq '../manual/security/1password.md' "$PROJECT_DIR/docs/setup/assisted/03-security-and-ssh.md"; then
  fail "Phase 3 does not state the SSH approval default or link to the approval guide"
  semantic_failed=1
fi
# The full approval reference moved out of Phase 3; it must survive intact.
approval_guide="$PROJECT_DIR/docs/setup/manual/security/1password.md"
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
if ! grep -Fq 'Import Profile…' "$PROJECT_DIR/docs/setup/manual/editors/vscode.md" \
   || ! grep -Fq '.code-profile' "$PROJECT_DIR/docs/setup/manual/editors/vscode.md" \
   || ! grep -Fq 'clear all cloud data' "$PROJECT_DIR/docs/setup/manual/editors/vscode.md" \
   || ! grep -Fq 'Settings Sync is intentionally on or intentionally off' "$PROJECT_DIR/docs/setup/manual/editors/vscode.md"; then
  fail "VS Code app guide is missing selective import, export, sync reset, or verification guidance"
  semantic_failed=1
fi
if ! grep -Fq 'Security controls are reviewed manually' "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" \
   || ! grep -Fq 'spctl --master-disable' "$PROJECT_DIR/docs/setup/assisted/MACOS-SETTINGS.md" \
   || ! grep -Fq 'OPTION_GROUPS=(' "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" \
   || grep -Eq '^GROUPS=' "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" \
   || ! grep -Fq 'validate_option_catalog' "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" \
   || ! grep -Fq '*[Ff]loat*) type=float' "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" \
   || ! grep -Fq 'bool:1|bool:true) value=true' "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" \
   || grep -Eq '^[[:space:]]*spctl[[:space:]]+--master-disable' "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" \
   || ! grep -Fq -- '--restore' "$SCRIPT_DIR/../src/modules/configure-macos-settings.sh" \
   || ! grep -Fq 'macos-settings-status' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh; then
  fail "early macOS settings wizard, security boundary, or restore path is incomplete"
  semantic_failed=1
fi
if ! grep -Fq 'Create a new GitHub Ed25519 key' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || ! grep -Fq 'Azure DevOps RSA 3072-bit key' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || ! grep -Fq '# >>> Day One Mac: 1Password SSH agent >>>' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || ! grep -Fq 'Host github.com' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || ! grep -Fq 'Host ssh.dev.azure.com' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || ! grep -Fq 'configure_onepassword_ssh' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || ! grep -Fq 'update_homebrew_1password_if_needed' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || ! grep -Fq 'Import a trusted existing key' "$PROJECT_DIR/docs/setup/assisted/03-security-and-ssh.md" \
   || ! grep -Fq 'Step 3.7 — Pin provider keys when needed' "$PROJECT_DIR/docs/setup/assisted/03-security-and-ssh.md" \
   || ! grep -Fq 'Azure DevOps: use RSA' "$PROJECT_DIR/docs/setup/manual/security/1password.md" \
   || ! grep -Fq -- '--web --skip-ssh-key' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || grep -Eq 'gh auth login .*--web[[:space:]]*$' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh; then
  fail "Phase 3 does not cover provider-compatible new keys, existing-key import, and Track 3 routing"
  semantic_failed=1
fi
if ! grep -Fq 'Export Settings & Data' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq '.rayconfig' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'import is additive' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'Path A - Use Raycast alongside Spotlight' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'Path B - Use Raycast as the only keyboard launcher' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'Raycast uses `⌥Space` in both supported paths' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'Keep Spotlight indexing enabled in both launcher modes' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'Divide search responsibilities' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'Fallback commands appear when Root Search has no direct match' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'Clipboard Search' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'Globally Allowed Tools' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md"; then
  fail "Raycast app guide is missing dual-mode shortcuts, indexing, export, import, or permission guidance"
  semantic_failed=1
fi
if ! grep -Fq 'https://www.raycast.com/download' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'existing installation owner is recorded' "$PROJECT_DIR/docs/setup/manual/apps/raycast.md" \
   || ! grep -Fq 'raycast-manual' "$PROJECT_DIR/docs/setup/assisted/integrations/raycast.md" \
   || ! grep -Fq 'Never add `--execute`' "$PROJECT_DIR/docs/setup/assisted/integrations/raycast.md" \
   || ! grep -Fq 'Bring Your Own Key' "$PROJECT_DIR/docs/setup/manual/apps/raycast-ai-providers.md" \
   || ! grep -Fq 'http://127.0.0.1:20128/v1' "$PROJECT_DIR/docs/setup/manual/apps/raycast-ai-providers.md" \
   || ! grep -Fq '.config/raycast/ai/providers.yaml' "$PROJECT_DIR/docs/setup/manual/apps/raycast-ai-providers.md"; then
  fail "Raycast manual installation, command, or provider guidance is incomplete"
  semantic_failed=1
fi
if ! grep -Fq 'Recommended global shortcut ownership' "$PROJECT_DIR/docs/setup/manual/apps/keyboard-shortcuts.md" \
   || ! grep -Fq 'That conflicts with 1Password' "$PROJECT_DIR/docs/setup/manual/apps/keyboard-shortcuts.md" \
   || ! grep -Fq 'Spotlight indexing remains enabled' "$PROJECT_DIR/docs/setup/manual/apps/keyboard-shortcuts.md" \
   || ! grep -Fq 'Raycast always owns `⌥Space`' "$PROJECT_DIR/docs/setup/manual/apps/keyboard-shortcuts.md" \
   || ! grep -Fq '⌘K ⌘S' "$PROJECT_DIR/docs/setup/manual/apps/keyboard-shortcuts.md"; then
  fail "application keyboard-shortcut reference is missing ownership, conflict, Spotlight, or editor guidance"
  semantic_failed=1
fi
if ! grep -Fq 'day-one-mac workspace --guided' "$PROJECT_DIR/docs/setup/assisted/optional/ai-workspaces.md" \
   || ! grep -Fq 'app-storage/codex-projectless' "$PROJECT_DIR/docs/setup/assisted/optional/ai-workspaces.md" \
   || ! grep -Fq 'app-storage/claude-cowork' "$PROJECT_DIR/docs/setup/assisted/optional/ai-workspaces.md" \
   || ! grep -Fq 'do not permanently add `~/Developer`' "$PROJECT_DIR/docs/setup/assisted/optional/ai-workspaces.md" \
   || ! grep -Fq 'CLAUDE.md -> AGENTS.md' "$PROJECT_DIR/docs/setup/assisted/optional/ai-workspaces.md" \
   || ! grep -Fq 'only one client should actively modify it at a time' "$PROJECT_DIR/docs/setup/assisted/optional/ai-workspaces.md" \
   || ! grep -Fq 'project.worktrees/' "$PROJECT_DIR/docs/setup/manual/git/multiple-identities.md" \
   || ! grep -Fq 'One AI client is the primary writer' "$PROJECT_DIR/docs/setup/manual/development/worktrees/README.md" \
   || ! grep -Fq 'never moves an active task' "$SCRIPT_DIR/../src/modules/workspace-manager.sh"; then
  fail "projectless-task and worktree documentation or manager semantics have drifted"
  semantic_failed=1
fi
if ! grep -Fq '## Complete portable command list' "$PROJECT_DIR/docs/setup/assisted/reference/command-reference.md" \
   || ! grep -Fq '`day-one-mac safety-report [options]`' "$PROJECT_DIR/docs/setup/assisted/reference/command-reference.md" \
   || ! grep -Fq '`day-one-mac workspace [command]`' "$PROJECT_DIR/docs/setup/assisted/reference/command-reference.md" \
   || ! grep -Fq '`./validate-warp-drive.sh`' "$PROJECT_DIR/docs/setup/assisted/reference/command-reference.md" \
   || ! grep -Fq '[Upgrade notes](../../../shared/upgrade-notes.md)' "$PROJECT_DIR/docs/setup/assisted/reference/command-reference.md"; then
  fail "command reference is missing portable, direct-script, maintenance, or upgrade coverage"
  semantic_failed=1
fi
if ! grep -Fq 'Shell (PS1)' "$PROJECT_DIR/docs/setup/manual/terminals/warp.md" \
   || ! grep -Fq 'Settings Sync' "$PROJECT_DIR/docs/setup/manual/terminals/warp.md" \
   || ! grep -Fq 'Export all Warp Drive objects' "$PROJECT_DIR/docs/setup/manual/terminals/warp.md" \
   || ! grep -Fq 'plain `.env`' "$PROJECT_DIR/docs/setup/manual/terminals/warp.md" \
   || ! grep -Fq 'claude auth status --text' "$PROJECT_DIR/docs/setup/manual/terminals/warp.md" \
   || ! grep -Fq 'codex login status' "$PROJECT_DIR/docs/setup/manual/terminals/warp.md" \
   || ! grep -Fq 'copilot login' "$PROJECT_DIR/docs/setup/manual/terminals/warp.md"; then
  fail "Warp app guide is missing Starship, sync, export, or secret-handling guidance"
  semantic_failed=1
fi
if ! grep -Fq 'For the script-assisted route, start the Day One Mac wizard' "$PROJECT_DIR/docs/setup/assisted/01-first-boot-and-decisions.md" \
   || ! grep -Fq '[Continue to early macOS settings →](MACOS-SETTINGS.md)' "$PROJECT_DIR/docs/setup/assisted/01-first-boot-and-decisions.md" \
   || ! grep -Fq '[← Early macOS settings](MACOS-SETTINGS.md)' "$PROJECT_DIR/docs/setup/assisted/02-command-line-foundation.md" \
   || ! grep -Fq 'Existing Homebrew found at' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh \
   || ! grep -Fq 'Choose one setup route' "$PROJECT_DIR/docs/START-HERE.md" \
   || ! grep -Fq 'day-one-mac finalize' "$PROJECT_DIR/docs/setup/assisted/05-dotfiles-and-shell.md" \
   || ! grep -Fq 'Required sequence' "$PROJECT_DIR/docs/setup/assisted/README.md" \
   || ! grep -Fq 'report_check "post-setup finalisation command" day-one-mac finalize --help' "$PROJECT_DIR"/src/setup/*.sh "$PROJECT_DIR"/src/setup/phases/*.sh; then
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
for advanced_doc in "$PROJECT_DIR"/docs/how-to/modules/advanced/[1-2][0-9]-*.md; do
  [[ -s "$advanced_doc" ]] && advanced_docs=$((advanced_docs + 1))
done
if [[ "$advanced_docs" == 8 ]] \
   && grep -Fq 'Capability placement' "$PROJECT_DIR/docs/setup/assisted/advanced/README.md" \
   && grep -Fq 'Modules 15–22' "$SCRIPT_DIR/../src/modules/advanced-setup.sh" \
   && grep -Fq 'advanced-audit.md' "$SCRIPT_DIR/../src/modules/advanced-audit.sh" \
   && grep -Fq 'repository-audit.tsv' "$SCRIPT_DIR/../src/modules/advanced-audit.sh"; then
  pass "advanced Modules 15–22 have a complete crosswalk, tracker, and private audit"
else
  fail "advanced module documentation, tracker, or audit is incomplete"
fi

if grep -Fq 'all Homebrew formulae, all Homebrew casks' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'NONINTERACTIVE=1 /bin/bash "$uninstaller"' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'applications not installed by' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq '"$cask" == 1password' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq '"$cask" == docker-desktop' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq -- '--archive-1password-data' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq -- '--archive-ssh-private-keys' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq -- '--prepare-keychain-reset' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'application-inventory.md' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'Step 5 archive progress' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'archive progress: item' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq -- '--resume-cleanup' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'cd "$ARCHIVE_DIR"' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'moving ~/Developer cannot invalidate the current directory' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'Preview only.' "$SCRIPT_DIR/../src/operations/clean-development-state.sh" \
   && grep -Fq 'Refusing to guess which packages or files belong to the playbook.' "$SCRIPT_DIR/../src/operations/rollback-recorded-setup.sh" \
   && grep -Fq 'pre-existing or unrecorded — preserve' "$SCRIPT_DIR/../src/operations/remove-day-one-mac.sh" \
   && grep -Fq 'DEVELOPER_MODE=keep' "$SCRIPT_DIR/../src/operations/remove-day-one-mac.sh" \
   && grep -Fq 'REMOVE DAY ONE MAC' "$SCRIPT_DIR/../src/operations/remove-day-one-mac.sh" \
   && ! grep -Eq '(^|[[:space:]])diskutil([[:space:]]|$)|eraseDisk|rm[[:space:]]+-rf' \
        "$SCRIPT_DIR/../src/operations/clean-development-state.sh" "$SCRIPT_DIR/../src/operations/rollback-recorded-setup.sh" \
        "$SCRIPT_DIR/../src/operations/remove-day-one-mac.sh"; then
  pass "cleanup is preview-first, recoverable, and contains no disk-erasure command"
else
  fail "cleanup scope or safety guards are incomplete"
fi

if grep -Fq 'applications.tsv' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq $'category\\tname\\tversion\\tbundle_id\\tpath\\thomebrew_cask' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq "render_application_group 'Homebrew Applications'" "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq "render_application_group 'System Applications'" "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq "render_application_group 'Embedded or Other Bundles'" "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq 'repositories.tsv' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq 'NO-REMOTE' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq 'SHA256SUMS.txt' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq -- '--check-time-machine-latest' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq 'Stage 0 Step 1 — safety report preview' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq 'Review the completed safety report now?' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq '## Complete report index' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq '[Repository review](repositories.md)' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq '[Checksums](SHA256SUMS.txt)' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq '[[ "$GUIDED" == 1 && -t 0 && -t 1 ]] || return 0' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq 'SINGLE_VALUES=(route_a route_b unsure exit)' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq -- '--safety-report' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq -- '--status' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq -- '--prepare-backup-folder' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'Step 2 — verify the encrypted drive and copy the report' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'Step 3 — copy the selected backup snapshot and test a restore' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'Step 4 — preview exactly what cleanup would change' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'Step 5 — apply the reviewed account-preserving cleanup' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'APFSContainerReference' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'APFSPhysicalStores.0.APFSPhysicalStore' "$SCRIPT_DIR/../src/core/apfs-volume.sh" \
   && grep -Fq 'PhysicalStores.0.DeviceIdentifier' "$SCRIPT_DIR/../src/core/apfs-volume.sh" \
   && grep -Fq 'DesignatedPhysicalStore' "$SCRIPT_DIR/../src/core/apfs-volume.sh" \
   && grep -Fq 'mounted_device_for_path' "$SCRIPT_DIR/../src/core/apfs-volume.sh" \
   && grep -Fq 'diskutil info -plist "$mounted_device"' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq -- '--backup-only --in-progress-file' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq -- '--resume-snapshot' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'The wizard is closing now so it does not inspect paths that Step 5 may already have archived.' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'existing-mac-restore-confirmed' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'existing-mac-backup-folder' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'existing-mac-last-result' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'Saved completion status' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'backup_folder_status_reason' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'Reset and re-run Step 1 — keeps old reports and backup files' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'reset-history/Step-1-' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'Safety Report - $STAMP' "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" \
   && grep -Fq -- '--preflight-report' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'encrypted external APFS' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'ACCOUNT PRESERVING CLEANUP' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'confirm_repair_assistant_ready' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && grep -Fq 'Repair Assistant' "$PROJECT_DIR/docs/setup/assisted/existing-mac/00-existing-mac-decision.md" \
   && grep -Fq 'exec "$CLEAN_SCRIPT" --execute' "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" \
   && ! grep -Eq 'eraseDisk|diskutil[[:space:]]+erase|rm[[:space:]]+-rf|brew[[:space:]]+uninstall|docker[[:space:]]+(stop|rm)' \
        "$SCRIPT_DIR/../src/preflight/preflight-audit.sh" "$SCRIPT_DIR/../src/preflight/prepare-existing-mac.sh" "$SCRIPT_DIR/../src/core/apfs-volume.sh"; then
  pass "Stage 0 is private, report-first, backup-gated, and delegates cleanup safely"
else
  fail "Stage 0 inventory, backup gates, reporting, or safety boundary is incomplete"
fi

if grep -Fq $'Navigation\teza\t' "$PROJECT_DIR/config/catalogs/optional-formulae.tsv" \
   && grep -Fq $'Shell\tzsh-autosuggestions\t' "$PROJECT_DIR/config/catalogs/optional-formulae.tsv" \
   && grep -Fq $'Containers\tlazydocker\t' "$PROJECT_DIR/config/catalogs/optional-formulae.tsv" \
   && grep -Fq 'Only selected formulae are installed' "$SCRIPT_DIR/../src/modules/configure-cli-tools.sh"; then
  pass "optional CLI catalogue includes requested tools and is installation-only"
else
  fail "optional CLI catalogue or selector policy is incomplete"
fi

if grep -Fq 'databases) shift; exec "$PROJECT_ROOT/scripts/configure-databases.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq -- '--services CSV' "$SCRIPT_DIR/../src/modules/configure-databases.sh" \
   && grep -Fq 'Existing containers and named volumes are preserved.' "$SCRIPT_DIR/../src/modules/configure-databases.sh" \
   && grep -Fq 'Install or resume the selected database services now' "$SCRIPT_DIR/../src/cli/bootstrap-day-one-mac.sh" \
   && grep -Fq "optional) target=\"\$RUNTIME_ROOT/docs/setup/assisted/optional/README.md\"" "$SCRIPT_DIR/../src/runtime/runtime-manager.sh"; then
  pass "optional database selections have a resumable installer and explicit verification"
else
  fail "optional database installer or selector handoff is incomplete"
fi

if grep -Fq 'if [[ "$dashboard" == 1 ]]' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq 'optional-status|modules) shift; exec "$PROJECT_ROOT/scripts/optional-status.sh"' "$SCRIPT_DIR/day-one-mac" \
   && grep -Fq -- '--audit' "$SCRIPT_DIR/../src/modules/optional-status.sh" \
   && grep -Fq 'Modules 09–22' "$SCRIPT_DIR/../src/modules/optional-status.sh" \
   && grep -Fq 'optional-status.md' "$PROJECT_DIR/docs/setup/assisted/reference/README.md"; then
  pass "Modules 09–22 have one read-only status and audit dashboard"
else
  fail "unified optional and advanced status dashboard is incomplete"
fi

if grep -Fq $'core\talways\tstatus\tDay One · Status\td1s\t' "$PROJECT_DIR/config/catalogs/raycast-commands.tsv" \
   && grep -Fq $'Recommended\tEveryone\tWarp\twarpdotdev\t' "$PROJECT_DIR/config/catalogs/raycast-extensions.tsv" \
   && grep -Fq -- '--launcher-mode MODE' "$SCRIPT_DIR/../src/modules/configure-raycast.sh" \
   && grep -Fq 'alongside-spotlight|raycast-only' "$SCRIPT_DIR/../src/modules/configure-raycast.sh" \
   && grep -Fq 'Raycast Root Search: ⌥Space (both modes)' "$SCRIPT_DIR/../src/modules/configure-raycast.sh" \
   && grep -Fq -- '--remove-generated' "$SCRIPT_DIR/../src/modules/configure-raycast.sh" \
   && grep -Fq 'refusing to replace an unmanaged directory' "$SCRIPT_DIR/../src/modules/configure-raycast.sh" \
   && grep -Fq 'No generated command contains --execute' "$SCRIPT_DIR/../src/modules/configure-raycast.sh" \
   && ! grep -Eq 'brew[[:space:]]+uninstall|diskutil[[:space:]]+erase' "$SCRIPT_DIR/../src/modules/configure-raycast.sh"; then
  pass "Raycast command catalogue is selection-aware, managed, and preview-safe"
else
  fail "Raycast command manager, extension catalogue, or safety boundary is incomplete"
fi

if "$SCRIPT_DIR/../src/modules/validate-warp-drive.sh" >/dev/null; then
  pass "Day One Mac Warp Drive bundle passes its safety and drift checks"
else
  fail "Day One Mac Warp Drive bundle validation failed"
fi

if [[ "$VALIDATION_MODE" == --all ]]; then
  source "$PROJECT_DIR/tools/validation/regressions.sh"
fi
if [[ "$FAILURES" -gt 0 ]]; then
  ui_error "$FAILURES validation check(s) need attention."
  exit 1
fi

ui_success 'Structural and targeted semantic validation passed for Day One Mac.'
