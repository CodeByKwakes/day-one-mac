# Restore a developer workspace across displays

Keep VS Code maximized on the open MacBook. Use external displays for the
running application, AI conversation, terminal and database work. Configure
physical displays first, then save app-window layouts in Raycast.

This is a recommended starting layout, not a measured fit for every monitor.
Calibrate each desk at its actual resolution. A 24-inch diagonal alone does
not establish readable text size or usable screen area.

## Choose one owner per function

| Function | Owner | Boundary |
|---|---|---|
| USB display connection | DisplayLink Manager, where required | Wait for every screen before restoring |
| Resolution and physical arrangement | macOS Displays; optional displayplacer | Preserve the open MacBook display |
| Named app-window layouts | Raycast Pro | Separate from VS Code profiles and Git worktrees |
| Individual window movement | Raycast for this recipe | Remove equivalent Vorssaint bindings before assigning them here |
| CPU, memory, ports and quit protection | [Vorssaint](vorssaint.md) | Keep useful non-overlapping features |
| Optional voice adjustments | [Atticus](atticus.md) | Pilot separately; not the display-restoration authority |

Raycast's named custom layouts require its relevant paid features. Check the
[current plan](https://www.raycast.com/pricing); an existing Pro subscription
can use this recipe without another window-manager subscription.

## Prerequisites

- An Apple-silicon Mac with its lid open and permission to manage displays.
- Raycast configured through the [launcher guide](raycast.md).
- DisplayLink Manager already installed by its approved owner if the dock needs it.
- A private folder for display snapshots and the Raycast export.
- Open the intended VS Code project/profile and the required application windows.

The base M4 MacBook Pro supports two external displays alongside its built-in
screen through native display connections. A third external display needs a
suitable additional solution; do not assume every USB dock supports it.
[Apple display specifications](https://support.apple.com/en-by/121552).

DisplayLink requires Screen Recording permission to send pixels to USB displays
and appropriate background access. This permission does not itself mean video
is being saved. Follow the [vendor configuration guide](https://support.displaylink.com/knowledgebase/articles/2024872-displaylink-manager-first-time-configuration).
It is separate from permission for an AI tool to capture screen context.

## 1. Calibrate the desk

1. Connect the desk's monitors and wait for DisplayLink Manager to show them.

   Expected result: Office has the MacBook plus two external displays; Home
   has the MacBook plus three. Stop if a screen is missing or repeatedly reconnects.

2. Open **System Settings → Displays** and choose extended displays rather than
   mirroring. Set orientation first, then readable resolution and refresh rate.

   Expected result: each display has its own desktop and legible text. Do not
   copy another machine's scaling or force an unsupported refresh rate.

3. Open **Arrange** and drag the display rectangles to match their physical
   positions. Select the main display deliberately; it need not be the laptop.

   Expected result: the pointer crosses between the expected screen edges.
   Use the [DisplayLink arrangement instructions](https://support.displaylink.com/knowledgebase/articles/658258-how-to-configure-displaylink-dis)
   if the installed macOS interface differs.

4. Turn Stage Manager off for the initial test. Maximize VS Code on the MacBook
   using Raycast's **Maximize** command rather than macOS native full screen.

   Expected result: VS Code fills the available desktop without creating a
   separate full-screen Space. Leave existing workspaces open.

## 2. Place the development windows

Treat external display numbers below as roles, not assumed macOS numbering.
Record which physical monitor serves each role privately at each desk.

| Display | Office Code | Home Code |
|---|---|---|
| MacBook | VS Code maximized | VS Code maximized |
| External 1 | Browser preview, DevTools and reference tabs | Browser preview, DevTools and reference tabs |
| External 2 | Codex above, Warp below; start at 65%/35% height | Codex desktop maximized |
| External 3 | Not connected | Warp maximized |

1. Arrange these windows with Raycast's window commands or by dragging them.

   Expected result: the editor remains readable on the laptop; external text
   does not require leaning forward. Use separate tabs instead of narrow panes
   when the 24-inch screens make splitting uncomfortable.

2. Create a **Data** variation by replacing the terminal's external-screen role
   with DataGrip. At Office, give DataGrip the whole second external display.

   Expected result: the selected environment and database are clearly visible.
   Use [database environment safeguards](../databases/README.md). A layout must
   not initiate production queries, save credentials or change database roles.

3. Create a **Review** variation with the PR or Azure DevOps browser on External 1
   and a VS Code diff on the MacBook. Keep Codex and terminal support available.

   Expected result: review and execution contexts are easy to distinguish.
   Teams, Outlook and notes can be opened when needed without permanent slots.

## 3. Save layouts in Raycast

1. Open Root Search and run **Save Current Layout**, or use **Create Layout**
   and add the selected windows. Name the first layouts `Office-Code` and
   `Home-Code`. Add `Office-Data`, `Home-Data` and Review variants only after Code works.

   Expected result: each named layout appears in Raycast. These names identify
   desk and activity, not editor profiles.

2. Edit each layout and set **Other Windows** to **None**.

   Expected result: unrelated windows remain open. Review file, URL and app
   arguments in each entry; remove unwanted launches and sensitive URLs.

3. Test each saved layout while the matching desk is connected.

   Expected result: the correct project window stays on the MacBook. With several
   VS Code windows, test which one Raycast selects. If ambiguous, keep the editor
   out of the saved layout and maximize the chosen window manually. A layout
   must not silently select another Git worktree or create a new VS Code profile.

4. Give each proven layout a Root Search alias. Use an optional restore hotkey
   only after checking the [shortcut ownership table](keyboard-shortcuts.md#workspace-and-voice-shortcuts).

   Expected result: one command owns each shortcut. Export Raycast using the
   [backup procedure](raycast.md#export-raycast-settings-and-data).

The [Raycast window manual](https://manual.raycast.com/window-management)
documents layout creation, window handling and the named-layout deep link.

## 4. Optionally capture physical display arrangements

Named Raycast layouts place windows; preserve the physical display arrangement
separately when docking does not reliably restore it.

1. Check whether `displayplacer` is already available:

   ```bash
   command -v displayplacer
   ```

   Expected result: the selected installation's path. If missing and Homebrew
   owns this optional tool, run `brew install displayplacer`.

2. Record the calibrated desk privately:

   ```bash
   umask 077
   mkdir -p "$HOME/.config/workspace-layouts/manual"
   (set -C; displayplacer list > "$HOME/.config/workspace-layouts/manual/office.txt")
   ```

   Expected result: a readable inventory and a suggested `displayplacer` command.
   Use `home.txt` at Home. The command refuses to overwrite an existing snapshot;
   select a new filename before repeating.

3. Inspect that suggested command before running it. Confirm every current display
   ID, resolution, refresh rate, scaling and origin. Do not use a command that
   disables the laptop display or mirrors screens unintentionally.

   Expected result: the proposed arrangement matches the calibrated desk. Run
   the reviewed command from Terminal only with that same desk connected.

4. Run `displayplacer list` again, then request the saved window layout:

   ```bash
   open 'raycast://customWindowManagementCommand?name=Office-Code'
   ```

   Expected result: the reported display values match the capture, then Raycast
   requests the named layout. Verify the actual windows visually.

Persistent IDs can change after docking or wake, and some modes fall back to a
working resolution. Recapture rather than guessing IDs or forcing a mode.
The [displayplacer reference](https://github.com/jakehilborn/displayplacer)
owns supported arguments. DisplayLink compatibility must be tested on the actual
adapter and displays; it is not established by this guide's fixture tests.

For one reviewed command that checks identity, previews changes and saves recovery
first, use the optional [workspace tool reference](../../../shared/tools/workspaces.md).
The manual route above needs no Day One Mac helper or permanent checkout.

## Verify and recover

1. Move one disposable window, invoke the saved layout and check its placement.
2. Disconnect and reconnect the selected desk, then repeat after DisplayLink settles.
3. Test a sleep/wake cycle when convenient. Confirm the MacBook remains enabled.
4. Check VS Code's project/profile, Codex conversation and Warp working directory.
5. Confirm DataGrip's environment without connecting to production as a test.

Expected result: the same chosen context is restored. Opening a URL successfully
is not proof that Raycast placed the correct windows.

If a screen is absent, restore it through Displays and DisplayLink before retrying.
If IDs duplicate or change, use manual arrangement and recalibrate; do not match
by screen count alone. If windows remain misplaced, check Accessibility, Spaces,
Stage Manager and multiple windows of the same app. Keep **Other Windows: None**.
If displayplacer cannot reproduce the arrangement, keep Raycast's window layout
and arrange displays manually instead.

Rollback: use **System Settings → Displays** to recover the prior arrangement,
then restore the selected Raycast export if needed. A display snapshot does not
restore application contents, tabs, unsaved work or AI conversations. Remove only
your selected aliases or wrapper; keep private snapshots and exports until tested.
