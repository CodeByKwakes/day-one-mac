[← Advanced 18](18-hosting-identities-azure-and-worktrees.md) · **🤖 ⚙️ Advanced 19** · [Advanced 20 →](20-restore-and-migrate.md)

# Advanced 19 - macOS, GUI applications, and local HTTPS

**Time:** 45-120 minutes · **Required:** no · **Prerequisite:** stable required setup

## Outcome

macOS preferences and application permissions are changed deliberately after
their current values are recorded. Optional productivity applications are
configured without importing unknown previous state, and local HTTPS uses a new
machine-local development CA that is never committed.

The ordinary Finder, Dock, keyboard, trackpad, menu-bar, and screenshot choices
now belong to the early [macOS Settings Wizard](../MACOS-SETTINGS.md). Run that
wizard after Phase 1 on a personal Mac if you want those changes. Managed Macs
skip the checkpoint: IT owns preferences, and local apply/resume/restore is
blocked. Ask the policy owner to make approved changes.
Advanced 19 remains optional and covers broader preference design, application
permissions, login items, browser roles, and local HTTPS.

## Executable selected-preference route

Module 19 adds explicit plan/apply/check/resume operations for a bounded subset
of the existing wizard's scalar preferences. A scalar is one Boolean, number
or string, rather than an entire settings dictionary. Only selected keys are
written; the runner does not restart Finder, Dock or other applications.

Create `preferences.tsv` in an editor, using two tab-separated fields:

```text
setting	finder-path
setting	dock-size
```

These examples show the Finder path bar and set the Dock size to 44. Preview
the exact domain, key, type and value before confirming:

```bash
day-one-mac advanced --module 19 --plan --manifest ./preferences.tsv
day-one-mac advanced --module 19 --apply --manifest ./preferences.tsv
day-one-mac advanced --module 19 --check
```

Apply requires current Phase 8 on a personal Mac; managed apply/resume is
refused. Plan/check remain inspection operations. Supported IDs are:

```text
finder-hidden, finder-extensions, finder-path, finder-status, finder-list
dock-size, dock-right, dock-magnification-off, dock-autohide, dock-scale-effect
dock-minimize-into-app, dock-no-launch-animation, dock-show-indicators, dock-no-recents
keyboard-fast, autocorrect-off
```

Use one `setting` row per ID, not a comma-separated list. Manual GUI settings
and `screenshot-location` are excluded; the latter also creates a directory.
Security controls, permissions, login items and certificate trust remain
outside this runner.

Before the first write, private records preserve every selected key's original type and value,
including whether the key was absent. Values are Base64-encoded to preserve
empty strings and line breaks; Base64 is encoding, **not encryption**. The
runner prints the record directory. Keep these records with your private setup
state, not in a public repository.

If a write fails, inspect the run journal, fix the cause and retry:

```bash
day-one-mac advanced --module 19 --resume
day-one-mac advanced --module 19 --check
```

Already-correct values are not rewritten. A pending key can resume only when
it still has its recorded original or desired value. An applied key changed
later in System Settings causes a conflict; neither apply nor resume forces it
back. Do not change these preferences concurrently with a run.

If the preference domain cannot be exported, the runner stops instead of
assuming its keys are absent. Open the owning application or inspect the domain
manually before retrying. Check verifies typed stored values, not their visual
effect; reopen the relevant UI yourself when ready.

This route maintains separate per-key records from the early wizard. The
legacy `macos-settings --restore` command does **not** restore Module 19's
records and may change keys that Module 19 subsequently flags as conflicts.
There is no automatic rollback, force override or record reset in this route.
Intentional reversals require separately reviewing the exact original keys and
their typed values; do not delete records simply to silence a conflict.

## Shared manual actions

Use [manual macOS settings](../../manual/macos.md) for application permissions,
login items and GUI preferences. Use [local HTTPS](../../manual/local-https.md)
for certificate trust. These actions are outside the selected-scalar runner.
Return here after verifying the actual UI or local HTTPS workflow.

## Verify and troubleshoot

Run the module check after applying the selected manifest. Expected result:
typed stored values match the reviewed operation. Reopen the affected UI and
verify its visible effect separately. A check of stored values does not prove
that every OS build supports a private preference key.

For a conflict, preserve the current value and inspect the original and desired
values in the private record. Do not delete records, force a value or use the
legacy wizard's restore as a substitute for reviewing this operation.

## Recovery

The runner has no automatic per-module rollback. Restore only a deliberately
reviewed original key with its original type, or remove that exact key if it was
originally absent. Keep the record until the visible result is verified. Managed
preferences and certificate trust remain owned by their approved processes.
