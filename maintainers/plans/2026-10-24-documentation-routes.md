# Documentation routes implementation plan

> **For agentic workers:** Use the installed executing-plans skill with the repository's validation tools. The user approved the documentation audit and proposal on 24 October 2026.

**Goal:** Give Scripted (Assisted) Setup and Manual Setup independent, complete journeys with one shared reference library.

**Architecture:** Keep `docs/setup/assisted` and `docs/setup/manual`. Move common prerequisites, terminology and reference material to `docs/shared`. Preserve old paths and heading destinations with regular-file compatibility guides, and update the packaged reader and catalogues together.

**Tech stack:** Markdown, JSON/TSV catalogues, the existing JavaScript documentation reader, macOS Bash 3.2 validation.

**Spec:** The Phase 1 audit and proposed tree approved in the task conversation on 24 October 2026. The five approved decisions retain route roots, organise complete tasks, move Second Brain prose, distinguish source from release availability, and leave contributor-skill repairs separate.

## Global constraints

- Preserve Apple-silicon-only support, phase IDs 01-08, module IDs and retired Module 12.
- Preserve all existing uncommitted profile, shell and skill changes.
- Manual setup invokes no Day One Mac scripts. Assisted setup uses public `day-one-mac` commands.
- Keep shared human actions in one manual owner with explicit assisted handoffs.
- Preserve old documentation paths and useful heading destinations throughout the supported 1.x line.
- Configuration catalogues own executable metadata; generated profile data remains generated.
- Keep historical records immutable in substance and outside runtime packages.
- Do not apply live settings, install a runtime, publish, push or commit as part of this rewrite.

## Review focus

1. Old links to sections of split documents must reach the relevant task, including in offline HTML.
2. A manual reader must not need runtime state, a permanent checkout or a Day One Mac command.
3. Core, unmanaged, managed-standard-account and non-1Password choices must remain valid.
4. Moving prose must not change module payload assets or required-phase fingerprints accidentally.
5. A source-only capability must not be presented as already published or hardware-verified.

## Working classification

Kind: runbook/reference/descriptive | Audience: developers following either setup route | Purpose: complete and verify the selected setup without guessing | Non-goals: new runtime features, vendor-account changes, production operations, new platform support, contributor-skill repair.

## Task 1: Freeze paths and relocate canonical content

**Files:** documentation under `docs/` and `extensions/second-brain/`; compatibility catalogue; migration fixture.

**Interfaces:** Every old path and heading remains a supported input. New canonical guides live under the approved route or shared roots. Payload templates remain in their current locations.

- [x] Capture the current working-tree text and old heading inventory outside the checkout.
- [x] Add a regression for route ownership, old fragment destinations and packaged coverage; observe its failure before migration.
- [x] Relocate prose and rewrite relative links, preserving compatibility entries.
- [x] Check all old path and fragment destinations.

## Task 2: Rewrite the route guides and shared library

**Files:** both setup routes, shared library, root README/CONTRIBUTING and documentation entry points.

**Interfaces:** Each task has one canonical procedure, numbered actions, expected outcomes, verification, troubleshooting and recovery appropriate to its effects.

- [x] Separate mixed route procedures and consolidate manual VS Code guidance.
- [x] Create missing manual foundation, authentication and maintenance tasks from existing verified sources.
- [x] Rewrite shared decisions, prerequisites, glossary and troubleshooting navigation.
- [x] Correct all approved audit findings except the separately scoped contributor-skill links.
- [x] Preserve source provenance and state external acceptance limits explicitly.

## Task 3: Integrate the reader, catalogues and package

**Files:** `src/docs/`, `config/catalogs/`, `config/runtime-files.txt`, generated-reference tool and affected tests.

**Interfaces:** Public CLI topics, old links, Markdown/HTML exports and packaged runtime documents resolve to the same canonical content.

- [x] Update metadata and reader navigation to the two setup sections and shared library.
- [x] Preserve section-specific compatibility routing and exclude aliases from navigation/search.
- [x] Update source consumers and generated reference output without changing profile recipes.
- [x] Run focused reader, export, catalogue and profile checks.

## Task 4: Validate and review

**Files:** integration checks and an acceptance record under `maintainers/acceptance/`.

- [x] Run `pnpm run lint`, `pnpm run validate:static`, `pnpm run test:integration` and packaged checks.
- [x] Exercise an isolated packaged upgrade and rollback when runtime-path changes are final.
- [x] Obtain an independent final review of route boundaries, compatibility and content preservation.
- [x] Resolve substantive findings, record unverified external/device behavior, and deliver the rewritten files with a summary.

## Execution record

- Approval: 2026-10-24, user approved all five Phase 1 recommendations.
- Baseline: `00167b5` plus existing uncommitted work; a complete text snapshot is retained outside the repository for comparison.
- Workflow adaptation: continue on the existing dedicated branch; use this ledger and existing test tooling because optional Superpowers companion scripts are not installed. The approved proposal authorises implementation without another outline approval.
- Pre-flight: documentation paths feed the reader, CLI guide catalogues, runtime allowlist, generated-profile reference and validation fixtures. These consumers must move together; source payload assets and historical records remain separate.

- Ruling: optional advanced manual recipes now have separate task owners under the Manual Setup topics; the assisted modules retain their manifest, plan/apply/check and return gates. This follows the approved route boundary even where the original proposed tree had a mixed advanced module.
- Link validation: preserved the 100 pre-existing aliases and added 118 moves. Section-specific database redirects remain intact; rootless destination links explicitly open the destination top rather than retaining a stale fragment.
- Regression evidence: route/navigation coverage failed before implementation, then passed. The independent review found a misplaced Warp completion guard; executing the documented snippet in an isolated HOME reproduced `compinit` not found before the fix.
- Tooling: Homebrew pnpm could not verify/download the repository-selected package-manager version through the restricted network. Validation uses the already available bundled pnpm to run the same scripts against existing locked dependencies; no package-manager or dependency files were changed.

- Independent review: five Important findings, no Critical findings. Corrected the Warp guard, removed assisted/circular prerequisites from manual tasks, retained 36 entry-page headings, mapped split VS Code/local-HTTPS sections to their owners, and restored permissions/login-items/browser-role tasks. The original-heading fixture now covers 234 paths and 3,229 headings, including the root README and CONTRIBUTING.
- Integration follow-up: setup-centre, advanced-audit and generated Raycast guide paths now resolve to canonical pages. Second Brain validation checks canonical route prose and existing payload assets rather than compatibility stubs. No installation or data-mutation semantics changed.
- Full gate: `tools/validate.sh --all` passed, including all integration regressions. A first restricted run could not bind a temporary Unix socket; the authorized full rerun allowed that fixture and passed without skipping it.

- Acceptance record: [documentation route rewrite](../acceptance/2026-10-24-documentation-routes.md). No commit, publication or live setup action was performed.
