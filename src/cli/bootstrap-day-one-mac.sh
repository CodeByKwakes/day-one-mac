#!/usr/bin/env bash
# Choice-first entry point for the self-contained Day One Mac project.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HERE="$DAY_ONE_ROOT/scripts"
PROJECT_DIR="$(cd "$HERE/.." && pwd)"
DOC_DIR="$PROJECT_DIR/docs"
source "$HERE/../src/core/project-paths.sh"
source "$HERE/../src/core/terminal-ui.sh"
source "$HERE/../src/core/required-phase-catalog.sh"
source "$HERE/../src/core/wizard-centre.sh"
source "$HERE/../src/core/application-ownership.sh"
source "$HERE/../src/core/platform.sh"
source "$HERE/../src/core/state.sh"
source "$HERE/../src/core/operation-lock.sh"
source "$HERE/../src/core/developer-folders.sh"
source "$HERE/../src/core/configuration-choices.sh"
source "$HERE/../src/core/hosting-auth.sh"
ORIGINAL_ARGS=("$@")

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
CONTAINER_RUNTIME=auto

usage() {
  cat <<'EOF'
Usage: ./bootstrap-day-one-mac.sh [options]

Wizard:
  (no options)                 open the interactive setup centre
  --wizard                     browse phases, modules and other actions
  --guided                     open the wizard when no setup choices are supplied
  --dry-run                    preview the wizard's selected base setup
  --optional [--guided]        open optional setup only after Phase 8

Existing Mac — optional Stage 0 before Phase 1:
  --prepare-existing [options] choose Route A or Route B in the Stage 0 wizard
  --safety-report [options]    create only the read-only safety report

Compatibility:
  --preflight [options]        older name for --safety-report

Direct setup:
  --plan                      read-only phase impact plan; does not save choices
  --apply                     run selected phases explicitly (all eight by default)
  --check                     local read-only checks; manual gates remain explicit
  --resume                    reuse saved choices and recheck before skipping phases
  --json                      schema v1 output for --plan, --check or --status
  --accept-preparation        confirm updated macOS and backup/disposable data;
                              required with --yes for explicit Phase 1 actions
  --applications [options]    check app ownership; optionally install missing casks
  --install-centre            install/revalidate all required software, then exit
  --ssh-pin [PROVIDER]        save 1Password public keys to ~/.ssh, then exit
                              PROVIDER is github, azure, or both (default: the saved track)
  --phase NN                   run one required phase; repeatable
  --track 1|2|3|4             1 GitHub; 2 Azure DevOps; 3 both; 4 none of the above
  --stack node|python|both    language toolchain selection
  --layout LAYOUT             none, repository, purpose, or existing
  --ghq no|yes                optional ghq (not preselected)
  --ghq-root PATH             confirmed primary root for existing + ghq yes
  --name "Full Name"          Git author name
  --email ADDRESS             primary Git author email
  --preset PRESET            core or recommended-productivity (default)
  --primary-ide IDE           vscode or other; controls Git editor integration
  --dotfiles-repo URL         apply an existing private chezmoi source
  --new-dotfiles              create or keep a new chezmoi source
  --dotfiles-versioning MODE  none (unmanaged), local (chezmoi), or git (private repo)
  --local-dotfiles            create a local-only chezmoi source
  --shell MODE                keep the current zsh, apple zsh, or homebrew zsh
  --prompt MODE               none (preserve existing prompt) or starship
  --macos-settings MODE       configure or skip the early optional settings wizard
  --skip-macos-settings       continue to Phase 2 without preference changes
  --app-install-policy MODE   prompt, homebrew, or check-only for missing apps
  --https-helper MODE         gcm or existing HTTPS credential helper
  --github-repo URL           repository used to verify GitHub Git access
  --azure-repo URL            repository used to verify Azure Git access
  --github-clone-dir PATH     optionally clone after verification; none disables
  --azure-clone-dir PATH      optionally clone after verification; none disables
  --status                    show recorded completion, not live machine health
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
  exec bash "$HERE/../src/setup/setup.sh" "$@"
}

direct_stage_zero() {
  local command="$1"
  shift
  day_one_require_apple_silicon || exit 2
  case "$command" in
    preflight) exec bash "$HERE/../src/preflight/preflight-audit.sh" "$@" ;;
    prepare) exec bash "$HERE/../src/preflight/prepare-existing-mac.sh" "$@" ;;
  esac
}

direct_applications() {
  exec bash "$HERE/../src/operations/application-status.sh" "$@"
}

state_value() {
  [[ -r "$STATE_DIR/$1" ]] && sed -n '1p' "$STATE_DIR/$1" || true
}

save_state_value() {
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  day_one_write_state "$STATE_DIR/$1" "$2"
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
  ui_clear_screen
}

SINGLE_VALUES=()
SINGLE_LABELS=()
SINGLE_RESULT=""
SINGLE_SHOW_REVIEW=0
wizard_back_available() {
  local value
  [[ "${WIZARD_BACK_ENABLED:-0}" != 1 ]] || return 0
  for value in ${SINGLE_VALUES[@]+"${SINGLE_VALUES[@]}"}; do
    [[ "$value" != back && "$value" != finish ]] || return 0
  done
  return 1
}

wizard_back() {
  local value
  if [[ "${WIZARD_BACK_ENABLED:-0}" == 1 ]]; then return 11; fi
  for value in ${SINGLE_VALUES[@]+"${SINGLE_VALUES[@]}"}; do
    if [[ "$value" == back || "$value" == finish ]]; then SINGLE_RESULT="$value"; return 0; fi
  done
  return 1
}

select_one() {
  local heading="$1" default_index="$2" cursor key rest item radio details=0
  cursor="$default_index"
  while :; do
    clear_screen
    if [[ "$SINGLE_SHOW_REVIEW" == 1 ]]; then
      print_review_body "$details"
    else
      ui_banner '🍎' 'Day One Mac setup wizard'
    fi
    ui_prompt "$heading"
    ui_menu_window "${#SINGLE_VALUES[@]}" "$cursor"
    for ((item=DAY_ONE_UI_MENU_START; item<DAY_ONE_UI_MENU_END; item++)); do
      radio='( )'
      [[ "$item" != "$cursor" ]] || radio='(*)'
      ui_menu_item "$item" "$cursor" "$radio" "${SINGLE_LABELS[$item]}"
    done
    ui_menu_position "${#SINGLE_VALUES[@]}" "$cursor"
    ui_menu_help single
    if wizard_back_available; then ui_text 'b / Left Arrow: back'; fi
    [[ "$SINGLE_SHOW_REVIEW" != 1 ]] || ui_text 'd: toggle full setup details'
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
      d|D) if [[ "$details" == 1 ]]; then details=0; else details=1; fi ;;
      b|B|$'\033[D')
        if wizard_back_available; then
          clear_screen
          wizard_back
          return $?
        fi ;;
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
  local heading="$1" cursor=0 key rest item check
  while :; do
    clear_screen
    ui_banner '🍎' 'Day One Mac setup wizard'
    ui_prompt "$heading"
    ui_menu_window "${#MENU_VALUES[@]}" "$cursor" 11
    for ((item=DAY_ONE_UI_MENU_START; item<DAY_ONE_UI_MENU_END; item++)); do
      check='[ ]'
      [[ "${MENU_SELECTED[$item]}" != 1 ]] || check='[x]'
      ui_menu_item "$item" "$cursor" "$check" "${MENU_LABELS[$item]}"
    done
    ui_menu_position "${#MENU_VALUES[@]}" "$cursor"
    ui_menu_help toggle
    if [[ "${WIZARD_BACK_ENABLED:-0}" == 1 ]]; then ui_text 'b / Left Arrow: previous setup section'; fi
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
      b|B|$'\033[D')
        if [[ "${WIZARD_BACK_ENABLED:-0}" == 1 ]]; then clear_screen; return 11; fi ;;
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
  if [[ "${WIZARD_BACK_ENABLED:-0}" == 1 ]]; then ui_text 'Type :back to return to the previous setup section.'; fi
  printf '%s' "$label"
  [[ -n "$default" ]] && printf ' [%s]' "$default"
  printf ': '
  IFS= read -r answer
  if [[ "${WIZARD_BACK_ENABLED:-0}" == 1 && "$answer" == :back ]]; then return 11; fi
  PROMPT_RESULT="${answer:-$default}"
}

prompt_name() {
  local default="$1"
  while :; do
    prompt_value 'Git author name' "$default" || return $?
    if valid_line "$PROMPT_RESULT"; then GIT_NAME="$PROMPT_RESULT"; return 0; fi
    warn 'Enter a one-line name.'
  done
}

prompt_email() {
  local default="$1"
  while :; do
    prompt_value 'Primary Git email' "$default" || return $?
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
      vscode-profiles) label='VS Code profiles — moved to the application guide' ;;
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
    4) printf 'None of the above' ;;
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
  printf '  🔒 Phase 4  Core tools, preset applications and selected hosting services\n'
  printf '  🔒 Phase 5  Selected configuration ownership, shell and prompt\n'
  printf '  🔒 Phase 6  Selected language toolchains\n'
  printf '  🔒 Phase 7  Minimal VS Code base (skipped for core preset)\n'
  printf '  🔒 Phase 8  Verification, Brewfile and dotfiles protection\n'
  printf '  🧩 Then       Finish, view the report, or choose optional modules\n\n'
  printf '  🔒 means required. A ✓ appears only after a phase passes.\n\n'
}

print_review_body() {
  ui_banner '🧭' 'Review your setup'
  if [[ "${1:-1}" == 0 ]]; then
    ui_text "Track $TRACK: $(track_label "$TRACK") | preset: $PRESET"
    ui_text "Stack: $(stack_label "$STACK")"
    ui_text "Git: $GIT_NAME <$GIT_EMAIL> | auth: $AUTH_MODE"
    ui_text "Folders: $FOLDER_LAYOUT | ghq: $GHQ_CHOICE"
    [[ -z "$FOLDER_GHQ_ROOT" ]] || ui_text "Root: $FOLDER_GHQ_ROOT"
    [[ -z "${GITHUB_CLONE_DIR:-}" ]] || ui_text "GitHub clone: $GITHUB_CLONE_DIR"
    [[ -z "${AZURE_CLONE_DIR:-}" ]] || ui_text "Azure clone: $AZURE_CLONE_DIR"
    ui_text "Config: $DOTFILES_VERSIONING | shell: $SHELL_CHOICE | prompt: $PROMPT_CHOICE"
    ui_text "IDE: $PRIMARY_IDE | macOS settings: $MACOS_SETTINGS_PLAN"
    ui_text 'Required Phases 1-8 run first; optional modules run afterward.'
    return 0
  fi
  printf 'Required setup — preset: %s\n' "$PRESET"
  printf '  Hosting:   Track %s — %s\n' "$TRACK" "$(track_label "$TRACK")"
  printf '  Stack:     %s\n' "$(stack_label "$STACK")"
  printf '  Folders:   %s; ghq: %s\n' "$FOLDER_LAYOUT" "$GHQ_CHOICE"
  [[ -z "$FOLDER_GHQ_ROOT" ]] || printf '  Root:      %s\n' "$FOLDER_GHQ_ROOT"
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
  [[ "$AUTH_MODE" != https ]] || printf '  HTTPS:     %s credential helper\n' "$HTTPS_HELPER"
  printf '  Clones:    GitHub: %s; Azure: %s (none means verify only)\n' "${GITHUB_CLONE_DIR:-none}" "${AZURE_CLONE_DIR:-none}"
  if [[ -n "$DOTFILES_REPO" ]]; then
    printf '  Dotfiles:  existing private source — %s\n' "$DOTFILES_REPO"
  elif [[ "$DOTFILES_VERSIONING" == none ]]; then
    printf '  Dotfiles:  user-owned files — no chezmoi or remote required\n'
  elif [[ "$DOTFILES_VERSIONING" == local ]]; then
    printf '  Dotfiles:  local-only chezmoi source — no Git history or remote gate\n'
  else
    printf '  Dotfiles:  new chezmoi source — private Git required in Phase 8\n'
  fi
  printf '  Shell:     %s; prompt: %s (none preserves existing configuration)\n' "$SHELL_CHOICE" "$PROMPT_CHOICE"
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
  done < <(day_one_required_application_ids "$PRESET" "$AUTH_MODE")

  if [[ "$include_optional" == 1 ]] \
     && { contains_csv "$OPTIONAL_MODULES" databases || contains_csv "$OPTIONAL_MODULES" omniroute; }; then
    case "$CONTAINER_RUNTIME" in
      docker) optional_ids="${optional_ids}${optional_ids:+ }docker-desktop" ;;
      orbstack) optional_ids="${optional_ids}${optional_ids:+ }orbstack" ;;
    esac
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
    printf -- '- Developer layout: `%s`; ghq: `%s`; existing root: `%s`\n' "$FOLDER_LAYOUT" "$GHQ_CHOICE" "$FOLDER_GHQ_ROOT"
    printf -- '- Git name: `%s`\n' "$GIT_NAME"
    printf -- '- Git email: `%s`\n' "$GIT_EMAIL"
    printf -- '- Primary IDE: `%s`\n' "$PRIMARY_IDE"
    printf -- '- Early macOS settings: `%s`\n' "$MACOS_SETTINGS_PLAN"
    printf -- '- Git authentication: `%s`; HTTPS helper: `%s`\n' "$AUTH_MODE" "$HTTPS_HELPER"
    if [[ -n "$DOTFILES_REPO" ]]; then
      printf -- '- Dotfiles: existing private chezmoi source `%s`\n' "$DOTFILES_REPO"
    elif [[ "$DOTFILES_VERSIONING" == none ]]; then
      printf -- '- Dotfiles: user-owned files; no chezmoi or remote\n'
    elif [[ "$DOTFILES_VERSIONING" == local ]]; then
      printf -- '- Dotfiles: local-only chezmoi source; no Git history or remote gate\n'
    else
      printf -- '- Dotfiles: new chezmoi source with private Git required in Phase 8\n'
    fi
    printf -- '- Shell: `%s`; prompt: `%s`\n' "$SHELL_CHOICE" "$PROMPT_CHOICE"
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
    printf -- '- Container engine: `%s`\n' "$CONTAINER_RUNTIME"
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
  folders_save_choices || return $?
  save_state_value git-name "$GIT_NAME"
  save_state_value git-email "$GIT_EMAIL"
  save_state_value deployment-mode "${DEPLOYMENT_MODE:-personal}"
  save_state_value workstation-policy "${WORKSTATION_POLICY:-}"
  save_state_value preset "$PRESET"
  save_state_value primary-ide "$PRIMARY_IDE"
  save_state_value dotfiles-repo "$DOTFILES_REPO"
  save_state_value dotfiles-versioning "$DOTFILES_VERSIONING"
  save_state_value shell-choice "$SHELL_CHOICE"
  save_state_value prompt-choice "$PROMPT_CHOICE"
  save_state_value configuration-schema 1
  save_state_value auth-mode "$AUTH_MODE"
  save_state_value https-helper "$HTTPS_HELPER"
  save_state_value github-verification-repo "$GITHUB_REPO"
  save_state_value azure-verification-repo "$AZURE_REPO"
  save_state_value github-clone-dir "$GITHUB_CLONE_DIR"
  save_state_value azure-clone-dir "$AZURE_CLONE_DIR"
  save_state_value macos-settings-plan "$MACOS_SETTINGS_PLAN"
  save_state_value optional-modules "$OPTIONAL_MODULES"
  save_state_value database-services "$DATABASE_SERVICES"
  save_state_value container-runtime "$CONTAINER_RUNTIME"
  save_state_value ai-clients "$AI_CLIENTS"
  save_state_value mcp-servers "$MCP_SERVERS"
  write_wizard_report
  ok "wizard choices saved to $STATE_DIR/wizard-selections.md"
}

choose_track() {
  local default_index=0
  case "$TRACK" in 2) default_index=1 ;; 3) default_index=2 ;; 4) default_index=3 ;; esac
  SINGLE_VALUES=(1 2 3 4)
  SINGLE_LABELS=('Track 1 — GitHub' 'Track 2 — Azure DevOps' 'Track 3 — GitHub + Azure DevOps' 'Track 4 — None of the above; manage repository access yourself')
  select_one 'Choose the hosting services this Mac will use:' "$default_index" || return $?
  TRACK="$SINGLE_RESULT"
}

choose_folders() {
  local default_index=0
  case "$FOLDER_LAYOUT" in repository) default_index=1 ;; purpose) default_index=2 ;; existing) default_index=3 ;; esac
  SINGLE_VALUES=(none repository purpose existing)
  SINGLE_LABELS=(
    'No predefined layout — create/reuse ~/Developer only'
    'Repository-oriented — host/owner/repository under ~/Developer'
    'Purpose-oriented — Projects, Sandbox, Resources, Archive'
    'Keep existing — preserve roots and all repository locations'
  )
  select_one 'Choose future placement; no repositories will be moved:' "$default_index" || return $?
  FOLDER_LAYOUT="$SINGLE_RESULT"
  SINGLE_VALUES=(no yes)
  SINGLE_LABELS=('Do not select ghq — leave any existing copy and settings untouched' 'Select ghq — install if missing; review existing settings before configuring')
  default_index=0
  [[ "$GHQ_CHOICE" != yes ]] || default_index=1
  select_one 'Use ghq for repository cloning and discovery?' "$default_index" || return $?
  GHQ_CHOICE="$SINGLE_RESULT"
  if [[ "$GHQ_CHOICE" == yes && "$FOLDER_LAYOUT" == existing ]]; then
    printf '\nReview ghq root --all in another terminal. No roots will be rewritten.\n'
    while :; do
      prompt_value 'Confirmed absolute primary root (the output of ghq root)' "$FOLDER_GHQ_ROOT" || return $?
      FOLDER_GHQ_ROOT="$PROMPT_RESULT"
      [[ "$FOLDER_GHQ_ROOT" == /* && "$FOLDER_GHQ_ROOT" != *[$'\t\r\n']* ]] && break
      warn 'Enter an absolute, single-line path.'
    done
  else FOLDER_GHQ_ROOT=''
  fi
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
    select_toggles 'Choose one or both development stacks:' || return $?
    case "$MENU_RESULT" in
      node) STACK=node; return 0 ;;
      python) STACK=python; return 0 ;;
      node,python) STACK=both; return 0 ;;
      *) warn 'Select at least one development stack.' ;;
    esac
  done
}

choose_preset() {
  local default_index=0
  [[ "$PRESET" == core ]] && default_index=1
  SINGLE_VALUES=(recommended-productivity core)
  SINGLE_LABELS=(
    'Recommended productivity — includes VS Code, Raycast, Warp and the Nerd Font'
    'Core — command-line tools only; 1Password only if selected for authentication'
  )
  select_one 'Choose the software preset' "$default_index" || return $?
  PRESET="$SINGLE_RESULT"
}

choose_primary_ide() {
  local default_index=0
  [[ "$PRIMARY_IDE" == other ]] && default_index=1
  SINGLE_VALUES=(vscode other)
  SINGLE_LABELS=(
    'Yes — use VS Code for Git commit messages, diffs and merge conflicts'
    'No — keep Git editor, diff and merge-tool settings unchanged'
  )
  select_one 'Use VS Code for Git and chezmoi editing? (VS Code remains installed with this preset)' "$default_index" || return $?
  PRIMARY_IDE="$SINGLE_RESULT"
}

choose_auth_mode() {
  local default_index=0
  [[ "$TRACK" != 4 || -n "$AUTH_MODE" ]] || default_index=3
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
  select_one 'Choose how Git authenticates:' "$default_index" || return $?
  AUTH_MODE="$SINGLE_RESULT"
  case "$AUTH_MODE" in
    keychain) printf '\nA private key will be created in ~/.ssh and protected by a passphrase you choose.\n\n' ;;
    external) printf '\nDay One Mac will not create a key; it only checks that your agent offers one.\n\n' ;;
    https)    printf '\nNo SSH key is set up. Choose a credential helper for Git access.\n\n' ;;
  esac
  if [[ "$AUTH_MODE" == https ]]; then
    SINGLE_VALUES=(gcm existing)
    SINGLE_LABELS=('Git Credential Manager — browser sign-in (recommended for Azure)' 'GitHub CLI / existing Azure helper — company-managed or PAT/Keychain')
    default_index=0
    [[ "${HTTPS_HELPER:-gcm}" != existing ]] || default_index=1
    select_one 'Choose the HTTPS Git credential helper:' "$default_index" || return $?
    HTTPS_HELPER="$SINGLE_RESULT"
  else HTTPS_HELPER=existing
  fi
}

choose_verification_repos() {
  local provider provider_label url destination name action
  case "$TRACK" in
    1) AZURE_CLONE_DIR=none ;;
    2) GITHUB_CLONE_DIR=none ;;
    4) GITHUB_CLONE_DIR=none; AZURE_CLONE_DIR=none ;;
  esac
  # Keep the provider list on its own descriptor: menus and URL prompts must
  # continue reading the person's terminal, not this process substitution.
  while IFS= read -r provider <&3; do
    case "$provider" in github) provider_label=GitHub ;; azure) provider_label='Azure DevOps' ;; esac
    SINGLE_VALUES=(none clone)
    SINGLE_LABELS=('No — verify access without downloading a repository (default)' 'Yes — clone a repository to verify access')
    select_one "Would you like to clone a repository from $provider_label to verify access?" 0 || return $?
    action="$SINGLE_RESULT"
    printf '\nBoth options need a repository you can read. Prefer a private repository to check authenticated access.\n'
    if [[ "$action" == clone ]]; then
      printf 'Phase 4 will check access, then clone into the folder you choose.\n'
    else
      printf 'Only remote access will be checked; no clone will be created.\n'
    fi
    while :; do
      prompt_value "$provider repository URL ($AUTH_MODE)" "$(hosting_repo_url "$provider")" || return $?
      url="$PROMPT_RESULT"
      if hosting_repo_valid "$provider" "$url" "$AUTH_MODE"; then break; fi
      warn 'Use the exact provider clone URL for the selected transport, without tokens.'
    done
    case "$provider" in github) GITHUB_REPO="$url" ;; azure) AZURE_REPO="$url" ;; esac
    destination=none
    if [[ "$action" == clone ]]; then
      destination="$(hosting_clone_dir "$provider")"
      if [[ "$destination" == none ]]; then
        name="${url%/}"; name="${name##*/}"; name="${name%.git}"
        destination="$(folders_target_root)/$name"
      fi
      while :; do
        prompt_value "$provider clone destination (absolute path; existing files are preserved)" "$destination" || return $?
        destination="$PROMPT_RESULT"
        hosting_clone_dir_valid "$destination" && break
        warn 'Choose an absolute folder path without symlinks, parent traversal or a trailing slash.'
      done
    fi
    case "$provider" in github) GITHUB_CLONE_DIR="$destination" ;; azure) AZURE_CLONE_DIR="$destination" ;; esac
  done 3< <(hosting_provider_ids)
}

choose_dotfiles() {
  local default_index=0
  [[ "$DOTFILES_VERSIONING" == local ]] && default_index=1
  [[ "$DOTFILES_VERSIONING" == git ]] && default_index=2
  [[ -n "$DOTFILES_REPO" ]] && default_index=3
  SINGLE_VALUES=(none new-local new-git existing)
  SINGLE_LABELS=(
    'Keep configuration user-owned — do not install or use chezmoi'
    'Create a local-only chezmoi source without Git version history'
    'Create a new chezmoi source and protect it with private Git'
    'Use an existing private dotfiles repository'
  )
  select_one 'Choose who manages your configuration files:' "$default_index" || return $?
  if [[ "$SINGLE_RESULT" == existing ]]; then
    while :; do
      prompt_value 'Private dotfiles repository URL' "$DOTFILES_REPO" || return $?
      if valid_line "$PROMPT_RESULT" && [[ "$PROMPT_RESULT" != *[[:space:]]* ]]; then
        DOTFILES_REPO="$PROMPT_RESULT"
        DOTFILES_VERSIONING=git
        return 0
      fi
      warn 'Enter a one-line repository URL without spaces.'
    done
  fi
  DOTFILES_REPO=""
  if [[ "$SINGLE_RESULT" == none ]]; then DOTFILES_VERSIONING=none
  elif [[ "$SINGLE_RESULT" == new-local ]]; then DOTFILES_VERSIONING=local
  else DOTFILES_VERSIONING=git
  fi
}

choose_shell_and_prompt() {
  local default_index=0
  [[ "$SHELL_CHOICE" != apple ]] || default_index=1
  [[ "$SHELL_CHOICE" != homebrew ]] || default_index=2
  SINGLE_VALUES=(keep apple homebrew)
  SINGLE_LABELS=('Keep my current zsh login shell (other shells need manual setup)' 'Use Apple /bin/zsh' 'Install and use Homebrew zsh')
  select_one 'Choose the login shell; existing shell files are preserved for review:' "$default_index" || return $?
  SHELL_CHOICE="$SINGLE_RESULT"
  default_index=0
  [[ "$PROMPT_CHOICE" != starship ]] || default_index=1
  SINGLE_VALUES=(none starship)
  SINGLE_LABELS=('Leave my existing prompt alone' 'Install and configure Starship')
  select_one 'Choose the prompt independently of the shell and chezmoi:' "$default_index" || return $?
  PROMPT_CHOICE="$SINGLE_RESULT"
}

choose_database_services() {
  MENU_VALUES=(postgres redis mongodb)
  MENU_LABELS=('PostgreSQL' 'Redis' 'MongoDB')
  selected_defaults "$1" postgres redis mongodb
  select_toggles "$2" || return $?
}

choose_container_engine() {
  SINGLE_VALUES=(auto docker orbstack)
  SINGLE_LABELS=('Use the installed engine (detect Docker Desktop or OrbStack)' 'Docker Desktop' 'OrbStack')
  select_one 'Choose a container engine:' 0 || return $?
  CONTAINER_RUNTIME="$SINGLE_RESULT"
}

choose_ai_clients() {
  MENU_VALUES=(claude codex copilot-app copilot-vscode copilot-cli raycast-ai)
  MENU_LABELS=('Claude Code' 'OpenAI Codex' 'GitHub Copilot app — standalone desktop client' 'GitHub Copilot in VS Code' 'GitHub Copilot CLI' 'Raycast AI — paid plan required for custom providers')
  selected_defaults "$1" claude codex copilot-app copilot-vscode copilot-cli raycast-ai
  select_toggles "$2" || return $?
}

choose_optional_plan() {
  local previous_databases="$DATABASE_SERVICES"
  local previous_ai_clients="$AI_CLIENTS" previous_mcp_servers="$MCP_SERVERS"
  MENU_VALUES=(databases ai-clients omniroute mcp-servers enhanced-cli warp-drive advanced second-brain)
  MENU_LABELS=(
    'Databases — PostgreSQL, Redis or MongoDB'
    'AI clients — Claude Code, Codex, GitHub Copilot or Raycast AI'
    'OmniRoute AI gateway — local Docker routing for selected AI clients'
    'MCP servers — requires at least one selected AI client'
    'Enhanced CLI tools — eza, lazydocker, shell helpers and more'
    'Warp Drive — importable workflows and command notebook'
    'Advanced modules — identities, worktrees, HTTPS, restore and audits'
    'Second Brain — choose an Obsidian or Notion knowledge system'
  )
  selected_defaults "$OPTIONAL_MODULES" databases ai-clients omniroute mcp-servers enhanced-cli warp-drive advanced second-brain
  select_toggles 'Choose optional modules to plan for after Phase 8 (none is valid):' || return $?
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
    choose_database_services "$previous_databases" 'Choose database services (none removes Databases from the plan):'
    DATABASE_SERVICES="$MENU_RESULT"
    if [[ -z "$DATABASE_SERVICES" ]]; then
      OPTIONAL_MODULES="$(without_csv_value "$OPTIONAL_MODULES" databases)"
      warn 'Databases were removed from the optional plan because no service was selected.'
    fi
  fi

  if contains_csv "$OPTIONAL_MODULES" databases || contains_csv "$OPTIONAL_MODULES" omniroute; then
    choose_container_engine
  fi

  AI_CLIENTS=""
  if contains_csv "$OPTIONAL_MODULES" ai-clients; then
    choose_ai_clients "$previous_ai_clients" 'Choose AI clients (none also removes OmniRoute and MCP from the plan):'
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
    select_toggles 'Choose MCP servers (none removes MCP servers from the plan):' || return $?
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
  save_state_value container-runtime "$CONTAINER_RUNTIME"
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
    info "Resume the required setup with: $HERE/../src/cli/bootstrap-day-one-mac.sh --wizard"
    exit 10
  }

  while :; do
    choose_optional_plan
    build_application_review_cache 1
    SINGLE_VALUES=(save change exit)
    SINGLE_LABELS=(
      'Save this optional plan — then continue to available installers and guides'
      'Go back and change optional choices'
      'Exit without changing the saved optional plan'
    )
    SHOW_OPTIONAL_REVIEW=1
    SINGLE_SHOW_REVIEW=1
    select_one 'Save this optional plan?' 0 || return $?
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
    info "Guides: $PROJECT_DIR/docs/how-to/modules/optional/"
    info 'Saving a selection does not claim installation; each selected module must verify its own outcome.'
    info 'Unified status: day-one-mac optional --status'
    if contains_csv "$OPTIONAL_MODULES" databases; then
      SINGLE_VALUES=(install finish)
      SINGLE_LABELS=(
        'Install or resume the selected database services now'
        'Exit with the database selection saved for later'
      )
      select_one 'Databases are selected. Continue now?' 0 || return $?
      if [[ "$SINGLE_RESULT" == install ]]; then
        bash "$HERE/../src/modules/configure-databases.sh" --services "$DATABASE_SERVICES" --disposable-data
      else
        info "Resume later: day-one-mac databases --saved"
      fi
    fi
    contains_csv "$OPTIONAL_MODULES" enhanced-cli \
      && info 'Enhanced CLI installer: day-one-mac cli-tools'
    contains_csv "$OPTIONAL_MODULES" ai-clients \
      && info 'AI payload preview: day-one-mac optional --module 10 --plan (sign-in remains manual)'
    contains_csv "$OPTIONAL_MODULES" vscode-profiles \
      && info 'Profiles moved: day-one-mac vscode-profile full-stack --dry-run (choose a recipe in the VS Code application guide)'
    contains_csv "$OPTIONAL_MODULES" warp-drive \
      && info 'Warp export preview: day-one-mac optional --module 14 --plan (import remains manual)'
    contains_csv "$OPTIONAL_MODULES" advanced \
      && info 'Advanced guided tracker: day-one-mac advanced --guided'
    if contains_csv "$OPTIONAL_MODULES" ai-clients \
       || contains_csv "$OPTIONAL_MODULES" omniroute \
       || contains_csv "$OPTIONAL_MODULES" mcp-servers \
       || contains_csv "$OPTIONAL_MODULES" warp-drive \
       || contains_csv "$OPTIONAL_MODULES" second-brain; then
      info 'The remaining selected modules contain account, secret, or application UI decisions; follow their installed guides.'
      info 'Open them with: day-one-mac docs optional --open'
    fi
  else
    ok 'No optional modules selected. The required setup remains complete.'
  fi
}

post_required_menu() {
  local action
  while :; do
    SINGLE_VALUES=(finish optional advanced actions report)
    SINGLE_LABELS=(
      'Return to setup centre (recommended)'
      'Browse optional modules'
      'Browse advanced modules'
      'Open other actions'
      'View the final verification report'
    )
    select_one '✅ Required Day One Mac setup is complete. What would you like to do next?' 0 || return $?
    action="$SINGLE_RESULT"
    case "$action" in
      finish) return 0 ;;
      optional) centre_modules optional; return 0 ;;
      advanced) centre_modules advanced; return 0 ;;
      actions) centre_other_actions; return 0 ;;
      report) show_verification_report ;;
    esac
  done
}

choose_git_identity() {
  local default_name default_email
  clear_screen
  ui_banner '🔐' 'Git identity'
  printf 'This identity becomes the global default. Advanced Module 18 adds multiple identities later.\n\n'
  default_name="${GIT_NAME:-$(git config --global user.name 2>/dev/null || id -F 2>/dev/null || id -un)}"
  default_email="${GIT_EMAIL:-$(git config --global user.email 2>/dev/null || true)}"
  prompt_name "$default_name" || return $?
  prompt_email "$default_email" || return $?
}

choose_deployment() {
  local default_index=0
  [[ "${DEPLOYMENT_MODE:-personal}" != managed ]] || default_index=1
  SINGLE_VALUES=(personal managed)
  SINGLE_LABELS=('Personal Mac — local ownership and recovery evidence' 'Managed Mac — approved MDM/account policy required')
  select_one 'Who manages this Mac?' "$default_index" || return $?
  DEPLOYMENT_MODE="$SINGLE_RESULT"
  WORKSTATION_POLICY=''
  if [[ "$DEPLOYMENT_MODE" == managed ]]; then
    prompt_value 'Approved workstation policy JSON path (from IT)' '' || return $?
    WORKSTATION_POLICY="$PROMPT_RESULT"
    [[ -r "$WORKSTATION_POLICY" ]] || { warn 'The approved policy must be readable. See the managed workstation guide.'; return 11; }
  fi
}

configure_wizard() {
  local step=0 status WIZARD_BACK_ENABLED=1
  local steps=(choose_track choose_stack choose_folders choose_git_identity choose_preset choose_primary_ide choose_auth_mode choose_verification_repos choose_dotfiles choose_shell_and_prompt choose_deployment)
  while [[ "$step" -lt "${#steps[@]}" ]]; do
    # Core has no editor question; Track 4 has no provider access question.
    if [[ "$step" == 5 && "$PRESET" == core ]]; then PRIMARY_IDE=other; step=$((step + 1)); continue; fi
    if [[ "$step" == 7 && "$TRACK" == 4 ]]; then
      choose_verification_repos || return $?
      step=$((step + 1)); continue
    fi
    if "${steps[$step]}"; then status=0; else status=$?; fi
    if [[ "$status" == 11 ]]; then
      if [[ "$step" == 0 ]]; then return 11; fi
      step=$((step - 1))
      [[ "$step" != 5 || "$PRESET" != core ]] || step=$((step - 1))
      [[ "$step" != 7 || "$TRACK" != 4 ]] || step=$((step - 1))
    elif [[ "$status" != 0 ]]; then return "$status"
    else step=$((step + 1))
    fi
  done
  # Keep the initial wizard focused on the required base. The runner asks
  # whether to configure optional macOS preferences immediately after Phase 1.
  MACOS_SETTINGS_PLAN=ask
}

has_saved_core_choices() {
  [[ "$(state_value track-schema-version)" == 2 ]] \
    && [[ "$FOLDER_LAYOUT" =~ ^(none|repository|purpose|existing)$ ]] \
    && [[ "$GHQ_CHOICE" =~ ^(yes|no)$ ]] \
    && [[ "$(state_value track)" =~ ^[1234]$ ]] \
    && [[ "$(state_value stack)" =~ ^(node|python|both)$ ]] \
    && [[ "$DOTFILES_VERSIONING" =~ ^(none|git|local)$ ]] \
    && [[ "$SHELL_CHOICE" =~ ^(keep|apple|homebrew)$ ]] \
    && [[ "$PROMPT_CHOICE" =~ ^(none|starship)$ ]] \
    && valid_line "$(state_value git-name)" \
    && valid_email "$(state_value git-email)"
}

load_saved_choices() {
  TRACK="$(state_value track)"
  STACK="$(state_value stack)"
  FOLDER_LAYOUT="$(state_value folder-layout)"
  GHQ_CHOICE="$(state_value ghq-choice)"
  FOLDER_GHQ_ROOT="$(state_value folder-ghq-root)"
  GIT_NAME="$(state_value git-name)"
  GIT_EMAIL="$(state_value git-email)"
  DEPLOYMENT_MODE="$(state_value deployment-mode)"
  DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-personal}"
  WORKSTATION_POLICY="$(state_value workstation-policy)"
  PRESET="$(state_value preset)"
  PRESET="${PRESET:-recommended-productivity}"
  PRIMARY_IDE="$(state_value primary-ide)"
  [[ "$PRESET" != core ]] || PRIMARY_IDE=other
  DOTFILES_REPO="$(state_value dotfiles-repo)"
  DOTFILES_VERSIONING="$(state_value dotfiles-versioning)"
  SHELL_CHOICE="$(state_value shell-choice)"
  PROMPT_CHOICE="$(state_value prompt-choice)"
  configuration_load_choices
  AUTH_MODE="$(state_value auth-mode)"
  # Setups saved before this choice existed all used the 1Password agent.
  [[ -n "$AUTH_MODE" ]] || AUTH_MODE=1password
  hosting_load_choices
  MACOS_SETTINGS_PLAN="$(state_value macos-settings-plan)"
  [[ -n "$MACOS_SETTINGS_PLAN" ]] || MACOS_SETTINGS_PLAN=ask
  OPTIONAL_MODULES="$(state_value optional-modules)"
  DATABASE_SERVICES="$(state_value database-services)"
  AI_CLIENTS="$(state_value ai-clients)"
  MCP_SERVERS="$(state_value mcp-servers)"
  CONTAINER_RUNTIME="$(state_value container-runtime)"
  [[ -n "$CONTAINER_RUNTIME" ]] || CONTAINER_RUNTIME=auto
}

choose_machine_state() {
  SINGLE_VALUES=(clean existing unsure back)
  SINGLE_LABELS=(
    'New or factory-reset Mac — continue to the eight required phases'
    'Existing Mac with data or settings — choose Route A or Route B'
    'Not sure — open Stage 0 and create the read-only safety report first'
    'Back to setup centre without changing anything'
  )
  select_one 'What state is this Mac in?' 0 || return $?
  case "$SINGLE_RESULT" in
    clean) return 0 ;;
    existing)
      if [[ "$DRY_RUN" == 1 ]]; then direct_stage_zero prepare --guided --dry-run
      else direct_stage_zero prepare --guided
      fi
      ;;
    unsure) direct_stage_zero prepare --guided ;;
    back) return 11 ;;
  esac
}

run_wizard() {
  local review_action setup_rc
  day_one_require_apple_silicon || exit 2
  [[ -t 0 && -t 1 ]] || die 'The setup wizard requires an interactive terminal. Use --track, --stack, --name and --email for a non-interactive run.'
  [[ "$DRY_RUN" == 1 ]] || day_one_serialize setup "$0" "${ORIGINAL_ARGS[@]}"
  load_saved_choices
  if has_saved_core_choices; then
    SINGLE_VALUES=(resume change status back)
    SINGLE_LABELS=(
      'Resume with the saved choices (recommended)'
      'Review or change setup choices'
      'Show detailed phase status'
      'Back to setup centre'
    )
    select_one "Saved setup found: Track $TRACK — $(track_label "$TRACK"); $(stack_label "$STACK")" 0 || return $?
    case "$SINGLE_RESULT" in
      change) configure_wizard || { [[ "$?" == 11 ]] && return 0; return 1; } ;;
      status) direct_setup --status ;;
      back) return 0 ;;
    esac
    [[ "$PRIMARY_IDE" =~ ^(vscode|other)$ ]] || choose_primary_ide
  else
    choose_machine_state || { [[ "$?" == 11 ]] && return 0; return 1; }
    configure_wizard || { [[ "$?" == 11 ]] && return 0; return 1; }
  fi

  if [[ "$TRACK" != 4 ]] && { [[ "$TRACK" != 2 && -z "$GITHUB_REPO" ]] || [[ "$TRACK" != 1 && -z "$AZURE_REPO" ]]; }; then
    choose_verification_repos
  fi
  build_application_review_cache 0

  while :; do
    SINGLE_VALUES=(start change back)
    if [[ "$DRY_RUN" == 1 ]]; then
      SINGLE_LABELS=('Preview the selected setup without saving' 'Go back and change choices' 'Back to setup centre without saving')
    else
      SINGLE_LABELS=('Save choices and begin or resume setup' 'Go back and change choices' 'Back to setup centre without saving')
    fi
    SINGLE_SHOW_REVIEW=1
    select_one 'Are these choices correct?' 0 || return $?
    SINGLE_SHOW_REVIEW=0
    review_action="$SINGLE_RESULT"
    case "$review_action" in
      change) configure_wizard || { [[ "$?" == 11 ]] && return 0; return 1; }; build_application_review_cache 0 ;;
      back) return 0 ;;
      start) break ;;
    esac
  done

  show_review
  if [[ "$DRY_RUN" != 1 ]]; then save_wizard_choices
  else info 'dry run: wizard choices were not saved'; fi
  printf '\nStarting the required setup. After Phase 2, one Installation Centre prepares all required software before configuration.\n'

  setup_args=(--guided --track "$TRACK" --stack "$STACK" --name "$GIT_NAME" --email "$GIT_EMAIL" --primary-ide "$PRIMARY_IDE")
  setup_args+=(--layout "$FOLDER_LAYOUT" --ghq "$GHQ_CHOICE")
  [[ -z "$FOLDER_GHQ_ROOT" ]] || setup_args+=(--ghq-root "$FOLDER_GHQ_ROOT")
  if [[ -n "$DOTFILES_REPO" ]]; then setup_args+=(--dotfiles-repo "$DOTFILES_REPO")
  else setup_args+=(--new-dotfiles)
  fi
  setup_args+=(--deployment "${DEPLOYMENT_MODE:-personal}" --preset "$PRESET" --auth-mode "$AUTH_MODE")
  [[ -z "${WORKSTATION_POLICY:-}" ]] || setup_args+=(--policy "$WORKSTATION_POLICY")
  setup_args+=(--https-helper "$HTTPS_HELPER")
  [[ -z "$GITHUB_REPO" ]] || setup_args+=(--github-repo "$GITHUB_REPO")
  [[ -z "$AZURE_REPO" ]] || setup_args+=(--azure-repo "$AZURE_REPO")
  setup_args+=(--github-clone-dir "${GITHUB_CLONE_DIR:-none}" --azure-clone-dir "${AZURE_CLONE_DIR:-none}")
  setup_args+=(--dotfiles-versioning "$DOTFILES_VERSIONING")
  setup_args+=(--shell "$SHELL_CHOICE" --prompt "$PROMPT_CHOICE")
  setup_args+=(--macos-settings "$MACOS_SETTINGS_PLAN")
  [[ "$DRY_RUN" == 1 ]] && setup_args+=(--dry-run)
  if bash "$HERE/../src/setup/setup.sh" "${setup_args[@]}"; then setup_rc=0; else setup_rc=$?; fi
  if [[ "$setup_rc" -eq 0 && "$DRY_RUN" != 1 ]]; then
    post_required_menu
  fi
  return "$setup_rc"
}

# The wizard is the default for a person. Fully specified commands retain the
# stable direct runner used by tests, automation and one-phase recovery.
case "${1:-}" in
  --configure)
    # Internal entry keeps the setup lock scoped to configuration and execution,
    # rather than holding it while someone browses the read-only centre.
    shift
    [[ "$#" == 0 || ( "$#" == 1 && "$1" == --dry-run ) ]] || die 'Invalid configuration wizard options.'
    [[ "$#" == 0 ]] || DRY_RUN=1
    run_wizard
    exit $?
    ;;
  --optional)
    shift
    [[ "$#" -eq 0 || ( "$#" -eq 1 && "$1" == --guided ) ]] \
      || die '--optional accepts only an optional --guided flag.'
    day_one_serialize setup "$0" "${ORIGINAL_ARGS[@]}"
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
  run_setup_centre
else
  direct_setup "${PASSTHROUGH_ARGS[@]}"
fi
