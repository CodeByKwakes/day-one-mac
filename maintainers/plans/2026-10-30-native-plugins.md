# Native plugin packaging and Claude Code acceptance

Approved after the AI component cleanup. Claude Code is the compatibility target;
Claude Desktop support and agent activation remain deferred. Do not publish,
register a permanent plugin, transfer credentials or change live Mac preferences.

## Tasks and decisions

- [x] Validate a pinned temporary Claude Code CLI without changing the live setup.
- [x] Build native Codex and Claude packages from the same main skill and MCP code.
- [x] Verify relocated artifacts, licenses, native manifests, symlinks and read-only tools.
- [x] Document installation prerequisites, duplicate avoidance and live-test limits.
- [x] Run repository gates, pinned Skills CLI acceptance and independent review.

Ruling: use the existing feature branch and self-contained output directories
outside the checkout. Keep generated plugin artifacts out of skill packages and
source control. Bundle production runtime code; never ship dependency directories,
account configuration or contributor-only skills. Copy dependency license notices.

Ruling: preserve a portable Codex manifest plus its compatibility fallback, and a
separate Claude manifest. Root placeholders are platform-specific. Native role
templates remain inside the skill assets and are not activated as plugin agents.

## Verification

Full `tools/validate.sh --all` and actionlint pass. MCP: 23 protocol/safety
checks, production-only relocated package installation, rebuilt container and
final container smoke pass. The bundler is excluded from production installation.
Skills CLI 1.7.4: 66 fixture installs plus shared Claude symlinks, bounded lifecycle
and temporary Git-source update checks pass.

The native artifact fixture passes relocation, exact manifest/hash coverage,
license notices, no-overwrite, symlink refusal and read-only stdio discovery.
Claude Code 2.1.314, installed only in a task-specific temporary directory, passes
strict validation of the generated plugin, marketplace and four role formats.
Codex CLI discovers the local catalog using command-line overrides and reports
the plugin available, uninstalled and disabled. Neither client was registered or
activated. Existing contributor skill symlinks remain covered by the root gate.

An independent read-only reviewer found no actionable issues and confirmed that
all three bundled production dependencies have matching license notices. No
model/account session, credential transfer, Claude Desktop integration or live
agent activation was performed. A permanent Claude Code installation and signed-in
functional invocation remain separate user setup steps.

Review artifacts were built through the documented pnpm command into a new
Downloads directory. ZIP integrity passes; the archive excludes macOS resource
forks and extended-attribute entries. Artifact hashes cover every packaged file.
