[← Choose a route](00-existing-mac-decision.md) · [Next: backup readiness →](02-backup-readiness.md)

# Step 1 — Create and review the safety report

Use this step before **Route A or Route B**.

The technical script name is `preflight-audit.sh`. Here, **audit** means
“inspect and report.” The script creates a private list of the Mac's current
state. It does not clean, reset, update, or back up the Mac.

## Run the guided version

```bash
cd "$(day-one-mac root)/scripts"
./prepare-existing-mac.sh --guided
```

Choose Route A, Route B, or Not sure, then choose **Step 1 — create the safety
report**. The report is saved by default in a new private folder:

```text
~/.day-one-mac/preflight/Safety Report - 2026-09-12 23-00-00/
```

The report shows the creation time inside its summary as a familiar local value,
for example `2026-09-12 23:00:00 BST`. The folder uses dashes in the time so it
is safe to copy between filesystems.

When collection finishes, the script gives you three choices:

1. open `SUMMARY.md` in the Mac's default application;
2. display `SUMMARY.md` directly in Terminal; or
3. finish without opening it and review it later.

The exact report folder remains visible whichever option you choose. Start
with `SUMMARY.md`. When you close the report review, the Stage 0 dashboard
returns automatically and marks Step 1 with `✓`.

## Reset and repeat Step 1 safely

You do not normally need to reset Step 1 just because Step 2 is still `○`.
First read the dashboard's **Last result** and **Saved paths** sections; Step 2
usually needs the external drive to be unlocked or its report copy to pass.

To deliberately create a fresh report, select **Reset and re-run Step 1 —
keeps old reports and backup files** from the Route A or Route B dashboard and
confirm once. This action:

- keeps every existing report folder and all external-drive data;
- archives the old Step 1 and dependent progress markers in
  `~/.day-one-mac/reset-history`;
- keeps the selected external backup-folder path; and
- immediately creates and records a new safety report.

Because Step 2 depends on the current report, run Step 2 again afterward so
the new report is copied and verified on the external drive.

`SUMMARY.md` is the report's home page. It contains the most important counts,
a readiness warning, an ordered review checklist, and clickable relative links
to every supporting Markdown, TSV, Brewfile, and checksum file that was created.

## What the report contains

- macOS version, processor type, storage, FileVault status, and account names;
- applications grouped as Homebrew, ordinary, user, macOS system, or embedded;
- installed Homebrew, Node, npm, pnpm, Python, Docker, Git, hosting, chezmoi,
  and shell tools;
- Git repository branch, uncommitted-file count, remote address, upstream,
  ahead/behind state, and stash count;
- startup items, system extensions, Time Machine status, and local container
  details when Docker is running; and
- the presence and size of common development configuration locations.

The report does not copy configuration-file contents or reveal environment
variable values. It does not contact Git remotes. Repository ahead/behind
figures therefore use the last information previously fetched on this Mac.

## Review these files in order

1. `SUMMARY.md` — the linked overview, readiness checklist, and next actions.
2. `repositories.md` — fix every `DIRTY` or `NO-REMOTE` repository.
3. `applications.md` — decide which application data, licences, or settings
   need a separate export.
4. `packages.md` and `Brewfile.snapshot` — record software you may reinstall.
5. `containers.md` — identify databases or volumes that need an export.
6. `security-startup-backup.md` — review backup and background components.
7. `configuration-paths.md` — find settings that need an intentional archive.
8. `collection-status.tsv` — investigate every row marked `REVIEW`.

`applications.tsv` and `repositories.tsv` are spreadsheet-friendly versions
of the same information.

## How the report reaches the backup drive

Do not manually move the only report copy. In guided Step 2, Day One copies the
entire report folder into the selected encrypted external backup folder, checks
every recorded checksum, and reads `SUMMARY.md` back into a temporary local
file. The dashboard marks Step 2 complete only after those checks pass.

Technical users can also verify a copied report manually:

```bash
cd "/absolute/path/to/the/copied-report"
shasum -a 256 -c SHA256SUMS.txt
```

Replace the example path with the real report folder. Every line must end with
`OK`. If one fails, copy or create the report again.

> A checksum confirms that the report copied correctly. It does not prove that
> your projects, documents, databases, or credentials were backed up. Route B
> Step 3 creates that selected development snapshot.

## Optional technical controls

Most users can skip this section.

To write the report directly to a mounted external volume:

```bash
./prepare-existing-mac.sh --safety-report \
  --archive-root "/Volumes/Backup Drive/Day-One-Mac"
```

To search additional repository parent folders, run the underlying report
tool directly:

```bash
./preflight-audit.sh --guided \
  --repo-root "$HOME/Work" \
  --repo-root "/Volumes/Projects/Repositories"
```

Replace `Backup Drive` and other examples with real names shown in Finder. The
report refuses to write private information inside this Git repository.
Use [the encrypted backup-drive guide](ENCRYPTED-BACKUP-DRIVE.md) and the
wizard's Step 2 first if you have not yet prepared that folder.

## Privacy warning

The report can contain usernames, local paths, application names, repository
remote addresses, and security status. Keep it private, never commit it to Git,
and delete it only after the transition and recovery period are complete.

---

[← Choose a route](00-existing-mac-decision.md) · [Next: backup readiness →](02-backup-readiness.md)
