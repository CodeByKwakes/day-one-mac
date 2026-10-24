---
name: day-one-contribute
description: Extend Day One Mac with a supported tool, skill or reviewed operation and its documentation/tests. Use for repository feature work, not installing tools on a user Mac.
---

# Day One contribute

Work in an explicitly selected source checkout, not the exported setup workspace.
Read that repository's AGENTS.md and CONTRIBUTING.md before changing code.
Use [adding a capability](references/project/docs/shared/reference/adding-capabilities.md)
for the required contract and tests.

Define supported platforms, installation owner, real prerequisites, operations,
verification and recovery. Keep executable metadata in config and the recipe
in its manual topic. AI guidance should link to that recipe.

Add a focused regression for changed behaviour. Cover absent prerequisites,
existing foreign configuration, repeat execution, failure and recovery where
relevant. Update the explicit runtime allowlist for distributable files and
verify packaged use outside the checkout.

Do not introduce a whole-system runner, implicit installation, credential
examples or machine-specific paths. Report checks actually run and acceptance
that still needs hardware/accounts. Publishing and live installation require
separate authorization.

## Installed package

Resolve bundled links relative to this skill directory, not the working directory.
The project reference snapshot is under `references/project/`; use its matching
paths when a guide refers to supplied configuration or template files. Read only
the guide needed for the current task. Keep this installed package unchanged.

The skill is already available after installation. Workspace export is an
optional alternative; do not require it to begin. Save approved private notes
in a user-selected workspace. The optional `day-one-mac` utility command needs
a separate installation; use the manual recipes when that command is absent.
