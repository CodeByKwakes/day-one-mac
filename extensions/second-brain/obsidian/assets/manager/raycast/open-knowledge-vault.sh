#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Knowledge Vault
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🗂️
# @raycast.packageName Second Brain
# @raycast.description Choose a configured vault and open its dashboard

# managed-by: second-brain
set -euo pipefail

MANIFEST="${SECOND_BRAIN_LAYOUT:-$HOME/.config/second-brain/layout.tsv}"
if [[ -z "${SECOND_BRAIN_LAYOUT:-}" && ! -r "$MANIFEST" \
   && -r "$HOME/.config/fresh-start-second-brain/layout.tsv" ]]; then
  MANIFEST="$HOME/.config/fresh-start-second-brain/layout.tsv"
fi
[[ -r "$MANIFEST" ]] || { printf 'Layout not found: %s\n' "$MANIFEST" >&2; exit 1; }

names=()
paths=()
dashboards=()
while IFS=$'\t' read -r kind slug name path sensitivity tools dashboard; do
  [[ "$kind" == vault ]] || continue
  case ",$tools," in
    *,raycast,*)
      names[${#names[@]}]="$name"
      paths[${#paths[@]}]="$path"
      dashboards[${#dashboards[@]}]="$dashboard/Vault Dashboard"
      ;;
  esac
done < "$MANIFEST"
[[ "${#names[@]}" -gt 0 ]] || { printf 'No configured vault enables Raycast.\n' >&2; exit 1; }

if [[ "${#names[@]}" == 1 ]]; then
  choice="${names[0]}"
else
  choice="$(/usr/bin/osascript -l JavaScript \
    -e 'function run(argv) { var app=Application.currentApplication(); app.includeStandardAdditions=true; var answer=app.chooseFromList(argv,{withPrompt:"Choose a knowledge vault",defaultItems:[argv[0]]}); return answer ? answer[0] : ""; }' \
    "${names[@]}")"
fi
[[ -n "$choice" ]] || exit 0

selected=-1
for ((i=0; i<${#names[@]}; i++)); do [[ "${names[$i]}" == "$choice" ]] && selected="$i"; done
[[ "$selected" -ge 0 ]] || { printf 'Selected vault is no longer configured.\n' >&2; exit 1; }

urlencode() { /usr/bin/osascript -l JavaScript -e 'function run(argv) { return encodeURIComponent(argv[0]); }' "$1"; }
/usr/bin/open "obsidian://open?vault=$(urlencode "${names[$selected]}")&file=$(urlencode "${dashboards[$selected]}")"
printf 'Opening %s\n' "${names[$selected]}"
