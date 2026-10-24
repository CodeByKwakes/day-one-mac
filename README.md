# Day One Mac

Day One Mac builds a secure, reproducible development environment on a new or
factory-reset Apple-silicon Mac. The setup has eight required phases; databases,
AI tools, MCP servers, editor profiles, and advanced automation wait until the
base is working.

## Start here

- [Scripted (Assisted) Setup](docs/setup/assisted/README.md): install the standalone
  runtime, review choices and follow resumable phases with recorded ownership.
- [Manual Setup](docs/setup/manual/README.md): perform each installation and edit
  yourself, without Day One Mac scripts.

Start with [prerequisites and route selection](docs/START-HERE.md). Both routes
use one [shared library](docs/shared/README.md) for decisions, terminology,
verification and troubleshooting. [All documentation](docs/README.md) groups tasks
by route and topic.

## Install without keeping a repository

Follow the [runtime installation guide](docs/setup/assisted/runtime.md) for the
public installer, review, checksum verification and recovery. After installation,
run `day-one-mac --wizard` to start or resume. The installed runtime includes the
guides; `day-one-mac docs --list` lists topics and `day-one-mac docs --browser`
opens the offline reader. See [reading and export](docs/shared/reading-and-export.md).

Runtime state and ownership records are distinct from a source checkout. The
manual route does not install the runtime or require its state.

## Repository layout

```text
day-one-mac/
├── install-day-one-mac   Public release installer
├── scripts/             Public launcher and compatibility entry points
├── src/                 Runtime implementation, grouped by responsibility
├── config/              Catalogues, policy examples and VS Code profile data
├── docs/                Assisted setup, manual setup and the shared library
├── templates/           Shell files and reusable configuration templates
├── integrations/        Warp and macOS Shortcuts assets
├── extensions/          Independent Second Brain builders
├── tests/               Regression tests and isolated fixtures
├── tools/               Contributor validation, packaging and acceptance
├── maintainers/         Architecture, plans, audits and release evidence
└── .agents/skills/      Contributor skills; excluded from runtime packages
```

Start with the [chezmoi learning path](docs/setup/manual/shell/README.md) for first setup,
everyday edits, ownership, templates, secrets and recovery. For offline HTML,
Markdown exports and browser printing, use the
[documentation commands](docs/shared/reading-and-export.md).
