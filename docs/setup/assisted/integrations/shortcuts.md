# Import the bundled Open in VS Code shortcut

Use this assisted handoff when VS Code is already installed. The command opens
Apple's import screen; you review and approve the shortcut yourself.

## Script-assisted setup - import the ready-made shortcut

Run `day-one-mac --wizard`, then choose **Other actions → macOS Shortcuts ·
import Open in VS Code**, or use these commands in Terminal:

```bash
day-one-mac shortcuts --plan
day-one-mac shortcuts --import
```

1. Review the preview, then run the import command.
2. In Apple Shortcuts, inspect the workflow: **Open Shortcut Input in Visual
   Studio Code**, exposed as a Finder Quick Action.
3. Click **Add Shortcut**. If a shortcut with that name already exists, cancel
   to keep it; do not replace a customized version unintentionally.
4. Verify **Shortcut Details → Use as Quick Action → Finder**, then follow
   [the Finder test](../../manual/apps/macos-shortcuts.md#4-verify-it-from-finder).

VS Code must already be installed. The bundled export is signed for **Anyone**
and contains no fixed folder references or scripts. The command only opens
Apple's import screen: it does not silently install, overwrite, or record a
successful installation. Cancelling leaves the shortcut uninstalled. Keyboard
assignments remain your choice. If you already have the tested shortcut, keep
it rather than importing a duplicate.

`day-one-mac shortcuts --guided` asks before opening the import screen.
`--dry-run` always previews, including when combined with `--import` or
`--guided`. There is no background import during the required phases.

Apple's CLI exposes run, list, view and sign operations, not an install
operation. This handoff uses the supported Shortcuts import UI. See
[Apple's command-line guide](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).

## Verify and recover

Follow the [Finder test](../../manual/apps/macos-shortcuts.md#4-verify-it-from-finder),
then return here. Expected result: the selected folder opens in the intended
VS Code application. Cancel import if it would replace a customised shortcut.
Remove only the imported shortcut through Apple Shortcuts to undo this action.

## Add Open Setup Report

**Script-assisted route only.** This opens existing evidence; it does not run
verification or refresh the report.

1. In Finder, press `⇧⌘G` and enter `~/.day-one-mac/`.
2. Confirm **verification.md** exists. If it does not, complete or troubleshoot
   [Phase 8](../08-verify-and-reproduce.md) first. Do not create an
   empty file to stand in for a report.
3. Create a shortcut named **Open Setup Report**.
4. Add the **File** action. Click its file field and select **verification.md**
   from that folder. Use `⇧⌘G` in the picker to reach the hidden directory.
5. Add **Open File**, using the **File** action's output, and select
   **Visual Studio Code** as the app.
6. Run it and confirm the report opens. Check its contents and date before
   treating it as evidence of the current machine state.

The default full shorthand path is `~/.day-one-mac/verification.md`. If your
setup uses a custom state location, select the report at that location.
Manual-route users should open their own setup notes instead.
