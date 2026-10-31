# Choose VS Code extensions

Choose only the extensions required by your projects. Complete the [editor setup](../vscode.md) first. Shared settings and profiles have a [separate owner](profiles.md).

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

Use the **Full Stack** column when [creating the development profile](profiles.md#4-apply-profile-settings).

#### AI extensions

Use the **AI** column with the [AI settings recipe](profiles.md#ai-overrides);
copying settings does not require copying Full Stack's extension selection.

#### Operations extensions

Use the **Operations** column with the [Operations settings recipe](profiles.md#operations-overrides).

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

The [Full Stack settings](../../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
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
   [Full Stack settings](../../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
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
   [Full Stack settings](../../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
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
   [Full Stack settings](../../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
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
   entries from the [Full Stack settings](../../../../shared/reference/vscode-profile-data.md#full-stack-overrides).

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
   [Full Stack settings](../../../../shared/reference/vscode-profile-data.md#full-stack-overrides)
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
