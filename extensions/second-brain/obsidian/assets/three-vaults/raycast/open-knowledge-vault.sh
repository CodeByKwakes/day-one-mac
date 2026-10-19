#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Knowledge Vault
# @raycast.mode silent
# @raycast.argument1 { "type": "dropdown", "placeholder": "Vault", "data": [{"title":"Software Development","value":"development"},{"title":"Software Content","value":"software-content"},{"title":"Tech Content","value":"tech-content"}] }

# Optional parameters:
# @raycast.icon 🗂️
# @raycast.packageName Second Brain — Three Vaults
# @raycast.description Open the selected Obsidian vault dashboard

set -euo pipefail

CONFIG_FILE="${SECOND_BRAIN_THREE_CONFIG:-$HOME/.config/second-brain/multi-vaults.conf}"
if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

target="${1:-}"
case "$target" in
  development)
    vault="${DEVELOPMENT_VAULT_NAME:-Software Development}"
    dashboard='01 Dashboard/Development Dashboard'
    ;;
  software-content)
    vault="${SOFTWARE_CONTENT_VAULT_NAME:-Software Content}"
    dashboard='01 Dashboard/Software Content Dashboard'
    ;;
  tech-content)
    vault="${TECH_CONTENT_VAULT_NAME:-Tech Content}"
    dashboard='01 Dashboard/Tech Content Dashboard'
    ;;
  *) printf 'Choose a valid vault.\n' >&2; exit 2 ;;
esac

urlencode() {
  /usr/bin/osascript -l JavaScript \
    -e 'function run(argv) { return encodeURIComponent(argv[0]); }' "$1"
}

/usr/bin/open "obsidian://open?vault=$(urlencode "$vault")&file=$(urlencode "$dashboard")"
printf 'Opening %s\n' "$vault"
