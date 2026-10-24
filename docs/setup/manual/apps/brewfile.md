# Maintain a selective Brewfile

Use this task when Homebrew is installed and you want to maintain a selective
Brewfile. Complete [Homebrew setup](../homebrew.md) first. Keep each application's
existing installation owner and back up the Brewfile before editing it.
Chezmoi commands apply only when chezmoi owns that file.

If using the private report paths below, first create the directory with `mkdir -p "$HOME/.local/state/development-setup"` and restrict it with `chmod 700 "$HOME/.local/state/development-setup"`. Expected: reports remain local and outside the repository.

## 1. Inventory the selected software

```bash
brew list --formula | LC_ALL=C sort
brew list --cask | LC_ALL=C sort
command -v mas >/dev/null 2>&1 && mas list || true
command -v code >/dev/null 2>&1 && code --list-extensions --show-versions | LC_ALL=C sort || true
```

Record the existing installation owner beside each application. Review the inventory
before deciding that anything is obsolete. An application absent from Homebrew
still has a separate installation owner; review that owner before changing it.

## 2. Back up the desired-state file

Run this backup before editing an existing Brewfile. Each run uses a new private
directory, so it preserves earlier copies. If a command fails, stop and fix the
reported error before editing the Brewfile.

```bash
(
  set -eu
  umask 077
  if [ -e "$HOME/Brewfile" ] || [ -L "$HOME/Brewfile" ]; then
    mkdir -p "$HOME/.local/state/development-setup/manual-backups"
    brewfile_backup=$(mktemp -d "$HOME/.local/state/development-setup/manual-backups/Brewfile.XXXXXX")
    cp "$HOME/Brewfile" "$brewfile_backup/Brewfile"
    cmp "$HOME/Brewfile" "$brewfile_backup/Brewfile"
    printf 'Verified backup: %s\n' "$brewfile_backup/Brewfile"
  else
    printf 'No existing Brewfile to back up.\n'
  fi
)
```

Expected result: the command prints a verified backup path, or confirms that no
Brewfile exists. Keep the printed path for recovery.

If chezmoi owns the Brewfile, inspect its source and pending changes:

```bash
chezmoi source-path "$HOME/Brewfile"
chezmoi diff
```

If you selected chezmoi ownership and the Brewfile is not managed, add it only
after reviewing its contents:

```bash
chezmoi add "$HOME/Brewfile"
```

## 3. Structure the Brewfile for humans

Keep the supported declaration types grouped, with alphabetical entries inside
human-purpose sections:

```ruby
# Command-line foundation
brew "chezmoi"
brew "ghq"
brew "git"

# Optional terminal experience
brew "bat"
brew "eza"
brew "fzf"

# Selected desktop applications
# Include only applications that this Mac intentionally manages with Homebrew.
cask "1password"
cask "1password-cli"
cask "raycast"
cask "visual-studio-code"
cask "warp"

# Optional desktop applications
cask "dbeaver-community"
cask "orbstack"

# Third-party optional maintenance application
tap "jithin-sabu/tap"
cask "jithin-sabu/tap/purge"

# Mac App Store — only when mas is intentionally used
# mas "Example", id: 123456789

# VS Code extensions
vscode "esbenp.prettier-vscode"
```

Do not chase a fixed total. The correct count is the set intended for this Mac
and track. Preserve taps, declaration options, comments, and custom statements
that are still understood.

An externally installed selected application is intentionally absent from the
Brewfile. Confirm its existing installer and update channel before adding it to Homebrew.

## 4. Treat the four categories differently

| Category | Selection policy | Removal policy |
|---|---|---|
| Formulae | Keep required tools plus deliberately selected CLI tools | Do not make formula removal a toggle; inspect reverse dependencies first |
| Casks | Select applications actually wanted **and Homebrew-managed** on this Mac | Back up application data, then remove only explicitly selected Homebrew extras |
| Mac App Store | Record only applications reproducible by the signed-in Apple account | Remove through the application owner or Finder after data review |
| VS Code extensions | Keep a minimal Default profile; add profile-specific extensions only when needed | Export profile/settings first, then uninstall named IDs |

This distinction prevents a visual selector from removing a formula that is a
dependency of another tool.

## 5. Build choices from the current file

Use the current Brewfile as the catalogue, not a hard-coded list:

```bash
printf '\nFormulae (preserved)\n'
sed -nE 's/^brew "([^"]+)".*/\1/p' "$HOME/Brewfile" | LC_ALL=C sort

printf '\nCasks (selectable)\n'
sed -nE 's/^cask "([^"]+)".*/\1/p' "$HOME/Brewfile" | LC_ALL=C sort

printf '\nVS Code extensions (selectable)\n'
sed -nE 's/^vscode "([^"]+)".*/\1/p' "$HOME/Brewfile" | LC_ALL=C sort
```

When adding something discovered on this Mac, verify its canonical token first:

```bash
# Read-only examples; use the selected package's exact token.
brew search git
brew info --formula git
brew info --cask visual-studio-code
code --list-extensions | rg -i 'prettier'
```

Use the extension's full publisher ID in the Brewfile, even when the VS Code UI
shows a friendly product name.

## 6. Preview installation and drift

```bash
brew bundle check --file="$HOME/Brewfile" --no-upgrade
brew bundle install --file="$HOME/Brewfile" --dry-run
brew bundle cleanup --file="$HOME/Brewfile"
```

The cleanup command above is a report unless `--force` is added. Read every
candidate. Formulae can appear because of dependency topology, and a cask may
own application data that a package list cannot describe.

After review, install missing declarations:

```bash
brew bundle install --file="$HOME/Brewfile"
```

## 7. Handle cask removal recoverably

Before removing a cask:

1. Quit the application.
2. Export its settings through its own UI when available.
3. Identify its support directories under `~/Library`.
4. Copy those directories to a dated private recovery archive.
5. Use `brew uninstall --cask <token>` without `--zap` first.
6. Record the token and archive location in a Markdown report.

Do not use `--zap` until its listed artefacts have been reviewed. Zap metadata
can include preferences shared with another edition of an application.

## 8. Handle VS Code removal recoverably

Export each profile that matters before changing extensions. The separate
optional VS Code profile guide describes granular cleanup of extensions,
settings, keybindings, snippets, profiles, workspace state, and history.

Quit VS Code first. Inventory the default profile and copy all profile settings:

Expected result: a new `Verified backup` path. A failed copy stops this block;
keep any partial directory for inspection and do not remove extensions yet.
For named profiles, export each profile through VS Code first, including its
extension list, then quit it again. The default CLI inventory is not a list
of every profile's extensions.

```bash
(
  set -euo pipefail
  umask 077
  backup_root="$HOME/.local/state/development-setup/vscode-backups"
  mkdir -p "$backup_root"
  backup_dir="$(mktemp -d "$backup_root/backup.XXXXXX")"
  code --list-extensions --show-versions > "$backup_dir/extensions.txt"
  cp -R "$HOME/Library/Application Support/Code/User" "$backup_dir/User"
  diff -qr "$HOME/Library/Application Support/Code/User" "$backup_dir/User"
  printf 'Verified backup: %s\n' "$backup_dir"
)
```

Remove only a named, reviewed extension:

```bash
printf 'Exact extension identifier to remove: '
IFS= read -r extension_id
if [[ "$extension_id" == *.* && "$extension_id" != -* ]]; then
  code --uninstall-extension "$extension_id"
else
  printf 'No valid extension identifier supplied; nothing removed\n' >&2
fi
```

Reinstall from the captured inventory by stripping the version suffix one line
at a time and reviewing compatibility; do not pipe an unreviewed list straight
into an installer.

## 9. Record the final state with chezmoi

Complete this section only when chezmoi owns the Brewfile. If you maintain it
directly, save the reviewed file, repeat the backup step and continue to
Verification and next steps.

```bash
chezmoi add "$HOME/Brewfile"
chezmoi diff
chezmoi apply "$HOME/Brewfile"
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

For a local-only chezmoi source, update its encrypted backup. If private Git is
the selected protection method, review and commit the source:

```bash
cd "$(chezmoi source-path)"
git diff -- Brewfile
git add Brewfile
git commit -m "chore: curate advanced Homebrew desired state"
```

## Rollback

Restore the previous Brewfile through chezmoi or from the manual backup, preview
its diff, and reinstall missing desired packages. Restoring a Brewfile does not
automatically reinstall application data removed with a cask.

## Verification and next steps

Run `brew bundle check --file="$HOME/Brewfile" --no-upgrade` against the reviewed
file. Expected result: the check succeeds for the selected declarations.
Keep the verified backup path with your private inventory. If you arrived from
an assisted module, return after reviewing the final inventory.

## Troubleshooting

| Symptom | Next action |
|---|---|
| The backup command fails | Stop before editing; check the reported source path, destination and permissions |
| The bundle check reports a missing item | Review that declaration and its installation owner before installing it or changing the file |
| An installed app is absent from Homebrew | Check its existing installation owner; it may be managed outside Homebrew |
| The edited Brewfile is wrong | Follow Rollback using the verified backup; application data needs its own recovery copy |
