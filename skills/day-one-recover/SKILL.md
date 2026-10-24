---
name: day-one-recover
description: Prepare backups, restore selected configuration or remove explicitly selected owned components. Use for recovery, rollback or uninstallation, not broad disk cleanup.
---

# Day One recover

Read [backup and restore](references/project/docs/setup/manual/backup-and-restore.md),
[lifecycle guidance](references/project/docs/setup/manual/lifecycle.md) and, for older
installations, [migration](references/project/docs/shared/migration/from-scripted-setup.md).

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

## Installed package

Resolve bundled links relative to this skill directory, not the working directory.
The project reference snapshot is under `references/project/`; use its matching
paths when a guide refers to supplied configuration or template files. Read only
the guide needed for the current task. Keep this installed package unchanged.

The skill is already available after installation. Workspace export is an
optional alternative; do not require it to begin. Save approved private notes
in a user-selected workspace. The optional `day-one-mac` utility command needs
a separate installation; use the manual recipes when that command is absent.
