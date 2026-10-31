# Install, update, remove and recover components

Manage each component through its existing installation owner. Keep the Day One
Mac bundle, assistant workspace, developer applications and project dependencies
separate when planning a change.

## Prerequisites and assumptions

Identify the selected component, current version, owner and affected data.
Read its owning guide and verify a backup before replacing configuration or data.
Commands below inspect Homebrew ownership; substitute the exact reviewed token
only after reading the output.

## Install or add a tool

1. Find the capability in the [manual index](README.md) and inspect existing software.

   ```bash
   command -v node
   brew list --formula
   brew list --cask
   ```

   Expected result: known executable locations and package ownership. Run Homebrew
   commands only after its own guide is complete. Absence is not an error to hide.

2. Follow the selected capability's prerequisites and installation procedure.

   Expected result: one installation owner and no duplicate native/Homebrew copy.

3. Complete its configuration and functional verification.

   Expected result: a working application or project, with remaining account/UI
   actions stated explicitly. Record the result privately.

## Update a component

1. Inspect available package updates:

   ```bash
   brew outdated --formula
   brew outdated --cask
   ```

   Expected result: candidates for review, not permission to upgrade everything.

2. Review the chosen release, project constraints and recovery requirements.
   Use the original owner: Homebrew for its packages, the app's updater for a
   vendor-owned app, or the project's lockfile workflow for dependencies.

   Expected result: one selected update with a restorable configuration/data backup.

3. Apply that update and rerun the owning guide's verification.

   Expected result: the expected version and a working project. A successful
   package command alone is insufficient. Keep the prior backup until accepted.

For Homebrew, `brew upgrade FORMULA` and `brew upgrade --cask CASK` target one
reviewed token. `FORMULA` and `CASK` are placeholders, not literal package names.
An older package version may not remain available; do not promise automatic downgrade.

## Remove a component

1. List dependants before selecting removal, for example:

   ```bash
   brew uses --installed node
   ```

   Expected result: packages that depend on the selected formula, or an empty list.

2. Identify retained data, settings and backups, then approve the exact removal.

   Expected result: an explicit choice about application data. Do not use broad
   cleanup, cask zap, force removal or volume pruning as a default.

3. Use the original owner's uninstall procedure and verify the expected absence.

   Expected result: only the selected component is removed. For Homebrew-owned
   items, use `brew uninstall FORMULA` or `brew uninstall --cask CASK` with the
   reviewed token. Recheck affected applications after removal.

## Recover or maintain Day One Mac assets

Stage data restores using [backup and restore](backup-and-restore.md). Test a
sample before replacing active data. Database migrations may need a logical
backup and application-specific recovery rather than a package downgrade.

For an old manager installation, use [legacy removal](../../shared/migration/remove-legacy-manager.md).
Removing the legacy manager preserves developer apps and setup records.
Update an installed skill through its [scoped lifecycle procedure](ai/day-one-skills.md#update-and-remove),
or use the [native plugin update procedure](ai/day-one-plugins.md#update-an-existing-installation)
for that delivery method. Keep private session notes outside the installed
package and resume through [assistant operation](../ai/operation.md).
To add support to this project, follow [adding capabilities](../../shared/reference/adding-capabilities.md).
