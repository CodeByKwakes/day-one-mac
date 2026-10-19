# Day One Mac organization implementation plan

> **For agentic workers:** Use the installed executing-plans skill to implement this plan task by task. The user approved the proposed organization and requested implementation on 19 October 2026.

**Goal:** Organize the existing product around clear responsibilities while preserving public commands, safety controls and saved evidence.

**Architecture:** One repository contains a standalone runtime, contributor tools, user documentation and optional integrations. Configuration owns executable data; documentation explains it. Regular-file compatibility entry points preserve supported script paths while implementations move into `src/`.

**Tech stack:** macOS Bash 3.2, Node.js 22+, Python 3, TSV/JSON and Markdown.

**Spec:** The approved restructuring recommendation in this conversation, captured by the contracts and target paths below.

## Global constraints

- Preserve Apple-silicon support, Bash 3.2, existing CLI behavior, phase IDs 01–08 and module IDs; 12 remains retired.
- Preserve preview/apply distinctions, locks, ownership, atomic state, explicit destructive confirmation and runtime integrity checks.
- Preserve existing state locations. Changed implementation evidence requires honest revalidation; never translate an old completion marker into a new success claim.
- Do not add a bootstrap dependency on Node.js or Python for basic phase/module metadata.
- Preserve the complete manual route and managed standard-user route.
- Runtime packages use an explicit allowlist of regular files; contributor skills, tests and audit history stay outside it.
- Keep mechanical moves separate from deliberate behavior changes. No public release or remote push is required by this plan.

## Review focus

1. An upgrade with existing phase evidence must report affected phases as stale without deleting settings or ownership evidence.
2. Paths with spaces and Unicode, execution outside the checkout and packaged runtime execution must resolve consistently.
3. Old documentation links and script entry points must remain useful after moves.
4. Missing or malformed configuration must fail explicitly, without accepting false completion or installing anything.
5. Documentation, profile generation and preview commands must not mutate the user's Mac.

## Target ownership

| Path | Responsibility |
| --- | --- |
| `scripts/` | Compatibility entry points and public launcher |
| `src/core/` | Shared state, locks, paths, ownership and platform helpers |
| `src/cli/` | Command dispatch and wizard presentation |
| `src/setup/` | Required setup and phases |
| `src/preflight/` | Existing-Mac safety preparation |
| `src/modules/` | Optional and advanced behavior |
| `src/operations/` | Verification, cleanup, finalization and removal |
| `src/runtime/` | Runtime packaging, installation and activation |
| `src/docs/` | Offline reader and export |
| `config/` | Canonical catalogues, policies and profile data |
| `templates/`, `integrations/`, `extensions/` | Reusable templates, application integrations and Second Brain |
| `docs/` | Setup journeys, how-to guides, reference and explanation |
| `maintainers/` | Architecture decisions, plans, audits, acceptance and releasing |
| `tests/`, `tools/` | Fixtures/regressions and contributor commands |

## Task 1: Record contracts and make executable data independent

**Files:** `AGENTS.md`, `AGENT.md`, `config/profiles/vscode/*.json`, `config/catalogs/phases.tsv`, `src/modules/vscode-profiles/build.cjs`, `src/core/required-phase-catalog.sh`, `src/setup/setup.sh`, profile and phase-dependency regression tests.

**Interfaces:** Profile `recipe(slug, selected)` retains its current return shape and exact output. Phase catalogue provides stable IDs, titles and guide paths. Dependency catalogue provides reviewed relative implementation paths per phase.

- [x] Capture current profile outputs and required-phase dependency behavior.
- [x] Add tests for guide-independent generation, output equivalence, invalid config and unrelated-helper changes.
- [x] Extract canonical profile configuration and validate it before use.
- [x] Centralize phase metadata and explicit implementation dependencies.
- [x] Document one-time revalidation and preserve existing state untouched.
- [x] Run profile, required-action and configuration regression checks.

## Task 2: Relocate implementation, tests and contributor tooling

**Files:** Existing `scripts/` implementations and tests; new `src/`, `tests/`, `tools/`; runtime allowlist, package scripts, CI and import/path references.

**Interfaces:** Public commands and supported old executable entry points retain arguments and exit status. Internal source paths use the repository/runtime root, independent of working directory.

- [x] Define and record the complete old-to-new path map.
- [x] Move coherent implementations and repair imports/root resolution.
- [x] Preserve regular-file entry point wrappers where callers need compatibility.
- [x] Move fixtures and contributor commands; update package scripts and CI.
- [x] Split the setup runner's configuration and installation responsibilities at existing function seams; preserve function contracts.
- [x] Run syntax/lint, public command and packaged execution checks.

## Task 3: Organize documentation, templates and integrations

**Files:** `docs/`, `maintainers/`, `templates/`, `integrations/`, `extensions/`, documentation reader/export, navigation catalogues and runtime allowlist.

**Interfaces:** Canonical documents have one maintained source. An explicit old-path map preserves documentation navigation. Shared PostgreSQL procedures are client-neutral.

- [x] Move documentation by purpose and rewrite relative links against the path map.
- [x] Preserve old Markdown anchors through compatibility pages or reader aliases.
- [x] Reconcile account, preset and optional-tool claims.
- [x] Extract shared PostgreSQL procedures and focused development references.
- [x] Relocate shell templates, Warp/Shortcuts/Raycast assets and Second Brain.
- [x] Keep maintainer archives out of end-user runtime packages; retain their historical content.
- [x] Run documentation, profile, asset and packaged checks.

## Task 4: Establish maintainable validation and contributor guidance

**Files:** `tools/`, `tests/`, `package.json`, `.github/workflows/`, contributor documentation and `.agents/skills/day-one-mac-maintenance/SKILL.md`.

**Interfaces:** Fast static validation and full regression validation remain separately runnable. The release gate still runs the complete required checks.

- [x] Separate static validation, regression orchestration and native acceptance entry points.
- [x] Create the focused maintenance skill and validate its frontmatter/references.
- [x] Document catalogue ownership, path migration rules and test selection.
- [x] Run full lint and validation; record exact results.

## Task 5: Review, package and verify upgrade compatibility

**Files:** Regression fixtures, migration notes and completion evidence.

**Interfaces:** Installation of the candidate archive and rollback preserve old release/state data and enforce inventory integrity.

- [x] Build an archive from the final candidate and exercise packaged command/docs/profile routes.
- [x] Exercise upgrade from the baseline release and rollback in isolated temporary homes.
- [x] Obtain independent security-focused review of the complete change and address substantive findings.
- [x] Commit verified changes, including the user-added skills without rewriting their contents.
- [x] Report automated evidence separately from real-device/MDM pilot evidence.

## Execution record

- Baseline: `0dcfeca`; installed runtime recorded by the preceding audit as `1.5.0-local.20261015-dbeaver.0dcfeca`.
- Initial local changes: six user-installed skills, matching Claude skill links and `skills-lock.json`.
- Execution: current dedicated `codex/optional-tool-docs` branch. Existing authorized scope is reused; no redundant outline approval is needed.
- Workflow adaptation: use repository test tools and this tracked ledger where optional Superpowers companion scripts are not installed. No missing workflow package is needed to implement product behavior.
- Native/managed acceptance requires real external evidence; automated fixtures must never be described as that evidence.

- Task 1: profile and dependency regressions were observed failing before implementation and passing afterward. Baseline resolved recipes are retained in `tests/fixtures/vscode/recipes-v1.json`.
- Tasks 2–3: path maps record 143 code, 280 documentation/asset and 6 configuration moves. Compatibility entry points and 100 guide aliases remain supported. The offline reader, exports, required actions and Second Brain fixtures passed after relocation fixes.
- Task 4: static/full validation entry points are separated. ShellCheck passed 228 scripts; Markdown and workflow lint passed. The project maintenance skill and its Claude link are added; user-installed skill contents remain untouched.
- Task 5: packaged-module acceptance passed all 14 active capabilities. The prior-layout fixture passed `0dcfeca` → candidate archive → rollback and preserved old evidence and shell files. Native/MDM acceptance remains separate.
- Final: fixed R1–R4 — `test-restructure-safety.sh` RED→GREEN; the final `tools/validate.sh --all` run passed with exit 0. A canonical setup-centre guide regression also passed RED→GREEN.
- Ruling: retain the current dedicated branch and use repository test tooling where optional Superpowers workflow scripts are absent — the approved scope and regression contracts remain available — the cost is a manually maintained execution ledger instead of those helper scripts.
- Ruling: use the existing catalogue titles for advanced module listings and retain regular-file compatibility adapters through the current 1.x line — this gives metadata one owner without dropping existing callers — the cost is retained adapter/alias files and a larger package than a clean-slate layout.
- Detailed commands, review resolutions and acceptance limits: [acceptance record](../acceptance/RESTRUCTURE-2026-10-19.md).

- Completion evidence: the complete static/regression gate passed with exit 0; focused required-action checks and baseline archive upgrade/rollback were rerun after the final fingerprint error-propagation guard and passed. ShellCheck, Markdown lint and actionlint passed. The implementation commit includes this plan, the acceptance record and the preserved user-added skills.
- Runtime activation is a separate post-commit action under the existing user authorization; report its exact version and integrity result in the conversation. No public release or push is part of this work.
