#!/usr/bin/env bash
set -euo pipefail

printf 'homebrew-uninstaller\t%s\n' "$(pwd -P)" \
  >> "${DAY_ONE_TEST_BREW_LOG:?DAY_ONE_TEST_BREW_LOG is required}"
