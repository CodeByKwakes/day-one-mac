# Public Skills CLI installation acceptance

**Installation from the exact published commit passed in isolated destinations.**
The check also reproduced a branch-URL limitation and corrected the guide to
recommend a full commit ID. Overall readiness remains **Not ready** under the
[current acceptance procedure](../acceptance/CURRENT-READINESS.md).

## Source and isolation

On 1 November 2026, the approved branch publication made
`b9f663f682ed5f5d7c60bf76f7e9410dc5f8a478` available on GitHub. A public archive
check matched all 2,099 files across its 11 skill packages. Remote `main` stayed
unchanged; no pull request, workflow run or deployment accompanied that check.

The installer checks used the already reviewed Skills CLI 1.7.4 launcher with
Node.js 24.21.0 and working Git. Each probe had a private home, workspace and
temporary directory. Credentials were not forwarded, telemetry was disabled and
each command had a 90-second limit. Global scope referred only to a disposable
home. No active client installation or provider was used.

## Observed contracts

| Contract | Result | Evidence boundary |
|---|---|---|
| Public catalogue at the full commit ID | All 11 packages listed; no package installed | The URL selected the published `skills/` directory |
| Main package, project scope | All 236 files and ten bundled workflows matched; Claude link stayed inside the fixture | Codex, Copilot and Claude Code destinations were selected together |
| VS Code and macOS apps specialists | Both 182-file packages matched; main package, unrelated marker and private note survived | Project scope only |
| Main package, global scope | Same package and contained Claude link; project directory remained empty | Disposable home, not the real account |
| Installed project listing | Main and both selected specialists appeared; installed files were unchanged | No client discovery or provider request |

The repository's existing `validatePackage` helper checked package hashes and
contained Markdown references. CLI temporary clones were removed. Its normal
Node compile cache remained inside each private temporary directory.

The first main-install test returned zero but an overly broad test assertion
treated that compile cache as a retained source checkout. Inspection of
`bin/cli.mjs` confirmed its `module.enableCompileCache()` call. The corrected
test allowed that cache and repeated discovery and installation in fresh fixtures.
The original failure and replay records remain preserved as test-setup evidence.

## Confirmed URL defect and documentation repair

The installation guide previously recommended a tree URL for any published
branch, tag or commit. With the branch `codex/agents-router`, CLI 1.7.4 selected
ref `codex` and subpath `agents-router/skills`. Two fresh read-only discovery
attempts exited 1 with `Remote branch codex not found in upstream origin`.
No skill was installed by either attempt.

The installed CLI's `parseSource` implementation takes only the first segment
after `tree/` as the ref. The [owning guide](../../docs/setup/manual/ai/day-one-skills.md#install-from-github)
now asks for the full 40-character published commit ID, states the slash-name
limitation and explains how to check the displayed `Source:` line. The CLI
dependency was not changed. The commit-ID commands passed against the public
snapshot identified above.

## Evidence and limits

Private evidence retains the charter, CLI identity, exact argument vectors,
separate stdout/stderr, elapsed times and before/after file hashes. It also retains
the test-setup correction, both failed branch-URL probes and successful pinned
installations. Disposable packages and runtime caches remain available for review.

This check used a previously installed CLI and does not establish a fresh `npx`
download. Public-source update/removal, separate single-client installations,
interactive selection, all specialist installations and live model use were not
repeated. Earlier isolated local-source lifecycle checks remain separate evidence.

The source downloaded here precedes this documentation repair. Regenerated local
packages and any later publication need their own source identity. Existing
native client acceptance remains tied to its recorded package. No additional push,
PR, macOS 15 test, browser workaround or device change was part of this check.
