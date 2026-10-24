[← Phase 5](../../docs/setup/manual/shell/README.md) · [Reference library](../../docs/shared/README.md)

# Shell-file reference

This folder contains readable reference copies of the shell files used by the
manual shell guide. Use them to compare an upgraded Mac with the current Day
One Mac layout before accepting a chezmoi change.

These are **references, not an installer**. Do not copy the whole folder over
your home directory. Existing shell files can contain reviewed company or
personal configuration that should be merged rather than erased.

These copies show the Node + Starship variant. Omit the Starship initialization
block and `starship.toml` when Starship is not selected, and the `PNPM_HOME`
block for a Python-only setup. With unmanaged configuration, edit the target
files directly; do not initialize or adopt them into chezmoi. The shared file
layout works with either Apple or Homebrew zsh.

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
ls -la "/absolute/path/to/reviewed/templates/phase-05-shell-files/home"
```

The `path.zsh` reference represents a Mac with the Node.js stack selected, so
it includes `PNPM_HOME`. On a Python-only Mac, the final `PNPM_HOME` block is
correctly absent. Review each source line in `.zprofile` against your selected shell layout.

Git identity and SSH configuration are not duplicated here because their
correct content depends on the selected hosting track, authentication mode,
email, primary-IDE choice, and organisation policy. The portable global Git
ignore is included because it is the same on every Mac. The manual shell guide explains machine-specific files and their verification.

## Compare without changing anything

Set the reference location once:

```bash
REFERENCE="/absolute/path/to/reviewed/templates/phase-05-shell-files/home"
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
command -v git
command -v node
```

---

[← Phase 5](../../docs/setup/manual/shell/README.md) · [Reference library](../../docs/shared/README.md)
