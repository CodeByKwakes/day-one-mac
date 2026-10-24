# Setup phase and manual coverage

Every required phase has a manual capability guide. Assisted modules also link
to manual work where that capability applies. Runtime records, ownership
manifests and generated proposals are assisted features; the manual route uses
its own notes and backups instead of recreating those records.

## Required setup and checkpoints

| Phase or checkpoint | Assisted entry | Manual owner | Verification boundary |
|---|---|---|---|
| Existing-Mac preparation | [Stage 0](../../setup/assisted/existing-mac/README.md) | [Backup and restore](../../setup/manual/backup-and-restore.md) | Approved starting boundary and independent recovery; no manual broad cleanup script |
| Optional AI checkpoint, before Phase 1 | [AI setup assistant](../../setup/assisted/ai-setup-assistant.md) | [AI preparation](../../setup/manual/ai/setup-assistant.md) | Intentional skip or one client with account/tool checks |
| 01 | [First boot](../../setup/assisted/01-first-boot-and-decisions.md) | [macOS](../../setup/manual/macos.md), [decisions](../decisions.md) | Native supported OS, policy, backup and selections |
| Optional macOS checkpoint | [Preferences](../../setup/assisted/MACOS-SETTINGS.md) | [macOS preferences](../../setup/manual/macos.md) | Review applied preferences and GUI permissions |
| 02 | [Foundation](../../setup/assisted/02-command-line-foundation.md) | [Apple tools and Homebrew](../../setup/manual/homebrew.md) | Native tools and selected package owner |
| Installation Centre | [Selected applications](../../setup/assisted/INSTALLATION-CENTRE.md) | [Applications](../../setup/manual/apps/README.md) | Selected apps launch; account/licence prompts remain human |
| 03 | [Security](../../setup/assisted/03-security-and-ssh.md) | [Authentication](../../setup/manual/security/README.md) | Selected key/helper works; recovery access checked |
| 04 | [Core tools](../../setup/assisted/04-core-tools-and-hosting.md) | [Git](../../setup/manual/git/setup.md), [folders](../../setup/manual/development/folders.md) | Correct identity and authorised repository read |
| 05 | [Shell](../../setup/assisted/05-dotfiles-and-shell.md) | [Shell and ownership](../../setup/manual/shell/README.md) | Syntax and new-shell behaviour |
| 06 | [Languages](../../setup/assisted/06-language-toolchains.md) | [Toolchains](../../setup/manual/languages.md) | Selected project runtime and dependency checks |
| 07 | [Editor base](../../setup/assisted/07-vscode-base.md) | [VS Code](../../setup/manual/editors/vscode.md) | Intended profile/settings, or deliberate editor skip |
| 08 | [Verify and reproduce](../../setup/assisted/08-verify-and-reproduce.md) | [Backup and verification](../../setup/manual/backup-and-restore.md) | Actual project, account and sample recovery evidence |

## Optional and advanced modules

The [module catalogue](../../../config/catalogs/modules.tsv) owns executable
IDs and prerequisites. All listed module apply routes require Phase 8. Their
manual counterparts have tool-specific prerequisites and need no phase markers.

| Module | Assisted scope | Manual owner | Completion check |
|---|---|---|---|
| 09 | [Selected local databases](../../setup/assisted/optional/09-databases.md) | [Containers](../../setup/manual/databases/containers.md), [operations](../../setup/manual/databases/operations.md) | Query and separate-target restore |
| 10 | [Additional AI clients](../../setup/assisted/optional/10-ai-agents.md) | [Clients](../../setup/manual/ai/clients.md) | Version, account and harmless prompt separately |
| 10A | [Owned OmniRoute container](../../setup/assisted/optional/10a-omniroute.md) | [OmniRoute](../../setup/manual/ai/omniroute.md) | Local health and selected provider |
| 11 | [MCP proposals](../../setup/assisted/optional/11-mcp-servers.md) | [MCP](../../setup/manual/ai/mcp.md) | Reviewed scope, auth and approved tool test |
| 13 | [CLI selection](../../setup/assisted/optional/13-enhanced-cli-tools.md) | [Shell integrations](../../setup/manual/shell/aliases.md) | Tool invocation and optional aliases |
| 14 | [Warp export](../../setup/assisted/optional/14-warp-drive.md) | [Warp](../../setup/manual/terminals/warp.md) | Manual import and a harmless workflow |
| 15 | [Dotfile proposals](../../setup/assisted/advanced/15-full-dotfiles-and-bootstrap.md) | [Dotfile hardening](../../setup/manual/shell/dotfile-hardening.md) | Reviewed source and scoped apply |
| 16 | [Application inventory](../../setup/assisted/advanced/16-brewfile-apps-and-editor.md) | [Brewfile](../../setup/manual/apps/brewfile.md) | Backup and desired-state comparison |
| 17 | [Helper bundles](../../setup/assisted/advanced/17-shell-and-package-automation.md) | [Package workflows](../../setup/manual/shell/package-workflows.md) | Owner-correct commands and project checks |
| 18 | [Identity/worktree proposals](../../setup/assisted/advanced/18-hosting-identities-azure-and-worktrees.md) | [Identities](../../setup/manual/git/multiple-identities.md), [worktrees](../../setup/manual/development/worktrees/README.md) | Correct account in each checkout |
| 19 | [Selected macOS preferences](../../setup/assisted/advanced/19-macos-gui-and-local-https.md) | [macOS](../../setup/manual/macos.md), [local HTTPS](../../setup/manual/local-https.md) | GUI permissions and trusted local certificate |
| 20 | [Restore staging](../../setup/assisted/advanced/20-restore-and-migrate.md) | [Project/data restore](../../setup/manual/preparation/restore-projects.md) | Separate destinations and verified contents |
| 21 | [Audit snapshot](../../setup/assisted/advanced/21-audit-maintenance-and-rebuild.md) | [Maintenance](../../setup/manual/maintenance.md) | Project checks and independent recovery rehearsal |
| 22 | [AI governance evidence](../../setup/assisted/advanced/22-ai-skills-and-mcp-operations.md) | [AI maintenance](../../setup/manual/ai/maintenance.md) | Selected skills, scopes and account access |

Module 12 remains [retired](../../setup/assisted/optional/12-vscode-profiles.md).
Use the dedicated [profile command](../../setup/assisted/optional/vscode-profiles.md)
or the [manual editor guide](../../setup/manual/editors/vscode.md). Other
standalone capabilities include [AI workspaces](../../setup/manual/development/ai-workspaces.md),
[Second Brain](../../setup/manual/second-brain/README.md),
[Raycast](../../setup/manual/apps/raycast.md) and
[Shortcuts](../../setup/manual/apps/macos-shortcuts.md).

## Guide contract and validation

A setup procedure states its objective, prerequisites, numbered actions,
expected results, verification and recovery. Optional branches name their
configuration/installation owner. Shared prerequisites, terms and acceptance
criteria live in the [shared library](../README.md); route indexes link to each
procedure's single owner.

Repository checks cover packaged document presence, local links, preserved
bookmarks, shell/JSON example syntax and selected disposable failure tests.
Syntax checks do not execute installers or prove account, database, GUI or
hardware acceptance. Follow [shared verification](../verification.md) for those
checks and record untested items explicitly.

Changes are reviewed in Git with their commands and evidence. Runtime releases
package the approved guides; historical audits remain in maintainer records.
A guide in the source tree may describe a command absent from an older installed
release. Inspect the installed command's help before following that procedure.
