# Readiness follow-up and macOS 15 pilot closure

**Overall readiness verdict: Not ready.** Selected manual software checks and AI
bootstrap passed on macOS 15, but the AI setup route and required recovery,
human and device acceptance remain incomplete.

This dated record supplements the [31 October review](2026-10-31-readiness-review.md).
The [current acceptance procedure](../acceptance/CURRENT-READINESS.md) owns the
requirements. The user ended further macOS 15 testing on 1 November 2026.
Remaining rows stay unverified; resuming that OS requires a new user instruction.

## Scope and evidence

The macOS 15 guests used the committed public handoff from
`e91981f24795c3fa5ccc1e926f397cb3853663f9`. Its documentation fingerprint was
`700721c43843d2dc6e93ba368466e0d86b820f331f6ca1b310fcc463f6836327`.
Separate full copies of a preserved clean baseline ran macOS 15.8.2,
build 24H232, on native arm64. Only one guest ran at a time.

The local follow-up commit `bda6a07fcac85a1291a3a12f4368a4f3c3ef06fb`
corrected optional shell reference files and their generated skill copies.
It was not transferred into the guests. The canonical shell and AI bootstrap
guides used by the pilot were unchanged.

Guest results below are visual observations transcribed into private records.
Raw guest terminal logs and numeric exit statuses were not exported. The final
Apple installer completion is user-reported and has no post-install check.
Repository validation logs are separate evidence from these live observations.

| Area | Observed result | Boundary |
|---|---|---|
| Manual core | Apple developer tools, Homebrew, Git/jq/ripgrep and user-owned Apple Zsh setup passed selected checks | Homebrew's newer-CLT warning remained unresolved |
| Manual Python | uv-managed Python and PyPA sampleproject build, Twine checks and one test passed before and after restart | Project used Python 3.13.18 and project-local Nox 2024.3.2 after the newer runner failed its version constraint |
| Manual Node | fnm-managed Node 26.13.0, npm 11.20.0 and pnpm 12.16.1 resolved in fresh terminals; TinyQueue lint and four tests passed after restart | Existing Python project also passed; no independent Node-only baseline or pnpm project install |
| AI native bootstrap | Codex CLI 0.166.0 installed before developer prerequisites; a fresh terminal resolved it | User completed ChatGPT sign-in |
| AI skill and provider | Manual skill copy, actual reads of the installed entry/workflow, a live response, and bounded `pwd`/`uname -m` commands passed | Agent-operated; manual copy rather than native plugin installation |
| AI developer setup | Reviewed plan and scoped `xcode-select --install` launch observed; user reported installer completion | Post-install verification, Homebrew, shell, language projects and restart checks were not completed |
| Earlier macOS 26 Node continuation | Fresh-terminal Node ownership and TinyQueue lint/four tests passed after restart | Existing guest; Node guide matched the committed candidate, but the new handoff was not installed there |

The maintainer retains the primary records outside the public repository:
`manual-node-post-restart.json`, `ai-bootstrap-result.json`,
`ai-apple-tools-start.json`, `ai-pilot-stop.json` and
`node-post-boot-results.json`, with their related preparation records.
These records identify the tested source, interventions and unresolved checks.

## Corrected shell references and local validation

The shell reference in `templates/phase-05-shell-files/home/.zshrc` lacked the
canonical guide's Warp guards around completion and optional shell plugins.
Its README also assumed Homebrew Zsh and an unconditional Node selection.
Commit `bda6a07` aligns the reference with the
[owning Zsh guide](../../docs/setup/manual/shell/zsh.md) and routes verification
through the selected tools.

The retained `follow-up-shell-reference-drift.json` records the repair and
validation. `shell-reference-validation-normal-access.log` records the full
`pnpm run validate:complete` pass. `shell-reference-skills-cli.log` records
Skills CLI 1.7.4 acceptance, including 66 installations across 11 skills,
three clients and two scopes.

The initial restricted run failed at AppleScript compilation. The unchanged
focused fixture and complete gate passed with normal compiler access.
Optional Warp behavior was not tested live, and no publication occurred.

## Remaining findings and acceptance limits

No new blocking instruction defect was confirmed after the shell repair.
The following gaps prevent a complete readiness claim:

1. The macOS 15 AI route covers bootstrap only. Its reviewed plan and the
   user-reported Apple installer completion do not establish a working
   development environment. Retain partial status and the user's stop instruction.
2. Homebrew's developer-tools warning remains unresolved in the selected
   guests. Successful binary-package checks do not establish source-build support.
3. Independent encrypted restore, uncoached novice usability, advanced-user
   navigation and physical/managed-device acceptance remain unverified.
4. Reader visual interaction, printing and VoiceOver remain unverified after
   the local-file browser restriction recorded in the earlier audit.
5. Live native-plugin invocation and exact published-source acceptance remain
   open. Local package fixtures and manually copied skill discovery do not close
   those checks.

Optional applications, providers, containers, displays and other unselected
capabilities retain the exclusions in the earlier review. TinyQueue's reported
development-dependency advisories were not investigated or repaired.

## Maintainer checklist

1. [x] Preserve committed fixes, validation logs and source-specific pilot evidence.
2. [x] Record the macOS 15 stop instruction and distinguish user reports from observed checks.
3. [ ] Prepare a distribution handoff from the selected final commit, preserving these limits.
4. [ ] Complete reader and selected native-plugin acceptance in an available approved environment.
5. [ ] Leave unavailable recovery, human and device checks open; do not resume macOS 15 testing without a new instruction.
6. [ ] Obtain separate publication authorization before pushing or publishing, then verify the exact public artifacts.
