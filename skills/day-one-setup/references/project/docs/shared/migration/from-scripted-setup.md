# Migrate from scripted setup

Keep existing software, settings and private recovery records when moving to
the AI-assisted or manual routes. The new command does not resume the old setup
wizard or interpret its completion markers as current machine health.

## Before updating

1. Inspect the installed version and available runtime copies:

   ```bash
   day-one-mac --version
   day-one-mac runtime-status
   ```

   Expected result: the active version and integrity status. Retain the last
   working runtime until the new version is accepted.

2. Back up important data and preserve `~/.day-one-mac`, including ownership
   manifests, originals, selected operations and recovery evidence.

   Expected result: a readable independent backup. Do not delete state to make
   a check appear current. State may contain private paths; do not publish it.

3. Read the release notes and follow the [runtime update procedure](../tools/runtime.md).

   Expected result: the selected version is active and passes integrity checks.
   This source change is not evidence that a public release has been published.

## Choose the new journey

1. Open [Start here](../../START-HERE.md) and choose AI-assisted or manual setup.

   Expected result: a selected route that inspects existing capabilities before
   proposing changes. Already configured software is reused when appropriate.

2. Verify each selected capability with its owning manual guide.

   Expected result: fresh evidence, separate from historical phase markers.
   Retained utilities use actual dependencies rather than requiring Phase 8.

3. Use the [utility reference](../reference/tools.md) for bounded operations.

   Expected result: a preview and explicit selection. The `optional` and
   `advanced` aliases accept explicit tool operations only; they do not run a wizard.

## Retired commands and recovery

`setup`, `install`, `finalize`, `remove`, `clean`, `reset-development`,
`prepare-existing`, `prepare-reset` and `ssh-pin` return a retirement notice.
Old setup entry points also stop without changes. Use the manual authentication,
backup and lifecycle guides for the underlying tasks.

`rollback` remains a preview-first tool for recorded owned changes. Read its
[recovery contract](../tools/rollback.md) before applying. `rollback-runtime`
selects an earlier installed runtime and does not undo application changes.
Never run the old runner merely because it is available in a retained release.

If the new runtime fails, preview `day-one-mac rollback-runtime`, choose the
previous version using its help, and verify integrity again. Preserve the
failed version's evidence for diagnosis. An isolated upgrade/rollback test does
not prove that every hardware permission or external account works on your Mac.
