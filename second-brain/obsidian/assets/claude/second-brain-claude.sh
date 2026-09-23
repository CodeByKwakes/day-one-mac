#!/bin/bash
set -euo pipefail

CONFIG_FILE="${SECOND_BRAIN_CONFIG:-$HOME/.config/second-brain/config}"
if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

VAULT_PATH="${SECOND_BRAIN_VAULT_PATH:-$HOME/Vaults/Second Brain}"

if [[ ! -d "$VAULT_PATH" ]]; then
  printf 'Second Brain vault not found: %s\n' "$VAULT_PATH" >&2
  printf 'Update %s or run the setup helper.\n' "$CONFIG_FILE" >&2
  exit 1
fi

if [[ ! -f "$VAULT_PATH/CLAUDE.md" ]]; then
  printf 'Safety instructions are missing: %s/CLAUDE.md\n' "$VAULT_PATH" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  printf 'Claude Code is not installed or not on PATH.\n' >&2
  exit 127
fi

cd "$VAULT_PATH"
exec claude --permission-mode plan "$@"
