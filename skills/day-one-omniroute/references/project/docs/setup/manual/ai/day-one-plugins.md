# Optional native Day One Mac plugins

Install the main Day One Mac skill and its read-only local MCP connection as one
native plugin. Plain [skill installation](day-one-skills.md) is sufficient when
you need instructions without this connection. Choose one delivery method for
the main skill. Neither method activates native agent templates.

## Choose the installation route and locations

Use the native plugin for Codex or Claude Code when you want the main skill and
local MCP connection together. For Claude Desktop, use the separate
[standalone MCP installation](../../../../integrations/mcp/README.md#method-a-native-macos).
A Claude Code plugin does not configure Claude Desktop. Neither local route
requires npm publication or a public plugin-directory listing.

The recommended locations fit the optional
[purpose-oriented workspace](../development/folders.md#choose-a-layout):

```text
~/Developer/
├── Sandbox/day-one-mac/                 Editable source, if already kept here
└── Resources/Project-Materials/day-one-mac/
    └── releases/<version>/
        ├── native-plugins/             Reviewed distribution files
        └── mcp/                        Standalone tarball and checksum
~/.local/share/
├── day-one-mac/plugins/<version>/       Stable native package root
└── day-one-mac-mcp/<version>/           Stable standalone MCP installation
```

`<version>` means the reviewed package version, for example `0.1.1`. The source
location is illustrative: preserve an existing checkout wherever it lives.
Normal users need no checkout. Resources holds distribution files; clients
reference installed copies under `.local/share`. Keep these copies while any
client references them, and retain the previous version for recovery. Do not
put active installations in Sandbox, Downloads or Archive. No new symlink is
required. Existing installations at other stable paths remain valid.

Shell commands expand `$HOME`; JSON and TOML do not. `/absolute/path/to/...`
is an example to replace with an observed path, not a required folder name or
an indication that the package needs publishing. The standalone configuration
utility prints resolved paths; native plugins resolve their bundled MCP paths
through the client's plugin-root variable.

## AI-assisted installation

Use a client with approved local file and command access. A chat without those
tools can explain the manual steps but cannot install packages on the Mac.
No general filesystem MCP server is required to bootstrap this installation.

1. Give the assistant this inspection-only request:

   ```text
   Plan installation of Day One Mac for my selected clients. Do not install yet.
   Inspect existing skills, plugin registrations and direct MCP entries. Use the
   native plugin for Codex/Claude Code and standalone MCP for Claude Desktop.
   Verify the reviewed package version, provenance, hashes, Node requirement
   and stable destination. Show commands, configuration changes, scope, private
   backups, verification and recovery. Preserve unrelated settings and report
   any sign-in, approval or restart that I must complete.
   ```

   Expected: a plan based on existing registrations and the selected artifact.
   Stop if the artifact is unavailable or its provenance cannot be established.
   A checksum beside a package detects corruption; it does not authenticate its
   publisher. Obtain the expected checksum through a trusted source.

2. Review the proposed change, then approve only the named clients, version,
   paths and scope when ready. Asking for a plan does not authorize installation.

   Expected: the assistant follows the manual recipe below, or the linked
   standalone recipe, backs up affected configuration privately and merges only
   the selected entry. Existing plugin copies and unrelated servers are preserved.
   It must not add a direct Day One Mac MCP connection alongside the same client's
   native plugin. Standalone MCP does not install a skill.

3. Complete sign-in and permission prompts yourself. If a client must restart,
   finish or save current work before restarting it. Have the assistant verify
   discovery and a harmless `list_guides` or `read_guide` call after the restart.

   Expected: installed files, registration, server discovery and a successful
   read are reported separately. A pending restart is an incomplete live check.
   Keep the server read-only; this installation does not authorize preference
   changes, publication, pushing or automatic future updates.

## Manual installation

Follow the prerequisites, then the procedure for your selected client below.
For Claude Desktop, follow the standalone MCP recipe linked above instead.

<a id="review-the-package"></a>

## Prerequisites and package review

1. Install and sign in to the selected [AI client](clients.md). Check its command:

   ```bash
   codex --version
   ```

   For Claude Code instead, run:

   ```bash
   claude --version
   ```

   Expected: the selected CLI is available. The commands below were checked with
   Codex CLI 0.165.0 and Claude Code 2.1.308 on 30 October 2026. These are tested
   versions, not established minimums. Check `plugin --help` in your version;
   stop if the required command is unavailable.

2. Obtain the reviewed artifact for your client from a maintainer using the
   [packaging procedure](../../../shared/reference/plugin-packaging.md).
   Artifacts are local build outputs, not a public-directory or npm release.
   Keep old and new versions in separate stable folders outside a checkout.

   Expected: the selected folder contains `codex` and `claude` directories.
   Normal users do not need contributor builds or a permanent source checkout.

3. Place the reviewed package in a new stable version folder. For version
   `0.1.1`, the recommended root is below. It must contain the received `codex`
   and `claude` directories directly; setting this variable does not copy or
   install anything. If the package already lives elsewhere, use its confirmed
   absolute root instead. Do not overwrite an existing version directory.

   ```bash
   PACKAGE_ROOT="$HOME/.local/share/day-one-mac/plugins/0.1.1"
   test -f "$PACKAGE_ROOT/codex/day-one-mac/artifact.json"
   test -f "$PACKAGE_ROOT/claude/day-one-mac/artifact.json"
   ```

   Expected: both tests return zero without output. Stop on a missing file.
   Inspect each package's `artifact.json`, manifests, license notices and skill.
   Compare the recorded hashes with the received files before trusting them.
   Never use a folder inside an installed skill for private notes or backups.

4. Check the required Node.js version:

   ```bash
   command -v node
   node --version
   ```

   Expected: Node.js 22.20 or newer. The plugin launches `node`; a graphical
   client must also find it. If the terminal works but the plugin reports
   `spawn node ENOENT`, inspect that client's MCP logs and launch environment.
   Follow [language setup](../languages.md) and the client's supported executable
   configuration. Do not source `.zshrc` from an MCP launcher or add another
   Node installation merely to mask the failure. Retain the prior working plugin.

5. Inspect existing standalone skills and direct MCP registrations. Disable a
   duplicate main skill or server through its original client/installer controls
   before enabling the plugin. Preserve files for other clients and unrelated
   server entries. See [component ownership](../../../shared/explanation/ai-components.md).

   Expected: one active main skill and one Day One Mac MCP connection per client.
   Claude plugin skills have a namespace such as `/day-one-mac:day-one-mac`.

## Install the selected client package

Choose only the client procedure you need. Codex registrations are personal.
Claude Code offers user, project and local scopes; the examples below use
**user** scope for one person's Mac setup. For a project-owned installation,
choose `--scope project` deliberately and use that same scope for every later
update/removal. Do not install the same plugin at several scopes accidentally.

### Codex

1. Register the marketplace:

   ```bash
   codex plugin marketplace add "$PACKAGE_ROOT/codex"
   ```

   Expected: `day-one-mac-local` is registered at this source. If that name is
   already registered at another source, use the update procedure below.

2. Inspect available packages:

   ```bash
   codex plugin list --marketplace day-one-mac-local --available --json
   ```

   Expected: `day-one-mac` and its reviewed version appear.

3. Install the selected plugin:

   ```bash
   codex plugin add day-one-mac@day-one-mac-local --json
   ```

   Expected: the result identifies the installed plugin and cache location.
   Record these privately, then complete verification below.

### Claude Code

1. Validate the received marketplace:

   ```bash
   claude plugin validate "$PACKAGE_ROOT/claude" --strict
   ```

   Expected: validation succeeds. Parsing is not a security review or account test.

2. Register it:

   ```bash
   claude plugin marketplace add "$PACKAGE_ROOT/claude"
   ```

   Expected: `day-one-mac-local` points at the reviewed folder.

3. Install at the selected scope:

   ```bash
   claude plugin install day-one-mac@day-one-mac-local --scope user
   ```

   Expected: one installed plugin at user scope. Reload the session before testing.

<a id="verify-and-remove"></a>

## Verify the installed version and connection

1. Inspect the selected client's installation:

   ```bash
   codex plugin list --marketplace day-one-mac-local --json
   ```

   For Claude Code instead:

   ```bash
   claude plugin list --json
   ```

   Expected: installed/enabled status and version match the reviewed artifact,
   not merely the marketplace's advertised version. Record any scope differences.

2. Start a fresh client session. Ask it to use Day One Mac's `list_guides`, then
   `read_guide` with `{"id":"shortcuts"}`.

   Expected: the guide titles and shortcut recipe return successfully. Confirm
   the client actually called the tool; an unaided answer does not prove MCP works.

3. Inspect the tool list. The default server exposes `list_guides`, `read_guide`,
   `check_host`, `preview_desktop_click` and preview-only `desktop_click`.

   Expected: `apply_desktop_click` is absent. Do not change preferences merely to
   test discovery. A container reports Linux, not the Mac host. The skill can
   describe approved changes using other client tools, so retain their approvals.

## Update an existing installation

1. Record the current plugin version, scope and marketplace source with the list
   commands above and `plugin marketplace list` in the chosen client. Preserve
   the old artifact directory and back up the affected client configuration
   through its supported export or a verified private file copy.

   Expected: the previous source and permissions can be recovered. Do not clear
   an entire client configuration or copy authentication files between clients.

2. Review the new artifact and repeat the prerequisite checks. Set `PACKAGE_ROOT`
   to the new reviewed root. In the same shell, record the exact old artifact root:

   ```bash
   PREVIOUS_PACKAGE_ROOT="/absolute/path/to/previous-plugin-artifacts"
   ```

   Expected: both roots remain available and have different versioned contents.
   Never overwrite the old artifact in place.

3. For Codex, replace only the named marketplace registration:

   ```bash
   codex plugin marketplace remove day-one-mac-local
   ```

   Expected: only that source registration is removed. Then register the new source:

   ```bash
   codex plugin marketplace add "$PACKAGE_ROOT/codex"
   ```

   Expected: the source points at the new root. Then refresh the installed plugin:

   ```bash
   codex plugin add day-one-mac@day-one-mac-local --json
   ```

   Expected: the installed version/cache matches the new artifact. Stop after any
   error; retain the old artifacts and use recovery below. Git marketplace
   `upgrade` is not a replacement for changing a local directory source.

4. For Claude Code instead, repoint the directory source, then update at the
   existing installation scope:

   ```bash
   claude plugin marketplace add "$PACKAGE_ROOT/claude"
   ```

   Expected: the named source points at the new directory. Then run:

   ```bash
   claude plugin update day-one-mac@day-one-mac-local --scope user
   ```

   Expected: the installed version changes at user scope. Replace the scope
   only if the existing installation uses another one.

5. Reload existing sessions and repeat all verification steps. Keep the old
   source until the new skill invocation and harmless tool call work.

   Expected: unrelated skills, MCP servers and permissions remain unchanged.
   A repository commit or skill update alone does not update an installed plugin.

## Recover or remove

If an update fails, stop using the affected plugin. Preserve its error and the
new artifact for inspection. Restore the old source using
`PREVIOUS_PACKAGE_ROOT` from the update procedure:

- Codex: remove only `day-one-mac-local`, add
  `"$PREVIOUS_PACKAGE_ROOT/codex"`, then run the same `plugin add` command.
- Claude Code: add `"$PREVIOUS_PACKAGE_ROOT/claude"` as the marketplace source,
  then run the same scoped `plugin update` command.

Expected: fresh installation status and a tool call prove recovery. If the client
refuses a version downgrade, disable or remove only this plugin using its native
controls, reinstall from the preserved source at its original scope, and verify.
Do not force a downgrade by editing the cache. Restore a settings backup only
if the exact affected entries cannot be recovered through supported controls;
review newer unrelated settings before replacing anything.

For intentional removal, disable the plugin in the client's plugin manager first.
Then use the selected client's command:

```bash
codex plugin remove day-one-mac@day-one-mac-local
```

For Claude Code instead:

```bash
claude plugin uninstall day-one-mac@day-one-mac-local --scope user
```

Expected: the selected installation is absent. Remove the marketplace registration
only when no remaining installation uses it. Developer applications, Mac settings,
private notes and recovery records remain separate. Keep artifact folders until
no client depends on them and recovery is no longer needed.

## Acceptance and troubleshooting

The [client acceptance matrix](../../../shared/reference/client-acceptance.md)
distinguishes fixtures, live checks and deferred integrations. Claude Code
acceptance does not establish Claude Desktop compatibility. Native agent
activation is also separate.

| Symptom | Next action |
|---|---|
| Plugin commands are missing | Compare CLI version/help with the tested baseline; use plain skills until a supported client is available |
| Same marketplace name, different source | Preserve the old path, then use the directory-source update procedure |
| Installed version differs from the source | Check installed status/scope, rerun the selected update, then reload |
| Main skill appears twice | Review standalone versus plugin discovery; disable only the duplicate registration |
| MCP fails only in the graphical app | Inspect its log and Node executable environment; a terminal version check is insufficient |
| Tool list includes apply unexpectedly | Stop and review startup flags and duplicate direct-server registrations before use |

Sources: [Codex plugin packaging](https://developers.openai.com/plugins/build/plugins),
[Claude plugin management](https://code.claude.com/docs/en/discover-plugins).
