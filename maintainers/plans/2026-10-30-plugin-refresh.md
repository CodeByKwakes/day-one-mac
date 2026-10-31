# Refresh the installed native plugin snapshot

Approved after committing workspace restoration and personal-toolkit separation.
Build version 0.1.1, preserve version 0.1.0 for recovery, and refresh only the
selected Day One Mac plugin in Codex and Claude Code. No desk calibration,
Finder project moves, agent activation or Claude Desktop setup is included.

## Tasks

- [x] Version the plugin/MCP snapshot and allowlist the new public guide resources.
- [x] Verify source packages, native artifacts and read-only protocol behavior.
- [x] Save private client recovery copies and build a new stable artifact directory.
- [x] Refresh the selected client registrations and verify the installed version.
- [x] Run bounded live guide reads, then commit the versioned source changes.

The new guide IDs are `workspaces`, `atticus` and `components`. They expose
reference text only; adding a guide does not install its applications or run its
commands. Existing mutation opt-in and client approval requirements remain.

## Verification

The complete repository gate, actionlint, 23 MCP protocol/safety checks,
production package acceptance and native artifact fixtures pass. Skills CLI 1.7.4
passes 66 isolated installation cases and its lifecycle checks. The 0.1.1
container build and final stdio smoke pass with fourteen resources.

An independent read-only review found no actionable issues. Stable artifacts
were hash-verified before refreshing the selected local marketplace in each
client. Both clients report version 0.1.1 enabled. Installed Codex hashes and the
Use Day One Mac display label verify. Earlier 0.1.0 artifacts remain intact.

Signed-in fresh Codex and Claude sessions read the new workspace and component
guides. Claude also invoked the namespaced main skill. The probes used only
read-only guide calls, with shell/file tools unavailable. Unrelated client
settings were compared with private pre-refresh recovery copies and preserved.
No live display configuration, Finder move, Atticus setup or agent activation
was performed. Existing client sessions may need reload to load the new snapshot.
