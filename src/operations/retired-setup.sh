#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' \
  'The scripted setup runner and broad removal/reset commands are retired.' \
  'Choose AI-assisted or Manual setup: day-one-mac docs open' \
  'Migration: docs/shared/migration/from-scripted-setup.md' \
  'Existing settings, installed software and recovery records are unchanged.' >&2
exit 2
