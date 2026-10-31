# Documentation audit implementation plan

> Use executing-plans to implement the approved audit action list in this session.

**Goal:** Make current setup instructions actionable without retired runtime
dependencies, while preserving published URLs and portable packages.

**Architecture:** Canonical manual recipes remain under `docs/setup/manual`.
Indexes route to their owners; compatibility notices remain inbound routes.
Generated skills and native plugin guide snapshots are rebuilt from sources.

**Tech stack:** Markdown, Node.js 22.20+, existing documentation renderer and tests.

**Spec:** The documentation audit and its ten prioritized fixes, approved in chat.

## Constraints and review focus

- Preserve historical records, existing guide URLs and section anchors.
- Do not change live client settings, install software, commit, push or publish.
- Keep manual instructions independent of project helpers.
- Check alternative commands, missing prerequisites, existing client state,
  old section links and offline discovery.
- Distinguish source checks, isolated fixtures and live client/device acceptance.

## Tasks

- [x] Repair retired functionality claims, catalogue language and active/legacy paths.
  Update the owning manual guides, glossary, Notion assets and lifecycle references.
- [x] Separate alternative executable examples and complete Notion connection/export
  procedures using current primary sources. Keep client-specific consent explicit.
- [x] Complete native plugin installation, update, verification and recovery guidance;
  simplify README routing and add a client acceptance matrix.
- [x] Route current links directly to canonical guides. Split VS Code setup into
  task pages while retaining old anchors. Consolidate repeated instruction owners.
- [x] Add meaningful semantic documentation checks and body/heading search coverage.
  Observe focused failures before implementing the guard and reader changes.
- [x] Regenerate reviewed packages, run repository gates and pinned installer
  acceptance, then obtain one independent whole-change review.

## Evidence and decisions

Baseline: `cfca10e26724ac7f543cc6829729f8746e682d6c`, clean feature branch.

Ruling: use the established maintainer plan directory and repository checks because
companion execution helpers are absent. Existing user approval covers this plan.
Changes remain uncommitted; the audit follow-up does not request a new commit.

Kind: runbook/reference | Audience: first-time Mac developers and contributors |
Purpose: complete selected setup and maintain its documentation | Non-goals:
live workstation changes, new integrations and publication.

Focused evidence: the new contract test first failed on its missing implementation,
then on body-only search, then on a combined installer in OmniRoute. Those cases
now pass. The source gate checks current links and reviewed assets; the published
VS Code fixture preserves all 54 original rendered anchors. Lint passes.

Ruling: link the existing reviewed Notion CSV and Warp catalogue directly and
permit only their reviewed public source roots in the skill builder. Otherwise
installed guides would point outside their portable package. No new executable
integration or live installation is introduced.

Independent review identified four important findings: missing plugin anchors,
remaining Raycast command-pack guidance, empty link destinations, and obsolete
assisted database-route prose. Each was reproduced by a focused failing check
before correction. The fix pass preserves plugin anchors, routes to available
workflows and extends the contract guard to reject empty links and retired
Script Command instructions. Review did not establish live client acceptance.

Final verification: `pnpm run validate:complete` passed after the review fix pass,
including lint, static links/contracts, root integration fixtures, 23 MCP tests,
relocated production-package acceptance and native artifact validation. Skills
CLI 1.7.4 passed all 66 installation cases plus combined-client symlinks and
Git-source update/removal acceptance. Eleven packages contain 2,077 files.
All four independent-review findings have focused failing/passing evidence;
no review findings were deferred. Live integrations were not reconfigured or
reaccepted. Changes remain uncommitted and unpublished.
