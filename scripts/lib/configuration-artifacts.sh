#!/usr/bin/env bash
# Caller supplies die, safe_path, SELECTION, PROJECT_DIR and HOME.
day_one_dotfile_target() {
  case "$1" in
    gitignore) printf '.gitignore_global\tdot_gitignore_global\n' ;;
    starship) printf '.config/starship.toml\tdot_config/starship.toml\n' ;;
    aliases) printf '.config/zsh/aliases.zsh\tdot_config/zsh/aliases.zsh\n' ;;
    pnpm-defaults) printf '.config/pnpm/rc\tdot_config/pnpm/rc\n' ;;
    *) return 1 ;;
  esac
}
day_one_configuration_selection() {
  local input="$1" row kind value source extra seen='' target source_suffix
  [[ -f "$input" && -r "$input" ]] && safe_path "$input" || die 'Provide a readable, non-symlink configuration manifest.'
  while IFS= read -r row || [[ -n "$row" ]]; do
    [[ -n "$row" && "$row" != \#* ]] || continue
    [[ "$row" != $'\t'* && "$row" != *$'\t' && "$row" != *$'\t\t'* && "$row" != *$'\r'* ]] || die 'Use nonempty tab-separated fields.'
    IFS=$'\t' read -r kind value source extra <<< "$row"
    [[ -z "$extra" ]] || die 'Too many manifest fields.'
    if [[ "$MODULE" == 15 ]]; then
      target="$(day_one_dotfile_target "$kind")" || die 'Unknown dotfile target; credentials and arbitrary paths are not supported.'
      source_suffix="${target#*$'\t'}"
      [[ "$value" =~ ^(chezmoi|manual|unmanaged)$ && -n "$source" ]] || die 'Specify target, declared owner and source path or -.'
      if [[ "$value" == chezmoi ]]; then
        [[ "$source" == /* && ( "$source" == */"$source_suffix" || "$source" == */"$source_suffix".tmpl ) && "$source" != *'/../'* && "$source" != *'/./'* && "$source" != *//* ]] || die 'Use the absolute canonical chezmoi source file matching the target.'
      else [[ "$source" == - ]] || die 'Manual/unmanaged targets must use - for their source.'; fi
      ! grep -Fxq "$kind" <<< "$seen" || die 'Duplicate dotfile target.'
      seen="${seen:+$seen$'\n'}$kind"
      printf '%s\t%s\t%s\n' "$kind" "$value" "$source"
    else
      [[ -z "$source" && -n "$value" ]] || die 'Module 17 needs exactly two fields.'
      case "$kind" in
        helper) [[ "$value" == navigation || "$value" == packages ]] || die 'Choose navigation or packages helpers.' ;;
        project) [[ "$value" == /* && "$value" != / && "$value" != "$HOME" && "$value" != *'/../'* && "$value" != *'/./'* && "$value" != */.. && "$value" != */. && "$value" != *//* ]] || die 'Use an explicit absolute project directory.' ;;
        *) die 'Module 17 accepts helper and project rows only.' ;;
      esac
      ! grep -Fxq "$row" <<< "$seen" || die 'Duplicate helper/project row.'
      seen="${seen:+$seen$'\n'}$row"
      printf '%s\t%s\n' "$kind" "$value"
    fi
  done < "$input"
  [[ -n "$seen" ]] || die 'Empty configuration manifest.'
  if [[ "$MODULE" == 17 ]]; then
    grep -q $'^helper\t' <<< "$seen" || die 'Select at least one helper.'
    if grep -q $'^project\t' <<< "$seen"; then
      grep -Fxq $'helper\tpackages' <<< "$seen" || die 'Project checks require the packages helper.'
    fi
  fi
}
day_one_file_digest() {
  local file="$1" hash
  [[ -f "$file" && -r "$file" ]] && safe_path "$file" || return 1
  [[ "${2:-}" != owned || -O "$file" ]] || return 1
  hash="$(shasum -a 256 "$file")" || return 1
  hash="${hash%% *}"
  [[ "$hash" =~ ^[a-f0-9]{64}$ ]] || return 1
  printf '%s' "$hash"
}
day_one_configuration_evidence() {
  local kind value source target target_hash source_hash result output
  while IFS=$'\t' read -r kind value source; do
    result=PASS; source_hash=-; target_hash=unavailable
    if [[ "$MODULE" == 15 ]]; then
      target="$(day_one_dotfile_target "$kind")" || return 1
      target="$HOME/${target%%$'\t'*}"
      target_hash="$(day_one_file_digest "$target" owned)" || { result=FAIL; target_hash=unavailable; }
      if [[ "$value" == chezmoi ]]; then
        source_hash="$(day_one_file_digest "$source" owned)" || { result=FAIL; source_hash=unavailable; }
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$kind" "$value" "$result" "$target_hash" "$source_hash" "$target"
    elif [[ "$kind" == helper ]]; then
      target="$PROJECT_DIR/config/shell-helpers/$value.zsh"
      target_hash="$(day_one_file_digest "$target")" || { result=FAIL; target_hash=unavailable; }
      printf 'helper\t%s\t%s\t%s\n' "$value" "$result" "$target_hash"
    else
      output=unavailable
      if [[ -d "$value" ]] && safe_path "$value" \
          && day_one_file_digest "$PROJECT_DIR/config/shell-helpers/packages.zsh" >/dev/null \
          && output="$(ZDOTDIR=/dev/null zsh -dfc 'source "$1"; builtin cd -- "$2"; day_one_pm_for_dir' _ "$PROJECT_DIR/config/shell-helpers/packages.zsh" "$value" 2>&1)"; then
        [[ "$output" == npm || "$output" == pnpm ]] || result=FAIL
      else
        result=FAIL
        output="$(printf '%s\n' "$output" | tr '\t\r' ' ' | sed -n '1p')"
        [[ -n "$output" && "$output" != unavailable ]] || output=unsafe-project-or-helper-path
      fi
      printf 'project\t%s\t%s\t%s\n' "$value" "$result" "$output"
    fi
  done <<< "$SELECTION"
}
day_one_configuration_outputs() {
  local kind value source relative action
  if [[ "$MODULE" == 15 ]]; then
    while IFS=$'\t' read -r kind value source; do
      relative="$(day_one_dotfile_target "$kind")"; relative="${relative%%$'\t'*}"
      case "$value" in
        chezmoi) action=review-existing-source ;;
        manual) action=keep-current-owner ;;
        unmanaged) action=review-before-add ;;
      esac
      printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$value" "$HOME/$relative" "$source" "$action"
    done <<< "$SELECTION" > "$ARTIFACT/import-proposal.tsv"
  else
    while IFS=$'\t' read -r kind value; do
      [[ "$kind" == helper ]] || continue
      cp "$PROJECT_DIR/config/shell-helpers/$value.zsh" "$ARTIFACT/$value.zsh"
      ZDOTDIR=/dev/null zsh -dfn "$ARTIFACT/$value.zsh" || return 1
    done <<< "$SELECTION"
  fi
  [[ "$(day_one_configuration_evidence)" == "$EVIDENCE" ]] || die 'Configuration evidence changed during generation.' 1
}
