# Obsidian note and instruction conventions

Use these conventions for a new vault. For an existing vault, record its current
folders and values first. Review any proposed mapping before renaming a folder,
changing properties or moving notes. Back up the selected files before applying it.

## Note properties

| Property | New-vault values | Use |
|---|---|---|
| `domain` | `development`, `software-content`, `tech-content`, `shared` | Subject; select only needed domains |
| `type` | `capture`, `project`, `learning`, `content`, `source`, `person`, `review`, `index` | Kind of note |
| `status` | `inbox`, `active`, `incubating`, `drafting`, `review`, `scheduled`, `published`, `done`, `archived` | Workflow state |
| `created` | ISO date, `YYYY-MM-DD` | Creation date; fill template placeholders |
| `sensitivity` | `public`, `personal`, `work-confidential` | Handling guidance |
| `ai_allowed` | `false` until explicitly selected for AI processing | Workflow preference, never access control |
| `topics` | YAML list of short subjects | Retrieval and related notes |
| `repo_id` | Optional stable connection ID | Links a project note to its private repository record |
| `repo` | Optional approved URL | Human-readable project link; never an authenticated URL |

Add a custom domain only when it has a clear purpose. Record its name, folder and
status vocabulary in `90 System/Knowledge System.md`, then adjust the selected
views. Preserve valid existing properties that are not in this table.

A reusable capture starts with:

```yaml
---
domain: development
type: capture
status: inbox
created: "{{date}}"
sensitivity: personal
ai_allowed: false
topics: []
---
```

Obsidian's Templates plugin fills `{{date}}` when inserting a template. Check
that the resulting note contains a date, not the placeholder. Fill blank fields
in optional starter templates before moving the note out of the inbox.

## Minimum useful files

Follow [vault creation](README.md) to create folders. Create these notes in
Obsidian before adding integrations:

1. Create `00 Inbox/Inbox.md` with your processing checklist.

   Expected: opening the note gives you one place to start an inbox review.

2. Create `00 Inbox/Quick capture.md` with a heading and an empty capture list.

   Expected: an existing Markdown file can receive optional append captures.

3. Create an index note in each selected domain folder.

   Expected: the dashboard can link to that domain without a broken link.

4. Create `90 System/Knowledge System.md` and record your chosen folders,
   property vocabulary, AI policy and backup location reference.

   Expected: decisions are explicit; never include credentials or recovery keys.

5. Create `99 Templates/Capture.md` using the property block above.

   Expected: **Templates: Insert template** produces an editable capture.

6. Create `01 Dashboards/Second Brain HQ.md` with links to these notes.

   Expected: each link opens a real note. Bases is an optional next step in the
   [dashboard guide](dashboard.md), not a prerequisite for capture or search.

Optional examples are supplied under
`extensions/second-brain/obsidian/assets/vault` in the source or the Second Brain
skill's `references/project/` snapshot. Review individual files before copying
them. Copy only missing files into an existing vault; never replace its whole
folder or `.obsidian` configuration. Remove unused domain links and embeds.

## Shared AI instructions

1. Open your vault's existing `AGENTS.md`, or create it if absent.

   Expected: the file is at the selected vault root, outside the code repository.

2. Review the [shared policy example](../../../../../extensions/second-brain/obsidian/assets/vault/AGENTS.md)
   and merge the applicable rules into your file.

   Expected: existing instructions remain intact. System configuration changes
   and repository reading have explicit scope rather than blanket access.

3. For Claude, create a relative link only when `CLAUDE.md` does not already exist.
   Run this from the selected vault directory:

   ```bash
   bash <<'BASH'
   set -euo pipefail
   test -f AGENTS.md
   if [ -e CLAUDE.md ] || [ -L CLAUDE.md ]; then
     printf '%s\n' 'Existing CLAUDE.md preserved; review its contents or link target.'
   else
     ln -s AGENTS.md CLAUDE.md
   fi
   BASH
   ```

   Expected: `ls -l CLAUDE.md` shows `AGENTS.md` for a new link. An existing file
   is preserved for manual reconciliation. To undo a newly created link, verify
   its target with `readlink CLAUDE.md`, then remove only that link.

4. Open the selected client's instruction view and confirm it loaded the file.

   Expected: [Codex](codex.md), [Copilot](copilot.md) or [Claude](claude.md)
   identifies the intended instructions. A link alone does not prove discovery.

When symlinks do not suit your sync service, Claude supports a small `CLAUDE.md`
containing `@AGENTS.md`. Review its import in the client. Keep shared rules in one
file rather than maintaining competing copies.
[Claude memory documentation](https://code.claude.com/docs/en/memory).

Permission metadata can be checked before reading a note body when that metadata
check is in scope. False or missing AI permission means skip the body unless the
user explicitly approves that note. Instructions and separate folders do not
prevent a process from reading other files; client and system controls determine access.

## Verification and recovery

Insert a capture, fill its properties, link it from the dashboard and search for
a unique phrase. Check the source Markdown and any selected Base view. For an
existing vault, compare the approved files with their backup and verify that
unrelated notes and settings remain unchanged. Undo only the approved edits;
restore a sample separately using [backup and recovery](backup.md).
