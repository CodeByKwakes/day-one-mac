---
name: day-one-maintain
description: Review and apply scoped updates to developer tools and Day One Mac assets while preserving installation owners and recovery options. Use for maintenance or configuration drift.
---

# Day One maintain

Read [maintenance](../../../docs/setup/manual/maintenance.md) and
[lifecycle guidance](../../../docs/setup/manual/lifecycle.md).

Identify whether the request concerns the Day One Mac skill, private session
notes, a developer application, a container image or project dependencies.
Their update mechanisms and rollback guarantees differ.

Inspect the current owner and version, review relevant release notes, and plan
one bounded update. Keep recoverable configuration/data backups as required by
the owning guide. Do not use a blanket package upgrade to satisfy a narrow task.
After approved execution, run the capability's functional checks.

For skill updates, use the scoped update instructions in the
[skill guide](../../../docs/setup/manual/ai/day-one-skills.md) and compare changes. Preserve
session notes and user customisations separately. Do not overwrite global
client files, follow mutable skill sources silently or treat an integrity hash
as publisher authentication. Record any version that cannot be verified.
