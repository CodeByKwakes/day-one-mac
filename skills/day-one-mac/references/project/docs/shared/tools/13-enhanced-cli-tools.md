[← MCP servers](11-mcp-servers.md) · **🤖 ⚙️ Optional 13** · [Warp Drive →](14-warp-drive.md)

# Optional 13 - Enhanced command-line toolkit 🤖 ⚙️

This module restores the richer terminal tools intentionally left out of the
eight-phase minimum. It is optional, repeatable, and independent of the hosting
track. It includes `eza`, `zsh-autosuggestions`, `lazydocker`, and a reviewed
catalogue of navigation, Git, container, content, development, and diagnostic
formulae.

## What the selector does

The catalogue lives in `config/catalogs/optional-formulae.tsv`, sorted by group and
formula. The selector shows one category at a time, starting with Navigation.
Only explicitly selected optional tools are installed here.
It checks every optional formula before installation and records
only newly installed formulae and dependencies in the normal day-one-mac
manifest.

It never uninstalls a formula merely because it is unselected. This avoids
removing a dependency that another tool or project still needs.

Apply saves selected formulae separately from installation ownership. This
includes selected tools that were already installed, without claiming them as
Day One-owned. Failed installs retain the selection and a private run journal;
`day-one-mac cli-tools --saved` resumes it.

For the shared Phase-8-gated interface, use
`day-one-mac tool --module 13 --plan --packages eza,fzf`, then the same
selection with `--apply`. Use `--check` or `--resume` without a selection to
inspect or finish the saved work. Plans and checks never save state.
See the [execution reference](../reference/module-execution.md).

## Record the selection in the Brewfile

When a reviewed Brewfile exists, the script prints the exact `brew "token"`
declarations for the selected tools. It does not silently rewrite or sort that
file because doing so could discard its comments, taps, or intentional order.
After installation, edit the Brewfile through its selected owner. For user-owned
configuration, edit `~/Brewfile` directly. For chezmoi, use `chezmoi edit
"$HOME/Brewfile"`, review its diff and apply that target. Add each printed
`brew "token"` declaration once, preserving comments and order.

Run `brew bundle check --file="$HOME/Brewfile" --no-upgrade`.
Expected result: the intended declarations are satisfied without an upgrade.

An optional tool installed without old completion markers is included automatically when the
runner first creates `~/Brewfile`. A tool installed when its prerequisites are satisfied needs the
reviewed declaration above.

## Review or select tools

```bash
# Read-only catalogue with current installation state.
day-one-mac cli-tools --list

# Grouped interactive selector.
day-one-mac cli-tools

# Reproducible non-interactive selections.
day-one-mac cli-tools --packages eza,zsh-autosuggestions,lazydocker --dry-run
day-one-mac cli-tools --packages eza,zsh-autosuggestions,lazydocker
```

The selector shows the focused tool’s description below the choices, with
installed or missing labels beside each visible tool. Long categories use a
window of rows; the item counter shows where you are in the full category.

In the selector, use Left/Right (or `h`/`l`) to change category, Up/Down (or
`j`/`k`) to move between tools, and Space to toggle. `a` selects all tools in
the current category; `n` clears only that category. Selections stay checked
when you move between categories. Enter reviews all selected tools before
installation. The total selected count stays visible. Nothing is preselected.

Browse Navigation, Shell, Git, Containers, Content, Development and System
as needed. `--list` prints the complete catalogue with descriptions and
installation status. Explicit `--packages`, `--saved`, `--all` and `--check`
runs show only the selection summary, avoiding the full catalogue first.
`--check` returns a
non-zero status when a selected tool is missing, which is useful in an audit:

```bash
day-one-mac cli-tools \
  --packages eza,zsh-autosuggestions,lazydocker \
  --check
```

## Optional alias setup on the AI-assisted route

After an interactive install with `eza` selected, the CLI offers to add `ls`,
`ll` and `lt` aliases. Press Enter to skip. `--yes` accepts package installation
only; alias setup needs a separate yes or the explicit `--aliases` flag:

```bash
# Preview package installation and the alias block without writing files.
day-one-mac cli-tools --packages eza --aliases --aliases-owner unmanaged --dry-run

# Install or reuse eza, then add the optional aliases.
day-one-mac cli-tools --packages eza --aliases --aliases-owner unmanaged
```

The shared module interface accepts the same opt-in:

```bash
day-one-mac tool --module 13 --apply --packages eza --aliases --aliases-owner unmanaged
```

Prepare the shell first: `~/.zshrc` must already source
`~/.config/zsh/aliases.zsh`, and configuration ownership must be selected.
User-owned files receive an appended, marked block. Existing aliases and
functions keep their definitions, and rerunning the setup does not duplicate
the block. Existing content is backed up privately in the printed module run
folder before the write; a syntax check runs before replacement.

For chezmoi-owned configuration, the CLI updates the plain source file only
when it matches the live file, then [applies that single target with scripts
excluded](https://www.chezmoi.io/reference/commands/apply/). Templated files,
symlinks, unresolved ownership and source/live drift require the manual merge
below. If targeted apply fails, the source backup remains in the printed run
folder; review the source and live file before retrying.

Open a new terminal afterward. The aliases are guarded by the presence of
`eza`. Other tools and shell integrations keep their existing manual setup.
`--check` continues to verify packages; it does not verify alias activation.

## Add shell integration with your selected configuration owner

Installing a formula does not activate its shell hooks. Complete the selected
[manual Zsh integration](../../setup/manual/shell/zsh.md) and optional
[alias task](../../setup/manual/shell/aliases.md), then return here. Expected result:
a new shell recognises the selected tool without duplicate initialisation.
Do not add chezmoi solely to activate an optional tool.

## Remove an optional tool

The selector is installation-only. For an intentional removal, first check
dependents and then use Homebrew:

```bash
brew uses --installed eza
brew uninstall eza
brew autoremove --dry-run
```

Remove the corresponding chezmoi-managed shell block, run `chezmoi diff`, and
apply it. The broad cleanup removes every Homebrew formula; the precise rollback
also knows about optional formulae that this selector added.

## Optional completion checklist 🚦

- [ ] Every installed formula was deliberately selected.
- [ ] Required setup tools remained under their owning phases.
- [ ] Any newly selected formula is declared once in the managed Brewfile.
- [ ] `brew bundle check --file="$HOME/Brewfile" --no-upgrade` succeeds.
- [ ] Only selected shell integrations were added, and a new login shell opens
      without an error.
- [ ] `AUTO_CD` is on only if you chose it, and you accepted that a bare word
      which is a directory but not a command now changes directory.
- [ ] Any intentional removal was checked with `brew uses --installed` first.

---

[← MCP servers](11-mcp-servers.md) · [Warp Drive →](14-warp-drive.md) · [Project home](../../README.md)

## Alias ownership on a new setup

Use `--aliases-owner unmanaged` for a directly edited aliases file, or
`--aliases-owner chezmoi` for a plain chezmoi source that matches the live file.
Use the same option with `cli-tools` or `tool --module 13`. It requires
`--aliases` and does not transfer ownership or create legacy setup records.
If omitted, an existing saved ownership choice is used; otherwise apply stops.
Templates, symlinks and source/live drift still require manual resolution.
