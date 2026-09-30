#!/usr/bin/env bash
# Sourced phase implementation; shared runner context is supplied by setup.sh.

# Emit the managed ~/.ssh/config body for the selected authentication mode.
#
# IdentitiesOnly is written only next to an IdentityFile, in every mode. On its
# own it confines OpenSSH to the default ~/.ssh/id_* files and the configured
# agent is never consulted.
ssh_config_block() {
  local github_public="$HOME/.ssh/github-auth.pub"
  local azure_public="$HOME/.ssh/azure-devops-auth.pub"
  local agent_line='    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'
  printf '%s\n' '# >>> Day One Mac: SSH authentication >>>'
  printf '%s\n' "# Generated for auth mode '$AUTH_MODE' from the saved hosting track."
  if uses_github; then
    printf '%s\n' 'Host github.com'
    printf '%s\n' '    HostName github.com'
    printf '%s\n' '    User git'
    ssh_config_identity_lines "$AUTH_MODE" "$github_public" "$HOME/.ssh/id_ed25519" "$agent_line"
    printf '%s\n' '    ServerAliveInterval 60'
    printf '%s\n' '    ServerAliveCountMax 3'
  fi
  if uses_azure; then
    uses_github && printf '\n'
    printf '%s\n' 'Host ssh.dev.azure.com'
    printf '%s\n' '    HostName ssh.dev.azure.com'
    printf '%s\n' '    User git'
    ssh_config_identity_lines "$AUTH_MODE" "$azure_public" "$HOME/.ssh/id_rsa_azure" "$agent_line"
    printf '%s\n' '    ServerAliveInterval 60'
    printf '%s\n' '    ServerAliveCountMax 3'
  fi
  printf '%s\n' '# <<< Day One Mac: SSH authentication <<<'
}

# The identity half of one Host block, which is all that varies by mode.
ssh_config_identity_lines() {
  local mode="$1" public_pin="$2" keychain_key="$3" agent_line="$4"
  case "$mode" in
    1password)
      printf '%s\n' "$agent_line"
      if [[ -f "$public_pin" ]]; then
        printf '%s\n' "    IdentityFile ~/${public_pin#"$HOME"/}"
        printf '%s\n' '    IdentitiesOnly yes'
      fi
      ;;
    keychain)
      # Apple's ssh stores the passphrase in the login keychain, so the key is
      # usable without retyping it. ssh -G does not echo UseKeychain; that is a
      # display quirk, not a sign it was rejected.
      printf '%s\n' '    UseKeychain yes'
      printf '%s\n' '    AddKeysToAgent yes'
      printf '%s\n' "    IdentityFile ~/${keychain_key#"$HOME"/}"
      printf '%s\n' '    IdentitiesOnly yes'
      ;;
    external)
      # Whatever agent the user already runs answers; pin only if they asked.
      if [[ -f "$public_pin" ]]; then
        printf '%s\n' "    IdentityFile ~/${public_pin#"$HOME"/}"
        printf '%s\n' '    IdentitiesOnly yes'
      fi
      ;;
  esac
}

update_homebrew_1password_if_needed() {
  local token outdated=""
  [[ "$DRY_RUN" == 1 ]] && return 0
  load_brew || return 0
  for token in 1password 1password-cli; do
    brew list --cask "$token" >/dev/null 2>&1 || continue
    if brew outdated --quiet --cask --greedy "$token" 2>/dev/null | grep -Fqx "$token"; then
      outdated="$outdated${outdated:+ }$token"
    fi
  done
  [[ -n "$outdated" ]] || return 0
  warn "Homebrew reports an available update for: $outdated"
  confirm "Upgrade the Homebrew-managed 1Password components now?" || {
    warn "Update the listed casks through their current owner, then rerun the Installation Centre."
    return "$EX_MANUAL"
  }
  for token in $outdated; do run brew upgrade --cask "$token"; done
}

# Phase 5 puts ~/.ssh/config under chezmoi. When Phase 3 is rerun afterwards —
# which Step 3.7 explicitly asks for — it edits the target directly, leaving the
# chezmoi source stale. A later 'chezmoi apply' would then silently revert the
# provider blocks. Re-add the file so source and target stay in agreement.
resync_managed_ssh_config() {
  local ssh_config="$1"
  command -v chezmoi >/dev/null 2>&1 || return 0
  chezmoi source-path "$ssh_config" >/dev/null 2>&1 || return 0
  if chezmoi add "$ssh_config" >/dev/null 2>&1; then
    info "refreshed the chezmoi source for $ssh_config"
  else
    warn "$ssh_config is managed by chezmoi but its source could not be refreshed."
    warn "Run 'chezmoi add $ssh_config' and review 'chezmoi diff' so a later apply does not revert these provider blocks."
  fi
}

# A pinned public key is what lets the SSH config carry an IdentityFile, which
# in turn is the only condition under which IdentitiesOnly is safe to write.
# The value is already reachable from 1Password, so copying it by hand is
# avoidable. Public keys only: anything that looks private is refused.
public_key_is_valid() {
  local value="$1"
  [[ -n "$value" ]] || return 1
  # A private key, or any multi-line blob, must never reach ~/.ssh.
  [[ "$value" != *'PRIVATE KEY'* ]] || return 1
  [[ "$value" != *$'\n'* ]] || return 1
  case "$value" in
    'ssh-ed25519 '*|'ssh-rsa '*) return 0 ;;
    *) return 1 ;;
  esac
}

# Titles discover candidates, but are neither an identity nor proof of access.
# Retain stable item IDs so duplicate titles cannot redirect the public read.
onepassword_ssh_items() (
  local pattern="$1" tmp
  tmp="$(mktemp -t day-one-mac-items)" || return 1
  trap 'rm -f "$tmp" "${tmp}.deadline"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  run_with_deadline "$tmp" 20 op item list --categories "SSH Key" --format json || return 1
  jq -ce --arg p "$pattern" '
    if type != "array" then error("expected item list") else
      [.[] | select((.title // "") | ascii_downcase | contains($p)) |
        if (.id | type) != "string" or (.id | test("^[a-zA-Z0-9]{26}$") | not)
        then error("expected item ID") else {id, title} end]
    end' "$tmp" 2>/dev/null
)

# Parse real key material, not just its prefix. Only the fingerprint escapes
# the private temporary file; ssh-keygen diagnostics and key bytes stay hidden.
public_key_fingerprint() (
  local value="$1" tmp result
  public_key_is_valid "$value" || return 1
  tmp="$(mktemp -t day-one-mac-fingerprint)" || return 1
  trap 'rm -f "$tmp"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  printf '%s\n' "$value" > "$tmp"
  result="$(ssh-keygen -l -E sha256 -f "$tmp" 2>/dev/null)" || return 1
  [[ "$result" != *$'\n'* ]] || return 1
  printf '%s\n' "$result" | awk '$2 ~ /^SHA256:/ {print $2}'
)

verify_public_key_with_onepassword_agent() {
  local provider="$1" value="$2" fingerprint identities
  fingerprint="$(public_key_fingerprint "$value")" || fingerprint=""
  if [[ -z "$fingerprint" ]]; then
    warn "The $provider pin is not a parseable single public key. Nothing was changed."
    return 1
  fi
  if [[ "$provider" == azure && "$value" != 'ssh-rsa '* ]]; then
    warn 'The Azure DevOps pin must be an RSA public key. Nothing was changed.'
    return 1
  fi
  identities="$(agent_identities "$ONEPASSWORD_AGENT_SOCK")"
  if ! printf '%s\n' "$identities" | awk -v fp="$fingerprint" '$2 == fp {found=1} END {exit !found}'; then
    warn "The selected $provider key ($fingerprint) is not offered by the 1Password SSH agent."
    warn 'Unlock 1Password and review the intended item and agent allow-list; do not enable unrelated keys just to pass this check.'
    return 1
  fi
  info "Verified $provider public-key fingerprint: $fingerprint"
}

verify_existing_provider_key_pins() {
  local provider target value
  for provider in github azure; do
    case "$provider" in
      github) uses_github || continue; target="$HOME/.ssh/github-auth.pub" ;;
      azure) uses_azure || continue; target="$HOME/.ssh/azure-devops-auth.pub" ;;
    esac
    [[ -e "$target" || -L "$target" ]] || continue
    if [[ -L "$HOME/.ssh" || -L "$target" || ! -f "$target" || ! -r "$target" ]]; then
      warn "Review the physical public-key file at $target; it was not changed."
      return 1
    fi
    value="$(cat "$target")" || return 1
    verify_public_key_with_onepassword_agent "$provider" "$value" || return 1
  done
}

# Fetch only the public field, never the complete SSH item. Subshell traps keep
# cleanup local to this read and do not replace the runner's own traps.
onepassword_public_key_value() (
  local tmp result
  tmp="$(mktemp -t day-one-mac-pubkey)" || return 1
  trap 'rm -f "$tmp" "${tmp}.deadline"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  if run_with_deadline "$tmp" 20 op item get "$1" --fields 'label=public key' --format json; then
    # CLI versions may encode a selected field as an object or an array.
    # Require exactly one public field; never accept a complete item response.
    jq -er 'if type == "array" then . else [.] end |
      if length == 1 and .[0].label == "public key" and (.[0].value | type) == "string"
      then .[0].value else error("expected one public field") end' "$tmp" 2>/dev/null
  else
    result=$?
    return "$result"
  fi
)

# Save a provider's 1Password public key as the pinned ~/.ssh/<provider>-auth.pub.
export_provider_public_key() {
  local provider="$1" target pattern label items candidates item_id title count choice value status fingerprint
  case "$provider" in
    github) target="$HOME/.ssh/github-auth.pub"; pattern=github; label='GitHub' ;;
    azure)  target="$HOME/.ssh/azure-devops-auth.pub"; pattern=azure; label='Azure DevOps' ;;
    *) err "Unknown provider for key export: $provider"; return 1 ;;
  esac

  have op || { warn "The 1Password CLI ('op') is required to export a public key."; return 1; }
  have jq || { warn "'jq' is required to export a public key; rerun the Installation Centre."; return 1; }

  if ! items="$(onepassword_ssh_items "$pattern")"; then
    warn 'Could not list SSH key candidates in 1Password within 20 seconds. Unlock the app and retry.'
    return 1
  fi
  candidates="$(printf '%s' "$items" | jq -c '[.[] | select(.title | test("signing|sign key"; "i") | not)]')" || return 1
  count="$(printf '%s' "$candidates" | jq 'length')"
  if [[ "$count" -eq 0 ]]; then
    warn "No authentication candidate has '$pattern' in its title; signing-labelled items are excluded."
    warn "Create the key in Step 3.4 and name it by provider, for example '$label — Personal — Authentication'."
    return 1
  fi
  choice=1
  if [[ "$count" -gt 1 ]]; then
    info "Several 1Password SSH Key items match '$pattern'; choose the intended identity, not the best-looking title:"
    printf '%s' "$candidates" | jq -r 'to_entries[] | "  \(.key + 1)) \(.value.title | tojson) [\(.value.id)]"'
    if [[ "${ASSUME_YES:-0}" == 1 ]]; then
      warn '--yes cannot choose between identities. Run interactively or use the manual route in Step 3.7.'
      return 1
    fi
    choice="$(ask 'Choose the intended key number (q cancels)' q '^([1-9][0-9]*|q)$')" || return 1
    [[ "$choice" =~ ^[1-9][0-9]*$ && "${#choice}" -le 6 ]] || return 1
    [[ "$choice" -le "$count" ]] || { warn 'No such key number; nothing was changed.'; return 1; }
  fi
  item_id="$(printf '%s' "$candidates" | jq -r --argjson n "$choice" '.[$n - 1].id')"
  title="$(printf '%s' "$candidates" | jq -c --argjson n "$choice" '.[$n - 1].title')"
  info "Selected 1Password item: $title [$item_id]"

  if value="$(onepassword_public_key_value "$item_id")"; then
    :
  else
    status=$?
    [[ "$status" -eq 124 ]] \
      && warn "Reading '$title' from 1Password timed out; approve the prompt and retry." \
      || warn "Could not read exactly one public-key field from '$title' in 1Password."
    warn "Review the public-key field in the 1Password app or use the manual route in Step 3.7."
    return 1
  fi
  value="${value%"${value##*[![:space:]]}"}"

  if ! public_key_is_valid "$value"; then
    warn "'$title' did not yield a usable public key."
    warn "Expected one line beginning 'ssh-ed25519 ' or 'ssh-rsa '. Nothing was written to ~/.ssh."
    warn "Review the public-key field in the 1Password app; do not export the complete item."
    return 1
  fi

  verify_public_key_with_onepassword_agent "$provider" "$value" || return 1
  fingerprint="$(public_key_fingerprint "$value")" || return 1
  confirm "Save $label key $title [$item_id], fingerprint $fingerprint, to $target?" || return 1
  # Check again after the confirmation: the app may have locked meanwhile.
  verify_public_key_with_onepassword_agent "$provider" "$value" || return 1
  if [[ -L "$HOME/.ssh" || -L "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
    warn "Refusing a linked or non-file pin path: $target"
    return 1
  fi

  create_directory "$HOME/.ssh"
  write_text_file "$target" "$value"$'\n'
  [[ "$DRY_RUN" == 1 ]] || chmod 644 "$target"
  [[ "$DRY_RUN" == 1 ]] || chmod 700 "$HOME/.ssh"
  ok "saved the $label public key to $target"
  info "Rerun Phase 3 so the SSH config gains its IdentityFile line."
}

configure_onepassword_ssh() {
  local ssh_config="$HOME/.ssh/config"
  if [[ "$AUTH_MODE" == https ]]; then
    info "Auth mode 'https': no SSH config block is written."
    return 0
  fi
  local start_marker='# >>> Day One Mac: SSH authentication >>>'
  local end_marker='# <<< Day One Mac: SSH authentication <<<'
  local old_start='# >>> Day One Mac: 1Password SSH agent >>>'
  local old_end='# <<< Day One Mac: 1Password SSH agent <<<'
  local block remainder content current legacy has_markers=0
  block="$(ssh_config_block)"
  legacy=$'Host *\n    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"\n    IdentitiesOnly yes\n    ServerAliveInterval 60\n    ServerAliveCountMax 3'

  create_directory "$HOME/.ssh"
  if [[ "$DRY_RUN" != 1 ]]; then chmod 700 "$HOME/.ssh"; fi

  if [[ -L "$ssh_config" ]]; then
    warn "$ssh_config is a symbolic link, so Phase 3 will not replace its source indirectly."
    warn "Add the provider blocks from Step 3.9 to the file managed by that link, then rerun Phase 3."
    return "$EX_MANUAL"
  fi

  if [[ ! -e "$ssh_config" ]]; then
    write_text_file "$ssh_config" "$block"$'\n'
  else
    current="$(cat "$ssh_config")"
    if grep -Fxq -e "$start_marker" -e "$end_marker" -e "$old_start" -e "$old_end" "$ssh_config"; then
      has_markers=1
    fi
    # Accept exactly one complete pair, including the former 1Password label.
    # Never swallow user settings after malformed, nested or mixed markers.
    if ! remainder="$(awk -v start="$start_marker" -v end="$end_marker" \
      -v old_start="$old_start" -v old_end="$old_end" '
      $0 == start || $0 == old_start {
        if (seen || skipping) { bad=1; exit }
        seen=1; skipping=1; closing=($0 == start ? end : old_end); next
      }
      $0 == end || $0 == old_end {
        if (!skipping || $0 != closing) { bad=1; exit }
        skipping=0; next
      }
      !skipping { print }
      END { if (bad || skipping) exit 1 }
    ' "$ssh_config")"; then
      err "$ssh_config contains malformed or multiple Day One Mac SSH blocks."
      warn "Repair the marked block manually before rerunning Phase 3; no change was made."
      return "$EX_GATE"
    elif [[ "$has_markers" == 1 ]]; then
      content="$block"
      [[ -z "$remainder" ]] || content="$content"$'\n'"$remainder"
      [[ "$current" == "$content" ]] || write_text_file "$ssh_config" "$content"$'\n'
    elif [[ "$current" == "$legacy" ]]; then
      info "migrating the earlier Day One Mac Host * block to track-specific host blocks"
      write_text_file "$ssh_config" "$block"$'\n'
    else
      if [[ "$DRY_RUN" == 1 ]]; then
        info "would ask before adding a backed-up, track-specific $AUTH_MODE block to $ssh_config"
        return 0
      fi
      confirm "Back up $ssh_config and add the selected provider blocks at its beginning?" || {
        warn "The existing SSH config was not changed. Merge the block from Step 3.9, then rerun Phase 3."
        return "$EX_MANUAL"
      }
      content="$block"$'\n\n'"$current"
      write_text_file "$ssh_config" "$content"$'\n'
    fi
  fi

  [[ "$DRY_RUN" == 1 ]] && return 0
  chmod 600 "$ssh_config"
  [[ ! -f "$HOME/.ssh/github-auth.pub" ]] || chmod 644 "$HOME/.ssh/github-auth.pub"
  [[ ! -f "$HOME/.ssh/azure-devops-auth.pub" ]] || chmod 644 "$HOME/.ssh/azure-devops-auth.pub"
  resync_managed_ssh_config "$ssh_config"
  if uses_github; then ssh -G github.com >/dev/null 2>&1 || return "$EX_GATE"; fi
  if uses_azure; then ssh -G ssh.dev.azure.com >/dev/null 2>&1 || return "$EX_GATE"; fi
}

# Phase 3's checklist promises that `op account list` succeeds, so verify the
# desktop CLI integration itself rather than only that the `op` binary exists.
# The call can raise a biometric prompt, so it runs under a deadline.
verify_onepassword_cli_integration() {
  local tmp status line
  tmp="$(mktemp -t day-one-mac-op)"
  run_with_deadline "$tmp" 20 op account list
  status=$?
  if [[ "$status" -eq 124 ]]; then
    warn "'op account list' did not finish within 20 seconds."
    warn "Approve or dismiss the 1Password prompt, keep the app unlocked, then rerun Phase 3."
    rm -f "$tmp"
    return 1
  fi
  if [[ "$status" -ne 0 ]]; then
    warn "'op account list' failed, so the 1Password CLI integration is not usable yet:"
    while IFS= read -r line; do [[ -z "$line" ]] || warn "  $line"; done < "$tmp"
    warn "In 1Password -> Settings -> Developer, turn on 'Integrate with 1Password CLI',"
    warn "unlock the app, then rerun Phase 3. See Step 3.2 of the phase guide."
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
  return 0
}

ONEPASSWORD_AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# List the agent's identities. With a socket argument the named agent is asked;
# without one, whatever SSH_AUTH_SOCK already points at. Prints nothing when the
# agent is unreachable or holds no key, so callers test for an empty result.
agent_identities() {
  local sock="$1" out
  if [[ -n "$sock" ]]; then
    out="$(env SSH_AUTH_SOCK="$sock" ssh-add -l -E sha256 2>/dev/null || true)"
  else
    out="$(ssh-add -l 2>/dev/null || true)"
  fi
  case "$out" in *'no identities'*) out="" ;; esac
  printf '%s' "$out"
}

# Show what the agent holds, so fingerprints can be matched against the provider.
show_agent_identities() {
  local line
  info "The SSH agent currently offers:"
  while IFS= read -r line; do [[ -z "$line" ]] || info "  $line"; done <<<"$1"
}

# Azure DevOps accepts RSA only. Without this a Track 2 or 3 Mac passes Phase 3
# and fails Phase 4 on a misleading "Permission denied (publickey)".
require_rsa_for_azure() {
  uses_azure || return 0
  printf '%s\n' "$1" | grep -q '(RSA)' && return 0
  warn "Azure DevOps requires an RSA key, but the agent offers no RSA identity."
  warn "Create or import an RSA 3072-bit key using Step 3.4 of the phase guide, then rerun Phase 3."
  return 1
}

# Offer to write the provider key pins rather than writing them unasked.
offer_provider_key_pins() {
  local pinned=0
  verify_existing_provider_key_pins || return 1
  if uses_github && [[ ! -f "$HOME/.ssh/github-auth.pub" ]]; then
    info "The GitHub public key is not pinned to ~/.ssh/github-auth.pub."
    info "Pinning adds an IdentityFile line, which is what makes IdentitiesOnly safe."
    if confirm "Save the GitHub public key from 1Password to ~/.ssh/github-auth.pub now?"; then
      export_provider_public_key github || { warn 'Complete the manual route in Step 3.7, then retry.'; return 1; }
      pinned=1
    else
      warn 'No GitHub pin approved. Complete Step 3.7, then retry.'
      return 1
    fi
  fi
  if uses_azure && [[ ! -f "$HOME/.ssh/azure-devops-auth.pub" ]]; then
    warn "The Azure public key is not pinned. Azure DevOps accepts only the first key offered,"
    warn "so pinning matters whenever the agent holds more than one identity."
    if confirm "Save the Azure DevOps public key from 1Password to ~/.ssh/azure-devops-auth.pub now?"; then
      export_provider_public_key azure || { warn 'Complete the manual route in Step 3.7, then retry.'; return 1; }
      pinned=1
    else
      warn 'No Azure pin approved. Complete Step 3.7, then retry.'
      return 1
    fi
  fi
  [[ "$pinned" == 0 ]] || info "A pin was added; the SSH config below will include its IdentityFile."
  verify_existing_provider_key_pins
}

# Classify without asking for a secret, changing the key, or printing key bytes.
# Failure alone is not proof of encryption: invalid/unreadable keys fail too.
keychain_key_protection() {
  local target="$1" diagnostic
  if [[ ! -f "$target" || ! -r "$target" || -L "$target" ]]; then
    printf 'unverifiable\n'
  elif diagnostic="$(LC_ALL=C ssh-keygen -y -P '' -f "$target" 2>&1 >/dev/null </dev/null)"; then
    printf 'unprotected\n'
  elif [[ "$diagnostic" == *'incorrect passphrase supplied to decrypt private key'* ]]; then
    printf 'encrypted\n'
  else
    printf 'unverifiable\n'
  fi
}

# Create a passphrase-protected key and hand it to the macOS Keychain.
# ssh-keygen prompts for the passphrase itself: the runner never sees or stores it.
generate_keychain_key() {
  local target="$1" type="$2" bits="$3"
  if [[ -e "$target" || -L "$target" ]]; then
    info "reusing the existing key at $target"
  else
    warn "ssh-keygen will now ask for a passphrase. Choose one you can recall;"
    warn "the macOS Keychain stores it so you are not asked again on this Mac."
    record_path_before_write "$target"
    record_path_before_write "$target.pub"
    if [[ -n "$bits" ]]; then
      ssh-keygen -t "$type" -b "$bits" -f "$target" -C "day-one-mac $(id -un)@$(hostname -s)" || return 1
    else
      ssh-keygen -t "$type" -f "$target" -C "day-one-mac $(id -un)@$(hostname -s)" || return 1
    fi
    ok "created $target"
  fi
  case "$(keychain_key_protection "$target")" in
    encrypted) ;;
    unprotected)
      warn "$target has an empty passphrase; Phase 3 cannot accept it."
      warn "Run ssh-keygen -p -f '$target' yourself, choose a non-empty passphrase, then rerun Phase 3."
      return 1 ;;
    *)
      warn "Cannot verify passphrase protection for $target; no key was replaced."
      warn "Check the key format, permissions and path manually, then rerun Phase 3."
      return 1 ;;
  esac
  chmod 600 "$target"
  [[ ! -f "$target.pub" ]] || chmod 644 "$target.pub"
  # A failed load must not mark Phase 3 done. Do not fall back to -K: that flag
  # means something different in upstream OpenSSH.
  if ! ssh-add --apple-use-keychain "$target"; then
    warn "Could not load $target using the Apple Keychain."
    warn "Use Apple's ssh-add --apple-use-keychain '$target', then rerun Phase 3."
    return 1
  fi
  info "Register the matching public key with your provider: $target.pub"
  return 0
}

# Required applications for this Mac. 1Password is required only when it is
# the chosen authentication mode; other modes must not be forced to install it.
required_application_ids() {
  day_one_required_application_ids "${PRESET:-recommended-productivity}" "$AUTH_MODE"
}

# Git transport implied by the authentication mode.
git_protocol_for_mode() {
  [[ "$AUTH_MODE" == https ]] && printf 'https' || printf 'ssh'
}

# --- Phase 3 authentication modes -------------------------------------------
# Every mode ends with the same SSH config write and FileVault gate; they differ
# only in where the SSH identity comes from.

phase_03_onepassword() {
  local app_id key_guidance app_version cli_version identities line
  ui_section '📦' 'Required application ownership'
  scan_applications 1password 1password-cli || return $?
  if [[ "$DRY_RUN" != 1 ]]; then
    for app_id in 1password 1password-cli; do
      verify_application "$app_id" || {
        err 'A required 1Password component is missing or has an ownership conflict.'
        warn 'Rerun the Installation Centre; Phase 3 configures applications but no longer installs them.'
        return "$EX_GATE"
      }
    done
  fi
  [[ "$DRY_RUN" == 1 ]] && return 0
  have op || { err "1Password CLI is not available."; return "$EX_GATE"; }
  app_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    /Applications/1Password.app/Contents/Info.plist 2>/dev/null || true)"
  cli_version="$(op --version 2>/dev/null || true)"
  [[ -z "$app_version" ]] || info "1Password for Mac $app_version"
  [[ -z "$cli_version" ]] || info "1Password CLI $cli_version"
  phase_next "1Password CLI integration" "Turn on 'Integrate with 1Password CLI' in Settings -> Developer, then rerun Phase 3."
  verify_onepassword_cli_integration || return "$EX_MANUAL"
  phase_step_done "1Password CLI integration answers 'op account list'"
  case "$TRACK" in
    1) key_guidance="Create a new GitHub Ed25519 key or import the trusted existing GitHub key; then allow its vault." ;;
    2) key_guidance="Create a new Azure DevOps RSA 3072-bit key or import the trusted existing RSA key; then allow its vault." ;;
    3) key_guidance="Create/import the GitHub and Azure DevOps keys in Step 3.4; use RSA for Azure and pin separate keys to each provider." ;;
  esac
  phase_next "1Password SSH identity" "$key_guidance"
  identities="$(agent_identities "$ONEPASSWORD_AGENT_SOCK")"
  if [[ -z "$identities" ]]; then
    warn "$key_guidance"
    warn "Turn on 'Use the SSH agent' in Settings -> Developer, unlock 1Password, then rerun Phase 3."
    return "$EX_MANUAL"
  fi
  show_agent_identities "$identities"
  require_rsa_for_azure "$identities" || return "$EX_MANUAL"
  phase_step_done "1Password SSH agent exposes at least one usable identity"
  offer_provider_key_pins || return "$EX_MANUAL"
}

phase_03_keychain() {
  local generated=0
  phase_next "on-disk SSH key held by the macOS Keychain" "Create the key when prompted and choose a passphrase you can recall."
  [[ "$DRY_RUN" == 1 ]] && return 0
  create_directory "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  uses_github && { generate_keychain_key "$HOME/.ssh/id_ed25519" ed25519 "" || return "$EX_MANUAL"; generated=1; }
  uses_azure && { generate_keychain_key "$HOME/.ssh/id_rsa_azure" rsa 3072 || return "$EX_MANUAL"; generated=1; }
  [[ "$generated" == 1 ]] || { err "No provider selected for a keychain key."; return "$EX_GATE"; }
  phase_step_done "keychain-backed SSH key present and loaded"
}

phase_03_external() {
  local identities
  phase_next "an SSH identity from your own agent" "Load a key into your agent, then rerun Phase 3."
  [[ "$DRY_RUN" == 1 ]] && return 0
  # Deliberately no socket override: whatever SSH_AUTH_SOCK already points at
  # is the agent being verified.
  identities="$(agent_identities "")"
  if [[ -z "$identities" ]]; then
    err "No SSH agent identity is available."
    warn "Auth mode 'external' means Day One Mac does not create or manage a key."
    warn "Start your agent and load a key so that 'ssh-add -l' lists it, then rerun Phase 3."
    return "$EX_MANUAL"
  fi
  show_agent_identities "$identities"
  require_rsa_for_azure "$identities" || return "$EX_MANUAL"
  phase_step_done "an external agent exposes at least one usable identity"
}

phase_03_https() {
  phase_next "HTTPS Git authentication" "Phase 4 configures the credential helper; no SSH key is needed."
  info "Auth mode 'https': Phase 3 configures no SSH key or agent."
  info "Git authenticates over HTTPS, set up in Phase 4."
  phase_step_done "HTTPS mode selected; SSH setup intentionally skipped"
}

phase_03() {
  ui_title '3️⃣' 'Phase 03 — Security and SSH'
  info "Guide: $(phase_doc 03)"
  info "Git authentication mode: $AUTH_MODE"
  phase_next "authentication setup and disk encryption" "Complete the steps for your chosen mode, then rerun Phase 3."
  if ! load_brew; then
    [[ "$DRY_RUN" == 1 ]] || { err "Complete Phase 2 first."; return "$EX_GATE"; }
  fi
  case "$AUTH_MODE" in
    1password) phase_03_onepassword || return $? ;;
    keychain)  phase_03_keychain    || return $? ;;
    external)  phase_03_external    || return $? ;;
    https)     phase_03_https       || return $? ;;
    *) err "Unknown authentication mode: $AUTH_MODE"; return "$EX_GATE" ;;
  esac
  configure_onepassword_ssh || return $?
  [[ "$DRY_RUN" == 1 ]] && return 0
  phase_next "FileVault disk encryption" "Open System Settings → Privacy & Security → FileVault, turn it on, and save the recovery method."
  fdesetup status 2>/dev/null | grep -q 'FileVault is On' || {
    warn "Enable FileVault in System Settings, save its recovery key, then rerun."
    return "$EX_MANUAL"
  }
  phase_step_done "FileVault is on"
  ok "Authentication configuration ($AUTH_MODE) and FileVault verified locally"
  info 'Provider authentication is checked separately in Phase 4.'
}
