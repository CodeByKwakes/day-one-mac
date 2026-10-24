# Add a supported capability

Keep each setup recipe in one manual guide. AI skills select that recipe; they
do not maintain a second set of installation commands.

1. Work in a repository branch and read AGENTS.md and CONTRIBUTING.md.

   Expected result: the intended scope and supported Apple-silicon platform are clear.

2. Add or extend the owning guide under `docs/setup/manual/` with prerequisites,
   numbered steps, expected results, verification, troubleshooting and recovery.

   Expected result: the procedure works without project helpers or a setup runner.

3. Update skill instructions under `templates/skills/` and client roles only if
   routing to the guide is insufficient. Keep executable configuration in `config/`.

   Expected result: one source for each instruction and configuration value.

4. If a bounded helper is needed, place it under `helpers/`. Require explicit
   inputs, preview mutations, protect pre-existing files and preserve recovery.
   Keep private output outside the installed skill and avoid global state.

   Expected result: the helper works from an isolated copied skill package.

5. Add behavioural tests for changed behaviour, including invalid input,
   missing prerequisites, later edits, ownership and partial failure as applicable.

   Expected result: the regression fails before the fix and passes afterwards.

6. Review additions to `config/skill-sources.txt` and `config/document-sources.txt`,
   update navigation and rebuild with `pnpm run skills:build`.

   Expected result: all references resolve, and only reviewed public files are bundled.

7. Run `pnpm run lint`, `pnpm run validate:static` and `pnpm run test:integration`.
   For packaging changes, also run the Skills CLI acceptance in CONTRIBUTING.md.

   Expected result: actual results and any remaining live-account checks are recorded.

Use Conventional Commits and Git revisions to track changes. Record source
verification dates beside changing vendor claims. Tags may pin reviewed skills;
there is no runtime release pipeline or package-version coupling. A local commit
is not available to GitHub installers until published through the normal review process.

<a id="prerequisites"></a>
<a id="implementation-steps"></a>
<a id="versioning"></a>
