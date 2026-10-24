# Contributing

Day One Mac maintains manual recipes, AI skills and narrowly scoped helpers.
Read [Start here](docs/START-HERE.md) and [adding a capability](docs/shared/reference/adding-capabilities.md)
before changing behaviour. Work in a branch; keep real inventories, credentials
and private machine paths outside the public repository.

## Prepare contributor tools

1. Install Node.js 22.20 or newer, the pnpm version in `package.json`, ShellCheck
   and actionlint using your approved tool owner.

   Expected result: `node --version`, `pnpm --version`, `shellcheck --version`
   and `actionlint --version` succeed.

2. From the repository root, install locked dependencies:

   ```bash
   pnpm install --frozen-lockfile
   ```

   Expected result: contributor dependencies and local Git hooks are ready.
   The private package is tooling only; users do not install it as an application.

## Change and verify

1. Edit the owning manual guide, configuration, skill template or helper. Update
   the reviewed source inventories for newly bundled files. Never edit generated
   `skills/` contents directly.

2. Regenerate references and skill packages:

   ```bash
   pnpm run docs:sync
   pnpm run skills:build
   ```

   Expected result: committed outputs match their sources. The builder refuses
   unexpected generated files; review obsolete entries before removing them.

3. Run the full gate:

   ```bash
   tools/validate.sh --all
   actionlint
   ```

   Expected result: lint, static and integration checks pass. Fixtures use
   temporary locations and mock external commands; they do not prove live
   account, provider, hardware or managed-device acceptance.

4. For skill packaging or installer changes, test the pinned Skills CLI. Install
   it in a temporary contributor directory, not as a global application:

   ```bash
   SKILLS_TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/day-one-skills-test.XXXXXX")"
   npm install --prefix "$SKILLS_TEST_DIR" --ignore-scripts --no-audit --no-fund skills@1.7.4
   pnpm run test:skills-cli "$SKILLS_TEST_DIR/node_modules/skills/bin/cli.mjs"
   ```

   Expected result: isolated local/Git installs, scoped updates, removal and
   source-independent packages pass for the supported clients. No live AI account
   is needed. Retain logs outside the repository, then remove only the temporary
   directory you created when finished.

5. Review the diff and commit using Conventional Commits, for example
   `docs: clarify profile recovery` or `fix(skills): preserve shared references`.

   Expected result: the commit explains the concrete change and verification.
   Git hooks check formatting and messages; CI checks all supported runners.

## Publishing and compatibility

There is no runtime release pipeline, installer archive or release token
requirement. Reviewed commits and optional tags identify skill snapshots.
A GitHub install can only use a revision available on the remote. Pushing,
merging and publishing require their normal approval.

Preserve old documentation URLs using migration notices and the alias catalogue.
Do not restore runtime wrappers to keep old commands alive. Existing users have
one [legacy manager removal guide](docs/shared/migration/remove-legacy-manager.md).
Historical plans, audits, CHANGELOG entries, tags and releases remain records.

The [offline reader](docs/shared/reading-and-export.md) is a static contributor
export. Its files work without the checkout or a running service.

<a id="before-changing-code"></a>
<a id="source-ownership"></a>
<a id="validate-a-change"></a>
<a id="release-workflow"></a>
<a id="public-examples"></a>
<a id="setup-guide-template"></a>
<a id="ai-assisted-and-manual-architecture"></a>
