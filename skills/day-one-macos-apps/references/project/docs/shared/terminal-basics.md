# Terminal basics

[Back to Start here](../START-HERE.md)

## Terminal basics used in this guide

**Terminal** is the macOS application in which you enter text commands. Open it
from **Applications → Utilities → Terminal** or with Spotlight.

- Copy only the text inside a code block, not the surrounding backticks.
- Paste one command block at a time and press Return.
- A guide may instead tell you to save a block in a file. Use the editor steps
  below for that block; do not paste configuration contents at the terminal prompt.
- A command that starts with `#` is an explanation; it does not make a change.
- Text such as `<repository>` is a placeholder. Replace the complete text,
  including angle brackets, with your real value.
- When macOS asks for an administrator password in Terminal, no dots or letters
  appear while you type. This is normal. Type the password and press Return.
- `Control-C` stops the current command. Inspect the result before repeating a step; an interruption may leave partial work.
- `~` means your home folder, such as `/Users/alex`.

Definitions for recurring terms such as CLI, cask, gate, manifest, and vault
are in the [plain-English glossary](glossary.md).

## Check command results

A successful command normally exits with status `0`. Read its output and the
owning guide's expected result. Stop on an unexpected result before running the
next step. A version number proves availability, not working account access.

Commands beginning with `npx skills` install or manage AI skills; `day-one-mac`
in an AI prompt names a skill, not a shell command. The legacy command is retired.

## Create or edit a configuration file

Use this procedure when a guide asks you to save plain text before you have
installed a code editor. macOS includes `/usr/bin/nano`, a terminal editor.
Files beginning with a dot are hidden in Finder; press **Command+Shift+.** to
show or hide them. A `.zshrc` file is plain text, not a command to run.

For user-owned files, work through the example below one step at a time. For a
chezmoi-managed file, use [chezmoi editing](../setup/manual/shell/chezmoi.md#2-edit-the-source-copy)
instead so the source and active copy stay consistent. Keep a working terminal
open until a new session has passed the owning guide's checks.

1. Select the exact file named by the guide. This example creates the shared
   Zsh PATH file:

   ```bash
   TARGET_FILE="$HOME/.config/zsh/path.zsh"
   printf 'File to edit: %s\n' "$TARGET_FILE"
   (
     INSPECT_PATH="$TARGET_FILE"
     while :; do
       ls -ld "$INSPECT_PATH"
       [[ "$INSPECT_PATH" == "$HOME" || "$INSPECT_PATH" == / ]] && break
       INSPECT_PATH="$(dirname "$INSPECT_PATH")"
     done
   )
   ```

   Expected: the intended path. `No such file or directory` is normal for a new
   file or missing parent. The loop shows the selected file and every parent up
   to your home folder, including `.ssh` when you select an SSH file. Inspect
   existing entries and their owner. Stop if an entry is a symbolic link (the
   listing starts with `l`), belongs to another owner or is managed by another
   tool. Use this procedure only for plain-text files inside your own home folder.

2. Prepare the [private evidence folder](private-evidence.md), then create a new
   backup directory for this edit:

   ```bash
   umask 077
   EDIT_BACKUP="$(mktemp -d "$HOME/.local/state/development-setup/edit.XXXXXX")" && {
     if [[ -f "$TARGET_FILE" ]]; then
       cp -p "$TARGET_FILE" "$EDIT_BACKUP/original"
     else
       printf 'The target did not exist before this edit.\n' > "$EDIT_BACKUP/absent.txt"
     fi && printf 'Recovery folder: %s\n' "$EDIT_BACKUP"
   }
   ```

   Expected: a new recovery folder containing `original` or `absent.txt`. Stop
   on any error. Record that folder and the target path privately; these terminal
   variables are not available automatically in a later session.

3. Create the selected parent directory and open the file:

   ```bash
   mkdir -p "$(dirname "$TARGET_FILE")"
   /usr/bin/nano "$TARGET_FILE"
   ```

   Expected: the editor shows the selected file. Paste only the configuration
   block from its guide. For an existing file, keep unrelated content and merge
   the required lines once. Do not include Markdown backticks.

4. Press **Control+O**, then **Return** to save to the displayed filename.
   Press **Control+X** to exit. To abandon an unsaved edit, press **Control+X**
   and answer **N** when asked to save. In nano, `^` means the Control key.

   Expected: the terminal prompt returns. Nano saves plain text and does not
   add a `.txt` suffix. Reopen the same path to inspect the saved content.

5. For this Zsh example, check syntax without executing the file:

   ```bash
   /bin/zsh -n "$TARGET_FILE"
   ```

   Expected: no output and exit status zero. Correct any error before opening
   a new terminal. JSON, TOML and other formats need their owning guide's check;
   do not validate them with Zsh. Then perform the guide's new-session check.

### Recover an unsuccessful edit

Keep the failed file for comparison before restoring anything. If a new terminal
cannot start normally, run `/bin/zsh -f` from the working terminal to open a shell
without your ordinary startup configuration. Use the recorded target and backup
paths; do not guess which recovery folder belongs to this edit.

1. Set the recorded paths again. Replace `edit.REPLACE_ME` with the folder name
   recorded for this edit, and change the target if you edited a different file:

   ```bash
   TARGET_FILE="$HOME/.config/zsh/path.zsh"
   EDIT_BACKUP="$HOME/.local/state/development-setup/edit.REPLACE_ME"
   printf 'Restore target: %s\nRecovery folder: %s\n' "$TARGET_FILE" "$EDIT_BACKUP"
   ls -ld "$TARGET_FILE" "$EDIT_BACKUP"
   ls -l "$EDIT_BACKUP"
   ```

   Expected: the exact target and its recorded recovery folder. Repeat the parent
   inspection from step 1 above with this target before changing it. Stop if
   ownership or management changed. Review the current file and `original` in
   the editor; leave both unchanged during this comparison. Restoring the whole
   file would also replace any successful edits made after the backup, so merge
   those deliberately instead if needed.

2. For a file that existed before the edit, preserve the failed content in a new
   private folder, then restore the recorded `original`:

   ```bash
   (
     set -euo pipefail
     umask 077
     test -f "$EDIT_BACKUP/original"
     FAILED_EDIT="$(mktemp -d "$EDIT_BACKUP/failed.XXXXXX")"
     if [[ -f "$TARGET_FILE" ]]; then
       cp -p "$TARGET_FILE" "$FAILED_EDIT/edited"
     fi
     cp -p "$EDIT_BACKUP/original" "$TARGET_FILE"
     printf 'Restored original; failed content, if present: %s\n' "$FAILED_EDIT"
   )
   ```

   Expected: the original content is restored and any failed file is preserved.
   Stop on an error. For a file that was originally absent, use this next block
   instead, only after confirming that no later work depends on the new file:

   ```bash
   (
     set -euo pipefail
     umask 077
     test -f "$EDIT_BACKUP/absent.txt"
     test ! -e "$EDIT_BACKUP/original"
     test -f "$TARGET_FILE"
     FAILED_EDIT="$(mktemp -d "$EDIT_BACKUP/failed.XXXXXX")"
     mv "$TARGET_FILE" "$FAILED_EDIT/edited"
     printf 'New file moved out of its active location to: %s\n' "$FAILED_EDIT/edited"
   )
   ```

   Expected: the new file is preserved in the recovery folder and is absent from
   its active location. If the target is already absent, no move is needed. If
   other files now require it, update those through their owning guide before
   starting a new session.

3. Repeat the owning guide's validation. For an existing Zsh file, run
   `/bin/zsh -n "$TARGET_FILE"`, then check a new terminal. Keep the recovery
   folder until the setup works.

<a id="terminal-colours-and-symbols"></a>
<a id="compact-menus-and-status-screens"></a>
