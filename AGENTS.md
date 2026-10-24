# Project instructions for AI agents

Day One Mac is a public, Apple-silicon-only macOS development-environment
guide and reviewed utility bundle. Read `docs/START-HERE.md`, `docs/shared/explanation/process-overview.md` and the
affected capability before changing behaviour.

The user journeys are AI-assisted setup and manual setup. Canonical tool
recipes live under `docs/setup/manual`; AI operation lives under `docs/setup/ai`.
The optional versioned `day-one-mac` command exposes reviewed operations only.
Never restore a setup wizard or whole-machine phase runner. A normal user must
not need a permanent source checkout. Manual setup must not call project scripts.

Preserve ownership and recovery state. Retained tools check real prerequisites;
old phase markers are historical evidence, never current completion. Keep
numeric operation IDs stable for compatibility. Shared references own tool
contracts, prerequisites and terminology. Avoid duplicating executable recipes.

Never add credentials, private keys, recovery codes, real personal inventories,
company identifiers, private repository names, 1Password vault names or
machine-specific absolute paths. Keep destructive actions preview-first,
explicitly confirmed, precisely scoped and recoverable. Never erase or format
a disk.

Shell scripts must remain compatible with macOS Bash 3.2, use
`set -euo pipefail`, quote paths and support spaces and Unicode. Reuse helpers
under `src/core/`, preserve idempotency and record only Day One Mac-owned
changes.

Validate with:

```bash
pnpm run lint
pnpm run validate:static
pnpm run test:integration
```

Run commands from the repository root. `tools/validate.sh --all` is the full
gate. Runtime changes additionally need packaged checks; see `CONTRIBUTING.md`.

## Restructuring and maintenance

Read `maintainers/plans/2026-10-24-ai-manual-rewrite.md` for the approved migration.
The earlier restructure is historical. Retired public commands must stop with
a migration notice; preserve retained interfaces and all recovery state paths. Configuration
catalogues own executable metadata; guides explain it. Keep user documentation,
contributor tooling and runtime packaging distinct. Test an isolated packaged
upgrade and rollback before installing an architectural change on a real Mac.
