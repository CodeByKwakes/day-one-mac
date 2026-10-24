[← Advanced 19](19-macos-gui-and-local-https.md) · **🤖 ⚙️ Advanced 20** · [Advanced 21 →](21-audit-maintenance-and-rebuild.md)

# Advanced 20 - Restore and migrate selected data

**Time:** depends on data · **Required:** no · **Prerequisite:** required Phase 8 and a verified backup

## Outcome

Selected documents, repositories, database dumps, and application exports are
restored from an explicitly chosen mounted volume. The clean environment keeps
its new configuration; caches, package directories, private system databases,
and an old home directory are not copied wholesale.

Choose **no restore** when the Mac is intentionally blank. Skipping this module
is a complete and valid outcome.

## Executable checksummed staging route

This route copies only explicitly listed regular files into a **new private
staging directory**, never into Documents, a repository or an application's
live data. Staging means preparing a separate copy for review before deciding
where it belongs. Node 22+ must be on PATH. Apply/resume requires Phase 8.

For an intentionally blank Mac, record the decision without selecting a disk:

```bash
umask 077
printf 'mode\tno-restore\n' > restore.tsv
day-one-mac advanced --module 20 --plan --manifest "$PWD/restore.tsv"
day-one-mac advanced --module 20 --apply --manifest "$PWD/restore.tsv"
day-one-mac advanced --module 20 --check
```

For selective staging, mount your reviewed backup under `/Volumes`, then use
one `source` row followed by `file` rows. Each file row contains its relative
source path, relative staging destination and trusted SHA-256 digest. The
following is a template; replace the path and digest before running it:

```bash
umask 077
printf 'source\t%s\nfile\t%s\t%s\t%s\n' \
  '/Volumes/Reviewed Backup/exports' \
  'documents/project-notes.txt' 'documents/project-notes.txt' \
  '<64-character-lowercase-SHA-256-from-your-reviewed-manifest>' > restore.tsv
day-one-mac advanced --module 20 --plan --manifest "$PWD/restore.tsv"
```

Use real tab separators (`printf` above creates them). Select individual files,
not directories or wildcards. Obtain digests from an independently reviewed
backup manifest; hashing a damaged file now does not prove it was backed up
correctly. A checksum detects byte changes, not authenticity or malware.
Keep the manifest private and outside public repositories.

The plan validates the mounted source, checks all selected hashes, shows byte
sizes and source/target pairs, and rejects duplicate or colliding targets.
It writes no state. Review the content for secrets yourself: path exclusions
are not a content scanner. If the plan is correct:

```bash
day-one-mac advanced --module 20 --apply --manifest "$PWD/restore.tsv"
day-one-mac advanced --module 20 --check
```

The printed staging location is beneath
`~/.day-one-mac/module-runs/20/RUN/staging/files/`. Open only files you trust;
the runner never executes, unpacks or imports their contents. Files are mode
`600` and staging directories `700`; original ownership, extended attributes,
ACLs and executable bits are intentionally not restored.

If a transfer is interrupted, keep the same backup mounted and run:

```bash
day-one-mac advanced --module 20 --resume
day-one-mac advanced --module 20 --check
```

Resume reuses the saved session, verifies existing staged files and copies
only missing ones. Changed sources, changed destinations, symlinks or a
different mounted-source identity stop the operation without overwriting data.
Partial temporary copies remain under `staging/incoming/`; they are not
promoted or reused. Insufficient space can therefore require separately
reviewed cleanup before retrying. A new apply creates a new session, preserving
the old one; it is not a force-overwrite command.

Hidden files, known credential containers, package/cache trees, directory
copies and live restores are excluded. Whole repositories, application state,
database imports, metadata-sensitive files and final placement require the
manual procedures below. Keep the backup mounted for `--check`; an unavailable
source is a verification failure, not successful migration. The dashboard
remains `partial`, including for an explicit no-restore decision, because it
does not attest completion of this guide.

## Complete the shared manual actions

Follow the linked task for the selected actions, verify them, then return here. Manual configuration has one owner; the module records evidence.

| Manual action | Guide |
|---|---|
| 1. Make the restore decision explicit | [Open task](../../manual/preparation/restore-projects.md#1-make-the-restore-decision-explicit) |
| 2. Select and validate the mounted volume | [Open task](../../manual/preparation/restore-projects.md#2-select-and-validate-the-mounted-volume) |
| 3. Verify manifests and checksums | [Open task](../../manual/preparation/restore-projects.md#3-verify-manifests-and-checksums) |
| 4. Review repository condition before restoring | [Open task](../../manual/preparation/restore-projects.md#4-review-repository-condition-before-restoring) |
| 5. Restore project dependencies from declarations | [Open task](../../manual/preparation/restore-projects.md#5-restore-project-dependencies-from-declarations) |
| 6. Restore database dumps, not runtime storage | [Open task](../../manual/preparation/restore-projects.md#6-restore-database-dumps-not-runtime-storage) |
| 7. Preview document restore | [Open task](../../manual/preparation/restore-projects.md#7-preview-document-restore) |
| 8. Restore application data through supported imports | [Open task](../../manual/preparation/restore-projects.md#8-restore-application-data-through-supported-imports) |
| 9. Deliberately exclude stale state | [Open task](../../manual/preparation/restore-projects.md#9-deliberately-exclude-stale-state) |
| 10. Write a restore report | [Open task](../../manual/preparation/restore-projects.md#10-write-a-restore-report) |

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
