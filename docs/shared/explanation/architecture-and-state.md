# Runtime architecture and state

Day One Mac has two setup routes: [AI-assisted](../../setup/ai/README.md) and
[manual](../../setup/manual/README.md). Both use the same manual recipes.
The optional utility bundle supplies bounded operations; it does not coordinate
whole-machine setup. See [migration](../migration/from-scripted-setup.md) for old installations.

## Responsibilities

| Component | Responsibility | Boundary |
|---|---|---|
| `scripts/day-one-mac` | Resolve the runtime and dispatch commands | No setup orchestration |
| `src/runtime/` | Install, verify, switch and remove runtime versions | Preserve application data and recovery state |
| `src/modules/` | Selected utilities with preview, apply and verification | Check actual prerequisites; preserve existing ownership |
| `src/core/` | Paths, state, locks, deadlines and shared checks | No implicit installation |
| `src/operations/assistant.cjs` | Export a private assistant workspace | No client launch or global configuration changes |
| `templates/skills/` | Shared instructions for six capabilities | Instructions do not grant execution permissions |
| `templates/agents/` | Client-specific role adapters | Client permission settings remain authoritative |
| `docs/setup/manual/` | Canonical setup recipes | No Day One Mac scripts required |
| `tools/` and `tests/` | Contributor validation and release checks | Excluded from the installed runtime |

## State and ownership

The default private state directory remains `~/.day-one-mac`. Existing scalar
selections, ownership manifests, backups and operation records remain readable.
Retired phase records are historical evidence. They are neither prerequisites
for a utility nor proof that the current machine is healthy.

Each retained utility checks its actual inputs: platform, required executable,
selected manifest, destination, ownership and any required approval. Run its
plan before applying. A generated artifact verifies only the exported files;
manual import, account sign-in and service access still need their own checks.

New utility state uses private files, rejects redirected paths and records only
owned changes. Atomic replacement writes a complete temporary file beside the
destination before renaming it. This protects an individual file, not a whole
multi-file operation or a sudden power loss. Mutating operations use the shared
operation lock. Do not delete a live lock; follow the recovery instructions.

## Packaging and updates

`config/runtime-files.txt` is the shipping allowlist. Unlisted personal files,
contributor instructions, dependencies and the retired runner do not ship.
Installed versions live under `~/.local/share/day-one-mac/releases/`; `current`
selects the active version. A verified update changes that selection and retains
the previous version for rollback. It does not reconfigure the Mac.

The public installer checks release provenance and checksums. Local archive
checksums detect changes but do not establish publisher identity. Contributor
acceptance must exercise an extracted package and an isolated previous-version
upgrade and rollback before a real-Mac installation.

## Assistant workspaces

Export creates a new directory with shared skills, client role adapters, approved
recipes and a hash manifest. Existing destinations are refused. Session notes
live in `session/` and remain private. Checks detect modified or unexpected
exported files; they do not prove that a model followed the instructions.

Updates create a separate export for review. Preserve session notes and deliberate
customisations before retiring an older export. Global AI client files and
credentials are outside this export's ownership.
