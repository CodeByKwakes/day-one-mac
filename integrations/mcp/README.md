# Day One Mac MCP server

Use this optional stdio server to read Day One Mac recipes, check the process's
platform, and preview desktop wallpaper-click behaviour. Native execution can
apply that single preference after explicit approval. This package is a requested
optional integration; normal guide and skill users need no server or checkout.

Day One Mac already has a defined purpose: Apple-silicon macOS development setup
through canonical manual recipes and portable skills. Homebrew, shell, Git and
application installation stay guided tasks. The server has no package installer,
arbitrary command tool, filesystem browser, whole-machine runner or background
service. Building or registering it does not perform setup on the Mac.

## Ownership and configuration

This is an executable integration, not an agent or a native Codex/Claude plugin
package. Its prompts carry workflow instructions; tools and resources belong to
the server. Agent roles consume these interfaces without owning registrations.

The reviewed `config/mcp/day-one-mac.json` owns guide sources, client names,
timeouts and the default read-only tool list. Builds copy it into the independent
package. Configuration output prints client-native entries without writing any
client settings. Merge only the selected entry, inspect existing direct/Docker
registrations, and keep credentials outside repository files. Do not symlink
Codex TOML to Claude JSON or VS Code settings.

Generated Codex configuration uses `enabled_tools` to allow only the four modern
read-only tools. To enable an approved native preference change, separately review
the startup flags and add `apply_desktop_click` to that client allowlist. Claude
Code and VS Code retain their own permission controls; no model-supplied string
can establish human approval. Local Claude Code is the compatibility target;
Claude Desktop and hosted clients need separate acceptance.

## Part 1: Capabilities

All tool results contain JSON in a text content block. Errors use `isError: true`.
Inputs below are JSON arguments; outputs are abbreviated examples, not live
machine evidence.

| Tool | Purpose | Example input | Example output |
|---|---|---|---|
| `list_guides` | List the bundled recipes | `{}` | `[{"id":"macos","title":"Prepare macOS","uri":"day-one-mac://guide/macos","source":"docs/setup/manual/macos.md"}, ...]` |
| `read_guide` | Read one guide by ID | `{"id":"macos"}` | `{"id":"macos","title":"Prepare macOS","source":"docs/setup/manual/macos.md","text":"# Prepare macOS\n..."}` |
| `check_host` | Read OS/architecture and native macOS version | `{}` | `{"platform":"darwin","arch":"arm64","native_mac":true,"macos":"26.7.1",...}` |
| `preview_desktop_click` | Preview one wallpaper-click preference without writes | `{"mode":"stage-manager-only"}` | `{"dry_run":true,"before":true,"desired":false,"preview_token":"<UUID>","expires_in_seconds":60,...}` |

`apply_desktop_click` is advertised only with startup opt-in and private backups.
It accepts `mode`, `preview_token` and `confirmation`; it cannot create a preview.
The compatibility tool `desktop_click` remains available: its default-process
schema accepts previews only. With startup opt-in it retains the original mixed
interface. Prefer the separate tools for precise client permissions.

The catalogue resource is `day-one-mac://catalog`. Reading it with
`{"uri":"day-one-mac://catalog"}` returns the same list as `list_guides`.
The thirteen other resources use `text/markdown`:

| Resource URI | Purpose | Example read input | Example output text |
|---|---|---|---|
| `day-one-mac://guide/macos` | macOS preferences and protection | `{"uri":"day-one-mac://guide/macos"}` | `# Prepare macOS` followed by the recipe |
| `day-one-mac://guide/homebrew` | Apple tools and Homebrew | `{"uri":"day-one-mac://guide/homebrew"}` | Homebrew recipe Markdown |
| `day-one-mac://guide/shell` | Zsh configuration | `{"uri":"day-one-mac://guide/shell"}` | Zsh recipe Markdown |
| `day-one-mac://guide/git` | Git configuration and access | `{"uri":"day-one-mac://guide/git"}` | Git recipe Markdown |
| `day-one-mac://guide/vscode` | VS Code profiles and formatting | `{"uri":"day-one-mac://guide/vscode"}` | VS Code recipe Markdown |
| `day-one-mac://guide/apps` | Route application setup | `{"uri":"day-one-mac://guide/apps"}` | Application index Markdown |
| `day-one-mac://guide/verification` | Setup verification criteria | `{"uri":"day-one-mac://guide/verification"}` | Verification guide Markdown |
| `day-one-mac://guide/shortcuts` | App recipes and Send to Archive | `{"uri":"day-one-mac://guide/shortcuts"}` | macOS shortcut guide Markdown |
| `day-one-mac://guide/skills` | Skill installation and maintenance boundaries | `{"uri":"day-one-mac://guide/skills"}` | Skill guide Markdown |
| `day-one-mac://guide/mcp` | Native client registration | `{"uri":"day-one-mac://guide/mcp"}` | MCP connection guide Markdown |
| `day-one-mac://guide/workspaces` | Desk calibration and layout recovery | `{"uri":"day-one-mac://guide/workspaces"}` | Workspace guide Markdown |
| `day-one-mac://guide/atticus` | Optional voice pilot | `{"uri":"day-one-mac://guide/atticus"}` | Atticus guide Markdown |
| `day-one-mac://guide/components` | Product and personal toolkit boundaries | `{"uri":"day-one-mac://guide/components"}` | Component reference Markdown |

Resource responses wrap text in `contents: [{uri, mimeType, text}]`. These are
build-time snapshots of allowlisted public guides. Their relative links refer to
the canonical repository documentation; this package bundles only the listed guides. Rebuild after changing those sources.

| Prompt | Purpose | Example arguments | Example output |
|---|---|---|---|
| `setup_plan` | Plan a selected capability using its guide | `{"topic":"git"}` | User message containing the guide and instructions to inspect ownership, preview changes and seek approval |
| `troubleshoot_setup` | Investigate before repairing | `{"symptom":"Windows move when I click the wallpaper"}` | User message requesting reproduction, relevant guide and a recoverable repair preview |

Prompts return `messages: [{role: "user", content: {type: "text", text: ...}}]`.
`topic` accepts the same thirteen IDs as `read_guide`; symptoms are 1-2000 characters.
All tool and prompt argument objects reject unknown keys.

### Safety and confirmation

The default process exposes only read-only tools. `preview_desktop_click`
always previews; the compatibility `desktop_click` defaults to `dry_run: true`
and rejects `false` without startup opt-in. The preference tools accept only `always` or `stage-manager-only`, and addresses only
`com.apple.WindowManager` / `EnableStandardClickToShowDesktop` as a boolean.
It does not toggle Stage Manager or restart Window Manager.

An application requires every condition below:

1. A native `darwin` / `arm64` process started with `--allow-changes` and `--backup-dir`.
2. An existing, user-owned backup directory with mode `700` and no symlink components.
3. A preview from the same running server, less than 60 seconds old, for the same desired value.
4. Human approval in the client's tool confirmation UI, followed by a call to
   `apply_desktop_click` with these arguments:

   ```json
   {
     "mode": "stage-manager-only",
     "preview_token": "UUID_FROM_THE_PREVIEW",
     "confirmation": "APPLY DESKTOP CLICK"
   }
   ```

5. An unchanged original preference and an exclusive per-user lock.

The token is single-use. At most 16 unexpired previews are retained per process.
The server writes a private recovery record before mutation, checks for drift
again, and reads the saved value afterward. A failed write or verification keeps
that record and returns an error. Filesystem backups are `600`; no whole
preference domain is copied. A missing key is recorded as `null`, separately from
an existing `false` value. Unexpected types and command errors stop the operation.

The confirmation string proves the caller supplied it, not that a human did.
Keep client write approvals enabled; do not auto-approve `apply_desktop_click` or the mutation-enabled
compatibility `desktop_click`.
Managed-device authorization remains the operator's responsibility. The server
cannot determine who approved a tool call or override OS/client policy.

All mutation-enabled instances share a fixed per-user lock at
`~/Library/Caches/day-one-mac-mcp/desktop-click.lock`, independently of their
backup directories. Its parent directory is private and user-owned. If an
operation crashes, inspect recovery records and confirm no instance is writing
before removing a stale lock. The server never clears it automatically.

### Recovery

Open the returned backup JSON privately. Its `restore` array records the command
and arguments for the exact original value. For an existing boolean, run the
reviewed command below, replacing `true` with the recorded value if necessary:

```bash
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool true
```

If `before` was `null`, remove only the introduced key:

```bash
defaults delete com.apple.WindowManager EnableStandardClickToShowDesktop
```

Do not execute backup contents as shell code. Verify the preference in System
Settings and test a wallpaper click. The saved value alone does not establish
working behaviour; follow the macOS guide if Window Manager needs refreshing.
Retain backups until recovery and normal operation are verified.

## Part 2: Implementation

TypeScript matches the repository's Node contributor tooling and provides typed
inputs through the official MCP SDK and Zod. Dependencies are exact versions in
`package.json` and resolved in `npm-shrinkwrap.json`. The implementation uses the
SDK's stdio transport, validated tools, static resources and prompts.

| File | Responsibility |
|---|---|
| `package.json`, `npm-shrinkwrap.json` | Pinned dependencies and build/test/start commands |
| `tsconfig.json` | Strict TypeScript build |
| `src/index.ts` | Validate startup flags, load bundled guides and serve stdio |
| `src/configure.ts` | Resolve local executables and print client configurations |
| `src/server.ts` | Full tool/resource/prompt implementation and bounded preference operation |
| `scripts/bundle-guides.mjs` | Package reviewed canonical guides from the shared specification; reject symlink sources |
| `test/server.test.ts` | Safety fixtures and real stdio protocol test |
| `test/docker-smoke.ts` | Check discovery and macOS-operation denial in the final image |
| `test/package-smoke.ts` | Inspect and install the real tarball outside the checkout |
| `scripts/image-artifact.mjs` | Build and export versioned images locally |
| `scripts/package-artifact.mjs` | Pack the MCP directory explicitly and validate its identity and contents |
| `Dockerfile`, `compose.yaml` | Unprivileged Linux guide server |

The server executes only fixed absolute macOS binaries with argument arrays,
a five-second timeout and bounded output. It never uses shell interpolation.
Stdout is reserved for MCP messages; startup failures go to stderr.

## Part 3: Client integration

Replace `/absolute/path/day-one-mac` with the checkout path printed during native
installation. The examples use Homebrew executable paths; resolve your installed
executables before copying them. Node version managers can expose temporary
shell paths, so resolve Node's installation path rather than copying a temporary
launcher. Paths with spaces stay a single JSON argument. JSON/TOML strings do
not expand `$HOME` or `~`; use absolute paths.

### Generate configurations with this machine's paths

The configuration utility prints settings for the current machine. It never
writes client files, registers a server or starts Docker.

From a source checkout, build first and run:

```bash
npm --prefix integrations/mcp run build
node integrations/mcp/dist/src/configure.js --client all
```

From a persistent tarball installation, use its installed utility as described
in the installation section. The default `direct` launch uses the installed
server and resolves Node's real executable path. It does not depend on a clone.

| Option | Default | Usage |
|---|---|---|
| `--client` | `all` | Print `all`, `claude`, `codex`, `vscode` or `raycast`; Codex-only output is TOML, other output is JSON |
| `--launch` | `direct` | Choose an installed server, a pinned npm registry package (`npm`), or the local Docker image (`docker`) |
| `--npm-cli` | Detected | With `--launch npm`, supply an absolute `npm-cli.js` path when automatic discovery fails |
| `--image` | `day-one-mac-mcp:0.1.1` | With `--launch docker`, select an image tag or digest |
| `--help` | Off | Print usage without generating configurations |

Examples from a source build:

```bash
node integrations/mcp/dist/src/configure.js --client codex
node integrations/mcp/dist/src/configure.js --client vscode --launch npm
node integrations/mcp/dist/src/configure.js --client raycast --launch docker
```

Registry launch output pins this package version and sets the child process's
PATH to include its resolved Node installation. It is a configuration preview,
not proof that the release exists in npm. Verify package ownership and release
availability before using it. No registry release is required for `direct` mode.

Merge only the selected server entry into existing client settings. For Raycast,
copy the command, arguments and any environment entries into its installation
form. Keep generated output private because it contains machine-specific paths.
Regenerate it after removing the selected Node installation or moving the
installed package. Docker output resolves the executable from PATH and preserves
its launcher path across package-manager upgrades.

### Claude Code

Run from the intended project, after reviewing an existing configuration:

```bash
claude mcp add --transport stdio --scope local day-one-mac -- \
  /opt/homebrew/bin/node /absolute/path/day-one-mac/integrations/mcp/dist/src/index.js
claude mcp get day-one-mac
```

Local scope is personal to this project. Use `--scope user` deliberately for
all projects, or `--scope project` for a reviewed shared `.mcp.json`.
The corresponding JSON server entry is:

```json
{
  "mcpServers": {
    "day-one-mac": {
      "command": "/opt/homebrew/bin/node",
      "args": ["/absolute/path/day-one-mac/integrations/mcp/dist/src/index.js"]
    }
  }
}
```

In Claude Code, `/mcp` shows connection status; resource and prompt UI availability
can differ by client/runtime version. Do not copy this into Claude Desktop's
configuration without reviewing that separate client's format and scope.

### Codex

Merge into personal `~/.codex/config.toml`, or a trusted project's
`.codex/config.toml`. This is TOML, separate from VS Code editor settings:

```toml
[mcp_servers.day_one_mac]
command = "/opt/homebrew/bin/node"
args = ["/absolute/path/day-one-mac/integrations/mcp/dist/src/index.js"]
startup_timeout_sec = 20
tool_timeout_sec = 15
```

Alternatively, register the personal configuration with the supported CLI:

```bash
codex mcp add day_one_mac -- /opt/homebrew/bin/node \
  /absolute/path/day-one-mac/integrations/mcp/dist/src/index.js
codex mcp list
```

The app, IDE extension and CLI share Codex configuration. Refresh the server or
start a new session after registration. Resource/prompt presentation varies;
the guide tools cover clients that expose tools only.

### VS Code

Merge this compatibility configuration into `.vscode/mcp.json`, or use
**MCP: Open User Configuration** for personal/profile scope:

```json
{
  "servers": {
    "day-one-mac": {
      "type": "stdio",
      "command": "/opt/homebrew/bin/node",
      "args": ["/absolute/path/day-one-mac/integrations/mcp/dist/src/index.js"]
    }
  }
}
```

Run **MCP: List Servers**, select this server, and start it after reviewing trust
and tool permissions. This configures VS Code's MCP client, not the Codex
extension's separate MCP configuration. Add each only when that client needs it.
Current portable `.mcp.json` flows use a different wrapper; do not duplicate
one server in both locations. Managed policy can restrict available tools.

### Raycast

Raycast Desktop's native **Install MCP Server** command supports this package;
no custom extension is required. MCP requires Raycast Pro. Enter:

```text
Name: day-one-mac
Transport: Standard Input/Output
Command: /opt/homebrew/bin/node
Arguments: /absolute/path/day-one-mac/integrations/mcp/dist/src/index.js
```

Keep the absolute script path as one argument when it contains spaces. Use
**Manage MCP Servers** to verify the tool list and connection output, then ask
`@day-one-mac list the setup guides`. Raycast iOS supports HTTP servers only;
this stdio implementation targets Desktop. Restart Raycast after changing PATH,
or use the absolute executable path above. Configure write-tool permissions
separately from the server's startup opt-in.

### Enable the native preference operation deliberately

Create the shared private directory outside the checkout and installed skills:

```bash
mkdir -p "$HOME/Library/Application Support/Day One Mac Backups/MCP"
chmod 700 "$HOME/Library/Application Support/Day One Mac Backups/MCP"
```

After inspecting ownership and symlinks, append these arguments to the native
server entry in the selected client, substituting the absolute backup path:

```json
[
  "/absolute/path/day-one-mac/integrations/mcp/dist/src/index.js",
  "--allow-changes",
  "--backup-dir",
  "/absolute/private/backup/directory"
]
```

Preview first, approve the exact value, and apply with the returned token within
60 seconds. Removing the flags and restarting returns the server to read-only
execution. Client registration and these startup flags never change the Mac by
themselves.

## Part 4: Installation

### Method A: Native macOS

Use a prebuilt tarball on another MacBook. The receiving Mac needs approved
Node.js 22.20+ and npm, but no clone, TypeScript compiler or global npm package.
The tarball includes compiled code, guide snapshots, a licence and dependency
shrinkwrap. Installation still needs access to the dependencies' npm registry,
or a previously populated npm cache.

Copy the tarball and its checksum file into a new folder on the receiving Mac.
From that folder, verify and install the reviewed artifact:

```bash
shasum -a 256 -c day-one-mac-mcp-0.1.1.tgz.sha256
mkdir -p "$HOME/.local/share/day-one-mac-mcp"
npm install --prefix "$HOME/.local/share/day-one-mac-mcp" \
  --ignore-scripts --no-audit --no-fund ./day-one-mac-mcp-0.1.1.tgz
node "$HOME/.local/share/day-one-mac-mcp/node_modules/day-one-mac-mcp/dist/src/configure.js" \
  --client all
```

The last command prints the four clients' native configurations with this Mac's
actual paths. Review and merge the selected entry. Keep the installation folder
while clients reference it. Back up existing client settings before merging.
Use an empty install directory for the first installation; review an existing
installation before updating it.

#### Build and test from source

Contributors use the checkout containing this integration. A new clone can only
contain code already available on the remote:

```bash
git clone https://github.com/CodeByKwakes/day-one-mac.git day-one-mac
cd day-one-mac
npm --prefix integrations/mcp ci --ignore-scripts --no-audit --no-fund
npm --prefix integrations/mcp test
npm --prefix integrations/mcp run test:package
node integrations/mcp/dist/src/configure.js --client all
```

The package test packs and installs a tarball in a temporary directory with
spaces and Unicode, then verifies executable entries, guide access and stdio
outside the checkout. It also checks that development dependencies are absent.
Package acceptance can read public npm registry metadata and use cached
dependencies; it performs no registry publication or client registration.

To create a local tarball, choose a new output directory outside installed skills:

```bash
ARTIFACT_PARENT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-mac-mcp-artifacts.XXXXXX")"
npm --prefix integrations/mcp run package:local -- "$ARTIFACT_PARENT/package"
```

The command builds first, checks the package identity and contents, then writes
a tarball and checksum into a newly reserved directory. The package file allowlist excludes tests, source
checkout files, dependency directories and private output. The shrinkwrap records
exact dependencies; consumers do not need to build the server after installation.
No package install lifecycle script is required.

#### Registry installation after an approved release

The following is a future release command, not a claim that this package name or
version is currently published by the intended owner:

```bash
npx --yes --ignore-scripts --package=day-one-mac-mcp@0.1.1 \
  day-one-mac-mcp-configure --client all --launch npm
```

The output can launch the pinned package without a persistent checkout. Upgrades
are explicit: review the next release, update the selected version and regenerate
client settings. Keep private preference recovery records across upgrades.

### Method B: Docker

Run from the repository root with an approved, running Docker installation:

```bash
npm --prefix integrations/mcp run image:build
docker run -i --rm --read-only --cap-drop=ALL \
  --security-opt=no-new-privileges day-one-mac-mcp:0.1.1
```

After building native test dependencies and artifacts, verify the final image
with `npm --prefix integrations/mcp run test:docker`. CI builds the image and
runs this same smoke test, in addition to the macOS and Linux safety fixtures.

To move the locally built image to another MacBook without a registry, export
it to a new absolute output directory:

```bash
IMAGE_PARENT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-mac-mcp-image.XXXXXX")"
npm --prefix integrations/mcp run image:export -- "$IMAGE_PARENT/transfer"
```

Copy the resulting `.tar` and `.sha256` files to the receiving Mac. In that folder:

```bash
shasum -a 256 -c day-one-mac-mcp-0.1.1-docker.tar.sha256
docker image load --input day-one-mac-mcp-0.1.1-docker.tar
```

The native image build matches its builder's platform; use the arm64 artifact
built on an Apple-silicon MacBook for other Apple-silicon MacBooks. No image is
uploaded by either artifact command.

The base image is pinned by digest. The build runs the same tests in Linux. The final image uses a non-root user,
contains only production dependencies and server/guide artifacts, and starts a
stdio process. Do not add `-t`: a pseudo-terminal can corrupt protocol framing.
No host volumes, Docker socket or published ports are required.

For any stdio client above, replace the native command and arguments with:

```json
{
  "command": "/opt/homebrew/bin/docker",
  "args": ["run", "-i", "--rm", "--read-only", "--cap-drop=ALL", "--security-opt=no-new-privileges", "day-one-mac-mcp:0.1.1"]
}
```

Retain VS Code's outer `servers` wrapper and `type: "stdio"`, or Claude's
`mcpServers` wrapper. For Codex, the equivalent table is:

```toml
[mcp_servers.day_one_mac]
command = "/opt/homebrew/bin/docker"
args = ["run", "-i", "--rm", "--read-only", "--cap-drop=ALL", "--security-opt=no-new-privileges", "day-one-mac-mcp:0.1.1"]
startup_timeout_sec = 60
```

In Raycast, use the Docker command and enter those same arguments in order.
Replace the Docker executable path with `command -v docker` if different.
Each client starts its own disposable container. Do not use `docker compose up`
as a shared stdio endpoint. The optional `compose.yaml` supports a foreground
one-off process:

```bash
docker compose -f integrations/mcp/compose.yaml run --rm -T day-one-mac
```

Linux containers cannot run macOS `defaults` or configure the Mac host.
`check_host` reports the container and `desktop_click` rejects both previews and
changes there. Use Docker for guides and planning; use a separately approved
native connection for macOS checks and preference operations. Mounting the host
filesystem does not turn Linux commands into macOS commands.

Stdio keeps the process local, needs no listening port or HTTP authentication,
and fits all four desktop clients. HTTP could share one service across clients,
but requires a separately implemented transport, session handling and deployment
authentication. This package implements stdio only; there is no HTTP URL, port,
SSE endpoint or unauthenticated network service to configure.

## Part 5: Verification and troubleshooting

After building, `npm --prefix integrations/mcp test` must pass the safety fixtures
and a real stdio client handshake. These tests use temporary directories and
simulated preference writes; they do not establish live Mac behaviour or client
account access.

For each selected client:

1. Check connection status: Claude `/mcp`, Codex `codex mcp list`, VS Code **MCP: List Servers**, or Raycast **Manage MCP Servers**.
2. The default server advertises five tools: `list_guides`, `read_guide`, `check_host`,
   `preview_desktop_click` and compatibility `desktop_click`. All are annotated
   read-only. Generated Codex configuration exposes only the four modern tools
   through its allowlist. Startup opt-in adds `apply_desktop_click` and makes the legacy
   interface mutation-capable; the preview tool remains read-only.
3. Call `list_guides` with `{}`, then `read_guide` with `{"id":"macos"}`.
4. Call `check_host` and confirm whether the process is native or containerized.
5. Where supported, read `day-one-mac://catalog` and request `setup_plan` with `{"topic":"git"}`. The server advertises fourteen resources and two prompts.
6. On native Apple silicon, call `preview_desktop_click` with `{"mode":"stage-manager-only"}` and confirm `dry_run: true`. Do not apply merely to test discovery.

| Error or symptom | Fix |
|---|---|
| `ENOENT`, missing module, or missing `guides.json` | Run locked dependency installation and build; check the absolute Node/script paths and quoting |
| No tools, connection timeout, or invalid JSON | Reserve stdout for MCP; run the entry point directly rather than through a logging wrapper; inspect the client's server stderr |
| Docker cannot connect or reports Linux | Start the approved Docker service for guide access; use native Node for macOS checks and mutations |
| Changes disabled, expired token, drift or lock | Keep read-only mode unless selected; use a private backup directory, review a fresh preview and approve it; inspect active operations before addressing a stale lock |
| npm reports a certificate-chain error | Use the organisation-approved trust chain; where supported, `NODE_USE_SYSTEM_CA=1 npm ci --ignore-scripts` uses system trust. Keep TLS verification enabled |

### Primary references

Client and SDK formats were checked on 27 October 2026:

- [Official TypeScript SDK](https://ts.sdk.modelcontextprotocol.io/v2/), including tools, resources, prompts and stdio.
- [Claude Code MCP](https://code.claude.com/docs/en/mcp).
- [Codex MCP](https://learn.chatgpt.com/docs/extend/mcp).
- [VS Code MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers).
- [Raycast MCP](https://manual.raycast.com/ai/model-context-protocol).
