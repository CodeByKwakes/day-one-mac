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
# The sourced contributor inventory above defines this array.
# shellcheck disable=SC2154
for relative in "${required_docs[@]}"; do
  if [[ ! -s "$PROJECT_DIR/$relative" ]]; then
    fail "missing or empty document: $relative"
    missing=1
  fi
done
[[ "$missing" == 0 ]] && pass "all required and optional documents are present"

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
      "$PROJECT_DIR/docs/setup/manual/maintenance.md" \
   && grep -Fq 'Purge is never invoked by a Day One Mac script' \
      "$PROJECT_DIR/docs/setup/manual/maintenance.md"; then
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
    /^<a id="[a-z0-9_-]+"><\/a>$/ {
      anchor=$0
      sub(/^<a id="/, "", anchor)
      sub(/"><\/a>$/, "", anchor)
      if (anchor == wanted) found=1
    }
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
run_fixture "runtime inventory and guide ownership are consistent" "project layout failed" node "$PROJECT_DIR/tools/check-project-layout.cjs" || true
run_fixture "VS Code reference matches configuration" "VS Code reference drift" node "$PROJECT_DIR/tools/sync-vscode-reference.cjs" --check || true
run_fixture "Warp workflows use current, bounded commands" "Warp workflow validation failed" "$PROJECT_DIR/src/modules/validate-warp-drive.sh" || true
if [[ "$VALIDATION_MODE" == --all ]]; then
  source "$PROJECT_DIR/tools/validation/regressions.sh"
fi
[[ "$FAILURES" == 0 ]] || { ui_error "$FAILURES validation check(s) need attention."; exit 1; }
ui_success 'Structural and targeted semantic validation passed for Day One Mac.'
