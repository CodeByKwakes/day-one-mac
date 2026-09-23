[← OmniRoute](10a-omniroute.md) · **🤖 ⚙️ Optional 11** · [VS Code profiles →](12-vscode-profiles.md)

# Optional 11 — Model Context Protocol (MCP) servers

**Time:** 15–45 minutes · **Required:** no · **Prerequisite:** at least one AI client from Optional 10

## Outcome

Only the MCP servers you genuinely need are connected to the AI clients where
you intend to use them. Each server has an understood scope, no literal secret
is committed to Git, approval prompts remain enabled, and one harmless request
has proved the connection.

Model Context Protocol (MCP) servers are programs or remote services that give an AI client additional
tools. A server can read files, call paid APIs, or change external systems, so
installing one is a security decision rather than a harmless editor preference.

This guide uses two connection types. **HTTP** connects to a hosted web address.
**stdio** (standard input/output) means the AI client starts a local command and
communicates with it directly. In either case, review the server's permissions
and keep approval prompts enabled.

## Step 11.1 — Choose the smallest useful set

Start with one server and add another only when a real workflow needs it.

| Server | Useful for | Main risk | Recommended scope |
|---|---|---|---|
| Context7 | Current library documentation | Sends queries to a hosted service | User |
| Apify | Web extraction and hosted Actors | Actors may cost money or change remote state | User, disabled when unused |
| Tavily | Web search, extraction, maps and crawls | Consumes account quota | User, disabled when unused |
| Filesystem | Reading or editing local files | Broad paths expose personal data | Workspace or `~/Developer` only |
| Playwright | Browser-driven UI tests | Can interact with signed-in websites | Workspace only |

Never grant a filesystem server `$HOME` or `/`. Never point a database MCP at
production while learning the tool. Do not enable global auto-approval.

The hosted endpoints used in this guide are:

```text
Context7 OAuth  https://mcp.context7.com/mcp/oauth
Apify           https://mcp.apify.com
Tavily          https://mcp.tavily.com/mcp
```

Check a provider's own documentation before adding it because URLs and
authentication methods can change.

## Step 11.2 — Decide user or workspace scope

- **User scope** makes the server visible in many repositories. Use this only
  for a generally useful, low-risk service such as documentation search.
- **Workspace scope** places configuration in the project. Use it for local
  files, browser automation, databases, or team-shared server declarations.
- A committed workspace file must contain commands and variable names only,
  never tokens. Each developer supplies their own credentials.

Avoid defining the same server name at user and workspace scope. The duplicate
can hide which endpoint and permissions are active.

## Step 11.3 — Add servers to Claude Code

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

Remove a definition cleanly with its matching scope:

```bash
claude mcp remove playwright --scope project
claude mcp remove context7 --scope user
```

## Step 11.4 — Add servers to Codex CLI

Skip this section if Codex was not selected.

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

## Step 11.5 — Add servers to VS Code and built-in Copilot

Skip this section if you do not use VS Code chat. VS Code supports a guided UI
and that is safer than hand-editing JSON for a first setup.

1. Press `⌘⇧P`.
2. Run **MCP: Add Server**.
3. Choose **HTTP** for a hosted endpoint or **Command (stdio)** for a local
   process.
4. Choose **User** for a general server or **Workspace** for the current repo.
5. Review the generated configuration before starting the server.
6. Accept the first-use trust prompt only when the URL, command, arguments,
   and scope match what you intended.
7. Run **MCP: List Servers** and use **Show Output** on any failure.

VS Code workspace configuration lives at `.vscode/mcp.json`. User
configuration should be opened with **MCP: Open User Configuration**, because
profiles can have separate user data. A minimal workspace example is:

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

For Copilot Agent Host portability, use workspace `.mcp.json` or user
`~/.copilot/mcp-config.json` when the current VS Code documentation directs
you there. Do not maintain equivalent copies in all three locations.

In Chat, choose **Configure Tools** and enable only the tool groups required by
the current request. Keep automatic approval off. Disable an unused server
through **MCP: List Servers** without deleting its definition.

## Step 11.6 — Add servers to GitHub Copilot CLI and the GitHub Copilot app

Complete only the subsection for the selected surface. Skip this step when
neither the Copilot CLI nor the GitHub Copilot app was selected.

### GitHub Copilot CLI

The CLI uses
`~/.copilot/mcp-config.json`. Back up an existing file before editing it:

```bash
mkdir -p "$HOME/.day-one-mac/manual-backups"
cp "$HOME/.copilot/mcp-config.json" \
  "$HOME/.day-one-mac/manual-backups/mcp-config.json.before-edit" \
  2>/dev/null || true
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
jq . "$HOME/.copilot/mcp-config.json" >/dev/null
copilot
```

Inside Copilot CLI, use `/mcp list`, authenticate the selected server if
requested, and inspect it before invoking a tool. A discovered tool is not the
same as an approved tool call.

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

## Step 11.7 — Add servers to Raycast AI

Skip this section unless Raycast AI was selected. Raycast AI and MCP require a
paid Raycast plan.

1. Open Raycast and search for **Manage MCP Servers**.
2. Choose **Install New Server**.
3. For Context7, Apify, or Tavily, choose **HTTP**, paste only the reviewed URL
   from Step 11.1, and complete OAuth when the service offers it.
4. For a local server, choose **Standard Input/Output**, enter the executable
   and arguments separately, and restrict any filesystem path to the intended
   project or `~/Developer`.
5. Add credentials through the server's OAuth flow or Raycast's Environment or
   HTTP Headers field. Never place one inside the command or URL.
6. Save the server, inspect the tools Raycast discovers, and keep tool
   permission prompts on **Ask**.
7. Test one harmless read-only tool, then disable the server when it is not
   needed.

Raycast MCP adds tools to Raycast AI; the OmniRoute connection in Optional 10A
chooses the model. They are separate layers, and configuring one does not
automatically configure the other.

## Step 11.8 — Handle secrets safely

Use the first supported option in this order:

1. Provider-hosted OAuth in the browser.
2. A client input prompt or the macOS Keychain.
3. A named environment variable injected only when launching the client.
4. A project-local untracked `.env` as a last resort for development only.

Do not place a token in a URL, committed JSON, shell profile, screenshot, or
terminal transcript. Before committing a workspace definition, run:

```bash
git check-ignore -v .env 2>/dev/null || true
rg -n 'Bearer |API_KEY[" ]*[:=][" ]*[A-Za-z0-9]' .mcp.json .vscode 2>/dev/null || true
git diff -- .mcp.json .vscode/mcp.json
```

Any real token match must be removed and rotated.

## Step 11.9 — Prove the connection with a read-only task

Test one server at a time. For Context7, ask:

```text
Use Context7 to find the current documented command for installing the latest
Node LTS with fnm. Cite the page used and do not change any files.
```

Confirm that the client names the expected MCP tool and asks for approval.
Do not begin with an Apify Actor, browser login, repository write, or database
mutation.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Server says authentication is required | Run the client's login/auth action and complete the browser flow |
| Local server command is not found | Open a new shell; verify `node`, `npx`, or `pnpm` before debugging MCP |
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
and [Raycast MCP](https://manual.raycast.com/ai/model-context-protocol).
Provider setup references: [Context7](https://context7.com/docs/resources/all-clients),
[Apify](https://docs.apify.com/integrations/mcp), and
[Tavily](https://docs.tavily.com/documentation/mcp).

---

[← OmniRoute gateway](10a-omniroute.md) · [VS Code profiles (optional) →](12-vscode-profiles.md) · [Project home](../README.md)
