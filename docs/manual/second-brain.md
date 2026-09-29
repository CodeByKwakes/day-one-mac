[← Manual handbook](README.md) · [Second Brain library](../../second-brain/README.md)

# Build and use your Second Brain

**Audience:** beginners setting up a knowledge system and maintainers supporting it.
**Outcome:** one useful capture → review → retrieval workflow, with a tested backup.
Neither AI, cloud sync nor every integration is required.

## 1. Choose a home and privacy boundary

| Choose | When it fits | What to accept |
|---|---|---|
| [Obsidian](../../second-brain/obsidian/README.md) | Local Markdown files, offline work, direct control of backups | You manage folders, sync choices and plugin trust |
| [Notion](../../second-brain/notion/README.md) | A cloud workspace with linked databases and collaboration | Account/permission ownership and export limitations need attention |

Pick one primary home first; do not build two competing task or knowledge systems.
Choose domains you actually use, such as development, software content and tech
content. Separate work from personal material when policy or sharing requires it.
Folders, tags and an `AI Allowed` property describe intent; they do not enforce
access control. A separate vault/workspace helps only when the connected tools
also have appropriately restricted access.

## 2A. Obsidian walkthrough

1. Install/open Obsidian through its chosen owner. Decide where notes live; the
   project convention is under `~/Vaults`, outside `~/Developer`. Decide backup
   ownership before connecting any sync service.
2. Choose a route below. Start with one unified vault only if its domains may
   share the same access, sync and AI policy. Use separate vaults otherwise.
3. Open the resulting folder as a vault in Obsidian. Inspect the starter files
   before trusting any supplied settings or enabling community plugins.
4. Create one non-sensitive inbox note, use a template, add the chosen domain,
   and check that the dashboard/Bases view can find it. The
   [dashboard guide](../../second-brain/obsidian/DASHBOARD.md) explains core views
   separately from optional plugin features.
5. Add only one integration initially, then perform its end-to-end test below.

### Script-assisted layout

In an installed release, preview the reason-first manager:

```bash
cd "$(day-one-mac root)/second-brain/obsidian"
./scripts/second-brain-manager.sh --guided
```

When ready, run `./scripts/second-brain-manager.sh --guided --apply`, review the
newly displayed layout, then type the requested `APPLY LAYOUT` confirmation.
The manager creates the selected scaffolding and local integration helpers.
Application installation requires the separate `--install-apps` choice and app
policy. It does not log in, enable sync or create a remote backup.

Inspect the result from the same directory:

```bash
./scripts/second-brain-manager.sh --show
./scripts/second-brain-manager.sh --validate
second-brain-report
```

Validation checks structure, not the quality of your notes or a successful GUI
integration. The [manager reference](../../second-brain/obsidian/DYNAMIC-LAYOUT-MANAGER.md)
covers the manifest, custom layouts, owned files and reconfiguration. Unrecognised
notes are preserved with proposed comparison files; do not accept proposals blindly.

### Entirely manual layout

Use the manual route in your selected integration guide to create the folders
and copy reviewed starter assets. No Day One Mac runtime or manager invocation
is required. Keep your own record of layout, integrations and backup locations;
do not expect manager state checks to describe a manually created vault.

### Choose an integration

| Integration and complete setup guide | You do manually | Acceptance test |
|---|---|---|
| [Raycast](../../second-brain/obsidian/GUIDE-1-OBSIDIAN-RAYCAST.md) | Add the intended vault/commands, choose shortcuts, review permissions | Capture a harmless note, search for it and open it in the correct vault |
| [Claude Code](../../second-brain/obsidian/GUIDE-2-OBSIDIAN-CLAUDE-CODE.md) | Sign in, choose vault scope and allowed data, approve tool permissions | Ask for a read-only summary of a test note; verify its sources and no writes |
| [Codex](../../second-brain/obsidian/GUIDE-3-OBSIDIAN-CODEX.md) | Sign in, select the intended working folder and read-only permissions | Retrieve/summarise a harmless note before authorising any edits |
| No integration | Use Obsidian search, templates and links | Find a note and its source without relying on AI |

Do not connect an entire personal/work vault just to make the example succeed.
Cross-vault search and dashboards are not automatically equivalent to one unified
vault; see [multiple-vault boundaries](../../second-brain/obsidian/THREE-VAULT-ARCHITECTURE.md).

## 2B. Notion walkthrough

Notion's manager is a **local planner**, not a cloud provisioning tool. You build
the actual workspace, properties, sharing and integrations in Notion yourself.

1. Confirm the intended account/workspace and policy with
   [prerequisites](../../second-brain/notion/01-PREREQUISITES.md).
2. Create the [workspace and domains](../../second-brain/notion/02-WORKSPACE-AND-DOMAINS.md).
3. Build the [databases and properties](../../second-brain/notion/03-DATABASES-AND-PROPERTIES.md):
   Domains, Knowledge, Projects and Sources; add Tasks only if needed. Use linked
   views of central databases instead of duplicating one database per domain.
4. Add [templates](../../second-brain/notion/04-TEMPLATES.md) and the
   [dashboard](../../second-brain/notion/05-DASHBOARD.md). Create one sample note
   with a source and a project relation; check both the source database and view.
5. If wanted, configure [Raycast](../../second-brain/notion/06-RAYCAST-INTEGRATION.md)
   or review the [AI integration choices](../../second-brain/notion/07-AI-INTEGRATION.md).
   Account consent and access scopes remain manual; no tokens belong in the plan.
6. Complete the [backup/export exercise](../../second-brain/notion/09-BACKUP-AND-EXPORT.md)
   and [checklist](../../second-brain/notion/CHECKLIST.md).

An entirely manual setup follows those guides directly. For optional local
planning assistance in an installed release:

```bash
cd "$(day-one-mac root)/second-brain/notion"
./scripts/notion-second-brain-manager.sh --guided
```

Adding `--apply` saves the approved **local** plan, seeds and selected helper
files. It does not call Notion's API, create databases or authenticate. Follow the
saved plan in the app and test the real workspace; a local plan is not completion
evidence. The [Notion entry guide](../../second-brain/notion/README.md) lists outputs.

## 3. Use it before expanding it

Daily: capture one idea with its source, then retrieve something you already
know. Weekly: process the inbox, connect related notes, review active projects
and discard low-value duplication. AI output stays unapproved until a human
checks meaning, facts and citations. Monthly: review access, stale integrations
and backup recoverability. Use the detailed
[Obsidian operating workflow](../../second-brain/obsidian/OPERATING-SYSTEM.md) or
[Notion operating workflow](../../second-brain/notion/08-OPERATING-WORKFLOW.md).

## 4. Back up and practise recovery

For Obsidian, back up the vault (including attachments and intentional `.obsidian`
configuration) to an approved encrypted destination. Preserve manager manifests
and helper configuration separately if used. Restore a copy into a different
folder and open it as a test vault; do not overwrite the live vault to test backup.
Check several notes, links, attachments and a template. Sync propagates deletions
too and is not a substitute for a recoverable backup.

For Notion, export Markdown/CSV and attachments where available, inspect the
archive and preserve the schema/view/permission instructions alongside it.
Exports are not a full-fidelity one-click restore: relations, views, permissions,
history and automations may need reconstruction. Test with non-sensitive sample
content, not an accidental second public workspace.

For either route, record the backup date, tested content and remaining manual
recovery steps. Keep notes and exports out of the public Day One Mac/dotfiles
repository. The handbook exporter exports these **guides**, not your vault,
Notion workspace, local planner state or credentials.
