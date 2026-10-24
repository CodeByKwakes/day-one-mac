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
| Initial setup or adding a developer tool | [Setup](../day-one-setup/SKILL.md) |
| Inspect versions, prerequisites or configuration drift | [Check](../day-one-check/SKILL.md) |
| Update tools or maintain existing configuration | [Maintain](../day-one-maintain/SKILL.md) |
| Back up, restore or remove a selected component | [Recover](../day-one-recover/SKILL.md) |
| Configure or troubleshoot an optional gateway | [OmniRoute](../day-one-omniroute/SKILL.md) |
| Change the Day One Mac repository | [Contribute](../day-one-contribute/SKILL.md) |

For a combined request, inspect first, propose the requested changes, and then
use the relevant workflows in dependency order. A check is read-only unless the
user separately approves a probe with side effects or a repair. Reuse existing
decisions and approvals; clarify only material missing choices or changed scope.

The workflows are instructions for this session. Do not install other skills,
start subagents or change client permissions merely to route a request. Native
client approval controls still apply. Optional role templates are separate
from the skills and require explicit project configuration.

Use the manual recipes bundled with the selected workflow. Load only the
relevant guide. Reviewed bundled helpers are optional; inspect their previews
and use only within the approved scope. Client installation,
provider sign-in and tool downloads still require their normal prerequisites.

Store approved session notes in a user-selected private workspace, outside this
skill's installation. Preserve installation owners and backups, and report
verified results separately from suggested changes or unresolved account steps.
