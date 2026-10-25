---
name: day-one-mac
description: Set up, check, maintain or recover an Apple-silicon Mac development environment, including optional OmniRoute and developer shortcuts. Use as the single Day One Mac entry point; specialist workflows are bundled without separate skill installations.
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
| Create, inspect or maintain developer shortcuts and apps | [Shortcuts](references/workflows/day-one-shortcuts.md) |
| Read, find or open documentation | [Reading options](references/project/docs/shared/reading-and-export.md) |

For a combined request, inspect first, propose the requested changes, and then
use the relevant workflows in dependency order. A check is read-only unless the
user separately approves a probe with side effects or a repair. Reuse existing
decisions and approvals; clarify only material missing choices or changed scope.

The workflows are instructions for this session. Do not install other skills,
start subagents or change client permissions merely to route a request. Native
client approval controls still apply. Optional role templates are separate
from the skills and require explicit project configuration.

For reading requests, use the relevant bundled guide or the published handbook.
The website and offline download are reading surfaces, not setup executors.
Do not require a source checkout or run a contributor build merely to read a
guide. Installed guides stay at the skill's installed revision until updated.

Use the manual recipes bundled with the selected workflow. Load only the
relevant guide. Reviewed bundled helpers are optional; inspect their previews
and use only within the approved scope. Client installation,
provider sign-in and tool downloads still require their normal prerequisites.

Store approved session notes in a user-selected private workspace, outside this
skill's installation. Preserve installation owners and backups, and report
verified results separately from suggested changes or unresolved account steps.

## Installed package

Resolve bundled links relative to this skill directory, not the working directory.
The project reference snapshot is under `references/project/`; use its matching
paths when a guide refers to supplied configuration or template files. Read only
the guide needed for the current task. Keep this installed package unchanged.

Save private notes outside this installed package. No Day One Mac runtime is required.
Reviewed helpers are bundled under `references/project/helpers/`; inspect their
help and preview output before approving changes. Manual recipes need no helpers.
