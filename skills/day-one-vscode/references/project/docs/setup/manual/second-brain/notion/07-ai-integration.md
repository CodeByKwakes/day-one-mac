# 7 - AI integration 🤖 ⚙️ Optional

[← Raycast](06-raycast-integration.md) · [Operating workflow →](08-operating-workflow.md)

## Purpose

Use AI for summaries, connections, and drafts without letting generated text
silently replace reviewed knowledge.

## Option A - no AI

Skip this page. Search, templates, relations, forms, and dashboards remain fully
usable.

## Option B - Notion AI

Use Notion AI for page summaries, draft outlines, database assistance, and
workspace questions when your plan and policy permit it.

Before the first use:

- Check the workspace AI settings.
- Confirm the page's Sensitivity and AI Allowed values.
- Test with non-sensitive material.
- Review every factual statement and source.

<a id="option-c---claude-through-notion-mcp"></a>

## Option C - Claude Code through Notion MCP

First install and sign in to [Claude Code](../../ai/clients.md). Inspect `/mcp`
for an existing Notion connection; retain it instead of registering a duplicate.
Use a harmless page in the approved workspace for the first test.

1. From the intended project, register a personal, project-local connection:

   ```bash
   claude mcp add --transport http --scope local notion https://mcp.notion.com/mcp
   ```

   Expected: a local entry named `notion`. Stop if that name already belongs to
   another connection. Choose user scope only when you need it across projects.
2. Start `claude`, run `/mcp`, select Notion and complete browser authentication.
   Expected: the connection identifies the intended workspace. Review consent
   yourself; an AI policy property does not restrict what this account can access.
3. Request a read of the harmless page without edits. Expected: an actual tool
   call returns its title and text. Review the result before requesting drafts.

## Option D - Codex through Notion MCP

Install and sign in to [Codex](../../ai/clients.md). Inspect `codex mcp list`
first. The following CLI registration is personal/global, not project-only:

1. Add the remote server only when no intended Notion entry already exists:

   ```bash
   codex mcp add notion --url https://mcp.notion.com/mcp
   ```

   Expected: the entry appears in personal configuration. For project-only
   configuration, follow the [client scope guide](../../ai/mcp.md#understand-configuration-locations).
2. Authenticate interactively:

   ```bash
   codex mcp login notion
   ```

   Expected: browser consent completes for the approved workspace. Never put a
   Notion token into a command, chat or repository.
3. In a fresh Codex session, request the harmless page without edits. Expected:
   the tool returns the intended title and text. Keep write approvals enabled.

These connection methods follow [Notion's client instructions](https://developers.notion.com/guides/mcp/get-started-with-mcp),
checked on 30 October 2026. Commands were inspected locally; account-backed Notion
acceptance is still required. Claude Desktop is a different client and is not
configured by the Claude Code commands above.

### Troubleshoot and disconnect

- Missing command: finish the selected client installation and PATH check first.
- Authentication failure: confirm the browser account, workspace and enterprise
  MCP policy; do not substitute an API token into a URL.
- Missing page: check its sharing and your account's access. Do not widen access
  just to make a test succeed.
- Wrong existing entry: preserve its configuration and owner before changing it.

To disconnect the Claude Code entry above, run `claude mcp remove --scope local notion`.
Use the actual scope if you chose another. For the personal Codex entry, run
`codex mcp remove notion`. Revoke unwanted
access in Notion's connection settings separately. Expected: a fresh session no
longer exposes that connection; unrelated servers and pages remain intact.

## Shared review workflow

```text
Capture
  → AI Allowed reviewed
  → assistant proposes summary, tags, or links
  → AI Status = Needs Review
  → human checks meaning, facts, sources, and sensitivity
  → AI Status = Approved or the proposal is rejected
```

Recommended prompts:

- “Summarise this page without changing it. List uncertain claims separately.”
- “Suggest up to five related pages. Do not create links.”
- “Turn these reviewed notes into an outline. Cite the source pages used.”
- “Identify contradictions and missing evidence. Do not resolve them silently.”

## Security reality

An AI Allowed checkbox does not limit MCP access. Notion MCP acts with the
connected user's permissions. Use a separate workspace or do not connect an AI
client when a hard boundary is required.

Review connected integrations periodically and disconnect clients that are no
longer used.

Next: [Operating workflow →](08-operating-workflow.md)
