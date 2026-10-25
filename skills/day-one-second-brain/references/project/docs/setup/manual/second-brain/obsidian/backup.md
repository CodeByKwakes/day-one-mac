# Back up and restore an Obsidian vault

Use a versioned backup that covers the selected vault and its needed settings.
Sync can propagate a deletion; it does not replace a separate recovery copy.
Choose the backup service permitted for the material in that vault.

## Before changes

1. Find the vault's actual folder through Obsidian and confirm its name in Finder.

   Expected: the backup targets the intended vault, not another synced copy.

2. Use Time Machine or your approved backup service to back up that folder.

   Expected: the backup contains notes, attachments and required `.obsidian`
   settings. Review plugin and account data before copying settings elsewhere.

3. Back up the private repository connection file separately, if you use one.

   Expected: its local paths remain private and its copy is outside installed skills.

## Verify recovery

1. Select one harmless note from a dated backup.

   Expected: the backup version is identifiable without overwriting the live note.

2. Restore it to a new temporary folder using the backup application's restore controls.

   Expected: both the live note and the restored sample still exist.

3. Open both files and compare their text, properties and any required attachment.

   Expected: the restored content matches the chosen version. Record the result
   and backup reference in your private review note.

4. Before a larger restore, pause editing and review the exact replacement list.

   Expected: conflicting copies are preserved, and changes to the live vault
   have explicit approval. Do not copy an old `.obsidian` folder over current settings blindly.

## Optional local Git history

Git can help review text changes but does not replace the backup above. Keep
vault history separate from the code repositories linked in project notes.
Review ignored files and the complete staged diff before any initial commit.
Do not add a remote or push notes unless the account and data policy permit it.
The [Git guide](../../git/setup.md) owns Git setup; repository connections do not
initialize a vault repository or enable synchronization.

## Troubleshooting

If a restore is incomplete, keep the recovered copy and inspect the backup's
inclusion rules. If sync conflicts appear, preserve both versions before merging.
A successful note restore does not establish that every plugin or account is
recoverable; verify those separately when they are part of your recovery goal.
