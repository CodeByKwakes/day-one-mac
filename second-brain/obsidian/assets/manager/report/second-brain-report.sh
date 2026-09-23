#!/usr/bin/env bash
# managed-by: second-brain
# Deterministic analytics for every vault in the dynamic layout manifest.
set -euo pipefail

MANIFEST="${SECOND_BRAIN_LAYOUT:-$HOME/.config/second-brain/layout.tsv}"
if [[ -z "${SECOND_BRAIN_LAYOUT:-}" && ! -r "$MANIFEST" \
   && -r "$HOME/.config/fresh-start-second-brain/layout.tsv" ]]; then
  MANIFEST="$HOME/.config/fresh-start-second-brain/layout.tsv"
fi
WRITE=0

usage() {
  printf '%s\n' \
    'Usage: second-brain-report [--layout FILE] [--write]' \
    '' \
    'Prints one read-only Markdown summary across all configured vaults.' \
    '--write stores the same report outside the vaults under local state.'
}
die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --layout)
      [[ "$#" -ge 2 ]] || die '--layout needs a file'
      MANIFEST="$2"
      shift 2
      ;;
    --write) WRITE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ -r "$MANIFEST" ]] || die "layout not found: $MANIFEST"
TMP_REPORT="$(mktemp "${TMPDIR:-/tmp}/second-brain-dynamic-report.XXXXXX")"
trap 'rm -f "$TMP_REPORT"' EXIT

count_notes() {
  find "$1" -type f -name '*.md' \
    ! -path '*/99 Templates/*' \
    ! -path '*/90 System/*' \
    ! -path '*/01 Dashboard/*' \
    ! -path '*/01 Dashboards/*' \
    ! -name 'AGENTS.md' ! -name 'CLAUDE.md' | wc -l | tr -d ' '
}

count_inbox() {
  find "$1/00 Inbox" -type f -name '*.md' \
    ! -name 'Inbox.md' ! -name 'Quick capture.md' 2>/dev/null | wc -l | tr -d ' '
}

count_recent() {
  find "$1" -type f -name '*.md' -mtime -7 \
    ! -path '*/99 Templates/*' \
    ! -path '*/90 System/*' \
    ! -path '*/01 Dashboard/*' \
    ! -path '*/01 Dashboards/*' | wc -l | tr -d ' '
}

count_gaps() {
  vault_path="$1"
  total=0
  while IFS= read -r -d '' note; do
    missing=0
    for property in domain type status created; do
      grep -Eq "^${property}:[[:space:]]*[^[:space:]]" "$note" || missing=1
    done
    [[ "$missing" == 0 ]] || total=$((total + 1))
  done < <(find "$vault_path" -type f -name '*.md' \
    ! -path '*/99 Templates/*' ! -path '*/90 System/*' \
    ! -path '*/01 Dashboard/*' ! -path '*/01 Dashboards/*' \
    ! -path '*/00 Inbox/*' ! -name 'AGENTS.md' ! -name 'CLAUDE.md' -print0)
  printf '%s' "$total"
}

count_unlinked() {
  vault_path="$1"
  total=0
  while IFS= read -r -d '' note; do
    grep -Fq '[[' "$note" || total=$((total + 1))
  done < <(find "$vault_path" -type f -name '*.md' \
    ! -path '*/99 Templates/*' ! -path '*/90 System/*' \
    ! -path '*/01 Dashboard/*' ! -path '*/01 Dashboards/*' \
    ! -path '*/00 Inbox/*' ! -name 'AGENTS.md' ! -name 'CLAUDE.md' -print0)
  printf '%s' "$total"
}

{
  printf '# Second Brain health — %s\n\n' "$(date '+%Y-%m-%d')"
  printf 'Generated locally from `%s`. This report does not modify a vault.\n\n' "$MANIFEST"
  printf '| Vault | Notes | Inbox | Modified 7d | Metadata gaps | No outbound links |\n'
  printf '|---|---:|---:|---:|---:|---:|\n'
  found=0
  while IFS=$'\t' read -r kind slug name path sensitivity tools dashboard; do
    [[ "$kind" == vault ]] || continue
    found=1
    if [[ ! -d "$path" ]]; then
      printf '| %s | missing | — | — | — | — |\n' "$name"
      continue
    fi
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$name" "$(count_notes "$path")" "$(count_inbox "$path")" \
      "$(count_recent "$path")" "$(count_gaps "$path")" "$(count_unlinked "$path")"
  done < "$MANIFEST"
  [[ "$found" == 1 ]] || die 'layout contains no vault records'
  printf '\n## Configured domains\n\n'
  printf '| Domain | Vault | Archetype | AI allowed |\n|---|---|---|:---:|\n'
  while IFS=$'\t' read -r kind slug name vault_slug folder archetype sensitivity ai_allowed subfolders; do
    [[ "$kind" == domain ]] || continue
    vault_name="$(awk -F '\t' -v wanted="$vault_slug" '$1=="vault" && $2==wanted {print $3; exit}' "$MANIFEST")"
    printf '| %s | %s | %s | %s |\n' "$name" "$vault_name" "$archetype" "$ai_allowed"
  done < "$MANIFEST"
  printf '\n## Review prompts\n\n'
  printf -- '- Which inbox needs attention first?\n'
  printf -- '- Are metadata gaps hiding notes from a dashboard?\n'
  printf -- '- Which generated AI proposals should be accepted, revised, or archived?\n'
  printf -- '- Is every vault, plus the layout manifest, covered by a tested backup?\n'
} > "$TMP_REPORT"

if [[ "$WRITE" == 1 ]]; then
  report_dir="${SECOND_BRAIN_STATE:-$HOME/.local/state/second-brain}/reports"
  mkdir -p "$report_dir"
  report_path="$report_dir/$(date '+%Y-%m-%d')-health.md"
  [[ ! -e "$report_path" ]] || report_path="$report_dir/$(date '+%Y-%m-%d-%H%M%S')-health.md"
  cp "$TMP_REPORT" "$report_path"
  printf 'Wrote %s\n' "$report_path"
else
  cat "$TMP_REPORT"
fi
