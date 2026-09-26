[← Required apps](README.md) · **Raycast setup** · [Day One command pack](RAYCAST-COMMANDS.md) · [AI providers](RAYCAST-AI-PROVIDERS.md) · [Keyboard shortcuts](KEYBOARD-SHORTCUTS.md) · [Warp setup →](WARP.md)

# Set up, back up, and restore Raycast

**When:** install in the Installation Centre after Phase 2; configure after
Phase 4 · **Required app:** yes · **Extensions, AI, and Second Brain commands:** optional

**Prerequisite:** Homebrew is available from Phase 2. The Installation Centre
normally installs or verifies Raycast before Phase 3, but this guide also gives
complete Homebrew, manual-download and company-installer routes.

## Outcome

Raycast starts with macOS, always opens with `⌥Space`, searches only the
locations you expect, and receives macOS permissions only when a chosen feature
needs them. You will choose whether Spotlight also keeps its `⌘Space` window
shortcut or whether Raycast is the only keyboard launcher. You will also know
how to export, selectively import, and later change the setup.

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
day-one-mac --wizard
```

Replace `<github-user>` with the account or organisation used in the clone
path. To check only Raycast, run:

```bash
day-one-mac applications --id raycast --install-missing
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
   day-one-mac applications --id raycast
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

## Step 3 — Choose how Raycast and Spotlight work together

Raycast uses `⌥Space` in both supported paths. The choice affects only whether
the Spotlight search window keeps `⌘Space`. It never disables or removes the
Spotlight index.

Preview the recommended path:

```bash
day-one-mac raycast --launcher-mode alongside-spotlight --preview
```

Preview the Raycast-only launcher path:

```bash
day-one-mac raycast --launcher-mode raycast-only --preview
```

| Path | `⌥Space` | `⌘Space` | Spotlight indexing |
|---|---|---|---|
| **Raycast alongside Spotlight** (recommended) | Raycast Root Search | Spotlight Search | Enabled |
| **Raycast-only launcher** | Raycast Root Search | Unassigned | Enabled |

### Path A — Use Raycast alongside Spotlight

Choose this path when trying Raycast for the first time or when Spotlight still
serves a distinct search workflow.

1. Open **Raycast Settings → General**.
2. Set **Raycast Hotkey** to `⌥Space`.
3. Open **System Settings → Keyboard → Keyboard Shortcuts → Spotlight**.
4. Keep **Show Spotlight search** enabled as `⌘Space`.
5. Press `⌥Space` and confirm Raycast opens.
6. Press `⌘Space` and confirm Spotlight opens.

### Path B — Use Raycast as the only keyboard launcher

Choose this path after deciding that a separate Spotlight window is redundant.
Raycast still uses `⌥Space`; `⌘Space` is deliberately left unassigned.

1. Open **Raycast Settings → General**.
2. Set **Raycast Hotkey** to `⌥Space`.
3. Open **System Settings → Keyboard → Keyboard Shortcuts → Spotlight**.
4. Turn off only **Show Spotlight search**.
5. Do not disable Spotlight indexing or add Spotlight locations to its privacy
   list merely to hide its window.
6. Press `⌥Space` and confirm Raycast opens.
7. Press `⌘Space` and confirm it no longer opens Spotlight.

If `⌥Space` conflicts, inspect **Keyboard Shortcuts → Input Sources** and
**Apple Intelligence & Siri** before changing another binding. Do not assign
`⌥Space` to Raycast Quick AI; Root Search owns it in both paths.

To switch paths later, change only **Show Spotlight search**. Keep Raycast on
`⌥Space` and keep Spotlight indexing enabled.

## Step 4 — Configure the baseline manually

Open Settings with `⌘,` while Raycast is visible. In current Raycast versions,
`⌘F` searches settings if a label has moved.

The settings below are the recommended coexistence baseline. They keep
Spotlight available for Apple-native and system content while Raycast handles
applications, commands and developer workflows. The Raycast-only path uses the
same Raycast settings; only the Spotlight window shortcut differs.

### Launcher

| Area | Day One choice | Why |
|---|---|---|
| Open at Login | On | The launcher is available after restart |
| Main hotkey | `⌥Space` | Stays consistent whether Spotlight's window shortcut is enabled or disabled |
| Show Raycast on | Screen with active window | Results appear beside the work currently in focus |
| Pop to Root Search | Immediately or after 5 seconds | A reopened launcher starts predictably without preserving stale context for long |
| Menu bar icon | Personal choice | It changes visibility, not function |
| Root Search sensitivity | Default | Tune it only after using real searches |
| Files in Root Search | On | Approved project and document matches appear without opening a separate command |
| Contacts in Root Search | Off initially | Spotlight already handles Apple Contacts; enable this only if Raycast adds value |
| AI permissions | Ask | Keeps tool actions visible and reviewable |
| Quick AI global hotkey | None | `⌥Space` belongs to Root Search in both launcher modes |
| Community extensions | None initially | Add one only for a defined need |

Try the two core controls:

- `⌥Space` opens **Root Search**.
- `⌘K` opens the **Action Panel** for the selected result.

Create aliases or dedicated hotkeys only for commands used repeatedly. Too many
global shortcuts become harder to remember and are more likely to conflict.

After the required base is complete, the optional [Day One Raycast command pack](RAYCAST-COMMANDS.md)
can generate safe, track-aware and AI-aware Script Commands. It keeps setup
checks searchable without assigning dozens of global shortcuts.

### Fallback commands

Fallback commands appear when Root Search has no direct match. Keep this list
short and ordered by actual use:

1. **Search Files** for approved local folders.
2. A web-search command for the preferred browser and search engine.
3. **Quick AI** only when Raycast AI was deliberately selected.
4. Calculator or another frequently used built-in command.

Quick AI does not need a global shortcut. Open it from Root Search, use its
in-Root-Search trigger, or keep it as a fallback command. This leaves
`⌥Space` permanently assigned to Root Search.

### Divide search responsibilities

Giving each launcher a primary role makes their results complementary instead
of duplicating the same broad search.

| Use Spotlight for | Use Raycast for |
|---|---|
| Apple-native files and application content | Launching applications and commands |
| Mail, Messages, Contacts, Calendar and Reminders | Day One Mac Script Commands and aliases |
| System Settings and Apple Shortcuts | Project, repository and terminal launchers |
| Broad macOS search and system actions | Quicklinks, window management and reviewed extensions |
| Content supplied by Apple applications | Optional AI workflows with explicit approval |

### File Search

1. Open **Raycast Settings → Extensions → File Search**.
2. Include only locations used regularly, such as the home folder,
   `~/Developer`, Documents, Downloads when useful, and approved Obsidian
   vaults.
3. Exclude noisy or sensitive locations such as `node_modules`, `.git`, build
   outputs, caches, `~/Library`, encrypted backups, password exports, secret
   directories, and work folders that Raycast must not inspect.
4. Prefer permission for individual folders over Full Disk Access.
5. Test one known project file by name and, if required, by content.

Keep Spotlight indexing enabled in both launcher modes. Disabling the Spotlight
window shortcut does not require changing its index or privacy list.

### Spotlight search settings

Open **System Settings → Spotlight** or **Siri & Spotlight**. Keep the useful
local categories enabled while removing duplicate or unwanted surfaces:

| Spotlight area | Recommended setting |
|---|---|
| Applications and System Settings | On |
| Documents, folders and PDFs | On |
| Mail, Messages, Contacts, Calendar and Reminders | On when those Apple apps are used |
| Developer tools | On |
| Images, music and other media | Personal choice |
| Related web content | Off when Spotlight should stay focused on local and system results |
| Help Apple Improve Search | Off when minimizing search telemetry is preferred |
| Clipboard Search | Off when Raycast Clipboard History is enabled; avoid two searchable clipboard surfaces |

Open **Search Privacy** and exclude only specific private or irrelevant folders.
Do not exclude the entire internal disk. Remember that Spotlight privacy and
Raycast File Search are separate boundaries: review exclusions in both places.

### Shortcut audit

Open **Raycast Settings → Shortcuts** and confirm:

- Root Search alone owns `⌥Space`.
- Quick AI has no default global shortcut.
- `⌘\` remains available for 1Password Universal Autofill.
- infrequent Day One commands use aliases instead of global hotkeys.
- any imported shortcut has been checked for conflicts.

### Clipboard History

Enable this only when personal or company policy permits clipboard capture.
Open its settings and exclude 1Password, Passwords, Keychain Access and any
sensitive work application. Copy a harmless sentence, find it in Clipboard
History, then confirm copied credentials from an excluded app do not appear.
When it is enabled, turn off Spotlight Clipboard Search so only one reviewed
clipboard surface remains searchable.

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

### Extensions

Start with Raycast's built-in commands. Add a Store extension only for a
defined task, after reviewing its publisher, requested access, authentication
scope and data destination. Do not recreate a Spotlight feature in Raycast
merely to make both launchers return the same results.

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

1. Press `⌥Space` and confirm Raycast opens.
2. Test `⌘Space`: it opens Spotlight in alongside mode and remains unassigned
   in Raycast-only mode.
3. Search for and open **Visual Studio Code**.
4. Open Raycast again, search for **Warp**, then press `⌘K` and inspect the
   available actions.
5. Use Raycast to find a known project file under `~/Developer`.
6. Use Spotlight to find a known System Settings item or Apple-app record.
7. Confirm a deliberately excluded folder and a credential copied from an
   excluded application do not appear unexpectedly.
8. Restart the Mac or log out and in when convenient, then confirm Raycast starts
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
| `⌥Space` does not open Raycast | Open Raycast from Applications, confirm its hotkey is `⌥Space`, then inspect Input Sources and Siri for conflicts |
| `⌘Space` does not match the chosen mode | Enable **Show Spotlight search** for alongside mode or disable only that shortcut for Raycast-only mode |
| Raycast is not available after restart | Turn on Open at Login in Raycast Settings |
| The menu bar icon is missing | Enable it in Raycast and allow it in macOS menu bar settings |
| File content is not found | Check Raycast's File Search scope and Spotlight privacy/indexing |
| Window commands fail | Grant Accessibility only if you intentionally use window management |
| Old items remain after import | Expected: import is additive; remove unwanted items explicitly |
| An AI tool acts without asking | Restore permission mode to Ask and clear globally allowed tools |

## Raycast completion checklist 🚦

- [ ] Raycast exists at `/Applications/Raycast.app`.
- [ ] The ownership check reports **Homebrew-managed** or **External installation**.
- [ ] `⌥Space` opens Raycast reliably.
- [ ] `⌘Space` opens Spotlight in alongside mode or remains unassigned in Raycast-only mode.
- [ ] Spotlight indexing remains enabled for file-content search.
- [ ] Open at Login is enabled.
- [ ] Root Search can open VS Code and Warp.
- [ ] File Search covers only intended locations and excludes noisy or sensitive paths.
- [ ] Spotlight result categories and Search Privacy match the intended Apple-native search scope.
- [ ] Only one reviewed clipboard-search surface is enabled.
- [ ] Every macOS permission has a named feature that needs it.
- [ ] AI remains optional and its tools use Ask approval.
- [ ] A private encrypted `.rayconfig` export exists and its passphrase is in 1Password.
- [ ] Optional Day One Script Commands, when used, come from the managed directory and contain no cleanup execution shortcut.

Official references: [Raycast quickstart](https://manual.raycast.com/quickstart),
[Settings and Replace Spotlight](https://manual.raycast.com/settings#replace-spotlight),
[import and export](https://manual.raycast.com/import-export), and
[File Search](https://manual.raycast.com/file-search). See also
[Quick AI](https://manual.raycast.com/ai/quick-ai),
[Apple Spotlight settings](https://support.apple.com/guide/mac-help/mchl54d95e8a/mac),
and [Apple Spotlight indexing and privacy](https://support.apple.com/102321).
Optional AI routing uses
Raycast's [Custom Providers](https://manual.raycast.com/ai/custom-providers)
format.

---

[← Required apps](README.md) · [Add Day One commands](RAYCAST-COMMANDS.md) · [Choose an AI provider](RAYCAST-AI-PROVIDERS.md) · [Configure Warp →](WARP.md) · [Second Brain options →](../../second-brain/README.md)
