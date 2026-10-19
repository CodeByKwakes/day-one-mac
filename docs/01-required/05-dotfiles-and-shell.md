# Phase 5 — Configuration ownership, shell, and prompt

This guide moved to [05-dotfiles-and-shell](../setup/assisted/05-dotfiles-and-shell.md). Use that page for the maintained instructions.

<!-- day-one-mac:compatibility-guide -->

## Outcome

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#outcome).

## Choose ownership, shell, and prompt first

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#choose-ownership-shell-and-prompt-first).

## How to use this phase

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#how-to-use-this-phase).

## How chezmoi separates files

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#how-chezmoi-separates-files).

## Step 5.1 — Choose the source and versioning mode

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-51--choose-the-source-and-versioning-mode).

### Existing private dotfiles repository

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#existing-private-dotfiles-repository).

### New source protected by private Git

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#new-source-protected-by-private-git).

### New local-only source

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#new-local-only-source).

## Step 5.2 — Configure the login shell

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-52--configure-the-login-shell).

## Step 5.3 — Configure interactive zsh

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-53--configure-interactive-zsh).

### Why both startup files load the shared PATH setup

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#why-both-startup-files-load-the-shared-path-setup).

### Existing `.zshenv` files

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#existing-zshenv-files).

## Step 5.3a — Safe aliases

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-53a--safe-aliases).

## Step 5.4 — Configure Starship

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-54--configure-starship).

## Step 5.5 — Store machine-local data

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-55--store-machine-local-data).

## Step 5.5a — Switch to the Homebrew zsh 🔴

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-55a--switch-to-the-homebrew-zsh-).

### 🔴 If a new terminal will not open

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#-if-a-new-terminal-will-not-open).

## Step 5.6 — Verify the standalone day-one-mac command

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-56--verify-the-standalone-day-one-mac-command).

## Step 5.7 — Add and inspect new-source targets

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-57--add-and-inspect-new-source-targets).

## Reference — what every Phase 5 file should contain

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#reference--what-every-phase-5-file-should-contain).

### `~/.zprofile`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#zprofile).

### `~/.config/zsh/path.zsh`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#configzshpathzsh).

### `~/.zshrc`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#zshrc).

### `~/.config/zsh/aliases.zsh`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#configzshaliaseszsh).

### `~/.gitconfig`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#gitconfig).

### `~/.gitignore_global`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#gitignore_global).

### `~/.ssh/config`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#sshconfig).

### `~/.config/starship.toml`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#configstarshiptoml).

### `~/.config/chezmoi/chezmoi.toml` — machine-local, not managed

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#configchezmoichezmoitoml--machine-local-not-managed).

### `~/.local/bin/day-one-mac`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#localbinday-one-mac).

## Never add these to chezmoi

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#never-add-these-to-chezmoi).

## Step 5.8 — Verify a new login shell

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#step-58--verify-a-new-login-shell).

## If you make a mistake — rerun or recover Phase 5

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#if-you-make-a-mistake--rerun-or-recover-phase-5).

### Correct the selected dotfiles mode

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#correct-the-selected-dotfiles-mode).

### Correct one managed file

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#correct-one-managed-file).

### Recover a broken login shell

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#recover-a-broken-login-shell).

### Understand `--reset-progress`

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#understand---reset-progress).

## Troubleshooting

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#troubleshooting).

## Phase 5 completion checklist 🚦

Continue at [this section](../setup/assisted/05-dotfiles-and-shell.md#phase-5-completion-checklist-).
