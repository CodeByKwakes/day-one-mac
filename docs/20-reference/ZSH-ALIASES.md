[← Phase 5](../01-required/05-dotfiles-and-shell.md) · [Shell automation](../03-advanced/17-shell-and-package-automation.md)

# Add, edit, save, and remove Zsh aliases

This page focuses on alias syntax. For the complete process that carries an
edit from the chezmoi source to the active file and then into the private
dotfiles repository, follow [Manage dotfiles with chezmoi](MANAGING-DOTFILES-WITH-CHEZMOI.md).

An **alias** gives a short name to a longer Terminal command. Day One Mac keeps
aliases in one chezmoi-managed file:

```text
~/.config/zsh/aliases.zsh
```

Do not scatter aliases through `.zprofile`, `.zshrc`, Warp settings, and random
snippets. `.zshrc` already loads this file for every interactive shell.

## Before adding an alias

Choose a name that does not replace an important command. Check it first:

```bash
type myalias
```

`not found` means the name is free. If it already names a command, function,
or alias, choose another name unless replacing it is deliberate and documented.

Alias syntax is:

```zsh
alias shortname='long command'
```

Use straight single quotes, not typographic “smart quotes.” Never put a token,
password, private key, or `.env` value in an alias.

## Add a new alias

Example: add `cprojects` to open the ghq repository root.

### 1. Open the chezmoi source version

```bash
chezmoi edit "$HOME/.config/zsh/aliases.zsh"
```

The configured editor opens the source copy. Phase 5 normally configures VS
Code with `--wait`, so leave this Terminal window open.

### 2. Add the alias in the correct group

Add:

```zsh
# Repository navigation
alias cprojects='cd "$(ghq root)"'
```

Command substitution remains inside the single-quoted alias definition, so
`ghq root` is evaluated when the alias is used, not when the shell starts.

### 3. Save and close the editor

In VS Code:

1. Press `⌘S` to save.
2. Close the file tab with `⌘W`.
3. Return to Terminal. The waiting `chezmoi edit` command finishes.

For another editor, use its normal save-and-close action.

### 4. Check syntax before applying

```bash
/opt/homebrew/bin/zsh -n "$(chezmoi source-path "$HOME/.config/zsh/aliases.zsh")"
```

No output means the syntax parsed successfully. An error gives the line number;
reopen the file and correct it before continuing.

### 5. Review and apply

```bash
chezmoi diff
chezmoi apply "$HOME/.config/zsh/aliases.zsh"
```

Read the diff before applying. Only the alias you intended should change.
With the Phase 5 VS Code integration, `cmdiff` opens the graphical comparison,
`cmdifftext` prints a unified diff in Terminal, and `cmmerge TARGET` opens the
three-way merge editor when both copies contain changes worth keeping.

### 6. Load and test it

Start a clean Homebrew-zsh login shell:

```bash
exec /opt/homebrew/bin/zsh -l
```

Confirm the definition:

```bash
type cprojects
alias cprojects
```

Then use it:

```bash
cprojects
pwd
```

## Edit an existing alias

Open the same source file:

```bash
chezmoi edit "$HOME/.config/zsh/aliases.zsh"
```

Change only the command inside the quotes. For example:

```zsh
# Before
alias gl='git log --oneline --graph --decorate -20'

# After
alias gl='git log --oneline --graph --decorate -30'
```

Then repeat the syntax, diff, apply, and reload steps:

```bash
/opt/homebrew/bin/zsh -n "$(chezmoi source-path "$HOME/.config/zsh/aliases.zsh")"
chezmoi diff
chezmoi apply "$HOME/.config/zsh/aliases.zsh"
exec /opt/homebrew/bin/zsh -l
```

## Remove an alias

Delete its complete `alias …` line through `chezmoi edit`, then review and
apply. Until a new shell opens, remove the old in-memory definition with:

```bash
unalias cprojects
```

Opening a new shell after applying is simpler and confirms the saved state:

```bash
exec /opt/homebrew/bin/zsh -l
type cprojects
```

The expected final result is `cprojects not found`.

## When to use a function instead

Use an alias for one clear command. Use a Zsh function when you need named
arguments, validation, several steps, or conditional logic:

```zsh
mkcd() {
  [[ $# -eq 1 ]] || { print 'Usage: mkcd DIRECTORY' >&2; return 2; }
  mkdir -p -- "$1" && cd -- "$1"
}
```

Functions can live in `aliases.zsh` while the file remains small. If functions
grow complex, move them to a separate managed `functions.zsh` and source it
from `.zshrc`.

## Safe alias rules

Good aliases are readable and reversible. Avoid aliases that hide:

- `git push --force`, resets, or hook bypasses;
- Homebrew upgrade and cleanup in one command;
- Docker or database prune/delete operations;
- package publication;
- AI unrestricted or full-auto modes; or
- commands containing credentials.

Use explicit preview aliases such as `brewcleanpreview` and type destructive
commands in full after reviewing their targets.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| `chezmoi edit` opens the wrong editor | Review `[edit]` in `~/.config/chezmoi/chezmoi.toml` |
| Alias works now but disappears later | Make sure it was edited in the chezmoi source, applied, and committed when using private Git |
| `command not found` after applying | Run `exec /opt/homebrew/bin/zsh -l`, then `day-one-mac shell-status` |
| Alias name behaves unexpectedly | Run `type -a NAME` and choose a name that does not mask another command |
| Quoting error | Use `zsh -n` on the chezmoi source path before applying |

---

[Return to Phase 5 →](../01-required/05-dotfiles-and-shell.md)
