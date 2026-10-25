# Prepare a verified encrypted backup destination

Use an existing approved encrypted external volume before copying irreplaceable
data. This task does not erase or format a disk. If no suitable volume exists,
ask its owner or IT to provision one through the approved storage process.

## 1. Identify the destination

Connect the drive and inspect it in Finder and Disk Utility. Confirm its label,
capacity, physical device and ownership before selecting it.

Expected result: the destination is an independent external device, not another
folder on the source Mac or an unrelated mounted volume.

## 2. Confirm encryption and available space

Inspect the volume's format/encryption status and unlock it using the approved
method. For the assisted account-preserving archive, the required destination is
an encrypted external APFS volume; APFS means Apple File System.

Expected result: the drive is readable, encrypted and has enough space for the
selected backup. Preserve recovery information independently of this Mac.

## 3. Create a clearly named backup folder

Use Finder to create a new folder on that volume. Inspect an existing folder
before reusing it; never overwrite the only previous backup.

Expected result: its Finder location identifies the external volume and the
intended new backup destination.

## 4. Copy selected data through its owner

Use the approved backup tool or Finder for ordinary files. Use application-native
exports or backup tools for databases and other live data. Record what is covered
and what needs a separate recovery process.

Expected result: the backup finishes without unresolved errors and includes the
selected source data. A safety inventory alone is not a backup.

## 5. Test a sample restore

Restore a harmless sample into a separate temporary folder and open it.

Expected result: the restored content is correct. Keep both source and backup
until verification succeeds. Database recovery needs its own isolated restore.

## Troubleshooting

| Symptom | Action |
|---|---|
| Drive is absent from Finder | Check cable, power and Disk Utility; do not initialise an unknown device |
| Drive will not unlock | Use the owner's recovery method; stop if it cannot be recovered |
| Capacity is insufficient | Obtain another approved destination or review backup scope without deleting the only copy |
| Existing backup folder conflicts | Choose a new destination and preserve the previous recovery point |

Use [Apple's backup guidance](https://support.apple.com/mac-backup) for the
selected backup method. Return to the calling setup task after the sample
restore passes; retain the destination and recovery details privately.
