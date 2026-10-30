# Build native plugin artifacts

Contributor tooling builds Codex and Claude Code packages from the generated
main skill and the optional MCP server. Normal users install a reviewed artifact
using the [native plugin recipe](../../setup/manual/ai/day-one-plugins.md);
they do not need this checkout or its build helpers.

## Sources and output

`templates/plugins/metadata.json` owns shared identity and version. The version
matches `integrations/mcp/package.json`. `tools/build-plugins.cjs` produces native
manifests, local marketplace catalogs and per-package `artifact.json` hashes.
Each package contains the main skill with its independent references, compiled
MCP code, reviewed guide snapshots and dependency license notices.

The bundler is pinned in the MCP contributor lockfile. It combines production
code into one Node.js module without shipping `node_modules`. Runtime metadata
retains the import-relative layout used by the server. Native manifests use
`${PLUGIN_ROOT}` for Codex and `${CLAUDE_PLUGIN_ROOT}` for Claude Code.
No account configuration, private notes, contributor skills or dependency trees
are copied. Role templates stay inside skill assets and are not activated.

## Build and verify

Prepare contributor dependencies as described in CONTRIBUTING.md, including the
locked MCP dependencies. Inspect the recommended parent directory for ownership
and unexpected symlinks before creating missing directories. For reviewed version
`0.1.1`, prepare the parent and regenerate skills after editing public sources:

```bash
mkdir -p "$HOME/Developer/Resources/Project-Materials/day-one-mac/releases/0.1.1"
pnpm run skills:build
pnpm run plugins:build --output "$HOME/Developer/Resources/Project-Materials/day-one-mac/releases/0.1.1/native-plugins"
```

Use the reviewed package version in the output path and a destination that does
not already exist. See the
[distribution and installation layout](../../setup/manual/ai/day-one-plugins.md#choose-the-installation-route-and-locations).

Expected result: new `codex` and `claude` marketplace directories outside the
checkout. Existing destinations and destination symlinks are refused. A failed
build retains its reserved output for inspection; do not distribute partial
output or retry into that directory. Builds do not register or start a client.

Run the plugin fixture and combined gate:

```bash
pnpm run test:plugins
pnpm run validate:complete
```

The plugin fixture checks relocation into paths with spaces and Unicode,
source-independent MCP startup, read-only discovery, license notices, hashes,
output ownership and no-overwrite. It leaves live client configuration alone.
For authoritative native Claude validation, supply an approved CLI explicitly:

```bash
DAY_ONE_CLAUDE_BIN="$(command -v claude)" pnpm run test:plugins
```

Expected result: strict Claude validation of the generated plugin and marketplace,
in addition to the protocol fixture. The fixture uses a temporary Claude config
directory, disables updates and does not log into an account. Without this
variable, native CLI validation is not claimed. CLI validation does not establish
account-backed invocation. Set `DAY_ONE_CODEX_BIN` to an approved Codex executable
to check local marketplace discovery using temporary command-line overrides;
the fixture does not register, install or enable it. CI runs the portable artifact fixture; native client
acceptance and MCP container acceptance remain separate checks.

Keep generated artifacts outside Git and inside a stable reviewed location before
manual registration. Public-directory submission, registry publication, pushing
and automatic client installation require separate scope.
