[← Project home](README.md) · **Guide 1** · [Dashboard →](dashboard.md)

# Guide 1 - Obsidian + Raycast

**Guide release:** 2.3.0.0 · **Raycast baseline:** 2.3.0.0, compatible with
later 2.3.x releases · **Time:** 60-90 minutes

## Outcome

You will have one searchable Obsidian vault for three knowledge domains, a
consistent template library, a central dashboard, and Raycast commands that
search, open, and capture notes without first switching to Obsidian.

No AI account is required for this route. Raycast AI is not required.

## 1. Make the privacy and storage decisions

Use this default unless a work policy requires something else:

```text
~/Vaults/Second Brain/       notes and attachments only
~/Developer/                 source-code repositories only
```

Do not make `~/Developer` the vault. Obsidian would watch generated files,
dependency directories, and repository internals. Link to a repository from a
note using its local path or remote URL instead.

Choose the work boundary before capture begins:

| Work material | Decision |
|---|---|
| Approved for this local vault and its chosen backup | Keep it in `10 Software Development`, mark `sensitivity: work-confidential` |
| Not approved for personal sync or remote Git | Keep the vault local and use an employer-approved backup only |
| Not approved to coexist with personal notes | Create `~/Vaults/Work Brain` as a separate vault |
| Not approved for third-party AI | Raycast search is still usable; do not later give an AI tool this vault as its working directory |

🚦 Continue only after you can state where the vault is backed up and whether
work notes may live there.

## 2. Verify Obsidian and Raycast

Reuse existing approved installations. If both apps are absent and Homebrew is their selected owner, run `brew install --cask obsidian raycast`. Otherwise use each application's official download or your managed software portal.

Expected result: both apps open. Check **About** in each; do not require a particular historical patch release.

## 3. Prepare the vault

Complete the [manual vault task](README.md). Keep code repositories outside the vault, and use [layouts](layouts.md) when work and personal material require separate storage.

Expected result: a harmless note can be created, found and reopened in the intended vault.

## 4. Open and configure the Obsidian vault

1. Open Obsidian.
2. Choose **Open folder as vault**.
3. Select `~/Vaults/Second Brain`.
4. Open **Settings → Files and links**.
5. Set **Default location for new notes** to `00 Inbox`.
6. Set **Default location for new attachments** to **In the folder specified
   below**, then enter `80 Attachments`.
7. Set **New link format** to **Shortest path when possible**.
8. Turn on **Automatically update internal links**.
9. Under **Core plugins**, enable **Bases**, **Backlinks**, **Bookmarks**,
   **Command palette**, **Daily notes** if you use them, **File recovery**,
   **Outgoing links**, **Properties view**, **Search**, and **Templates**.
10. Under **Templates**, set **Template folder location** to `99 Templates`.
11. Under **Editor**, use Source or Live Preview according to preference. Edit
    templates in Source mode if a property editor tries to replace a template
    variable.

No community plugin is required. Start with core plugins; add Dataview only if
you choose the advanced analytics in [the dashboard guide](dashboard.md).

## 5. Standardise properties and note conventions

Every reusable note uses a small property vocabulary:

| Property | Allowed values or rule |
|---|---|
| `domain` | `development`, `software-content`, `tech-content`, or `shared` |
| `type` | `capture`, `project`, `learning`, `content`, `source`, `person`, `review`, or `index` |
| `status` | `inbox`, `active`, `incubating`, `drafting`, `review`, `scheduled`, `published`, `done`, `archived` |
| `created` | ISO date, `YYYY-MM-DD` |
| `sensitivity` | `public`, `personal`, or `work-confidential` |
| `ai_allowed` | `true` only after you have checked policy and note contents |
| `topics` | A YAML list; use stable topic names, not every word that occurs |

Keep the vocabulary small. Folders answer “which domain?”, properties answer
“what state is it in?”, and links answer “what is it connected to?” Do not
encode the same fact in five nested tags.

To use a template:

1. Create a note in the correct folder or in `00 Inbox`.
2. Open the command palette with `Command-P`.
3. Run **Templates: Insert template**.
4. Choose Development Note, Software Content, Tech Content, Source, Project,
   Capture, or Weekly Review.
5. Fill blank properties before the note leaves the inbox.

Naming rules:

- Use a descriptive title: `Prevent duplicate webhook delivery`, not
  `Notes 4`.
- Keep the date in `created`, except daily and weekly review filenames.
- Use `[[wikilinks]]` for concepts you expect to revisit.
- Keep one canonical note per durable concept; link to it from project notes.
- Put code in its repository and link it using the `repo` property.

## 6. Verify the core dashboard

Open `01 Dashboards/Second Brain HQ.md`. It embeds four `.base` files:

- Development
- Software Content
- Tech Content
- All Knowledge

If you see source text rather than a view, confirm the Bases core plugin is
enabled. Each Base filters by folder, so the three dashboards remain separate
without creating separate vaults.

Create one test note from each domain template. Open each Base, select its
first view, and use the toolbar to sort by **File modified time → Newest**.
Obsidian retains view configuration in the `.base` file.

## 7. Install the Obsidian extension in Raycast

1. Open Raycast with its global shortcut.
2. Search for **Store** and open it.
3. Search for **Obsidian** by Marc Julian.
4. Open the extension listing, review its requested preferences, and install.
5. In Raycast Settings, open **Extensions → Obsidian**.
6. For **Search Note**, select the `Second Brain` vault.
7. Enable content search so results match both titles and note bodies.
8. Set the primary action to open in Obsidian if that is your normal intent;
   keep Quick Look as the primary action if you mostly read without editing.
9. Exclude `80 Attachments`, `99 Templates`, `.trash`, and `.obsidian` from
   media/search results where the command exposes exclusions.
10. For **Create Note**, select the same vault and set the default path to
    `00 Inbox`.
11. Add folder actions for `10 Software Development/Learning`,
    `20 Software Content/Ideas`, and `30 Tech Content/Ideas`.

The extension's Search Note command supports title/content search and tag
filters. Create Note supports date, time, clipboard, and selection tokens. Its
Daily Note commands require Daily Notes and, for some actions, Advanced
Obsidian URI; the workflow in this guide does not require those commands.

## 8. Make Raycast fast enough to become a habit

In Raycast Settings, assign memorable aliases or hotkeys:

| Command | Suggested alias | Suggested hotkey | Use |
|---|---|---|---|
| Obsidian: Search Note | `bs` | `Control-Option-S` | Search every domain |
| Obsidian: Create Note | `bn` | `Control-Option-N` | Create a classified or inbox note |
| Open Knowledge Dashboard | `bd` | `Control-Option-D` | Open the reviewed dashboard Quicklink |

Avoid a hotkey that macOS or an editor already owns. Aliases are enough if you
prefer fewer global shortcuts.

## 9. Add a dashboard Quicklink

1. In Obsidian, open the dashboard note and choose **Copy Obsidian URL**. Expected: the URI identifies this vault and note.
2. In Raycast, run **Create Quicklink** and paste that URI with the name **Open Knowledge Dashboard**. Expected: the command appears in Root Search.
3. Run the Quicklink. Expected: Obsidian opens the intended dashboard; if another vault opens, replace the URI with one copied from the correct vault.

Use the Store extension from Step 7 for search and capture. This manual route needs no generated Script Commands or private manager configuration.

## 10. Test the complete path 🚦

Run these tests in order:

1. In Obsidian, open `Second Brain HQ`.
2. From Raycast, run **Create Note** and create `Raycast integration test` in
   `00 Inbox`.
3. Put the phrase `retrieval-check-2300` in the body.
4. Run **Search Note**, search for that phrase, and open the result.
5. Run **Obsidian: Create Note** with `Test quick capture`.
6. Confirm the line appears in `00 Inbox/Quick capture.md`.
7. Run **Open Knowledge Dashboard** and choose the configured vault when asked.
8. Delete the test note only after all results pass.

If title search works but body search does not, re-open the Search Note command
preferences and enable content search. If a Script Command opens the wrong
vault, correct `SECOND_BRAIN_VAULT_NAME` in the config file. Vault names in an
Obsidian URI are names, not filesystem paths.

## 11. Capture real knowledge now

Do not finish with an empty system:

1. Capture one development lesson from the last week.
2. Capture one software tutorial or documentation idea.
3. Capture one audience-facing tech content idea.
4. Create one Source note for something you want to cite.
5. Link at least two notes with `[[wikilinks]]`.
6. Process the test captures using the decision rules in
   [Operating System](operations.md).

## 12. Back up before relying on it

Choose one sync path and one independent backup. Obsidian Sync is the simplest
first-party multi-device option, but synchronization is not a backup. Time
Machine or another versioned backup should also cover the vault.

If you use Git, keep the remote private, exclude volatile workspace state, and
do not push employer material to a personal service without written approval.
Do not run two independent sync engines over the same vault until you have
understood and tested their conflict behaviour.

## Completion checklist

- [ ] Obsidian and Raycast open normally.
- [ ] Every selected domain folder exists in its configured vault.
- [ ] Core Templates and Bases are configured.
- [ ] All four Base files render.
- [ ] Raycast Search Note finds note content.
- [ ] Create Note targets `00 Inbox`.
- [ ] The three Script Commands work, or you intentionally chose the Store
      extension only.
- [ ] Work-policy and AI-policy boundaries are recorded.
- [ ] An independent backup covers the vault.
- [ ] Real notes exist in every selected domain.

Official references: [Obsidian installation](https://obsidian.md/help/install),
[Obsidian Templates](https://obsidian.md/help/plugins/templates),
[Obsidian URI](https://obsidian.md/help/Extending%2BObsidian/Obsidian%2BURI),
[Raycast Obsidian extension](https://www.raycast.com/marcjulian/obsidian), and
[Raycast Script Commands](https://manual.raycast.com/script-commands).

---

[← Project home](README.md) · [Dashboard and analytics →](dashboard.md)
