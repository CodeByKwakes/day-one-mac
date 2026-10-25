# Finder shortcut assets

Use the [macOS Shortcuts guide](../../docs/setup/manual/apps/macos-shortcuts.md)
for setup, Finder toolbar placement, verification, updates and removal.
These assets require no Day One Mac runtime or permanent checkout.

| Asset | Format | Purpose |
|---|---|---|
| `Open in VS Code.shortcut` | Signed Apple Shortcuts export | Import a Finder Quick Action that opens Shortcut Input in VS Code |
| `open-in-vscode.plist` | Readable XML | Review the existing VS Code export's workflow; not a signed import file |
| `git-clone.applescript` | Readable AppleScript | Paste into one Run AppleScript action to create the portable Git Clone shortcut |
| `folder-common.applescript` | Shared AppleScript handlers | Folder input, application discovery, Warp URL encoding and existing-profile checks |
| `open-in-vscode.applescript` | App entry source | Open one folder in stable VS Code |
| `open-in-warp.applescript` | App entry source | Open a Warp tab using the encoded folder URI |
| `open-vscode-profile.applescript` | App entry source | Choose a verified existing stable VS Code profile |
| `open-development-workspace.applescript` | App entry source | Open the same folder in VS Code and Warp |
| `catalog.json` | Build metadata | Recipe IDs, source order, dependencies and bundle identifiers |
| Open in Warp | [Native-action recipe](../../docs/setup/manual/apps/macos-shortcuts.md#create-open-in-warp) | Recreate selected-folder input and Open File in Warp; no signed export is supplied |

## Portability and verification

Generated `.app` launchers depend on local installed shortcuts and are not
included. The guide records the supplied launchers' review and explains why
copying them does not back up their actions. Recreate each launcher on its Mac.
Git Clone uses the current user's home folder as the picker's initial location,
requires confirmation, rejects credential-bearing URL forms and refuses any
existing destination. Custom SSH commands stop before folder creation; standard
`~/.ssh/config` remains supported. Failures retain their new folder for inspection.

The existing VS Code export was signed for **Anyone** on macOS 26.7.1. It uses
`com.microsoft.VSCode`, accepts apps/folders and contains no saved file bookmarks,
shell scripts, personal paths or contact details. Its XML is review material;
editing that file does not update the signed export.

`tests/integration/test-finder-shortcuts.cjs` compiles the Git Clone source and
tests pure handlers and generated shell commands using mock Git, plus an isolated
real Git configuration for the SSH guard. It never runs
the interactive shortcut or authenticates to a provider. The manual guide owns
first-run application, permission and folder checks.

## Maintain the assets

The [standalone app procedure](../../docs/setup/manual/apps/macos-shortcuts.md#build-standalone-apps-manually)
uses Script Editor. The optional [build helper](../../docs/shared/tools/shortcut-apps.md)
compiles the same sources into a new review directory and verifies local ad hoc
signatures. Those signatures do not provide notarization or a Developer ID.
Generated apps are review outputs, not committed binaries. Each contains its
code and works without the installed skill or source checkout.

The `day-one-shortcuts` skill and the main `day-one-mac` skill bundle these
sources. Follow [skill installation](../../docs/setup/manual/ai/day-one-skills.md)
for either scope. Skill updates do not replace previously built apps.

Keep executable source and its guide consistent. For VS Code, update the workflow
in Shortcuts, verify it, then review a new export and its readable XML together.
Anyone exports send the shortcut to Apple for validation; contact-restricted
exports must not be committed. Signing metadata makes exports non-reproducible
byte for byte. Never edit a signed export in place or write to Shortcuts' database.

Git Clone and Warp do not currently have new signed `.shortcut` exports. Users
can build them through the documented actions and export their verified copies.
Do not present a launcher app or an unsigned source file as an importable backup.
