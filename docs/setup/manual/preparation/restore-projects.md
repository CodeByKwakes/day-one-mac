# Restore selected projects and application data

Use this task after choosing the destination layout and preparing a readable
backup. Review the [backup prerequisites](../../../shared/prerequisites.md) and
write a list of files to restore before copying anything. Git access is required
for repository clones; database and application imports require their selected
clients.

Before saving reports, complete the [private evidence directory prerequisite](../../../shared/private-evidence.md).

## 1. Make the restore decision explicit

Before connecting a disk, decide which statement is true:

```text
A. No restore: this machine starts without previous user data.
B. Selective restore: a reviewed backup contains specific files to recover.
```

Do not browse an unknown disk and gradually copy whatever looks familiar. Write
a restore list first: documents, repositories, database dumps, application
exports, and any exceptional local-only files.

## 2. Select and validate the mounted volume

```bash
printf 'Mounted backup path under /Volumes: '
IFS= read -r BACKUP_VOLUME
[[ "$BACKUP_VOLUME" == /Volumes/* ]] || {
  printf 'Refusing a path outside /Volumes\n' >&2
  return 1 2>/dev/null || exit 1
}
[[ -d "$BACKUP_VOLUME" && -r "$BACKUP_VOLUME" ]] || {
  printf 'Backup is missing, unreadable, or unmounted: %s\n' "$BACKUP_VOLUME" >&2
  return 1 2>/dev/null || exit 1
}
df -h "$BACKUP_VOLUME"
```

Resolve the exact backup root below that volume and quote it in every command:

```bash
printf 'Backup directory relative to that volume: '
IFS= read -r backup_directory
BACKUP_ROOT="$BACKUP_VOLUME/$backup_directory"
[[ -d "$BACKUP_ROOT" ]] || {
  printf 'Backup root not found: %s\n' "$BACKUP_ROOT" >&2
  return 1 2>/dev/null || exit 1
}
find "$BACKUP_ROOT" -maxdepth 2 -type f -print | sed -n '1,120p'
```

Do not use a guessed `/Volumes/<name>` in multiple commands. Keep the validated
variable in the current terminal and revalidate it after sleep, logout, or
reconnection.

## 3. Verify manifests and checksums

If the backup has a checksum manifest:

```bash
cd "$BACKUP_ROOT"
shasum -a 256 -c SHA256SUMS
```

If it does not, record that limitation before restoring. Check that critical
exports are non-empty and readable:

```bash
find "$BACKUP_ROOT" -type f -size 0 -print
find "$BACKUP_ROOT" -type l ! -exec test -e {} \; -print
```

A Time Machine volume is not required. The restore source can be an ordinary
external or network-mounted volume, but it must be readable, selected
explicitly, and independently verified. A single copy is still a single point
of failure.

## 4. Review repository condition before restoring

A repository report should identify:

```text
clean and remote-backed       re-clone
dirty with a remote           preserve patch/uncommitted files, then re-clone
NO-REMOTE                     copy the complete repository as irreplaceable data
ahead of remote               preserve commits/bundle, then re-clone
```

For a remote-backed repository:

```bash
printf 'Reviewed repository URL: '
IFS= read -r restore_remote
printf 'New destination directory in your selected developer layout: '
IFS= read -r restore_project
if [[ -n "$restore_remote" && "$restore_remote" != -* && "$restore_project" == "$HOME/"* \
      && ! -e "$restore_project" && ! -L "$restore_project" ]]; then
  git clone -- "$restore_remote" "$restore_project"
else
  printf 'Supply a URL and a new destination; nothing cloned\n' >&2
fi
```

Do not copy its old `node_modules`, virtual environment, caches, or build
output. Reinstall from lockfiles after cloning.

For a dirty repository backup, inspect before applying anything:

```bash
git -C "$BACKUP_ROOT/<repository>" status --short --branch
git -C "$BACKUP_ROOT/<repository>" diff --stat
git -C "$BACKUP_ROOT/<repository>" diff > "$HOME/.local/state/development-setup/<repository>.working-tree.patch"
```

For `NO-REMOTE`, copy the whole directory to an isolated recovery location,
inspect it, create a private remote, and only then move it into the selected developer
layout.

## 5. Restore project dependencies from declarations

For Node projects:

```bash
cd "$restore_project"  # The successful clone destination from Step 4.
fnm use --install-if-missing
```

Then choose from evidence:

```bash
pnpm install --frozen-lockfile   # pnpm-lock.yaml
npm ci                           # package-lock.json
```

Do not create a new lockfile merely to make installation start. Resolve a
missing or conflicting manager declaration first.

For Python projects:

```bash
cd "$restore_project"  # The successful clone destination from Step 4.
uv sync --locked
```

Do not restore `.venv`; native wheels and interpreter paths can differ across
machines.

## 6. Restore database dumps, not runtime storage

Start only the selected local service from [container setup](../databases/containers.md).
Use a separate database or disposable container for the first restore. Follow
[PostgreSQL backup and restore](../databases/operations.md#3-back-up-and-rehearse-a-restore)
for its matching tools, ownership checks and fresh target. Redis and MongoDB
rehearsals are in [container recovery](../databases/containers.md#8-back-up-before-destructive-work).

Identify the dump format and server version before importing. Stop if the
backup's schema, roles or format are unknown. A SQL dump can execute commands;
review its source and restore into an isolated environment first. Do not import
it directly into an existing application's database.

Expected result: the restored target passes its data and application checks
while the original remains unchanged. Keep both until a separate cutover is
approved. Never replace Docker or OrbStack VM storage from another Mac.

## 7. Preview document restore

1. Create a separate private recovery directory in this terminal:

   ```bash
   umask 077
   restore_dir="$(mktemp -d "$HOME/Restore-review.XXXXXX")"
   mkdir "$restore_dir/Documents"
   printf 'Recovery target: %s\n' "$restore_dir"
   ```

   Expected result: a new empty directory. Keep its printed path for recovery.

2. Preview the selected transfer:

   ```bash
   rsync -avhn "$BACKUP_ROOT/Documents/" "$restore_dir/Documents/"
   ```

   Expected result: only the intended files and size. Review unexpected hidden
   files and links before copying.

3. Copy into that same separate destination:

   ```bash
   rsync -avh "$BACKUP_ROOT/Documents/" "$restore_dir/Documents/"
   ```

   Expected result: exit status 0. A failure leaves a partial restore; inspect it
   before retrying. Existing `~/Documents` files remain unchanged.

4. Compare and open sample files:

   ```bash
   diff -qr "$BACKUP_ROOT/Documents" "$restore_dir/Documents"
   open "$restore_dir/Documents"
   ```

   Expected result: no unexplained content differences and readable files.
   This comparison does not verify all macOS metadata. Use the application's
   supported restore method when extended attributes or libraries matter.

After verification, choose each final destination and preserve any colliding
file before moving a restored copy through Finder. Keep the source backup.
Repeat with explicit pairs for Pictures or other selected folders; never aim
rsync at the complete home directory.

## 8. Restore application data through supported imports

Preferred restore routes:

| Application data | Restore method |
|---|---|
| 1Password | Sign into the account; verify vaults and keys through the service |
| VS Code | Choose Settings Sync restore or import a reviewed profile |
| Raycast | Import a reviewed encrypted `.rayconfig` |
| Browsers | Sign into the intended profile or import bookmarks only |
| SSH | Follow the selected [authentication owner](../security/README.md); use its recovery procedure rather than copying keys indiscriminately |
| Git hosting | Authenticate provider CLIs again; do not copy token stores |

Avoid copying application support directories when a supported export/import
exists. Never restore the macOS Keychain database or privacy database from
another Mac.

## 9. Deliberately exclude stale state

Do not bulk restore:

```text
node_modules/
.venv/ or virtualenvs
Homebrew Cellar or Caskroom
Docker/OrbStack VM storage
~/Library/Caches
browser cookies/session databases
macOS Keychain databases
macOS privacy-permission databases (often called TCC databases)
old shell framework caches
AI client authentication files
```

Regenerate local HTTPS certificates and development CAs on the new Mac.

## 10. Write a restore report

Create `~/.local/state/development-setup/restore-report.md` containing:

- backup volume and backup-root paths;
- checksum result or the absence of a manifest;
- every restored source/destination pair;
- repositories cloned, patched, or recovered as `NO-REMOTE`;
- database dump filenames and verification results;
- application imports completed manually;
- intentionally skipped data;
- unresolved collisions or follow-up work.

Set permissions:

```bash
chmod 600 "$HOME/.local/state/development-setup/restore-report.md"
```

## Rollback

Keep restored files in distinct, reviewed destinations until verification.
When a restore must be undone, move its exact targets to a dated recovery
archive instead of deleting them. Re-cloned repositories can be removed only
after confirming they contain no new local changes.

## Verification and next steps

Open a sample of the restored files and compare them with the reviewed restore
list. Check each restored repository's status, run the selected database restore
checks and confirm that application imports open correctly. Record failures and
skipped items in the private restore report before returning to any calling
assisted module.

## Troubleshooting

| Symptom | Next action |
|---|---|
| A checksum fails | Stop before restoring that file and investigate the backup source; preserve the backup and existing destination |
| The backup volume disappears | Reconnect it and repeat the volume and backup-root checks in Step 2 |
| A destination already exists | Preserve both copies and compare them before choosing a destination |
| An application cannot import its export | Retain the export and use that application's supported import and recovery procedure |
