# Day One recover

Read [backup and restore](../project/docs/setup/manual/backup-and-restore.md),
[lifecycle guidance](../project/docs/setup/manual/lifecycle.md) and, for older
installations, [migration](../project/docs/shared/migration/from-scripted-setup.md).

Identify the exact component, installation owner, affected files and application
data. A package inventory is not a data backup. Preview what will change and
confirm destructive scope with the user before execution.

Stage restores separately, verify checksums and inspect conflicts before
replacing active files. Preserve the current version when possible. Removing
the Day One Mac bundle does not mean removing tools it helped configure.

Never erase or format disks, delete unowned data, run broad package cleanup or
remove a volume because its name looks familiar. For a failed partial operation,
inspect its journal and current state before retrying. A rollback command may
not reverse database migrations or external account changes; state the limit.
