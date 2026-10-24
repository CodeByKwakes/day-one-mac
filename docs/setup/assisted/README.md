# Scripted (Assisted) Setup

Use the standalone `day-one-mac` command to perform resumable setup with reviewed
choices and recorded ownership. Complete the [shared prerequisites](../../shared/prerequisites.md)
and [decision worksheet](../../shared/decisions.md) first. A Git checkout is not
required. Managed devices follow the approved IT policy and elevation process.

## 1. Install the standalone runtime

Follow the complete [runtime installation task](runtime.md), then return here.

Expected result: `day-one-mac --version` reports the installed runtime. Source
features are not necessarily in that release; check help before using a new command.

## 2. Prepare an existing Mac when needed

If the Mac contains data or settings, complete the
[existing-Mac preparation](existing-mac/README.md) first. A new or factory-reset
Mac can continue. The safety report does not copy or recover data.

Expected result: the selected starting boundary and independent backup are verified.

## Optional AI preparation before Phase 1

Use the [AI setup checkpoint](ai-setup-assistant.md) to choose no AI, guidance
only or approved execution with one client. The wizard offers this choice on
first entry into required setup. Client sign-in and tool checks remain manual.
The AI choice is saved separately from required configuration choices.

## 3. Preview the setup

```bash
day-one-mac --wizard --dry-run
```

Expected result: a proposed plan without configuration changes. Review device
ownership, software preset, hosting, authentication, language, folder and shell
choices. Unselected optional software is not a prerequisite.

## 4. Start or resume the wizard

```bash
day-one-mac --wizard
```

Choose **Start or resume required setup**. Use Up/Down or `j`/`k` to move,
Enter/Space to select, `b` or Left Arrow to go back, and `q` to stop. At text
prompts use `:back`. Accepted choices remain in memory until the review screen.
`NO_COLOR=1` disables colours; `DAY_ONE_MAC_ASCII=1` uses plain symbols.

Expected result: choices are reviewed before being saved, and the current phase
reports its result or an explicit next action.

## Required sequence

| Order | Guide | Expected outcome |
|---|---|---|
| Optional checkpoint | [AI setup assistant](ai-setup-assistant.md) | Intentional skip or verified selected client |
| Phase 1 | [First boot and decisions](01-first-boot-and-decisions.md) | Approved starting boundary and saved selections |
| Optional checkpoint | [macOS settings](MACOS-SETTINGS.md) | Selected personal preferences or an intentional skip |
| Phase 2 | [Command-line foundation](02-command-line-foundation.md) | Native Apple tools and Homebrew |
| Required checkpoint | [Installation Centre](INSTALLATION-CENTRE.md) | Selected software present with understood ownership |
| Phase 3 | [Security and SSH](03-security-and-ssh.md) | Selected authentication and required encryption checks |
| Phase 4 | [Core tools and hosting](04-core-tools-and-hosting.md) | Git identity, layout and repository access |
| Phase 5 | [Configuration and shell](05-dotfiles-and-shell.md) | Selected owner, Zsh and prompt verified |
| Phase 6 | [Languages](06-language-toolchains.md) | Selected runtimes available in a new shell |
| Phase 7 | [VS Code base](07-vscode-base.md) | Selected editor baseline, or the core preset's deliberate skip |
| Phase 8 | [Verify and reproduce](08-verify-and-reproduce.md) | Current checks and recovery evidence |

The wizard handles the full sequence. Running one phase directly does not run
its prerequisites or the Installation Centre. When directed to a shared manual
action, do only that action and return to the stopped phase.

## 5. Inspect or resume after a pause

Run `day-one-mac --status`.

Expected result: completed, stale and remaining work are distinguished. Follow
the printed next action; then rerun the wizard or the named phase, for example
`day-one-mac setup --phase 03`. Do not fabricate a marker or delete state to
clear a failed check.

## 6. Verify completion

Open the Phase 8 report and complete the
[shared acceptance checks](../../shared/verification.md). For managed evidence,
use the [readiness reference](reference/workstation-readiness.md).

Expected result: selected checks pass with current evidence. Package fixtures do
not prove a real managed-device pilot, application login or database restore.

## Optional next steps

Use [optional operations](optional/README.md) or [advanced operations](advanced/README.md)
only when a project needs them. Profiles and workspaces have dedicated commands;
retired Module 12 remains retired. Human application setup lives in the
[manual application tasks](../manual/apps/README.md).

## Troubleshooting and recovery

Use the phase's next action and [symptom index](../../shared/troubleshooting.md).
Keep setup state while relying on recorded recovery. Read
[recovery and removal](recovery/README.md) before deleting state or undoing work;
preview and confirm the precisely scoped operation first.

## Previously published section links

These entries preserve bookmarks from the previous structure. Each points to the current task; follow the main guide above for the normal sequence.

## Required Day One Mac setup

Continue with the [current guide](README.md).

## Required order

Continue with the [current guide](README.md).

## Preview, apply, check, and resume

Continue with the [current guide](README.md).
