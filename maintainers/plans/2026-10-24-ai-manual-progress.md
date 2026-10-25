# Execution record: AI-assisted and manual setup

Plan: [implementation plan](2026-10-24-ai-manual-rewrite.md).
Baseline: `4e776b4`. Branch: `codex/ai-manual-setup`.

Kind: normative implementation record. Audience: project maintainers.
Purpose: track the approved migration and evidence. Non-goals: publishing,
updating the live Mac or changing credentials.

## Decisions

- The approved two-route design supersedes the older runner-preservation contract.
  Preserve recovery data, not the retired ability to orchestrate setup.
- Keep numeric operation IDs as compatibility identifiers; do not require phase markers.
- Export a self-contained assistant workspace rather than modify global client files.
  Updating creates a new workspace; existing sessions and customisations remain available.
- Execute inline on the requested branch. Companion planning/worktree packages
  are unavailable; use this record and repository tests without installing workflow tools.
- Retired behaviour tests will be identified explicitly and replaced by retirement
  checks. Retained operation tests continue to exercise failure and recovery paths.

## Progress

- Branch created; working tree clean at baseline.
- Task 1: implemented; focused retirement, prerequisite and ownership tests passed.
- Task 2: implemented; export, refusal, tamper and relative-reference tests passed.
- Task 3: routes, client guides, lifecycle, integration exports and browser updated;
  documentation route, command-example and reader checks passed.
- Task 4: lint, full static/integration validation, packaged acceptance and
  isolated upgrade/rollback passed after review fixes.

## Current evidence and migration decisions

- New retirement/fresh-home test observed failing before implementation, then passing.
- Assistant export test observed failing before implementation, then passing. It covers
  paths with spaces/Unicode, existing destinations, symlink parents, hashing, session notes
  and shared Claude skills. No live client configuration was changed.
- Profile generation/replacement tests pass with actual CLI prerequisites and no phase gate.
- Ruling: preserve source-only historical runner helpers for recovery research, but retire
  direct public execution and omit runner code from runtime packaging. Do not present
  those helpers as a supported setup route.
- Ruling: remove wizard-only selection, required-action, preparation and Phase 3 dispatch
  suites from the active gate. Replace their public contract with inert-command checks.
  Keep package integrity/path/lock checks from the mixed audit suite and retain operation,
  hosting, shell, profile, ownership, recovery and application tests.
- Ruling: module audit snapshots treat absent old phase records as informational. Unsafe
  existing records still fail; recorded selections and current tool checks still detect drift.
- Static validation retains catalogue schemas, local links/anchors, script syntax,
  release/hook contracts and package layout. Obsolete wizard string checks are removed.
- Warp and Raycast exports now expose current help, assistant planning, tool inspection
  and recovery guidance. Existing imported copies require manual review/reimport.
- No runtime installation, global AI configuration, publish or push has been performed.

## Independent final review and fixes

One fresh-context review identified five migration gaps. All were accepted:

- Removed the bootstrap page's obsolete skill reference; the old template now
  directs existing users to the current workspace without running setup.
- Added explicit alias ownership for fresh manual shells. Regression failed on
  the absent option, then passed for preview/apply without legacy state.
- Added a shared current management check before either preference writer or
  restore path. The fresh managed fixture first wrote defaults incorrectly;
  it now refuses managed, unknown and failed inspections before state changes.
- Extracted retained direct preference and recorded-rollback tests from the
  mixed retired runner suite. Their preview, typed originals, restore and
  recovery preservation checks pass.
- Historical Advanced guide hashes are informational, not current completion
  gates. Regression reproduced the old audit failure and now passes without
  rewriting historical state; redirected historical records still fail.

Packaged capability acceptance and an isolated `4e776b4` upgrade/rollback passed
before the review fixes. Final aggregate, package and upgrade checks are rerun
below to cover the final implementation. Live client/account/managed-hardware
acceptance remains separate.

## Final verification

- `pnpm run lint`: passed; ShellCheck reviewed 235 scripts and Markdown lint
  reported no issues across 463 files.
- `pnpm run acceptance:package`: passed; isolated archive installation, 14 active
  capabilities, packaged Node helpers, plan/apply/check/resume, drift and audit.
- `tests/integration/test-runtime-upgrade.sh EXTRACTED_PREVIOUS_TREE`: passed
  with a temporary extraction of baseline `4e776b4`; upgrade and rollback
  preserved existing state, ownership and shell files.
- Skill and role checks: six skill frontmatters and Claude/Copilot YAML parsed;
  Codex role fields and permission-inheritance contracts checked. Actual client
  loading still requires the chosen client, account and current native support.
- `tools/validate.sh --all`: passed with exit 0, covering the full static and
  integration gates, including archive/path/lock safety and retained rollback.
- `node tests/integration/test-docs.cjs`: passed after adding the final browser
  anchor assertions; legacy anchors render while unsafe raw HTML stays escaped.
- `git diff --check`: passed before committing the rewrite.

No public release, live installation, account access or hardware acceptance is
claimed. The implementation remains on the requested branch for review.
