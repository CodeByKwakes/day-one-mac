# Notion Second Brain — Day One Mac

[← Choose a Second Brain](../README.md) · [Start with prerequisites →](01-PREREQUISITES.md)

This guide builds a multi-domain knowledge system in Notion. It is designed for
software-development learning, software content, tech content, and any domains
you add later.

Notion becomes the source of truth. Raycast provides optional fast entry
points. Notion AI, Claude, and Codex are optional assistants; none is required
for the core system.

## What you will build

```text
Second Brain HQ
├── Quick Capture
├── Inbox
├── Knowledge
│   ├── Software Development
│   ├── Software Content
│   ├── Tech Content
│   └── your additional domains
├── Active Projects
├── Content Pipeline
├── Sources to Verify
├── AI Review
├── Weekly Review
└── Analytics
```

The headings above are linked views. They do not create duplicate copies of
your notes.

## Start here

1. Read [Prerequisites and boundaries](01-PREREQUISITES.md).
2. Run the local planner in preview mode:

   ```bash
   cd "$(day-one-mac root)/second-brain/notion"
   ./scripts/notion-second-brain-manager.sh --guided
   ```

3. Run it again with `--apply` to save the approved, non-secret local plan.
4. Build the workspace in the order shown below.
5. Complete the [verification checklist](CHECKLIST.md).

The planner does not sign in to Notion, create cloud pages, or store an API
token. Notion templates, relations, forms, permissions, dashboard layout, and
automations are deliberately completed in Notion so you can review their
effect before they become active.

## Build order

| Step | Guide | Result |
|---|---|---|
| 1 | [Prerequisites](01-PREREQUISITES.md) | Account, workspace, privacy boundary, and selected domains |
| 2 | [Workspace and domains](02-WORKSPACE-AND-DOMAINS.md) | Second Brain HQ and Domains database |
| 3 | [Databases and properties](03-DATABASES-AND-PROPERTIES.md) | Knowledge, Projects, and Sources databases |
| 4 | [Templates](04-TEMPLATES.md) | Repeatable Capture, Development, Content, Source, Project, Person, and Review pages |
| 5 | [Dashboard](05-DASHBOARD.md) | Central views, pipelines, review queues, and analytics |
| 6 | [Raycast](06-RAYCAST-INTEGRATION.md) | Optional fast open and capture commands |
| 7 | [AI integrations](07-AI-INTEGRATION.md) | Optional Notion AI, Claude, or Codex workflow with human review |
| 8 | [Operating workflow](08-OPERATING-WORKFLOW.md) | Daily capture, weekly processing, and monthly maintenance |
| 9 | [Backup and export](09-BACKUP-AND-EXPORT.md) | Tested export routine and recovery expectations |

## Default databases

- **Domains** defines the subjects, ownership, and policy boundaries.
- **Knowledge** holds captures, learning, decisions, notes, and content.
- **Projects** tracks outcomes and connects supporting knowledge.
- **Sources** tracks evidence, URLs, authors, and verification.
- **Tasks** is optional. Do not create it if another service already owns tasks.

Use one central Knowledge database. Create filtered views for domains rather
than separate databases unless permissions require physical separation.

## What the local planner creates

After a confirmed apply:

| Location | Purpose |
|---|---|
| `~/.config/second-brain-notion/config` | Non-secret choices and approved Notion page URLs |
| `~/.local/state/second-brain-notion/setup-plan.md` | Human-readable build plan |
| `~/.local/share/second-brain-notion/raycast/` | Optional Raycast Script Commands |
| `~/.local/state/second-brain-notion/seeds/` | Copies of importable starter CSV files |

It never stores a Notion password, session cookie, integration secret, Claude
credential, or OpenAI credential.

## Important boundaries

> 🔴 **An `AI Allowed` checkbox is a workflow instruction, not access
> control.** A connected AI tool can act with the permissions of the connected
> account. Put restricted work information in a separate approved workspace or
> do not connect that workspace to external AI.

> 🟠 **Notion is cloud-first.** A Markdown/CSV export is useful for portability,
> but it does not recreate every view, relation, permission, automation, comment,
> or page history with one import.

Official references:

- [Databases](https://www.notion.com/help/intro-to-databases)
- [Relations and rollups](https://www.notion.com/help/relations-and-rollups)
- [Sharing and permissions](https://www.notion.com/help/sharing-and-permissions)
- [Notion MCP](https://www.notion.com/help/notion-mcp)
- [Backing up data](https://www.notion.com/help/back-up-your-data)

Next: [Prerequisites and boundaries →](01-PREREQUISITES.md)
