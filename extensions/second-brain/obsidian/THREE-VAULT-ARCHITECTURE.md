[← Project home](README.md) · **Three-vault layout** · [Dashboard →](DASHBOARD.md)

# Separate physical Obsidian vaults — three-domain example

Use this design when the three knowledge domains need separate sync accounts,
AI permissions, employer policies, or backup rules. It creates:

```text
~/Vaults/
├── Software Development/
├── Software Content/
└── Tech Content/
```

This is a real separation boundary, not merely three folders in one vault.

## Decide between one and three vaults

| Requirement | One vault, three domains | Three physical vaults |
|---|---|---|
| Obsidian search across everything | Native | Search one vault at a time |
| Links and backlinks across domains | Native | External Obsidian links or written references only |
| One live Bases dashboard | Native | One dashboard per vault; aggregate report is external |
| Different sync accounts or employer rules | Weak boundary | Stronger, explicit boundary |
| Different AI access per domain | Easy to mis-scope | Each AI session targets one vault |
| Simple maintenance | Best | More settings, backups, and templates to maintain |

Choose three vaults because isolation is required, not merely because the
topics are different. If no policy boundary exists, the single-vault design
is simpler and remains the default.

## Step 1 — Choose each vault's policy 🔴

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
day-one-mac applications --id obsidian --install-missing
```

Then install only the companion tools you plan to use:

- Follow [Guide 1](GUIDE-1-OBSIDIAN-RAYCAST.md#step-2--install-obsidian-and-raycast)
  for Raycast.
- Follow [Guide 2](GUIDE-2-OBSIDIAN-CLAUDE-CODE.md#step-2--install-obsidian-and-claude-code)
  for Claude Code.
- Follow [Guide 3](GUIDE-3-OBSIDIAN-CODEX.md#step-2--install-obsidian-and-codex)
  for Codex.

Choose one installation channel for each AI client, verify its account, and do
not open a vault until the account is permitted to process that vault.

## Step 2 — Preview and create the vaults

Use the guided manager when the domains or vault count should be chosen
interactively:

```bash
./scripts/second-brain-manager.sh --guided --apply
```

Choose **Separate vault for each selected domain**, then toggle the domains and
integrations. For a reproducible standard three-domain example, preview the
exact targets:

```bash
./scripts/setup-multi-vaults.sh --tools all
```

Apply after reviewing them:

```bash
./scripts/setup-multi-vaults.sh --tools all --apply
```

Available tool choices are `none`, `raycast`, `claude`, `codex`, and `all`.
`all` installs local integration scripts and both AI instruction files; it does
not install applications, sign in, enable sync, create remotes, or store
credentials. Manager-marked generated files can be refreshed; unrecognised
existing files are preserved with proposed replacements written beside them.

To use a different parent folder:

```bash
./scripts/setup-multi-vaults.sh \
  --root "$HOME/Documents/Knowledge" \
  --tools raycast \
  --apply
```

The root must be an absolute path, cannot be your home directory itself, and
cannot be inside `~/Developer`.

`setup-three-vaults.sh` is a compatibility shortcut. It delegates to the
[dynamic manager](DYNAMIC-LAYOUT-MANAGER.md), which owns the saved manifest and
generated files.

## Step 3 — Understand each structure

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

## Step 4 — Open and configure all three in Obsidian

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

## Step 5 — Use Raycast as the cross-vault launcher

The setup installs three Script Commands when `raycast` or `all` is selected:

- **Open Knowledge Vault** — choose one of the three vaults.
- **Search Knowledge Vault** — choose a vault, then enter a search query.
- **Capture Knowledge Item** — choose a vault, then enter capture text.

Add this Script Directory in Raycast:

```text
~/.local/share/second-brain/raycast
```

Raycast provides the unified launch surface, but the search itself still runs
inside one selected Obsidian vault. Three physical vaults cannot provide a
single native Obsidian content index.

## Step 6 — Use Codex with exactly one vault

When `codex` or `all` is selected, run:

```bash
second-brain-codex development
second-brain-codex software-content
second-brain-codex tech-content
```

The launcher uses `workspace-write` with `on-request` approval and sets the
working directory to only the selected vault. Run `/status` and `/permissions`
at the start of the session.

Do not add the other vaults to a work session merely for convenience. That
would weaken the separation this architecture was chosen to provide. To reuse
knowledge between vaults, create a reviewed handoff note containing only the
approved summary and source reference.

Each vault receives the same defensive `AGENTS.md`. You may make a policy more
restrictive in a vault-specific copy, but do not silently loosen it.

## Step 7 — Use Claude Code with exactly one vault

When `claude` or `all` is selected:

```bash
second-brain-claude development
second-brain-claude software-content
second-brain-claude tech-content
```

The launcher begins in plan mode. Confirm the selected vault and loaded
`CLAUDE.md` before processing notes. The same no-cross-vault rule applies.

## Step 8 — Handle cross-vault knowledge explicitly

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

## Step 9 — Dashboard and analytics

Each vault has its own Base-backed dashboard. Run the aggregate, read-only
health report from Terminal or Raycast:

```bash
second-brain-report
```

It reports note totals, inbox counts, metadata gaps, isolated notes, and recent
activity per vault. It does not simulate a live cross-vault Base and does not
copy notes between vaults.

For a visual central entry point, use Raycast favourites or an Obsidian Canvas
containing external links to the three dashboards. Counts in a manually edited
Canvas become stale; the terminal report remains the reliable aggregate.

## Step 10 — Back up and validate

Apply a versioned backup policy to each vault. Sync is not an independent
backup. Test restoration with a harmless note in each location.

Validate the installed layout:

```bash
./scripts/second-brain-manager.sh --validate
```

## Completion gate 🚦

- [ ] The need for physical separation is recorded.
- [ ] All three vaults open independently in Obsidian.
- [ ] Each vault has the correct inbox, attachment, template, and dashboard settings.
- [ ] Raycast commands always ask for a target vault.
- [ ] AI launchers open only the selected vault.
- [ ] Each vault's AI account and data policy are approved.
- [ ] Cross-vault handoffs cite their original path and review date.
- [ ] The aggregate report runs without changing notes.
- [ ] All three vaults have independent, tested backups.

---

[← Project home](README.md) · [Dashboard →](DASHBOARD.md)
