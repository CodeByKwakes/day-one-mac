# Build native plugin artifacts

Contributor tooling packages the generated main skill for Codex and Claude Code.
Current native plugins contain no MCP server, runtime or auto-activated agent.
Normal users follow the [plugin recipe](../../setup/manual/ai/day-one-plugins.md)
and need no source checkout.

## Sources and output

`templates/plugins/metadata.json` owns plugin identity and version independently
of the archived MCP package. `tools/build-plugins.cjs` copies the main skill,
LICENSE and contained references, then writes native manifests, local marketplace
catalogs and SHA-256 hashes in `artifact.json`. It needs no MCP dependencies,
server build, Docker image or bundler.

No client configuration, private notes or contributor toolkit is copied. Role
templates remain skill assets and are not activated. Source-independent skill
helpers retain their own prerequisites; plugin startup runs no executable helper.

## Build and verify

1. Prepare contributor dependencies through CONTRIBUTING.md and regenerate skills:

   ```bash
   pnpm run skills:build
   ```

   Expected: generated packages match their reviewed sources.

2. Choose a new absolute output outside the checkout with an existing trusted
   parent. For example, prepare a private temporary parent:

   ```bash
   PLUGIN_REVIEW_PARENT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-plugin-review.XXXXXX")"
   pnpm run plugins:build --output "$PLUGIN_REVIEW_PARENT/native-plugins"
   ```

   Expected: new `codex` and `claude` directories. Existing outputs and symlinked
   destinations are refused. Do not distribute a partial output after failure.
   A temporary review folder is not a stable installation source; copy reviewed
   artifacts to a versioned stable location before registration.

3. Run artifact fixtures and the full gate:

   ```bash
   pnpm run test:plugins
   pnpm run validate:complete
   ```

   Expected: relocation, hashes, contained sources, no-overwrite and absence of
   MCP manifests/runtime pass. These fixtures leave live registrations alone.

4. For native CLI validation, supply only approved executables:

   ```bash
   DAY_ONE_CLAUDE_BIN="$(command -v claude)" DAY_ONE_CODEX_BIN="$(command -v codex)" pnpm run test:plugins
   ```

   Expected: strict Claude plugin/marketplace validation and Codex marketplace
   discovery. Claude uses a temporary config; Codex uses temporary command-line
   source overrides. No plugin is installed or enabled in the live clients.
   Without these variables, native CLI validation is not claimed. Neither form
   proves account-backed skill invocation.

## Prepare a package handoff

After the build and checks succeed, create a ZIP with `codex` and `claude` at its
root. The example uses the `PLUGIN_REVIEW_PARENT` from the build above and the
version in `templates/plugins/metadata.json`:

```bash
(
  set -euo pipefail
  PLUGIN_VERSION="$(node -p "require('./templates/plugins/metadata.json').version")"
  PLUGIN_ARCHIVE="$PLUGIN_REVIEW_PARENT/day-one-mac-native-plugins-$PLUGIN_VERSION.zip"
  test ! -e "$PLUGIN_ARCHIVE" && test ! -L "$PLUGIN_ARCHIVE"
  cd "$PLUGIN_REVIEW_PARENT/native-plugins"
  zip -qr "$PLUGIN_ARCHIVE" codex claude
  shasum -a 256 "$PLUGIN_ARCHIVE"
)
```

Expected: a new archive and its SHA-256 digest. Inspect `unzip -l` for the selected
archive, extract it into a separate temporary folder, and compare both client
trees with the built output before sharing. Include the digest and reviewed
source identity in the approved handoff channel. A modified local source needs
its reviewed diff as evidence; do not label it with a clean commit alone.

The receiver follows the [package receiving procedure](../../setup/manual/ai/day-one-plugins.md#receive-and-place-a-package).
Creating an archive is local preparation. Publishing or sending it to another
person requires the corresponding approval. Keep the active registration source
in a stable directory rather than the temporary build location.

The MCP is archived; its source, dependency lock, previous server-bearing plugin
builder and related evidence live under
`maintainers/archive/2026-10-31-day-one-mac-mcp`. They are excluded from normal
packaging and CI. The [archive notice](../../../integrations/mcp/README.md)
owns existing-connection guidance. Restoring an MCP is a separate reviewed change.

Public submission, registry publication, pushing and automatic client updates
require their own scope. A successful build does not register a marketplace.
