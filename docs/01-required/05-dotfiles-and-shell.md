[← Phase 4](04-core-tools-and-hosting.md) · **Phase 5** · [Phase 6 →](06-language-toolchains.md)

# Phase 5 — chezmoi, the shell, and Starship

**Time:** 25–45 minutes · **Required:** everyone

A **dotfile** is a configuration file whose name begins with a dot, such as
`~/.zshrc` or `~/.gitconfig`. macOS hides these in Finder by default. They hold
your personal settings for the shell, Git, and similar tools. **chezmoi** keeps
a master copy of each one in a single folder so they can be reviewed, versioned,
and restored on another Mac. See [GLOSSARY.md](../20-reference/GLOSSARY.md) for related terms.

## Outcome

chezmoi owns a small, understandable set of dotfiles. Homebrew, pnpm, fnm, and
Starship initialize predictably; a portable `day-one-mac` command can locate
this project; machine-specific choices remain local; and no secret is copied
into the source directory.

## How to use this phase

Run `day-one-mac setup --phase 05`. For a new source, the runner creates
only the documented minimum. For an existing source, it shows the complete
chezmoi comparison and asks before applying. The manual commands below explain
the files and help with a stopped phase; do not recreate files after a pass.

Important: approval of an existing source covers **every target shown by
`chezmoi diff`**, not only the eight minimum files listed in this guide. Stop and
inspect any unfamiliar path before accepting the apply.

Phase 5 schema 12 introduces the shared `path.zsh` and `aliases.zsh` files and
keeps a comment-only `~/.ssh/config` for HTTPS-only machines. A Mac completed
under an older schema is revalidated. The runner creates missing shared files
but does not overwrite an existing `.zprofile` or `.zshrc`; it stops with the
exact source line that must be merged through chezmoi.

## How chezmoi separates files

There are three distinct locations:

| Location | Purpose | Commit it? |
|---|---|---|
| `~/.local/share/chezmoi` | Source files that reproduce targets | Private Git when selected; otherwise encrypted backup |
| Normal paths such as `~/.zshrc` | Files applications actually read | No separate commit; chezmoi applies them |
| `~/.config/chezmoi/chezmoi.toml` | Machine-local data and editor choice | No |

Use `chezmoi source-path` to inspect the source directory. Use `chezmoi managed`
to see which target files belong to it.

## Step 5.1 — Choose the source and versioning mode

For side-by-side copies of the deterministic shell files, open the
[Phase 5 shell-file reference](../20-reference/phase-05-shell-files/README.md).
Use it for comparison only; merge reviewed differences through chezmoi rather
than copying the complete folder over an existing setup.

For every later edit, follow [Manage dotfiles with chezmoi](../20-reference/MANAGING-DOTFILES-WITH-CHEZMOI.md).
It shows the complete source → preview → apply → validate → private Git commit
and push flow, including when `add`, `apply`, or `merge` is correct.

### Existing private dotfiles repository

Pass the repository to the runner:

```bash
day-one-mac setup \
  --phase 05 \
  --dotfiles-repo <private-repository-url>
```

The runner initializes the source, shows `chezmoi diff`, and asks before
applying changes. It records affected targets first so precise rollback can
restore the pre-apply state.

The existing source must ultimately manage:

```text
~/.zprofile
~/.zshrc
~/.config/zsh/path.zsh
~/.config/zsh/aliases.zsh
~/.gitconfig
~/.ssh/config
~/.config/starship.toml
```

If one is missing, the phase reports the exact target instead of silently
claiming completion. Edit the source with `chezmoi edit <target>` or add a
reviewed target with `chezmoi add <target>`.

### New source protected by private Git

When no repository is supplied, the runner executes:

```bash
chezmoi init
```

It creates the minimal targets below only when they do not already exist, then
adds them to the new source. Existing files are preserved for manual review.
Phase 8 then requires a private remote and pushed branch.

### New local-only source

Choose this when policy or preference means the source must not be Git
versioned:

```bash
day-one-mac setup --phase 05 --local-dotfiles
```

chezmoi still manages and applies the same files. Phase 8 performs the secret
scan but skips Git, remote-privacy and push gates. A new source has no required
version history or remote recovery, so include `~/.local/share/chezmoi` in an
encrypted backup.
The option never deletes an existing `.git` directory. Phase 8 reports any
pre-existing Git metadata and preserves it. To obtain a genuinely unversioned
source, create a separate reviewed source instead of automatically deleting
repository history.

## Step 5.2 — Configure the login shell

`~/.zprofile` is loaded by a login zsh. It delegates environment paths to one
shared file so login and non-login shells cannot drift apart:

```zsh
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"
```

The managed `~/.config/zsh/path.zsh` contains the idempotent PATH setup:

```zsh
typeset -U path PATH
if [[ -x /opt/homebrew/bin/brew ]] && {
  [[ ${HOMEBREW_PREFIX:-} != /opt/homebrew ]] ||
  [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] ||
  [[ ":$PATH:" != *":/opt/homebrew/sbin:"* ]]
}; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

export PNPM_HOME="$HOME/Library/pnpm" # Node.js selections only
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
```

`typeset -U path PATH` tells zsh to keep only the first occurrence of each
PATH directory. That protects repeated sourcing and partially configured
company-managed environments from accumulating duplicates.

Do not duplicate these blocks in `.zprofile` or `.zshrc`. Both startup files
source `path.zsh`; its guards make repeated sourcing safe.

## Step 5.3 — Configure interactive zsh

`~/.zshrc` runs for **every** interactive shell. It loads the shared PATH,
keeps persistent history, initializes completion exactly once, loads fnm and
safe aliases, then starts Starship. Optional syntax highlighting remains last:

```zsh
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY

for completion_dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do
  [[ -d "$completion_dir" ]] || continue
  (( ${fpath[(Ie)$completion_dir]} )) || fpath=("$completion_dir" $fpath)
done
unset completion_dir
autoload -Uz compinit
compinit

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

[[ -r "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
```

### Why both startup files load the shared PATH setup

zsh reads `~/.zprofile` only for **login** shells. A plain `zsh`, a tmux pane,
and some IDE terminals are interactive but *not* login shells, so they never
see it.

That matters because the blocks below are guarded by `command -v`. Without
Homebrew on `PATH`, `command -v starship` simply fails and the shell starts
with **no Starship prompt, no fnm, and no pnpm** — silently, with no error to
explain it. The same gap makes uv-installed Python invisible and is what
prompts uv to suggest `uv python update-shell`.

The shared file makes its work a no-op when the entries already exist. Phase 5
starts Homebrew zsh with an almost empty environment and verifies both shell
kinds, so it cannot accidentally pass because the parent terminal already had
Homebrew on PATH.

`SHARE_HISTORY` makes commands entered in one Warp tab available in another.
Remove only that option through `chezmoi edit ~/.zshrc` if separate per-tab
history is preferred; the history file and the remaining safety options still
work.

### Existing `.zshenv` files

Day One Mac does not create `.zshenv`, because that file affects every zsh,
including scripts. Phase 5 stops for review if an existing `.zshenv` changes
`ZDOTDIR` or disables normal startup files with `unsetopt RCS`. The safety
report and cleanup inventory include the file, but never rewrite it blindly.

## Step 5.3a — Safe aliases

Aliases live in `~/.config/zsh/aliases.zsh`, not in the middle of `.zshrc`.
The base contains only readable, non-destructive shortcuts:

```text
cdayone                 cd "$(day-one-mac root)"
gs / gd / gds / gl      Git status, diffs, and a short graph
gremotes                Git remote URLs
cm / cmstatus           chezmoi and its status inspection
cmdiff / cmdifftext     visual VS Code diff / terminal text diff
cmmerge                 VS Code three-way merge for one target
cmverify / cmdoctor     chezmoi verification
brewcheck / brewout     Homebrew inspection
brewcleanpreview        cleanup preview only
brewautopreview         autoremove preview only
```

They are added during Phase 5, after their dependencies exist, and are managed
by chezmoi. The `cdayone` alias uses the portable command that was installed at
the start and adopted into chezmoi here. No alias performs a
force push, cleanup, prune, publication, database deletion, or other
destructive action. Raycast command aliases are separate and do not belong in
this file.

For the complete edit, save, syntax-check, apply, reload, and removal workflow,
read [Add, edit, save, and remove Zsh aliases](../20-reference/ZSH-ALIASES.md).

This baseline is deliberately small. Optional shell behaviour — including
`setopt AUTO_CD`, which makes a bare `~` change to your home directory instead
of failing with `permission denied` — is offered in
[Module 13 — Enhanced CLI tools](../02-optional/13-enhanced-cli-tools.md).

**Do not run `uv python update-shell`.** Its job is to add `~/.local/bin` to
`PATH`, which the lines above already do. Running it appends a competing line
to a chezmoi-managed file; `chezmoi diff` will then show drift and a later
`chezmoi apply` will revert it. This is the same rule as Phase 6's "do not run
`pnpm setup`".

If `compinit` reports insecure directories, inspect them first:

```bash
zsh -f -c 'autoload -Uz compaudit && compaudit'
```

Remove group/other write permission only from the specific reported paths you
own. Do not apply a recursive chmod to `/opt/homebrew` or `$HOME`.

## Step 5.4 — Configure Starship

The runner creates `~/.config/starship.toml` only when absent:

```toml
add_newline = false
command_timeout = 1000

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

This is intentionally small. Add language, Git, cloud, or timing modules only
after confirming they are useful and do not slow every prompt.

Verify the file independently of the shell:

```bash
STARSHIP_CONFIG="$HOME/.config/starship.toml" starship prompt
```

This prints one rendered prompt, which looks like a stray `❯` possibly
surrounded by colour codes. That odd-looking line means the configuration
parsed correctly. A message mentioning an error or an unknown key is the
failure case; fix the named line in `starship.toml` and run it again.

## Step 5.5 — Store machine-local data

When absent, the runner creates `~/.config/chezmoi/chezmoi.toml`. The editor,
diff, and merge sections below are included only when VS Code is the selected
primary editor:

```toml
[edit]
command = "code"
args = ["--wait"]

[diff]
command = "code"
args = ["--wait", "--diff"]

[merge]
command = "bash"
args = [
  "-c",
  "cp {{ .Target | quote }} {{ printf \"%s.base\" .Target | quote }} && code --new-window --wait --merge {{ .Destination | quote }} {{ .Target | quote }} {{ printf \"%s.base\" .Target | quote }} {{ .Source | quote }}",
]

[data]
track = "github" # github, github+azure, or azure
stack = "both"   # node, python, or both
name = "Your Name"
email = "you@example.com"
```

The actual values come from Phase 1. This file stays on the machine and is not
added to the dotfiles repository. When VS Code is the selected primary editor,
the runner offers to add missing `diff` and `merge` sections to an existing
file. Existing custom tool sections are preserved, and the setup manifest keeps
the original before any accepted edit.

`chezmoi diff` now opens VS Code and waits until its comparison tabs close.
Use the built-in terminal renderer when you need text output in a log or script:

```bash
chezmoi --use-builtin-diff diff --no-pager
```

Phase 5 always uses that built-in form internally, so a graphical tool can
never stall its drift gate or make an empty stdout look like a clean source.

## Step 5.5a — Switch to the Homebrew zsh 🔴

macOS ships zsh at `/bin/zsh`. Day One Mac installs Homebrew's zsh as well and
makes it your login shell, so the shell tracks Homebrew updates rather than
macOS releases.

This is **the only step in Day One Mac that uses `sudo`**, and the only one
that changes a macOS account setting. Phase 5 asks twice before doing anything:

```text
  ℹ Current login shell: /bin/zsh
  ℹ Homebrew zsh: /opt/homebrew/bin/zsh (zsh 5.9.2)
  ⚠ /opt/homebrew/bin/zsh must be listed in /etc/shells before it can be a login shell.
  ⚠ This is the only step in Day One Mac that needs sudo; it appends one line.
Append /opt/homebrew/bin/zsh to /etc/shells with sudo? [y/N]:
  ✓ registered /opt/homebrew/bin/zsh in /etc/shells
  ⚠ Changing your login shell affects every new terminal.
  ⚠ If Homebrew zsh is ever removed, recover with: chsh -s /bin/zsh
Make /opt/homebrew/bin/zsh your login shell now? [y/N]:
  ✓ login shell changed to /opt/homebrew/bin/zsh
  ℹ Open a new terminal for it to take effect.
```

Declining either prompt leaves the login shell unchanged and stops Phase 5
safely as incomplete. The phase passes only after Directory Services reports
`/opt/homebrew/bin/zsh`. `/etc/shells` is only ever appended to, never
rewritten, and the runner refuses to switch to a binary that does not start.

Confirm afterwards in a **new** terminal:

```bash
dscl . -read "/Users/$(id -un)" UserShell
zsh --version
```

```text
UserShell: /opt/homebrew/bin/zsh
zsh 5.9.2 (arm64-apple-darwin25.0)
```

### 🔴 If a new terminal will not open

This is the failure mode worth knowing before you agree. If Homebrew's zsh is
later removed or broken, your login shell points at a missing binary. Recover
from any working shell — Terminal will still open with a fallback, and macOS
Recovery always works:

```bash
chsh -s /bin/zsh
```

The previous shell is also recorded at `~/.day-one-mac/previous-login-shell`.

## Step 5.6 — Verify the standalone day-one-mac command

The recommended start guide installs `~/.local/bin/day-one-mac` before Phase 1.
The checksum-verified runtime installer remains the sole owner of this file;
Phase 5 verifies it but never adds it to chezmoi. This boundary allows
`day-one-mac update` to switch versions without an older dotfiles source
restoring an obsolete launcher. See the
[early installer and download guide](../20-reference/PORTABLE-COMMAND.md).

When Phase 5 detects a launcher managed by an older Day One Mac installation,
it backs up that source entry below
`~/.day-one-mac/migrations/phase-05-standalone-launcher/`, runs
`chezmoi forget ~/.local/bin/day-one-mac`, and confirms the live executable was
preserved. It also merges only the reviewed Phase 4 Git keys into a plain
legacy `dot_gitconfig`; a templated Git source stops for a manual review.

The command reads one machine-local value:

```text
~/.day-one-mac/runtime-root
```

That value points to the stable `current` runtime link. It is deliberately
not stored in the dotfiles source because runtime state is machine-local. The
command exposes these stable operations:

```text
day-one-mac --status             Show track, stack, and phase progress
day-one-mac setup [options]      Run or inspect required phases
day-one-mac prepare-existing --guided  Choose Stage 0 Route A or Route B
day-one-mac safety-report        Create the Stage 0 read-only safety report
day-one-mac validate             Validate this independent project
day-one-mac shell-status         Inspect zsh, PATH, completions and shell tools
day-one-mac inventory            Write the application report
day-one-mac applications         Check required or optional app ownership
day-one-mac install              Install or revalidate required software
day-one-mac ssh-pin [provider]   Save a 1Password public key to ~/.ssh
day-one-mac workspace --guided   Create or open a bounded projectless task
day-one-mac macos-settings       Configure, inspect, or restore optional settings
day-one-mac optional --guided    Choose post-Phase-8 optional modules
day-one-mac finalize             Preview post-Phase-8 evidence compaction
day-one-mac advanced             Read and track advanced Modules 15–22
day-one-mac advanced-audit       Write the optional advanced environment report
day-one-mac cli-tools            Select optional Homebrew formulae
day-one-mac remove               Choose recorded, sectional, or full removal
day-one-mac clean                Preview broad cleanup
day-one-mac rollback             Preview manifest-owned rollback
day-one-mac root                 Print the active runtime root
day-one-mac help                 Show the installed command summary
```

These names are also used by the optional Warp Drive bundle. Verify the
indirection instead of adding a personal checkout path to shell configuration:

```bash
command -v day-one-mac
day-one-mac root
day-one-mac --status
day-one-mac advanced --list
day-one-mac workspace --help
```

The [complete command reference](../20-reference/COMMAND-REFERENCE.md) maps every portable
command to its direct project script, lists compatibility aliases, and explains
when to choose finalisation, recorded rollback, sectional removal, or broad
cleanup.

Normal installations use the versioned standalone runtime and do not need a
checkout-location repair. If a contributor deliberately uses linked mode and
moves that source checkout, reinstall linked mode from the new location before
rerunning the phase. Current phase fingerprints remain valid.

## Step 5.7 — Add and inspect new-source targets

For a new source, the equivalent manual commands are:

```bash
chezmoi add ~/.zprofile ~/.zshrc ~/.gitconfig ~/.gitignore_global ~/.ssh/config \
  ~/.config/zsh/path.zsh ~/.config/zsh/aliases.zsh \
  ~/.config/starship.toml

chezmoi managed
chezmoi diff
```

An empty diff means source and targets agree. To make a later change safely:

```bash
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply ~/.zshrc
```

## Reference — what every Phase 5 file should contain

These are the **minimal Day One Mac baselines**, not a rule that every byte
must match. An existing private source may contain additional reviewed aliases,
Git includes, SSH hosts, or Starship modules. Phase 5 preserves existing files
and checks the required behaviour instead of deleting legitimate additions.

Use these commands to compare a target with its chezmoi source:

```bash
chezmoi source-path "$HOME/.zshrc"
chezmoi cat "$HOME/.zshrc"
chezmoi diff
```

Typical source names are:

| Target on the Mac | Typical chezmoi source path |
|---|---|
| `~/.zprofile` | `dot_zprofile` |
| `~/.zshrc` | `dot_zshrc` |
| `~/.config/zsh/path.zsh` | `dot_config/zsh/path.zsh` |
| `~/.config/zsh/aliases.zsh` | `dot_config/zsh/aliases.zsh` |
| `~/.gitconfig` | `dot_gitconfig` |
| `~/.gitignore_global` | `dot_gitignore_global` |
| `~/.ssh/config` | `dot_ssh/config` |
| `~/.config/starship.toml` | `dot_config/starship.toml` |

chezmoi may use a different encoded name when attributes or templates are
involved. Trust `chezmoi source-path TARGET` rather than guessing a filename.

### `~/.zprofile`

The required content is one guarded source line:

```zsh
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"
```

The early portable installer may also leave the explanatory comment
`# Day One Mac shared shell path` above it. That is expected.

### `~/.config/zsh/path.zsh`

All machines use this base:

```zsh
# Shared PATH setup for login and non-login interactive zsh.
# Keep this file idempotent: both ~/.zprofile and ~/.zshrc source it.
typeset -U path PATH
if [[ -x /opt/homebrew/bin/brew ]] && {
  [[ ${HOMEBREW_PREFIX:-} != /opt/homebrew ]] ||
  [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] ||
  [[ ":$PATH:" != *":/opt/homebrew/sbin:"* ]]
}; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
```

Node selections append this block; Python-only selections do not:

```zsh
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
```

### `~/.zshrc`

The minimal interactive-shell file is:

```zsh
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY

for completion_dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do
  [[ -d "$completion_dir" ]] || continue
  (( ${fpath[(Ie)$completion_dir]} )) || fpath=("$completion_dir" $fpath)
done
unset completion_dir
autoload -Uz compinit
compinit

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

[[ -r "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Syntax highlighting must be the final shell integration.
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
```

The fnm guard may remain on Python-only machines; it does nothing when fnm is
absent. Syntax highlighting must remain the final integration when installed.

### `~/.config/zsh/aliases.zsh`

The base alias file is deliberately non-destructive:

```zsh
# Safe, readable aliases selected by Day One Mac.
# Keep destructive, publishing, force-push and prune commands explicit.
if command -v day-one-mac >/dev/null 2>&1; then
  alias cdayone='cd "$(day-one-mac root)"'
fi

if command -v git >/dev/null 2>&1; then
  alias gs='git status --short --branch'
  alias gd='git diff'
  alias gds='git diff --staged'
  alias gl='git log --oneline --graph --decorate -20'
  alias gremotes='git remote --verbose'
fi

if command -v chezmoi >/dev/null 2>&1; then
  alias cm='chezmoi'
  alias cmstatus='chezmoi status'
  alias cmdiff='chezmoi diff'
  alias cmdifftext='chezmoi --use-builtin-diff diff --no-pager'
  alias cmmerge='chezmoi merge'
  alias cmverify='chezmoi verify'
  alias cmdoctor='chezmoi doctor'
fi

if command -v brew >/dev/null 2>&1; then
  alias brewcheck='brew bundle check --file="$HOME/Brewfile" --no-upgrade'
  alias brewout='brew outdated --greedy'
  alias brewcleanpreview='brew cleanup --dry-run'
  alias brewautopreview='brew autoremove --dry-run'
fi
```

Follow [the alias editing guide](../20-reference/ZSH-ALIASES.md) instead of editing
the applied target and losing the change at the next `chezmoi apply`.

### `~/.gitconfig`

Git may reorder sections, and GitHub CLI can add an HTTPS credential-helper
section. The required values are equivalent to:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
[init]
    defaultBranch = main
[pull]
    ff = only
[fetch]
    prune = true
[push]
    autoSetupRemote = true
[core]
    excludesFile = /Users/your-name/.gitignore_global
[merge]
    conflictStyle = zdiff3
[ghq]
    root = /Users/your-name/Developer
```

When VS Code was selected as the primary IDE, additional `core.editor`,
`merge.tool`, `mergetool.vscode`, `diff.tool`, and `difftool.vscode` values are
expected. Their executable path may be `code` or the absolute command inside
`/Applications/Visual Studio Code.app`; both are valid. They are deliberately
absent when another primary IDE was selected.

Check semantics without relying on formatting:

```bash
git config --global --get user.name
git config --global --get user.email
git config --global --get init.defaultBranch
git config --global --get pull.ff
git config --global --get fetch.prune
git config --global --get push.autoSetupRemote
git config --global --get core.excludesFile
git config --global --get merge.conflictStyle
git config --global --get ghq.root
```

### `~/.gitignore_global`

The managed baseline contains only operating-system and temporary editor
files. Add project-specific patterns to the repository's own `.gitignore`.

```gitignore
.DS_Store
.AppleDouble
.LSOverride
._*
.Trashes
*.swp
*.swo
*~
```

### `~/.ssh/config`

The exact host blocks depend on the saved track and authentication mode. A
GitHub-only machine using the default 1Password route normally has:

```sshconfig
# >>> Day One Mac: 1Password SSH agent >>>
# Generated for auth mode '1password' from the saved hosting track.
Host github.com
    HostName github.com
    User git
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    IdentityFile ~/.ssh/github-auth.pub
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
# <<< Day One Mac: 1Password SSH agent <<<
```

Track 2 or Track 3 also contains an `ssh.dev.azure.com` block. It uses
`~/.ssh/azure-devops-auth.pub` for 1Password. Other authentication modes vary:

- **Keychain:** `UseKeychain yes`, `AddKeysToAgent yes`, and the corresponding
  on-disk private-key path.
- **External agent:** no `IdentityAgent`; an `IdentityFile` is present only
  when a public key was deliberately pinned.
- **HTTPS:** no SSH identity is configured. If no prior file exists, Phase 5
  creates only `# Day One Mac: HTTPS Git authentication selected; no SSH identity is configured.`

An existing personal or company SSH configuration can follow the marked block
and is preserved. `IdentitiesOnly yes` must never appear without an adjacent
`IdentityFile`.

### `~/.config/starship.toml`

The minimal prompt configuration is:

```toml
add_newline = false
command_timeout = 1000

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

### `~/.config/chezmoi/chezmoi.toml` — machine-local, not managed

This file stores per-Mac values and therefore stays outside the chezmoi source:

```toml
[edit]
command = "code"
args = ["--wait"]

[diff]
command = "code"
args = ["--wait", "--diff"]

[merge]
command = "bash"
args = [
  "-c",
  "cp {{ .Target | quote }} {{ printf \"%s.base\" .Target | quote }} && code --new-window --wait --merge {{ .Destination | quote }} {{ .Target | quote }} {{ printf \"%s.base\" .Target | quote }} {{ .Source | quote }}",
]

[data]
track = "github"
stack = "both"
name = "Your Name"
email = "you@example.com"
```

`track` can be `github`, `azure`, or `github+azure`; `stack` can be `node`,
`python`, or `both`.

### `~/.local/bin/day-one-mac`

This is an executable dispatcher, not a hand-edited configuration file. It is
installed outside chezmoi and must resolve the verified active runtime:

```bash
printf 'mode: %s\n' "$(stat -f '%Lp' "$HOME/.local/bin/day-one-mac")"
day-one-mac runtime-status
day-one-mac root
```

Expected mode is `700`, and runtime integrity must be `verified`. If either
check fails, run `day-one-mac update`, verify `day-one-mac runtime-status`, and
then rerun Phase 5. Do not add the launcher back to chezmoi.

## Never add these to chezmoi

- `.env` files or literal API keys.
- 1Password application data or SSH private keys.
- `~/.azure`, `~/.aws`, `~/.config/gh/hosts.yml`, or browser cookies.
- npm registry tokens from `.npmrc`.
- Machine caches, runtime installations, or `node_modules`.

Before the first commit, inspect both filenames and content.

List every file in the source:

```bash
cd "$(chezmoi source-path)"
find . -path ./.git -prune -o -type f -print | sort
```

Then read the contents, one file at a time with a clear header before each:

```bash
cd "$(chezmoi source-path)"
find . -path ./.git -prune -o -type f -print | sort | while IFS= read -r file; do
  printf '\n===== %s =====\n' "$file"
  cat "$file"
done
```

Expected output looks like this:

```text
===== ./dot_zshrc =====
source "$HOME/.config/zsh/path.zsh"
autoload -Uz compinit
compinit
...

===== ./dot_gitconfig =====
[user]
	name = Your Name
```

Read every block. Do not publish until the source is secret-free.

## Step 5.8 — Verify a new login shell

Open a new terminal or run:

```bash
exec /opt/homebrew/bin/zsh -l
```

Also check a **non-login** interactive shell, which is the case `~/.zprofile`
does not cover:

```bash
/opt/homebrew/bin/zsh -ic 'command -v brew starship fnm 2>/dev/null; echo "prompt: ${STARSHIP_SHELL:-not initialised}"'
```

Every command you selected should resolve. If Homebrew or Starship is missing
here but present after `exec /opt/homebrew/bin/zsh -l`, the shared PATH source
line from Step 5.3 is absent.

Then verify:

```bash
command -v brew git ghq chezmoi starship day-one-mac
command -v zsh # must print /opt/homebrew/bin/zsh
ghq root
day-one-mac root
chezmoi doctor
chezmoi source-path
chezmoi managed
chezmoi --use-builtin-diff diff --no-pager
printf 'PNPM_HOME=%s\n' "${PNPM_HOME:-not-set}"
day-one-mac shell-status
```

`PNPM_HOME` is required only for Node selections.

## If you make a mistake — rerun or recover Phase 5

Phase 5 is designed to be rerun. Requesting one phase runs it even when its
completion marker is current:

```bash
day-one-mac --status
day-one-mac shell-status
day-one-mac setup --phase 05
```

If the phase stopped with an error, it was **not** marked complete. Follow the
terminal's first **Next action**, then run the Phase 5 command again. Earlier
completed phases remain saved.

### Correct the selected dotfiles mode

Rerun with the intended source choice:

```bash
# Keep a local-only chezmoi source with no required Git history.
day-one-mac setup --phase 05 --local-dotfiles

# Use an existing private dotfiles repository.
day-one-mac setup --phase 05 \
  --dotfiles-repo "git@github.com:YOUR-NAME/YOUR-DOTFILES.git"
```

These commands do not delete an existing chezmoi `.git` directory. If the
wrong repository was initialized, stop and inspect `chezmoi source-path` before
changing remotes or moving data.

### Correct one managed file

Edit the source copy, validate it, review the diff, apply only that target, and
rerun the phase. For example:

```bash
chezmoi edit "$HOME/.zshrc"
/opt/homebrew/bin/zsh -n "$(chezmoi source-path "$HOME/.zshrc")"
chezmoi diff
chezmoi apply "$HOME/.zshrc"
exec /opt/homebrew/bin/zsh -l
day-one-mac setup --phase 05
```

Use the same sequence for `path.zsh` or `aliases.zsh`. Validate TOML files with
their owning tool: `starship prompt` for `starship.toml` and `chezmoi doctor`
for the chezmoi configuration.

### Recover a broken login shell

If Homebrew zsh was selected but a new terminal cannot start, restore Apple's
zsh from any working shell:

```bash
chsh -s /bin/zsh
```

Open a new terminal, repair or reinstall `/opt/homebrew/bin/zsh`, then rerun
Phase 5. The previous login-shell value is recorded at
`~/.day-one-mac/previous-login-shell`.

### Understand `--reset-progress`

Do **not** use this for an ordinary Phase 5 correction:

```bash
day-one-mac setup --reset-progress --dry-run
day-one-mac setup --reset-progress
```

It archives completion markers for **all eight phases**. It does not remove
Homebrew packages, undo shell files, delete the chezmoi source, or reverse the
login-shell setting. A targeted `--phase 05` rerun plus `chezmoi edit` is the
safer recovery path. Use the preview-first removal or recorded rollback tools
only when the intended outcome is to undo broader setup work.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| `chezmoi source-path` fails | Run `chezmoi init`, then rerun Phase 5 |
| An existing source produces a large diff | Stop, inspect each change, and apply individual targets first |
| An older source tries to replace `~/.local/bin/day-one-mac` | Decline the apply. Update to the current runtime and rerun Phase 5; it backs up and forgets the legacy source entry without deleting the live command |
| `day-one-mac` is missing | Confirm `~/.config/zsh/path.zsh` adds `~/.local/bin`, confirm both startup files source it, and open a new shell |
| `day-one-mac root` names a removed checkout | Install the latest public runtime again and verify it with `day-one-mac runtime-status`; linked-mode contributors should reinstall from the intended source checkout |
| Starship is installed but no prompt appears | Confirm `.zshrc` contains exactly one `starship init zsh` block and open a new shell |
| Nerd Font symbols are boxes | Select JetBrainsMono Nerd Font in the terminal or VS Code setting |
| pnpm reports its global bin is not on PATH | Confirm `~/.config/zsh/path.zsh`, run `exec /opt/homebrew/bin/zsh -l`, and print `$PNPM_HOME` |
| Phase 5 reports a `.zshenv` conflict | Review `ZDOTDIR` or `unsetopt RCS` in that file; do not delete unrelated settings blindly |
| An alias is missing | Run `day-one-mac shell-status`, confirm `.zshrc` sources `~/.config/zsh/aliases.zsh`, then open a new shell |
| `chezmoi diff` opens VS Code when terminal output was expected | Use `chezmoi --use-builtin-diff diff --no-pager`; `--no-pager` alone does not bypass a configured graphical tool |
| `chezmoi diff` asks 1Password for an unknown secret | Remove or correct that template reference before applying |

## Phase 5 completion checklist 🚦

- [ ] `chezmoi source-path` returns a real directory.
- [ ] The eight configuration targets, including both `~/.config/zsh` files, are managed.
- [ ] `~/.local/bin/day-one-mac` is executable and is not managed by chezmoi.
- [ ] The machine-local config contains the correct track, stack, name, and email.
- [ ] `chezmoi diff` is empty or every VS Code comparison is understood.
- [ ] Starship renders without a configuration error.
- [ ] A new login shell finds Homebrew, Git, chezmoi, and Starship.
- [ ] Directory Services reports `/opt/homebrew/bin/zsh` as the login shell.
- [ ] `day-one-mac shell-status` passes, including `compaudit`.
- [ ] `day-one-mac root` returns the current self-contained project directory.
- [ ] `day-one-mac advanced --list` shows Modules 15–22.
- [ ] Node selections expose `PNPM_HOME` on PATH.
- [ ] The source contains no tokens, private keys, or provider credential files.

References: [chezmoi quick start](https://www.chezmoi.io/quick-start/),
[VS Code diff configuration](https://www.chezmoi.io/user-guide/tools/diff/),
[VS Code merge configuration](https://www.chezmoi.io/user-guide/tools/merge/),
and [Starship setup](https://starship.rs/guide/).

---

[← Phase 4](04-core-tools-and-hosting.md) · [Continue to Phase 6 →](06-language-toolchains.md)
