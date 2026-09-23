[← Advanced 15](15-full-dotfiles-and-bootstrap.md) · **🤖 ⚙️ Advanced 16** · [Advanced 17 →](17-shell-and-package-automation.md)

# Advanced 16 — Brewfile, applications, and editor inventory

**Time:** 45–90 minutes · **Required:** no · **Prerequisite:** required Phase 8

## Outcome

`~/Brewfile` becomes reviewed desired state rather than a blind dump. Formulae,
casks, Mac App Store applications, and VS Code extensions are grouped and
reproducible; removals are separately reviewed, backed up where possible, and
reported.

## Step 16.1 — Capture reality without changing it

```bash
day-one-mac inventory
brew list --formula | LC_ALL=C sort
brew list --cask | LC_ALL=C sort
command -v mas >/dev/null 2>&1 && mas list || true
command -v code >/dev/null 2>&1 && code --list-extensions --show-versions | LC_ALL=C sort || true
```

The private application report is written below `~/.day-one-mac`. Review it
before deciding that anything is obsolete. An application absent from Homebrew
is still preserved by the broad cleanup tool.

## Step 16.2 — Back up the desired-state file

```bash
mkdir -p "$HOME/.day-one-mac/manual-backups"
cp "$HOME/Brewfile" \
  "$HOME/.day-one-mac/manual-backups/Brewfile.before-advanced-16" \
  2>/dev/null || true
chezmoi source-path "$HOME/Brewfile"
chezmoi diff
```

If the Brewfile is not managed, add it only after reviewing its contents:

```bash
chezmoi add "$HOME/Brewfile"
```

## Step 16.3 — Structure the Brewfile for humans

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

# Required desktop applications
# Include only applications that this Mac intentionally manages with Homebrew.
cask "1password"
cask "1password-cli"
cask "raycast"
cask "visual-studio-code"
cask "warp"

# Optional desktop applications
cask "orbstack"

# Mac App Store — only when mas is intentionally used
# mas "Example", id: 123456789

# VS Code extensions
vscode "esbenp.prettier-vscode"
```

Do not chase a fixed total. The correct count is the set intended for this Mac
and track. Preserve taps, declaration options, comments, and custom statements
that are still understood.

An externally installed required application is intentionally absent from the
Brewfile. Confirm its owner in `~/.day-one-mac/application-provenance.md`
instead of adding a duplicate cask declaration.

## Step 16.4 — Treat the four categories differently

| Category | Selection policy | Removal policy |
|---|---|---|
| Formulae | Keep required tools plus deliberately selected CLI tools | Do not make formula removal a toggle; inspect reverse dependencies first |
| Casks | Select applications actually wanted **and Homebrew-managed** on this Mac | Back up application data, then remove only explicitly selected Homebrew extras |
| Mac App Store | Record only applications reproducible by the signed-in Apple account | Remove through the application owner or Finder after data review |
| VS Code extensions | Keep a minimal Default profile; add profile-specific extensions only when needed | Export profile/settings first, then uninstall named IDs |

This distinction prevents a visual selector from removing a formula that is a
dependency of another tool.

## Step 16.5 — Build choices from the current file

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
brew search <name>
brew info <formula>
brew info --cask <cask>
code --list-extensions | rg -i '<publisher-or-name>'
```

Use the extension's full publisher ID in the Brewfile, even when the VS Code UI
shows a friendly product name.

## Step 16.6 — Preview installation and drift

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

## Step 16.7 — Handle cask removal recoverably

Before removing a cask:

1. Quit the application.
2. Export its settings through its own UI when available.
3. Identify its support directories under `~/Library`.
4. Copy those directories to a dated private recovery archive.
5. Use `brew uninstall --cask <token>` without `--zap` first.
6. Record the token and archive location in a Markdown report.

Do not use `--zap` until its listed artefacts have been reviewed. Zap metadata
can include preferences shared with another edition of an application.

## Step 16.8 — Handle VS Code removal recoverably

Export each profile that matters before changing extensions. The separate
optional VS Code profile guide describes granular cleanup of extensions,
settings, keybindings, snippets, profiles, workspace state, and history.

Inventory exact versions:

```bash
mkdir -p "$HOME/.day-one-mac/vscode-backups"
code --list-extensions --show-versions \
  > "$HOME/.day-one-mac/vscode-backups/extensions.before-advanced-16.txt"
cp -R "$HOME/Library/Application Support/Code/User" \
  "$HOME/.day-one-mac/vscode-backups/User.before-advanced-16" \
  2>/dev/null || true
```

Remove only a named, reviewed extension:

```bash
code --uninstall-extension <publisher.extension>
```

Reinstall from the captured inventory by stripping the version suffix one line
at a time and reviewing compatibility; do not pipe an unreviewed list straight
into an installer.

## Step 16.9 — Record the final state with chezmoi

```bash
chezmoi add "$HOME/Brewfile"
chezmoi diff
chezmoi apply "$HOME/Brewfile"
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

Then commit the source privately:

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

## Advanced 16 completion checklist 🚦

- [ ] The application inventory has been reviewed.
- [ ] Formulae remain protected from bulk toggle removal.
- [ ] Cask and extension choices come from the current file and use canonical IDs.
- [ ] Required 1Password, Raycast, VS Code, and Warp are either deliberately declared as Homebrew casks or recorded as valid external installations; chezmoi, ghq, Git, and selected stack/provider formulae remain declared.
- [ ] No fixed count is treated as a correctness gate.
- [ ] Every removal has an export/archive and Markdown record.
- [ ] `brew bundle check --no-upgrade` passes.
- [ ] The Brewfile is managed by chezmoi and committed privately.

```bash
day-one-mac advanced --complete 16
```

---

[← Advanced 15](15-full-dotfiles-and-bootstrap.md) · [Continue to Advanced 17 →](17-shell-and-package-automation.md)
