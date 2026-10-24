# Add a supported capability

Add one canonical manual recipe and the executable metadata needed by its
reviewed operation. AI skills should route to the recipe instead of duplicating
installation commands.

## Prerequisites

Work in a repository branch and read AGENTS.md and CONTRIBUTING.md. Identify
the supported platform, user need, installation owner and existing implementation.
Do not test installation against your live machine without explicit scope.

## Implementation steps

1. Define the capability: purpose, real prerequisites, supported versions,
   configuration owner, plan/apply/check behaviour and human actions.

   Expected result: a contract that does not depend on old phase completion.

2. Add or extend its guide under `docs/setup/manual/`.

   Expected result: numbered steps with expected results, functional verification,
   troubleshooting, update/removal and recovery. Mark unverified vendor behaviour.

3. Add authoritative metadata in `config/` if a utility consumes it. Keep stable
   existing operation IDs and ownership paths. Module 12 remains retired.

   Expected result: executable data has one owner and is not parsed from prose.

4. Extend the relevant shared skill or add a narrowly scoped skill when routing
   alone is insufficient. Use each client's actual agent schema.

   Expected result: one skill source and resolvable references in an exported workspace.

5. Add behavioural tests for invalid input, missing prerequisites, pre-existing
   foreign resources, repeat application and failure/recovery where relevant.

   Expected result: failures are reproduced before the implementation changes.

6. Update `config/runtime-files.txt`, documentation indexes and command help.

   Expected result: packaged operation works outside the checkout and includes
   only reviewed regular files. No private inventory or credential is packaged.

7. Run the contributor checks and packaged acceptance required by CONTRIBUTING.md.

   Expected result: recorded command results and explicit remaining hardware/account
   acceptance. A breaking interface change needs migration and release notes.

## Versioning

Use Git history and release notes for changes. Keep tested client versions and
source verification dates with their compatibility claims. Do not claim a
feature is publicly released because it exists in the branch. Publishing and
installing a new runtime are separate decisions from repository validation.
