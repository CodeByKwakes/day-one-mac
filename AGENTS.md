# Project instructions for AI agents

Day One Mac is a public, Apple-silicon-only macOS development-environment
installer. Read `docs/START-HERE.md`, `docs/explanation/PROCESS-OVERVIEW.md` and the
affected phase before changing behaviour.

The normal user path is the public release installer, the versioned standalone
runtime, and the `day-one-mac` command. User-facing examples should use that
command. Direct scripts belong only in contributor, low-level troubleshooting,
or recovery instructions. Never make an ordinary setup depend on a permanent
Git checkout or a personal absolute path.

Documentation must distinguish the **manual route** (no Day One Mac scripts),
the **script-assisted route** (`day-one-mac`), and **shared manual actions**
that neither route can automate. Required work is a phase, an inserted gate is
a checkpoint, and optional or advanced work is a module. Do not mix routes
inside one procedure unless the transition is an explicit recovery step.

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

Read `maintainers/plans/2026-10-19-restructure.md` for the current migration
contract and progress. Preserve public commands and state paths. Configuration
catalogues own executable metadata; guides explain it. Keep user documentation,
contributor tooling and runtime packaging distinct. Test an isolated packaged
upgrade and rollback before installing an architectural change on a real Mac.
