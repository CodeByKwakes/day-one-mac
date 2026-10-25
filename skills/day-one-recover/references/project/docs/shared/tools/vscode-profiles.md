# Generate, replace and restore VS Code profiles

Use this optional skill helper after choosing profiles in the
[manual VS Code guide](../../setup/manual/editors/vscode.md). Manual setup works
without the helper. The helper does not install a Day One Mac command.

## Prerequisites

Use Node.js 22.20 or newer. Live extension installation and settings replacement
require native Apple-silicon macOS. Export the existing profiles through VS Code
before changing them. Enable the `code` command if installing extensions.

Install the [Day One Mac skill](../../setup/manual/ai/day-one-skills.md), then
change to its installed directory. For a shared project installation:

```bash
cd .agents/skills/day-one-mac
PROFILE_HELPER="$PWD/references/project/helpers/vscode/build.cjs"
node "$PROFILE_HELPER" default --help
```

Expected result: helper options. For a Claude-only installation, use
`.claude/skills/day-one-mac`. In a source checkout the helper is
`helpers/vscode/build.cjs`; both copies use their adjacent reviewed profile data.

## Generate and import review files

1. Preview the selected extension list. Replace `full-stack` with `default`,
   `ai` or `operations` for another profile.

   ```bash
   node "$PROFILE_HELPER" full-stack --dry-run
   ```

   Expected result: extension identifiers and no writes.

2. Generate a new review folder:

   ```bash
   node "$PROFILE_HELPER" full-stack --output "$HOME/Downloads/full-stack-review"
   ```

   Expected result: settings, shortcuts, extension lists and a `.code-profile`
   file. The destination must not already exist.

3. Use **Code > Settings > Profiles > New Profile > Import Profile** to import
   the review file. Review the resources before creating the profile.

   Expected result: a separate `Full Stack Review` profile. To update an existing
   profile, switch to it and merge the JSON through **Preferences: Open User
   Settings (JSON)**. This preserves unrelated settings.

4. If desired, explicitly install missing recommended extensions into the
   original profile name:

   ```bash
   node "$PROFILE_HELPER" full-stack --install-extensions
   ```

   Expected result: missing extensions are added. Existing extensions remain.
   Settings are not replaced. Sign-in remains manual. Optional extensions need
   `--with publisher.identifier` using an ID listed by that profile's review file.

## Replace settings and shortcuts deliberately

Replacement replaces complete User settings and keybindings. Export first,
quit VS Code and pause Settings Sync. Default resources shared by other profiles
may affect those profiles. The helper never changes extension inventory,
credentials, MCP connections or the profile database.

1. Choose a private backup parent outside the installed skill:

   ```bash
   PROFILE_BACKUPS="$HOME/Backups/vscode-profile-replacements"
   mkdir -p "$HOME/Backups"
   ```

   Expected result: the parent exists. The helper creates the private backup
   directory only when an approved change starts. If it exists, it must be 0700.

2. Preview Default replacement:

   ```bash
   node "$PROFILE_HELPER" default --replace-settings --backup-dir "$PROFILE_BACKUPS"
   ```

   Expected result: exact target files and an approval hash, without writes.
   For a named profile, switch to it in VS Code and copy its local settings path
   from **Preferences: Open User Settings (JSON)**. Supply that absolute path as
   `--settings-file`; never guess the internal profile ID.

3. Repeat the same command with the displayed hash:

   ```bash
   node "$PROFILE_HELPER" default --replace-settings --backup-dir "$PROFILE_BACKUPS" \
     --execute --approve HASH_FROM_PREVIEW
   ```

   Expected result: verified settings and shortcuts, plus a printed private
   backup path. A changed target or hash stops the operation. Reopen VS Code,
   verify settings and shortcuts, then deliberately reconcile Settings Sync.

## Restore and troubleshoot

Preview recovery with the exact printed backup path, then repeat with its new
approval hash:

```bash
node "$PROFILE_HELPER" default --restore "/absolute/path/to/printed/backup"
node "$PROFILE_HELPER" default --restore "/absolute/path/to/printed/backup" \
  --execute --approve HASH_FROM_RESTORE_PREVIEW
```

Expected result: original bytes and permissions restored; originally absent
files are absent again. Later edits cause a refusal so you can merge manually.
A partial replacement retains complete before/after files and `record.json`.
Keep the backup until you have verified recovery and no longer need it.

A `.day-one-profile.lock` directory beside the selected settings file prevents
concurrent helpers. After an interrupted process, verify no helper is running
before removing that exact empty lock with `rmdir`. Never remove another
process's lock or discard recovery records. Symlinked/shared/foreign targets
are refused. Use the manual merge procedure for those arrangements.

<a id="before-you-start"></a>
<a id="generate-review-files"></a>
<a id="import-settings-and-extensions-together"></a>
<a id="replace-existing-profile-settings-and-shortcuts"></a>
<a id="install-extensions-into-the-named-profile"></a>
<a id="verify-the-selected-action"></a>
<a id="troubleshooting"></a>
