# 3 — Databases and properties

[← Workspace and domains](02-WORKSPACE-AND-DOMAINS.md) · [Templates →](04-TEMPLATES.md)

## Purpose

Build a small, connected data model. Each database row is also a Notion page,
so properties provide structure while the page body holds the useful detail.

## Knowledge — required

Create a full-page database named **Knowledge** under Second Brain HQ.

| Property | Type | Notes |
|---|---|---|
| Name | Title | Clear human-readable title |
| Domain | Relation → Domains | Required before leaving Inbox |
| Type | Select | Capture, Learning, Decision, Development Note, Content, Person, Review |
| Status | Select | Inbox, Active, Drafting, Review, Scheduled, Published, Done, Archived |
| Project | Relation → Projects | Add after Projects exists |
| Sources | Relation → Sources | Add after Sources exists |
| Topics | Multi-select | Use a small controlled vocabulary |
| Sensitivity | Select | Public, Personal, Confidential, Work Restricted |
| AI Allowed | Checkbox | Workflow signal only |
| AI Status | Select | Not Required, Needs Review, Reviewed, Approved |
| Review Date | Date | Next intentional review |
| Repo URL | URL | Optional |
| Channel | Select | Blog, Video, Social, Newsletter, Documentation |
| Audience | Text | Optional |
| Publish Date | Date | Optional |
| Canonical URL | URL | Published or source-of-truth location |
| Created | Created time | Automatic |
| Last Edited | Last edited time | Automatic |

Keep content-only properties hidden from development views rather than making a
second Knowledge database.

## Projects — required

Create **Projects** with:

| Property | Type |
|---|---|
| Project | Title |
| Domain | Relation → Domains |
| Status | Select: Proposed, Active, Waiting, Done, Archived |
| Outcome | Text |
| Next Action | Text |
| Deadline | Date |
| Repo URL | URL |
| Knowledge | Relation → Knowledge |
| Sources | Relation → Sources |
| Last Edited | Last edited time |

## Sources — required

Create **Sources** with:

| Property | Type |
|---|---|
| Source | Title |
| URL | URL |
| Author or Organisation | Text |
| Published | Date |
| Accessed | Date |
| Verification | Select: Unchecked, Verified, Recheck, Rejected |
| Review Date | Date |
| Domain | Relation → Domains |
| Knowledge | Relation → Knowledge |
| Projects | Relation → Projects |
| Notes | Text |

## Complete both sides of the relations

Notion can show a relation in both connected databases. Keep the reverse
property so a Project shows its notes and a Knowledge page shows its Project.

Useful rollups:

- Domains → Knowledge Count.
- Projects → Knowledge Count.
- Projects → Latest Knowledge Edit.
- Sources → Related Knowledge Count.

## Tasks — optional

Create a Tasks database only if Notion will own your actions. If GitHub Issues,
Azure Boards, Linear, Jira, or another service already owns tasks, link to that
system from Projects and keep Notion focused on knowledge.

## Status rules

Development:

```text
Inbox → Active → Done → Archived
```

Content:

```text
Inbox → Incubating → Drafting → Review → Scheduled → Published → Archived
```

Use one shared Status property. Views can display only the values relevant to
their workflow.

## Completion gate

- [ ] Knowledge, Projects, and Sources exist.
- [ ] Knowledge uses a Domain relation, not a duplicated text field.
- [ ] Relations work in both directions.
- [ ] A test Knowledge page can link to one Project and one Source.
- [ ] No optional automation is running yet.

Next: [Templates →](04-TEMPLATES.md)
