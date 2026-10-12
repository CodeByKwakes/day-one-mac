# Bundled Finder shortcut

`Open in VS Code.shortcut` is an Apple Shortcuts export signed for **Anyone**
on macOS 26.7.1. Its single action opens Shortcut Input using the application
bundle identifier `com.microsoft.VSCode`. It has Finder Quick Actions enabled,
accepts apps/folders, and contains no saved file bookmarks, shell scripts,
personal paths, or contact details. VS Code must already be installed.

`open-in-vscode.plist` is the readable XML representation of the workflow
extracted from that signed export. It is review material, not an importable
signed replacement. Signing metadata and padding make exports non-reproducible
byte for byte; runtime checksums cover the distributed signed file.

To update the artifact, edit and test the workflow in Apple Shortcuts, export
with **File → Export… → For: Anyone**, inspect the workflow for private state,
and update both files together. Apple receives the workflow for signing. Do
not export using **People Who Know Me**, which can include contact details.
Never edit a signed export in place or write to the user's Shortcuts database.

The portable command opens the import preview; **Add Shortcut**, handling
existing names, and any shortcut permissions belong to the user. Do not mark
an import complete merely because `open` returned success.
