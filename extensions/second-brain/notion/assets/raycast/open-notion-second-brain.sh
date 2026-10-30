#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Notion Second Brain
# @raycast.mode silent
# @raycast.packageName Notion Second Brain
# @raycast.icon 🧠

set -euo pipefail

CONFIG="${SECOND_BRAIN_NOTION_CONFIG:-$HOME/.config/second-brain-notion/config}"
if [[ ! -r "$CONFIG" ]]; then
  printf 'Notion Second Brain is not configured. Use the manual Raycast Quicklink recipe instead.\n' >&2
  exit 1
fi

URL="$(awk -F '\t' '$1 == "hq_url" {sub(/^[^\t]*\t/, ""); print; exit}' "$CONFIG")"
if [[ -z "$URL" ]]; then
  printf 'HQ URL is missing. Use the manual Raycast Quicklink recipe with your private HQ URL.\n' >&2
  exit 1
fi

open "$URL"
