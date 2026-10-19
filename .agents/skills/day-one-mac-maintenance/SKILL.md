---
name: day-one-mac-maintenance
description: Maintain the Day One Mac installer, runtime, configuration catalogues and setup documentation while preserving its state, ownership and packaging contracts. Use for changes in this repository, not for configuring unrelated application repositories.
---

# Day One Mac maintenance

Read the repository's `AGENTS.md`, `docs/START-HERE.md` and the affected guide.
Use the public `day-one-mac` command in user instructions. A normal installation
must work without a Git checkout or contributor dependencies.

## Contracts that affect implementation choices

- Target native Apple silicon and macOS Bash 3.2. Avoid `mapfile`, `readarray`,
  associative arrays and Bash 4-only expansions. Quote paths; preserve spaces
  and Unicode. Source helpers instead of executing or sourcing user profiles.
- Preserve phase IDs 01–08, existing module IDs and retired Module 12. Profiles
  use `vscode-profile`; never recreate Module 12's generator.
- Keep planning and inspection read-only. Apply uses existing operation locks,
  ownership records and atomic private state helpers. Record only project-owned
  changes. Destructive operations retain preview, confirmation and recovery.
- Preserve state locations and originals. A fingerprint change requires real
  revalidation; never manufacture new completion markers from old evidence.
- Phase dependencies are explicit configuration. Update their catalogue when
  changing a required phase's transitive implementation dependencies; optional
  helpers must not invalidate unrelated required phases.
- Executable profile data belongs in `config/profiles/vscode/`. Documentation
  explains it; the generator must not parse Markdown headings or tables.
- Runtime contents are explicitly allowlisted regular files. No symlinks,
  contributor skills, test fixtures, dependency trees or private machine data
  belong in a package. Update the allowlist with every runtime path change.
- Keep compatibility entry points small. Mechanical moves and behavioral
  changes should be separately reviewable. Resolve paths from the runtime root,
  not the caller's current directory.
- Managed settings belong to IT. Support a standard daily account with approved
  elevation. Do not assume local administrator rights for every user.

## Documentation ownership

Keep manual setup, script-assisted setup and shared manual actions distinct.
Use phases for required work, checkpoints for inserted gates and modules for
optional work. Shared PostgreSQL procedures are client-neutral; client guides
own their application-specific instructions. Keep maintainer plans and audit
history separate from ordinary setup guides.

The user's approved outline and requested execution remain authorization;
routine edits within that scope do not require another outline approval.
Verify new product claims against official sources when the task authorizes
source verification. Do not claim current hardware/MDM acceptance from fixtures.

## Evidence appropriate to the change

Use the commands in `CONTRIBUTING.md` and `package.json`. Run focused behavioral
checks for the changed interface, Markdown/link checks for guides, ShellCheck
and Bash syntax checks for shell changes, and the full release gate for runtime
migration. A packaged upgrade and rollback must use an isolated temporary home
before an authorized installation on a real Mac. Preserve existing user changes.

Report the source commit, checks actually run, package/runtime status and any
remaining acceptance limits separately. Do not claim a public release, live
installation or managed-device pilot merely because the repository tests pass.
