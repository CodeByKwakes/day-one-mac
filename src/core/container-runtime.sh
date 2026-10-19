#!/usr/bin/env bash
# Locate bundled CLIs without installing a second engine or switching contexts.

day_one_container_cli_path() {
  local directory
  for directory in "${DAY_ONE_MAC_ORBSTACK_CLI_DIR:-$HOME/.orbstack/bin}" \
    "$HOME/.docker/bin" \
    "${DAY_ONE_MAC_APPLICATIONS_ROOT:-/Applications}/Docker.app/Contents/Resources/bin" \
    "$HOME/Applications/Docker.app/Contents/Resources/bin"; do
    if ! command -v docker >/dev/null 2>&1 && [[ -x "$directory/docker" ]]; then
      export PATH="$directory:$PATH"
    fi
  done
  hash -r 2>/dev/null || true
}
