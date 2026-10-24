# Set up a Second Brain

Choose a knowledge system for notes, sources and project support. This manual
route uses the selected application directly. Keep knowledge content separate
from code repositories unless the material is intentionally project documentation.

## 1. Choose the system and privacy boundary

| Choice | Use when | Complete task |
|---|---|---|
| Obsidian | Local Markdown files and file-based backups fit your needs | [Obsidian](obsidian/README.md) |
| Notion | Shared cloud databases, relations and views fit your needs | [Notion](notion/README.md) |

Expected result: a chosen owner, location and recovery plan. A work/personal
boundary may require separate physical vaults or cloud workspaces. A folder
label or `AI Allowed` property does not enforce access permissions.

## 2. Build the smallest useful structure

Follow the selected complete task and create one capture, one source-backed
note and one project. Add integrations only after capture and search work.

Expected result: you can find a saved note and identify its source without an AI
assistant. You do not need every domain, plugin or dashboard to start.

## 3. Test recovery

Follow the selected system's backup/export task and restore a harmless sample.

Expected result: the result is readable in a separate location. Cloud sync is
not protection against every deletion; Notion exports do not recreate every
permission, relation, view or page history.

## Troubleshooting and next steps

Use the owning application's guide for missing files, permission problems or
sync conflicts. Preserve conflicting copies before resolving them. Continue
with its operating workflow only after the sample restore succeeds.

## Link a repository without syncing its contents

1. Create a project note with the repository's public URL or a private, policy-approved reference. Expected: the note identifies the project without copying source or credentials.
2. Add the local checkout path as plain text for your own use. Expected: the vault remains separate from `~/Developer`; do not symlink source directories into a synced vault.
3. Open the repository in your editor and record a short approved summary in the note. Expected: Git owns code history and the vault owns notes, with no duplicate repository.
