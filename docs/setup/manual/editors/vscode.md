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

Profiles organise settings and extensions. They do not isolate accounts, agent
credentials, database permissions or CLI configuration. A copied profile is a
snapshot; common preferences do not automatically inherit later edits.

The exact JSON is generated from the repository's versioned configuration in
[profile data](../../../shared/reference/vscode-profile-data.md). Marketplace
links identify the proposed extensions; check publisher, availability and the
installed editor's setting schema before installation. Vendor labels and agent
features can change with versions, accounts and policy. Official
[profile documentation](https://code.visualstudio.com/docs/configure/profiles)
and [AI overview](https://code.visualstudio.com/docs/agents/overview) were consulted
on 24 October 2026; that does not certify every third-party extension release.

## Open VS Code and enable the CLI

1. Open the approved VS Code application.

   Expected result: the editor opens without a conflicting duplicate installation.

2. Run **Shell Command: Install 'code' command in PATH** from the Command Palette
   (`Cmd+Shift+P`).

   Expected result: `code --version` works in a new terminal.

3. Export existing profiles before changing them, using the backup section below.

   Expected result: a private `.code-profile` file exists for each configuration
   you intend to replace. Review exports for account details and private paths.

## 1. Choose and create profiles

| Profile | Purpose | Appearance | Normal database use |
|---|---|---|---|
| Default | Configuration, notes, general editing | Dark Modern; neutral | None |
| Full Stack | Daily Angular/Nest/Nx development | Dark Modern; blue | Local/dev/test |
| AI | Prompt authoring, reviews, debugging, agents and skills | Dark Modern; purple | Optional local/dev/test tools |
| Operations | Containers, pipelines, databases, remote work | Dark Modern; green | Production read-only investigation |

Choose Default plus only the task profiles you need.

### Create the selected profiles

1. [Export your current profiles](#export-a-portable-profile---preferred) before changing them.
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

Each profile table lists its full shared set again. **Recommended** means part
of that profile's baseline. **Optional** means install only for an actual task.
Linked names point to Marketplace listings; these are not commands to install
every optional item. Let parent extensions manage required companions.

#### Default extensions

| Extension | Identifier | Status and purpose |
|---|---|---|
| [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Recommended: Format supported languages |
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
| [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Recommended: Format supported languages |
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
| [Codex - OpenAI’s coding agent](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) | `openai.chatgpt` | Recommended: OpenAI coding-agent integration |
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
| [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Recommended: Format supported languages |
| [EditorConfig](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) | `editorconfig.editorconfig` | Recommended: Respect repository whitespace rules |
| [Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) | `pkief.material-icon-theme` | Recommended: File and folder icons |
| [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) | `yzhang.markdown-all-in-one` | Recommended: Markdown editing conveniences |
| [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) | `streetsidesoftware.code-spell-checker` | Recommended: Spelling diagnostics |
| [markdownlint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint) | `davidanson.vscode-markdownlint` | Recommended: Markdown structure checks |
| [Codex - OpenAI’s coding agent](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) | `openai.chatgpt` | Recommended: OpenAI coding-agent integration |
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
| [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | `esbenp.prettier-vscode` | Recommended: Format supported languages |
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
| [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) | `ms-vscode-remote.remote-ssh` | Optional: When opening remote folders |
| [Remote - SSH: Editing](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-edit) | `ms-vscode-remote.remote-ssh-edit` | Optional: Keep when required by Remote SSH |
| [Remote Explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer) | `ms-vscode.remote-explorer` | Optional: Keep when required by remote tooling |
| [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | `ms-vscode-remote.remote-containers` | Optional: When you develop inside a container |
| [Codex - OpenAI’s coding agent](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) | `openai.chatgpt` | Optional: OpenAI coding-agent integration |
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

Use the maintained [JSON configuration](../../../shared/reference/vscode-profile-data.md#shared-settings).

Explicit saves limit surprise edits. Formatting is enabled for Markdown and
JSON here, then for stack languages in Full Stack. Markdown All in One's table
formatter and automatic TOC updates are disabled so Prettier and deliberate
TOC updates have clear ownership. Repository Prettier/EditorConfig rules still
apply. Add spelling exceptions through Code Spell Checker's personal dictionary.

The non-login Zsh profile depends on the shared PATH helper being sourced from
`.zshrc`; follow the detailed Zsh recipe. Replace `/bin/zsh` in both terminal
profiles if you deliberately chose a different executable. Select the Nerd
Font in Warp too. `terminal.external.osxExec` opens Warp as a separate app.

All four recipes set
`"terminal.integrated.suggest.upArrowNavigatesHistory": true`. Pair it with
the [Zsh matching-history bindings](../shell/zsh.md#search-matching-commands-with-up-and-down):
type `brew `, then Up/Down to cycle through previous commands with that prefix.
The profile setting alone cannot change Zsh's history behaviour. Existing
profiles need a manual User Settings merge, and existing shell files need the
linked `.zshrc` merge. Warp retains its own input behaviour.

The approval settings preserve Day One Mac's baseline; they govern supported
VS Code chat flows, not every vendor extension. Keep credentials out of User
Settings and exported profiles. User settings are personal configuration, not
secret storage. [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

The shared commit-message instructions ask Copilot to use Conventional Commits
with a specific subject and, for substantial changes, a body explaining what
changed and why. Stage the intended changes, then select **Generate Commit
Message** beside the message input in Source Control and review the result.
This setting is experimental and applies to Copilot's commit-message generator;
Codex and Claude require their own instructions. The versioned profile recipes include it. For an existing setup, merge the setting
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

Apply after Full Stack. These replace the accent and Copilot inline preference,
while retaining TypeScript/Angular/Prisma diagnostics and formatting.

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

Open **Preferences: Open Keyboard Shortcuts (JSON)** in Full Stack. Add these
entries to its existing array. They are suggested personal chords, not defaults:

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

Search each chord in the Keyboard Shortcuts editor for conflicts before saving.
Do not copy these import bindings into Operations unless it also edits TS/JS.
Use **Developer: Toggle Keyboard Shortcuts Troubleshooting** if a chord invokes
another action. [Keyboard configuration](https://code.visualstudio.com/docs/configure/keybindings).

## 6. Edit environment files

Install DotENV in Full Stack, Operations, and AI. Its verified language identifier
is `dotenv`; the main guide’s profile settings cover `.env`, `.env.local`,
`.env.example`, and `development.env`.
[Language manifest](https://github.com/mikestead/vscode-dotenv/blob/master/package.json).

The [canonical profile settings](#4-apply-profile-settings)
already disable automatic formatting and suggestions for environment files.
Review that baseline in the active profile rather than applying another copy.

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

Add to Full Stack User Settings, replacing folder names with your actual names:

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
2. Select **Dark Modern** as the profile theme.
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

Expect distinct colors for the custom tag, input, event, control-flow keyword,
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

## Export and back up the configuration

### Export a portable profile - preferred

1. Open **Manage → Profiles**.
2. Select the profile you want to preserve.
3. Open its actions menu and choose **Export…**.
4. Review which parts will be exported.
5. Choose **Local file** and save the `.code-profile` file under:

   ```text
   /Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code/
   ```

VS Code can also save a profile to a GitHub secret gist. Use a local file when
the profile is private, work-managed, or not intended to leave the Mac. Some
machine-specific settings are deliberately excluded from profile exports.

### Restore your own exported profile

1. In Profiles, choose **Import Profile…** and select your `.code-profile` backup. Expected: VS Code shows a preview of its contents.
2. Select only the settings, keyboard shortcuts, snippets and extensions you intend to restore. Expected: unrelated profile data is not selected.
3. Import under a distinct temporary profile name. Expected: the imported profile can be tested before replacing your working profile.
4. Verify the terminal, formatter and extension behavior using the checks above. Expected: Settings Sync is intentionally on or intentionally off, and the profile works locally before syncing it to another device.

### Record the extension inventory

```bash
EXPORT_DIR="/Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code"
test -d "/Volumes/<backup-volume>" || { echo "Backup volume is not mounted"; exit 1; }
mkdir -p "$EXPORT_DIR"
code --list-extensions --show-versions | sort > "$EXPORT_DIR/extensions.txt"
```

This text file is an audit. A later reinstall normally installs the current
release rather than forcing a pinned version:

```bash
cut -d@ -f1 "/Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code/extensions.txt" |
  while IFS= read -r extension; do
    test -n "$extension" && code --install-extension "$extension"
  done
```

Review the list first. Restoring every old extension can defeat the clean-start
goal.

### Back up the complete local user folder - recovery copy

Quit VS Code first, then make a private recovery copy:

```bash
EXPORT_DIR="/Volumes/<backup-volume>/Day-One-Mac-App-Exports/VS-Code"
test -d "/Volumes/<backup-volume>" || { echo "Backup volume is not mounted"; exit 1; }
mkdir -p "$EXPORT_DIR"
ditto "$HOME/Library/Application Support/Code/User" "$EXPORT_DIR/User"
```

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
| `code: command not found` | Repeat Step 1 and reopen Terminal |
| Old extensions reappear | Turn off Settings Sync, remove the unwanted extensions, verify locally, then reconfigure sync |
| A formatter changes every project | Remove the global default and set it in that repository instead |
| Starship symbols are squares | Select JetBrainsMono Nerd Font and reopen the terminal |
| One profile looks different | Confirm the active profile from **Manage → Profiles** |
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
3. Review the [Default extension list](#default-extensions). Markdown, spelling,
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

---

[Application guides](../apps/README.md) · [Detailed stack recipes](vscode.md) · [Warp](../terminals/warp.md) · [Vorssaint](../apps/vorssaint.md)
