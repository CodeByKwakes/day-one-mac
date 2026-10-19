# 7 — AI integration 🤖 ⚙️ Optional

[← Raycast](06-RAYCAST-INTEGRATION.md) · [Operating workflow →](08-OPERATING-WORKFLOW.md)

## Purpose

Use AI for summaries, connections, and drafts without letting generated text
silently replace reviewed knowledge.

## Option A — no AI

Skip this page. Search, templates, relations, forms, and dashboards remain fully
usable.

## Option B — Notion AI

Use Notion AI for page summaries, draft outlines, database assistance, and
workspace questions when your plan and policy permit it.

Before the first use:

- Check the workspace AI settings.
- Confirm the page's Sensitivity and AI Allowed values.
- Test with non-sensitive material.
- Review every factual statement and source.

## Option C — Claude through Notion MCP

1. Read Notion's current MCP documentation.
2. Confirm the Claude client is approved for the workspace.
3. Connect using the current official authentication flow.
4. Limit testing to non-sensitive pages.
5. Ask Claude to propose a summary or links.
6. Set AI Status to **Needs Review**.
7. Review the result manually before changing it to **Approved**.

## Option D — Codex through Notion MCP

Codex support and connection steps can change independently of Notion. Before
connecting:

1. Check the current official Codex documentation for remote/custom MCP support.
2. Confirm your Notion workspace and account are allowed.
3. Use the official interactive authentication flow.
4. Do not paste a Notion token into a chat, repository, shell-history command,
   or Markdown file.
5. Test read-only retrieval first.
6. Require confirmation before creates, edits, moves, or deletes.

If the installed Codex client does not support the required flow, keep Codex
working on exported/local material or do not connect it.

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

Next: [Operating workflow →](08-OPERATING-WORKFLOW.md)
