#!/usr/bin/env bash
# Canonical Docker Desktop and OrbStack data locations used by Stage 0.
# Keep this list in one file so the wizard's size estimate, backup snapshot,
# cleanup preview, and final cleanup always describe the same paths.

DAY_ONE_DOCKER_DATA_PATHS=(
  "$HOME/Library/Containers/com.docker.docker"
  "$HOME/Library/Group Containers/group.com.docker"
)

DAY_ONE_ORBSTACK_DATA_PATHS=(
  "$HOME/.orbstack"
  "$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack"
  "$HOME/Library/Caches/dev.kdrag0n.MacVirt"
  "$HOME/Library/HTTPStorages/dev.kdrag0n.MacVirt"
  "$HOME/Library/Preferences/dev.kdrag0n.MacVirt.plist"
  "$HOME/Library/Saved Application State/dev.kdrag0n.MacVirt.savedState"
  "$HOME/Library/WebKit/dev.kdrag0n.MacVirt"
)
