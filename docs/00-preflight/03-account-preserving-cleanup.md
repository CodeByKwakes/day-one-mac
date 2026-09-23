[← Backup readiness](02-backup-readiness.md) · [Next: Day One handoff →](04-handoff-to-day-one.md)

# Route B only — Preview or apply account cleanup

Skip this page if you chose Route A.

Route B keeps macOS, the current user account, FileVault, Apple Command Line
Tools, and applications that Homebrew does not own. It removes the known
development setup, so it is not the same as a factory reset.

## Use the guided route

```bash
day-one-mac prepare-existing --guided
```

Choose **Route B**. The next screen makes the order visible:

1. **Create and review the safety report.** Required before any backup action.
2. **Verify the encrypted drive and copy the report.** Checksums and an
   automatic read-back must pass.
3. **Copy the selected development snapshot and test a restore.** The originals
   remain in place during this step.
4. **Preview cleanup.** Safe to run; it makes no changes.
5. **Apply cleanup.** Available only after Steps 1–4 pass for the current scope.

The wizard returns to this dashboard after each safe step. A `✓` shows what is
complete, `○` shows the next available action, and `🔒` shows what is waiting
for an earlier gate. You can still exit at any time and resume with the same
command.

## Understand the preview

The preview prints the exact targets found on this Mac. It shows:

- all Homebrew formulae and casks that apply would remove;
- known development configuration that would move into recovery;
- optional project, container, 1Password, and SSH data you selected; and
- items the script deliberately leaves alone.

Nothing is moved or removed in preview mode. Rerun the preview if you install,
remove, or change anything before applying.

## Backup and cleanup scope choices

On a checkbox screen, use Up/Down to move, Space to turn an item on or off, and
Return to accept the full list.

| Choice | During Step 3 backup | During Step 5 cleanup |
|---|---|---|
| Include `~/Developer` | Copies the whole project root. | Moves the project root to recovery. Leave this off if projects must stay active. |
| Include Docker Desktop data | Copies all known Docker Desktop container and group-container locations. | Moves those known locations; custom locations are not guessed. |
| Include OrbStack data | Copies all known OrbStack application, virtual-machine, cache, and support-data locations. | Moves those known locations; custom locations are not guessed. |
| Include local 1Password data | Copies known local app-support data. | Moves that data. Cloud vaults, items, keys, and the account are never deleted. |
| Include SSH private keys | Copies detected private and matching public keys. | Moves the same files from `~/.ssh`. |
| Include rebuildable tool downloads and caches | Optional. Copies downloaded runtimes, npm/pnpm caches, the pnpm store, VS Code extensions, and full VS Code local data. Leave off normally; portable settings and reinstall inventories are still retained. | Cleanup always moves detected rebuildable data into its dated recovery archive rather than deleting it directly. |
| Write Keychain instructions | Adds a manual guide to the snapshot. | Adds the guide; the script never changes Keychain data. |
| Use Homebrew cask zap | No removal occurs during backup. | Removes support-data paths declared by casks. Review carefully because these may contain real app data. |

Quit Docker Desktop, OrbStack, 1Password, and Homebrew-installed applications
before archiving their live data. Export important databases separately;
archiving a container virtual machine is not a database restore test.

Other running developer tools may leave temporary Unix sockets or named pipes
inside folders such as `~/.codex` or a Git repository. These are live
connections between processes; they contain no restorable document or setting.
During the copy-only snapshot, the script skips those endpoints, continues
copying normal files, and lists each omission in `transient-items-skipped.md`.
It also omits
the rebuildable `~/.codex/.tmp` runtime/plugin cache; durable Codex settings,
skills, rules, and non-temporary plugin data remain in the snapshot. For
`~/.codex/vendor_imports`, the imported skill working files are preserved while
only their nested, rebuildable `.git` metadata is omitted. User-managed Git
repositories elsewhere are copied in full. If one contains an unreadable Git
object or another permission-protected file, the snapshot stops instead of
silently omitting it. In the guided wizard you can approve one administrator-
assisted retry for that exact copy. This uses elevated access only to read the
source; it does not change source ownership or permissions. The backup copy is
made readable by the current user, and the exact source and destination are
listed in `administrator-read-access.md`. During the final cleanup, close
developer tools first so their active state is settled.

Before each copy begins, the terminal shows the exact source, estimated size,
and destination. During a long copy it prints an update every 30 seconds. If
the destination has not measurably grown for five minutes, the wizard explains
which source is affected and lets you keep waiting or stop safely. Stopping a
copy-only snapshot never removes a source file; the unfinished recovery folder
is marked `INCOMPLETE.md` and is not accepted as a valid backup.

After copying, the script builds one file list and checks files in batches. The
terminal shows `completed/total`, percentage, rate, and estimated time
remaining. A completed snapshot contains `SNAPSHOT-COMPLETE`, which is tied to
the checksum manifest. The dashboard validates that small marker instead of
re-reading every backed-up file whenever the menu is redrawn. You can still run
a deliberate full check later from the snapshot root:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

If the checksum stage is interrupted, select Step 3 again and accept the resume
option. Completed file copies are reused, and new checksum batches continue
from the last completed batch. The original Mac remains unchanged.

## What apply does

After all safety gates and confirmations, apply:

1. checks free space and creates a dated recovery folder on the external drive;
2. records the current applications and Homebrew packages;
3. changes to the external recovery folder so its working location cannot be
   moved out from under it;
4. moves ordinary selected development settings into recovery;
5. removes Homebrew casks and formulae;
6. removes Homebrew only after cask removal succeeds; and
7. moves `~/Developer` and the Day One Mac progress folder last.

Step 5 shows a separate archive-progress section before it starts moving data.
For each existing source it prints the current item number, source and
destination. Long moves update every 30 seconds with bytes processed, overall
percentage, elapsed time, and estimated time remaining. This is a live
heartbeat: changing destination size means the operation is still working even
when `mv` itself produces no terminal output. If no measurable growth is seen
for five minutes, the wizard names the affected source and asks whether to keep
waiting or stop. A safe stop leaves the recovery directory marked
`INCOMPLETE.md`; inspect `operations.tsv` before retrying because earlier items
may already have moved.

After the moves, checksum creation has its own file count, percentage, rate,
elapsed time, and estimated time remaining. Keep the external drive connected
until the final **development cleanup complete** message appears.

### If Step 5 appears stuck

Do not stop Step 5 merely to obtain the newer progress display. A cleanup that
has already started keeps running the version of the script it started with.
From a second terminal, inspect the active recovery directory without starting
another cleanup. Replace the example with the exact **Recovery** path printed by
your run:

```bash
RECOVERY="/Volumes/Backup Drive/My Mac Backup/Day-One-Mac-Clean-Recovery-YYYYMMDDTHHMMSSZ"

pgrep -fl 'clean-development-state|mv|brew|shasum'
du -sh "$RECOVERY"
tail -n 20 "$RECOVERY/operations.tsv"
```

Run `du -sh "$RECOVERY"` again after one or two minutes. A growing size means
the archive is still receiving data. A matching process also means work is
still active, although a large directory can spend time scanning many small
files before its measured size changes.

If stopping is genuinely necessary, press **Control-C once** and wait for the
shell prompt to return. Do not eject the recovery drive. Confirm the interrupted
run was labelled:

```bash
test -f "$RECOVERY/INCOMPLETE.md" \
  && echo "Cleanup safely marked incomplete"

tail -n 30 "$RECOVERY/operations.tsv"
```

An interrupted Step 5 must not be restarted as a new cleanup because earlier
items may already have moved. The cleanup tool has a separate, guarded resume
mode for a recovery folder marked `INCOMPLETE.md`. It reuses the original
inventories, skips source paths that have already moved, preserves a path that
an application recreated under `resume-additions/`, and continues package
removal and checksums in the same recovery folder. See **Recover an incomplete
Step 5**
below. If the wizard's progress folder was archived by an older release, the
dashboard may look empty; that does not mean the safety report or backup was
deleted.

### Recover an incomplete Step 5

Use this only when Step 5 created `INCOMPLETE.md`. Keep the encrypted drive
connected. Open a **new Terminal window** and first move to a location that
still exists:

The guided wizard is the recommended recovery method. From an updated project
copy stored outside `~/Developer`, run:

```bash
cd "$HOME/Downloads/MacOS-recovery/day-one-mac/scripts"
./prepare-existing-mac.sh --guided
```

Choose **Route B**. The first highlighted action is **Resume latest incomplete
Step 5** when a valid incomplete recovery is found in the recorded backup
folder or on a mounted external volume. The wizard shows the exact recovery
path and restores the original archive and cask-zap choices from that recovery.
If those choices cannot be recovered, it stops for an explicit scope review
instead of guessing. The manual commands below remain available as a fallback.

```bash
cd "$HOME"
RECOVERY="/Volumes/Backup Drive/My Mac Backup/Day-One-Mac-Clean-Recovery-YYYYMMDDTHHMMSSZ"
test -f "$RECOVERY/INCOMPLETE.md" \
  && tail -n 40 "$RECOVERY/operations.tsv"
```

Replace `RECOVERY` with the exact path printed by the failed run. If the test
does not print the operation log, stop: the selected directory is not the
incomplete recovery folder.

Use Apple's **Terminal** app for this recovery—not Warp—because Step 5 may
uninstall the Homebrew-managed Warp application. Quit VS Code, Warp, OrbStack,
and the other Homebrew-managed applications before continuing. An application
opened after the interruption may recreate a small settings directory. Resume
keeps that new directory under `resume-additions/<resume-id>/home/...` instead
of overwriting the version already archived. Homebrew is also rediscovered at
its standard Apple silicon or Intel location when the archived shell files no
longer add it to `PATH`.

Get the current project into a temporary location **outside `~/Developer`**.
This matters when the interrupted run already moved the original checkout:

The public repository needs no GitHub credential. Keep this temporary recovery
copy outside `~/Developer`, which may already have been archived.

```bash
git clone https://github.com/CodeByKwakes/day-one-mac.git \
  "$HOME/Downloads/day-one-mac-recovery"
cd "$HOME/Downloads/day-one-mac-recovery/scripts"
```

Run the cleanup tool with the same archive choices used by the interrupted
run. For example, a run that selected projects, OrbStack data, SSH private
keys, and cask zap resumes with:

```bash
./clean-development-state.sh \
  --execute \
  --resume-cleanup "$RECOVERY" \
  --zap-cask-data \
  --archive-projects \
  --archive-orbstack-data \
  --archive-ssh-private-keys
```

Add `--archive-docker-data`, `--archive-1password-data`, or
`--prepare-keychain-reset` only if that same choice was enabled in the failed
run. Newer recovery folders contain `cleanup-options.tsv`, and resume refuses
options that do not match it. Older folders do not have that file, so the tool
warns you and uses the options typed on the command line.

The resume still asks for the cleanup and credential confirmation phrases. It
does not recopy completed items or create a second recovery folder. Review any
`resume-additions/` directory before restoring application settings; its files
were created after the original archive. Success is shown by all three of these
checks:

```bash
test ! -e "$RECOVERY/INCOMPLETE.md"
test -s "$RECOVERY/SNAPSHOT-COMPLETE"
(cd "$RECOVERY" && shasum -a 256 -c SHA256SUMS.txt)
```

At the end, the terminal shows a short **Step 5 resume result**. The generated
`resume-summary.md` separates failures retained from earlier attempts from
operations completed or failed during the latest resume. Earlier `failed`
entries remain in `operations.tsv` as audit history and do not, by themselves,
mean the resumed cleanup failed.

Do not delete the temporary checkout or any recovery data until those checks
pass and you have opened a restored sample.

The recovery folder contains a readable `README.md`, `cleanup.log`,
`operations.tsv`, `settings-scope.md`, inventories, manual follow-up notes, and
checksums. A backup snapshot also contains `transient-items-skipped.md`. If
rebuildable downloads were omitted, `reinstall-inventories/` records tool
versions, npm and pnpm global packages, fnm-managed Node versions, and VS Code
extensions. If an operation stops part-way through, its folder is labelled
`INCOMPLETE.md` and
is never accepted by the wizard as a verified snapshot. If a cask fails to
uninstall, Homebrew is kept so you can diagnose and retry safely.

Before apply begins, the script requires:

- an encrypted physical external APFS recovery folder;
- a complete safety report inside that recovery folder;
- valid report checksums;
- enough recovery-drive space for the selected data plus safety headroom; and
- multiple exact typed confirmations.

## Technical non-wizard commands

Most users should use the wizard. These commands are for repeatable technical
operation.

Preview:

```bash
day-one-mac prepare-existing --dry-run
```

Apply, replacing both example paths:

```bash
day-one-mac prepare-existing --apply \
  --archive-root "/Volumes/Backup Drive/My MacBook Pro Backup - 2026-09-12 23-00" \
  --preflight-report "/Volumes/Backup Drive/My MacBook Pro Backup - 2026-09-12 23-00/Safety Report - 2026-09-12 23-05-00" \
  --archive-projects \
  --archive-docker-data \
  --archive-orbstack-data
```

The older `--audit` path option remains supported but is no longer the
recommended spelling. The older `--archive-container-data` flag also remains
available as a compatibility alias; it selects both Docker Desktop and
OrbStack data.

## What Route B leaves behind

Route B does not clear every setting. Manually installed applications, unknown
support files, macOS preferences, iCloud state, login items, privacy grants,
Keychain records, and unknown background services can remain. Read the
generated `settings-scope.md` for the exact boundary.

Choose Route A instead if this remaining state is unacceptable.

---

[← Backup readiness](02-backup-readiness.md) · [Next: Day One handoff →](04-handoff-to-day-one.md)
