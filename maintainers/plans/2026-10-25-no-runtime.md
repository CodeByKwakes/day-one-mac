# No-runtime migration

Approved scope: documentation, portable AI skills and reviewed local helpers.
Baseline: `2855d4e`, branch `codex/ai-manual-setup`.

## Tasks

1. Separate portable skills, VS Code helpers and the offline reader from runtime
   inventories, versioning and state. Verify packages outside the checkout.
2. Update current guides, agents, integrations and contributor contracts. Preserve
   canonical manual recipes, historical records and compatibility guide URLs.
3. Remove the runtime, installers, runner, release automation and exclusive tests.
4. Validate independent Skills CLI installation, update and removal; run lint,
   static and integration gates. Obtain one fresh review, address material
   findings and commit. Do not push or alter remote settings or the live Mac.

## Interfaces and decisions

- Skill generation and documentation export share reviewed public sources, but
  have separate inventories. Neither reads runtime VERSION or runtime files.
- VS Code helpers resolve their own bundled data. Replacement requires a private,
  explicit backup directory and an approval digest; backups remain outside the
  installed skill. Existing private recovery records are never deleted.
- Manual guides remain executable without project helpers. Helper usage belongs
  in shared references and AI guidance.
- Historical plans, audits, tags and releases remain historical evidence.
- Companion execution helpers are absent; this file is the execution ledger.

## Review focus

Check source allowlists and independent package completeness, safe profile
replacement and restoration, offline HTML escaping and navigation, stale runtime
instructions in current guides, retained native integrations, removal of release
publishing without weakening validation, and the legacy cleanup procedure's
ownership and recovery boundaries. Fixture evidence does not establish live
provider access or account permissions.

## Evidence

- Initial working tree clean at the baseline.

- Task 1: separated VS Code helpers, portable source inventories and static reader.
  Profile fixture first failed on the absent standalone helper, then passed after
  extraction. Independent package checks generate profiles from all seven copied
  packages. Replacement fixtures cover approvals, drift, unsafe paths, partial
  failure and exact recovery. No live profiles were changed.
- Task 2: replaced runtime guide instructions with migration notices, retained
  published fragments and linked canonical manual owners. Updated AI client
  preparation, scoped skill lifecycle, private notes and the complete legacy
  removal guide. Current contributor instructions describe the new architecture.
- Task 3: removed 286 runtime-only tracked implementation/workflow/test files.
  The no-runtime fixture failed on the existing installer before removal and
  passed afterwards. Native Warp commands, shortcut assets, templates, historical
  plans/audits and published tags/releases were preserved.
- Verification so far: lint, static and integration gates passed. actionlint passed.
  Actual pinned Skills CLI acceptance passed 42 installations across seven skills,
  three clients and two scopes, plus combined-client links, Git-source installation,
  scoped updates, reinstall, source disappearance and bounded removal. Tests used
  temporary accounts and local Git remotes, not live AI accounts or GitHub publication.
- Final review: one fresh reviewer found a clean-checkout dependency on ignored
  Finder metadata in both source inventories. No other material issue was found.
- Final fix: `test-clean-source.cjs` reproduced the Finder metadata failure,
  then passed after removing those entries. Source and export validators now
  reject Finder metadata. The regression copies only source-controlled/addable
  files, then validates links, generated skills, profile data and static exports.
- Final full gate passed after the fix: 22 shell files and 1,297 Markdown files
  linted with zero findings; static checks verified 295 compatibility aliases,
  463 documents and seven generated packages; all integration fixtures passed.
  actionlint and `git diff --check` also passed. No review findings were deferred.
- Review limits are unchanged: live accounts, application imports, hardware,
  managed-device acceptance and visual/accessibility browser QA were not performed.
  They are outside this repository cleanup; reader interaction and profile changes
  were verified with isolated fixtures. Remote publication and live cleanup were
  not performed, and historical plans/audits were not changed.
- Final pinned Skills CLI acceptance was rerun after the review fix and passed
  all 42 installations, shared Claude links, local Git installation and the
  documented scoped update recipe. No publication is claimed.
