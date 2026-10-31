[← the base shell task](README.md) · [Shell automation](package-workflows.md)

# Add, edit, save, and remove Zsh aliases

An **alias** gives a short name to a longer Terminal command. Keep aliases in
`~/.config/zsh/aliases.zsh` and load that file once from `.zshrc`, as shown in
the [Zsh setup](zsh.md). Choose the editing route that owns your files:

- User-owned: back up the file, edit it directly, run `/bin/zsh -n` on it and
  open a new terminal. Skip all `chezmoi` commands below.
- Chezmoi-owned: edit the source, preview and apply the named target. Follow
  [chezmoi workflows](chezmoi.md) for source backup and private Git choices.

For user-owned files, create the directory and open the file with your editor:

```bash
mkdir -p "$HOME/.config/zsh"
nano "$HOME/.config/zsh/aliases.zsh"
```

Expected result: the editor opens the actual file. In nano, use Ctrl+O then
Enter to save and Ctrl+X to exit. Before editing an existing file, keep a
separate dated backup. In the numbered example below, use this editor action
instead of `chezmoi edit`, and validate the actual file instead of its source.

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

Example: add `cprojects` to open `~/Developer`. Create that directory first
with `mkdir -p "$HOME/Developer"`, or substitute your chosen existing root.

### 1. Open the chezmoi source version

```bash
chezmoi edit "$HOME/.config/zsh/aliases.zsh"
```

For chezmoi-owned files, the configured editor opens the source copy. If it
uses VS Code with `--wait`, leave this Terminal window open.

### 2. Add the alias in the correct group

Add:

```zsh
# Repository navigation
alias cprojects='cd "$HOME/Developer"'
```

The single quotes keep `$HOME` inside the alias definition until it runs.
If you selected ghq, `alias cprojects='cd "$(ghq root)"'` is an alternative;
verify `ghq root` first.

### 3. Save and close the editor

In VS Code:

1. Press `⌘S` to save.
2. Close the file tab with `⌘W`.
3. Return to Terminal. The waiting `chezmoi edit` command finishes.

For another editor, use its normal save-and-close action.

### 4. Check syntax before applying

```bash
/bin/zsh -n "$(chezmoi source-path "$HOME/.config/zsh/aliases.zsh")"
```

No output means the syntax parsed successfully. An error gives the line number;
reopen the file and correct it before continuing.

### 5. Review and apply

```bash
chezmoi diff
chezmoi apply "$HOME/.config/zsh/aliases.zsh"
```

Read the diff before applying. Only the alias you intended should change.
If you configured the optional VS Code integration, `cmdiff` opens the graphical comparison,
`cmdifftext` prints a unified diff in Terminal, and `cmmerge TARGET` opens the
three-way merge editor when both copies contain changes worth keeping.

### 6. Load and test it

Start a new macOS Zsh login shell (or your selected Homebrew Zsh):

```bash
exec /bin/zsh -l
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
/bin/zsh -n "$(chezmoi source-path "$HOME/.config/zsh/aliases.zsh")"
chezmoi diff
chezmoi apply "$HOME/.config/zsh/aliases.zsh"
exec /bin/zsh -l
```

## Remove an alias

Delete its complete `alias …` line through the selected owner, then check
syntax and save/apply the named file. Until a new shell opens, remove the old in-memory definition with:

```bash
unalias cprojects
```

Opening a new shell after applying is simpler and confirms the saved state:

```bash
exec /bin/zsh -l
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
| Alias works now but disappears later | Check the selected owner saved the file and `.zshrc` loads it; apply the source if using chezmoi |
| `command not found` after applying | Run `exec /bin/zsh -l`, then check `echo "$ZSH_VERSION"` and `type -a <command>` |
| Alias name behaves unexpectedly | Run `type -a NAME` and choose a name that does not mask another command |
| Quoting error | Use `zsh -n` on the chezmoi source path before applying |

---

[Return to the base shell task →](zsh.md)

## Add shell integration with your selected configuration owner

Install the optional plugins you selected:

```bash
brew install zsh-completions zsh-autosuggestions zsh-syntax-highlighting
```

For **user-owned configuration**, edit `~/.zshrc` directly with your editor.
For **chezmoi-owned configuration**, use `chezmoi edit ~/.zshrc`, review
`chezmoi diff`, then apply. Do not run chezmoi commands for user-owned files.

The [Zsh baseline](zsh.md) contains these blocks. Merge only missing blocks into an existing file:

1. Add Homebrew's `site-functions` and `zsh-completions` directories to `fpath`
   before the existing `autoload -Uz compinit` and completion initialization.
   Preserve Docker and other completion paths; initialize completion once.
2. Source `zsh-autosuggestions` through the readable-file guard before Starship
   initialization. Keep persistent history enabled for history suggestions.
3. Source `zsh-syntax-highlighting` through its guard as the final integration.
4. In VS Code's active profile, enable the shell integration and suggestion
   settings from the [VS Code guide](../editors/vscode.md). Close existing terminals and open a new Zsh terminal.

Try `git ch` followed by **Tab**, start typing a command already in your history
and press **Right Arrow** to accept its grey suggestion, or press **Ctrl+Space**
for VS Code's terminal suggestion dropdown. Warp supplies its own input editor
and completions; guard Zsh completion and line-editor plugins so they do not
load there. Follow the [shared VS Code/Warp Zsh setup](zsh.md#1-use-zsh-consistently-in-vs-code-and-warp)
for the exact guard and profile settings. The baseline includes that Warp guard;
when updating an existing configuration, merge only the missing guarded blocks.

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

the base shell task already contains guarded integration for `zsh-completions`,
`zsh-autosuggestions` and `zsh-syntax-highlighting`. Installing those formulae
activates them in the next shell when those blocks are present; existing files
need the reviewed merge above. Do not add a second source or `compinit`.

Keep `eza` aliases in `aliases.zsh`. Keep `zoxide init`, completion `fpath`,
`compinit`, Starship and plugin source lines in `.zshrc`, in the order shown in
the base shell task. Syntax highlighting must remain the final integration.

### The `AUTO_CD` trade-off

Without it, typing a bare path runs it as a command, and zsh words the failure
confusingly - a directory is not executable, so you get a permission error
rather than anything about directories:

```text
$ ~
zsh: permission denied: /Users/your-name
```

`setopt AUTO_CD` makes `~`, `Developer`, and `..` change directory instead.

The cost is narrower than it first appears. **Commands always win**: a
directory called `ls` in your current folder does not shadow the `ls` command.
The only change is for a word that is *not* a command but *is* a directory
name - then zsh silently changes directory where it used to tell you the
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
not, `AUTO_CD` is close to free. It is opt-in here rather than in the the base shell task
baseline because it changes how every bare word is interpreted, which is a
personal preference rather than a setup requirement.

Review and apply:

```bash
chezmoi diff
chezmoi apply
exec /bin/zsh -l
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
does not install Docker Desktop or OrbStack. Complete the
[manual container setup](../databases/containers.md) if local containers are needed.
