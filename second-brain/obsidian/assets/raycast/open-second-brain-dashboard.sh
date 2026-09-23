#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Second Brain Dashboard
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📊
# @raycast.packageName Second Brain
# @raycast.description Open the unified Obsidian dashboard

set -euo pipefail

CONFIG_FILE="${SECOND_BRAIN_CONFIG:-$HOME/.config/second-brain/config}"
if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

VAULT_NAME="${SECOND_BRAIN_VAULT_NAME:-Second Brain}"

urlencode() {
  /usr/bin/osascript -l JavaScript \
    -e 'function run(argv) { return encodeURIComponent(argv[0]); }' "$1"
}

ENCODED_VAULT="$(urlencode "$VAULT_NAME")"
ENCODED_FILE="$(urlencode '01 Dashboards/Second Brain HQ')"
/usr/bin/open "obsidian://open?vault=$ENCODED_VAULT&file=$ENCODED_FILE"
printf 'Opening %s dashboard\n' "$VAULT_NAME"
