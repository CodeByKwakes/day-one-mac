[← Stage 0 home](README.md) · [Next: prove the backup works →](02-backup-readiness.md)

# Create an encrypted external backup drive

Use this guide before Stage 0 Step 2 if the external drive is new,
unencrypted, or not using APFS. **APFS** is Apple's current filesystem for Mac
storage. **Encryption** means the files cannot be read without the password.

The Day One scripts do not format, erase, or encrypt drives. Disk Utility does
that work, and you remain in control throughout.

> **Erasing a drive permanently deletes everything already on it.** Copy any
> files you need from the drive somewhere else first. Disconnect other external
> drives if that makes the correct device easier to identify.

## What you need

- a directly connected USB, Thunderbolt, or USB-C drive;
- a Mac administrator account;
- enough capacity for the data identified by the safety report, plus room for
  future recovery files; and
- a strong, unique encryption password stored somewhere you can recover without
  this Mac, such as a password manager available on another trusted device.

The drive does **not** have to be a Time Machine drive. A normal encrypted APFS
drive is the simplest choice for this workflow.

## Format and encrypt a dedicated backup drive

These steps erase the selected external drive.

1. Connect the drive directly to the Mac.
2. Open **Disk Utility**. Press Command-Space, type `Disk Utility`, then press
   Return.
3. In Disk Utility, choose **View → Show All Devices**. This shows both physical
   devices and the volumes stored on them.
4. In the sidebar, select the **top-level external physical device**. Check its
   name and capacity carefully. Do not select `Macintosh HD` or any item under
   the Internal heading.
5. Click **Erase**.
6. Enter a clear drive name, such as `Day One Backup`.
7. For **Scheme**, choose **GUID Partition Map**.
8. For **Format**, choose **APFS (Encrypted)**.
9. Enter a strong, unique password and record it safely. If this password is
   lost, the encrypted files may be unrecoverable.
10. Click **Choose**, then **Erase**. Wait for Disk Utility to finish and click
    **Done**.
11. Eject the drive in Finder, reconnect it, and confirm that macOS asks for the
    password and can unlock it.

Apple's current Disk Utility guidance also notes that encrypting an existing
unencrypted device this way requires erasing it first.

## Let Day One create the backup folder

Do not type a long `mkdir` command. Use the Stage 0 wizard:

```bash
cd "$(day-one-mac root)/scripts"
./prepare-existing-mac.sh --guided
```

1. Choose Route A or Route B.
2. Choose **Step 2 — verify the encrypted drive and copy the report**.
3. Choose **Create a new named folder**.
4. Select the mounted drive from the on-screen list. Choose **Enter a different
   mounted-volume path** only if it is not shown.
5. Press Return to accept the suggested folder name, or enter your own plain
   folder name.

The default includes the Mac's Computer Name and local date and time:

```text
My MacBook Pro Backup - 2026-09-12 23-00
```

The wizard displays times to people as `2026-09-12 23:00 BST`, but uses a dash
instead of the colon in folder names for safer Finder, shell, and cross-platform
copying. It verifies that the location is physical, external, encrypted, APFS,
mounted, and writable before creating anything. It copies and verifies the
safety report, remembers the selected folder, and returns to the progress
dashboard. Route B Step 3 then copies the selected development snapshot.

If you already have a suitable folder, choose **Use an existing folder**. The
same drive checks still run, and no existing contents are replaced.

## Verify the drive yourself

In Disk Utility, select the mounted volume and confirm:

- the location is **External**;
- the format is **APFS (Encrypted)**; and
- the volume is mounted and visible in Finder under Locations.

Technical users can also inspect it in Terminal:

```bash
diskutil info "/Volumes/Day One Backup"
```

Look for an APFS filesystem, `Internal: No`, and encryption enabled. Replace the
example path with the exact name shown in Finder.

## If you also want Time Machine

Time Machine is optional and does not replace the Stage 0 sample-restore test.
To configure it, open **System Settings → General → Time Machine**, choose
**Add Backup Disk**, select the destination, choose **Set Up Disk**, and enable
**Encrypt Backups**.

For the clearest separation, use either a different physical drive or a
separate encrypted APFS volume for the Day One recovery folder. Files placed
manually on a Time Machine destination are not a second backup of themselves,
and sharing one physical disk still leaves one point of hardware failure.

The Route B script needs an ordinary writable folder. If the Time Machine
volume does not allow one, add a separate encrypted APFS data volume in Disk
Utility or use another drive.

## Common problems

### The drive does not appear under `/Volumes`

Unlock it in Finder or Disk Utility. Try reconnecting it directly rather than
through an unpowered hub.

### The wizard says the drive is internal or virtual

You selected the startup disk, a disk image, or another non-physical location.
Stop and choose the mounted external drive itself. APFS normally presents a
real external disk through a synthetic container. The wizard follows that
container to its physical store automatically; an actual `.dmg` disk image is
still rejected. Update the repository and rerun the wizard if an older version
incorrectly rejected a physical APFS drive as virtual.

### The wizard says the drive is not encrypted APFS

Do not bypass the check. Back up anything already on the drive, then follow the
Disk Utility steps above, or select a different compliant drive.

### The folder already exists

The wizard will not merge into it silently. Review the folder, then explicitly
choose to reuse it or enter a new name.

## Official Apple references

- [Encrypt and protect a storage device in Disk Utility](https://support.apple.com/en-gb/guide/disk-utility/dskutl35612/mac)
- [Choose a Time Machine backup disk and encryption options](https://support.apple.com/guide/mac-help/choose-a-backup-disk-set-encryption-options-mh11421/mac)
- [Keep a Time Machine backup disk secure](https://support.apple.com/en-gb/guide/mac-help/mh21241/mac)

---

[← Stage 0 home](README.md) · [Next: prove the backup works →](02-backup-readiness.md)
