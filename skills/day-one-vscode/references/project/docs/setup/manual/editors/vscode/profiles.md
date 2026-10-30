# Configure VS Code profiles and settings

Keep changes in User Settings for the active profile. Back up existing profiles before replacement. Start with the [editor setup](../vscode.md), then select [extensions](extensions.md).

## 1. Choose and create profiles

| Profile | Purpose | Appearance | Recommended profile icon | Normal database use |
|---|---|---|---|---|
| Default | Configuration, notes, general editing | Dark Modern; neutral | Built-in gear | None |
| Full Stack | Daily Angular/Nest/Nx development | Dark Modern; purple | Code (`code`) | Local/dev/test |
| AI | Prompt authoring, reviews, debugging, agents and skills | Dark Modern; blue | Robot (`robot`) | Optional local/dev/test tools |
| Operations | Containers, pipelines, databases, remote work | Dark Modern; green | Server (`server`) | Production read-only investigation |

Choose Default plus only the task profiles you need. Configure Default in
sections 2 and 3 before creating the named profiles in section 4.

### Create the selected profiles

1. Open **Manage gear → Profiles** to display the Profiles editor.
2. Select **Default**, using **Use this Profile for Current Window** if necessary.
3. Keep this window on Default while applying the shared extensions and settings below.

Expected result: the Profiles editor shows Default as active. Default normally
has no profile name in the window title. Named-profile creation follows under
[Apply profile settings](#4-apply-profile-settings).

### Choose profile icons

The Code icon identifies daily development, Robot identifies AI work, and
Server identifies infrastructure and database work. Keep Default's built-in
gear; the Default profile has no editable icon field in VS Code 1.143.1.

After creating a named profile:

1. Open **Manage → Profiles** and select **Full Stack**, **AI** or **Operations**.

   Expected result: the selected profile's **Name** and **Icon** fields appear.

2. Select **Profile Icon**, search for the identifier in the table above, and
   select the matching icon.

   Expected result: the profile list displays the chosen icon.

3. Select **Use this Profile for Current Window** to check the result.

   Expected result: the Manage button uses the profile icon. The title-bar
   accent follows the profile's User Settings.

These icons are native VS Code profile metadata, selected in the Profiles
editor. No icon extension or `settings.json` key is needed for them. Material
Icon Theme controls file and folder icons separately. See
[VS Code profile icons](https://code.visualstudio.com/docs/configure/profiles#_check-the-current-profile).

### Choose how resources are shared

| Mechanism | What later changes do | Use in this setup |
|---|---|---|
| Copy from Default | Creates an independent snapshot of selected resources | Starting point for each named profile |
| Apply Setting to all Profiles | Shares that setting across profiles | Optional for identical preferences such as font size; keep accents and language blocks profile-specific |
| Apply Extension to all Profiles | Makes that extension available across profiles | Recommended for the six shared extensions and Reload when selected |
| Use a whole resource from Default | Reuses Default's Settings, Keyboard Shortcuts or another selected resource | Keep Settings, Extensions and Keyboard Shortcuts owned by each named profile in this recipe |

Copying does not create inheritance between profiles. The AI recipe's
`extends` relationship belongs to the Day One Mac generator; the manual route
combines the documented JSON blocks itself. See [VS Code profiles](https://code.visualstudio.com/docs/configure/profiles).

## 3. Apply shared User Settings

Prepare the [personal Markdown rules](#markdown-formatting) before applying
the shared settings or importing a generated profile.

1. With Default active, run **Preferences: Open User Settings (JSON)**.
2. Merge the [shared settings block](../../../../shared/reference/vscode-profile-data.md#shared-settings)
   into the existing root object, preserving unrelated preferences.
3. Apply the [Default overrides](../../../../shared/reference/vscode-profile-data.md#default-overrides)
   to that same object and save the file.
4. Inspect Settings for unknown keys and open a new integrated terminal.
5. Open **Explorer → … → Open Editors** and enable it if unchecked.

Expected result: one valid JSON object supplies Dark Modern, a neutral title-bar
accent, the selected font and the development Zsh terminal. Default's Copilot
inline suggestions are off. Markdown uses markdownlint on explicit saves;
JSON uses Prettier.
Explorer displays nested folders on separate rows, including folders with only
one child folder, because `explorer.compactFolders` is `false`.
The expanded **Open Editors** section lists your open files.

`explorer.openEditors.visible: 9` sets the initial maximum list height before
scrolling. It does not enable a hidden view in VS Code 1.143.1. Visibility is
part of the profile's UI layout; check it after creating or importing each
profile. The Command Palette action **Explorer: Focus on Open Editors View**
also reveals the section. See the [VS Code Explorer guide](https://code.visualstudio.com/docs/editing/getting-started/userinterface#can-i-hide-the-open-editors-section-in-the-explorer-view).

Each subsequent profile receives this baseline by copying Default. A shared
recipe is not automatically a live shared setting. To share an individual
preference, open **Preferences: Open Settings (UI)**, find it, open its gear menu
and select **Apply Setting to all Profiles**. Keep values that differ below
in each profile's own User Settings.

### Settings ownership matrix

| Setting or configuration group | Default | Full Stack | AI | Operations | Where it belongs |
|---|---|---|---|---|---|
| Explicit saves, final newline, editor fonts, rulers and navigation preferences | Shared | Shared | Shared | Shared | User Settings; optional all-profiles sharing for identical values |
| `explorer.compactFolders` | Off | Off | Off | Off | Shared User Settings; show each nested folder on its own row |
| `explorer.openEditors.visible` | 9 | 9 | 9 | 9 | Shared User Settings; initial maximum rows before scrolling |
| Open Editors view visibility | On | On | On | On | Profile UI layout; enable through Explorer's Views menu |
| Editor tab layout and opening behavior | Shared | Shared | Shared | Shared | User Settings; see [Editor tabs](#editor-tabs) |
| Angular rename preferences | No | Shared | Shared | No | Profile User Settings; check standalone versus NgModule mode for each project |
| Dark Modern and Material Icon Theme | Shared | Shared | Shared | Shared | User Settings |
| Zsh profiles, terminal font, shell integration and Warp executable | Shared | Shared | Shared | Shared | Machine-specific User Settings; verify paths after import |
| Git fetch/sync preferences and Conventional Commit instructions | Shared | Shared | Shared | Shared | User Settings |
| GitLens Conventional Commit message instructions | Shared; active if installed | Shared | Shared | Shared | User Settings; separate from Copilot's generator |
| `git.enableSmartCommit` and `git.suggestSmartCommit` | Off | Off | Off | Off | Shared User Settings; stage selected changes before committing |
| Automatic Git worktree detection | On, limit 30 | On, limit 30 | On, limit 30 | On, limit 30 | Shared User Settings; discover existing worktrees |
| `chat.tools.global.autoApprove` and `chat.tools.terminal.enableAutoApprove` | Off | Off | Off | Off | Shared User Settings; applies to supported VS Code chat flows |
| `chat.mcp.gallery.enabled` | On | On | On | On | Shared User Settings; enables the MCP server gallery (Preview) |
| Markdown/JSON formatting and Markdown extension preferences | Shared | Shared | Shared plus prose suggestions off | Shared | Profile User Settings; preserve nested language values |
| Markdown compact-table style | Shared | Shared | Shared | Shared | Profile User Settings plus one private rules file; see [Markdown formatting](#markdown-formatting) |
| Title-bar and badge colors | Neutral | Purple | Blue | Green | Profile User Settings; do not share across profiles |
| Profile icon | Built-in gear | Code (`code`) | Robot (`robot`) | Server (`server`) | Profiles editor; separate from User Settings and file/folder icons |
| Copilot inline suggestions | Off | On except excluded languages | Off | Off | Profile User Settings; chat availability is separate |
| TS/JS, HTML, CSS/SCSS and Prisma formatting; import actions | No | Enabled | Enabled | No | Full Stack overrides, also combined into AI |
| GitLens inline annotations | No | Off | Off | Off | Profile User Settings where GitLens is selected |
| File Utils destination display and context menus | No | Configured | Inherited; active if installed | No | Full Stack User Settings, also combined into AI |
| CSS Peek selector lookup and telemetry preferences | No | Configured | Inherited; active if installed | No | Full Stack User Settings, also combined into AI |
| NPM Visual Manager columns, scan depth and background badge checks | No | Configured | Inherited; active if installed | No | Profile User Settings; avoid the workspace-writing Ignore Package button |
| Auto Barrel generation scope, export detection and formatting | No | Configured | Inherited | No | Profile User Settings; see [Auto Barrel](extensions.md#auto-barrel-full-stack-and-ai) |
| Tailwind CSS mode, Prettier registration, HTML class suggestions and SCSS at-rule warning policy | No | Enabled | Inherited | No | Profile User Settings; see [Tailwind CSS](extensions.md#tailwind-css-full-stack-and-ai) |
| `.env` associations, formatting and suggestion restrictions | No | Enabled | Enabled | Enabled | Profile User Settings; not an access-control boundary |
| Pipeline-file language mode | Default detection | Azure Pipelines | YAML | Azure Pipelines | Profile User Settings, matching installed language providers |
| SQL and Dockerfile format-on-save | Default behavior | Off | Off | Off | Profile User Settings |
| Codex and Claude preferences, agent instructions and skill discovery | No | Enabled | Enabled with AI overrides | Manual if selected | Profile User Settings; accounts and CLI permissions remain separate |
| Codex Cmd+Enter, queued follow-ups and inline reviews | No | Enabled | Inherited | Manual if selected | Profile User Settings; chat sharing has no separate sync setting |
| Import-cleanup shortcuts | No custom entries | Three chords | Three chords | No custom entries | Profile Keyboard Shortcuts JSON |
| New file tab shortcut | `Cmd+T` | `Cmd+T` | `Cmd+T` | `Cmd+T` | Shared Keyboard Shortcuts entries; native `Cmd+N` remains available |
| Angular/NestJS folder associations and Angular HTML token palette | No | Manual | No | No | Full Stack User Settings, sections 7 and 8 |
| Skills, MCP servers, credentials and database connections | Separate | Separate | Separate | Separate | Their linked client/tool configuration, not the profile settings recipe |

The [configuration reference](../../../../shared/reference/vscode-profile-data.md)
owns the exact keys and values. For manual merges, replace an existing scalar
value, merge nested object properties and replace arrays only when intended.
Do not paste multiple root objects or duplicate keys. In particular, retain
shared Markdown whitespace settings when applying the AI Markdown override.

To browse MCP servers, open Extensions and search `@mcp`, or run **MCP: Browse
MCP Servers** from the Command Palette. Enabling the gallery does not install
servers or change approvals. Follow the [MCP setup guide](../../ai/mcp.md) to
configure a selected server; organization policies can restrict availability.

The non-login Zsh terminal requires the shared PATH helper in `.zshrc`. Follow
the [Zsh recipe](../../shell/zsh.md) and replace `/bin/zsh` in both terminal profiles
only if you chose another executable. `terminal.external.osxExec` opens Warp
as a separate application.

The shared `terminal.integrated.suggest.upArrowNavigatesHistory` setting pairs
with the [Zsh matching-history bindings](../../shell/zsh.md#search-matching-commands-with-up-and-down).
Type `brew ` and press Up/Down to check matching history. The VS Code setting
alone does not configure Zsh; Warp retains its own input behavior.

Keep Smart Commit and its suggestion disabled in all four profiles. This avoids
automatically staging unrelated edits when nothing is staged and suppresses the
Smart Commit suggestion. In each profile, open **Preferences: Open Settings (UI)**
and check that **Git: Enable Smart Commit** and **Git: Suggest Smart Commit** are
both unchecked. See [staging and committing changes](https://code.visualstudio.com/docs/sourcecontrol/staging-commits)
for reviewing and staging individual files or selected lines.

The shared `git.detectWorktrees` setting enables discovery of existing Git
worktrees, with `git.detectWorktreesLimit` set to 30. This does not create a
worktree. Follow the [worktree guide](../../development/worktrees/vscode.md#configure-worktree-detection)
to verify discovery and choose optional window and terminal preferences.

Stage intended changes before selecting **Generate Commit Message** in Source
Control. The shared experimental
`github.copilot.chat.commitMessageGeneration.instructions` setting requests a
Conventional Commit subject and a useful body for substantial changes. Review
the result. This setting applies to Copilot's generator; GitLens uses the
separate setting below. Codex and Claude use their own instructions.
Keep credentials out of settings and exports.
[AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

### Editor tabs

All four profiles use readable file labels and wrap overflowing editor tabs
onto additional rows. Paths appear when needed to distinguish matching file
names. Single-clicking a file previews it in a reusable tab; Quick Open also
uses preview mode. Double-click a file or edit it to keep its tab open. Retained
tabs wrap onto additional rows. New tabs appear to the right of the active tab;
an editor-count limit does not close older files to make room.

1. Activate each selected profile and run **Preferences: Open User Settings (JSON)**.

   Expected result: the settings file belongs to the intended profile. Back up
   its existing contents before editing.

2. Merge the `workbench.editor.*` entries from the
   [shared settings block](../../../../shared/reference/vscode-profile-data.md#shared-settings)
   into its root object and save, preserving unrelated preferences.

   Expected result: the shared tab preferences are present without duplicate
   keys. These are User Settings; no project configuration file is needed.

3. Single-click two unchanged files in Explorer, one after the other.

   Expected: the second file reuses the italic preview tab. Double-click that
   file to retain it, then single-click another file. The retained tab stays
   open beside the new preview. Repeat with `Cmd+P` to check Quick Open.

4. Press `Cmd+N` twice or double-click empty space beside the tabs.

   Expected: new blank tabs can be created. Double-click enough file tabs to
   retain them and fill the tab bar; additional retained tabs wrap to another
   row. Edit a disposable blank tab to check its modified highlight, then close
   the test tabs and discard only the disposable edit.

`Cmd+N` creates a blank file even when no empty space remains beside the tabs.
With space available, double-click the empty editor title area to create one.
The [shared new-tab shortcut](editing.md#new-file-tab-shortcut) also assigns `Cmd+T` to
this action. Use `Ctrl+Tab` to switch recent editors, `Cmd+Shift+T` to reopen a
closed editor and `Cmd+W` to close the active one. See the
[default shortcuts](https://code.visualstudio.com/docs/reference/default-keybindings)
and [tab guide](https://code.visualstudio.com/docs/editing/getting-started/userinterface#tabs).

Wrapped rows use some vertical space. If a single row suits your screen better,
disable **Workbench → Editor: Wrap Tabs** and scroll the tab bar instead.
Settings and defaults were checked against VS Code 1.143.1 on 27 October 2026.
Workspace settings can override profile preferences; inspect the active
setting's workspace value if behavior differs. Restoring the saved tab values
reverts this configuration without replacing other profile settings.

### Markdown formatting

All four profiles use markdownlint to format Markdown on explicit saves.
Its compact table rule keeps one space around cell contents instead of padding
columns to match the longest cell. Prettier remains the formatter for code and
JSON in the profiles that enable those languages.

1. Create the personal configuration directory in Terminal:

   ```bash
   mkdir -p "$HOME/.config/markdownlint"
   ```

   Expected result: the directory exists outside your repositories.

2. Open its rule file in VS Code:

   ```bash
   code "$HOME/.config/markdownlint/config.json"
   ```

   Expected result: VS Code opens the existing file or a new buffer. Back up
   existing contents before editing them.

3. Copy the [personal Markdown rules](../../../../shared/reference/vscode-profile-data.md#personal-markdown-rules)
   into that file and save. For an existing configuration, merge the `MD013`
   and `MD060` properties while preserving unrelated rules.

   Expected result: a valid JSON file selects compact tables and a 100-character
   prose limit, with tables and code blocks exempt. The configuration reference
   owns its exact values.

4. Apply the [shared settings](../../../../shared/reference/vscode-profile-data.md#shared-settings)
   to each selected profile, preserving nested preferences such as AI's
   suggestion settings.

   Expected result: `markdownlint.configFile` points to the personal rule file,
   and `[markdown]` selects `DavidAnson.vscode-markdownlint` with format-on-save
   enabled. Keep Markdown All in One's table formatter disabled. Avoid adding
   a second formatter or fix-on-save action for Markdown.

5. Save a disposable Markdown file containing compact and padded tables with
   `Cmd+S` in each profile. Test outside a repository first to isolate your
   personal rules, then check a project with its own configuration.

   Expected result: compact cells retain their spacing; padded cells lose
   extra spaces unless project rules select another style. Existing long
   separator dashes remain unchanged. Shorten them manually to `---` where
   wanted, preserving alignment markers such as `:---` or `---:`.

6. Add a table row and a labeled code block with lines longer than 100 characters
   to the disposable file. Add a prose line longer than 100 characters with
   several words beyond that limit, then save.

   Expected result: `MD013` flags the prose line but skips the table and code
   block. Split the prose at a space, then save again to clear that warning.
   Project rules can select a different limit or include tables and code.

Markdownlint 0.62.1 provides this formatter and supports the `MD060` compact
rule, checked on 26 October 2026. It applies supported lint fixes, including
spacing around headings and lists, but does not reformat code inside fenced
examples like Prettier. Language-specific Prettier options do not control this
Markdown formatter. See the publisher's [formatting commands](https://github.com/DavidAnson/vscode-markdownlint#fix)
and [table style rule](https://github.com/DavidAnson/markdownlint/blob/main/doc/md060.md).

The personal `MD013` rule uses a 100-character limit for prose and headings;
tables and code blocks are exempt so long cells and commands remain intact.
Markdownlint reports long prose without automatically reflowing it. Wrap prose
at word boundaries; shorten an overlong heading instead of splitting it.
The rule retains its default exceptions for unbreakable text such as long URLs.
See the [line-length rule](https://github.com/DavidAnson/markdownlint/blob/main/doc/md013.md).

Other checks stay enabled. Label command fences with `bash` and plain output
with `text` to satisfy `MD040`. Put angle-bracket placeholders such as `<app>`
inside inline code so `MD033` does not treat them as HTML.

Word wrapping stays enabled for prose. Long table content can still wrap
visually; `Option+Z` toggles wrapping in the current editor. It does not change
the file's line lengths or resolve `MD013` warnings. Generic trailing-whitespace
trimming remains disabled for Markdown to protect spaces used for explicit line
breaks.

The supported `markdownlint.configFile` setting supplies personal defaults;
repository configurations can override them. The older `markdownlint.config`
setting is deprecated. Keep established project rules authoritative and inspect
**View → Output → markdownlint** when behavior differs. See the
[configuration precedence](https://github.com/DavidAnson/vscode-markdownlint#configure)
and [personal configuration guidance](https://github.com/DavidAnson/vscode-markdownlint#markdownlintconfigfile).

Profile exports and Settings Sync include the setting, not the external rule
file. Back up `~/.config/markdownlint/config.json` alongside your profile exports
and restore it before using the profiles on another Mac. To revert the setup,
restore the saved profile settings and the previous rule file if one existed.

### Show GitLens blame without editor clutter

Full Stack and AI show current-line blame beside the selected line, with
CodeLens kept off. Operations keeps blame in the status bar and offers file
annotations on demand. The exact values live in the
[profile configuration reference](../../../../shared/reference/vscode-profile-data.md).

1. Select the intended profile and open a committed file in the normal editor.
2. Place the cursor on an unchanged line. Expected: Full Stack and AI show its
   author, date and commit summary at the end of the line.
3. Run **GitLens: Toggle File Blame** from `Cmd+Shift+P` for file-wide annotations.
   Expected: the gutter shows commit information beside groups of lines.
4. Run the same command again to clear file annotations. Use
   **GitLens: Toggle Line Blame Annotations** to toggle the current-line display.

If only the bottom status bar shows an author, inspect
`gitlens.currentLine.enabled` in the active profile's User Settings.
Check workspace overrides and GitLens's active mode before changing another
profile. A diff editor, untracked file or newly changed line is a different
verification target from an unchanged committed line.

Current-line annotations were observed in Full Stack with GitLens 19.4.0 on
27 October 2026. Saved values were checked for AI separately. These local checks
do not establish remote-workspace behaviour. See
[GitLens blame features](https://help.gitkraken.com/gitlens/gitlens-features/)
and the [settings reference](https://help.gitkraken.com/gitlens/gitlens-settings/).
Restore the profile's exported settings to undo a personal configuration change.

### Generate Conventional Commit messages with GitLens

The shared `gitlens.ai.generateCommitMessage.customInstructions` setting asks
GitLens to use `type(scope): description`, with an optional scope and an
evidence-based body for substantial changes. Its full value lives in the
[shared settings JSON](../../../../shared/reference/vscode-profile-data.md#shared-settings).
All four recipes carry it; Default uses it only if GitLens is available.
This does not add GitLens to Default's extension list or change the AI provider.

The setting and its use by both message generation and commit composition
were checked against GitLens 19.4.0 on 25 October 2026. Keep
`gitlens.ai.generateCommits.customInstructions` for additional grouping rules
if needed; duplicating the message instructions there is unnecessary in this
version. [GitLens configuration](https://github.com/gitkraken/vscode-gitlens/blob/main/src/config.ts),
[settings reference](https://help.gitkraken.com/gitlens/gitlens-settings/).

1. Open **Preferences: Open User Settings (JSON)** in the intended profile.

   Expected result: the shared GitLens instruction is present. Add its value
   from the linked JSON if it is missing.

2. Stage the files or individual changes intended for the next commit.

   Expected result: Source Control's **Staged Changes** contains that scope.

3. Run **GitLens: Generate Commit Message** from the Command Palette.

   Expected result: GitLens fills the commit message using its configured AI
   provider. Complete its provider or account setup if prompted.

4. Review the generated message against the staged changes before committing.

   Expected result: the type and scope match the change, and any body explains
   supported facts. Remove invented test results or unsupported breaking-change
   claims. [GitLens generation workflow](https://help.gitkraken.com/gitlens/gitlens-features/#ai-generated-commit-messages).

These instructions guide generation; a repository hook such as commitlint
provides format checks. Removing this one User Setting restores GitLens's
default message instructions without changing Copilot's settings.

## 4. Apply profile settings

1. Open **Manage gear → Profiles → New Profile** after verifying Default.
2. Enter the exact selected name: **Full Stack**, **AI** or **Operations**.
3. Choose **Copy from → Default** and include copies of Settings, Extensions
   and Keyboard Shortcuts, rather than reusing those whole resources from Default.
4. Select **Create**, then **Use this Profile for Current Window**.
5. Open Extensions and install the active profile's **R** entries from the
   [extension matrix](extensions.md#extension-tables), skipping shared entries already present.
6. Add only the **O** entries needed for your tasks. Keep task-specific extensions
   scoped to this profile instead of selecting the all-profiles action.
7. Open **Preferences: Open User Settings (JSON)** and combine the blocks below
   in order, following the nested-object merge rules in section 3.
8. Run **Explorer: Focus on Open Editors View** from the Command Palette.
9. Repeat these steps for each additional profile you chose.

Expected result: each named profile has the intended accent, extension column
and settings. AI copies Default's extension baseline, then adds its own list;
it does not require copying Full Stack's extra extensions or keeping a Full Stack
profile. Use **Profiles: Switch Profile** to compare the results.

| Profile | Exact settings recipe |
|---|---|
| Default | Shared block + Default overrides |
| Full Stack | Shared block + Full Stack overrides |
| AI | Shared block + Full Stack overrides + AI overrides; use AI's extension table |
| Operations | Shared block + Operations overrides |

### Default overrides

Use the maintained [JSON configuration](../../../../shared/reference/vscode-profile-data.md#default-overrides).

Copilot chat remains available; only inline suggestions are off.

### Full Stack overrides

This includes language formatting, manual unused-import removal, GitLens,
agent UI settings, YAML associations, environment-file handling, and generated
file exclusions. Claude Code and Good Prompts are part of the baseline.

Use the maintained [JSON configuration](../../../../shared/reference/vscode-profile-data.md#full-stack-overrides).

Prettier options are personal fallbacks; repository configuration takes
precedence. `source.sortImports` runs on explicit saves. Unused-import removal
and full Organize Imports stay manual; ESLint can still remove imports if its
project rules request that. Prisma owns `.prisma` formatting.

Open the Nx root and select **TypeScript: Select TypeScript Version → Use
Workspace Version**. Install the project's dependencies. An editor extension
does not install framework packages, ESLint, a database server, or Docker.

DotENV highlighting does not load variables. Its language overrides disable
inline suggestions and formatting, not an agent's ability to read the file.
Exclude real secrets from Git and use the application's own environment loader.

### AI overrides

Apply after the Full Stack settings block, using the AI extension column.
These replace the accent and Copilot inline preference while retaining
TypeScript/Angular/Prisma diagnostics and formatting. Pipeline filenames use
ordinary YAML because Azure Pipelines is not in AI's baseline. Full Stack and
Operations retain the dedicated Azure Pipelines language mode.

Use the maintained [JSON configuration](../../../../shared/reference/vscode-profile-data.md#ai-overrides).

Chat fonts and wrapped code improve readability. Checkpoints and change
summaries assist review; Git remains the record of repository changes. A zero
auto-accept delay disables timed acceptance in supported chat flows.

Codex uses Cmd+Enter, queues follow-ups, and keeps reviews in the current chat
when supported in both Full Stack and AI. Its sidebar does not take focus on
startup, and TODO CodeLens actions are off. These are interface preferences;
follow [continuing a Codex chat between VS Code and desktop](../../ai/workflows.md#continue-a-codex-chat-between-vs-code-and-desktop)
to use the same conversation in both applications.

Claude uses Cmd+Enter, Manual starting permissions, explicit file attachment,
and intentional resumption after reload. Save relevant files before a task:
Claude automatic saving is off. Runtime permissions and model/account choices
remain in each client's own configuration.
[Codex settings](https://learn.chatgpt.com/docs/developer-settings),
[Claude settings](https://code.claude.com/docs/en/vs-code).

### Operations overrides

Use the maintained [JSON configuration](../../../../shared/reference/vscode-profile-data.md#operations-overrides).

SQL stays manually formatted until you deliberately choose a formatter.
Configure connection credentials through PostgreSQL's connection UI, not JSON.
If enabling Codex or Claude in Operations, add their extension preferences
from Full Stack selectively; a profile switch does not grant database access.

### Associate a project with its profile

1. Open the intended folder or workspace in VS Code.
2. Run **Profiles: Switch Profile** and choose the intended profile.
3. Reopen that folder and inspect the active profile in **Manage gear → Profiles**.

Expected result: VS Code remembers the folder's profile association. Open
separate windows or worktrees when you need different profiles concurrently.
An association does not isolate accounts or grant database permissions.
[Folder associations](https://code.visualstudio.com/docs/configure/profiles#folder--workspace-associations).

## 10. Optional custom profile: Tech Content Creator

Use a separate writing profile only when articles, tutorials or screenshots
need a different editor layout. This is a manual customisation, not a fifth
`vscode-profile` generator recipe. Work and Personal profiles can use the same
approach with their organisation-approved extensions and account policies.

1. Export the current configuration using the [backup guide](recovery.md#export-and-back-up-the-configuration).
2. Create **Tech Content Creator** by copying a reviewed Default profile, or
   choose **Empty Profile** when cleaning up unknown state.
3. Review the Default column in the [extension matrix](extensions.md#extension-tables). Markdown,
   Prettier and icons cover the writing baseline. Add `usernamehw.errorlens`
   only if inline error messages help your demonstrations.
4. Apply [shared User Settings](#3-apply-shared-user-settings) and
   [Default overrides](#default-overrides), then merge the presentation
   overrides below. Preserve both explicit agent approval settings and the
   shared commit-message instructions when editing the baseline.
5. Test Markdown formatting, terminal launch and a sample document; then
   [export the new profile](recovery.md#export-a-portable-profile---preferred).

```jsonc
{
  "editor.fontSize": 15,
  "editor.lineHeight": 24,
  "editor.wordWrap": "on",
  "editor.rulers": [88],
  "window.commandCenter": false,
  "zenMode.hideLineNumbers": false
}
```

These are overrides, not a complete settings file. Keep project formatting
rules in the repository's own configuration. Inspect exports for private
paths, account details and unwanted extensions; profile copying is a snapshot,
so later shared-baseline changes must be reviewed in this custom profile too.
Keep presentation font size and rulers profile-specific. Reload is available
here too when **Apply Extension to all Profiles** is selected.

---

[Application guides](../../apps/README.md) · [Warp](../../terminals/warp.md) · [Vorssaint](../../apps/vorssaint.md)
