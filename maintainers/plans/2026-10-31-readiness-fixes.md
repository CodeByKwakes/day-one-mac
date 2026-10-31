# Documentation readiness implementation plan

> Execute inline with the executing-plans skill; obtain one independent review
> after implementation and verification.

**Goal:** resolve the actionable documentation audit findings and make remaining
publication and device acceptance work explicit.

**Architecture:** keep commands in their canonical manual guides. Extend shared
beginner and acceptance guidance, regenerate portable packages, and add bounded
contributor checks without introducing an installed runtime.

**Tech stack:** Markdown, Node.js 22.20+, macOS Bash 3.2, pinned Skills CLI 1.7.4.

**Spec:** the 31 October 2026 readiness review in the approving chat. Its scope is
the installation prerequisites, published-source mismatch, shell checks, beginner
editing, plugin acquisition, stale references, acceptance records and link QA
listed below. Publication and live-device pilots require their own execution scope.

## Constraints

- Preserve the current MCP archival changes and historical records.
- Keep normal manual setup independent of project helpers and a permanent checkout.
- Keep private notes, fixture outputs and package artifacts outside the repository.
- Preserve guide URLs and regenerate all affected skill snapshots.
- Do not commit, publish, change client registrations or configure the live Mac.

## Review focus

- A native AI client and Node installation without Git must have a complete next step.
- Apple Zsh with no optional alias file must pass the applicable syntax checks.
- A beginner must be able to save and recover a plain-text configuration file.
- An older public snapshot must not be mistaken for the reviewed local package.
- Link checking must exclude local/example endpoints and report inaccessible pages honestly.

## Tasks

### 1. Correct setup prerequisites and lifecycle instructions

- [x] Update README and the skill guide with Git checks and source selection.
- [x] Correct chezmoi shell validation and the obsolete workspace-export instruction.
- [x] Correct workflow counts, Warp wording, failed references and changelog context.
- [x] Exercise the documented shell check with required, optional and invalid fixture files.

### 2. Complete beginner, distribution and acceptance guidance

- [x] Extend terminal basics with private backup, built-in editor, syntax and recovery steps.
- [x] Add a minimal first-time path, capability prerequisites and copyable acceptance record.
- [x] Document source archives and contributor-supplied plugin ZIPs with checksum verification.
- [x] Add a current maintainer acceptance checklist beside historical acceptance material.
- [x] Check contained references and offline-reader navigation after source changes.

### 3. Add contributor checks for the observed failures

- [x] Add focused regression coverage for skill prerequisites and obsolete export guidance.
- [x] Add an opt-in external-link checker with injected fetch fixtures for failures,
      exclusions, redirects and bounded requests; keep the offline gate network-free.
- [x] Document its command and interpretation in CONTRIBUTING.md.

### 4. Regenerate, verify and review

- [x] Regenerate reference and skill outputs.
- [x] Run the full gate, native plugin checks and pinned Skills CLI acceptance.
- [x] Build a reviewable plugin ZIP outside the repository and verify its checksum.
- [x] Obtain an independent review and address material findings.
- [x] Report local evidence separately from publication and clean-device acceptance.

## Local completion evidence

The local corrections passed verification on 31 October 2026. The current
public release and clean-device journeys remain separate acceptance work under
[CURRENT-READINESS.md](../acceptance/CURRENT-READINESS.md).

- `pnpm run validate:complete` passed, including ShellCheck, Markdown lint,
  static references, integration fixtures, native artifact fixtures and actionlint.
- Generated packages verify: 11 skills, 2,088 files; static validation checks
  links/anchors across 488 documents and validates 295 aliases.
- Skills CLI 1.7.4 passed 66 isolated installations across 11 skills, three
  clients and two scopes, plus reinstall, update, removal and local Git-source checks.
- Approved native CLI checks passed for Claude Code 2.1.308 and Codex 0.165.0.
  These establish package validation/discovery, not account-backed invocation.
- Documented Apple Zsh checks passed with absent optional files and rejected
  invalid files without executing startup content. Beginner backup/recovery
  examples passed in Apple Bash and Zsh with spaces and Unicode paths.
- The documented native-plugin ZIP and receiving procedure produced matching
  extracted/copied trees and refused an existing destination. The offline guide
  and website share the same content fingerprint.
- The live link checker reported 344 destinations: 330 reachable, zero HTTP
  404/410 responses and 14 unverified responses (11 access refusals, three
  timeouts). The three timed-out Zsh pages were subsequently readable through
  web lookup; the automated report remains unchanged.
- A browser smoke check passed direct guide anchors, body-text search, keyboard
  selection/focus, narrow rendering and line wrapping. Copy feedback appeared;
  the browser tool's virtual clipboard could not verify the native copied text.
  Print, 200% zoom and VoiceOver acceptance remain untested.
- Independent review found two editing-guide issues: ancestor inspection used
  the wrong parent for SSH files, and recovery lacked concrete commands. Both
  were corrected and exercised before final validation.

No clean-device provisioning, managed-device pilot, live client invocation,
physical restore, commit, push or publication was performed. Local fixtures do
not establish that every supported device or account-backed workflow works.
