# Optional module execution reference

Modules **09 (databases)** and **13 (CLI formulae)** support a shared execution
interface. Other optional modules and Advanced 15–22 remain guided procedures.
An executable module automates its stated scope, not every action in its guide:
Module 13 does not edit shell configuration or a Brewfile.

For a first run, follow the [optional setup walkthrough](../02-optional/README.md#plan-apply-and-check-an-executable-module).

## Commands and prerequisites

| Operation | Behaviour |
|---|---|
| `day-one-mac optional --list` | Read the capability registry; this is not installation status. |
| `--module ID --plan` | Inspect available evidence and print proposed operations. No state, locks, installations, service starts or configuration writes. |
| `--module ID --apply` | Confirm, save the selection and apply missing work. Requires recorded Phase 8 completion. |
| `--module ID --check` | Inspect actual installation/configuration/health. Return nonzero when verification fails; never save completion. |
| `--module ID --resume` | Reconcile the last saved selection with current reality. Requires Phase 8 and confirmation; does not accept a replacement selection. |

Supply `--services postgres,redis,mongodb` for 09 or `--packages eza,fzf` for 13.
Omitting the selection uses the saved one; absence of saved choices is an error.
`--yes` skips the ordinary apply/resume confirmation only. It does not approve
macOS permissions or another application's onboarding.

Planning is allowed before Phase 8. If Docker cannot be inspected, the database
plan labels resource operations as conditional: it is not claiming that every
resource is absent. If Homebrew is missing, the CLI plan is also conditional.
An installed but failing Homebrew inventory check is an error, not an empty
inventory.

Apply always rechecks live state; a printed plan is not a frozen transaction.
Resolve conflicting existing containers yourself after reviewing their data.
The runner never replaces them automatically. Database verification checks
health plus the configured image, localhost port binding, named volume and
network. It does not prove credentials, application queries or backup quality.

## Compatibility

Existing `databases`, `cli-tools`, `optional --guided`, `optional --status`,
and `advanced` commands retain their roles. The new module interface adds
strict action validation and a Phase 8 gate for apply/resume.

The direct CLI installer keeps its existing Homebrew prerequisite for
compatibility; it does not gain a Phase 8 gate. Both direct installers share the
new locking, saved selections and run records. CLI users can resume directly
with `day-one-mac cli-tools --saved`.

Database preview now works before Phase 8 and cannot start OrbStack.
Database checks are deliberately stricter: running without a passing health
check, or using conflicting container configuration, no longer counts as ready.

## Saved choices, ownership and verification

These records mean different things:

- `database-services` and `optional-cli-packages`: the last apply selection,
  saved before installation so interrupted work can resume.
- `install-manifest.tsv`: newly installed Homebrew formulae/dependencies owned
  by Day One Mac. Pre-existing packages are never claimed merely because they
  were selected.
- `module-runs/ID/RUN/result`: `running`, `incomplete`, or `verified` for that
  particular apply attempt. This is historical evidence, not a live check.
- `advanced/completed/NN`: existing user-confirmed guide fingerprints. These
  are not converted into machine-verified execution records.

The dashboard recognises saved 09/13 selections even when the interactive
optional selector was not used. It checks current evidence rather than trusting
the latest run result. Shell integration remains a separate reviewed step.

## State, backups and recovery

Apply shares the existing operation lock with core setup and runtime management.
Other cooperating mutating operations fail with exit 75 while that lock is held.
Plans and checks do not acquire it. External Homebrew/Docker commands are not
controlled by this lock.

Each run writes private records under the configured state directory:

```text
module-runs/13/<unique-run>/
├── selection
├── result
├── journal.tsv
├── backups.tsv              when existing records were backed up
├── previously-absent.txt    when records did not previously exist
└── before/                  numbered copies mapped by backups.tsv
```

The run backs up the Day One-owned records it will modify, not database data,
the Homebrew installation or application credentials. Selection/result writes
and manifest updates use same-directory atomic replacement. Non-regular record
targets, including symlinks, are rejected.

If installation fails, successful earlier operations stay in place. Read the
printed journal path, resolve the error, then use `--resume` and `--check`.
Dependencies installed before a reported Homebrew failure are recorded when
post-install inventory remains available. An abrupt kill or unreadable inventory
can leave uncertain ownership; inspect it before using removal tooling.

There is no automatic rollback. Restoring a metadata backup does not undo
installed software or container changes, and can discard newer ownership
information. Keep application-data backups separately. An uncatchable process
termination may leave a `running` record and operation lock; check the recorded
process before manually recovering that specific lock.

## Contributor extension contract

`config/modules.tsv` has six tab-separated columns:
`id`, `layer`, `mode`, `prerequisite`, `title`, and repository-relative `guide`.
Its `mode` describes complete module-runner support, not the existence of
individual helper commands in a guided module.

`scripts/optional-module.sh` validates the request and dispatches supported
IDs to explicit adapters; it never executes a command obtained from TSV data.
`scripts/lib/module-execution.sh` supplies apply-only snapshots and journals.
The existing operation-lock and atomic-state libraries remain authoritative.

Before making another registry row executable:

1. Implement plan/apply/check/saved-selection behaviour in its adapter.
2. Acquire the shared lock before reading mutable apply state.
3. Back up owned records before writing, then save the approved selection.
4. Keep preview/check paths outside every mutation and service-start boundary.
5. Reconcile live state; preserve unmanaged resources; verify actual results.
6. Record manual requirements separately from machine verification.
7. Add fixtures for fresh setup, repeat runs, conflicts, failures and recovery.
8. Add every new runtime script, guide and asset to `config/runtime-files.txt`.

Run the isolated fixtures and project checks:

```bash
bash scripts/tests/test-optional-module.sh
bash scripts/tests/test-configure-databases.sh
bash scripts/tests/test-optional-status.sh
bash scripts/tests/test-portable-command.sh
pnpm run validate
pnpm run lint
```
