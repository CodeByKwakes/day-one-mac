[← VS Code profiles](12-vscode-profiles.md) · **🤖 ⚙️ Optional 13** · [Warp Drive →](14-warp-drive.md)

# Optional 13 — Enhanced command-line toolkit 🤖 ⚙️

This module restores the richer terminal tools intentionally left out of the
eight-phase minimum. It is optional, repeatable, and independent of the hosting
track. It includes `eza`, `zsh-autosuggestions`, `lazydocker`, and a reviewed
catalogue of navigation, Git, container, content, development, and diagnostic
formulae.

## What the selector does

The catalogue lives in `config/optional-formulae.tsv`, sorted by group and
formula. The selector shows required base tools separately so they cannot be
toggled off. It checks every optional formula before installation and records
only newly installed formulae and dependencies in the normal day-one-mac
manifest.

It never uninstalls a formula merely because it is unselected. This avoids
removing a dependency that another tool or project still needs.

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

In the selector, use Up/Down (or `j`/`k`) to move, Space to toggle, `a` for all,
`n` for none, and Enter to review the checked items before installation. The
required formulae appear with 🔒 and cannot be toggled. `--check` returns a
non-zero status when a selected tool is missing, which is useful in an audit:

```bash
day-one-mac cli-tools \
  --packages eza,zsh-autosuggestions,lazydocker \
  --check
```

## Add shell integration through chezmoi

Installing a formula and changing shell behaviour are separate actions. Edit
the managed shell file rather than allowing an installer to mutate it:

```bash
chezmoi edit ~/.config/zsh/aliases.zsh
```

Add the `eza` block to `aliases.zsh` only when selected:

```zsh
# Better directory listing; remove these aliases if scripts expect BSD ls.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza --long --all --git --group-directories-first'
  alias lt='eza --tree'
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
activates them in the next shell; do not add a second source or `compinit`.

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
- [ ] Required base formulae remained visible and could not be toggled off.
- [ ] Any newly selected formula is declared once in the managed Brewfile.
- [ ] `brew bundle check --file="$HOME/Brewfile" --no-upgrade` succeeds.
- [ ] Only selected shell integrations were added, and a new login shell opens
      without an error.
- [ ] `AUTO_CD` is on only if you chose it, and you accepted that a bare word
      which is a directory but not a command now changes directory.
- [ ] Any intentional removal was checked with `brew uses --installed` first.

---

[← VS Code profiles](12-vscode-profiles.md) · [Warp Drive →](14-warp-drive.md) · [Project home](../README.md)
