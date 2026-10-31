# Cross-device readiness review

**Overall readiness verdict: Not ready.** The reviewed software routes and local
checks pass within their recorded scope, but required recovery, human and device
acceptance remain unverified.

This review records the 31 October 2026 working tree on `codex/agents-router`,
based on `ba1f516f4a18ab369a569b790157507948a3b67a`, including uncommitted fixes.
It is not a release or publication sign-off. The
[current acceptance procedure](../acceptance/CURRENT-READINESS.md) owns the gates.

## Scope reviewed and not reviewed

The final engineering pass reviewed the pending owning-source changes against
HEAD, including new tests. Generated packages were checked against their sources.
Repository-wide structural and integration checks supplement that focused review;
they do not establish line-by-line review or live execution of every guide.

Reviewed areas:

- `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `LICENSE`, `CHANGELOG.md`,
  `package.json`, plugin metadata and the documentation entry routes.
- Changed manual guides for Homebrew, skill installation, AI bootstrap,
  OmniRoute and Raycast; terminal basics, troubleshooting and AI ownership.
- `.gitignore`, `.shellcheckrc`, `skills-lock.json`, the owned maintenance skill,
  `tools/lint.sh`, `tools/check-project-layout.cjs` and affected integration tests.
- Current acceptance instructions, the readiness-fix plan, generated skill
  packages, native plugin artifacts and the website/offline export.
- Private manual, Node and AI VM observations, including interventions and
  incomplete checks. The maintainer retains the detailed `pilot-record.json`
  and the `finalEngineeringReview` evidence separately from public sources.

Not reviewed or unverified:

- No uncoached first-time person tested the guide. The user confirmed that no
  human tester is available; the prepared handoff remains deferred.
- No independent encrypted sample restore, physical spare-Mac pilot,
  minimum-macOS installation or managed standard-account journey was completed.
- Optional GUI applications, displays, device encryption/recovery, containers,
  databases, SSH/provider accounts and other unselected capabilities were not
  accepted through live end-to-end tests.
- Native plugin artifact discovery/validation does not establish a live client
  conversation. The VM exercised Codex with a manually copied skill only.
- The browser tool rejected the offline reader's local-file URL. Visual layout,
  200% zoom, real keyboard interaction, printing and VoiceOver remain unverified.
  Automated DOM fixtures passed; no alternate browser workaround was used.
- The public GitHub installation and deployed handbook were not accepted against
  this uncommitted candidate. No push or publication occurred during this pass.
- Upstream gstack internals, every third-party installer and dependency advisory,
  and historical archived runtime behavior were outside this final diff review.
  The optional global gstack runtime was unavailable; repository checks and
  native reviewers were used. No outside-provider review is claimed.

## Local validation of the corrected candidate

The following results were observed on the working tree after the manual-update
repair. Counts are validator output for this candidate, not historical totals.

| Check | Observed result | Limit |
|---|---|---|
| `pnpm run validate:complete` | Passed with native client executables supplied; includes lint, static checks, integration fixtures, plugin tests and actionlint | Temporary fixtures and artifact checks, not workstation acceptance |
| Shell and Markdown checks | ShellCheck passed all 16 owned shell scripts; Markdown lint reported no issues | Third-party gstack tree is excluded; owned sources remain checked |
| Generated assets and internal routes | 12 native adapters, 11 skill packages and 2,099 packaged files matched; links/anchors across 488 inventoried documents passed | Structural consistency, not every optional workflow's live behavior |
| Skills CLI 1.7.4 acceptance | 66 installations passed across 11 skills, three clients and two scopes; combined-client links, source removal, local Git and scoped updates passed | Disposable local sources; no public GitHub availability claim |
| Literal manual recipes | Bash/Zsh backup and manual-copy fixtures passed, including update in the original workspace | No live configuration or recovery destination changed |
| Website and native plugin build | Fresh outputs built outside the checkout; export, relocation, hashes, exclusions and no-overwrite fixtures passed | Reader visual and live plugin invocation checks remain open |
| External link checker | 345 URLs checked: 333 reachable, no HTTP 404/410, 12 unverified HTTP responses; exit 2 retained | Reachability excludes fragment/content correctness |
| Independent source review | Testing, maintainability and simplification reviewers found no further defects; the adversarial finding was repaired and re-reviewed | Native same-harness reviews; no cross-model claim |

The first restricted validation attempt failed compiling the archive AppleScript.
The unchanged isolated fixture passed with normal macOS access, followed by the
complete gate. Neither attempt changed live projects or configuration.

The link check first failed DNS resolution under restricted network access.
The approved network run produced the counts above. Its eleven Warp URLs returned
403; the Microsoft Remote SSH listing returned 503. All twelve pages were readable
through web retrieval, so none was classified as a confirmed broken destination.
The raw automated result remains unverified for those URLs.

The final public-document export fingerprint is
`700721c43843d2dc6e93ba368466e0d86b820f331f6ca1b310fcc463f6836327`.
Its revision field is unset because the source contains uncommitted changes.
Private evidence retains individual source and log hashes.

`LICENSE` and `templates/plugins/metadata.json` agree on MIT licensing.
Contributor tooling remains version `1.5.0`; native plugin metadata is `0.1.2`.
These are separate version domains, documented in
[plugin packaging](../../docs/shared/reference/plugin-packaging.md).
`CHANGELOG.md` explicitly records historical runtime releases and routes current
guide changes to the [upgrade notes](../../docs/shared/upgrade-notes.md).

## Clean-VM software observations

These are historical observations of the transferred pilot kit, whose source
fingerprint was `dc8c820d984ef361f7eddd9fc5420cfbedd089d9faed3e0dfc3c49af7f917cd2`.
They do not certify the later guide fixes or the final export above.

Both journeys used native arm64 macOS 26.6.2, build 25G83, in separate UTM guests
with 6 GB RAM and a 64 GB virtual disk. The untouched baseline was retained.
The [documented platform floor](../../docs/shared/prerequisites.md#platform-and-evidence)
is macOS 15 on native Apple silicon. macOS 15 was not tested by this pilot;
CI configuration alone does not fill that acceptance row.

| Route | Observed pass | Intervention or remaining limit |
|---|---|---|
| Manual core and Python | Apple tools, Homebrew, Git/jq/ripgrep, Apple Zsh and uv; PyPA sampleproject build, Twine and one test passed before and after restart | Nox 2026.10.20 failed on the project's `needs_version`; project-local Nox 2024.3.2 passed with Python 3.13.18 |
| Manual Node selection | fnm 1.39.0, pnpm 12.16.1, Node 26.13.0 and npm 11.20.0; fresh terminal checks and tinyqueue lint/four tests passed | Added after Python; no independent Node-only baseline, post-Node restart or pnpm project installation |
| AI bootstrap | Native Codex 0.166.0 before usable Git/Node; manual skill copy, discovery, ChatGPT sign-in, harmless response and bounded reads | User completed account and password steps; this was agent-operated |
| AI core and Python | Scoped Apple tools, Homebrew, Apple Zsh and uv; PyPA build, Twine and one Python 3.13.18 test passed before and after restart | Reviewer corrected proposed shell failure handling before execution and supplied the earlier Nox finding; no autonomous or uncoached acceptance |

Homebrew reported an outdated Command Line Tools/Tier 2 warning in both guests.
Selected binary packages worked, but no source-build acceptance is implied.
The available update listing did not offer a separate CLT update; no OS upgrade
or developer-directory deletion was performed. The AI Homebrew confirmation
preview was not observed during the password handoff and remains unverified.

The tinyqueue pilot reported eight development-dependency vulnerabilities,
including one high severity; its production-only audit reported zero.
No advisory analysis or forced dependency repair was performed. These are
sample-project observations, not Day One Mac dependency findings.

The VM sessions ended with normal shutdown. No independent encrypted backup
destination was available, so restore acceptance remains unverified by the
user's explicit choice.

## Critical issues that block use

No remaining blocking code or instruction defect was confirmed in the final
reviewed changes. This does not establish complete readiness: the required
acceptance gaps below prevent the broader claim.

## Important issues and recommended actions

1. **Incomplete acceptance:** [Current readiness > Complete clean-device pilots](../acceptance/CURRENT-READINESS.md#complete-clean-device-pilots)
   requires human, recovery and relevant OS/device evidence. Keep those rows
   unverified. The maintainer can preserve the engineering results now and defer
   unavailable checks without inventing a replacement human result.
2. **Different candidate identities:** the VM kit predates the Homebrew command
   cache and skill-installation wording fixes. Use the final reviewed artifact
   for the next pilot and record its fingerprint. Do not transfer the old kit's
   live passes to the corrected candidate.
3. **Interventions affected completion:** the VM results required reviewer help,
   a project runner pin and explicit human handoffs. Keep these in future
   acceptance summaries; repeat the affected routes before claiming that a
   novice can complete them without help.
4. **Reader acceptance is incomplete:** [Reading and export](../../docs/shared/reading-and-export.md)
   and the acceptance procedure distinguish DOM fixtures from real browser and
   assistive-technology checks. Complete those checks in an available approved
   environment before claiming accessible offline-reader acceptance.

## Resolved findings

| Finding | Owning repair | Verification |
|---|---|---|
| Fixed-name backups could overwrite recovery evidence or hide copy failures | [Terminal configuration walkthrough](../../docs/shared/terminal-basics.md#create-or-edit-a-configuration-file); OmniRoute and Raycast route through it | `test-manual-config-backup.cjs`: distinct generations, permissions, absence, copy failures, unsupported targets and Unicode |
| Optional gstack failed contributor ownership/lint assumptions | [CONTRIBUTING](../../CONTRIBUTING.md#optional-repo-local-gstack), lock, exact dependency exclusion and owned-skill checks | `test-ai-components.cjs` and full lint; owned and unreviewed scripts remain included |
| Manual skill verification required Node and lacked a distinct lifecycle | [Manual copy](../../docs/setup/manual/ai/day-one-skills.md#install-by-manual-copy-without-node-or-git), file checks, update and removal | `test-manual-skill-copy.cjs`: no npx, collisions, source independence and Claude link |
| Manual update repeated fresh-workspace creation, abandoning the old installation | [Manually copied installations](../../docs/setup/manual/ai/day-one-skills.md#manually-copied-installations) returns to the recorded workspace and repeats only the copy step | Bash/Zsh update fixture preserves the prior package and existing client link; independent re-review passed |
| A current terminal could keep selecting Apple Git after Homebrew installation | [Homebrew core tools](../../docs/setup/manual/homebrew.md#8-install-the-shared-command-line-tools) adds `rehash` and explicit path checks | Generated packages match; no new clean-VM pass claimed for the wording change |
| Optional routes described Raycast or OrbStack as universally required | OmniRoute, Raycast and AI client guides distinguish selected owners and routes | Source review and structural checks; live optional-provider acceptance remains open |

## Minor issues

1. The twelve access-limited external URLs require an exception record when
   consuming automated link results. Retain their raw statuses and retrieval
   evidence; do not weaken the checker to treat all 403/503 responses as passes.
2. The existing spare-Mac handoff was prepared before the tester became
   unavailable and before the final update repair. Preserve it as historical
   evidence, then generate a fresh handoff when an actual pilot is scheduled.

## Missing evidence and recommended tooling

The repository already provides setup, prerequisites, troubleshooting, removal,
advanced reference, contributing and recovery material. The missing material is
acceptance evidence:

- A first-time-person walkthrough and an experienced-user navigation record.
- A sample restore from an independent encrypted destination.
- Exact-candidate minimum-OS, physical-device and relevant managed-device records.
- Real reader accessibility results and selected live plugin/client results.
- Published-source, deployed-reader and downloaded-artifact comparisons after
  a separately approved publication.

As a follow-up, consider a small acceptance-record validator that checks candidate
identity, route, result, intervention and evidence reference fields. It should
reject a complete status when required rows are unknown. Such a tool can enforce
record completeness; it cannot establish that a human or device check occurred.

## Checklist to reach ready

### Priority 1: preserve the engineering result

1. [x] Repair the confirmed documentation and tooling defects and regenerate packages.
2. [x] Complete repository checks, pinned Skills CLI acceptance and native artifact checks.
3. [x] Record external-link exceptions, reviewer interventions and distinct candidate identities.
4. [ ] Review and commit the prepared changes when authorized; retain private evidence separately.

### Priority 2: fill acceptance gaps when resources exist

1. [ ] Rebuild the pilot handoff from the committed candidate and verify its fingerprint.
2. [ ] Complete missing selected software checks, including Node restart, against that candidate.
3. [ ] Test an independent sample restore when a suitable destination becomes available.
4. [ ] Run the minimum-OS and physical-device routes, plus managed-device checks where claimed.
5. [ ] Run a first-time-person walkthrough when a tester is available; record all coaching.
6. [ ] Check advanced-user navigation, real reader accessibility and selected live plugins.

### Priority 3: verify distribution

1. [ ] Obtain separate publication authorization and verify the exact published sources and artifacts.
2. [ ] Sign off only the completed routes and capabilities, with evidence date and unresolved items.

Until the deferred resources exist, retain the limited software-pilot result and
the overall **Not ready** verdict. An AI walkthrough cannot close human-usability
acceptance, and another local copy cannot establish independent backup recovery.
