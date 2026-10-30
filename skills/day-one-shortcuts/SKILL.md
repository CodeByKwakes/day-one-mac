---
name: day-one-shortcuts
description: Create, inspect, build and maintain selected macOS developer shortcuts, the Send to Archive Finder Quick Action and standalone AppleScript apps for Git Clone, VS Code, Warp, existing VS Code profiles and a shared development workspace. Use for Finder, Dock and Shortcuts workflows on Apple-silicon Macs.
---

# Day One shortcuts

Use the [manual shortcut guide](references/project/docs/setup/manual/apps/macos-shortcuts.md)
for recipes and functional checks. Use the [app builder reference](references/project/docs/shared/tools/shortcut-apps.md)
for the optional bundled helper. The [catalogue](references/project/integrations/shortcuts/catalog.json)
owns recipe IDs, source order, dependencies and bundle identifiers.

## Select the requested operation

- Inspect: read supplied assets as evidence. Distinguish a `.shortcut` export,
  readable source, a ShortcutDroplet referencing a local workflow, and a
  standalone app containing its code. Do not run an unknown app to inspect it.
- Create or build: choose only the requested recipes and a new private review
  directory outside the installed skill. Check dependencies, preview the build
  and run it within the user's approved scope. Compilation does not install apps.
- Verify: inspect bundles and sources, then apply the guide's selected functional
  checks. A live clone, application launch or permission change needs that scope;
  a read-only audit does not authorize these probes.
- Update: compare the installed app or workflow with the reviewed source. Build
  into a new directory, preserve the working copy, and replace only the selected
  item after approval. Do not edit signed exports or Shortcuts' database.
- Remove: preview the exact app, workflow and launcher entries. Confirm which
  item the user owns and use the manual recovery instructions. Keep project
  directories, unrelated shortcuts and backups.
- Extend: in an explicitly selected source checkout, update its catalogue,
  sources, manual guide, inventories and tests together. Never alter an installed
  skill package to add a feature.

## Preserve the workflow boundaries

Generated apps embed their code and need no skill installation to run. Native
Shortcuts launchers still require their installed workflow. Do not distribute
personal shortcut identifiers, saved folders, credentials or unsigned files
presented as signed shortcut exports. No background manager is required.

Folder apps support one ordinary folder. Keep cancellation free of side effects.

Send to Archive is a separate multi-folder Automator recipe in the catalogue's
`quickActions` collection; the app builder does not install or build it.
Preview the category/date destination and preserve each folder's contents.
Use disposable folders for verification. Treat linked worktrees and repositories
with worktree metadata through Git's own move procedure, and inspect nested
repositories separately. Keep recovery records private and report partial moves
instead of retrying or rolling them back automatically. Fixture checks and Finder
menu registration do not establish the complete interactive workflow.

Use the registered named-profile guard; never guess profile names or rewrite
VS Code storage. A missing profile passed to VS Code can create an empty one.
Do not synthesize a default entry: the built-in default name is localized.
Direct that selection to VS Code's Profiles menu. Reject malformed name/location
records rather than treating their names as registered profiles.
If metadata cannot be read, use VS Code's Profiles menu and report the limitation.

Warp opens an encoded folder URI. Verify its working directory with `pwd`;
opening a window alone does not prove success. Workspace opening can partially
succeed. Keep any successful window and report which remaining action failed.
Git Clone preserves partial folders and refuses custom SSH command overrides.
Use the manual guide's Terminal fallback without changing existing Git settings.

Report the selected recipes, sources, output paths, checks performed and remaining
manual steps. Installing or updating this skill does not install, replace or
remove previously built apps. Preserve notes and recovery copies outside skills.

## Restore a selected developer workspace

Use the [workspace guide](references/project/docs/setup/manual/apps/workspaces.md) for desk
calibration and app placement, and the optional
[restore tool](references/project/docs/shared/tools/workspaces.md) for bounded automation.
Inspect the actual desk, DisplayLink readiness and built-in display before
capture. Keep calibration private; use exact display identities, not count or
localized names. Preview and approve the selected operation before mutation.
Stop on changed/duplicate IDs or multiple matching activities. Preserve recovery
snapshots and report display verification separately from a Raycast request.
Several VS Code windows need an explicit project selection; never infer success
from opening a deep link. Do not install a watcher or connect/query databases.
Atticus is an optional pilot, not a prerequisite or verified Codex/Copilot backend.

## Installed package

Resolve bundled links relative to this skill directory, not the working directory.
The project reference snapshot is under `references/project/`; use its matching
paths when a guide refers to supplied configuration or template files. Read only
the guide needed for the current task. Keep this installed package unchanged.

Save private notes outside this installed package. No Day One Mac runtime is required.
Reviewed helpers are bundled under `references/project/helpers/`; inspect their
help and preview output before approving changes. Manual recipes need no helpers.
