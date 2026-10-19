# Day One Mac

Day One Mac builds a secure, reproducible development environment on a new or
factory-reset Apple-silicon Mac. The setup has eight required phases; databases,
AI tools, MCP servers, editor profiles, and advanced automation wait until the
base is working.

## Start here

- **New or factory-reset Mac, using the guided scripts:** [open the beginner-safe start page](docs/START-HERE.md).
- **New or factory-reset Mac, without Day One Mac scripts:** [follow the complete manual route](docs/setup/manual/MANUAL-SETUP-GUIDE.md#manual-setup-flow).
- **Existing Mac with files or settings:** [start with the read-only safety process](docs/setup/existing-mac/README.md).
- **Need the complete map first:** [read the process overview](docs/explanation/PROCESS-OVERVIEW.md).
- **Need one specific command:** [open the command reference](docs/reference/COMMAND-REFERENCE.md).
- **Need to learn or maintain chezmoi:** [open the complete chezmoi setup tutorial](docs/setup/manual/CHEZMOI-SETUP-TUTORIAL.md).
- **Need to browse everything:** [open the documentation index](docs/README.md).
- **Need manual application steps or chezmoi workflows:** [open the manual handbook](docs/setup/manual/README.md).

## Install without keeping a repository

Download the small installer, inspect it, and install the checksum-verified
standalone runtime:

```bash
INSTALLER="$HOME/Downloads/install-day-one-mac"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
  -o "$INSTALLER"
# Or, if GNU wget with HTTPS support is already installed:
# wget --https-only --secure-protocol=TLSv1_2 -O "$INSTALLER" \
#   https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac
chmod 700 "$INSTALLER"
less "$INSTALLER"
"$INSTALLER"
export PATH="$HOME/.local/bin:$PATH"
day-one-mac --wizard
```

The installer includes the complete documentation set. List or open installed
guides at any time:

```bash
day-one-mac docs --list
day-one-mac docs start --open
day-one-mac docs chezmoi --open
day-one-mac docs handbook --browser
day-one-mac docs chezmoi-guide --browser
```

The runtime container is `~/.local/share/day-one-mac`; its `current` link points
to the active versioned release. No Git checkout is required afterward. The
wizard opens a setup centre for required phases, optional and advanced modules,
status checks, settings, and maintenance. Choose **Start or resume required
setup** for the complete first-time route. The setup runner saves completed
phases and tells you which
guide to open when a manual action is required. It also asks whether VS Code
should become Git's primary editor, diff viewer, and merge tool; choosing
another primary IDE leaves those Git settings unchanged. Read the
[portable installation guide](docs/reference/PORTABLE-COMMAND.md) for
updates, rollback, migration from an older Phase 8 installation, and
source-checkout development.

## Repository layout

```text
day-one-mac/
├── install-day-one-mac   Public release installer
├── scripts/             Public launcher and compatibility entry points
├── src/                 Runtime implementation, grouped by responsibility
├── config/              Catalogues, policy examples and VS Code profile data
├── docs/                Setup journeys, how-to guides, reference, explanation
├── templates/           Shell files and reusable configuration templates
├── integrations/        Warp and macOS Shortcuts assets
├── extensions/          Independent Second Brain builders
├── tests/               Regression tests and isolated fixtures
├── tools/               Contributor validation, packaging and acceptance
├── maintainers/         Architecture, plans, audits and release evidence
└── .agents/skills/      Contributor skills; excluded from runtime packages
```

Start with the [chezmoi learning path](docs/setup/manual/chezmoi.md) for first setup,
everyday edits, ownership, templates, secrets and recovery. For offline HTML,
Markdown exports and browser printing, use the
[documentation commands](docs/reference/DOCUMENTATION-COMMANDS.md).
It links the Phase 5 baseline, script-assisted and fully manual routes, daily
maintenance, command reference, ownership boundaries, private Git, and
local-only backups.
