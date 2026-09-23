[← Day One Mac home](README.md) · [Complete command reference](20-reference/COMMAND-REFERENCE.md) · [Complete manual/script guide](20-reference/NOTION-SETUP-GUIDE.md) · [Whole process overview](PROCESS-OVERVIEW.md) · [Glossary](20-reference/GLOSSARY.md) · [Start Phase 1 →](01-required/01-first-boot-and-decisions.md)

# Start here

This page is the short, beginner-safe route through Day One Mac. Use it before
opening an individual phase, especially if Terminal, Git, or Homebrew is new to
you.

## What this project does

Day One Mac turns a new or factory-reset Apple-silicon Mac into a working
development computer. Intel Macs and terminals running under Rosetta are not
supported. The eight required phases and one installation checkpoint prepare
the base tools, connect the chosen code-hosting account, manage configuration
files with chezmoi, set up the Starship Terminal prompt, install the selected
programming languages, prepare VS Code, and verify that the result can be
rebuilt.

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
- your 1Password account and recovery information;
- a GitHub account, an Azure DevOps account, or both, depending on your track;
- a half day for the first complete pass, plus download and macOS-update time.

Stop if the Mac still contains the only copy of an important file. This setup
does not migrate or recover old data. If the Mac is not new or factory-reset,
start with [Stage 0 — Safely prepare an existing Mac](00-preflight/README.md). Its
wizard first shows Route A (erase with Apple) and Route B (keep the account),
then makes the read-only safety report the first step for either route.

## The shortest safe route

If you want instructions without reading every reference page first, follow
this sequence. The wizard prints the next action whenever it must pause.

1. Finish macOS Setup Assistant and install every Software Update.
2. Put this repository in the recommended location shown below.
3. Install the portable command and run `day-one-mac --wizard` once.
4. Complete the eight required phases in order. Press Return when the wizard
   offers the next phase; use `q` when you need to stop.
5. When a phase stops, read **only that phase's** printed `Guide:` path and its
   **Troubleshooting** section. Perform the displayed next action, then rerun
   the same wizard command. Completed phases remain saved.
6. Stop after Phase 8 when you need only the working development foundation.
   Databases, AI clients, MCP servers, profiles, and advanced tools are optional
   and remain available later.

Every required phase follows the same reading pattern: **Outcome** explains the
result, **How to use this phase** gives the recommended command, numbered steps
explain decisions and recovery, **Troubleshooting** covers common failures, and
the final checklist states exactly what must be true before continuing.

## Terminal basics used in this guide

**Terminal** is the macOS application in which you enter text commands. Open it
from **Applications → Utilities → Terminal** or with Spotlight.

- Copy only the text inside a code block, not the surrounding backticks.
- Paste one command block at a time and press Return.
- A command that starts with `#` is an explanation; it does not make a change.
- Text such as `<repository>` is a placeholder. Replace the complete text,
  including angle brackets, with your real value.
- When macOS asks for an administrator password in Terminal, no dots or letters
  appear while you type. This is normal. Type the password and press Return.
- `Control-C` stops the current command. Rerun the phase afterward; do not
  manually mark it complete.
- `~` means your home folder, such as `/Users/alex`.

Definitions for recurring terms such as CLI, cask, gate, manifest, and vault
are in the [plain-English glossary](20-reference/GLOSSARY.md).

## Terminal colours and symbols

Interactive Day One scripts use colour and symbols to make the next action
easier to spot. Meaning never depends on colour alone:

| Display | Meaning |
|---|---|
| green `✓` | completed successfully |
| yellow `⚠` | warning or review required |
| red `✗` or `⛔` | failed or stopped |
| blue `ℹ` | information only |
| grey `○` | pending work |
| cyan title or highlighted row | current screen or selection |
| `🔒` | required and not toggleable |

Colours are automatically removed when output is saved to a file or used by
automation. To turn colours off manually, place `NO_COLOR=1` before a command:

```bash
NO_COLOR=1 day-one-mac --status
```

The words and symbols remain, so plain output and screen readers retain the
same meaning.

## Install the standalone command

The recommended setup does not require you to keep a Git repository. It
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
install them when verification fails. The `export` affects only this Terminal
window; future login shells load the saved path automatically.

The Git clone route remains available for contributors. See
[Install and manage the standalone runtime](20-reference/PORTABLE-COMMAND.md).

## Run the recommended route

After installing the portable command above:

```bash
day-one-mac --wizard
```

The wizard explains each choice. Use Up/Down or `j`/`k` to move. On a
single-choice screen, Space or Return accepts the highlighted choice. On a
multi-choice screen, Space toggles the highlighted item and Return accepts the
whole list.

The first wizard asks only for choices needed by the eight required phases. The
eight items marked 🔒 are required, not completed. A ✓ is used only for a
phase that has passed.

The wizard also asks whether VS Code is the primary IDE. Choose **Yes** to make
Git open commit messages, diffs, and merge conflicts in VS Code. Choose **No**
to leave Git's existing editor tools unchanged; VS Code remains installed as a
small compatibility editor either way.

One optional item deliberately runs early: the
[macOS Settings Wizard](01-required/MACOS-SETTINGS.md). A checkpoint appears after Phase
1—once macOS is updated—and before Phase 2 installs development tools. Press
Enter to configure the preferences or `s` to skip them; either choice can be
changed later.

After Phase 2 installs Homebrew, the required
[Installation Centre](01-required/INSTALLATION-CENTRE.md) checks all required software in
one place. Press Enter to install every missing required item with Homebrew, or
press `r` to review items individually when Company Portal or another approved
installer must own some apps. Later phases configure and verify that software;
they do not interrupt the flow with more app installers.

After Phase 8 passes, the wizard offers **Finish and exit** first. You may
instead open the optional setup centre for databases, AI clients, MCP servers,
VS Code profiles, and other extras. Return later with
`day-one-mac optional --guided`; optional choices never block the required
setup.

The Git authentication screen offers four ways to prove your identity to
GitHub or Azure DevOps: the **1Password SSH agent** (recommended, and the only
one that keeps no private key on disk), a **macOS Keychain** key file, **your
own agent** such as Secretive or a YubiKey, or **HTTPS** with no SSH key at
all. Choose 1Password unless policy or preference rules it out;
[Phase 3 Step 3.0](01-required/03-security-and-ssh.md) compares them.

The dotfiles screen offers private Git (recommended) or a local-only chezmoi
source. Local-only means the setup does not create or require Git history or a
remote. You must protect that source with an encrypted backup because another
Mac cannot clone it.

The first screen asks what state the Mac is in. Choose **New or factory-reset**
to continue to Phase 1. Choose **Existing Mac** or **Not sure** to open Stage 0.
That wizard clearly asks for Route A or Route B before offering any action.
Both routes start with a **safety report**, which only lists current state.
Its progress dashboard stays open after each safe step, marks completed checks
with `✓`, and saves enough information to resume after an intentional exit.
For Route B it also creates a copy-only development snapshot before cleanup can
be previewed or applied.

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

The older word `preflight` means “a safety check before work begins.” You do
not need to use it as a command; `--preflight` remains only as an older alias.

## One change that needs your password

Phase 5 installs Homebrew's zsh and offers to make it your login shell. That
is the only step that uses `sudo`, and the only one that changes a macOS
account setting. It asks twice — once to add the shell to `/etc/shells`, once
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
day-one-mac --phase 03
```

Replace `03` with the phase number shown in the error. When a phase stops,
follow its **Next action** first, then use the linked phase guide for details.

## How to read each phase

Each required phase follows the same practical route, although short phases may
combine closely related explanations:

1. Read **Outcome** and **How to use this phase**.
2. Complete any clearly labelled manual batch near the beginning.
3. Follow the numbered steps in order; command blocks explain or recover the
   automated route unless the text explicitly asks you to run them.
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

The Installation Centre makes sure 1Password, its CLI, Raycast, Warp, VS Code,
and the shared Nerd Font exist before Phase 3 begins. If Company Portal, the
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
