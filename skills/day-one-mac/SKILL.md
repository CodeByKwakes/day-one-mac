---
name: day-one-mac
description: Set up, check, maintain or recover an Apple-silicon Mac development environment, including optional OmniRoute. Use as the single Day One Mac entry point; it includes all six workflows without installing specialist skills.
---

# Day One Mac

Select the workflow that matches the user's request and read its bundled
instructions. Each workflow is available here without an installed specialist
skill, the Day One Mac runtime or a permanent source checkout.

| Request | Workflow to read |
|---|---|
| Initial setup or adding a developer tool | [Setup](references/workflows/day-one-setup.md) |
| Inspect versions, prerequisites or configuration drift | [Check](references/workflows/day-one-check.md) |
| Update tools or maintain existing configuration | [Maintain](references/workflows/day-one-maintain.md) |
| Back up, restore or remove a selected component | [Recover](references/workflows/day-one-recover.md) |
| Configure or troubleshoot an optional gateway | [OmniRoute](references/workflows/day-one-omniroute.md) |
| Change the Day One Mac repository | [Contribute](references/workflows/day-one-contribute.md) |

For a combined request, inspect first, propose the requested changes, and then
use the relevant workflows in dependency order. A check is read-only unless the
user separately approves a probe with side effects or a repair. Reuse existing
decisions and approvals; clarify only material missing choices or changed scope.

The workflows are instructions for this session. Do not install other skills,
start subagents or change client permissions merely to route a request. Native
client approval controls still apply. Optional role templates are separate
from the skills and require explicit project configuration.

Use the manual recipes bundled with the selected workflow. Load only the
relevant guide. Optional utility commands require a separately installed
runtime; choose the manual procedure when it is absent. Client installation,
provider sign-in and tool downloads still require their normal prerequisites.

Store approved session notes in a user-selected private workspace, outside this
skill's installation. Preserve installation owners and backups, and report
verified results separately from suggested changes or unresolved account steps.

## Installed package

Resolve bundled links relative to this skill directory, not the working directory.
The project reference snapshot is under `references/project/`; use its matching
paths when a guide refers to supplied configuration or template files. Read only
the guide needed for the current task. Keep this installed package unchanged.

The skill is already available after installation. Workspace export is an
optional alternative; do not require it to begin. Save approved private notes
in a user-selected workspace. The optional `day-one-mac` utility command needs
a separate installation; use the manual recipes when that command is absent.
