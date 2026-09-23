[← Required apps](README.md) · **Keyboard shortcuts** · [Raycast setup →](RAYCAST.md)

# Day One Mac keyboard shortcuts

This is the small shortcut set worth learning after the required setup. It is
not a complete list. Start with the **Recommended global shortcut ownership**
table, then learn shortcuts only when they save repeated work.

Shortcuts below use the current macOS defaults documented by each application.
An imported profile, company policy, extension, keyboard layout, or custom
keymap can change them. When a shortcut behaves differently, inspect the app's
own shortcut editor instead of repeatedly pressing it.

## Key symbols

| Symbol | Key |
|---|---|
| `⌘` | Command |
| `⌥` | Option/Alt |
| `⌃` | Control |
| `⇧` | Shift |
| `↩` | Return/Enter |
| `⎋` | Escape |

Two shortcuts written with a space, such as `⌘K ⌘S`, form a **chord**: press
the first combination, release it, then press the second.

## Recommended global shortcut ownership

These shortcuts can work while another application is active, so conflicts
matter more than shortcuts local to one window.

| Shortcut | Day One owner | Purpose |
|---|---|---|
| `⌘Space` | Raycast | Open Root Search; the Spotlight launcher shortcut is disabled, but Spotlight indexing stays enabled |
| `⌘\` | 1Password | Universal Autofill in the focused app or website |
| `⌥⌘\` | 1Password on macOS 27 | Open Quick Access |
| `⇧⌘Space` | 1Password on macOS 26 or earlier | Older Quick Access default; do not assign it on macOS 27 merely to match an old guide |

Warp also ships with `⌘\` for Warp Drive. That conflicts with 1Password
Universal Autofill. Keep `⌘\` for 1Password and either open Warp Drive from
Warp's `⌘P` Command Palette or remap Warp Drive under **Warp Settings →
Keyboard shortcuts**.

## 1Password

### Everyday global actions

| Shortcut | Action |
|---|---|
| `⌘\` | Fill the most relevant login with Universal Autofill |
| `⌥⌘\` | Open Quick Access on macOS 27 |
| `⇧⌘Space` | Open Quick Access on macOS 26 or earlier |
| `⇧⌘X` | Open the browser-extension pop-up in Chrome, Edge, Brave, or Safari |
| `⌘.` | Open the browser-extension pop-up in Firefox |

### In the 1Password app or Quick Access

| Shortcut | Action |
|---|---|
| `⌘F` | Search items |
| `⌘N` | Create a new item |
| `⌘E` | Edit the selected item |
| `⌘S` | Save changes |
| `⌘C` | Copy the username or primary field |
| `⇧⌘C` | Copy the password |
| `⌥⌘C` | Copy the one-time password |
| `⌘R` | Reveal or conceal secure fields in the selected item |
| `⎋` | Cancel an edit or clear Quick Access search |

Copied credentials are sensitive. Paste them only into the intended app or
site, and use Universal Autofill when possible so the secret does not pass
through the clipboard.

## Raycast

| Shortcut | Action |
|---|---|
| `⌘Space` | Open or close Raycast Root Search after completing the Day One Spotlight replacement |
| `↑` / `↓` | Move through results |
| `↩` | Run the primary action |
| `⌘K` | Open or close the Action Panel |
| `⌘↩` | Run the secondary action shown in the Action Panel |
| `⌥↩` | Run the tertiary action shown in the Action Panel |
| `⌘⎋` | Return to Root Search |
| `⎋` | Go back; from Root Search, close Raycast |
| `⌘,` | Open Settings, or configure the selected command in Root Search |
| `⇧⌘,` | Configure the selected extension |
| `⌘F` | Add the selected Root Search item to Favorites |

Recommended optional global assignments:

| Shortcut | Command | When to add it |
|---|---|---|
| `⌥⌘V` | Clipboard History | After credential and sensitive-work applications are excluded from capture |
| `⌃⌥⌘←` / `⌃⌥⌘→` | Left Half / Right Half | Only when Raycast Window Management is enabled |
| `⌃⌥⌘↑` / `⌃⌥⌘↓` | Maximize / Restore | Only when Raycast Window Management is enabled |
| `⌥Space` | Quick AI | Only when Raycast AI was deliberately selected |
| `⌃⌥⌘T` | A frequently used generated AI task command | Optional; prefer the `aitc`, `aitl`, or `aitp` alias first |

Audit custom Raycast hotkeys under **Raycast Settings → Shortcuts**. Prefer an
alias typed into Root Search when a command is useful but not frequent enough
to justify another global shortcut.

The optional [Day One Raycast command pack](RAYCAST-COMMANDS.md) provides
suggested `d1…` and `ai…` aliases. It deliberately assigns no hotkey itself.

## Warp

| Shortcut | Action |
|---|---|
| `⌘P` | Open the Command Palette; use this to discover the installed version's actions |
| `⌘,` | Open Settings |
| `⌃R` | Search command history |
| `⌃⇧R` | Open Workflows |
| `⌘L` | Return focus to Terminal input |
| `⌘D` | Split the active pane to the right |
| `⇧⌘D` | Split the active pane downward |
| `⌘[` / `⌘]` | Move to the previous or next pane |
| `⇧⌘↩` | Maximize or restore the active pane |
| `⌘K` | Clear visible terminal blocks |
| `⌘O` | Open file search |
| `⌘\` | Warp Drive default; remap it when 1Password Universal Autofill owns this shortcut |

Open **Warp Settings → Keyboard shortcuts** to search, change, clear, or reset a
binding. Warp highlights conflicts. Imported keysets may replace every default
listed above, so use `⌘P` when unsure.

## Visual Studio Code

| Shortcut | Action |
|---|---|
| `⇧⌘P` or `F1` | Open the Command Palette |
| `⌘P` | Quick Open a file by name |
| `⌘K ⌘S` | Open the Keyboard Shortcuts editor |
| `⌘,` | Open Settings |
| `⌃` + grave accent | Show or hide the integrated Terminal |
| `⌃⇧` + grave accent | Create a new integrated Terminal |
| `⌘B` | Show or hide the primary sidebar |
| `⇧⌘E` | Open Explorer |
| `⇧⌘F` | Search across files |
| `⌃⇧G` | Open Source Control |
| `⌘/` | Toggle a line comment |
| `⇧⌥F` | Format the current document |
| `F12` | Go to definition |
| `⌥F12` | Peek definition |
| `F2` | Rename the selected symbol |
| `⌘S` | Save the current file |

VS Code shortcuts can differ by profile and extension. Run **Preferences: Open
Keyboard Shortcuts** or press `⌘K ⌘S`, search for the command name, and check
the **When** column before changing a binding. Resolve conflicts in the editor
instead of editing `keybindings.json` blindly.

## Finder and macOS essentials

| Shortcut | Action |
|---|---|
| `⇧⌘.` | Show or hide hidden files in Finder |
| `⇧⌘G` | Go to a folder by path |
| `⌘↑` | Open the parent folder |
| `Space` | Quick Look the selected file |
| `⌘Tab` | Switch applications |
| `⌘` + grave accent | Switch windows in the current application |
| `⌘W` | Close the current window or tab |
| `⌘Q` | Quit the current application |
| `⌘,` | Open the current application's settings when supported |

## Shortcut verification checklist 🚦

- [ ] `⌘Space` opens Raycast once and does not also open Spotlight.
- [ ] Spotlight indexing remains enabled and Raycast File Search finds a known file.
- [ ] `⌘\` invokes 1Password Universal Autofill rather than Warp Drive.
- [ ] 1Password Quick Access opens with the shortcut documented for the installed macOS version.
- [ ] Warp's Command Palette opens and shows the current bindings.
- [ ] VS Code's Keyboard Shortcuts editor opens with `⌘K ⌘S`.
- [ ] Any imported profile or keymap conflict has been reviewed deliberately.

Official references:

- [1Password keyboard shortcuts](https://support.1password.com/keyboard-shortcuts/)
- [1Password Universal Autofill](https://support.1password.com/mac-universal-autofill/)
- [Raycast keyboard shortcuts](https://manual.raycast.com/keyboard-shortcuts)
- [Raycast settings and Replace Spotlight](https://manual.raycast.com/settings#replace-spotlight)
- [Warp keyboard shortcuts](https://docs.warp.dev/getting-started/keyboard-shortcuts)
- [VS Code keyboard shortcuts](https://code.visualstudio.com/docs/configure/keybindings)

---

[← Required apps](README.md) · [Configure Raycast →](RAYCAST.md) · [Configure Warp →](WARP.md) · [Configure VS Code →](VSCODE.md)
