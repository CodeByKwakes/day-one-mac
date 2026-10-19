#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Capture to Second Brain
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "Capture without classifying" }

# Optional parameters:
# @raycast.icon ✍️
# @raycast.packageName Second Brain
# @raycast.description Append one timestamped line to 00 Inbox/Quick capture

set -euo pipefail

CONFIG_FILE="${SECOND_BRAIN_CONFIG:-$HOME/.config/second-brain/config}"
if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

VAULT_NAME="${SECOND_BRAIN_VAULT_NAME:-Second Brain}"
CAPTURE="${1:-}"

if [[ -z "$CAPTURE" ]]; then
  printf 'Enter something to capture.\n' >&2
  exit 2
fi

urlencode() {
  /usr/bin/osascript -l JavaScript \
    -e 'function run(argv) { return encodeURIComponent(argv[0]); }' "$1"
}

STAMP="$(date '+%Y-%m-%d %H:%M')"
LINE="$(printf '\n- %s — %s' "$STAMP" "$CAPTURE")"
ENCODED_VAULT="$(urlencode "$VAULT_NAME")"
ENCODED_FILE="$(urlencode '00 Inbox/Quick capture')"
ENCODED_LINE="$(urlencode "$LINE")"

/usr/bin/open "obsidian://new?vault=$ENCODED_VAULT&file=$ENCODED_FILE&append=true&silent=true&content=$ENCODED_LINE"
printf 'Captured to %s\n' "$VAULT_NAME"
