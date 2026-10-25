# Manual setup coverage audit

## Scope and baseline

The audit at `7fe179f` covered 139 tracked Markdown files: 90 under
`docs/setup/manual` and 49 under `docs/setup/assisted`. This includes compatibility
pointers and indexes. The [file inventory](2026-10-24-setup-coverage-inventory.md)
records their locations and purposes. All files received structural, local-link
and example-syntax scans; procedure review concentrated on installation,
ownership, recovery and the manual/assisted boundary.

Every required phase already had a manual capability guide. Missing phase
numbers were not the problem. Several procedures needed recovery safeguards,
clearer optional branches or links to their actual prerequisite. The requested
AI assistant also needed an entry before the base setup rather than only an
after-Phase-8 module.

## Findings and approved changes

| Severity | Baseline finding | Approved repair and owner |
|---|---|---|
| High | Project restore copied directly into existing Documents and imported SQL into the default database | [Restore projects](../../docs/setup/manual/preparation/restore-projects.md) stages documents separately and routes database recovery to isolated targets |
| High | VS Code backup suppressed copy errors and reused a fixed destination | [Brewfile maintenance](../../docs/setup/manual/apps/brewfile.md#8-handle-vs-code-removal-recoverably) uses separate verified backups and stops on copy failure |
| Medium | A personal skill link was created before checking for collisions; dangling links were not covered | [AI maintenance](../../docs/setup/manual/ai/maintenance.md#3-add-compatibility-links-only-where-needed) preserves different files and links before mutation |
| Medium | Manual client instructions had an empty command block and depended on assisted ownership reports or an already installed Raycast | [AI clients](../../docs/setup/manual/ai/clients.md) states direct prerequisites, cask verification and the original installation owner |
| Medium | Manual aliases assumed chezmoi, ghq and Homebrew Zsh | [Alias guide](../../docs/setup/manual/shell/aliases.md) distinguishes user-owned files and uses the macOS Zsh syntax check |
| Medium | Routine manual maintenance was incomplete while procedures lived in the assisted module | [Manual maintenance](../../docs/setup/manual/maintenance.md) owns runtime, configuration, repository, service and rebuild procedures; Module 21 links there |
| Medium | Container backups lacked usable Redis/MongoDB restore rehearsals | [Container recovery](../../docs/setup/manual/databases/containers.md#8-back-up-before-destructive-work) adds isolated examples and keeps PostgreSQL with its existing owner |
| Medium | Playwright examples used global scope while the recommendation said workspace only | [MCP connections](../../docs/setup/manual/ai/mcp.md#playwright-scope) defaults to project scope and explains optional user scope and browser isolation |
| Medium | HTTPS setup had a circular prerequisite; Apple sign-in was described as a VS Code Sync requirement | [HTTPS setup](../../docs/setup/manual/security/https-git.md) clarifies the order; Phase 1 separates Apple and editor accounts |
| Medium | Thirteen shell blocks used angle-bracket templates that did not parse | Reviewed input variables, safe inspection examples or links replace those blocks |
| Low | Moved skill/MCP topics and Warp steps retained obsolete section numbers | Named section links route to the current owners |

The working-tree implementation also adds the
[manual AI preparation](../../docs/setup/manual/ai/setup-assistant.md),
[assisted checkpoint](../../docs/setup/assisted/ai-setup-assistant.md) and
[phase coverage reference](../../docs/shared/reference/setup-coverage.md).
The latter maps all eight required phases, inserted checkpoints and 14 active
optional/advanced modules. Module 12 remains retired.

## Assistant design and integration

The user approved no AI, guidance only or approved execution before Phase 1.
The checkpoint reuses one client or offers a reviewed native install, prepares
private instructions and leaves account sign-in/tool permissions to the user.
Module 10 remains an optional expansion after Phase 8. The selected mode is a
choice, not readiness evidence or a permission grant.

The runtime uses its existing lock and state helpers. Its public command is
`day-one-mac ai-setup`; preview and check do not launch clients or download
software. The packaged skill can be read by Codex, Claude or another approved
client. No global skill install or model/API credential is required by the
handoff generator.

An independent final review found two installation-ownership defects in the
initial implementation. Regression tests reproduced both: Module 10 could miss
a native CLI outside PATH, and the checkpoint treated damaged native paths as
absent. Shared discovery now preserves those clients and stops on damaged
paths. A failed-copy fixture covers incomplete handoff creation without claiming
a physical power-loss test.

## Validation and acceptance boundary

The committed baseline contained 745 non-empty shell examples; 13 were
parameterized blocks that failed syntax parsing. Its 18 JSON examples parsed.
Local links and package inventory passed the baseline checks. These results
came from the recorded audit scan, not live execution of vendor commands.

Validation commands for the implementation are:

```bash
pnpm run lint
pnpm run validate:static
pnpm run test:integration
pnpm run acceptance:package
```

`tools/validate.sh --all` combines static and integration gates. The isolated
upgrade/rollback test receives an extracted previous tree; it must never use
the operator's live setup state. Exact completion evidence is recorded in the
[implementation ledger](../plans/2026-10-24-ai-setup.md).

The example checks parse shell and JSON, and selected fixtures execute backup,
link, checkpoint and packaged-runtime operations in disposable locations.
They do not prove vendor installations, account entitlement, application GUI
permissions or real Redis/MongoDB/PostgreSQL recovery. Those remain local
acceptance work with the selected versions and data. The source changes are
not a published release or an update of the operator's installed runtime.
