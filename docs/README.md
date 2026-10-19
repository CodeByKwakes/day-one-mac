[← Project root](../README.md)

# Day One Mac documentation

Use this page as the single documentation index. You do not need to read every
folder before starting.

## Choose where to begin

| Your situation | Open this |
|---|---|
| New or factory-reset Mac; use the guided scripts | [Start Here](START-HERE.md) |
| New or factory-reset Mac; do not use Day One Mac scripts | [Complete manual route](setup/manual/MANUAL-SETUP-GUIDE.md#manual-setup-flow) |
| Existing Mac that still contains data or settings | [Stage 0 preflight](setup/existing-mac/README.md) |
| Want a one-page map of the complete process | [Process overview](explanation/PROCESS-OVERVIEW.md) |
| Configuring a new developer Mac and want an audit-backed blueprint | [New-device development environment blueprint](reference/NEW-DEVICE-SETUP-BLUEPRINT.md) |
| Following the required setup | [Required phases 1–8](setup/assisted/README.md) |
| Required Phase 8 has passed and you want extras | [Optional modules](how-to/modules/optional/README.md) |
| Need one status or audit view for Modules 09–22 | [Optional and advanced status dashboard](reference/OPTIONAL-STATUS.md) |
| Need power-user automation or migration | [Advanced modules](how-to/modules/advanced/README.md) |
| Need help configuring an installed application | [Application guides](how-to/apps/README.md) |
| Need PostgreSQL in local, dev, test or production, with a desktop client and VS Code | [Database setup hub](how-to/databases/README.md) · [DBeaver Community setup](how-to/databases/DBEAVER.md) |
| Want a personal VS Code setup for Angular, NestJS, Nx, and AI agents | [Profile setup and settings](how-to/apps/VSCODE-PROFILES.md) · [Advanced reference](how-to/development/VSCODE-TYPESCRIPT.md) |
| Want MCP tools running through Docker for VS Code, Claude Code or Codex | [Docker MCP setup](how-to/development/MCP-DOCKER.md) · [All MCP routes](how-to/modules/optional/11-mcp-servers.md) |
| Want developer window layouts, port monitoring, and desktop utilities | [Vorssaint developer guide](how-to/apps/VORSSAINT.md) |
| Want human decisions and manual tasks grouped together | [Manual Setup Handbook](setup/manual/README.md) |
| Want first setup, daily use, templates or recovery for dotfiles | [Chezmoi learning path](setup/manual/chezmoi.md) |
| Want an Obsidian or Notion knowledge system with backup and recovery | [Second Brain walkthrough](setup/manual/second-brain.md) |
| Need 1Password, Keychain, SSH, signing or account recovery | [Security learning path](setup/manual/security.md) |
| A project needs private npm packages from Azure Artifacts | [Manual npm authentication](setup/manual/azure-artifacts-npm.md) |
| Want to know what each app/formula does and whether it is required | [Software catalogue](reference/SOFTWARE-CATALOGUE.md) |
| Want browser reading, an offline export or a printable guide | [Documentation commands](reference/DOCUMENTATION-COMMANDS.md) |
| Need to undo, finalise, or remove setup changes | [Operations](how-to/recovery/README.md) |
| Need a command, definition, or configuration example | [Reference library](reference/README.md) |
| Need to set up or learn when to use chezmoi | [Complete chezmoi setup tutorial](setup/manual/CHEZMOI-SETUP-TUTORIAL.md) |
| Updating a Mac created before the standalone runtime | [Upgrade notes](reference/UPGRADE-NOTES.md) |
| Contributing code or documentation | [Git workflow](https://github.com/CodeByKwakes/day-one-mac/blob/main/maintainers/contributing/GIT-WORKFLOW.md) |
| Installing contributor linting and Git hooks | [Contributor tooling](https://github.com/CodeByKwakes/day-one-mac/blob/main/maintainers/contributing/CONTRIBUTOR-TOOLING.md) |
| Configuring a release automation credential | [Release-token setup](https://github.com/CodeByKwakes/day-one-mac/blob/main/maintainers/releasing/RELEASE-TOKEN-SETUP.md) |
| Protecting `main` with the recommended GitHub ruleset | [`main` protection checklist](https://github.com/CodeByKwakes/day-one-mac/blob/main/maintainers/releasing/MAIN-PROTECTION-CHECKLIST.md) |
| Maintaining the project documentation | [Maintenance](https://github.com/CodeByKwakes/day-one-mac/blob/main/maintainers/audits/README.md) |

For the long-form project explanation, assumptions, tracks, stacks, and
implementation details, read the [complete project guide](explanation/PROJECT-GUIDE.md).

## Documentation conventions

The documentation uses these terms consistently:

- **Manual route** means completing the setup without installing or invoking
  the `day-one-mac` runtime. Commands from macOS, Homebrew, and the selected
  tools are still used.
- **Script-assisted route** means using the installed `day-one-mac` command.
- **Shared manual action** means a decision or graphical action that remains
  manual on both routes, such as approving FileVault or signing in to an app.
- **Phase** means required work numbered 1–8. A **checkpoint** is an inserted
  decision or installation gate. A **module** is optional or advanced work.

When a phase guide discusses what the runner does, manual-route readers should
use the corresponding numbered section in the
[complete manual and script-assisted setup guide](setup/manual/MANUAL-SETUP-GUIDE.md).
Do not alternate between routes unless a troubleshooting instruction explicitly
requires it.

## The normal reading flow

```text
START-HERE
    ↓
Required Phases 1–8
    ↓
Verification and reproducibility report
    ↓
Finish, or choose Optional Modules 9–14
    ↓
Use Advanced Modules 15–22 only when needed
```

Stage 0 sits before this flow and is used only when the Mac is not genuinely
new or clean.

## Folder map

```text
docs/
├── README.md           This index
├── START-HERE.md       Beginner-safe entry point
├── setup/
│   ├── existing-mac/   Safety preparation before setup
│   ├── assisted/       Required phases and checkpoints
│   └── manual/         Complete manual route and learning guides
├── how-to/
│   ├── apps/           Application-specific instructions
│   ├── databases/      PostgreSQL, DataGrip, DBeaver and VS Code
│   ├── development/    Editors, AI workflows, terminals and worktrees
│   ├── modules/        Optional and advanced module procedures
│   └── recovery/       Finalisation, rollback, reset and removal
├── reference/          Commands, catalogues, layouts and generated data
└── explanation/        Architecture, concepts and process overview
```

Earlier numbered folders contain compatibility pages for existing bookmarks.
Maintain the canonical pages above; the offline reader follows the aliases.
Contributor plans, historical audits and release evidence live separately in
[`maintainers/`](https://github.com/CodeByKwakes/day-one-mac/tree/main/maintainers).

## When the wizard stops

1. Read the `Guide:` path printed in Terminal.
2. Open that one document rather than searching the entire project.
3. Complete the displayed **Next action**.
4. Rerun `day-one-mac --wizard`; completed phases remain saved.

Do not manually mark a phase complete. A phase receives a check mark only after
its verification gates pass.

---

[Start Here →](START-HERE.md) · [Required phases](setup/assisted/README.md) · [Command reference](reference/COMMAND-REFERENCE.md)
