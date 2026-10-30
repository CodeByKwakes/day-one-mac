# Client and workflow acceptance

Use this matrix to distinguish documented procedures from successful execution.
A source check inspects files. An isolated fixture uses disposable inputs. A live
check exercises a named client or device with its actual permissions and account.
Passing one does not establish the others. Recheck after relevant upgrades.

## Day One Mac distribution

| Surface | Source and fixture coverage | Live evidence and limits |
|---|---|---|
| Codex native plugin | Manifest, relocated MCP startup, packaged references and hashes | Version 0.1.1: signed-in main-guide reads recorded on 30 October 2026; existing sessions need reload after an update |
| Claude Code native plugin | Strict native validation when `DAY_ONE_CLAUDE_BIN` is supplied; independent server handshake | Version 0.1.1 with Claude Code 2.1.308: skill invocation and guide reads recorded on 30 October 2026 |
| Standalone skills for Codex, Claude Code and Copilot | Skills CLI 1.7.4 isolated scope, symlink, update and removal cases | Discover the installed skill and request the intended workflow in each selected client; installer fixtures do not prove account access |
| Claude Desktop | Shared stdio server is available; no Desktop-specific acceptance established | Integration deferred. Claude Code plugin or symlink acceptance does not prove Desktop discovery |
| Optional native agent roles | Generated adapter consistency and read-only policy checks | Activation and client permission checks remain separate, opt-in work |
| Docker MCP server | Non-root image and stdio resource/host-denial smoke fixture | Linux-container evidence does not prove access to macOS preferences |

These observations refer to the stated installed snapshot. Edited source guides
and generated packages are not installed client updates until deliberately
refreshed through their own lifecycle. No account or device readiness should be
inferred from this table when resuming a setup.

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
