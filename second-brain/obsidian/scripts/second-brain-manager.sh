#!/usr/bin/env bash
# Dynamic, preview-first Obsidian vault and domain manager.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DAY_ONE_PROJECT_DIR="$(cd "$PROJECT_DIR/../.." && pwd)"
source "$DAY_ONE_PROJECT_DIR/scripts/lib/project-paths.sh"
source "$DAY_ONE_PROJECT_DIR/scripts/lib/application-ownership.sh"
ASSETS="$PROJECT_DIR/assets"
DEFAULT_CONFIG_DIR="$HOME/.config/second-brain"
LEGACY_CONFIG_DIR="$HOME/.config/fresh-start-second-brain"
CONFIG_DIR="${SECOND_BRAIN_CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"
MANIFEST="${SECOND_BRAIN_LAYOUT:-$CONFIG_DIR/layout.tsv}"
STATE_DIR="${SECOND_BRAIN_STATE:-$HOME/.local/state/second-brain}"
DAY_ONE_STATE_DIR="$(day_one_state_dir "$(day_one_state_root)")"
DAY_ONE_INSTALL_MANIFEST="$DAY_ONE_STATE_DIR/install-manifest.tsv"
DAY_ONE_APPLICATION_TSV="$DAY_ONE_STATE_DIR/application-provenance.tsv"
DAY_ONE_APPLICATION_REPORT="$DAY_ONE_STATE_DIR/application-provenance.md"
USER_BIN="$HOME/.local/bin"
RAYCAST_DIR="$HOME/.local/share/second-brain/raycast"
LEGACY_RAYCAST_DIR="$HOME/.local/share/fresh-start-second-brain/raycast"

# Read an existing pre-rename manifest without writing during preview. The next
# confirmed layout apply saves it under ~/.config/second-brain and archives the
# known legacy control files into the normal recovery backup.
CURRENT_MANIFEST="$MANIFEST"
if [[ -z "${SECOND_BRAIN_CONFIG_DIR:-}" && -z "${SECOND_BRAIN_LAYOUT:-}" \
   && ! -r "$MANIFEST" && -r "$LEGACY_CONFIG_DIR/layout.tsv" ]]; then
  CURRENT_MANIFEST="$LEGACY_CONFIG_DIR/layout.tsv"
fi

ACTION=""
PRESET=""
ROOT_PATH="$HOME/Vaults"
SINGLE_VAULT_PATH="$HOME/Vaults/Second Brain"
TOOLS_INPUT="raycast,claude,codex"
LAYOUT_INPUT=""
APPLY=0
ASSUME_YES=0
INSTALL_APPS=0
APP_INSTALL_POLICY=""
RECONFIGURE=0
FAILURES=0
WARNINGS=0
REASONS="organisation"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/second-brain-manager.XXXXXX")"
CANDIDATE="$TMP_DIR/layout.tsv"
REPORT="$TMP_DIR/layout-report.md"
CHANGE_REPORT="$TMP_DIR/reconfiguration-report.md"
trap 'rm -rf "$TMP_DIR"' EXIT

info() { printf '  · %s\n' "$*"; }
pass() { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ⚠ %s\n' "$*" >&2; WARNINGS=$((WARNINGS + 1)); }
fail() { printf '  ✗ %s\n' "$*" >&2; FAILURES=$((FAILURES + 1)); }
die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }

usage() {
  printf '%s\n' \
    'Usage: ./scripts/second-brain-manager.sh ACTION [options]' \
    '' \
    'Actions:' \
    '  --guided                 ask why, which vaults, domains, folders, and tools' \
    '  --reconfigure            rebuild a reviewed candidate from an existing layout' \
    '  --preset NAME            build unified, multi-domain, or work-personal' \
    '  --layout FILE            preview/apply a hand-edited layout manifest' \
    '  --show                   print the currently saved layout report' \
    '  --validate               validate the manifest and installed vault structure' \
    '  --refresh-integrations   regenerate launchers from the saved manifest' \
    '' \
    'Options:' \
    '  --root ABSOLUTE_PATH     parent used by presets (default: ~/Vaults)' \
    '  --single-vault PATH      exact path for the unified preset' \
    '  --tools CSV              none, raycast, claude, codex, or a comma list' \
    '  --apply                  perform the reviewed plan; preview is the default' \
    '  --install-apps           with --apply, resolve selected missing applications' \
    '  --app-install-policy MODE  prompt, homebrew, or check-only' \
    '  --yes                    skip the typed APPLY LAYOUT confirmation' \
    '  --help                   show this help' \
    '' \
    'Reconfiguration never deletes notes or silently moves a domain between vaults.'
}

set_action() {
  [[ -z "$ACTION" || "$ACTION" == "$1" ]] || die "choose only one action (already selected: $ACTION)"
  ACTION="$1"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --guided) set_action guided; shift ;;
    --reconfigure) set_action guided; RECONFIGURE=1; shift ;;
    --preset)
      [[ "$#" -ge 2 ]] || die '--preset needs unified, multi-domain, or work-personal'
      set_action build
      case "$2" in
        three-domain) PRESET=multi-domain ;; # compatibility with the former name
        *) PRESET="$2" ;;
      esac
      shift 2
      ;;
    --layout)
      [[ "$#" -ge 2 ]] || die '--layout needs a file'
      set_action build
      LAYOUT_INPUT="$2"
      shift 2
      ;;
    --show) set_action show; shift ;;
    --validate) set_action validate; shift ;;
    --refresh-integrations) set_action refresh; shift ;;
    --root)
      [[ "$#" -ge 2 ]] || die '--root needs an absolute path'
      ROOT_PATH="$2"
      shift 2
      ;;
    --single-vault)
      [[ "$#" -ge 2 ]] || die '--single-vault needs an absolute path'
      SINGLE_VAULT_PATH="$2"
      shift 2
      ;;
    --tools)
      [[ "$#" -ge 2 ]] || die '--tools needs a value'
      TOOLS_INPUT="$2"
      shift 2
      ;;
    --apply) APPLY=1; shift ;;
    --install-apps) INSTALL_APPS=1; shift ;;
    --app-install-policy)
      [[ "$#" -ge 2 ]] || die '--app-install-policy needs prompt, homebrew, or check-only'
      APP_INSTALL_POLICY="$2"
      shift 2
      ;;
    --yes) ASSUME_YES=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

if [[ -z "$APP_INSTALL_POLICY" ]]; then
  if [[ -t 0 ]]; then APP_INSTALL_POLICY=prompt
  else APP_INSTALL_POLICY=check-only
  fi
fi
[[ "$APP_INSTALL_POLICY" =~ ^(prompt|homebrew|check-only)$ ]] \
  || die '--app-install-policy must be prompt, homebrew, or check-only'

if [[ -z "$ACTION" ]]; then
  if [[ -t 0 ]]; then ACTION=guided
  else usage >&2; exit 2
  fi
fi

expand_home_path() {
  case "$1" in
    '~') printf '%s' "$HOME" ;;
    '~/'*) printf '%s/%s' "$HOME" "${1#\~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}
ROOT_PATH="$(expand_home_path "$ROOT_PATH")"
SINGLE_VAULT_PATH="$(expand_home_path "$SINGLE_VAULT_PATH")"

contains_csv() { case ",$1," in *",$2,"*) return 0 ;; *) return 1 ;; esac; }

normalize_tools() {
  raw="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  case "$raw" in
    all) printf 'claude,codex,raycast'; return ;;
    both) printf 'claude,raycast'; return ;;
    raycast-codex) printf 'codex,raycast'; return ;;
    claude-codex) printf 'claude,codex'; return ;;
    none|'') printf 'none'; return ;;
  esac
  output=""
  old_ifs="$IFS"
  IFS=','
  for tool in $raw; do
    case "$tool" in raycast|claude|codex) ;; *) die "unsupported tool: $tool" ;; esac
    contains_csv "$output" "$tool" || output="${output}${output:+,}$tool"
  done
  IFS="$old_ifs"
  [[ -n "$output" ]] || output=none
  printf '%s\n' "$output" | tr ',' '\n' | LC_ALL=C sort | paste -sd, -
}
TOOLS_INPUT="$(normalize_tools "$TOOLS_INPUT")"

slugify() {
  value="$(printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
  printf '%s' "$value"
}

safe_text() {
  [[ -n "$1" ]] || return 1
  case "$1" in *$'\t'*|*$'\n'*|*$'\r'*|*'|'*) return 1 ;; esac
}

safe_relative() {
  value="$1"
  [[ "$value" == . ]] && return 0
  safe_text "$value" || return 1
  # Reject absolute paths, dotted paths, traversal, doubled slashes and
  # backslashes. `.*` already subsumes `../*` and some siblings, so ShellCheck
  # reports the list as redundant. The overlap is deliberate: every branch
  # rejects, and spelling each case out keeps the rule readable and makes it
  # harder to open a gap while editing. Do not "simplify" this list.
  # shellcheck disable=SC2221,SC2222
  case "$value" in /*|.*|*/../*|../*|*/..|*//*|*\\*) return 1 ;; esac
  return 0
}

safe_vault_path() {
  value="${1%/}"
  [[ "$value" == /* && "$value" != / && "$value" != "$HOME" ]] || return 1
  case "$value" in *$'\t'*|*$'\n'*|*$'\r'*|*'/../'*|*'/..'|*'/./'*) return 1 ;; esac
  case "$value/" in "$HOME/Developer/"*) return 1 ;; esac
  return 0
}

# In-memory candidate records. All arrays use the same index within a record type.
V_SLUGS=(); V_NAMES=(); V_PATHS=(); V_SENS=(); V_TOOLS=(); V_DASH=()
D_SLUGS=(); D_NAMES=(); D_VAULTS=(); D_FOLDERS=(); D_ARCH=(); D_SENS=(); D_AI=(); D_SUBS=()

reset_records() {
  V_SLUGS=(); V_NAMES=(); V_PATHS=(); V_SENS=(); V_TOOLS=(); V_DASH=()
  D_SLUGS=(); D_NAMES=(); D_VAULTS=(); D_FOLDERS=(); D_ARCH=(); D_SENS=(); D_AI=(); D_SUBS=()
}

add_vault() {
  V_SLUGS[${#V_SLUGS[@]}]="$1"
  V_NAMES[${#V_NAMES[@]}]="$2"
  V_PATHS[${#V_PATHS[@]}]="$3"
  V_SENS[${#V_SENS[@]}]="$4"
  V_TOOLS[${#V_TOOLS[@]}]="$5"
  V_DASH[${#V_DASH[@]}]="$6"
}

add_domain() {
  D_SLUGS[${#D_SLUGS[@]}]="$1"
  D_NAMES[${#D_NAMES[@]}]="$2"
  D_VAULTS[${#D_VAULTS[@]}]="$3"
  D_FOLDERS[${#D_FOLDERS[@]}]="$4"
  D_ARCH[${#D_ARCH[@]}]="$5"
  D_SENS[${#D_SENS[@]}]="$6"
  D_AI[${#D_AI[@]}]="$7"
  D_SUBS[${#D_SUBS[@]}]="$8"
}

archetype_subfolders() {
  case "$1" in
    development) printf 'Projects,Learning,Reference,Sources' ;;
    content) printf 'Ideas,Research,Drafts,Scheduled,Published,Sources' ;;
    research) printf 'Topics,Sources,Notes,Syntheses' ;;
    projects) printf 'Active,Waiting,Completed,Archive' ;;
    minimal) printf 'Notes,Sources' ;;
    *) printf '%s' "$2" ;;
  esac
}

add_standard_domains() {
  vault_dev="$1"; vault_software="$2"; vault_tech="$3"
  folder_dev="$4"; folder_software="$5"; folder_tech="$6"
  sens_dev="$7"; sens_other="$8"
  add_domain development 'Software Development' "$vault_dev" "$folder_dev" development "$sens_dev" false 'Projects,Learning,Reference,Sources'
  add_domain software-content 'Software Content' "$vault_software" "$folder_software" content "$sens_other" false 'Ideas,Research,Drafts,Scheduled,Published,Sources'
  add_domain tech-content 'Tech Content' "$vault_tech" "$folder_tech" content "$sens_other" false 'Ideas,Research,Drafts,Scheduled,Published,Sources'
}

build_preset() {
  reset_records
  case "$PRESET" in
    unified)
      single="${SINGLE_VAULT_PATH%/}"
      add_vault "$(slugify "$(basename "$single")")" "$(basename "$single")" "$single" personal "$TOOLS_INPUT" '01 Dashboards'
      add_standard_domains "${V_SLUGS[0]}" "${V_SLUGS[0]}" "${V_SLUGS[0]}" \
        '10 Software Development' '20 Software Content' '30 Tech Content' personal personal
      ;;
    multi-domain)
      root="${ROOT_PATH%/}"
      add_vault development 'Software Development' "$root/Software Development" personal "$TOOLS_INPUT" '01 Dashboard'
      add_vault software-content 'Software Content' "$root/Software Content" personal "$TOOLS_INPUT" '01 Dashboard'
      add_vault tech-content 'Tech Content' "$root/Tech Content" personal "$TOOLS_INPUT" '01 Dashboard'
      add_standard_domains development software-content tech-content . . . personal personal
      ;;
    work-personal)
      root="${ROOT_PATH%/}"
      add_vault work-knowledge 'Work Knowledge' "$root/Work Knowledge" work-confidential "$TOOLS_INPUT" '01 Dashboards'
      add_vault personal-knowledge 'Personal Knowledge' "$root/Personal Knowledge" personal "$TOOLS_INPUT" '01 Dashboards'
      add_standard_domains work-knowledge personal-knowledge personal-knowledge \
        . '10 Software Content' '20 Tech Content' work-confidential personal
      ;;
    *) die "unsupported preset: $PRESET" ;;
  esac
}

write_candidate() {
  target="$1"
  {
    printf '# Second Brain layout v1\n'
    printf '# record fields are tab-delimited; do not use tabs or newlines in values\n'
    printf 'meta\tschema\t1\n'
    printf 'meta\tpreset\t%s\n' "${PRESET:-custom}"
    printf 'meta\treasons\t%s\n' "${REASONS:-not-recorded}"
    for ((i=0; i<${#V_SLUGS[@]}; i++)); do
      printf 'vault\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${V_SLUGS[$i]}" "${V_NAMES[$i]}" "${V_PATHS[$i]}" \
        "${V_SENS[$i]}" "${V_TOOLS[$i]}" "${V_DASH[$i]}"
    done
    for ((i=0; i<${#D_SLUGS[@]}; i++)); do
      printf 'domain\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${D_SLUGS[$i]}" "${D_NAMES[$i]}" "${D_VAULTS[$i]}" \
        "${D_FOLDERS[$i]}" "${D_ARCH[$i]}" "${D_SENS[$i]}" \
        "${D_AI[$i]}" "${D_SUBS[$i]}"
    done
  } > "$target"
}

validate_manifest() {
  file="$1"
  local_fail=0
  [[ -r "$file" ]] || { fail "layout is not readable: $file"; return 1; }
  if ! awk -F '\t' '
    /^#/ || NF==0 {next}
    $1=="meta" && NF==3 {next}
    $1=="vault" && NF==7 {next}
    $1=="domain" && NF==9 {next}
    {exit 1}
  ' "$file"; then
    fail 'layout contains an unknown record or incorrect number of tab-separated fields'
    local_fail=1
  fi

  seen_vault_slugs="$TMP_DIR/seen-vault-slugs"
  seen_vault_names="$TMP_DIR/seen-vault-names"
  seen_vault_paths="$TMP_DIR/seen-vault-paths"
  seen_domain_slugs="$TMP_DIR/seen-domain-slugs"
  seen_domain_locations="$TMP_DIR/seen-domain-locations"
  seen_domain_templates="$TMP_DIR/seen-domain-templates"
  : > "$seen_vault_slugs"; : > "$seen_vault_names"; : > "$seen_vault_paths"; : > "$seen_domain_slugs"
  : > "$seen_domain_locations"; : > "$seen_domain_templates"
  vault_count=0; domain_count=0; schema_ok=0

  while IFS=$'\t' read -r kind a b c d e f g h; do
    case "$kind" in
      ''|'#'*) continue ;;
      meta)
        [[ "$a" == schema && "$b" == 1 ]] && schema_ok=1
        ;;
      vault)
        slug="$a"; name="$b"; path="$c"; sensitivity="$d"; tools="$e"; dashboard="$f"
        vault_count=$((vault_count + 1))
        [[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { fail "invalid vault slug: $slug"; local_fail=1; }
        safe_text "$name" && [[ "$name" != */* && "$name" == "$(basename "$path")" ]] \
          || { fail "vault name must be safe and match its path basename: $name"; local_fail=1; }
        safe_vault_path "$path" || { fail "unsafe vault path: $path"; local_fail=1; }
        case "$sensitivity" in public|personal|work-confidential) ;; *) fail "invalid vault sensitivity: $sensitivity"; local_fail=1 ;; esac
        normalized="$(normalize_tools "$tools")"
        [[ "$normalized" == "$tools" ]] || { fail "tools must be normalized as '$normalized' for vault $slug"; local_fail=1; }
        safe_relative "$dashboard" && [[ "$dashboard" != . && "$dashboard" != */* ]] \
          || { fail "dashboard folder must be one safe folder name: $dashboard"; local_fail=1; }
        if grep -Fqxi "$slug" "$seen_vault_slugs"; then fail "duplicate vault slug: $slug"; local_fail=1; fi
        if grep -Fqxi "$name" "$seen_vault_names"; then fail "duplicate vault name: $name"; local_fail=1; fi
        if grep -Fqxi "$path" "$seen_vault_paths"; then fail "duplicate vault path: $path"; local_fail=1; fi
        printf '%s\n' "$slug" >> "$seen_vault_slugs"
        printf '%s\n' "$name" >> "$seen_vault_names"
        printf '%s\n' "$path" >> "$seen_vault_paths"
        ;;
      domain)
        slug="$a"; name="$b"; vault_slug="$c"; folder="$d"; archetype="$e"; sensitivity="$f"; ai="$g"; subfolders="$h"
        domain_count=$((domain_count + 1))
        [[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { fail "invalid domain slug: $slug"; local_fail=1; }
        safe_text "$name" && [[ "$name" != */* ]] || { fail "unsafe domain name: $name"; local_fail=1; }
        safe_relative "$folder" || { fail "unsafe domain folder: $folder"; local_fail=1; }
        case "$archetype" in development|content|research|projects|minimal|custom) ;; *) fail "invalid archetype: $archetype"; local_fail=1 ;; esac
        case "$sensitivity" in public|personal|work-confidential) ;; *) fail "invalid domain sensitivity: $sensitivity"; local_fail=1 ;; esac
        case "$ai" in true|false) ;; *) fail "ai_allowed must be true or false for $slug"; local_fail=1 ;; esac
        [[ -n "$subfolders" ]] || { fail "domain must have at least one subfolder: $slug"; local_fail=1; }
        old_ifs="$IFS"; IFS=','
        for subfolder in $subfolders; do
          safe_relative "$subfolder" && [[ "$subfolder" != . ]] || { fail "unsafe subfolder '$subfolder' in $slug"; local_fail=1; }
        done
        IFS="$old_ifs"
        if grep -Fqxi "$slug" "$seen_domain_slugs"; then fail "duplicate domain slug: $slug"; local_fail=1; fi
        location_key="$vault_slug|$folder"
        template_key="$vault_slug|$name"
        if grep -Fqxi "$location_key" "$seen_domain_locations"; then fail "two domains share the same physical root: $location_key"; local_fail=1; fi
        if grep -Fqxi "$template_key" "$seen_domain_templates"; then fail "two domains would share one template name: $template_key"; local_fail=1; fi
        printf '%s\n' "$slug" >> "$seen_domain_slugs"
        printf '%s\n' "$location_key" >> "$seen_domain_locations"
        printf '%s\n' "$template_key" >> "$seen_domain_templates"
        ;;
      *) ;;
    esac
  done < "$file"

  [[ "$schema_ok" == 1 ]] || { fail 'layout schema marker is missing or unsupported'; local_fail=1; }
  [[ "$vault_count" -gt 0 ]] || { fail 'layout has no vault records'; local_fail=1; }
  [[ "$domain_count" -gt 0 ]] || { fail 'layout has no domain records'; local_fail=1; }

  while IFS=$'\t' read -r kind slug name vault_slug folder archetype sensitivity ai subfolders; do
    [[ "$kind" == domain ]] || continue
    if ! grep -Fqxi "$vault_slug" "$seen_vault_slugs"; then
      fail "domain $slug references missing vault: $vault_slug"
      local_fail=1
      continue
    fi
    dashboard="$(awk -F '\t' -v wanted="$vault_slug" '$1=="vault" && $2==wanted {print $7; exit}' "$file")"
    if [[ "$folder" != . ]]; then
      case "$folder" in '00 Inbox'|'80 Attachments'|'90 System'|'99 Templates'|"$dashboard")
        fail "domain $slug uses reserved vault folder: $folder"; local_fail=1 ;;
      esac
    else
      old_ifs="$IFS"; IFS=','
      for subfolder in $subfolders; do
        case "$subfolder" in '00 Inbox'|'80 Attachments'|'90 System'|'99 Templates'|"$dashboard")
          fail "root-level domain $slug uses reserved vault folder: $subfolder"; local_fail=1 ;;
        esac
      done
      IFS="$old_ifs"
    fi
  done < "$file"

  while IFS= read -r vault_slug; do
    domain_total="$(awk -F '\t' -v wanted="$vault_slug" '$1=="domain" && $4==wanted {count++} END {print count+0}' "$file")"
    [[ "$domain_total" -gt 0 ]] || { fail "vault has no assigned domain: $vault_slug"; local_fail=1; }
  done < "$seen_vault_slugs"

  while IFS= read -r left; do
    while IFS= read -r right; do
      [[ "$left" == "$right" ]] && continue
      case "$left/" in "$right/"*) fail "nested vault paths are not allowed: $left inside $right"; local_fail=1 ;; esac
    done < "$seen_vault_paths"
  done < "$seen_vault_paths"

  [[ "$local_fail" == 0 ]]
}

render_report() {
  file="$1"; destination="$2"
  preset="$(awk -F '\t' '$1=="meta" && $2=="preset" {print $3; exit}' "$file")"
  reasons="$(awk -F '\t' '$1=="meta" && $2=="reasons" {print $3; exit}' "$file")"
  {
    printf '# Second Brain layout\n\n'
    printf 'Generated from the reviewed manifest. Paths and policy choices are the source of truth.\n\n'
    printf -- '- **Preset:** `%s`\n' "${preset:-custom}"
    printf -- '- **Reasons:** %s\n\n' "${reasons:-not recorded}"
    printf '## Vaults\n\n'
    printf '| Vault | Slug | Path | Sensitivity | Integrations | Dashboard |\n'
    printf '|---|---|---|---|---|---|\n'
    while IFS=$'\t' read -r kind slug name path sensitivity tools dashboard; do
      [[ "$kind" == vault ]] || continue
      printf '| %s | `%s` | `%s` | %s | %s | `%s` |\n' "$name" "$slug" "$path" "$sensitivity" "$tools" "$dashboard"
    done < "$file"
    printf '\n## Domains\n\n'
    printf '| Domain | Slug | Vault | Folder | Archetype | Sensitivity | AI allowed | Folders |\n'
    printf '|---|---|---|---|---|---|:---:|---|\n'
    while IFS=$'\t' read -r kind slug name vault_slug folder archetype sensitivity ai subfolders; do
      [[ "$kind" == domain ]] || continue
      vault_name="$(awk -F '\t' -v wanted="$vault_slug" '$1=="vault" && $2==wanted {print $3; exit}' "$file")"
      printf '| %s | `%s` | %s | `%s` | %s | %s | %s | %s |\n' \
        "$name" "$slug" "$vault_name" "$folder" "$archetype" "$sensitivity" "$ai" "$subfolders"
    done < "$file"
    printf '\n## Safety behaviour\n\n'
    printf -- '- Existing notes are never deleted.\n'
    printf -- '- A domain path change is blocked as a migration.\n'
    printf -- '- Removed records become retained but unmanaged; their files stay in place.\n'
    printf -- '- Unrecognised existing dashboard/system files receive a proposed sibling instead of being overwritten.\n'
  } > "$destination"
}

show_layout() {
  [[ -r "$CURRENT_MANIFEST" ]] || die "no saved layout: $MANIFEST"
  validate_manifest "$CURRENT_MANIFEST" || exit 1
  render_report "$CURRENT_MANIFEST" "$REPORT"
  cat "$REPORT"
}

MENU_VALUES=(); MENU_LABELS=(); MENU_SELECTED=(); MENU_RESULT=""
select_toggles() {
  heading="$1"
  [[ -t 0 && -t 1 ]] || die "$heading requires an interactive terminal"
  cursor=0
  while true; do
    printf '\033[2J\033[H'
    printf '%s\n\n' "$heading"
    printf '  Up/Down or j/k: move   Space: toggle   a: all   n: none   Enter: accept   q: cancel\n\n'
    for ((menu_i=0; menu_i<${#MENU_VALUES[@]}; menu_i++)); do
      marker=' '
      [[ "$menu_i" == "$cursor" ]] && marker='>'
      check='[ ]'
      [[ "${MENU_SELECTED[$menu_i]}" == 1 ]] && check='[x]'
      printf ' %s %s %s\n' "$marker" "$check" "${MENU_LABELS[$menu_i]}"
    done
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then
      IFS= read -rsn2 rest || true
      key="$key$rest"
    fi
    case "$key" in
      $'\033[A'|k|K) cursor=$((cursor - 1)); [[ "$cursor" -ge 0 ]] || cursor=$((${#MENU_VALUES[@]} - 1)) ;;
      $'\033[B'|j|J) cursor=$((cursor + 1)); [[ "$cursor" -lt "${#MENU_VALUES[@]}" ]] || cursor=0 ;;
      ' ') if [[ "${MENU_SELECTED[$cursor]}" == 1 ]]; then MENU_SELECTED[$cursor]=0; else MENU_SELECTED[$cursor]=1; fi ;;
      a|A) for ((menu_i=0; menu_i<${#MENU_VALUES[@]}; menu_i++)); do MENU_SELECTED[$menu_i]=1; done ;;
      n|N) for ((menu_i=0; menu_i<${#MENU_VALUES[@]}; menu_i++)); do MENU_SELECTED[$menu_i]=0; done ;;
      q|Q) die 'selection cancelled' ;;
      '') break ;;
    esac
  done
  MENU_RESULT=""
  for ((menu_i=0; menu_i<${#MENU_VALUES[@]}; menu_i++)); do
    [[ "${MENU_SELECTED[$menu_i]}" == 1 ]] || continue
    MENU_RESULT="${MENU_RESULT}${MENU_RESULT:+,}${MENU_VALUES[$menu_i]}"
  done
  printf '\033[2J\033[H'
}

prompt_value() {
  label="$1"; default="$2"
  printf '%s [%s]: ' "$label" "$default"
  IFS= read -r answer
  PROMPT_RESULT="${answer:-$default}"
}

prompt_yes_no() {
  label="$1"; default="$2"
  if [[ "$default" == y ]]; then suffix='[Y/n]'; else suffix='[y/N]'; fi
  printf '%s %s: ' "$label" "$suffix"
  IFS= read -r answer
  answer="$(printf '%s' "${answer:-$default}" | tr '[:upper:]' '[:lower:]')"
  case "$answer" in y|yes) PROMPT_BOOL=1 ;; *) PROMPT_BOOL=0 ;; esac
}

choose_one() {
  heading="$1"; default="$2"; shift 2
  printf '%s\n' "$heading"
  choice_count="$#"; choice_i=1
  for label in "$@"; do printf '  %s) %s\n' "$choice_i" "$label"; choice_i=$((choice_i + 1)); done
  printf 'Selection [%s]: ' "$default"
  IFS= read -r answer
  answer="${answer:-$default}"
  case "$answer" in ''|*[!0-9]*) die 'invalid numeric selection' ;; esac
  [[ "$answer" -ge 1 && "$answer" -le "$choice_count" ]] || die 'selection is out of range'
  CHOICE_INDEX=$((answer - 1))
}

domain_defaults() {
  case "$1" in
    development) DEF_NAME='Software Development'; DEF_ARCH=development ;;
    software-content) DEF_NAME='Software Content'; DEF_ARCH=content ;;
    tech-content) DEF_NAME='Tech Content'; DEF_ARCH=content ;;
    personal-learning) DEF_NAME='Personal Learning'; DEF_ARCH=research ;;
    projects) DEF_NAME='Projects'; DEF_ARCH=projects ;;
    research-library) DEF_NAME='Research Library'; DEF_ARCH=research ;;
    *) DEF_NAME="$2"; DEF_ARCH=minimal ;;
  esac
  DEF_SUBS="$(archetype_subfolders "$DEF_ARCH" '')"
}

guided_build() {
  [[ -t 0 && -t 1 ]] || die 'guided setup requires an interactive terminal'
  if [[ "$RECONFIGURE" == 1 && -r "$CURRENT_MANIFEST" ]]; then
    printf '\nCurrent saved layout\n────────────────────\n'
    render_report "$CURRENT_MANIFEST" "$REPORT"
    sed -n '1,80p' "$REPORT"
    printf '\nReconfiguration builds a complete replacement candidate. Existing notes remain in place.\n'
    prompt_yes_no 'Continue to the layout wizard?' y
    [[ "$PROMPT_BOOL" == 1 ]] || die 'reconfiguration cancelled'
  fi

  MENU_VALUES=(organisation work-personal sync-boundary ai-boundary)
  MENU_LABELS=('Categories only — organise notes without separating access' 'Separate work and personal information' 'Different sync accounts or providers' 'Different AI accounts or access rules')
  MENU_SELECTED=(1 0 0 0)
  select_toggles 'Why might you need separate physical vaults?'
  REASONS="${MENU_RESULT:-not-recorded}"
  boundary=0
  for reason in work-personal sync-boundary ai-boundary; do contains_csv "$REASONS" "$reason" && boundary=1; done
  if [[ "$boundary" == 1 ]]; then
    printf 'Recommendation: use separate physical vaults because at least one access or account boundary is selected.\n\n'
    default_layout=3
  else
    printf 'Recommendation: use one vault with domains; organisation alone does not require physical separation.\n\n'
    default_layout=1
  fi
  choose_one 'Choose a starting layout:' "$default_layout" \
    'One unified vault' 'Separate vault for each selected domain' 'Work + Personal vaults' 'Custom vault layout'
  case "$CHOICE_INDEX" in 0) PRESET=unified ;; 1) PRESET=multi-domain ;; 2) PRESET=work-personal ;; 3) PRESET=custom ;; esac

  MENU_VALUES=(development software-content tech-content personal-learning projects research-library)
  MENU_LABELS=('Software Development' 'Software Content' 'Tech Content' 'Personal Learning' 'Projects' 'Research Library')
  MENU_SELECTED=(1 1 1 0 0 0)
  select_toggles 'Select the knowledge domains to create:'
  [[ -n "$MENU_RESULT" ]] || die 'select at least one domain'
  selected_domain_csv="$MENU_RESULT"

  S_SLUGS=(); S_NAMES=(); S_ARCH=(); S_SUBS=()
  old_ifs="$IFS"; IFS=','
  for selected_slug in $selected_domain_csv; do
    domain_defaults "$selected_slug" ''
    S_SLUGS[${#S_SLUGS[@]}]="$selected_slug"
    S_NAMES[${#S_NAMES[@]}]="$DEF_NAME"
    S_ARCH[${#S_ARCH[@]}]="$DEF_ARCH"
    S_SUBS[${#S_SUBS[@]}]="$DEF_SUBS"
  done
  IFS="$old_ifs"

  while true; do
    prompt_yes_no 'Add a custom domain?' n
    [[ "$PROMPT_BOOL" == 1 ]] || break
    prompt_value 'Custom domain display name' 'My Knowledge'
    custom_name="$PROMPT_RESULT"
    safe_text "$custom_name" && [[ "$custom_name" != */* ]] || die 'custom domain name contains an unsafe character'
    prompt_value 'Stable domain slug' "$(slugify "$custom_name")"
    custom_slug="$PROMPT_RESULT"
    [[ "$custom_slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die 'domain slug must use lower-case letters, numbers, and single hyphens'
    for existing in "${S_SLUGS[@]}"; do [[ "$existing" != "$custom_slug" ]] || die "duplicate domain slug: $custom_slug"; done
    choose_one 'Choose the domain folder archetype:' 5 Development Content Research Projects Minimal Custom
    case "$CHOICE_INDEX" in
      0) custom_arch=development ;; 1) custom_arch=content ;; 2) custom_arch=research ;;
      3) custom_arch=projects ;; 4) custom_arch=minimal ;; 5) custom_arch=custom ;;
    esac
    if [[ "$custom_arch" == custom ]]; then
      prompt_value 'Comma-separated folders' 'Notes,Sources'
      custom_subs="$PROMPT_RESULT"
    else
      custom_subs="$(archetype_subfolders "$custom_arch" '')"
    fi
    S_SLUGS[${#S_SLUGS[@]}]="$custom_slug"
    S_NAMES[${#S_NAMES[@]}]="$custom_name"
    S_ARCH[${#S_ARCH[@]}]="$custom_arch"
    S_SUBS[${#S_SUBS[@]}]="$custom_subs"
  done

  prompt_value 'Parent folder for generated vaults' "$ROOT_PATH"
  ROOT_PATH="$(expand_home_path "$PROMPT_RESULT")"
  safe_vault_path "$ROOT_PATH/Placeholder" || die "unsafe vault parent: $ROOT_PATH"

  MENU_VALUES=(raycast claude codex)
  MENU_LABELS=('Raycast capture and retrieval' 'Claude Code' 'OpenAI Codex')
  MENU_SELECTED=(1 0 1)
  select_toggles 'Select integrations to make available:'
  TOOLS_INPUT="$(normalize_tools "${MENU_RESULT:-none}")"

  reset_records
  ASSIGNED=()
  case "$PRESET" in
    unified)
      prompt_value 'Unified vault name' 'Second Brain'
      vault_name="$PROMPT_RESULT"; vault_slug="$(slugify "$vault_name")"
      add_vault "$vault_slug" "$vault_name" "$ROOT_PATH/$vault_name" personal "$TOOLS_INPUT" '01 Dashboards'
      for ((i=0; i<${#S_SLUGS[@]}; i++)); do ASSIGNED[$i]="$vault_slug"; done
      ;;
    multi-domain)
      for ((i=0; i<${#S_SLUGS[@]}; i++)); do
        add_vault "${S_SLUGS[$i]}" "${S_NAMES[$i]}" "$ROOT_PATH/${S_NAMES[$i]}" personal "$TOOLS_INPUT" '01 Dashboard'
        ASSIGNED[$i]="${S_SLUGS[$i]}"
      done
      ;;
    work-personal)
      add_vault work-knowledge 'Work Knowledge' "$ROOT_PATH/Work Knowledge" work-confidential "$TOOLS_INPUT" '01 Dashboards'
      add_vault personal-knowledge 'Personal Knowledge' "$ROOT_PATH/Personal Knowledge" personal "$TOOLS_INPUT" '01 Dashboards'
      MENU_VALUES=(); MENU_LABELS=(); MENU_SELECTED=()
      for ((i=0; i<${#S_SLUGS[@]}; i++)); do
        MENU_VALUES[$i]="${S_SLUGS[$i]}"; MENU_LABELS[$i]="${S_NAMES[$i]}"
        if [[ "${S_SLUGS[$i]}" == development ]]; then MENU_SELECTED[$i]=1; else MENU_SELECTED[$i]=0; fi
      done
      select_toggles 'Which selected domains belong in the Work vault?'
      work_csv="$MENU_RESULT"
      for ((i=0; i<${#S_SLUGS[@]}; i++)); do
        if contains_csv "$work_csv" "${S_SLUGS[$i]}"; then ASSIGNED[$i]=work-knowledge; else ASSIGNED[$i]=personal-knowledge; fi
      done
      ;;
    custom)
      prompt_value 'Number of physical vaults' '2'
      vault_count="$PROMPT_RESULT"
      case "$vault_count" in ''|*[!0-9]*) die 'vault count must be a number' ;; esac
      [[ "$vault_count" -ge 1 && "$vault_count" -le 20 ]] || die 'vault count must be between 1 and 20'
      for ((i=0; i<vault_count; i++)); do
        prompt_value "Vault $((i + 1)) display name" "Knowledge $((i + 1))"
        vault_name="$PROMPT_RESULT"; vault_slug="$(slugify "$vault_name")"
        for existing in "${V_SLUGS[@]}"; do [[ "$existing" != "$vault_slug" ]] || die "duplicate vault slug: $vault_slug"; done
        choose_one "Default sensitivity for $vault_name:" 2 Public Personal 'Work confidential'
        case "$CHOICE_INDEX" in 0) vault_sens=public ;; 1) vault_sens=personal ;; 2) vault_sens=work-confidential ;; esac
        add_vault "$vault_slug" "$vault_name" "$ROOT_PATH/$vault_name" "$vault_sens" "$TOOLS_INPUT" '01 Dashboards'
      done
      for ((i=0; i<${#S_SLUGS[@]}; i++)); do
        printf 'Assign domain "%s" to a vault:\n' "${S_NAMES[$i]}"
        for ((v=0; v<${#V_NAMES[@]}; v++)); do printf '  %s) %s\n' "$((v + 1))" "${V_NAMES[$v]}"; done
        printf 'Selection [1]: '; IFS= read -r answer; answer="${answer:-1}"
        case "$answer" in ''|*[!0-9]*) die 'invalid vault selection' ;; esac
        v=$((answer - 1)); [[ "$v" -ge 0 && "$v" -lt "${#V_NAMES[@]}" ]] || die 'vault selection is out of range'
        ASSIGNED[$i]="${V_SLUGS[$v]}"
      done
      ;;
  esac

  prompt_yes_no 'Use the same integrations in every vault?' y
  if [[ "$PROMPT_BOOL" != 1 ]]; then
    for ((v=0; v<${#V_NAMES[@]}; v++)); do
      MENU_VALUES=(raycast claude codex); MENU_LABELS=('Raycast' 'Claude Code' 'OpenAI Codex'); MENU_SELECTED=(0 0 0)
      contains_csv "${V_TOOLS[$v]}" raycast && MENU_SELECTED[0]=1
      contains_csv "${V_TOOLS[$v]}" claude && MENU_SELECTED[1]=1
      contains_csv "${V_TOOLS[$v]}" codex && MENU_SELECTED[2]=1
      select_toggles "Integrations allowed for ${V_NAMES[$v]}:"
      V_TOOLS[$v]="$(normalize_tools "${MENU_RESULT:-none}")"
    done
  fi

  prompt_yes_no 'Use the recommended folder archetype for every selected domain?' y
  if [[ "$PROMPT_BOOL" != 1 ]]; then
    for ((i=0; i<${#S_NAMES[@]}; i++)); do
      choose_one "Folder archetype for ${S_NAMES[$i]}:" 5 Development Content Research Projects Minimal Custom
      case "$CHOICE_INDEX" in
        0) S_ARCH[$i]=development ;; 1) S_ARCH[$i]=content ;; 2) S_ARCH[$i]=research ;;
        3) S_ARCH[$i]=projects ;; 4) S_ARCH[$i]=minimal ;; 5) S_ARCH[$i]=custom ;;
      esac
      if [[ "${S_ARCH[$i]}" == custom ]]; then
        prompt_value 'Comma-separated folders' "${S_SUBS[$i]}"
        S_SUBS[$i]="$PROMPT_RESULT"
      else
        S_SUBS[$i]="$(archetype_subfolders "${S_ARCH[$i]}" '')"
      fi
    done
  fi

  for ((i=0; i<${#S_SLUGS[@]}; i++)); do
    assigned="${ASSIGNED[$i]}"
    count=0; position=0
    for ((j=0; j<${#S_SLUGS[@]}; j++)); do
      if [[ "${ASSIGNED[$j]}" == "$assigned" ]]; then
        count=$((count + 1))
        [[ "$j" -le "$i" ]] && position=$((position + 1))
      fi
    done
    if [[ "$count" == 1 ]]; then folder=.
    else folder="$(printf '%02d' "$((position * 10))") ${S_NAMES[$i]}"
    fi
    v_index=-1
    for ((v=0; v<${#V_SLUGS[@]}; v++)); do [[ "${V_SLUGS[$v]}" == "$assigned" ]] && v_index="$v"; done
    [[ "$v_index" -ge 0 ]] || die "internal assignment error: $assigned"
    sensitivity="${V_SENS[$v_index]}"
    ai=false
    if contains_csv "${V_TOOLS[$v_index]}" claude || contains_csv "${V_TOOLS[$v_index]}" codex; then
      prompt_yes_no "Allow selected AI clients to process ${S_NAMES[$i]} notes when ai_allowed is true?" n
      [[ "$PROMPT_BOOL" == 1 ]] && ai=true
    fi
    add_domain "${S_SLUGS[$i]}" "${S_NAMES[$i]}" "$assigned" "$folder" \
      "${S_ARCH[$i]}" "$sensitivity" "$ai" "${S_SUBS[$i]}"
  done

  write_candidate "$CANDIDATE"
}

compare_existing() {
  candidate="$1"
  : > "$CHANGE_REPORT"
  [[ -r "$CURRENT_MANIFEST" ]] || return 0
  migration=0
  {
    printf '# Second Brain reconfiguration review\n\n'
    printf 'No note is deleted or moved by this operation.\n\n'
    printf '## Retained but unmanaged\n\n'
  } >> "$CHANGE_REPORT"
  removed=0
  while IFS=$'\t' read -r kind slug name path sensitivity tools dashboard; do
    [[ "$kind" == vault ]] || continue
    new_line="$(awk -F '\t' -v wanted="$slug" '$1=="vault" && $2==wanted {print; exit}' "$candidate")"
    if [[ -z "$new_line" ]]; then
      printf -- '- Vault `%s` at `%s` is removed from management; its files remain.\n' "$slug" "$path" >> "$CHANGE_REPORT"
      removed=1
    else
      new_path="$(printf '%s\n' "$new_line" | awk -F '\t' '{print $4}')"
      if [[ "$new_path" != "$path" ]]; then
        fail "vault '$slug' changes path from '$path' to '$new_path'; this requires a separate migration"
        migration=1
      fi
    fi
  done < "$CURRENT_MANIFEST"
  while IFS=$'\t' read -r kind slug name vault_slug folder archetype sensitivity ai subfolders; do
    [[ "$kind" == domain ]] || continue
    new_line="$(awk -F '\t' -v wanted="$slug" '$1=="domain" && $2==wanted {print; exit}' "$candidate")"
    if [[ -z "$new_line" ]]; then
      printf -- '- Domain `%s` in `%s/%s` is removed from management; its files remain.\n' "$slug" "$vault_slug" "$folder" >> "$CHANGE_REPORT"
      removed=1
    else
      new_name="$(printf '%s\n' "$new_line" | awk -F '\t' '{print $3}')"
      new_vault="$(printf '%s\n' "$new_line" | awk -F '\t' '{print $4}')"
      new_folder="$(printf '%s\n' "$new_line" | awk -F '\t' '{print $5}')"
      if [[ "$new_name" != "$name" ]]; then
        fail "domain '$slug' changes display name from '$name' to '$new_name'; this requires a separate rename plan because generated filenames use the display name"
        migration=1
      elif [[ "$new_vault" != "$vault_slug" || "$new_folder" != "$folder" ]]; then
        fail "domain '$slug' changes physical location; this requires a separate migration plan"
        migration=1
      fi
    fi
  done < "$CURRENT_MANIFEST"
  [[ "$removed" == 1 ]] || printf 'None.\n' >> "$CHANGE_REPORT"
  printf '\n## Manifest diff\n\n```diff\n' >> "$CHANGE_REPORT"
  diff -u "$CURRENT_MANIFEST" "$candidate" >> "$CHANGE_REPORT" || true
  printf '```\n' >> "$CHANGE_REPORT"
  [[ "$migration" == 0 ]]
}

backup_path() {
  target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  relative="${target#/}"
  destination="$BACKUP_DIR/files/$relative"
  mkdir -p "$(dirname "$destination")"
  [[ -e "$destination" || -L "$destination" ]] || cp -pR "$target" "$destination"
}

copy_missing() {
  source_path="$1"; target_path="$2"
  if [[ -e "$target_path" || -L "$target_path" ]]; then info "preserved existing: $target_path"; return 0; fi
  mkdir -p "$(dirname "$target_path")"
  cp -p "$source_path" "$target_path"
  pass "created: $target_path"
}

install_owned() {
  source_path="$1"; target_path="$2"
  if [[ -f "$target_path" ]] && cmp -s "$source_path" "$target_path"; then info "current: $target_path"; return 0; fi
  backup_path "$target_path"
  mkdir -p "$(dirname "$target_path")"
  cp -p "$source_path" "$target_path"
  chmod +x "$target_path"
  pass "installed managed command: $target_path"
}

retire_generated() {
  target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  case "$target" in "$HOME"/*) ;; *) die "refusing to retire a generated path outside HOME: $target" ;; esac
  destination="$BACKUP_DIR/retired/${target#"$HOME"/}"
  mkdir -p "$(dirname "$destination")"
  [[ ! -e "$destination" && ! -L "$destination" ]] || die "retirement destination already exists: $destination"
  mv "$target" "$destination"
  pass "retired deselected generated integration: $target"
}

write_managed() {
  source_path="$1"; target_path="$2"
  if [[ ! -e "$target_path" ]]; then
    mkdir -p "$(dirname "$target_path")"; cp -p "$source_path" "$target_path"; pass "created: $target_path"; return 0
  fi
  if grep -Eq 'managed-by: (second-brain|fresh-start-second-brain)' "$target_path" 2>/dev/null; then
    if cmp -s "$source_path" "$target_path"; then info "current: $target_path"; return 0; fi
    backup_path "$target_path"; cp -p "$source_path" "$target_path"; pass "updated managed file: $target_path"; return 0
  fi
  proposal="$target_path.day-one-mac-proposed"
  cp -p "$source_path" "$proposal"
  warn "preserved unrecognised file; review proposed replacement: $proposal"
}

generate_knowledge_system() {
  manifest="$1"; vault_slug="$2"; output="$3"
  vault_sensitivity="$(awk -F '\t' -v wanted="$vault_slug" '$1=="vault" && $2==wanted {print $5; exit}' "$manifest")"
  {
    printf '%s\n' '---' '# managed-by: second-brain' 'domain: shared' 'type: review' 'status: active'
    printf 'created: %s\n' "$(date '+%Y-%m-%d')"
    printf 'sensitivity: %s\n' "$vault_sensitivity"
    printf '%s\n' 'ai_allowed: false' 'topics:' '  - knowledge-management' '---' '' '# Knowledge System' '' '## Managed domains' ''
    while IFS=$'\t' read -r kind slug name assigned folder archetype sensitivity ai subfolders; do
      [[ "$kind" == domain && "$assigned" == "$vault_slug" ]] || continue
      printf -- '- `%s` — %s; `%s`; AI default `%s`.\n' "$slug" "$name" "$archetype" "$ai"
    done < "$manifest"
    printf '%s\n' '' '## Shared property contract' '' '- `domain`: a stable slug listed above, or `shared` for system notes.' '- `type`: `capture`, `project`, `learning`, `content`, `source`, `person`, or `review`.' '- `status`: `inbox`, `active`, `incubating`, `drafting`, `review`, `scheduled`, `published`, `done`, or `archived`.' '- `created`: ISO date.' '- `sensitivity`: `public`, `personal`, or `work-confidential`.' '- `ai_allowed`: a deliberate review cue, not a security boundary.' '' '## Rules' '' '- Capture first and process weekly.' '- Keep one canonical note and link to it.' '- Keep AI proposals in `90 System/AI Review` until reviewed.' '- Never treat sync as the independent backup.'
  } > "$output"
}

prepare_managed_note() {
  source_path="$1"; sensitivity="$2"; output="$3"
  awk -v sensitivity="$sensitivity" '
    NR == 1 && $0 == "---" {
      print
      print "# managed-by: second-brain"
      next
    }
    /^sensitivity:/ {
      print "sensitivity: " sensitivity
      next
    }
    { print }
  ' "$source_path" > "$output"
}

generate_dashboard() {
  manifest="$1"; vault_slug="$2"; output="$3"
  vault_name="$(awk -F '\t' -v wanted="$vault_slug" '$1=="vault" && $2==wanted {print $3; exit}' "$manifest")"
  {
    printf '%s\n\n' '<!-- managed-by: second-brain -->' "# $vault_name dashboard"
    printf '%s\n' '## Start' '' '- [[00 Inbox/Inbox|Process the inbox]]' '- [[00 Inbox/Quick capture|Quick capture]]' '- [[90 System/Knowledge System|Knowledge System]]' '' '## Domains' ''
    while IFS=$'\t' read -r kind slug name assigned folder archetype sensitivity ai subfolders; do
      [[ "$kind" == domain && "$assigned" == "$vault_slug" ]] || continue
      if [[ "$folder" == . ]]; then index="$name"; else index="$folder/$name"; fi
      printf -- '- [[%s|%s]]\n' "$index" "$name"
      printf '![[%s.base#Overview]]\n\n' "$slug"
    done < "$manifest"
    printf '%s\n' '## Review' '' '- AI proposals: `90 System/AI Review`' '- Local reports: run `second-brain-report`' '- Sync is not the independent backup.'
  } > "$output"
}

generate_base() {
  folder="$1"; subfolders="$2"; output="$3"
  {
    printf '%s\n' '# managed-by: second-brain' 'filters:' '  and:' '    - or:'
    old_ifs="$IFS"; IFS=','
    for subfolder in $subfolders; do
      if [[ "$folder" == . ]]; then filter_path="$subfolder"; else filter_path="$folder/$subfolder"; fi
      printf "        - 'file.inFolder(\"%s\")'\n" "$filter_path"
    done
    IFS="$old_ifs"
    printf '%s\n' "    - 'file.ext == \"md\"'" 'properties:' '  file.name:' '    displayName: Note' '  type:' '    displayName: Type' '  status:' '    displayName: Status' '  topics:' '    displayName: Topics' '  file.mtime:' '    displayName: Updated' 'views:' '  - type: table' '    name: Overview' '    order:' '      - file.name' '      - type' '      - status' '      - topics' '      - file.mtime' '  - type: table' '    name: Needs review' '    filters:' '      or:' "        - 'status == \"inbox\"'" "        - 'status == \"review\"'" "        - '!type'" "        - '!status'" "        - '!created'" '    order:' '      - file.name' '      - status' '      - file.mtime'
  } > "$output"
}

generate_index() {
  name="$1"; slug="$2"; sensitivity="$3"; ai="$4"; dashboard="$5"; output="$6"
  {
    printf '%s\n' '---' '# managed-by: second-brain'
    printf 'domain: %s\ntype: index\nstatus: active\ncreated: %s\nsensitivity: %s\nai_allowed: %s\ntopics:\n  - %s\n' \
      "$slug" "$(date '+%Y-%m-%d')" "$sensitivity" "$ai" "$slug"
    printf '%s\n\n' '---' "# $name"
    printf '%s\n' '## Navigate' '' "- [[$dashboard/Vault Dashboard|Vault dashboard]]" '- [[00 Inbox/Inbox|Inbox]]' '' '## Purpose' '' 'Describe what belongs in this domain and what should remain outside it.'
  } > "$output"
}

generate_template() {
  name="$1"; slug="$2"; sensitivity="$3"; ai="$4"; output="$5"
  {
    printf '%s\n' '---' '# managed-by: second-brain'
    printf 'domain: %s\ntype: note\nstatus: active\ncreated: "{{date}}"\nsensitivity: %s\nai_allowed: %s\ntopics: []\n' "$slug" "$sensitivity" "$ai"
    printf '%s\n\n' '---' '# {{title}}'
    printf '%s\n' '## Summary' '' '' '## Notes' '' '' '## Sources' '' '- [[]]' '' '## Related' '' '- [[]]'
  } > "$output"
}

scaffold_layout() {
  manifest="$1"
  while IFS=$'\t' read -r kind vault_slug vault_name vault_path vault_sens vault_tools dashboard; do
    [[ "$kind" == vault ]] || continue
    mkdir -p "$vault_path/00 Inbox" "$vault_path/$dashboard" "$vault_path/80 Attachments" \
      "$vault_path/90 System/AI Review" "$vault_path/90 System/Reports" "$vault_path/99 Templates"
    copy_missing "$ASSETS/three-vaults/common/.gitignore" "$vault_path/.gitignore"
    prepare_managed_note "$ASSETS/three-vaults/common/Inbox.md" "$vault_sens" "$TMP_DIR/inbox-$vault_slug.md"
    write_managed "$TMP_DIR/inbox-$vault_slug.md" "$vault_path/00 Inbox/Inbox.md"
    prepare_managed_note "$ASSETS/three-vaults/common/Quick capture.md" "$vault_sens" "$TMP_DIR/quick-capture-$vault_slug.md"
    write_managed "$TMP_DIR/quick-capture-$vault_slug.md" "$vault_path/00 Inbox/Quick capture.md"
    prepare_managed_note "$ASSETS/vault/99 Templates/Capture.md" "$vault_sens" "$TMP_DIR/capture-$vault_slug.md"
    write_managed "$TMP_DIR/capture-$vault_slug.md" "$vault_path/99 Templates/Capture.md"
    prepare_managed_note "$ASSETS/vault/99 Templates/Person.md" "$vault_sens" "$TMP_DIR/person-$vault_slug.md"
    write_managed "$TMP_DIR/person-$vault_slug.md" "$vault_path/99 Templates/Person.md"
    prepare_managed_note "$ASSETS/vault/99 Templates/Source.md" "$vault_sens" "$TMP_DIR/source-$vault_slug.md"
    write_managed "$TMP_DIR/source-$vault_slug.md" "$vault_path/99 Templates/Source.md"
    prepare_managed_note "$ASSETS/three-vaults/common/Weekly Review.md" "$vault_sens" "$TMP_DIR/weekly-review-$vault_slug.md"
    write_managed "$TMP_DIR/weekly-review-$vault_slug.md" "$vault_path/99 Templates/Weekly Review.md"
    contains_csv "$vault_tools" codex && copy_missing "$ASSETS/three-vaults/common/AGENTS.md" "$vault_path/AGENTS.md"
    contains_csv "$vault_tools" claude && copy_missing "$ASSETS/three-vaults/common/CLAUDE.md" "$vault_path/CLAUDE.md"
    generate_knowledge_system "$manifest" "$vault_slug" "$TMP_DIR/knowledge-$vault_slug.md"
    write_managed "$TMP_DIR/knowledge-$vault_slug.md" "$vault_path/90 System/Knowledge System.md"
    generate_dashboard "$manifest" "$vault_slug" "$TMP_DIR/dashboard-$vault_slug.md"
    write_managed "$TMP_DIR/dashboard-$vault_slug.md" "$vault_path/$dashboard/Vault Dashboard.md"
  done < "$manifest"

  while IFS=$'\t' read -r kind slug name vault_slug folder archetype sensitivity ai subfolders; do
    [[ "$kind" == domain ]] || continue
    vault_line="$(awk -F '\t' -v wanted="$vault_slug" '$1=="vault" && $2==wanted {print; exit}' "$manifest")"
    vault_path="$(printf '%s\n' "$vault_line" | awk -F '\t' '{print $4}')"
    dashboard="$(printf '%s\n' "$vault_line" | awk -F '\t' '{print $7}')"
    if [[ "$folder" == . ]]; then domain_root="$vault_path"; else domain_root="$vault_path/$folder"; fi
    mkdir -p "$domain_root"
    old_ifs="$IFS"; IFS=','
    for subfolder in $subfolders; do mkdir -p "$domain_root/$subfolder"; done
    IFS="$old_ifs"
    generate_index "$name" "$slug" "$sensitivity" "$ai" "$dashboard" "$TMP_DIR/index-$slug.md"
    write_managed "$TMP_DIR/index-$slug.md" "$domain_root/$name.md"
    generate_base "$folder" "$subfolders" "$TMP_DIR/base-$slug.base"
    write_managed "$TMP_DIR/base-$slug.base" "$vault_path/$dashboard/$slug.base"
    generate_template "$name" "$slug" "$sensitivity" "$ai" "$TMP_DIR/template-$slug.md"
    write_managed "$TMP_DIR/template-$slug.md" "$vault_path/99 Templates/$name.md"
  done < "$manifest"
}

candidate_has_tool() {
  awk -F '\t' -v wanted="$2" '$1=="vault" {n=split($6,a,","); for(i=1;i<=n;i++) if(a[i]==wanted) found=1} END{exit !found}' "$1"
}

install_integrations() {
  manifest="$1"
  mkdir -p "$USER_BIN"
  install_owned "$ASSETS/manager/report/second-brain-report.sh" "$USER_BIN/second-brain-report"
  if candidate_has_tool "$manifest" raycast; then
    mkdir -p "$RAYCAST_DIR"
    for source_path in "$ASSETS/manager/raycast"/*.sh; do install_owned "$source_path" "$RAYCAST_DIR/$(basename "$source_path")"; done
  else
    retire_generated "$RAYCAST_DIR/capture-knowledge-vault.sh"
    retire_generated "$RAYCAST_DIR/open-knowledge-vault.sh"
    retire_generated "$RAYCAST_DIR/search-knowledge-vault.sh"
  fi
  if candidate_has_tool "$manifest" codex; then install_owned "$ASSETS/manager/codex/second-brain-codex.sh" "$USER_BIN/second-brain-codex"
  else retire_generated "$USER_BIN/second-brain-codex"
  fi
  if candidate_has_tool "$manifest" claude; then install_owned "$ASSETS/manager/claude/second-brain-claude.sh" "$USER_BIN/second-brain-claude"
  else retire_generated "$USER_BIN/second-brain-claude"
  fi
  # Retire launchers from the fixed three-vault implementation after the new
  # manifest-aware commands have been installed. Every move is recoverable.
  retire_generated "$USER_BIN/second-brain-codex-three"
  retire_generated "$USER_BIN/second-brain-claude-three"
  retire_generated "$USER_BIN/second-brain-report-three"
  retire_generated "$RAYCAST_DIR/search-second-brain.sh"
  retire_generated "$RAYCAST_DIR/capture-second-brain.sh"
  retire_generated "$RAYCAST_DIR/open-second-brain-dashboard.sh"
  retire_generated "$LEGACY_RAYCAST_DIR/capture-knowledge-vault.sh"
  retire_generated "$LEGACY_RAYCAST_DIR/open-knowledge-vault.sh"
  retire_generated "$LEGACY_RAYCAST_DIR/search-knowledge-vault.sh"
  retire_generated "$LEGACY_RAYCAST_DIR/search-second-brain.sh"
  retire_generated "$LEGACY_RAYCAST_DIR/capture-second-brain.sh"
  retire_generated "$LEGACY_RAYCAST_DIR/open-second-brain-dashboard.sh"
  retire_generated "$HOME/.local/share/fresh-start-second-brain/three-vault-raycast"
  return 0
}

record_second_brain_application() {
  mkdir -p "$DAY_ONE_STATE_DIR"
  touch "$DAY_ONE_INSTALL_MANIFEST"
  chmod 700 "$DAY_ONE_STATE_DIR"
  chmod 600 "$DAY_ONE_INSTALL_MANIFEST"
  day_one_app_record_current "$DAY_ONE_APPLICATION_TSV" "$DAY_ONE_APPLICATION_REPORT" \
    "$DAY_ONE_INSTALL_MANIFEST"
}

install_catalog_application() {
  local app_id="$1" before_formulae="" formula="" brew_bin=""
  day_one_app_detect "$app_id" || die "unknown Day One Mac application: $app_id"
  record_second_brain_application
  case "$DAY_ONE_APP_STATUS" in
    ready)
      pass "$DAY_ONE_APP_NAME — $(day_one_app_source_label "$DAY_ONE_APP_SOURCE"); existing installation preserved"
      return 0
      ;;
    review)
      die "$DAY_ONE_APP_NAME needs review: $DAY_ONE_APP_REASON"
      ;;
  esac
  if [[ "$APP_INSTALL_POLICY" == prompt && ! -t 0 ]]; then
    die "$DAY_ONE_APP_NAME is missing; rerun interactively or pass --app-install-policy homebrew"
  fi
  day_one_app_choose_install_route "$APP_INSTALL_POLICY"
  case "$DAY_ONE_APP_INSTALL_CHOICE" in
    stop)
      day_one_app_show_install_requirements
      die "$DAY_ONE_APP_NAME remains missing; no application owner was selected"
      ;;
    external)
      while :; do
        day_one_app_prompt_external_action
        case "$DAY_ONE_APP_EXTERNAL_ACTION" in
          homebrew) break ;;
          stop) die "$DAY_ONE_APP_NAME remains missing; rerun when the approved installer is ready" ;;
          again) warn 'Choose Enter, h, or s.'; continue ;;
        esac
        hash -r 2>/dev/null || true
        day_one_app_detect "$app_id"
        record_second_brain_application
        case "$DAY_ONE_APP_STATUS" in
          ready) pass "$DAY_ONE_APP_NAME — $(day_one_app_source_label "$DAY_ONE_APP_SOURCE"); external installation verified"; return 0 ;;
          review) die "$DAY_ONE_APP_NAME needs review: $DAY_ONE_APP_REASON" ;;
          missing) warn "$DAY_ONE_APP_NAME is still missing." ;;
        esac
      done
      ;;
  esac
  brew_bin="$(day_one_app_brew_bin)" || die "Homebrew is required to install missing application: $DAY_ONE_APP_NAME"
  before_formulae="$("$brew_bin" list --formula 2>/dev/null | LC_ALL=C sort || true)"
  "$brew_bin" install --cask "$DAY_ONE_APP_CASK"
  grep -Fqx "brew-cask"$'\t'"$DAY_ONE_APP_CASK" "$DAY_ONE_INSTALL_MANIFEST" 2>/dev/null \
    || printf 'brew-cask\t%s\n' "$DAY_ONE_APP_CASK" >> "$DAY_ONE_INSTALL_MANIFEST"
  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    grep -Fqx "$formula" <<<"$before_formulae" \
      || grep -Fqx "brew-dependency"$'\t'"$formula" "$DAY_ONE_INSTALL_MANIFEST" 2>/dev/null \
      || printf 'brew-dependency\t%s\n' "$formula" >> "$DAY_ONE_INSTALL_MANIFEST"
  done < <("$brew_bin" list --formula 2>/dev/null | LC_ALL=C sort)
  day_one_app_detect "$app_id"
  record_second_brain_application
  day_one_app_is_satisfied || die "$DAY_ONE_APP_NAME did not pass verification after Homebrew installation"
  pass "installed and verified: $DAY_ONE_APP_NAME"
}

install_selected_apps() {
  manifest="$1"
  install_catalog_application obsidian
  candidate_has_tool "$manifest" raycast && install_catalog_application raycast
  candidate_has_tool "$manifest" claude && install_catalog_application claude-code
  candidate_has_tool "$manifest" codex && install_catalog_application codex
}

validate_installed() {
  file="$1"
  FAILURES=0
  validate_manifest "$file" || true
  while IFS=$'\t' read -r kind slug name path sensitivity tools dashboard; do
    [[ "$kind" == vault ]] || continue
    for relative in '00 Inbox' "$dashboard" '80 Attachments' '90 System' '99 Templates'; do
      [[ -d "$path/$relative" ]] || fail "missing vault folder: $path/$relative"
    done
    [[ -s "$path/$dashboard/Vault Dashboard.md" ]] || fail "missing generated dashboard: $path/$dashboard/Vault Dashboard.md"
    if contains_csv "$tools" codex && [[ ! -s "$path/AGENTS.md" ]]; then fail "missing AGENTS.md: $path"; fi
    if contains_csv "$tools" claude && [[ ! -s "$path/CLAUDE.md" ]]; then fail "missing CLAUDE.md: $path"; fi
  done < "$file"
  while IFS=$'\t' read -r kind slug name vault_slug folder archetype sensitivity ai subfolders; do
    [[ "$kind" == domain ]] || continue
    vault_line="$(awk -F '\t' -v wanted="$vault_slug" '$1=="vault" && $2==wanted {print; exit}' "$file")"
    vault_path="$(printf '%s\n' "$vault_line" | awk -F '\t' '{print $4}')"
    dashboard="$(printf '%s\n' "$vault_line" | awk -F '\t' '{print $7}')"
    if [[ "$folder" == . ]]; then root="$vault_path"; else root="$vault_path/$folder"; fi
    [[ -s "$root/$name.md" ]] || fail "missing domain index: $root/$name.md"
    [[ -s "$vault_path/$dashboard/$slug.base" ]] || fail "missing domain Base: $vault_path/$dashboard/$slug.base"
    old_ifs="$IFS"; IFS=','
    for subfolder in $subfolders; do [[ -d "$root/$subfolder" ]] || fail "missing domain folder: $root/$subfolder"; done
    IFS="$old_ifs"
  done < "$file"
  if [[ "$FAILURES" -gt 0 ]]; then printf '\nFAIL: %s layout check(s) need attention.\n' "$FAILURES" >&2; return 1; fi
  printf '\nPASS: saved Second Brain layout and installed vaults match.\n'
}

apply_candidate() {
  candidate="$1"
  validate_manifest "$candidate" || die 'candidate layout is invalid'
  compare_existing "$candidate" || die 'reconfiguration contains a physical migration; no changes were made'
  render_report "$candidate" "$REPORT"
  printf '\nSecond Brain layout preview\n───────────────────────────\n'
  cat "$REPORT"
  if [[ -r "$CURRENT_MANIFEST" ]]; then
    printf '\nManifest changes\n────────────────\n'
    diff -u "$CURRENT_MANIFEST" "$candidate" || true
  fi
  if [[ "$APPLY" != 1 ]]; then
    printf '\nPreview only. Rerun the same command with --apply after reviewing it.\n'
    [[ -s "$CHANGE_REPORT" ]] && printf 'Reconfiguration review was generated in the temporary preview.\n'
    return 0
  fi
  if [[ "$ASSUME_YES" != 1 ]]; then
    [[ -t 0 ]] || die 'apply needs a terminal confirmation or --yes'
    printf '\nType APPLY LAYOUT to create/update only the managed layout: '
    IFS= read -r answer
    [[ "$answer" == 'APPLY LAYOUT' ]] || die 'confirmation did not match; nothing changed'
  fi
  stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  BACKUP_DIR="$STATE_DIR/backups/$stamp-$$"
  mkdir -p "$BACKUP_DIR"
  chmod 700 "$BACKUP_DIR"
  backup_path "$CURRENT_MANIFEST"
  backup_path "$CONFIG_DIR/layout-report.md"
  [[ "$INSTALL_APPS" == 1 ]] && install_selected_apps "$candidate"
  scaffold_layout "$candidate"
  install_integrations "$candidate"
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR" 2>/dev/null || true
  cp "$candidate" "$CONFIG_DIR/.layout.tsv.new"
  chmod 600 "$CONFIG_DIR/.layout.tsv.new"
  mv "$CONFIG_DIR/.layout.tsv.new" "$MANIFEST"
  cp "$REPORT" "$CONFIG_DIR/layout-report.md"
  chmod 600 "$CONFIG_DIR/layout-report.md"
  if [[ -s "$CHANGE_REPORT" ]]; then
    mkdir -p "$STATE_DIR/reports"
    cp "$CHANGE_REPORT" "$STATE_DIR/reports/$stamp-reconfiguration.md"
  fi
  retire_generated "$CONFIG_DIR/config"
  retire_generated "$CONFIG_DIR/three-vaults.conf"
  if [[ "$CURRENT_MANIFEST" != "$MANIFEST" ]]; then
    retire_generated "$CURRENT_MANIFEST"
    retire_generated "$LEGACY_CONFIG_DIR/layout-report.md"
    retire_generated "$LEGACY_CONFIG_DIR/config"
    retire_generated "$LEGACY_CONFIG_DIR/three-vaults.conf"
    pass "migrated the saved layout namespace to: $CONFIG_DIR"
  fi
  pass "saved layout: $MANIFEST"
  pass "saved readable report: $CONFIG_DIR/layout-report.md"
  printf '\nNext:\n  • Open every configured path as an Obsidian vault.\n'
  printf '  • Set Inbox, Attachments, Templates, and Bases in each vault.\n'
  candidate_has_tool "$candidate" raycast && printf '  • Add Raycast Script Directory: %s\n' "$RAYCAST_DIR"
  candidate_has_tool "$candidate" codex && printf '  • Run second-brain-codex and choose an allowed vault.\n'
  candidate_has_tool "$candidate" claude && printf '  • Run second-brain-claude and choose an allowed vault.\n'
  printf '  • Verify: %s --validate\n' "$0"
}

case "$ACTION" in
  show) show_layout ;;
  validate)
    [[ -r "$CURRENT_MANIFEST" ]] || die "no saved layout: $MANIFEST"
    validate_installed "$CURRENT_MANIFEST"
    ;;
  refresh)
    [[ -r "$CURRENT_MANIFEST" ]] || die "no saved layout: $MANIFEST"
    validate_manifest "$CURRENT_MANIFEST" || exit 1
    printf 'Integration refresh preview\n───────────────────────────\n'
    info "would refresh the report command in $USER_BIN"
    candidate_has_tool "$CURRENT_MANIFEST" raycast && info "would refresh Raycast commands in $RAYCAST_DIR"
    candidate_has_tool "$CURRENT_MANIFEST" codex && info 'would refresh the Codex vault selector'
    candidate_has_tool "$CURRENT_MANIFEST" claude && info 'would refresh the Claude Code vault selector'
    if [[ "$APPLY" != 1 ]]; then printf '\nPreview only. Add --apply to refresh generated commands.\n'; exit 0; fi
    if [[ "$ASSUME_YES" != 1 ]]; then
      [[ -t 0 ]] || die 'refresh needs a terminal confirmation or --yes'
      printf 'Type REFRESH INTEGRATIONS to continue: '; IFS= read -r answer
      [[ "$answer" == 'REFRESH INTEGRATIONS' ]] || die 'confirmation did not match; nothing changed'
    fi
    BACKUP_DIR="$STATE_DIR/backups/$(date -u '+%Y%m%dT%H%M%SZ')-$$"
    mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
    install_integrations "$CURRENT_MANIFEST"
    ;;
  guided)
    guided_build
    apply_candidate "$CANDIDATE"
    ;;
  build)
    if [[ -n "$LAYOUT_INPUT" ]]; then
      [[ -r "$LAYOUT_INPUT" ]] || die "layout input is not readable: $LAYOUT_INPUT"
      cp "$LAYOUT_INPUT" "$CANDIDATE"
    else
      [[ -n "$PRESET" ]] || die '--preset or --layout is required'
      build_preset
      REASONS=preset
      write_candidate "$CANDIDATE"
    fi
    apply_candidate "$CANDIDATE"
    ;;
esac
