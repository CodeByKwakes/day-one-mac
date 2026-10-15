[← Application guides](README.md) · [Detailed stack recipes](VSCODE-TYPESCRIPT.md) · [Profile management](../02-optional/12-vscode-profiles.md)

# Final VS Code profile setup for full-stack TypeScript development

**Document type:** how-to guide and extension reference. **Audience:** experienced
macOS developers using Angular, NestJS, Nx, Prisma, Azure DevOps, Docker,
PostgreSQL, Copilot, Codex, and Claude Code. **Updated:** 15 October 2026.

This is the final profile selection and settings recipe for this stack. Use it
first; use the [detailed stack guide](VSCODE-TYPESCRIPT.md) for complete icon,
Angular HTML, worktree, skill, symlink, MCP, and Zsh instructions.

Latest stable checked: **VS Code 1.142.0**, released 14 October 2026. Your installed
version was 1.141.2 when checked; update through **Code → Check for Updates**.
New agent defaults roll out progressively and employer policies can override
availability. [Release notes](https://code.visualstudio.com/updates/v1_142).

All editor settings below belong to **User Settings for the active profile**.
No `.vscode/settings.json`, extension recommendation file, credential file, or
live configuration is created by following the documentation alone.
Repository formatter/linter rules and managed settings can still override
personal preferences. Keep required project configuration intact.

## Contents

1. [Create the four profiles](#1-create-the-four-profiles)
2. [Install the final extension lists](#2-install-the-final-extension-lists)
3. [Apply shared User Settings](#3-apply-shared-user-settings)
4. [Apply profile settings](#4-apply-profile-settings)
5. [Finish prompts, skills, agents, and MCP](#5-finish-prompts-skills-agents-and-mcp)
6. [Configure DataGrip and PostgreSQL connections](#6-configure-datagrip-and-postgresql-connections)
7. [Finish shortcuts, icons, worktrees, and Zsh](#7-finish-shortcuts-icons-worktrees-and-zsh)
8. [Verify and export](#8-verify-and-export)

## 1. Create the four profiles

| Profile | Purpose | Appearance | Normal database use |
|---|---|---|---|
| Default | Configuration, notes, general editing | Dark Modern; neutral | None |
| Full Stack | Daily Angular/Nest/Nx development | Dark Modern; blue | Local/dev/test |
| AI | Prompt authoring, reviews, debugging, agents and skills | Dark Modern; purple | Optional local/dev/test tools |
| Operations | Containers, pipelines, databases, remote work | Dark Modern; green | Production read-only investigation |

1. Export your current profile before changing it.
2. Configure Default with the shared extensions/settings below.
3. Create Full Stack and Operations by copying Default.
4. Configure Full Stack, then copy it to create AI.
5. In AI, disable Full Stack-only extensions unless needed for the current task.
6. Associate your normal repository with Full Stack. Select AI or Operations
   deliberately for focused work, preferably in a separate window/worktree.

Copying profiles is a snapshot, not automatic inheritance. Apply common
preferences to all profiles deliberately; keep accents and Copilot completion
choices profile-specific. Profiles are not sandboxes and do not isolate agent
credentials, CLI configuration, or database permissions.
[Profiles](https://code.visualstudio.com/docs/configure/profiles).

### Generate profile files with the scripts

Use the four scripts below from the Day One Mac directory. They require
**Node.js 22 or newer**. They read this guide's extension tables and settings
recipes, so keep the scripts and documentation together. Generated settings
are personal User Settings; these scripts create no repository `.vscode` files.

| Profile | Generate its reviewed baseline | Baseline extensions |
|---|---|---|
| Default | `bash scripts/vscode-profiles/default.sh` | 6 |
| Full Stack | `bash scripts/vscode-profiles/full-stack.sh` | 20 |
| AI | `bash scripts/vscode-profiles/ai.sh` | 16 |
| Operations | `bash scripts/vscode-profiles/operations.sh` | 12 |

Start with a preview, then generate the profiles you want:

```bash
bash scripts/vscode-profiles/full-stack.sh --dry-run
bash scripts/vscode-profiles/default.sh
bash scripts/vscode-profiles/full-stack.sh
bash scripts/vscode-profiles/ai.sh
bash scripts/vscode-profiles/operations.sh
```

Each invocation prints its output directory: by default a new private directory
in macOS temporary storage. Copy any files you want to keep to your private
backup location; temporary files are not permanent backups. For a persistent
destination, pass a **new directory whose parent already exists**:

```bash
mkdir -p "$HOME/Developer/Resources/VSCode/Profiles"
bash scripts/vscode-profiles/full-stack.sh \
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
bash scripts/vscode-profiles/default.sh --install-extensions
bash scripts/vscode-profiles/full-stack.sh --install-extensions
bash scripts/vscode-profiles/ai.sh --install-extensions
bash scripts/vscode-profiles/operations.sh --install-extensions
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
bash scripts/vscode-profiles/full-stack.sh \
  --with orta.vscode-jest \
  --with ms-playwright.playwright
bash scripts/vscode-profiles/operations.sh \
  --with ms-vscode-remote.remote-ssh \
  --install-extensions
```

The first example generates a bundle with Jest and Playwright; the second also
installs Operations extensions and Remote SSH. Extension IDs are matched without
case sensitivity. Settings specific to optional tools remain manual unless
already present in the guide's profile recipe. `--code "/path/to/code"` selects
another VS Code CLI executable. `--help` lists options. `--dry-run` always
prevents file writes and CLI calls, including when combined with install mode.

Validate the scripts without touching live VS Code configuration:

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

### Agent accounts and prompt tools

| Surface | Configure it through | Recommended use |
|---|---|---|
| Copilot | VS Code's existing AI setup and account selection | Inline help in Full Stack; Ask/Plan/agent work as needed |
| Codex | Its extension panel and supported personal configuration | Investigation, implementation, review; its own account/access |
| Claude Code | Its own extension sign-in and permission controls | Planning, implementation, independent review; its own account/access |
| Good Prompts | GoodPrompts: Open Panel | Build a bounded task prompt, review the preview, then copy it to the selected agent |
| Chat Customizations Evaluations | Analyze Prompt command, if installed | Review skill/prompt diagnostics; Copilot required for LLM analysis |
| Foundry Toolkit | Provider/playground UI, if installed | AI application experiments; separate provider access/billing can apply |

For Good Prompts, select the actual target tool explicitly: several agent
extensions are installed, so automatic detection may choose a different one.
Set TypeScript, the project's real Node version, Angular/NestJS/Nx, and its style
rules through the panel. Its documented configuration uses extension state,
not invented `goodprompts.*` JSON settings. Leave its optional MCP connections
unused initially; your clients already have their own MCP setup.
[Good Prompts](https://marketplace.visualstudio.com/items?itemName=omarbanat.goodprompts).

Use Ask/read-only or Plan mode to turn a rough request into a prompt containing:
**goal, current behavior/evidence, desired behavior, affected files, constraints,
validation, and expected final report**. Review invented assumptions before
implementation. The [copyable prompt-builder request](VSCODE-TYPESCRIPT.md#generate-a-good-prompt-with-tools-you-already-have)
works without an extra generator. Use one editing agent per worktree.

### Canonical project skills and agent wrappers

Keep one canonical skill library under `.agents/skills`. Current Copilot and
Codex can use it; give Claude links rather than maintaining duplicate files.
Use `AGENTS.md` for shared project policy and a compatible `CLAUDE.md` link.
Share role policy as Markdown, with small client-specific wrappers for Codex,
Copilot, and Claude; their agent definition formats are not interchangeable.

Follow the complete [no-overwrite project symlink recipe](VSCODE-TYPESCRIPT.md#link-project-skills-and-the-claude-adapter-manually).
It creates relative Claude skill-folder links and a link to the Claude agent
adapter. Inspect existing files first. Verify Claude agent discovery after a
restart; its symlink behavior must be checked against the installed version.

Keep these personal project files out of Git using the documented local
exclude recipe if you do not want to share them. Ignored local files do not
automatically appear in a new worktree; recreate the selected links there.
Global personal skills in `~/.agents/skills` are not profile-private.

Recommended initial skills and the reason to use them:

| Skill | Why / when |
|---|---|
| angular-developer | Angular framework implementation using the project's supported version |
| nx-workspace | Understand projects, targets, and boundaries before a monorepo change |
| nx-run-tasks | Select the correct build/lint/test/affected tasks |
| nx-generate | Generate code through repository conventions |
| nestjs-best-practices | Nest API architecture, DI, validation, and tests; community maintained |
| systematic-debugging | Reproduce and establish a cause before changing code |
| verification-before-completion | Gather real verification evidence before declaring success |
| supabase-postgres-best-practices | PostgreSQL query/schema performance; apply service-specific advice selectively |

For example, from the application repository, install the selected Angular/Nx
skills into the canonical shared workflow:

```bash
npx skills@latest add angular/skills \
  --skill angular-developer --agent codex github-copilot
npx skills@latest add nrwl/nx-ai-agents-config \
  --skill nx-workspace nx-run-tasks nx-generate --agent codex github-copilot
```

Use the [full skill reference and commands](VSCODE-TYPESCRIPT.md#10-choose-and-install-project-skills)
for NestJS, debugging, Docker, PostgreSQL, Azure DevOps, and Prisma. Check the
project's Prisma major version before installing version-specific Prisma skills.
Skip duplicate global/project packs unless deliberately maintaining a different
version. The skill source checks in that reference are dated, not a promise
that future `@latest` downloads remain identical.

Current VS Code `.prompt.md` commands apply only to Local harness sessions.
For Copilot/Codex reusable workflows, prefer portable skills. Do not add
deprecated customization-location settings; follow migration notices when an
old profile-local prompt needs conversion.
[Prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files).

### Selected MCP servers

| Server | Where it belongs | Why |
|---|---|---|
| Angular CLI MCP, read-only initially | Project context | Framework and Angular workspace tools |
| Nx MCP | Project context | Targets, generators, workspace context |
| Context7 | Personal/global or selected project | Current library documentation |
| Azure DevOps MCP | Selected organisation/project | Work items, PRs, build/pipeline context |
| Playwright MCP | Selected browser task | Interactive investigation; separate from Playwright Test extension |
| DataGrip MCP | Selected local/dev/test work | Existing DataGrip connections and database tools |
| GitHub MCP | Optional, only for GitHub-hosted work | Not a replacement for Azure DevOps tooling |

Use the [project/global MCP installation recipes](VSCODE-TYPESCRIPT.md#11-configure-project-and-global-mcp-servers).
Copilot, Codex, and Claude read different configuration locations/formats;
a server configured in one is not automatically configured in the others.
Portable global configuration can be shared across editor profiles. Do not
assume changing profiles stops a server or changes its database permissions.

## 6. Configure DataGrip and PostgreSQL connections

Use DataGrip for substantial database work and Microsoft's PostgreSQL extension
for in-editor browsing. Both connect to the same servers independently; saved
connections, passwords, and SSH tunnels do not automatically synchronize.
The installed DataGrip version checked was **2026.2.6**.

### Name connections consistently

| Environment | Suggested name in both clients | Normal permission | DataGrip colour |
|---|---|---|---|
| Local | LOCAL • app • developer | Read/write to local development data | Blue |
| Development | DEV • app • developer | Team-approved development privileges | Green |
| Test | TEST • app • reader | Read-only initially; separate writer when needed | Amber |
| Production | PROD • app • READ ONLY | Database-enforced read-only role | Red |
| Production maintenance | PROD • app • MAINTENANCE | Separate deliberate maintenance access | Red |

Use personal, identifiable database accounts. Do not reuse application service
accounts. A production read replica can suit investigation; account for lag
when checking a recent write. A profile name or connection colour is a visual
cue, not a permission boundary.

### Configure the VS Code client at User scope

1. Run **PGSQL: Add New Connection** in Full Stack or Operations.
2. Enter the real server, database, authentication, and friendly connection name.
3. Open **Advanced**. Set **Scope → User**, the correct port, and required SSL.
4. Use server groups to separate environments. Test before saving.
5. Choose **Save Password** only when appropriate; the extension uses VS Code
   SecretStorage, backed by macOS Keychain, rather than plaintext settings.
6. Keep local/dev/test work in Full Stack and production investigation in
   Operations. Other extensions and clients can still access what their own
   configured credentials allow.

User scope avoids a committed `.vscode/settings.json` connection. Azure-hosted
PostgreSQL can use Entra authentication when the server and roles support it;
Azure DevOps usage alone does not identify your database host.
[Connections and credential storage](https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/connections).

For a local Docker database, use its published host port, preferably bound to
`127.0.0.1`. For remote servers, use approved private networking/VPN or an SSH
bastion. Both clients support tunnelling and TLS; match the actual server's
certificate requirements. Prefer hostname/CA verification through **Verify
Full** rather than disabling verification to make a connection work.
[VS Code advanced connections](https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/advanced-connection-options),
[DataGrip SSH/TLS](https://www.jetbrains.com/help/datagrip/configuring-ssh-and-ssl.html).

### Configure DataGrip and production sessions

In **Data Sources and Drivers**, set friendly names, colours, selected schemas,
and the connection's read-only option. Use a restricted database role for the
normal production connection. Manual transaction mode is useful for deliberate
maintenance, but does not make every operation reversible. Keep the maintenance
connection separate and disconnect after use.
[DataGrip connection configuration](https://www.jetbrains.com/help/datagrip/configuring-database-connections.html).

Before important work, confirm the actual connection:

```sql
SELECT
  current_database() AS database_name,
  current_user AS database_user,
  inet_server_addr() AS server_address,
  inet_server_port() AS server_port;
```

Use filters/row limits and sensible statement/lock timeouts for investigation.
Do not leave transactions open while switching tasks. Keep production data and
schema changes as reviewed SQL/migrations rather than casual grid edits.

### DataGrip MCP and AI access

In DataGrip, open **Settings → Tools → MCP Server**, enable it, and inspect
**Exposed Tools**. Use its **Copy Config** or detected-client configuration for
your chosen client, preferring personal/global configuration. Restart the
client and test listing database connections before querying. Keep DataGrip
open with the intended project. Do not guess a permanent MCP port or command.
[JetBrains MCP setup](https://www.jetbrains.com/help/datagrip/mcp-server.html).

Initially use agent tools for local/dev/test only. Leave production out of the
agent workflow. For any later production agent access, database-enforced
read-only credentials are required for guaranteed write restriction. DataGrip
read-only UI flags, VS Code profiles, and MCP tool selection are not substitutes.
Leave DataGrip's command-execution-without-confirmation setting disabled.

The PostgreSQL extension's per-connection **Copilot access mode → Read Only**
is an additional control for that integration; it does not govern Codex,
Claude, or DataGrip MCP. Configure and verify each path independently.

### Optional SQL-file handoff

If you install Switch to DataGrip, its User Settings for this Mac can be:

```json
{
  "switch2datagrip.dataGripPath": "/Users/kwakes.prempeh/Applications/DataGrip.app"
}
```

Open the intended DataGrip project first, then use **Open in DataGrip** from
VS Code's editor context menu. This opens the file in DataGrip; it does not
mirror its database tree. Avoid its default Cmd+Shift+D if it conflicts with
VS Code's debugging shortcut.
[Extension listing](https://marketplace.visualstudio.com/items?itemName=MaxPowerEngine.switch2datagrip).

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

Useful macOS actions:

| Action | Shortcut / entry point |
|---|---|
| Command Palette | Cmd+Shift+P |
| Quick Open | Cmd+P |
| Format document | Shift+Option+F |
| Rename symbol | F2, or Fn+F2 when required by the keyboard |
| Problems | Cmd+Shift+M |
| Toggle integrated terminal | Ctrl+backtick |
| Open external terminal in Warp | Cmd+Shift+C, with the setting above |
| Organise imports, custom chord | Cmd+K then Cmd+I, after adding the recipe |
| Remove unused imports, custom chord | Cmd+K then Cmd+U, after adding the recipe |
| Sort imports, custom chord | Cmd+K then Cmd+Shift+I, after adding the recipe |

For the native worktree flow: open **Source Control Repositories → More
Actions → Worktrees → Create Worktree**, choose/create a branch, choose a
sibling directory, then open it in a new window with the intended profile.
Native support requires Git; no worktree extension is needed. Give each
worktree appropriate local ports and database state before running migrations.

For Warp, retain shared PATH/Node/history, but guard optional Zsh completion
and line-editor plugins with `TERM_PROGRAM != WarpTerminal` as documented in
the linked recipe. Prefer Warp's native suggestions there; avoid duplicate
`compinit`, prompt initialization, and shell integration. If VS Code's
suggestion dropdown competes with shell autosuggestions, choose one owner.

Do not overwrite `.zshrc`, `.zprofile`, or a chezmoi-owned source file wholesale.
This is a merge into your chosen shell setup, not another dotfile manager.

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

---

[Application guides](README.md) · [Detailed stack recipes](VSCODE-TYPESCRIPT.md) · [Warp](WARP.md) · [Vorssaint](VORSSAINT.md)
