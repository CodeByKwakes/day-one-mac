[← Reference library](README.md) · [Setup tutorial](CHEZMOI-SETUP-TUTORIAL.md) · [Command reference](CHEZMOI-COMMAND-REFERENCE.md)

# Update shell dotfiles safely with chezmoi

**Document type:** how-to guide · **Audience:** users maintaining a completed Day One Mac setup

Phase 5 makes chezmoi the source of truth for `.zprofile`, `.zshrc`, shared
PATH configuration, aliases, Git configuration, SSH configuration, and the
Starship prompt. After that point, editing only the normal file in your home
folder is temporary: a future `chezmoi apply` can replace it.

The normal flow is:

```text
Edit the chezmoi source
        ↓
Review the rendered difference
        ↓
Apply the specific target
        ↓
Validate the active file and shell
        ↓
Commit and push the private dotfiles repository
```

Use this page after Phase 5 has established the source. If chezmoi has not been
configured yet, start with [Set up chezmoi with Day One Mac](CHEZMOI-SETUP-TUTORIAL.md).
For ownership decisions, read
[Concepts and safety boundaries](CHEZMOI-CONCEPTS-AND-BOUNDARIES.md).

## Understand the two copies

| Copy | Example | Purpose |
|---|---|---|
| chezmoi source | `$(chezmoi source-path)/dot_zshrc` | Master copy or template that should be versioned |
| Applied target | `~/.zshrc` | File that zsh actually reads |

Never guess the encoded source filename. Ask chezmoi:

```bash
chezmoi source-path "$HOME/.zshrc"
chezmoi source-path "$HOME/.config/zsh/aliases.zsh"
```

## Check health before making a change

Begin a maintenance session with:

```bash
chezmoi doctor
chezmoi status
chezmoi --use-builtin-diff diff --no-pager
```

Resolve an unexpected existing diff before starting unrelated work. Otherwise,
the new change and old drift share the same review and commit boundary.

## Recommended process for `.zshrc`, `.zprofile`, aliases, or PATH

### 1. Confirm that chezmoi manages the file

```bash
chezmoi source-path "$HOME/.zshrc"
```

If this reports that the target is unmanaged, stop and review Phase 5 before
adding it. Do not accidentally place secrets or company-only settings in a
personal repository.

### 2. Edit the source copy

```bash
chezmoi edit "$HOME/.zshrc"
```

For an alias, edit the dedicated alias file instead:

```bash
chezmoi edit "$HOME/.config/zsh/aliases.zsh"
```

Save and close the editor. This changes the source; it does not yet change the
active target in your home folder.

### 3. Preview exactly what will change

```bash
chezmoi diff "$HOME/.zshrc"
```

VS Code opens one comparison for each changed target. The left side is the
file currently on the Mac and the right side is the rendered state chezmoi
would apply. Close the comparison tab when you finish reviewing it; `--wait`
keeps the Terminal command active until the review window closes.

For a plain unified diff in Terminal, bypass the configured graphical tool:

```bash
chezmoi --use-builtin-diff diff --no-pager "$HOME/.zshrc"
```

In that output, `-` lines are removed from the active target and `+` lines are
added by the source. `--no-pager` alone does not disable the VS Code diff tool.

### 4. Apply only the reviewed file

```bash
chezmoi apply "$HOME/.zshrc"
```

Applying one target is safer than applying every managed file while resolving
a single shell change.

### 5. Validate the active result

```bash
/opt/homebrew/bin/zsh -n "$HOME/.zshrc"
day-one-mac shell-status
```

For shared shell files, validate each one you changed:

```bash
/opt/homebrew/bin/zsh -n "$HOME/.zprofile"
/opt/homebrew/bin/zsh -n "$HOME/.config/zsh/path.zsh"
/opt/homebrew/bin/zsh -n "$HOME/.config/zsh/aliases.zsh"
```

Open a new Warp or Terminal tab only after syntax validation passes. A new
interactive shell loads `.zshrc`; a new login shell also loads `.zprofile`.

### 6. Review the dotfiles repository

```bash
DOTFILES_SOURCE="$(chezmoi source-path)"
git -C "$DOTFILES_SOURCE" status --short
git -C "$DOTFILES_SOURCE" diff
```

Confirm that the diff contains only the intended configuration and no token,
password, private key, `.env` value, or machine-only work setting.

### 7. Commit and push the source repository

Only do this when Phase 5 uses a private Git-versioned source. A local-only
chezmoi source stops after validation and should instead be protected by the
reviewed encrypted backup process.

```bash
git -C "$DOTFILES_SOURCE" add --all
git -C "$DOTFILES_SOURCE" diff --cached
git -C "$DOTFILES_SOURCE" commit -m "Update managed shell configuration"
git -C "$DOTFILES_SOURCE" push
```

The normal files in `$HOME` are not committed separately. Their source forms
inside `$(chezmoi source-path)` are what belong in the private repository.

## If you edited the applied file first

Sometimes an application or installer changes `~/.zprofile` or `~/.zshrc`
directly. Review both copies before adopting it:

```bash
chezmoi diff "$HOME/.zshrc"
chezmoi cat "$HOME/.zshrc"
```

If the applied file contains the exact change you want and the source does not,
record that target:

```bash
chezmoi add "$HOME/.zshrc"
```

Then inspect the source-repository diff before committing. Do not use `add`
when the target is stale and the source contains newer work; that would record
the stale target over the desired source.

If both copies contain valuable differences, use:

```bash
chezmoi merge "$HOME/.zshrc"
chezmoi diff "$HOME/.zshrc"
chezmoi apply "$HOME/.zshrc"
```

VS Code's merge editor shows the live destination, rendered target, base copy,
and chezmoi source. Accept only the parts you understand, save the merge result,
close the window, and rerun `chezmoi diff` before applying. The merge command
does not grant permission to apply unrelated files.

## Add a new configuration file

Use this procedure only after deciding that the file is reproducible,
non-secret configuration and no other system owns it.

1. Inspect the complete target, including hidden values and generated content.
2. Remove credentials, host-specific state, and cache data.
3. Add the exact target.
4. Inspect the new source path and repository diff.
5. Confirm that rendering does not change the active file unexpectedly.

```bash
TARGET="$HOME/.config/example/config.toml"
chezmoi add "$TARGET"
chezmoi source-path "$TARGET"
chezmoi cat "$TARGET"
chezmoi diff "$TARGET"
```

An empty target diff is expected immediately after a successful add. The
source-repository Git diff should show the newly recorded file. Validate it
with the owning application before committing.

Do not recursively add a configuration directory until every file type inside
it has been classified. Application directories often mix portable settings
with tokens, device identifiers, databases, logs, and caches.

## Stop managing a file but keep it on this Mac

Use `forget` when another tool should own the target or when the target should
remain machine-local:

```bash
TARGET="$HOME/.config/example/config.toml"
chezmoi source-path "$TARGET"
chezmoi forget "$TARGET"
test -e "$TARGET" && printf 'Target preserved: %s\n' "$TARGET"
chezmoi managed -p absolute | grep -Fx "$TARGET" || true
```

Review the source-repository deletion and commit it in private-Git mode. The
target remains on the current Mac, but chezmoi can no longer reproduce it.
Assign a new owner or backup when the file still matters.

Never use `forget` as a substitute for removing an exposed secret from Git
history. Rotate the credential and follow the provider's history-remediation
process.

## Remove a managed file from both source and target

This is a destructive change. First create a reviewed source commit or backup,
then edit the source directory deliberately. Preview the target removal with:

```bash
chezmoi diff "$HOME/.config/example/config.toml"
chezmoi apply --dry-run --verbose "$HOME/.config/example/config.toml"
```

Apply only after the output explicitly shows the intended target. Do not use a
broad apply to test a deletion. If the file merely needs a different owner,
use `chezmoi forget` instead.

## Record an application-generated change

Some applications rewrite a managed target directly. Before adopting the
change:

```bash
TARGET="$HOME/.config/example/config.toml"
chezmoi diff "$TARGET"
chezmoi cat "$TARGET"
```

If the application-generated target is the exact desired state:

```bash
chezmoi add "$TARGET"
git -C "$(chezmoi source-path)" diff
```

If it contains both intended and volatile changes, do not add the complete
file. Edit or template the source so it contains only reproducible settings,
then preview and apply the rendered target.

## Update the Brewfile

The Brewfile is desired state, not a live inventory that should be overwritten
after every package experiment.

For a planned package change:

```bash
chezmoi edit "$HOME/Brewfile"
chezmoi diff "$HOME/Brewfile"
chezmoi apply "$HOME/Brewfile"
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

Install or reconcile only after the Brewfile is reviewed:

```bash
brew bundle install --file="$HOME/Brewfile"
```

Do not use `brew bundle dump --force` over an existing managed Brewfile. It can
replace intentional desired state with every package currently present on one
Mac.

## Preserve an SSH configuration change

Phase 3 can update `~/.ssh/config` after Phase 5 has made it a managed target.
The runner normally refreshes the source. If another tool or a manual edit
changes the target, inspect and adopt only the reviewed host blocks:

```bash
chezmoi diff "$HOME/.ssh/config"
chezmoi add "$HOME/.ssh/config"
git -C "$(chezmoi source-path)" diff
```

An SSH config may contain public host routing and agent references. It must not
contain private-key material, copied secret values, or provider login state.

## Receiving a change on another Mac

Pull the private source repository without immediately applying every target:

```bash
DOTFILES_SOURCE="$(chezmoi source-path)"
git -C "$DOTFILES_SOURCE" pull --ff-only
chezmoi diff
```

Apply reviewed targets individually, then verify Phase 5:

```bash
chezmoi apply "$HOME/.zprofile" "$HOME/.zshrc" \
  "$HOME/.config/zsh/path.zsh" "$HOME/.config/zsh/aliases.zsh"
day-one-mac setup --phase 05
```

Do not use `chezmoi update` for this cautious workflow because it combines
retrieval and application. Separating Git pull, diff, and named apply makes the
review boundary visible.

## Work with a local-only source

The edit, preview, apply, and validate workflow is identical in local-only
mode. Replace the Git commit-and-push step with an encrypted backup of:

```text
~/.local/share/chezmoi
```

Run the backup after every accepted source change. Periodically restore it to a
temporary, private location and confirm that the source files are readable.
Local-only mode without a tested backup has no recovery path.

## Change machine-specific template data

Open the local configuration:

```bash
chezmoi edit-config
```

After changing a value, identify every affected rendered target before apply:

```bash
chezmoi diff
```

Apply named targets and validate them with their owning tools. Never commit
`~/.config/chezmoi/chezmoi.toml`, and never use it as a secret store.

## Add or change an advanced template

Templates need a source-first workflow because the active target contains only
one rendered result:

```bash
TARGET="$HOME/.gitconfig"
chezmoi edit "$TARGET"
chezmoi cat "$TARGET"
chezmoi diff "$TARGET"
chezmoi apply "$TARGET"
git -C "$(chezmoi source-path)" diff
```

Do not run `chezmoi add TARGET` merely to resolve a template diff; that can
replace portable logic with the current Mac's output. Follow Advanced 15 for
template validation and safe run-script requirements.

## Which command should I use?

| Situation | Correct action |
|---|---|
| You want to make a new planned change | `chezmoi edit TARGET`, preview, then `chezmoi apply TARGET` |
| The source is correct and the active target is stale | `chezmoi apply TARGET` |
| The active target has the reviewed change you want to preserve | `chezmoi add TARGET`, then inspect the source diff |
| Both source and target contain changes you need | `chezmoi merge TARGET`, preview, then apply |
| You want a visual inspection | `chezmoi diff TARGET` and `chezmoi cat TARGET` |
| You need diff text in Terminal or automation | `chezmoi --use-builtin-diff diff --no-pager TARGET` |
| Another tool should own the live target | `chezmoi forget TARGET`, then commit the source removal |
| You need to receive a remote change cautiously | Git `pull --ff-only` in the source, then `chezmoi diff` |

Templates require extra care because their source contains template logic, not
only rendered text. Prefer `chezmoi edit TARGET`; do not replace a template by
blindly adding its rendered target.

## Recovery

Before accepting a surprising change, stop and copy the diff into a private
note. Git-versioned sources can restore a reviewed source file with a normal
Git revert. The applied target can then be regenerated with `chezmoi apply`.
Never use destructive Git reset commands as a troubleshooting shortcut.

### Revert a private-Git source change

Use a normal revert so the recovery itself remains reviewable:

```bash
SOURCE="$(chezmoi source-path)"
git -C "$SOURCE" log --oneline -10
COMMIT="commit-id-you-reviewed"
git -C "$SOURCE" revert "$COMMIT"
chezmoi diff
chezmoi apply "$HOME/path/to/reviewed-target"
```

Validate the target, then push the revert. Do not apply unrelated targets just
because they appear in the same repository.

### Repair a broken shell target

Use a working shell to inspect the source and rendered target:

```bash
/bin/zsh
chezmoi cat "$HOME/.zshrc"
/bin/zsh -n "$(chezmoi source-path "$HOME/.zshrc")"
chezmoi diff "$HOME/.zshrc"
```

Correct the source, apply only the repaired file, and rerun:

```bash
chezmoi apply "$HOME/.zshrc"
day-one-mac shell-status
day-one-mac setup --phase 05
```

### Investigate a surprising broad diff

Do not apply it. List ownership and inspect one target at a time:

```bash
chezmoi status
chezmoi managed -p absolute | LC_ALL=C sort
chezmoi --use-builtin-diff diff --no-pager
git -C "$(chezmoi source-path)" status --short
```

Decide whether the source, target, or both contain the correct state before
choosing `apply`, `add`, or `merge`.

Official references: [chezmoi diff tools](https://www.chezmoi.io/user-guide/tools/diff/)
and [chezmoi merge tools](https://www.chezmoi.io/user-guide/tools/merge/).

---

[← Reference library](README.md) · [Setup tutorial](CHEZMOI-SETUP-TUTORIAL.md) · [Command reference](CHEZMOI-COMMAND-REFERENCE.md) · [Alias editing guide](ZSH-ALIASES.md)
