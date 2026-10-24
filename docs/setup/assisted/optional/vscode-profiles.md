# Generate, replace and restore VS Code profiles

Prepare profile resources with the public command, review them, then explicitly
choose import, extension installation or settings replacement. This is the
Scripted (Assisted) route. The [manual VS Code guide](../../manual/editors/vscode.md)
owns profile selection, extension descriptions and settings explanations.

## Before you start

- Back up the current profiles using VS Code's export action.
- Install Node.js 22 or newer and make `code --version` work.
- Check command availability below. Live installation/replacement requires the
  current Phase 8 gate; review-file generation does not.
- Keep generated exports and private backups outside application repositories.

Existing extensions are preserved by the replacement workflow. Default is
changed only when you explicitly select it and confirm the reviewed replacement.

## Generate review files

Use the installed `day-one-mac vscode-profile` command from any directory; no
source checkout is needed. **Availability:** check `day-one-mac --version` and
`day-one-mac vscode-profile --help` before proceeding. These commands exist in
this source tree; their presence in an installed or published release must be
checked separately. Local tag `v1.5.0` does not expose this command. Use a release
that contains it rather than copying individual scripts into an older runtime.

The generators require **Node.js 22 or newer** and read the bundled versioned
profile configuration. By default they create personal review files, not
repository `.vscode` files or active editor settings. Preview and bundle export
are available before Phase 8. Explicit extension installation and approved
settings replacement require current Phase 8. Import/merge remains the default;
the separate [replacement workflow](#replace-existing-profile-settings-and-shortcuts)
is opt-in and includes private backups and recovery.

| Profile | Generate its reviewed baseline | Baseline extensions |
|---|---|---|
| Default | `day-one-mac vscode-profile default` | 6 |
| Full Stack | `day-one-mac vscode-profile full-stack` | 20 |
| AI | `day-one-mac vscode-profile ai` | 16 |
| Operations | `day-one-mac vscode-profile operations` | 12 |

Start with a preview, then generate the profiles you want:

```bash
day-one-mac vscode-profile full-stack --dry-run
day-one-mac vscode-profile default
day-one-mac vscode-profile full-stack
day-one-mac vscode-profile ai
day-one-mac vscode-profile operations
```

Each invocation prints its output directory: by default a new private directory
in macOS temporary storage. Copy any files you want to keep to your private
backup location; temporary files are not permanent backups. For a persistent
destination, pass a **new directory whose parent already exists**:

```bash
mkdir -p "$HOME/Developer/Resources/VSCode/Profiles"
day-one-mac vscode-profile full-stack \
  --output "$HOME/Developer/Resources/VSCode/Profiles/full-stack-review"
```

The script refuses an existing destination, including a symlink. Choose another
name on later runs. Output directories are private (0700) and files are 0600.
Each bundle contains:

| File | Purpose |
|---|---|
| `<profile>.code-profile` | Importable profile with settings and selected extensions |
| `settings.json` | Fully merged User Settings for manual review/merge |
| `keybindings.json` | Three import-cleanup chords for Full Stack/AI; empty for other profiles |
| `extensions.txt` | Recommended extensions plus explicitly selected optional additions |
| `optional-extensions.txt` | Available optional IDs; these are not automatically installed |
| `README.txt` | Import and manual completion instructions |

The generator merges nested settings, retaining shared Markdown options and
Full Stack's language settings in AI. It bundles the [shared User Settings](../../manual/editors/vscode.md#3-apply-shared-user-settings),
[profile settings](../../manual/editors/vscode.md#4-apply-profile-settings) and
[import keybindings](../../manual/editors/vscode.md#personal-import-shortcuts). Folder-name icon associations,
the optional Angular token palette, shell configuration, skills/agent files,
MCP servers, and database connections still require the linked manual recipes.
Credentials and account sign-in are not included.

#### Import settings and extensions together

**Does the script automatically override Default? No.** The default command only generates
review files. Its output is named **Default Review**, **Full Stack Review**,
**AI Review**, or **Operations Review** for manual import. No live settings or
keybindings are applied. Importing a Review profile is a separate action in
VS Code. Export your current profile before making that manual change.

| Action | Effect on your existing Default profile |
|---|---|
| Generate a bundle or run `--dry-run` for any recipe | No change |
| Import **Full Stack Review** as a new profile in VS Code | Creates the reviewed profile; does not replace Default |
| Run `vscode-profile default --install-extensions` | Adds missing recommended extensions to Default; does not replace its settings or remove other extensions |
| Run `vscode-profile full-stack --install-extensions` | Targets Full Stack rather than Default; does not apply settings |
| Manually merge generated settings into Default | Changes only the properties you deliberately edit |
| Approve `default --replace-settings` | Replaces Default's settings and shortcuts after backing them up; keeps installed extensions |

1. Export your current profiles as private backups.
2. Open **Profiles**, use the **New Profile** dropdown, and select
   **Import Profile…**. Select the generated `.code-profile` file.
3. Review the components before creating the profile. Its name has a
   **Review** suffix, such as **Full Stack Review**. Test it before deciding
   whether to retain it or rename it after managing your existing profile.
4. To update an existing profile, switch to it and merge `settings.json` into
   **Preferences: Open User Settings (JSON)**. Preserve unrelated choices.
   Merge the supplied keybindings only after checking for shortcut conflicts.

VS Code's importer can filter machine-scoped settings. Compare the imported
settings with `settings.json`, especially macOS terminal paths, and merge any
needed local settings manually. The generated keybindings target macOS.

The built-in **Default** profile cannot be replaced simply by importing a
profile called Default. For Default, merge the generated settings into its
User Settings and install extensions into Default using the option below.
The replacement workflow below writes only documented User settings and
keybinding files; it never edits the internal profile database. VS Code documents profile
imports through the editor; see [Profiles](https://code.visualstudio.com/docs/configure/profiles).

#### Replace existing profile settings and shortcuts

Replacement is an explicit alternative to merging. It replaces the entire
`settings.json` and `keybindings.json` contents with the selected recipe.
Personal settings and custom shortcuts not in that recipe are removed from
the active files and preserved in a private backup. Default and Operations
currently have no custom shortcut entries, so their replacement keybindings
are `[]`; built-in VS Code shortcuts still work.

**Scope:** local, stable VS Code on macOS. The command keeps installed
extensions and does not edit separate account, snippet, task, MCP or layout
storage. Preferences or legacy inline MCP definitions inside `settings.json`
are replaced along with that file; keep them in the private export if needed. It does
not rename/delete profiles or edit opaque profile IDs. Workspace settings and
IT policies can still override User Settings. This mode is part of this source
candidate; an older installed runtime needs a release containing it.

**Shared manual preparation for either route:**

If these resources are owned by chezmoi, another dotfile manager, or IT,
change them through that owner instead of replacing the applied files here.
Otherwise the next managed apply can undo the replacement. Symlinked resources
are refused rather than followed.

1. Export the intended profile to a private local `.code-profile` backup.
2. Review Settings Sync and pause it before replacement. Save your files.
3. In the Profiles editor, confirm the intended profile has its own Settings
   and Keyboard Shortcuts rather than using Default's resources. Review
   **Apply Setting to all Profiles** choices: replacing Default can affect
   profiles that share its resources. See [profile sharing](https://code.visualstudio.com/docs/configure/profiles).
4. For a named profile, activate it, open **Preferences: Open User Settings
   (JSON)**, then copy the full file path using the editor tab's **Copy Path**
   action. If that opens Default's file, give the named profile its own Settings
   first. Save a local setting if necessary to create its file.
5. Quit VS Code completely with Cmd+Q before previewing or applying file changes.
   This prevents a running window from writing stale settings back afterward.

**Manual route - no Day One Mac commands:** after the preparation above,
reopen the intended profile. Save separate private copies of its User Settings
and Keyboard Shortcuts JSON before editing. Replace its User Settings with the fully combined
[shared settings and profile overrides](../../manual/editors/vscode.md#4-apply-profile-settings); do not paste
several root objects together. Replace its Keyboard Shortcuts JSON with the
[import keybindings](../../../shared/reference/vscode-profile-data.md#import-keybindings)
for Full Stack/AI, or `[]` for Default/Operations. Save and verify the result.
For manual recovery, reopen the same profile and restore those original JSON
contents. Keep your exported profile as an additional backup. Do not delete extensions.

**Script-assisted route:** the following commands replace only the two local
User resource files, using the selected recipe. They do not install extensions.

Preview Default without changing it:

```bash
day-one-mac vscode-profile default --replace-settings
```

The command displays both target paths and an **Approval hash**. Check the
profile and paths, then copy the exact hash into the apply command:

```bash
day-one-mac vscode-profile default --replace-settings \
  --execute --approve "<hash-from-the-preview>"
```

Default uses its documented `Code/User/settings.json` path automatically.
For Full Stack, AI or Operations, supply the path copied from the intended
profile. The command does not guess which opaque profile directory matches a
name. The recipe selects the content; the copied path selects the actual named
profile to change. Verify that path before approving. This example uses a
placeholder ID; replace it with the copied path:

```bash
PROFILE_SETTINGS="$HOME/Library/Application Support/Code/User/profiles/<profile-id>/settings.json"

day-one-mac vscode-profile full-stack --replace-settings \
  --settings-file "$PROFILE_SETTINGS"

day-one-mac vscode-profile full-stack --replace-settings \
  --settings-file "$PROFILE_SETTINGS" \
  --execute --approve "<hash-from-the-preview>"
```

Use `ai` or `operations` in place of `full-stack` for those recipes. Named
recipes cannot target Default's settings path. The target directory must
already exist; use VS Code to create the profile first. Insiders, portable
installations, remote profiles and other editors are outside this mode.

Apply requires current Phase 8, an approval matching the fresh preview, and
the normal Day One Mac operation lock. If either target changes after review,
the command refuses the stale approval. Preview alone and `--dry-run` create
no files, backups or locks. `--dry-run` also prevents writes when combined with
`--execute`. Repeating a matching replacement reports that no writes are needed.

Before the first target changes, the command saves original file bytes,
permissions and prior absence under the selected state directory's
`profile-replacements/` folder. The normal location is
`~/.day-one-mac/profile-replacements/`. Each private backup directory is 0700
and its files are 0600; treat it as sensitive because original settings may
contain personal data. The record covers only these two changed files.
The command prints **Backup:** followed by the exact recovery directory.

Reopen VS Code, select the same profile and verify the theme, terminal settings,
formatting and shortcuts. Confirm the matching-history `.zshrc` block separately;
replacing editor settings does not modify shell files. Restore Settings Sync
only after checking which configuration should synchronize.

**Recovery - preview first:** quit VS Code and pause Sync again. Substitute
the exact backup directory printed by the replacement:

```bash
PROFILE_BACKUP="$HOME/.day-one-mac/profile-replacements/<printed-backup-directory>"

day-one-mac vscode-profile default --restore "$PROFILE_BACKUP"

day-one-mac vscode-profile default --restore "$PROFILE_BACKUP" \
  --execute --approve "<hash-from-the-restore-preview>"
```

Use the original recipe name for named-profile recovery. Restore checks the
backup and current file hashes, restores the exact original bytes/permissions,
and removes a created resource only when it was originally absent and still
matches this replacement. It supports interrupted replacements, remains
available without current Phase 8, and refuses later edits rather than
discarding them. If it refuses drift, merge the private `.before` files manually
into the intended profile instead. Keep backups until you have verified recovery.

Extension installation remains separate: use `--install-extensions` or the
Extensions view if desired. Do not combine it with replacement or restore.
Neither mode removes your other installed extensions.

#### Install extensions into the named profile

For an existing profile whose settings you will merge manually, use the explicit
installation option. First run **Shell Command: Install 'code' command in PATH**
in VS Code if your terminal cannot find `code`.

```bash
day-one-mac vscode-profile default --install-extensions
day-one-mac vscode-profile full-stack --install-extensions
day-one-mac vscode-profile ai --install-extensions
day-one-mac vscode-profile operations --install-extensions
```

This targets **Default**, **Full Stack**, **AI**, or **Operations**, respectively,
without the Review suffix. The CLI can create a missing named profile; it does
not perform a separate existence check. Installation adds missing extensions,
skips already installed IDs, and stops on errors. It does not uninstall other
extensions, explicitly update existing ones, apply settings, or reinstall
Copilot/Copilot Chat. Marketplace dependencies may install companion extensions.
Use either the reviewed import or this installation route as appropriate;
running both is not required. [VS Code CLI](https://code.visualstudio.com/docs/configure/command-line).

Add only optional extensions listed for that profile using repeatable `--with`:

```bash
day-one-mac vscode-profile full-stack \
  --with orta.vscode-jest \
  --with ms-playwright.playwright
day-one-mac vscode-profile operations \
  --with ms-vscode-remote.remote-ssh \
  --install-extensions
```

The first example generates a bundle with Jest and Playwright; the second also
installs Operations extensions and Remote SSH. Extension IDs are matched without
case sensitivity. Settings specific to optional tools remain manual unless
already present in the guide's profile recipe. `--code "/path/to/code"` selects
another VS Code CLI executable. `--help` lists options. `--dry-run` always
prevents file writes and CLI calls, including when combined with install mode.

## Verify the selected action

1. Switch to the exact named profile in VS Code.

   Expected result: the name and accent match the profile you selected, not a
   similarly named review/import profile.

2. Open User Settings and Keyboard Shortcuts JSON for that profile.

   Expected result: the reviewed values appear. Workspace or managed policies
   can override them; inspect the effective setting where behaviour differs.

3. Open a disposable file and test formatting, import actions and the terminal.

   Expected result: the language uses the selected formatter, and a new Zsh
   terminal finds the intended tools. Complete the manual guide's feature checks.

## Troubleshooting

| Symptom | Check and next action |
|---|---|
| Unknown `vscode-profile` command | Inspect the installed runtime version/help; update to a containing release or follow the manual guide |
| Node requirement fails | Select an installed Node 22+ runtime and recheck `node --version` |
| Target profile not found for replacement | Create/import it first; repeat preview and review the exact profile name |
| VS Code is still running | Quit all VS Code windows before a replacement that requires it |
| Preview differs from intended settings | Stop and review the generated bundle; do not approve the replacement |
| Restore conflict | Preserve newer edits and follow the conflict-aware restore workflow above |

The replacement and restore sections above own the exact recovery commands.
Keep their private backup until the new setup is verified. Do not delete a whole
VS Code user-data directory as a shortcut.
