#!/usr/bin/env bash
# Unified read-only status and audit dashboard for optional Modules 09–22.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"
source "$SCRIPT_DIR/lib/application-ownership.sh"

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
REPORT="$STATE_DIR/optional-and-advanced-audit.md"
ENVIRONMENT_REPORT=""
REPOSITORY_REPORT=""
AUDIT=0
CHECK_ONLY=0
PRINT_REPORT=0
FAILURES=0
REVIEWS=0
PARTIALS=0
PENDING=0
ENVIRONMENT_FAILED=0

MODULE_IDS=(09 10 10A 11 12 13 14 15 16 17 18 19 20 21 22)
STATUSES=()
DETAILS=()
ACTIONS=()
RESULT_STATUS=""
RESULT_DETAIL=""
RESULT_ACTION=""

usage() {
  cat <<'EOF'
Usage: ./optional-status.sh [options]

Show one read-only dashboard for optional and advanced Modules 09–22.

  --audit        run the deeper environment audit and write a combined report
  --check        exit non-zero when a selected module is not ready/current
  --stdout       print the Markdown report created by --audit
  --report PATH  write the module audit report to PATH; implies --audit
  -h, --help     show this help

Status and audit never install software, start containers, edit configuration,
or mark a checklist complete. Manual/UI modules remain partial until their
guide checklist is verified; Advanced 15–22 use their recorded fingerprints.
EOF
}

contains_csv() {
  case ",$1," in *",$2,"*) return 0 ;; *) return 1 ;; esac
}

state_value() {
  [[ -r "$STATE_DIR/$1" ]] && sed -n '1p' "$STATE_DIR/$1" || true
}

module_title() {
  case "$1" in
    09) printf 'Local databases\n' ;;
    10) printf 'AI clients\n' ;;
    10A) printf 'OmniRoute AI gateway\n' ;;
    11) printf 'MCP servers\n' ;;
    12) printf 'VS Code profiles\n' ;;
    13) printf 'Enhanced CLI tools\n' ;;
    14) printf 'Warp Drive\n' ;;
    15) printf 'Full dotfiles and bootstrap\n' ;;
    16) printf 'Brewfile, applications, and editor inventory\n' ;;
    17) printf 'Shell and package automation\n' ;;
    18) printf 'Hosting identities, Azure, and worktrees\n' ;;
    19) printf 'macOS, GUI, and local HTTPS\n' ;;
    20) printf 'Restore and migrate selected data\n' ;;
    21) printf 'Audit, maintenance, and rebuild\n' ;;
    22) printf 'Shared AI skills and MCP operations\n' ;;
  esac
}

module_doc() {
  case "$1" in
    09) printf '%s/docs/02-optional/09-databases.md\n' "$PROJECT_DIR" ;;
    10) printf '%s/docs/02-optional/10-ai-agents.md\n' "$PROJECT_DIR" ;;
    10A) printf '%s/docs/02-optional/10a-omniroute.md\n' "$PROJECT_DIR" ;;
    11) printf '%s/docs/02-optional/11-mcp-servers.md\n' "$PROJECT_DIR" ;;
    12) printf '%s/docs/02-optional/12-vscode-profiles.md\n' "$PROJECT_DIR" ;;
    13) printf '%s/docs/02-optional/13-enhanced-cli-tools.md\n' "$PROJECT_DIR" ;;
    14) printf '%s/docs/02-optional/14-warp-drive.md\n' "$PROJECT_DIR" ;;
    15) printf '%s/docs/03-advanced/15-full-dotfiles-and-bootstrap.md\n' "$PROJECT_DIR" ;;
    16) printf '%s/docs/03-advanced/16-brewfile-apps-and-editor.md\n' "$PROJECT_DIR" ;;
    17) printf '%s/docs/03-advanced/17-shell-and-package-automation.md\n' "$PROJECT_DIR" ;;
    18) printf '%s/docs/03-advanced/18-hosting-identities-azure-and-worktrees.md\n' "$PROJECT_DIR" ;;
    19) printf '%s/docs/03-advanced/19-macos-gui-and-local-https.md\n' "$PROJECT_DIR" ;;
    20) printf '%s/docs/03-advanced/20-restore-and-migrate.md\n' "$PROJECT_DIR" ;;
    21) printf '%s/docs/03-advanced/21-audit-maintenance-and-rebuild.md\n' "$PROJECT_DIR" ;;
    22) printf '%s/docs/03-advanced/22-ai-skills-and-mcp-operations.md\n' "$PROJECT_DIR" ;;
  esac
}

optional_token() {
  case "$1" in
    09) printf 'databases\n' ;;
    10) printf 'ai-clients\n' ;;
    10A) printf 'omniroute\n' ;;
    11) printf 'mcp-servers\n' ;;
    12) printf 'vscode-profiles\n' ;;
    13) printf 'enhanced-cli\n' ;;
    14) printf 'warp-drive\n' ;;
    15|16|17|18|19|20|21|22) printf 'advanced\n' ;;
  esac
}

set_result() {
  RESULT_STATUS="$1"
  RESULT_DETAIL="$2"
  RESULT_ACTION="$3"
}

module_is_selected() {
  local id="$1" token marker
  token="$(optional_token "$id")"
  contains_csv "$OPTIONAL_MODULES" "$token" && return 0
  if [[ "$id" =~ ^(15|16|17|18|19|20|21|22)$ ]]; then
    marker="$STATE_ROOT/advanced/completed/$id"
    [[ -f "$marker" ]] && return 0
  fi
  return 1
}

docker_ready() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

container_state() {
  docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{if .State.Running}}running{{else}}stopped{{end}}{{end}}' "$1" 2>/dev/null || printf 'missing\n'
}

check_09() {
  local services service container state ready=0 missing=0 total=0
  services="$(state_value database-services)"
  [[ -n "$services" ]] || { set_result blocked 'selected, but no database services are saved' 'Rerun `day-one-mac optional --guided` and choose at least one database.'; return; }
  docker_ready || { set_result blocked 'Docker server is not reachable' 'Start the application that owns the active Docker context, then run `day-one-mac databases --saved --check`.'; return; }
  for service in postgres redis mongodb; do
    contains_csv "$services" "$service" || continue
    total=$((total + 1))
    case "$service" in
      postgres) container=dev-postgres ;;
      redis) container=dev-redis ;;
      mongodb) container=dev-mongo ;;
    esac
    state="$(container_state "$container")"
    case "$state" in healthy|running) ready=$((ready + 1)) ;; *) missing=$((missing + 1)) ;; esac
  done
  if [[ "$total" -gt 0 && "$ready" -eq "$total" ]]; then
    set_result ready "$ready/$total selected database containers are running" 'No action required.'
  elif [[ "$ready" -gt 0 ]]; then
    set_result partial "$ready/$total selected database containers are running" 'Run `day-one-mac databases --saved` to resume the missing service.'
  else
    set_result pending "0/$total selected database containers are running" 'Run `day-one-mac databases --saved`.'
  fi
}

ai_app_id() {
  case "$1" in
    claude) printf 'claude-code\n' ;;
    codex) printf 'codex\n' ;;
    copilot-app) printf 'copilot-app\n' ;;
    copilot-cli) printf 'copilot-cli\n' ;;
    raycast-ai) printf 'raycast\n' ;;
    *) return 1 ;;
  esac
}

check_10() {
  local clients client app_id total=0 ready=0 review=0 old_ifs="$IFS" extensions=""
  clients="$(state_value ai-clients)"
  [[ -n "$clients" ]] || { set_result blocked 'selected, but no AI clients are saved' 'Rerun the Optional Setup Center and choose at least one AI client.'; return; }
  if command -v code >/dev/null 2>&1; then extensions="$(code --list-extensions 2>/dev/null || true)"; fi
  IFS=','
  for client in $clients; do
    IFS="$old_ifs"
    total=$((total + 1))
    if [[ "$client" == copilot-vscode ]]; then
      if grep -Eiq '^github\.copilot($|-chat$)' <<<"$extensions"; then ready=$((ready + 1)); fi
    elif app_id="$(ai_app_id "$client" 2>/dev/null)" && day_one_app_detect "$app_id"; then
      case "$DAY_ONE_APP_STATUS" in ready) ready=$((ready + 1)) ;; review) review=$((review + 1)) ;; esac
    fi
    IFS=','
  done
  IFS="$old_ifs"
  if [[ "$review" -gt 0 ]]; then
    set_result review "$ready/$total selected clients detected; $review installation result(s) need review" 'Run `day-one-mac applications --optional` and review ownership conflicts.'
  elif [[ "$ready" -eq "$total" ]]; then
    set_result partial 'all selected client payloads are installed; sign-in and provider configuration require manual verification' 'Complete the Optional 10 checklist.'
  elif [[ "$ready" -gt 0 ]]; then
    set_result partial "$ready/$total selected client payloads are installed" 'Install the missing clients, then complete sign-in verification.'
  else
    set_result pending "0/$total selected client payloads are installed" 'Follow Optional 10 to install and authenticate the selected clients.'
  fi
}

check_10a() {
  local state
  docker_ready || { set_result blocked 'Docker server is not reachable' 'Start Docker and follow Optional 10A.'; return; }
  state="$(container_state omniroute)"
  case "$state" in
    healthy|running) set_result partial "OmniRoute container is $state; provider, key, and client routing require manual verification" 'Complete the Optional 10A checklist.' ;;
    missing) set_result pending 'OmniRoute container is missing' 'Follow Optional 10A to create and configure the gateway.' ;;
    *) set_result blocked "OmniRoute container is $state" 'Inspect `docker logs --tail 100 omniroute`.' ;;
  esac
}

check_11() {
  local selected count=0 path
  selected="$(state_value mcp-servers)"
  [[ -n "$selected" ]] || { set_result blocked 'selected, but no MCP servers are saved' 'Rerun the Optional Setup Center and choose at least one MCP server.'; return; }
  for path in \
    "$HOME/.mcp.json" \
    "$HOME/.copilot/mcp-config.json" \
    "$HOME/Library/Application Support/Code/User/mcp.json"; do
    [[ -s "$path" ]] && count=$((count + 1))
  done
  if [[ -r "$HOME/.codex/config.toml" ]] \
     && grep -Eq '^\[mcp_servers\.[^]]+\]' "$HOME/.codex/config.toml"; then
    count=$((count + 1))
  fi
  if [[ -r "$HOME/.claude.json" ]] \
     && grep -Eq '"mcpServers"[[:space:]]*:' "$HOME/.claude.json"; then
    count=$((count + 1))
  fi
  if [[ "$count" -gt 0 ]]; then
    set_result partial "$count known MCP configuration file(s) found; trust, authentication, and client scope require manual verification" 'Complete the Optional 11 checklist and inspect each client independently.'
  else
    set_result pending 'no known MCP configuration file was found' 'Follow Optional 11 for only the selected clients and servers.'
  fi
}

check_12() {
  local profiles=""
  command -v code >/dev/null 2>&1 || { set_result blocked 'VS Code command is unavailable' 'Repair required Phase 7 before configuring profiles.'; return; }
  profiles="$(code --list-profiles 2>/dev/null || true)"
  if [[ -n "$profiles" ]]; then
    set_result partial 'VS Code reports profile data; purpose, exports, and account separation require manual verification' 'Complete the Optional 12 checklist.'
  else
    set_result partial 'VS Code is installed; keeping only the Default profile may be intentional' 'Review Optional 12 and verify whether additional profiles are needed.'
  fi
}

check_13() {
  local formula installed installed_count=0 missing_count=0 selected_count=0
  [[ -r "$STATE_ROOT/install-manifest.tsv" ]] || { set_result pending 'no optional formula installation is recorded' 'Run `day-one-mac cli-tools`.'; return; }
  installed="$(brew list --formula 2>/dev/null || true)"
  while IFS=$'\t' read -r kind formula; do
    [[ "$kind" == brew-formula && -n "$formula" ]] || continue
    grep -Fq $'\t'"$formula"$'\t' "$PROJECT_DIR/config/optional-formulae.tsv" || continue
    selected_count=$((selected_count + 1))
    if grep -Fqx "$formula" <<<"$installed"; then installed_count=$((installed_count + 1)); else missing_count=$((missing_count + 1)); fi
  done < "$STATE_ROOT/install-manifest.tsv"
  if [[ "$selected_count" -eq 0 ]]; then
    set_result pending 'no catalogue formula installed by Day One Mac is recorded' 'Run `day-one-mac cli-tools`.'
  elif [[ "$missing_count" -eq 0 ]]; then
    set_result ready "$installed_count recorded optional formula(s) are installed" 'No action required.'
  else
    set_result partial "$installed_count/$selected_count recorded optional formula(s) remain installed" 'Rerun `day-one-mac cli-tools` for the missing selections.'
  fi
}

check_14() {
  if "$SCRIPT_DIR/validate-warp-drive.sh" >/dev/null 2>&1; then
    set_result partial 'the bundled Warp Drive collection is valid; Warp import state cannot be read safely' 'Verify the import in Warp and complete the Optional 14 checklist.'
  else
    set_result blocked 'the bundled Warp Drive validation failed' 'Run `day-one-mac validate` and repair the reported bundle issue.'
  fi
}

check_advanced() {
  local id="$1" marker document expected recorded
  marker="$STATE_ROOT/advanced/completed/$id"
  document="$(module_doc "$id")"
  [[ -f "$marker" ]] || { set_result pending 'no verified completion fingerprint is recorded' "Run \`day-one-mac advanced --module $id\`, complete its checklist, then record it."; return; }
  expected="$(shasum -a 256 "$document" | awk '{print $1}')"
  recorded="$(sed -n '1p' "$marker")"
  if [[ "$expected" == "$recorded" ]]; then
    set_result ready 'completion fingerprint matches the current guide' 'No action required.'
  else
    set_result review 'the guide changed after completion was recorded' "Review Module $id and record completion again only after its checklist passes."
  fi
}

evaluate_module() {
  local id="$1"
  if ! module_is_selected "$id"; then
    set_result 'not selected' 'not present in the saved optional plan and no completion marker exists' 'No action required.'
    return
  fi
  case "$id" in
    09) check_09 ;;
    10) check_10 ;;
    10A) check_10a ;;
    11) check_11 ;;
    12) check_12 ;;
    13) check_13 ;;
    14) check_14 ;;
    15|16|17|18|19|20|21|22) check_advanced "$id" ;;
  esac
}

status_marker() {
  case "$1" in
    ready) printf '✓ ready\n' ;;
    partial) printf '◐ partial\n' ;;
    pending) printf '○ pending\n' ;;
    review) printf '⚠ review\n' ;;
    blocked) printf '✗ blocked\n' ;;
    'not selected') printf '– not selected\n' ;;
  esac
}

print_module() {
  local id="$1" marker line
  marker="$(status_marker "$RESULT_STATUS")"
  line="$(printf '%-14s %3s — %s' "$marker" "$id" "$(module_title "$id")")"
  case "$RESULT_STATUS" in
    ready) ui_status success "$line" ;;
    partial|review) ui_status warning "$line" ;;
    blocked) ui_status error "$line" ;;
    *) ui_status pending "$line" ;;
  esac
}

escape_table() {
  printf '%s' "$1" | tr '\n' ' ' | sed 's/|/\\|/g'
}

write_report() {
  local temporary id i report_dir
  report_dir="$(dirname "$REPORT")"
  mkdir -p "$report_dir"
  chmod 700 "$report_dir" 2>/dev/null || true
  temporary="$(mktemp "$report_dir/.optional-audit.XXXXXX")"
  {
    printf '# Optional and advanced module audit\n\n'
    printf -- '- Generated: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- Saved optional plan: `%s`\n' "${OPTIONAL_MODULES:-none}"
    printf -- '- State directory: `%s`\n\n' "$STATE_DIR"
    printf '| Module | Status | Evidence | Next action |\n'
    printf '|---:|---|---|---|\n'
    for ((i=0; i<${#MODULE_IDS[@]}; i++)); do
      id="${MODULE_IDS[$i]}"
      printf '| %s · %s | %s | %s | %s |\n' \
        "$id" "$(module_title "$id")" "${STATUSES[$i]}" \
        "$(escape_table "${DETAILS[$i]}")" "$(escape_table "${ACTIONS[$i]}")"
    done
    printf '\n## Status meanings\n\n'
    printf -- '- **ready:** the module has sufficient machine-verifiable evidence, or an Advanced guide fingerprint is current.\n'
    printf -- '- **partial:** automated evidence exists, but a manual/UI/security checklist still needs human verification.\n'
    printf -- '- **pending:** selected, but no completion evidence was found.\n'
    printf -- '- **review:** recorded completion or ownership evidence is stale or conflicting.\n'
    printf -- '- **blocked:** a selected prerequisite or runtime is unavailable.\n'
    printf -- '- **not selected:** the saved optional plan does not include the module.\n'
    printf '\n## Full environment audit\n\n'
    printf 'The required-base, repository, authentication, package, container, and advanced environment audit is stored at `%s`.\n' "$ENVIRONMENT_REPORT"
  } > "$temporary"
  chmod 600 "$temporary"
  mv "$temporary" "$REPORT"
}

while (( $# )); do
  case "$1" in
    --audit) AUDIT=1; shift ;;
    --check) CHECK_ONLY=1; shift ;;
    --stdout) PRINT_REPORT=1; AUDIT=1; shift ;;
    --report) [[ "$#" -ge 2 ]] || { ui_error '--report needs a path'; exit 2; }; REPORT="$2"; AUDIT=1; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) ui_error "unknown option: $1"; usage >&2; exit 2 ;;
  esac
done

OPTIONAL_MODULES="$(state_value optional-modules)"
ENVIRONMENT_REPORT="$(dirname "$REPORT")/advanced-audit.md"
REPOSITORY_REPORT="$(dirname "$REPORT")/repository-audit.tsv"
ui_title '📊' 'Optional and advanced module status'
ui_label 'Saved optional plan' "${OPTIONAL_MODULES:-none}"
ui_label 'State' "$STATE_DIR"
printf '\n'

for id in "${MODULE_IDS[@]}"; do
  evaluate_module "$id"
  STATUSES+=("$RESULT_STATUS")
  DETAILS+=("$RESULT_DETAIL")
  ACTIONS+=("$RESULT_ACTION")
  print_module "$id"
  case "$RESULT_STATUS" in
    partial) PARTIALS=$((PARTIALS + 1)) ;;
    pending) PENDING=$((PENDING + 1)) ;;
    review) REVIEWS=$((REVIEWS + 1)) ;;
    blocked) FAILURES=$((FAILURES + 1)) ;;
  esac
done

printf '\nSelected-module attention: %s blocked · %s review · %s partial · %s pending\n' \
  "$FAILURES" "$REVIEWS" "$PARTIALS" "$PENDING"

if [[ "$AUDIT" == 1 ]]; then
  ui_section '🩺' 'Full read-only audit'
  if [[ "$CHECK_ONLY" == 1 ]]; then
    if ! DAY_ONE_MAC_AUDIT_REPORT="$ENVIRONMENT_REPORT" \
      DAY_ONE_MAC_REPO_REPORT="$REPOSITORY_REPORT" \
      "$SCRIPT_DIR/advanced-audit.sh" --check >/dev/null; then
      ENVIRONMENT_FAILED=1
      ui_warning 'the full environment audit contains required failures'
    fi
  else
    DAY_ONE_MAC_AUDIT_REPORT="$ENVIRONMENT_REPORT" \
      DAY_ONE_MAC_REPO_REPORT="$REPOSITORY_REPORT" \
      "$SCRIPT_DIR/advanced-audit.sh" >/dev/null
  fi
  write_report
  ui_success "module audit: $REPORT"
  ui_info "environment audit: $ENVIRONMENT_REPORT"
  ui_info "repository audit: $REPOSITORY_REPORT"
  [[ "$PRINT_REPORT" == 1 ]] && sed -n '1,$p' "$REPORT"
fi

if [[ "$CHECK_ONLY" == 1 \
   && $((FAILURES + REVIEWS + PARTIALS + PENDING + ENVIRONMENT_FAILED)) -gt 0 ]]; then
  exit 1
fi
