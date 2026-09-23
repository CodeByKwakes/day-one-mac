[← Project home](README.md) · **Dynamic manager** · [Three-vault design →](THREE-VAULT-ARCHITECTURE.md)

# Dynamic vault and domain manager

The manager creates a knowledge layout from decisions instead of assuming that
every person needs the same three physical vaults.

```bash
./scripts/second-brain-manager.sh --guided --apply
```

Nothing changes while the questions are being answered. The complete layout is
shown before the final `APPLY LAYOUT` confirmation.

## Vaults and domains are different

- A **vault** is a physical Obsidian boundary. It has its own plugins, settings,
  sync configuration, backup coverage, and AI working-directory boundary.
- A **domain** is an organised area of knowledge. Several domains can live in
  one vault without duplicating Obsidian settings.

Use another domain for organisation. Use another physical vault when work
policy, sync accounts, AI accounts, or confidentiality require separation.

## Guided sequence

The wizard asks, in this order:

1. Why separate vaults might be needed.
2. Whether to start from a unified, separate-vault-per-domain, work/personal,
   or custom physical layout.
3. Which built-in domains to include.
4. Whether to add any custom domains.
5. Where the vaults should live.
6. Which integrations are available.
7. Which vault may use each integration.
8. Which folder archetype each domain uses.
9. Whether AI processing is allowed for each domain.

Multi-selection screens use:

```text
Up/Down or j/k  move
Space           toggle
a               select all
n               select none
Enter           accept
q               cancel
```

The privacy questions are intentionally separate from installing an AI
launcher. A vault may have Codex or Claude Code available while a particular
domain remains `ai_allowed: false`.

## Layout presets

| Preset | Physical result | Domain result |
|---|---|---|
| Unified | One `Second Brain` vault | Every selected domain receives a numbered folder |
| Separate vault per domain | One physical vault per selected domain | A domain's archetype folders live at its vault root |
| Work + Personal | `Work Knowledge` and `Personal Knowledge` | You select which domains belong to work |
| Custom | Between 1 and 20 named physical vaults | Each domain is assigned to one selected vault |

The separate-vault-per-domain layout is dynamic: selecting four domains creates
four physical vaults. There is no hidden three-domain limit.

## Built-in domains

- Software Development
- Software Content
- Tech Content
- Personal Learning
- Projects
- Research Library

Custom domains receive a safe stable slug and can use any folder archetype.
Names can contain spaces; slugs use lower-case letters, numbers, and hyphens.
The slug is the stable identity. The manager deliberately blocks an in-place
display-name change because friendly generated filenames also use that name.
Rename the files through a separate reviewed migration, then update the
manifest, rather than leaving duplicate index and template files behind.

## Folder archetypes

| Archetype | Generated folders |
|---|---|
| Development | Projects, Learning, Reference, Sources |
| Content | Ideas, Research, Drafts, Scheduled, Published, Sources |
| Research | Topics, Sources, Notes, Syntheses |
| Projects | Active, Waiting, Completed, Archive |
| Minimal | Notes, Sources |
| Custom | A reviewed comma-separated list |

Every vault also receives its own Inbox, dashboard folder, Attachments,
`90 System/AI Review`, Reports, and Templates.

## Saved source of truth

The manager saves a strict, tab-delimited manifest:

```text
~/.config/second-brain/layout.tsv
```

It also generates a readable report:

```text
~/.config/second-brain/layout-report.md
```

Show it at any time:

```bash
./scripts/second-brain-manager.sh --show
```

The manifest deliberately needs no `jq`, Python, Node, or third-party parser.
The manager rejects duplicate vaults, duplicate domain roots, unknown tools,
unsafe relative folders, nested vaults, paths inside `~/Developer`, and names
that would make the report or TSV ambiguous.

## Non-interactive presets

Preview a reproducible preset:

```bash
./scripts/second-brain-manager.sh \
  --preset unified \
  --single-vault "$HOME/Vaults/Second Brain" \
  --tools raycast,codex
```

Apply the identical command after adding `--apply`:

```bash
./scripts/second-brain-manager.sh \
  --preset unified \
  --single-vault "$HOME/Vaults/Second Brain" \
  --tools raycast,codex \
  --apply
```

Other examples:

```bash
./scripts/second-brain-manager.sh --preset multi-domain --tools all
./scripts/second-brain-manager.sh --preset work-personal --tools raycast,codex
```

`none`, `raycast`, `claude`, `codex`, and comma-separated combinations are
accepted. `all` expands to all three integrations.

## Advanced custom manifest

The guided route is preferred. For automation, copy the installed manifest,
edit the copy, and preview it:

```bash
./scripts/second-brain-manager.sh --layout ./proposed-layout.tsv
```

Records have these shapes:

```text
meta    schema    1
vault   SLUG   DISPLAY_NAME   ABSOLUTE_PATH   SENSITIVITY   TOOLS   DASHBOARD_FOLDER
domain  SLUG   DISPLAY_NAME   VAULT_SLUG   DOMAIN_FOLDER   ARCHETYPE   SENSITIVITY   AI_ALLOWED   SUBFOLDERS
```

The separators must be literal tabs. Every field is required; use `none` for
no integrations and `.` when a single domain owns the vault root.

Example:

```text
meta	schema	1
meta	preset	custom
meta	reasons	work-policy
vault	engineering	Engineering	/Users/example/Vaults/Engineering	work-confidential	codex	01 Dashboards
domain	learning	Engineering Learning	engineering	10 Learning	development	work-confidential	false	Projects,Learning,Reference,Sources
```

Apply only after the preview validates:

```bash
./scripts/second-brain-manager.sh --layout ./proposed-layout.tsv --apply
```

## Reconfiguration

Run the guided wizard again with the current report displayed first:

```bash
./scripts/second-brain-manager.sh --reconfigure --apply
```

The new answers form a complete desired layout. Before confirmation, the
manager shows the report and manifest diff.

Safety rules:

- Existing notes are never deleted.
- Removing a domain or vault from the manifest leaves its files in place as
  retained but unmanaged content.
- Changing an existing vault path is blocked as a migration.
- Moving an existing domain to another vault or folder is blocked as a
  migration.
- An existing file without the manager marker is preserved; a
  `.day-one-mac-proposed` sibling is written for manual comparison.
- Generated files and commands are backed up before replacement.
- Deselected generated launchers are moved into the recovery backup rather
  than left active against stale configuration.

Backups and reconfiguration reports live under:

```text
~/.local/state/second-brain/
```

Physical moves are deliberately outside this scaffolder. Review, back up, and
perform them as a separate migration so links, attachments, sync, and Git
history can be checked.

## Dynamic Raycast behaviour

Add this one Script Command directory:

```text
~/.local/share/second-brain/raycast
```

The Open, Search, and Capture commands read `layout.tsv` every time. If several
vaults enable Raycast, the command asks which vault to target. If only one is
enabled, it opens directly. Reconfiguration does not require hardcoded dropdown
comments or one script per vault.

## Dynamic AI launchers

Run either launcher without an argument to choose from its allowed vaults:

```bash
second-brain-codex
second-brain-claude
```

Or pass a stable vault slug:

```bash
second-brain-codex engineering
second-brain-claude personal-knowledge
```

Codex starts with only that vault as its working directory, the
`workspace-write` sandbox, and `on-request` approvals. Claude Code changes into
only that vault and starts in plan mode. A launcher refuses a vault that does
not enable that client.

## Refresh and validation

Preview integration refreshes after pulling a newer version of this project:

```bash
./scripts/second-brain-manager.sh --refresh-integrations
./scripts/second-brain-manager.sh --refresh-integrations --apply
```

Validate the saved manifest and every generated vault:

```bash
./scripts/second-brain-manager.sh --validate
second-brain-report
second-brain-report --write
```

The written aggregate report is stored outside the vaults under local state,
so a multi-vault report does not leak one vault's counts into another.

## Compatibility commands

The previous commands remain available as preset wrappers:

```bash
./scripts/setup-second-brain.sh --tools raycast-codex --apply
./scripts/setup-multi-vaults.sh --tools all --apply
```

They now call the manager and produce the same manifest, generated launchers,
validation, and safety behaviour. `setup-three-vaults.sh` and the
`three-domain` preset name remain accepted only as compatibility aliases for
older notes or automation.

## Previous namespace

Current control files use the concise `second-brain` namespace under
`~/.config`, `~/.local/share`, and `~/.local/state`. If an earlier installation
has a readable `~/.config/fresh-start-second-brain/layout.tsv`, the manager and
launchers can still read it. The next confirmed layout apply writes the current
namespace and moves known legacy control files into the recoverable backup.
Vault notes are not moved by this namespace migration. After migration, update
Raycast's Script Directory to `~/.local/share/second-brain/raycast`.

---

[← Project home](README.md) · [Three-vault design →](THREE-VAULT-ARCHITECTURE.md)
