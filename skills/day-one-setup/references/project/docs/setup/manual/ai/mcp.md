# Project and global MCP connections

Install and sign in to the selected [AI clients](clients.md) first. For VS Code, use the [manual editor task](../editors/vscode.md); terminal clients do not require editor profiles.

For container-managed servers, use the [Docker MCP setup guide](mcp-docker.md).
It owns Docker Desktop prerequisites, named profiles, credentials, client
launchers and verification. This page owns direct project/IDE launchers and
hosted connections. Choose one route per server; do not enable duplicate direct
and Docker definitions. Module 11's artifact generator remains HTTPS-only.

## 1. Configure project and global MCP servers

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
| DataGrip MCP | Built into DataGrip 2025.2+; existing database connections and IDE tools | Copy the generated client configuration from DataGrip Settings → Tools → MCP Server | Personal/global initially; local/dev/test, restricted DB role; [database AI setup](../databases/datagrip.md#12-optional-sql-handoff-and-ai-access) |
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
MCP file. Use the [local Git exclusions](instructions-agents-skills.md#keep-local-project-ai-files-out-of-git)
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
codex mcp list
```

The same table syntax works in personal or project config; placement determines
scope. Do not assume `codex mcp add` creates a project definition. For HTTP
servers, use `codex mcp add NAME --url URL`; when supported, complete OAuth with
`codex mcp login NAME`. Keep credentials out of the command text and shared files.

### Claude: global installation

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
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

### Playwright scope

Keep browser automation in the selected project. For Codex, add this table to
that project's `.codex/config.toml` after reviewing the package:

```toml
[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest", "--isolated"]
```

For Claude Code, run from the selected project:

```bash
claude mcp add --scope project playwright -- npx -y @playwright/mcp@latest --isolated
```

Expected result: the project's MCP configuration lists Playwright. Review it
before trusting the workspace. `--isolated` uses a separate browser session;
project placement is not a filesystem or network permission boundary. A user
scope definition is an optional convenience for frequent testing, but exposes
the tool to more tasks. Keep per-tool approval and use a disposable browser
session. See [Playwright MCP options](https://github.com/microsoft/playwright-mcp).

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
[DataGrip/PostgreSQL workflow](../databases/datagrip.md)
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

## Configure each selected client

The following direct-client tasks are manual. Choose one procedure per server
and client; do not install every example.

## 2. Choose the smallest useful set

Start with one server and add another only when a real workflow needs it.

| Server | Useful for | Main risk | Recommended scope |
|---|---|---|---|
| Context7 | Current library documentation | Sends queries to a hosted service | User |
| Apify | Web extraction and hosted Actors | Actors may cost money or change remote state | User, disabled when unused |
| Tavily | Web search, extraction, maps and crawls | Consumes account quota | User, disabled when unused |
| Filesystem | Reading or editing local files | Broad paths expose personal data | One explicitly selected repository |
| Playwright | Browser-driven UI tests | Can interact with signed-in websites | Project by default; isolated browser session |

Workspace scope controls where a definition is loaded; it does not restrict
the server's filesystem permissions. Configure the server's own allowed paths
to the repository you intend to expose. Never grant it all of `~/Developer`,
`$HOME` or `/`. Never point a database MCP at
production while learning the tool. Do not enable global auto-approval.

The hosted endpoints used in this guide are:

```text
Context7 OAuth  https://mcp.context7.com/mcp/oauth
Apify           https://mcp.apify.com
Tavily          https://mcp.tavily.com/mcp
```

Check a provider's own documentation before adding it because URLs and
authentication methods can change.

## 3. Decide user or workspace scope

- **User scope** makes the server visible in many repositories. Use this only
  for a generally useful, low-risk service such as documentation search.
- **Workspace scope** places configuration in the project. Use it for local
  files, browser automation, databases, or team-shared server declarations.
- A committed workspace file must contain commands and variable names only,
  never tokens. Each developer supplies their own credentials.

Avoid defining the same server name at user and workspace scope. The duplicate
can hide which endpoint and permissions are active.

## 4. Add servers to Claude Code

Skip this section if Claude Code was not selected.

Add one hosted server at a time:

```bash
claude mcp add --transport http --scope user \
  context7 https://mcp.context7.com/mcp/oauth

claude mcp add --transport http --scope user \
  apify https://mcp.apify.com

claude mcp add --transport http --scope user \
  tavily https://mcp.tavily.com/mcp
```

List and inspect what was written:

```bash
claude mcp list
claude mcp get context7
```

Then start `claude`, enter `/mcp`, open each hosted server, and complete its
browser sign-in. A project-scoped server can show **Pending approval** until
you open Claude in that trusted repository and accept the configuration.

To add a workspace-only stdio server, run the command from the repository and
put everything executed by the server after `--`:

```bash
claude mcp add --scope project playwright -- pnpm dlx @playwright/mcp@latest
```

This example downloads and runs the current package when the server starts.
Review the publisher first. For a reproducible team setup, replace `@latest`
with an explicitly reviewed version; apply the same rule to `npx` examples.

Remove a definition cleanly with its matching scope:

```bash
claude mcp remove playwright --scope project
claude mcp remove context7 --scope user
```

## 5. Add servers to Codex CLI

Skip this section if Codex was not selected.

The `codex mcp add` commands below write user configuration. For workspace-only
servers, use the reviewed `.codex/config.toml` snippet route above instead.
Codex loads project configuration only for trusted projects. Removing a
user-scoped definition affects other repositories that use it.

For remote OAuth-capable servers:

```bash
codex mcp add context7 --url https://mcp.context7.com/mcp/oauth
codex mcp add apify --url https://mcp.apify.com
codex mcp add tavily --url https://mcp.tavily.com/mcp
```

Inspect and authenticate them one at a time:

```bash
codex mcp list
codex mcp login context7
codex mcp login apify
codex mcp login tavily
codex mcp list
```

For a local stdio server, the executable and its arguments follow `--`:

```bash
codex mcp add context7-local -- npx -y @upstash/context7-mcp
```

Run `codex mcp --help` before removal or advanced changes so the command
matches the installed Codex release. Codex stores MCP declarations in its own
configuration; keep credentials in OAuth or environment-backed storage.

## 6. Add servers to VS Code and built-in Copilot

Skip this section if you do not use VS Code chat. VS Code supports a guided UI
and that is safer than hand-editing JSON for a first setup.

1. Press `⌘⇧P`.
2. Run **MCP: Add Server**.
3. Choose **HTTP** for a hosted endpoint or **Command (stdio)** for a local
   process.
4. Prefer **Global → Copilot Global** for a general server or **Workspace →
   .mcp.json** for the current repository. The latter requires
   `chat.mcp.workspaceRootConfig.enabled` in current VS Code. Use the available
   Local harness/User/Workspace format when that experimental option is absent
   or prohibited by policy.
5. Review the generated configuration before starting the server.
6. Accept the first-use trust prompt only when the URL, command, arguments,
   and scope match what you intended.
7. Run **MCP: List Servers** and use **Show Output** on any failure.

For new Copilot servers, current VS Code guidance offers portable workspace
`.mcp.json` (`mcpServers`) or user `${COPILOT_HOME:-$HOME/.copilot}/mcp-config.json`.
The VS Code compatibility format uses `.vscode/mcp.json` (`servers`). Open
profile-specific compatibility settings with **MCP: Open User Configuration**.
The following example uses that compatibility format, matching Module 11's
generated snippet:

```jsonc
{
  "servers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp/oauth"
    },
    "playwright": {
      "type": "stdio",
      "command": "pnpm",
      "args": ["dlx", "@playwright/mcp@latest"]
    }
  }
}
```

For a new portable workspace definition, use the `mcpServers` structure in
Step 11.6 at `.mcp.json`. Check client-specific authentication and local-command
fields before sharing a definition across clients. Do not maintain equivalent
copies in all three locations.

In Chat, choose **Configure Tools** and enable only the tool groups required by
the current request. Keep automatic approval off. Disable an unused server
through **MCP: List Servers** without deleting its definition.

## 7. Add servers to GitHub Copilot CLI and the GitHub Copilot app

Complete only the subsection for the selected surface. Skip this step when
neither the Copilot CLI nor the GitHub Copilot app was selected.

### GitHub Copilot CLI

The CLI uses `${COPILOT_HOME:-$HOME/.copilot}/mcp-config.json`.
Back up an existing file before editing it. This creates a private, unique
backup and reports any copy failure; stop if the backup fails:

```bash
(
  umask 077
  config="${COPILOT_HOME:-$HOME/.copilot}/mcp-config.json"
  if [ -e "$config" ]; then
    mkdir -p "$HOME/.local/state/development-setup/manual-backups" || exit 1
    backup_dir="$(mktemp -d "$HOME/.local/state/development-setup/manual-backups/mcp.XXXXXX")" || exit 1
    cp "$config" "$backup_dir/mcp-config.json" || exit 1
    printf 'Backup: %s\n' "$backup_dir/mcp-config.json"
  fi
)
```

A remote-server structure is:

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp/oauth",
      "tools": ["*"]
    }
  }
}
```

Validate the JSON before opening the client:

```bash
jq . "${COPILOT_HOME:-$HOME/.copilot}/mcp-config.json" >/dev/null
copilot
```

Inside Copilot CLI, use `/mcp list`, authenticate the selected server if
requested, and inspect it before invoking a tool. A discovered tool is not the
same as an approved tool call.
The `tools: ["*"]` example exposes every tool from this server; it does not
approve calls. Review the tool list and restrict it to what you need.

### GitHub Copilot app

If the standalone GitHub Copilot app was selected, open **Customize → MCP
servers**. The app can use MCP declarations from the current repository or
Copilot CLI and can also add a server through its own settings. Keep one
authoritative definition per server so the app does not hide which URL,
command, or credential it is using. Inspect discovered tools and begin with a
read-only request in an expendable repository.

For a company-managed account, the organisation's Copilot app and MCP policies
must both permit the connection. An MCP server visible in Copilot CLI is not
proof that the desktop app is authorised to use it.

## 8. Add servers to Raycast AI

Skip this section unless Raycast AI was selected. Raycast AI and MCP require a
paid Raycast plan.

1. Open Raycast and search for **Manage MCP Servers**.
2. Choose **Install New Server**.
3. For Context7, Apify, or Tavily, choose **HTTP**, paste only the reviewed URL
   from Step 11.1, and complete OAuth when the service offers it.
4. For a local server, choose **Standard Input/Output**, enter the executable
   and arguments separately, and restrict any filesystem path to the intended
   repository.
5. Add credentials through the server's OAuth flow or Raycast's Environment or
   HTTP Headers field. Never place one inside the command or URL.
6. Save the server, inspect the tools Raycast discovers, and keep tool
   permission prompts on **Ask**.
7. Test one harmless read-only tool, then disable the server when it is not
   needed.

Raycast MCP adds tools to Raycast AI; the OmniRoute connection in Optional 10A
chooses the model. They are separate layers, and configuring one does not
automatically configure the other.

## 9. Handle secrets safely

Use the first supported option in this order:

1. Provider-hosted OAuth in the browser.
2. A client input prompt or the macOS Keychain.
3. A named environment variable injected only when launching the client.
4. A project-local untracked `.env` as a last resort for development only.

An `.env` file is not automatically loaded by these clients. Use an explicitly
supported loader or credential input, and ensure the file is ignored and
untracked before storing anything. `${VAR}`, `${env:VAR}` and Codex's
`bearer_token_env_var` are different client-specific mechanisms; do not copy
credential placeholders between formats unchanged.

Do not place a token in a URL, committed JSON, shell profile, screenshot, or
terminal transcript. Before committing a workspace definition, run:

```bash
git check-ignore -v .env 2>/dev/null || true
# Print filenames only, so a potential credential is not echoed.
git ls-files -z -- .mcp.json .vscode/mcp.json .codex/config.toml |
  xargs -0 rg -l 'Bearer |API_KEY|TOKEN|password|secret'
git diff --stat -- .mcp.json .vscode/mcp.json .codex/config.toml
git diff --cached --stat -- .mcp.json .vscode/mcp.json .codex/config.toml
```

Inspect flagged files privately, including staged changes. Variable names can
match without containing secrets; no matches are not proof of safety. The scan
covers tracked workspace files only; inspect new files and other destinations
separately. Resolve scan errors before committing. Any real token committed or
exposed must be removed and rotated.

## 10. Prove the connection with a read-only task

Test one server at a time. For Context7, ask:

```text
Use Context7 to find the current documented command for installing the latest
Node LTS with fnm. Cite the page used and do not change any files.
```

Confirm that the client invokes the expected MCP tool and returns a successful
result. Check its approval settings separately: some clients, including
Raycast, approve read-only tools by default, so a missing prompt alone does not
prove connection failure. Keep confirmation enabled for tools that change data.
Do not begin with an Apify Actor, browser login, repository write, or database
mutation.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Server says authentication is required | Run the client's login/auth action and complete the browser flow |
| Local server command is not found | Verify `node`, `npx`, or `pnpm` in Terminal. For GUI clients, restart the app after PATH changes or configure a verified absolute executable path; a new shell alone does not update the app |
| Token variable is unavailable | Supply it to the client process using its supported credential mechanism; do not assume a GUI app reads shell exports or `.env` |
| Project server is pending | Open the client inside the trusted repository and approve that exact definition |
| Same server appears twice | Remove either the user or workspace definition; keep one authoritative scope |
| VS Code server fails | Run **MCP: List Servers** → server → **Show Output** |
| Tool list looks stale | Restart the server; in VS Code use **MCP: Reset Cached Tools** |
| A paid call ran unexpectedly | Disable the server, review its exposed tools and provider usage, then re-enable only what is needed |

## Completion checklist 🚦

- [ ] Every configured server has a documented purpose and intended scope.
- [ ] Only selected, installed AI clients were configured.
- [ ] No filesystem server can access `$HOME` or `/` broadly.
- [ ] No token or API key appears literally in version-controlled files.
- [ ] OAuth or credential-backed authentication succeeds where required.
- [ ] Auto-approval remains disabled.
- [ ] One harmless, read-only tool call succeeds per enabled server.
- [ ] Unused servers are disabled or removed.

Official references: [Codex MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli),
[Claude Code MCP](https://code.claude.com/docs/en/mcp),
[VS Code MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers),
[GitHub Copilot app](https://docs.github.com/en/copilot/get-started/quickstart-copilot-app),
[Copilot CLI MCP](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers),
and [Raycast MCP](https://manual.raycast.com/ai/model-context-protocol).
Provider setup references: [Context7](https://context7.com/docs/resources/all-clients),
[Apify](https://docs.apify.com/integrations/mcp), and
[Tavily](https://docs.tavily.com/documentation/mcp).

---

[← OmniRoute gateway](omniroute.md) · [Enhanced CLI tools →](../shell/README.md) · [Project home](../../../README.md)
