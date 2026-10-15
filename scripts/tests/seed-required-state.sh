#!/usr/bin/env bash
# Test fixtures only. Never run against a real onboarding state directory.
set -euo pipefail
fixture_state="${1:?temporary state required}"
fixture_scripts="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
case "$fixture_state" in /tmp/*|/private/tmp/*) ;; *) printf 'Fixture state must be below the temporary directory.\n' >&2; exit 2 ;; esac
export DAY_ONE_MAC_STATE_ROOT="$fixture_state" DAY_ONE_MAC_STATE_DIR="$fixture_state"
source "$fixture_scripts/setup.sh"
mkdir -p "$COMPLETED_DIR"
for record in 'track:4' 'track-schema-version:2' 'stack:python' 'preset:core' 'primary-ide:other' \
  'auth-mode:https' 'dotfiles-versioning:none' 'shell-choice:apple' 'prompt-choice:none' \
  'configuration-schema:1' 'folder-layout:none' 'ghq-choice:no' 'deployment-mode:personal'; do
  [[ -e "$STATE_DIR/${record%%:*}" ]] || printf '%s\n' "${record#*:}" > "$STATE_DIR/${record%%:*}"
done
required_load_recorded_choices
for phase in 01 02 03 04 05 06 07 08; do phase_fingerprint "$phase" > "$COMPLETED_DIR/$phase"; done
