# Native Claude plugin session acceptance

**The explicit session-only check passed.** Claude Code 2.1.308 loaded Day One
Mac 0.1.2 and answered a read-only request using three bundled documents.
Overall repository readiness remains **Not ready** because the other gaps in
the [readiness follow-up](2026-11-01-readiness-followup.md) remain open.

This record covers the host check on 1 November 2026. No persistent Claude
plugin update, further macOS 15 testing or publication occurred. The
[client acceptance matrix](../../docs/shared/reference/client-acceptance.md)
owns the current distribution summary.

## Source and controls

The session loaded the reviewed artifact built from
`c0bc02400aa8e5c501fb1638bdfe977b32158bbe` through `--plugin-dir`.
All 238 manifest-listed file hashes matched before and after the requests.
Both the plugin manifest and the client initialization event identified 0.1.2.
The package declared no MCP server or hooks.

The [Claude CLI reference](https://code.claude.com/docs/en/cli-reference)
documents session-only loading. The check used an empty private workspace,
restricted mode, only the `Read` tool, plan permissions, denied permission
prompts, an explicit empty MCP configuration and no session persistence.
Each attempt had a 180-second deadline and a configured USD 0.50 budget cap.
The existing account sign-in was used; no credential file was read or copied
into evidence.

## Attempts and observed results

The initial natural-language request produced no file reads. Although client
initialization listed the plugin and its namespaced skill, the model reported
that it could not discover them. The process returned zero, but this attempt
did not pass acceptance. Its request, response and trace remain preserved.

The second attempt only prefixed the same request with
`/day-one-mac:day-one-mac`, the command described in the
[plugin lifecycle guide](../../docs/setup/manual/ai/day-one-plugins.md).
No client permissions or available tools were broadened. This attempt completed
exactly three successful `Read` calls under the session-loaded plugin:

1. `skills/day-one-mac/SKILL.md`
2. `skills/day-one-mac/references/workflows/day-one-shortcuts.md`
3. `skills/day-one-mac/references/project/docs/setup/manual/apps/macos-shortcuts.md`

The response accurately explained the native Shortcut launcher versus standalone
generated app distinction and the guide's preview and recovery boundaries.
The process returned zero, stderr was empty, and the workspace remained empty.
No helper, command, app or installation ran through the model's tools.

The maintainer retains `plan.json`, both requests, separate `events.jsonl` and
`run.json` files, and `acceptance-result.json` privately. The latter records
evidence hashes, successful reads, package verification and registration checks.

## Acceptance boundary

This establishes explicit skill invocation and bundled-reference resolution
through a live Claude session. It does not establish persistent 0.1.2
installation, implicit activation under ordinary client permissions or broader
workflow coverage. The first attempt's restrictive tool configuration prevents
conclusions about normal automatic activation.

The existing user-scope 0.1.1 registration remained disabled and unchanged.
Its package was preserved. No actual shortcut, clean-device setup, recovery,
reader accessibility or human usability check occurred. The
[Codex acceptance record](2026-11-01-native-codex-acceptance.md) covers its
separately approved installed-plugin check.

Future checks must distinguish plugin discovery, skill activation and completed
reference reads. A listed plugin or a successful process exit alone proves
neither activation nor task completion.
