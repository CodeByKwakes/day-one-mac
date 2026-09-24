# Advanced optional setup

**Start only after the eight required phases pass.** Nothing in this directory
is needed for a secure, working development Mac.

The required setup intentionally stops at a small, reproducible foundation.
This advanced layer adds power-user capabilities only when they solve a real
need. Teardown work, machine migration, fixed package counts, and optional
complexity never become required setup steps.

Every module is independent, documents its rollback boundary, and ends with a
checklist. Use the tracker from any directory after installing the portable command:

```bash
day-one-mac advanced --list
day-one-mac advanced --status
day-one-mac advanced --guided
day-one-mac advanced --module 15
```

The tracker never installs software or edits configuration. It opens the
selected guide and records completion only when you explicitly mark it. If a
completed guide later changes, its fingerprint becomes **review required**.

## Recommended order

| Module | Capability | Add it when |
|---|---|---|
| [15 · Full dotfiles and bootstrap](15-full-dotfiles-and-bootstrap.md) | Expanded chezmoi inventory, machine data, templates, hooks, and secret audit | More than the minimal five configuration areas must reproduce |
| [16 · Brewfile, applications, and editor inventory](16-brewfile-apps-and-editor.md) | Curated formula/cask/MAS/VS Code desired state and safe cleanup | The Mac needs a wider application catalogue |
| [17 · Shell and package automation](17-shell-and-package-automation.md) | ghq navigation, Git helpers, manager detection, repo/package audits | Repeated terminal work justifies aliases and helpers |
| [18 · Hosting identities, Azure, and worktrees](18-hosting-identities-azure-and-worktrees.md) | Personal/work identity routing, Azure defaults, repository layout, and the linked [VS Code/AI worktree guide](GIT-WORKTREES-VSCODE-AND-AI.md) | Multiple identities/providers or concurrent branches are real requirements |
| [19 · macOS, GUI, and local HTTPS](19-macos-gui-and-local-https.md) | Reviewed defaults, permissions, launch-at-login, Raycast/menu bar, local certificates | The base tools are stable and personal ergonomics are understood |
| [20 · Restore and migrate selected data](20-restore-and-migrate.md) | Verified-volume restore, repo re-cloning, project data, database imports | A clean Mac needs selected content from a previous machine |
| [21 · Audit, maintenance, and rebuild](21-audit-maintenance-and-rebuild.md) | Drift reports, update routine, private commits, and rebuild rehearsal | The setup must remain reproducible over time |
| [22 · Shared AI skills and MCP operations](22-ai-skills-and-mcp-operations.md) | One reviewed skill source, client-specific agents, MCP lifecycle, and trust checks | Optional AI clients are installed and repeated workflows need governance |

Modules 09–14 remain the first optional layer: databases, AI clients, the 10A
OmniRoute gateway, MCP, VS Code profiles, enhanced CLI formulae, and Warp
Drive. Complete the relevant one before its advanced extension here.

## Capability placement

Use this table to find the current home of each capability. It describes the
present Day One Mac design; it is not a second sequence to complete.

| Capability | Day One Mac destination | Decision |
|---|---|---|
| Prerequisites, track, identity, stack | Required Phase 1 | Kept and simplified |
| External backup and system snapshots | Advanced 20 | Optional on a genuinely clean Mac |
| Full teardown and package removal | `ROLLBACK.md` and the two cleanup tools | Kept outside setup; never a required phase |
| Xcode tools and Homebrew | Required Phase 2 | Kept |
| 1Password SSH and FileVault | Required Phase 3 | Kept; advanced secret inventory in 15/22 |
| Folder architecture and ghq | Required Phase 4 | Kept |
| Complete chezmoi inventory and hooks | Advanced 15 | Optional expansion of required Phase 5 |
| Audited Brewfile and application selection | Required Phase 8 plus Advanced 16 | Minimal capture first, curation later |
| Large shell command surface and performance | Advanced 17 | Optional; high-risk shortcuts excluded |
| Node manager dispatch, migrations, and audits | Advanced 17 | Optional; project declarations remain authoritative |
| Python via uv | Required Phase 6 | Kept without global package sprawl |
| Container databases | Optional 09 | Kept outside required flow |
| AI clients and authentication | Optional 10 | Kept outside required flow |
| Local multi-provider AI routing | Optional 10A | Docker-only OmniRoute gateway; client defaults remain reversible |
| MCP servers and client walkthroughs | Optional 11 plus Advanced 22 | Basic connection first, governed lifecycle later |
| Azure CLI, identity switching, and Pipelines | Required Phase 4 plus Advanced 18 | Track-aware base, deeper provider setup optional |
| VS Code base, clean reset, and profiles | Required Phase 7 plus Optional 12 | Kept and separated by need |
| macOS defaults and GUI application setup | Advanced 19 | Optional and preference-driven |
| Restore repositories, databases, and documents | Advanced 20 | Optional and source-verified |
| Full verification and scorecard | Required Phase 8 plus Advanced 21 | Foundation gate first, extended audit later |
| Maintenance and ten-minute rebuild rehearsal | Advanced 21 | Optional operational discipline |
| Command/port reference and Warp workflows | Optional 14 | Kept as an importable command library |
| Full Brewfile catalogue | Advanced 16 | Dynamic desired state; no fixed totals |
| Git worktrees | [Advanced 18](18-hosting-identities-azure-and-worktrees.md) and the [detailed VS Code/AI guide](GIT-WORKTREES-VSCODE-AND-AI.md) | Optional |
| Emergency rollback | `ROLLBACK.md` | Kept and expanded |
| Retired credential managers, package managers, and duplicate-app removal | Cleanup tools only | Not setup work and never replayed on a clean Mac |

## Global rules

1. Preview before apply; diff before overwrite.
2. Back up a target immediately before changing it.
3. Manage reproducible preferences with chezmoi, but keep credentials and
   machine-local selections outside its source.
4. Let projects declare runtime and package-manager versions.
5. Never treat a Docker volume, synchronized editor setting, or cloud vault as
   an independent backup.
6. Do not enable AI tool auto-approval globally.
7. Do not mark an advanced module complete merely because its commands ran;
   complete its verification checklist.

## State and reset

Advanced progress is kept separately from the required phase state:

```text
~/.day-one-mac/advanced/
├── completed/       one guide fingerprint per completed module
└── archive/         reset markers, retained for audit
```

Resetting an advanced marker changes no application, dotfile, project, or
credential:

```bash
day-one-mac advanced --reset 18
```

Use the owning module's rollback section when the configured feature itself
must be removed.

---

[← Day One Mac home](../README.md) · [Begin Advanced 15 →](15-full-dotfiles-and-bootstrap.md)
