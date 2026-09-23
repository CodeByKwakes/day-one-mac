[← Required apps](README.md) · **Raycast setup** · [Day One command pack](RAYCAST-COMMANDS.md) · [AI providers](RAYCAST-AI-PROVIDERS.md) · [Keyboard shortcuts](KEYBOARD-SHORTCUTS.md) · [Warp setup →](WARP.md)

# Set up, back up, and restore Raycast

**When:** install in the Installation Centre after Phase 2; configure after
Phase 4 · **Required app:** yes · **Extensions, AI, and Second Brain commands:** optional

**Prerequisite:** Homebrew is available from Phase 2. The Installation Centre
normally installs or verifies Raycast before Phase 3, but this guide also gives
complete Homebrew, manual-download and company-installer routes.

## Outcome

Raycast starts with macOS, opens from one memorable shortcut, searches only the
locations you expect, and receives macOS permissions only when a chosen feature
needs them. You will also know how to export, selectively import, and later
change the setup.

Raycast is an application launcher: it opens apps, finds files, runs commands,
and can host optional extensions. The required Day One gate needs only the
application itself. It does not require a Raycast account, paid plan, AI, or
community extension.

## Step 1 — Install or verify Raycast

Choose **one** route. Do not install a Homebrew copy over a valid copy supplied
by Company Portal, the Mac App Store or a trusted manual installer.

### Route A — Let Day One Mac check and offer the choices

The normal setup opens the Installation Centre after Phase 2:

```bash
cd "$HOME/Developer/github.com/<github-user>/day-one-mac/scripts"
./bootstrap-day-one-mac.sh --wizard
```

Replace `<github-user>` with the account or organisation used in the clone
path. To check only Raycast, run:

```bash
./application-status.sh --id raycast --install-missing
```

Choose Homebrew, finish an approved external installer and recheck, or stop
safely. The check accepts only a valid `/Applications/Raycast.app` with the
expected bundle identity; pressing Enter is not treated as proof of installation.

### Route B — Install with Homebrew

The project command above is preferred because it records what Day One Mac
installed. The direct equivalent is:

```bash
brew install --cask raycast
```

### Route C — Install the official download manually

1. Open [Raycast's official download page](https://www.raycast.com/download).
2. Download the macOS build and open the downloaded installer or disk image.
3. Move **Raycast.app** into the system **Applications** folder. Do not leave it
   in Downloads or run it from a mounted disk image.
4. Open Raycast once so macOS can verify the application.
5. Return to Terminal and run the ownership check:

   ```bash
   cd "$HOME/Developer/github.com/<github-user>/day-one-mac/scripts"
   ./application-status.sh --id raycast
   ```

### Route D — Use Company Portal or another approved installer

Install Raycast through the organisation's approved system, confirm that it is
at `/Applications/Raycast.app`, open it once, then run the same ownership
check. Day One Mac records it as external and does not replace it with a cask.

| Check result | Meaning | Continue? |
|---|---|---|
| **Homebrew-managed** | Raycast is present and Homebrew owns the cask | Yes |
| **External installation** | Company Portal, the App Store or a manual installer owns it | Yes |
| **Missing** | No valid Raycast application was found | Install it by one route |
| **Needs review** | Its path, receipt or bundle identity conflicts | Resolve the reported conflict first |

The portable recheck is:

```bash
day-one-mac applications --id raycast
```

## Step 2 — First launch

1. Open **Raycast** from Applications.
2. Complete the short welcome screen without installing optional extensions.
3. Use the temporary default `⌥Space` shortcut during the welcome screen.
4. Press `⌥Space`, type `Raycast Settings`, and press Return.
5. Turn on **Open Raycast at login** so the shortcut works after restarting.

## Step 3 — Replace the Spotlight launcher with Raycast

Day One Mac recommends using `⌘Space` for Raycast so there is one launcher
shortcut to remember. This removes Spotlight **from that keyboard shortcut**;
it does not uninstall Spotlight, disable its search index, or remove the
Spotlight icon.

1. Open **System Settings → Keyboard → Keyboard Shortcuts → Spotlight**.
2. Turn off **Show Spotlight search**, or assign it a different shortcut if you
   still want a separate Spotlight window shortcut.
3. Leave Spotlight indexing enabled. Raycast File Search can use the macOS
   search index for file names and content.
4. Return to **Raycast Settings → General**.
5. Click **Raycast Hotkey**, then press `⌘Space`.
6. Close Settings and press `⌘Space`. Raycast Root Search should open once,
   without Spotlight appearing behind it.

If Raycast reports another conflict, also check:

- **System Settings → Keyboard → Keyboard Shortcuts → Input Sources** for a
  language-switching shortcut that uses `⌘Space`; and
- **System Settings → Apple Intelligence & Siri** for an “Ask Siri” shortcut
  that holds `⌘Space` or `⌥Space`.

To undo the change later, assign Raycast a different hotkey first, then return
to the Spotlight keyboard-shortcut page and enable **Show Spotlight search**.

## Step 4 — Configure the baseline manually

Open Settings with `⌘,` while Raycast is visible. In current Raycast versions,
`⌘F` searches settings if a label has moved.

Recommended starting choices:

| Area | Day One choice | Why |
|---|---|---|
| Open at Login | On | The launcher is available after restart |
| Main hotkey | `⌘Space` | Replaces the Spotlight launcher shortcut with Raycast |
| Menu bar icon | Personal choice | It changes visibility, not function |
| Root Search sensitivity | Default | Tune it only after using real searches |
| File Search scope | Home and Applications initially | Avoid indexing external or confidential locations by accident |
| AI permissions | Ask | Keeps tool actions visible and reviewable |
| Community extensions | None initially | Add one only for a defined need |

Try the two core controls:

- `⌘Space` opens **Root Search**.
- `⌘K` opens the **Action Panel** for the selected result.

Create aliases or dedicated hotkeys only for commands used repeatedly. Too many
global shortcuts become harder to remember and are more likely to conflict.

After the required base is complete, the optional [Day One Raycast command pack](RAYCAST-COMMANDS.md)
can generate safe, track-aware and AI-aware Script Commands. It keeps setup
checks searchable without assigning dozens of global shortcuts.

### File Search

1. Open **Raycast Settings → Extensions → File Search**.
2. Include only the home folder and approved work folders needed on this Mac.
3. Exclude confidential folders that should not appear in launcher results.
4. Test one known file by name and, if required, by content.

Keep Spotlight indexing enabled: Raycast can use the macOS index even though
the Spotlight **window shortcut** has been reassigned.

### Clipboard History

Enable this only when personal or company policy permits clipboard capture.
Open its settings and exclude 1Password, Passwords, Keychain Access and any
sensitive work application. Copy a harmless sentence, find it in Clipboard
History, then confirm copied credentials from an excluded app do not appear.

### Window Management

This is optional. Run one window command first, then grant Accessibility only
if macOS requests it and the feature is wanted. Suggested shortcuts are kept
in [Keyboard shortcuts](KEYBOARD-SHORTCUTS.md); skip them on a managed Mac when
global shortcuts or Accessibility access are restricted.

### Raycast AI

Raycast AI is not part of the required launcher. Leave it unconfigured unless
it was deliberately selected after Phase 8. When selected, keep tool approval
on **Ask**, leave the globally allowed-tools list empty, then choose exactly one
initial provider route in the [Raycast AI providers guide](RAYCAST-AI-PROVIDERS.md).

## Step 5 — Grant permissions when needed

Raycast should not receive every macOS privacy permission during first launch.
Use a feature first, read its explanation, then approve only what that feature
requires.

| Feature | Permission macOS may request | Decision |
|---|---|---|
| Window management or navigation | Accessibility | Approve only if you use those commands |
| Screen-aware features | Screen Recording | Approve only when the selected command needs screen content |
| Broad file search or screenshots | Files and Folders or Full Disk Access | Prefer narrower folder access; grant broader access only for a known need |
| Script Commands | Permission is attributed to Raycast | Remember the script runs as Raycast, not Terminal |

Review permissions later in **System Settings → Privacy & Security**. Remove a
permission when the feature that justified it is no longer used.

For Raycast AI, keep tool permissions on **Ask**. If you previously chose
**Always Allow**, open Raycast Settings, search for `Globally Allowed Tools`,
review the allow-list, and remove individual tools or reset the list. AI is not
required by Day One Mac.

## Step 6 — Test the required launcher

1. Press `⌘Space` and confirm only Raycast opens.
2. Search for and open **Visual Studio Code**.
3. Open Raycast again, search for **Warp**, then press `⌘K` and inspect the
   available actions.
4. Search for one file you know exists under your home folder.
5. Restart the Mac or log out and in when convenient, then confirm Raycast starts
   automatically.

If file content search is unavailable, check that macOS Spotlight indexes the
selected folder. Raycast uses the operating system's search index for content
search.

## Export Raycast settings and data

Raycast's full export is an encrypted `.rayconfig` file.

1. Open **Raycast Settings → Advanced**.
2. Find **Export & Import Settings**.
3. Set an export passphrase of at least eight characters.
4. Save that passphrase in 1Password, not beside the export file.
5. Choose **Export Settings & Data**.
6. Save the file under:

   ```text
   /Volumes/<backup-volume>/Day-One-Mac-App-Exports/Raycast/
   ```

The export can contain settings, hotkeys, aliases, extensions, Quicklinks,
snippets, notes, clipboard data, AI objects, MCP servers, and other personal
launcher state. Keep it private even though the file is encrypted.

Some Raycast plans can schedule exports from the same Advanced settings area.
Choose daily, weekly, or monthly, select a private output folder, and set a
retention limit. A schedule is useful only if the output volume is available.

Raycast can also export Quicklinks or snippets as JSON. Those focused JSON
exports are not encrypted; inspect them for private URLs, names, or text before
sharing or committing them.

## Import without recreating old clutter

1. Make a fresh export of the current local Raycast setup first.
2. Open **Settings → Advanced → Export & Import Settings**.
3. Choose **Import Settings & Data** and select the `.rayconfig` file.
4. Enter its passphrase.
5. Review the category checklist.
6. Select only the categories needed on this Mac.
7. Complete the import, then test the main hotkey and permissions.

Raycast import is additive: it merges selected data with the current setup
rather than wiping everything first. Existing items remain, and duplicate
handling varies by data type. For a clean build, import a small category such
as reviewed Quicklinks or snippets instead of selecting every category.

Never import a work export into a personal Raycast account unless company policy
allows the data to leave the managed environment.

## Change the setup later

- Press `⌘,` in Raycast to open Settings.
- Press `⌘F` in Settings and search for `hotkey`, `login`, `files`, `AI`, or
  `export` instead of relying on an old screenshot or menu location.
- Select a command and press `⇧⌘,` to jump to that command's settings.
- Use the Action Panel to add or remove an alias or hotkey.
- Review extensions in Settings and uninstall those with no current purpose.
- Review **System Settings → Privacy & Security** after removing an extension;
  uninstalling an extension does not necessarily revoke the app's macOS access.

To rebuild a clean Raycast configuration without losing evidence:

1. Export the current state.
2. Record the hotkeys and extensions you intend to keep.
3. Remove custom extensions, aliases, hotkeys, Quicklinks, and snippets through
   Raycast Settings.
4. Reset individual areas such as File Search to their defaults where the
   current Raycast version provides that action.
5. Revoke unneeded macOS permissions.
6. Reintroduce one feature at a time and create a new baseline export.

Do not assume that moving Raycast to Trash removes its settings or cloud data.

## Add optional integrations later

- [Day One Mac Raycast commands](RAYCAST-COMMANDS.md) adds the reviewed local
  command directory and the recommended extension catalogue.
- [Second Brain — Obsidian and Raycast](../../second-brain/obsidian/GUIDE-1-OBSIDIAN-RAYCAST.md)
  adds vault-aware capture and search commands.
- [Second Brain — Notion and Raycast](../../second-brain/notion/06-RAYCAST-INTEGRATION.md)
  adds safe dashboard and private-form entry points without storing API tokens.
- [OmniRoute — Raycast AI](../02-optional/10a-omniroute.md#step-10a10--connect-raycast-ai)
  adds models from the local gateway through Raycast's supported Custom
  Providers file. It is optional, requires a paid Raycast plan, and uses a
  dedicated revocable endpoint key.
- Raycast Store extensions should be installed only after checking the
  publisher, requested permissions, and data destination.
- AI and MCP features belong to the optional Day One modules, not the required
  launcher setup.

## Troubleshooting

| Symptom | What to do |
|---|---|
| `⌘Space` still opens Spotlight | Disable **Show Spotlight search** under Keyboard Shortcuts → Spotlight, then record `⌘Space` again in Raycast |
| The shortcut does nothing | Open Raycast from Applications; check Spotlight, Input Sources, and Siri for a conflicting shortcut |
| Raycast is not available after restart | Turn on Open at Login in Raycast Settings |
| The menu bar icon is missing | Enable it in Raycast and allow it in macOS menu bar settings |
| File content is not found | Check Raycast's File Search scope and Spotlight privacy/indexing |
| Window commands fail | Grant Accessibility only if you intentionally use window management |
| Old items remain after import | Expected: import is additive; remove unwanted items explicitly |
| An AI tool acts without asking | Restore permission mode to Ask and clear globally allowed tools |

## Raycast completion checklist 🚦

- [ ] Raycast exists at `/Applications/Raycast.app`.
- [ ] The ownership check reports **Homebrew-managed** or **External installation**.
- [ ] `⌘Space` opens Raycast reliably and does not also open Spotlight.
- [ ] Spotlight indexing remains enabled for file-content search.
- [ ] Open at Login is enabled.
- [ ] Root Search can open VS Code and Warp.
- [ ] File Search covers only intended locations.
- [ ] Every macOS permission has a named feature that needs it.
- [ ] AI remains optional and its tools use Ask approval.
- [ ] A private encrypted `.rayconfig` export exists and its passphrase is in 1Password.
- [ ] Optional Day One Script Commands, when used, come from the managed directory and contain no cleanup execution shortcut.

Official references: [Raycast quickstart](https://manual.raycast.com/quickstart),
[Settings and Replace Spotlight](https://manual.raycast.com/settings#replace-spotlight),
[import and export](https://manual.raycast.com/import-export), and
[File Search](https://manual.raycast.com/file-search). Optional AI routing uses
Raycast's [Custom Providers](https://manual.raycast.com/ai/custom-providers)
format.

---

[← Required apps](README.md) · [Add Day One commands](RAYCAST-COMMANDS.md) · [Choose an AI provider](RAYCAST-AI-PROVIDERS.md) · [Configure Warp →](WARP.md) · [Second Brain options →](../../second-brain/README.md)
