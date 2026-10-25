[← Guide 2](claude.md) · **Dashboard** · [Operating system →](operations.md)

# Dashboard across all selected knowledge domains

## Recommended dashboard stack

Start with Obsidian's **Bases** core plugin and your
`01 Dashboards/Second Brain HQ.md`. Bases stores views in local `.base` files
and reads normal Markdown properties. It gives you tables, filters, grouping,
and result counts without trusting a community plugin.

Add Dataview later only if you want calculated roll-ups that Bases does not yet
express conveniently. Add Canvas only if spatial planning materially helps; it
is not the source of truth.

## Suggested dashboard structure

```text
Second Brain HQ
├── Capture and search links
├── Inbox and weekly-review links
├── Development.base
│   ├── Active
│   └── Needs review
├── Software Content.base
│   ├── Pipeline
│   └── Published
├── Tech Content.base
│   ├── Pipeline
│   └── Published
└── All Knowledge.base
    ├── Recent
    ├── By domain
    └── Needs review
```

The same note can be linked from another domain, but it has one canonical
folder and one `domain` value. That prevents dashboards from counting copied
versions as separate knowledge.

## 1. Turn on Bases

1. Open **Obsidian Settings → Core plugins** and enable **Bases**. Expected: the Bases commands are available.
2. Run **Bases: Create new base** from the Command Palette. Expected: an editable `.base` file opens.
3. Save it as `01 Dashboards/All Knowledge.base`. Expected: it appears beside the dashboard note.
4. Add a view filtered to notes whose `status` property is `inbox`. Expected: your test capture appears in the table.
5. Add a view filtered to the `90 System/AI Review` folder. Expected: a test draft in that folder appears, with other notes excluded.
6. In the dashboard note, insert `![[All Knowledge.base]]`. Expected: the Base renders inside the note.
7. Add optional per-domain Bases and sort recent views by file modification time. Expected: the newest test note sorts first.

If a Base is empty, create a note in the folder it filters and fill the
template properties. A Base does not invent metadata for older notes.

## 2. Choose the useful dashboard signals

Use signals that change a decision. Recommended starting set:

| Signal | Why it matters | Action threshold |
|---|---|---|
| Inbox size | Shows capture debt | Process when above 10 items or older than 7 days |
| Active development notes/projects | Keeps work in progress visible | Park work that has no next action |
| Content by status | Shows bottlenecks between idea and published | If drafts grow for two weeks, stop collecting ideas and finish one |
| Notes changed in 7 and 30 days | Simple growth/activity indicator | A zero week triggers a workflow review, not a writing quota |
| Missing properties | Finds notes omitted from Bases | Repair during weekly review |
| Notes with no outbound links | Finds isolated captures | Link, archive, or deliberately leave standalone |
| Sources awaiting verification | Prevents unsupported publishing | No publication while a required claim is unverified |
| AI review backlog | Prevents generated drafts becoming hidden debt | Approve, revise, or archive weekly |

Do not optimize for total note count. A smaller linked system that changes your
work is more useful than a large clipping archive.

## 3. Review dashboard evidence

Use the selected Bases views to inspect inbox age, missing properties, source
review and active projects. Open a sample row to confirm the underlying note
matches the view. Record only a useful count and the action it prompts in your
weekly-review note.

Expected result: the dashboard reflects the selected vault's actual notes.
A directory count is not evidence that content is correct or safely published.
The optional assisted report belongs to the
[manager workflow](../README.md).

## 4. Add optional Dataview roll-ups

Dataview is a community plugin. It is not required for either primary guide.
If you choose it:

1. Back up the vault.
2. Open **Settings → Community plugins** and turn off Restricted mode.
3. Browse, review, and install **Dataview**.
4. Enable Dataview.
5. Keep JavaScript queries disabled unless a dashboard truly requires them.
6. Paste only reviewed queries into a separate note such as
   `01 Dashboards/Analytics.md`.

### Inbox queue

````markdown
```dataview
TABLE WITHOUT ID file.link AS Note, file.ctime AS Captured
FROM "00 Inbox"
WHERE file.name != "Inbox" AND file.name != "Quick capture"
SORT file.ctime ASC
```
````

### Domain totals

````markdown
```dataview
TABLE WITHOUT ID domain AS Domain, length(rows) AS Notes
FROM "10 Software Development" OR "20 Software Content" OR "30 Tech Content"
WHERE domain
GROUP BY domain
SORT domain ASC
```
````

### Content pipeline

````markdown
```dataview
TABLE WITHOUT ID status AS Status, length(rows) AS Items
FROM "20 Software Content" OR "30 Tech Content"
WHERE type = "content" AND status != "published" AND status != "archived"
GROUP BY status
SORT status ASC
```
````

### Metadata gaps

````markdown
```dataview
TABLE file.folder AS Folder, domain, type, status, created
FROM "10 Software Development" OR "20 Software Content" OR "30 Tech Content"
WHERE !domain OR !type OR !status OR !created
SORT file.mtime DESC
```
````

If a query returns unexpected results, inspect the note properties before
changing the query. Keep property names and values exact and lower-case.

## 5. Create a visual Canvas only when useful

A Canvas can be a useful launch surface for:

- Cards for the selected domains, linked to their index notes.
- An inbox card.
- An active-project card.
- Current software-content and tech-content cards.
- A weekly review card.

Canvas is weak for analytics and can become manually stale. Use it as a visual
map over canonical notes, not as a second task database. The Markdown HQ and
Base files remain the reliable dashboard.

## 6. Make the dashboard the entry point

- Bookmark `Second Brain HQ` in Obsidian.
- Set it as the target of the included Raycast dashboard command.
- Start Claude Code from the vault root so the dashboard and all domains are
  in the same governed working directory.
- Start Codex from the selected vault, as described in the [Codex task](codex.md), so its root and `AGENTS.md`
  form the governed working directory.
- Add a link to the latest weekly review near the top.
- During weekly review, update statuses rather than manually rewriting lists.

## Single vault versus separate physical vaults

| Design | You gain | You lose |
|---|---|---|
| One vault, multiple domains - recommended | Unified links, search, Raycast target, Bases, and AI context | Weaker security separation; permissions apply to the whole directory |
| [Separate vaults](layouts.md) | Strong work/personal separation and separate sync policies | No native cross-vault links or single Base dashboard; Raycast and AI must choose targets |
| Personal vault + separate work vault | Best practical policy compromise | The central personal dashboard can link to the work vault only through external launch links, not live cross-vault analytics |

If policy requires separation, accept the dashboard limitation. Convenience is
not a reason to weaken a confidentiality boundary. The assisted manager
generates one dashboard per vault and a read-only aggregate report; it does not
claim to create a live cross-vault Base.

## Dashboard completion gate 🚦

- [ ] All four core Base files render.
- [ ] Each domain has at least one correctly classified note.
- [ ] Recent and pipeline views use a useful sort/group order.
- [ ] Each selected view matches its sample source notes.
- [ ] The weekly review records useful actions without duplicating source notes.
- [ ] Dashboard signals have explicit actions, not just attractive numbers.
- [ ] Canvas and Dataview remain optional.

Official references: [Introduction to Obsidian Bases](https://obsidian.md/help/bases),
[create and embed a Base](https://obsidian.md/help/bases/create-base), and
[Base views](https://obsidian.md/help/bases/views).

---

[← Choose an integration guide](README.md) · [Operating system →](operations.md)
