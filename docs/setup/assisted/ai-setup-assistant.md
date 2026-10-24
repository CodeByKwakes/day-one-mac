# Choose optional AI assistance before Phase 1

Use this checkpoint if a client should help with the whole setup. It prepares
one selected client and a private task folder before required setup begins.
Choose no AI to continue normally. Additional clients, AI workspaces and MCP
remain optional work after the base; [Module 10](optional/10-ai-agents.md)
retains its Phase 8 prerequisite.

## Prerequisites and scope

Complete the [shared prerequisites](../../shared/prerequisites.md), device-policy
check and any [existing-Mac preparation](existing-mac/README.md) first. Before a
planned reset, use browser guidance rather than installing tools into the old
account. Install the [public runtime](runtime.md) when the assisted route is
permitted. No permanent Git checkout, Homebrew or Node installation is needed
for this checkpoint's native CLI installers.

Run `day-one-mac ai-setup --help`. Expected result: the options below. If the
installed release does not have this command, use the
[manual AI preparation](../manual/ai/setup-assistant.md) and return here after
verification. Source documentation can precede a public release.

## 1. Preview the checkpoint

```bash
day-one-mac ai-setup --plan
```

Expected result: available choices or a saved selection. Preview and check
create no state, download nothing and do not launch client processes.

| Mode | Client | Apply behaviour | Account/tool verification |
|---|---|---|---|
| `none` | None | Saves an intentional skip | Not needed |
| `guide` | `existing` app/browser, `codex` or `claude` | Prepares instructions; you execute setup commands | Manual |
| `execute` | `codex` or `claude` | Prepares instructions for approved local execution | Manual; never implied by a saved choice |

An approved desktop client can use the generated task folder. The CLI's
`existing` selection represents guidance only; it cannot verify that app's
execution tools.

## 2. Choose or reuse one client

```bash
day-one-mac ai-setup
```

Expected result: a menu offers **Continue without AI**, **AI guidance only** or
**AI-assisted execution**. Choose a client only when needed. A recognised CLI
is reused and its version command is checked with a timeout. Existing personal
configuration is preserved. A dangling link, non-executable file or directory
at the native client path stops installation and names the path for recovery.

For a missing CLI, the menu offers native installation. Review the URL and
confirm the download, read the script, then confirm execution separately.
Installation uses the same downloaded file only if it is unchanged after
review. A failed download or cancelled review does not run the installer.
Vendor installers can perform further downloads and own their resulting files.
A partially failed vendor installation needs that vendor's recovery procedure.

Expected result: an intentional skip or a printed private handoff folder.
Installation and sign-in remain separate. Continue without AI if policy,
network access, account access or cost prevents using the selected client.

## 3. Complete sign-in and verify the handoff

Open the printed folder in the selected client. It contains:

```text
AGENTS.md
CLAUDE.md
.agents/skills/day-one-mac-assistant/SKILL.md
```

`AGENTS.md` records the assisted route, selected mode and installed documentation
location. `CLAUDE.md` imports it. Explicitly attach/read the skill if the client
does not discover it automatically. Follow the
[manual sign-in and tool verification](../manual/ai/setup-assistant.md#3-verify-the-executable-and-sign-in),
reusing this generated folder and skipping creation of replacement instructions.

Expected result: the intended account responds, the client reads the correct
route and it can perform only the harmless approved command test. Handoff files
do not grant execution permission or prove billing, authentication or tool access.

## 4. Continue the required setup

Return to the terminal prompt and choose to continue, or pause there and use
the verified client. In guidance mode, you execute each reviewed command.
For client execution, first request a read-only plan:

```text
Read the handoff and setup skill. Inspect the installed command's help and
plan the required setup with my selected choices. Do not apply changes yet.
List the exact next command, prerequisites, expected result and recovery.
```

Expected result: a concrete next action for review. Approve only that scope.
Keep one writer at a time: do not run the wizard while an AI client applies
another setup operation. The runtime also serializes its own mutations.

The full wizard includes required human checkpoints. A client running individual
`setup --phase` commands must follow each phase's prerequisites and manual
handoffs; it cannot replace the Installation Centre or mark manual checks done.
Use `day-one-mac setup --status --json` to inspect saved evidence and available
live checks. Completion records alone are not workstation acceptance.

## 5. Revisit or inspect the choice

The wizard's **Start or resume required setup** presents this checkpoint before
its required configuration questions when no choice is saved. **Other actions →
AI setup assistant** revisits it. A saved choice is reused; it does not block
the required route if the account later becomes unavailable. Direct
`day-one-mac setup` remains usable without this optional choice.

```bash
day-one-mac ai-setup --check
```

Expected result: `none` reports an intentional skip; a selected CLI reports
executable presence. `existing` requires manual verification. This command
never tests account status or runs the client.

## Command reference

| Option | Default / accepted values | Usage |
|---|---|---|
| No options | Interactive menu | Choose/revisit assistance |
| `--plan` | Saved choice, or available choices | Read-only inspection; accepts explicit mode/client |
| `--check` | Saved choice | Inspect choice and executable presence; explicit choices also accepted |
| `--apply` | Saved choice, or explicit mode/client | Save selection and create a private handoff; does not launch an agent |
| `--mode` | `none`, `guide`, `execute` | Use with one action |
| `--client` | `codex`, `claude`, `existing` | Required for guide/execute; `existing` supports guide only |
| `--install` | Off | With apply, review a missing CLI installer in an interactive terminal |
| `--help`, `-h` | None | Show usage without changes |

Examples for existing clients, run only the selected action:

```bash
day-one-mac ai-setup --plan --mode execute --client codex
day-one-mac ai-setup --apply --mode execute --client codex
day-one-mac ai-setup --apply --mode guide --client existing
day-one-mac ai-setup --apply --mode none
```

To request a missing Claude Code installation, use
`day-one-mac ai-setup --apply --mode execute --client claude --install` in an
interactive terminal. `--install` is never implied by apply alone.

| Exit status | Meaning | Next action |
|---|---|---|
| `0` | Requested inspection/apply completed | Perform remaining manual checks |
| `1` | State, catalogue, download, install or version check failed | Inspect the exact error and retained files |
| `2` | Invalid options or unsupported execution platform | Correct the choice/platform |
| `10` | Missing selection/client, manual check or declined install | Resolve it or choose no AI |
| `20` | Interactive checkpoint paused/back | Resume later or choose no AI |

## State and recovery

The default private state is `~/.day-one-mac/ai-setup`. The configured state-root
override also applies. It contains `selection.tsv`, a `current` handoff basename,
and separate `handoff.*`, `installer.*` or `version.*` directories when needed.
Each apply with assistance creates a new handoff and preserves earlier ones.
A no-AI choice preserves earlier handoffs but does not use them. No required
phase marker is written. Client account history stays in its own storage.

To disable assistance, apply `--mode none`. Keep diagnostic files while resolving
a failure. Inspect and archive exact obsolete task folders later; do not delete
the entire setup state. Removing a handoff does not uninstall a client. Native
clients retain their vendor update/removal owner, including when Module 10 later
finds them. Use [client maintenance](../manual/ai/clients.md#7-verification-and-removal)
for the selected owner.

## Optional integration and acceptance

The packaged [setup skill](../../../templates/ai-setup-assistant/SKILL.md) can be
read by another approved client. Keep adapters small and use its permission
controls. Additional [MCP](../manual/ai/mcp.md) and
[skills](../manual/ai/instructions-agents-skills.md) are optional; they do not
belong in the minimum bootstrap.

A launcher can open this checkpoint and the reviewable next command. “Approve
and run” means applying that reviewed operation with its existing confirmation,
not approving every future command. Automated CI can validate packages and
fixtures; it cannot perform a person's sign-in, licence acceptance or recovery
check. Finish with [shared workstation verification](../../shared/verification.md).
