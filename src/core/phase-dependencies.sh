#!/usr/bin/env bash
# Explicit implementation dependencies; optional helper changes stay optional.
day_one_phase_implementation_hash() {
  local root="$1" phase="$2" relative entries digest hashes parent catalog
  local files=()
  [[ "$phase" =~ ^0[1-8]$ ]] || return 2
  for catalog in phases.tsv phase-dependencies.tsv; do
    [[ -f "$root/config/catalogs/$catalog" && ! -L "$root/config/catalogs/$catalog" ]] || {
      printf 'Missing or unsafe phase catalogue: %s\n' "$catalog" >&2; return 1; }
  done
  # Validate the complete schema before selecting a phase. A malformed row must
  # never silently remove an implementation from the completion fingerprint.
  entries="$(awk -F '\t' -v phase="$phase" '
    function safe(path) {
      return path ~ /^[A-Za-z0-9_+.\/-]+$/ && path !~ /^\// && path !~ /\/\// && path !~ /(^|\/)\.\.?($|\/)/
    }
    /^[[:space:]]*$/ || /^#/ {next}
    FNR == NR {
      if (NF != 4 || $1 !~ /^0[1-8]$/ || $2 == "" || !safe($3) || !safe($4) || phases[$1]++) invalid=1
      implementation[$1]=$4
      next
    }
    {
      if (NF != 2 || ($1 != "*" && $1 !~ /^0[1-8]$/) || !safe($2) || seen[$1 SUBSEP $2]++) invalid=1
      if ($1 != "*" && $2 == implementation[$1]) covered[$1]=1
      if ($1 == "*" || $1 == phase) selected[++count]=$2
    }
    END {
      for (i=1; i<=8; i++) {
        id=sprintf("%02d", i)
        if (phases[id] != 1 || !covered[id]) invalid=1
      }
      if (invalid || !count) exit 1
      for (i=1; i<=count; i++) print selected[i]
    }
  ' "$root/config/catalogs/phases.tsv" "$root/config/catalogs/phase-dependencies.tsv")" || {
    printf 'Invalid or incomplete phase dependency catalogues.\n' >&2; return 1; }
  while IFS= read -r relative; do
    [[ -f "$root/$relative" ]] || {
      printf 'Missing phase dependency: %s\n' "$relative" >&2; return 1; }
    parent="$relative"
    while [[ "$parent" != . ]]; do
      [[ ! -L "$root/$parent" ]] || { printf 'Unsafe phase dependency: %s\n' "$relative" >&2; return 1; }
      case "$parent" in */*) parent="${parent%/*}" ;; *) parent=. ;; esac
    done
    files+=("$root/$relative")
  done <<< "$entries"
  # Check the reader itself before hashing its output: a failed shasum must not
  # be hidden by a successful final pipeline stage when sourced by a caller.
  hashes="$(shasum -a 256 "${files[@]}")" || return 1
  digest="$(printf '%s\n' "$hashes" | awk '{print $1}' | shasum -a 256 | awk '{print $1}')" || return 1
  printf '%s\n' "$digest"
}
