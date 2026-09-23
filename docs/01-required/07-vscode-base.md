[← Phase 6](06-language-toolchains.md) · **Phase 7** · [Phase 8 →](08-verify-and-reproduce.md)

# Phase 7 — VS Code base

**Time:** 20–35 minutes · **Required:** everyone

## Outcome

VS Code opens from Terminal, uses zsh and the Nerd Font, and starts with a small
portable settings file. Extension lists, AI clients, Settings Sync, and
separate profiles remain deliberate optional choices.

VS Code is still verified when another primary IDE was selected. The Phase 1
choice controls only whether Git uses VS Code for commit messages, visual diffs
and merge conflicts; it does not control whether this compatibility editor is
installed.

## How to use this phase

Run `day-one-mac setup --phase 07`. The runner creates the minimal
settings file only when none exists; it does not overwrite an existing file.
Use the reference steps below to review an existing setup or fix the `code`
launcher. Profiles and large extension sets are not part of this required gate.

For the complete first-launch, settings-level, selective import, export,
Settings Sync, clean-cloud reset, and later-change procedure, keep the
[detailed VS Code application guide](../10-app-guides/VSCODE.md) open alongside this
phase. This phase remains the concise required gate; the application guide
explains every manual decision.

## Step 7.1 — Confirm the installation

Phase 4 verified a valid VS Code application. It may be Homebrew-managed or
supplied by Company Portal, the Mac App Store, or another approved installer.
Check its recorded owner, then verify the command-line launcher:

```bash
day-one-mac applications --id visual-studio-code
code --version
```

An **External installation** result is valid and does not need to be converted
to Homebrew. The `code` command is a separate gate because a graphical VS Code
installation may not have enabled its Terminal launcher yet.

If the app opens but `code` is missing:

1. Open VS Code.
2. Press `⌘⇧P`.
3. Run **Shell Command: Install 'code' command in PATH**.
4. Close and reopen Terminal.
5. Run `code --version` again.

## Step 7.2 — Understand existing settings behavior

The runner writes the base settings only when this file does not exist:

```text
~/Library/Application Support/Code/User/settings.json
```

If settings already exist, they are preserved. Compare them with the baseline
below and merge intentionally. The setup never replaces a user-owned editor
configuration.

This path belongs to VS Code's **Default** profile. If VS Code shows another
profile name, run **Preferences: Open User Settings (JSON)** while that profile
is active and review its separate settings. Do not assume changing the Default
profile changes another profile.

Before a manual replacement, create a local backup:

```bash
SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
cp "$SETTINGS" "$SETTINGS.before-day-one-mac" 2>/dev/null || true
```

## Step 7.3 — Use the minimal settings baseline

Open **Preferences: Open User Settings (JSON)**.

If the file is empty or contains only `{}`, paste the whole block below. If it
already contains settings, **merge** these keys into the existing `{ ... }`
rather than replacing the file — copy the individual lines in, and make sure
every line except the last ends with a comma.

```jsonc
{
  "editor.formatOnSave": true,
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "git.autofetch": true,
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'",
  "chat.tools.global.autoApprove": false,
  "chat.tools.terminal.enableAutoApprove": false
}
```

Why this stays small:

- Formatting behavior is predictable without selecting a global formatter.
- Git fetches metadata but does not push or merge automatically.
- Integrated terminals use the shell configured in Phases 5–6.
- Starship symbols render through the installed Nerd Font.
- AI tools cannot globally or terminal-auto-approve actions if enabled later.

The nested quotes in `terminal.integrated.fontFamily` are deliberate: the outer
double quotes are JSON, and the inner single quotes are what the font setting
itself needs around a name containing spaces. Note also that the family name is
`JetBrainsMono` with no space, followed by ` Nerd Font`.

A project can override settings in `.vscode/settings.json` without making every
workspace inherit framework-specific choices.

## Step 7.4 — Keep extensions project-driven

Do not install a large public catalogue on day one. Start with a real project,
read its `.vscode/extensions.json`, and install only relevant recommendations.

Common examples:

| Project type | Consider only when used |
|---|---|
| JavaScript/TypeScript | ESLint (`dbaeumer.vscode-eslint`), Prettier (`esbenp.prettier-vscode`) |
| Python | Python (`ms-python.python`), Ruff (`charliermarsh.ruff`) |
| Containers | Container Tools (`ms-azuretools.vscode-containers`) |
| Azure pipelines 🏢 | Azure Pipelines (`ms-azure-devops.azure-pipelines`) |

Install an individual extension:

```bash
# Install in the currently active/default profile.
code --install-extension dbaeumer.vscode-eslint

# Install in one named profile without adding it to every profile.
code --profile "Tech Content Creator" \
  --install-extension esbenp.prettier-vscode
```

When profiles exist, always name the intended profile or install from that
profile's Extensions view. Otherwise it is easy to assume an extension is
global when it belongs only to the active profile.

Review installed extensions:

```bash
code --list-extensions --show-versions | sort
```

Current VS Code already includes Copilot Chat, so do not install the old
standalone Copilot Chat extension separately. Signing in to Copilot and using
any AI feature remain optional.

## Step 7.5 — Decide about Settings Sync

Settings Sync is optional. Before enabling it:

1. Confirm whether the account is personal or work-owned.
2. Export or back up the current profile.
3. Review which categories—settings, extensions, profiles, keybindings, UI
   state—should synchronize.
4. Resolve conflicts on one machine before enabling another.

For the clean base, leaving Sync off until Phase 8 completes is safest.

## Step 7.6 — Run or resume the phase

```bash
day-one-mac setup --phase 07
```

The runner creates the parent directories and base settings only when absent.
It verifies the VS Code CLI and that both tool-auto-approval settings remain
false.

## Step 7.7 — Smoke test the editor

```bash
mkdir -p ~/Developer/_sandbox/editor-check
code ~/Developer/_sandbox/editor-check
```

In VS Code:

1. Create and save `README.md`.
2. Open **Terminal → New Terminal**.
3. Confirm the shell is zsh and the Starship prompt renders.
4. Run `git --version`, `chezmoi --version`, and the selected runtime command.
5. Close the folder without installing unrelated extensions.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| `code: command not found` | Install the shell command from the Command Palette and reopen Terminal |
| VS Code is ready but reported as external | No repair is needed; keep using Company Portal, the App Store, or the existing owner for updates |
| Prompt symbols render as squares | Confirm the cask exists and the terminal font setting uses JetBrainsMono Nerd Font |
| VS Code starts bash instead of zsh | Check `terminal.integrated.defaultProfile.osx` and create a new terminal |
| Settings JSON is invalid | Use **Preferences: Open User Settings (JSON)** and fix the highlighted syntax |
| An extension changes every project's formatter | Remove the global default and put the formatter in project settings |
| Settings Sync restores old extensions | Turn Sync off, remove unwanted state, verify locally, then choose what to sync |

## Phase 7 completion checklist 🚦

- [ ] `code --version` succeeds from a new terminal.
- [ ] `day-one-mac applications --id visual-studio-code` reports the application ready and shows its owner.
- [ ] The base settings JSON parses without warnings.
- [ ] Both tool-auto-approval settings are false.
- [ ] The integrated terminal opens zsh and renders Starship.
- [ ] No literal token or machine-specific secret exists in settings.
- [ ] Extensions are limited to current project needs.
- [ ] No VS Code profile or Settings Sync account is required to pass.

Reference: [VS Code on macOS](https://code.visualstudio.com/docs/setup/mac) and
[Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync).
See also the [full Day One VS Code setup guide](../10-app-guides/VSCODE.md).

---

[← Phase 6](06-language-toolchains.md) · [Continue to Phase 8 →](08-verify-and-reproduce.md)
