#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Search Knowledge Vault
# @raycast.mode silent
# @raycast.argument1 { "type": "dropdown", "placeholder": "Vault", "data": [{"title":"Software Development","value":"development"},{"title":"Software Content","value":"software-content"},{"title":"Tech Content","value":"tech-content"}] }
# @raycast.argument2 { "type": "text", "placeholder": "Search text" }

# Optional parameters:
# @raycast.icon 🔎
# @raycast.packageName Second Brain — Three Vaults
# @raycast.description Search the selected physical Obsidian vault

set -euo pipefail

CONFIG_FILE="${SECOND_BRAIN_THREE_CONFIG:-$HOME/.config/second-brain/multi-vaults.conf}"
if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

case "${1:-}" in
  development) vault="${DEVELOPMENT_VAULT_NAME:-Software Development}" ;;
  software-content) vault="${SOFTWARE_CONTENT_VAULT_NAME:-Software Content}" ;;
  tech-content) vault="${TECH_CONTENT_VAULT_NAME:-Tech Content}" ;;
  *) printf 'Choose a valid vault.\n' >&2; exit 2 ;;
esac
query="${2:-}"
[[ -n "$query" ]] || { printf 'Enter search text.\n' >&2; exit 2; }

urlencode() {
  /usr/bin/osascript -l JavaScript \
    -e 'function run(argv) { return encodeURIComponent(argv[0]); }' "$1"
}

/usr/bin/open "obsidian://search?vault=$(urlencode "$vault")&query=$(urlencode "$query")"
printf 'Searching %s\n' "$vault"
