[← VS Code profiles](12-vscode-profiles.md) · **🤖 ⚙️ Optional 13** · [Warp Drive →](14-warp-drive.md)

# Optional 13 — Enhanced command-line toolkit 🤖 ⚙️

This module restores the richer terminal tools intentionally left out of the
eight-phase minimum. It is optional, repeatable, and independent of the hosting
track. It includes `eza`, `zsh-autosuggestions`, `lazydocker`, and a reviewed
catalogue of navigation, Git, container, content, development, and diagnostic
formulae.

## What the selector does

The catalogue lives in `config/optional-formulae.tsv`, sorted by group and
formula. The selector shows one category at a time, starting with Navigation.
Required setup tools stay under Phases 2–8 and cannot be toggled here.
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
`day-one-mac optional --module 13 --plan --packages eza,fzf`, then the same
selection with `--apply`. Use `--check` or `--resume` without a selection to
inspect or finish the saved work. Plans and checks never save state.
See the [execution reference](../20-reference/MODULE-EXECUTION.md).

## Record the selection in the Brewfile

When a Phase 8 Brewfile exists, the script prints the exact `brew "token"`
declarations for the selected tools. It does not silently rewrite or sort that
file because doing so could discard its comments, taps, or intentional order.
After installation, record the desired state through chezmoi:

```bash
chezmoi edit ~/Brewfile
# Add each declaration printed by configure-cli-tools.sh, once.
chezmoi diff ~/Brewfile
chezmoi apply ~/Brewfile
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

An optional tool installed before Phase 8 is included automatically when the
runner first creates `~/Brewfile`. A tool installed after Phase 8 needs the
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

## Optional alias setup on the script-assisted route

After an interactive install with `eza` selected, the CLI offers to add `ls`,
`ll` and `lt` aliases. Press Enter to skip. `--yes` accepts package installation
only; alias setup needs a separate yes or the explicit `--aliases` flag:

```bash
# Preview package installation and the alias block without writing files.
day-one-mac cli-tools --packages eza --aliases --dry-run

# Install or reuse eza, then add the optional aliases.
day-one-mac cli-tools --packages eza --aliases
```

The shared module interface accepts the same opt-in:

```bash
day-one-mac optional --module 13 --apply --packages eza --aliases
```

Complete Phase 5 first: `~/.zshrc` must already source
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

Use the same shell activation for the manual and script-assisted routes.
The plugins remain optional; VS Code's terminal suggestion dropdown is enabled
separately in [Phase 7](../01-required/07-vscode-base.md#step-73--use-the-minimal-settings-baseline).

On the script-assisted route, select `zsh-completions`, `zsh-autosuggestions`
and `zsh-syntax-highlighting` in the selector's Shell category, or run:

```bash
day-one-mac cli-tools --packages zsh-completions,zsh-autosuggestions,zsh-syntax-highlighting
```

On the manual route, install those same selected packages yourself:

```bash
brew install zsh-completions zsh-autosuggestions zsh-syntax-highlighting
```

For **user-owned configuration**, edit `~/.zshrc` directly with your editor.
For **chezmoi-owned configuration**, use `chezmoi edit ~/.zshrc`, review
`chezmoi diff`, then apply. Do not run chezmoi commands for user-owned files.

Fresh Phase 5 files already contain the required blocks. For an existing file,
merge only what is missing from
[Step 5.3](../01-required/05-dotfiles-and-shell.md#step-53--configure-interactive-zsh):

1. Add Homebrew's `site-functions` and `zsh-completions` directories to `fpath`
   before the existing `autoload -Uz compinit` and completion initialization.
   Preserve Docker and other completion paths; initialize completion once.
2. Source `zsh-autosuggestions` through the readable-file guard before Starship
   initialization. Keep persistent history enabled for history suggestions.
3. Source `zsh-syntax-highlighting` through its guard as the final integration.
4. In VS Code's active profile, enable the shell integration and suggestion
   settings from Phase 7. Close existing terminals and open a new Zsh terminal.

Try `git ch` followed by **Tab**, start typing a command already in your history
and press **Right Arrow** to accept its grey suggestion, or press **Ctrl+Space**
for VS Code's terminal suggestion dropdown. Warp supplies its own input editor
and completions; guard Zsh completion and line-editor plugins so they do not
load there. Follow the [shared VS Code/Warp Zsh setup](../10-app-guides/VSCODE-TYPESCRIPT.md#12-use-zsh-consistently-in-vs-code-and-warp)
for the exact guard and profile settings. Fresh Phase 5 files do not yet add
that Warp guard; merge it before using these optional plugins with Warp.

### Other optional shell integrations

Installing a formula and changing shell behaviour are separate actions. The
commands below show the chezmoi route; for user-owned files, edit the same
targets directly and omit `chezmoi diff` and `chezmoi apply`.

```bash
chezmoi edit ~/.config/zsh/aliases.zsh
```

Add the `eza` block to `aliases.zsh` only when selected:

```zsh
# Better directory listing; remove these aliases if scripts expect BSD ls.
if command -v eza >/dev/null 2>&1; then
  (( ${+aliases[ls]} || ${+functions[ls]} )) || alias ls='eza --group-directories-first'
  (( ${+aliases[ll]} || ${+functions[ll]} )) || alias ll='eza --long --all --git --group-directories-first'
  (( ${+aliases[lt]} || ${+functions[lt]} )) || alias lt='eza --tree'
fi
```

For interactive behaviour rather than aliases, edit the managed `.zshrc`:

```bash
chezmoi edit ~/.zshrc
```

Add these selected blocks before the Starship block:

```zsh

# Learned directory navigation.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Type a directory path on its own to change into it, so `~` goes home
# instead of failing. Read the trade-off below before adding this.
setopt AUTO_CD

```

Phase 5 already contains guarded integration for `zsh-completions`,
`zsh-autosuggestions` and `zsh-syntax-highlighting`. Installing those formulae
activates them in the next shell when those blocks are present; existing files
need the reviewed merge above. Do not add a second source or `compinit`.

Keep `eza` aliases in `aliases.zsh`. Keep `zoxide init`, completion `fpath`,
`compinit`, Starship and plugin source lines in `.zshrc`, in the order shown in
Phase 5. Syntax highlighting must remain the final integration.

### The `AUTO_CD` trade-off

Without it, typing a bare path runs it as a command, and zsh words the failure
confusingly — a directory is not executable, so you get a permission error
rather than anything about directories:

```text
$ ~
zsh: permission denied: /Users/your-name
```

`setopt AUTO_CD` makes `~`, `Developer`, and `..` change directory instead.

The cost is narrower than it first appears. **Commands always win**: a
directory called `ls` in your current folder does not shadow the `ls` command.
The only change is for a word that is *not* a command but *is* a directory
name — then zsh silently changes directory where it used to tell you the
command did not exist:

```text
# without AUTO_CD
$ gti
zsh: command not found: gti

# with AUTO_CD, if a directory named gti happens to exist
$ gti
# ...silently changes into it
```

That matters most if you keep directories named after common typos. If you do
not, `AUTO_CD` is close to free. It is opt-in here rather than in the Phase 5
baseline because it changes how every bare word is interpreted, which is a
personal preference rather than a setup requirement.

Review and apply:

```bash
chezmoi diff
chezmoi apply
exec /opt/homebrew/bin/zsh -l
```

Confirm `AUTO_CD` if you added it:

```bash
zsh -ic '[[ -o autocd ]] && echo "AUTO_CD is on" || echo "AUTO_CD is off"'
```

It is off on a clean macOS, so `AUTO_CD is off` before you add the line and
`AUTO_CD is on` after `chezmoi apply` plus a new shell is the expected change.

Verify the three requested examples:

```bash
eza --version
lazydocker --version
test -r "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
```

`lazydocker` needs a running Docker-compatible engine. Installing the formula
does not install Docker Desktop or OrbStack; use Optional 9 if local containers
are needed.

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

[← VS Code profiles](12-vscode-profiles.md) · [Warp Drive →](14-warp-drive.md) · [Project home](../README.md)
