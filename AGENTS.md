# Project instructions for AI agents

Day One Mac is a public, Apple-silicon-only macOS development-environment guide
and portable AI-skill collection. Read `docs/START-HERE.md`,
`docs/shared/explanation/process-overview.md` and the affected capability first.

The routes are AI-assisted setup and manual setup. Canonical recipes live under
`docs/setup/manual`; AI operation lives under `docs/setup/ai`. Do not restore a
setup wizard, whole-machine runner, global CLI, installed runtime or background
manager. Normal users need no permanent checkout. Manual setup must not call
project helpers.

Keep instructions in `templates/skills/`, native roles in `templates/agents/`,
and generated installable packages in `skills/`. Update `config/skill-sources.txt`
and `config/document-sources.txt` deliberately when adding public sources.
Helpers under `helpers/` must work inside an independently installed skill, with
no runtime state or checkout dependency. Keep private outputs outside skills.

Preserve ownership and recovery evidence. Historical phase markers do not prove
current completion. Never add credentials, private keys, recovery codes,
personal inventories, company identifiers or machine-specific absolute paths.
Keep mutations preview-first, explicitly scoped and recoverable. Never erase or
format a disk. Respect managed-device ownership and client permissions.

Shell scripts target macOS Bash 3.2, use `set -euo pipefail`, quote paths and
support spaces and Unicode. Use private writes, drift checks and locks where
needed. Do not source a user's shell configuration to inspect it.

Validate from the repository root:

```bash
pnpm run lint
pnpm run validate:static
pnpm run test:integration
```

`tools/validate.sh --all` is the full local gate. Packaging changes also require
the pinned Skills CLI acceptance in CONTRIBUTING.md. Report isolated fixture
results separately from live provider or device checks.

## Restructuring and maintenance

The approved no-runtime migration is recorded in
`maintainers/plans/2026-10-25-no-runtime.md`. Earlier plans and audits remain
historical. Preserve public guide URLs with compatibility notices. Keep manual
recipes, contributor tools and installed skill assets distinct. Never change
live Mac configuration, delete recovery backups, publish or push without scope.
