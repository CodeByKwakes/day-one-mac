# Upgrade notes for earlier installations

> Historical upgrade record. Old setup-runner commands below are retired.
> Use the [current migration guide](migration/from-scripted-setup.md).

This page covers upgrades from earlier Day One Mac layouts and legacy
installations. A new Mac can start with the current installation guide.

> **Current installation:** download the release installer, run
> `day-one-mac --wizard`, and use the command names in
> [Command reference](reference/command-reference.md).

## October 2026 project reorganization

Public `day-one-mac` commands, phase IDs 01-08 and module IDs are preserved.
Module 12 remains retired. The current source provides `day-one-mac vscode-profile`
for profiles; check installed help before relying on it in a published release.
The local `v1.5.0` tag predates that command. See the [profile operation](tools/vscode-profiles.md) for availability and the supported alternative.
Implementations moved into `src/`; old supported script paths are small
compatibility entry points. The current source groups scripted setup under `docs/setup/assisted`, complete
manual tasks under `docs/setup/manual`, and shared requirements/reference under
`docs/shared`. Former `docs/how-to`, `docs/reference` and `docs/explanation`
paths remain compatibility guides.
Earlier guide links redirect to their canonical pages, including old headings.

The upgrade preserves `~/.day-one-mac`, ownership records, backups, settings and
Second Brain data. It does not apply setup phases or modify your applications.
Required-phase fingerprints now use explicit dependencies. Earlier markers may
show **changed - revalidate** once, even when the Mac still works correctly.
They remain saved; they are never converted into fresh success evidence.

After installing, run `day-one-mac runtime-status`, `day-one-mac verify` and
`day-one-mac setup --status`. Use `day-one-mac setup --check` for live machine
checks. Review a changed phase with `day-one-mac setup --phase NN --dry-run`
before choosing to rerun it. Do not delete state to hide a revalidation warning.
Rollback with `day-one-mac rollback-runtime --execute` selects the preceding
retained runtime; it does not undo setup actions or reset saved evidence.

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
| `day-one-mac optional-status` | `day-one-mac optional --status` |
| `day-one-mac modules` | `day-one-mac optional --status` |
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
# Or, if GNU wget with HTTPS support is already installed:
# wget --https-only --secure-protocol=TLSv1_2 -O "$INSTALLER" \
#   https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac
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

[← Reference index](README.md) · [Portable runtime](tools/runtime.md) ·
[Phase 5](../setup/manual/shell/README.md)

## Runtime and phase-contract upgrade

Required phases now fingerprint implementation and choices instead of guide
wording. Existing markers become stale once; saved choices, ownership records,
and installed software remain. Review `day-one-mac --status` and resume through
the wizard. Do not reset state or uninstall software for this migration.
Missing preset state retains `recommended-productivity`; `core` is opt-in.
Runtime rollback now follows the previously activated version. If no activation
history exists, specify `--version` explicitly. Runtime verification no longer
runs contributor tests. See [Architecture and state](explanation/architecture-and-state.md).
