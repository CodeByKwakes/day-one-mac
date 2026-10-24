[← Project home](README.md) · **Three-vault layout** · [Dashboard →](dashboard.md)

# Separate physical Obsidian vaults - three-domain example

Use this design when the three knowledge domains need separate Obsidian settings,
sync configuration or backup rules. The example uses these folders:

```text
~/Vaults/
├── Software Development/
├── Software Content/
└── Tech Content/
```

Each vault has separate Obsidian settings and sync configuration. Separate
folders alone do not restrict filesystem access or an AI client's permissions.
Confirm any required access restrictions with the system or policy owner.

## Decide between one and three vaults

| Requirement | One vault, three domains | Three physical vaults |
|---|---|---|
| Obsidian search across everything | Native | Search one vault at a time |
| Links and backlinks across domains | Native | External Obsidian links or written references only |
| One live Bases dashboard | Native | One dashboard per vault; aggregate report is external |
| Separate sync configuration | Shared vault configuration | Configuration selected for each vault |
| Different AI access per domain | Configure client permissions explicitly | Configure client permissions and select the intended vault |
| Simple maintenance | Best | More settings, backups, and templates to maintain |

Choose three vaults when maintaining separate settings, sync and backups is
useful. The single-vault design remains the default for domains that share those
choices. Enforce employer access rules through approved permissions and services.

## 1. Choose each vault's policy 🔴

Record these choices before creating anything:

| Vault | Sync allowed? | AI account/provider | AI allowed? | Backup target |
|---|---|---|---|---|
| Software Development |  |  |  |  |
| Software Content |  |  |  |  |
| Tech Content |  |  |  |  |

If software-development notes contain employer material, keep that vault out
of personal sync, personal Git remotes, and personal AI accounts unless policy
explicitly permits them.

## Install the selected applications

Install Obsidian first:

```bash
brew install --cask obsidian
```

Then install only the companion tools you plan to use:

- Follow [Guide 1](raycast.md#2-verify-obsidian-and-raycast)
  for Raycast.
- Follow [Guide 2](claude.md#2-install-obsidian-and-claude-code)
  for Claude Code.
- Follow [Guide 3](codex.md#2-install-and-verify-the-selected-clients)
  for Codex.

Choose one installation channel for each AI client, verify its account, and do
not open a vault until the account is permitted to process that vault.

## 2. Create each selected vault manually

Follow [the vault creation task](README.md) once for each approved physical
boundary. Use a distinct folder and account/sync decision for each vault. Add
only the selected domain folders; do not nest one vault inside another.

Expected result: Obsidian opens each intended root independently and a test note
is saved in the correct physical vault. Existing notes remain untouched.

## 3. Understand each structure

### Software Development

```text
Software Development/
├── 00 Inbox/
├── 01 Dashboard/
├── 10 Projects/
├── 20 Learning/
├── 30 Reference/
├── 40 Sources/
├── 80 Attachments/
├── 90 System/{AI Review,Reports}/
└── 99 Templates/
```

Use it for engineering decisions, debugging notes, project context, learning,
and reusable references. Keep source repositories in `~/Developer`; link to
them from notes rather than placing code inside the vault.

### Software Content

```text
Software Content/
├── 00 Inbox/
├── 01 Dashboard/
├── 10 Ideas/
├── 20 Drafts/
├── 30 Published/
├── 40 Sources/
├── 80 Attachments/
├── 90 System/{AI Review,Reports}/
└── 99 Templates/
```

Use it for documentation, tutorials, release material, code-led articles, and
their editorial pipeline.

### Tech Content

```text
Tech Content/
├── 00 Inbox/
├── 01 Dashboard/
├── 10 Ideas/
├── 20 Research/
├── 30 Scripts/
├── 40 Published/
├── 50 Sources/
├── 80 Attachments/
├── 90 System/{AI Review,Reports}/
└── 99 Templates/
```

Use it for broader technology research, video and podcast scripts,
newsletters, social posts, reviews, and publishing retrospectives.

## 4. Open and configure all three in Obsidian

Repeat these steps for each folder:

1. Choose **Open folder as vault**.
2. Set new notes to `00 Inbox`.
3. Set attachments to `80 Attachments`.
4. Enable automatic link updates.
5. Enable Bases, Backlinks, File recovery, Properties, Search, and Templates.
6. Set the template folder to `99 Templates`.
7. Open the vault's dashboard and verify its Base embed.

Obsidian settings are normally vault-local under `.obsidian`. Configure and
back up each vault independently. Do not copy an employer-controlled
`.obsidian` folder into a personal vault without reviewing its plugins and sync
settings.

## 5. Open each vault from Raycast

Create a Quicklink to each vault's dashboard using the [Raycast task](raycast.md). Give each link a distinct name and test it.

Expected result: each command opens exactly one intended vault. Search remains vault-specific; three folders do not create a single native Obsidian search index.

## 6. Use Codex with exactly one vault

Follow the [Codex task](codex.md), substituting the exact selected vault path in `codex --cd`. Create and review that vault's `AGENTS.md` before opening it.

Expected result: `/status` shows the selected vault and `/permissions` shows the intended access. Keep other vaults outside the session. Use a reviewed handoff note for approved cross-vault knowledge.

## 7. Use Claude Code with exactly one vault

Follow the [Claude task](claude.md) from the selected vault directory. Review its `CLAUDE.md` or shared instruction link before starting in plan mode.

Expected result: `/context` identifies the intended instructions and `/permissions` shows the chosen access level. Do not add another vault merely for convenience.

## 8. Handle cross-vault knowledge explicitly

Wikilinks do not resolve across three independent vaults. Use one of these
reviewable patterns:

- Add an `obsidian://open` external link to open a known note in another vault.
- Record a plain source reference containing vault name, note path, and review
  date.
- Copy a short, approved handoff summary; do not duplicate the entire source
  note.
- Re-check the original before publishing because the handoff can become stale.

Example:

```markdown
Source vault: Software Development
Source note: 20 Learning/Package manager ownership.md
Reviewed: 2026-09-12
Open: [Development source](obsidian://open?vault=Software%20Development&file=20%20Learning%2FPackage%20manager%20ownership)
```

## 9. Dashboard and analytics

Open the [dashboard](dashboard.md) in each vault and review its Inbox and AI Review views. Expected: each view includes a harmless test note with matching properties and excludes notes outside that vault.

For a central entry point, add Raycast favourites or an Obsidian Canvas with external links to the three dashboards. A manually recorded total becomes stale; check the underlying views when making a decision.

## 10. Back up and validate

Apply a versioned backup policy to each vault. Sync is not an independent
backup. Test restoration with a harmless note in each location.

Open each vault and verify its selected template, attachment and dashboard paths. Expected: a test note appears only in its intended vault.

## Completion gate 🚦

- [ ] The need for physical separation is recorded.
- [ ] All three vaults open independently in Obsidian.
- [ ] Each vault has the correct inbox, attachment, template, and dashboard settings.
- [ ] Each Raycast Quicklink opens the intended vault.
- [ ] Each AI client opens only the selected vault.
- [ ] Each vault's AI account and data policy are approved.
- [ ] Cross-vault handoffs cite their original path and review date.
- [ ] Dashboard observations match a sample of notes in each vault.
- [ ] All three vaults have independent, tested backups.

---

[← Project home](README.md) · [Dashboard →](dashboard.md)
