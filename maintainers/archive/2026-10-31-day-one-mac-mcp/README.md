# Archived Day One Mac MCP implementation

The MCP integration is paused. Active native plugins distribute the portable
main skill without a server. Manual guides, external MCP recipes and reviewed
helpers remain supported.

## Preserved source

`source/` contains the tracked MCP package, configuration specification and
snapshots of the plugin builder, plugin fixture, package scripts, Docker context
and CI workflow that depended on it. `manifest.json` records the source revision
and SHA-256 of every preserved file under its original repository-relative path.
Dependencies, build outputs, credentials, private backups and installed client
configuration are excluded. Earlier dated plans and acceptance records remain
historical evidence; they are not current installation instructions.

Archived files are evidence, not supported entry points. They retain original
paths and references. Do not build or run them from this nested archive, add them
to skill inventories or restore their old CI jobs automatically.

## Revisit deliberately

1. Create a branch and review the preserved source and dependency versions.
2. Verify the archive hashes against `manifest.json` before copying anything.
3. Restore only the selected package and specification to their original paths.
   Review changes since the recorded source revision; do not overwrite current
   plugin tooling, package scripts or workflows with their archived snapshots.
4. Recheck the current MCP SDK, client schemas, approval controls, ownership,
   private backup handling and source-independent packaging.
5. Add explicit tests and opt-in build/CI commands for the chosen scope. Keep
   ordinary skills and manual setup independent of the server.
6. Obtain separate approval for registration, permissions, publication or live
   preference changes. Re-test the selected clients before describing support.

Local client registrations and old artifacts require their own recovery records.
A source restoration does not re-enable an installed server. Private preference
backups must be retained independently of this public archive.
