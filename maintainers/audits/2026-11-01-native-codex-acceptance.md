# Native Codex plugin acceptance

**The scoped native-plugin check passed.** Codex CLI 0.165.0 loaded Day One Mac
0.1.2 and answered one read-only request using installed references. Overall
repository readiness remains **Not ready** because the other acceptance gaps in
the [earlier follow-up](2026-11-01-readiness-followup.md) remain open.

This record covers the approved host plugin update on 1 November 2026, not a
clean-device installation. No further macOS 15 testing or publication occurred.
The [client acceptance matrix](../../docs/shared/reference/client-acceptance.md)
summarizes the tested source and scope.

## Source and update evidence

The tested source was `c0bc02400aa8e5c501fb1638bdfe977b32158bbe`.
The native plugin ZIP SHA-256 was
`29a0a31484ea60acf6c0b56c2f3ca920d8d5e067cd3d5eb4f6928f93d8766872`.
The local handoff passed source, archive and native CLI fixture checks before
the user approved its installation.

The update changed only the selected `day-one-mac-local` marketplace source and
`day-one-mac` plugin through the documented native commands. The new package was
copied into a separate stable directory, with no overwrite. Its 240 installed
Codex files matched the reviewed source, including `artifact.json`.

The previous 0.1.1 source remained available, and its 239 manifest-listed file
hashes matched before the update. The existing standalone skill was already
disabled in Codex; its files and disabled setting were preserved. No credential
file was read or copied into evidence.

## Live request and observed result

A fresh, ephemeral Codex CLI session used read-only mode and an empty private
workspace. The single request asked the native plugin to discover its main skill
and explain its bundled shortcut guide. It prohibited helpers, installation,
system inspection and file changes.

The completed tool trace contained exactly three successful `cat` commands:

1. `skills/day-one-mac/SKILL.md`
2. `skills/day-one-mac/references/workflows/day-one-shortcuts.md`
3. `skills/day-one-mac/references/project/docs/setup/manual/apps/macos-shortcuts.md`

All paths resolved under the installed 0.1.2 plugin cache. The response explained
the native Shortcut launcher versus standalone generated app distinction and
the documented preview and recovery limits. The process returned zero, the
workspace remained empty, and post-request package hashes still matched.

The maintainer retains `approved-preflight.json`, the three native update
receipts, `installed-verification.json`, `live-events.jsonl`, `live-run.json` and
`live-acceptance-result.json` privately. The latter records evidence hashes.
The original request and response are retained beside those files.

## Acceptance boundary

This closes the specific Codex installed-version, reference-resolution and
explicit live-request check for the named source. It does not establish broad
workflow coverage, implicit activation, an actual shortcut run, Claude live
invocation, reader accessibility, backup restoration or human/device acceptance.

The package declares no MCP server or hooks. The check did not remove direct
MCP registrations or certify unrelated integrations. The earlier 0.1.1 package
remains available for the reviewed recovery procedure; no downgrade was tested.

The repository acceptance note and regenerated packages may describe this result
after the tested source. They are not automatically installed updates. The host
plugin remains the explicitly approved candidate identified above.
