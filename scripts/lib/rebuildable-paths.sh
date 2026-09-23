#!/usr/bin/env bash
# Shared path catalogue for large local tool downloads and caches.
# These paths can be recreated from package manifests and the inventories
# written by clean-development-state.sh. They are excluded from the portable
# Step 3 snapshot unless the user explicitly includes them. Route B cleanup
# still moves them into its dated recovery archive instead of deleting them.

DAY_ONE_REBUILDABLE_DEV_PATHS=(
  "$HOME/.local/share/fnm"
  "$HOME/.local/state/fnm_multishells"
  "$HOME/.local/share/uv"
  "$HOME/.local/share/virtualenvs"
  "$HOME/.npm"
  "$HOME/.node-gyp"
  "$HOME/.corepack"
  "$HOME/.pnpm-store"
  "$HOME/.cache/fnm"
  "$HOME/.cache/pnpm"
  "$HOME/.cache/uv"
  "$HOME/.cache/pip"
  "$HOME/.cache/pypoetry"
  "$HOME/Library/pnpm"
  "$HOME/.vscode"
  "$HOME/Library/Application Support/Code"
  "$HOME/Library/Caches/com.microsoft.VSCode"
)

# Copy only portable VS Code configuration. The full User directory also holds
# workspaceStorage, globalStorage, History, logs, and extension caches that can
# contain hundreds of thousands of rebuildable files.
DAY_ONE_PORTABLE_VSCODE_PATHS=(
  "$HOME/.vscode/argv.json"
  "$HOME/Library/Application Support/Code/User/settings.json"
  "$HOME/Library/Application Support/Code/User/keybindings.json"
  "$HOME/Library/Application Support/Code/User/tasks.json"
  "$HOME/Library/Application Support/Code/User/snippets"
  "$HOME/Library/Application Support/Code/User/profiles"
  "$HOME/Library/Application Support/Code/User/sync"
)
