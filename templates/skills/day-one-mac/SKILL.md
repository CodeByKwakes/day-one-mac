---
name: day-one-mac
description: Set up, check, maintain or recover an Apple-silicon Mac development environment, including VS Code profiles, macOS apps, Second Brain workflows, optional OmniRoute and developer shortcuts. Use as the single Day One Mac entry point; specialist workflows are bundled without separate skill installations.
---

# Day One Mac

Select the workflow that matches the user's request and read its bundled
instructions. Each workflow is available here without an installed specialist
skill, the Day One Mac runtime or a permanent source checkout.

| Request | Workflow to read |
|---|---|
| Configure or troubleshoot VS Code profiles, settings, extensions or shortcuts | [VS Code](../day-one-vscode/SKILL.md) |
| Review or maintain selected macOS apps and system preferences | [macOS apps](../day-one-macos-apps/SKILL.md) |
| Initial setup or adding a developer tool | [Setup](../day-one-setup/SKILL.md) |
| Inspect versions, prerequisites or configuration drift | [Check](../day-one-check/SKILL.md) |
| Update tools or maintain existing configuration | [Maintain](../day-one-maintain/SKILL.md) |
| Back up, restore or remove a selected component | [Recover](../day-one-recover/SKILL.md) |
| Configure or troubleshoot an optional gateway | [OmniRoute](../day-one-omniroute/SKILL.md) |
| Change the Day One Mac repository | [Contribute](../day-one-contribute/SKILL.md) |
| Create, inspect or maintain developer shortcuts and apps | [Shortcuts](../day-one-shortcuts/SKILL.md) |
| Set up a knowledge system or connect selected code repositories to project notes | [Second Brain](../day-one-second-brain/SKILL.md) |
| Read, find or open documentation | [Reading options](../../../docs/shared/reading-and-export.md) |

Choose a specific workflow before a general setup or maintenance workflow when
the request identifies that capability. For a combined request, inspect first,
propose the requested changes, and then
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
