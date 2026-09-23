#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${SECOND_BRAIN_NOTION_CONFIG_DIR:-$HOME/.config/second-brain-notion}"
STATE_DIR="${SECOND_BRAIN_NOTION_STATE_DIR:-$HOME/.local/state/second-brain-notion}"
RAYCAST_DIR="${SECOND_BRAIN_NOTION_RAYCAST_DIR:-$HOME/.local/share/second-brain-notion/raycast}"
CONFIG_FILE="$CONFIG_DIR/config"
PLAN_FILE="$STATE_DIR/setup-plan.md"
APPLY=0
GUIDED=0
ACTION=plan
USAGE_TYPE=personal
DOMAINS='Software Development,Software Content,Tech Content'
ASSISTANTS=none
RAYCAST=no
HQ_URL=
CAPTURE_URL=

usage() {
  cat <<'EOF'
Usage: ./scripts/notion-second-brain-manager.sh [action] [options]

Actions:
  --guided                 Ask for choices interactively.
  --show                   Show the saved local plan.
  --validate               Validate saved configuration and local assets.
  --help                   Show this help.

Planning options:
  --usage personal|work|separate
  --domains "Name,Another Name"
  --assistants none|notion-ai|claude|codex|comma-separated-list
  --raycast yes|no
  --hq-url URL
  --capture-url URL
  --apply                  Save the reviewed plan and local helper files.

Without --apply, the command only previews. It never signs in to Notion,
creates cloud pages, or stores a Notion/API/AI credential.
EOF
}

die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }
note() { printf '  ℹ %s\n' "$*"; }
pass() { printf '  ✓ %s\n' "$*"; }

valid_url() {
  [[ -z "$1" || "$1" =~ ^https://([A-Za-z0-9-]+\.)*(notion\.so|notion\.site)(/|$) ]]
}

normalise_domains() {
  printf '%s' "$1" |
    tr ',' '\n' |
    awk '{$1=$1; if (length && !seen[$0]++) print}' |
    paste -sd ',' -
}

validate_choices() {
  case "$USAGE_TYPE" in personal|work|separate) ;; *) die "usage must be personal, work, or separate" ;; esac
  DOMAINS="$(normalise_domains "$DOMAINS")"
  [[ -n "$DOMAINS" ]] || die 'select at least one domain'
  case "$RAYCAST" in yes|no) ;; *) die 'raycast must be yes or no' ;; esac
  [[ -n "$ASSISTANTS" ]] || die 'assistants cannot be empty'
  if [[ "$ASSISTANTS" == *none* && "$ASSISTANTS" != none ]]; then
    die 'none cannot be combined with another assistant'
  fi
  local item
  IFS=',' read -r -a selected <<< "$ASSISTANTS"
  for item in "${selected[@]}"; do
    case "$item" in none|notion-ai|claude|codex) ;; *) die "unsupported assistant: $item" ;; esac
  done
  valid_url "$HQ_URL" || die 'HQ URL must be an https:// notion.so or notion.site URL'
  valid_url "$CAPTURE_URL" || die 'capture URL must be an https:// notion.so or notion.site URL'
}

ask_value() {
  local prompt="$1" default="$2" answer
  printf '%s [%s]: ' "$prompt" "$default"
  IFS= read -r answer
  printf '%s' "${answer:-$default}"
}

ask_yes_no() {
  local prompt="$1" default="$2" answer suffix='[y/N]'
  [[ "$default" == yes ]] && suffix='[Y/n]'
  printf '%s %s: ' "$prompt" "$suffix"
  IFS= read -r answer
  case "${answer:-$default}" in y|Y|yes|YES) printf yes ;; *) printf no ;; esac
}

run_guided() {
  [[ -t 0 ]] || die '--guided needs an interactive terminal'
  printf '\n🧠 Notion Second Brain planner\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf 'This plans the workspace. It does not connect to Notion or store secrets.\n\n'
  USAGE_TYPE="$(ask_value 'Use: personal, work, or separate' "$USAGE_TYPE")"
  DOMAINS="$(ask_value 'Domains, separated by commas' "$DOMAINS")"
  ASSISTANTS="$(ask_value 'Assistants: none, notion-ai, claude, codex (comma-separated)' "$ASSISTANTS")"
  RAYCAST="$(ask_yes_no 'Create optional Raycast Script Commands?' "$RAYCAST")"
  if [[ "$RAYCAST" == yes ]]; then
    HQ_URL="$(ask_value 'Second Brain HQ URL; leave blank if not created yet' "$HQ_URL")"
    CAPTURE_URL="$(ask_value 'Private capture form URL; leave blank if not created yet' "$CAPTURE_URL")"
  fi
}

write_plan() {
  local target="$1" generated
  generated="$(date -u '+%Y-%m-%d %H:%M UTC')"
  {
    printf '# Notion Second Brain setup plan\n\n'
    printf 'Generated: %s\n\n' "$generated"
    printf '## Selected boundary\n\n- Usage: **%s**\n' "$USAGE_TYPE"
    if [[ "$USAGE_TYPE" == separate ]]; then
      printf '%s\n' '- Personal and work information use separate approved workspaces/accounts.'
    fi
    printf '\n## Domains\n\n'
    tr ',' '\n' <<< "$DOMAINS" | while IFS= read -r domain; do printf -- '- %s\n' "$domain"; done
    printf '\n## Optional integrations\n\n- AI assistants: %s\n- Raycast: %s\n' "$ASSISTANTS" "$RAYCAST"
    printf -- '- HQ URL recorded: %s\n' "$([[ -n "$HQ_URL" ]] && printf yes || printf no)"
    printf -- '- Capture URL recorded: %s\n' "$([[ -n "$CAPTURE_URL" ]] && printf yes || printf no)"
    printf '\n## Build order\n\n'
    printf '%s\n' '1. Create Second Brain HQ and Domains.' '2. Create Knowledge, Projects, and Sources.' '3. Add relations and templates.' '4. Build linked dashboard views.' '5. Add optional Raycast and AI integrations.' '6. Test capture, review, search, permissions, and export.'
    printf '\n> AI Allowed is a workflow field, not a permission boundary.\n'
  } > "$target"
}

csv_value() {
  local value="$1"
  value="${value//\"/\"\"}"
  printf '"%s"' "$value"
}

write_seeds() {
  local domain kind sensitivity
  case "$USAGE_TYPE" in
    personal) kind=Personal; sensitivity=Personal ;;
    work) kind=Work; sensitivity='Work Restricted' ;;
    separate) kind=; sensitivity= ;;
  esac
  {
    printf 'Domain,Kind,Sensitivity,AI Policy,Active,Owner,Notes\n'
    tr ',' '\n' <<< "$DOMAINS" | while IFS= read -r domain; do
      csv_value "$domain"; printf ','
      csv_value "$kind"; printf ','
      csv_value "$sensitivity"; printf ',"No AI",true,"","Review the boundary before adding content"\n'
    done
  } > "$STATE_DIR/seeds/domains.csv"
  {
    printf 'Name,Domain,Type,Status,Sensitivity,AI Allowed,AI Status,Topics\n'
    tr ',' '\n' <<< "$DOMAINS" | while IFS= read -r domain; do
      csv_value "First capture — $domain"; printf ','
      csv_value "$domain"; printf ',Capture,Inbox,'
      csv_value "$sensitivity"; printf ',false,"Not Required",onboarding\n'
    done
  } > "$STATE_DIR/seeds/starter-knowledge.csv"
}

preview() {
  local preview_file
  preview_file="$(mktemp "${TMPDIR:-/tmp}/notion-second-brain-plan.XXXXXX")"
  trap 'rm -f "$preview_file"' RETURN
  write_plan "$preview_file"
  printf '\nNotion Second Brain plan — preview only\n─────────────────────────────────────────\n'
  cat "$preview_file"
  printf '\nNo files or Notion pages were changed. Add --apply to save this local plan.\n'
}

apply_plan() {
  local temp_config backup_stamp
  mkdir -p "$CONFIG_DIR" "$STATE_DIR/seeds"
  if [[ -f "$CONFIG_FILE" || -f "$PLAN_FILE" ]]; then
    backup_stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
    mkdir -p "$STATE_DIR/backups/$backup_stamp"
    [[ ! -f "$CONFIG_FILE" ]] || cp -p "$CONFIG_FILE" "$STATE_DIR/backups/$backup_stamp/config"
    [[ ! -f "$PLAN_FILE" ]] || cp -p "$PLAN_FILE" "$STATE_DIR/backups/$backup_stamp/setup-plan.md"
  fi
  temp_config="$(mktemp "$CONFIG_DIR/config.XXXXXX")"
  {
    printf 'version\t1\n'
    printf 'usage\t%s\n' "$USAGE_TYPE"
    printf 'domains\t%s\n' "$DOMAINS"
    printf 'assistants\t%s\n' "$ASSISTANTS"
    printf 'raycast\t%s\n' "$RAYCAST"
    printf 'hq_url\t%s\n' "$HQ_URL"
    printf 'capture_url\t%s\n' "$CAPTURE_URL"
  } > "$temp_config"
  chmod 600 "$temp_config"
  mv "$temp_config" "$CONFIG_FILE"
  write_plan "$PLAN_FILE"
  write_seeds
  if [[ "$RAYCAST" == yes ]]; then
    mkdir -p "$RAYCAST_DIR"
    cp -p "$ROOT/assets/raycast/"*.sh "$RAYCAST_DIR/"
    chmod 755 "$RAYCAST_DIR/"*.sh
  fi
  pass "saved configuration: $CONFIG_FILE"
  pass "saved setup plan: $PLAN_FILE"
  pass "generated import seeds: $STATE_DIR/seeds"
  if [[ "$RAYCAST" == yes ]]; then
    pass "installed Raycast commands: $RAYCAST_DIR"
    [[ -n "$HQ_URL" ]] || note 'HQ URL is blank; the open command will explain how to add it.'
    [[ -n "$CAPTURE_URL" ]] || note 'Capture URL is blank; the capture command will explain how to add it.'
  fi
}

show_saved() {
  [[ -r "$PLAN_FILE" ]] || die "no saved plan found: $PLAN_FILE"
  cat "$PLAN_FILE"
}

validate_saved() {
  [[ -r "$CONFIG_FILE" ]] || die "configuration missing: $CONFIG_FILE"
  [[ -r "$PLAN_FILE" ]] || die "setup plan missing: $PLAN_FILE"
  grep -q $'^version\t1$' "$CONFIG_FILE" || die 'unsupported or missing configuration version'
  grep -q $'^usage\t' "$CONFIG_FILE" || die 'usage choice missing'
  grep -q $'^domains\t.' "$CONFIG_FILE" || die 'domains missing'
  pass 'saved configuration and setup plan exist'
  if grep -q $'^raycast\tyes$' "$CONFIG_FILE"; then
    [[ -x "$RAYCAST_DIR/open-notion-second-brain.sh" ]] || die 'Raycast open command missing'
    [[ -x "$RAYCAST_DIR/capture-to-notion-second-brain.sh" ]] || die 'Raycast capture command missing'
    pass 'Raycast commands are installed and executable'
  fi
  pass 'local Notion Second Brain plan is valid'
}

while (($#)); do
  case "$1" in
    --guided) GUIDED=1 ;;
    --apply) APPLY=1 ;;
    --show) ACTION=show ;;
    --validate) ACTION=validate ;;
    --usage) shift; (($#)) || die '--usage needs a value'; USAGE_TYPE="$1" ;;
    --domains) shift; (($#)) || die '--domains needs a value'; DOMAINS="$1" ;;
    --assistants) shift; (($#)) || die '--assistants needs a value'; ASSISTANTS="$1" ;;
    --raycast) shift; (($#)) || die '--raycast needs a value'; RAYCAST="$1" ;;
    --hq-url) shift; (($#)) || die '--hq-url needs a value'; HQ_URL="$1" ;;
    --capture-url) shift; (($#)) || die '--capture-url needs a value'; CAPTURE_URL="$1" ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

case "$ACTION" in
  show) show_saved; exit 0 ;;
  validate) validate_saved; exit 0 ;;
esac

((GUIDED == 0)) || run_guided
validate_choices
if ((APPLY)); then apply_plan; else preview; fi
