[← Day One Mac home](README.md) · [Complete command reference](20-reference/COMMAND-REFERENCE.md) · [Manual and script-assisted routes](20-reference/MANUAL-SETUP-GUIDE.md) · [Whole process overview](PROCESS-OVERVIEW.md) · [Glossary](20-reference/GLOSSARY.md) · [Start Phase 1 →](01-required/01-first-boot-and-decisions.md)

# Start here

This page is the short, beginner-safe route through Day One Mac. Use it before
opening an individual phase, especially if Terminal, Git, or Homebrew is new to
you.

## What this project does

Day One Mac turns a new or factory-reset Apple-silicon Mac into a working
development computer. Intel Macs and terminals running under Rosetta are not
supported. The eight required phases and one installation checkpoint prepare
the base tools, connect the chosen code-hosting account, manage configuration
files with your selected owner, optionally set up the Starship prompt, install the selected
programming languages, prepare VS Code, and verify that the result can be
rebuilt.

The developer-folder pilot now offers [four layouts with optional ghq](manual/developer-folders.md).
The wizard collects these choices separately; ghq is not preselected. Existing
setups must review them before resuming affected phases. Non-interactive setup
must supply `--layout none|repository|purpose|existing` and `--ghq no|yes`, or
have saved choices. Configuration ownership, shell, and prompt are also
independent choices: see [Phase 5 choices](01-required/05-dotfiles-and-shell.md#choose-ownership-shell-and-prompt-first).
Fresh direct runs must supply `--dotfiles-versioning none|local|git`,
`--shell keep|apple|homebrew`, and `--prompt none|starship`. Preset, editor, and
language defaults outside this slice are unchanged.

The setup is resumable. A phase receives a ✓ only after its checks pass. If a
phase stops, earlier completed phases stay saved and the screen explains what
is complete, what remains, and what to do next.

For a one-page map of Stage 0, every required phase, optional modules, advanced
setup, saved state, and rollback, read the [whole process overview](PROCESS-OVERVIEW.md).

## Before you begin

You need:

- an Apple-silicon Mac running natively as `arm64`;
- a Mac administrator account whose password you know;
- power and a reliable internet connection;
- at least 30 GB of free storage for the required base; full Xcode, container
  images, databases, AI models, and project dependencies need additional space;
- a separate, readable backup of anything you need from the old Mac;
- credentials and recovery information for the selected Git authentication
  mode; 1Password details are needed only in `1password` mode;
- a GitHub account, an Azure DevOps account, or both, depending on your track;
- a half day for the first complete pass, plus download and macOS-update time.

Stop if the Mac still contains the only copy of an important file. This setup
does not migrate or recover old data. If the Mac is not new or factory-reset,
start with [Stage 0 — Safely prepare an existing Mac](00-preflight/README.md). Its
wizard first shows Route A (erase with Apple) and Route B (keep the account),
then makes the read-only safety report the first step for either route.

## Choose one setup route

Choose once and stay on that route unless a troubleshooting instruction tells
you to switch. Both routes include shared manual actions that macOS or an
account provider requires you to approve.

### Script-assisted route — recommended

Use this route when local policy allows the Day One Mac scripts and you want
resumable phases, saved verification, and recorded ownership.

1. Finish macOS Setup Assistant and install every Software Update.
2. Install the standalone command as shown below. A repository checkout is not
   required.
3. Run `day-one-mac --wizard` once.
4. Complete the eight required phases in order. Press Return when the wizard
   offers the next phase; use `q` when you need to stop.
5. When a phase stops, read **only that phase's** printed `Guide:` path and its
   **Troubleshooting** section. Perform the displayed next action, then rerun
   the same wizard command. Completed phases remain saved.
6. Stop after Phase 8 when you need only the working development foundation.
   Databases, AI clients, MCP servers, profiles, and advanced tools are optional
   and remain available later.

### Manual route — no Day One Mac scripts

Use this route when policy prohibits the project scripts or when you want to
perform and record every underlying change yourself. Do not install the
standalone runtime. Follow the [complete manual setup flow](20-reference/MANUAL-SETUP-GUIDE.md#manual-setup-flow)
from Manual 1 through Manual 8, including every checkpoint. The manual route
does not create phase markers, ownership manifests, or precise automated
rollback evidence, so keep your own completion record.

Every required phase follows the same reading pattern: **Outcome** explains the
result, **How to use this phase** gives the recommended command, numbered steps
explain decisions and recovery, **Troubleshooting** covers common failures, and
the final checklist states exactly what must be true before continuing.

## Terminal basics used in this guide

New to Terminal? Read [Terminal basics](20-reference/TERMINAL-BASICS.md) before
copying commands. It explains passwords, placeholders, stopping commands, and
colour-independent status symbols.

## Terminal colours and symbols

A ✓ means a check passed; ⚠ means review is needed. See the
[full symbol reference](20-reference/TERMINAL-BASICS.md#terminal-colours-and-symbols).

## Install the standalone command for the script-assisted route

Skip this section if you chose the manual route. The script-assisted setup does
not require you to keep a Git repository. It
installs a checksum-verified runtime under your home folder.

On a factory-reset Mac, first ask macOS to install the Apple command-line
tools:

```bash
xcode-select --install
```

Wait for the installer window to finish. Then download the public installer:

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

Read the file in `less`, then press `q` before running it. The installer
downloads a release archive and its SHA-256 checksum separately and refuses to
install them when verification fails. A checksum detects corruption; it does
not independently prove who published the download. See
[release trust and optional provenance checks](20-reference/PORTABLE-COMMAND.md#release-trust-and-provenance).
The `export` affects only this Terminal
window; future login shells load the saved path automatically.

The Git clone route remains available for contributors. See
[Install and manage the standalone runtime](20-reference/PORTABLE-COMMAND.md).

## Run the recommended route

After installing the portable command above:

```bash
day-one-mac --wizard
```

Use Up/Down or `j`/`k` to move, Space to select, and Return to continue.
The wizard reviews all choices before saving them.

Choose a software preset:

- **Recommended productivity** (the existing default): includes VS Code,
  Raycast, Warp, and the Nerd Font alongside the command-line foundation.
- **Core**: skips those desktop applications and Phase 7 editor configuration.
  Authentication, shell, language tools, and Phase 8 verification still apply.
  1Password and its CLI are required only with 1Password authentication.

For the productivity preset, the editor question controls **Git and chezmoi
integration**, not whether VS Code is installed. Core leaves existing editor
settings alone. To change presets later, review the wizard choices again;
switching to core does not uninstall previously installed applications.

Choose your hosting account, language stack, Git identity, authentication mode,
and dotfiles protection. Private Git provides a remote copy; local-only
chezmoi needs an encrypted backup. Compare authentication modes in
[Phase 3](01-required/03-security-and-ssh.md).

Follow this sequence:

1. Phase 1 confirms your decisions and backup boundary.
2. Configure or skip the optional macOS preferences checkpoint.
3. Phase 2 prepares Homebrew; the Installation Centre then checks the selected
   software and preserves valid company-managed or externally installed apps.
4. Phases 3–7 configure authentication, hosting, dotfiles, languages, and the
   selected editor baseline. Complete manual approvals when prompted.
5. Phase 8 verifies the result. Choose **Finish and exit**; extras remain
   available through `day-one-mac optional --guided`.

Read [the whole process](PROCESS-OVERVIEW.md) only when you need the detailed
map; you do not need to repeat phase reference commands after the runner passes.

## Understand preview and apply

Use a preview when you want to see commands without changing the Mac:

```bash
day-one-mac --wizard --dry-run
```

`--dry-run` means preview only. The normal wizard performs the approved work.
Cleanup tools use the word `--execute` for their separate destructive action;
they never erase or format the drive.

For an existing Mac, use this one guided command:

```bash
day-one-mac prepare-existing --guided
```

To create only the read-only safety report, use:

```bash
day-one-mac safety-report --guided
```

Use the current command names shown above. Upgrade-only aliases and retired
state names are documented separately in
[Upgrade notes](20-reference/UPGRADE-NOTES.md), so a first-time setup does not
need to learn them.

## One change that needs your password

Phase 5 installs Homebrew's zsh and offers to make it your login shell. This
step asks twice — once to add the shell to `/etc/shells`, once
to switch. Declining leaves your shell untouched and stops Phase 5 safely as
incomplete; the phase passes only when Directory Services confirms Homebrew
zsh.

If it is ever broken, recover from any working shell with:

```bash
chsh -s /bin/zsh
```

## Stop, resume, and get help

It is safe to quit between phases. To see the current state:

```bash
day-one-mac --status
```

To retry one phase:

```bash
day-one-mac setup --phase 03
```

Replace `03` with the phase number shown in the error. When a phase stops,
follow its **Next action** first, then use the linked phase guide for details.

## How to read each phase

Each required phase follows the same practical route, although short phases may
combine closely related explanations:

1. Read **Outcome** and **How to use this phase**.
2. Complete any clearly labelled manual batch near the beginning.
3. Follow the numbered steps in order; command blocks explain or recover the
   script-assisted route unless the text explicitly asks you to run them.
4. If a gate stops, use **Troubleshooting** and the terminal's **Next action**.
5. Continue only when the phase completion checklist is true.

Reference commands in a phase explain or diagnose the automation; they are not
a second checklist that must be repeated after the runner succeeds.

The early command installer makes `day-one-mac` available immediately without
a permanent clone. The standalone runtime remains its sole owner; Phase 5
keeps it out of chezmoi and safely migrates older managed copies. If the
portable command is unavailable, run
the matching script from this repository. The
[complete command reference](20-reference/COMMAND-REFERENCE.md) shows both forms and when to
use every setup, report, workspace, finalisation, rollback, and removal command.

## Set up the required applications

The Installation Centre checks software required by your preset and authentication
mode before Phase 3 begins. If Company Portal, the
Mac App Store, or another approved installer already supplied a valid copy, the runner
keeps it and reports that Homebrew does not own it. Only missing applications
trigger a choice: install with Homebrew, use another approved installer and
recheck, or stop safely and resume later.

Open the [required application setup hub](10-app-guides/README.md) after Phase 4.
It gives a beginner-safe order and full setup, settings, import, export, backup,
and later-change instructions for each app. Complete the VS Code guide alongside
Phase 7. Optional extensions, AI features, profiles, and Warp Drive imports do
not block the required setup.

Read [Application ownership](20-reference/APPLICATION-OWNERSHIP.md) if this is a managed
work Mac or if you want to understand what rollback can remove.

## After Phase 8

The base Mac is complete. Add only optional modules a real project needs.
Databases, AI clients, the OmniRoute AI gateway, Model Context Protocol (MCP)
servers, VS Code profiles, enhanced Terminal tools, Warp Drive workflows,
advanced modules, and the Second Brain are not required for a successful base
setup. OmniRoute and MCP can be selected only with at least one AI client; see
the saved wizard review for the clients you chose.

You may now compact the retained setup records while keeping status, restore,
and rollback support. Preview this optional action first:

```bash
day-one-mac finalize
```

Read [Finalise or detach Day One Mac](04-operations/FINALIZE.md) before executing it or
removing `~/.day-one-mac`. Deleting that folder manually would discard
ownership manifests, captured originals, and settings-restore evidence.

---

[Command reference](20-reference/COMMAND-REFERENCE.md) · [Glossary](20-reference/GLOSSARY.md) · [Start Phase 1 →](01-required/01-first-boot-and-decisions.md)
