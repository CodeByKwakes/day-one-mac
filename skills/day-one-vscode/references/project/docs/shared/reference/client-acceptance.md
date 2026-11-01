# Client and workflow acceptance

Use this matrix to distinguish documented procedures from successful execution.
A source check inspects files. An isolated fixture uses disposable inputs. A live
check exercises a named client or device with its actual permissions and account.
Passing one does not establish the others. Recheck after relevant upgrades.

## Day One Mac distribution

| Surface | Source and fixture coverage | Live evidence and limits |
|---|---|---|
| Codex native plugin | Skill-only relocation, packaged references, hashes and absence of server manifests | On 1 November 2026, version 0.1.2 passed installed-version/hash checks and one explicit read-only shortcuts-guide request in Codex CLI 0.165.0; broader workflows remain unverified |
| Claude Code native plugin | Skill-only artifact checks; strict native validation when the CLI is supplied | Version 0.1.2 needs fresh skill-invocation checks; version 0.1.1 invocation was recorded with Claude Code 2.1.308 on 30 October 2026 |
| Standalone skills for Codex, Claude Code and Copilot | Skills CLI 1.7.4 isolated scope, symlink, update and removal cases | Discover the installed skill and request the intended workflow in each selected client; installer fixtures do not prove account access |
| Claude Desktop | No active Day One Mac MCP distribution | Integration deferred; Claude Code acceptance does not prove Desktop discovery |
| Optional native agent roles | Generated adapter consistency and read-only policy checks | Activation and client permission checks remain separate, opt-in work |
| Archived Day One Mac MCP | Historical server/container fixtures preserved with source | Not part of current releases or CI; restoration needs separate review |

These observations refer to the stated installed snapshot. Edited source guides
and generated packages are not installed client updates until deliberately
refreshed through their own lifecycle. No account or device readiness should be
inferred from this table when resuming a setup.

The 1 November Codex check used source revision
`c0bc02400aa8e5c501fb1638bdfe977b32158bbe`. Its trace contained three successful
reads from the installed plugin: the main skill, shortcuts workflow and manual
shortcut guide. It did not run a shortcut or establish clean-device acceptance.
The previous package was preserved, and the existing standalone skill remained
disabled in Codex. Private evidence records the approval, update and response.

## Application and device workflows

| Workflow | Fixture coverage | Required live check |
|---|---|---|
| Send to Archive | Planning, multiple moves, private recovery, conflicts, drift and input guards | On 30 October 2026, Finder-triggered test moves, cancellation and destination-name refusal were observed using disposable folders; test again on each installation |
| Workspace restoration | Parsing, stable identities, topology mismatch, drift, locks and display-only recovery | Office and Home physical calibration, DisplayLink readiness and Raycast/editor matching remain unverified |
| MacBook full-screen editing | Not a display-helper guarantee | macOS owns the full-screen Space; a Raycast maximized layout does not promise to recreate that Space |
| Atticus | Pinned upstream source review described in its guide | Optional live build, provider, permission and voice-command acceptance remain unverified |
| Notion MCP | Documented official connection routes and local CLI help inspection | Workspace consent and a harmless page read must be completed by the selected account |

Record new acceptance privately with client/tool version, selected scope,
command or UI action, expected and actual result, and recovery reference.
Contributors may add a sanitized dated evidence entry after review. Do not
include usernames, private paths, workspace identifiers or credentials.

For failures, use [troubleshooting](../troubleshooting.md). The
[plugin lifecycle](../../setup/manual/ai/day-one-plugins.md) and
[skill lifecycle](../../setup/manual/ai/day-one-skills.md) own their update steps.
