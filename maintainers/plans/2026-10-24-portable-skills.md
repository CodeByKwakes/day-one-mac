# Portable skills and manager retirement

Kind: implementation record. Audience: project maintainers.
Purpose: implement the approved skill distribution and scoped local retirement.
Baseline: `41aaec0`. Branch: `codex/ai-manual-setup`.

## Approved scope

Publish self-contained packages for `day-one-mac` and the six specialist skills.
The main skill routes to bundled workflows without requiring other installed skills.
Generate references from maintained sources, preserve optional agent adapters,
update the README with GitHub/local installation, and test actual Skills CLI use.
Commit the verified repository changes before retiring the old installed manager.
Keep the repository, developer tools, profiles, credentials and shared shell setup.
Do not push, merge, publish or install skills into real global client directories.

Retirement follows a verified private backup, runtime removal preview and confirmed
uninstall, removal of the obsolete `cdayone` block, and archival of remaining state
and installer. Remove only confirmed obsolete application integrations. Preserve
the recovery archive. Machine-specific evidence stays outside this public repository.

## Tasks

- [x] Package seven portable skills and test local reference resolution.
- [x] Integrate workspace export, documentation and generated-file checks.
- [x] Verify actual CLI installation independently and with each selected client.
- [x] Run repository gates, packaged checks and independent final review.
- [ ] Commit the verified implementation.
- [ ] Back up, retire and verify the old local manager; report recovery location.

## Interfaces and review focus

- `config/catalogs/assistant-skills.json` declares packages and required assets.
- `tools/build-skills.cjs` writes deterministic `skills/` packages; `--check`
  detects stale or unexpected output without writing.
- Package references resolve inside one skill, including nested manual links.
- The exporter installs these same packages, with client roles kept separate.
- Actual CLI tests use temporary homes/workspaces, including spaces and Unicode.
- A single main skill must include all workflows with no specialist installation.
- Generation must refuse private sources, symlinks and path escapes.
- Updates/removal must preserve unrelated skills and private session notes.
- Live cleanup must preserve a verified backup and change only the approved paths.

## Execution decisions and evidence

- Approval includes the main skill amendment and scoped cleanup after validation.
- Companion workflow packages are absent; execute inline with repository checks
  and one independent final review, as required by executing-plans.
- Required linked guides are bundled as generated references. Navigation can
  produce overlapping reference sets; this costs package size, while avoiding
  separate hand-maintained copies or a dependency on a live checkout.
- The first npm metadata request failed certificate verification. TLS verification
  remains enabled; test the system trust store before choosing another source.
- macOS system trust with Node's `--use-system-ca` resolved package access.
  The pinned CLI is `skills@1.7.4`, requiring Node.js `>=22.20.0`.
- Initial portability regression failed because packages did not exist, then
  passed for seven isolated packages with bundled references and one entry point.
- Actual CLI checks passed for 42 single-client/scope installs, local reinstall,
  source disappearance and selected removal. Two combined-client checks verified
  shared Claude links. Single-client Claude uses a direct copy; docs reflect it.
- Concurrent packaging exposed a partial inventory read during generation.
  Atomic file replacement now preserves complete old/new views. The regression
  failed before the helper existed and passed after implementation.
- Independent final review found an unscoped CLI `check` that actually updates
  skills, and a bootstrap caller expecting the old exported layout. One fix pass
  replaces the update recipe with a named, explicit scope and corrects bootstrap
  expectations. The actual CLI reproduced the unrelated-skill update before the
  recipe fix; the regression executes the documented command block.
- Repository-root CLI discovery selects the generated main package. A local Git
  remote fixture exercises installation and updates without claiming publication.
- The independent reviewer resolved 8,299 internal package links and found no
  further actionable issues in generation, routing, role adapters or export.
- Final lint and static validation passed. Package acceptance and an isolated
  previous-version upgrade/rollback passed, preserving state and shell files.
- The final integration run passed every fixture except an SSH fixture whose
  temporary Unix socket was blocked by execution permissions. Its isolated rerun
  with that permission passed all assertions. The aggregate command retains its
  nonzero result for the blocked attempt; no code failure remains unresolved.
- Actual CLI checks passed after the review fixes, including repository-root
  discovery, Git-source installation and the documented scoped update recipe.
- The private retirement helper passed an isolated rehearsal covering backup
  verification, changed-file refusal, scoped archival and unrelated aliases.
