[← Application guides](README.md) · [Detailed stack recipes](VSCODE-TYPESCRIPT.md) · [Backup, reset and sync](VSCODE.md#export-and-back-up-the-configuration)

# Choose and configure VS Code profiles

**Document type:** how-to guide and extension reference. **Audience:** experienced
macOS developers using Angular, NestJS, Nx, Prisma, Azure DevOps, Docker,
PostgreSQL, Copilot, Codex, and Claude Code. **Updated:** 15 October 2026.

This is the authoritative profile selection, extension and settings recipe.
Start with [base VS Code setup](VSCODE.md), then choose only the profiles your
work needs here. Use the [advanced reference](VSCODE-TYPESCRIPT.md) for icons,
Angular HTML, worktrees, skills, MCP and Zsh. Backup, selective reset and
Settings Sync are maintained in [VS Code setup and maintenance](VSCODE.md).

Profiles are optional. Keeping Default alone is valid. Work/Personal describe
account or organisational contexts; Full Stack/AI/Operations describe tasks.
They are alternative ways to organise your editor, not two sets to install.
A profile organises editor settings and extensions; it is not an account or
security boundary. Follow employer policy for sign-in, Sync, extension trust
and credential separation. Do not rely on a profile name to enforce access.

The old [Module 12 generator is retired](../02-optional/12-vscode-profiles.md).
The manual and script-assisted routes below now share this one recipe.

Recipe source check: **VS Code 1.142.0**, 15 October 2026. Check your own
approved version through **Code → Check for Updates**; this is not a live
inventory of your Mac.
New agent defaults roll out progressively and employer policies can override
availability. [Release notes](https://code.visualstudio.com/updates/v1_142).

All editor settings below belong to **User Settings for the active profile**.
No `.vscode/settings.json`, extension recommendation file, credential file, or
live configuration is created by following the documentation alone.
Repository formatter/linter rules and managed settings can still override
personal preferences. Keep required project configuration intact.

## Contents

1. [Choose and create profiles](#1-choose-and-create-profiles)
2. [Install the final extension lists](#2-install-the-final-extension-lists)
3. [Apply shared User Settings](#3-apply-shared-user-settings)
4. [Apply profile settings](#4-apply-profile-settings)
5. [Finish prompts, skills, agents, and MCP](#5-finish-prompts-skills-agents-and-mcp)
6. [Configure DataGrip and PostgreSQL connections](#6-configure-datagrip-and-postgresql-connections)
7. [Finish shortcuts, icons, worktrees, and Zsh](#7-finish-shortcuts-icons-worktrees-and-zsh)
8. [Verify and export](#8-verify-and-export)
9. [Optional custom profile: Tech Content Creator](#9-optional-custom-profile-tech-content-creator)

## 1. Choose and create profiles

| Profile | Purpose | Appearance | Normal database use |
|---|---|---|---|
| Default | Configuration, notes, general editing | Dark Modern; neutral | None |
| Full Stack | Daily Angular/Nest/Nx development | Dark Modern; blue | Local/dev/test |
| AI | Prompt authoring, reviews, debugging, agents and skills | Dark Modern; purple | Optional local/dev/test tools |
| Operations | Containers, pipelines, databases, remote work | Dark Modern; green | Production read-only investigation |

Choose Default plus whichever task profiles are useful. The extension and
settings sections define the same baseline for both routes. Start with the
manual route if you do not use Day One Mac scripts; use the generator route
if you want files prepared for review. Do not perform both setup procedures.

### Manual route — create the selected profiles

1. [Export your current profiles](VSCODE.md#export-a-portable-profile--preferred) before changing them.
2. Configure Default with the shared extensions/settings below.
3. Create Full Stack and/or Operations by copying Default, if selected.
4. If AI is selected, use the Full Stack settings as its foundation, then apply AI overrides. Copy a configured Full Stack profile when available; you do not need to keep a separate Full Stack profile solely for this step.
5. In AI, disable Full Stack-only extensions unless needed for the current task.
6. Associate each repository with its chosen profile. Use Full Stack for
   development if selected; choose AI or Operations deliberately for focused
   work, preferably in a separate window/worktree.

Copying profiles is a snapshot, not automatic inheritance. Apply common
preferences to all profiles deliberately; keep accents and Copilot completion
choices profile-specific. Profiles are not sandboxes and do not isolate agent
credentials, CLI configuration, or database permissions.
[Profiles](https://code.visualstudio.com/docs/configure/profiles).

### Generate profile files with the scripts

**Script-assisted route:** prepare files from the same recipes below, then
review and import them. This replaces the manual creation procedure above.

Use the installed `day-one-mac vscode-profile` command from any directory; no
source checkout is needed. **Availability:** these recipes originated in source
commit `4fbd145`; the public command belongs to the subsequent documentation-audit
remediation. They are candidate features until a release containing them is
published. Check `day-one-mac --version` and `day-one-mac vscode-profile --help`;
an older runtime such as `1.5.0-local.20261015-audit.29cc299` does not include them.
Use an approved newer runtime rather than copying individual scripts into it.

The generators require **Node.js 22 or newer** and read this bundled guide's
extension tables and settings recipes. They create personal review files, not
repository `.vscode` files or active editor settings. Preview and bundle export
are available before Phase 8; explicit extension installation requires current
Phase 8. Import/merge remains a reviewed manual action after the required setup.

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
Full Stack's language settings in AI. It bundles the settings in sections 3–4
and the detailed guide's import keybindings. Folder-name icon associations,
the optional Angular token palette, shell configuration, skills/agent files,
MCP servers, and database connections still require the linked manual recipes.
Credentials and account sign-in are not included.

#### Import settings and extensions together

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
No script edits VS Code's internal profile storage. VS Code documents profile
imports through the editor; see [Profiles](https://code.visualstudio.com/docs/configure/profiles).

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

**Contributor check:** from a source checkout, validate the generators without
touching live VS Code configuration. This check is not an installed-runtime command:

```bash
node scripts/tests/test-vscode-profiles.cjs
```

## 2. Install the final extension lists

### Copilot: already provided through your VS Code setup

Do not add `github.copilot` or `github.copilot-chat` to your manual installation
checklist. Their Marketplace identifiers still exist, but your setup already
provides the VS Code-managed Copilot components. Use the status-bar **Use AI
Features** flow and your intended account. Access depends on account and policy.
[Copilot setup](https://code.visualstudio.com/docs/setup/copilot).

| Capability | Default | Full Stack | AI | Operations |
|---|---|---|---|---|
| Inline suggestions | Off | On, excluding environment files and prose | Off initially | Off initially |
| Chat and agents | Available on demand | Enabled | Enabled | Use deliberately |

TypeScript services, Node debugging, Git/worktrees, prompt/skill support, and
Dark Modern are native editor capabilities. They are not additional extensions
to install. Skills and MCP servers are separate configuration, described later.

### Extension tables

Each profile table lists its full shared set again. **Recommended** means part
of that profile's baseline. **Optional** means install only for an actual task.
Linked names point to Marketplace listings; these are not commands to install
every optional item. Let parent extensions manage required companions.

#### Default extensions

| Extension | Identifier | Status and purpose |
|---|---|---|
| [Prettier – Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Recommended: Format supported languages |
| [EditorConfig](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) | `editorconfig.editorconfig` | Recommended: Respect repository whitespace rules |
| [Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) | `pkief.material-icon-theme` | Recommended: File and folder icons |
| [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) | `yzhang.markdown-all-in-one` | Recommended: Markdown editing conveniences |
| [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) | `streetsidesoftware.code-spell-checker` | Recommended: Spelling diagnostics |
| [markdownlint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint) | `davidanson.vscode-markdownlint` | Recommended: Markdown structure checks |
| [vscode-pdf](https://marketplace.visualstudio.com/items?itemName=tomoki1207.pdf) | `tomoki1207.pdf` | Optional: Optional PDF viewing |
| [Excel Viewer](https://marketplace.visualstudio.com/items?itemName=grapecity.gc-excelviewer) | `grapecity.gc-excelviewer` | Optional: Optional spreadsheet/CSV viewing |

#### Full Stack extensions

| Extension | Identifier | Status and purpose |
|---|---|---|
| [Prettier – Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Recommended: Format supported languages |
| [EditorConfig](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) | `editorconfig.editorconfig` | Recommended: Respect repository whitespace rules |
| [Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) | `pkief.material-icon-theme` | Recommended: File and folder icons |
| [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) | `yzhang.markdown-all-in-one` | Recommended: Markdown editing conveniences |
| [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) | `streetsidesoftware.code-spell-checker` | Recommended: Spelling diagnostics |
| [markdownlint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint) | `davidanson.vscode-markdownlint` | Recommended: Markdown structure checks |
| [Angular Language Service](https://marketplace.visualstudio.com/items?itemName=angular.ng-template) | `angular.ng-template` | Recommended: Angular template diagnostics and navigation |
| [Angular HTML](https://marketplace.visualstudio.com/items?itemName=ghaschel.vscode-angular-html) | `ghaschel.vscode-angular-html` | Recommended: Your chosen template highlighting |
| [Nx Console](https://marketplace.visualstudio.com/items?itemName=nrwl.angular-console) | `nrwl.angular-console` | Recommended: Generators, targets, and workspace information |
| [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) | `dbaeumer.vscode-eslint` | Recommended: Repository lint diagnostics and fixes |
| [Prisma](https://marketplace.visualstudio.com/items?itemName=prisma.prisma) | `prisma.prisma` | Recommended: Prisma schema editing and formatting |
| [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) | `eamodio.gitlens` | Recommended: History, blame, and comparisons |
| [Codex – OpenAI’s coding agent](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) | `openai.chatgpt` | Recommended: OpenAI coding-agent integration |
| [Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) | `anthropic.claude-code` | Recommended: Anthropic coding-agent integration |
| [Good Prompts](https://marketplace.visualstudio.com/items?itemName=omarbanat.goodprompts) | `omarbanat.goodprompts` | Recommended: Guided prompt generation and library |
| [DotENV](https://marketplace.visualstudio.com/items?itemName=mikestead.dotenv) | `mikestead.dotenv` | Recommended: Environment-file highlighting |
| [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) | `redhat.vscode-yaml` | Recommended: YAML schemas and diagnostics |
| [Azure Pipelines](https://marketplace.visualstudio.com/items?itemName=ms-azure-devops.azure-pipelines) | `ms-azure-devops.azure-pipelines` | Recommended: Pipeline YAML support |
| [Container Tools](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-containers) | `ms-azuretools.vscode-containers` | Recommended: Docker and Compose tooling |
| [PostgreSQL](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-pgsql) | `ms-ossdata.vscode-pgsql` | Recommended: Direct PostgreSQL browsing and queries |
| [Jest](https://marketplace.visualstudio.com/items?itemName=orta.vscode-jest) | `orta.vscode-jest` | Optional: When the repository uses Jest |
| [Playwright Test](https://marketplace.visualstudio.com/items?itemName=ms-playwright.playwright) | `ms-playwright.playwright` | Optional: When the repository uses Playwright |
| [Tailwind CSS IntelliSense](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) | `bradlc.vscode-tailwindcss` | Optional: When the repository uses Tailwind |
| [Stylelint](https://marketplace.visualstudio.com/items?itemName=stylelint.vscode-stylelint) | `stylelint.vscode-stylelint` | Optional: When the repository configures Stylelint |
| [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | `ms-vscode-remote.remote-containers` | Optional: When you develop inside a container |
| [GitHub Pull Requests](https://marketplace.visualstudio.com/items?itemName=github.vscode-pull-request-github) | `github.vscode-pull-request-github` | Optional: GitHub-hosted PRs; not Azure Repos PRs |
| [Error Lens](https://marketplace.visualstudio.com/items?itemName=usernamehw.errorlens) | `usernamehw.errorlens` | Optional: If inline diagnostics improve readability |
| [Switch to DataGrip](https://marketplace.visualstudio.com/items?itemName=MaxPowerEngine.switch2datagrip) | `MaxPowerEngine.switch2datagrip` | Optional: Optional SQL-file handoff; not database browsing |

#### AI extensions

| Extension | Identifier | Status and purpose |
|---|---|---|
| [Prettier – Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Recommended: Format supported languages |
| [EditorConfig](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) | `editorconfig.editorconfig` | Recommended: Respect repository whitespace rules |
| [Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) | `pkief.material-icon-theme` | Recommended: File and folder icons |
| [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) | `yzhang.markdown-all-in-one` | Recommended: Markdown editing conveniences |
| [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) | `streetsidesoftware.code-spell-checker` | Recommended: Spelling diagnostics |
| [markdownlint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint) | `davidanson.vscode-markdownlint` | Recommended: Markdown structure checks |
| [Codex – OpenAI’s coding agent](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) | `openai.chatgpt` | Recommended: OpenAI coding-agent integration |
| [Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) | `anthropic.claude-code` | Recommended: Anthropic coding-agent integration |
| [Good Prompts](https://marketplace.visualstudio.com/items?itemName=omarbanat.goodprompts) | `omarbanat.goodprompts` | Recommended: Guided prompt generation and library |
| [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) | `eamodio.gitlens` | Recommended: History, blame, and comparisons |
| [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) | `dbaeumer.vscode-eslint` | Recommended: Repository lint diagnostics and fixes |
| [Angular Language Service](https://marketplace.visualstudio.com/items?itemName=angular.ng-template) | `angular.ng-template` | Recommended: Angular template diagnostics and navigation |
| [Nx Console](https://marketplace.visualstudio.com/items?itemName=nrwl.angular-console) | `nrwl.angular-console` | Recommended: Generators, targets, and workspace information |
| [Prisma](https://marketplace.visualstudio.com/items?itemName=prisma.prisma) | `prisma.prisma` | Recommended: Prisma schema editing and formatting |
| [DotENV](https://marketplace.visualstudio.com/items?itemName=mikestead.dotenv) | `mikestead.dotenv` | Recommended: Environment-file highlighting |
| [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) | `redhat.vscode-yaml` | Recommended: YAML schemas and diagnostics |
| [Chat Customizations Evaluations](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-chat-customizations-evaluations) | `ms-vscode.vscode-chat-customizations-evaluations` | Optional: Optional prompt/skill analysis using Copilot |
| [Foundry Toolkit for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-windows-ai-studio.windows-ai-studio) | `ms-windows-ai-studio.windows-ai-studio` | Optional: Optional model playground and AI application tooling |
| [Jest](https://marketplace.visualstudio.com/items?itemName=orta.vscode-jest) | `orta.vscode-jest` | Optional: When the repository uses Jest |
| [Playwright Test](https://marketplace.visualstudio.com/items?itemName=ms-playwright.playwright) | `ms-playwright.playwright` | Optional: When the repository uses Playwright |
| [PostgreSQL](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-pgsql) | `ms-ossdata.vscode-pgsql` | Optional: Direct PostgreSQL browsing and queries |

#### Operations extensions

| Extension | Identifier | Status and purpose |
|---|---|---|
| [Prettier – Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Recommended: Format supported languages |
| [EditorConfig](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) | `editorconfig.editorconfig` | Recommended: Respect repository whitespace rules |
| [Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) | `pkief.material-icon-theme` | Recommended: File and folder icons |
| [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) | `yzhang.markdown-all-in-one` | Recommended: Markdown editing conveniences |
| [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) | `streetsidesoftware.code-spell-checker` | Recommended: Spelling diagnostics |
| [markdownlint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint) | `davidanson.vscode-markdownlint` | Recommended: Markdown structure checks |
| [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) | `eamodio.gitlens` | Recommended: History, blame, and comparisons |
| [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) | `redhat.vscode-yaml` | Recommended: YAML schemas and diagnostics |
| [Azure Pipelines](https://marketplace.visualstudio.com/items?itemName=ms-azure-devops.azure-pipelines) | `ms-azure-devops.azure-pipelines` | Recommended: Pipeline YAML support |
| [Container Tools](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-containers) | `ms-azuretools.vscode-containers` | Recommended: Docker and Compose tooling |
| [DotENV](https://marketplace.visualstudio.com/items?itemName=mikestead.dotenv) | `mikestead.dotenv` | Recommended: Environment-file highlighting |
| [PostgreSQL](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-pgsql) | `ms-ossdata.vscode-pgsql` | Recommended: Direct PostgreSQL browsing and queries |
| [Remote – SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) | `ms-vscode-remote.remote-ssh` | Optional: When opening remote folders |
| [Remote – SSH: Editing](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-edit) | `ms-vscode-remote.remote-ssh-edit` | Optional: Keep when required by Remote SSH |
| [Remote Explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer) | `ms-vscode.remote-explorer` | Optional: Keep when required by remote tooling |
| [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | `ms-vscode-remote.remote-containers` | Optional: When you develop inside a container |
| [Codex – OpenAI’s coding agent](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) | `openai.chatgpt` | Optional: OpenAI coding-agent integration |
| [Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) | `anthropic.claude-code` | Optional: Anthropic coding-agent integration |
| [shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format) | `foxundermoon.shell-format` | Optional: Optional shell formatting; choose one formatter |
| [Switch to DataGrip](https://marketplace.visualstudio.com/items?itemName=MaxPowerEngine.switch2datagrip) | `MaxPowerEngine.switch2datagrip` | Optional: Optional SQL-file handoff; not database browsing |

Keep DataGrip as the primary database application and Microsoft's PostgreSQL
extension for in-editor browsing. Skip a second general-purpose SQL extension
initially. Keep one icon theme, one main formatter per language, and GitLens
plus native Git before adding another graph interface. ESLint and configured
Stylelint provide diagnostics, not competing formatting ownership.

Install through the active profile's Extensions view, or name it explicitly:

```bash
code --profile "Full Stack" --install-extension anthropic.claude-code
code --profile "Full Stack" --install-extension omarbanat.goodprompts
code --profile "Full Stack" --install-extension ms-ossdata.vscode-pgsql
code --profile "AI" --install-extension omarbanat.goodprompts
code --profile "Operations" --install-extension ms-ossdata.vscode-pgsql
```

## 3. Apply shared User Settings

Switch profiles and run **Preferences: Open User Settings (JSON)**. Merge these
properties into the existing root object. Do not paste several complete JSON
objects into one file. In a clean profile, this block is the starting object.
For an existing profile, preserve your other chosen settings.

Then apply section 4's overrides in the order shown. If a property already
exists, edit it rather than adding a duplicate key. Nested language blocks
should preserve the shared options unless an override explicitly replaces them.

```json
{
  "files.autoSave": "off",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "editor.fontFamily": "'JetBrainsMono Nerd Font', Menlo, monospace",
  "editor.fontSize": 14,
  "editor.minimap.enabled": false,
  "editor.renderWhitespace": "selection",
  "editor.rulers": [
    100
  ],
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "editor.stickyScroll.enabled": true,
  "editor.linkedEditing": true,
  "editor.formatOnSave": false,
  "editor.formatOnPaste": false,
  "editor.detectIndentation": true,
  "workbench.editor.labelFormat": "medium",
  "workbench.editor.enablePreview": false,
  "git.autofetch": true,
  "git.confirmSync": true,
  "git.enableSmartCommit": false,
  "scm.alwaysShowRepositories": true,
  "workbench.colorTheme": "Dark Modern",
  "workbench.iconTheme": "material-icon-theme",
  "terminal.integrated.profiles.osx": {
    "Zsh — development": {
      "path": "/bin/zsh",
      "args": [],
      "icon": "terminal"
    },
    "Zsh — login diagnostics": {
      "path": "/bin/zsh",
      "args": [
        "-l"
      ],
      "icon": "terminal"
    }
  },
  "terminal.integrated.defaultProfile.osx": "Zsh — development",
  "terminal.integrated.shellIntegration.enabled": true,
  "terminal.integrated.suggest.enabled": true,
  "terminal.integrated.inheritEnv": true,
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font, monospace",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.scrollback": 10000,
  "terminal.integrated.copyOnSelection": false,
  "terminal.integrated.enablePersistentSessions": true,
  "terminal.external.osxExec": "Warp.app",
  "chat.tools.global.autoApprove": false,
  "chat.tools.terminal.enableAutoApprove": false,
  "github.copilot.chat.commitMessageGeneration.instructions": [
    {
      "text": "Use Conventional Commits: <type>(<optional scope>): <description>. Choose feat, fix, docs, refactor, perf, test, build, ci, chore, or revert based on the actual change. Follow repository conventions when available."
    },
    {
      "text": "Write an imperative, specific subject, preferably within 72 characters, without a trailing period. Describe the main outcome rather than listing filenames. Use a scope only when it makes the affected area clearer."
    },
    {
      "text": "For substantial changes, add a blank line and a concise body explaining the problem, what changed, and why. Include meaningful behavior changes or limitations. Keep simple changes to a subject alone."
    },
    {
      "text": "Describe only changes included in this commit. Do not invent motivations, test results, issue references, or compatibility guarantees. Mention validation only when its execution and outcome are known."
    },
    {
      "text": "Use ! and a BREAKING CHANGE footer only for actual breaking changes. Include issue references only when supplied. Return only the commit message, without Markdown fences or commentary."
    }
  ],
  "markdownlint.run": "onSave",
  "markdown.extension.toc.updateOnSave": false,
  "markdown.extension.tableFormatter.enabled": false,
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.wordWrap": "on",
    "files.trimTrailingWhitespace": false
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[jsonc]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  }
}
```

Explicit saves limit surprise edits. Formatting is enabled for Markdown and
JSON here, then for stack languages in Full Stack. Markdown All in One's table
formatter and automatic TOC updates are disabled so Prettier and deliberate
TOC updates have clear ownership. Repository Prettier/EditorConfig rules still
apply. Add spelling exceptions through Code Spell Checker's personal dictionary.

The non-login Zsh profile depends on the shared PATH helper being sourced from
`.zshrc`; follow the detailed Zsh recipe. Replace `/bin/zsh` in both terminal
profiles if you deliberately chose a different executable. Select the Nerd
Font in Warp too. `terminal.external.osxExec` opens Warp as a separate app.

The approval settings preserve Day One Mac's baseline; they govern supported
VS Code chat flows, not every vendor extension. Keep credentials out of User
Settings and exported profiles. User settings are personal configuration, not
secret storage. [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

The shared commit-message instructions ask Copilot to use Conventional Commits
with a specific subject and, for substantial changes, a body explaining what
changed and why. Stage the intended changes, then select **Generate Commit
Message** beside the message input in Source Control and review the result.
This setting is experimental and applies to Copilot's commit-message generator;
Codex and Claude require their own instructions. All four profile scripts
include it when generating new bundles. For an existing setup, merge the setting
into User Settings and use **Apply Setting to all Profiles** if desired.
[Commit-message instruction setting](https://code.visualstudio.com/docs/agents/reference/ai-settings).

## 4. Apply profile settings

| Profile | Exact settings recipe |
|---|---|
| Default | Shared block + Default overrides |
| Full Stack | Shared block + Full Stack overrides |
| AI | Shared block + Full Stack overrides + AI overrides; use AI's extension table |
| Operations | Shared block + Operations overrides |

### Default overrides

```json
{
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#30343B",
    "titleBar.activeForeground": "#FFFFFF"
  },
  "github.copilot.enable": {
    "*": false
  }
}
```

Copilot chat remains available; only inline suggestions are off.

### Full Stack overrides

This includes language formatting, manual unused-import removal, GitLens,
agent UI settings, YAML associations, environment-file handling, and generated
file exclusions. Claude Code and Good Prompts are part of the baseline.

```json
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.detectIndentation": true,
  "prettier.requireConfig": false,
  "prettier.singleQuote": true,
  "prettier.semi": true,
  "prettier.printWidth": 100,
  "prettier.tabWidth": 2,
  "eslint.format.enable": false,
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.sortImports": "explicit",
      "source.organizeImports": "never",
      "source.removeUnusedImports": "never"
    }
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.sortImports": "explicit",
      "source.organizeImports": "never",
      "source.removeUnusedImports": "never"
    }
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.sortImports": "explicit",
      "source.organizeImports": "never",
      "source.removeUnusedImports": "never"
    }
  },
  "[html]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[scss]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[css]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[jsonc]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.wordWrap": "on"
  },
  "[prisma]": {
    "editor.defaultFormatter": "Prisma.prisma",
    "editor.formatOnSave": true
  },
  "search.exclude": {
    "**/dist": true,
    "**/coverage": true,
    "**/.nx": true,
    "**/.angular": true
  },
  "files.watcherExclude": {
    "**/dist/**": true,
    "**/coverage/**": true,
    "**/.nx/**": true,
    "**/.angular/**": true
  },
  "files.associations": {
    "azure-pipelines.yml": "azure-pipelines",
    "azure-pipelines.yaml": "azure-pipelines",
    "**/.azure-pipelines/**/*.yml": "azure-pipelines",
    "**/.azure-pipelines/**/*.yaml": "azure-pipelines",
    ".env": "dotenv",
    ".env.*": "dotenv",
    "*.env": "dotenv"
  },
  "yaml.format.enable": false,
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[azure-pipelines]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[sql]": {
    "editor.formatOnSave": false
  },
  "[dockerfile]": {
    "editor.formatOnSave": false
  },
  "gitlens.currentLine.enabled": false,
  "gitlens.codeLens.enabled": false,
  "gitlens.statusBar.enabled": true,
  "github.copilot.enable": {
    "*": true,
    "plaintext": false,
    "markdown": false,
    "scminput": false,
    "dotenv": false
  },
  "chat.useAgentSkills": true,
  "chat.useAgentsMdFile": true,
  "chat.useClaudeMdFile": true,
  "chat.useCustomizationsInParentRepositories": true,
  "github.copilot.chat.cli.customAgents.enabled": true,
  "chatgpt.openOnStartup": false,
  "chatgpt.composerEnterBehavior": "cmdAlways",
  "chatgpt.commentCodeLensEnabled": false,
  "[dotenv]": {
    "editor.formatOnSave": false,
    "editor.formatOnPaste": false,
    "editor.quickSuggestions": false,
    "editor.inlineSuggest.enabled": false,
    "editor.wordWrap": "off",
    "files.trimTrailingWhitespace": false
  },
  "chat.fontSize": 14,
  "chat.editor.fontSize": 13,
  "chat.editor.wordWrap": "on",
  "chat.checkpoints.enabled": true,
  "chat.checkpoints.showFileChanges": true,
  "chat.editing.autoAcceptDelay": 0,
  "chat.editing.confirmEditRequestRemoval": true,
  "chat.editing.confirmEditRequestRetry": true,
  "chat.tools.global.autoApprove": false,
  "chat.tools.terminal.enableAutoApprove": false,
  "claudeCode.preferredLocation": "sidebar",
  "claudeCode.initialPermissionMode": "default",
  "claudeCode.allowDangerouslySkipPermissions": false,
  "claudeCode.useTerminal": false,
  "claudeCode.useCtrlEnterToSend": true,
  "claudeCode.attachOpenFile": false,
  "claudeCode.autosave": false,
  "claudeCode.continueAfterReload": false,
  "claudeCode.respectGitIgnore": true,
  "chatgpt.followUpQueueMode": "queue",
  "chatgpt.reviewDelivery": "inline",
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#163A63",
    "titleBar.activeForeground": "#FFFFFF",
    "activityBarBadge.background": "#2563EB"
  }
}
```

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

Apply after Full Stack. These replace the accent and Copilot inline preference,
while retaining TypeScript/Angular/Prisma diagnostics and formatting.

```json
{
  "workbench.colorTheme": "Dark Modern",
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#452568",
    "titleBar.activeForeground": "#FFFFFF",
    "activityBarBadge.background": "#9B6DDA"
  },
  "chat.fontSize": 14,
  "chat.editor.fontSize": 13,
  "chat.editor.wordWrap": "on",
  "chat.checkpoints.enabled": true,
  "chat.checkpoints.showFileChanges": true,
  "chat.editing.autoAcceptDelay": 0,
  "chat.editing.confirmEditRequestRemoval": true,
  "chat.editing.confirmEditRequestRetry": true,
  "chat.tools.global.autoApprove": false,
  "chat.tools.terminal.enableAutoApprove": false,
  "chat.useAgentSkills": true,
  "chat.useAgentsMdFile": true,
  "chat.useClaudeMdFile": true,
  "chat.useCustomizationsInParentRepositories": true,
  "github.copilot.chat.cli.customAgents.enabled": true,
  "github.copilot.enable": {
    "*": false
  },
  "chatgpt.openOnStartup": false,
  "chatgpt.composerEnterBehavior": "cmdAlways",
  "chatgpt.followUpQueueMode": "queue",
  "chatgpt.reviewDelivery": "detached",
  "chatgpt.commentCodeLensEnabled": false,
  "claudeCode.preferredLocation": "sidebar",
  "claudeCode.initialPermissionMode": "default",
  "claudeCode.allowDangerouslySkipPermissions": false,
  "claudeCode.useTerminal": false,
  "claudeCode.useCtrlEnterToSend": true,
  "claudeCode.attachOpenFile": false,
  "claudeCode.autosave": false,
  "claudeCode.continueAfterReload": false,
  "claudeCode.respectGitIgnore": true,
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.wordWrap": "on",
    "files.trimTrailingWhitespace": false,
    "editor.quickSuggestions": {
      "other": "off",
      "comments": "off",
      "strings": "off"
    }
  }
}
```

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

```json
{
  "files.associations": {
    "azure-pipelines.yml": "azure-pipelines",
    "azure-pipelines.yaml": "azure-pipelines",
    "**/.azure-pipelines/**/*.yml": "azure-pipelines",
    "**/.azure-pipelines/**/*.yaml": "azure-pipelines",
    ".env": "dotenv",
    ".env.*": "dotenv",
    "*.env": "dotenv"
  },
  "yaml.format.enable": false,
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[azure-pipelines]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[sql]": {
    "editor.formatOnSave": false
  },
  "[dockerfile]": {
    "editor.formatOnSave": false
  },
  "[dotenv]": {
    "editor.formatOnSave": false,
    "editor.formatOnPaste": false,
    "editor.quickSuggestions": false,
    "editor.inlineSuggest.enabled": false,
    "editor.wordWrap": "off",
    "files.trimTrailingWhitespace": false
  },
  "gitlens.currentLine.enabled": false,
  "gitlens.codeLens.enabled": false,
  "gitlens.statusBar.enabled": true,
  "github.copilot.enable": {
    "*": false
  },
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#174B3A",
    "titleBar.activeForeground": "#FFFFFF",
    "activityBarBadge.background": "#16805D"
  }
}
```

SQL stays manually formatted until you deliberately choose a formatter.
Configure connection credentials through PostgreSQL's connection UI, not JSON.
If enabling Codex or Claude in Operations, add their extension preferences
from Full Stack selectively; a profile switch does not grant database access.

## 5. Finish prompts, skills, agents, and MCP

These are shared manual actions for either setup route. Configure only the
clients and integrations you selected; signing in or importing a profile does
not configure the other clients automatically.

| Task | Setup reference | Verify in the actual client |
|---|---|---|
| Agent accounts and prompt tools | [AI workflow reference](VSCODE-TYPESCRIPT.md#3-ai-workflow-reference) | Intended account, permission mode and project; preview a prompt before editing |
| Shared instructions and client-specific agent wrappers | [Project instructions, skills and agents](VSCODE-TYPESCRIPT.md#9-share-project-instructions-skills-and-agents) | One canonical policy; each client discovers its own adapter |
| Selected project skills | [Skill selection reference](VSCODE-TYPESCRIPT.md#10-choose-and-install-project-skills) | Review source and project compatibility; inspect existing files before adding links |
| MCP servers | [Project and global MCP recipes](VSCODE-TYPESCRIPT.md#11-configure-project-and-global-mcp-servers) | Trust, authentication and tool access in each client separately |

Use one editing agent per worktree. Personal skills and global agent/MCP
configuration can be shared across profiles; a profile switch neither isolates
credentials nor stops servers. Keep private configuration out of exported
profiles and review any project files before committing them.

## 6. Configure DataGrip and PostgreSQL connections

Database connections and credentials are a separate manual step. Use the
[DataGrip and PostgreSQL setup guide](DATAGRIP.md)
for local provisioning, dev/test/prod roles and connections, TLS, migrations,
backups and optional MCP. Its [VS Code steps](DATAGRIP.md#8-connect-vs-code-to-the-same-databases)
configure the editor's own User-scope connections.
Choose only the environments your work requires. A profile or connection
colour does not enforce database permissions.

## 7. Finish shortcuts, icons, worktrees, and Zsh

| Task | Final choice | Exact setup |
|---|---|---|
| Organise imports | Manual action: sorts and removes unused imports | [Import policy and copyable keybindings](VSCODE-TYPESCRIPT.md#4-configure-import-cleanup-and-keyboard-shortcuts) |
| Remove unused imports | Manual after the change is ready | Same keybinding recipe; retain intentional module initialization |
| Sort imports | On explicit save in Full Stack/AI | Already in the TypeScript settings above |
| Angular folder icons | Angular icon for actual frontend folder names | [Folder associations](VSCODE-TYPESCRIPT.md#6-configure-angular-and-nestjs-folder-icons) |
| NestJS folder icons | Red server clone for API folders; optional custom SVG logo | Same icon recipe; don't invent a built-in NestJS identifier |
| Angular HTML palette | Dark Modern plus the extension's documented token scopes | [Copyable palette and token inspection](VSCODE-TYPESCRIPT.md#7-configure-angular-html-highlighting) |
| Native Git worktrees | One working directory for each independent branch/agent task | [Worked UI/CLI example](VSCODE-TYPESCRIPT.md#8-create-a-native-git-worktree-worked-example) |
| Zsh in VS Code and Warp | Shared PATH, Node manager and history; terminal-specific completions | [Complete home-file merge recipe](VSCODE-TYPESCRIPT.md#12-use-zsh-consistently-in-vs-code-and-warp) |

Follow the linked recipe only for the capability you selected. The advanced
reference owns the detailed shortcuts and shell/worktree examples. Preserve
existing configuration and merge through its chosen owner, including chezmoi
when used. Review account permissions separately from editor appearance.

## 8. Verify and export

1. Open a new terminal in Full Stack; confirm `node`, the repository package
   manager, Git, and the selected Zsh environment.
2. Open an Angular template and Prisma schema; confirm diagnostics and correct
   formatter ownership. Check import actions on a small disposable edit.
3. Verify Angular/NestJS folder icons and HTML token colours in Full Stack.
4. Open Good Prompts in Full Stack and AI; select the intended agent and review
   a generated prompt without making edits.
5. Confirm Copilot, Codex, and Claude each use the intended account, mode, and
   project. Verify Claude's canonical skill links rather than creating copies.
6. Test selected MCP servers in the actual client/harness. Don't assume the
   same server is available in another provider or remote environment.
7. Test local/dev/test database connections, then separately verify the
   production read-only identity. Do not use a write operation as a casual test.
8. Export each profile to a private backup outside the repository. Inspect
   exports for personal information; back up CLI agent/skill configuration
   separately and regrant machine-specific permissions when moving Macs.

Exported profiles do not replace database credential management or runtime
configuration backups. A successful editor setup does not establish that a
migration is safe. No live configuration is changed by this guide.

## 9. Optional custom profile: Tech Content Creator

Use a separate writing profile only when articles, tutorials or screenshots
need a different editor layout. This is a manual customisation, not a fifth
`vscode-profile` generator recipe. Work and Personal profiles can use the same
approach with their organisation-approved extensions and account policies.

1. Export the current configuration using the [backup guide](VSCODE.md#export-and-back-up-the-configuration).
2. Create **Tech Content Creator** by copying a reviewed Default profile, or
   choose **Empty Profile** when cleaning up unknown state.
3. Review the [Default extension list](#default-extensions). Markdown, spelling,
   Prettier and icons cover the writing baseline. Add `usernamehw.errorlens`
   only if inline error messages help your demonstrations.
4. Apply [shared User Settings](#3-apply-shared-user-settings) and
   [Default overrides](#default-overrides), then merge the presentation
   overrides below. Preserve both explicit agent approval settings and the
   shared commit-message instructions when editing the baseline.
5. Test Markdown formatting, terminal launch and a sample document; then
   [export the new profile](VSCODE.md#export-a-portable-profile--preferred).

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

---

[Application guides](README.md) · [Detailed stack recipes](VSCODE-TYPESCRIPT.md) · [Warp](WARP.md) · [Vorssaint](VORSSAINT.md)
