#!/usr/bin/env bash
# Metadata-only AI artifacts. Never evaluate manifests or read token values.
# Caller supplies die, safe_path, tree_hashes and canonical SELECTION.
day_one_mcp_selection() {
  local input="$1" row client name scope url token extra seen='' key
  [[ -f "$input" && -r "$input" ]] && safe_path "$input" || die 'Provide a readable, non-symlink MCP manifest.'
  while IFS= read -r row || [[ -n "$row" ]]; do
    [[ -n "$row" && "$row" != \#* ]] || continue
    [[ "$row" != *$'\r'* && "$row" != $'\t'* && "$row" != *$'\t\t'* && "$row" != *$'\t' ]] || die 'MCP manifest needs five nonempty TSV fields.'
    IFS=$'\t' read -r client name scope url token extra <<< "$row"
    [[ -z "$extra" && -n "$token" ]] || die 'MCP manifest needs five fields.'
    [[ "$client" =~ ^(claude|codex|vscode)$ && "$name" =~ ^[a-z][a-z0-9_-]{0,63}$ && "$scope" == workspace ]] || die 'Use a supported client, plain server name and workspace scope.'
    [[ "$url" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[0-9]{1,5})?(/[A-Za-z0-9._~/-]*)?$ && "$url" != *..* ]] || die 'Use a token-free HTTPS URL without credentials, query, fragment or escapes.'
    [[ "$token" == - || "$token" =~ ^DAY_ONE_MCP_[A-Z][A-Z0-9_]*$ ]] || die 'Use - or a dedicated DAY_ONE_MCP_ token variable name, never its value.'
    key="$client/$name"
    ! grep -Fxq "$key" <<< "$seen" || die 'Duplicate client/server entry.'
    seen="${seen:+$seen$'\n'}$key"
    printf '%s\t%s\t%s\t%s\t%s\n' "$client" "$name" "$scope" "$url" "$token"
  done < "$input"
  [[ -n "$seen" ]] || die 'MCP manifest is empty.'
}

day_one_mcp_render() {
  local wanted="$1" client name scope url token separator=''
  if [[ "$wanted" == claude ]]; then printf '{"mcpServers":{'
  elif [[ "$wanted" == vscode ]]; then printf '{"servers":{'; fi
  while IFS=$'\t' read -r client name scope url token; do
    [[ "$client" == "$wanted" ]] || continue
    if [[ "$client" == codex ]]; then
      printf '[mcp_servers.%s]\nurl = "%s"\nenabled = false\n' "$name" "$url"
      [[ "$token" == - ]] || printf 'bearer_token_env_var = "%s"\n' "$token"
      printf '\n'
    else
      printf '%s"%s":{"type":"http","url":"%s"' "$separator" "$name" "$url"
      if [[ "$token" != - ]]; then
        if [[ "$client" == claude ]]; then
          printf ',"headers":{"Authorization":"Bearer ${%s}"}' "$token"
        else
          printf ',"headers":{"Authorization":"Bearer ${env:%s}"}' "$token"
        fi
      fi
      printf '}'; separator=,
    fi
  done <<< "$SELECTION"
  [[ "$wanted" == codex ]] || printf '}}\n'
}

day_one_governance_selection() {
  local input="$1" row kind name owner path extra seen=''
  [[ -f "$input" && -r "$input" ]] && safe_path "$input" || die 'Provide a readable governance manifest.'
  while IFS= read -r row || [[ -n "$row" ]]; do
    [[ -n "$row" && "$row" != \#* ]] || continue
    [[ "$row" != *$'\r'* && "$row" != $'\t'* && "$row" != *$'\t\t'* && "$row" != *$'\t' ]] || die 'Governance manifest needs four nonempty TSV fields.'
    IFS=$'\t' read -r kind name owner path extra <<< "$row"
    [[ -z "$extra" && "$kind" =~ ^(skill|mcp)$ && "$name" =~ ^[a-z][a-z0-9_-]{0,63}$ && "$owner" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || die 'Invalid governance kind, name or owner label.'
    [[ "$path" == /* && "$path" != / && "$path" != "$HOME" && "$path" != */ && "$path" != *//* && "$path" != */../* && "$path" != */./* && "$path" != */.. && "$path" != */. ]] || die 'Use a narrow absolute path without dot components.'
    ! grep -Fxq "$kind/$name" <<< "$seen" || die 'Duplicate governance name.'
    seen="${seen:+$seen$'\n'}$kind/$name"
    printf '%s\t%s\t%s\t%s\n' "$kind" "$name" "$owner" "$path"
  done < "$input"
  [[ -n "$seen" ]] || die 'Governance manifest is empty.'
}

day_one_governance_evidence() {
  local kind name owner path content hash result
  while IFS=$'\t' read -r kind name owner path; do
    result=FAIL; hash=unavailable; content=''
    if [[ "$kind" == skill ]]; then
      if [[ -f "$path/SKILL.md" ]] && content="$(tree_hashes "$path")"; then result=PASS; fi
    elif content="$(day_one_mcp_selection "$path")"; then result=PASS
    fi
    if [[ "$result" == PASS ]]; then
      if ! hash="$(printf '%s\n' "$content" | shasum -a 256 | awk '{print $1}')" \
          || [[ ! "$hash" =~ ^[a-f0-9]{64}$ ]]; then
        result=FAIL; hash=unavailable
      fi
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$name" "$owner" "$result" "$hash"
  done <<< "$SELECTION"
}
