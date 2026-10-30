# Verify, export and recover VS Code

Use these checks after [editor setup](../vscode.md) and selected profile changes. Preserve your current working configuration before a restore or reset.

## 9. Verify and export

Run the checks for the profiles and optional integrations you selected.

| Check | Expected result |
|---|---|
| Switch through your profiles | Each name, accent and enabled extension set matches its matrix column |
| Open Explorer in each profile | Open Editors is visible and expanded; opening a file adds it to the list |
| Save a disposable Markdown file in each profile | [Markdown formatting](profiles.md#markdown-formatting) uses the shared style unless project rules override it |
| Open a development terminal and run `node --version`, `git --version` and the project package manager's version command | Each tool resolves to the intended installation |
| Open an Angular template and Prisma schema in Full Stack or AI | Diagnostics and formatter ownership match the selected extensions |
| Open a configured Tailwind project in Full Stack or AI | CSS uses Tailwind CSS mode, SCSS keeps its mode, class completion works and Prettier formats CSS on save |
| Peek a class definition in the disposable CSS Peek example in Full Stack, or AI if selected | The matching authored stylesheet rule appears; Tailwind and Angular tooling remain enabled |
| Select an unchanged committed line in Full Stack or AI | GitLens shows current-line blame; file-wide annotations can be toggled on and off |
| Generate a barrel in a disposable TypeScript directory in Full Stack or AI | Exports match the selected files, respect exclusions and pass the project's type check |
| Rename a disposable Angular component in Full Stack or AI | Related files and references match the new name; reviewed changes pass the project's build and tests |
| Search Extensions for `streetsidesoftware.code-spell-checker` in all four profiles | Code Spell Checker is not installed in these profiles |
| Save and use import shortcuts on a disposable TS/JS change | Sorting and removal follow the chosen policy; the diff contains only intended edits |
| Generate a GitLens message for reviewed staged changes | The message follows Conventional Commits and describes only the staged scope; generation alone does not commit |
| Inspect icons and HTML token colors in Full Stack | The selected folders and tokens use the configured appearance |
| Open Good Prompts in Full Stack or AI | A generated prompt can be reviewed before sending it to an agent |
| Open NPM Visual Manager in Full Stack, or AI if selected | Intended package file and manager appear; an AI prompt copies without applying updates |
| Inspect selected AI clients and their linked skills/MCP configuration | The intended account, project, permissions and tools are available in that client |
| Follow the [Codex continuity check](../../ai/workflows.md#continue-a-codex-chat-between-vs-code-and-desktop) when using the desktop app | The existing conversation and a harmless follow-up are visible in both applications |
| Test selected database connections with the database guide | Local/dev/test work; production uses the separately verified read-only identity |
| Save work and test Reload where selected | The window reloads; the native Command Palette action remains available if the button is absent |

1. Resolve failed checks using the owning guide or troubleshooting section.
2. [Export each verified profile](#export-a-portable-profile---preferred) to a private backup.
3. [Configure Settings Sync](#configure-settings-sync-on-a-new-machine) if selected.

Expected result: each profile has a reviewed backup. CLI agent/skill configuration
and database credentials have their own recovery process; moving Macs may require
new account sign-ins and machine permissions.

Exported profiles do not replace database credential management or runtime
configuration backups. A successful editor setup does not establish that a
database migration is safe.

## Export and back up the configuration

### Export a portable profile - preferred

1. Open **Manage → Profiles**.
2. Select the profile you want to preserve.
3. Open its actions menu and choose **Export…**.
4. Review which parts will be exported.
5. Choose **Local file** and save each `.code-profile` with its profile name and
   a date/time in a private backup directory such as:

   ```text
   /Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code/
   ```

Expected result: each selected profile has a distinct export and older backups
remain available. Inspect the export for private paths or account details.
Back up the external rule file described under [Markdown formatting](profiles.md#markdown-formatting)
separately; its contents are not stored in the profile export.

VS Code can also save a profile to a GitHub secret gist. Use a local file when
the profile is private, work-managed, or not intended to leave the Mac. Some
machine-specific settings are deliberately excluded from profile exports.

### Restore your own exported profile

1. In Profiles, choose **Import Profile…** and select your `.code-profile` backup. Expected: VS Code shows a preview of its contents.
2. Select only the settings, keyboard shortcuts, snippets and extensions you intend to restore. Expected: unrelated profile data is not selected.
3. Import under a distinct temporary profile name. Expected: the imported profile can be tested before replacing your working profile.
4. Verify the terminal, formatter and extension behavior using the checks above. Expected: Settings Sync is intentionally on or intentionally off, and the profile works locally before syncing it to another device.

### Record the extension inventory

After creating the profiles, run this in Terminal with your mounted backup-volume
name. Remove unselected profile names from the loop; add custom names only when
those profiles exist. The command records one inventory per named profile.

```bash
(
  set -euo pipefail
  umask 077
  BACKUP_VOLUME="/Volumes/<backup-volume>"
  test -d "$BACKUP_VOLUME" || { echo "Backup volume is not mounted"; exit 1; }
  EXPORT_ROOT="$BACKUP_VOLUME/Day-One-Mac-App-Exports/VS-Code"
  mkdir -p "$EXPORT_ROOT"
  INVENTORY_DIR="$(mktemp -d "$EXPORT_ROOT/extensions-$(date '+%Y%m%d-%H%M%S').XXXXXX")"
  for profile in "Default" "Full Stack" "AI" "Operations"; do
    code --profile "$profile" --list-extensions --show-versions |
      LC_ALL=C sort > "$INVENTORY_DIR/$profile.extensions.txt"
  done
  printf 'Extension inventories: %s\n' "$INVENTORY_DIR"
)
```

Expected result: the printed new directory contains a separate versioned list
for each selected profile. Open every list and check representative extensions.
These lists do not preserve settings, extension enablement or all-profiles
sharing; retain the `.code-profile` exports too.

To restore extensions, review one inventory and set its exact path and matching
profile name below. Create or select that profile first. The CLI can create a
missing named profile, so check spelling before running the command.

```bash
(
  set -euo pipefail
  PROFILE="Full Stack"
  INVENTORY_FILE="/path/to/reviewed-inventory/Full Stack.extensions.txt"
  test -f "$INVENTORY_FILE" || { echo "Inventory file is missing"; exit 1; }
  cut -d@ -f1 "$INVENTORY_FILE" |
  while IFS= read -r extension; do
    test -n "$extension" || continue
    code --profile "$PROFILE" --install-extension "$extension"
  done
)
```

Expected result: the selected profile contains the reviewed extensions. Recheck
its inventory and enabled state. This installs available current releases, not
the recorded versions, and does not remove other extensions. Repeat only for
profiles you intend to restore, then reapply any all-profiles sharing choices.
[Profile-scoped CLI options](https://code.visualstudio.com/docs/configure/command-line#working-with-extensions).

### Back up the complete local user folder - recovery copy

Quit all VS Code windows with `Cmd+Q`, then make a private recovery copy in a
new dated directory. Replace the backup-volume placeholder first:

```bash
(
  set -euo pipefail
  umask 077
  BACKUP_VOLUME="/Volumes/<backup-volume>"
  test -d "$BACKUP_VOLUME" || { echo "Backup volume is not mounted"; exit 1; }
  EXPORT_ROOT="$BACKUP_VOLUME/Day-One-Mac-App-Exports/VS-Code"
  mkdir -p "$EXPORT_ROOT"
  RECOVERY_DIR="$(mktemp -d "$EXPORT_ROOT/User-$(date '+%Y%m%d-%H%M%S').XXXXXX")"
  ditto "$HOME/Library/Application Support/Code/User" "$RECOVERY_DIR/User"
  printf 'User-folder recovery copy: %s\n' "$RECOVERY_DIR"
)
```

Expected result: the printed directory contains a `User` folder, and prior
recovery copies remain separate. Treat its contents as private application data.

This is a recovery archive, not the preferred cross-machine import method.
Restore profiles through the Profiles editor and copy individual snippets or
keybindings only after inspecting them.

## Reset selected local settings or profiles

Export each affected profile first and retain the backup until the replacement
works. Turn off Settings Sync while cleaning up; keep the cloud copy unless
replacing it is an explicit, separate decision.

| What needs changing | Scoped action in VS Code |
|---|---|
| Unwanted extensions | Switch to the intended profile; disable or uninstall only the selected entries in Extensions |
| Conflicting settings | Open the active profile's User Settings JSON and remove only the unwanted keys; review workspace overrides separately |
| Complete settings reset | After export, replace only that profile's settings with `{}`, then reapply the approved base or profile recipe |
| Old named profiles | Export each one, switch to the replacement, then remove only the unwanted named profile in Profiles |
| Clean custom profile | Create an Empty Profile and apply the [reviewed baseline](profiles.md#10-optional-custom-profile-tech-content-creator) |

Test formatting, Git, terminal launch and the expected extension set before
removing the old profile. Do not delete the entire `Code/User` directory as a
shortcut: it contains more than settings and may hold other profiles and
extension state. Resetting local settings does not clear cloud Sync data or
change a client's credential permissions.

## Configure Settings Sync on a new machine

1. Open **Manage gear → Turn on Settings Sync…** after local verification.
2. Sign in with the intended Microsoft or GitHub account, following your organisation's policy.
3. Run **Settings Sync: Configure…** and select **Profiles**, **Settings**,
   **Keyboard Shortcuts** and **Extensions** for this setup. Select other categories
   only when wanted; review **Prompts and Instructions** before synchronizing them.
4. Use **Settings Sync: Show Synced Data** to inspect the stored configuration.
5. Verify the selected profiles on another approved device before discarding backups.

Expected result: selected profile data appears under the intended account.
Machine-specific settings may be excluded; check terminal paths and fonts on
each Mac. Remote SSH, container and WSL extension installations do not synchronize
like local extensions. Sync does not replace private backups or client sign-in.
[Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync),
[profile synchronization](https://code.visualstudio.com/docs/configure/profiles#synchronize-profiles-across-machines).

## Change or clear Settings Sync later

To change what synchronizes:

1. Open **Manage → Settings Sync is On**.
2. Open **Configure** and select or clear individual categories.
3. Use **Show Synced Data** to inspect saved versions and registered machines.

To create a genuinely new cloud baseline:

1. Export the affected profiles on each device and review the intended Sync account.
2. Select **Settings Sync is On** → **Turn Off**; keep cloud data initially.
3. Verify the replacement local settings and extensions with Sync off.
4. Only when intentionally replacing the shared remote baseline, select the
   separate option to clear all cloud data. Coordinate work-managed accounts with IT.
5. Turn Sync on again for the intended account, select only the approved
   categories, and test another device before discarding backups.

Clearing cloud data affects other devices using that account. Do it only when
you intend to replace the shared remote state.

## Troubleshooting

| Symptom | What to do |
|---|---|
| `code: command not found` | Follow [Open VS Code and enable the CLI](../vscode.md#open-vs-code-and-enable-the-cli), then reopen Terminal |
| Old extensions reappear | Turn off Settings Sync, remove the unwanted extensions, verify locally, then reconfigure sync |
| A formatter changes every project | Inspect the active profile's User Settings; scope the formatter by language and remove unintended all-profiles sharing. Keep existing repository formatting rules authoritative |
| Markdown does not format on save, or tables gain padding | Confirm Markdown language mode, markdownlint formatter ownership and the private rule file; inspect **View → Output → markdownlint** and project overrides. Check that another formatter or save action is not formatting tables |
| Creating or finding file tabs is awkward | Use `Cmd+N` for a blank file or `Cmd+P` for an existing one. Check the active profile's [tab settings](profiles.md#editor-tabs) and workspace overrides; wrapped rows keep overflowing tabs visible |
| Starship symbols are squares | Select JetBrainsMono Nerd Font and reopen the terminal |
| One profile looks different | Confirm the active profile from **Manage → Profiles** |
| Reload is missing from the status bar | Check that the extension is enabled in the active profile and inspect local/remote placement; use **Developer: Reload Window** as the fallback |
| Pipeline files have no language support in AI | Use AI's YAML associations and YAML extension; reserve the dedicated Azure Pipelines mode for a profile with its extension |
| `chezmoi diff` appears stuck | Close the VS Code comparison tabs; `--wait` deliberately keeps the Terminal command active during review |
| A work setting appears on a personal Mac | Sign out of the wrong sync account and review synced categories before reconnecting |
