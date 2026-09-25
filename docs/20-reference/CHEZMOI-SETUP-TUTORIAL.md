[← Reference library](README.md) · [Daily workflows](MANAGING-DOTFILES-WITH-CHEZMOI.md) · [Command reference](CHEZMOI-COMMAND-REFERENCE.md)

# Set up chezmoi with Day One Mac

**Document type:** tutorial · **Audience:** first-time chezmoi users · **Time:** 35–60 minutes

This tutorial explains where chezmoi fits into a complete Day One Mac setup.
It covers both supported routes:

- **Script-assisted:** the `day-one-mac` runner creates or adopts the minimum
  configuration, pauses at safety boundaries, and records phase completion.
- **Manual:** you run every chezmoi command yourself and keep your own setup
  record. The manual route does not create runner rollback manifests or phase
  completion markers.

Choose one route for the initial setup. Do not repeat the manual creation steps
after the script-assisted route has passed: doing so can overwrite a source the
runner deliberately preserved.

## What you will finish with

At the end:

- chezmoi has a readable source directory at `~/.local/share/chezmoi`;
- the required shell, Git, SSH, and Starship files are managed;
- machine-specific choices remain in `~/.config/chezmoi/chezmoi.toml`;
- the `day-one-mac` launcher remains outside chezmoi;
- `~/Brewfile` records Homebrew desired state and is managed by chezmoi;
- the source is either protected by private Git or included in an encrypted
  backup; and
- you know how to make the next change without losing it.

## 1. Understand when chezmoi is used

Chezmoi appears at several points in the required setup:

| Setup point | What happens |
|---|---|
| Phase 1 | You choose an existing private source, a new private-Git source, or a local-only source. |
| Phase 4 | Homebrew installs the `chezmoi` command. |
| Phase 5 | The source is initialized or adopted; required targets and machine data are configured. |
| Phases 6–7 | Toolchain and editor work may depend on the managed shell files. |
| Phase 8 | The Brewfile is added, the source is scanned, and its private-Git or encrypted-backup protection is verified. |
| After setup | You use chezmoi whenever a managed configuration file changes. |

Use the script-assisted route when you want Day One Mac to verify prerequisites,
preserve existing files, and record progress. Use the manual route when policy
prevents running the setup scripts or when you deliberately maintain your own
completion and recovery records.

## 2. Learn the three locations

Chezmoi separates the master configuration from the files applications read:

| Location | Role | Commit it? |
|---|---|---|
| `~/.local/share/chezmoi` | Source: master files, templates, and optional run scripts | Yes, only to private Git; otherwise back it up encrypted |
| `~/.zshrc`, `~/.gitconfig`, and other normal paths | Targets: active files read by applications | No; chezmoi produces them |
| `~/.config/chezmoi/chezmoi.toml` | Per-Mac editor settings and template data | No |

Ask chezmoi for the real locations instead of guessing encoded source names:

```bash
chezmoi source-path
chezmoi source-path "$HOME/.zshrc"
chezmoi managed -p absolute
```

Read [Concepts and safety boundaries](CHEZMOI-CONCEPTS-AND-BOUNDARIES.md) before
adding credentials, application state, or machine-specific configuration.

## 3. Confirm the prerequisites

### Script-assisted route

Check saved progress and required tools:

```bash
day-one-mac setup --status
command -v brew git chezmoi starship day-one-mac
```

Complete Phases 1–4 if any required phase is incomplete:

```bash
day-one-mac setup --guided
```

### Manual route

Confirm Homebrew and Git work, then install the required tools if necessary:

```bash
command -v brew git
brew install chezmoi starship zsh
chezmoi --version
```

The manual route assumes Git identity, hosting authentication, Homebrew, and
the required Day One Mac applications have already been configured. Use the
required-phase documents if they have not.

## 4. Choose how to protect the source

Choose one mode before initializing chezmoi:

| Mode | Choose it when | Protection requirement |
|---|---|---|
| Existing private repository | You already have reviewed dotfiles to restore or continue | Reachable private remote and pushed branch |
| New private-Git source | You want version history and recovery on another Mac | Create a private remote during Phase 8 |
| Local-only source | Policy or preference prohibits a dotfiles remote | Current encrypted backup of the complete source directory |

Private Git is the recommended default. Local-only mode still uses chezmoi;
it removes only the remote and Git completion requirement.

### Script-assisted route

Pass the intended choice explicitly when running Phase 5:

```bash
# Adopt an existing private source.
day-one-mac setup --phase 05 \
  --dotfiles-repo "git@github.com:ACCOUNT/DOTFILES.git"

# Create a new source that Phase 8 will require you to protect with private Git.
day-one-mac setup --phase 05 --new-dotfiles --dotfiles-versioning git

# Create or retain a source with no Git or remote requirement.
day-one-mac setup --phase 05 --local-dotfiles
```

If the choice was already saved by the wizard, `day-one-mac setup --phase 05`
uses it. Supplying the option again makes the intended mode clear.

### Manual route

For an existing private source:

```bash
chezmoi init "git@github.com:ACCOUNT/DOTFILES.git"
chezmoi diff
```

For a new private-Git or local-only source:

```bash
chezmoi init
chezmoi source-path
```

Do not apply an existing source until you have reviewed every path in
`chezmoi diff`. A repository can contain valid personal settings that are
incorrect for the new Mac.

## 5. Configure this Mac

The machine configuration is local input to templates. It is not one of the
managed dotfiles.

### Script-assisted route

When the file is absent, Phase 5 creates the required values from the choices
collected by the installer. It preserves an existing file and can add missing
VS Code review settings after confirmation. Inspect the result:

```bash
chezmoi edit-config
```

Confirm the editor and `[data]` values match this Mac. Expected Day One Mac
data includes the selected hosting `track`, development `stack`, name, and
email. If an existing value is stale, correct it deliberately; the runner does
not overwrite existing machine data. Close without changing values you do not
understand.

### Manual route

Open the configuration:

```bash
chezmoi edit-config
```

Use this baseline, replacing the example values:

```toml
[edit]
command = "code"
args = ["--wait"]

[diff]
command = "code"
args = ["--wait", "--diff"]

[data]
track = "github"
stack = "both"
name = "Your Name"
email = "you@example.com"
```

Valid Day One Mac tracks are `github`, `azure`, and `github+azure`. Valid
stacks are `node`, `python`, and `both`. Do not put passwords, tokens, private
keys, or authentication JSON in this file merely because it is not committed.

## 6. Establish the required managed targets

The minimum target set is:

```text
~/.zprofile
~/.zshrc
~/.config/zsh/path.zsh
~/.config/zsh/aliases.zsh
~/.gitconfig
~/.gitignore_global
~/.ssh/config
~/.config/starship.toml
```

### Script-assisted route

Run the selected Phase 5 command. The runner:

1. initializes or reuses the source;
2. preserves existing `.zprofile` and `.zshrc` files;
3. creates only missing baseline files for a new source;
4. checks the required semantic content;
5. adds new targets to chezmoi;
6. shows the complete diff for an existing source;
7. asks before applying; and
8. records recovery information for affected targets.

If it stops, follow its first **Next action** and rerun the same Phase 5
command. A stopped phase is not marked complete.

### Manual route

Create or merge the target files using the exact examples and explanations in
[Phase 5 — chezmoi, the shell, and Starship](../01-required/05-dotfiles-and-shell.md)
and the [shell-file reference](phase-05-shell-files/README.md). Do not copy the
reference directory wholesale over an existing home directory.

When every target has been reviewed, add it:

```bash
chezmoi add "$HOME/.zprofile" "$HOME/.zshrc" \
  "$HOME/.config/zsh/path.zsh" \
  "$HOME/.config/zsh/aliases.zsh" \
  "$HOME/.gitconfig" "$HOME/.gitignore_global" \
  "$HOME/.ssh/config" "$HOME/.config/starship.toml"
```

Then inspect what chezmoi owns:

```bash
chezmoi managed -p absolute | LC_ALL=C sort
chezmoi --use-builtin-diff diff --no-pager
```

## 7. Preserve the Day One Mac runtime boundary

`~/.local/bin/day-one-mac` is an installed launcher, not a dotfile. Chezmoi
must not manage it because applying an older source could replace a verified
runtime launcher.

### Both routes

Check the boundary:

```bash
if chezmoi managed -p absolute | grep -Fx "$HOME/.local/bin/day-one-mac"; then
  printf 'REVIEW: the launcher is incorrectly managed\n'
else
  printf 'PASS: the launcher is runtime-owned\n'
fi

day-one-mac runtime-status
```

If an older source manages the launcher, decline any broad apply and use the
reviewed migration in [Upgrade notes](UPGRADE-NOTES.md). Do not add it again.

## 8. Preview and apply safely

### Script-assisted route

Review every comparison Phase 5 opens. For an existing source, approval applies
to the complete displayed diff, not only the minimum targets listed above.
Decline if any file is unfamiliar.

### Manual route

Preview all targets in the terminal:

```bash
chezmoi --use-builtin-diff diff --no-pager
```

Apply reviewed targets individually first:

```bash
chezmoi apply "$HOME/.zprofile"
chezmoi apply "$HOME/.zshrc"
chezmoi apply "$HOME/.config/zsh/path.zsh"
chezmoi apply "$HOME/.config/zsh/aliases.zsh"
```

Apply the remaining named targets only after their diffs are understood. Avoid
a broad `chezmoi apply` while resolving an unexpected change.

## 9. Validate the active configuration

### Both routes

Validate syntax before starting a new shell:

```bash
/opt/homebrew/bin/zsh -n "$HOME/.zprofile"
/opt/homebrew/bin/zsh -n "$HOME/.zshrc"
/opt/homebrew/bin/zsh -n "$HOME/.config/zsh/path.zsh"
/opt/homebrew/bin/zsh -n "$HOME/.config/zsh/aliases.zsh"
chezmoi doctor
chezmoi verify
chezmoi --use-builtin-diff diff --no-pager
```

Then test both login and non-login shell behaviour:

```bash
/opt/homebrew/bin/zsh -lic 'command -v brew git chezmoi starship day-one-mac'
/opt/homebrew/bin/zsh -ic 'command -v brew starship'
day-one-mac shell-status
```

For the script-assisted route, finish the phase gate:

```bash
day-one-mac setup --phase 05
```

An empty diff means source and targets agree. A non-empty diff is acceptable
only when you can explain every line and have intentionally not applied it yet.

## 10. Record Homebrew desired state in Phase 8

### Script-assisted route

Run:

```bash
day-one-mac setup --phase 08
```

The runner creates `~/Brewfile` only when absent, pauses instead of overwriting
an existing file, adds a newly created Brewfile to chezmoi, scans the source,
and enforces the selected protection mode.

### Manual route

Create the Brewfile only when one does not already exist:

```bash
test -e "$HOME/Brewfile" || brew bundle dump --file="$HOME/Brewfile"
cat "$HOME/Brewfile"
brew bundle check --file="$HOME/Brewfile" --no-upgrade
chezmoi add "$HOME/Brewfile"
chezmoi diff "$HOME/Brewfile"
```

If the file already exists, review and update it instead of replacing it with
`brew bundle dump --force`.

## 11. Protect the source

### Private-Git mode

Inspect filenames and source-repository changes before committing:

```bash
SOURCE="$(chezmoi source-path)"
git -C "$SOURCE" status --short
git -C "$SOURCE" diff
find "$SOURCE" -path "$SOURCE/.git" -prune -o -type f -print | LC_ALL=C sort
```

Use the Phase 8 secret scan and create a **private** remote. Then:

```bash
git -C "$SOURCE" add --all
git -C "$SOURCE" diff --cached
git -C "$SOURCE" commit -m "chore: bootstrap day one dotfiles"
git -C "$SOURCE" push -u origin main
```

Rerun `day-one-mac setup --phase 08` on the script-assisted route so the
runner can verify remote privacy, reachability, upstream state, and source
cleanliness.

### Local-only mode

Do not add a remote merely to satisfy a Git-oriented example. Back up the
complete directory instead:

```text
~/.local/share/chezmoi
```

Use an encrypted backup and test that the directory can be restored. A
local-only source without a current backup is not reproducible.

## 12. Make your first routine change

Change an alias through the source rather than editing only the live target:

```bash
chezmoi edit "$HOME/.config/zsh/aliases.zsh"
chezmoi diff "$HOME/.config/zsh/aliases.zsh"
/opt/homebrew/bin/zsh -n "$(chezmoi source-path "$HOME/.config/zsh/aliases.zsh")"
chezmoi apply "$HOME/.config/zsh/aliases.zsh"
day-one-mac shell-status
```

In private-Git mode, review, commit, and push the source change. In local-only
mode, run the encrypted backup after the change. Continue with
[Daily chezmoi workflows](MANAGING-DOTFILES-WITH-CHEZMOI.md) whenever you edit,
adopt, remove, receive, or recover a managed file.

## Completion checklist

- [ ] `chezmoi source-path` returns the intended source directory.
- [ ] The required target set is present in `chezmoi managed -p absolute`.
- [ ] `~/.local/bin/day-one-mac` is not managed by chezmoi.
- [ ] Machine data is local and contains no credentials.
- [ ] Shell syntax, `chezmoi doctor`, `chezmoi verify`, and shell status pass.
- [ ] `chezmoi diff` is empty or every remaining change is understood.
- [ ] `~/Brewfile` is reviewed and managed.
- [ ] Private-Git mode has a private pushed remote, or local-only mode has a
      tested encrypted backup.
- [ ] You completed one source → preview → apply → validate cycle yourself.

---

[← Reference library](README.md) · [Daily workflows →](MANAGING-DOTFILES-WITH-CHEZMOI.md) · [Concepts and boundaries](CHEZMOI-CONCEPTS-AND-BOUNDARIES.md)
