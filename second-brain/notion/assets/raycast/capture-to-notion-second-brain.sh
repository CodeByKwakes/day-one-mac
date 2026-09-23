#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Capture to Notion Second Brain
# @raycast.mode silent
# @raycast.packageName Notion Second Brain
# @raycast.icon ✍️

set -euo pipefail

CONFIG="${SECOND_BRAIN_NOTION_CONFIG:-$HOME/.config/second-brain-notion/config}"
if [[ ! -r "$CONFIG" ]]; then
  printf 'Notion Second Brain is not configured. Run the local planner first.\n' >&2
  exit 1
fi

URL="$(awk -F '\t' '$1 == "capture_url" {sub(/^[^\t]*\t/, ""); print; exit}' "$CONFIG")"
if [[ -z "$URL" ]]; then
  printf 'Capture URL is missing. Create a private Notion form, then rerun the planner.\n' >&2
  exit 1
fi

open "$URL"
