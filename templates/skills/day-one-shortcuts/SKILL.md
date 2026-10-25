---
name: day-one-shortcuts
description: Create, inspect, build and maintain selected macOS developer shortcuts and standalone AppleScript apps for Git Clone, VS Code, Warp, existing VS Code profiles and a shared development workspace. Use for Finder, Dock and Shortcuts workflows on Apple-silicon Macs.
---

# Day One shortcuts

Use the [manual shortcut guide](../../../docs/setup/manual/apps/macos-shortcuts.md)
for recipes and functional checks. Use the [app builder reference](../../../docs/shared/tools/shortcut-apps.md)
for the optional bundled helper. The [catalogue](../../../integrations/shortcuts/catalog.json)
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
