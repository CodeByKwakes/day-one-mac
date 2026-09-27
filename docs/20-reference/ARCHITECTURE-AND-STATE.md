# Runtime architecture and state contract

This reference is for contributors and operators. For first-time setup, use
[Start here](../START-HERE.md); for terminology, use the [glossary](GLOSSARY.md).

## Execution boundaries

| Component | Owns | Must not do |
|---|---|---|
| `scripts/day-one-mac` | Resolve the active runtime and dispatch commands | Implement phase behavior |
| `bootstrap-day-one-mac.sh` | Collect, review, and save wizard choices | Silently install optional modules |
| `setup.sh` | Parse options, load selections, enforce gates, record completion | Copy phase bodies into tests |
| `scripts/phases/01-*.sh` through `08-*.sh` | Phase-specific configuration and verification | Run automatically when sourced |
| `scripts/lib/` | Shared state, locking, deadlines, paths, ownership, and packaging | Claim ownership of pre-existing external apps |
| `verify.sh` | Installed-runtime integrity and syntax checks | Require contributor dependencies or run setup |
| `validate.sh` and `scripts/tests/` | Repository structure and regression checks | Ship as an end-user setup dependency |

Phase modules run in the runner's shell, with its saved selections and helper
functions. Sourcing `setup.sh` defines this context without starting setup.
This is an incremental separation, not a fully isolated dependency-injection
design: shared variables still form an internal API. Keep those dependencies
explicit when moving functions between modules.

## Selection contract

Saved scalar files include `track`, `stack`, `auth-mode`, `preset`,
`primary-ide`, Git identity, and dotfiles choices. Older installations without a
preset retain `recommended-productivity`. The explicit `core` preset skips
Raycast, Warp, the Nerd Font, and VS Code; it does not uninstall them.

Authentication independently selects whether 1Password and its CLI are needed.
The `primary-ide` option controls Git and chezmoi integration, not the desktop
application catalogue. Core uses `other` so it does not introduce an editor
dependency. Optional modules remain separate and may have their own application
requirements.

## Completion and migration

A required phase marker is a SHA-256 fingerprint, not a claim that the machine
can never drift. Its inputs include a contract version, implementation hashes,
relevant selections, and the required application catalogue where applicable.
The runner and shared libraries affect all phase hashes. A phase module affects
its own hash. Phases 4 and 5 also include their security-module helpers; Phase 8
includes every phase and the runtime verifier, so changes to setup behavior
invalidate the final machine verification too.

Documentation wording and optional catalogue entries do not invalidate required
phases. Optional advanced-module tracking is separate and can still fingerprint
its guides. The Installation Centre includes selections and implementation
evidence, then checks that the selected software is actually available.

Migrating from the old fingerprint format makes existing required-phase markers
stale once. No application or saved choice is removed. Review `--status`, then
resume the wizard and approve the phases it needs to run. Do not manually edit
markers or use `--reset-progress` merely to update the runtime.

## Atomic writes and concurrent operations

An atomic write puts complete content into a private temporary file in the same
directory, then renames it over the destination. Readers see the old or the new
value, not a half-written value. This is used for scalar choices, completion
markers, and runtime locator/history records. Non-regular destinations and
symlinks anywhere in the state path are rejected before directories or temporary
files are created. Module journals use the same parent-path checks before
creating a run or copying ownership records. The fixed macOS aliases `/tmp`,
`/var`, and `/etc` are allowed only when they point to their standard `private/`
targets; custom symlinked paths are not.

If an overridden state path is rejected, inspect the named link and use the
intended directory's physical path (the path printed by `pwd -P` inside that
directory). Preserve existing state; do not delete it or reset progress to clear
this error. These checks and the operation lock protect against pre-existing
redirects and competing Day One writers, not a hostile process running as the
same user and replacing directories during a write.

A directory lock outside the state tree serializes the required setup, wizard,
runtime installation/switch/removal, macOS preferences, application ownership
report, recorded rollback, cleanup, and finalisation. Nested commands inherit
the same operation lock. Other optional tools retain their own existing state
handling; this is not yet a transactional database for every project command.

Contention exits with status 75 rather than guessing which writer should win.
The supervisor releases its lock after normal success or failure. A forced kill
or power loss can leave a stale lock. Before removing one, inspect the recorded
PID and confirm that both the supervisor and its child operation have stopped.
Never delete a live lock. The default location is
`~/.day-one-mac.operation.lock`; an overridden state root changes that prefix.

Atomic replacement protects individual files, not an entire multi-file
transaction, and does not guarantee disk durability through sudden power loss.
Ownership manifests and append-only logs retain their existing formats.

## Runtime ownership and switching

Both the local installer and release builder copy only files listed in
`config/runtime-files.txt`. Adding a runtime dependency requires updating that
manifest. Unlisted files, contributor agent instructions, tests, dependency directories,
and arbitrary local files are excluded. Manifest entries must be regular files
within the source, with no symlink parents or path traversal.

Each release lives in its own version directory and includes `SHA256SUMS`.
Existing versions with different contents are rejected. The activation helper
verifies the candidate before atomically replacing `current` with macOS
`mv -h`, which replaces a directory symlink instead of following it.
Verification requires the exact regular-file inventory in
`config/runtime-files.txt`, its necessary parent directories, and `SHA256SUMS`.
Additional files or directories, symlinks, special file types, missing files,
and incomplete or duplicate checksum entries are rejected. Runtime status,
explicit verification, activation, and rollback use the same check. An integrity
failure during activation leaves both `current` and `previous` unchanged.

The `previous` record stores activation history, not lexical version order.
Default rollback selects that previous activation; explicit `--version` remains
available. If activation was interrupted and history equals the active version,
choose a verified version explicitly. Runtime rollback does not undo machine
configuration or migrate state backward.

## Verification and trust

`day-one-mac verify` checks the installed runtime. Phase 8 separately checks the
machine, selected tools, authentication, and dotfiles protection. A linked Git
checkout has no release manifest, so verification reports that limitation.
`day-one-mac validate` runs the full suite only from a contributor checkout;
inside a standalone runtime it is a compatibility alias for `verify`.
The focused Warp bundle validator remains packaged because optional status
calls it; contributor-only suite runners do not.

Checksums detect changed bytes but cannot authenticate a publisher when both
the archive and checksum come from the same compromised source. New releases
request GitHub build attestations. The optional installer
`--require-attestation` gate verifies repository and workflow identity through
`gh` before extraction. Missing or failed attestations stop that installation.
Older releases may not have attestations; the default does not pretend otherwise.

Homebrew's installer is downloaded over HTTPS to a private state file, syntax
checked, hashed, and presented for approval before execution. The saved hash is
an audit record, not a pinned upstream trust root. Review the downloaded script
and the printed path; an upstream Homebrew install can still request administrator
privileges. See [runtime operations](PORTABLE-COMMAND.md).

## Contributor verification

Run `scripts/validate.sh` and `pnpm run lint` in the source checkout.
The suite uses isolated temporary homes; it must not install software on the
contributor's Mac. Behavioral tests source real phase modules and shared helpers.
The audit regressions cover package exclusion, corruption detection, locking,
atomic state, selection behavior, and fingerprint invalidation. Portable-command
fixtures cover activation, rollback history, linked mode, and argument rejection.

Keep documentation split by purpose: a short beginner tutorial in Start here,
task-oriented recovery in phase guides, command/state contracts in reference
pages, and contributor implementation detail here. Update all affected layers
when a user-visible choice or runtime contract changes.
