# Day One contribute

Work in an explicitly selected source checkout, not the installed skill directory.
Read that repository's AGENTS.md and CONTRIBUTING.md before changing code.
Use [adding a capability](../project/docs/shared/reference/adding-capabilities.md)
for the required contract and tests.

Define supported platforms, installation owner, real prerequisites, operations,
verification and recovery. Keep executable metadata in config and the recipe
in its manual topic. AI guidance should link to that recipe.

Add a focused regression for changed behaviour. Cover absent prerequisites,
existing foreign configuration, repeat execution, failure and recovery where
relevant. Update the reviewed skill and documentation source inventories for distributable files and
verify independent skill use outside the checkout.

Do not introduce a whole-system runner, implicit installation, credential
examples or machine-specific paths. Report checks actually run and acceptance
that still needs hardware/accounts. Publishing and live installation require
separate authorization.
