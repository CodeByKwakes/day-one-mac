#!/usr/bin/env bash
# Deterministic, local vault analytics. Read-only unless --write is supplied.
set -euo pipefail

VAULT_PATH=""
WRITE=0
CONFIG_FILE="${SECOND_BRAIN_CONFIG:-$HOME/.config/second-brain/config}"

usage() {
  printf '%s\n' \
    'Usage: vault-health-report.sh [--vault ABSOLUTE_PATH] [--write]' \
    '' \
    'Prints Markdown analytics for the fixed default-domain Obsidian vault.' \
    '--write stores a dated copy under 90 System/Reports.'
}

die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --vault)
      [[ "$#" -ge 2 ]] || die '--vault needs an absolute path'
      VAULT_PATH="$2"
      shift 2
      ;;
    --write) WRITE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

if [[ -z "$VAULT_PATH" && -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  VAULT_PATH="${SECOND_BRAIN_VAULT_PATH:-}"
fi
VAULT_PATH="${VAULT_PATH:-$HOME/Vaults/Second Brain}"

case "$VAULT_PATH" in /*) ;; *) die '--vault must be an absolute path' ;; esac
[[ -d "$VAULT_PATH" ]] || die "vault not found: $VAULT_PATH"

for relative in '00 Inbox' '10 Software Development' '20 Software Content' '30 Tech Content'; do
  [[ -d "$VAULT_PATH/$relative" ]] || die "required folder missing: $relative"
done

TMP_REPORT="$(mktemp "${TMPDIR:-/tmp}/second-brain-health.XXXXXX")"
TMP_MONTHS="$(mktemp "${TMPDIR:-/tmp}/second-brain-months.XXXXXX")"
TMP_MISSING="$(mktemp "${TMPDIR:-/tmp}/second-brain-missing.XXXXXX")"
TMP_UNLINKED="$(mktemp "${TMPDIR:-/tmp}/second-brain-unlinked.XXXXXX")"
trap 'rm -f "$TMP_REPORT" "$TMP_MONTHS" "$TMP_MISSING" "$TMP_UNLINKED"' EXIT

count_markdown() {
  target="$1"
  if [[ ! -d "$target" ]]; then
    printf '0'
  else
    find "$target" -type f -name '*.md' | wc -l | tr -d ' '
  fi
}

count_recent() {
  days="$1"
  total=0
  for relative in '10 Software Development' '20 Software Content' '30 Tech Content'; do
    value="$(find "$VAULT_PATH/$relative" -type f -name '*.md' -mtime "-$days" | wc -l | tr -d ' ')"
    total=$((total + value))
  done
  printf '%s' "$total"
}

development_count="$(count_markdown "$VAULT_PATH/10 Software Development")"
software_content_count="$(count_markdown "$VAULT_PATH/20 Software Content")"
tech_content_count="$(count_markdown "$VAULT_PATH/30 Tech Content")"
inbox_count="$(find "$VAULT_PATH/00 Inbox" -type f -name '*.md' ! -name 'Inbox.md' ! -name 'Quick capture.md' 2>/dev/null | wc -l | tr -d ' ')"
quick_capture_count="$(grep -Ec '^- [0-9]{4}-[0-9]{2}-[0-9]{2} ' "$VAULT_PATH/00 Inbox/Quick capture.md" 2>/dev/null || true)"
recent_7="$(count_recent 7)"
recent_30="$(count_recent 30)"

for relative in '10 Software Development' '20 Software Content' '30 Tech Content'; do
  while IFS= read -r -d '' note; do
    missing_fields=""
    for property in domain type status created; do
      if ! grep -Eq "^${property}:[[:space:]]*[^[:space:]]" "$note"; then
        missing_fields="${missing_fields}${missing_fields:+, }$property"
      fi
    done
    note_relative="${note#"$VAULT_PATH"/}"
    if [[ -n "$missing_fields" ]]; then
      printf '%s\t%s\n' "$note_relative" "$missing_fields" >> "$TMP_MISSING"
    fi
    if ! grep -Fq '[[' "$note"; then
      printf '%s\n' "$note_relative" >> "$TMP_UNLINKED"
    fi
    created_value="$(grep -Em1 '^created:[[:space:]]*' "$note" | sed -E 's/^created:[[:space:]]*["'"'"']?([0-9]{4}-[0-9]{2}).*/\1/' || true)"
    case "$created_value" in
      [0-9][0-9][0-9][0-9]-[0-9][0-9]) printf '%s\n' "$created_value" >> "$TMP_MONTHS" ;;
    esac
  done < <(find "$VAULT_PATH/$relative" -type f -name '*.md' -print0)
done

missing_count="$(wc -l < "$TMP_MISSING" | tr -d ' ')"
unlinked_count="$(wc -l < "$TMP_UNLINKED" | tr -d ' ')"
generated="$(date '+%Y-%m-%d %H:%M:%S %Z')"

{
  printf '# Vault health — %s\n\n' "$(date '+%Y-%m-%d')"
  printf 'Generated locally at `%s`. Modified-file figures measure activity, not creation.\n\n' "$generated"
  printf '## Snapshot\n\n'
  printf '| Signal | Count |\n|---|---:|\n'
  printf '| Software development Markdown files | %s |\n' "$development_count"
  printf '| Software content Markdown files | %s |\n' "$software_content_count"
  printf '| Tech content Markdown files | %s |\n' "$tech_content_count"
  printf '| Inbox notes awaiting classification | %s |\n' "$inbox_count"
  printf '| Quick-capture lines | %s |\n' "$quick_capture_count"
  printf '| Domain notes modified in 7 days | %s |\n' "$recent_7"
  printf '| Domain notes modified in 30 days | %s |\n' "$recent_30"
  printf '| Notes missing required properties | %s |\n' "$missing_count"
  printf '| Notes with no outbound wikilink | %s |\n\n' "$unlinked_count"
  printf '## Creation history by recorded month\n\n'
  printf '| Month | Notes |\n|---|---:|\n'
  if [[ -s "$TMP_MONTHS" ]]; then
    sort "$TMP_MONTHS" | uniq -c | while read -r count month; do
      printf '| %s | %s |\n' "$month" "$count"
    done
  else
    printf '| No valid `created` properties | 0 |\n'
  fi
  printf '\n## Missing properties\n\n'
  if [[ -s "$TMP_MISSING" ]]; then
    while IFS=$'\t' read -r path fields; do
      printf -- '- `%s` — %s\n' "$path" "$fields"
    done < "$TMP_MISSING"
  else
    printf 'None.\n'
  fi
  printf '\n## No outbound wikilinks\n\n'
  if [[ -s "$TMP_UNLINKED" ]]; then
    while IFS= read -r path; do printf -- '- `%s`\n' "$path"; done < "$TMP_UNLINKED"
  else
    printf 'None.\n'
  fi
  printf '\n## Review prompts\n\n'
  printf -- '- Is the inbox below the agreed threshold?\n'
  printf -- '- Which content status is accumulating work?\n'
  printf -- '- Which isolated notes should be linked, archived, or intentionally standalone?\n'
  printf -- '- Is the independent backup current and restorable?\n'
} > "$TMP_REPORT"

if [[ "$WRITE" == 1 ]]; then
  report_dir="$VAULT_PATH/90 System/Reports"
  mkdir -p "$report_dir"
  report_path="$report_dir/$(date '+%Y-%m-%d')-vault-health.md"
  if [[ -e "$report_path" ]]; then
    report_path="$report_dir/$(date '+%Y-%m-%d-%H%M%S')-vault-health.md"
  fi
  cp "$TMP_REPORT" "$report_path"
  printf 'Wrote %s\n' "$report_path"
else
  cat "$TMP_REPORT"
fi
