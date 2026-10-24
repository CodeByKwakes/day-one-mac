# Verify and back up the finished setup

Finish the manual route with independent recovery evidence and a real project
check. A Brewfile or Git repository describes configuration; neither backs up
databases, untracked project files, credentials or application accounts.

## 1. Record the selected packages

If `~/Brewfile` is absent, run:

```bash
brew bundle dump --file="$HOME/Brewfile"
```

Expected result: a new Brewfile lists Homebrew's installed state. If the file
already exists, review it in your editor; do not overwrite comments or intentional
selections with a forced dump. Keep only the desired packages.

## 2. Check the Brewfile

```bash
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

Expected result: selected dependencies are satisfied, or missing items are named.
The check does not restore application data or account sessions.

## 3. Protect configuration through its owner

For user-owned files, include the Brewfile and reviewed shell/editor/Git settings
in your encrypted backup. For chezmoi, follow its
[source protection and recovery](shell/chezmoi.md) steps. Inspect adopted files
for credentials before committing, even to a private repository.

Expected result: a recovery copy exists independently of this Mac.

## 4. Test a sample restore

Restore a harmless sample into a new temporary folder using the backup tool's
restore workflow. Open it and compare it with the expected content.

Expected result: the restored file is readable and correct. Do not overwrite the
only working copy as a test. For databases, use the
[database restore procedure](databases/operations.md) and an isolated target.

## 5. Verify a real project

Open one authorised repository in the selected editor. Follow its README to
install its pinned dependencies and run its test or development command.

Expected result: the selected language, package manager, Git access and editor
work together. Record failures and use the owning task's troubleshooting section.

## 6. Complete the acceptance record

Use [shared verification](../../shared/verification.md) to record selected and
intentionally unselected controls, protection status and recovery evidence.

Expected result: every selected check has a result and an owner; unknown results
remain unknown. The manual route creates no automated completion marker.

## Restore after a problem

1. Identify the file or data class that failed and preserve its current state.
2. Locate the verified recovery copy and inspect it before replacement.
3. Restore only that item through its owner, keeping unrelated changes.
4. Repeat the task's verification and the real project check.

Expected result: the intended capability works and no unrelated configuration
was replaced. Credential revocation, database restore and application sign-in
are separate operations; use the responsible service's recovery process.

Next: [routine maintenance](maintenance.md) or an optional task in the
[manual index](README.md).
