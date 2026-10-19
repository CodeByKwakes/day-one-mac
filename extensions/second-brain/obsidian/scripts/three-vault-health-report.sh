#!/usr/bin/env bash
# Deterministic read-only summary for three physical Obsidian vaults.
set -euo pipefail

CONFIG_FILE="${SECOND_BRAIN_THREE_CONFIG:-$HOME/.config/second-brain/multi-vaults.conf}"
ROOT_PATH=""

usage() {
  printf '%s\n' \
    'Usage: three-vault-health-report.sh [--root ABSOLUTE_PATH]' \
    '' \
    'Prints a read-only Markdown summary for three physical Obsidian vaults.'
}
die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      [[ "$#" -ge 2 ]] || die '--root needs an absolute path'
      ROOT_PATH="$2"
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

if [[ -z "$ROOT_PATH" && -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  ROOT_PATH="${THREE_VAULT_ROOT:-}"
fi
ROOT_PATH="${ROOT_PATH:-$HOME/Vaults}"
case "$ROOT_PATH" in /*) ;; *) die '--root must be an absolute path' ;; esac

count_markdown() {
  find "$1" -type f -name '*.md' \
    ! -path '*/99 Templates/*' \
    ! -path '*/90 System/*' \
    ! -path '*/01 Dashboard/*' | wc -l | tr -d ' '
}

count_inbox() {
  find "$1/00 Inbox" -type f -name '*.md' \
    ! -name 'Inbox.md' ! -name 'Quick capture.md' | wc -l | tr -d ' '
}

count_recent() {
  find "$1" -type f -name '*.md' -mtime -7 \
    ! -path '*/99 Templates/*' \
    ! -path '*/90 System/*' \
    ! -path '*/01 Dashboard/*' | wc -l | tr -d ' '
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
    ! -path '*/01 Dashboard/*' ! -path '*/00 Inbox/*' -print0)
  printf '%s' "$total"
}

count_unlinked() {
  vault_path="$1"
  total=0
  while IFS= read -r -d '' note; do
    grep -Fq '[[' "$note" || total=$((total + 1))
  done < <(find "$vault_path" -type f -name '*.md' \
    ! -path '*/99 Templates/*' ! -path '*/90 System/*' \
    ! -path '*/01 Dashboard/*' ! -path '*/00 Inbox/*' -print0)
  printf '%s' "$total"
}

printf '# Three-vault health — %s\n\n' "$(date '+%Y-%m-%d')"
printf 'Generated locally. This command does not modify any vault.\n\n'
printf '| Vault | Notes | Inbox | Modified 7d | Metadata gaps | No outbound links |\n'
printf '|---|---:|---:|---:|---:|---:|\n'
for vault_name in 'Software Development' 'Software Content' 'Tech Content'; do
  vault_path="$ROOT_PATH/$vault_name"
  [[ -d "$vault_path" ]] || die "vault not found: $vault_path"
  printf '| %s | %s | %s | %s | %s | %s |\n' \
    "$vault_name" \
    "$(count_markdown "$vault_path")" \
    "$(count_inbox "$vault_path")" \
    "$(count_recent "$vault_path")" \
    "$(count_gaps "$vault_path")" \
    "$(count_unlinked "$vault_path")"
done

printf '\n## Review prompts\n\n'
printf -- '- Which inbox needs attention first?\n'
printf -- '- Are metadata gaps preventing a dashboard from showing notes?\n'
printf -- '- Which cross-vault handoffs need their source rechecked?\n'
printf -- '- Is each vault covered by a tested, independent backup?\n'
