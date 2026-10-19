#!/usr/bin/env bash
# Required-phase metadata is shared by setup, documentation and navigation.
day_one_phase_field() {
  local phase="$1" field="$2" root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || return 1
  awk -F '\t' -v phase="$phase" -v field="$field" '
    $1 == phase { print $field; found=1; exit }
    END { if (!found) exit 1 }
  ' "$root/config/catalogs/phases.tsv"
}
phase_doc() {
  local relative
  relative="$(day_one_phase_field "$1" 3)" || return 1
  printf '%s/%s\n' "${DOC_DIR%/docs}" "$relative"
}
phase_title() { day_one_phase_field "$1" 2; }
