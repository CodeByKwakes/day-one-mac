[← Day One Mac home](../README.md) · [Beginner start](../START-HERE.md) · **Required setup** · [Optional modules →](../02-optional/README.md)

# Required Day One Mac setup

This folder explains the required outcomes and their verification gates. Choose
one execution route before starting:

- **Script-assisted:** run the main wizard rather than treating every command
  block as a separate checklist:

```bash
day-one-mac --wizard
```

- **Manual:** follow [Manual 1 through Manual 8](../20-reference/MANUAL-SETUP-GUIDE.md#manual-setup-flow)
  without installing or invoking `day-one-mac`.

The runner prints the relevant guide whenever the script-assisted route needs a
shared manual action. Manual-route readers use the phase guides for context and
the complete manual flow for commands. Do not combine the routes step by step.

## Required order

| Order | Guide | Result |
|---:|---|---|
| 1 | [Phase 1 — First boot and decisions](01-first-boot-and-decisions.md) | Confirm the clean-start boundary and save track, stack, Git identity, settings, and dotfiles choices. |
| 1A | [Optional early macOS settings checkpoint](MACOS-SETTINGS.md) | Review Finder, Dock, keyboard, and trackpad preferences, or deliberately skip them. |
| 2 | [Phase 2 — Command-line foundation](02-command-line-foundation.md) | Verify Xcode Command Line Tools and native Apple-silicon Homebrew. |
| 2A | [Required Installation Centre](INSTALLATION-CENTRE.md) | Detect application ownership and provide every required app and CLI before configuration begins. |
| 3 | [Phase 3 — Security and SSH](03-security-and-ssh.md) | Configure the selected authentication route and verify FileVault. |
| 4 | [Phase 4 — Core tools and hosting](04-core-tools-and-hosting.md) | Verify core tools, create the development layout, configure Git, and authenticate hosting services. |
| 5 | [Phase 5 — Configuration, shell and prompt](05-dotfiles-and-shell.md) | Use the selected configuration owner, zsh and optional Starship; keep the launcher installer-owned. |
| 6 | [Phase 6 — Language toolchains](06-language-toolchains.md) | Configure the selected Node/npm/pnpm and/or Python/uv stack. |
| 7 | [Phase 7 — VS Code base](07-vscode-base.md) | Apply the minimal editor and integrated-terminal baseline. |
| 8 | [Phase 8 — Verify and reproduce](08-verify-and-reproduce.md) | Run all gates and record the reproducible Homebrew and dotfiles state. |

The macOS settings checkpoint is optional, but making a reviewed choice is part
of the required sequence. The Installation Centre is required because later
phases configure applications that must already exist.

## Preview, apply, check, and resume

This is an alternative to the main wizard, not an extra checklist. It is useful
when you want to see the intended effects before running a phase. Check
`day-one-mac setup --help` first: older installed releases might not yet expose
these actions. A source checkout uses `./scripts/day-one-mac` instead.

1. Preview your choices. This example selects GitHub, both language stacks,
   Keychain-backed SSH, private Git-backed dotfiles, Apple zsh, and no new prompt.
   It selects no folder layout or ghq. Replace the example
   author identity with your own; never put a password in these options.

   ```bash
   day-one-mac setup --plan --track 1 --stack both \
     --auth-mode keychain --name "Your Name" --email "you@example.com" \
     --preset recommended-productivity --primary-ide vscode \
     --new-dotfiles --dotfiles-versioning git --shell apple --prompt none \
     --layout none --ghq no --macos-settings skip
   ```

   Read the impact and manual steps for each phase. Planning saves nothing and
   does not reserve package versions. Missing configuration, shell, prompt or
   folder choices block apply; planning alone does not save or accept them.

2. When the choices are right, run the same command with `--apply` in place of
   `--plan`. Apply changes the Mac, saves your choices, and runs the existing
   phase gates. Complete any Apple installer, sign-in, key approval or GUI step
   it requests. Do not add `--yes` just to get past a question you have not read.

3. Inspect the current local prerequisites without applying configuration:

   ```bash
   day-one-mac setup --check
   ```

   `fail` identifies a missing or mismatched local prerequisite. `manual` means
   the check cannot establish the full outcome without an interactive or
   external operation. It is expected even on a previously accepted Mac. For
   example, an encrypted key on disk does not prove that GitHub accepts it.
   Checks use the current Terminal PATH and do not execute your startup files.

4. After completing a requested manual step, continue with saved choices:

   ```bash
   day-one-mac setup --resume
   ```

   Resume works at phase level, not at individual-command level. It skips only
   a phase whose saved fingerprint is current **and** whose local check returns
   `pass` or `not-required`. The current checks retain manual gates for Phases
   1–6 and Phase 8, and for Phase 7 outside the core preset, so expect those
   phases to run their existing gates again. Resume can install software or
   apply reviewed configuration; it is not another read-only check.

To limit an action, add `--phase 05` (or repeat `--phase` for several phases).
Phases 3–8 may still invoke the required Installation Centre. A full apply also
runs the settings checkpoint after Phase 1 and the Installation Centre after
Phase 2. Explicit apply runs selected phases even if previously recorded done.

Use `day-one-mac setup --status` for saved progress, not proof of current health.
The read-only check does not rewrite the Phase 8 report or completion markers.
Full acceptance still uses Phase 8 and the manual checks in its guide. See the
[action reference](../20-reference/COMMAND-REFERENCE.md#required-phase-action-contract)
for exit codes, JSON output and compatibility rules.

---

[← Beginner start](../START-HERE.md) · [Begin Phase 1 →](01-first-boot-and-decisions.md)
