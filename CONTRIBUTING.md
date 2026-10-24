# Contributing

Thank you for improving Day One Mac.

## Before changing code

1. Read [Start Here](docs/START-HERE.md) and the affected capability guide.
2. Keep AI-assisted and manual setup as the two routes. Retained utilities
   perform explicit operations and check their actual prerequisites.
3. Never add real credentials, private keys, personal inventories, company
   names, private repository names, vault names or absolute personal paths.
4. Keep scripts compatible with the Bash 3.2 included with macOS.
5. Make mutations idempotent, preview-first where destructive, and precisely
   recorded for rollback.
6. Use the `day-one-mac` portable command in user-facing instructions. Show
   direct scripts only in contributor, low-level troubleshooting, or recovery
   sections, and state why the direct form is needed.
7. Treat the public release installer and versioned standalone runtime as the
   normal distribution path. A source checkout is optional development state.

## Source ownership

Runtime behavior lives in `src/`; `scripts/` preserves the public launcher and
old entry points. Edit canonical guides in `docs/setup/ai`, `docs/setup/manual` and `docs/shared`. Old numbered guide folders are aliases.
Contributor history and release procedures belong in `maintainers/`.

Application, module, phase and dependency catalogues live in `config/catalogs/`.
VS Code profile data lives in `config/profiles/vscode/profiles.json`; run
`pnpm run docs:sync` after editing it. Do not edit the generated reference.
Add every runtime file to `config/runtime-files.txt`. Keep contributor skills,
tests, audit history and private machine data outside that allowlist.

## Validate a change

```bash
pnpm install --frozen-lockfile
pnpm run lint
pnpm run validate:static
pnpm run test:integration
pnpm run acceptance:package
```

Static checks validate shell syntax, local documentation links, configuration
catalogues and whether generated references match their source. Integration
tests use isolated temporary homes. The combined `tools/validate.sh --all` is the
CI gate: it must pass before a change proceeds through that workflow.
Native acceptance requires separate real-Mac and managed-device evidence.

Also inspect:

```bash
git diff --check
git status --short
```

Run `pnpm install --frozen-lockfile` once after cloning to install the
contributor tools and activate the shared Husky hooks. See the
contributor-tooling setup guide (`maintainers/contributing/CONTRIBUTOR-TOOLING.md` in a source checkout)
for prerequisites, hook behaviour, troubleshooting, and safe bypasses. These
maintainer files belong to a source checkout and are not in the standalone runtime.

## Release workflow

Use Conventional Commit subjects so Release Please can select the next
semantic version:

- `fix:` proposes a patch release;
- `feat:` proposes a minor release;
- `feat!:` or another explicit breaking-change marker proposes a major release.

Do not update `VERSION`, create a release tag, or publish a GitHub Release by
hand during normal development. After validation succeeds on `main`, Release
Please updates one release pull request containing `VERSION`, the private
contributor-tooling version in `package.json`, `CHANGELOG.md`, and the release
manifest. Review and merge that pull request when the changes are ready to
publish. The workflow creates the tag and a draft release, validates that exact
candidate and archive, then attaches the runtime, checksum, installer and
provenance/evidence before publishing. Failed candidates remain drafts; see the
release and retry procedure (`maintainers/contributing/GIT-WORKFLOW.md#release-lifecycle-and-failed-draft-retry` in a source checkout).

Repository maintainers must keep the narrowly scoped `RELEASE_PLEASE_TOKEN`
Actions secret available so the generated release pull request receives the
normal validation workflow.

## Public examples

Use placeholders such as:

```text
/Users/your-name
github.com/example-user/example-repository
op://<vault>/<item>/<field>
```

Never use a realistic token, even when it has been revoked.

## Setup-guide template

Keep one complete procedure in its owning route. A shared human action lives in the Manual Setup topic; the assisted guide links to that task and says when to return. Shared prerequisites, terminology, acceptance criteria and troubleshooting navigation live under `docs/shared`.

Use this order for a new or substantially revised setup guide:

1. **Outcome and scope:** who needs the task, what changes and what remains outside it.
2. **Prerequisites:** selected tools, permissions, versions and backups. Link shared requirements once.
3. **Numbered actions:** one action per step, followed by the expected result. Define unfamiliar terms on first use and mark placeholders explicitly.
4. **Verification:** observable checks of the finished behavior, not just command exit status.
5. **Troubleshooting and recovery:** likely symptoms, the relevant owner and a scoped way to undo the change.
6. **Next steps and sources:** where to continue, vendor references, and anything not verified on real hardware or in the published release.

Reference pages may use tables instead of a procedure. Compatibility pages preserve old headings and forward to the current owner; they must not grow a second copy of the instructions. Update the reader, aliases and runtime inventory with every move.

## AI-assisted and manual architecture

The normal setup choices are AI-assisted and manual. Canonical commands live in
`docs/setup/manual/`; AI guides explain client preparation and the approval cycle.
Shared prerequisites, reference and recovery live in `docs/shared/`. The optional
`day-one-mac` bundle exposes bounded reviewed utilities, not a whole-machine runner.

Add executable metadata to `config/catalogs/`, package dependencies explicitly in
`config/runtime-files.txt`, and document prerequisites and ownership before adding
an apply action. Skills in `templates/skills/` share instructions across clients;
role adapters in `templates/agents/` use each client's own format. Never treat a
skill as permission to execute commands.

Historical runner source and fixtures remain for previous-version recovery research;
they are excluded from the current runtime and active setup path. Integration
checks cover command retirement, fresh-state utilities, assistant exports and the
retained operations. See `maintainers/plans/2026-10-24-ai-manual-progress.md` in a source checkout
for replaced test contracts. Do not restore phase-marker gates.

Before proposing an architectural release, run the lint, static, integration and
packaged acceptance gates, then exercise an isolated upgrade and rollback from
the previous release. Live account, managed-device and container checks require
separate acceptance evidence; a passing fixture is not that evidence.
