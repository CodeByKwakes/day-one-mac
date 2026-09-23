#!/usr/bin/env bash
# Choice-first entry point for the self-contained Day One Mac project.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$HERE/.." && pwd)"
source "$HERE/lib/project-paths.sh"
source "$HERE/lib/terminal-ui.sh"
source "$HERE/lib/application-ownership.sh"
source "$HERE/lib/platform.sh"

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
COMPLETED_DIR="$STATE_DIR/completed"
DRY_RUN=0
FORCE_WIZARD=0
WIZARD_CANDIDATE=0
DIRECT_REQUEST=0
ORIGINAL_ARG_COUNT="$#"
PASSTHROUGH_ARGS=()
APPLICATION_REVIEW_CACHE=""
SHOW_OPTIONAL_REVIEW=0

usage() {
  cat <<'EOF'
Usage: ./bootstrap-day-one-mac.sh [options]

Wizard:
  (no options)                 open the interactive setup wizard
  --wizard                     open the wizard explicitly
  --guided                     open the wizard when no setup choices are supplied
  --dry-run                    preview the wizard's selected base setup
  --optional [--guided]        open optional setup only after Phase 8

Existing Mac — optional Stage 0 before Phase 1:
  --prepare-existing [options] choose Route A or Route B in the Stage 0 wizard
  --safety-report [options]    create only the read-only safety report

Compatibility:
  --preflight [options]        older name for --safety-report

Direct setup:
  --applications [options]    check app ownership; optionally install missing casks
  --install-centre            install/revalidate all required software, then exit
  --ssh-pin [PROVIDER]        save 1Password public keys to ~/.ssh, then exit
                              PROVIDER is github, azure, or both (default: the saved track)
  --phase NN                   run one required phase; repeatable
  --track 1|2|3               1 GitHub; 2 Azure DevOps; 3 both
  --stack node|python|both    language toolchain selection
  --name "Full Name"          Git author name
  --email ADDRESS             primary Git author email
  --primary-ide IDE           vscode or other; controls Git editor integration
  --dotfiles-repo URL         apply an existing private chezmoi source
  --new-dotfiles              create or keep a new chezmoi source
  --dotfiles-versioning MODE  git (private remote) or local (no Git gate)
  --local-dotfiles            create a local-only chezmoi source
  --macos-settings MODE       configure or skip the early optional settings wizard
  --skip-macos-settings       continue to Phase 2 without preference changes
  --app-install-policy MODE   prompt, homebrew, or check-only for missing apps
  --status                    show saved choices and phase completion
  --reset-progress            archive completion markers; keep installed files
  --yes                       accept ordinary setup confirmations
  -h, --help                  show this help

The first wizard collects only choices needed by Phases 1–8. Optional modules
are offered after Phase 8 and remain available later with --optional. They are
never silently installed with the required base.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
die() { ui_error "$@"; exit 1; }

direct_setup() {
  exec bash "$HERE/setup.sh" "$@"
}

direct_stage_zero() {
  local command="$1"
  shift
  day_one_require_apple_silicon || exit 2
  case "$command" in
    preflight) exec bash "$HERE/preflight-audit.sh" "$@" ;;
    prepare) exec bash "$HERE/prepare-existing-mac.sh" "$@" ;;
  esac
}

direct_applications() {
  exec bash "$HERE/application-status.sh" "$@"
}

state_value() {
  [[ -r "$STATE_DIR/$1" ]] && sed -n '1p' "$STATE_DIR/$1" || true
}

save_state_value() {
  local name="$1" value="$2" tmp
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  tmp="$(mktemp "$STATE_DIR/.wizard.XXXXXX")"
  printf '%s\n' "$value" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$STATE_DIR/$name"
}

contains_csv() {
  case ",$1," in *",$2,"*) return 0 ;; *) return 1 ;; esac
}

without_csv_value() {
  local csv="$1" unwanted="$2" value output="" old_ifs="$IFS"
  IFS=','
  for value in $csv; do
    [[ "$value" == "$unwanted" ]] && continue
    output="${output}${output:+,}$value"
  done
  IFS="$old_ifs"
  printf '%s' "$output"
}

order_optional_modules() {
  local csv="$1" value output=""
  for value in databases ai-clients omniroute mcp-servers vscode-profiles enhanced-cli warp-drive advanced second-brain; do
    contains_csv "$csv" "$value" || continue
    output="${output}${output:+,}$value"
  done
  printf '%s' "$output"
}

valid_line() {
  [[ -n "$1" && "$1" != *$'\n'* && "$1" != *$'\r'* ]]
}

valid_email() {
  [[ "$1" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]
}

clear_screen() {
  [[ -t 1 ]] && printf '\033[2J\033[H'
}

SINGLE_VALUES=()
SINGLE_LABELS=()
SINGLE_RESULT=""
SINGLE_SHOW_REVIEW=0
select_one() {
  local heading="$1" default_index="$2" cursor key rest item marker radio
  cursor="$default_index"
  while :; do
    clear_screen
    ui_banner '🍎' 'Day One Mac setup wizard'
    [[ "$SINGLE_SHOW_REVIEW" == 1 ]] && print_review_body
    printf '%s\n\n' "$heading"
    printf '  Up/Down or j/k: move   Space or Enter: accept   q: quit\n\n'
    for ((item=0; item<${#SINGLE_VALUES[@]}; item++)); do
      marker=' '
      radio='( )'
      [[ "$item" == "$cursor" ]] && marker='>'
      [[ "$item" == "$cursor" ]] && radio='(●)'
      if [[ "$item" == "$cursor" ]]; then
        printf ' %s%s%s %s %s%s\n' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN" "$marker" "$radio" "${SINGLE_LABELS[$item]}" "$DAY_ONE_UI_RESET"
      else
        printf ' %s %s %s\n' "$marker" "$radio" "${SINGLE_LABELS[$item]}"
      fi
    done
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then
      IFS= read -rsn2 rest || true
      key="$key$rest"
    fi
    case "$key" in
      $'\033[A'|k|K)
        cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#SINGLE_VALUES[@]} - 1))
        ;;
      $'\033[B'|j|J)
        cursor=$((cursor + 1)); [[ "$cursor" -lt "${#SINGLE_VALUES[@]}" ]] || cursor=0
        ;;
      ' ') SINGLE_RESULT="${SINGLE_VALUES[$cursor]}"; clear_screen; return 0 ;;
      q|Q) clear_screen; exit 0 ;;
      '') SINGLE_RESULT="${SINGLE_VALUES[$cursor]}"; clear_screen; return 0 ;;
    esac
  done
}

MENU_VALUES=()
MENU_LABELS=()
MENU_SELECTED=()
MENU_RESULT=""
select_toggles() {
  local heading="$1" cursor=0 key rest item marker check
  while :; do
    clear_screen
    ui_banner '🍎' 'Day One Mac setup wizard'
    printf '%s\n\n' "$heading"
    printf '  Up/Down or j/k: move   Space: toggle   a: all   n: none\n'
    printf '  Enter: accept          q: quit\n\n'
    for ((item=0; item<${#MENU_VALUES[@]}; item++)); do
      marker=' '
      check='[ ]'
      [[ "$item" == "$cursor" ]] && marker='>'
      [[ "${MENU_SELECTED[$item]}" == 1 ]] && check='[x]'
      if [[ "$item" == "$cursor" ]]; then
        printf ' %s%s%s %s %s%s\n' "$DAY_ONE_UI_BOLD" "$DAY_ONE_UI_CYAN" "$marker" "$check" "${MENU_LABELS[$item]}" "$DAY_ONE_UI_RESET"
      else
        printf ' %s %s %s\n' "$marker" "$check" "${MENU_LABELS[$item]}"
      fi
    done
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then
      IFS= read -rsn2 rest || true
      key="$key$rest"
    fi
    case "$key" in
      $'\033[A'|k|K)
        cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#MENU_VALUES[@]} - 1))
        ;;
      $'\033[B'|j|J)
        cursor=$((cursor + 1)); [[ "$cursor" -lt "${#MENU_VALUES[@]}" ]] || cursor=0
        ;;
      ' ')
        if [[ "${MENU_SELECTED[$cursor]}" == 1 ]]; then MENU_SELECTED[$cursor]=0
        else MENU_SELECTED[$cursor]=1
        fi
        ;;
      a|A) for ((item=0; item<${#MENU_VALUES[@]}; item++)); do MENU_SELECTED[$item]=1; done ;;
      n|N) for ((item=0; item<${#MENU_VALUES[@]}; item++)); do MENU_SELECTED[$item]=0; done ;;
      q|Q) clear_screen; exit 0 ;;
      '') break ;;
    esac
  done
  MENU_RESULT=""
  for ((item=0; item<${#MENU_VALUES[@]}; item++)); do
    [[ "${MENU_SELECTED[$item]}" == 1 ]] || continue
    MENU_RESULT="${MENU_RESULT}${MENU_RESULT:+,}${MENU_VALUES[$item]}"
  done
  clear_screen
}

prompt_value() {
  local label="$1" default="$2" answer
  printf '%s' "$label"
  [[ -n "$default" ]] && printf ' [%s]' "$default"
  printf ': '
  IFS= read -r answer
  PROMPT_RESULT="${answer:-$default}"
}

prompt_name() {
  local default="$1"
  while :; do
    prompt_value 'Git author name' "$default"
    if valid_line "$PROMPT_RESULT"; then GIT_NAME="$PROMPT_RESULT"; return 0; fi
    warn 'Enter a one-line name.'
  done
}

prompt_email() {
  local default="$1"
  while :; do
    prompt_value 'Primary Git email' "$default"
    if valid_email "$PROMPT_RESULT"; then GIT_EMAIL="$PROMPT_RESULT"; return 0; fi
    warn 'Enter a valid email address.'
  done
}

csv_label() {
  local csv="$1" value output="" label
  [[ -n "$csv" ]] || { printf 'None'; return 0; }
  local old_ifs="$IFS"
  IFS=','
  for value in $csv; do
    case "$value" in
      databases) label='Databases' ;;
      ai-clients) label='AI clients' ;;
      omniroute) label='OmniRoute AI gateway' ;;
      mcp-servers) label='MCP servers' ;;
      vscode-profiles) label='VS Code profiles' ;;
      enhanced-cli) label='Enhanced CLI tools' ;;
      warp-drive) label='Warp Drive workflows' ;;
      advanced) label='Advanced modules' ;;
      second-brain) label='Second Brain' ;;
      postgres) label='PostgreSQL' ;;
      redis) label='Redis' ;;
      mongodb) label='MongoDB' ;;
      claude) label='Claude Code' ;;
      codex) label='Codex' ;;
      copilot-app) label='GitHub Copilot app' ;;
      copilot-vscode) label='GitHub Copilot in VS Code' ;;
      copilot-cli) label='GitHub Copilot CLI' ;;
      raycast-ai) label='Raycast AI' ;;
      context7) label='Context7' ;;
      apify) label='Apify' ;;
      tavily) label='Tavily' ;;
      filesystem) label='Filesystem' ;;
      playwright) label='Playwright' ;;
      *) label="$value" ;;
    esac
    output="${output}${output:+, }$label"
  done
  IFS="$old_ifs"
  printf '%s' "$output"
}

selected_defaults() {
  local csv="$1"; shift
  local index=0 value
  MENU_SELECTED=()
  for value in "$@"; do
    if contains_csv "$csv" "$value"; then MENU_SELECTED[$index]=1
    else MENU_SELECTED[$index]=0
    fi
    index=$((index + 1))
  done
}

track_label() {
  case "$1" in
    1) printf 'GitHub' ;;
    2) printf 'Azure DevOps' ;;
    3) printf 'GitHub + Azure DevOps' ;;
    *) printf 'Not selected' ;;
  esac
}

stack_label() {
  case "$1" in
    node) printf 'Node.js / JavaScript (fnm, Node LTS, npm and pnpm)' ;;
    python) printf 'Python (uv)' ;;
    both) printf 'Node.js / JavaScript + Python' ;;
    *) printf 'Not selected' ;;
  esac
}

show_required_base() {
  printf '\nRequired base — runs before all optional modules\n'
  printf '  🔒 Phase 1  First boot, backup confirmation and decisions\n'
  printf '  ⚙️  Checkpoint  Optional macOS preferences: configure or skip\n'
  printf '  🔒 Phase 2  Xcode Command Line Tools and Homebrew\n'
  printf '  📦 Installation Centre  Install every required app and command-line tool\n'
  printf '  🔒 Phase 3  Git authentication (%s) and FileVault\n' "${AUTH_MODE:-1password}"
  printf '  🔒 Phase 4  Core tools, Raycast, Warp and selected hosting services\n'
  printf '  🔒 Phase 5  chezmoi-managed dotfiles and Starship\n'
  printf '  🔒 Phase 6  Selected language toolchains\n'
  printf '  🔒 Phase 7  Minimal VS Code base\n'
  printf '  🔒 Phase 8  Verification, Brewfile and dotfiles protection\n'
  printf '  🧩 Then       Finish, view the report, or choose optional modules\n\n'
  printf '  🔒 means required. A ✓ appears only after a phase passes.\n\n'
}

print_review_body() {
  ui_banner '🧭' 'Review your setup'
  printf 'Required setup\n'
  printf '  Hosting:   Track %s — %s\n' "$TRACK" "$(track_label "$TRACK")"
  printf '  Stack:     %s\n' "$(stack_label "$STACK")"
  printf '  Git name:  %s\n' "$GIT_NAME"
  printf '  Git email: %s\n' "$GIT_EMAIL"
  if [[ "$PRIMARY_IDE" == vscode ]]; then
    printf '  IDE:       VS Code — also use it for Git edit, diff and merge actions\n'
  else
    printf '  IDE:       another primary IDE — do not change Git editor tools\n'
  fi
  if [[ "$MACOS_SETTINGS_PLAN" == skip ]]; then
    printf '  macOS:     skip optional settings now; command remains available later\n'
  elif [[ "$MACOS_SETTINGS_PLAN" == ask ]]; then
    printf '  macOS:     choose configure or skip immediately after Phase 1\n'
  else
    printf '  macOS:     run the optional Settings Wizard after Phase 1\n'
  fi
  printf '  Auth:      %s\n' "$AUTH_MODE"
  if [[ -n "$DOTFILES_REPO" ]]; then
    printf '  Dotfiles:  existing private source — %s\n' "$DOTFILES_REPO"
  elif [[ "$DOTFILES_VERSIONING" == local ]]; then
    printf '  Dotfiles:  local-only chezmoi source — no Git history or remote gate\n'
  else
    printf '  Dotfiles:  new chezmoi source — private Git required in Phase 8\n'
  fi
  show_required_base
  if [[ "$SHOW_OPTIONAL_REVIEW" == 1 ]]; then
    ui_section '🧩' 'Optional plan — available after Phase 8; not installed automatically'
    printf '  Modules:   %s\n' "$(csv_label "$OPTIONAL_MODULES")"
    contains_csv "$OPTIONAL_MODULES" databases \
      && printf '  Databases: %s\n' "$(csv_label "$DATABASE_SERVICES")"
    contains_csv "$OPTIONAL_MODULES" ai-clients \
      && printf '  AI clients: %s\n' "$(csv_label "$AI_CLIENTS")"
    contains_csv "$OPTIONAL_MODULES" omniroute \
      && printf '  OmniRoute clients: %s\n' "$(csv_label "$AI_CLIENTS")"
    contains_csv "$OPTIONAL_MODULES" mcp-servers \
      && printf '  MCP servers: %s\n' "$(csv_label "$MCP_SERVERS")"
  fi
  [[ -z "$APPLICATION_REVIEW_CACHE" ]] || printf '%s\n' "$APPLICATION_REVIEW_CACHE"
  printf '\nSafety\n'
  printf '  ✓ Completed phases will be revalidated and then skipped when current.\n'
  printf '  ✓ A phase is saved only after all of its gates pass.\n'
  printf '  ✓ macOS settings are offered after Phase 1; all other optional work waits until Phase 8.\n\n'
}

application_review_line() {
  local app_id="$1" role="$2" source_label
  day_one_app_detect "$app_id" || return 0
  source_label="$(day_one_app_source_label "$DAY_ONE_APP_SOURCE")"
  case "$DAY_ONE_APP_STATUS" in
    ready) printf '  ✓ %-24s %s — left unchanged if external\n' "$DAY_ONE_APP_NAME" "$source_label" ;;
    missing) printf '  ○ %-24s Missing — choose its installer in %s\n' "$DAY_ONE_APP_NAME" "$role" ;;
    review) printf '  ⚠ %-24s Needs review — %s\n' "$DAY_ONE_APP_NAME" "$DAY_ONE_APP_REASON" ;;
  esac
}

build_application_review_cache() {
  local include_optional="${1:-0}" cache="" line app_id optional_ids="" seen="," role
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    line="$(application_review_line "$app_id" 'the Installation Centre')"
    cache="${cache}${cache:+$'\n'}$line"
    seen="${seen}${app_id},"
  done < <(day_one_app_catalog_ids required)

  if [[ "$include_optional" == 1 ]] \
     && { contains_csv "$OPTIONAL_MODULES" databases || contains_csv "$OPTIONAL_MODULES" omniroute; }; then
    optional_ids="${optional_ids}${optional_ids:+ }orbstack"
  fi
  if [[ "$include_optional" == 1 ]] && contains_csv "$AI_CLIENTS" claude; then optional_ids="${optional_ids}${optional_ids:+ }claude-code"; fi
  if [[ "$include_optional" == 1 ]] && contains_csv "$AI_CLIENTS" codex; then optional_ids="${optional_ids}${optional_ids:+ }codex"; fi
  if [[ "$include_optional" == 1 ]] && contains_csv "$AI_CLIENTS" copilot-app; then optional_ids="${optional_ids}${optional_ids:+ }copilot-app"; fi
  if [[ "$include_optional" == 1 ]] && contains_csv "$AI_CLIENTS" copilot-cli; then optional_ids="${optional_ids}${optional_ids:+ }copilot-cli"; fi
  if [[ "$include_optional" == 1 ]] && contains_csv "$OPTIONAL_MODULES" second-brain; then optional_ids="${optional_ids}${optional_ids:+ }obsidian"; fi
  for app_id in $optional_ids; do
    case "$seen" in *",$app_id,"*) continue ;; esac
    line="$(application_review_line "$app_id" 'its optional guide')"
    cache="${cache}${cache:+$'\n'}$line"
    seen="${seen}${app_id},"
  done

  APPLICATION_REVIEW_CACHE=$'\nCurrent application ownership — checked now; the Installation Centre resolves missing required items\n'
  APPLICATION_REVIEW_CACHE="${APPLICATION_REVIEW_CACHE}${cache}"
  APPLICATION_REVIEW_CACHE="${APPLICATION_REVIEW_CACHE}"$'\n  Non-Homebrew means Company Portal, Mac App Store, or another approved installer.'
}

show_review() {
  clear_screen
  ui_banner '🍎' 'Day One Mac setup wizard'
  print_review_body
}

write_wizard_report() {
  local report="$STATE_DIR/wizard-selections.md" tmp
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  tmp="$(mktemp "$STATE_DIR/.wizard-report.XXXXXX")"
  {
    printf '# Day One Mac wizard selections\n\n'
    printf -- '- Saved: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- Hosting: `Track %s — %s`\n' "$TRACK" "$(track_label "$TRACK")"
    printf -- '- Stack: `%s`\n' "$(stack_label "$STACK")"
    printf -- '- Git name: `%s`\n' "$GIT_NAME"
    printf -- '- Git email: `%s`\n' "$GIT_EMAIL"
    printf -- '- Primary IDE: `%s`\n' "$PRIMARY_IDE"
    printf -- '- Early macOS settings: `%s`\n' "$MACOS_SETTINGS_PLAN"
    if [[ -n "$DOTFILES_REPO" ]]; then
      printf -- '- Dotfiles: existing private chezmoi source `%s`\n' "$DOTFILES_REPO"
    elif [[ "$DOTFILES_VERSIONING" == local ]]; then
      printf -- '- Dotfiles: local-only chezmoi source; no Git history or remote gate\n'
    else
      printf -- '- Dotfiles: new chezmoi source with private Git required in Phase 8\n'
    fi
    printf '\n## Required base\n\nAll eight required phases are included. The Installation Centre runs after Phase 2 so all required software is ready before configuration. Track and stack choices control conditional work.\n'
    printf '\n## Optional plan\n\n'
    if [[ -n "$OPTIONAL_MODULES" ]]; then
      printf -- '- Saved for after Phase 8: %s\n' "$(csv_label "$OPTIONAL_MODULES")"
    else
      printf -- '- No optional modules selected yet. Run `day-one-mac optional --guided` after Phase 8.\n'
    fi
    contains_csv "$OPTIONAL_MODULES" databases \
      && printf -- '- Database services: %s\n' "$(csv_label "$DATABASE_SERVICES")"
    contains_csv "$OPTIONAL_MODULES" ai-clients \
      && printf -- '- AI clients: %s\n' "$(csv_label "$AI_CLIENTS")"
    contains_csv "$OPTIONAL_MODULES" omniroute \
      && printf -- '- OmniRoute clients: %s\n' "$(csv_label "$AI_CLIENTS")"
    contains_csv "$OPTIONAL_MODULES" mcp-servers \
      && printf -- '- MCP servers: %s\n' "$(csv_label "$MCP_SERVERS")"
    if [[ -n "$APPLICATION_REVIEW_CACHE" ]]; then
      printf '\n## Application ownership at review time\n\n```text\n%s\n```\n' "$APPLICATION_REVIEW_CACHE"
    fi
    printf '\nOptional selections are planning records. Complete them only after Phase 8 using the linked guides.\n'
  } > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$report"
}

save_wizard_choices() {
  save_state_value project-root "$PROJECT_DIR"
  save_state_value track "$TRACK"
  save_state_value track-schema-version 2
  save_state_value stack "$STACK"
  save_state_value git-name "$GIT_NAME"
  save_state_value git-email "$GIT_EMAIL"
  save_state_value primary-ide "$PRIMARY_IDE"
  save_state_value dotfiles-repo "$DOTFILES_REPO"
  save_state_value dotfiles-versioning "$DOTFILES_VERSIONING"
  save_state_value auth-mode "$AUTH_MODE"
  save_state_value macos-settings-plan "$MACOS_SETTINGS_PLAN"
  save_state_value optional-modules "$OPTIONAL_MODULES"
  save_state_value database-services "$DATABASE_SERVICES"
  save_state_value ai-clients "$AI_CLIENTS"
  save_state_value mcp-servers "$MCP_SERVERS"
  write_wizard_report
  ok "wizard choices saved to $STATE_DIR/wizard-selections.md"
}

choose_track() {
  local default_index=0
  case "$TRACK" in 2) default_index=1 ;; 3) default_index=2 ;; esac
  SINGLE_VALUES=(1 2 3)
  SINGLE_LABELS=('Track 1 — GitHub' 'Track 2 — Azure DevOps' 'Track 3 — GitHub + Azure DevOps')
  select_one 'Choose the hosting services this Mac will use:' "$default_index"
  TRACK="$SINGLE_RESULT"
}

choose_stack() {
  MENU_VALUES=(node python)
  MENU_LABELS=('Node.js / JavaScript — fnm, Node LTS, npm and pnpm' 'Python — uv-managed Python')
  case "$STACK" in
    node) MENU_SELECTED=(1 0) ;;
    python) MENU_SELECTED=(0 1) ;;
    *) MENU_SELECTED=(1 1) ;;
  esac
  while :; do
    select_toggles 'Choose one or both development stacks:'
    case "$MENU_RESULT" in
      node) STACK=node; return 0 ;;
      python) STACK=python; return 0 ;;
      node,python) STACK=both; return 0 ;;
      *) warn 'Select at least one development stack.' ;;
    esac
  done
}

choose_primary_ide() {
  local default_index=0
  [[ "$PRIMARY_IDE" == other ]] && default_index=1
  SINGLE_VALUES=(vscode other)
  SINGLE_LABELS=(
    'Yes — use VS Code for Git commit messages, diffs and merge conflicts'
    'No — keep Git editor, diff and merge-tool settings unchanged'
  )
  select_one 'Use Visual Studio Code as the primary IDE on this Mac?' "$default_index"
  PRIMARY_IDE="$SINGLE_RESULT"
}

choose_auth_mode() {
  local default_index=0
  case "$AUTH_MODE" in
    keychain) default_index=1 ;;
    external) default_index=2 ;;
    https)    default_index=3 ;;
  esac
  ui_banner '🔑' 'Git authentication'
  printf 'How should this Mac prove its identity to GitHub or Azure DevOps?\n'
  printf 'Only the first option keeps the private key out of ~/.ssh entirely.\n\n'
  SINGLE_VALUES=(1password keychain external https)
  SINGLE_LABELS=(
    '1Password SSH agent — no private key on disk (recommended)'
    'macOS Keychain — a passphrase-protected key file in ~/.ssh'
    'My own SSH agent — Secretive, a YubiKey, or a company agent'
    'HTTPS instead of SSH — no SSH key at all'
  )
  select_one 'Choose how Git authenticates:' "$default_index"
  AUTH_MODE="$SINGLE_RESULT"
  case "$AUTH_MODE" in
    keychain) printf '\nA private key will be created in ~/.ssh and protected by a passphrase you choose.\n\n' ;;
    external) printf '\nDay One Mac will not create a key; it only checks that your agent offers one.\n\n' ;;
    https)    printf '\nNo SSH key is set up. Azure DevOps over HTTPS also needs Git Credential Manager.\n\n' ;;
  esac
}

choose_dotfiles() {
  local default_index=0
  [[ "$DOTFILES_VERSIONING" == local ]] && default_index=1
  [[ -n "$DOTFILES_REPO" ]] && default_index=2
  SINGLE_VALUES=(new-git new-local existing)
  SINGLE_LABELS=(
    'Create a new chezmoi source and protect it with private Git (recommended)'
    'Create a local-only chezmoi source without Git version history'
    'Use an existing private dotfiles repository'
  )
  select_one 'Choose how chezmoi should store and protect your dotfiles:' "$default_index"
  if [[ "$SINGLE_RESULT" == existing ]]; then
    while :; do
      prompt_value 'Private dotfiles repository URL' "$DOTFILES_REPO"
      if valid_line "$PROMPT_RESULT" && [[ "$PROMPT_RESULT" != *[[:space:]]* ]]; then
        DOTFILES_REPO="$PROMPT_RESULT"
        DOTFILES_VERSIONING=git
        return 0
      fi
      warn 'Enter a one-line repository URL without spaces.'
    done
  fi
  DOTFILES_REPO=""
  if [[ "$SINGLE_RESULT" == new-local ]]; then DOTFILES_VERSIONING=local
  else DOTFILES_VERSIONING=git
  fi
}

choose_optional_plan() {
  local previous_databases="$DATABASE_SERVICES"
  local previous_ai_clients="$AI_CLIENTS" previous_mcp_servers="$MCP_SERVERS"
  MENU_VALUES=(databases ai-clients omniroute mcp-servers vscode-profiles enhanced-cli warp-drive advanced second-brain)
  MENU_LABELS=(
    'Databases — PostgreSQL, Redis or MongoDB'
    'AI clients — Claude Code, Codex, GitHub Copilot or Raycast AI'
    'OmniRoute AI gateway — local Docker routing for selected AI clients'
    'MCP servers — requires at least one selected AI client'
    'VS Code profiles — work, personal or content profiles'
    'Enhanced CLI tools — eza, lazydocker, shell helpers and more'
    'Warp Drive — importable workflows and command notebook'
    'Advanced modules — identities, worktrees, HTTPS, restore and audits'
    'Second Brain — choose an Obsidian or Notion knowledge system'
  )
  selected_defaults "$OPTIONAL_MODULES" databases ai-clients omniroute mcp-servers vscode-profiles enhanced-cli warp-drive advanced second-brain
  select_toggles 'Choose optional modules to plan for after Phase 8 (none is valid):'
  OPTIONAL_MODULES="$MENU_RESULT"

  if { contains_csv "$OPTIONAL_MODULES" omniroute || contains_csv "$OPTIONAL_MODULES" mcp-servers; } \
     && ! contains_csv "$OPTIONAL_MODULES" ai-clients; then
    OPTIONAL_MODULES="${OPTIONAL_MODULES}${OPTIONAL_MODULES:+,}ai-clients"
    OPTIONAL_MODULES="$(order_optional_modules "$OPTIONAL_MODULES")"
    if contains_csv "$OPTIONAL_MODULES" omniroute && contains_csv "$OPTIONAL_MODULES" mcp-servers; then
      warn 'AI clients were added because OmniRoute and MCP both need a compatible client.'
    elif contains_csv "$OPTIONAL_MODULES" omniroute; then
      warn 'AI clients were added because OmniRoute needs a compatible client.'
    else
      warn 'AI clients were added because MCP needs a compatible client.'
    fi
  fi

  DATABASE_SERVICES=""
  if contains_csv "$OPTIONAL_MODULES" databases; then
    MENU_VALUES=(postgres redis mongodb)
    MENU_LABELS=('PostgreSQL' 'Redis' 'MongoDB')
    selected_defaults "$previous_databases" postgres redis mongodb
    select_toggles 'Choose database services (none removes Databases from the plan):'
    DATABASE_SERVICES="$MENU_RESULT"
    if [[ -z "$DATABASE_SERVICES" ]]; then
      OPTIONAL_MODULES="$(without_csv_value "$OPTIONAL_MODULES" databases)"
      warn 'Databases were removed from the optional plan because no service was selected.'
    fi
  fi

  AI_CLIENTS=""
  if contains_csv "$OPTIONAL_MODULES" ai-clients; then
    MENU_VALUES=(claude codex copilot-app copilot-vscode copilot-cli raycast-ai)
    MENU_LABELS=('Claude Code' 'OpenAI Codex' 'GitHub Copilot app — standalone desktop client' 'GitHub Copilot in VS Code' 'GitHub Copilot CLI' 'Raycast AI — paid plan required for custom providers')
    selected_defaults "$previous_ai_clients" claude codex copilot-app copilot-vscode copilot-cli raycast-ai
    select_toggles 'Choose AI clients (none also removes OmniRoute and MCP from the plan):'
    AI_CLIENTS="$MENU_RESULT"
    if [[ -z "$AI_CLIENTS" ]]; then
      OPTIONAL_MODULES="$(without_csv_value "$OPTIONAL_MODULES" ai-clients)"
      OPTIONAL_MODULES="$(without_csv_value "$OPTIONAL_MODULES" omniroute)"
      OPTIONAL_MODULES="$(without_csv_value "$OPTIONAL_MODULES" mcp-servers)"
      warn 'AI clients, OmniRoute and MCP were removed because no AI client was selected.'
    fi
  fi

  MCP_SERVERS=""
  if contains_csv "$OPTIONAL_MODULES" mcp-servers; then
    MENU_VALUES=(context7 apify tavily filesystem playwright)
    MENU_LABELS=(
      'Context7 — current library documentation'
      'Apify — web extraction and hosted Actors'
      'Tavily — web search and extraction'
      'Filesystem — local files with a restricted path'
      'Playwright — browser-driven testing'
    )
    selected_defaults "$previous_mcp_servers" context7 apify tavily filesystem playwright
    select_toggles 'Choose MCP servers (none removes MCP servers from the plan):'
    MCP_SERVERS="$MENU_RESULT"
    if [[ -z "$MCP_SERVERS" ]]; then
      OPTIONAL_MODULES="$(without_csv_value "$OPTIONAL_MODULES" mcp-servers)"
      warn 'MCP servers were removed from the optional plan because no server was selected.'
    fi
  fi
}

save_optional_choices() {
  save_state_value optional-modules "$OPTIONAL_MODULES"
  save_state_value database-services "$DATABASE_SERVICES"
  save_state_value ai-clients "$AI_CLIENTS"
  save_state_value mcp-servers "$MCP_SERVERS"
  write_wizard_report
  ok "optional plan saved to $STATE_DIR/wizard-selections.md"
}

show_verification_report() {
  local report="$STATE_DIR/verification.md"
  clear_screen
  ui_banner '✅' 'Required setup verification'
  if [[ -s "$report" ]]; then
    sed -n '1,240p' "$report"
    printf '\nFull report: %s\n' "$report"
  else
    warn "No verification report exists yet: $report"
  fi
  printf '\nPress Enter to return: '
  IFS= read -r _
}

run_optional_center() {
  local review_action
  day_one_require_apple_silicon || exit 2
  [[ -t 0 && -t 1 ]] || die 'The optional setup centre requires an interactive terminal.'
  load_saved_choices
  has_saved_core_choices || die 'Complete the required setup wizard choices before opening optional setup.'
  [[ -s "$COMPLETED_DIR/08" ]] || {
    err 'Optional setup remains locked until required Phase 8 is complete.'
    info "Resume the required setup with: $HERE/bootstrap-day-one-mac.sh --wizard"
    exit 10
  }

  while :; do
    choose_optional_plan
    build_application_review_cache 1
    SINGLE_VALUES=(save change exit)
    SINGLE_LABELS=(
      'Save this optional plan — modules remain manual and separately resumable'
      'Go back and change optional choices'
      'Exit without changing the saved optional plan'
    )
    SHOW_OPTIONAL_REVIEW=1
    SINGLE_SHOW_REVIEW=1
    select_one 'Save this optional plan?' 0
    SINGLE_SHOW_REVIEW=0
    SHOW_OPTIONAL_REVIEW=0
    review_action="$SINGLE_RESULT"
    case "$review_action" in
      change) continue ;;
      exit) return 0 ;;
      save) break ;;
    esac
  done

  save_optional_choices
  ui_title '🧩' 'Optional setup centre'
  info "Saved modules: $(csv_label "$OPTIONAL_MODULES")"
  if [[ -n "$OPTIONAL_MODULES" ]]; then
    info "Guides: $PROJECT_DIR/docs/02-optional/"
    info 'Nothing optional was installed automatically.'
  else
    ok 'No optional modules selected. The required setup remains complete.'
  fi
}

post_required_menu() {
  local action
  while :; do
    SINGLE_VALUES=(finish optional report)
    SINGLE_LABELS=(
      'Finish and exit — optional modules can be added later (recommended)'
      'Open the optional setup centre'
      'View the final verification report'
    )
    select_one '✅ Required Day One Mac setup is complete. What would you like to do next?' 0
    action="$SINGLE_RESULT"
    case "$action" in
      finish) return 0 ;;
      optional) run_optional_center; return 0 ;;
      report) show_verification_report ;;
    esac
  done
}

configure_wizard() {
  local default_name default_email
  choose_track
  choose_stack
  clear_screen
  ui_banner '🔐' 'Git identity'
  printf 'This identity becomes the global default. Advanced Module 18 adds multiple identities later.\n\n'
  default_name="${GIT_NAME:-$(git config --global user.name 2>/dev/null || id -F 2>/dev/null || id -un)}"
  default_email="${GIT_EMAIL:-$(git config --global user.email 2>/dev/null || true)}"
  prompt_name "$default_name"
  prompt_email "$default_email"
  choose_primary_ide
  choose_auth_mode
  choose_dotfiles
  # Keep the initial wizard focused on the required base. The runner asks
  # whether to configure optional macOS preferences immediately after Phase 1.
  MACOS_SETTINGS_PLAN=ask
}

has_saved_core_choices() {
  [[ "$(state_value track-schema-version)" == 2 ]] \
    && [[ "$(state_value track)" =~ ^[123]$ ]] \
    && [[ "$(state_value stack)" =~ ^(node|python|both)$ ]] \
    && [[ "$DOTFILES_VERSIONING" =~ ^(git|local)$ ]] \
    && valid_line "$(state_value git-name)" \
    && valid_email "$(state_value git-email)"
}

load_saved_choices() {
  TRACK="$(state_value track)"
  STACK="$(state_value stack)"
  GIT_NAME="$(state_value git-name)"
  GIT_EMAIL="$(state_value git-email)"
  PRIMARY_IDE="$(state_value primary-ide)"
  DOTFILES_REPO="$(state_value dotfiles-repo)"
  DOTFILES_VERSIONING="$(state_value dotfiles-versioning)"
  [[ -n "$DOTFILES_VERSIONING" ]] || DOTFILES_VERSIONING=git
  AUTH_MODE="$(state_value auth-mode)"
  # Setups saved before this choice existed all used the 1Password agent.
  [[ -n "$AUTH_MODE" ]] || AUTH_MODE=1password
  MACOS_SETTINGS_PLAN="$(state_value macos-settings-plan)"
  [[ -n "$MACOS_SETTINGS_PLAN" ]] || MACOS_SETTINGS_PLAN=ask
  OPTIONAL_MODULES="$(state_value optional-modules)"
  DATABASE_SERVICES="$(state_value database-services)"
  AI_CLIENTS="$(state_value ai-clients)"
  MCP_SERVERS="$(state_value mcp-servers)"
}

choose_machine_state() {
  SINGLE_VALUES=(clean existing unsure exit)
  SINGLE_LABELS=(
    'New or factory-reset Mac — continue to the eight required phases'
    'Existing Mac with data or settings — choose Route A or Route B'
    'Not sure — open Stage 0 and create the read-only safety report first'
    'Exit without changing anything'
  )
  select_one 'What state is this Mac in?' 0
  case "$SINGLE_RESULT" in
    clean) return 0 ;;
    existing)
      if [[ "$DRY_RUN" == 1 ]]; then direct_stage_zero prepare --guided --dry-run
      else direct_stage_zero prepare --guided
      fi
      ;;
    unsure) direct_stage_zero prepare --guided ;;
    exit) exit 0 ;;
  esac
}

run_wizard() {
  local review_action setup_rc
  day_one_require_apple_silicon || exit 2
  [[ -t 0 && -t 1 ]] || die 'The setup wizard requires an interactive terminal. Use --track, --stack, --name and --email for a non-interactive run.'
  load_saved_choices
  if has_saved_core_choices; then
    SINGLE_VALUES=(resume change status exit)
    SINGLE_LABELS=(
      'Resume with the saved choices (recommended)'
      'Review or change setup choices'
      'Show detailed phase status'
      'Exit'
    )
    select_one "Saved setup found: Track $TRACK — $(track_label "$TRACK"); $(stack_label "$STACK")" 0
    case "$SINGLE_RESULT" in
      change) configure_wizard ;;
      status) direct_setup --status ;;
      exit) exit 0 ;;
    esac
    [[ "$PRIMARY_IDE" =~ ^(vscode|other)$ ]] || choose_primary_ide
  else
    choose_machine_state
    configure_wizard
  fi

  build_application_review_cache 0

  while :; do
    SINGLE_VALUES=(start change exit)
    if [[ "$DRY_RUN" == 1 ]]; then
      SINGLE_LABELS=('Preview the selected setup without saving' 'Go back and change choices' 'Exit without saving')
    else
      SINGLE_LABELS=('Save choices and begin or resume setup' 'Go back and change choices' 'Exit without saving')
    fi
    SINGLE_SHOW_REVIEW=1
    select_one 'Are these choices correct?' 0
    SINGLE_SHOW_REVIEW=0
    review_action="$SINGLE_RESULT"
    case "$review_action" in
      change) configure_wizard; build_application_review_cache 0 ;;
      exit) exit 0 ;;
      start) break ;;
    esac
  done

  show_review
  if [[ "$DRY_RUN" != 1 ]]; then save_wizard_choices
  else info 'dry run: wizard choices were not saved'; fi
  printf '\nStarting the required setup. After Phase 2, one Installation Centre prepares all required software before configuration.\n'

  setup_args=(--guided --track "$TRACK" --stack "$STACK" --name "$GIT_NAME" --email "$GIT_EMAIL" --primary-ide "$PRIMARY_IDE")
  if [[ -n "$DOTFILES_REPO" ]]; then setup_args+=(--dotfiles-repo "$DOTFILES_REPO")
  else setup_args+=(--new-dotfiles)
  fi
  setup_args+=(--dotfiles-versioning "$DOTFILES_VERSIONING")
  setup_args+=(--macos-settings "$MACOS_SETTINGS_PLAN")
  [[ "$DRY_RUN" == 1 ]] && setup_args+=(--dry-run)
  if bash "$HERE/setup.sh" "${setup_args[@]}"; then setup_rc=0; else setup_rc=$?; fi
  if [[ "$setup_rc" -eq 0 && "$DRY_RUN" != 1 ]]; then
    post_required_menu
  fi
  return "$setup_rc"
}

# The wizard is the default for a person. Fully specified commands retain the
# stable direct runner used by tests, automation and one-phase recovery.
case "${1:-}" in
  --optional)
    shift
    [[ "$#" -eq 0 || ( "$#" -eq 1 && "$1" == --guided ) ]] \
      || die '--optional accepts only an optional --guided flag.'
    run_optional_center
    exit 0
    ;;
  --applications)
    shift
    direct_applications "$@"
    ;;
  --safety-report|--preflight)
    shift
    direct_stage_zero preflight "$@"
    ;;
  --prepare-existing)
    shift
    if [[ "$#" -eq 0 ]]; then direct_stage_zero prepare --guided; fi
    direct_stage_zero prepare "$@"
    ;;
esac

[[ "$ORIGINAL_ARG_COUNT" == 0 ]] && WIZARD_CANDIDATE=1
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --wizard) FORCE_WIZARD=1 ;;
    --guided) WIZARD_CANDIDATE=1; PASSTHROUGH_ARGS+=("$1") ;;
    --dry-run) DRY_RUN=1; WIZARD_CANDIDATE=1; PASSTHROUGH_ARGS+=("$1") ;;
    -h|--help) usage; exit 0 ;;
    *) DIRECT_REQUEST=1; PASSTHROUGH_ARGS+=("$1") ;;
  esac
  shift
done

if [[ "$FORCE_WIZARD" == 1 && "$DIRECT_REQUEST" == 1 ]]; then
  die '--wizard accepts only --dry-run; choose track, stack, identity and dotfiles inside the wizard.'
fi

if [[ "$FORCE_WIZARD" == 1 || ( "$WIZARD_CANDIDATE" == 1 && "$DIRECT_REQUEST" == 0 ) ]]; then
  run_wizard
else
  direct_setup "${PASSTHROUGH_ARGS[@]}"
fi
