---
name: day-one-macos-apps
description: Review and maintain selected macOS developer applications and preferences, including installation ownership, updates, permissions, login items, shortcuts and recovery. Use for scoped app or System Settings work on Apple-silicon Macs, not blanket machine cleanup.
---

# Day One macOS apps

Choose the owning recipe from the [application index](../../../docs/setup/manual/apps/README.md).
Use [macOS settings](../../../docs/setup/manual/macos.md) for system preferences,
permissions and login items, and [component lifecycle](../../../docs/setup/manual/lifecycle.md)
for installation, updates and removal. These guides are bundled; no other skill
installation or permanent source checkout is required.

## Inspect the selected application

Confirm the exact app and requested operation. Resolve ambiguous names before
launching, installing or removing anything. Record the macOS version and app
version, installation location and owner: Homebrew, App Store, vendor updater,
manual installation or device management. An app bundle alone does not identify
who owns updates or prove that an account, licence or integration works.

Inspect only the selected app's configuration and relevant prerequisites. Do not
collect unrelated account data or source the user's shell configuration. Verify
changing settings, command flags and menu paths against the installed version
and vendor documentation. Report uncertain mappings instead of inventing
`defaults write` keys or assuming an old plist controls the current version.

## Select the operation

| Operation | Decision before execution | Evidence afterward |
|---|---|---|
| Review | Requested app, feature and relevant preferences | Observed values, conflicts and scoped suggestions |
| Install | Exact product, source, owner and prerequisite permissions | Expected app version and one selected workflow |
| Configure | Current/proposed values and affected files or UI controls | Persistent values and working feature |
| Update | Existing owner, release compatibility and recovery limits | Expected version and working integrations |
| Remove | Exact owned item and whether settings/data must remain | Selected item absent; retained data still present |
| Restore | Chosen backup and newer changes to preserve | Selected settings or data restored and checked |

Use the existing update channel. Do not install a second Homebrew copy over a
working App Store, vendor or managed installation. Preview bounded changes and
reuse the user's approval when it covers that scope. Keep exported preferences
and recovery evidence private, outside installed skills.

Prefer application preferences, supported export/import and documented CLI
interfaces. For a verified `defaults` setting, record its domain, key, type and
whether it originally existed. Recovery must restore the old typed value or
remove only a key introduced by this change. Do not copy whole preference domains
between unrelated machines or overwrite a live app's unsaved configuration.

## Preserve application boundaries

Grant macOS permissions only for the selected feature through the supported UI.
Never bypass management, disable system protections or rewrite privacy databases.
Account sign-in and licence acceptance stay with the user. Preserve required
password-manager, security and employer-managed background services.

Check shortcut collisions in the app and macOS before assigning a key. For Warp,
verify the selected shell and working directory; for an editor handoff, verify the
actual project and profile. Docker settings and uninstall operations must preserve
volumes and images unless the user explicitly selects their removal.

Use the [VS Code guide](../../../docs/setup/manual/editors/vscode.md) for profile
resources and the [shortcut guide](../../../docs/setup/manual/apps/macos-shortcuts.md)
for standalone launcher apps. Keep each topic's values in its owning guide.
Do not treat a shortcut app, its target application and its project folder as
one uninstall target.

Uninstallation preserves user data by default. Avoid cask zap, broad Library
deletion, volume pruning and force removal for a normal app uninstall. Backups
do not guarantee an older application binary remains available; state recovery
limits before an update that may migrate data.

Verify the actual requested workflow after mutation and report anything requiring
a restart or human interaction. Read-only audits must not launch apps, trigger
updates or change permissions as a probe without that scope. Return the selected
app, before/after evidence, retained data and recovery location.

## Restore a selected developer workspace

Use the [workspace guide](../../../docs/setup/manual/apps/workspaces.md) for desk
calibration and app placement, and the optional
[restore tool](../../../docs/shared/tools/workspaces.md) for bounded automation.
Inspect the actual desk, DisplayLink readiness and built-in display before
capture. Keep calibration private; use exact display identities, not count or
localized names. Preview and approve the selected operation before mutation.
Stop on changed/duplicate IDs or multiple matching activities. Preserve recovery
snapshots and report display verification separately from a Raycast request.
Several VS Code windows need an explicit project selection; never infer success
from opening a deep link. Do not install a watcher or connect/query databases.
Atticus is an optional pilot, not a prerequisite or verified Codex/Copilot backend.
