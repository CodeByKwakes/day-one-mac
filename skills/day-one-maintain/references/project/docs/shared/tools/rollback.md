# Recover recorded owned changes

`day-one-mac rollback` previews recovery using existing ownership manifests.
It is separate from runtime version rollback and cannot undo external account
changes, database migrations or unrecorded manual edits.

## Prerequisites

Preserve the state directory and independent backups. Read the preview and
confirm that every proposed path/package belongs to the intended operation.
Unknown ownership is a reason to stop, not to adopt or delete the resource.

## Steps

1. Read the installed help:

   ```bash
   day-one-mac rollback --help
   ```

   Expected result: the installed version's selection and confirmation options.

2. Run the default preview:

   ```bash
   day-one-mac rollback
   ```

   Expected result: the recorded scope and recoverable originals, with no removal.

3. Preserve current files and approve only the reviewed scope using the explicit
   execution options shown by that version's help.

   Expected result: a bounded operation with retained evidence. Do not add force
   flags to bypass an ownership or drift conflict.

4. Verify the selected application's behaviour using its manual guide.

   Expected result: recovered configuration and any unresolved changes identified.

For file/data restores, use [backup and restore](../../setup/manual/backup-and-restore.md).
For an installed runtime version, use [runtime rollback](runtime.md). Broad reset
and removal commands are retired; see [migration](../migration/from-scripted-setup.md).
