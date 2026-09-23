#!/usr/bin/env bash
# managed-by: second-brain
set -euo pipefail

MANIFEST="${SECOND_BRAIN_LAYOUT:-$HOME/.config/second-brain/layout.tsv}"
if [[ -z "${SECOND_BRAIN_LAYOUT:-}" && ! -r "$MANIFEST" \
   && -r "$HOME/.config/fresh-start-second-brain/layout.tsv" ]]; then
  MANIFEST="$HOME/.config/fresh-start-second-brain/layout.tsv"
fi
[[ -r "$MANIFEST" ]] || { printf 'Second Brain layout not found: %s\n' "$MANIFEST" >&2; exit 1; }

vault_slugs=()
vault_names=()
vault_paths=()
while IFS=$'\t' read -r kind slug name path sensitivity tools dashboard; do
  [[ "$kind" == vault ]] || continue
  case ",$tools," in
    *,codex,*)
      vault_slugs[${#vault_slugs[@]}]="$slug"
      vault_names[${#vault_names[@]}]="$name"
      vault_paths[${#vault_paths[@]}]="$path"
      ;;
  esac
done < "$MANIFEST"

[[ "${#vault_slugs[@]}" -gt 0 ]] || { printf 'No configured vault enables Codex.\n' >&2; exit 1; }

requested="${1:-}"
if [[ "$requested" == --help || "$requested" == -h ]]; then
  printf '%s\n' 'Usage: second-brain-codex [vault-slug] [codex options]' '' 'Without a slug, an interactive vault selector is shown.'
  exit 0
fi

selected=-1
if [[ -n "$requested" ]]; then
  for ((i=0; i<${#vault_slugs[@]}; i++)); do
    [[ "${vault_slugs[$i]}" == "$requested" ]] && selected="$i"
  done
  [[ "$selected" -ge 0 ]] || { printf 'Codex is not enabled for vault slug: %s\n' "$requested" >&2; exit 2; }
  shift
elif [[ "${#vault_slugs[@]}" == 1 ]]; then
  selected=0
else
  [[ -t 0 ]] || { printf 'Choose a vault slug when stdin is not interactive.\n' >&2; exit 2; }
  printf 'Choose the one vault Codex may open:\n' >&2
  for ((i=0; i<${#vault_names[@]}; i++)); do
    printf '  %s) %s [%s]\n' "$((i + 1))" "${vault_names[$i]}" "${vault_slugs[$i]}" >&2
  done
  printf '> ' >&2
  IFS= read -r choice
  case "$choice" in ''|*[!0-9]*) printf 'Invalid selection.\n' >&2; exit 2 ;; esac
  selected=$((choice - 1))
  [[ "$selected" -ge 0 && "$selected" -lt "${#vault_slugs[@]}" ]] || { printf 'Invalid selection.\n' >&2; exit 2; }
fi

vault_path="${vault_paths[$selected]}"
[[ -d "$vault_path" ]] || { printf 'Vault not found: %s\n' "$vault_path" >&2; exit 1; }
[[ -r "$vault_path/AGENTS.md" ]] || { printf 'AGENTS.md missing: %s\n' "$vault_path" >&2; exit 1; }
command -v codex >/dev/null 2>&1 || { printf 'codex is not installed.\n' >&2; exit 127; }

printf 'Opening only: %s\n' "$vault_path" >&2
exec codex --cd "$vault_path" --sandbox workspace-write --ask-for-approval on-request "$@"
