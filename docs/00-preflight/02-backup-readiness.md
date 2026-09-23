[← Safety report](01-private-inventory.md) · [Next: Route B cleanup →](03-account-preserving-cleanup.md)

# Steps 2–3 — Prepare, copy, and prove the backup can be restored

Do this after reviewing the safety report and before either route removes
anything.

A backup is ready only when it contains what matters **and** you can restore a
few sample items. A “copy completed” message alone is not enough.

## Backup-drive requirements

The Day One safety standard is an encrypted external drive. Encryption protects
the private report, projects, credentials, and settings if the drive is lost.

- **Route A:** Apple does not check the backup format for you. Day One still
  requires an encrypted external copy and a sample restore test before reset.
- **Route B apply:** the script strictly requires a writable folder on a
  physically attached, encrypted, APFS-formatted external drive. It rejects the
  internal disk, an unencrypted disk, network storage, and virtual disk images.

The drive does **not** need to be a Time Machine drive. A normal encrypted APFS
data volume works and is often easier to inspect. Time Machine can be an
additional backup, but its latest-backup date does not replace the sample
restore test.

## Check the drive in macOS

If the drive is not already encrypted APFS, follow the complete
[encrypted backup-drive guide](ENCRYPTED-BACKUP-DRIVE.md). Formatting a drive
erases its current contents, so the Day One script deliberately never performs
that action.

When the drive is ready, let the wizard verify it and prepare the folder:

```bash
cd "$(day-one-mac root)/scripts"
./prepare-existing-mac.sh --guided
```

Choose the same route as before, then choose **Step 2 — verify the encrypted
drive and copy the report**. You can create a new folder or select an existing
one. Mounted user-visible drives appear as a menu; hidden Time Machine service
mounts are excluded. Most users do not need to type a `/Volumes/...` path. The
default new name is the Computer Name plus a readable local date and time, such
as:

```text
My MacBook Pro Backup - 2026-09-12 23-00
```

Folder names use `23-00` while screen messages use `23:00`; avoiding the colon
makes the name safer if files are later copied to another platform. The wizard
copies and verifies the safety report, remembers the folder, and returns to the
progress dashboard without exiting.

Returning to the dashboard means the action finished; it does not by itself
mean success or failure. Check the automatically displayed **Last result**:

- `✓ Step 2 completed` means the menu row also changes to `✓` and Step 3 opens.
- `✗ Step 2 is incomplete` is followed by the exact missing check. Unlock or
  reconnect the named drive, correct the folder problem, or run Step 2 again.
- If **Backup folder** says `not recorded`, folder selection stopped before the
  drive passed the physical, external, encrypted APFS, and write checks.

Do not reset Step 1 to fix a drive problem. Use the dashboard's reset action
only when you intentionally want to replace the current safety report; it
preserves old reports and backup files.

### If an APFS drive is reported as virtual

An APFS **container** is a virtual layer even when it is stored on a real USB
or Thunderbolt disk. The wizard follows that layer to its physical store and
then verifies the whole disk is external. Current Day One Mac supports the
different physical-store field names emitted by `diskutil` across macOS
versions. When this check passes, the terminal shows both the physical-store
identifier and the verified external volume.

If the latest script still cannot resolve the backing disk, do not bypass the
check. Keep the drive connected and collect these read-only details for review:

```bash
diskutil info "/Volumes/Day One Backup"
diskutil apfs list
```

These commands only display disk information; they do not format or change the
drive. Replace `Day One Backup` if Finder shows a different volume name.

Next choose **Step 3 — copy the selected backup snapshot and test a restore**.
The checkbox screen controls both the snapshot and the later cleanup scope.
Known development configuration is always copied. You can additionally include
projects, container data, local 1Password data, detected SSH private keys, and
large rebuildable tool downloads. Leave the rebuildable-cache option off for a
normal portable backup. The snapshot still includes package, runtime, and VS
Code extension inventories plus portable VS Code settings, keybindings,
snippets, and profiles, so the omitted downloads can be installed again.
The script creates a dated `Day-One-Mac-Backup-Snapshot-...` folder and leaves
all source files, applications, and Homebrew in place.

Checksum progress shows completed files, the total, a percentage, processing
rate, and an estimated remaining time. If you interrupt that stage, return to
Step 3. For a copy-complete snapshot, the default resume choice continues the
checksum work without recopying the source folders. An older incomplete
checksum created by a previous script version is rehashed using the faster
batch method, but its already copied data is still reused.

This distinction is deliberate:

- **Backup step:** copies files, so the working Mac remains unchanged.
- **Final Route B cleanup:** moves known settings into a separate recovery
  folder and removes Homebrew-owned software only after all gates pass.

## Decide what must be copied

Use the safety report as the checklist. Consider:

- documents, media, downloads, and project folders;
- every `DIRTY` Git repository, unpushed commit, and stash;
- every `NO-REMOTE` repository, because no remote copy is configured;
- database dumps and Docker or OrbStack volumes;
- application exports, licences, profiles, snippets, and unsynced settings;
- SSH keys, certificates, signing keys, recovery codes, and secure notes;
- the chezmoi source plus configuration that chezmoi does not manage; and
- the complete safety-report folder.

Personal folders such as `~/Documents`, `~/Downloads`, Photos libraries, and
knowledge vaults are not automatically included in the development snapshot.
Copy them separately if they matter, especially before Route A.

1Password vaults and macOS Keychain records are credential systems rather than
ordinary folders. Confirm that you can sign in and recover them on a second
trusted device. Do not delete a cloud vault or reset the Keychain just to clean
one Mac.

## Test that recovery really works

Restore representative samples into a temporary folder and open or use them:

1. one document and one photo or video;
2. one private Git repository, including an uncommitted test file if relevant;
3. one important database dump into a disposable database;
4. one application settings export; and
5. the copied safety report, verified with `SHA256SUMS.txt`.

Write down the test date, drive name, samples restored, and outcome in a note on
the external drive.

## Ready-to-continue check

- [ ] The external drive is mounted, unlocked, and writable.
- [ ] It is encrypted; Route B users also confirmed APFS format.
- [ ] The complete safety report is on the drive and its checksums pass.
- [ ] Every `DIRTY` or `NO-REMOTE` repository has a recovery plan.
- [ ] Important databases or containers have a tested export.
- [ ] Representative documents, repositories, settings, and database data
      restored successfully.
- [ ] Required accounts and recovery information work on another trusted device.

When Step 3's restore confirmation is saved, the dashboard marks it `✓` and
highlights the cleanup preview. If you intentionally leave the wizard, return
with the same command:

```bash
cd "$(day-one-mac root)/scripts"
./prepare-existing-mac.sh --guided
```

---

[← Safety report](01-private-inventory.md) · [Next: Route B cleanup →](03-account-preserving-cleanup.md)
