[← Phase 5](../../01-required/05-dotfiles-and-shell.md) · [Reference library](../README.md)

# Phase 5 shell-file reference

This folder contains readable reference copies of the shell files created or
adopted by Phase 5. Use them to compare an upgraded Mac with the current Day
One Mac layout before accepting a chezmoi change.

These are **references, not an installer**. Do not copy the whole folder over
your home directory. Existing shell files can contain reviewed company or
personal configuration that should be merged rather than erased.

## Reference tree

```text
home/
├── .gitignore_global
├── .zprofile
├── .zshrc
└── .config/
    ├── starship.toml
    └── zsh/
        ├── aliases.zsh
        └── path.zsh
```

Show the hidden filenames with:

```bash
ls -la "$(day-one-mac root)/docs/20-reference/phase-05-shell-files/home"
```

The `path.zsh` reference represents a Mac with the Node.js stack selected, so
it includes `PNPM_HOME`. On a Python-only Mac, the final `PNPM_HOME` block is
correctly absent. The comment above the source line in `.zprofile` is harmless
and is normally present when the portable command was installed before Phase
5.

Git identity and SSH configuration are not duplicated here because their
correct content depends on the selected hosting track, authentication mode,
email, primary-IDE choice, and organisation policy. The portable global Git
ignore is included because it is the same on every Mac. Phase 5 explains the
machine-specific files' required shapes and the runner verifies their semantics.

## Compare without changing anything

Set the reference location once:

```bash
REFERENCE="$(day-one-mac root)/docs/20-reference/phase-05-shell-files/home"
```

Compare each applied file:

```bash
diff -u "$REFERENCE/.zprofile" "$HOME/.zprofile" || true
diff -u "$REFERENCE/.zshrc" "$HOME/.zshrc" || true
diff -u "$REFERENCE/.gitignore_global" "$HOME/.gitignore_global" || true
diff -u "$REFERENCE/.config/zsh/path.zsh" "$HOME/.config/zsh/path.zsh" || true
diff -u "$REFERENCE/.config/zsh/aliases.zsh" "$HOME/.config/zsh/aliases.zsh" || true
diff -u "$REFERENCE/.config/starship.toml" "$HOME/.config/starship.toml" || true
```

In a diff, lines beginning with `-` belong only to the reference shown first;
lines beginning with `+` belong only to the current file shown second. A
difference is not automatically wrong—review personal additions before
changing anything.

Compare the chezmoi source with its applied targets too:

```bash
chezmoi diff
chezmoi status
```

## Safely adopt a required reference change

For an existing chezmoi source, edit the source rather than overwriting the
applied file:

```bash
chezmoi edit "$HOME/.zshrc"
chezmoi diff "$HOME/.zshrc"
chezmoi apply "$HOME/.zshrc"
```

Repeat that sequence for the specific file that needs a reviewed change.
Finish with:

```bash
/opt/homebrew/bin/zsh -n "$HOME/.zprofile"
/opt/homebrew/bin/zsh -n "$HOME/.zshrc"
/opt/homebrew/bin/zsh -n "$HOME/.config/zsh/path.zsh"
/opt/homebrew/bin/zsh -n "$HOME/.config/zsh/aliases.zsh"
day-one-mac shell-status
day-one-mac setup --phase 05
```

---

[← Phase 5](../../01-required/05-dotfiles-and-shell.md) · [Reference library](../README.md)
