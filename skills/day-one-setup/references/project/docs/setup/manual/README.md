# Manual Setup

Build the selected development environment using macOS and individual tools.
This route does not install or invoke Day One Mac scripts. Keep your own record
of completed checks, changed files and recoverable backups.

## Before you start

Complete the [prerequisites](../../shared/prerequisites.md) and
[decision worksheet](../../shared/decisions.md). On a managed Mac, use IT's
approved software and elevation process. For an existing populated account,
follow the existing-Mac limit in the prerequisites before changing configuration.

## Using AI instead

For AI guidance or approved client execution, choose the [AI-assisted route](../ai/README.md).
This manual sequence is complete without an AI account or Day One Mac tools.

## Follow the base setup

Each row is a complete task. Finish its verification before continuing.

| Order | Task | Expected outcome |
|---|---|---|
| 1 | [macOS and security baseline](macos.md) | Native, approved OS with encryption and recoverable access |
| 2 | [Apple tools and Homebrew](homebrew.md) | Native package manager and selected foundational tools |
| 3 | [Git authentication](security/README.md) | One working, recoverable authentication method |
| 4 | [Git and provider access](git/setup.md) | Correct author identity and an authorised repository read |
| 5 | [Shell and configuration](shell/README.md) | Selected ownership, Zsh and optional prompt verified |
| 6 | [Language toolchains](languages.md) | Selected Node/Python stack works in a new shell |
| 7 | [Applications](apps/README.md) | Selected editor/terminal/launcher opens and works; core may skip |
| 8 | [Backup and final verification](backup-and-restore.md) | Restorable configuration and a real project test |

## Add a capability when needed

- [VS Code](editors/vscode.md): profiles, extensions, settings and keyboard shortcuts.
- [PostgreSQL and database clients](databases/README.md): local and remote environments.
- [AI clients](ai/clients.md), [agents and skills](ai/instructions-agents-skills.md), and [MCP](ai/mcp.md).
- [Git worktrees](development/worktrees/README.md): terminal, VS Code and AI workflows.
- [Developer folders](development/folders.md) and [portable resources](development/resources.md).
- [Second Brain](second-brain/README.md): Obsidian or Notion.
- [Local HTTPS](local-https.md) and [routine maintenance](maintenance.md).

Each addition has its own prerequisites and verification. Use [component lifecycle](lifecycle.md)
for scoped installation, updates, removal and recovery.

## Recover or get help

Start with the [symptom index](../../shared/troubleshooting.md), then use the
owning guide's recovery procedure. Restore only the files you changed. The
manual route has no automated ownership manifest or broad rollback command.

## Previously published section links

Existing bookmarks remain available below. Use the route and task links above
for the normal setup sequence.

### Manual Setup Handbook

Continue with [the base setup sequence](#follow-the-base-setup).

### What the CLI does and what you do

Continue with [How setup fits together](../../shared/explanation/process-overview.md).

### 1. macOS preferences and permissions

Continue with [Prepare macOS](macos.md).

### 2. AI accounts, providers and MCP trust

Continue with [Install and configure selected AI clients](ai/clients.md).

### 3. Editor profiles, extensions, Warp and app settings

Continue with [Configure VS Code for development](editors/vscode.md).

### 4. Chezmoi, ownership and shell activation

Continue with [Configure the shell and choose a file owner](shell/README.md).

### 5. Git identities, signing, Azure and worktrees

Continue with [Configure Git and provider access](git/setup.md).

### 6. Database and gateway decisions

Continue with [Database setup and operations](databases/README.md).

### 7. Restore, maintenance and baseline acceptance

Continue with [Verify and back up the finished setup](backup-and-restore.md).

### Reading and keeping these guides

Continue with [Read and export documentation offline](../../shared/reading-and-export.md).

<a id="choose-your-route"></a>
