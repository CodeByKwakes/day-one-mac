[← Day One Mac home](../README.md) · [Beginner start](../START-HERE.md) · **Required setup** · [Optional modules →](../02-optional/README.md)

# Required Day One Mac setup

This folder explains the required outcomes and their verification gates. Choose
one execution route before starting:

- **Script-assisted:** run the main wizard rather than treating every command
  block as a separate checklist:

```bash
day-one-mac --wizard
```

- **Manual:** follow [Manual 1 through Manual 8](../20-reference/NOTION-SETUP-GUIDE.md#manual-setup-flow)
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
| 5 | [Phase 5 — Dotfiles and shell](05-dotfiles-and-shell.md) | Configure chezmoi, zsh and Starship while keeping the standalone launcher under runtime ownership. |
| 6 | [Phase 6 — Language toolchains](06-language-toolchains.md) | Configure the selected Node/npm/pnpm and/or Python/uv stack. |
| 7 | [Phase 7 — VS Code base](07-vscode-base.md) | Apply the minimal editor and integrated-terminal baseline. |
| 8 | [Phase 8 — Verify and reproduce](08-verify-and-reproduce.md) | Run all gates and record the reproducible Homebrew and dotfiles state. |

The macOS settings checkpoint is optional, but making a reviewed choice is part
of the required sequence. The Installation Centre is required because later
phases configure applications that must already exist.

---

[← Beginner start](../START-HERE.md) · [Begin Phase 1 →](01-first-boot-and-decisions.md)
