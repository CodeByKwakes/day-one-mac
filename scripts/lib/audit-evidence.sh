#!/usr/bin/env bash
# Bounded, write-free evidence: never evaluate a Brewfile or launch account clients.
# Caller supplies SCRIPT_DIR, PROJECT_DIR, STATE_ROOT, STATE_DIR and safe_path.
day_one_audit_evidence() {
  local phase file id guide expected recorded output status selection digest
  printf 'gate\tresult\tevidence\n'
  if "$SCRIPT_DIR/verify.sh" >/dev/null 2>&1; then
    if [[ -s "$PROJECT_DIR/SHA256SUMS" ]]; then
      printf 'runtime\tPASS\tpackaged checksums and entry points verified\n'
    else
      printf 'runtime\tPASS\tdevelopment entry points only; no release integrity claim\n'
    fi
  else printf 'runtime\tFAIL\truntime verification failed\n'
  fi
  for phase in 01 02 03 04 05 06 07 08; do
    file="$STATE_DIR/completed/$phase"
    if [[ -f "$file" && -s "$file" ]] && safe_path "$file"; then
      if digest="$(shasum -a 256 "$file" | awk '{print $1}')"; then
        printf 'phase-%s-record\tPASS\t%s\n' "$phase" "$digest"
      else printf 'phase-%s-record\tFAIL\tunreadable completion record\n' "$phase"
      fi
    else printf 'phase-%s-record\tFAIL\tmissing or unsafe completion record\n' "$phase"
    fi
  done
  # Hash only explicit, non-secret setup records. No directory-wide credential scan.
  for file in track stack preset auth-mode primary-ide optional-modules database-services \
      optional-cli-packages software-10-clients software-16.tsv install-manifest.tsv \
      artifact-11-selection.tsv artifact-12-selection.tsv artifact-14-selection.tsv \
      artifact-22-selection.tsv omniroute-selection.tsv artifact-15-selection.tsv \
      artifact-17-selection.tsv artifact-18-selection.tsv preferences-19-selection.tsv restore-20-selection.tsv; do
    if ! safe_path "$STATE_DIR/$file" || [[ -e "$STATE_DIR/$file" && ! -f "$STATE_DIR/$file" ]]; then
      printf 'selection-%s\tFAIL\tunsafe record\n' "$file"
    elif [[ -f "$STATE_DIR/$file" ]]; then
      if digest="$(shasum -a 256 "$STATE_DIR/$file" | awk '{print $1}')"; then
        printf 'selection-%s\tPASS\t%s\n' "$file" "$digest"
      else printf 'selection-%s\tFAIL\tunreadable selection record\n' "$file"
      fi
    else printf 'selection-%s\tINFO\tnot recorded\n' "$file"
    fi
  done
  for id in 09 10 10A 11 12 13 14 15 16 17 18 19 20 22; do
    case "$id" in
      09) selection=database-services ;;
      10) selection=software-10-clients
          [[ -s "$STATE_DIR/$selection" ]] || selection=ai-clients ;;
      10A) selection=omniroute-selection.tsv ;;
      11|12|14|15|17|18|22) selection="artifact-$id-selection.tsv" ;;
      19) selection=preferences-19-selection.tsv ;;
      20) selection=restore-20-selection.tsv ;;
      13) selection=optional-cli-packages ;;
      16) selection=software-16.tsv ;;
    esac
    if ! safe_path "$STATE_DIR/$selection" || [[ -e "$STATE_DIR/$selection" && ! -f "$STATE_DIR/$selection" ]]; then
      printf 'module-%s\tFAIL\tunsafe selection record\n' "$id"
      continue
    fi
    if [[ ! -s "$STATE_DIR/$selection" ]]; then
      printf 'module-%s\tINFO\tno executable selection recorded\n' "$id"
      continue
    fi
    status=PASS
    output="$("$SCRIPT_DIR/optional-module.sh" --module "$id" --check 2>&1)" || status=FAIL
    # Preserve a change detector, not private command output or auth-adjacent paths.
    printf 'module-%s\t%s\t%s\n' "$id" "$status" "$(printf '%s' "$output" | shasum -a 256 | awk '{print $1}')"
  done
  while IFS=$'\t' read -r id _layer _mode _prerequisite _title guide; do
    [[ "$id" =~ ^(15|16|17|18|19|20|22)$ ]] || continue
    file="$STATE_ROOT/advanced/completed/$id"
    [[ -e "$file" || -L "$file" ]] || continue
    if [[ ! -f "$file" ]] || ! safe_path "$file"; then
      printf 'guide-%s\tFAIL\tunsafe completion record\n' "$id"; continue
    fi
    if ! expected="$(shasum -a 256 "$PROJECT_DIR/$guide" | awk '{print $1}')" \
        || ! recorded="$(sed -n '1p' "$file")"; then
      printf 'guide-%s\tFAIL\tunreadable guide or completion record\n' "$id"; continue
    fi
    if [[ "$recorded" == "$expected" ]]; then status=PASS; else status=FAIL; fi
    printf 'guide-%s\t%s\t%s\n' "$id" "$status" "$expected"
  done < "$PROJECT_DIR/config/modules.tsv"
}
