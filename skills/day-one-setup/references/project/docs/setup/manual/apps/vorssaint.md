[← Application guides](README.md) · [Keyboard shortcuts](keyboard-shortcuts.md) · [VS Code development setup](../editors/vscode.md)

# Configure Vorssaint for software development on macOS

**Document type:** how-to guide with settings reference. **Audience:** experienced
software developers on macOS, especially Angular, NestJS, Nx, Prisma, PostgreSQL,
and Docker users. **Checked:** 14 October 2026 against installed **3.4.1**, build
**101**, and the corresponding public release source.

Use Vorssaint to arrange development windows, inspect resource use and ports,
and make repeated desktop actions faster. Start with a small feature selection
and add capabilities when they solve a daily problem. This guide assumes you
already have the app installed and keep personal preferences on your Mac.

Vorssaint requires Apple Silicon and macOS 14 or later. It is a modular utility,
not an IDE, Git client, Docker runtime, or project tracker. The integrations
below are either verified app features or workflows using external tools;
they are labelled accordingly. Menu labels can change after 3.4.1.
[Official project](https://github.com/vorssaint/vorssaint-utils),
[3.4.1 release](https://github.com/vorssaint/vorssaint-utils/releases/tag/v3.4.1).

Nothing here installs utilities, changes permissions, or applies settings
automatically. Configure through the app's interface; avoid undocumented
`defaults write` recipes and editing its private preference keys.

## Contents

1. [Choose the baseline and permissions](#1-choose-the-baseline-and-permissions)
2. [Arrange coding and debugging windows](#2-arrange-coding-and-debugging-windows)
3. [Assign shortcuts without conflicts](#3-assign-shortcuts-without-conflicts)
4. [Configure clipboard, snippets, and scratchpads](#4-configure-clipboard-snippets-and-scratchpads)
5. [Monitor performance and investigate ports](#5-monitor-performance-and-investigate-ports)
6. [Connect your development workflow](#6-connect-your-development-workflow)
7. [Add advanced features selectively](#7-add-advanced-features-selectively)
8. [Verify, back up, and maintain the setup](#8-verify-back-up-and-maintain-the-setup)

For named multi-display Office/Home workspaces, use the
[workspace guide](workspaces.md). In that recipe Raycast owns window placement;
leave equivalent Vorssaint window bindings disabled while retaining monitoring,
ports and quit protection. The individual-window baseline below remains an
alternative when Vorssaint is your selected window owner.

## 1. Choose the baseline and permissions

Open Vorssaint from Applications, then open **Settings** from its menu bar
panel. If the app seems absent, check the menu bar rather than the Dock.
Open **Features** and select the tools below individually. Installing a
feature makes it available; its own enable switch may still need turning on.
Uninstalled features stop loading, and reinstalling restores their settings.
[Feature overview](https://vorssaint.com/).

### Recommended feature selection

The initial recommendation assumes Raycast remains your launcher. Choose one
owner for each overlapping function before enabling it in both apps.

| Feature | Starting choice | Purpose and trade-off |
|---|---|---|
| Window layout | Install; enable when Vorssaint owns window management | Arrange editor, terminal, and browser; disable equivalent Raycast/Rectangle/Magnet bindings |
| Maximize windows | Optional | Make the green button fill the current desktop instead of entering full screen; keep native behavior if you use full-screen Spaces |
| CPU, Memory, Disks | Install | Investigate builds, language servers, indexing, and Docker pressure |
| Power | Install on a MacBook | See battery impact and choose when to stop background work |
| Network, GPU | Add when diagnosing a relevant problem | Useful for transfers or rendering; unnecessary as permanent menu bar readouts for most coding |
| Port Manager | Install | Find listeners blocking Angular, NestJS, PostgreSQL, or a debugger |
| Kill Process | Optional companion | Enables Port Manager termination; inspect ownership and try normal shutdown first |
| Keep awake | Install; sessions off by default | Keep a deliberate long build or transfer running for a limited period |
| Quit & close protection | Install | Protect selected development apps from accidental Cmd+Q |
| Clipboard, Text snippets | Leave capture/expansion off if Raycast owns them | One history collector and one expander make behavior predictable |
| Scratchpad, Shelf | Optional | Temporary debug notes and file handoff; do not use them as your authoritative project records |
| Screenshot, Copy text from screen, Color picker | Optional | Bug reproduction, inaccessible error text, and frontend work |
| Command Bar | Optional secondary entry point | Discover Vorssaint actions; keep Raycast's existing launcher shortcut |
| Dynamic Island and AI Agents | Optional | Session progress and available agent metrics; additional visual activity and local log reading |
| Dock Preview, app switcher | Optional | Valuable with many windows, but add only if native switching is insufficient |
| Cleaner, Uninstaller, Homebrew, App updates | Leave unused initially | Keep package and toolchain changes deliberate, through your established updater |
| Fan Control, extra brightness, companion, animated music bars | Leave off initially | These are not required to improve development productivity |

**For a lean daily setup:** start with window layout, CPU/memory/disks, Port
Manager, temporary keep-awake, and quit protection. Keep the menu bar to memory
and CPU plus the main icon. More enabled modules do not make builds faster.

### Startup and permissions

1. In **General**, turn on **Launch at login** once the baseline works. Keep
   only one launch mechanism; don't also add your own launch agent.
2. In **About**, keep automatic Vorssaint update checks enabled unless your
   organisation manages updates. Review a release before installing it.
3. Grant **Accessibility** for window manipulation and your selected input
   actions.
4. Grant **Screen Recording** only when choosing previews, capture, or OCR.
   The switcher can use a simpler icon-based mode without it.
5. Allow **Notifications** if you want resource and completion alerts.
6. Add audio, microphone, camera, calendar, Automation, or folder access when
   enabling the feature that needs it. Routine window and monitoring use
   does not require Full Disk Access or an administrator helper.

Review grants under **System Settings → Privacy & Security**. The app's
permission page explains which installed features use each grant. Labels for
screen/audio capture differ across macOS releases.
[Versioned permissions guide](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/docs/PERMISSIONS.md).

## 2. Arrange coding and debugging windows

Open **Settings → Window layout**. For the first week, use keyboard placement
and simple edge snapping; leave modifier-drag gestures off until you need them.

| Setting | Starting value | Benefit |
|---|---|---|
| Window dragging / edge snapping | On if Vorssaint owns snapping | Fast positioning without entering full screen |
| Window gap | 8 | Small visual separation without wasting much editor space |
| Screen gap | 8 | Leaves a visible margin; use 0 on a small laptop screen |
| Side edge placements | Left/right halves initially | Predictable behavior; configure thirds later for a wide monitor |
| Top edge placement | Maximize | Useful for a focused debugging session |
| Modifier-drag gestures | Off initially | Avoid interacting with IDE multi-cursor or mouse gestures |
| Ignore apps | Add an app only when its layout misbehaves | Keep unusual dialogs or specialised interfaces under their own control |

These gap values are actual 3.4.1 presets. **Window dragging** lets you assign
placements to individual edges and corners. Exact layouts belong to individual
windows; don't assume Vorssaint saves and launches a complete named project
workspace. [Window layout settings](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/WindowLayoutSettings.swift).

### Apply useful layouts

1. **Laptop coding:** put VS Code in the left two thirds, browser in the right
   third if available and readable. Use VS Code's integrated terminal rather
   than adding a third cramped window. Switch to halves or maximize on a
   smaller display.
2. **External display:** put editor left, browser right, and Warp on the laptop
   screen. Open DevTools in the browser rather than forcing another narrow
   column.
3. **API debugging:** use editor and Warp side by side. Put the HTTP client or
   browser on the other display. Keep the target worktree visible in titles.
4. **Xcode:** maximize its workspace on the main display, with Simulator on
   the second display or beside it when space permits. Move Simulator manually
   if a window resists resizing; don't force every application into thirds.
5. **Two worktrees:** open two distinct VS Code windows, place them in halves,
   and use different editor profile accents. Keep each terminal attached to
   the appropriate worktree.

If macOS edge tiling also triggers, choose one owner. On macOS versions with
native tiling controls, inspect **System Settings → Desktop & Dock → Windows**
and disable overlapping drag-to-edge actions when using Vorssaint snapping.
Do not disable all native window controls merely to try this app.

Leave **Focus follows mouse** off initially: changing focus while you move to
read a log can send typing to the wrong terminal. Leave **Quit on close** off
for VS Code, Xcode, Warp, Docker, and agent apps; closing a window should not
unexpectedly end their remaining background work.

For **Quit & close protection**, enable protection for **Cmd+Q**, select
**selected apps only**, and add VS Code, Xcode, and Warp. Start with **Hold**
using the app's default hold duration. Keep **Cmd+W** protection off initially;
frequent editor-tab closing should remain quick. Test before adding Docker
or Codex. [Quit protection settings](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/QuitProtectionSettings.swift).

## 3. Assign shortcuts without conflicts

Open **Settings → Keyboard shortcuts**, install the associated feature if its
row is missing, then record each chosen shortcut. Test it while VS Code,
Xcode, Warp, and your browser are focused. Inspect each application's shortcut
editor before accepting a conflicting global binding.

The bindings below are **suggested custom assignments**, not Vorssaint defaults.
Keep the existing [Day One Mac shortcut ownership](keyboard-shortcuts.md):
Raycast owns **Option+Space**, Spotlight retains **Cmd+Space** in alongside
mode, and 1Password owns **Cmd+Backslash**.

| Suggested binding | Owner / action | Use |
|---|---|---|
| Ctrl+Option+Cmd+Left | Vorssaint Left Half | Editor beside browser |
| Ctrl+Option+Cmd+Right | Vorssaint Right Half | Browser or terminal beside editor |
| Ctrl+Option+Cmd+Up | Vorssaint Maximize | Focused debugging |
| Ctrl+Option+Cmd+Down | Vorssaint Restore | Return to previous placement |
| Ctrl+Option+Cmd+N | Vorssaint Scratchpad, optional | Keep a short debugging note |
| Ctrl+Option+Cmd+K | Vorssaint Keep awake | Toggle a configured temporary session; check its status |
| Ctrl+Option+Cmd+Space | Vorssaint Command Bar, optional | Find a less frequent utility action |
| Option+Cmd+V | Clipboard History, one chosen owner | Reuse recent text; keep Raycast ownership unless switching |

Port Manager has no dedicated role in the verified 3.4.1 shortcut settings;
open it from the menu bar panel rather than assuming a bindable action.

The four layout bindings intentionally reuse the repository's Raycast layout
scheme. **Remove them from Raycast first** if giving them to Vorssaint. Leave
the optional window switcher unbound initially, then choose a shortcut that
preserves your preferred native Cmd+Tab behavior.

Don't take over **Cmd+V**, **Cmd+W**, **Cmd+Q**, **F2**, or IDE debugging function
keys globally just to make them consistent. Quit protection intercepts only
the selected action/app scope; a global remapping can disrupt unrelated apps.
The optional **Super key** can reduce a multi-modifier chord to one physical
key, but configure it only after the ordinary shortcuts work and only if
Caps Lock/right-side modifiers are free in your keyboard setup.
[Shortcut settings implementation](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/ShortcutsSettings.swift).

## 4. Configure clipboard, snippets, and scratchpads

### Choose one clipboard owner

Keep Raycast Clipboard History if it already suits you. Leave **Save clipboard
history** off in Vorssaint and do not assign a second history shortcut.

To switch to Vorssaint, disable Raycast's clipboard capture first, then open
**Settings → Clipboard** and apply:

| Control | Recommended starting value |
|---|---|
| Save clipboard history | On only when Vorssaint is the owner |
| Skip text that looks sensitive | On |
| Ignored applications | Add 1Password and other credential/sensitive-work apps |
| Limit | 100; use 50 for a smaller working set |
| Also save copied images and files | Off initially; enable only if required |
| History layout | List |
| Show latest copy in the menu bar | Off |
| Clear clipboard on screen lock | On |
| Clear clipboard on computer sleep | On |
| Clear clipboard on display sleep | Off initially; a blank display can interrupt a pending paste |
| Clear after a delay | Off initially; optionally choose 120 seconds for a sensitive workflow |

The app offers an item-count limit, not a documented general history-age
setting. Clear unpinned history at the end of a sensitive task; pinned entries
remain. Sensitive-text filtering is heuristic and can miss secrets embedded
in JSON, shell commands, or `.env` content. Excluding the editor prevents
useful code capture too, so decide deliberately for sensitive repositories.
[Clipboard settings](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/ClipboardSettings.swift),
[ignored-app support](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/Services/Clipboard/ClipboardIgnoredApps.swift).

Automatic clearing empties the **system clipboard**, not saved history. Test
with dummy text rather than a real credential. Local storage is not a promise
that every clipboard item is suitable for backup or screen sharing.
[Privacy notes](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/docs/PRIVACY.md).

### Use app-wide snippets for prose

If Raycast already expands snippets, keep it as the owner. Otherwise install
**Text snippets**, open its settings, enable expansion, and create a snippet
with a distinctive trigger and its replacement text. Test in a disposable note
before using an editor or terminal.

| Suggested trigger | Replacement text | When to use it |
|---|---|---|
| `;repro` | `Steps to reproduce:\nExpected:\nActual:\nEnvironment:` | Bug reports; enter real line breaks, not literal backslash-n characters |
| `;prnote` | `Problem:\nChange:\nValidation:\nFollow-up:` | Pull request notes; enter real line breaks |
| `;review` | `Check correctness, error handling, tests, and compatibility with the existing architecture.` | A reusable review prompt |
| `;debug` | `State the observed failure, reproduce it, and gather evidence before changing code.` | A debugging reminder |

Use VS Code/Xcode's language snippets for Angular components, Nest providers,
and code with placeholders. Global text expansion lacks the IDE's language
context. Avoid global snippets that paste and execute shell commands, create
migrations, change branches, or contain secrets. Keep only one expander active.
[Text snippet editor](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/TextSnippetsSettings.swift).

### Keep scratchpads and files temporary

Install **Scratchpad** only if a floating note helps. Create a tab named
`Current debug` with the worktree, failing test, hypothesis, and next check.
Move decisions and useful findings into the issue, PR, or repository before
clearing it. Scratchpads autosave; do not treat them as ephemeral secret storage.

Install **Shelf** when frequently moving screenshots or fixtures between apps.
Drop the item there, then drag it into your intended destination. Keep original
source files in the repository; the Shelf is a handoff surface. For captures,
prefer saving locally and attaching a reviewed image to the issue. Temporary
share links upload the capture and are a separate, explicit action.
[Scratchpad service](https://github.com/vorssaint/vorssaint-utils/tree/v3.4.1/Sources/Vorssaint/Services/QuickTools/ScratchpadService.swift),
[capture privacy](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/docs/PRIVACY.md).

## 5. Monitor performance and investigate ports

### Set a quiet monitoring baseline

Open **Settings → System monitor** and use these starting choices:

| Setting | Daily development | Temporary diagnosis |
|---|---|---|
| Update every | 5 seconds on battery; 2 seconds when plugged in | 1 second while reproducing a short problem |
| Menu bar readings | Memory and optionally CPU | Add network/disk/GPU only for the current investigation |
| Measure memory as | Used | Compare with App memory when investigating app allocations |
| Memory-pressure alert | On | Keep on; 3.4.1 alerts on critical pressure |
| Low disk-space alert | On, 15% free threshold | Inspect what grows during builds |
| CPU-load alert | Off | Optionally on at 90%; expected compilation can trigger it |
| Repeat-alert cooldown | 15 minutes | Shorten only for a controlled test |
| Fan Control | Off | Let macOS manage cooling |

The update choices are 1, 2, and 5 seconds. Sampling is adaptive, so the setting
is not a guarantee that every sensor polls at that exact cadence. These are
starting recommendations, not measured speed gains on your Mac.
[Monitor settings](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/MonitorSettings.swift),
[alert controls](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/MonitorAlertsControls.swift),
[sampling policy](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/Services/Metrics/MonitorSamplingPolicy.swift).

When an Nx build feels slow:

1. Observe CPU, memory pressure, and disk activity while reproducing it once.
2. Open macOS **Activity Monitor** and identify the responsible process.
3. Check whether Docker, an IDE language server, Spotlight, or the build itself
   accounts for the load. Stop redundant watchers before changing settings.
4. Compare the same build again. Keep the change only if it helps.

High occupied memory alone does not establish a problem; macOS uses caching
and compression. Memory pressure and swap activity provide useful context.
[Apple's memory guidance](https://support.apple.com/guide/activity-monitor/view-memory-usage-actmntr1004/mac).

### Worked example: NestJS cannot bind port 3000

1. Open **Port Manager** from Vorssaint's menu bar panel.
2. Find port `3000` and inspect the process name, PID, and listening address.
3. If it belongs to your earlier Nest dev server, return to that Warp/VS Code
   terminal and press **Ctrl+C**. If it is another project's service, choose a
   different port or stop it through its normal owner.
4. If the process is orphaned, use the termination action only after confirming
   the PID. It requires the **Kill Process** feature. Recheck the port afterward.
5. Restart NestJS in the intended worktree and open its health endpoint.

For independent confirmation in Warp:

```bash
lsof -nP -iTCP:3000 -sTCP:LISTEN
```

Do not mass-kill all `node` processes: that can end IDE helpers and unrelated
agents. A process tree action can also stop child processes beyond the one
listener. [Port Manager UI](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/PortManager/PortManagerView.swift).

| Common development port | Typical owner; verify your project |
|---|---|
| 4200 | Angular dev server |
| 3000 | Example NestJS HTTP server; configurable |
| 5432 | PostgreSQL, native or Docker-published |
| 9229 | Node inspector |
| 5555 | Common Prisma Studio setup; configurable |

A Docker-published port can appear as a runtime/forwarder process rather than
the PostgreSQL process inside the container. Inspect container mappings with
`docker ps`; stop the correct container through Docker, not the host forwarder.

```bash
docker ps
docker stats --no-stream
```

Vorssaint's host monitor does not replace container-level measurements. Use
Docker's stats for CPU/memory by container, then Docker Desktop or
`docker stop CONTAINER_NAME` for a deliberate shutdown. Docker sends the
container's stop signal and allows a grace period before forcing termination.
[Docker stats](https://docs.docker.com/reference/cli/docker/container/stats/),
[Docker stop](https://docs.docker.com/reference/cli/docker/container/stop/).

## 6. Connect your development workflow

### Give each tool a clear responsibility

| Tool | Role with Vorssaint | Integration type |
|---|---|---|
| Git / GitLens / VS Code Source Control | Branches, diffs, commits, PRs, worktrees | External tools; Vorssaint arranges their windows |
| VS Code | TypeScript, Angular/Nest debugging, tasks, imports, agent extensions | External IDE; launcher/window/menu actions are conveniences |
| Xcode and Simulator | Apple-platform coding, signing, testing, debugging | External IDE/runtime; window placement and app switching |
| Warp / Zsh | Explicit project commands, test logs, CLI agents | External terminal; share workspace context manually |
| Docker Desktop or your selected runtime | Container lifecycle, resources, volumes, networks | External runtime; host monitoring and ports supplement it |
| Raycast | Main launcher, existing script commands, chosen clipboard/snippet ownership | Complementary utility; remove duplicate global bindings |
| 1Password | Credential storage, SSH agent, autofill | Separate security tool; exclude it from clipboard capture |
| Codex / GitHub Copilot / Claude | Coding agents and account authentication | External clients; optional Vorssaint monitoring reads available local data |
| Azure DevOps | Issues, pipelines, repositories, team delivery | Browser/CLI workflow; no native Vorssaint project-management integration verified |

No Git credential, SSH key, Azure token, or Docker registry password belongs
in a Vorssaint snippet or settings export. Keep existing authentication setup.

### Open a project or worktree deliberately

1. Use Raycast or Finder to open your project folder, or use Warp to enter it.
2. Open a separate VS Code window with the desired profile:

   ```bash
   cd "$HOME/Developer/my-project"
   code --new-window --profile "Full Stack" .
   git status --short --branch
   git worktree list
   ```

3. Apply your window placement shortcut. Keep the browser and terminal on
   the same feature branch's environment.
4. Start project commands from that worktree. Choose separate ports for two
   simultaneous dev servers rather than assuming worktrees isolate ports.

Replace the example directory with your real path. The `code` command requires
**Shell Command: Install 'code' command in PATH** in VS Code. Vorssaint is not
creating the worktree here; use the
[native VS Code worktree example](../development/worktrees/vscode.md).
[VS Code CLI](https://code.visualstudio.com/docs/configure/command-line),
[Git worktree reference](https://git-scm.com/docs/git-worktree).

For Xcode, open the project's intended `.xcworkspace` or `.xcodeproj`, then
arrange its windows. Keep build settings, scheme selection, and debugger
configuration inside Xcode; Vorssaint does not configure them.

### Optional Command Bar project links and scripts

If you enable **Command Bar**, use **Settings → Command Bar → Your shortcuts**:

1. Add a **Place** with a short name such as `Day One Mac` and choose its folder.
   Test where the place opens; this is not an automatic IDE workspace selector.
2. Add a **Link** for the project's Azure DevOps board, local UI, or documentation.
   Use the real URL; leave credentials out of it.
3. Add a **Script** only for a small, understood action. Choose its executable
   file and a distinct name. Keep the option to run when the name is typed
   alone off until you understand the execution behavior.

In 3.4.1, script links can run while a matching query is being entered so their
output can appear in the bar. Do not use preview scripts for deployments,
branch changes, migrations, or container deletion. Keep those in Warp with
explicit confirmation and visible output.
[Command Bar settings](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/CommandBarSettings.swift),
[script execution behavior](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/Services/CommandBar/CommandBarScriptRunner.swift).

For a personal project launcher, save this as
`~/.local/bin/open-day-one-mac`, then make it executable. Check the two example
paths on your Mac before saving. No repository settings need to be committed.

```bash
#!/bin/bash
set -eu
project_path="$HOME/Developer/Sandbox/day-one-mac"
code_path="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
[ -d "$project_path" ] || { printf 'Project folder is missing.\n' >&2; exit 1; }
[ -x "$code_path" ] || { printf 'VS Code launcher is missing.\n' >&2; exit 1; }
exec "$code_path" --new-window --profile "Full Stack" "$project_path"
```

```bash
chmod +x "$HOME/.local/bin/open-day-one-mac"
```

Choose that file as the Script destination. Leave **Also run when its name
is typed on its own** off. Enable **Run from its global shortcut without
opening the bar**, and assign a free row shortcut through **Give it a shortcut**
(for example Ctrl+Option+Cmd+O, after checking conflicts). Invoke that shortcut
deliberately; typing arguments after the script name can still trigger preview
execution, so use the shortcut for this launcher. Opening a new IDE window
repeatedly is annoying as a live preview. A fixed executable path avoids depending on an interactive
Zsh initialization that the app may not run. For shell configuration and Warp
integration, follow the [shared Zsh guide](../shell/zsh.md#1-use-zsh-consistently-in-vs-code-and-warp).

## 7. Add advanced features selectively

### Temporary keep-awake for long work

Open **Keep awake** settings:

1. Set a finite session duration appropriate to the job, such as one hour.
2. Leave **auto-start** off; start the session when the build, download, or
   recording actually needs it.
3. Allow display sleep for unattended work and pause when locked if that is
   appropriate to your task. If a locked build must continue, leave that pause
   off for the deliberate session and check the remaining duration.
4. Leave mouse jiggling and closed-lid mode off. Leave normal screen locking
   and security settings intact.
5. Stop the session when the task finishes; check the status rather than
   assuming a shortcut only started it.

This prevents idle sleep; it does not accelerate a build or protect a process
from crashes. Always-on triggers for VS Code keep the Mac awake even while
an idle editor is open. Add app/power triggers only if that behavior is wanted.
[Keep-awake controls](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/EnergySettings.swift).

### Codex and Copilot status in Dynamic Island

This is an **optional native Vorssaint monitoring feature**, separate from
installing or authenticating an agent.

1. Install **Dynamic Island** and **AI Agents** from Features if desired.
2. Open **Settings → Dynamic Island → Content → AI Agents**.
3. Enable **Codex** and **GitHub Copilot**; disable OpenCode if unused. Enable
   Claude only when you want it monitored.
4. Enable live activity with **elapsed time** as a useful initial readout.
5. Enable finish alerts for tasks lasting at least **60 seconds**; this avoids
   alerts for every short turn. Keep limit alerts optional; **90% used** is a
   sensible initial threshold when the provider exposes reliable limits.
6. Show limits as **remaining**. Leave the **Resets** card off initially and
   treat API-value estimates as informational, not your subscription bill.
7. Keep the companion, music visualizer, notification mirroring, and lock-screen
   display off if your goal is a quiet development screen.

The monitor uses available local agent records. Copilot's source is local
CLI/app session data under `~/.copilot/session-state`; do not assume all VS Code
Copilot Chat activity or account quota is represented. Some counters appear
only after a session writes shutdown metrics. A missing metric is not zero
usage. Agent clients and log formats can change independently of Vorssaint.

Codex's Resets card can invoke Codex's own authenticated tool and contact
OpenAI; it is different from simply reading cached local session data.
**Keep prices up to date** fetches the app's public price list. Enable only
when you want current estimates and that network request.
[AI Agents settings](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/UI/Settings/NotchAgentsSettings.swift),
[agent data and network behavior](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/docs/PRIVACY.md).

Vorssaint neither installs project skills nor selects agent instructions.
Use the [shared skills and agent setup](../ai/instructions-agents-skills.md#1-share-project-instructions-skills-and-agents)
for those. Check account usage in each provider's own client when making a
quota or spending decision.

### Frontend and bug-report utilities

Install **Color picker** when checking UI colors; choose HEX for CSS examples.
Use **Copy text from screen** only for errors you cannot copy directly, then
check OCR against the original before running anything it recognises.

For a bug recording, capture the smallest useful area, exclude credentials
and unrelated notifications, and save locally. Enable microphone only when
narration helps. Create a share link only after reviewing the result; otherwise
attach the file through your existing issue tracker.

The optional **Watch** feature can observe a progress region for a long task.
Prefer the terminal's actual exit status or test summary as the result; a
visual progress change does not prove success. Leave Watch off when not used.
[3.4.1 capture and Watch changes](https://github.com/vorssaint/vorssaint-utils/releases/tag/v3.4.1).

## 8. Verify, back up, and maintain the setup

### Verify with ordinary development work

- [ ] Vorssaint launches after login without duplicate menu bar instances.
- [ ] Layout shortcuts work in VS Code, Xcode, Warp, and the browser; Raycast
      does not also react to the same shortcut.
- [ ] Cmd+Q protection applies only to selected apps; ordinary Cmd+W remains fast.
- [ ] Monitoring stays responsive at 2 or 5 seconds without a crowded menu bar.
- [ ] Port Manager shows a known local dev server; closing it normally removes
      the listener after refresh.
- [ ] Only one app captures clipboard history and expands your chosen triggers.
- [ ] Dummy sensitive text is handled as expected; clearing the clipboard and
      deleting saved history are understood as separate actions.
- [ ] A temporary keep-awake session expires and does not leave a permanent rule.
- [ ] Optional agent counters match the data available in the provider's client,
      or are treated as incomplete estimates.
- [ ] No project secret or credential is saved in snippets, captures, or notes.

No universal utility configuration makes every Mac faster. Compare a normal
build/debugging session with unnecessary modules disabled. Use Activity Monitor
for an idle baseline and a sustained workload; temporary peaks during a
capture or feature installation are different from steady background load.

### Back up personal settings

Open **Settings → Advanced**, use the settings **Export** action, and save the
`.plist` to a private backup folder outside the project. Export before trying
large changes. Import replaces the exported preference set and relaunches the
app; it is not a merge of a few selected settings.

An export can include snippets and other personal configuration. Inspect it
before sharing. Permissions, machine-specific folder grants, and local caches
are not a portable substitute for setup on another Mac; regrant required access
there. Back up important scratchpad content separately rather than assuming
an app-preference backup preserves every working note or clipboard entry.
[Backup implementation](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/Services/SettingsBackup.swift),
[exported settings definition](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/Sources/Vorssaint/Core/SettingsBackupSupport.swift).

### Troubleshoot narrowly

| Symptom | Action |
|---|---|
| A setting or shortcut row is missing | Check Features first; uninstalled modules hide their controls |
| Layout shortcut does nothing | Check Accessibility, shortcut registration, and the other utility that may own it |
| Two window movements happen | Disable snapping/hotkeys in the duplicate window manager or macOS drag tiling |
| Previews are blank | Check Screen Recording permission; simpler switching can work without previews |
| Clipboard is empty | Check the chosen owner, capture toggle, ignored apps, and sensitive-text filter |
| A copied secret remains after lock | Inspect saved history separately; automatic clearing only empties the live clipboard |
| Agent figures are missing | Check provider toggles and supported local logs; restart after a completed session, then compare with the provider client |
| Battery use increases | Disable unused modules, animated content and previews; use 5-second monitoring and compare an idle baseline |
| Port remains occupied | Refresh and inspect the current PID; a supervisor or container may restart the service |
| An export restores unexpected choices | Restore the previous export; imports replace preferences and relaunch |

For a permission that remains broken, follow the
[official troubleshooting steps](https://github.com/vorssaint/vorssaint-utils/blob/v3.4.1/docs/TROUBLESHOOTING.md).
Reset only the affected grant after checking the app entry; do not reset all
permissions or disable macOS security as routine troubleshooting.

Keep one update owner for each application and toolchain. If you later use
Vorssaint's **Homebrew** or **App updates** module, review operations instead
of running competing automatic upgrades during development. Do not schedule
Cleaner to remove Docker volumes, database data, Git worktrees, SDKs, or build
caches you depend on. Clean a known target when evidence shows it is the problem.

---

[← Application guides](README.md) · [Raycast setup](raycast.md) · [Warp setup](../terminals/warp.md) · [VS Code development setup](../editors/vscode.md)
