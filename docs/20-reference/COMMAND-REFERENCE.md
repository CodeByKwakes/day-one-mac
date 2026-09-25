[← Start Here](../START-HERE.md) · **Command reference** · [Process overview](../PROCESS-OVERVIEW.md) · [Removal and reset](../04-operations/REMOVE-DAY-ONE-MAC.md)

# Day One Mac command reference

This page lists every supported user-facing Day One Mac command, its direct
script equivalent, and when to use it. It does not list files below
`scripts/lib/` or `scripts/tests/` as setup commands: those are internal
libraries and regression fixtures.

## Understand the two command forms

### Portable command — recommended from the beginning

Install the public, checkout-independent runtime:

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

It installs a versioned runtime under `~/.local/share/day-one-mac` and works
from any directory without a Git checkout. Phase 5 later adopts the same
launcher into chezmoi. See [Install and manage the standalone runtime](PORTABLE-COMMAND.md).

### Direct scripts — fallback and maintenance

From either the installed runtime or a development checkout:

```bash
cd "$(day-one-mac root)/scripts"
./bootstrap-day-one-mac.sh --wizard
```

Direct scripts are primarily for development and documented troubleshooting.

Check the portable command before relying on it:

```bash
day-one-mac help
day-one-mac --status
```

If the runtime command is deliberately removed, reinstall it using the reviewed
public installer or an offline release archive.

## Complete portable command list

Install this command before Phase 1; the standalone runtime remains its sole owner
into chezmoi. See [PORTABLE-COMMAND.md](PORTABLE-COMMAND.md) for installation,
updates and rollback.

| Portable command | Direct script equivalent | Use it when |
|---|---|---|
| `day-one-mac` | `./bootstrap-day-one-mac.sh` | Open the main setup wizard using saved choices when available. |
| `day-one-mac bootstrap [options]` | Downloaded-dispatcher operation | Clone or reuse the project and install the portable command before Phase 1. |
| `day-one-mac help` | No exact script; dispatcher help | See the installed top-level commands. `-h` and `--help` are equivalent. |
| `day-one-mac root` | Read `~/.day-one-mac/runtime-root` | Print the active standalone runtime or linked development root. |
| `day-one-mac runtime-status` | `./runtime-manager.sh status` | Show the active version, location and checksum result. |
| `day-one-mac update` | `./runtime-manager.sh update` | Download and install the latest verified public release beside the current version. |
| `day-one-mac rollback-runtime [options]` | `./runtime-manager.sh rollback [options]` | Preview or select a previous installed runtime without undoing setup changes. |
| `day-one-mac uninstall-runtime [options]` | `./runtime-manager.sh uninstall [options]` | Remove only the launcher and runtime while preserving setup state and the configured environment. |
| `day-one-mac docs [TOPIC] [--open]` | `./runtime-manager.sh docs …` | List, locate, or open documentation inside the active runtime. Topics include `optional` and `advanced`; use `--list` for all topics or `--folder --open` for the complete documentation folder. |
| `day-one-mac shell-status` | `./shell-status.sh` | Run a read-only check of Homebrew zsh, startup files, clean-shell PATHs, completions and selected tools. |
| `day-one-mac setup [options]` | `./bootstrap-day-one-mac.sh [options]` | Start, resume, inspect, or reset the required eight-phase setup. |
| `day-one-mac install [options]` | `./bootstrap-day-one-mac.sh --install-centre [options]` | Install or revalidate required applications and command-line tools after Phase 2. |
| `day-one-mac applications [options]` | `./application-status.sh [options]` | Check required or optional application ownership and resolve selected missing apps. |
| `day-one-mac ssh-pin [github\|azure\|both]` | `./bootstrap-day-one-mac.sh --ssh-pin …` | Export reviewed 1Password SSH public keys to stable `~/.ssh` public-key files. |
| `day-one-mac macos-settings [options]` | `./configure-macos-settings.sh [options]` | Configure, inspect, preview, or restore optional Finder, Dock, keyboard, and trackpad preferences. |
| `day-one-mac workspace [command]` | `./workspace-manager.sh [command]` | Create, inspect, complete, or open a bounded projectless task. |
| `day-one-mac raycast [options]` | `./configure-raycast.sh [options]` | Preview, generate, inspect, or archive the optional track-aware Raycast Script Commands. |
| `day-one-mac optional --guided` | `./bootstrap-day-one-mac.sh --optional --guided` | Choose optional modules after required Phase 8 passes and continue to available installers. |
| `day-one-mac databases [options]` | `./configure-databases.sh [options]` | Install, resume, inspect, or verify the selected PostgreSQL, Redis, and MongoDB containers. |
| `day-one-mac safety-report [options]` | `./preflight-audit.sh [options]` | Create the read-only Stage 0 report on an existing Mac before choosing a reset or cleanup route. |
| `day-one-mac prepare-existing [options]` | `./prepare-existing-mac.sh [options]` | Open the resumable Route A/Route B dashboard for a Mac that already contains data or setup. With no arguments, the portable command adds `--guided`. |
| `day-one-mac inventory [options]` | `./application-inventory.sh [options]` | Write a complete report of Homebrew, Mac App Store, system, and other application bundles. |
| `day-one-mac advanced [options]` | `./advanced-setup.sh [options]` | Read and track advanced Modules 15–22 after the base setup. It does not perform their configuration. |
| `day-one-mac advanced-audit [options]` | `./advanced-audit.sh [options]` | Generate the private, extended environment and repository report. |
| `day-one-mac cli-tools [options]` | `./configure-cli-tools.sh [options]` | Select and install optional Homebrew formulae without removing unselected tools. |
| `day-one-mac finalize [options]` | `./finalize-setup.sh [options]` | Review or compact setup evidence after Phase 8, or deliberately detach the setup system. |
| `day-one-mac remove [options]` | `./remove-day-one-mac.sh [options]` | Choose a recorded, sectional, or full removal plan with an ownership-aware preview. |
| `day-one-mac rollback [options]` | `./rollback-recorded-setup.sh [options]` | Preview or reverse only changes recorded as belonging to Day One Mac. |
| `day-one-mac clean [options]` | `./clean-development-state.sh [options]` | Preview a broad development cleanup or create/resume its recovery archive. This is wider than recorded rollback. |
| `day-one-mac validate` | `./validate.sh` | Run the complete read-only structural and regression validation suite. |

Use the current names in this reference for new notes and Warp workflows.
Machines upgraded from a pre-standalone installation can consult
[Upgrade notes](UPGRADE-NOTES.md) for accepted aliases and state migration.

## Required setup commands

### Main wizard and eight phases

```bash
day-one-mac --guided
day-one-mac --status
day-one-mac setup --phase 05
day-one-mac setup --dry-run
day-one-mac setup --reset-progress
```

Direct equivalents:

```bash
./bootstrap-day-one-mac.sh --guided
./bootstrap-day-one-mac.sh --status
./bootstrap-day-one-mac.sh --phase 05
./setup.sh --guided
./setup.sh --phase 05
```

Use `bootstrap-day-one-mac.sh` for the normal choice-first experience. Use the
lower-level `setup.sh` only when following a phase guide or troubleshooting the
eight-phase engine directly.

Important setup selectors include:

```text
--track 1|2|3
--stack node|python|both
--name "Full Name"
--email ADDRESS
--primary-ide vscode|other
--dotfiles-repo URL
--new-dotfiles
--dotfiles-versioning git|local
--local-dotfiles
--macos-settings ask|configure|skip
--app-install-policy prompt|homebrew|check-only
--phase NN
--dry-run
--status
--reset-progress
```

Run `day-one-mac setup --help` or `./bootstrap-day-one-mac.sh --help` before
using unattended flags. `--yes` accepts ordinary confirmations; it does not
bypass typed destructive confirmations or select an application owner.

### Installation Centre and application ownership

```bash
day-one-mac install
day-one-mac applications --required
day-one-mac applications --optional
day-one-mac applications --id raycast
day-one-mac applications --id obsidian --install-missing
day-one-mac applications --required --install-missing \
  --app-install-policy homebrew
```

Use `install` for the required software checkpoint. Use `applications` for a
smaller ownership check or one selected application. The check accepts valid
Homebrew, Company Portal, Mac App Store, and manual installations; it does not
replace an existing externally managed application.

### 1Password public-key pinning

```bash
day-one-mac ssh-pin github
day-one-mac ssh-pin azure
day-one-mac ssh-pin both
```

Use this after the 1Password SSH agent contains the intended key. It stores
only reviewed public keys under `~/.ssh`; private keys remain in 1Password.

### macOS settings

```bash
day-one-mac macos-settings --wizard
day-one-mac macos-settings --preview
day-one-mac macos-settings --status
day-one-mac macos-settings --restore
```

The wizard is optional. Restore uses values captured before the first Day One
change; it does not guess an Apple default.

### Raycast commands and extension recommendations

```bash
day-one-mac raycast --wizard
day-one-mac raycast --preview
day-one-mac raycast --status
day-one-mac raycast --extensions
day-one-mac raycast --remove-generated
```

Use this after installing the portable `day-one-mac` command. The
wizard reads the saved hosting track and AI-client selection, then writes a
separate Script Command directory under `~/.local/share/day-one-mac/raycast`.
It does not install Store extensions or edit Raycast's private settings. See
[Use Day One Mac from Raycast](../10-app-guides/RAYCAST-COMMANDS.md).

## Projectless workspace commands

```bash
day-one-mac workspace --guided
day-one-mac workspace init
day-one-mac workspace create-task --title "Research topic" \
  --kind research --client codex --sensitivity private
day-one-mac workspace list
day-one-mac workspace status "$TASK_DIR"
day-one-mac workspace open-vscode "$TASK_DIR"
day-one-mac workspace start-codex "$TASK_DIR"
day-one-mac workspace start-claude "$TASK_DIR"
day-one-mac workspace complete "$TASK_DIR"
```

Use these only for standalone file-based work that does not belong to a Git
repository. Existing repository changes belong in a Git worktree. See
[AI workspaces](AI-WORKSPACES.md) for the folder and trust boundaries.

## Existing-Mac Stage 0 commands

### Safety report only

```bash
day-one-mac safety-report --guided
day-one-mac safety-report --plan
day-one-mac safety-report --output "/absolute/private/report-folder"
```

This is read-only apart from writing its report. It is not a backup.

### Resumable preparation dashboard

```bash
day-one-mac prepare-existing
day-one-mac prepare-existing --status
day-one-mac prepare-existing --safety-report
day-one-mac prepare-existing --dry-run
```

Use the guided dashboard for normal Route A or Route B work. Direct archive and
apply flags are documented by:

```bash
./prepare-existing-mac.sh --help
```

Do not construct a Route B apply command from memory.

## Reports, optional tools, and advanced modules

```bash
day-one-mac inventory
day-one-mac inventory --output "/absolute/path/applications.md"

day-one-mac cli-tools --list
day-one-mac cli-tools --check
day-one-mac cli-tools --packages eza,fd,lazygit --dry-run

day-one-mac databases --saved
day-one-mac databases --services postgres,redis --dry-run
day-one-mac databases --saved --check

day-one-mac advanced --list
day-one-mac advanced --status
day-one-mac advanced --module 18
day-one-mac advanced --complete 18
day-one-mac advanced --reset 18

day-one-mac advanced-audit --stdout
day-one-mac advanced-audit --check
```

The advanced tracker records documentation progress; it does not silently
implement an advanced module.

## Finalisation, rollback, and removal

These commands are deliberately preview-first:

```bash
day-one-mac finalize --status
day-one-mac finalize

day-one-mac rollback
day-one-mac remove --guided
day-one-mac remove --inventory
day-one-mac clean
```

Execution requires an explicit mode:

```bash
day-one-mac finalize --execute
day-one-mac rollback --execute
day-one-mac remove --guided --execute
day-one-mac clean --execute --archive-root "/absolute/recovery/parent"
```

Choose the narrowest tool:

| Goal | Command |
|---|---|
| Keep setup but compact evidence | `day-one-mac finalize` |
| Reverse only manifest-recorded changes | `day-one-mac rollback` |
| Select recorded changes or sections interactively | `day-one-mac remove --guided` |
| Remove all Homebrew development state with recovery options | `day-one-mac clean` |

Read [Removal and reset](../04-operations/REMOVE-DAY-ONE-MAC.md) before executing any of them.

## Script-only maintenance commands

These have no portable dispatcher word because they maintain the repository
rather than a configured Mac:

| Direct command | Purpose |
|---|---|
| `./validate-warp-drive.sh` | Validate the 63 importable Warp workflows and their safety rules. |
| `./lint.sh` | Run ShellCheck over every project shell script. Requires `shellcheck`. |
| `./lint.sh --severity warning --format gcc` | Run a narrower machine-readable lint report. |

`./validate.sh` also remains available directly and is equivalent to
`day-one-mac validate` once the portable command is installed.

Do not execute files under `scripts/lib/`; they are sourced by other scripts.
Do not use files under `scripts/tests/` as setup entry points; the validator
runs those fixtures in isolated temporary homes.

## Get exact option help

Portable examples:

```bash
day-one-mac help
day-one-mac setup --help
day-one-mac applications --help
day-one-mac raycast --help
day-one-mac workspace --help
day-one-mac remove --help
```

Direct-script examples:

```bash
./bootstrap-day-one-mac.sh --help
./configure-raycast.sh --help
./prepare-existing-mac.sh --help
./clean-development-state.sh --help
./rollback-recorded-setup.sh --help
```

The command's own `--help` output is authoritative for flags. This document is
the authoritative map between portable command names, scripts, and intended
use.

---

[← Start Here](../START-HERE.md) · [Process overview](../PROCESS-OVERVIEW.md) · [Removal and reset](../04-operations/REMOVE-DAY-ONE-MAC.md)
