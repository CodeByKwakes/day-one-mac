# Setup documentation audit inventory

Source: `7fe179f`. This inventory records every tracked Markdown file in the manual and assisted setup trees. All files received structural, link and example-syntax scans; substantive findings came from targeted procedure and code review. It does not certify live installation or external link availability.

## Manual guides

| File | Purpose | Type |
|---|---|---|
| `docs/setup/manual/1password.md` | 1Password, SSH and hosting walkthrough | Compatibility pointer |
| `docs/setup/manual/CHEZMOI-SETUP-TUTORIAL.md` | Set up chezmoi with Day One Mac | Compatibility pointer |
| `docs/setup/manual/MANUAL-SETUP-GUIDE.md` | Day One Mac — complete manual and script-assisted setup | Compatibility pointer |
| `docs/setup/manual/README.md` | Manual Setup | Guide/reference/index |
| `docs/setup/manual/ai/clients.md` | Install and configure selected AI clients | Guide/reference/index |
| `docs/setup/manual/ai/instructions-agents-skills.md` | Project instructions, agents and skills | Guide/reference/index |
| `docs/setup/manual/ai/maintenance.md` | Maintain AI skills and MCP access | Guide/reference/index |
| `docs/setup/manual/ai/mcp-docker.md` | Set up MCP servers with Docker | Guide/reference/index |
| `docs/setup/manual/ai/mcp.md` | Project and global MCP connections | Guide/reference/index |
| `docs/setup/manual/ai/omniroute.md` | Configure an OmniRoute gateway manually | Guide/reference/index |
| `docs/setup/manual/ai/workflows.md` | AI workflows in VS Code | Guide/reference/index |
| `docs/setup/manual/apps/README.md` | Set up selected applications | Guide/reference/index |
| `docs/setup/manual/apps/brewfile.md` | Maintain a selective Brewfile | Guide/reference/index |
| `docs/setup/manual/apps/keyboard-shortcuts.md` | Day One Mac keyboard shortcuts | Guide/reference/index |
| `docs/setup/manual/apps/macos-shortcuts.md` | Optional macOS Shortcuts for development | Guide/reference/index |
| `docs/setup/manual/apps/raycast-ai-providers.md` | Choose and configure a Raycast AI provider | Guide/reference/index |
| `docs/setup/manual/apps/raycast.md` | Set up, back up, and restore Raycast | Guide/reference/index |
| `docs/setup/manual/apps/vorssaint.md` | Configure Vorssaint for software development on macOS | Guide/reference/index |
| `docs/setup/manual/azure-artifacts-npm.md` | Configure npm access to Azure Artifacts on macOS | Compatibility pointer |
| `docs/setup/manual/backup-and-restore.md` | Verify and back up the finished setup | Guide/reference/index |
| `docs/setup/manual/chezmoi.md` | Chezmoi learning path | Compatibility pointer |
| `docs/setup/manual/databases/README.md` | Database setup and operations | Guide/reference/index |
| `docs/setup/manual/databases/containers.md` | Run disposable local database containers | Guide/reference/index |
| `docs/setup/manual/databases/datagrip.md` | PostgreSQL setup with DataGrip and VS Code | Guide/reference/index |
| `docs/setup/manual/databases/dbeaver.md` | PostgreSQL setup with DBeaver Community and VS Code | Guide/reference/index |
| `docs/setup/manual/databases/operations.md` | PostgreSQL migrations, verification and recovery | Guide/reference/index |
| `docs/setup/manual/databases/postgresql.md` | PostgreSQL setup across local, development, test and production | Guide/reference/index |
| `docs/setup/manual/databases/vscode.md` | Connect VS Code to PostgreSQL | Guide/reference/index |
| `docs/setup/manual/developer-folders.md` | Developer folders and optional ghq | Compatibility pointer |
| `docs/setup/manual/development/ai-workspaces.md` | Choose an AI working directory | Guide/reference/index |
| `docs/setup/manual/development/folders.md` | Developer folders and optional ghq | Guide/reference/index |
| `docs/setup/manual/development/resources.md` | Developer Resources | Guide/reference/index |
| `docs/setup/manual/development/worktrees/README.md` | Git worktrees: choose your workflow | Guide/reference/index |
| `docs/setup/manual/development/worktrees/claude.md` | Git worktrees with Claude | Guide/reference/index |
| `docs/setup/manual/development/worktrees/codex.md` | Git worktrees with Codex | Guide/reference/index |
| `docs/setup/manual/development/worktrees/copilot.md` | Git worktrees with VS Code Agents and GitHub Copilot | Guide/reference/index |
| `docs/setup/manual/development/worktrees/environment.md` | Worktree environment files and running applications | Guide/reference/index |
| `docs/setup/manual/development/worktrees/terminal.md` | Git worktrees from Terminal | Guide/reference/index |
| `docs/setup/manual/development/worktrees/troubleshooting.md` | Git worktree troubleshooting | Guide/reference/index |
| `docs/setup/manual/development/worktrees/vscode.md` | Git worktrees in VS Code | Guide/reference/index |
| `docs/setup/manual/editors/vscode.md` | Configure VS Code for development | Guide/reference/index |
| `docs/setup/manual/git/azure-artifacts-npm.md` | Configure npm access to Azure Artifacts on macOS | Guide/reference/index |
| `docs/setup/manual/git/github-private-repository.md` | Clone a private GitHub setup repository | Guide/reference/index |
| `docs/setup/manual/git/multiple-identities.md` | Configure multiple Git identities and hosting defaults | Guide/reference/index |
| `docs/setup/manual/git/setup.md` | Configure Git and provider access | Guide/reference/index |
| `docs/setup/manual/homebrew.md` | Install Apple tools and Homebrew | Guide/reference/index |
| `docs/setup/manual/keychain-ssh.md` | Apple Keychain-backed SSH walkthrough | Compatibility pointer |
| `docs/setup/manual/languages.md` | Set up language toolchains | Guide/reference/index |
| `docs/setup/manual/local-https.md` | Enable local HTTPS for a development project | Guide/reference/index |
| `docs/setup/manual/macos.md` | Prepare macOS | Guide/reference/index |
| `docs/setup/manual/maintenance.md` | Maintain the environment | Guide/reference/index |
| `docs/setup/manual/preparation/encrypted-backup.md` | Prepare a verified encrypted backup destination | Guide/reference/index |
| `docs/setup/manual/preparation/restore-projects.md` | Restore selected projects and application data | Guide/reference/index |
| `docs/setup/manual/second-brain.md` | Build and use your Second Brain | Compatibility pointer |
| `docs/setup/manual/second-brain/README.md` | Set up a Second Brain | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/01-prerequisites.md` | 1 - Prerequisites and boundaries | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/02-workspace-and-domains.md` | 2 - Workspace and domains | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/03-databases-and-properties.md` | 3 - Databases and properties | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/04-templates.md` | 4 - Database templates | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/05-dashboard.md` | 5 - Second Brain HQ dashboard | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/06-raycast-integration.md` | 6 - Raycast integration 🤖 ⚙️ Optional | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/07-ai-integration.md` | 7 - AI integration 🤖 ⚙️ Optional | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/08-operating-workflow.md` | 8 - Operating workflow | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/09-backup-and-export.md` | 9 - Backup, export, and recovery expectations | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/README.md` | Notion Second Brain - Day One Mac | Guide/reference/index |
| `docs/setup/manual/second-brain/notion/checklist.md` | Notion Second Brain completion checklist | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/README.md` | Build an Obsidian knowledge vault manually | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/alternatives.md` | Alternative tool stacks | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/checklist.md` | Second Brain - Day One Mac checklist | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/claude.md` | Guide 2 - Obsidian + Claude Code | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/codex.md` | Guide 3 - Obsidian + Codex | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/dashboard.md` | Dashboard across all selected knowledge domains | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/layouts.md` | Separate physical Obsidian vaults - three-domain example | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/operations.md` | The operating system: capture, process, connect, create | Guide/reference/index |
| `docs/setup/manual/second-brain/obsidian/raycast.md` | Guide 1 - Obsidian + Raycast | Guide/reference/index |
| `docs/setup/manual/security.md` | Security setup: choose one key owner | Compatibility pointer |
| `docs/setup/manual/security/1password.md` | 1Password, SSH and hosting walkthrough | Guide/reference/index |
| `docs/setup/manual/security/README.md` | Security setup: choose one key owner | Guide/reference/index |
| `docs/setup/manual/security/external-agent.md` | Use an existing SSH agent | Guide/reference/index |
| `docs/setup/manual/security/https-git.md` | Configure HTTPS Git credentials | Guide/reference/index |
| `docs/setup/manual/security/keychain-ssh.md` | Apple Keychain-backed SSH walkthrough | Guide/reference/index |
| `docs/setup/manual/security/ssh-signing-and-recovery.md` | SSH registration, signing and recovery | Guide/reference/index |
| `docs/setup/manual/shell/README.md` | Configure the shell and choose a file owner | Guide/reference/index |
| `docs/setup/manual/shell/aliases.md` | Add, edit, save, and remove Zsh aliases | Guide/reference/index |
| `docs/setup/manual/shell/chezmoi.md` | Set up and maintain chezmoi | Guide/reference/index |
| `docs/setup/manual/shell/dotfile-hardening.md` | Extend a reviewed dotfile setup | Guide/reference/index |
| `docs/setup/manual/shell/package-workflows.md` | Maintain shell and package-manager workflows | Guide/reference/index |
| `docs/setup/manual/shell/zsh.md` | Zsh in VS Code and Warp | Guide/reference/index |
| `docs/setup/manual/ssh-signing-and-recovery.md` | SSH registration, signing and recovery | Compatibility pointer |
| `docs/setup/manual/terminals/warp.md` | Set up, back up, and restore Warp | Guide/reference/index |

## Assisted guides

| File | Purpose | Type |
|---|---|---|
| `docs/setup/assisted/01-first-boot-and-decisions.md` | Phase 1 — First boot and setup decisions | Guide/reference/index |
| `docs/setup/assisted/02-command-line-foundation.md` | Phase 2 — Command-line foundation | Guide/reference/index |
| `docs/setup/assisted/03-security-and-ssh.md` | Phase 3 — Security, 1Password, and SSH | Guide/reference/index |
| `docs/setup/assisted/04-core-tools-and-hosting.md` | Phase 4 — Core tools, folders, Git, and hosting | Guide/reference/index |
| `docs/setup/assisted/05-dotfiles-and-shell.md` | Phase 5 — Configuration ownership, shell, and prompt | Guide/reference/index |
| `docs/setup/assisted/06-language-toolchains.md` | Phase 6 — Language toolchains and pnpm | Guide/reference/index |
| `docs/setup/assisted/07-vscode-base.md` | Phase 7 — VS Code base | Guide/reference/index |
| `docs/setup/assisted/08-verify-and-reproduce.md` | Phase 8 — Verify, record, and reproduce | Guide/reference/index |
| `docs/setup/assisted/INSTALLATION-CENTRE.md` | Required Installation Centre | Guide/reference/index |
| `docs/setup/assisted/MACOS-SETTINGS.md` | Early macOS Settings Wizard | Guide/reference/index |
| `docs/setup/assisted/README.md` | Scripted (Assisted) Setup | Guide/reference/index |
| `docs/setup/assisted/advanced/15-full-dotfiles-and-bootstrap.md` | Advanced 15 - Full dotfiles and bootstrap | Guide/reference/index |
| `docs/setup/assisted/advanced/16-brewfile-apps-and-editor.md` | Advanced 16 - Brewfile, applications, and editor inventory | Guide/reference/index |
| `docs/setup/assisted/advanced/17-shell-and-package-automation.md` | Advanced 17 - Shell and package automation | Guide/reference/index |
| `docs/setup/assisted/advanced/18-hosting-identities-azure-and-worktrees.md` | Advanced 18 - Hosting identities, Azure DevOps, and worktrees | Guide/reference/index |
| `docs/setup/assisted/advanced/19-macos-gui-and-local-https.md` | Advanced 19 - macOS, GUI applications, and local HTTPS | Guide/reference/index |
| `docs/setup/assisted/advanced/20-restore-and-migrate.md` | Advanced 20 - Restore and migrate selected data | Guide/reference/index |
| `docs/setup/assisted/advanced/21-audit-maintenance-and-rebuild.md` | Advanced 21 - Audit, maintenance, and rebuild | Guide/reference/index |
| `docs/setup/assisted/advanced/22-ai-skills-and-mcp-operations.md` | Advanced 22 - Shared AI skills and MCP operations | Guide/reference/index |
| `docs/setup/assisted/advanced/README.md` | Advanced optional setup | Guide/reference/index |
| `docs/setup/assisted/existing-mac/00-existing-mac-decision.md` | Choose Route A or Route B | Guide/reference/index |
| `docs/setup/assisted/existing-mac/01-private-inventory.md` | Step 1 - Create and review the safety report | Guide/reference/index |
| `docs/setup/assisted/existing-mac/02-backup-readiness.md` | Steps 2-3 - Prepare, copy, and prove the backup can be restored | Guide/reference/index |
| `docs/setup/assisted/existing-mac/03-account-preserving-cleanup.md` | Route B only - Preview or apply account cleanup | Guide/reference/index |
| `docs/setup/assisted/existing-mac/04-handoff-to-day-one.md` | Continue to Day One Mac | Guide/reference/index |
| `docs/setup/assisted/existing-mac/README.md` | Stage 0 - Safely prepare an existing Mac | Guide/reference/index |
| `docs/setup/assisted/integrations/raycast.md` | Use Day One Mac from Raycast | Guide/reference/index |
| `docs/setup/assisted/integrations/shortcuts.md` | Import the bundled Open in VS Code shortcut | Guide/reference/index |
| `docs/setup/assisted/optional/09-databases.md` | Optional 9 - Local databases with containers | Guide/reference/index |
| `docs/setup/assisted/optional/10-ai-agents.md` | Optional 10: install AI client payloads | Guide/reference/index |
| `docs/setup/assisted/optional/10a-omniroute.md` | Optional 10A: create an owned OmniRoute container | Guide/reference/index |
| `docs/setup/assisted/optional/11-mcp-servers.md` | Optional 11: generate MCP connection snippets | Guide/reference/index |
| `docs/setup/assisted/optional/12-vscode-profiles.md` | Module 12 retired - VS Code profiles moved | Guide/reference/index |
| `docs/setup/assisted/optional/13-enhanced-cli-tools.md` | Optional 13 - Enhanced command-line toolkit 🤖 ⚙️ | Guide/reference/index |
| `docs/setup/assisted/optional/14-warp-drive.md` | Optional 14 - Import the Day One Mac Warp Drive bundle | Guide/reference/index |
| `docs/setup/assisted/optional/README.md` | Optional Day One Mac modules | Guide/reference/index |
| `docs/setup/assisted/optional/ai-workspaces.md` | AI workspaces, projectless tasks, and repository work | Guide/reference/index |
| `docs/setup/assisted/optional/second-brain.md` | Dynamic vault and domain manager | Guide/reference/index |
| `docs/setup/assisted/optional/vscode-profiles.md` | Generate, replace and restore VS Code profiles | Guide/reference/index |
| `docs/setup/assisted/recovery/README.md` | Finalise, roll back, remove, or clean Day One Mac | Guide/reference/index |
| `docs/setup/assisted/recovery/finalize.md` | Finalise or detach Day One Mac | Guide/reference/index |
| `docs/setup/assisted/recovery/remove-day-one-mac.md` | Remove Day One Mac safely | Guide/reference/index |
| `docs/setup/assisted/recovery/rollback.md` | Clean the development state without erasing the Mac | Guide/reference/index |
| `docs/setup/assisted/reference/README.md` | Assisted command and state reference | Guide/reference/index |
| `docs/setup/assisted/reference/command-reference.md` | Day One Mac command reference | Guide/reference/index |
| `docs/setup/assisted/reference/module-execution.md` | Module execution reference | Guide/reference/index |
| `docs/setup/assisted/reference/optional-status.md` | Optional and advanced status dashboard | Guide/reference/index |
| `docs/setup/assisted/reference/workstation-readiness.md` | Personal and managed workstation readiness | Guide/reference/index |
| `docs/setup/assisted/runtime.md` | Install and manage the standalone runtime | Guide/reference/index |
