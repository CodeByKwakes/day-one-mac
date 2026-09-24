# Upgrade notes for earlier installations

This page is only for a Mac that ran Day One Mac before the standalone runtime
was introduced. A new or factory-reset Mac does not need any item on this page.

> **Current installation:** download the release installer, run
> `day-one-mac --wizard`, and use the command names in
> [Command reference](COMMAND-REFERENCE.md).

## What the current release uses

| Purpose | Current location or command |
|---|---|
| Main command | `~/.local/bin/day-one-mac` |
| Versioned runtime | `~/.local/share/day-one-mac/releases/<version>` |
| Active runtime | `~/.local/share/day-one-mac/current` |
| Saved setup state | `~/.day-one-mac` |
| Read-only existing-Mac report | `day-one-mac safety-report` |
| Existing-Mac preparation | `day-one-mac prepare-existing` |
| Extended private report | `day-one-mac advanced-audit` |

Confirm the active installation with:

```bash
day-one-mac runtime-status
```

The result must show `standalone runtime`, the expected release version, and
`Integrity: verified`.

## Accepted compatibility names

The runtime still recognises these names so an existing installation can be
upgraded safely. Do not use them in new notes, aliases, or Warp workflows.

| Earlier name | Current replacement |
|---|---|
| `day-one-mac preflight` | `day-one-mac safety-report` |
| `day-one-mac prepare-reset` | `day-one-mac prepare-existing` |
| `day-one-mac audit` | `day-one-mac advanced-audit` |
| `prepare-existing-mac.sh --audit-only` | `day-one-mac prepare-existing --safety-report` |
| `prepare-existing-mac.sh --audit PATH` | `day-one-mac prepare-existing --preflight-report PATH` |
| `clean-development-state.sh --archive-container-data` | Use both `--archive-docker-data` and `--archive-orbstack-data` |
| `~/.fresh-mac-setup` | `~/.day-one-mac` |
| `FRESH_START_*` variables | `DAY_ONE_MAC_*` variables |
| `fresh-start` launcher | `day-one-mac` |

The compatibility code reads earlier state only when the current state is not
present. It never merges two state directories automatically.

## Move an existing Mac to the standalone runtime

Install the latest verified public release:

```bash
INSTALLER="$HOME/Downloads/install-day-one-mac"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
  -o "$INSTALLER"
chmod 700 "$INSTALLER"
less "$INSTALLER"
"$INSTALLER"
export PATH="$HOME/.local/bin:$PATH"
day-one-mac runtime-status
```

Then rerun Phase 5:

```bash
day-one-mac setup --phase 05
```

If chezmoi manages `~/.local/bin/day-one-mac`, Phase 5 backs up that source
entry, runs `chezmoi forget` for the launcher, and preserves the live command.
The standalone runtime must be the only owner of the launcher because runtime
updates and dotfile application are separate operations.

## If Phase 5 stops for a manual merge

Do not overwrite a customized template blindly. Review the source:

```bash
chezmoi source-path ~/.gitconfig
chezmoi edit ~/.gitconfig
chezmoi diff ~/.gitconfig
```

Apply only after the reviewed source contains the intended current settings:

```bash
chezmoi apply ~/.gitconfig
day-one-mac setup --phase 05
```

## Second Brain compatibility data

Current Obsidian manager state uses `~/.config/second-brain`. An earlier
installation may contain `~/.config/fresh-start-second-brain`; the manager can
read that path only to migrate known control files. Knowledge vault contents
remain user documents and are never removed as compatibility data.

## Completion check

- [ ] `day-one-mac runtime-status` reports a verified standalone runtime.
- [ ] `~/.local/bin/day-one-mac` is not listed by `chezmoi managed`.
- [ ] The current command names are used in personal notes and Warp workflows.
- [ ] Phase 5 passes after any reviewed dotfile merge.
- [ ] Earlier state is retained only until the current setup and rollback path
      have been verified.

---

[← Reference index](README.md) · [Portable runtime](PORTABLE-COMMAND.md) ·
[Phase 5](../01-required/05-dotfiles-and-shell.md)
