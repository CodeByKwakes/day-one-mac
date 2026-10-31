# AI tooling consolidation

Approved on 2026-10-30 following the read-only architecture review in the task.

## Scope

Keep Codex first, support local Claude Code through shared skill symlinks, and
preserve manual setup without a runtime requirement. Native agents stay opt-in.
Keep MCP optional and read-only by default. Native plugin packaging is deferred.
Do not register servers, activate agents, change the live Mac, push or publish.

## Implementation ledger

- [x] Preserve and validate the pending archive, VS Code and skill changes.
- [x] Document component ownership, dependencies and platform boundaries.
- [x] Generate native Day One agent adapters from shared policies.
- [x] Share MCP configuration metadata, separate preview/apply and expand guides.
- [x] Verify symlinks, independent packages and protocol permissions.
- [x] Run repository gates, pinned Skills CLI acceptance and independent review.

Baseline: `0519e763c89b72df83fd6affd685fdefcd26b9ce` with existing uncommitted
archive, editor and generated-skill changes. A task-specific temporary snapshot
preserves that diff before implementation. Existing changes remain in place.

Ruling: execute in the current feature branch to preserve the pending changes;
do not create a checkout that omits them. Keep public package assets intact until
independent-package checks justify any reduction.

Ruling: the approved chat plan supplies the task list. Missing companion workflow
packages do not require installation; use contributor checks and this ledger.

## Verification

Root lint, static and integration checks pass. The archive and other macOS
fixtures require normal scripting-dictionary access; restricted compilation
fails even on a minimal Standard Additions command. Source was not changed to
work around the environment.

MCP: 23 unit/protocol tests, relocated production-only tarball acceptance,
local Docker build and final container stdio discovery/host-operation denial pass.
The isolated npm package install uses the system trust store with TLS verification
retained. Configuration examples do not register a live server.

Skills CLI 1.7.4: 66 isolated installations across eleven skills, three clients
and two scopes pass, including update/removal and combined-client Claude symlinks.
The component fixture verifies all repository contributor-skill symlinks and
shared policy propagation to all three agent formats. All four edited contributor
skills pass the skill validator using a temporary YAML parser installation.

Live acceptance: Codex CLI version inspection only. Claude executable is absent
from the inspected command path. No account-backed Codex/Claude session, role
activation, Finder menu UI or actual project move was performed by this task.
The full `tools/validate.sh --all` gate and `actionlint` pass. Native Codex
TOML and Claude YAML adapters parse and preserve the expected inspection limits.
An independent read-only reviewer found no actionable issues and verified all
1,911 packaged file hashes, exact manifest coverage and Claude symlink targets.
Final diff inspection found no whitespace errors. Native plugin packaging,
asset slimming and live activation remain outside this approved core change.
