[← Project root](../README.md)

# Day One Mac documentation

Use this page as the single documentation index. You do not need to read every
folder before starting.

## Choose where to begin

| Your situation | Open this |
|---|---|
| New or factory-reset Mac; use the guided scripts | [Start Here](START-HERE.md) |
| New or factory-reset Mac; do not use Day One Mac scripts | [Complete manual route](20-reference/NOTION-SETUP-GUIDE.md#manual-setup-flow) |
| Existing Mac that still contains data or settings | [Stage 0 preflight](00-preflight/README.md) |
| Want a one-page map of the complete process | [Process overview](PROCESS-OVERVIEW.md) |
| Configuring a new developer Mac and want an audit-backed blueprint | [New-device development environment blueprint](NEW-DEVICE-SETUP-BLUEPRINT.md) |
| Following the required setup | [Required phases 1–8](01-required/README.md) |
| Required Phase 8 has passed and you want extras | [Optional modules](02-optional/README.md) |
| Need one status or audit view for Modules 09–22 | [Optional and advanced status dashboard](20-reference/OPTIONAL-STATUS.md) |
| Need power-user automation or migration | [Advanced modules](03-advanced/README.md) |
| Need help configuring an installed application | [Application guides](10-app-guides/README.md) |
| Need to undo, finalise, or remove setup changes | [Operations](04-operations/README.md) |
| Need a command, definition, or configuration example | [Reference library](20-reference/README.md) |
| Updating a Mac created before the standalone runtime | [Upgrade notes](20-reference/UPGRADE-NOTES.md) |
| Maintaining the project documentation | [Maintenance](99-maintenance/README.md) |

For the long-form project explanation, assumptions, tracks, stacks, and
implementation details, read the [complete project guide](PROJECT-GUIDE.md).

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
[complete manual and script-assisted setup guide](20-reference/NOTION-SETUP-GUIDE.md).
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
├── README.md              This index
├── START-HERE.md          Short, beginner-safe route
├── PROCESS-OVERVIEW.md    Full process and decision map
├── NEW-DEVICE-SETUP-BLUEPRINT.md
│                           Audit-backed fresh-device plan
├── PROJECT-GUIDE.md       Detailed project explanation
├── 00-preflight/          Existing-Mac safety before the setup flow
├── 01-required/           Phases 1–8 and required checkpoints
├── 02-optional/           Modules 9–14, only after Phase 8
├── 03-advanced/           Modules 15–22 for power users
├── 04-operations/         Finalisation, rollback, reset, and removal
├── 10-app-guides/         1Password, Raycast, VS Code, Warp, shortcuts
├── 20-reference/          Commands, layouts, dotfiles, glossary, examples
└── 99-maintenance/        Documentation audits and maintainer notes
```

## When the wizard stops

1. Read the `Guide:` path printed in Terminal.
2. Open that one document rather than searching the entire project.
3. Complete the displayed **Next action**.
4. Rerun `day-one-mac --wizard`; completed phases remain saved.

Do not manually mark a phase complete. A phase receives a check mark only after
its verification gates pass.

---

[Start Here →](START-HERE.md) · [Required phases](01-required/README.md) · [Command reference](20-reference/COMMAND-REFERENCE.md)
