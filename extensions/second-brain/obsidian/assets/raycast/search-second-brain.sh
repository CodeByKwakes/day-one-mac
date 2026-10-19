#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Search Second Brain
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "Search all selected domains" }

# Optional parameters:
# @raycast.icon 🧠
# @raycast.packageName Second Brain
# @raycast.description Open an encoded search in the configured Obsidian vault

set -euo pipefail

CONFIG_FILE="${SECOND_BRAIN_CONFIG:-$HOME/.config/second-brain/config}"
if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

VAULT_NAME="${SECOND_BRAIN_VAULT_NAME:-Second Brain}"
QUERY="${1:-}"

if [[ -z "$QUERY" ]]; then
  printf 'Enter a search query.\n' >&2
  exit 2
fi

urlencode() {
  /usr/bin/osascript -l JavaScript \
    -e 'function run(argv) { return encodeURIComponent(argv[0]); }' "$1"
}

ENCODED_VAULT="$(urlencode "$VAULT_NAME")"
ENCODED_QUERY="$(urlencode "$QUERY")"
/usr/bin/open "obsidian://search?vault=$ENCODED_VAULT&query=$ENCODED_QUERY"
printf 'Searching %s\n' "$VAULT_NAME"
