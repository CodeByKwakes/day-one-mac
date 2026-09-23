# 1 — Prerequisites and boundaries

[← Notion home](README.md) · [Workspace and domains →](02-WORKSPACE-AND-DOMAINS.md)

## Purpose

This step prevents personal, employer, and AI-access rules from being mixed
inside one workspace by accident.

## Required

- A current supported browser or the Notion desktop application.
- A Notion account you are allowed to use for the selected information.
- Permission to create pages and databases in the chosen workspace.
- Ten to twenty minutes to decide which information belongs together.

Raycast, Notion AI, Claude, Codex, and a Notion API integration are optional.

## Choose the account boundary first

| Situation | Recommended boundary |
|---|---|
| Personal notes only | Personal workspace |
| Employer notes only | Employer-approved workspace and account |
| Personal and work notes | Separate workspaces or accounts |
| Employer forbids external AI | Do not connect that workspace to Notion MCP or another AI client |
| Employer forbids Notion | Keep work material out of this system |

A database filter such as `Domain = Work` only changes what is displayed. It
does not prevent a person or connected tool with database access from reading
the other rows.

## Choose the initial domains

Start small. Recommended examples:

- Software Development
- Software Content
- Tech Content

Optional additions:

- Personal Learning
- Projects
- Research
- Career
- Team Knowledge

Domains remain dynamic. Adding one later does not require another database.

## Choose your assistant level

- **None:** use templates, search, relations, and dashboards only.
- **Notion AI:** use AI inside Notion, subject to your plan and workspace rules.
- **Claude:** connect only after reviewing the Notion MCP permissions.
- **Codex:** connect only if the current Codex client and workspace policy
  support the required MCP connection.
- **Multiple assistants:** use one shared AI Review queue and never let two
  assistants silently rewrite the same canonical page.

## Optional local plan

Preview the wizard without writing anything:

```bash
./scripts/notion-second-brain-manager.sh --guided
```

Apply only after the summary is correct:

```bash
./scripts/notion-second-brain-manager.sh --guided --apply
```

The URLs may be left blank until the HQ and capture form exist. Rerun
`--guided --apply` later to update them.

## Completion gate

- [ ] I know whether this system is personal, work, or separated.
- [ ] I have chosen the first domains.
- [ ] I know whether AI access is allowed.
- [ ] I understand that a Notion filter is not a permission boundary.
- [ ] I understand that the local planner does not build the cloud workspace.

Next: [Workspace and domains →](02-WORKSPACE-AND-DOMAINS.md)
