[← Advanced 21](21-audit-maintenance-and-rebuild.md) · **🤖 ⚙️ Advanced 22**

# Advanced 22 — Shared AI skills and MCP operations

**Time:** 45–120 minutes · **Required:** no · **Prerequisites:** Optional 10 and, for MCP, Optional 11

## Outcome

Selected AI clients share reviewed reusable skills from one source where their
discovery models permit it. Client-specific agents remain separate, MCP servers
have an inventory and owner, trust is explicit, secrets stay out of Git, and
unused capabilities can be disabled or removed cleanly.

## Step 22.1 — Record the selected clients and purpose

Create a private decision record under `~/.day-one-mac`:

```markdown
# AI client selection

| Client | Selected | Account type | Purpose |
|---|---|---|---|
| Claude Code | yes/no | subscription/API | |
| Codex | yes/no | ChatGPT/API | |
| VS Code Copilot | yes/no | GitHub account | |
| GitHub Copilot app | yes/no | GitHub account or approved own model provider | |
| Copilot CLI | yes/no | GitHub account | |
```

Do not install every client to make the table look complete. A client without a
distinct use adds authentication, upgrade, policy, and MCP surface area.

## Step 22.2 — Use one canonical personal skill source

The canonical target is:

```text
~/.agents/skills/<skill-name>/SKILL.md
```

Manage reviewed, non-secret personal skills through chezmoi:

```bash
mkdir -p "$HOME/.agents/skills"
chezmoi add "$HOME/.agents/skills"
```

Each skill should have:

```text
skill-name/
├── SKILL.md
├── references/     optional, only material used by the skill
├── scripts/        optional, reviewed executable helpers
└── assets/         optional, reusable non-secret inputs
```

The skill description should say exactly when it applies and when it does not.
Instructions must not contain access tokens, private URLs, customer data,
employer-only policy copied without permission, or commands that bypass user
approval.

## Step 22.3 — Add compatibility links only where needed

When a selected client requires its own skill directory and supports normal
filesystem links, link to the canonical target rather than copying content.
For Claude Code, a relative layout can be:

```bash
mkdir -p "$HOME/.claude/skills"
ln -s ../../.agents/skills/review "$HOME/.claude/skills/review"
```

Before creating any link:

```bash
[[ ! -e "$HOME/.claude/skills/review" ]] || {
  printf 'Target already exists; inspect it before replacement\n' >&2
  return 1 2>/dev/null || exit 1
}
```

Verify the resolved target:

```bash
readlink "$HOME/.claude/skills/review"
test -f "$HOME/.claude/skills/review/SKILL.md"
```

Do not assume every client supports the same discovery path. Use the selected
client's current documented location; keep client-specific adapters tiny.

## Step 22.4 — Start with three narrow skills

Useful starters from the advanced setup are:

| Skill | Scope | Required safety |
|---|---|---|
| `review` | Inspect changes and report findings | Read-only unless a separate fix is requested |
| `pr` | Prepare a pull-request summary/checklist | Never push or publish without explicit instruction |
| `test` | Select and run the smallest relevant checks | No production systems or destructive fixtures |

Create only those you will maintain. Each must be usable without knowledge of
this setup repository and must state its expected tools and failure behaviour.

## Step 22.5 — Keep client-specific agents separate

Use separate folders for agent profiles because client schemas and permission
models differ:

```text
~/.claude/agents/       Claude-specific agent Markdown
~/.codex/agents/        Codex-specific agent definitions
~/.copilot/agents/      Copilot-specific agent definitions
```

Share purpose and source references through the canonical skill, but do not
symlink an entire client configuration directory. Authentication, models,
sandbox controls, tool names, and hooks are not portable.

For every agent document:

1. Define the task boundary.
2. Declare whether writes, network access, or external messages are permitted.
3. Require a diff/review before a consequential action.
4. State how it reports partial failure.
5. Exclude secret-reading paths unless the task explicitly needs them.

## Step 22.6 — Maintain one MCP inventory

Create a non-secret catalogue at `~/.config/mcp/servers.md`:

```markdown
| Server | Purpose | Transport | Scope | Credential method | Clients | Owner |
|---|---|---|---|---|---|---|
| context7 | Library docs | HTTP | user | OAuth | selected clients | personal |
| playwright | Browser tests | stdio | workspace | none | selected clients | repository |
```

The catalogue is documentation, not a credential store. Add it to chezmoi only
after verifying that URLs contain no token query parameters and private server
names are acceptable in the private dotfiles repository.

## Step 22.7 — Add one server through one client first

Follow Optional 11 for client commands. For each new server:

1. Record purpose, transport, scope, credential method, clients, and owner.
2. Add it to one selected client.
3. Inspect the resulting configuration file.
4. Authenticate through OAuth/Keychain/1Password where supported.
5. Run one read-only test with approval prompts enabled.
6. Only then add it to another client that needs it.

Do not fan out an untested server to every client. Similar names can mask
different endpoints and permissions.

## Step 22.8 — Apply client-specific scope rules

| Server type | Preferred scope |
|---|---|
| Hosted documentation/search | User scope when low risk and generally useful |
| Filesystem | Workspace scope with a narrow repository path |
| Browser automation | Workspace scope; use a dedicated test profile |
| Database | Workspace scope; local development endpoint only |
| Paid web extraction | Disabled except during the intended task |
| Employer/private service | Work machine/profile only; never public dotfiles |

A filesystem server must not receive `/` or the complete home directory. A
database server must not point to production while being tested.

## Step 22.9 — Use secrets by reference

Order of preference:

1. Hosted OAuth.
2. Client credential store or macOS Keychain.
3. 1Password-injected environment variable at launch.
4. Untracked project-local environment file as a last resort.

Never place a literal token in:

- `SKILL.md` or agent instructions;
- MCP URLs or committed JSON/TOML;
- `.zshrc`, Warp workflows, screenshots, or reports;
- a default argument exposed by a reusable command.

Scan staged configuration by filename/content without echoing matched values to
a shared transcript:

```bash
cd "$(chezmoi source-path)"
rg -l 'Bearer[[:space:]]|github_pat_|ghp_|api[_-]?key|access[_-]?token' . || true
git diff --cached --name-only
```

Any real credential match must be removed, rotated, and removed from Git
history before pushing.

## Step 22.10 — Keep approval and trust visible

- Leave global tool auto-approval disabled.
- Trust a workspace configuration only after reviewing its URL, executable,
  arguments, working directory, environment variables, and exposed tools.
- Approve the smallest tool group for the current task.
- Treat Apify/Tavily or other paid operations as billable external actions.
- Use a separate browser profile for Playwright or similar automation.
- Do not let a reusable skill authorize a broader action than the user asked.

## Step 22.11 — Verify selected clients independently

Use the applicable commands only:

```bash
claude --version
claude mcp list

codex --version
codex login status
codex mcp list

copilot --version
```

For VS Code, use its MCP server list and output commands, inspect the active
profile, and confirm Copilot is signed into the intended GitHub account.

For Raycast AI, add only servers supported by the installed plan and current
UI. Export its configuration to encrypted backup after setup; do not treat the
export as a safe public artefact.

## Step 22.12 — Disable and remove cleanly

When a server is no longer needed:

1. Disable it in each selected client.
2. Confirm no workflow depends on it.
3. Remove the client definitions using client-supported commands/UI.
4. Revoke OAuth/token access at the provider.
5. Remove the catalogue row.
6. Review the chezmoi diff and commit the removal.

When a skill is retired, remove compatibility links first, then the canonical
source. Do not leave broken symlinks that make client discovery unreliable.

## Rollback

Restore the previous private dotfiles commit, apply only reviewed skill/config
targets, and reauthenticate if needed. Credentials are intentionally outside
the rollback; revoke and recreate them through their provider rather than
recovering token files from Git.

## Advanced 22 completion checklist 🚦

- [ ] Only purpose-backed AI clients are installed and recorded.
- [ ] Personal skills have one canonical, secret-free source.
- [ ] Compatibility links resolve and no whole client directory is shared.
- [ ] Client-specific agents declare scope, permissions, and failure behaviour.
- [ ] Every MCP server has purpose, scope, credential method, clients, and owner.
- [ ] Each server passed one read-only test before wider rollout.
- [ ] Filesystem, browser, database, and paid-tool scopes are narrow.
- [ ] Global auto-approval remains disabled.
- [ ] No credential appears in skills, configs, dotfiles, Warp, or Git.
- [ ] Disable/removal and provider-revocation procedures are understood.

```bash
day-one-mac advanced --complete 22
```

---

[← Advanced 21](21-audit-maintenance-and-rebuild.md) · [Advanced index](README.md) · [Day One Mac home](../README.md)
