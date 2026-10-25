# Maintain the environment

Update one ownership layer at a time, with a tested backup and a working project
check. Use Homebrew only for packages it owns; Company Portal, App Store and
manual installations keep their own update channels.

## 1. Inspect Homebrew metadata

Run `brew update`.

Expected result: current package metadata, or a specific network error to resolve.
This does not upgrade all installed software.

## 2. Review available changes

Run `brew outdated`.

Expected result: a list of upgrade candidates, possibly empty. Review release
notes and project constraints before selecting a package.

## 3. Upgrade a selected package

Run `brew upgrade PACKAGE`, replacing `PACKAGE` with the reviewed formula or
cask. Use `--formula` or `--cask` when the token is ambiguous.

Expected result: that selected package upgrades. Recheck its version and one
real workflow before updating another dependency layer.

## 4. Review cleanup separately

Run `brew cleanup --dry-run`.

Expected result: proposed cache/old-version removals only. Run `brew cleanup`
only after reviewing the list and confirming those retained versions are no
longer needed. Cleanup is not a backup or a database reset.

## Useful inspection combinations

```bash
brew update && brew outdated
```

The second command runs only if metadata refresh succeeds. To inspect installed
packages by ownership class, run `brew list --formula` and `brew list --cask`
separately. Use `brew info PACKAGE` to inspect a specific item and
`brew services list` to inspect Homebrew services. Do not start or stop a service
until you have identified its data and owner.

## Troubleshooting and recovery

Use `brew doctor` to investigate a package-manager problem and act on the exact
reported path. A previous version may no longer be available upstream; confirm
recovery before an important upgrade. Keep project lockfiles, runtime pins and
database backups independent of package-manager cleanup.

For shell/editor problems, restore the reviewed configuration through its owner.
For service problems, use the [database operations guide](databases/operations.md).

## 5. Check project runtimes

1. Open one active Node project and inspect its version declarations:

   ```bash
   pwd
   git status --short --branch
   fnm current
   node --version
   npm --version
   pnpm --version
   ```

   Expected result: the runtime and package manager match that project's
   `.node-version`, `.nvmrc`, `engines` or `packageManager` policy. Resolve a
   mismatch before changing dependencies. Follow [language setup](languages.md)
   to install a selected runtime. Keep its previous working version until tests
   pass; changing the default Node version is a separate decision.

2. Restore Node dependencies using the existing lockfile and its owner:

   ```bash
   # Choose one, according to the repository's declared package manager.
   pnpm install --frozen-lockfile
   npm ci
   ```

   Expected result: installation succeeds without rewriting the lockfile.
   Run the project's documented build and tests. A dependency install can run
   repository scripts; review and trust the project first.

3. For a selected Python project, open its directory and inspect before syncing:

   ```bash
   uv --version
   uv python list
   git status --short --branch
   uv sync --locked
   uv run python --version
   ```

   Expected result: the declared interpreter and locked dependencies are
   available. Run that project's documented tests; `pytest` is only appropriate
   when the project declares it. Keep uv with its chosen installer rather than
   adding a second copy through pip.

## 6. Review configuration drift

Follow the [Brewfile task](apps/brewfile.md) to compare desired packages with
installed software. It includes backups and recovery for application and
extension changes. If chezmoi owns your configuration, inspect it:

```bash
chezmoi doctor
chezmoi status
chezmoi diff
chezmoi verify
```

Expected result: no unexplained differences. Edit through the selected owner,
preview, then apply only the intended targets using [chezmoi workflows](shell/chezmoi.md).
For user-owned files, compare the active file against its backup and edit it
directly. Preserve any local changes before replacing a file.

Commit only reviewed, non-secret changes when using a private Git source.
A local-only source needs an encrypted backup after each accepted change.
Neither approach should include account tokens or client session history.

## 7. Review repositories before system work

Open each active repository and run:

```bash
git status --short --branch
git remote --verbose
git branch --verbose --verbose
git worktree list
```

Expected result: every uncommitted change, local-only branch and additional
worktree is accounted for in the backup plan. Inspect remote URLs privately;
legacy URLs can contain credentials. A clean worktree alone does not prove
that all commits exist on a remote. Preserve repositories without remotes as
irreplaceable data. Never bulk-reset repositories during maintenance.

## 8. Verify selected services and applications

Use [database operations](databases/operations.md) and
[container backup rehearsals](databases/containers.md#8-back-up-before-destructive-work)
before an image or schema change. Verify a harmless query, expected data and
application access after the change. Avoid global container-prune commands.

For AI, follow [client and MCP maintenance](ai/maintenance.md). Check account
and permissions independently of the executable version. For VS Code, verify
the active profile, extensions and [Settings Sync](editors/vscode.md); export a
profile before a major change. Sync is not a complete workstation backup.

Purge is never invoked by a Day One Mac script. Its Full Disk Access permission
and every cleanup approval remain manual decisions.

For optional GUI cleanup, inspect the application's proposed paths and export
its settings first. Purge is a third-party option, available as
`jithin-sabu/tap/purge`; review that tap before selecting it. Leave scheduled cleaning disabled. Preserve removals in Trash and leave privileged helpers
disabled unless a specific approved removal requires them. Use one update
owner for the app, and verify normal workflows before emptying Trash.

## 9. Record a maintenance cadence

| When | Inspect | Expected result |
|---|---|---|
| Weekly | Security updates, active repositories and services | Known pending updates and backed-up local work |
| Monthly | Package drift, configuration changes and client access | Reviewed changes with a working project check |
| Quarterly | Unused apps/extensions, permissions and recovery access | Only intended access remains |
| Before a major macOS upgrade | Independent backup, database restores, application compatibility | A tested recovery route |
| After an upgrade | Command Line Tools, Homebrew, shell, editor and selected engine | Real project build and service checks pass |

These intervals are recommendations. Follow device policy when it sets a
schedule. A reminder can request inspection; it should not silently upgrade or
remove software.

## 10. Rehearse a manual rebuild

1. Record the selected tools, configuration owners, project URLs and backup
   locations in a private inventory. Keep credentials in their approved store.
   Expected result: another machine can be set up without reconstructing choices
   from memory.
2. On a separate approved test Mac, follow the [manual route](README.md),
   including the optional AI choice if wanted. Expected result: the same
   capabilities are configured without relying on old completion records.
3. Restore a sample into separate targets using [project recovery](preparation/restore-projects.md).
   Expected result: verified documents and application data while source backups
   remain intact.
4. Complete [shared verification](../../shared/verification.md).
   Expected result: actual account, project, service and backup checks are
   recorded, including anything still untested.

A command preview on the existing Mac does not establish that a rebuild works.
Keep the original system until recovery and project acceptance checks pass.
