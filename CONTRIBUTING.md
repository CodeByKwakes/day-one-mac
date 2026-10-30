# Contributing

Day One Mac maintains manual recipes, AI skills and narrowly scoped helpers.
Read [Start here](docs/START-HERE.md) and [adding a capability](docs/shared/reference/adding-capabilities.md)
before changing behaviour. Work in a branch; keep real inventories, credentials
and private machine paths outside the public repository.

Use this checkout's `day-one-mac-maintenance` skill for repository upkeep.
It is the only repository-owned contributor skill, displayed as **Maintain this
repository**. General planning, writing, design and review helpers belong in a
contributor's personal toolkit. They are optional; AGENTS.md, this guide and the
repository checks are sufficient to contribute.
The public `day-one-maintain` and `day-one-contribute` workflows serve different
scopes; see the [maintenance skill distinction](docs/setup/manual/ai/day-one-skills.md#repository-maintenance-versus-environment-maintenance)
for their source locations and packaging boundaries.

The [AI component reference](docs/shared/explanation/ai-components.md) owns skill,
integration and agent boundaries. Edit shared policies under
`templates/agents/shared` and role metadata in
`config/catalogs/assistant-agents.json`; native adapters are generated.

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
   pnpm run agents:build
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

   When changing MCP or shared AI integration contracts, install its locked
   contributor dependencies and run the combined gate:

   ```bash
   npm --prefix integrations/mcp ci --ignore-scripts --no-audit --no-fund
   pnpm run validate:complete
   ```

   This adds MCP protocol and relocated-package checks to the root gate. Docker
   image build/smoke checks remain separate, as in CI. These are optional-server
   contributor checks, not prerequisites for ordinary guide or skill users.

   Native plugin changes also run `pnpm run test:plugins`. The
   [plugin packaging reference](docs/shared/reference/plugin-packaging.md) owns
   artifact generation and optional native CLI acceptance.

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

The [handbook website and offline download](docs/shared/reading-and-export.md)
share the reviewed document inventory. Contributor builds need Node.js 22.20+
and `zip`; reading needs only a browser. `Publish documentation` deploys the
successful `Validate` run's main-branch revision, provided it is still current.
Enable GitHub Pages with **Settings → Pages → Source → GitHub Actions** once.
To publish the current main revision again, use **Actions → Validate → Run
workflow → main**. This validates first, then triggers documentation publishing.
Pull requests cannot deploy. No runtime installer or application release is built.

For a local website and offline ZIP, use a new output directory:

```bash
pnpm run docs:build --output "$HOME/Downloads/day-one-website-review"
```

The output contains `index.html`, `day-one-mac-offline.zip`, public source files
and `snapshot.json`. A local build records its content fingerprint without
inventing a Git revision; CI supplies the validated commit SHA. Follow the
reading guide for local opening, publishing checks and rollback.

<a id="before-changing-code"></a>
<a id="source-ownership"></a>
<a id="validate-a-change"></a>
<a id="release-workflow"></a>
<a id="public-examples"></a>
<a id="setup-guide-template"></a>
<a id="ai-assisted-and-manual-architecture"></a>
