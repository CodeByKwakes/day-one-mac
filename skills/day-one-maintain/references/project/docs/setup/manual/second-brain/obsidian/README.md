# Build an Obsidian knowledge vault manually

Create a small, usable vault without Day One Mac scripts. You need the approved
Obsidian application, a private storage location and a backup plan. Install
`obsidian` through Homebrew only if absent and Homebrew is the intended owner.

## 1. Choose a vault boundary

A vault is a physical folder with its own Obsidian settings and plugins. A domain
is a subject inside it. Start with one vault unless policy, accounts or backup
requirements require separate folders. Use [layouts](layouts.md) for that decision.

Expected result: the intended vault location is outside a code repository and
has an approved sync and AI-processing policy.

## 2. Create or open the vault

In Obsidian, choose **Create new vault**, select its name and location, and open
it. For an existing vault, use **Open folder as vault** instead; do not create
another copy of the same notes.

Expected result: the file explorer shows the intended folder. Create a harmless
test note and confirm its `.md` file appears there in Finder.

## 3. Create the selected folders

Create these folders through Obsidian or Finder, omitting unused domains:

```text
00 Inbox/
01 Dashboards/
10 Software Development/
20 Software Content/
30 Tech Content/
40 Sources/
90 System/AI Review/
80 Attachments/
99 Templates/
```

Expected result: each folder has one purpose. Code required to build a project
stays in its repository; the vault links to that project rather than becoming
another source-code copy.

## 4. Create a reusable note template

Create `99 Templates/Capture.md` with these properties, then fill the values
when creating a real note:

```yaml
---
type: capture
domain: development
status: inbox
created: "{{date}}"
sensitivity: personal
ai_allowed: false
topics: []
---
```

Add headings for **Question**, **Notes**, **Sources** and **Next action**.
Enable Obsidian's Templates core plugin and select `99 Templates` as its folder.

Expected result: a new note can insert this template and retain editable values.
Templates fills the date placeholder; verify a real date in the created note. `ai_allowed` is an instruction, not a security
control. The repository also contains optional example templates under
`extensions/second-brain/obsidian/assets/vault/99 Templates`. Review an individual
example before copying it; the procedure above does not need those files.

## 5. Set capture and attachment locations

Choose the new-note location and attachment folder in Obsidian settings.
Select `00 Inbox` and `80 Attachments` for this layout.

Expected result: a test note and a harmless attachment appear in those folders.
Keep the original if you are testing a migration from an existing vault.

## 6. Build navigation and a dashboard

Create the minimum notes in [note conventions](note-contract.md#minimum-useful-files),
then create `01 Dashboards/Second Brain HQ.md` linking to them. Add a weekly-review
note when you start the review routine. Follow [dashboard setup](dashboard.md) if you
want Bases views after the links work.

Expected result: every link opens the intended note or folder and one test note
appears in the expected view.

## 7. Verify and back up

Create, search for, edit and reopen one note. Follow [backup and recovery](backup.md)
to restore a sample separately. Complete the applicable [checklist](checklist.md).

Expected result: capture, search and recovery work independently of an AI client.

## Choose integration guides

- [Raycast](raycast.md): optional launch and capture shortcuts.
- [Repository connections](../repositories.md): selected code references and AI reading.
- [Copilot](copilot.md): knowledge work in VS Code.
- [Claude Code](claude.md): bounded drafting and review in an approved vault.
- [Codex](codex.md): bounded drafting and review in an approved vault.
- [Operating workflow](operations.md): daily capture and weekly review.

For a problem, preserve the files and inspect the selected vault, sync account
and plugin settings. Disable only the newly introduced optional plugin to test
a suspected conflict; do not delete the vault as a repair step.
