# How setup fits together

Day One Mac has two independent setup journeys. Shared references define the
choices and completion criteria; each route owns its executable procedure.
Use [Start here](../../START-HERE.md) to choose the journey.

## Optional assistance before the base

The [AI choice](../../setup/manual/ai/setup-assistant.md) precedes Phase 1 for
both routes. It can be skipped. Guidance uses an existing client; local
execution needs a verified approved client. Neither mode changes the human
checkpoints or grants blanket permission. The assisted checkpoint saves its
choice separately and leaves required phase IDs unchanged. Module 10 adds
clients later, after Phase 8. See the [coverage map](../reference/setup-coverage.md)
for each phase and its manual capability.

## Scripted (Assisted) Setup

The standalone runtime supplies `day-one-mac`. It needs no permanent Git
checkout. Its eight required phases collect choices, prepare tools, establish
authentication and configuration, install selected languages and verify results.
The Installation Centre is a checkpoint after the foundation, not a ninth phase.

The runner records its own changes and revalidates saved evidence before reuse.
A current phase marker does not mean every optional application or account is
configured. Optional and advanced apply operations use their own prerequisites,
selection records and recovery rules.

Follow the [assisted sequence](../../setup/assisted/README.md) for installation,
pauses, resumption and completion. Use its recovery guides before deleting state.

## Manual Setup

The manual route uses macOS and the chosen tools directly. It requires no runtime,
phase markers or Day One Mac ownership records. You record changes and keep
recoverable backups yourself. Follow the [manual sequence](../../setup/manual/README.md)
from operating-system checks through a real project and sample restore.

No broad manual account-preserving cleanup is provided. An existing populated
Mac needs the approved backup/reset boundary described in the prerequisites.

## Shared manual actions

Licences, account sign-in, provider key registration, macOS permission approval,
client connections and recovery tests require deliberate human work. Their
canonical task lives in Manual Setup. An assisted phase states which action to
perform and when to return. Do not rerun an entire manual installation after a
successful assisted installation.

## Choices are independent

The [decision worksheet](../decisions.md) owns the selection matrix. Hosting
providers do not choose AI clients. User-owned configuration does not require
chezmoi. Core does not require productivity desktop apps. An existing external
application keeps its installation/update owner.

## Evidence and recovery

[Shared verification](../verification.md) defines acceptance criteria. Assisted
state records, real application tests and hardware/managed-device pilots are
different forms of evidence. Unknown or expired evidence is not a successful
check. [Architecture and state](architecture-and-state.md) explains the runtime
contract; the [troubleshooting index](../troubleshooting.md) routes failures.

Keep setup state while relying on recorded rollback. A package list is not an
application-data backup; a Git commit is not proof that it reached a remote.

## Historical records

Maintainer audits describe what was observed at their stated baseline. The
September new-device blueprint is retained as a historical record under
`maintainers/audits/2026-09-25-new-device-blueprint.md` in the source checkout.
It is not bundled as current setup guidance or evidence of a later release.
