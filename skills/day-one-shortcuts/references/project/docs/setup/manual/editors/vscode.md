# Configure VS Code for development

Set up personal profiles for Angular, NestJS, Prisma, Nx, TypeScript, databases
and AI work on macOS. This complete manual task keeps editor settings in
**User Settings for the active profile**; it does not create project `.vscode`
files or invoke Day One Mac scripts.

## Before you start

Complete [Homebrew](../homebrew.md), [language tools](../languages.md) and
[Zsh startup](../shell/zsh.md). Keep your approved existing VS Code installation;
install `visual-studio-code` through Homebrew only when absent and Homebrew is
its intended owner. Use the organisation's channel for managed software.

Have the selected project's dependencies, Git and Node.js available before
testing Full Stack or AI. Select JetBrainsMono Nerd Font if installed, or keep
the supplied fallback font. Warp is optional; omit its external-terminal setting
when you do not use it. Account access and managed extension policies remain
prerequisites for the AI tools you select.

Profiles organise settings and extensions. They do not isolate accounts, agent
credentials, database permissions or CLI configuration. **User Settings** means
the active profile's personal settings; workspace settings and IT policy can
override them. This procedure creates no project `.vscode` files.

The exact JSON is generated from the versioned configuration in
[profile data](../../../shared/reference/vscode-profile-data.md). Keep that page
open beside this procedure. It owns the copyable values; the tables below explain
where each group belongs. Marketplace links identify extensions; check the
publisher and the installed editor's setting schema before applying preferences.
The official [profile documentation](https://code.visualstudio.com/docs/configure/profiles)
and [AI overview](https://code.visualstudio.com/docs/agents/overview) were consulted
on 24 October 2026. Account, policy and version differences can affect availability.

## Open VS Code and enable the CLI

1. Open the approved VS Code application.

   Expected result: the editor opens without a conflicting duplicate installation.

2. Run **Shell Command: Install 'code' command in PATH** from the Command Palette
   (`Cmd+Shift+P`).

   Expected result: `code --version` prints the editor version in a new terminal.

3. [Export each existing profile](#export-a-portable-profile---preferred) that
   you intend to change.

   Expected result: a private `.code-profile` backup exists for each selected profile.

4. Review Settings Sync in the Manage gear menu and pause it while replacing an
   existing configuration, keeping the cloud copy.

   Expected result: changes on this Mac will not immediately replace another
   device's configuration. Re-enable Sync only after local verification.

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

## 2. Install the final extension lists

### Copilot: already provided through your VS Code setup

Inspect the AI features already available in your approved VS Code installation.
If Copilot is provided, do not install duplicate components. The identifiers
`github.copilot` and `github.copilot-chat` identify Marketplace components, not
additional requirements for an installation that already supplies the capability. Use the status-bar **Use AI
Features** flow and your intended account. Access depends on account and policy.
[Copilot setup](https://code.visualstudio.com/docs/setup/copilot).

| Capability | Default | Full Stack | AI | Operations |
|---|---|---|---|---|
| Inline suggestions | Off | On, excluding environment files and prose | Off initially | Off initially |
| Chat and agents | Available on demand | Enabled | Enabled | Use deliberately |

TypeScript services, Node debugging, Git/worktrees, supported prompt/skill handling, and
Dark Modern are native editor capabilities. They are not additional extensions
to install. Skills and MCP servers are separate configuration, described later.

### Extension tables

**R** means recommended for that profile. **O** means optional for an actual
task. **No** means outside its recipe. Companion extensions may be installed by
their parent extension; do not install them a second time just to match a count.

| Extension | Identifier | Purpose | Default | Full Stack | AI | Operations |
|---|---|---|---|---|---|---|
| [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Format supported languages | R | R | R | R |
| [EditorConfig](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) | `editorconfig.editorconfig` | Respect repository whitespace rules | R | R | R | R |
| [Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) | `pkief.material-icon-theme` | File and folder icons | R | R | R | R |
| [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) | `yzhang.markdown-all-in-one` | Markdown editing conveniences | R | R | R | R |
| [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) | `streetsidesoftware.code-spell-checker` | Spelling diagnostics | R | R | R | R |
| [markdownlint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint) | `davidanson.vscode-markdownlint` | Markdown structure checks | R | R | R | R |
| [Angular Language Service](https://marketplace.visualstudio.com/items?itemName=angular.ng-template) | `angular.ng-template` | Angular template diagnostics and navigation | No | R | R | No |
| [Angular HTML](https://marketplace.visualstudio.com/items?itemName=ghaschel.vscode-angular-html) | `ghaschel.vscode-angular-html` | Your chosen template highlighting | No | R | No | No |
| [Nx Console](https://marketplace.visualstudio.com/items?itemName=nrwl.angular-console) | `nrwl.angular-console` | Generators, targets, and workspace information | No | R | R | No |
| [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) | `dbaeumer.vscode-eslint` | Repository lint diagnostics and fixes | No | R | R | No |
| [Prisma](https://marketplace.visualstudio.com/items?itemName=prisma.prisma) | `prisma.prisma` | Prisma schema editing and formatting | No | R | R | No |
| [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) | `eamodio.gitlens` | History, blame, and comparisons | No | R | R | R |
| [Codex - OpenAI’s coding agent](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) | `openai.chatgpt` | OpenAI coding-agent integration | No | R | R | O |
| [Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) | `anthropic.claude-code` | Anthropic coding-agent integration | No | R | R | O |
| [Good Prompts](https://marketplace.visualstudio.com/items?itemName=omarbanat.goodprompts) | `omarbanat.goodprompts` | Guided prompt generation and library | No | R | R | No |
| [DotENV](https://marketplace.visualstudio.com/items?itemName=mikestead.dotenv) | `mikestead.dotenv` | Environment-file highlighting | No | R | R | R |
| [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) | `redhat.vscode-yaml` | YAML schemas and diagnostics | No | R | R | R |
| [Azure Pipelines](https://marketplace.visualstudio.com/items?itemName=ms-azure-devops.azure-pipelines) | `ms-azure-devops.azure-pipelines` | Pipeline YAML support | No | R | No | R |
| [Container Tools](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-containers) | `ms-azuretools.vscode-containers` | Docker and Compose tooling | No | R | No | R |
| [PostgreSQL](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-pgsql) | `ms-ossdata.vscode-pgsql` | Direct PostgreSQL browsing and queries | No | R | O | R |
| [vscode-pdf](https://marketplace.visualstudio.com/items?itemName=tomoki1207.pdf) | `tomoki1207.pdf` | PDF viewing | O | No | No | No |
| [Excel Viewer](https://marketplace.visualstudio.com/items?itemName=grapecity.gc-excelviewer) | `grapecity.gc-excelviewer` | spreadsheet/CSV viewing | O | No | No | No |
| [Reload](https://marketplace.visualstudio.com/items?itemName=natqe.reload) | `natqe.reload` | Status-bar button for the built-in Reload Window command | O | O | O | O |
| [Jest](https://marketplace.visualstudio.com/items?itemName=orta.vscode-jest) | `orta.vscode-jest` | When the repository uses Jest | No | O | O | No |
| [Playwright Test](https://marketplace.visualstudio.com/items?itemName=ms-playwright.playwright) | `ms-playwright.playwright` | When the repository uses Playwright | No | O | O | No |
| [Tailwind CSS IntelliSense](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) | `bradlc.vscode-tailwindcss` | When the repository uses Tailwind | No | O | No | No |
| [Stylelint](https://marketplace.visualstudio.com/items?itemName=stylelint.vscode-stylelint) | `stylelint.vscode-stylelint` | When the repository configures Stylelint | No | O | No | No |
| [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | `ms-vscode-remote.remote-containers` | When you develop inside a container | No | O | No | O |
| [GitHub Pull Requests](https://marketplace.visualstudio.com/items?itemName=github.vscode-pull-request-github) | `github.vscode-pull-request-github` | GitHub-hosted PRs; not Azure Repos PRs | No | O | No | No |
| [Error Lens](https://marketplace.visualstudio.com/items?itemName=usernamehw.errorlens) | `usernamehw.errorlens` | If inline diagnostics improve readability | No | O | No | No |
| [Switch to DataGrip](https://marketplace.visualstudio.com/items?itemName=MaxPowerEngine.switch2datagrip) | `maxpowerengine.switch2datagrip` | SQL-file handoff; not database browsing | No | O | No | O |
| [Chat Customizations Evaluations](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-chat-customizations-evaluations) | `ms-vscode.vscode-chat-customizations-evaluations` | prompt/skill analysis using Copilot | No | No | O | No |
| [Foundry Toolkit for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-windows-ai-studio.windows-ai-studio) | `ms-windows-ai-studio.windows-ai-studio` | model playground and AI application tooling | No | No | O | No |
| [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) | `ms-vscode-remote.remote-ssh` | When opening remote folders | No | No | No | O |
| [Remote - SSH: Editing](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-edit) | `ms-vscode-remote.remote-ssh-edit` | Keep when required by Remote SSH | No | No | No | O |
| [Remote Explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer) | `ms-vscode.remote-explorer` | Keep when required by remote tooling | No | No | No | O |
| [shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format) | `foxundermoon.shell-format` | shell formatting; choose one formatter | No | No | No | O |

Keep DataGrip as the primary database application and PostgreSQL for in-editor
browsing. Use one icon theme and one formatter per language. GitLens supplements
native Git; ESLint and configured Stylelint supply diagnostics and fixes.

#### Default extensions

Use the **Default** column in the matrix, then follow
[Install and share the Default baseline](#install-and-share-the-default-baseline).

#### Full Stack extensions

Use the **Full Stack** column when [creating the development profile](#4-apply-profile-settings).

#### AI extensions

Use the **AI** column with the [AI settings recipe](#ai-overrides);
copying settings does not require copying Full Stack's extension selection.

#### Operations extensions

Use the **Operations** column with the [Operations settings recipe](#operations-overrides).

### Install and share the Default baseline

1. Open **View → Extensions** (`Cmd+Shift+X`) while Default is active.
2. Search each Default **R** entry by its identifier, verify the publisher and
   select **Install** if it is absent.
3. Open each installed entry's gear menu and select **Apply Extension to all Profiles**.
4. Include Reload with the same sharing action if you want its status-bar button.

Expected result: the Default baseline is enabled, and the selected shared
extensions remain available after switching profiles. Leave task-specific
extensions for section 4. Installing an extension into Default alone is not
the same as selecting the all-profiles action.

### Reload: optional shared convenience

**Reload** (`natqe.reload`, publisher `natqe`) adds a button on the right of
the status bar. It invokes VS Code's existing `workbench.action.reloadWindow`
command and requires no extension-specific settings or keybinding.

The manifest and source checked on 24 October 2026 identify version `0.0.7`,
declare VS Code `^1.30.0` and activate at startup. That range includes VS Code
1.143.1; it is not proof of compatibility with every extension combination.
The manifest has no browser entry point, so it is not a standalone web extension.
[Manifest](https://github.com/natqe/reload/blob/master/package.json),
[implementation](https://github.com/natqe/reload/blob/master/src/extension.ts),
[web-extension requirements](https://code.visualstudio.com/api/extension-guides/web-extensions).

Use **Apply Extension to all Profiles** for consistent access across this local
VS Code installation. Per-profile installation keeps the button out of profiles
that do not need it. Neither choice automatically installs it on every remote
host or container. An explicitly scoped CLI alternative is:

```bash
code --profile "Full Stack" --install-extension natqe.reload
```

Save work and finish active agent/debugging tasks before testing the button.
The publisher's tracker includes reports of a disappearing button and remote
placement preventing its use after an SSH disconnection. These are reported
limitations, not reproduced conflicts with the other recommended extensions.
[Issue tracker](https://github.com/natqe/reload/issues),
[remote-session report](https://github.com/natqe/reload/issues/2).

Expected result: clicking **Reload** reopens the current window. If the button
is absent, run **Developer: Reload Window** from the Command Palette. The native
command also works without this extension; no additional reload extension is needed.

## 3. Apply shared User Settings

1. With Default active, run **Preferences: Open User Settings (JSON)**.
2. Merge the [shared settings block](../../../shared/reference/vscode-profile-data.md#shared-settings)
   into the existing root object, preserving unrelated preferences.
3. Apply the [Default overrides](../../../shared/reference/vscode-profile-data.md#default-overrides)
   to that same object and save the file.
4. Inspect Settings for unknown keys and open a new integrated terminal.

Expected result: one valid JSON object supplies Dark Modern, a neutral title-bar
accent, the selected font and the development Zsh terminal. Default's Copilot
inline suggestions are off. Markdown and JSON use Prettier on explicit saves.

Each subsequent profile receives this baseline by copying Default. A shared
recipe is not automatically a live shared setting. To share an individual
preference, open **Preferences: Open Settings (UI)**, find it, open its gear menu
and select **Apply Setting to all Profiles**. Keep values that differ below
in each profile's own User Settings.

### Settings ownership matrix

| Setting or configuration group | Default | Full Stack | AI | Operations | Where it belongs |
|---|---|---|---|---|---|
| Explicit saves, final newline, editor fonts, rulers and navigation preferences | Shared | Shared | Shared | Shared | User Settings; optional all-profiles sharing for identical values |
| Dark Modern and Material Icon Theme | Shared | Shared | Shared | Shared | User Settings |
| Zsh profiles, terminal font, shell integration and Warp executable | Shared | Shared | Shared | Shared | Machine-specific User Settings; verify paths after import |
| Git fetch/sync preferences and Conventional Commit instructions | Shared | Shared | Shared | Shared | User Settings |
| `chat.tools.global.autoApprove` and `chat.tools.terminal.enableAutoApprove` | Off | Off | Off | Off | Shared User Settings; applies to supported VS Code chat flows |
| Markdown/JSON formatting and Markdown extension preferences | Shared | Shared | Shared plus prose suggestions off | Shared | Profile User Settings; preserve nested language values |
| Title-bar and badge colors | Neutral | Purple | Blue | Green | Profile User Settings; do not share across profiles |
| Profile icon | Built-in gear | Code (`code`) | Robot (`robot`) | Server (`server`) | Profiles editor; separate from User Settings and file/folder icons |
| Copilot inline suggestions | Off | On except excluded languages | Off | Off | Profile User Settings; chat availability is separate |
| TS/JS, HTML, CSS/SCSS and Prisma formatting; import actions | No | Enabled | Enabled | No | Full Stack overrides, also combined into AI |
| GitLens inline annotations | No | Off | Off | Off | Profile User Settings where GitLens is selected |
| `.env` associations, formatting and suggestion restrictions | No | Enabled | Enabled | Enabled | Profile User Settings; not an access-control boundary |
| Pipeline-file language mode | Default detection | Azure Pipelines | YAML | Azure Pipelines | Profile User Settings, matching installed language providers |
| SQL and Dockerfile format-on-save | Default behavior | Off | Off | Off | Profile User Settings |
| Codex and Claude preferences, agent instructions and skill discovery | No | Enabled | Enabled with AI overrides | Manual if selected | Profile User Settings; accounts and CLI permissions remain separate |
| Import-cleanup shortcuts | No custom entries | Three chords | Three chords | No custom entries | Profile Keyboard Shortcuts JSON |
| Angular/NestJS folder associations and Angular HTML token palette | No | Manual | No | No | Full Stack User Settings, sections 7 and 8 |
| Skills, MCP servers, credentials and database connections | Separate | Separate | Separate | Separate | Their linked client/tool configuration, not the profile settings recipe |

The [configuration reference](../../../shared/reference/vscode-profile-data.md)
owns the exact keys and values. For manual merges, replace an existing scalar
value, merge nested object properties and replace arrays only when intended.
Do not paste multiple root objects or duplicate keys. In particular, retain
shared Markdown whitespace settings when applying the AI Markdown override.

Markdown All in One's table formatter and automatic table-of-contents updates
are disabled to give Prettier and deliberate edits clear ownership. Repository
Prettier and EditorConfig rules still apply. Use Code Spell Checker's personal
dictionary for spelling exceptions.

The non-login Zsh terminal requires the shared PATH helper in `.zshrc`. Follow
the [Zsh recipe](../shell/zsh.md) and replace `/bin/zsh` in both terminal profiles
only if you chose another executable. `terminal.external.osxExec` opens Warp
as a separate application.

The shared `terminal.integrated.suggest.upArrowNavigatesHistory` setting pairs
with the [Zsh matching-history bindings](../shell/zsh.md#search-matching-commands-with-up-and-down).
Type `brew ` and press Up/Down to check matching history. The VS Code setting
alone does not configure Zsh; Warp retains its own input behavior.

Stage intended changes before selecting **Generate Commit Message** in Source
Control. The shared experimental instructions request a Conventional Commit
subject and a useful body for substantial changes. Review the result. These
instructions apply to Copilot's generator; Codex and Claude use their own
instructions. Keep credentials out of settings and exports.
[AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

## 4. Apply profile settings

1. Open **Manage gear → Profiles → New Profile** after verifying Default.
2. Enter the exact selected name: **Full Stack**, **AI** or **Operations**.
3. Choose **Copy from → Default** and include copies of Settings, Extensions
   and Keyboard Shortcuts, rather than reusing those whole resources from Default.
4. Select **Create**, then **Use this Profile for Current Window**.
5. Open Extensions and install the active profile's **R** entries from the
   [extension matrix](#extension-tables), skipping shared entries already present.
6. Add only the **O** entries needed for your tasks. Keep task-specific extensions
   scoped to this profile instead of selecting the all-profiles action.
7. Open **Preferences: Open User Settings (JSON)** and combine the blocks below
   in order, following the nested-object merge rules in section 3.
8. Repeat these steps for each additional profile you chose.

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

Use the maintained [JSON configuration](../../../shared/reference/vscode-profile-data.md#default-overrides).

Copilot chat remains available; only inline suggestions are off.

### Full Stack overrides

This includes language formatting, manual unused-import removal, GitLens,
agent UI settings, YAML associations, environment-file handling, and generated
file exclusions. Claude Code and Good Prompts are part of the baseline.

Use the maintained [JSON configuration](../../../shared/reference/vscode-profile-data.md#full-stack-overrides).

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

Use the maintained [JSON configuration](../../../shared/reference/vscode-profile-data.md#ai-overrides).

Chat fonts and wrapped code improve readability. Checkpoints and change
summaries assist review; Git remains the record of repository changes. A zero
auto-accept delay disables timed acceptance in supported chat flows.

Codex uses Cmd+Enter, queues follow-ups, and opens reviews separately in AI.
Claude uses Cmd+Enter, Manual starting permissions, explicit file attachment,
and intentional resumption after reload. Save relevant files before a task:
Claude automatic saving is off. Runtime permissions and model/account choices
remain in each client's own configuration.
[Codex settings](https://learn.chatgpt.com/docs/ide/settings),
[Claude settings](https://code.claude.com/docs/en/vs-code).

### Operations overrides

Use the maintained [JSON configuration](../../../shared/reference/vscode-profile-data.md#operations-overrides).

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

## 5. Configure import cleanup and keyboard shortcuts

### Choose one import policy

| Action | Effect | Recommended use |
|---|---|---|
| Sort Imports | Sorts imports without removing unused bindings | On explicit save |
| Remove Unused Imports | Removes unused import bindings | Explicit shortcut after a change is ready |
| Organize Imports | Sorts and removes unused imports | Explicit shortcut for final cleanup |
| ESLint fix | Applies the repository's fixable lint rules | On explicit save |

The language service supplies these actions; no import-cleanup extension is
needed. TypeScript treats side-effect imports differently from unused bindings,
but inspect the diff when code intentionally relies on module initialization.
ESLint may also remove imports if the project config enables such a fixer.
Do not add a second import-sort extension or Prettier plugin unless the project
already standardizes on it. Sort Imports requires TypeScript 4.3+; separate
unused-import removal requires 4.9+. Use the project's supported version.
[Current import-action implementation](https://github.com/microsoft/vscode/blob/main/extensions/typescript-language-features/src/languageFeatures/organizeImports.ts).

For automatic full cleanup, replace the action block in each desired language
with this alternative; do not enable both policies:

```json
{
  "[typescript]": {
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.sortImports": "never",
      "source.removeUnusedImports": "never",
      "source.organizeImports": "explicit"
    }
  }
}
```

This removes temporarily unused imports when you save. Keep the default
manual-removal policy if you frequently scaffold code before using imports.

### Useful built-in macOS shortcuts

| Task | Default shortcut |
|---|---|
| Command Palette | `⇧⌘P` |
| Open file | `⌘P` |
| Workspace search | `⇧⌘F` |
| Source Control | `⌃⇧G` |
| Keyboard Shortcuts editor | `⌘K`, then `⌘S` |
| Quick Fix / code action | `⌘.` |
| Rename symbol | `F2` (or `fn+F2` with media-key mode) |
| Go to definition | `F12` (or `fn+F12`) |
| Format document | `⇧⌥F` |
| Toggle line comment | `⌘/` |
| Toggle terminal | `⌃` plus backtick |
| Go back / forward | `⌃-` / `⌃⇧-` |
| Split editor | `⌘\` |

The split-editor key conflicts with 1Password Universal Autofill on some Day
One setups. Resolve that through the [shared shortcut guide](../apps/keyboard-shortcuts.md)
rather than silently overriding it. Extensions, keyboard layouts, and prior
keymaps can change defaults; inspect **Preferences: Open Keyboard Shortcuts**.

### Personal import shortcuts

1. Switch to Full Stack or AI and open **Preferences: Open Keyboard Shortcuts**.
2. Search each chord below and resolve any existing assignment you want to keep.
3. Run **Preferences: Open Keyboard Shortcuts (JSON)** and merge the entries
   into its existing array, then save.

These are suggested personal chords, not defaults:

```json
[
  {
    "key": "cmd+k cmd+i",
    "command": "editor.action.organizeImports",
    "when": "editorTextFocus && !editorReadonly && (editorLangId == typescript || editorLangId == typescriptreact || editorLangId == javascript)"
  },
  {
    "key": "cmd+k cmd+u",
    "command": "editor.action.sourceAction",
    "args": {
      "kind": "source.removeUnusedImports",
      "apply": "first"
    },
    "when": "editorTextFocus && !editorReadonly && (editorLangId == typescript || editorLangId == typescriptreact || editorLangId == javascript)"
  },
  {
    "key": "cmd+k cmd+shift+i",
    "command": "editor.action.sourceAction",
    "args": {
      "kind": "source.sortImports",
      "apply": "first"
    },
    "when": "editorTextFocus && !editorReadonly && (editorLangId == typescript || editorLangId == typescriptreact || editorLangId == javascript)"
  }
]
```

Expected result: on a disposable TS/JS edit, Sort Imports retains unused imports,
Remove Unused Imports removes unused bindings, and Organize Imports does both.
Inspect the diff before keeping a cleanup change.

Do not copy these import bindings into Operations unless it also edits TS/JS.
Use **Developer: Toggle Keyboard Shortcuts Troubleshooting** if a chord invokes
another action. [Keyboard configuration](https://code.visualstudio.com/docs/configure/keybindings).

## 6. Edit environment files

DotENV belongs in Full Stack, Operations and AI. Its language identifier
is `dotenv`; the profile settings cover `.env`, `.env.local`,
`.env.example`, and `development.env`.
[Language manifest](https://github.com/mikestead/vscode-dotenv/blob/master/package.json).

The [canonical profile settings](#4-apply-profile-settings)
already disable automatic formatting and suggestions for environment files.
Review that baseline in the active profile rather than applying another copy.

1. Open a non-secret `.env.example` file in one of those profiles.
2. Check the language mode in the status bar and the active formatter settings.
3. Save a disposable edit and inspect the result.

Expected result: DotENV supplies highlighting; automatic formatting and inline
suggestions are disabled. Saving does not load variables into an application.

Keep whitespace and quoting under the application's parser rules. Do not
associate dotenv with shellscript solely to get colors: Docker Compose, dotenv,
and shell parsing are not interchangeable. The language block disables inline
suggestions, but does not prevent an agent or extension from reading a file.
Search exclusions and `.gitignore` are also not agent access controls.

A non-secret example file can describe the expected variables:

```dotenv
# Example values only; replace in your local environment.
API_PORT=3000
DATABASE_URL=postgresql://app:example-only@localhost:5432/app_dev
COMPOSE_PROJECT_NAME=app_dev
```

Keep real values in the project's ignored environment file or selected secret
manager. Use [worktree environment guidance](../development/worktrees/environment.md)
for per-worktree ports and databases. Do not share one writable database across
branches with incompatible migrations. The NestJS debugger, Prisma CLI, Docker
Compose, and MCP processes each load variables through their own configuration;
opening `.env` in VS Code does not load it into them.

## 7. Configure Angular and NestJS folder icons

Use Material Icon Theme as the single icon theme. Its current verified folder
inventory contains an Angular icon but no NestJS-branded folder entry. Use an
Angular folder icon for frontend folders and a red server icon for NestJS API
folders; this avoids inventing an unsupported `nestjs` folder-icon identifier.
[Folder inventory](https://github.com/material-extensions/vscode-material-icon-theme/blob/main/src/core/icons/folderIcons.ts).

1. Switch to Full Stack and run **Preferences: Open User Settings (JSON)**.
2. Merge the following properties, substituting your folder names and preserving
   any existing custom-clone entries.
3. Save the settings and inspect those folders in the Explorer.

```json
{
  "workbench.iconTheme": "material-icon-theme",
  "material-icon-theme.folders.theme": "specific",
  "material-icon-theme.folders.associations": {
    "frontend": "angular",
    "web": "angular",
    "angular": "angular"
  },
  "material-icon-theme.folders.customClones": [
    {
      "name": "nestjs-api",
      "base": "server",
      "color": "#E0234E",
      "folderNames": ["api", "backend", "nestjs"],
      "rootFolderNames": ["api", "backend", "nestjs"]
    }
  ]
}
```

Expected result: the selected frontend folders use Angular icons; selected API
folders use red server icons. Unrelated folder names keep their existing icons.

Associations match folder names, not framework detection. Every folder named
`api` in this profile gets that icon. Do not map generic `src` to Angular in a
mixed frontend/backend repository. Merge custom clone arrays rather than
replacing existing clones. Folder association names omit the `folder-` prefix.
For a literal NestJS logo, the extension supports user-owned custom SVG folder
icons with separate closed/open assets; follow its published custom-icon
procedure rather than pointing to an arbitrary repository-relative SVG.
[Icon customization](https://github.com/material-extensions/vscode-material-icon-theme#custom-icon-associations).

## 8. Configure Angular HTML highlighting

`ghaschel.vscode-angular-html` supplies highlighting, not Angular diagnostics
or formatting. Keep `angular.ng-template` and Prettier. Leave Angular templates
in their supported HTML language mode; do not invent an `angular-html` language
association. Use it only in Full Stack to avoid changing unrelated profiles.

1. Open an Angular component template.
2. Run **Preferences: Color Theme** and select **Dark Modern**.
3. In Settings, search `@ext:ghaschel.vscode-angular-html` to inspect the options
   exposed by your installed version.
4. For the publisher's screenshot palette, run **vscode-angular-html: Set
   custom color customizations**. Inspect the changed User Settings afterward.
5. Alternatively, use the smaller native color block below. Merge it with
   existing token rules and avoid enabling both competing palettes.

The publisher explicitly states that its screenshot palette is not supplied
by a theme alone. [Extension listing](https://marketplace.visualstudio.com/items?itemName=ghaschel.vscode-angular-html).

```json
{
  "editor.tokenColorCustomizations": {
    "[Dark Modern]": {
      "textMateRules": [
        {
          "scope": "html-template.tag.custom",
          "settings": { "foreground": "#4EC9B0" }
        },
        {
          "scope": "html-template.ng.attributes.input-binding.first-level",
          "settings": { "foreground": "#9CDCFE" }
        },
        {
          "scope": "html-template.ng.attributes.event-handler",
          "settings": { "foreground": "#DCDCAA" }
        },
        {
          "scope": "html-template.ng.control-flow.keyword",
          "settings": { "foreground": "#C586C0" }
        },
        {
          "scope": [
            "html-template.ng.interpolation.begin",
            "html-template.ng.interpolation.end"
          ],
          "settings": { "foreground": "#CE9178" }
        }
      ]
    }
  }
}
```

These are scopes documented by the extension, not guessed setting names.
Use **Developer: Inspect Editor Tokens and Scopes** on a token if the installed
grammar differs. Semantic coloring or later token rules can override colors.
The publisher's configuration documentation is version-sensitive; preserve
your existing palette before using its generation command.
[Scope reference](https://github.com/ghaschel/vscode-angular-html/blob/HEAD/docs/THEMING.md).

Test with a template supported by your project's Angular version:

```html
@if (customer()) {
  <app-customer-card
    [customer]="customer()"
    (saved)="refreshCustomers()"
  />
  <p>{{ customer()?.name }}</p>
}
```

Expected result: distinct colors identify the custom tag, input, event, control-flow keyword,
and interpolation delimiters. If highlighting regresses, disable only this
extension and confirm Language Service diagnostics still work.

## Finish related development tasks

The editor setup above is complete without these optional integrations. Each
link below is a complete task with its own verification; choose only what you need.

| Task | Owner |
|---|---|
| Native worktree lifecycle and worked UI example | [VS Code worktrees](../development/worktrees/vscode.md) |
| Prompt generation, Copilot, Codex and Claude workflows | [AI workflows](../ai/workflows.md) |
| Project instructions, skill installation and Claude symlinks | [Instructions, agents and skills](../ai/instructions-agents-skills.md) |
| Project/global MCP servers | [MCP setup](../ai/mcp.md) |
| Prefix history, shell startup and Warp compatibility | [Zsh](../shell/zsh.md) |
| DataGrip and VS Code connections to the same databases | [Database clients](../databases/README.md) |

Use one editing agent per worktree. Database credentials belong in each client's
connection storage, not exported settings. DataGrip and VS Code connect to the
same server independently; a SQL-file handoff extension does not share sessions.

## 9. Verify and export

Run the checks for the profiles and optional integrations you selected.

| Check | Expected result |
|---|---|
| Switch through your profiles | Each name, accent and enabled extension set matches its matrix column |
| Open a development terminal and run `node --version`, `git --version` and the project package manager's version command | Each tool resolves to the intended installation |
| Open an Angular template and Prisma schema in Full Stack or AI | Diagnostics and formatter ownership match the selected extensions |
| Save and use import shortcuts on a disposable TS/JS change | Sorting and removal follow the chosen policy; the diff contains only intended edits |
| Inspect icons and HTML token colors in Full Stack | The selected folders and tokens use the configured appearance |
| Open Good Prompts in Full Stack or AI | A generated prompt can be reviewed before sending it to an agent |
| Inspect selected AI clients and their linked skills/MCP configuration | The intended account, project, permissions and tools are available in that client |
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
| Clean custom profile | Create an Empty Profile and apply the [reviewed baseline](#10-optional-custom-profile-tech-content-creator) |

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
| `code: command not found` | Follow [Open VS Code and enable the CLI](#open-vs-code-and-enable-the-cli), then reopen Terminal |
| Old extensions reappear | Turn off Settings Sync, remove the unwanted extensions, verify locally, then reconfigure sync |
| A formatter changes every project | Inspect the active profile's User Settings; scope the formatter by language and remove unintended all-profiles sharing. Keep existing repository formatting rules authoritative |
| Starship symbols are squares | Select JetBrainsMono Nerd Font and reopen the terminal |
| One profile looks different | Confirm the active profile from **Manage → Profiles** |
| Reload is missing from the status bar | Check that the extension is enabled in the active profile and inspect local/remote placement; use **Developer: Reload Window** as the fallback |
| Pipeline files have no language support in AI | Use AI's YAML associations and YAML extension; reserve the dedicated Azure Pipelines mode for a profile with its extension |
| `chezmoi diff` appears stuck | Close the VS Code comparison tabs; `--wait` deliberately keeps the Terminal command active during review |
| A work setting appears on a personal Mac | Sign out of the wrong sync account and review synced categories before reconnecting |

## 10. Optional custom profile: Tech Content Creator

Use a separate writing profile only when articles, tutorials or screenshots
need a different editor layout. This is a manual customisation, not a fifth
`vscode-profile` generator recipe. Work and Personal profiles can use the same
approach with their organisation-approved extensions and account policies.

1. Export the current configuration using the [backup guide](#export-and-back-up-the-configuration).
2. Create **Tech Content Creator** by copying a reviewed Default profile, or
   choose **Empty Profile** when cleaning up unknown state.
3. Review the Default column in the [extension matrix](#extension-tables). Markdown, spelling,
   Prettier and icons cover the writing baseline. Add `usernamehw.errorlens`
   only if inline error messages help your demonstrations.
4. Apply [shared User Settings](#3-apply-shared-user-settings) and
   [Default overrides](#default-overrides), then merge the presentation
   overrides below. Preserve both explicit agent approval settings and the
   shared commit-message instructions when editing the baseline.
5. Test Markdown formatting, terminal launch and a sample document; then
   [export the new profile](#export-a-portable-profile---preferred).

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

[Application guides](../apps/README.md) · [Warp](../terminals/warp.md) · [Vorssaint](../apps/vorssaint.md)
