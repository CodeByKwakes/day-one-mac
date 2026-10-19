#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Capture Knowledge Item
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "Capture without classifying" }

# Optional parameters:
# @raycast.icon ✍️
# @raycast.packageName Second Brain
# @raycast.description Choose a configured vault and append to its inbox

# managed-by: second-brain
set -euo pipefail

capture="${1:-}"
[[ -n "$capture" ]] || { printf 'Enter something to capture.\n' >&2; exit 2; }
MANIFEST="${SECOND_BRAIN_LAYOUT:-$HOME/.config/second-brain/layout.tsv}"
if [[ -z "${SECOND_BRAIN_LAYOUT:-}" && ! -r "$MANIFEST" \
   && -r "$HOME/.config/fresh-start-second-brain/layout.tsv" ]]; then
  MANIFEST="$HOME/.config/fresh-start-second-brain/layout.tsv"
fi
[[ -r "$MANIFEST" ]] || { printf 'Layout not found: %s\n' "$MANIFEST" >&2; exit 1; }

names=()
while IFS=$'\t' read -r kind slug name path sensitivity tools dashboard; do
  [[ "$kind" == vault ]] || continue
  case ",$tools," in *,raycast,*) names[${#names[@]}]="$name" ;; esac
done < "$MANIFEST"
[[ "${#names[@]}" -gt 0 ]] || { printf 'No configured vault enables Raycast.\n' >&2; exit 1; }

if [[ "${#names[@]}" == 1 ]]; then choice="${names[0]}"
else
  choice="$(/usr/bin/osascript -l JavaScript \
    -e 'function run(argv) { var app=Application.currentApplication(); app.includeStandardAdditions=true; var answer=app.chooseFromList(argv,{withPrompt:"Capture into which knowledge vault?",defaultItems:[argv[0]]}); return answer ? answer[0] : ""; }' \
    "${names[@]}")"
fi
[[ -n "$choice" ]] || exit 0
urlencode() { /usr/bin/osascript -l JavaScript -e 'function run(argv) { return encodeURIComponent(argv[0]); }' "$1"; }
line="$(printf '\n- %s — %s' "$(date '+%Y-%m-%d %H:%M')" "$capture")"
/usr/bin/open "obsidian://new?vault=$(urlencode "$choice")&file=$(urlencode '00 Inbox/Quick capture')&append=true&silent=true&content=$(urlencode "$line")"
printf 'Captured to %s\n' "$choice"
