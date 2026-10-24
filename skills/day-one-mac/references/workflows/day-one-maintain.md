# Day One maintain

Read [maintenance](../project/docs/setup/manual/maintenance.md) and
[lifecycle guidance](../project/docs/setup/manual/lifecycle.md).

Identify whether the request concerns the Day One Mac bundle, assistant
workspace, a developer application, a container image or project dependencies.
Their update mechanisms and rollback guarantees differ.

Inspect the current owner and version, review relevant release notes, and plan
one bounded update. Keep recoverable configuration/data backups as required by
the owning guide. Do not use a blanket package upgrade to satisfy a narrow task.
After approved execution, run the capability's functional checks.

For assistant updates, export a new workspace and compare changes. Preserve
session notes and user customisations separately. Do not overwrite global
client files, follow mutable skill sources silently or treat an integrity hash
as publisher authentication. Record any version that cannot be verified.
