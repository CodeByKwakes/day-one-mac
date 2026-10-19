#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${SECOND_BRAIN_THREE_CONFIG:-$HOME/.config/second-brain/multi-vaults.conf}"
if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

usage() {
  printf '%s\n' \
    'Usage: second-brain-codex-three development|software-content|tech-content [codex options]' \
    '' \
    'Starts Codex with only the selected physical vault as its working directory.'
}

target="${1:-}"
[[ "$#" -gt 0 ]] && shift
case "$target" in
  development) vault_path="${DEVELOPMENT_VAULT_PATH:-$HOME/Vaults/Software Development}" ;;
  software-content) vault_path="${SOFTWARE_CONTENT_VAULT_PATH:-$HOME/Vaults/Software Content}" ;;
  tech-content) vault_path="${TECH_CONTENT_VAULT_PATH:-$HOME/Vaults/Tech Content}" ;;
  --help|-h|'') usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

[[ -d "$vault_path" ]] || { printf 'Vault not found: %s\n' "$vault_path" >&2; exit 1; }
[[ -r "$vault_path/AGENTS.md" ]] || { printf 'AGENTS.md missing: %s\n' "$vault_path" >&2; exit 1; }
command -v codex >/dev/null 2>&1 || { printf 'codex is not installed.\n' >&2; exit 127; }

exec codex --cd "$vault_path" \
  --sandbox workspace-write \
  --ask-for-approval on-request \
  "$@"
