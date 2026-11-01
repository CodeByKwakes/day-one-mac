# Day One Mac: agent router

Day One Mac is a public, Apple-silicon-only macOS development-environment guide
and portable AI-skill collection. People use its manual recipes or AI-assisted
guidance to set up and maintain their Macs without a permanent source checkout.

## Where to look first

Read [Start here](docs/START-HERE.md) and the
[process overview](docs/shared/explanation/process-overview.md), then the owning
guide for the task below. Paths are repository-relative; maintainer records and
contributor tools require a source checkout.

| Task | Canonical source |
|---|---|
| Manual setup | [Manual sequence](docs/setup/manual/README.md) and the affected guide under `docs/setup/manual/` |
| AI-assisted setup | [AI operation](docs/setup/ai/operation.md) and `docs/setup/ai/` |
| Add a capability or helper | [Capability contract](docs/shared/reference/adding-capabilities.md), [helper reference](docs/shared/reference/tools.md), `helpers/` |
| Change skill instructions | `templates/skills/`; [AI component ownership](docs/shared/explanation/ai-components.md) |
| Change native agent roles | `templates/agents/shared/` and `config/catalogs/assistant-agents.json`; native adapters under `templates/agents/` are generated |
| Package skills or native plugins | [CONTRIBUTING.md](CONTRIBUTING.md), [plugin packaging](docs/shared/reference/plugin-packaging.md), `config/skill-sources.txt`, `config/document-sources.txt`; `skills/` is generated output |
| Change the handbook or offline reader | [Reading and export](docs/shared/reading-and-export.md), `tools/docs/` |
| Check migration decisions or acceptance | `maintainers/plans/2026-10-25-no-runtime.md` records the approved migration; `maintainers/acceptance/CURRENT-READINESS.md` defines current acceptance checks |

## Hard invariants

- Do not restore a setup wizard, whole-machine runner, global CLI, installed
  runtime or background manager. Manual setup must not call project helpers.
- Keep mutations preview-first, explicitly scoped and recoverable. Preserve
  ownership and recovery evidence. Respect managed-device ownership and client
  permissions.
- Never add credentials, private keys, recovery codes, personal inventories,
  company identifiers or machine-specific absolute paths. Keep private outputs
  outside installed skills.
- Never erase or format a disk.
- Never change live Mac configuration, delete recovery backups, publish or push
  without explicit scope.

## Validation

Run from the repository root:

```bash
pnpm run lint
pnpm run validate:static
pnpm run test:integration
```

`tools/validate.sh --all` combines these checks. For plugin tests and actionlint
as well, use `pnpm run validate:complete`. Packaging changes also require the
pinned Skills CLI acceptance in [CONTRIBUTING.md](CONTRIBUTING.md).
Report isolated fixture results separately from live provider or device checks.

## Shell conventions

Target macOS Bash 3.2, use `set -euo pipefail`, quote paths and support spaces
and Unicode. Use private writes, drift checks and locks where needed. Never
source a user's shell configuration to inspect it. Lint configuration lives in
`.shellcheckrc`; [CONTRIBUTING.md](CONTRIBUTING.md) owns the check procedures.

## Maintenance

- Historical plans, audits and phase markers do not prove current completion.
- Preserve public guide URLs with compatibility notices.
- Keep manual recipes, contributor tools and installed skill assets distinct.
  Helpers must work inside independently installed skills without runtime state
  or a checkout dependency.
- Review both source inventories when adding public sources. Edit owning sources
  and regenerate skill packages and native adapters through CONTRIBUTING.md.
