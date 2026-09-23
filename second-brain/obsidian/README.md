[← Choose a Second Brain](../README.md)

# Obsidian Second Brain — Day One Mac

**Guide release 2.3.0.0 · macOS · dynamic vaults, domains, and integrations**

This is a self-contained build for a new personal knowledge system. It does
not require the older MacBook or second-brain playbooks. Start with the dynamic
manager so it can ask which physical vaults, domains, folders, privacy
boundaries, and integrations you need. Then follow the guide for each tool you
selected to finish its application-specific settings and smoke test.

## What this builds

The recommended starting design is one local Obsidian vault at
`~/Vaults/Second Brain`, split into three domain bases:

1. **Software development** — work, projects, decisions, debugging, and
   learning.
2. **Software content** — product documentation, tutorials, examples, release
   material, and code-led articles.
3. **Tech content** — videos, newsletters, social posts, reviews, research,
   and publishing plans.

One vault is the default because Obsidian, Raycast, Claude Code, and Codex can
search and link across every domain without maintaining three indexes. The
`domain` property and numbered folders keep the boundaries visible. The
manager can instead build work/personal, one-vault-per-domain, or fully custom
layouts when the privacy and account boundaries require them.

> 🔴 **Work-policy gate:** if employer rules do not allow work notes in a
> personal sync service, remote repository, or AI service, create a physically
> separate work vault. A Markdown property cannot prevent a tool with folder
> access from reading a file.

## Choose integration guides after the layout wizard

| I want | Start here | Best at | Main tradeoff |
|---|---|---|---|
| Fast capture and retrieval from anywhere on the Mac | [Guide 1 — Obsidian + Raycast](GUIDE-1-OBSIDIAN-RAYCAST.md) | Search, capture, opening the right note | AI synthesis is not the centre of the workflow |
| AI-assisted processing and synthesis | [Guide 2 — Obsidian + Claude Code](GUIDE-2-OBSIDIAN-CLAUDE-CODE.md) | Inbox processing, summaries, connections, content reuse | Requires a supported Claude account and a deliberate privacy boundary |
| AI assistance with Codex | [Guide 3 — Obsidian + Codex](GUIDE-3-OBSIDIAN-CODEX.md) | Governed local file work, reviewed synthesis, and a familiar Codex workflow | Requires an approved OpenAI account and careful working-directory scope |
| Raycast plus an AI client | Complete Guide 1, then the selected AI guide | Fast capture plus reviewed synthesis | More moving parts and separate permission surfaces |

Each guide is complete enough to use on its own, but the clearest route is:

1. Preview or apply the reason-first manager under **Fastest safe start**.
2. Open the guide for every selected integration.
3. Complete only that guide's application settings and test section.

The guides share the same default properties, templates, and dashboard. The
manager adapts them to the selected domains instead of requiring a fixed count.

## Choose a vault layout

| Layout | Choose it when | Important limitation |
|---|---|---|
| **One unified vault — recommended** | All domains may use the same sync and AI policy | Access to the vault can expose every included domain |
| **Separate vault per domain** | Each selected domain needs an independent physical boundary | Obsidian has no single native cross-vault search, links, or live Base dashboard |
| **Work + Personal** | Work policy or accounts must stay separate from personal notes | Knowledge shared between the two vaults needs an explicit handoff |
| **Custom** | Your boundaries do not fit the presets | More choices and maintenance; use only the vaults you can explain |

For every multi-vault layout, the manager adds target selection to Raycast and
one-vault-at-a-time launchers for Codex and Claude Code. It does not pretend
that independent vaults behave like one Obsidian database.

## Project contents

| File | Purpose |
|---|---|
| [Guide 1](GUIDE-1-OBSIDIAN-RAYCAST.md) | End-to-end Obsidian and Raycast setup |
| [Guide 2](GUIDE-2-OBSIDIAN-CLAUDE-CODE.md) | End-to-end Obsidian and Claude Code setup |
| [Guide 3](GUIDE-3-OBSIDIAN-CODEX.md) | End-to-end Obsidian and Codex setup |
| [Dynamic layout manager](DYNAMIC-LAYOUT-MANAGER.md) | Reason-first wizard, custom domains, reconfiguration, manifest, and safety rules |
| [Three-vault architecture](THREE-VAULT-ARCHITECTURE.md) | Separate vaults, target-aware launchers, boundaries, and tradeoffs |
| [Dashboard](DASHBOARD.md) | Core Bases dashboard, optional Dataview analytics, and health reporting |
| [Operating system](OPERATING-SYSTEM.md) | Daily capture, weekly processing, monthly review, naming, and maintenance |
| [Alternative stacks](ALTERNATIVE-STACKS.md) | Three credible alternatives with gains and losses |
| [Checklist](CHECKLIST.md) | A short, verifiable checklist for either route |
| `assets/vault/` | Starter notes, templates, and Obsidian Base files |
| `assets/raycast/` | Three Raycast Script Commands and their configuration example |
| `assets/codex/` | Manual/legacy bounded Codex launcher for the fixed single-vault design |
| `assets/three-vaults/` | Manual/legacy fixed-layout dashboards, policy files, and launchers |
| `assets/manager/` | Manifest-aware Raycast, Codex, Claude, and reporting commands |
| `scripts/second-brain-manager.sh` | Dynamic guided setup and the canonical layout manager |
| `scripts/setup-second-brain.sh` | Compatibility wrapper for the unified preset |
| `scripts/setup-multi-vaults.sh` | Shortcut for the standard separate-vault-per-domain preset |
| `scripts/setup-three-vaults.sh` | Former command name retained as a compatibility alias |
| `scripts/vault-health-report.sh` | Legacy per-vault analytics report; writes only with `--write` |
| `scripts/three-vault-health-report.sh` | Legacy fixed three-vault aggregate report |
| `scripts/validate.sh` | Validates this project and, optionally, an installed vault |

## Fastest safe start

Run the reason-first wizard and approve the resulting plan in the same session:

```bash
cd "$(day-one-mac root)/second-brain/obsidian"
./scripts/second-brain-manager.sh --guided --apply
```

It first asks why separation may be needed, recommends one or several physical
vaults, then lets you toggle domains and integrations. No file changes before
the final `APPLY LAYOUT` confirmation.

To explore the questions without applying the result:

```bash
./scripts/second-brain-manager.sh --guided
```

For a reproducible standard preset, preview the generated vault first:

```bash
cd "$(day-one-mac root)/second-brain/obsidian"
./scripts/setup-second-brain.sh --tools raycast
```

Choose `raycast`, `claude`, `codex`, `both` (Raycast + Claude),
`raycast-codex`, `claude-codex`, or `all`. Nothing is written until `--apply`
is present:

```bash
./scripts/setup-second-brain.sh --tools both --apply
```

For Codex plus Raycast:

```bash
./scripts/setup-second-brain.sh --tools raycast-codex --apply
```

For the standard separate-vault-per-domain layout, with one physical vault for each default
domain:

```bash
./scripts/setup-multi-vaults.sh --tools all
./scripts/setup-multi-vaults.sh --tools all --apply
```

To let the helper check selected application ownership and resolve only missing
applications:

```bash
./scripts/setup-second-brain.sh --tools both --apply --install-apps
```

For each missing app, choose Homebrew, another approved installer with a live
recheck, or a safe stop. For an unattended personal-Mac run, make Homebrew
explicit with `--app-install-policy homebrew`. Use `check-only` when deployment
policy allows reporting but not installation. `--yes` never chooses ownership.

The manager updates only files bearing its ownership marker. It preserves an
unrecognised existing note and writes a `.day-one-mac-proposed` comparison
instead. It refuses unsafe or nested vault paths and paths inside
`~/Developer`, creates no remote, enables no cloud sync, and stores no
credentials. Reconfiguration cannot silently move or rename a domain or vault.
See the [manager guide](DYNAMIC-LAYOUT-MANAGER.md) for custom layouts and
recovery behaviour.

## What the manager creates

| Location | Contents |
|---|---|
| Each selected vault | Inbox, domain folders, Obsidian Bases, dashboard, attachments, AI review, reports, and templates |
| `~/.config/second-brain/layout.tsv` | Canonical tab-delimited layout manifest |
| `~/.config/second-brain/layout-report.md` | Human-readable copy of the selected vault, domain, privacy, and integration choices |
| `~/.local/share/second-brain/raycast` | Dynamic Open, Search, and Capture Script Commands when Raycast is selected |
| `~/.local/bin/second-brain-codex` | Vault-scoped Codex selector when Codex is selected |
| `~/.local/bin/second-brain-claude` | Vault-scoped Claude Code selector when Claude is selected |
| `~/.local/bin/second-brain-report` | Read-only aggregate health report for every configured vault |
| `~/.local/state/second-brain` | Recoverable backups, reconfiguration reviews, and intentionally written health reports |

The manager can install selected applications only when `--install-apps` is
explicitly supplied. It accepts valid Homebrew, Mac App Store, Company Portal,
or manual installations and never replaces an external copy. Missing apps use
the same Homebrew/external/safe-stop choice as the main phases. It never signs
in, enables sync, creates a remote, stores credentials, or moves existing vault
notes. Ownership is recorded in
`~/.day-one-mac/application-provenance.md`.

## Review or change the setup later

```bash
./scripts/second-brain-manager.sh --show
./scripts/second-brain-manager.sh --validate
second-brain-report
./scripts/second-brain-manager.sh --reconfigure --apply
./scripts/second-brain-manager.sh --refresh-integrations --apply
```

Reconfiguration shows a complete replacement plan and manifest diff. Removing
a domain stops managing it but keeps its notes. Moving or renaming an existing
domain or vault is blocked until you perform a separate, reviewed migration.
If a previous version used `~/.config/fresh-start-second-brain`, the current
manager reads it and migrates known control files on the next confirmed apply;
vault content stays in place.

Validate the source project and the installed vault:

```bash
./scripts/validate.sh
./scripts/validate.sh --vault "$HOME/Vaults/Second Brain"
./scripts/second-brain-manager.sh --validate
```

## Version note

`2.3.0.0` is the release of this guide, not a required installed-app version.
The Raycast path was tested against the Raycast 2.3.x interface. Use a current
supported Raycast release; do not downgrade or pin the application solely to
match this guide.
Raycast Store extensions and Homebrew casks update independently. The guide
uses stable public commands—Search Note, Create Note, Script Commands, and
Obsidian URI—rather than private implementation details.

## Recommended result after day one

For a unified preset, replace the example counts below with the domains you
selected:

- One idea captured in `00 Inbox/Quick capture.md`.
- One development learning note.
- One software-content idea.
- One tech-content idea.
- `Second Brain HQ.md` opens and displays the All Knowledge view plus one Base
  view for every selected domain.
- Search finds text across every selected domain.
- Either Raycast opens the note from anywhere, Claude Code completes a
  read-only synthesis in plan mode, or Codex completes one in a read-only
  sandbox.
- A real backup exists. Sync alone is not treated as backup.

Next: [choose Guide 1](GUIDE-1-OBSIDIAN-RAYCAST.md),
[choose Guide 2](GUIDE-2-OBSIDIAN-CLAUDE-CODE.md),
[choose Guide 3](GUIDE-3-OBSIDIAN-CODEX.md), or review the
[three-vault design](THREE-VAULT-ARCHITECTURE.md).
