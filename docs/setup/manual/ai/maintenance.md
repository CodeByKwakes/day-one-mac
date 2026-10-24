# Maintain AI skills and MCP access

Use this task to maintain skills and MCP connections for clients you already use.
Complete the [selected client setup](clients.md) first and keep a backup of its
configuration. Edit files through their configuration owner, the person or tool
responsible for maintaining them. Chezmoi commands apply only to chezmoi-owned
files; Git commands apply only to a versioned source.

If using the private report paths below, first create the directory with `mkdir -p "$HOME/.local/state/development-setup"` and restrict it with `chmod 700 "$HOME/.local/state/development-setup"`. Expected: reports remain local and outside the repository.

## 1. Record the selected clients and purpose

Create a private decision record under `~/.local/state/development-setup`:

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

## 2. Use one canonical personal skill source

The canonical target is:

```text
~/.agents/skills/<skill-name>/SKILL.md
```

Keep one reviewed copy of each skill in this directory. If chezmoi owns the
skill files, add only the reviewed, non-secret skill path:

```bash
chezmoi add "$HOME/.agents/skills/<reviewed-skill-name>"
```

Replace the placeholder with an existing reviewed skill. If you maintain the
files directly, use your selected editing and backup method instead.

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

## 3. Add compatibility links only where needed

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

## 4. Start with three narrow skills

Useful starters from the advanced setup are:

| Skill | Scope | Required safety |
|---|---|---|
| `review` | Inspect changes and report findings | Read-only unless a separate fix is requested |
| `pr` | Prepare a pull-request summary/checklist | Never push or publish without explicit instruction |
| `test` | Select and run the smallest relevant checks | No production systems or destructive fixtures |

Create only those you will maintain. Each must be usable without knowledge of
this setup repository and must state its expected tools and failure behaviour.

## 5. Keep client-specific agents separate

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

## 6. Maintain one MCP inventory

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

## 7. Add one server through one client first

Follow Optional 11 for client commands. For each new server:

1. Record purpose, transport, scope, credential method, clients, and owner.
2. Add it to one selected client.
3. Inspect the resulting configuration file.
4. Authenticate through OAuth/Keychain/1Password where supported.
5. Run one read-only test with approval prompts enabled.
6. Only then add it to another client that needs it.

Do not fan out an untested server to every client. Similar names can mask
different endpoints and permissions.

## 8. Apply client-specific scope rules

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

## 9. Use secrets by reference

Order of preference:

1. Hosted OAuth.
2. Client credential store or macOS Keychain.
3. 1Password-injected environment variable at launch.
4. Untracked project-local environment file as a last resort.

Environment files are not loaded automatically by every client. Follow the
client-specific credential and launch instructions in
[Optional 11](mcp.md),
including the separate PATH and environment requirements for GUI apps.

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

## 10. Keep approval and trust visible

- Leave global tool auto-approval disabled.
- Trust a workspace configuration only after reviewing its URL, executable,
  arguments, working directory, environment variables, and exposed tools.
- Approve the smallest tool group for the current task.
- Treat Apify/Tavily or other paid operations as billable external actions.
- Use a separate browser profile for Playwright or similar automation.
- Do not let a reusable skill authorize a broader action than the user asked.

## 11. Verify selected clients independently

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

## 12. Disable and remove cleanly

When a server is no longer needed:

1. Disable it in each selected client.
2. Confirm no workflow depends on it.
3. Remove the client definitions using client-supported commands/UI.
4. Revoke OAuth/token access at the provider.
5. Remove the catalogue row.
6. Review and back up the configuration change through its owner. Commit it only if the source is versioned.

When a skill is retired, remove compatibility links first, then the canonical
source. Do not leave broken symlinks that make client discovery unreliable.

## Rollback

Restore the reviewed skill or configuration file from its backup. For a
versioned chezmoi source, restore the source entry and apply only its named
target. Reauthenticate if needed. Credentials are intentionally outside
the rollback; revoke and recreate them through their provider rather than
recovering token files from Git.

## Verification and next steps

Confirm that each selected client discovers the intended skills and lists only
the MCP servers you approved. Use the client checks in Step 11 to verify the
account and server list. Record remaining manual checks in your private inventory.
If you arrived from an assisted module, return after these checks pass.

## Troubleshooting

| Symptom | Next action |
|---|---|
| A skill is missing | Check its `SKILL.md` path and any symlink target, then reload the project in the selected client |
| A server appears in the wrong scope | Inspect that client's personal and project definitions using Step 8 |
| Access still works after removing a definition | Revoke the provider's OAuth or token grant as described in Step 12 |
| An edit breaks discovery | Restore the reviewed file or link from its backup and repeat the client check |
