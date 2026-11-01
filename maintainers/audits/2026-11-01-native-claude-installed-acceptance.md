# Native Claude installed-plugin acceptance

**The scoped installed-plugin check passed.** Claude Code 2.1.308 loaded the
registered Day One Mac 0.1.2 plugin and answered an explicit read-only request.
The plugin remains enabled at user scope. Overall readiness remains **Not ready**
because the other gaps in the [readiness follow-up](2026-11-01-readiness-followup.md)
remain open.

This record covers the approved host update and corrected request on 1 November
2026. It supplements the earlier [session-only check](2026-11-01-native-claude-acceptance.md).
No further macOS 15 testing or publication occurred.

## Source, update and recovery

The reviewed package was built from
`c0bc02400aa8e5c501fb1638bdfe977b32158bbe`. Its 238 manifest-listed files matched
the stable source and installed cache after the update and final request.
The prior package remained available with all 237 listed file hashes intact.
The new package declared no MCP server or hooks.

The approved update used the documented user-scope marketplace, update and
enable commands. Only the duplicate Claude standalone-skill symlink moved into
private recovery storage. Its shared target remained unchanged. Checks confirmed
that unrelated user settings, plugins and marketplaces were unchanged.

The first installed-plugin request was inconclusive. The test permitted reads
under `installPath`, but the client loaded its registered `readFromFolder`.
Both attempted reads were denied; no reference read succeeded. The new plugin
was disabled and the original standalone link restored before another request
was proposed. This was a test-setup error, not a confirmed package defect.

The user then approved one corrected request. The test allowed the verified
registered source folder, preserved the duplicate link again and re-enabled
only the selected plugin. The earlier request and recovery evidence remain
available. No permission boundary was bypassed.

## Successful request and observed result

A fresh session explicitly loaded the actual user settings in restricted mode.
It exposed only `Read`, used plan permissions, denied permission prompts and
loaded an explicit empty MCP configuration. Session persistence and browser
integration were disabled. No `--plugin-dir` or `--plugin-url` override was used.

The namespaced command `/day-one-mac:day-one-mac` selected the main skill.
Client initialization identified `day-one-mac@day-one-mac-local`, version 0.1.2,
at the registered source. The completed trace contained two successful reads:

1. `skills/day-one-mac/references/workflows/day-one-shortcuts.md`
2. `skills/day-one-mac/references/project/docs/setup/manual/apps/macos-shortcuts.md`

The response reported that the skill loader supplied `SKILL.md`; the retained
trace has no separate main-skill read or full injected body. The answer explained
the launcher versus standalone app distinction and the guide's preview/recovery
boundaries. It did not claim an actual shortcut or device test passed.

The process returned zero without a timeout or permission denial. Stderr and
the private workspace remained empty. No helper, command or app ran through
the model's tools. Post-request checks confirmed the enabled user-scope state,
matching source/cache hashes and preserved recovery material.

## Evidence and acceptance boundary

The maintainer retains the approval/preflight records, native update receipts,
installed verification, both request traces, recovery verification and
`acceptance-result.json` privately. The final record identifies the successful
reads and hashes of the primary evidence.

This establishes the selected user-scope update, registered-plugin discovery
and explicit bundled-reference request. It does not establish implicit
activation, every workflow, an ordinary unrestricted session, clean-device
setup, independent restore, reader accessibility or human usability.

For future bounded checks, the [plugin lifecycle guide](../../docs/setup/manual/ai/day-one-plugins.md)
distinguishes the installed cache from the registered source actually loaded.
The earlier review handoff and installed package retain their own source
identities; this acceptance note does not automatically update either artifact.
