[← Phase 4](04-core-tools-and-hosting.md) · **Phase 5** · [Phase 6 →](06-language-toolchains.md)

# Phase 5 — Configuration ownership, shell, and prompt

**Time:** 25-45 minutes · **Required:** everyone

A **dotfile** is a configuration file whose name begins with a dot, such as
`~/.zshrc` or `~/.gitconfig`. macOS hides these in Finder by default. They hold
your personal settings for the shell, Git, and similar tools. **chezmoi** keeps
a master copy of each one in a single folder so they can be reviewed, versioned,
and restored on another Mac. See [GLOSSARY.md](../../shared/glossary.md) for related terms.

## Outcome

Your selected owner maintains a small set of configuration files. Homebrew and
selected toolchains initialize predictably; Starship runs only when selected
for new configuration. The portable command remains installer-owned, and
secrets stay outside any dotfiles source.

## Choose ownership, shell, and prompt first

These are independent choices, collected by the wizard before installation:

| Choice | Values | Meaning |
|---|---|---|
| `--dotfiles-versioning` | `none`, `local`, `git` | User-owned files, local chezmoi, or chezmoi with a private repository |
| `--shell` | `keep`, `apple`, `homebrew` | Preserve the current zsh login shell, select `/bin/zsh`, or install/select Homebrew zsh |
| `--prompt` | `none`, `starship` | Leave existing prompt configuration alone, or install/configure Starship |

Fresh direct runs must supply all three choices; `--yes` does not select them.
Plan output may show missing choices, but apply stops until they are supplied.
Previously saved setups retain the earlier Homebrew-zsh/Starship choices until
you explicitly change them. Old completion markers are revalidated, not treated
as evidence that the new choices passed.

For example, with hosting, language, identity and folder choices already saved:

```bash
day-one-mac setup --phase 05 --plan --dotfiles-versioning none --shell apple --prompt none
day-one-mac setup --phase 05 --apply --dotfiles-versioning none --shell apple --prompt none
day-one-mac setup --phase 05 --check
day-one-mac setup --phase 05 --resume
```

**Fully manual route:** follow the shared shell-file steps below, editing files
directly for `none`. Skip every chezmoi initialization, adoption, apply, and
remote command. For `local` or `git`, use the chezmoi sections. Choose the shell
and Starship branches in [Manual 5](../manual/shell/zsh.md).
No Day One Mac command is required by that route.

Declining a component does not uninstall it, remove its existing configuration,
or disable an existing prompt. An unmanaged selection stops when an existing
chezmoi source/configuration is detected: back up both source and targets, review
all managed paths and custom source locations, and detach ownership manually
before retrying. Do not delete a source to silence the check. If you intend to
keep chezmoi ownership, retain `local` or `git` instead. A custom non-zsh shell or
symlink-owned startup file also requires manual review; the runner does not
replace it.

## How to use this phase

- **Manual route:** complete
  [Manual 5](../manual/shell/zsh.md)
  and use the file explanations below as reference. Do not install or manage
  the portable `day-one-mac` launcher.
- **Script-assisted route:** run `day-one-mac setup --phase 05`. For a new source, the runner creates
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
exact source line that must be merged using the selected configuration owner.

## How chezmoi separates files

This section and all source-management steps apply only to `local` or `git`.

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
[Phase 5 shell-file reference](../../../templates/phase-05-shell-files/README.md).
Use it for comparison only; merge reviewed differences through chezmoi rather
than copying the complete folder over an existing setup.

First-time users should follow the
[complete chezmoi setup tutorial](../manual/shell/chezmoi.md),
which keeps the script-assisted and fully manual paths explicit through Phase
8. For every later edit, follow
[Daily chezmoi workflows](../manual/shell/chezmoi.md).
It shows the source → preview → apply → validate → private Git commit or
local-only backup flow, including when `add`, `apply`, `merge`, or `forget` is
correct.

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

The runner prepares missing files for the saved selection and preserves
existing configuration. Use `day-one-mac shell-status` to inspect the result.
For an existing file needing a merge, complete the linked manual task through
the selected file owner, then return and rerun Phase 5.
Expected result: one PATH/completion/prompt initialisation and a working new
session; unselected Homebrew Zsh, Starship or aliases are not required.

## Step 5.3 — Configure interactive zsh

The runner prepares missing files for the saved selection and preserves
existing configuration. Use `day-one-mac shell-status` to inspect the result.
For an existing file needing a merge, complete the linked manual task through
the selected file owner, then return and rerun Phase 5.
Expected result: one PATH/completion/prompt initialisation and a working new
session; unselected Homebrew Zsh, Starship or aliases are not required.

### Why both startup files load the shared PATH setup

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Existing `.zshenv` files

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

## Step 5.3a — Safe aliases

The runner prepares missing files for the saved selection and preserves
existing configuration. Use `day-one-mac shell-status` to inspect the result.
For an existing file needing a merge, complete the linked manual task through
the selected file owner, then return and rerun Phase 5.
Expected result: one PATH/completion/prompt initialisation and a working new
session; unselected Homebrew Zsh, Starship or aliases are not required.

## Step 5.4 — Configure Starship

The runner prepares missing files for the saved selection and preserves
existing configuration. Use `day-one-mac shell-status` to inspect the result.
For an existing file needing a merge, complete the linked manual task through
the selected file owner, then return and rerun Phase 5.
Expected result: one PATH/completion/prompt initialisation and a working new
session; unselected Homebrew Zsh, Starship or aliases are not required.

## Step 5.5 — Store machine-local data

This section applies only when chezmoi is selected.

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

This walkthrough applies only to `--shell homebrew`. With `--shell keep`,
skip account changes. With `--shell apple`, use `/bin/zsh` as the target; the
runner verifies it and changes the account only if necessary. See
[Manual 5](../manual/shell/zsh.md)
for the corresponding manual branches.

Homebrew zsh tracks Homebrew updates; Apple's `/bin/zsh` tracks macOS releases.

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
from any working shell - Terminal will still open with a fallback, and macOS
Recovery always works:

```bash
chsh -s /bin/zsh
```

The previous shell is also recorded at `~/.day-one-mac/previous-login-shell`.

## Step 5.6 — Verify the standalone day-one-mac command

The recommended start guide installs `~/.local/bin/day-one-mac` before Phase 1.
The checksum-verified runtime installer remains the sole owner of this file;
Phase 5 verifies it but never adds it to chezmoi. This boundary allows
`day-one-mac update` to switch versions without a dotfiles apply restoring a
launcher from an earlier installation. See the
[early installer and download guide](runtime.md).

When Phase 5 detects a launcher managed by an earlier Day One Mac installation,
it backs up that source entry below
`~/.day-one-mac/migrations/phase-05-standalone-launcher/`, runs
`chezmoi forget ~/.local/bin/day-one-mac`, and confirms the live executable was
preserved. It also merges only the reviewed Phase 4 Git keys into a plain
earlier `dot_gitconfig`; a templated Git source stops for a manual review. The
exact compatibility names are isolated in
[Upgrade notes](../../shared/upgrade-notes.md).

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
day-one-mac optional --status      Show or audit Modules 09–22 together
day-one-mac databases            Install, resume, or verify optional databases
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

The [complete command reference](reference/command-reference.md) maps every portable
command to its direct project script, lists compatibility aliases, and explains
when to choose finalisation, recorded rollback, sectional removal, or broad
cleanup.

Normal installations use the versioned standalone runtime and do not need a
checkout-location repair. If a contributor deliberately uses linked mode and
moves that source checkout, reinstall linked mode from the new location before
rerunning the phase. Current phase fingerprints remain valid.

## Step 5.7 — Add and inspect new-source targets

Only when chezmoi is selected: for a new source, the equivalent manual commands
are below. Omit `~/.config/starship.toml` when Starship was not selected.

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

The [versioned shell templates](../../../templates/phase-05-shell-files/README.md)
own the generated baseline. The [manual Zsh task](../manual/shell/zsh.md) owns
personal terminal changes, including Warp guards and prefix-history keys.
Inspect the selected source through its owner; do not paste a second complete
initialisation block over an existing file.

### `~/.zprofile`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.config/zsh/path.zsh`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.zshrc`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.config/zsh/aliases.zsh`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.gitconfig`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.gitignore_global`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.ssh/config`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.config/starship.toml`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.config/chezmoi/chezmoi.toml` — machine-local, not managed

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### `~/.local/bin/day-one-mac`

Complete the relevant action in the [manual task](../manual/shell/zsh.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

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

Review each selected source file privately in your editor. Do not publish the
source until credentials and private keys are excluded. A filename scan alone
does not establish that content is secret-free.

## Step 5.8 — Verify a new login shell

The examples below use Homebrew zsh with Node and Starship. Substitute `/bin/zsh`
for the Apple choice, or the verified current zsh path for `keep`. Omit checks
for unselected tools. This is the assisted verification procedure; the independent manual route has its own shell task.

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
command -v brew git chezmoi starship day-one-mac
dscl . -read "/Users/$(id -un)" UserShell # must match the selected account shell
ghq root                 # only if selected; compare with the reviewed layout
day-one-mac root
chezmoi doctor
chezmoi source-path
chezmoi managed
chezmoi --use-builtin-diff diff --no-pager
printf 'PNPM_HOME=%s\n' "${PNPM_HOME:-not-set}"
day-one-mac shell-status
```

`PNPM_HOME` is required only for Node selections. `command -v zsh` reports PATH
resolution, not the account's login shell; an installed Homebrew zsh can appear
first on PATH even when the account deliberately uses Apple's zsh.

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
| An earlier source tries to replace `~/.local/bin/day-one-mac` | Decline the apply. Update to the current runtime and rerun Phase 5; it backs up and forgets that source entry without deleting the live command |
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

- [ ] If chezmoi is selected, `chezmoi source-path` returns a real directory.
- [ ] Selected targets have one understood owner; Starship's file is required only when selected.
- [ ] `~/.local/bin/day-one-mac` is executable and is not managed by chezmoi.
- [ ] If chezmoi is selected, its machine-local config and reviewed diff are understood.
- [ ] If Starship is selected, it renders without a configuration error.
- [ ] New login and non-login interactive shells find Homebrew, Git, and selected tools.
- [ ] Directory Services reports the selected shell; `keep` did not change it.
- [ ] `day-one-mac shell-status` checks the saved shell/prompt choices and completion permissions pass `compaudit`.
- [ ] `day-one-mac root` returns the current self-contained project directory.
- [ ] `day-one-mac advanced --list` shows Modules 15-22.
- [ ] Node selections expose `PNPM_HOME` on PATH.
- [ ] The source contains no tokens, private keys, or provider credential files.

References: [chezmoi quick start](https://www.chezmoi.io/quick-start/),
[VS Code diff configuration](https://www.chezmoi.io/user-guide/tools/diff/),
[VS Code merge configuration](https://www.chezmoi.io/user-guide/tools/merge/),
and [Starship setup](https://starship.rs/guide/).

---

[← Phase 4](04-core-tools-and-hosting.md) · [Continue to Phase 6 →](06-language-toolchains.md)
