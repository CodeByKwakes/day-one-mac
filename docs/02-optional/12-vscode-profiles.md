[← MCP servers](11-mcp-servers.md) · **🤖 ⚙️ Optional 12** · [Enhanced CLI tools →](13-enhanced-cli-tools.md)

# Optional 12 — VS Code profiles

**Time:** 15–35 minutes · **Required:** no · **Prerequisite:** Phase 7

## Outcome

You have either kept the default profile or created a small set of purposeful
profiles. Existing settings were exported before removal, Settings Sync has a
single understood source of truth, and each new profile contains only the
extensions and settings needed for its job.

Profiles are optional. A single default profile is the simplest and most
reproducible choice. Add profiles only when work, personal, or content tasks
need meaningfully different extensions, accounts, trust boundaries, or UI.

## Step 12.1 — Decide whether profiles solve a real problem

Use one profile when all projects share roughly the same editor. Consider
separate profiles when:

- A work organisation controls extensions or Settings Sync.
- Personal and work GitHub accounts must not share Copilot state.
- Python and web projects otherwise load large irrelevant extension sets.
- Content creation needs writing, Markdown, spelling, image, or recording
  tools that do not belong in the development profile.

A practical maximum is four:

| Profile | Purpose | Typical additions |
|---|---|---|
| General Development | Default coding environment | Git, formatting, common languages |
| Work | Employer repositories and policies | Organisation-approved Azure/Git tooling |
| Personal | Personal GitHub and experiments | Personal account integrations |
| Tech Content Creator | Articles, tutorials, demos and code screenshots | Markdown, spelling, presentation-friendly UI |

## Step 12.2 — Export the current state first

In VS Code:

1. Open the Accounts icon at the lower left.
2. Choose **Profiles** → **Export Profile**.
3. Select Settings, Keyboard Shortcuts, Snippets, Tasks, and Extensions.
4. Save the `.code-profile` file outside the VS Code user-data directory,
   preferably in a reviewed backup folder.
5. Give it a date, for example `vscode-before-clean-start-2026-09-11.code-profile`.

Also record the installed extensions from Terminal:

```bash
mkdir -p "$HOME/.day-one-mac/vscode-backup"
code --list-extensions --show-versions \
  > "$HOME/.day-one-mac/vscode-backup/extensions-before-clean.txt"
```

Do not continue until the export can be located in Finder.

## Step 12.3 — Choose what “clean” means

These are independent choices:

| Item | Remove when | Keep when |
|---|---|---|
| Extensions | You want to rebuild the extension list | The existing list is already deliberate |
| Settings/keybindings/snippets | Old settings conflict or are unexplained | They are understood and portable |
| Profiles | Old profiles overlap or have no clear owner | Each profile has a unique purpose |
| Settings Sync cloud data | The cloud copy would immediately reintroduce old state | Another trusted machine still relies on it |

For a fresh local start, first turn off Settings Sync from the Accounts menu.
Choose the option that keeps cloud data until the local replacement is proven.
Deleting local and cloud state together removes the easiest recovery route.

## Step 12.4 — Remove only the chosen local state

### Extensions only

List extensions, then uninstall each reviewed extension through the Extensions
view. For a completely empty extension list after exporting:

```bash
code --list-extensions
```

Use the extension gear menu → **Uninstall**. GUI removal is slower but makes
the selection explicit and respects profile ownership.

### Settings only

Press `⌘⇧P`, run **Preferences: Open User Settings (JSON)**, copy the file to
the backup location, then replace its contents with `{}`. Repeat separately
for Keyboard Shortcuts JSON only if that is also being reset.

### Old profiles

1. Accounts → **Profiles** → **Manage Profiles**.
2. Switch away from the profile being removed.
3. Export it if it has not already been exported.
4. Use its gear menu → **Delete Profile**.
5. Keep the Default profile until a replacement opens a real repository.

Avoid deleting `~/Library/Application Support/Code/User` manually. It combines
settings, profiles, state, snippets, and authentication-adjacent metadata; the
in-app operations provide safer scope and clearer recovery.

## Step 12.5 — Create a profile

1. Accounts → **Profiles** → **Create Profile**.
2. Choose **Empty Profile** for a true clean start.
3. Enter the profile name.
4. Select a distinct icon so the active context is visible.
5. Open a representative repository with that profile.
6. Install only the extensions required by that repository.
7. Apply a minimal settings file and test formatting, terminal launch, Git,
   and source control before adding more.

Use **Create from Current Profile** only when most existing state is wanted;
otherwise it carries the clutter into the new profile.

## Step 12.6 — Build the Tech Content Creator profile

Create an empty profile named **Tech Content Creator**. Its goals are readable
prose, accurate code snippets, clean demonstrations, and a quiet interface.

Suggested extension choices:

| Marketplace name | Extension ID | Why |
|---|---|---|
| Code Spell Checker | `streetsidesoftware.code-spell-checker` | Catches prose and identifier typos |
| markdownlint | `davidanson.vscode-markdownlint` | Consistent Markdown structure |
| Markdown All in One | `yzhang.markdown-all-in-one` | Table of contents and authoring shortcuts |
| Prettier - Code formatter | `esbenp.prettier-vscode` | Formats supported code examples |
| Error Lens | `usernamehw.errorlens` | Makes demo errors visible in the editor |
| Material Icon Theme | `pkief.material-icon-theme` | Clear file identification on screen |

Install only the entries you need:

```bash
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension davidanson.vscode-markdownlint
code --install-extension yzhang.markdown-all-in-one
code --install-extension esbenp.prettier-vscode
code --install-extension usernamehw.errorlens
code --install-extension pkief.material-icon-theme
```

Use this compact profile settings baseline:

```jsonc
{
  "editor.fontFamily": "'JetBrainsMono Nerd Font', Menlo, monospace",
  "editor.fontSize": 15,
  "editor.lineHeight": 24,
  "editor.minimap.enabled": false,
  "editor.stickyScroll.enabled": true,
  "editor.wordWrap": "on",
  "editor.formatOnSave": true,
  "editor.rulers": [88],
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "markdown.preview.breaks": false,
  "markdown.validate.enabled": true,
  "workbench.iconTheme": "material-icon-theme",
  "workbench.startupEditor": "none",
  "workbench.activityBar.location": "top",
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'",
  "window.commandCenter": false,
  "zenMode.hideLineNumbers": false
}
```

Keep project-specific formatter choices in the repository’s
`.vscode/settings.json`. Do not put recording paths, tokens, client names, or
private absolute paths in a profile intended for export.

## Step 12.7 — Configure Settings Sync deliberately

Settings Sync is optional. It is useful only after the new local baseline is
correct.

1. Sign in with the account that should own this environment.
2. Accounts → **Backup and Sync Settings**.
3. Open **Settings Sync: Configure** from the Command Palette.
4. Select only the categories you want to roam.
5. Include Profiles and Extensions only if the same profile design should
   appear on another Mac.
6. Treat MCP Servers as a separate security choice; never sync literal secrets.
7. Let the initial sync finish, quit VS Code, reopen it, and verify the active
   profile before enabling Sync on a second machine.

If VS Code asks whether to merge or replace remote data, stop and identify
which side contains the trusted baseline. Keep the exported `.code-profile`
until the second machine has reproduced it successfully.

Work and personal organisations can have different account and extension
policies. In that case, keep separate profiles and follow the organisation’s
managed-settings rules instead of forcing one synced profile across both.

## Step 12.8 — Export the new profiles

For every retained profile:

1. Switch into it.
2. Accounts → **Profiles** → **Export Profile**.
3. Review every selected component.
4. Save the `.code-profile` file to a private, backed-up location.
5. Import it on a second machine only after reviewing the extension list.

Do not commit an exported profile before inspecting it as text for private
repository URLs, usernames, absolute paths, or service configuration.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Old settings return immediately | Disable Settings Sync, reset locally again, then decide whether to clear or replace the cloud copy |
| An extension exists in one profile only | Switch to that profile before changing the extension; profile extension sets are separate |
| `code` is not found | In VS Code run **Shell Command: Install 'code' command in PATH**, then open a new terminal |
| Formatter works in one repo but not another | Check the workspace `.vscode/settings.json` and install the formatter in the active profile |
| Copilot uses the wrong account | Sign out in the active profile and authenticate the intended GitHub account; do not share the work profile |
| Import brings back too much | Delete the new profile, recreate an empty one, and manually select the smaller extension set |

## Completion checklist 🚦

- [ ] An export and versioned extension list exist before any reset.
- [ ] Every retained profile has one clear purpose.
- [ ] The Default profile can still open and edit a normal repository.
- [ ] The Tech Content Creator profile, if created, opens Markdown and code
      examples with the expected formatting.
- [ ] No profile contains credentials or machine-specific private paths.
- [ ] Settings Sync uses the intended account and categories.
- [ ] The replacement profile was tested before old cloud data was removed.

---

[← MCP servers](11-mcp-servers.md) · [Enhanced CLI tools →](13-enhanced-cli-tools.md) · [Project home](../README.md)
