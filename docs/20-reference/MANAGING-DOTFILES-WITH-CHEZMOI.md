[← Reference library](README.md) · [Phase 5](../01-required/05-dotfiles-and-shell.md) · [Shell-file examples](phase-05-shell-files/README.md)

# Update shell dotfiles safely with chezmoi

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

## Which command should I use?

| Situation | Correct action |
|---|---|
| You want to make a new planned change | `chezmoi edit TARGET`, preview, then `chezmoi apply TARGET` |
| The source is correct and the active target is stale | `chezmoi apply TARGET` |
| The active target has the reviewed change you want to preserve | `chezmoi add TARGET`, then inspect the source diff |
| Both source and target contain changes you need | `chezmoi merge TARGET`, preview, then apply |
| You want a visual inspection | `chezmoi diff TARGET` and `chezmoi cat TARGET` |
| You need diff text in Terminal or automation | `chezmoi --use-builtin-diff diff --no-pager TARGET` |

Templates require extra care because their source contains template logic, not
only rendered text. Prefer `chezmoi edit TARGET`; do not replace a template by
blindly adding its rendered target.

## Recovery

Before accepting a surprising change, stop and copy the diff into a private
note. Git-versioned sources can restore a reviewed source file with a normal
Git revert. The applied target can then be regenerated with `chezmoi apply`.
Never use destructive Git reset commands as a troubleshooting shortcut.

Official references: [chezmoi diff tools](https://www.chezmoi.io/user-guide/tools/diff/)
and [chezmoi merge tools](https://www.chezmoi.io/user-guide/tools/merge/).

---

[← Reference library](README.md) · [Phase 5](../01-required/05-dotfiles-and-shell.md) · [Alias editing guide](ZSH-ALIASES.md)
