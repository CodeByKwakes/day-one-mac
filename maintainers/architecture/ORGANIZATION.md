# Repository organization and migration

Decision date: 19 October 2026. Implementation baseline: `0dcfeca`.

## Boundaries and ownership

| Area | Owns | Must not own |
| --- | --- | --- |
| `src/core` | Paths, state, locks, ownership, platform and shared contracts | User journeys or optional feature policy |
| `src/setup` | Required phase coordination, choices, installation, inspection | Optional profiles or documentation-derived executable data |
| Other `src` domains | CLI, preflight, modules, operations, runtime and reader | Contributor test orchestration |
| `config/catalogs` | Application/module/phase metadata and explicit phase dependencies | Secrets or machine-specific evidence |
| `config/profiles` | Validated VS Code profile recipes | Prose procedures |
| `docs` | Setup, how-to, reference and explanation | Runtime source data or historical audit status |
| `templates`, `integrations`, `extensions` | Reusable assets, application imports, independent Second Brain builders | User-owned live configuration |
| `tests`, `tools`, `maintainers` | Fixtures, validation, release tooling, architecture and evidence | Normal-user runtime dependencies |

The setup coordinator sources choices, installation and inspection capabilities
at existing function boundaries. They still share runner context; this migration
does not introduce a new context object or promise complete independence.

## Compatibility and saved evidence

The code, document and configuration path migration JSON files in this directory
record mechanical moves. `config/catalogs/document-aliases.json` maps old guide
paths to canonical ones. Old supported scripts are regular-file adapters, keeping
arguments, exit codes and source behavior. Do not replace them with symlinks:
runtime integrity packaging intentionally accepts regular files only.

Keep these adapters and guide aliases throughout the current 1.x compatibility
line. Remove one only after a separately approved deprecation, published upgrade
instructions, a caller search and packaged upgrade tests. No retirement date is
implied by moving the implementation. Legacy pages are excluded from reader
navigation and search, but their old routes and section anchors still resolve.

State and user output paths remain unchanged. Phase dependency schema 2 requires
honest revalidation of earlier markers. Optional implementation changes no longer
invalidate unrelated required phases. Dependency rows must be valid, unique and
cover every phase implementation; failures stop before a phase can apply changes
or replace evidence. Add transitive dependencies deliberately when changing a
phase. The runtime cannot infer a dependency omitted from a valid catalogue.

## Documentation and profile data

The PostgreSQL foundation, database operations and VS Code connection procedures
are shared. DataGrip and DBeaver guides own client-specific setup. Advanced
editor guidance links to focused AI, project instruction, MCP and terminal pages.

Profile generation reads JSON configuration. `tools/sync-vscode-reference.cjs`
generates the reference page; `--check` rejects drift. Profile equivalence fixtures
preserve the outputs captured before extraction.

## Packaging and acceptance

`config/runtime-files.txt` is the only runtime allowlist. Compatibility files
remain in it; the restructuring prioritizes supported upgrades over a smaller
file count. Contributor skills, historical audits and tests are excluded.

`tools/validate.sh --static` checks structure and documentation.
`--regressions` runs isolated behavioral fixtures; `--all` runs both. Shell and
Markdown linting remain separate. Packaging tests verify offline documentation,
profile generation, installation integrity and rollback using temporary homes.
Real macOS and MDM acceptance remains a separate release requirement: a fixture
cannot prove physical peripherals, identity-provider enrollment or enterprise
policy behavior.
