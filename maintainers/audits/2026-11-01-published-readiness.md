# Published snapshot readiness and reader acceptance

**Overall readiness verdict: Not ready.** Publication, selected installation
contracts and reader interactions passed, but required recovery, accessibility,
human and device acceptance remain incomplete.

This record consolidates evidence collected on 1 November 2026 under the
[current acceptance procedure](../acceptance/CURRENT-READINESS.md). Earlier audits
retain their original findings and tested sources. No additional product defect
was reproduced in the reader checks described here.

On 1 November 2026, the repository owner confirmed macOS 26 and newer as the
intended support scope. The working-tree correction declares that floor in
[prerequisites](../../docs/shared/prerequisites.md#platform-and-evidence) and limits
the [validation matrix](../../.github/workflows/validate.yml) to macOS 26.
This correction has not been published in the revision identified below.

The partial macOS 15 AI pilot and its Command Line Tools warning remain in the
[pilot closure](2026-11-01-readiness-followup.md) as historical evidence. They are
outside current acceptance scope and do not block macOS 26+ readiness. No further
local macOS 15 testing is required. The remaining checks below still apply to
supported systems.

## Source identities and publication

[PR #17](https://github.com/CodeByKwakes/day-one-mac/pull/17) squash-merged the
reviewed source `cc1c020713a8035403ea7d41d64776ad9a3c7233` into published revision
`845f36867c361c5db12d886178b1d6060966300a`. Their Git trees matched.
The [main validation run](https://github.com/CodeByKwakes/day-one-mac/actions/runs/41299834450)
passed its hosted macOS 15 and 26 checks. The
[documentation deployment](https://github.com/CodeByKwakes/day-one-mac/actions/runs/41300092058)
then succeeded for that revision.

The published handbook snapshot recorded this content fingerprint:

```text
f36f636d7e3d0b9bde7f0d6e8b41d0fc02e9e635ce4ecefd78ce4de28eb6a776
```

Downloaded source bytes matched all 577 public sources. Each reader contained
488 matching Markdown documents. The website and offline readers matched the
reviewed handoff apart from revision metadata. Archive path, CRC and extraction
checks passed. A later browser download produced the same verified offline ZIP.

The installed Codex and Claude plugin checks retain their earlier source
`c0bc02400aa8e5c501fb1638bdfe977b32158bbe`, version 0.1.2. Those clients were not
updated to the later published documentation during these checks.

## Installation and client evidence

Five public-source Skills CLI checks passed against the reviewed source's full
40-character commit ID, using Skills CLI 1.7.4 and Node.js 24.21.0 in disposable
homes and workspaces:

1. List all 11 packages without installing one.
2. Install the main package in project scope and verify 236 files and ten workflows.
3. Install the VS Code and macOS apps specialists while preserving existing files.
4. Install the main package in disposable global scope without changing the project.
5. List installed project skills without changing their files.

Codex, Copilot and Claude installation layouts were selected. These checks used
an existing CLI launcher; they did not establish a fresh npm bootstrap or a live
request through each resulting installation. Public-source update/removal and
interactive selection were not repeated. Earlier local-source lifecycle fixtures
remain separate evidence. The
[public installation audit](2026-11-01-public-skills-installation.md) records the
earlier branch-URL failure and full-commit-ID repair.

The [installed Codex check](2026-11-01-native-codex-acceptance.md) and
[installed Claude check](2026-11-01-native-claude-installed-acceptance.md) establish
their scoped 0.1.2 updates, discovery and explicit read-only reference requests.
They do not establish every workflow, implicit activation or a clean-device
native-plugin installation.

## Reader observations

The Codex in-app browser tested the public HTTPS handbook. Selected guides were
Start here, Manual Setup, AI-assisted setup, VS Code configuration and Terminal
basics. These are live browser observations, separate from the DOM fixtures.

| Check | Observed result | Boundary |
|---|---|---|
| Routes and direct links | Both setup routes, a manual section, Back navigation and direct guide reload passed | Selected links only |
| Search | A VS Code query opened the expected guide; an unmatched query preserved chapter navigation | No human search-usability measurement |
| Narrow layout | The VS Code guide remained readable at 375 by 812; menu, Escape and Command+K worked | Viewport test, not a physical mobile device or browser zoom |
| Keyboard traversal | 38 Start here stops had focus outlines and boxes within the viewport; Enter expanded a chapter | Desktop sequence with initially collapsed optional chapters |
| Text contrast | Computed light-theme samples on Start here and Terminal basics exceeded 4.5:1; minimum 5.4662:1 | Selected text, placeholder and solid-background groups; no full WCAG claim |
| Multiline copy | The first Terminal basics example pasted into TextEdit with all 282 characters and ten line breaks intact | One public example; no command executed |
| Browser download | Download offline completed; its archive identified the published revision and fingerprint | Opening the downloaded HTML remained untested |
| Print | The user confirmed a print window appeared and cancelled it | Native dialog inspection was blocked; pages and PDF output remain unverified |

The saved TextEdit document decoded to the exact copied text. It remains in
private evidence storage. Owned browser tabs were closed and the temporary
viewport override was reset. Warning/error queries returned no entries at the
recorded completion points, without establishing console behavior on every guide.

A separate static calculation covered 40 light/dark text-palette combinations,
ten focus-colour combinations and four input-border combinations. They met the
selected contrast thresholds. Static dark-theme results do not establish rendered
dark-theme acceptance. Neither calculation nor browser sampling certifies
assistive-technology behavior.

## Remaining acceptance and operating limits

1. **Offline reader, VoiceOver, zoom and output:** local-file browsing, VoiceOver,
   200% browser zoom and rendered print/PDF output remain unverified. Use an
   approved environment that supports those checks. Preserve the current
   local-file and native Codex dialog restrictions; do not work around them.
2. **Broader browser coverage:** dark-theme rendering, forced colours, other
   browsers, physical keyboard shortcuts and every guide's keyboard sequence
   were not accepted. Selected successes do not fill those rows.
3. **Independent restore:** no independent encrypted backup destination was
   available. A verified archive is not a restored data sample.
4. **Human usability:** uncoached novice setup and advanced-user navigation remain
   deferred because no human tester was available. Agent-operated checks do not
   establish either result.
5. **Physical and managed devices:** the required hardware, ownership, network,
   elevation and recovery controls remain unverified. Clean VMs establish only
   their tested software journeys.
6. **External references and optional capabilities:** the retained link check
   found 334 reachable URLs, no 404/410 responses and eleven unverified Warp 403
   responses among 345 URLs. It exited 2. Unselected capability limits in the
   [earlier review](2026-10-31-readiness-review.md) remain in effect.

## Evidence retention and next actions

Primary evidence remains private: installer argument vectors and receipts,
publication and snapshot comparisons, browser observations, contrast values,
the native paste record, retained document and validation logs. Public records
omit account details, local paths, credentials and recovery locations.

- [x] Verify approved publication and exact public-source installation scope.
- [x] Record selected installed-client and public-browser results with their sources.
- [x] Preserve recovery material, prior failures and the local macOS 15 stop.
- [ ] Complete remaining reader checks in an available approved environment.
- [ ] Verify an independent sample restore and the claimed physical/managed controls.
- [ ] Obtain uncoached novice and advanced-user evidence when a tester is available.
- [ ] Reassess the verdict against the acceptance procedure without promoting
  untested rows to pass or treating this record as a new publication.
