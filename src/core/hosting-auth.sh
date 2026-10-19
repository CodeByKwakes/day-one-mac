#!/usr/bin/env bash
# Shared HTTPS helper selection and bounded Git transport verification.

hosting_load_choices() {
  HTTPS_HELPER="${HTTPS_HELPER:-$(state_value https-helper)}"
  HTTPS_HELPER="${HTTPS_HELPER:-existing}"
  GITHUB_REPO="${GITHUB_REPO:-$(state_value github-verification-repo)}"
  AZURE_REPO="${AZURE_REPO:-$(state_value azure-verification-repo)}"
  GITHUB_CLONE_DIR="${GITHUB_CLONE_DIR:-$(state_value github-clone-dir)}"
  AZURE_CLONE_DIR="${AZURE_CLONE_DIR:-$(state_value azure-clone-dir)}"
  GITHUB_CLONE_DIR="${GITHUB_CLONE_DIR:-none}"
  AZURE_CLONE_DIR="${AZURE_CLONE_DIR:-none}"
}

hosting_provider_ids() {
  case "$TRACK" in 1) printf 'github\n' ;; 2) printf 'azure\n' ;; 3) printf 'github\nazure\n' ;; esac
}

hosting_repo_url() {
  case "$1" in github) printf '%s' "${GITHUB_REPO:-}" ;; azure) printf '%s' "${AZURE_REPO:-}" ;; esac
}

hosting_clone_dir() {
  case "$1" in github) printf '%s' "${GITHUB_CLONE_DIR:-none}" ;; azure) printf '%s' "${AZURE_CLONE_DIR:-none}" ;; esac
}

hosting_clone_dir_valid() {
  [[ "$1" == /* && "$1" != / && "$1" != */ && "$1" != *[$'\t\r\n']* ]] || return 1
  day_one_safe_state_path "$1/.clone-check"
}

hosting_repo_valid() {
  local provider="$1" url="$2" mode="$3"
  [[ -n "$url" && "$url" != *[$'\t\r\n ']* && "$url" != *'?'* && "$url" != *'#'* ]] || return 1
  # Exact provider hosts and credential-free URLs only. Never accept PATs in URLs.
  if [[ "$mode" == https ]]; then
    case "$provider" in
      github) [[ "$url" =~ ^https://github\.com/[^/]+/[^/]+/?$ ]] ;;
      azure) [[ "$url" =~ ^https://([a-zA-Z0-9._-]+@)?dev\.azure\.com/[^/]+/[^/]+/_git/[^/]+/?$ ]] ;;
      *) return 1 ;;
    esac
  else
    case "$provider" in
      github) [[ "$url" =~ ^git@github\.com:[^/]+/[^/]+$ || "$url" =~ ^ssh://git@github\.com/[^/]+/[^/]+$ ]] ;;
      azure) [[ "$url" =~ ^git@ssh\.dev\.azure\.com:v3/[^/]+/[^/]+/[^/]+$ || "$url" =~ ^ssh://git@ssh\.dev\.azure\.com/v3/[^/]+/[^/]+/[^/]+$ ]] ;;
      *) return 1 ;;
    esac
  fi
}

hosting_validate_choices() {
  local provider url url_mode destination
  [[ "$HTTPS_HELPER" == gcm || "$HTTPS_HELPER" == existing ]] || {
    err '--https-helper must be gcm or existing.'; return 2; }
  [[ "$HTTPS_HELPER" != gcm || "$AUTH_MODE" == https ]] || {
    err '--https-helper gcm requires --auth-mode https.'; return 2; }
  for provider in github azure; do
    url="$(hosting_repo_url "$provider")"
    url_mode="$AUTH_MODE"
    case "$TRACK:$provider" in
      1:github|2:azure|3:*) ;;
      *) if [[ "$url" == https://* ]]; then url_mode=https; else url_mode=external; fi ;;
    esac
    [[ -z "$url" ]] || hosting_repo_valid "$provider" "$url" "$url_mode" || {
      err "Invalid $provider verification repository. Use the exact selected HTTPS or SSH clone URL without a token."; return 2; }
    destination="$(hosting_clone_dir "$provider")"
    [[ "$destination" != none ]] || continue
    case "$TRACK:$provider" in 1:github|2:azure|3:*) ;; *) err 'Cloning requires a selected hosting provider.'; return 2 ;; esac
    [[ -n "$url" ]] && hosting_clone_dir_valid "$destination" || {
      err "--$provider-clone-dir needs an absolute, non-symlink destination and a verification URL."; return 2; }
  done
  [[ "${GITHUB_CLONE_DIR:-none}" == none || "${GITHUB_CLONE_DIR:-none}" != "${AZURE_CLONE_DIR:-none}" ]] || {
    err 'Choose different clone destinations for GitHub and Azure.'; return 2; }
}

hosting_gcm_path() {
  local executable
  executable="$(command -v git-credential-manager 2>/dev/null || true)"
  [[ -x "$executable" ]] || executable=/usr/local/bin/git-credential-manager
  [[ -x "$executable" ]] || return 1
  printf '%s' "$executable"
}

hosting_configure_helper() {
  local executable helper provider host key
  [[ "$AUTH_MODE" == https && "$HTTPS_HELPER" == gcm ]] || return 0
  executable="$(hosting_gcm_path)" || {
    [[ "$DRY_RUN" == 1 ]] || { err 'Git Credential Manager is missing; rerun the Installation Centre.'; return "$EX_GATE"; }
    executable=/usr/local/bin/git-credential-manager
  }
  if [[ "$DRY_RUN" != 1 ]]; then
    "$executable" --version >/dev/null || { err 'Git Credential Manager cannot run.'; return "$EX_GATE"; }
    record_path_before_write "$HOME/.gitconfig"
  fi
  # Use an absolute, quoted helper so Apple Git and Homebrew Git both find it.
  printf -v helper '!%q' "$executable"
  while IFS= read -r provider; do
    case "$provider" in github) host=github.com ;; azure) host=dev.azure.com ;; esac
    key="credential.https://$host.helper"
    # Explicit GCM consent replaces only this provider's helper chain.
    run git config --global --replace-all "$key" ''
    run git config --global --add "$key" "$helper"
  done < <(hosting_provider_ids)
}

hosting_git_transport() {
  local output="$1" seconds="$2"
  shift 2
  if [[ "$AUTH_MODE" == https ]]; then
    run_with_deadline "$output" "$seconds" env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never \
      git -c credential.interactive=never -c credential.modalPrompt=false \
      -c http.lowSpeedLimit=1 -c http.lowSpeedTime=20 "$@"
  else
    run_with_deadline "$output" "$seconds" env GIT_TERMINAL_PROMPT=0 \
      GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes' \
      git "$@"
  fi
}

hosting_verify_repo() {
  local provider="$1" url output status=0
  url="$(hosting_repo_url "$provider")"
  if [[ -z "$url" ]]; then
    warn "Provide --$provider-repo with one accessible repository to verify Git access; CLI login alone is insufficient."
    return "$EX_MANUAL"
  fi
  hosting_repo_valid "$provider" "$url" "$AUTH_MODE" || return "$EX_MANUAL"
  output="$(mktemp "${TMPDIR:-/tmp}/day-one-git-access.XXXXXX")"
  chmod 600 "$output"
  # Never emit refs, repository names or authentication errors into setup logs.
  # Verification cannot open a browser or prompt; bootstrap credentials in the
  # user's interactive terminal first, then rerun this bounded check.
  hosting_git_transport "$output" 60 ls-remote "$url" HEAD || status=$?
  rm -f "$output"
  if [[ "$status" != 0 ]]; then
    warn "$provider Git repository access failed (exit $status). In an interactive terminal, run git ls-remote with your selected clone URL, complete browser sign-in or enter a PAT, then rerun Phase 4."
    return "$EX_MANUAL"
  fi
}

hosting_clone_matches() {
  local destination="$1" url="$2" root
  [[ -d "$destination" ]] || return 1
  root="$(git -C "$destination" rev-parse --show-toplevel 2>/dev/null || true)"
  [[ "$root" == "$(cd "$destination" && pwd -P)" && \
      "$(git -C "$destination" remote get-url origin 2>/dev/null || true)" == "$url" ]] && \
    git --no-optional-locks -c core.fsmonitor=false -C "$destination" status --porcelain >/dev/null 2>&1
}

hosting_clone_selected_repos() {
  local provider destination url output status
  while IFS= read -r provider; do
    destination="$(hosting_clone_dir "$provider")"
    [[ "$destination" != none ]] || continue
    url="$(hosting_repo_url "$provider")"
    hosting_clone_dir_valid "$destination" || return "$EX_MANUAL"
    if [[ -e "$destination" ]]; then
      if hosting_clone_matches "$destination" "$url"; then
        info "$provider clone already exists; working files left unchanged."
        continue
      fi
      warn "$provider clone destination is already occupied. Choose another destination; nothing was overwritten."
      return "$EX_MANUAL"
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
      print_command git clone -- "$url" "$destination"
      continue
    fi
    mkdir -p "$(dirname "$destination")" || return "$EX_GATE"
    output="$(mktemp "${TMPDIR:-/tmp}/day-one-git-access.XXXXXX")"
    chmod 600 "$output"
    status=0
    hosting_git_transport "$output" 300 clone -- "$url" "$destination" || status=$?
    rm -f "$output"
    if [[ "$status" != 0 ]]; then
      warn "$provider clone failed (exit $status). Any partial destination was preserved; review it before retrying."
      return "$EX_MANUAL"
    fi
    hosting_clone_matches "$destination" "$url" || {
      warn "$provider clone returned success but its working tree or origin is unavailable. Review the destination."
      return "$EX_GATE"; }
    info "$provider repository cloned to the selected destination; it remains user-owned."
  done < <(hosting_provider_ids)
}

hosting_verify_selected_repos() {
  local provider
  while IFS= read -r provider; do
    hosting_verify_repo "$provider" || return $?
  done < <(hosting_provider_ids)
}
