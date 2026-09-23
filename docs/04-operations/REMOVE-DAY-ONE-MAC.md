[← Project home](../README.md) · **Remove or reset** · [Rollback reference →](ROLLBACK.md)

# Remove Day One Mac safely

Use this guide when you want to undo some or all of the development setup
without erasing macOS. The removal wizard is preview-first and separates
Day One-owned changes from pre-existing software and user projects.

This is not Apple's factory reset. It never formats a disk, removes the macOS
account, disables FileVault, or silently deletes cloud credentials.

## Start with the guided wizard

When the portable command is installed:

```bash
day-one-mac remove --guided
```

When the portable command is unavailable:

```bash
day-one-mac remove --guided
```

The first run should be a preview. Read the complete Homebrew ownership and
repository-risk report before rerunning the selected plan with execution.

## Choose the correct removal meaning

| Mode | Removes | Preserves |
|---|---|---|
| Preview | Nothing | Everything |
| Recorded changes | Manifest-owned Homebrew items, recorded paths, managed dotfiles and saved Day One state | Pre-existing/unrecorded Homebrew items, non-Homebrew apps, non-empty projects |
| Select sections | Only the toggled sections | Every untoggled section |
| Full development reset | Every Homebrew formula/cask and known development configuration | macOS, account, non-Homebrew apps, ordinary documents, and unselected high-risk data |

“Recorded” is the recommended choice for undoing this playbook. “Full” is for
returning the current account to a broadly clean development state.

## Section choices

Selective mode offers recorded Homebrew packages, recorded configuration,
chezmoi files and source, captured macOS preferences, container data, selected
`~/Developer` content, and Day One Mac state. The wizard reads the exact install
and path manifests under `~/.day-one-mac`; if they are missing, recorded
rollback refuses to guess ownership.

## How Homebrew ownership works

The inventory labels each installed item as **Day One recorded** or
**pre-existing or unrecorded — preserve**. Dependencies are removed only when
no installed formula uses them. Homebrew itself is removed only when Day One
recorded installing it and no preserved package remains. Company Portal, App
Store, and manual applications are never treated as Homebrew-owned merely
because an app with the same name exists.

Full mode offers cask zap separately. Zap may remove real support data, so
leave it off unless that data is backed up and meant to be removed.

## Developer-folder choices

`~/Developer` is kept unless selected. Selective mode can archive only the
current setup repository, individually toggled Git repositories and workspace
folders, or the complete Developer directory. The inventory marks repositories
as `DIRTY` or `NO-REMOTE` when they need special attention.

The recovery parent must already exist, must be absolute, and cannot be inside
`~/Developer` or `~/.day-one-mac`. Before moving Developer content, the script
changes to the home directory so moving the setup checkout cannot invalidate its own working
directory. It archives selected content instead of irreversibly deleting it. For
large folders, the terminal reports the approximate size, elapsed time,
percentage copied, and estimated time remaining while the move is running.

## Container and credential boundaries

Quit Docker Desktop and OrbStack before selecting local container data. Full
mode retains the established cleanup engine's progress, resume, and checksum
behavior.

The wizard does not automatically delete 1Password cloud vaults or items,
macOS Keychain contents, SSH private keys unless explicitly selected in Full
mode, or Obsidian vault contents merely because configuration is removed.

## Useful previews

```bash
day-one-mac remove --inventory
day-one-mac remove --mode recorded
day-one-mac remove --mode sections \
  --sections packages,config,dotfiles,macos,state
day-one-mac remove --mode full
```

Execution requires `--execute` and the exact confirmation phrase
`REMOVE DAY ONE MAC`. Use `--yes` only for already-reviewed automation.

## Recovery output

Selective removal creates `Day-One-Mac-Removal-<UTC timestamp>` below the
selected recovery parent. It contains a readable report, an operation log,
selected Developer/container data, and any nested precise rollback recovery.
Full mode places its established `Day-One-Mac-Clean-Recovery-*` bundle there.

If “everything” means removing the user account, applications, settings, and
personal files, use Apple's Erase All Content and Settings through Stage 0
Route A instead of this wizard.

---

[← Project home](../README.md) · [Detailed rollback and recovery reference →](ROLLBACK.md)
