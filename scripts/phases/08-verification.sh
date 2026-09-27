#!/usr/bin/env bash
# Sourced phase implementation; shared runner context is supplied by setup.sh.

report_check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '| %s | PASS |\n' "$label" >> "$STATE_DIR/verification.md"
  else
    printf '| %s | FAIL |\n' "$label" >> "$STATE_DIR/verification.md"
    VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
    phase_gate_failed "$label"
  fi
}

# Scan a chezmoi source for obvious secret material.
#
# Results are returned through globals rather than stdout: a command
# substitution would run this in a subshell and discard SECRET_SCAN_ERROR.
#   SECRET_SCAN_MATCHES — newline-separated matching file paths, empty if clean
#   SECRET_SCAN_ERROR   — why the scan could not run
# Returns 0 when the scan ran (with or without matches) and 1 when the scan
# itself failed, so a broken or missing scanner is never read as a clean result.
#
# Each pattern is passed with -e because several of them begin with "-", which
# ripgrep would otherwise parse as a command-line flag.
SECRET_SCAN_MATCHES=""
SECRET_SCAN_ERROR=""
scan_source_for_secrets() {
  local source="$1" output status
  SECRET_SCAN_MATCHES=""
  SECRET_SCAN_ERROR=""

  if ! command -v rg >/dev/null 2>&1; then
    SECRET_SCAN_ERROR="ripgrep (rg) was not found on PATH. Install it with 'brew install ripgrep', then rerun Phase 8."
    return 1
  fi

  set +e
  output="$(rg -l --hidden --no-ignore -g '!.git/**' \
    -e '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----' \
    -e 'github_pat_[A-Za-z0-9_]{20,}' \
    -e 'ghp_[A-Za-z0-9]{20,}' \
    -e 'AKIA[0-9A-Z]{16}' \
    "$source" 2>&1)"
  status=$?
  set -e

  # ripgrep: 0 = matched, 1 = no match, 2 or higher = the scan failed.
  if [[ "$status" -gt 1 ]]; then
    SECRET_SCAN_ERROR="the secret scan could not run: $output"
    return 1
  fi

  [[ "$status" -eq 0 ]] && SECRET_SCAN_MATCHES="$output"
  return 0
}

verify_dotfiles_remote() {
  local source remote_url provider repo_slug visibility azure_path azure_org azure_project secret_matches behind ahead
  source="$(chezmoi source-path 2>/dev/null || true)"
  phase_next "private dotfiles repository" "Commit the reviewed chezmoi source, add a private origin remote for the selected track, push it, then rerun Phase 8."

  [[ -n "$source" && -d "$source" ]] || {
    err "chezmoi has no readable source directory."
    return "$EX_GATE"
  }
  git -C "$source" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    warn "The chezmoi source is not a Git repository yet: $source"
    warn "Follow Step 8.5 to initialise it, review it for secrets, commit, and add a private remote."
    return "$EX_MANUAL"
  }
  git -C "$source" rev-parse --verify HEAD >/dev/null 2>&1 || {
    warn "The chezmoi source has no commit yet. Review it, create the first commit, and rerun Phase 8."
    return "$EX_MANUAL"
  }

  if ! scan_source_for_secrets "$source"; then
    printf '| Dotfiles secret-pattern scan | FAIL — did not run |\n' >> "$STATE_DIR/verification.md"
    err "The dotfiles source was not scanned for secrets, so it cannot be approved."
    err "$SECRET_SCAN_ERROR"
    return "$EX_GATE"
  fi
  secret_matches="$SECRET_SCAN_MATCHES"
  if [[ -n "$secret_matches" ]]; then
    printf '| Dotfiles secret-pattern review | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "Possible secret material was found in these source files:"
    while IFS= read -r match; do warn "  ${match#"$source"/}"; done <<<"$secret_matches"
    warn "Remove false positives or real secrets safely, rotate exposed credentials, then rerun Phase 8."
    return "$EX_MANUAL"
  fi
  printf '| Dotfiles secret-pattern scan | PASS |\n' >> "$STATE_DIR/verification.md"

  if [[ -n "$(git -C "$source" status --porcelain)" ]]; then
    printf '| Dotfiles repository clean | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "The dotfiles source has uncommitted changes: $source"
    git -C "$source" status --short >&2
    warn "Review and commit the intended files before rerunning Phase 8."
    return "$EX_MANUAL"
  fi
  printf '| Dotfiles repository clean | PASS |\n' >> "$STATE_DIR/verification.md"

  remote_url="$(git -C "$source" remote get-url origin 2>/dev/null || true)"
  [[ -n "$remote_url" ]] || {
    printf '| Private dotfiles origin | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "The dotfiles source has no origin remote. Create a private repository, add origin, push, and rerun."
    return "$EX_MANUAL"
  }

  case "$remote_url" in
    *github.com:*.git|*github.com/*.git|*github.com:*|*github.com/*)
      provider=github
      repo_slug="$(printf '%s\n' "$remote_url" \
        | sed -E 's#^(ssh://)?git@github\.com[:/]##; s#^https://github\.com/##; s#\.git$##')"
      [[ "$TRACK" == 1 || "$TRACK" == 3 ]] || {
        err "A GitHub dotfiles remote does not match Track $TRACK."
        return "$EX_GATE"
      }
      visibility="$(gh repo view "$repo_slug" --json visibility --jq '.visibility' 2>/dev/null || true)"
      [[ "$visibility" == PRIVATE ]] || {
        printf '| Dotfiles remote privacy | FAIL |\n' >> "$STATE_DIR/verification.md"
        err "GitHub did not confirm that $repo_slug is private (reported: ${visibility:-unavailable})."
        return "$EX_GATE"
      }
      ;;
    *ssh.dev.azure.com*|*dev.azure.com/*/_git/*)
      provider=azure
      [[ "$TRACK" == 2 || "$TRACK" == 3 ]] || {
        err "An Azure DevOps dotfiles remote does not match Track $TRACK."
        return "$EX_GATE"
      }
      case "$remote_url" in
        *ssh.dev.azure.com*) azure_path="$(printf '%s\n' "$remote_url" | sed -E 's#^.*ssh\.dev\.azure\.com[:/]v3/##; s#\.git$##')" ;;
        *) azure_path="$(printf '%s\n' "$remote_url" | sed -E 's#^https://dev\.azure\.com/##; s#/_git/#/#; s#\.git$##')" ;;
      esac
      azure_org="${azure_path%%/*}"
      azure_path="${azure_path#*/}"
      azure_project="${azure_path%%/*}"
      azure_project="${azure_project//%20/ }"
      [[ -n "$azure_org" && -n "$azure_project" && "$azure_org" != "$azure_path" ]] || {
        err "Could not identify the Azure organisation and project from origin: $remote_url"
        return "$EX_MANUAL"
      }
      visibility="$(az devops project show --org "https://dev.azure.com/$azure_org" \
        --project "$azure_project" --query visibility -o tsv 2>/dev/null || true)"
      visibility="$(printf '%s' "$visibility" | tr '[:upper:]' '[:lower:]')"
      [[ "$visibility" == private ]] || {
        printf '| Dotfiles remote privacy | FAIL |\n' >> "$STATE_DIR/verification.md"
        err "Azure DevOps did not confirm that project '$azure_project' is private (reported: ${visibility:-unavailable})."
        return "$EX_GATE"
      }
      ;;
    *)
      printf '| Private dotfiles origin | REVIEW |\n' >> "$STATE_DIR/verification.md"
      warn "The origin host is not one this playbook can verify automatically: $remote_url"
      warn "Use a GitHub or Azure DevOps private remote that matches the selected track."
      return "$EX_MANUAL"
      ;;
  esac

  git -C "$source" ls-remote origin >/dev/null 2>&1 || {
    printf '| Dotfiles remote reachable | FAIL |\n' >> "$STATE_DIR/verification.md"
    err "The dotfiles origin is not reachable with the current authentication: $remote_url"
    return "$EX_GATE"
  }
  git -C "$source" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1 || {
    printf '| Dotfiles branch pushed | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "The current dotfiles branch has no upstream. Push it with -u, then rerun Phase 8."
    return "$EX_MANUAL"
  }
  read -r behind ahead <<<"$(git -C "$source" rev-list --left-right --count '@{upstream}...HEAD')"
  if [[ "$behind" != 0 || "$ahead" != 0 ]]; then
    printf '| Dotfiles branch pushed | REVIEW — behind %s, ahead %s |\n' "$behind" "$ahead" >> "$STATE_DIR/verification.md"
    warn "The dotfiles branch and its upstream differ (behind $behind, ahead $ahead)."
    warn "Review, reconcile and push the branch before rerunning Phase 8."
    return "$EX_MANUAL"
  fi
  printf '| Dotfiles remote provider | PASS — %s |\n' "$provider" >> "$STATE_DIR/verification.md"
  printf '| Dotfiles remote privacy | PASS |\n' >> "$STATE_DIR/verification.md"
  printf '| Dotfiles remote reachable | PASS |\n' >> "$STATE_DIR/verification.md"
  printf '| Dotfiles branch pushed | PASS |\n' >> "$STATE_DIR/verification.md"
  phase_step_done "dotfiles source is clean, secret-scanned, private, reachable and pushed"
}

verify_local_dotfiles_source() {
  local source secret_matches
  source="$(chezmoi source-path 2>/dev/null || true)"
  phase_next "local chezmoi source review" "Review the local source and ensure it is included in an encrypted backup."
  [[ -n "$source" && -d "$source" ]] || {
    err "chezmoi has no readable source directory."
    return "$EX_GATE"
  }
  if ! scan_source_for_secrets "$source"; then
    printf '| Dotfiles secret-pattern scan | FAIL — did not run |\n' >> "$STATE_DIR/verification.md"
    err "The dotfiles source was not scanned for secrets, so it cannot be approved."
    err "$SECRET_SCAN_ERROR"
    return "$EX_GATE"
  fi
  secret_matches="$SECRET_SCAN_MATCHES"
  if [[ -n "$secret_matches" ]]; then
    printf '| Dotfiles secret-pattern review | REVIEW |\n' >> "$STATE_DIR/verification.md"
    warn "Possible secret material was found in these source files:"
    while IFS= read -r match; do warn "  ${match#"$source"/}"; done <<<"$secret_matches"
    warn "Remove real secrets, rotate exposed credentials, then rerun Phase 8."
    return "$EX_MANUAL"
  fi
  printf '| Dotfiles secret-pattern scan | PASS |\n' >> "$STATE_DIR/verification.md"
  printf '| Dotfiles versioning | PASS — local-only selected |\n' >> "$STATE_DIR/verification.md"
  printf '| Dotfiles remote | NOT REQUIRED — local-only selected |\n' >> "$STATE_DIR/verification.md"
  warn "chezmoi is local-only: $source"
  if [[ -d "$source/.git" ]]; then
    printf '| Existing dotfiles Git metadata | PRESENT — preserved, not deleted |\n' >> "$STATE_DIR/verification.md"
    warn "This source already contains Git metadata. Local-only mode skips commit and remote gates but never deletes existing history."
    warn "If you want a genuinely unversioned source, copy the reviewed files into a new source directory instead of deleting .git automatically."
  else
    printf '| Existing dotfiles Git metadata | NONE |\n' >> "$STATE_DIR/verification.md"
    warn "There is no Git history or remote recovery gate."
  fi
  warn "Include the chezmoi source directory in an encrypted backup."
  phase_step_done "local-only chezmoi source is readable and secret-scanned"
}

report_keychain_key_protection() {
  local report="$1" disk_key="$2" protection
  protection="$(keychain_key_protection "$disk_key")"
  if [[ "$protection" == encrypted ]]; then
    printf '| Passphrase protection: `%s` | PASS — encrypted key detected |\n' "${disk_key/#"$HOME"/~}" >> "$report"
  else
    printf '| Passphrase protection: `%s` | FAIL — %s |\n' "${disk_key/#"$HOME"/~}" "$protection" >> "$report"
    VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
    phase_gate_failed "Keychain private-key passphrase protection"
  fi
}

phase_08() {
  local brewfile="$HOME/Brewfile" brewfile_created=0 report="$STATE_DIR/verification.md" app_id
  local disk_keys disk_key
  ui_title '8️⃣' 'Phase 08 — Verify and reproduce'
  info "Guide: $(phase_doc 08)"
  if [[ "$DRY_RUN" == 1 ]]; then
    print_command "$SCRIPT_DIR/verify.sh"
    info "would write $report and verify the selected track and stack"
    info "would preserve an existing $brewfile, or create and manage it if absent"
    print_command brew bundle dump --file="$brewfile"
    print_command chezmoi add "$brewfile"
    if [[ "$DOTFILES_VERSIONING" == git ]]; then
      info "would require a clean, pushed, private GitHub or Azure DevOps dotfiles origin"
    else
      info "would verify the local-only chezmoi source and skip Git remote requirements"
    fi
    return 0
  fi
  phase_next "Day One Mac runtime verification" "Run 'day-one-mac verify', fix the named integrity or runtime failure, then rerun Phase 8."
  "$SCRIPT_DIR/verify.sh" || return "$EX_GATE"
  phase_step_done "Day One Mac runtime verification passed"
  ensure_state
  VERIFY_FAILURES=0
  phase_next "machine verification gates" "Open ~/.day-one-mac/verification.md and return to the phase that owns each failed row."
  {
    printf '# Day One Mac verification\n\n'
    printf -- '- Generated: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- Track: `%s — %s`\n' "$TRACK" "$(track_name)"
    printf -- '- Stack: `%s`\n' "$STACK"
    printf -- '- Dotfiles versioning: `%s`\n\n' "$DOTFILES_VERSIONING"
    printf '| Gate | Result |\n|---|---|\n'
  } > "$report"
  report_check "Apple-silicon native terminal" day_one_require_apple_silicon
  report_check "Xcode or Command Line Tools readiness" verify_apple_developer_tools
  report_check "Apple-silicon Homebrew prefix" bash -c '[[ "$(brew --prefix 2>/dev/null)" == /opt/homebrew ]]'
  report_check "Git identity" git config --global user.email
  report_check "ghq repository root" bash -c '[[ "$(ghq root 2>/dev/null | sed -n "1p")" == "$HOME/Developer" ]]'
  report_check "Day One Mac project root" bash -c '[[ "$(day-one-mac root)" == "$1" ]]' _ "$PROJECT_DIR"
  report_check "post-setup finalisation command" day-one-mac finalize --help
  report_check "advanced setup command" day-one-mac advanced --list
  report_check "advanced environment report command" day-one-mac advanced-audit --help
  report_check "existing-Mac safety report command" day-one-mac safety-report --plan
  report_check "existing-Mac Route A/Route B command" day-one-mac prepare-existing --help
  report_check "chezmoi" chezmoi doctor
  report_check "Starship" starship --version
  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    day_one_app_load "$app_id" || continue
    report_application "$DAY_ONE_APP_NAME" "$app_id"
  done < <(required_application_ids)
  if [[ "${PRESET:-recommended-productivity}" != core ]]; then
    report_check "VS Code CLI" code --version
  fi
  report_check "FileVault" bash -c "fdesetup status 2>/dev/null | grep -q 'FileVault is On'"
  report_check "Gatekeeper" bash -c "spctl --status 2>/dev/null | grep -q 'assessments enabled'"
  uses_node && report_check "Node, npm and pnpm" zsh -lic 'node --version && npm --version && pnpm --version'
  uses_python && report_check "Python via uv" uv python find
  uses_github && report_check "GitHub CLI" gh auth status
  uses_azure && report_check "Azure CLI" az account show
  printf '| Git authentication mode | %s |\n' "$AUTH_MODE" >> "$report"
  # Ask the agent this mode actually uses. In 1password mode the agent is
  # reached through the IdentityAgent socket in ~/.ssh/config, not through
  # SSH_AUTH_SOCK, so a bare `ssh-add -l` queries the empty default agent and
  # reports a failure even when 1Password is serving keys correctly.
  case "$AUTH_MODE" in
    1password)
      if [[ -n "$(agent_identities "$ONEPASSWORD_AGENT_SOCK")" ]]; then
        printf '| SSH agent identity | PASS |\n' >> "$report"
      else
        printf '| SSH agent identity | FAIL |\n' >> "$report"
        VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
        phase_gate_failed "SSH agent identity"
      fi
      ;;
    keychain|external)
      if [[ -n "$(agent_identities "")" ]]; then
        printf '| SSH agent identity | PASS |\n' >> "$report"
      else
        printf '| SSH agent identity | FAIL |\n' >> "$report"
        VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
        phase_gate_failed "SSH agent identity"
      fi
      ;;
    https)
      printf '| SSH agent identity | NOT REQUIRED — https selected |\n' >> "$report"
      ;;
  esac
  # Storage location is not encryption state. Keychain mode deliberately keeps
  # encrypted private files; all other modes retain the no-local-key policy.
  if [[ "$AUTH_MODE" == keychain ]]; then
    printf '| Private key files in ~/.ssh | EXPECTED — keychain mode |\n' >> "$report"
    disk_keys=""
    uses_github && disk_keys="$HOME/.ssh/id_ed25519"
    uses_azure && disk_keys="$disk_keys${disk_keys:+$'\n'}$HOME/.ssh/id_rsa_azure"
    while IFS= read -r disk_key; do
      [[ -n "$disk_key" ]] || continue
      report_keychain_key_protection "$report" "$disk_key"
    done <<<"$disk_keys"
  else
    # Name the offending files: "FAIL" alone leaves no way to tell which key
    # appeared, or whether it is one `gh auth login` created before the
    # --skip-ssh-key flag was added.
    disk_keys="$(find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' 2>/dev/null | LC_ALL=C sort || true)"
    if [[ -z "$disk_keys" ]]; then
      printf '| No on-disk id_* private-key files in ~/.ssh | PASS |\n' >> "$report"
    else
      printf '| No on-disk id_* private-key files in ~/.ssh | FAIL |\n' >> "$report"
      while IFS= read -r disk_key; do
        [[ -n "$disk_key" ]] || continue
        printf '| — unexpected private key | `%s` |\n' "${disk_key/#"$HOME"/~}" >> "$report"
        warn "Unexpected private key on disk: ${disk_key/#"$HOME"/~}"
      done <<<"$disk_keys"
      warn "Auth mode '$AUTH_MODE' keeps no private key in ~/.ssh."
      warn "If 'gh auth login' created it before --skip-ssh-key was added, remove it from GitHub, then delete it once 1Password's key is confirmed working."
      VERIFY_FAILURES=$((VERIFY_FAILURES + 1))
      phase_gate_failed "No on-disk id_* private-key files in ~/.ssh"
    fi
  fi
  chmod 600 "$report"
  info "report: $report"
  if [[ "$VERIFY_FAILURES" -gt 0 ]]; then
    err "$VERIFY_FAILURES verification gate(s) failed; review the report."
    return "$EX_GATE"
  fi
  phase_step_done "track- and stack-aware machine audit passed"
  phase_next "reviewed Brewfile under chezmoi management" "Review ~/Brewfile, add it to chezmoi if needed, and rerun Phase 8."
  if [[ ! -e "$brewfile" ]]; then
    record_path_before_write "$brewfile"
    run brew bundle dump --file="$brewfile"
    brewfile_created=1
    ok "recorded the installed Homebrew desired state in $brewfile"
  else
    info "preserved existing $brewfile"
  fi
  if ! chezmoi source-path "$brewfile" >/dev/null 2>&1; then
    if [[ "$brewfile_created" == 1 ]]; then
      run chezmoi add "$brewfile"
    else
      printf '| Brewfile managed by chezmoi | REVIEW |\n' >> "$report"
      warn "$brewfile already existed and is not managed by chezmoi."
      warn "Review it, run 'chezmoi add $brewfile', then rerun Phase 8."
      return "$EX_MANUAL"
    fi
  fi
  if chezmoi source-path "$brewfile" >/dev/null 2>&1; then
    printf '| Brewfile managed by chezmoi | PASS |\n' >> "$report"
  else
    printf '| Brewfile managed by chezmoi | FAIL |\n' >> "$report"
    err "Brewfile could not be added to chezmoi."
    return "$EX_GATE"
  fi
  phase_step_done "reviewed Brewfile is managed by chezmoi"
  if [[ "$DOTFILES_VERSIONING" == git ]]; then
    verify_dotfiles_remote || return $?
  else
    verify_local_dotfiles_source || return $?
  fi
  ok "Day One Mac base is complete; optional extras remain optional"
}
