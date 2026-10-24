[← MCP module](../../assisted/optional/11-mcp-servers.md) · [Direct connections](mcp.md) · [Documentation index](../../../README.md)

# Set up MCP servers with Docker

**Type:** how-to · **Audience:** Mac developers and administrators ·
**Time:** 30-60 minutes for one server and one client.

**Outcome:** a reviewed Docker MCP profile provides selected tools to VS Code,
Claude Code or Codex, with a successful low-impact tool call in each selected
client. Start with a disposable project and public information.

Before connecting a client, install and sign in to your selected applications
using the [manual AI client task](clients.md). Install only the clients
you intend to use. Client availability, account access and organisation policy
are separate prerequisites from Docker readiness.

This is a **shared manual action**: both Day One Mac routes use the Docker and
client steps below. Module 11 still generates **HTTPS-only workspace snippets**;
its `--apply` does not create Docker profiles or activate clients, and its
`--check` does not verify this Docker setup. No Day One Mac checkout is needed.

Instructions were checked against official documentation on **19 October 2026**
and command help from **Docker MCP CLI 0.44.1**. Toolkit remains a beta feature.
Use the version checks below; a different release can expose different controls.
[Docker Toolkit overview](https://docs.docker.com/ai/mcp-catalog-and-toolkit/).

## 1. Choose the connection route

| Route | Choose it when | What runs locally |
|---|---|---|
| Hosted HTTP | The publisher provides a suitable managed endpoint | Client; no local server container |
| Direct stdio | A tool needs the project's installed runtime or an IDE | Publisher's local process, such as Angular/Nx or DataGrip |
| Docker MCP Toolkit | You want reviewed container servers managed through a named profile | Docker Desktop, gateway and selected server containers |

Use [Module 11](../../assisted/optional/11-mcp-servers.md) for hosted connections and
[the direct connection reference](mcp.md) for project launchers.
Do not keep direct and Docker copies of the same server active accidentally.
DataGrip's built-in MCP remains an IDE service; installing Docker does not move
its connections into containers. DBeaver's normal SQL workflow also does not
require MCP.

```text
VS Code / Claude Code / Codex
            │ stdio: client starts a gateway process
            ▼
Docker MCP Gateway → explicitly named profile
            │
            ▼
Selected MCP server containers → permitted files / websites / APIs
```

A Docker profile can also contain remote services; those services do not become
locally containerized. Profiles group configuration; they are not separate OS
accounts or proof of credential isolation. The gateway manages server startup
and routing. [Gateway architecture](https://docs.docker.com/ai/mcp-catalog-and-toolkit/mcp-gateway/).

**OmniRoute and MCP Gateway have different jobs.**
[OmniRoute](omniroute.md) routes model requests. Docker MCP
Gateway supplies tools. Neither is a prerequisite for the other.

## 2. Check Docker and the selected engine

This guide's supported recipe uses **Docker Desktop with MCP Toolkit enabled**.
Use Desktop **4.63 or later** with the profile controls shown in Docker's
[profile guide](https://docs.docker.com/ai/mcp-catalog-and-toolkit/profiles/).
The getting-started page describes an earlier 4.62 UI floor; 4.63 is the more
conservative requirement for this profile-based procedure.

For a new installation, follow the engine selection in
[manual container setup](../databases/containers.md).
Installing a database is unnecessary for MCP. Use the Apple-silicon Docker
Desktop build, complete first-run prompts, then enable **Settings → Beta
features → Enable Docker MCP Toolkit → Apply**. Labels can vary by release.
[Docker setup](https://docs.docker.com/ai/mcp-catalog-and-toolkit/get-started/).

On a managed Mac, use the IT-approved Desktop installation, licensing and MCP
policy. Do not bypass a disabled feature or change an organisation's proxy,
certificate, endpoint-security or device-management configuration.

Inspect the installation before changing anything:

```bash
docker --version
docker context show
docker context ls
docker mcp version
docker mcp profile --help
docker mcp gateway run --help
```

Confirm `desktop-linux` is the local Docker Desktop context. Inspect its
endpoint, then check that the engine responds:

```bash
docker context inspect desktop-linux --format '{{.Endpoints.docker.Host}}'
docker --context desktop-linux info --format '{{.OSType}} / {{.Architecture}}'
```

Expect a local Unix-socket endpoint and a Linux engine using ARM architecture.
Stop if the context is missing, remote or unexpected. A successful
`docker --version` proves only that the CLI exists. Start the approved Docker
Desktop application if the engine is stopped; retry its health check.

The client examples specify `--context desktop-linux` so they do not silently
follow a different default engine. They do not change your default context.
Investigate inherited `DOCKER_HOST`, `DOCKER_CONTEXT` or `DOCKER_CONFIG` overrides
before setup; a GUI client and a terminal can use different environments.
Do not change the recorded engine of existing Module 9/10A resources as a side
effect of configuring MCP.

### If you use OrbStack

Day One Mac supports OrbStack for other container workflows. That does not
establish parity with Docker Desktop's Toolkit UI, profiles and credential
integration. Docker documents a separately installed gateway for Docker Engine,
but this guide does **not** validate an OrbStack gateway recipe. Keep your
existing workload on its engine; use the direct/hosted route, or arrange an
approved Desktop setup and explicitly select its context for MCP.
[Standalone gateway requirements](https://docs.docker.com/ai/mcp-catalog-and-toolkit/mcp-gateway/).

## 3. Review one server before connecting clients

Use **MCP Toolkit → Catalog** to inspect the publisher, server ID, image,
required settings, secrets and exposed tools. The CLI can show the same server
metadata. This example uses the catalog's Playwright server for a public-page
check; use it only if browser automation is useful to you:

```bash
docker mcp catalog server ls mcp/docker-mcp-catalog:latest --filter name=playwright
docker mcp catalog server inspect mcp/docker-mcp-catalog:latest playwright
```

These discovery commands can retrieve registry metadata. If `playwright` is
absent or has changed, stop and review the current entry instead of substituting
an unrelated image. `latest` is used here for discovery, not as a reproducibility
promise. Record the reviewed catalog reference, server ID, image reference and
resolved digest before sharing a team setup.

Review these boundaries for every selected server:

| Boundary | Required decision |
|---|---|
| Publisher and image | Check source/provenance and Apple-silicon support; do not force x86 emulation just to hide a missing build |
| Files | Prefer no host mount; otherwise expose one necessary directory, read-only if possible; exclude credentials and unrelated repositories |
| Docker control | Do not grant a tool server the Docker socket or privileged mode merely to make it work; the trusted gateway itself needs engine access |
| Network | List the destinations needed; containerization alone does not stop data leaving the Mac |
| Accounts | Use the least privileged service account, OAuth grant or API token appropriate to the task |
| Tools | Enable only needed tools and keep client approval controls on |
| Resources | Start with one server and inspect actual CPU, memory and startup time before expanding |

Catalog inclusion is useful evidence, not a guarantee that a server is safe for
your data. Keep signature verification enabled; investigate signature failures
instead of disabling the check. Docker describes catalog assurance as best
effort. [Security FAQ](https://docs.docker.com/ai/mcp-catalog-and-toolkit/faqs/).

### Prevent agents from adding unreviewed servers

Docker's **Dynamic MCP** can expose management tools such as `mcp-add` and
`mcp-config-set`. A small saved profile alone does not constrain those tools.
Check the feature state, record its previous value, and disable dynamic tools
for this deliberately selected-server setup:

```bash
docker mcp feature ls
docker mcp feature disable dynamic-tools
```

This setting affects the local Toolkit, including other connected clients;
coordinate it on a shared setup. Restart existing gateway/client sessions after
changing it. Verify that management tools are absent before the first request.
If policy prevents that, stop and obtain an administrator-approved restriction.
[Dynamic MCP controls](https://docs.docker.com/ai/mcp-catalog-and-toolkit/dynamic-mcp/).

## 4. Create and configure a profile

Choose a new ID for your disposable project. The example uses
`day-one-sandbox`; replace it consistently if it already belongs to another
workflow. List existing profiles privately, then create only if the ID is free:

```bash
docker mcp profile list
docker mcp profile create --name day-one-sandbox --id day-one-sandbox
docker mcp profile server add day-one-sandbox \
  --server catalog://mcp/docker-mcp-catalog:latest/playwright
docker mcp profile show day-one-sandbox
```

These commands write Docker's profile configuration. They do not connect an AI
client. The CLI syntax is also described in
[Docker's CLI guide](https://docs.docker.com/ai/mcp-catalog-and-toolkit/cli/).

In **Profiles → day-one-sandbox**, resolve any configuration-required indicator.
Use the server's own field names and documented types; there is no universal
allowed-path or database setting. Under **Tools**, turn off unnecessary tools.
For the initial Playwright check, retain only those needed to open a public
page, inspect its title and close that test session. Avoid real browser profiles,
signed-in sessions, uploads and private URLs.

For later command-line changes, inspect `docker mcp profile tools --help` and
use the exact `server.tool` names shown by your installed server. Do not guess
tool names from an example for another release.

### Credentials and databases

Use Docker's server configuration/authentication interface for OAuth and secret
inputs. If using the CLI, `docker mcp secret set KEY` accepts secret data on
standard input; check its help and feed it through your approved secret manager.
Do not type literal values into commands, export files or `profile config --set`.
Avoid plaintext temporary files and shell tracing when supplying secrets.

Docker documents that **OAuth credentials are shared across profiles**. A
`dev` and a `prod` profile are therefore not independent account boundaries.
For work/personal separation, follow the organisation's approved account and
credential isolation design. [Profile credential scope](https://docs.docker.com/ai/mcp-catalog-and-toolkit/profiles/).

Keep database MCP off production by default. Begin with synthetic local data
and a restricted database role. A server's read-only option is an extra control,
not a replacement for database permissions. Use the
[PostgreSQL guide](../databases/postgresql.md) for environment roles/TLS and the
[operations guide](../databases/operations.md) for controlled access.
Inside a container, `localhost` identifies that container; do not copy a host
connection string or broaden a database's network exposure to fix a failed
connection. Establish the approved container-to-database route separately.

### Check startup before client activation

After reviewing the server, run:

```bash
docker --context desktop-linux mcp gateway run \
  --profile day-one-sandbox --verify-signatures --dry-run
```

**This is a startup test, not a read-only preview.** The installed CLI describes
`--dry-run` as starting the gateway without listening; it can pull images, start
servers and contact services. It does not prove a client handshake or tool call.
Use it only after the preceding review, resolve errors, and stop the process
with `Ctrl-C` if it remains active. Treat output as potentially sensitive.

## 5. Connect only the clients you use

Back up each existing destination privately before editing it. Merge just the
new entry; retain unrelated servers/settings. Use one route per client.
The examples below use stdio: the client launches the gateway on demand.
Do not add `--port`, an HTTP listener or a detached background launcher.

### VS Code and Copilot

Open the intended **local** project. Run **MCP: Add Server → Command (stdio)**
and enter:

```text
docker --context desktop-linux mcp gateway run --profile day-one-sandbox
```

Use `day-one-docker` as the server ID. Select **Workspace → .mcp.json** when
available; current VS Code exposes this through
`chat.mcp.workspaceRootConfig.enabled`. For personal use across projects,
**Global → Copilot Global** writes outside the repository instead. Follow your
organisation's policy for experimental settings.
[VS Code destinations](https://code.visualstudio.com/docs/copilot/customization/mcp-servers).

The portable file uses this structure:

```json
{
  "mcpServers": {
    "day-one-docker": {
      "command": "docker",
      "args": ["--context", "desktop-linux", "mcp", "gateway", "run", "--profile", "day-one-sandbox"]
    }
  }
}
```

For a Local harness or a release without that destination, use
`.vscode/mcp.json` instead, with the top-level `servers` object and an explicit
`"type": "stdio"` inside the server entry. Do not put this in `settings.json` or
rename the portable file without changing its schema.
[VS Code format reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

Review trust, use **MCP: List Servers** to start/inspect the entry, and select
only the required tools in the current chat. A Dev Container, SSH window or
cloud session runs in a different environment; this local Mac recipe does not
grant it Docker access. Do not mount the host Docker socket to work around that.

### Claude Code

From the intended project, register the reviewed launcher:

```bash
claude mcp add --scope project day-one-docker -- \
  docker --context desktop-linux mcp gateway run --profile day-one-sandbox
```

This writes `.mcp.json`. If the portable entry above already exists there,
reuse it instead of adding a second definition. Open Claude in that project,
review its server approval, then inspect `/mcp`. Use `--scope user` only when
you deliberately want the same profile available across projects.
[Claude scopes and stdio setup](https://code.claude.com/docs/en/mcp).

### Codex CLI and editor extension

Merge into the trusted project's `.codex/config.toml`:

```toml
[mcp_servers.day-one-docker]
command = "docker"
args = ["--context", "desktop-linux", "mcp", "gateway", "run", "--profile", "day-one-sandbox"]
startup_timeout_sec = 60
enabled = false
```

Keep it disabled while reviewing. Once the profile/startup checks pass, change
only this entry to `enabled = true` and start a new session in the trusted
project. The 60-second startup allowance is a starting value for this recipe,
not a measured guarantee; investigate slow pulls/startup before increasing it.
Check `codex mcp list`, then inspect the actual tools in the session.
[Codex MCP configuration](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).

For an intentionally personal/global entry, the alternative is:

```bash
codex mcp add day-one-docker -- \
  docker --context desktop-linux mcp gateway run --profile day-one-sandbox
```

This edits personal configuration and does not create the disabled project
entry above. Choose one scope. An `enabled` entry, or `Unsupported` in the
OAuth column for stdio, does not establish whether a server's tools work.

### Docker's automatic client connector

Docker also offers `docker mcp client connect CLIENT --profile PROFILE` and
the Toolkit **Clients** tab. These edit live client configuration; they are not
previews. If choosing that route instead, inspect the destination and diff,
check the explicit profile/context, and avoid also adding the manual entry.
Docker's documented VS Code connector writes `.vscode/mcp.json`, which differs
from portable Copilot configuration. Connector defaults and `--global` support
are client/version dependent. [Docker client connections](https://docs.docker.com/ai/mcp-catalog-and-toolkit/cli/).

## 6. Verify one harmless request

In each selected client, inspect the tool list before sending a request:

```text
Use the Playwright tool from day-one-docker to open https://example.com and
report its page title. Do not sign in, submit forms, download files, change
local files, add MCP servers or use other tools. Close the test browser after.
```

Approve only the expected actions. Expand the tool output and confirm the
intended gateway/server performed the request; a plausible model answer is
not evidence of connectivity. Record the client version, profile ID, selected
server/image, successful request and date, without tokens or private data.

Verify that dynamic management tools are absent, unselected tools are unavailable
and the browser has no personal session. Repeat after restart. For a different
server, substitute a similarly low-impact read of public or synthetic data.
Do not test a write operation or production database just to prove connectivity.

## 7. Maintain, troubleshoot and remove the setup

### Updates and recovery

Before changing a working profile, save its export into a new private directory:

```bash
(
  umask 077
  backup_dir="$(mktemp -d "$HOME/mcp-profile-backup.XXXXXX")" || exit 1
  docker mcp profile export day-one-sandbox "$backup_dir/profile.json" || exit 1
  printf 'Profile backup: %s\n' "$backup_dir/profile.json"
)
```

Keep the client configuration backups too. Review exports for private paths,
URLs and mistakenly embedded values before sharing. Re-establish credentials
separately after a restore; a configuration export is not a credential backup.

Use a separate trial profile for an update. Record a reviewed catalog version
and the resolved server-image digest; a pinned catalog is insufficient if its
entry still names a mutable image tag. Managed teams should distribute reviewed
catalog entries with fixed image references, test them on ARM, then repeat the
client tool check before switching profiles. Do not blindly re-add `latest`
entries across every profile. If an update fails, point the client back to its
previous working profile while investigating.

Inspect resource use in Docker Desktop when several clients are active; each
may launch its own gateway/session. CLI 0.44.1 advertises per-server defaults
of one CPU and 2 GB memory. Those are limits, not preallocated usage or a total
profile budget. Adjust only after measuring an actual bottleneck.

### Troubleshooting

| Symptom | Check and resolution |
|---|---|
| `claude` or `codex` is missing | Complete the selected client's Optional 10 installation and PATH checks; skip unselected clients |
| `docker mcp` is missing | Check Desktop version and Toolkit enablement; a standalone Docker CLI is insufficient |
| `profile` or `--profile` is unknown | Check installed help; update through the approved Desktop channel before following this recipe |
| Daemon unavailable | Start the approved engine; verify the local `desktop-linux` endpoint and `docker info` |
| GUI cannot find Docker | Compare its PATH with `command -v docker`; use that verified absolute executable path locally if needed, then restart the client |
| Wrong servers appear | Check the exact profile and client scope; inspect dynamic-tools state and duplicates |
| Missing credentials | Configure that server's auth/secret input; shell exports and `.env` are not automatically loaded by Docker or GUI clients |
| Startup times out | Inspect image pull, architecture, proxy and signature errors; distinguish these from a genuinely slow startup |
| Tool selection is stale | Restart the affected server/session; in VS Code inspect **Show Output** and reset cached tools if required |
| Browser cannot reach a service | Confirm the browser runs inside its container; establish the intended network route without widening host/database exposure |
| High CPU or memory | Inspect selected containers, concurrent clients and repeated retries; disable unused servers before raising limits |

### Disable or remove only this setup

1. Stop the affected client/gateway session. Disable `day-one-docker` in that
   client's controls, or set Codex's `enabled = false`. Keep other sessions intact.
2. To remove a manually configured entry, back up the file and delete only that
   entry. For Claude project scope, use
   `claude mcp remove day-one-docker --scope project`; for a personal Codex entry,
   use `codex mcp remove day-one-docker`. For Docker-created connections, inspect
   `docker mcp client disconnect --help` and use the original client/scope.
3. Inspect `docker mcp profile show day-one-sandbox --clients`. Export first,
   confirm no other workflow needs it, then deliberately remove it with
   `docker mcp profile remove day-one-sandbox`. Profile deletion can also update
   connected-client configuration; it is not a harmless cache cleanup.
4. Review unused secrets and OAuth grants separately. Removing a server/profile
   does not prove credentials were erased; shared grants may still support other
   profiles. Remove/revoke only those no longer needed.
5. Keep images needed by other workloads. Never use a system-wide Docker prune,
   volume deletion or database reset to remove an MCP connection.

If you changed `dynamic-tools`, restore its recorded previous state only after
reviewing the effect on every remaining client. Do not automatically turn it on.
[Credential cleanup semantics](https://docs.docker.com/ai/mcp-catalog-and-toolkit/faqs/).

## Completion checklist

- [ ] The approved local Docker Desktop engine is healthy.
- [ ] One named profile contains only reviewed servers and required tools.
- [ ] Dynamic server-management tools are disabled for this setup.
- [ ] Mounts, network access and account permissions match the intended task.
- [ ] Credentials remain outside shared configuration; OAuth sharing is understood.
- [ ] Each selected client uses the intended profile, context and configuration scope.
- [ ] A harmless tool call and restart check pass in each selected client.
- [ ] Configuration backups, reviewed image references and removal steps are recorded.

[← MCP module](../../assisted/optional/11-mcp-servers.md) · [Advanced MCP reference](mcp.md)
