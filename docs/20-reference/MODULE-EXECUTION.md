# Module execution reference

Modules **09 (databases)**, **10 (AI client payloads)**, **13 (CLI formulae)**
and **16 (selected software)** support a shared execution interface.
**10A** adds an owned digest-pinned OmniRoute container lifecycle.
**11 (MCP snippets)**, **12 (profile artifacts)**, **14 (Warp exports)**,
**21 (audit snapshots)** and **22 (AI governance evidence)**
use that interface for generated artifacts, not software installation.
Other optional and Advanced modules remain guided procedures.
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
| `advanced --module 16 --inventory` | Print candidate two-column TSV to stdout. Does not save a selection or evaluate the Brewfile. |

Supply `--services postgres,redis,mongodb` for 09 or `--packages eza,fzf` for 13.
Omitting the selection uses the saved one; absence of saved choices is an error.
`--yes` skips the ordinary apply/resume confirmation only. It does not approve
macOS permissions or another application's onboarding.

Use `optional` for 09/10/10A/11/12/13/14 and `advanced` for 16/21/22:

| Module | Selection | Verification scope |
|---|---|---|
| 10 | `--clients claude,codex` (also `copilot-app`, `copilot-cli`, `copilot-vscode`, `raycast-ai`) | Catalogue payload presence/ownership; never authentication, billing or permissions |
| 16 | `--manifest PATH` with two tab-separated fields per row | Selected applications, formulae and Default-profile extensions; never Brewfile, licences or Settings Sync |

Module 16 row kinds are `app` (catalogue ID), `formula` (Homebrew token),
and `extension` (lowercase `publisher.name`). Comments start with `#`.
Raw casks, App Store IDs, Ruby, shell commands, VSIX files and version-pinned
extensions are not accepted. The runner never evaluates a Brewfile.
Use [the beginner walkthrough](../03-advanced/16-brewfile-apps-and-editor.md#executable-selected-payload-route)
to generate and review your first selection.

For 10/16, `--app-install-policy check-only` is the safe default. Missing
catalogue apps stop until you choose `prompt` interactively or explicitly
approve `homebrew`. Existing external apps are preserved under every policy.
`--yes` does not choose Homebrew. Formula and extension rows explicitly select
their respective installers. Enable the `code` command before applying
extension rows; the runner targets only the Default profile through the
[VS Code CLI](https://code.visualstudio.com/docs/configure/command-line).

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
and guide-only `advanced` commands retain their roles. Explicit actions for
`advanced --module 16` now route to the software runner; without an action,
that command still opens the guide. The module interface adds
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
- `software-10-clients` and `software-10.tsv`: original AI choices and resolved
  application rows. The compatibility `ai-clients` selection is also saved.
  Resume uses `software-10-clients`, not a subsequently edited wizard choice.
- `software-16.tsv`: canonical selection snapshot. Resume does not reread the
  original manifest. A new selection requires plan/apply, not resume.
- `software-10-report.tsv` and `software-16-report.tsv`: last apply payload
  evidence. Cask/bundle and extension versions are recorded when available;
  external CLI clients are not launched just to probe a version.
- `install-manifest.tsv`: newly installed Homebrew formulae/dependencies owned
  by Day One Mac. Pre-existing packages are never claimed merely because they
  were selected.
- `software-extension-installs.tsv`: Default-profile extension IDs added during
  installation, including detected dependencies. Pre-existing extensions stay
  unclaimed. This is evidence, not an automatic removal instruction.
- `module-runs/ID/RUN/result`: `running`, `incomplete`, or `verified` for that
  particular apply attempt. This is historical evidence, not a live check.
- `advanced/completed/NN`: existing user-confirmed guide fingerprints. These
  are not converted into machine-verified execution records.

The dashboard recognises saved 09/10/13/16 selections even when the interactive
optional selector was not used. It checks current evidence rather than trusting
the latest run result. Shell integration remains a separate reviewed step.
For 10/16 a passing payload check still yields `partial` in the dashboard:
manual account/configuration work is outside the runner's verification scope.
Module 16 becomes dashboard-ready only when its live payload check passes
and a separately user-confirmed guide fingerprint is current. A stale
fingerprint or failed payload check requires review.

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
and the software runner's formula/extension ledger updates use same-directory
atomic replacement. The delegated application installer retains its existing
append-based installation ledger; its records are backed up before the run.
Non-regular backup targets, including symlinks, are rejected.

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

Software runs additionally save `verification-scope` and `manual-steps.txt`.
Their snapshots cover owned selection, provenance, report and ledger records,
not application settings or credentials. The installer records newly visible
Homebrew dependencies and extensions even after a reported installer failure
when post-install inventory is readable. A resume skips pre-existing selected
payloads and never requests removal. Installing missing items may still change
dependencies through the package manager or trigger OS/vendor prompts.

## Generated artifacts: Modules 11, 12, 14, 21 and 22

`scripts/configure-artifacts.sh` uses the same lock, Phase 8 gate, confirmation,
backup and journal machinery. Its apply action creates files only; it never
imports them, starts applications or changes accounts. Plan/check create no
temporary files or reports. Existing `advanced-audit` remains a separate
broader command that writes reports, including with `--stdout` or `--check`.

| Module | Input | Output and check scope |
|---|---|---|
| 11 | `--manifest PATH`: client, server name, workspace scope, HTTPS URL, token variable or `-` | Client-specific review snippets; byte integrity, not connectivity or authentication |
| 12 | `--manifest PATH`: one `profile<TAB>Name` row plus zero or more `extension<TAB>publisher.name` rows | Minimal `profile.code-profile` and deduplicated `extensions.txt`; verify generated bytes/selection, not imported editor state |
| 14 | Runtime-allowlisted Warp collection | Versioned `Day One Mac` directory; verify file hashes and current source alignment, not Warp/cloud objects |
| 21 | Fixed `audit-evidence-v1` scope | `evidence.tsv` and `report.md` with previous/current comparison; fail check on drift, failed gates, missing or damaged baseline |
| 22 | `--manifest PATH`: kind, name, owner, absolute narrow path | Skill-tree and MCP-metadata hashes, owner labels and diff; no code execution or trust approval |

Profile names are restricted to safe ASCII, 1–64 characters, starting with a
letter/digit; `Default` is rejected. Extensions are lowercase IDs without
versions, VSIX paths or arbitrary shell arguments. The generated profile has
only `name` and string-encoded `extensions` resources. No existing settings,
secrets, keybindings, snippets, tasks, MCP or global state are exported. Import
review must address inherited/default settings and extension trust.

Each apply/resume creates a new `module-runs/ID/RUN/artifact/`. The canonical
selection is saved first in `artifact-ID-selection.tsv`. After generation and
verification, `artifact-ID-current` is atomically replaced with the run ID
and a SHA-256 digest of its sorted file-hash inventory. `artifact.sha256` beside
the artifact is a readable file inventory. Checks recompute the complete
inventory, detecting missing, extra or changed files and rejecting symlinks;
they do not execute paths from a checksum file. These hashes detect local
changes, not authenticity against an attacker who can edit the state directory.

A failed generation retains its journal/selection and does not replace the
published pointer. A previous good artifact is not necessarily valid for a
newly saved selection, so check still compares both. Resume uses the saved
profile choice or Warp source hash. Changed Warp source requires a new
plan/apply; old exports are retained. Paths through symlinks are rejected.
Artifacts are private review outputs, not backups of application data.

Audit apply saves failed-gate evidence too, publishes the diagnostic snapshot,
and returns nonzero with an incomplete run. After fixing the issue, resume
captures fresh evidence; it never performs remediation. Audit check compares
live evidence with the latest snapshot, not just a historical success marker.
A new apply accepts the current evidence as the comparison baseline, so review
the plan first. Damaged prior audit artifacts block comparison; preserve and
investigate them before recovering that specific pointer.

The audit hashes explicit non-secret state records and runs checks only for
saved executable selections. Required phase records are checked for presence,
not recomputed against current phase implementation or machine health.
Module 21's own guide marker is excluded to avoid self-generated drift. Full
environment checks, updates, cleanup, account verification and rebuilds remain
outside this adapter. No completion fingerprints are written by these actions.

## AI artifact schemas and gateway contract

For Module 11, clients are `claude`, `codex` or `vscode`, scope is only
`workspace`, and names match `[a-z][a-z0-9_-]{0,63}`. HTTPS URLs use a
restricted ASCII hostname/optional port/path syntax; credentials, queries,
fragments and escapes are rejected. Review paths for embedded secrets too.
Token names must match `DAY_ONE_MCP_[A-Z][A-Z0-9_]*`; values are never read.
Duplicate client/name pairs are rejected. `-` omits the auth field, not the
need for a separate authentication decision. Generated files are not named
as live client discovery files. Codex entries are disabled.

Module 22 accepts `skill` or `mcp` rows. Names use the same plain-name rule;
owners are 1–64 letters/digits/dots/underscores/hyphens, starting with a letter
or digit. Skill paths must contain `SKILL.md` and every file in that selected
tree contributes to the digest. MCP paths contain Module 11 metadata, not live
client settings. Canonical metadata hashes ignore comments/blank lines.
Symlinks and non-regular files fail the evidence gate; whole-home/root paths
are rejected. Do not put a whole library under a fake `SKILL.md` to bypass
the narrow-scope rule. Apply/resume snapshots current contents; review the
diff before accepting a new baseline. Like Module 21, failed evidence is
published diagnostically with a nonzero exit. Hashes are not signatures.

Module 10A accepts exactly one each of `context`, `image` and `port` in a
two-column TSV. Context must be `orbstack` with a local Unix endpoint; image
must be `diegosouzapw/omniroute@sha256:` plus 64 lowercase hex characters;
port must be 1024–65535. All engine commands explicitly select this context.
Plan is conditional and makes no Docker calls; check only inspects.

Apply saves `omniroute-selection.tsv` and journals pull/create/start steps.
The labels `com.day-one-mac.owner=module-10a-v1` and
`com.day-one-mac.spec=<selection-hash>` identify owned resources. These are
cooperative ownership metadata, not protection against a malicious Docker
administrator. Before starting, the runner verifies bounded image/runtime,
port, mount, network, security and environment constraints. It requires the
reviewed image's original healthcheck and does not make provider requests.
It does not update, adopt, remove or roll back containers/volumes. The run
stores the newly created container ID; labels and live checks reconcile a
partial failure. A shared volume, conflicting name or unreadable inventory
stops the operation. Fixed names deliberately prevent parallel instances.
Health failure retains resources and returns nonzero after a 60-second
polling window (Docker command latency can extend wall time).

The dashboard recognises all three saved selections, but passing checks remain
`partial` because activation, trust and provider readiness are manual.
Module 21 includes their selected-scope live checks in its audit evidence.

## Contributor extension contract

`config/modules.tsv` has six tab-separated columns:
`id`, `layer`, `mode`, `prerequisite`, `title`, and repository-relative `guide`.
Its `mode` describes complete module-runner support, not the existence of
individual helper commands in a guided module.

`scripts/optional-module.sh` validates the request and dispatches supported
IDs to explicit adapters; it never executes a command obtained from TSV data.
`scripts/lib/module-execution.sh` supplies apply-only snapshots and journals.
The existing operation-lock and atomic-state libraries remain authoritative.
`scripts/configure-software.sh` shares selection validation, inventory,
ownership checks and recovery for 10/16. Read-only paths call detection helpers
directly: `application-status.sh` itself writes provenance even for status.
Apply delegates missing catalogue apps to that existing ownership-aware
installer. No account, client launch, arbitrary cask, Brewfile evaluation or
cleanup action belongs in this adapter.

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
bash scripts/tests/test-software-modules.sh
bash scripts/tests/test-artifact-modules.sh
bash scripts/tests/test-ai-artifacts.sh
bash scripts/tests/test-omniroute-module.sh
bash scripts/tests/test-configure-databases.sh
bash scripts/tests/test-optional-status.sh
bash scripts/tests/test-portable-command.sh
pnpm run validate
pnpm run lint
```
