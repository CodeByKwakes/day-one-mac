[← Application setup](README.md) · [Keyboard shortcuts](keyboard-shortcuts.md) · [VS Code setup](../editors/vscode.md)

# Optional macOS Shortcuts for development

Use this guide to clone repositories and open selected project folders. Create
shortcuts with the native actions below, or import the reviewed VS Code export.
The Git Clone source is readable AppleScript that you paste into a new shortcut.
Folder selections, permissions and Finder toolbar placement remain local choices.
For apps that contain their own code, follow [standalone app creation](#build-standalone-apps-manually).
The optional `day-one-shortcuts` skill can assist with the same recipes; see
[skill installation](../ai/day-one-skills.md#optional-specialist-skills).

The Finder **Open in VS Code** recipe was tested on macOS 26.7.1 with a folder
whose name contained spaces. It uses the built-in **Open File** action; no
shell script, `code` launcher, or **Allow Running Scripts** setting is needed.
The other recipes are optional configurations to verify on your own Mac.

## Choose a shortcut

| Shortcut or action | Use it for | Requires |
|---|---|---|
| Git Clone | Choose a repository URL, destination and folder name | Git, existing authentication and script permission |
| Open in Warp | Send the selected Finder folder to Warp | Warp; verify the resulting directory |
| Open in VS Code | Open the folder selected in Finder | VS Code |
| Open with VS Code Profile | Choose an existing profile before opening a folder | Stable VS Code and readable local profile metadata |
| Open Development Workspace | Open one folder in VS Code and Warp | Both stable applications |
| Open Selected Folder in VS Code | Run from a Finder toolbar button | A toolbar copy configured below |
| Open Project in VS Code | Choose a folder when launching the shortcut directly | VS Code and the first recipe |
| Open Developer Folder | Return to your chosen development root | An existing development folder |
| New Terminal at Folder / New Warp Tab Here | Start a shell in the selected folder | The relevant Finder service |
| Copy Folder Path | Copy an exact path for a command or support request | Finder only |

Start with **Open in VS Code**. Add other shortcuts only when you use them
regularly. Keep the global key assignments in the
[keyboard shortcut reference](keyboard-shortcuts.md#recommended-global-shortcut-ownership).

## Understand launcher apps and transferable shortcuts

A `.app` made by **File → Add to Dock** launches an installed shortcut. It does
not contain an independent backup of the workflow. Create its replacement on
the destination Mac after importing or rebuilding the shortcut.

The supplied launcher copies and installed actions were inspected on
25 October 2026. Their `ShortcutMetadata.plist` files contain local shortcut
identifiers, and their `Info.plist` files declare a minimum macOS version of 26.7.
Those particular launchers are unsuitable as general-purpose repository assets.
The source recipes below do not inherit that binary minimum; verify actions on
your installed macOS version.

| Reviewed shortcut | Input and actions | Portable repository form |
|---|---|---|
| Git Clone | One AppleScript action asks for a URL, parent folder, name and confirmation | [Reviewed source](../../../../integrations/shortcuts/git-clone.applescript); create the action below |
| Open in VS Code | Receives Shortcut Input and opens it in VS Code | Existing signed export plus the manual recipe below |
| Open in Warp | Get Selected Files in Finder, then Open File in Warp | Native-action recipe below; no signed Warp export is supplied |

Git Clone's supplied action used a personal default folder. The repository
source uses the current user's home folder as the picker's starting point.
It rejects credential-bearing HTTPS authorities, SSH passwords, query strings
and control characters. It reserves a new destination immediately before Git
runs, so a directory created after the confirmation preview also causes failure.

The source is compiled and its validation, quoting and destination behaviour
are tested in `tests/integration/test-finder-shortcuts.cjs` using a mock Git.
An isolated real Git configuration verifies the custom SSH command guard.
That fixture does not prove live authentication, UI permissions or application
opening. Follow each verification step on the destination Mac.

## Create Git Clone

### Prerequisites

Install Git through your chosen owner and verify `git --version` in Terminal.
For private repositories, first verify access through your existing SSH agent
or credential manager. Never put a token or password in the clone URL.
The shortcut prefers `/opt/homebrew/bin/git`, then `/usr/bin/git`.

Standard SSH settings in `~/.ssh/config` remain supported. If Git uses
`core.sshCommand`, `GIT_SSH_COMMAND` or `GIT_SSH`, clone in Terminal instead.
The shortcut stops when it detects these settings, before creating a destination,
so it cannot silently replace your selected identity, proxy or SSH wrapper.
Finder does not inherit environment variables set only in an open Terminal;
Terminal authentication alone does not verify the shortcut's environment.

Review the linked source before enabling scripts. This shortcut needs
**Shortcuts → Settings → Advanced → Allow Running Scripts**. On a managed Mac,
obtain the required approval; leave this option off if you do not need scripted
shortcuts. VS Code and Warp's native Open File recipes do not need it.

### Create and configure the action

1. In Shortcuts, choose **File → New Shortcut**.

   Expected result: an empty shortcut editor.

2. Name it **Git Clone**, or use a distinct name when one already exists.

   Expected result: the existing shortcut remains available for comparison.

3. Search the Action Library for **Run AppleScript** and add that action.

   Expected result: one script action with an editable source field.

4. Copy the complete [Git Clone source](../../../../integrations/shortcuts/git-clone.applescript)
   into the action, replacing its sample code.

   Expected result: the source begins with comments and an `on run` handler.
   Include the helper handlers below it. No path to a checkout is required.

5. Click the action's **Build** button.

   Expected result: AppleScript compiles without an error. Do not run an
   incomplete or modified copy until its changes have been reviewed.

6. Run the shortcut and enter a trusted clone URL. Choose the parent folder,
   review the suggested name and approve the full destination.

   Expected result: Git downloads and checks out into a newly created folder.
   Existing directories, files and symlinks are refused. SSH password prompts
   and Git's terminal prompt are disabled; account setup belongs in Terminal.

7. Choose **Show in Finder**, **Open in VS Code** or **Done** when cloning finishes.

   Expected result: the chosen action uses the exact clone directory. Opening
   VS Code requires it to be installed and still respects Workspace Trust.

Git uses existing credential and filter configuration. The clone command disables
Git hooks for this operation and rejects the external command transport. It does
not install dependencies or run a package manager. Use only trusted repositories.
The GUI can wait during a large clone; this version has no progress display.

### Verify, maintain and recover

Use a small public test repository or an approved private repository. Choose a
new folder name containing spaces, then verify it in Terminal:

```bash
git -C "/absolute/path/to/your/new clone" remote -v
git -C "/absolute/path/to/your/new clone" status --short --branch
```

Expected result: the intended remote and a checked-out branch. Inspect remote
URLs locally; do not publish credentials or private repository names.
Run the shortcut again with the same destination. Expected result: it refuses
before downloading or overwriting files. Cancel a fresh run before **Clone**;
no destination folder should be created.

A failed clone leaves its new directory for inspection. Check authentication in
Terminal, inspect that exact directory and select a new destination for a retry.
Delete a partial clone only after confirming it has no work you need. If the
clone succeeds but opening VS Code fails, the repository still exists; open it
manually rather than cloning again.

To update, duplicate the shortcut, replace the source in the copy, compile and
repeat verification. Keep the previous shortcut until the copy works. Restore
by selecting the previous shortcut; cloning does not change global Git settings.

## Create Open in Warp

Use this toolbar recipe only for selected ordinary folders. The reviewed shortcut
contains two native actions and no shell script. It has no fallback to the
current Finder window when nothing is selected.

1. In Shortcuts, create a new shortcut named **Open in Warp**.

   Expected result: an empty editor, without replacing another shortcut.

2. Add **Get Selected Files in Finder** as the first action.

   Expected result: Finder's selected item is available as an output variable.

3. Add **Open File** and set its input to the first action's output variable.

   Expected result: the input is **Selected File**, not literal text or
   **Shortcut Input**.

4. Set the application in **Open File** to **Warp** and leave **Show Open In Menu** off.

   Expected result: the second action reads **Open Selected File in Warp**.

5. Select one test folder in Finder, then run the shortcut.

   Expected result: Warp opens the requested location. In the new shell run
   `pwd`, and compare the result with Finder's **Copy as Pathname** value.
   Repeat with a different folder whose name contains spaces.

6. If both checks pass, use the [toolbar instructions](#add-a-finder-toolbar-button)
   to create and pin its local launcher. Skip the VS Code duplication steps:
   this Warp recipe already reads the selection.

   Expected result: the toolbar button opens the folder you select each time.

If Warp opens without changing directory, use its documented
[Finder service](#use-existing-terminal-services) instead. Warp's
[files and links documentation](https://docs.warp.dev/terminal/more-features/files-and-links)
describes services and folder drops; it does not establish this particular
Shortcuts workflow's behaviour on every release. Never assume the current
working directory from the window title alone.

## Create Open in VS Code

### 1. Create the shortcut and enable Finder

1. Open **Finder → Applications → Shortcuts**.
2. In Shortcuts, choose **File → New Shortcut**.
3. Click the name at the top and enter **Open in VS Code**.
4. Click **Shortcut Details** (the circled **i** at the top right).
5. In **Details**, enable **Use as Quick Action**, then enable **Finder**.

### 2. Choose the input type

1. At the top of the main editing area, find **Receive … from Quick Actions**.
2. Click the blue input-type text after **Receive**. Initially it can say
   **Apps and 18 more** rather than **Folders**.
3. In that popup, select **Folders** under **Documents** and clear the other
   selected types. Scroll through the list to check them all.
4. Click outside the popup to close it.

**Folders is an input type, not an action in the Action Library.** On the
validated Mac the summary displayed **Folders and Apps** even though the
folder selection was used; application bundles can be treated as folders.
Use this shortcut on ordinary project folders.

### 3. Add the Open File action

1. Click **Action Library**, beside **Shortcut Details** at the top right.
2. In **Search Actions**, type **Open File**.
3. Double-click **Open File** to add it to the shortcut.
4. In the new action, set the first field to **Shortcut Input** if it is not
   already selected. Choose the variable, not literal text.
5. Click **Default App**, search for **Visual Studio Code**, and select it.
6. Leave **Show Open In Menu** off if that option is shown.

The action should read **Open Shortcut Input in Visual Studio Code**.
There is no folder path to type: Finder supplies the selected folder.
Close the editor; Shortcuts saves automatically.

### 4. Verify it from Finder

1. Create an empty folder named **Shortcut Test Folder** in a convenient place.
2. Right-click that folder itself, not empty space inside it.
3. Choose **Quick Actions → Open in VS Code**.
4. Confirm VS Code's Explorer shows **Shortcut Test Folder** as its root.
5. Close the test window and remove the empty test folder when finished.

For a real repository, open the individual repository or worktree folder.
Review any Workspace Trust prompt for that folder; opening a folder does not
require trusting the entire developer root.

## Add a Finder toolbar button

An imported or manually created VS Code shortcut provides a Finder Quick
Action. Pinning an app to Finder's toolbar is a separate local setup step. The diagram below shows the toolbar route; it is a schematic, not a
screenshot. This toolbar variant has not been tested end to end by this guide.

```text
SET UP ONCE

Shortcuts: duplicate and configure the toolbar copy
                         |
                         v
Shortcuts menu: File > Add to Dock
                         |
                         v
Dock icon: right-click > Options > Show in Finder
                         |
                         v
Hold Command + drag the revealed app to Finder's top toolbar
                         |
                         v
Release when the green + appears
```

### 1. Give the toolbar copy its own folder input

A toolbar click launches the shortcut's app. It does not automatically pass
Finder's selection as **Shortcut Input**, so first configure a copy to read
that selection explicitly.

1. In Shortcuts' main window, right-click **Open in VS Code → Duplicate**.
2. Rename the copy **Open Selected Folder in VS Code** and open it.
3. In **Action Library → Search Actions**, search for **Get Selected Files in
   Finder** and add it. Despite its name, the action can return folders.
4. Drag that action above the existing **Open File** action.
5. In **Open File**, click **Shortcut Input** and replace it with the output
   variable from **Get Selected Files in Finder**. Keep **Visual Studio Code**
   as the app. Select the variable token rather than typing its name as text.
6. In **Shortcut Details**, turn off **Use as Quick Action → Finder** for this
   copy to avoid a second entry in Finder's Quick Actions menu. Keep the
   original shortcut's Finder setting enabled.

The two entry points now obtain their input differently:

```text
ORIGINAL QUICK ACTION                TOOLBAR COPY

Right-click a folder                 Select a folder in Finder
         |                                      |
         v                                      v
Quick Actions > Open in VS Code       Click the toolbar app button
         |                                      |
         v                                      v
Shortcut Input                       Get Selected Files in Finder
         |                                      |
         v                                      v
Open File in Visual Studio Code      Open File in Visual Studio Code
```

Select one project folder before using the toolbar copy. It opens the selected
item; it does not infer the current window's folder when nothing is selected.
To work with the folder you are currently browsing, first press `⌘↑` to show
its parent, then select that folder. Use the
[project-picker recipe](#add-open-project-in-vs-code) instead if you prefer to
choose a folder each time.

### 2. Create the launcher and pin it

1. With **Open Selected Folder in VS Code** selected in Shortcuts, choose
   **File → Add to Dock** from the menu bar at the top of the screen.
2. Find its new icon in the Dock. Right-click it and choose
   **Options → Show in Finder**. This reveals the generated app launcher;
   use that app, not the exported `.shortcut` import file.
3. In Finder, choose **View → Show Toolbar** if the toolbar is hidden.
4. Hold **⌘ Command** and drag the revealed app onto Finder's **top toolbar**,
   beside the existing view/action buttons. Keep Command held during the drag.
5. Release the mouse when the **green +** appears, then release Command.

```text
FINDER WINDOW — SCHEMATIC

+--------------------------------------------------------------+
| Back  Forward    Folder name    View  Actions  [YOUR BUTTON]   |
|                                               ^              |
|                         Command-drag the app here             |
+--------------+-----------------------------------------------+
| Sidebar      | Folder contents                               |
|              |                                               |
|              | [selected project folder]                     |
+--------------+-----------------------------------------------+

Target: the TOP toolbar, not the sidebar or the folder contents.
```

Apple documents [adding a shortcut to the Dock](https://support.apple.com/en-euro/guide/shortcuts-mac/apd163eb9f95/mac)
and [Command-dragging an app into Finder's toolbar](https://support.apple.com/en-om/guide/mac-help/-mchlp3011/mac).
The shortcut's generated app connects those two operations.

### 3. Test and tidy up

1. In Finder, select an empty test folder named **Toolbar Test Folder**.
2. Click the new toolbar button. Confirm VS Code opens that exact folder.
3. Select a different folder and repeat, confirming the selection determines
   the result. Review any first-run permission prompt for the intended action.
4. Check **right-click → Quick Actions → Open in VS Code** still works through
   the original shortcut.
5. Close the test windows and remove the empty test folder when finished.

To keep only the toolbar button, right-click the Dock icon and choose
**Options → Remove from Dock**. Keep the generated app itself in place;
deleting or moving it can break the toolbar link.

To remove the toolbar button, hold **⌘ Command** and drag it out of the toolbar.
This removes the toolbar item, not the original shortcut. Toolbar placement is
local to this Mac; repeat the pinning step on another Mac.

## Add Open Project in VS Code

Use a folder picker when you want to start from Shortcuts instead of Finder.

1. In Shortcuts' main window, right-click **Open in VS Code** and choose
   **Duplicate**. Name the copy **Open Project in VS Code**.
2. Open the copy. In its **Receive** block, click **Continue** beside
   **If there's no input** and choose **Ask For**. Select **Folders** as the
   requested input type if prompted.
3. Keep **Open Shortcut Input in Visual Studio Code** as the action.
4. Run the shortcut from Shortcuts and choose a project folder.
5. Confirm VS Code opens that folder, including when its name contains spaces.

To make it searchable, enable **Shortcut Details → Show in Spotlight** where
available. Use Spotlight only if enabled in your chosen launcher mode; running
from the Shortcuts app works in either mode. The original Finder action can
keep its existing behavior when no input is supplied.

## Add Open Developer Folder

Use a saved folder selection rather than a hard-coded username.

1. Create a new shortcut named **Open Developer Folder**.
2. Add the **File** action from the Action Library.
3. Click its file field and select your existing development folder in the
   picker. The selected item should be the folder itself.
4. Add **Open File** underneath it and set its input to the **File** action's
   output. Choose **Finder** as the app.
5. Run it and confirm Finder shows your chosen development root.

For the standard layout, the folder is `~/Developer`. Here `~` means your own
home folder. In a file picker, press `⇧⌘G`, enter `~/Developer`, then press
Return. If you kept a different existing layout, select that folder instead;
this shortcut does not create or reorganize it. See
[developer folder choices](../development/folders.md).

## Use existing terminal services

You do not need another Shortcuts workflow to open a shell in a folder.

1. In Finder, right-click the project folder and open **Services**.
2. Choose **New Terminal at Folder**, or **New Warp Tab Here** when Warp's
   service is available. **New Warp Window Here** opens a separate window.
3. In the new shell, run `pwd` and confirm it prints the selected folder's path.

If a service is missing, check **System Settings → Keyboard → Keyboard
Shortcuts… → Services → Files and Folders** and enable the relevant installed
service. Warp must be installed to provide its services. The [Open in Warp shortcut](#create-open-in-warp) is an optional alternative.
Opening an app alone does not prove its shell starts in the selected directory;
verify that workflow with `pwd` before relying on it.

For a launcher alternative, follow the [Raycast guide](raycast.md).
No Day One Mac command or installed manager is required.

## Copy a folder path without creating a shortcut

1. Select the folder in Finder.
2. Press `⌥⌘C` to copy its pathname. Alternatively, hold Option while opening
   Finder's **Edit** menu and choose **Copy … as Pathname**.
3. Paste into a text editor to verify the path before using it in a command.

The clipboard contains an absolute path, not shell-escaped text. Put the path
in quotes when a shell command expects one argument and it contains spaces.
Do not publish paths containing private project or account names.

## Build standalone apps manually

A standalone AppleScript app contains its executable workflow. It does not need
an installed Shortcuts workflow, a skill or the source checkout after creation.
The source uses macOS frameworks and system tools; Node.js is not needed to run
the resulting app. Application permissions and target tools remain prerequisites.
Apple documents [saving a script as an application](https://support.apple.com/guide/script-editor/save-a-script-as-an-app-scpedt1072/mac).

### Select and compile the source

1. Choose one recipe and review its source files in the order shown:

   | App name | Source order | Required when running |
   |---|---|---|
   | Git Clone | [Git Clone](../../../../integrations/shortcuts/git-clone.applescript) only | Git and configured authentication |
   | Open in VS Code | [Shared folder handlers](../../../../integrations/shortcuts/folder-common.applescript), then [VS Code entry](../../../../integrations/shortcuts/open-in-vscode.applescript) | Stable VS Code |
   | Open in Warp | Shared folder handlers, then [Warp entry](../../../../integrations/shortcuts/open-in-warp.applescript) | Stable Warp |
   | Open with VS Code Profile | Shared folder handlers, then [profile entry](../../../../integrations/shortcuts/open-vscode-profile.applescript) | Stable VS Code with existing profile metadata |
   | Open Development Workspace | Shared folder handlers, then [workspace entry](../../../../integrations/shortcuts/open-development-workspace.applescript) | Stable VS Code and Warp |

   Expected result: the selected app's dependencies are clear. The
   [catalogue](../../../../integrations/shortcuts/catalog.json) records matching
   recipe IDs and build metadata. The source does not install dependencies.

2. In Script Editor, choose **File → New** and select **AppleScript** as the language.

   Expected result: a new AppleScript document.

3. Paste the selected source. For a folder app, paste the shared handlers first,
   then exactly one entry source into the same document.

   Expected result: one `on run` handler and, for folder apps, one `on open`
   handler. Do not combine entry sources for multiple apps.

4. Click **Compile**.

   Expected result: no syntax error. Compilation does not test permissions,
   authentication or application opening.

5. Choose **File → Export** and set **File Format → Application**.

   Expected result: an application export dialog. Keep **Stay open after run
   handler**, **Show startup screen** and **Run-only** off.

6. Save with the selected app name inside a new review folder.

   Expected result: a `.app` bundle. Keep existing installed copies in place;
   choose another destination if the export would overwrite anything.

7. Repeat only for the other apps you want.

   Expected result: separate apps with separate entry handlers. No background
   service is installed. Save the readable script documents alongside the apps
   if you want local editable copies.

To create a native Shortcuts version of the profile or workspace app, paste its
combined source into one **Run AppleScript** action. Compile it there and enable
script permission only for that use. Running this source reads Finder selection
or shows a picker; it does not use **Shortcut Input**. Keep the native VS Code
Quick Action recipe above when you want Finder to supply that variable directly.

### Folder input and profile behaviour

Folder apps accept one dropped folder. With no dropped input, they read Finder's
selection and use a folder picker when nothing is selected. Launching the app
itself from Finder also falls back to the picker. Files, application bundles,
multiple selections and the filesystem root are refused. If Finder access is
denied, the picker remains available. Canceling a picker or profile list opens
no target application.

The profile chooser reads registered named profiles from stable VS Code's local
`~/Library/Application Support/Code/User/globalStorage/storage.json`. This is an
internal format and may change. Each record needs a name and nonempty string
location. It stops when the list is missing, ambiguous or invalid, and checks
the selected name again before dispatch. The built-in default profile is omitted
because its name is localized; select it through VS Code's **Profiles** menu.
Use VS Code's
**Profiles** menu for Insiders, portable mode or custom user-data locations.

Avoid renaming or deleting profiles during launch. The read-only check and VS
Code's subsequent launch are separate operations. A profile removed between them
can still be recreated empty by VS Code's `--profile` option. That behaviour is
documented in [the VS Code CLI reference](https://code.visualstudio.com/docs/configure/command-line#_select-a-profile).
The app never edits profile settings or installs extensions.

The standalone Warp app uses a percent-encoded
`warp://action/new_tab?path=...` URL, as documented in
[Warp's URI scheme](https://docs.warp.dev/terminal/more-features/uri-scheme).
It sends no command to the new terminal. Your existing shell startup behaviour
still applies. Workspace opening checks both applications first, then opens VS
Code followed by Warp at the same folder. It does not start a development server.

### Verify and install the apps

1. Inspect the app's source in Script Editor before the first run.

   Expected result: it matches the selected recipe. Helper-built apps also have
   a combined source file and build manifest in their review directory.

2. Run a selected folder app against a disposable folder containing spaces.

   Expected result: the target receives the exact folder. Check the VS Code
   Explorer root or run `pwd` in Warp. For the workspace app, check both.

3. Test the profile app with an existing profile.

   Expected result: the profile indicator matches your choice. Cancel another
   selection and confirm that no new window opens. If metadata checks fail,
   open the folder and choose its profile through VS Code manually.

4. Drag one folder onto a folder app, then try two folders and a regular file.

   Expected result: one folder opens; unsupported selections show an error.
   Test Git Clone separately with its [clone verification](#verify-maintain-and-recover).

5. Move only the verified apps into a stable folder you own, such as
   `~/Applications/Developer Shortcuts/`.

   Expected result: app paths remain stable. Use another name or preserve an
   existing copy before replacing it. Permission prompts are local choices;
   do not disable Gatekeeper or managed-device controls to force an app to run.

6. Hold Command and drag an app from Finder onto Finder's toolbar, or drag it
   to the Dock.

   Expected result: a launcher entry pointing to that app. For standalone apps,
   skip **File → Add to Dock** in Shortcuts; that menu creates a different kind
   of launcher that depends on an installed workflow.

Automated tests compile the five apps and verify their generated bundles and
pure handlers. Live Finder permissions, workspace opening and provider access
still require the checks above. If only one workspace application opens, retain
that window and open the other manually.

### Update, recover and remove standalone apps

1. Build or export a new copy into a fresh review folder.

   Expected result: the installed copy remains unchanged. Skill updates alone
   never update a previously generated app.

2. Verify the replacement and move the existing owned app to a private backup folder.

   Expected result: the original remains recoverable. Preserve personal edits
   deliberately instead of replacing an unknown copy.

3. Put the replacement at the intended stable path and repeat its functional check.

   Expected result: it works from both Finder and the toolbar or Dock. Re-add a
   launcher entry if it still targets the backup. Keep the backup until satisfied.

To roll back, preserve the failed replacement separately and restore the prior
app to its former path. macOS may ask for automation permission again after a
rebuild. Review that prompt for the selected app.

To remove a standalone app, remove its toolbar/Dock entry and move only that
owned `.app` to Trash. Keep its source and backup until you no longer need them.
This does not remove cloned repositories, VS Code profiles, Warp configuration
or a separate native Shortcuts workflow. Removing the skill is another operation;
follow [skill removal](../ai/day-one-skills.md#update-and-remove) for that scope.

<a id="keep-move-or-remove-these-shortcuts"></a>

## Keep, move, or remove native shortcuts

- **Keyboard access:** open a shortcut, then **Shortcut Details → Add Keyboard
  Shortcut**. Choose an unused combination; no global key is assigned by these
  recipes.
- **Hide from Finder:** clear **Shortcut Details → Use as Quick Action → Finder**.
- **Remove:** in Shortcuts' main window, right-click the shortcut and choose
  **Delete**. This removes the workflow, not the project folder or report.
- **Move to another Mac:** export the shortcut workflow, then create the launcher
  again on the destination Mac. Copying a generated `.app` alone is insufficient.

### Export, import and recreate the launcher

1. In Shortcuts, select the verified shortcut and choose **File → Export**.

   Expected result: a save dialog for a `.shortcut` file.

2. Review the **For** option before saving. **Anyone** sends a copy to Apple for
   validation. **People Who Know Me** includes your contact information and is
   unsuitable for this public repository.

   Expected result: the sharing scope matches your intent. Remove private paths,
   credentials and saved file bookmarks before making a public export. Apple
   documents these behaviours in [Share shortcuts on Mac](https://support.apple.com/guide/shortcuts-mac/share-shortcuts-apdf01f8c054/mac).

3. On the destination Mac, open the reviewed export and inspect its actions before
   choosing **Add Shortcut**.

   Expected result: a new installed shortcut. Resolve name conflicts deliberately;
   keep a working original until the replacement has passed its checks.

4. Reselect any saved folders and applications, then repeat the relevant
   verification steps in this guide.

   Expected result: the shortcut works with that Mac's paths, apps and permissions.

5. Use **File → Add to Dock** and the Finder toolbar steps to create a new launcher.

   Expected result: the launcher points to the shortcut installed on that Mac.
   Keep the launcher in a stable local folder. Removing its Dock icon is safe;
   deleting the app or installed shortcut can break the Finder button.

## Troubleshooting

| Symptom | Check |
|---|---|
| No entry under Finder Quick Actions | Enable **Use as Quick Action → Finder**, check the input type, and right-click an actual folder |
| Action opens Finder instead of VS Code | Change **Default App** to **Visual Studio Code** in **Open File** |
| Shortcut asks to enable scripts | Git Clone intentionally needs script permission; the VS Code and Warp native recipes do not |
| Nothing happens when pressing Run | The Finder recipe needs selected-folder input; test from Finder or use the picker recipe |
| A saved folder or report cannot be found | Reselect it in the **File** action after moving it or importing the shortcut |
| Toolbar button runs but no folder opens | Configure the toolbar copy to read **Get Selected Files in Finder**, use its output in **Open File**, and select a folder first |
| Dragging does not add a toolbar button | Hold Command while dragging the generated app from Finder; wait for the green + over the top toolbar |
| Toolbar button stops working after cleanup | Check the generated app still exists; removing its Dock icon is different from deleting the app |
| A command-line run fails | Test the actual Finder Quick Action; a CLI error alone does not establish that the Finder workflow is broken |

---

[← Application setup](README.md) · [Keyboard shortcuts](keyboard-shortcuts.md) · [VS Code setup](../editors/vscode.md)
