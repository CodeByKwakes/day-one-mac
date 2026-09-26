[← Raycast setup](RAYCAST.md) · **Day One command pack** · [AI providers](RAYCAST-AI-PROVIDERS.md) · [Keyboard shortcuts](KEYBOARD-SHORTCUTS.md)

# Use Day One Mac from Raycast

**When:** after the required base setup · **Required:** no · **Changes made:** one managed Script
Command directory only

This optional command pack turns safe Day One Mac checks, documentation and AI
workspace actions into searchable Raycast commands. It reads the hosting track
and AI clients already selected by the setup wizard. It does not install Store
extensions, edit Raycast's private database or add an `--execute` cleanup.

## Before you start

Complete the required base setup and verify the portable command:

```bash
command -v day-one-mac
day-one-mac root
```

The generated commands live here:

```text
~/.local/share/day-one-mac/raycast
```

That directory is deliberately separate from personal Script Commands. Day One
Mac replaces only a directory containing its management marker and archives the
previous generated version before a refresh.

## Choose a command setup route

Both routes use Raycast's supported Script Commands feature and end with the
same visible commands. Do not mix the two directories.

| Route | Use it when | Directory |
|---|---|---|
| Generated — recommended | Commands should follow the saved hosting track and AI choices automatically | `~/.local/share/day-one-mac/raycast` |
| Manual | You want to create and maintain each script yourself | `~/.local/share/day-one-mac/raycast-manual` |

The generated directory is owned by the Day One manager. Never store personal
scripts there: a refresh may archive and replace it. The manual directory is
never changed by `day-one-mac raycast`.

## Route A — Generate the command pack

Recommended interactive route:

```bash
day-one-mac raycast --wizard
```

Use Space to toggle groups, then review the complete command list before
writing it. The defaults include health checks, documentation, selected AI
clients and the saved hosting track. Cleanup previews and the Second Brain
launcher are off by default.

Useful alternatives:

```bash
day-one-mac raycast --preview
day-one-mac raycast --status
day-one-mac raycast --extensions
day-one-mac raycast --launcher-mode alongside-spotlight --preview
day-one-mac raycast --launcher-mode raycast-only --preview
day-one-mac raycast --groups core,documentation,ai,hosting --apply
```

The wizard asks for launcher behaviour before command groups. Both choices keep
Raycast Root Search on `⌥Space`. The recommended alongside choice keeps
Spotlight Search on `⌘Space`; the Raycast-only choice leaves `⌘Space`
unassigned. Shortcut changes are manual and Spotlight indexing stays enabled.

The direct script form is available only for contributor troubleshooting:

```bash
cd "$(day-one-mac root)/scripts"
./configure-raycast.sh --preview
```

Applying requires the portable dispatcher installed by the early command
installer. This prevents generated commands from depending on a personal clone
path.

If `day-one-mac raycast` is reported as an unknown command,
update the standalone runtime and verify it:

```bash
day-one-mac update
day-one-mac runtime-status
```

Contributors can also run `./configure-raycast.sh --wizard` directly from the
active runtime or a linked source checkout; generated commands still require
the portable launcher.

## Route B — Create Script Commands manually

Use this route to understand and control every file. It still calls the
portable `day-one-mac` command installed at the start; it simply avoids the
Raycast command generator.

### Create the manual directory

```bash
mkdir -p "$HOME/.local/share/day-one-mac/raycast-manual"
chmod 700 "$HOME/.local/share/day-one-mac/raycast-manual"
```

Create `day-one-status.sh` in that directory with a text editor:

```bash
#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Day One · Status
# @raycast.mode fullOutput
# @raycast.packageName Day One Mac
# @raycast.description Show the current Day One Mac setup status.

set -euo pipefail

DAY_ONE_BIN="$HOME/.local/bin/day-one-mac"
if [[ ! -x "$DAY_ONE_BIN" ]]; then
  printf 'The Day One Mac command is unavailable. Reinstall the public standalone runtime.\n' >&2
  exit 1
fi

exec "$DAY_ONE_BIN" --status
```

Make it executable:

```bash
chmod 700 "$HOME/.local/share/day-one-mac/raycast-manual/day-one-status.sh"
```

Before importing it into Raycast, run the file directly in Terminal. This
separates a shell error from a Raycast registration problem:

```bash
"$HOME/.local/share/day-one-mac/raycast-manual/day-one-status.sh"
```

### Create other read-only commands

Copy the file, give the copy a unique filename and title, then replace only
the final `exec` line. These are the safe portable payloads:

| Raycast title | Suggested alias | Final command |
|---|---:|---|
| Day One · Application Ownership | `d1a` | `exec "$DAY_ONE_BIN" applications --required` |
| Day One · Application Inventory | `d1i` | `exec "$DAY_ONE_BIN" inventory` |
| Day One · Validate | `d1v` | `exec "$DAY_ONE_BIN" validate` |
| Day One · Finalisation Status | `d1f` | `exec "$DAY_ONE_BIN" finalize --status` |
| AI · List Projectless Tasks | `ail` | `exec "$DAY_ONE_BIN" workspace list` |
| GitHub · Authentication Status | `gha` | `command -v gh >/dev/null || exit 1; exec gh auth status` |
| Azure · Active Account | `aza` | `command -v az >/dev/null || exit 1; exec az account show --output table` |
| Azure · List Repositories | `azr` | `command -v az >/dev/null || exit 1; exec az repos list --output table` |

Add GitHub commands only for Track 1 or 3. Add Azure commands only for Track 2
or 3. Add the AI workspace commands only when projectless tasks are wanted.

Raycast does not provide an interactive Terminal to Script Commands, so do not
call `day-one-mac workspace --guided` from one. For a non-interactive task
creator, add this metadata above `set -euo pipefail`:

```bash
# @raycast.argument1 { "type": "text", "placeholder": "Task title", "optional": true }
```

Then use this body after the `DAY_ONE_BIN` check:

```bash
TITLE="${1:-Untitled}"
TASK_PATH="$("$DAY_ONE_BIN" workspace create-task \
  --title "$TITLE" \
  --kind other \
  --client undecided \
  --sensitivity private \
  --quiet)"
exec open "$TASK_PATH"
```

This creates a bounded private task and opens it in Finder. Start Claude Code,
Codex or another client only after reviewing the new folder. Use the generated
route when the client-specific command should instead open Warp and copy the
reviewed launch command.

For a command that opens a Day One document in VS Code, replace the final line
with this pattern and change the path after `ROOT`:

```bash
ROOT="$("$DAY_ONE_BIN" root)"
exec open -a "Visual Studio Code" "$ROOT/START-HERE.md"
```

Useful document targets are:

```text
START-HERE.md
reference/COMMAND-REFERENCE.md
reference/AI-WORKSPACES.md
optional/README.md
second-brain/README.md
```

To open the repository itself:

```bash
ROOT="$("$DAY_ONE_BIN" root)"
exec open -a "Visual Studio Code" "$ROOT"
```

To open the projectless task parent in Finder:

```bash
mkdir -p "$HOME/Developer/_Projectless/tasks"
exec open "$HOME/Developer/_Projectless/tasks"
```

Use `silent` instead of `fullOutput` for commands that only open an app, file
or folder. Raycast's metadata lines must remain directly below the shebang.

### Add preview-only safety commands manually

These commands show intended changes but do not execute removal. Keep
`@raycast.mode fullOutput` and do not assign global hotkeys:

| Title | Payload |
|---|---|
| Day One · Removal Inventory | `exec "$DAY_ONE_BIN" remove --inventory` |
| Day One · Preview Recorded Rollback | `exec "$DAY_ONE_BIN" rollback` |
| Day One · Preview Broad Cleanup | `exec "$DAY_ONE_BIN" clean` |

Never add `--execute`, typed confirmations, automatic package installation or
credential values to a Raycast script. Perform state-changing work in Terminal
where its complete prompt and output remain visible.

### Maintain manual commands

- Test each changed file directly in Terminal before using Raycast.
- Keep file permissions at `700` and the directory at `700`.
- Store only reviewed, non-secret scripts in chezmoi if portability is wanted.
- Remove a command by moving its script to a private archive, then confirm it
  disappears from Root Search.
- Use `day-one-mac raycast --preview` as a comparison list; it does not change
  the manual directory.

## Add the directory to Raycast once

Use the directory for the route selected above:

```text
Generated: ~/.local/share/day-one-mac/raycast
Manual:    ~/.local/share/day-one-mac/raycast-manual
```

1. Open **Raycast Settings → Extensions → Script Commands**.
2. Choose **Add Script Directory**.
3. Press `⇧⌘G` in the folder chooser.
4. Enter the generated or manual directory shown above.
5. Select the folder.
6. Search Root Search for `Day One · Status`.
7. Run it and confirm that the saved setup status appears.

Raycast watches the directory, so a later `day-one-mac raycast --wizard`
refresh does not require another import.

## Assign the suggested aliases

Script Command metadata does not assign aliases. This is deliberate: aliases
are user-level Raycast state, and an imported work profile may already own one.

For each command you want to shorten:

1. Find the command in Root Search.
2. Press `⌘K` and choose **Configure Command**, or press `⌘,`.
3. Set the suggested alias shown in the table below.
4. Open **Settings → Shortcuts → Alias Set** when finished and review conflicts.

### Required setup and health

| Command | Alias | Result |
|---|---:|---|
| Day One · Status | `d1s` | Show track, stack and Phase 01–08 state |
| Day One · Application Ownership | `d1a` | Check required apps without installing |
| Day One · Application Inventory | `d1i` | Write the private application inventory |
| Day One · Validate | `d1v` | Run the full project validator |
| Day One · Finalisation Status | `d1f` | Check whether post-Phase-8 finalisation is appropriate |

### Guides and launchers

| Command | Alias | Result |
|---|---:|---|
| Day One · Open Start Here | `d1h` | Open the beginner guide in VS Code |
| Day One · Command Reference | `d1c` | Open every portable/direct command and its intended use |
| Day One · Open Project in VS Code | `d1r` | Open the recorded Day One project root |
| Day One · Open Project Terminal | `d1t` | Open a Warp tab at the recorded runtime root |
| Day One · Optional Modules | `d1o` | Open the optional-module index; run nothing |

### Safety previews

These are excluded by default. They remain preview-only when selected:

| Command | Alias | Result |
|---|---:|---|
| Day One · Removal Inventory | `d1ri` | Classify ownership and removal scope |
| Day One · Preview Recorded Rollback | `d1rp` | Preview manifest-owned reversal |
| Day One · Preview Broad Cleanup | `d1cp` | Preview broad development cleanup |

Never add a global hotkey to cleanup or rollback. Execution stays in Terminal
behind the documented typed confirmations.

## AI client commands

The command generator includes only clients saved by the Day One wizard.

| Saved selection | Generated action |
|---|---|
| Codex | Create a bounded private task, open Warp there and copy the `start-codex` command |
| Claude Code | Create a bounded private task, open Warp there and copy the `start-claude` command |
| Copilot CLI | Create a bounded private task, open Warp there and copy the `copilot` launch command |
| GitHub Copilot app | Open the standalone application |
| Raycast AI | Open the reviewed AI setup and approval guide |

The create commands take an optional title. They never launch an agent in the
`_Projectless` parent. After Warp opens, review and paste the copied command.
Use the regular workspace wizard when the task is work-confidential or public;
Raycast-created tasks deliberately default to `private`.

Common aliases:

| Command | Alias |
|---|---:|
| AI · List Projectless Tasks | `ail` |
| AI · Open Projectless Tasks | `aif` |
| AI · Open Workspace Guide | `aig` |
| AI · New Codex Task | `aitc` |
| AI · New Claude Code Task | `aitl` |
| AI · New Copilot CLI Task | `aitp` |

## Hosting commands

- Tracks 1 and 3 receive GitHub authentication and repository commands.
- Tracks 2 and 3 receive Azure account and repository commands.
- Track 2 never receives GitHub commands merely because `gh` happens to exist.

## Recommended Raycast extensions

Run the current local catalogue at any time:

```bash
day-one-mac raycast --extensions
```

### Built in—no Store installation

| Feature | Why | Review first |
|---|---|---|
| File Search | Find approved local files | Limit intended search locations |
| Clipboard History | Recover and reuse copied values | Exclude password, keychain and sensitive work apps |
| Quicklinks | Open guides, folders and approved dashboards | Never put a token in a saved URL |
| Snippets | Insert repeated reviewed text | Disable expansion in credential apps |
| Window Management | Arrange development windows | Accessibility permission is required |

### Recommended Store extensions

Install an extension manually as follows:

1. Open Raycast and search for **Store**.
2. Search for the exact extension name below.
3. Confirm the publisher before selecting **Install**.
4. Read the requested access and connect only the intended personal or work
   account.
5. Configure only approved folders, repositories or vaults.
6. Run one harmless action, then remove the extension if its access is wider
   than its purpose.

| Extension | Publisher | Use when | Review |
|---|---|---|---|
| [Warp](https://www.raycast.com/warpdotdev/warp) | `warpdotdev` | Every Day One Mac using Warp | Vendor extension; inspect the target directory or launch configuration |
| [Visual Studio Code](https://www.raycast.com/thomas/visual-studio-code) | Thomas Paul Mann | Every Day One Mac using VS Code | Community extension; review editor/folder access |
| [GitHub](https://www.raycast.com/raycast/github) | Raycast | Track 1 or 3 | Confirm the correct personal/work GitHub account and OAuth scope |
| [GitHub Copilot](https://www.raycast.com/github/github-copilot) | GitHub | Copilot was selected | Confirm organisation policy and repository access |
| [Obsidian](https://www.raycast.com/marcjulian/obsidian) | Marc Julian | Optional Obsidian Second Brain | Configure only intended vault paths and exclusions |

### Useful but optional

| Extension | Suitable use | Caution |
|---|---|---|
| [Can I Use](https://www.raycast.com/thomas/can-i-use) | Browser-compatibility lookup for web development | Public information only; no project access should be needed |
| [Kill Process](https://www.raycast.com/rolandleth/kill-process) | Find a runaway process | Killing a process can lose unsaved work |
| [Port Manager](https://www.raycast.com/lucaschultz/port-manager) | Find the owner of a busy local port | Closing a port normally terminates work |

Do not install the Homebrew or 1Password Store extensions merely because they
are popular. Day One Mac already owns Homebrew changes through reviewed scripts,
and 1Password Universal Autofill/Quick Access avoids exposing vault search to
another extension. A Docker-management extension is also unnecessary for the
base OrbStack workflow; use the reviewed database and Warp commands instead.

## Recommended shortcuts

| Shortcut | Owner |
|---|---|
| `⌥Space` | Raycast Root Search in both launcher modes |
| `⌘Space` | Spotlight Search in alongside mode; unassigned in Raycast-only mode |
| `⌥⌘V` | Clipboard History |
| `⌃⌥⌘←` / `⌃⌥⌘→` | Left/Right Half, when Window Management is enabled |
| `⌃⌥⌘↑` / `⌃⌥⌘↓` | Maximize/Restore, when Window Management is enabled |
| `⌃⌥⌘T` | AI task creation, only if used frequently |

Prefer an alias over a hotkey for every Day One health command. Keep `⌘\` for
1Password Universal Autofill and do not reuse it for Raycast or Warp. Open
Quick AI through Root Search unless a separate conflict-free shortcut is
deliberately chosen.

## Refresh or remove the generated commands

Refresh after changing the hosting track or AI clients:

```bash
day-one-mac raycast --wizard
day-one-mac raycast --status
```

Preview either launcher path without changing files or settings:

```bash
day-one-mac raycast --launcher-mode alongside-spotlight --preview
day-one-mac raycast --launcher-mode raycast-only --preview
```

The wizard saves the selected guidance with the generated command manifest,
but shortcut changes remain manual in macOS and Raycast settings.

Remove only the generated directory:

```bash
day-one-mac raycast --remove-generated
```

Removal moves the directory into `~/.day-one-mac/raycast-command-backups`; it
does not delete personal Raycast settings, aliases, extensions or exports.
Remove the old Script Directory entry in Raycast Settings if it remains listed.

## Verification checklist 🚦

- [ ] The early installer provided `day-one-mac` and `day-one-mac root` succeeds.
- [ ] The managed Script Command directory is added exactly once.
- [ ] `Day One · Status` runs from Raycast.
- [ ] Generated hosting commands match the saved track.
- [ ] Generated AI commands match the selected clients.
- [ ] Cleanup and rollback commands are preview-only and have no hotkeys.
- [ ] Clipboard History excludes credential and sensitive applications.
- [ ] Every Store extension has a known publisher, purpose and reviewed access.
- [ ] An encrypted Raycast export is stored separately from its 1Password passphrase.

Official references: [Script Commands](https://manual.raycast.com/script-commands),
[aliases and hotkeys](https://manual.raycast.com/command-aliases-and-hotkeys),
[extensions](https://manual.raycast.com/extensions), and
[import/export](https://manual.raycast.com/import-export).

---

[← Raycast setup](RAYCAST.md) · [AI providers](RAYCAST-AI-PROVIDERS.md) · [Keyboard shortcuts](KEYBOARD-SHORTCUTS.md) · [AI workspaces](../20-reference/AI-WORKSPACES.md)
