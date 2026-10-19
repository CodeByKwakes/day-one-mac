# Project and global MCP connections

This focused reference was extracted from the advanced VS Code guide.
Follow the [base editor setup](../apps/VSCODE.md) and [profile guide](../apps/VSCODE-PROFILES.md) first.
[Advanced development reference](VSCODE-TYPESCRIPT.md).

For container-managed servers, use the [Docker MCP setup guide](MCP-DOCKER.md).
It owns Docker Desktop prerequisites, named profiles, credentials, client
launchers and verification. This page owns direct project/IDE launchers and
hosted connections. Choose one route per server; do not enable duplicate direct
and Docker definitions. Module 11's artifact generator remains HTTPS-only.

## 11. Configure project and global MCP servers

MCP adds live tools and data. Skills add workflow instructions. An extension,
skill, and MCP server are different components and do not install one another.
Add only servers a real task needs. Built-in file/search/terminal tools usually
make a generic filesystem or shell MCP server redundant.

### Useful server reference

| Server | Publisher / use | Launch command or endpoint | Preferred scope / requirements |
|---|---|---|---|
| Angular CLI MCP | Official Angular; framework/project tools | `npx --no-install ng mcp --read-only` | Project; installed CLI must support `mcp`; check `npx --no-install ng mcp --help` |
| Nx MCP | Official Nx; workspace/process/docs/CI tools | `npx --no-install nx mcp` | Project; native command in Nx 21.4+; older versions use separate `nx-mcp` |
| Context7 | Upstash; current library documentation | `npx -y @upstash/context7-mcp` | Global or project; service rate limits/access can require a key; follow provider auth setup |
| Azure DevOps MCP | Microsoft; work items, PRs, builds | Copilot HTTP: `https://mcp.dev.azure.com/YOUR_ORGANIZATION`; local: `npx -y @azure-devops/mcp YOUR_ORGANIZATION` | Organization-global or project; remote Entra prerequisites; local needs Node 20+ |
| Playwright MCP | Microsoft; interactive browser tools | `npx -y @playwright/mcp@latest` | Global or project; supported Node/browser setup; distinct from Playwright CLI skill |
| Postgres MCP Pro | Crystal DBA community; SQL, schema, EXPLAIN | `uvx --python 3.12 postgres-mcp --access-mode=restricted` | Project; Python/uv, `DATABASE_URI`, database permissions; optional, not Microsoft PostgreSQL extension |
| DataGrip MCP | Built into DataGrip 2025.2+; existing database connections and IDE tools | Copy the generated client configuration from DataGrip Settings → Tools → MCP Server | Personal/global initially; local/dev/test, restricted DB role; [database AI setup](../databases/DATAGRIP.md#12-optional-sql-handoff-and-ai-access) |
| GitHub MCP | Official GitHub; GitHub PR/issues/repository context | `https://api.githubcopilot.com/mcp/` | Optional global; GitHub auth; not an Azure Repos substitute |

Sources: [Angular MCP](https://angular.dev/ai/mcp),
[Nx AI setup and MCP reference](https://nx.dev/docs/features/enhance-ai),
[Context7](https://github.com/upstash/context7),
[Azure DevOps remote](https://learn.microsoft.com/en-us/azure/devops/mcp-server/remote-mcp-server),
[Azure DevOps local](https://github.com/microsoft/azure-devops-mcp),
[Playwright MCP](https://github.com/microsoft/playwright-mcp),
[Postgres MCP Pro](https://github.com/crystaldba/postgres-mcp),
[GitHub MCP](https://github.com/github/github-mcp-server).

The Angular/Nx examples deliberately use installed binaries. Do not fetch a
new framework CLI merely because a project lacks `mcp`. Framework tools belong
to that worktree; registering them globally does not install dependencies in
every repository. Some Nx CI capabilities require Nx Cloud access.

### Understand configuration locations

| Client | Project | Personal/global |
|---|---|---|
| Copilot, current portable setup | Root `.mcp.json`, `mcpServers` object | `~/.copilot/mcp-config.json`, `mcpServers` object |
| VS Code compatibility format | `.vscode/mcp.json`, `servers` object | **MCP: Open User Configuration**, profile `mcp.json` |
| Codex extension/CLI | `.codex/config.toml`, `[mcp_servers.NAME]` tables; trusted project | `~/.codex/config.toml`; `codex mcp add` edits personal configuration |
| Claude Code | `.mcp.json`; `claude mcp add --scope project` | `~/.claude.json`; `claude mcp add --scope user` |

Current VS Code's Copilot flow offers portable destinations for new servers.
Workspace-root `.mcp.json` requires `chat.mcp.workspaceRootConfig.enabled`;
use the Local harness compatibility destination if that option is unavailable
or disallowed. Profile
MCP storage is distinct from portable global storage: the latter is shared
across profiles. Root JSON can be shared by compatible Copilot/Claude clients,
but Codex uses its own TOML configuration. Do not symlink JSON to TOML.
[VS Code MCP configuration](https://code.visualstudio.com/docs/agent-customization/mcp-servers),
[Codex MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli),
[Claude scopes](https://code.claude.com/docs/en/mcp).

MCP configuration is not ordinary VS Code `settings.json`. Your preference for
User Settings covers editor settings; MCP definitions still need the client's
MCP file. Use the [local Git exclusions](PROJECT-INSTRUCTIONS-AND-SKILLS.md#keep-local-project-ai-files-out-of-git)
if you do not want to commit project configuration. Never include literal
credentials in a shared file.

### Copilot and Claude: project installation

From the repository root, create or merge `.mcp.json`:

```json
{
  "mcpServers": {
    "nx": {
      "command": "npx",
      "args": ["--no-install", "nx", "mcp"]
    },
    "angular": {
      "command": "npx",
      "args": ["--no-install", "ng", "mcp", "--read-only"]
    }
  }
}
```

Include Angular only when the installed CLI supports the command and the server
recognizes your workspace. In an Nx repository without the layout Angular MCP
expects, retain Nx and use Angular documentation/skills. Do not claim all tools
work simply because the process starts.

In Copilot, run **MCP: Add Server** for other entries, choose `.mcp.json`, and
use the launch command/URL from the server table. Review/start the server through
**MCP: List Servers** and inspect its tools in the chat tool picker.

If using Claude to create the project definitions instead, these commands write
the same root file; skip them when the JSON entries already exist:

```bash
claude mcp add --scope project nx -- npx --no-install nx mcp
claude mcp add --scope project angular -- npx --no-install ng mcp --read-only
```

### Copilot: global installation

Run **MCP: Add Server**, select the command/HTTP transport, and choose **Copilot
Global**. Or merge into `~/.copilot/mcp-config.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

Add only the servers you use. These commands register launchers that download
packages when needed; they are not npm global package installations. After a
successful setup, consider replacing `@latest`/unversioned packages with reviewed
versions for reproducibility. Context7's provider offers authenticated setup and
higher limits; if authentication is required, follow its current client recipe
rather than committing a key. [Context7 clients](https://context7.com/docs/resources/all-clients).

For a profile-only server, use **MCP: Open User Configuration** and VS Code's
`servers` format instead. Do not register the same server in both global files
without an intentional scope reason.

### Codex: project and global installation

Project: merge into `.codex/config.toml`:

```toml
[mcp_servers.nx]
command = "npx"
args = ["--no-install", "nx", "mcp"]

[mcp_servers.angular]
command = "npx"
args = ["--no-install", "ng", "mcp", "--read-only"]
```

Launch from the intended worktree and verify the server's working directory.
If a server starts elsewhere, set its supported `cwd` to that checkout; a
machine-specific absolute path should remain local. Do not reuse a primary
checkout's `cwd` when working in a linked worktree.

Global: use the CLI or merge the corresponding tables into personal config:

```bash
codex mcp add context7 -- npx -y @upstash/context7-mcp
codex mcp add playwright -- npx -y @playwright/mcp@latest
codex mcp list
```

The same table syntax works in personal or project config; placement determines
scope. Do not assume `codex mcp add` creates a project definition. For HTTP
servers, use `codex mcp add NAME --url URL`; when supported, complete OAuth with
`codex mcp login NAME`. Keep credentials out of the command text and shared files.

### Claude: global installation

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
claude mcp list
```

For any other local launcher, replace the name and command/arguments using the
server reference. For a compatible HTTP server:

```bash
claude mcp add --scope user --transport http github \
  https://api.githubcopilot.com/mcp/
```

Use `--scope project` instead of `--scope user` when it should belong to that
repository. Review auth/tool status in `/mcp`; availability depends on the server
and account, not simply the command succeeding.

### Azure DevOps: remote for Copilot, local when needed

For supported Copilot accounts, add this object to the selected JSON
`mcpServers` map, replacing the organization name:

```json
{
  "ado": {
    "type": "http",
    "url": "https://mcp.dev.azure.com/YOUR_ORGANIZATION"
  }
}
```

Complete Microsoft Entra sign-in. Current documentation requires an
Entra-backed Azure DevOps Services organization; standalone Microsoft-account
organizations are not supported for the remote route. It notes remote auth
limitations for Codex and custom app-registration requirements for Claude Code.
Use local stdio when the remote route cannot authenticate. Sample skill tool
names can differ between local and remote server versions; inspect actual tools.

Codex local route, global registration:

```bash
codex mcp add ado -- npx -y @azure-devops/mcp YOUR_ORGANIZATION
```

Project equivalent in `.codex/config.toml`:

```toml
[mcp_servers.ado]
command = "npx"
args = ["-y", "@azure-devops/mcp", "YOUR_ORGANIZATION"]
```

Copilot/Claude local alternative, merge this object into `mcpServers`:

```json
{
  "ado": {
    "command": "npx",
    "args": ["-y", "@azure-devops/mcp", "YOUR_ORGANIZATION"]
  }
}
```

Authenticate using the server's supported flow. A local server still needs
organization membership and permissions; do not put a PAT into these examples.
For Claude CLI installation, use the same launcher with `--scope project` or
`--scope user`. Prefer inspecting builds/work items before enabling write tools.

### PostgreSQL: optional project connection

If you use DataGrip, follow the
[DataGrip/PostgreSQL workflow](../databases/DATAGRIP.md)
for your normal setup. The independent server below is an alternative when you
specifically need it; do not add a duplicate database MCP by default.

For ordinary manual queries, the PostgreSQL extension is sufficient. Add a
database MCP server only when an agent needs SQL/schema/plan tools.

Postgres MCP Pro is a community server. Use restricted mode and a database
account with suitable read permissions. Advanced statistics/index analysis
depends on database extensions and privileges; do not install those automatically.

Merge into project JSON's `mcpServers` map:

```json
{
  "postgres": {
    "command": "uvx",
    "args": ["--python", "3.12", "postgres-mcp", "--access-mode=restricted"]
  }
}
```

Codex project equivalent:

```toml
[mcp_servers.postgres]
command = "uvx"
args = ["--python", "3.12", "postgres-mcp", "--access-mode=restricted"]
env_vars = ["DATABASE_URI"]
```

Supply `DATABASE_URI` to the launching client through your selected private
environment/secret-manager workflow. `DATABASE_URL` used by Prisma is not
automatically `DATABASE_URI` used by this server. VS Code launched from Finder
may not inherit terminal variables; an already-running process does not gain
new variables merely because another terminal exports them. An editor's `.env`
highlighting does not load this credential. Check the server connection before
querying. Use a dedicated launch/session when projects need different databases.

For a deliberately global database connection, put the same entry in the
personal MCP file, or register the launcher with `codex mcp add postgres -- ...`
or `claude mcp add --scope user postgres -- ...`. Project scope is preferable
when the connection differs per repository. Never hard-code its password in
shared settings.

### GitHub: conditional global connection

If you also work on GitHub-hosted projects, add through **MCP: Add Server →
HTTP → Copilot Global**, or merge this into the selected map:

```json
{
  "github": {
    "type": "http",
    "url": "https://api.githubcopilot.com/mcp/"
  }
}
```

Codex equivalent: `codex mcp add github --url https://api.githubcopilot.com/mcp/`.
Use the client's supported GitHub authentication and review available tools.
For project scope, place the HTTP object in project JSON or the corresponding
`url` table in project TOML. Do not add GitHub MCP for Azure Repos alone.
