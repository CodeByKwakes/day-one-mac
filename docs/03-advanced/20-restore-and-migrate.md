[← Advanced 19](19-macos-gui-and-local-https.md) · **🤖 ⚙️ Advanced 20** · [Advanced 21 →](21-audit-maintenance-and-rebuild.md)

# Advanced 20 — Restore and migrate selected data

**Time:** depends on data · **Required:** no · **Prerequisite:** required Phase 8 and a verified backup

## Outcome

Selected documents, repositories, database dumps, and application exports are
restored from an explicitly chosen mounted volume. The clean environment keeps
its new configuration; caches, package directories, private system databases,
and an old home directory are not copied wholesale.

Choose **no restore** when the Mac is intentionally blank. Skipping this module
is a complete and valid outcome.

## Step 20.1 — Make the restore decision explicit

Before connecting a disk, decide which statement is true:

```text
A. No restore — this machine starts without previous user data.
B. Selective restore — a reviewed backup contains specific files to recover.
```

Do not browse an unknown disk and gradually copy whatever looks familiar. Write
a restore list first: documents, repositories, database dumps, application
exports, and any exceptional local-only files.

## Step 20.2 — Select and validate the mounted volume

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
BACKUP_ROOT="$BACKUP_VOLUME/<reviewed-backup-directory>"
[[ -d "$BACKUP_ROOT" ]] || {
  printf 'Backup root not found: %s\n' "$BACKUP_ROOT" >&2
  return 1 2>/dev/null || exit 1
}
find "$BACKUP_ROOT" -maxdepth 2 -type f -print | sed -n '1,120p'
```

Do not use a guessed `/Volumes/<name>` in multiple commands. Keep the validated
variable in the current terminal and revalidate it after sleep, logout, or
reconnection.

## Step 20.3 — Verify manifests and checksums

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

## Step 20.4 — Review repository condition before restoring

A repository report should identify:

```text
clean and remote-backed       re-clone
dirty with a remote           preserve patch/uncommitted files, then re-clone
NO-REMOTE                     copy the complete repository as irreplaceable data
ahead of remote               preserve commits/bundle, then re-clone
```

For a remote-backed repository:

```bash
ghq get <reviewed-remote-url>
```

Do not copy its old `node_modules`, virtual environment, caches, or build
output. Reinstall from lockfiles after cloning.

For a dirty repository backup, inspect before applying anything:

```bash
git -C "$BACKUP_ROOT/<repository>" status --short --branch
git -C "$BACKUP_ROOT/<repository>" diff --stat
git -C "$BACKUP_ROOT/<repository>" diff > "$HOME/.day-one-mac/<repository>.working-tree.patch"
```

For `NO-REMOTE`, copy the whole directory to an isolated recovery location,
inspect it, create a private remote, and only then move it into the normal ghq
layout.

## Step 20.5 — Restore project dependencies from declarations

For Node projects:

```bash
cd <re-cloned-project>
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
cd <re-cloned-project>
uv sync --locked
```

Do not restore `.venv`; native wheels and interpreter paths can differ across
machines.

## Step 20.6 — Restore database dumps, not runtime storage

Start only the database selected in Optional 09, then restore a logical dump.

PostgreSQL example:

```bash
docker start dev-postgres
docker exec -i dev-postgres psql -U postgres -d postgres \
  < "$BACKUP_ROOT/databases/postgres.sql"
```

List tables or run an application smoke test after import. Do not replace the
OrbStack or Docker VM data directory with a copy from another version or
architecture. Named volume data is not portable backup by itself.

## Step 20.7 — Preview document restore

Always run a dry transfer first:

```bash
rsync -avhn "$BACKUP_ROOT/Documents/" "$HOME/Documents/"
```

Review collisions, unexpected hidden files, and total size. Then run the same
command without `n`:

```bash
rsync -avh "$BACKUP_ROOT/Documents/" "$HOME/Documents/"
```

Repeat with explicit source/destination pairs for Pictures or other intended
folders. Do not aim rsync at `$HOME`.

## Step 20.8 — Restore application data through supported imports

Preferred restore routes:

| Application data | Restore method |
|---|---|
| 1Password | Sign into the account; verify vaults and keys through the service |
| VS Code | Choose Settings Sync restore or import a reviewed profile |
| Raycast | Import a reviewed encrypted `.rayconfig` |
| Browsers | Sign into the intended profile or import bookmarks only |
| SSH | Use the 1Password agent; do not restore plaintext private keys by default |
| Git hosting | Authenticate provider CLIs again; do not copy token stores |

Avoid copying application support directories when a supported export/import
exists. Never restore the macOS Keychain database or privacy database from
another Mac.

## Step 20.9 — Deliberately exclude stale state

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

## Step 20.10 — Write a restore report

Create `~/.day-one-mac/restore-report.md` containing:

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
chmod 600 "$HOME/.day-one-mac/restore-report.md"
```

## Rollback

Keep restored files in distinct, reviewed destinations until verification.
When a restore must be undone, move its exact targets to a dated recovery
archive instead of deleting them. Re-cloned repositories can be removed only
after confirming they contain no new local changes.

## Advanced 20 completion checklist 🚦

- [ ] Restore/no-restore was chosen explicitly.
- [ ] The volume and backup root were validated under `/Volumes`.
- [ ] Checksums passed or their absence is documented.
- [ ] Remote-backed repositories were re-cloned through ghq.
- [ ] Dirty, ahead, and `NO-REMOTE` repositories were handled individually.
- [ ] Dependencies came from lockfiles; no package/cache directories were copied.
- [ ] Databases came from logical dumps, not container VM storage.
- [ ] Document transfers were previewed before execution.
- [ ] Application data used supported import/sign-in routes.
- [ ] The private restore report records every material action.

```bash
day-one-mac advanced --complete 20
```

---

[← Advanced 19](19-macos-gui-and-local-https.md) · [Continue to Advanced 21 →](21-audit-maintenance-and-rebuild.md)
