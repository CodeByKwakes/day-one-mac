# Day One Mac

Day One Mac builds a secure, reproducible development environment on a new or
factory-reset Apple-silicon Mac. The setup has eight required phases; databases,
AI tools, MCP servers, editor profiles, and advanced automation wait until the
base is working.

## Start here

- **New or factory-reset Mac, using the guided scripts:** [open the beginner-safe start page](docs/START-HERE.md).
- **New or factory-reset Mac, without Day One Mac scripts:** [follow the complete manual route](docs/20-reference/NOTION-SETUP-GUIDE.md#manual-setup-flow).
- **Existing Mac with files or settings:** [start with the read-only safety process](docs/00-preflight/README.md).
- **Need the complete map first:** [read the process overview](docs/PROCESS-OVERVIEW.md).
- **Need one specific command:** [open the command reference](docs/20-reference/COMMAND-REFERENCE.md).
- **Need to browse everything:** [open the documentation index](docs/README.md).

## Install without keeping a repository

Download the small installer, inspect it, and install the checksum-verified
standalone runtime:

```bash
INSTALLER="$HOME/Downloads/install-day-one-mac"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
  -o "$INSTALLER"
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
```

The runtime container is `~/.local/share/day-one-mac`; its `current` link points
to the active versioned release. No Git checkout is required afterward. The
wizard saves completed phases and tells you which
guide to open when a manual action is required. It also asks whether VS Code
should become Git's primary editor, diff viewer, and merge tool; choosing
another primary IDE leaves those Git settings unchanged. Read the
[portable installation guide](docs/20-reference/PORTABLE-COMMAND.md) for
updates, rollback, migration from an older Phase 8 installation, and
source-checkout development.

## Repository layout

```text
day-one-mac/
├── install-day-one-mac  Reviewed standalone installer
├── README.md            This short entry point
├── docs/                Setup guides, navigation, and reference material
├── scripts/             Setup, verification, runtime and recovery commands
├── config/              Application and optional-tool catalogues
├── second-brain/        Independent knowledge-system builders
└── warp-drive/          Importable Warp workflows
```

Configuration files that Phase 5 should manage are shown in the
[Phase 5 shell-file reference](docs/20-reference/phase-05-shell-files/README.md).
The safe source-to-target-to-Git process is documented in
[Manage dotfiles with chezmoi](docs/20-reference/MANAGING-DOTFILES-WITH-CHEZMOI.md).
