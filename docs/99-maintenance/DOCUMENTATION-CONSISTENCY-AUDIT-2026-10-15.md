# Documentation consistency audit — 15 October 2026

## Scope and conclusion

**Original audit result:** nine documentation/contract findings: one high,
seven medium and one low priority. The findings below preserve the baseline
observations and line references; see **Implementation status** for remediation.
They are not proof of a compromised or noncompliant workstation.

This explanation-led report is for maintainers and administrators of personal
and managed Macs. It uses the previously approved audit structure. The baseline
is source commit `4fbd145b85ce4a2bb1ad808a265006fb79e2bc0d`. At audit time the installed
runtime was `1.5.0-local.20261015-audit.29cc299`; it predates the VS Code profile
generator commit. Source and installed runtime must not be treated as identical.

The inventory covers **168 tracked first-party Markdown files**: 109 under
`docs`, 51 under `second-brain`, six at repository root, one under `config` and
one under `warp-drive`. Agent skill libraries, dependencies and vendor material
are excluded from product-document scope. Corpus-wide structural checks were
combined with targeted semantic comparisons of setup, security, command,
application, recovery, release and maintenance instructions against code and
configuration. This is not a claim that every prose statement was independently
verified or every command executed.

## Commit follow-up — `3f8ff20`

Reviewed on 15 October 2026 against the original audit baseline. Commit
`3f8ff207cb890819fb691d3b4c77de097d6c5f4e` adds 27 lines to
[VS Code profiles](../10-app-guides/VSCODE-PROFILES.md): shared Copilot
Conventional Commit instructions and usage guidance. **D01–D09 remain open;
their priorities and the implementation plan are unchanged.**

Although only Markdown changed, that guide supplies data to the profile
generator. Newly generated Default, Full Stack, AI and Operations bundles all
include the five instruction entries. Their suggested types are accepted by
the repository's commitlint configuration, and the preferred 72-character
subject fits its 100-character maximum. Both automatic tool-approval settings
remain disabled. Existing profiles require the documented manual merge/import;
the commit does not itself apply editor settings.

The profile-generator fixture suite passed again, including actual bundle
generation and mock CLI checks. Additional read-only assertions confirmed the
new instructions in all four recipes and their local commit-rule compatibility.
Markdown lint passed for 140 files, including this report. Live Copilot behavior
and the external setting reference were not independently revalidated.

At that follow-up the runtime still reported `1.5.0-local.20261015-audit.29cc299`,
so D05's availability gap remained. This follow-up extends the evidence only for the
changed guide and generated profiles; original inventory and validation counts
below continue to describe the original audit baseline.

## Implementation status

The user subsequently authorized implementation and commit of the recommended
fixes. Repository changes address all nine findings; external acceptance is
listed separately so local checks are not mistaken for operational certification.

| Finding | Implemented correction | Remaining operational acceptance |
|---|---|---|
| D01 | Shared personal/managed acceptance matrix; account/update/Homebrew/preference branches; deployment selectors and evidence state documented | IT-approved managed policy and a real standard-account walkthrough |
| D02 | FileVault/Gatekeeper explicitly non-waivable in readiness and both routes, preserving existing final-phase gates | Owner review and actual device checks |
| D03 | Current Phase 8 prerequisites aligned across direct/module commands; saved choices distinguished from stale completion | Existing users review status and revalidate affected phases |
| D04 | All four first-apply examples include disposable-data consent; resume and synthetic-data limits explained | Actual engine and workload acceptance |
| D05 | Public `vscode-profile` entry point; installed-runtime instructions; bundle scope/availability table; current Phase 8 before extension installation | Roll out a runtime containing this commit; review/import generated settings manually |
| D06 | Stable `validate` aggregate requires successful macOS 15 and 26 jobs, including failure/cancel/skip handling; protection guide aligned | Repository administrator verifies emitted check, ruleset and a failed-platform PR in GitHub |
| D07 | Draft/candidate/validation/attestation/publication lifecycle and `draft_tag` retry documented across release guides | Live failed-draft and retry rehearsal; no public release performed by this remediation |
| D08 | Manual and Phase 8 checklists respect preset, authentication, configuration and prompt selections | Fresh-user walkthroughs with both minimal and productivity selections |
| D09 | Older audit labelled historical with revision boundary; maintenance index links current audit and implementation evidence | Refresh evidence when behavior or policy changes |

### Remediation validation — 15 October 2026

These checks cover the remediation developed over `3f8ff20`; the original audit
counts further below remain historical.

| Check | Result and boundary |
|---|---|
| Full project validator | Completed with one sandbox-only failure: the SSH fixture could not bind its temporary Unix socket. Every other check passed, including all 96 selection plans. The complete SSH fixture then passed outside the sandbox; the sandbox invocation itself still returned 1 |
| Focused readiness and workflow tests | 13 passed, including FileVault/Gatekeeper exception refusal and aggregate CI failure/cancellation/skip handling |
| Shell/Markdown lint and workflow syntax | 141 shell scripts and 140 Markdown files passed; `actionlint` and patch whitespace checks passed |
| Local references and JSON examples | 1,446 local file/heading references resolve; all 31 JSON examples parse |
| Documentation export/reader | Passed after preserving the older manual-guide heading bookmark; offline navigation and privacy fixtures pass |
| Profiles | All four bundles retain commit instructions and disabled auto-approval; missing Phase 8 blocks extension installation before writes; mock CLI tests pass with current fixture state |
| Packaged runtime | Installation/integrity and 15 capabilities passed, including profile export from outside a checkout using the installed command |
| Database instructions | All five first-apply examples across the two owning guides include disposable-data consent |

The new audit and the earlier technical/implementation records are now included
in the runtime manifest so their index links work in offline exports. Live
GitHub rules/publication, actual editor import and managed-device pilots remain
outside these local results. Local rollout uses a distinct version label tied
to the remediation commit and retains the previous runtime; use `runtime-status`
to inspect the active version. Updating the runtime does not apply workstation
setup, install extensions, import settings or approve a managed policy.

## Audit Findings

### D01 — High: managed-device requirements are missing from older routes

**Revise:** [Manual setup](../20-reference/MANUAL-SETUP-GUIDE.md),
[Process overview](../PROCESS-OVERVIEW.md),
[Phase 2](../01-required/02-command-line-foundation.md),
[macOS settings](../01-required/MACOS-SETTINGS.md),
[Module 19](../03-advanced/19-macos-gui-and-local-https.md),
[Command reference](../20-reference/COMMAND-REFERENCE.md) and
[Architecture/state](../20-reference/ARCHITECTURE-AND-STATE.md).

The manual guide requires an administrator account (line 51) and every available
OS update (182–183), whereas the [readiness contract](../20-reference/WORKSTATION-READINESS.md)
requires a managed daily standard account and an approved update policy
(19–32). Phase 2 tells readers to approve Homebrew bootstrap; managed execution
refuses it (`scripts/phases/02-foundation.sh`, 72–75). Settings guides omit the
managed apply prohibition. The manual completion checklist omits firewall, SIP
and equivalent current recovery/policy evidence. Setup selectors and state
reference sections also omit the new deployment selection.

**Impact:** managed users following manual instructions can diverge from IT
policy; assisted users encounter undocumented stops. The runtime guards remain
present. **Action:** introduce personal/managed branches before account, update,
Homebrew and preferences steps; use one shared acceptance-control matrix without
requiring scripts on the manual route. Correct the claim that Phase 1 installs
OS updates: that work is manual. **Effort:** 4–6 hours plus IT review.

### D02 — Medium: security-exception outcomes are ambiguous

**Revise:** [Readiness](../20-reference/WORKSTATION-READINESS.md),
[manual security](../manual/security.md) and
[Phase 8](../01-required/08-verify-and-reproduce.md).

Readiness permits a current approved exception to supersede an automatic failure
(lines 124–139); its implementation accepts `EXCEPTION` as ready. However,
Phase 3 independently requires FileVault, and Phase 8 independently requires
FileVault and Gatekeeper (`03-security.sh`, 617–620; `08-verification.sh`,
437–439). An accepted readiness exception therefore need not permit setup
completion. **Impact:** contradictory acceptance evidence and blocked onboarding;
no bypass was demonstrated. **Action:** define which controls are non-waivable
in each route, then align policy documentation and phase behavior. Add a fixture
covering both readiness and the final phase. Do not weaken a security check merely
to match wording. **Effort:** 2–4 hours after a security-owner decision.

### D03 — Medium: prerequisite documentation contradicts execution

**Revise:** [Module execution](../20-reference/MODULE-EXECUTION.md),
[Module 12](../02-optional/12-vscode-profiles.md) and
[macOS settings](../01-required/MACOS-SETTINGS.md).

Module execution says the direct CLI installer has no Phase 8 gate (76–79), but
`scripts/configure-cli-tools.sh:316` requires a **current** Phase 8 fingerprint.
Module 12's header says Phase 7; its apply procedure requires Phase 8. The settings
guide's blanket assurance that upgrades do not reset completed phases obscures
the documented invalidation of stale fingerprints.

**Impact:** at least two contradictory prerequisites and misleading upgrade
expectations. **Action:** publish a shared preview/check/apply/resume prerequisite
table, distinguish saved choices from current verification, and state the
Module 12 Phase 8 prerequisite specifically for assisted apply. **Effort:** 1–2 hours.

### D04 — Medium: four database apply examples omit required consent

**Revise:** [Optional setup](../02-optional/README.md), line 70, and
[databases](../02-optional/09-databases.md), lines 59, 74 and 76.

These first-apply examples omit `--disposable-data`; the same database guide's
opening example correctly includes it. Without prior saved acknowledgement,
`scripts/configure-databases.sh:545–548` stops with exit 10.
**Impact:** all four examples fail for a fresh selection; the synthetic-data-only
restriction is easy to miss. **Action:** include explicit acknowledgement and
the fixed-credential restriction in every first-apply path. Explain that resume
may reuse previously saved acknowledgement. Test extracted examples against
isolated fixtures. **Effort:** 1 hour.

### D05 — Medium: new profile instructions lack a versioned entry point

**Revise:** [VS Code profiles](../10-app-guides/VSCODE-PROFILES.md) and
[Module 12](../02-optional/12-vscode-profiles.md).

The four new generators are bundled in source but absent from this Mac's active
runtime. Lines 60–79 assume a "Day One Mac directory" and use relative scripts
without explaining how a standalone-runtime user reaches them. Module 12 creates
an extension-only bundle, while the new generators also include settings and
keybindings; the relationship needs an explicit explanation.

**Impact:** four unavailable generator commands for the installed version and
ambiguous artifact expectations. **Action:** label availability by source commit
or released version, document a tested installed-runtime entry point, and compare
the two bundle types. Verify from outside a checkout before declaring availability.
**Effort:** 2–3 hours; deployment remains a separate action.

### D06 — Medium: branch-protection instructions predate matrix validation

**Revise:** [Main protection checklist](../MAIN-PROTECTION-CHECKLIST.md),
lines 128–136 and 245–248.

It instructs maintainers to require a single `validate` check. The
[workflow](../../.github/workflows/validate.yml) now expands that job across
`macos-15` and `macos-26`, with no explicit aggregate job. The guide no longer
establishes the exact check contexts to require. Live GitHub rules were not read.
**Impact:** following an incorrect check name can block merges or fail to require
both platform results; actual protection failure is unproven. **Action:** inspect
the contexts emitted by a test PR, then document both exact names or implement a
stable aggregate gate that fails when either matrix leg fails. **Effort:** 1–2 hours
plus CI time.

### D07 — Medium: release and retry procedures omit the new lifecycle

**Revise:** [Git workflow](../GIT-WORKFLOW.md),
[release token setup](../RELEASE-TOKEN-SETUP.md),
[main protection checklist](../MAIN-PROTECTION-CHECKLIST.md) and
[candidate notes](RELEASE-CANDIDATE.md).

The publication summaries omit draft creation, immutable candidate validation,
exact-archive testing, provenance and guarded publication now present in
[`release.yml`](../../.github/workflows/release.yml). The retry procedure omits
`draft_tag`; only the newer implementation record explains it. Candidate notes
also need qualification around stale Phase 8 evidence and database consent.
**Impact:** uncertain release status and recovery steps after a failed candidate.
**Action:** document the complete state sequence and failed-draft retry, expected
evidence and compatibility changes. Rehearse failure/retry in GitHub before claiming
the live publication path is proven. **Effort:** 2–3 hours plus CI time.

### D08 — Medium: completion checklists contradict supported choices

**Revise:** [Manual setup](../20-reference/MANUAL-SETUP-GUIDE.md),
lines 140–141 and 1141–1157, and [Phase 8](../01-required/08-verify-and-reproduce.md),
lines 17–18 versus 63–65.

Manual completion requires SSH, chezmoi, Starship and desktop applications despite
supported HTTPS, unmanaged configuration, unchanged prompt and core selections.
Earlier caveats do not consistently carry into the final checklist. Phase 8 calls
Raycast/Warp required before later excluding them for core.
**Impact:** false failures or unnecessary installations across four independent
choice dimensions. **Action:** make each checklist item selection-dependent and
define a valid "not selected" outcome. Test core/HTTPS/unmanaged/no-Starship and
productivity/SSH/chezmoi/Starship walkthroughs. **Effort:** 1–2 hours.

### D09 — Low: historical assurance is presented without a bounded baseline

**Revise:** [25 September audit](DOCUMENTATION-AUDIT.md).

It describes 125 files, calls itself "current-state" and covers "1.0.6 and later"
(lines 3–12). Its historical measurements are valid as historical evidence, but
cannot establish current consistency for 168 files and changed behavior.
**Impact:** readers can mistake old assurance for current verification.
**Action:** label it superseded, bind its findings to the audited revision and
retain its original measurements. The maintenance index has been updated with
this report and a historical label; the older report itself remains unchanged.
**Effort:** under 1 hour.

## Improvement Recommendations

Resolve D01 first, then the acceptance/command contradictions D02–D04 and D08.
Before the next release, resolve D05–D07. Close D09 alongside that documentation
update. Keep canonical policy, command and completion tables in their owning
references; have tutorials link to them and include the necessary route-specific
steps. Structural lint alone cannot catch these semantic disagreements.

## Implementation Plan

| Phase | Actions and owner | Estimate | Acceptance and risk control |
|---|---|---|---|
| 1 — Acceptance contract | Maintainer and IT/security owner resolve D01–D02 and D08; define managed/manual outcomes and non-waivable controls before editing procedures | 1–1.5 working days | Personal and managed walkthroughs agree with policy and final checks; preserve security guards and script-free manual instructions |
| 2 — Commands and release | Maintainer fixes D03–D07; verifies fresh-state examples, installed-runtime entry points, CI contexts and failed-draft retry | 1–1.5 working days plus CI access | Documented examples pass fixtures or stop for the documented reason; both OS results required; failed candidate remains a draft |
| 3 — Evidence maintenance | Maintainer closes D09, reruns documentation checks and adds focused regression assertions for the corrected contracts | 0.5–1 working day | Date/commit-bound report, no broken links, matching prerequisites; security owner reviews any changed acceptance semantics |

Allow **2.5–4 working days**, excluding policy decisions, unavailable pilot Macs
or GitHub access. Estimates are planning ranges, not measured implementation
times. Required resources are one maintainer, part-time security/IT review, a
managed test Mac and a repository administrator for live CI verification.

## Validation and evidence limits

Checks run against the audit baseline:

| Check | Result |
|---|---|
| Parsed local file/heading references | 1,395 checked; no broken targets found |
| Configured Markdown lint scope | 139 files; zero issues |
| Fenced `json` examples | All 31 parse; this does not validate application schemas |
| Offline documentation export and reader | Passed, including links, privacy, no-overwrite and DOM navigation/search fixtures |
| VS Code generators | Passed bundle, merge, selection, safe-output and mock-CLI tests; no live editor import performed |
| Obsidian | Source validator and isolated setup/manager fixtures passed, including starter-vault wikilinks |
| Notion | Isolated local setup-plan fixture passed; no cloud workspace inspected |

The corpus contains 466 external references and 106 wikilinks. External links,
vendor feature/version claims and latest Apple guidance were not revalidated in
this local audit. Obsidian's dedicated checks cover starter-vault semantics, not
every possible user-created note. No full-project, live MDM, hardware, GUI,
recovery or GitHub publication test was performed for this report; earlier
technical-audit evidence remains tied to its own baseline.

No named organizational compliance standard was supplied. Local attestations and
passing fixtures cannot certify regulatory compliance. Full acceptance requires
an approved control mapping and retained operational evidence, as described in
[workstation acceptance](../04-operations/WORKSTATION-ACCEPTANCE.md).

The initial audit added the report and index only. The later implementation is
recorded above; historical findings and measurements are retained for traceability.

---

[Maintenance index](README.md) · [Documentation index](../README.md)
