# Optional native Day One Mac plugins

Install the portable main skill through Codex or Claude Code's plugin manager
when you prefer native plugin lifecycle controls. These packages contain skills
and guides only. They start no MCP server and activate no agent roles.
Plain [skill installation](day-one-skills.md) remains the primary, sufficient route.

## Choose the installation route and locations

Choose one active delivery method for the main skill in each client. Use the
[native plugin](#install-the-selected-client-package) for plugin discovery and
updates, or the [Skills CLI](day-one-skills.md) for portable installation across
supported clients. Claude Desktop is not a verified target for these native
packages. The [Day One Mac MCP archive notice](../../../../integrations/mcp/README.md)
owns older server installations; external MCP services remain separate.

Keep reviewed distribution files and installed copies separate:

```text
~/Developer/Resources/Project-Materials/day-one-mac/releases/<version>/native-plugins/
~/.local/share/day-one-mac/plugins/<version>/
```

Both package roots contain `codex` and `claude` directories directly. The source
checkout may live elsewhere and is not needed by installed packages. Keep old
and new artifacts in separate stable folders; avoid Downloads or a temporary
folder as an active registration source. See the
[purpose-oriented folder guide](../development/folders.md#choose-a-layout).

## AI-assisted installation

1. Ask a client with approved local file and command access:

   ```text
   Inspect Day One Mac's existing skills and plugin registrations for my selected
   clients. Plan installation of the reviewed skill-only native plugin. Do not
   install yet. Show version, source, hashes, scope, stable paths, configuration
   backups, duplicate-skill handling, verification and recovery. Do not register
   a Day One Mac MCP server or change unrelated integrations.
   ```

   Expected: a bounded plan using the manual procedure below. Browser-only
   guidance can explain steps but cannot perform local installation.

2. Approve the named clients, reviewed artifact, paths and scope when ready.

   Expected: only the selected registration changes. Sign-in, client approvals
   and required restarts remain explicit human actions.

## Manual installation

Use only the selected client procedure. A repository change does not update an
installed package. Preserve the prior working version until verification passes.

<a id="review-the-package"></a>

## Prerequisites and package review

1. Install and sign in to the selected [AI client](clients.md), then inspect its
   version and plugin commands:

   ```bash
   codex --version
   codex plugin --help
   ```

   For Claude Code instead:

   ```bash
   claude --version
   claude plugin --help
   ```

   Expected: the required commands are available. Current client support must
   be checked locally; package parsing does not establish account-backed use.

2. Follow [receive and place a package](#receive-and-place-a-package) below.

   Expected: the package has a reviewed source, a matching archive checksum and
   a new stable version folder. Preserve older artifacts and installed skills.

3. In Terminal, select the received root. For the skill-only package version:

   ```bash
   PACKAGE_ROOT="$HOME/.local/share/day-one-mac/plugins/0.1.2"
   test -f "$PACKAGE_ROOT/codex/day-one-mac/artifact.json"
   test -f "$PACKAGE_ROOT/claude/day-one-mac/artifact.json"
   ```

   Expected: both tests return zero. Setting the variable does not copy or
   install files. Use the observed absolute path if your stable root differs.
   Review the manifests, LICENSE and main skill. The archive checksum covers
   the received files; `artifact.json` also records individual file hashes.
   There should be no `runtime`, `.mcp.json`
   or `mcp.json` in either plugin root. The native package starts no Node process;
   selected reviewed helpers have their own prerequisites.

4. Inspect duplicate main-skill discovery and back up the affected client
   configuration privately through supported controls or a verified file copy.

   Expected: one active main skill per client, without deleting shared skill
   files needed by another client. Keep credentials and notes outside packages.

## Receive and place a package

Download `day-one-mac-native-plugins-0.1.2.zip` and `SHA256SUMS` from the
[0.1.2 preview release](https://github.com/CodeByKwakes/day-one-mac/releases/tag/plugins-v0.1.2).
Confirm the repository, reviewed source commit and acceptance limits in the
release notes. This is a manual artifact handoff, with no automatic client update.
An approved maintainer handoff may also supply the ZIP, expected SHA-256 digest
and reviewed source identity.
Alternatively, follow the [contributor build and handoff](../../../shared/reference/plugin-packaging.md#prepare-a-package-handoff)
using a source snapshot that contains this plugin version. If neither source is
available, use the [plain skill installation](day-one-skills.md).

1. Put the received ZIP in Downloads and inspect its checksum:

   ```bash
   RECEIVED_ARCHIVE="$HOME/Downloads/day-one-mac-native-plugins-0.1.2.zip"
   shasum -a 256 "$RECEIVED_ARCHIVE"
   ```

   Expected: the 64-character digest exactly matches the value supplied through
   the approved channel. Stop on a mismatch. A digest from the archive itself
   cannot authenticate its publisher. Adapt the filename for another version.

2. Extract the reviewed ZIP in Finder. Open the resulting folder and confirm
   that it contains `codex` and `claude` directories directly. In Terminal, set
   `RECEIVED_ROOT` to that folder's actual path; for this example:

   ```bash
   RECEIVED_ROOT="$HOME/Downloads/day-one-mac-native-plugins-0.1.2"
   test -f "$RECEIVED_ROOT/codex/day-one-mac/artifact.json" &&
   test -f "$RECEIVED_ROOT/claude/day-one-mac/artifact.json"
   ```

   Expected: both checks succeed without output. Finder may choose a different
   folder name, so inspect it before using the example. Open `artifact.json` and
   the selected client's plugin manifest in a text editor; confirm the version
   and publisher against the reviewed handoff.

3. Copy to a new stable location. This block refuses an existing version folder:

   ```bash
   (
     set -euo pipefail
     PACKAGE_ROOT="$HOME/.local/share/day-one-mac/plugins/0.1.2"
     test -f "$RECEIVED_ROOT/codex/day-one-mac/artifact.json"
     test -f "$RECEIVED_ROOT/claude/day-one-mac/artifact.json"
     mkdir -p "$(dirname "$PACKAGE_ROOT")"
     mkdir -m 700 "$PACKAGE_ROOT"
     cp -R "$RECEIVED_ROOT/codex" "$RECEIVED_ROOT/claude" "$PACKAGE_ROOT/"
     diff -qr "$RECEIVED_ROOT/codex" "$PACKAGE_ROOT/codex"
     diff -qr "$RECEIVED_ROOT/claude" "$PACKAGE_ROOT/claude"
   )
   ```

   Expected: the copy checks show no differences. Inspect any existing parent
   directory's ownership before the copy. Do not register a partial copy after
   an error. Return to package review step 3 to set `PACKAGE_ROOT` in your
   current terminal, then use the selected client procedure.

## Install the selected client package

Codex registrations are personal. The Claude example uses user scope; choose
project or local scope only deliberately and use that same scope for updates
and removal. A Claude plugin skill has a namespace such as `/day-one-mac:day-one-mac`.

### Codex

1. Register the selected marketplace:

   ```bash
   codex plugin marketplace add "$PACKAGE_ROOT/codex"
   ```

   Expected: `day-one-mac-local` references this source. If it already points
   elsewhere, use the update procedure before changing it.

2. Inspect the available package:

   ```bash
   codex plugin list --marketplace day-one-mac-local --available --json
   ```

   Expected: the reviewed `day-one-mac` version is available.

3. Install it:

   ```bash
   codex plugin add day-one-mac@day-one-mac-local --json
   ```

   Expected: installed identity and cache location match the selected artifact.

### Claude Code

1. Validate the received marketplace:

   ```bash
   claude plugin validate "$PACKAGE_ROOT/claude" --strict
   ```

   Expected: strict validation passes. This is not a source or account review.

2. Register the selected source:

   ```bash
   claude plugin marketplace add "$PACKAGE_ROOT/claude"
   ```

   Expected: `day-one-mac-local` references the reviewed directory.

3. Install at user scope:

   ```bash
   claude plugin install day-one-mac@day-one-mac-local --scope user
   ```

   Expected: one user-scoped installation. Reload before testing discovery.

<a id="verify-and-remove"></a>
<a id="verify-the-installed-version-and-connection"></a>

## Verify the installed version and skill

1. Inspect the selected client's installed package:

   ```bash
   codex plugin list --marketplace day-one-mac-local --json
   ```

   Or, for Claude Code:

   ```bash
   claude plugin list --json
   ```

   Expected: installed/enabled state and version match the selected artifact,
   not merely a marketplace's advertised version.

2. Start a fresh client session and explicitly invoke the main skill for a
   read-only explanation of the bundled shortcut guide.

   Expected: one main skill is discovered and its bundled references resolve.
   No tool call to `list_guides` or `read_guide` is required for skill use.

3. Inspect the client's MCP list for stale Day One Mac registrations.

   Expected: this skill-only plugin introduces none. An old direct registration
   or older plugin may remain until disabled and the session refreshed. Follow
   the archive notice; do not disable external MCP servers merely because this
   particular integration is archived.

## Update an existing installation

1. Record the installed version, scope and marketplace source. Preserve the old
   artifact and private configuration backup, then review the new package.

   Expected: the previous registration can be recovered without replacing
   unrelated settings or authentication files.

2. Set `PACKAGE_ROOT` to the new stable root and record `PREVIOUS_PACKAGE_ROOT`
   as the old absolute root in your private session notes.

   Expected: both directories remain available and have different versioned contents.

3. For Codex, repoint the local marketplace, then refresh the selected package:

   ```bash
   codex plugin marketplace remove day-one-mac-local
   codex plugin marketplace add "$PACKAGE_ROOT/codex"
   codex plugin add day-one-mac@day-one-mac-local --json
   ```

   Expected: only the selected source/package changes. Stop after an error.
   A Git marketplace upgrade is not a substitute for changing a local source.

4. For Claude Code instead, repoint and update at the existing scope:

   ```bash
   claude plugin marketplace add "$PACKAGE_ROOT/claude"
   claude plugin update day-one-mac@day-one-mac-local --scope user
   ```

   Expected: the installed package reflects the selected source and scope.
   If it was disabled, enable it deliberately through supported plugin controls
   only after checking duplicate standalone-skill discovery.

5. Reload and repeat installed-version, skill-discovery and MCP-absence checks.

   Expected: the new package works. Source edits alone do not update an installed
   plugin or remove an older session's tool catalog.

## Recover or remove

For recovery, repoint the named marketplace to `PREVIOUS_PACKAGE_ROOT` and repeat
that client's refresh command. If a downgrade is refused, use supported plugin
removal and reinstall from the preserved source; do not edit client caches.
Restoring a server-bearing older version also requires reviewing its MCP policy.

For removal, disable the selected plugin through its native manager, then run
only the selected client's command:

```bash
codex plugin remove day-one-mac@day-one-mac-local
```

Or, for Claude Code:

```bash
claude plugin uninstall day-one-mac@day-one-mac-local --scope user
```

Expected: only that installation is absent. Remove its marketplace only when no
remaining installation uses it. Keep old artifacts, notes and recovery records
until recovery is no longer needed. Developer applications and Mac settings are
separate and are not uninstalled by plugin removal.

## Acceptance and troubleshooting

The [client acceptance matrix](../../../shared/reference/client-acceptance.md)
distinguishes artifact fixtures, optional native CLI checks and live invocation.

| Symptom | Action |
|---|---|
| Plugin commands missing | Inspect installed CLI help; use the plain skill route if unsupported |
| Version or source differs | Inspect installed status and use the scoped directory-source update procedure |
| Main skill appears twice | Disable only the duplicate delivery method; preserve other clients' shared files |
| Day One MCP still appears | Inspect old direct registrations, plugin version and session refresh; this package declares no server |
| Broken bundled reference | Retain the working artifact and report the selected package/version |

Sources: [Codex plugin packaging](https://developers.openai.com/plugins/build/plugins),
[Claude plugin management](https://code.claude.com/docs/en/discover-plugins).
