[← Day One Mac home](../README.md) · [Choose a route →](00-existing-mac-decision.md)

# Stage 0 — Safely prepare an existing Mac

Use Stage 0 when this Mac still has files, applications, developer tools, or
settings from an earlier setup. Skip it only on a new or factory-reset Mac.
Day One Mac supports Apple-silicon Macs running a native `arm64` terminal only;
the Stage 0 wizard stops before work begins on Intel hardware or under Rosetta.

## Start here

Open Terminal and run:

```bash
cd "$(day-one-mac root)/scripts"
./prepare-existing-mac.sh --guided
```

The wizard first asks which result you want, then opens a progress dashboard.
The dashboard remains open after every safe step and automatically highlights
the next step. You may exit at any time; completed checks and selected paths
are saved under `~/.day-one-mac` and are rechecked when you return.

The dashboard always shows three diagnostic sections above its choices:

- **Saved completion status** — which gates genuinely pass now;
- **Saved paths** — the report, external backup folder, and latest snapshot;
- **Last result** — why the previous action passed, stopped, or remains locked.

Returning to the dashboard is normal. A step advances from `○` to `✓` only
after all of its checks pass. If Step 2 remains `○`, read **Last result** before
trying again; it identifies an unavailable drive, unwritable folder, missing
report copy, or failed checksum instead of hiding the message during redraw.

| Choice | What it means | What remains |
|---|---|---|
| **Route A — erase the Mac** | Apple removes the current accounts, files, applications, settings, and credentials | A blank-account experience; macOS itself remains installed |
| **Route B — keep the account** | The script removes the known development setup and all Homebrew-owned software | The current user, non-Homebrew applications, and unknown settings remain |
| **Not sure** | Create the read-only safety report first | Nothing is removed |

The script never erases a disk. For Route A, it shows a checklist and then
directs you to Apple's **Erase All Content and Settings** screen.
This first choice only changes the instructions you see; it does not start an
erase or cleanup. You can change routes after reviewing the report and backup.

## When to create the safety report

Create it **before Route A or Route B**. It is always Step 1.

The script filename calls this a `preflight audit`. In this guide, **audit**
simply means “inspect and report.” The safety report lists installed software,
repositories, containers, and important configuration locations. It helps you
notice items that need backing up.

> **The safety report is not a backup.** It records names and locations; it does
> not copy your projects, documents, passwords, databases, or settings.

## The complete journey

Route B now keeps report, backup, restore, preview, and cleanup work in one
continuous flow:

1. **Create and review the safety report.** Nothing is removed.
2. **Verify the encrypted external drive.** The wizard creates or selects a
   folder, copies the safety report into it, verifies checksums, and reads a
   report file back automatically.
3. **Create the development backup snapshot.** Choose whether to include
   `~/Developer`, local containers, local 1Password data, SSH keys, and large
   rebuildable tool caches. The cache option is off by default: package stores,
   downloaded runtimes, and installed VS Code extensions can be recreated from
   the reinstall inventories written into the snapshot. Portable VS Code
   settings, keybindings, snippets, and profiles are still copied. The wizard
   copies the selected files; it does not
   move or remove the originals.
   You then open a restored sample and confirm that it works. Temporary Unix
   sockets created by running tools such as Codex or Git are safely skipped;
   they are process connections, not settings or documents. The completed
   snapshot also omits Codex's rebuildable `.codex/.tmp` cache, which can hold
   process-owned files. Under `.codex/vendor_imports`, imported skill working
   files are copied but their rebuildable nested `.git` metadata is omitted.
   The snapshot records every omission and its reason in
   `transient-items-skipped.md`. User-managed repositories are different: their
   complete `.git` history is required. If a project contains files this account
   cannot read, the wizard does not skip them. It offers an explicit,
   administrator-assisted retry for that copy only, leaves the source unchanged,
   and records the exact paths in `administrator-read-access.md`.
   Checksums are created in batches with a file total, percentage, processing
   rate, and estimated time remaining. If checksum creation is interrupted,
   choose Step 3 again: the wizard offers to reuse the completed copies and
   resume at the last complete checksum batch.
4. **Preview Route B cleanup.** The exact removal and archive scope is printed,
   but nothing changes.
5. **Apply Route B cleanup.** This remains locked until Steps 1–4 pass with the
   current options. During Step 5, long archive moves show the current item,
   bytes, overall percentage, elapsed time, and estimated time remaining every
   30 seconds. Five minutes without measurable destination growth triggers a
   clear continue-or-stop prompt. Route A instead requires confirmation of a
   separate, complete backup before showing Apple's erase handoff.
6. **Begin Day One Phase 1.** Route B users restart the Mac first.

If Step 1 needs to be repeated, choose **Reset and re-run Step 1 — keeps old
reports and backup files** on either route dashboard. The reset archives only
the saved progress markers under `~/.day-one-mac/reset-history`, keeps every
report and external-drive file, and immediately starts a new safety report.

```text
Choose Route A or Route B
          │
          ▼
Safety report ──► encrypted drive + copied report
          │
          ├── Route A ──► confirm complete backup ──► Apple erase handoff
          │
          └── Route B ──► copy-only development snapshot
                                │
                                ▼
                        restore test ──► cleanup preview ──► apply
          │
          ▼
Day One Mac Phase 1
```

If Step 5 was started with an older script and appears silent, do not launch a
second cleanup. Use the activity checks and interruption procedure in
[Route B cleanup — If Step 5 appears stuck](03-account-preserving-cleanup.md#if-step-5-appears-stuck).
Stopping creates an `INCOMPLETE.md` recovery directory; it does not provide an
ordinary wizard retry. Review the recorded operations, then use the guarded
[`--resume-cleanup` recovery procedure](03-account-preserving-cleanup.md#recover-an-incomplete-step-5)
to continue in the same folder without moving completed items again.

## What is safe to try

- The safety report only creates a private report folder.
- At the end of a guided report, choose whether to open `SUMMARY.md` in the
  default Mac app, display it in Terminal, or finish and review it later.
- Route B preview prints targets without changing them.
- Route B apply is locked behind an encrypted external APFS volume, a verified
  report copy, a current development snapshot, a confirmed restore, a current
  cleanup preview, and several typed confirmations.
- Route A can only be started manually in macOS System Settings.

## Read in order

1. [Choose Route A or Route B](00-existing-mac-decision.md)
2. [Step 1 — create and review the safety report](01-private-inventory.md)
3. [How to create an encrypted external drive](ENCRYPTED-BACKUP-DRIVE.md)
4. [Steps 2–3 — copy and prove that the backup can be restored](02-backup-readiness.md)
5. [Route B only — preview or apply account cleanup](03-account-preserving-cleanup.md)
6. [Continue to Day One Phase 1](04-handoff-to-day-one.md)

## Technical command reference

Most users only need the guided command at the top. For automation or
troubleshooting:

```bash
# Create only the safety report.
./prepare-existing-mac.sh --safety-report

# Explain report contents without creating it.
./preflight-audit.sh --plan

# Preview Route B without the menu.
./prepare-existing-mac.sh --dry-run

# Verify a mounted drive and create a default named folder without the menu.
./prepare-existing-mac.sh --prepare-backup-folder \
  --backup-volume "/Volumes/Day One Backup"
```

The older options `--audit-only` and `--audit` still work, but the clearer
names `--safety-report` and `--preflight-report` are preferred.

To print the saved route, completion gates, and paths without opening the
interactive menu or changing anything:

```bash
./prepare-existing-mac.sh --status
```

---

[Choose a route →](00-existing-mac-decision.md)
