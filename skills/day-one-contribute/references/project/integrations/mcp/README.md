# Day One Mac MCP archive notice

The Day One Mac MCP implementation is archived and is not included in current
builds, native plugins or CI. Use the [main skill](../../docs/setup/manual/ai/day-one-skills.md)
or the [skill-only native plugin](../../docs/setup/manual/ai/day-one-plugins.md)
for AI-assisted setup. Manual guides remain usable without either.

The contributor source and hash manifest are preserved under
`maintainers/archive/2026-10-31-day-one-mac-mcp`. This notice preserves the original
public guide URL; the archive is not an installation route. General
[external MCP setup](../../docs/setup/manual/ai/mcp.md) remains available for
selected services such as Context7 or GitHub.

## Existing installations

Disable only the Day One Mac connection in each selected client. An older native
plugin can still bundle its own server even when no direct MCP entry exists.
Preserve the old artifact, selected registration and any preference-recovery
records privately before changing it. Reload existing sessions after disabling;
already-running sessions may retain their tool catalog until refreshed.

Codex supports a per-plugin MCP override that leaves the plugin skill enabled:

```toml
[plugins."day-one-mac@day-one-mac-local".mcp_servers.day_one_mac]
enabled = false
```

Check `codex mcp get day_one_mac --json` for `enabled: false`. For Claude Code,
use the client's supported plugin controls or replace the old package with a
reviewed skill-only release. If disabling the whole plugin, first verify a
standalone main skill is available through the [skill procedure](../../docs/setup/manual/ai/day-one-skills.md).
Do not disable unrelated MCP servers or delete their configuration.

To revisit the archived integration, review the contributor archive and obtain
approval for the selected restoration. Removing the Codex override restores the
previous default policy; do not enable it merely to test documentation discovery.

<a id="method-a-native-macos"></a>
<a id="method-b-docker"></a>
