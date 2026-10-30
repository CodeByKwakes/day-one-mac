# Set up selected applications

Choose only the applications in your worksheet. The productivity selection uses
VS Code, Warp, Raycast and a Nerd Font; core can skip them. 1Password belongs to
its selected authentication route. Additional applications are optional.

## Follow one complete task

| Application or task | Guide | Verify |
|---|---|---|
| VS Code and profiles | [Editor setup](../editors/vscode.md) | CLI, formatting, terminal and selected extensions |
| Warp | [Terminal setup](../terminals/warp.md) | Selected Zsh, PATH, prompt and working directory |
| Raycast | [Launcher setup](raycast.md) | Hotkey, app launch and selected permissions |
| 1Password | [Security setup](../security/1password.md) | Intended account, agent and repository access |
| Vorssaint | [Window management](vorssaint.md) | Layouts and shortcut conflicts |
| Multi-display development workspace | [Desk layouts and recovery](workspaces.md) | Correct screens, project window and display recovery |
| Atticus (optional) | [Voice pilot](atticus.md) | Chosen backend, permissions and an unambiguous harmless command |
| Database clients | [Database tasks](../databases/README.md) | Intended server and database-enforced role |
| Raycast AI | [Provider setup](raycast-ai-providers.md) | Intended account and a harmless request |
| Developer shortcuts and apps | [macOS Shortcuts](macos-shortcuts.md) | Folder input, selected profile, Warp directory and clone destination |
| Shortcut planning | [Keyboard shortcuts](keyboard-shortcuts.md) | No conflict with the selected application |

## Check the selected font

If you selected JetBrains Mono Nerd Font, inspect it in Font Book. Install
`font-jetbrains-mono-nerd-font` through the approved owner only if absent.
Choose it in the terminal/editor, then inspect ordinary text and prompt glyphs.
Expected result: readable characters without missing-glyph boxes. A different
font is valid when you do not require Nerd Font icons.

## Preserve ownership and recoverability

Keep company-managed, App Store and valid manual installations in their update
channels. Export settings privately before importing another configuration.
Grant macOS permissions only for selected features and test the actual feature;
an installed bundle alone does not prove a working account or integration.

Next: [backup and final verification](../backup-and-restore.md).
