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
| [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Format code and JSON | R | R | R | R |
| [EditorConfig](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) | `editorconfig.editorconfig` | Respect repository whitespace rules | R | R | R | R |
| [Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) | `pkief.material-icon-theme` | File and folder icons | R | R | R | R |
| [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) | `yzhang.markdown-all-in-one` | Markdown editing conveniences | R | R | R | R |
| [markdownlint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint) | `davidanson.vscode-markdownlint` | Format and check Markdown | R | R | R | R |
| [Angular Language Service](https://marketplace.visualstudio.com/items?itemName=angular.ng-template) | `angular.ng-template` | Angular template diagnostics and navigation | No | R | R | No |
| [Rename Angular Component](https://marketplace.visualstudio.com/items?itemName=tomwhite007.rename-angular-component) | `tomwhite007.rename-angular-component` | Rename related Angular files, classes, selectors and references | No | R | R | No |
| [Angular HTML](https://marketplace.visualstudio.com/items?itemName=ghaschel.vscode-angular-html) | `ghaschel.vscode-angular-html` | Your chosen template highlighting | No | R | No | No |
| [Nx Console](https://marketplace.visualstudio.com/items?itemName=nrwl.angular-console) | `nrwl.angular-console` | Generators, targets, and workspace information | No | R | R | No |
| [NPM Visual Manager](https://marketplace.visualstudio.com/items?itemName=LuisClementDev.npm-visual-manager) | `luisclementdev.npm-visual-manager` | Dependency dashboard, selected package updates and AI update prompts | No | R | O | No |
| [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) | `dbaeumer.vscode-eslint` | Repository lint diagnostics and fixes | No | R | R | No |
| [Prisma](https://marketplace.visualstudio.com/items?itemName=prisma.prisma) | `prisma.prisma` | Prisma schema editing and formatting | No | R | R | No |
| [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) | `eamodio.gitlens` | History, blame, and comparisons | No | R | R | R |
| [File Utils](https://marketplace.visualstudio.com/items?itemName=sleistner.vscode-fileutils) | `sleistner.vscode-fileutils` | Duplicate files, enter destination paths and copy file names | No | R | O | No |
| [Auto Barrel for VSCode](https://marketplace.visualstudio.com/items?itemName=imgildev.vscode-auto-barrel) | `imgildev.vscode-auto-barrel` | Generate and update TypeScript barrel exports in selected directories | No | R | R | No |
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
| [Tailwind CSS IntelliSense](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) | `bradlc.vscode-tailwindcss` | Tailwind classes, directives and `@apply` diagnostics | No | R | R | No |
| [CSS Peek](https://marketplace.visualstudio.com/items?itemName=pranaygp.vscode-css-peek) | `pranaygp.vscode-css-peek` | Navigate from template classes and IDs to existing CSS, SCSS and Less selectors | No | R | O | No |
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

Code Spell Checker is not part of these profiles. For an existing installation,
switch to each profile, search Extensions for `streetsidesoftware.code-spell-checker`
and select **Uninstall** where present. Check all four profiles afterward;
removing an identifier from a generated recipe does not uninstall it locally.
Keep personal dictionaries if you may use them elsewhere.

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

### File Utils: Full Stack file commands

**File Utils** (`sleistner.vscode-fileutils`, publisher Steffen Leistner) belongs
in Full Stack and is optional in AI. Install it in the selected profile without
using **Apply Extension to all Profiles**. For Full Stack, the CLI command is:

```bash
code --profile "Full Stack" --install-extension sleistner.vscode-fileutils
```

The [Full Stack settings](../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
show absolute destination paths and keep **Move**, **Duplicate** and **Copy Name**
in Explorer and tab menus. The editor text menu has no File Utils additions;
other extension commands remain in the Command Palette. AI recipes inherit
these preferences, which take effect only when File Utils is installed there.

To verify after applying the profile settings:

1. Open a disposable file in Full Stack and right-click its tab.

   Expected result: **Move**, **Duplicate** and **Copy Name** appear, with no
   File Utils rename or delete additions.

2. Run **File Utils: Duplicate...** and enter a new destination filename.

   Expected result: the original remains and a separate copy exists at the
   chosen path. Inspect the destination before confirming.

Release `3.10.3`, dated 22 July 2023, declares VS Code `^1.74.0`, which includes
1.143.1. Use native Explorer if the extension's picker omits hidden directories
such as `.agents` or `.github`. The tracker also contains an open report about
rename undo settings. These reports are limitations to check on your machine.
[Released manifest](https://github.com/sleistner/vscode-fileutils/blob/v3.10.3/package.json),
[hidden-directory report](https://github.com/sleistner/vscode-fileutils/issues/684),
[undo report](https://github.com/sleistner/vscode-fileutils/issues/686).

### NPM Visual Manager: Full Stack, optional in AI

Use **NPM Visual Manager** for dependency inspection in Full Stack. Select it in
AI when you use an assistant to plan package updates. Keep Nx Console for its
generators and tasks, and native **NPM Scripts** for running project scripts.

1. Switch to the existing Full Stack profile and install the extension:

   ```bash
   code --profile "Full Stack" --install-extension luisclementdev.npm-visual-manager
   ```

   Expected result: the extension appears in Full Stack. Leave **Apply Extension
   to all Profiles** off. If selected for AI, repeat with `--profile "AI"`.

2. Merge the `npm-visual-manager.*` entries from the
   [Full Stack settings](../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
   into profile User Settings. AI inherits these preferences in its recipe;
   they take effect only if the optional extension is installed.

   Expected result: dependency types, update types and security columns are
   visible. Background badge checks are off, and updates do not force exact
   version pins. The hidden size column measures installed package size, not
   the application's production bundle size. The scan depth remains five levels.

3. Open the intended repository or worktree, then run **Open NPM Package Manager**
   from the Command Palette. Confirm the selected `package.json` and manager.

   Expected result: the dashboard describes the intended project. For private
   feeds, verify a known package using existing npm authentication. Metadata
   queries read npm-compatible configuration; native Yarn `.yarnrc.yml` registry
   settings are not imported. Azure Artifacts acceptance needs a live feed check.

4. Select **AI prompt** when you want an assistant to review the visible updates.

   Expected result: a Markdown plan is copied locally. Review package names,
   project paths and commands before pasting into your approved client. Copying
   the prompt does not send it to a provider or install packages.

The Ignore Package button writes Workspace Settings, commonly
`.vscode/settings.json`. To keep personal preferences outside the repository,
avoid that button or manage `npm-visual-manager.ignoredPackages` in User Settings.
A User list affects every project using that profile. It hides updates; it does
not enforce a dependency version policy.

Review updates from a clean Git state and run the project's checks afterward.
Use [Nx migrations](https://nx.dev/docs/features/automate-updating-dependencies)
for applicable Nx upgrades and [Angular updates](https://angular.dev/cli/update)
for standalone Angular applications. Generic package installation does not run
their framework migrations. Rollback reinstalls previous package versions; keep
Git recovery for lockfiles, generated files and source migrations. Disabling
the badge skips its workspace-wide checks, while the open dashboard can still
perform registry requests and audits.

Published version 2.1.0 was checked on 27 October 2026 and declares VS Code
`^1.86.0`. The publisher is Luis Clement Cremades (`LuisClementDev`). See the
[manifest](https://github.com/luisssc/npm-visual-manager/blob/35430cacff2794936f7a350a46634331ddc99bdf/package.json),
[release notes](https://github.com/luisssc/npm-visual-manager/blob/35430cacff2794936f7a350a46634331ddc99bdf/CHANGELOG.md)
and [workspace-ignore implementation](https://github.com/luisssc/npm-visual-manager/blob/35430cacff2794936f7a350a46634331ddc99bdf/src/services/ignoreService.ts).

### Rename Angular Component: Full Stack and AI

Use **Rename Angular Component** (`tomwhite007.rename-angular-component`) for
related Angular files, classes and selectors in local macOS workspaces. Keep
Angular Language Service and native **Rename Symbol** (`F2`) for individual
symbols. Use only one Angular renamer in a profile.

1. Install the extension in the existing development profiles:

   ```bash
   code --profile "Full Stack" --install-extension tomwhite007.rename-angular-component
   code --profile "AI" --install-extension tomwhite007.rename-angular-component
   ```

   Expected result: the extension appears in Full Stack and AI. Leave
   **Apply Extension to all Profiles** off.

2. Merge the `renameAngularComponent.*` entries from the
   [Full Stack settings](../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
   into each profile's User Settings. AI inherits them in its recipe.

   Expected result: update popups and debug logging are off. The renamer does
   not force direct local paths over aliases or include dotted suffixes in
   generated folder names and selectors. Review alias changes after each rename.

3. Check `renameAngularComponent.projectUsesStandaloneComponentsOnly` in
   Settings before renaming in each project.

   Expected result: `true` for entirely standalone applications, or `false`
   for NgModule or mixed applications. The extension defaults to `true`;
   the profile recipe leaves this project-dependent choice unset. With `false`,
   selector replacement searches all templates and can affect duplicate selectors.
   If using User Settings, revisit this choice when switching projects.

4. On a disposable component in a development branch, right-click its `.ts`
   file and select **Rename Angular file**, then enter the new base name.

   Expected result: related files, class names, selectors and references match
   the new name. Both `button.component.ts` and suffixless `button.ts` naming
   are supported. Inspect the Git diff, including barrel exports, aliases and
   lazy imports, then run the affected project's build and tests.

The published 4.3.0 manifest was checked on 25 October 2026 and requires VS Code
1.99 or later. The publisher lists WSL and Dev Containers as unsupported;
perform renames in a local workspace. Running an application's services in Docker
does not require opening the editor inside a Dev Container.
[Published manifest](https://tomwhite007.gallery.vsassets.io/_apis/public/gallery/publisher/tomwhite007/extension/rename-angular-component/4.3.0/assetbyname/Microsoft.VisualStudio.Code.Manifest),
[publisher documentation](https://marketplace.visualstudio.com/items?itemName=tomwhite007.rename-angular-component),
[Dev Container limitation](https://github.com/tomwhite007/rename-angular-component/issues/52).

### Auto Barrel: Full Stack and AI

A barrel is an `index.ts` file that re-exports modules from a directory. Use
**Auto Barrel for VSCode** (`imgildev.vscode-auto-barrel`, publisher Manuel Gil)
for selected library entry points in Full Stack and AI.

1. Install the extension in the existing profiles:

   ```bash
   code --profile "Full Stack" --install-extension imgildev.vscode-auto-barrel
   code --profile "AI" --install-extension imgildev.vscode-auto-barrel
   ```

   Expected result: Auto Barrel appears in both profiles. Leave **Apply
   Extension to all Profiles** off; Default and Operations do not need it.

2. Merge the `autoBarrel.*` entries from the
   [Full Stack settings](../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
   into each profile's User Settings. AI inherits these entries in its recipe.

   Expected result: generation searches the selected directory and up to three
   levels of subdirectories. It excludes hidden files, respects `.gitignore`,
   detects named exports and sorts them alphabetically using single quotes. Keep the
   extension's default test-file exclusions; merge additional patterns with
   those defaults if needed.

3. In a disposable directory containing exported TypeScript modules,
   right-click the directory and select **Auto Barrel → Create a barrel file**.

   Expected result: an `index.ts` file contains exports for the selected
   directory. Inspect the diff, run the project's type check, and remove the
   disposable files after verification. To update one generated entry point,
   right-click its `index.ts` file and select **Auto Barrel → Update the barrel
   file**. Review the change before replacing curated exports.

With both `autoBarrel.files.detectExportsInFiles` and
`autoBarrel.files.useNamedExports` enabled, the generator uses names exported
by the source file. For example, a file exporting `class Button` produces
`export { Button } from './button/button';`. Names preserve their original
casing, and paths are relative to the generated barrel. Type-only declarations
use `export type`; default exports use `export { default as name }`.

The folder menu also labels its broader update command **Update the barrel
file**; select the file when you intend to update only one barrel. Use one barrel extension
to prevent competing generators. For NestJS, avoid barrels for module and
provider classes, especially imports within the barrel's own directory.

If **No files found matching the specified patterns** appears, check whether
the selected directory contains only an existing `index.ts` and subdirectories.
The extension excludes existing barrel files by default. Nested source files
require `autoBarrel.files.disableRecursiveBarrelling: false`; increase
`autoBarrel.files.maxSearchRecursionDepth` only when the intended files are
deeper than three levels. Check workspace overrides, included extensions and
exclusion patterns if the warning remains. Keep barrel-file exclusions to
avoid exporting the generated file from itself.

The installed extension's settings and menu labels were checked against
version 1.23.1 on 25 October 2026. See
[Auto Barrel documentation](https://github.com/ManuelGil/vscode-auto-barrel)
and [NestJS circular-dependency guidance](https://docs.nestjs.com/fundamentals/circular-dependency).

### CSS Peek: Full Stack, optional in AI

Use **CSS Peek**, published by Pranay Prakash (`pranaygp`), to inspect authored
styles from template class names and IDs. Install it in Full Stack; select it
for AI when reviewing frontend changes. Default and Operations do not need it.

1. Select the existing Full Stack profile and install the extension:

   ```bash
   code --profile "Full Stack" --install-extension pranaygp.vscode-css-peek
   ```

   Expected result: CSS Peek appears in Full Stack. Leave **Apply Extension to
   all Profiles** off. If selected for AI, repeat with `--profile "AI"`.

2. Open **Preferences: Open User Settings (JSON)** and merge the `cssPeek.*`
   entries from the [Full Stack settings](../../../shared/reference/vscode-profile-data.md#full-stack-overrides).

   Expected result: tag lookup and extension telemetry are disabled. Root
   `.gitignore` filtering remains enabled, and lookup includes stylesheets
   beyond those directly linked from the template. AI inherits these recipe
   values; they take effect only when CSS Peek is installed.

3. In a disposable local folder, save `index.html` containing
   `<section class="peek-demo">Example</section>` and `styles.scss` containing
   `.peek-demo { color: red; }`.

   Expected result: both files appear in the same opened VS Code folder.

4. Place the cursor inside `peek-demo` in the HTML file and run **Peek Definition**.

   Expected result: the `.peek-demo` rule appears from `styles.scss`. If it
   does not, check CSS Peek is enabled in the active profile and the stylesheet
   is not ignored. Inspect **Output → CSS Peek** for diagnostics.

Keep `cssPeek.supportTags` disabled for Angular, as the publisher recommends.
Keep `cssPeek.peekToLinkedOnly` disabled because an Angular external template
does not normally link its component stylesheet directly. Repeated selectors
can return several candidates; a match does not establish Angular component scope.

CSS Peek finds existing selectors, so retain Tailwind CSS IntelliSense for
generated utilities and `@apply` support. Keep Angular Language Service for
framework diagnostics and navigation, and Prettier for formatting. Preserve
the existing HTML and Tailwind CSS language associations.

CSS Peek 4.5.1's installed manifest and publisher documentation, checked on
27 October 2026, list these settings and require VS Code 1.91 or newer.
Root `.gitignore` filtering does not
handle nested ignore files or negated patterns. See the
[Marketplace listing](https://marketplace.visualstudio.com/items?itemName=pranaygp.vscode-css-peek)
and [publisher settings reference](https://github.com/pranaygp/vscode-css-peek#configuration).

To undo this addition, uninstall CSS Peek in the selected profile and remove
only its `cssPeek.*` settings, restoring any values you previously used.

### Tailwind CSS: Full Stack and AI

Install **Tailwind CSS IntelliSense** (`bradlc.vscode-tailwindcss`) in both
development profiles. Its settings belong in each profile's User Settings.
Default and Operations do not need the extension or Tailwind settings.

1. Install the extension in the existing profiles:

   ```bash
   code --profile "Full Stack" --install-extension bradlc.vscode-tailwindcss
   code --profile "AI" --install-extension bradlc.vscode-tailwindcss
   ```

   Expected result: Extensions shows Tailwind CSS IntelliSense in both profiles.
   Leave **Apply Extension to all Profiles** off for this extension.

2. Merge the Tailwind entries from the
   [Full Stack settings](../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
   into each profile. The AI recipe inherits those settings.

   Expected result: `.css` files use **Tailwind CSS** language mode; `.scss`
   files remain **SCSS**. The `*.css` association applies to every CSS file
   opened in these profiles, including projects without Tailwind.

   The `[tailwindcss]` formatter override and `prettier.documentSelectors`
   entry for `**/*.css` keep Prettier available in the new language mode.
   HTML string suggestions support class completion in Angular templates.
   Existing `.env` suggestion restrictions remain unchanged.

3. Open a trusted project that already has Tailwind installed and configured.

   Expected result: the extension detects a CSS entrypoint importing Tailwind
   for v4, or a `tailwind.config.*` file for v3. The extension does not install
   Tailwind or configure the application's build.

4. In a disposable edit to a stylesheet processed by Tailwind, type `@apply `
   inside a rule and request suggestions with `Ctrl+Space`.

   Expected result: Tailwind utilities appear. Save a valid rule and verify
   that Prettier formats it. Hover a utility to inspect its CSS, then discard
   the disposable edit. If completion is absent, inspect **Tailwind CSS: Show
   Output** in the Command Palette after the language server activates.

Tailwind validation stays enabled, with invalid `@apply` usage reported as an
error. For existing SCSS pipelines, `scss.lint.unknownAtRules: "ignore"`
suppresses VS Code's unknown-at-rule warnings while keeping other SCSS checks.
This also hides misspelled at-rules. Remove that setting to restore those
warnings; Stylelint diagnostics and build errors are controlled separately.

Tailwind v4 is not designed for Sass/SCSS preprocessors. Use plain CSS for its
Tailwind styles, and use `@reference` when separately processed stylesheets
need access to the main stylesheet's theme and utilities. Editor settings
cannot repair an incompatible build pipeline. Check the project's Tailwind
version before changing its stylesheets.

The publisher guidance checked on 25 October 2026 describes these activation
requirements and language-mode settings. See the
[extension documentation](https://github.com/tailwindlabs/tailwindcss-intellisense),
[Prettier document selectors](https://github.com/prettier/prettier-vscode#prettierdocumentselectors),
[Tailwind compatibility](https://tailwindcss.com/docs/compatibility#sass-less-and-stylus)
and [reference directive](https://tailwindcss.com/docs/functions-and-directives#reference-directive).

## 3. Apply shared User Settings

Prepare the [personal Markdown rules](#markdown-formatting) before applying
the shared settings or importing a generated profile.

1. With Default active, run **Preferences: Open User Settings (JSON)**.
2. Merge the [shared settings block](../../../shared/reference/vscode-profile-data.md#shared-settings)
   into the existing root object, preserving unrelated preferences.
3. Apply the [Default overrides](../../../shared/reference/vscode-profile-data.md#default-overrides)
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
| Auto Barrel generation scope, export detection and formatting | No | Configured | Inherited | No | Profile User Settings; see [Auto Barrel](#auto-barrel-full-stack-and-ai) |
| Tailwind CSS mode, Prettier registration, HTML class suggestions and SCSS at-rule warning policy | No | Enabled | Inherited | No | Profile User Settings; see [Tailwind CSS](#tailwind-css-full-stack-and-ai) |
| `.env` associations, formatting and suggestion restrictions | No | Enabled | Enabled | Enabled | Profile User Settings; not an access-control boundary |
| Pipeline-file language mode | Default detection | Azure Pipelines | YAML | Azure Pipelines | Profile User Settings, matching installed language providers |
| SQL and Dockerfile format-on-save | Default behavior | Off | Off | Off | Profile User Settings |
| Codex and Claude preferences, agent instructions and skill discovery | No | Enabled | Enabled with AI overrides | Manual if selected | Profile User Settings; accounts and CLI permissions remain separate |
| Codex Cmd+Enter, queued follow-ups and inline reviews | No | Enabled | Inherited | Manual if selected | Profile User Settings; chat sharing has no separate sync setting |
| Import-cleanup shortcuts | No custom entries | Three chords | Three chords | No custom entries | Profile Keyboard Shortcuts JSON |
| New file tab shortcut | `Cmd+T` | `Cmd+T` | `Cmd+T` | `Cmd+T` | Shared Keyboard Shortcuts entries; native `Cmd+N` remains available |
| Angular/NestJS folder associations and Angular HTML token palette | No | Manual | No | No | Full Stack User Settings, sections 7 and 8 |
| Skills, MCP servers, credentials and database connections | Separate | Separate | Separate | Separate | Their linked client/tool configuration, not the profile settings recipe |

The [configuration reference](../../../shared/reference/vscode-profile-data.md)
owns the exact keys and values. For manual merges, replace an existing scalar
value, merge nested object properties and replace arrays only when intended.
Do not paste multiple root objects or duplicate keys. In particular, retain
shared Markdown whitespace settings when applying the AI Markdown override.

To browse MCP servers, open Extensions and search `@mcp`, or run **MCP: Browse
MCP Servers** from the Command Palette. Enabling the gallery does not install
servers or change approvals. Follow the [MCP setup guide](../ai/mcp.md) to
configure a selected server; organization policies can restrict availability.

The non-login Zsh terminal requires the shared PATH helper in `.zshrc`. Follow
the [Zsh recipe](../shell/zsh.md) and replace `/bin/zsh` in both terminal profiles
only if you chose another executable. `terminal.external.osxExec` opens Warp
as a separate application.

The shared `terminal.integrated.suggest.upArrowNavigatesHistory` setting pairs
with the [Zsh matching-history bindings](../shell/zsh.md#search-matching-commands-with-up-and-down).
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
worktree. Follow the [worktree guide](../development/worktrees/vscode.md#configure-worktree-detection)
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
names. Preview tabs are disabled, so opening another file keeps the previous
file open. New tabs appear to the right of the active tab; an editor-count
limit does not close older files to make room.

1. Activate each selected profile and run **Preferences: Open User Settings (JSON)**.

   Expected result: the settings file belongs to the intended profile. Back up
   its existing contents before editing.

2. Merge the `workbench.editor.*` entries from the
   [shared settings block](../../../shared/reference/vscode-profile-data.md#shared-settings)
   into its root object and save, preserving unrelated preferences.

   Expected result: the shared tab preferences are present without duplicate
   keys. These are User Settings; no project configuration file is needed.

3. Press `Cmd+N` twice, then use `Cmd+P` and `Enter` to open a project file.

   Expected result: both blank tabs remain open beside the file tab. Open
   enough files to fill the tab bar and confirm that further tabs wrap to
   another row. Edit a disposable blank tab to check its modified highlight,
   then close the test tabs and discard the disposable edit.

`Cmd+N` creates a blank file even when no empty space remains beside the tabs.
With space available, double-click the empty editor title area to create one.
The [shared new-tab shortcut](#new-file-tab-shortcut) also assigns `Cmd+T` to
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

3. Copy the [personal Markdown rules](../../../shared/reference/vscode-profile-data.md#personal-markdown-rules)
   into that file and save. For an existing configuration, merge the `MD013`
   and `MD060` properties while preserving unrelated rules.

   Expected result: a valid JSON file selects compact tables and a 100-character
   prose limit, with tables and code blocks exempt. The configuration reference
   owns its exact values.

4. Apply the [shared settings](../../../shared/reference/vscode-profile-data.md#shared-settings)
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

### Generate Conventional Commit messages with GitLens

The shared `gitlens.ai.generateCommitMessage.customInstructions` setting asks
GitLens to use `type(scope): description`, with an optional scope and an
evidence-based body for substantial changes. Its full value lives in the
[shared settings JSON](../../../shared/reference/vscode-profile-data.md#shared-settings).
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
   [extension matrix](#extension-tables), skipping shared entries already present.
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

Codex uses Cmd+Enter, queues follow-ups, and keeps reviews in the current chat
when supported in both Full Stack and AI. Its sidebar does not take focus on
startup, and TODO CodeLens actions are off. These are interface preferences;
follow [continuing a Codex chat between VS Code and desktop](../ai/workflows.md#continue-a-codex-chat-between-vs-code-and-desktop)
to use the same conversation in both applications.

Claude uses Cmd+Enter, Manual starting permissions, explicit file attachment,
and intentional resumption after reload. Save relevant files before a task:
Claude automatic saving is off. Runtime permissions and model/account choices
remain in each client's own configuration.
[Codex settings](https://learn.chatgpt.com/docs/developer-settings),
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
| New blank file tab | `⌘N` |
| Reopen a closed editor | `⇧⌘T` |
| Switch recent editors | `⌃Tab` |
| Close the active editor | `⌘W` |
| Search workspace symbols | `⌘P`, then type `#` and the symbol name |
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

### New file tab shortcut

The shared shortcut assigns `Cmd+T` to a new blank file tab in Default,
Full Stack, AI and Operations. Native `Cmd+N` remains available. This replaces
the default `Cmd+T` workspace symbol search; use `Cmd+P`, then type `#` and a
symbol name for that search. Symbol results require a language provider for
the project. See [workspace symbol navigation](https://code.visualstudio.com/docs/editing/editingevolved#open-symbol-by-name).

1. Activate a selected profile and open **Preferences: Open Keyboard Shortcuts**.

   Expected result: searching `cmd+t` shows its current assignments. Inspect
   any existing custom assignment before replacing it.

2. Open **Preferences: Open Keyboard Shortcuts (JSON)** and back up its contents.
   Merge the [shared keybindings](../../../shared/reference/vscode-profile-data.md#shared-keybindings)
   into the existing array, then save. Repeat for each selected profile.

   Expected result: each profile has one custom `cmd+t` entry for
   `workbench.action.files.newUntitledFile`. Full Stack and AI retain their
   import-cleanup chords. Generated profile exports include both groups.

3. Press `Cmd+T`, then `Cmd+N`, and close the two blank tabs with `Cmd+W`.

   Expected result: both shortcuts create a new file tab. Confirm that `Cmd+P`
   followed by `#` opens workspace symbol search in a supported project.

To restore the default symbol-search shortcut, remove only the custom `cmd+t`
entry or restore its previous assignment from the backup. If another command
runs, use **Developer: Toggle Keyboard Shortcuts Troubleshooting** and inspect
which binding wins. [Keyboard configuration](https://code.visualstudio.com/docs/configure/keybindings).

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
| Open Explorer in each profile | Open Editors is visible and expanded; opening a file adds it to the list |
| Save a disposable Markdown file in each profile | [Markdown formatting](#markdown-formatting) uses the shared style unless project rules override it |
| Open a development terminal and run `node --version`, `git --version` and the project package manager's version command | Each tool resolves to the intended installation |
| Open an Angular template and Prisma schema in Full Stack or AI | Diagnostics and formatter ownership match the selected extensions |
| Open a configured Tailwind project in Full Stack or AI | CSS uses Tailwind CSS mode, SCSS keeps its mode, class completion works and Prettier formats CSS on save |
| Peek a class definition in the disposable CSS Peek example in Full Stack, or AI if selected | The matching authored stylesheet rule appears; Tailwind and Angular tooling remain enabled |
| Generate a barrel in a disposable TypeScript directory in Full Stack or AI | Exports match the selected files, respect exclusions and pass the project's type check |
| Rename a disposable Angular component in Full Stack or AI | Related files and references match the new name; reviewed changes pass the project's build and tests |
| Search Extensions for `streetsidesoftware.code-spell-checker` in all four profiles | Code Spell Checker is not installed in these profiles |
| Save and use import shortcuts on a disposable TS/JS change | Sorting and removal follow the chosen policy; the diff contains only intended edits |
| Generate a GitLens message for reviewed staged changes | The message follows Conventional Commits and describes only the staged scope; generation alone does not commit |
| Inspect icons and HTML token colors in Full Stack | The selected folders and tokens use the configured appearance |
| Open Good Prompts in Full Stack or AI | A generated prompt can be reviewed before sending it to an agent |
| Open NPM Visual Manager in Full Stack, or AI if selected | Intended package file and manager appear; an AI prompt copies without applying updates |
| Inspect selected AI clients and their linked skills/MCP configuration | The intended account, project, permissions and tools are available in that client |
| Follow the [Codex continuity check](../ai/workflows.md#continue-a-codex-chat-between-vs-code-and-desktop) when using the desktop app | The existing conversation and a harmless follow-up are visible in both applications |
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
Back up the external rule file described under [Markdown formatting](#markdown-formatting)
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
| Markdown does not format on save, or tables gain padding | Confirm Markdown language mode, markdownlint formatter ownership and the private rule file; inspect **View → Output → markdownlint** and project overrides. Check that another formatter or save action is not formatting tables |
| Creating or finding file tabs is awkward | Use `Cmd+N` for a blank file or `Cmd+P` for an existing one. Check the active profile's [tab settings](#editor-tabs) and workspace overrides; wrapped rows keep overflowing tabs visible |
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
3. Review the Default column in the [extension matrix](#extension-tables). Markdown,
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
