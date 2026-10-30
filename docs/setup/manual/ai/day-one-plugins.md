# Optional native Day One Mac plugins

Use a native plugin when you want the main Day One Mac skill and its read-only
local MCP connection installed together. Plain [skill installation](day-one-skills.md)
remains sufficient for guided setup. Neither route activates the supplied agent
templates or requires Claude Desktop.

## Review the package

Use a reviewed artifact for your client, produced by the
[contributor packaging procedure](../../../shared/reference/plugin-packaging.md).
Artifacts are local build outputs, not an npm or public-directory release.
Keep the selected marketplace folder in a stable location outside a checkout.

Each client directory contains a local marketplace and `day-one-mac/`:

```text
codex/                              claude/
├── .agents/plugins/marketplace.json ├── .claude-plugin/marketplace.json
└── day-one-mac/                     └── day-one-mac/
    ├── plugin.json                     ├── .claude-plugin/plugin.json
    ├── mcp.json                        ├── .mcp.json
    ├── .codex-plugin/plugin.json        ├── skills/day-one-mac/
    ├── .mcp.json                       └── runtime/
    ├── skills/day-one-mac/
    └── runtime/
```

The Codex portable manifest and compatibility fallback describe the same skill
and server. Claude has its own manifest and root-path placeholder. Skill contents
and runtime code are shared. Do not symlink an entire Codex package into Claude.
Ordinary standalone skills can still use the existing Claude skill symlinks.

Inspect `artifact.json` hashes, manifests, `.mcp.json`, license notices and the
main skill before installation. Packages contain real files, no dependency
directory, credentials, hooks or active agent registrations. Node.js 22.20 or
newer must be visible to the client's process as `node`; a working terminal alone
does not prove that a desktop application's PATH can find it.

## Install the selected client package

Set `PACKAGE_ROOT` to the absolute path containing the reviewed `codex` and
`claude` folders. Choose one client route below. Registration changes client
configuration; review existing standalone skill and MCP connections first.
Avoid enabling the same main skill and server through multiple installation
routes. Preserve unrelated skills, servers and permission settings.

For Codex, register the local marketplace, inspect it and install its plugin:

```bash
codex plugin marketplace add "$PACKAGE_ROOT/codex"
codex plugin list --marketplace day-one-mac-local
codex plugin add day-one-mac@day-one-mac-local
```

For Claude Code, register the marketplace, validate it and install at the scope
you intend to use:

```bash
claude plugin validate "$PACKAGE_ROOT/claude" --strict
claude plugin marketplace add "$PACKAGE_ROOT/claude"
claude plugin install day-one-mac@day-one-mac-local --scope project
```

Expected result: one installed `day-one-mac` plugin for the selected client.
Claude plugin skills use a namespace such as `/day-one-mac:day-one-mac`.
Installing the plugin does not authenticate an AI provider or configure the Mac.
[Codex packaging](https://developers.openai.com/plugins/build/plugins),
[Claude plugin reference](https://code.claude.com/docs/en/plugins-reference).

## Verify and remove

Refresh the client, confirm the main skill is discoverable and review the MCP
tool list. The default server advertises `list_guides`, `read_guide`, `check_host`,
`preview_desktop_click` and the preview-only compatibility `desktop_click`.
It does not advertise `apply_desktop_click`. Read the shortcuts guide through
`read_guide` with `{"id":"shortcuts"}`. Do not change preferences to test discovery.

MCP read-only defaults apply to its tool interface. The skill can still describe
approved setup operations using the client's other tools; retain those permission
controls. A server process reports its own host, so a container cannot inspect
Mac preferences. Agent templates remain opt-in and require native activation.

Use each client's plugin manager to disable the plugin before removing it.
Keep private notes and backups outside the installed package. Removing a plugin
does not undo Mac configuration, remove developer applications or erase recovery
records. A marketplace directory remains the source for later reinstalls; keep it
until the client no longer depends on it.

Native manifest validation and an isolated MCP handshake prove parsing and
protocol behavior. Account-backed skill invocation requires a signed-in client
and a separate functional check. Claude Desktop compatibility is not established
by Claude Code acceptance.
