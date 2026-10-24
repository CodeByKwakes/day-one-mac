[← Application setup](README.md) · [Keyboard shortcuts](keyboard-shortcuts.md) · [VS Code setup](../editors/vscode.md)

# Optional macOS Shortcuts for development

Use this guide to open projects and frequently used folders with fewer steps.
The optional utility workflow can open a bundled **Open in VS Code** shortcut for
import; you review it and click **Add Shortcut** in Apple Shortcuts. The manual
route can build the same action below. Folder-specific launchers still need
local file selections. Each recipe is optional; choose the ones you use.

The Finder **Open in VS Code** recipe was tested on macOS 26.7.1 with a folder
whose name contained spaces. It uses the built-in **Open File** action; no
shell script, `code` launcher, or **Allow Running Scripts** setting is needed.
The other recipes are optional configurations to verify on your own Mac.

## Choose a shortcut

| Shortcut or action | Use it for | Requires |
|---|---|---|
| Open in VS Code | Open the folder selected in Finder | VS Code |
| Open Selected Folder in VS Code | Run from a Finder toolbar button | A toolbar copy configured below |
| Open Project in VS Code | Choose a folder when launching the shortcut directly | VS Code and the first recipe |
| Open Developer Folder | Return to your chosen development root | An existing development folder |
| New Terminal at Folder / New Warp Tab Here | Start a shell in the selected folder | The relevant Finder service |
| Copy Folder Path | Copy an exact path for a command or support request | Finder only |

Start with **Open in VS Code**. Add other shortcuts only when you use them
regularly. Keep the global key assignments in the
[keyboard shortcut reference](keyboard-shortcuts.md#recommended-global-shortcut-ownership).

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

**Shared manual action for both routes.** The assisted import creates a Finder
Quick Action. Pinning an app to Finder's toolbar is a separate local setup
step. The diagram below shows the toolbar route; it is a schematic, not a
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
service. Warp must be installed to provide its services. Do not use the
**Open File** action with a terminal app as a substitute: opening an app does
not guarantee that its shell starts in the selected directory.

For Day One command launchers, use the existing
[Raycast command pack](raycast.md). It already covers project workflows
and setup commands without requiring a permanent checkout.

## Copy a folder path without creating a shortcut

1. Select the folder in Finder.
2. Press `⌥⌘C` to copy its pathname. Alternatively, hold Option while opening
   Finder's **Edit** menu and choose **Copy … as Pathname**.
3. Paste into a text editor to verify the path before using it in a command.

The clipboard contains an absolute path, not shell-escaped text. Put the path
in quotes when a shell command expects one argument and it contains spaces.
Do not publish paths containing private project or account names.

## Keep, move, or remove these shortcuts

- **Keyboard access:** open a shortcut, then **Shortcut Details → Add Keyboard
  Shortcut**. Choose an unused combination; no global key is assigned by these
  recipes.
- **Hide from Finder:** clear **Shortcut Details → Use as Quick Action → Finder**.
- **Remove:** in Shortcuts' main window, right-click the shortcut and choose
  **Delete**. This removes the workflow, not the project folder or report.
- **Move to another Mac:** use **File → Export…** for the selected shortcut and
  keep the export with your private app backups. After importing on the other
  Mac, reselect saved folders/files and the installed application, then repeat
  the verification step. Saved file references are machine-specific.

## Troubleshooting

| Symptom | Check |
|---|---|
| No entry under Finder Quick Actions | Enable **Use as Quick Action → Finder**, check the input type, and right-click an actual folder |
| Action opens Finder instead of VS Code | Change **Default App** to **Visual Studio Code** in **Open File** |
| Shortcut asks to enable scripts | Remove **Run Shell Script** and use **Open File** as described above |
| Nothing happens when pressing Run | The Finder recipe needs selected-folder input; test from Finder or use the picker recipe |
| A saved folder or report cannot be found | Reselect it in the **File** action after moving it or importing the shortcut |
| Toolbar button runs but no folder opens | Configure the toolbar copy to read **Get Selected Files in Finder**, use its output in **Open File**, and select a folder first |
| Dragging does not add a toolbar button | Hold Command while dragging the generated app from Finder; wait for the green + over the top toolbar |
| Toolbar button stops working after cleanup | Check the generated app still exists; removing its Dock icon is different from deleting the app |
| A command-line run fails | Test the actual Finder Quick Action; a CLI error alone does not establish that the Finder workflow is broken |

---

[← Application setup](README.md) · [Keyboard shortcuts](keyboard-shortcuts.md) · [VS Code setup](../editors/vscode.md)
