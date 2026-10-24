[← Advanced 15](15-full-dotfiles-and-bootstrap.md) · **🤖 ⚙️ Advanced 16** · [Advanced 17 →](17-shell-and-package-automation.md)

# Advanced 16 - Brewfile, applications, and editor inventory

**Time:** 45-90 minutes · **Required:** no · **Prerequisite:** required Phase 8

## Outcome

`~/Brewfile` becomes reviewed desired state rather than a blind dump. Formulae,
casks, Mac App Store applications, and VS Code extensions are grouped and
reproducible; removals are separately reviewed, backed up where possible, and
reported.

## 1. Capture reality without changing it

### Executable selected-payload route

For a recoverable installation of selected software, first generate candidates.
The command writes only to stdout; this shell redirection creates your review
file. Choose a new filename to avoid replacing an existing selection:

```bash
day-one-mac advanced --module 16 --inventory > software-selection.tsv
```

Open the file in your editor. Keep only rows you want on this Mac and add any
missing selections. Each uncommented row has exactly two fields separated by
one **tab**, not spaces. For example:

```text
app	obsidian
formula	bat
extension	esbenp.prettier-vscode
```

`app` accepts IDs from the application catalogue, not arbitrary cask names.
Inventory lists supported missing apps as commented candidates. Unknown casks
remain comments for manual review. `formula` accepts Homebrew formula tokens;
`extension` accepts lowercase `publisher.name` IDs for VS Code's **Default**
profile. Install and enable the `code` command before applying extension rows.
The runner does not install from VSIX files or configure other profiles.

Preview your reviewed file, then apply after Phase 8:

```bash
day-one-mac advanced --module 16 --plan --manifest software-selection.tsv
day-one-mac advanced --module 16 --apply --manifest software-selection.tsv --app-install-policy homebrew
day-one-mac advanced --module 16 --check
```

The application policy explicitly authorises Homebrew for missing catalogue
apps; existing external installations stay external. Formula rows already
select Homebrew, and extension rows select VS Code's installer. Already-present
selected rows are skipped, not explicitly upgraded or claimed as newly owned.
Installing a missing item can still add or change dependencies through its
package manager. Only add software whose source and permissions you reviewed.

After an error, resolve the reported blocker and run:

```bash
day-one-mac advanced --module 16 --resume --app-install-policy homebrew
```

Resume uses the snapshot saved at apply time, even if you edited or deleted the
original file. To change the selection, make a new `--plan` and `--apply`.
Removing a row never uninstalls anything.

This TSV is an installation selection, **not a replacement Brewfile**. The
runner never evaluates, rewrites or formats your Brewfile, preserving comments
and custom Ruby declarations. App Store purchases, licences, Settings Sync,
account setup, cleanup and guide completion remain manual. A passing check
proves only that selected payloads exist. Continue the guide below for the full
desired-state and reproducibility work.

## Complete the shared manual actions

Follow the linked task for the selected actions, verify them, then return here. Manual configuration has one owner; the module records evidence.

| Manual action | Guide |
|---|---|
| 1. Inventory the selected software | [Open task](../../manual/apps/brewfile.md#1-inventory-the-selected-software) |
| 2. Back up the desired-state file | [Open task](../../manual/apps/brewfile.md#2-back-up-the-desired-state-file) |
| 3. Structure the Brewfile for humans | [Open task](../../manual/apps/brewfile.md#3-structure-the-brewfile-for-humans) |
| 4. Treat the four categories differently | [Open task](../../manual/apps/brewfile.md#4-treat-the-four-categories-differently) |
| 5. Build choices from the current file | [Open task](../../manual/apps/brewfile.md#5-build-choices-from-the-current-file) |
| 6. Preview installation and drift | [Open task](../../manual/apps/brewfile.md#6-preview-installation-and-drift) |
| 7. Handle cask removal recoverably | [Open task](../../manual/apps/brewfile.md#7-handle-cask-removal-recoverably) |
| 8. Handle VS Code removal recoverably | [Open task](../../manual/apps/brewfile.md#8-handle-vs-code-removal-recoverably) |
| 9. Record the final state with chezmoi | [Open task](../../manual/apps/brewfile.md#9-record-the-final-state-with-chezmoi) |

## Advanced 16 completion checklist 🚦

- [ ] The application inventory has been reviewed.
- [ ] Formulae remain protected from bulk toggle removal.
- [ ] Cask and extension choices come from the current file and use canonical IDs.
- [ ] Selected applications have a recorded installation owner. Homebrew-owned applications and selected command-line tools remain declared; externally managed applications retain their existing owner.
- [ ] No fixed count is treated as a correctness gate.
- [ ] Every removal has an export/archive and Markdown record.
- [ ] `brew bundle check --no-upgrade` passes.
- [ ] The Brewfile is backed up through the selected configuration owner. Chezmoi users use the selected encrypted local backup or reviewed private Git workflow.

```bash
day-one-mac advanced --complete 16
```

---

[← Advanced 15](15-full-dotfiles-and-bootstrap.md) · [Continue to Advanced 17 →](17-shell-and-package-automation.md)
