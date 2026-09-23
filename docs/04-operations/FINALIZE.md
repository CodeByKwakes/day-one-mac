[← Phase 8](../01-required/08-verify-and-reproduce.md) · **Post-setup finalisation** · [Rollback →](ROLLBACK.md)

# Finalise or detach Day One Mac

Use this guide only after Phase 8 passes. Finalisation is not rollback: it
leaves installed applications, packages, projects, dotfiles, shell settings,
and macOS preferences unchanged.

## Choose the intended result

| Result | Command | What remains |
|---|---|---|
| Keep maintenance working | `day-one-mac finalize` | Compact `~/.day-one-mac`, dispatcher, Warp support, restore and rollback evidence |
| Detach completely | `day-one-mac finalize --detach` | Installed environment remains; state and portable command move to recovery |
| Remove some or all setup | `day-one-mac remove --guided` | Ownership-aware recorded, sectional, or full removal; not finalisation |

Do not delete `~/.day-one-mac` manually. It contains ownership manifests,
captured originals, verification evidence, settings restore information, and
the project locator used by the portable command.

## Compact and retain operations — recommended

Preview:

```bash
day-one-mac finalize
```

Execute only after the preview confirms Phase 8 and verification are current:

```bash
day-one-mac finalize --execute
```

This creates a checksum-protected evidence archive, archives the existing setup
log, moves obsolete `completed-*` reset directories into that archive, starts a
small new log, and writes:

```text
~/.day-one-mac/finalized-at
~/.day-one-mac/finalization.md
~/.day-one-mac/finalized/Day-One-Mac-Finalization-<UTC timestamp>/
```

It deliberately retains the current phase fingerprints, selections, manifests,
originals, verification report, application provenance, project locator, and
macOS settings recovery information.

Review later with:

```bash
day-one-mac finalize --status
```

## Detach completely

Detach is appropriate only when you want to keep the configured Mac but stop
using Day One commands, status, maintenance, restore, rollback, and imported
Warp workflows.

1. In Warp Drive, remove the imported **Day One Mac** collection. If it was
   never imported, no Warp action is needed.
2. Preview the detachment:

   ```bash
   day-one-mac finalize --detach
   ```

3. Prefer an encrypted recovery volume by selecting an archive parent:

   ```bash
   day-one-mac finalize \
     --detach \
     --warp-handled \
     --archive-root "/Volumes/Day One Backup" \
     --execute
   ```

4. Type exactly `DETACH DAY ONE MAC`.

The tool creates `Day-One-Mac-Detached-<UTC timestamp>`, verifies an evidence
archive and checksum, moves the portable command when present, then moves the
complete state directory into `day-one-mac-state/`. `~/.day-one-mac` therefore
no longer exists.

Installed software and configuration remain unchanged. A future `chezmoi
apply` may recreate the managed portable command; remove that source entry
deliberately if detachment should remain permanent.

## Restore a detached state

Read `DETACHED.md` inside the recovery directory. Restore only after checking
that the current paths do not contain newer state:

```text
<recovery>/day-one-mac-state  →  ~/.day-one-mac
<recovery>/day-one-mac-command  →  ~/.local/bin/day-one-mac
```

Set the command executable after restoring it. Reimport the Warp Drive folder
only when you want its workflows again.

## Safety boundaries

- Finalisation refuses to run before Phase 8 is recorded complete.
- A verification report containing `FAIL` or `REVIEW` blocks it.
- Missing install/path manifests block it.
- Detachment requires `--warp-handled` and a typed confirmation.
- The script does not use disk erase, broad recursive deletion, package
  uninstall, or settings reset commands.
- Keep the recovery directory until another encrypted backup has been tested.

---

[← Phase 8](../01-required/08-verify-and-reproduce.md) · [Review rollback →](ROLLBACK.md)
