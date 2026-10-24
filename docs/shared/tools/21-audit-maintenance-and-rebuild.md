# Audit utility records and maintain the Mac

This optional tool snapshots bounded utility evidence. It does not certify
account access, backups, FileVault, remote repositories or overall machine health.
Use [manual maintenance](../../setup/manual/maintenance.md) and
[shared verification](../verification.md) for those checks.

## Prerequisites

Install the optional utility bundle on Apple silicon. Existing utility selections
are inspected when present. Retired setup phase records are optional history;
new installations do not need to create them.

## Create and verify a snapshot

1. Preview the inspection scope.

   ```bash
   day-one-mac tool --module 21 --plan
   ```

   Expected result: runtime checks, explicit selection records and retained
   utility checks. No snapshot is created by the preview.

2. Approve one snapshot.

   ```bash
   day-one-mac tool --module 21 --apply --yes
   ```

   Expected result: a private artifact directory containing `report.md` and
   `evidence.tsv`. Failures remain visible; previous snapshots are retained.

3. Recheck the snapshot against current evidence.

   ```bash
   day-one-mac tool --module 21 --check
   ```

   Expected result: unchanged evidence, or a failure explaining drift. Review
   drift before creating a replacement snapshot. Do not edit records to make
   the check pass.

## Maintenance, removal and rebuild

Follow [lifecycle tasks](../../setup/manual/lifecycle.md) to install, update,
remove or recover a selected component. Identify its installation owner and
back up affected configuration first. Neither setup route performs broad cleanup.

For a rebuild, choose the AI-assisted or manual route on the target Mac and
verify each selected capability. Use a tested backup; a passing runtime checksum
or an old phase marker cannot replace restoration evidence.

## Recovery

A failed snapshot does not undo software or configuration. Preserve the report,
repair the specific capability, then make a new snapshot. If the runtime itself
is damaged, use [runtime rollback](runtime.md). Keep earlier evidence until you
have checked the repaired state.
