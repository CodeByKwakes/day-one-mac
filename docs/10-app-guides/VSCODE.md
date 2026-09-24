[← Required apps](README.md) · **VS Code setup** · [Keyboard shortcuts](KEYBOARD-SHORTCUTS.md) · [Required Phase 7](../01-required/07-vscode-base.md)

# Set up, back up, and restore VS Code

**When:** during Phase 7 · **Required app:** yes · **Profiles and Settings Sync:** optional

**Prerequisites completed:** Phase 4 has verified VS Code's installation source;
Phase 7 owns the command-line launcher and minimal settings check.

## Outcome

VS Code opens from Finder and Terminal, uses the Day One zsh and Starship
environment, starts with a small portable configuration, and has a deliberate
backup or synchronization policy. This guide also explains how to start clean,
import an existing profile, export the new setup, and change the decision later.

## What Phase 7 already does

The Day One runner first verifies the Visual Studio Code application and
records whether Homebrew, the Mac App Store, a company portal, or a manual
installer manages it. The Installation Centre asks whether to use Homebrew or
another approved installer only when VS Code is missing; Phase 7 then checks the separate `code`
launcher. If no user settings file
exists, it creates a small baseline at:

```text
~/Library/Application Support/Code/User/settings.json
```

If that file already exists, the runner leaves it untouched. It does not sign
in, enable Settings Sync, install an extension catalogue, or create profiles.

## Step 1 — Open VS Code and install the Terminal command

1. Open **Visual Studio Code** from Applications.
2. If macOS asks whether to open an app downloaded from the internet, confirm
   only if its publisher and the owner shown by
   `day-one-mac applications --id visual-studio-code` are expected.
3. Press `⌘⇧P` to open the **Command Palette**, the searchable list of VS Code
   actions.
4. Run **Shell Command: Install 'code' command in PATH**.
5. Quit and reopen Terminal.
6. Confirm the command works:

   ```bash
   code --version
   ```

If the action says the command already exists, no change is needed.

## Step 2 — Decide whether this is a clean setup

Use one of these routes before signing in:

### Route A — Clean local setup — recommended

1. Leave Settings Sync off.
2. Complete Phase 7 so the minimal settings file exists.
3. Install extensions only when a real project needs them.
4. Create an export after Phase 8 passes.

This route prevents an old synchronized extension list or setting from
immediately repopulating the new Mac.

### Route B — Import one reviewed profile

Use this when you have a trusted `.code-profile` file:

1. Select **Manage** (the gear icon) → **Profiles**.
2. Open the profile actions menu and choose **Import Profile…**.
3. Choose the local file or paste its trusted profile URL.
4. Review the preview. Deselect settings, snippets, tasks, extensions, or MCP
   server configuration that you do not want.
5. Choose **Create** only after the preview matches the purpose of the profile.

Imported profiles do not need to become the default. Open one explicitly from
**File → New Window with Profile**.

### Route C — Restore through Settings Sync

Use this only when the remote account is the intended source of truth:

1. Select **Manage** or **Accounts** → **Backup and Sync Settings…**.
2. Sign in with the intended GitHub or Microsoft account.
3. Select only the categories you want: settings, keyboard shortcuts, snippets,
   tasks, UI state, extensions, and profiles.
4. If VS Code detects both local and remote data, read the choice carefully:

   - **Merge** combines local and remote data.
   - **Replace Local** makes the remote state win on this Mac.
   - **Merge Manually** lets you inspect conflicts and is safest when unsure.

Do not install the retired third-party **Settings Sync** extension. Current VS
Code includes its own Settings Sync feature.

## Step 3 — Apply the Day One baseline

Open the Command Palette and run **Preferences: Open User Settings (JSON)**.
The required baseline is intentionally small:

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

Why these settings are safe for a base machine:

- VS Code tidies whitespace without choosing one formatter for every language.
- Git fetches remote information but does not push or merge automatically.
- New integrated terminals use zsh, which Phase 5 configures through chezmoi.
- The Nerd Font displays Starship's symbols.
- AI tools must ask before acting globally or through the terminal.

Project-specific formatters, lint rules, TypeScript paths, and language schemas
belong in the project's `.vscode/settings.json`, not in every user's global
settings.

## Step 4 — Understand settings levels

VS Code can apply the same-looking setting at several levels:

| Level | Affects | Use it for |
|---|---|---|
| User | Every project opened by this user | Font, terminal shell, safe general behavior |
| Profile | Only windows using that profile | Work/personal separation or a content-creation tool set |
| Workspace | One saved multi-folder workspace | Settings shared across related folders |
| Folder | One repository's `.vscode/settings.json` | Framework, formatter, and test-runner choices |

When a value appears wrong, search for it in Settings and inspect the **User**,
**Workspace**, and folder tabs before changing it. A project setting can
correctly override the user value.

### Optional — show Git worktrees as separate working folders

A **Git worktree** is another checked-out branch of an existing repository. It
lets an AI client or developer work on one branch without disturbing the main
checkout. This is different from a projectless task: repository work belongs in
a worktree; standalone file-based work belongs under `~/Developer/_Projectless`.

If you use worktrees, add these reviewed settings to your user or relevant
profile settings:

```jsonc
{
  "git.detectWorktrees": true,
  "git.detectWorktreesLimit": 50
}
```

Open only the individual worktree or projectless task folder. When VS Code asks
about **Workspace Trust**, inspect that folder before trusting it; do not trust
the whole `_Projectless` parent merely for convenience.

Follow [Git worktrees with VS Code and AI clients](../03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md)
for the recommended sibling-folder layout, ignored-file handling, client
commands, review, and safe removal.

## Step 5 — Install only relevant extensions

Open a real project and check whether it contains
`.vscode/extensions.json`. Install its recommendations only after reviewing
the publisher and purpose.

Useful examples, only when the project requires them:

```bash
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension ms-python.python
code --install-extension charliermarsh.ruff
```

List exactly what is installed:

```bash
code --list-extensions --show-versions | sort
```

An extension can belong to only one profile. In the Extensions view, use
**Apply Extension to all Profiles** only when every profile truly needs it.
The optional [VS Code profiles module](../02-optional/12-vscode-profiles.md)
provides a planned multi-profile design.

If OmniRoute was selected in the Day One wizard, follow
[Optional 10A](../02-optional/10a-omniroute.md) after installing the selected AI
client. Its OmniCopilot extension adds OmniRoute models to Chat; it does not
replace GitHub Copilot's native inline-completion service.

## Step 6 — Test the integrated terminal

1. Open **Terminal → New Terminal**.
2. Confirm the shell prompt contains the Starship layout.
3. Run:

   ```bash
   echo "$SHELL"
   git --version
   chezmoi --version
   ```

4. For a Node stack, also run `node --version` and `pnpm --version`.
5. For a Python stack, also run `uv --version`.

If the shell or font is wrong, create a new terminal after changing the setting;
an already-open terminal keeps its old process and font rendering state.

## Step 7 — Review and merge chezmoi changes visually

When VS Code is the primary editor, Phase 5 configures three related commands:

```bash
chezmoi edit "$HOME/.zshrc"   # edit the source and wait for VS Code to close
chezmoi diff "$HOME/.zshrc"   # compare the live and rendered files in VS Code
chezmoi merge "$HOME/.zshrc"  # open VS Code's three-way merge editor
```

Use `diff` when you only need to inspect. Use `merge` when both the live file
and chezmoi source contain changes worth keeping. In the merge editor:

1. Review the live destination, rendered target, base copy, and source.
2. Accept only the lines you understand.
3. Save the result with `⌘S` and close the window with `⌘W`.
4. Run `chezmoi diff "$HOME/.zshrc"` again.
5. Apply only that reviewed target with `chezmoi apply "$HOME/.zshrc"`.

For text output in Terminal or a log, bypass the graphical tool explicitly:

```bash
chezmoi --use-builtin-diff diff --no-pager "$HOME/.zshrc"
```

The current Phase 5 alias baseline provides `cmdiff`, `cmdifftext`, and
`cmmerge` for the same three review paths. An existing private dotfiles source
is not force-edited just to add convenience aliases; copy the reviewed lines
from the Phase 5 guide if `day-one-mac shell-status` reports them as optional. The
automated Phase 5 gate always uses the built-in text diff so it cannot wait on
a VS Code window.

## Export and back up the configuration

### Export a portable profile — preferred

1. Open **Manage → Profiles**.
2. Select the profile you want to preserve.
3. Open its actions menu and choose **Export…**.
4. Review which parts will be exported.
5. Choose **Local file** and save the `.code-profile` file under:

   ```text
   /Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code/
   ```

VS Code can also save a profile to a GitHub secret gist. Use a local file when
the profile is private, work-managed, or not intended to leave the Mac. Some
machine-specific settings are deliberately excluded from profile exports.

### Record the extension inventory

```bash
EXPORT_DIR="/Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code"
test -d "/Volumes/<backup-volume>" || { echo "Backup volume is not mounted"; exit 1; }
mkdir -p "$EXPORT_DIR"
code --list-extensions --show-versions | sort > "$EXPORT_DIR/extensions.txt"
```

This text file is an audit. A later reinstall normally installs the current
release rather than forcing a pinned version:

```bash
cut -d@ -f1 "/Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code/extensions.txt" |
  while IFS= read -r extension; do
    test -n "$extension" && code --install-extension "$extension"
  done
```

Review the list first. Restoring every old extension can defeat the clean-start
goal.

### Back up the complete local user folder — recovery copy

Quit VS Code first, then make a private recovery copy:

```bash
EXPORT_DIR="/Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code"
test -d "/Volumes/<backup-volume>" || { echo "Backup volume is not mounted"; exit 1; }
mkdir -p "$EXPORT_DIR"
ditto "$HOME/Library/Application Support/Code/User" "$EXPORT_DIR/User"
```

This is a recovery archive, not the preferred cross-machine import method.
Restore profiles through the Profiles editor and copy individual snippets or
keybindings only after inspecting them.

## Change or clear Settings Sync later

To change what synchronizes:

1. Open **Manage → Settings Sync is On**.
2. Open **Configure** and select or clear individual categories.
3. Use **Show Synced Data** to inspect saved versions and registered machines.

To create a genuinely new cloud baseline:

1. Export the current local profile and extension inventory.
2. Select **Settings Sync is On** → **Turn Off**.
3. Select the option to clear all cloud data.
4. Verify the local Day One settings and extensions.
5. Turn Settings Sync on again and select only the desired categories.

Clearing cloud data affects other devices using that account. Do it only when
you intend to replace the shared remote state.

## Change settings later

- Open graphical settings with `⌘,` and search by plain-English keyword.
- Open the exact JSON with **Preferences: Open User Settings (JSON)**.
- Put a setting in a profile when it should not affect every type of work.
- Use **Apply Setting to all Profiles** only for a deliberately universal item.
- Run Phase 7 again after changing required safety settings; the runner verifies
  them but does not overwrite the rest of your file.

## Troubleshooting

| Symptom | What to do |
|---|---|
| `code: command not found` | Repeat Step 1 and reopen Terminal |
| Old extensions reappear | Turn off Settings Sync, remove the unwanted extensions, verify locally, then reconfigure sync |
| A formatter changes every project | Remove the global default and set it in that repository instead |
| Starship symbols are squares | Select JetBrainsMono Nerd Font and reopen the terminal |
| One profile looks different | Confirm the active profile from **Manage → Profiles** |
| `chezmoi diff` appears stuck | Close the VS Code comparison tabs; `--wait` deliberately keeps the Terminal command active during review |
| A work setting appears on a personal Mac | Sign out of the wrong sync account and review synced categories before reconnecting |

## VS Code completion checklist 🚦

- [ ] `code --version` succeeds in a new Terminal window.
- [ ] The active profile is known.
- [ ] The integrated terminal uses zsh and the Nerd Font.
- [ ] The minimal safety settings are present and the JSON is valid.
- [ ] Extensions are limited to real project needs.
- [ ] `chezmoi diff` opens VS Code and the terminal-only form prints a unified diff.
- [ ] Settings Sync is intentionally on or intentionally off.
- [ ] A reviewed `.code-profile` export and extension inventory exist privately.

Official references: [VS Code on macOS](https://code.visualstudio.com/docs/setup/mac),
[Profiles](https://code.visualstudio.com/docs/configure/profiles), and
[Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync).

---

[← Required apps](README.md) · [Return to Phase 7](../01-required/07-vscode-base.md) · [Optional profiles →](../02-optional/12-vscode-profiles.md)
