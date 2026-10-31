# Native tool workflows for Warp

These workflows run native developer tools directly. Review the visible command
and its placeholders before running it. Import selected YAML files through
Warp's workflow import interface; no Day One Mac command or export utility is
needed. Download reviewed files from the repository or an extracted archive.

Git, Homebrew, chezmoi and provider commands require their own installations and
account permissions. Remove previously imported manager-dependent workflows
using Warp's interface; importing this set does not update old copies.

| File | Command |
|---|---|
| `03 Repositories and Hosting/01-ghq-root.yaml` | `"ghq root"` |
| `03 Repositories and Hosting/02-ghq-list.yaml` | `"ghq list"` |
| `03 Repositories and Hosting/03-ghq-clone.yaml` | `'ghq get "{{repository}}"'` |
| `03 Repositories and Hosting/04-git-status.yaml` | `"git status --short --branch"` |
| `03 Repositories and Hosting/05-git-remotes.yaml` | `"git remote --verbose"` |
| `03 Repositories and Hosting/06-github-auth.yaml` | `"gh auth status"` |
| `03 Repositories and Hosting/07-azure-account.yaml` | `"az account show --output table"` |
| `03 Repositories and Hosting/08-azure-repositories.yaml` | `"az repos list --output table"` |
| `04 Dotfiles/01-chezmoi-status.yaml` | `"chezmoi status"` |
| `04 Dotfiles/02-chezmoi-diff.yaml` | `"chezmoi diff"` |
| `04 Dotfiles/03-chezmoi-doctor.yaml` | `"chezmoi doctor"` |
| `04 Dotfiles/04-chezmoi-managed.yaml` | `"chezmoi managed"` |
| `04 Dotfiles/05-chezmoi-edit.yaml` | `'chezmoi edit "{{target}}"'` |
| `04 Dotfiles/06-chezmoi-apply.yaml` | `'chezmoi apply "{{target}}"'` |
| `04 Dotfiles/07-chezmoi-verify.yaml` | `"chezmoi verify"` |
| `05 Toolchains/01-tool-versions.yaml` | `'for tool in fnm node npm pnpm uv; do if command -v "$tool" >/dev/null 2>&1; then printf "%-8s " "$tool"; "$tool" --version; else printf "%-8s not installed\n" "$tool"; fi; done'` |
| `05 Toolchains/02-fnm-current.yaml` | `"fnm current"` |
| `05 Toolchains/03-fnm-install-lts.yaml` | `"fnm install --lts --use"` |
| `05 Toolchains/04-npm-scripts.yaml` | `"npm run"` |
| `05 Toolchains/05-npm-audit.yaml` | `"npm audit"` |
| `05 Toolchains/06-pnpm-install-frozen.yaml` | `"pnpm install --frozen-lockfile"` |
| `05 Toolchains/07-pnpm-audit.yaml` | `"pnpm audit"` |
| `05 Toolchains/08-pnpm-store-status.yaml` | `"pnpm store status"` |
| `05 Toolchains/09-uv-python-list.yaml` | `"uv python list"` |
| `05 Toolchains/10-uv-sync-locked.yaml` | `"uv sync --locked"` |
| `06 Homebrew/01-brewfile-check.yaml` | `'brew bundle check --file="$HOME/Brewfile" --no-upgrade'` |
| `06 Homebrew/02-outdated.yaml` | `"brew outdated --greedy"` |
| `06 Homebrew/03-update-metadata.yaml` | `"brew update"` |
| `06 Homebrew/04-doctor.yaml` | `"brew doctor"` |
| `06 Homebrew/05-cleanup-preview.yaml` | `"brew cleanup --dry-run"` |
| `06 Homebrew/06-autoremove-preview.yaml` | `"brew autoremove --dry-run"` |
