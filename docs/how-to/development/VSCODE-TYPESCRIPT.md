[← VS Code first launch](../apps/VSCODE.md) · [Profile setup](../apps/VSCODE-PROFILES.md) · [MCP module](../modules/optional/11-mcp-servers.md)

# Advanced VS Code reference for TypeScript and AI workflows

**Document type:** reference with task-specific how-to recipes. **Audience:** experienced
TypeScript developers on macOS. **Last source check:** 15 October 2026.

Use this reference after [base setup](../apps/VSCODE.md) and the
[main profile guide](../apps/VSCODE-PROFILES.md). It explains optional capabilities,
import shortcuts, icons, worktrees, skills, agents, MCP and shell integration.
Read the section needed for your task; this is not a second setup checklist.

The main profile guide owns the extension assignments and shared/per-profile
settings. This reference owns the advanced examples and import keybindings.
Merge optional examples only when needed; repository rules and managed policy
still apply. Account sign-in, credential permissions and external services
must be checked separately from editor profile configuration.

## Contents

1. [Prepare the toolchain and profiles](#1-prepare-the-toolchain-and-profiles)
2. [Extension capability reference](#2-extension-capability-reference)
3. [AI workflow reference](AI-WORKFLOWS.md#3-ai-workflow-reference)
4. [Configure import cleanup and keyboard shortcuts](#4-configure-import-cleanup-and-keyboard-shortcuts)
5. [Edit environment files](#5-edit-environment-files)
6. [Configure Angular and NestJS folder icons](#6-configure-angular-and-nestjs-folder-icons)
7. [Configure Angular HTML highlighting](#7-configure-angular-html-highlighting)
8. [Create a native Git worktree: worked example](#8-create-a-native-git-worktree-worked-example)
9. [Share project instructions, skills, and agents](PROJECT-INSTRUCTIONS-AND-SKILLS.md#9-share-project-instructions-skills-and-agents)
10. [Choose and install project skills](PROJECT-INSTRUCTIONS-AND-SKILLS.md#10-choose-and-install-project-skills)
11. [Configure project and global MCP servers](MCP-CONNECTIONS.md#11-configure-project-and-global-mcp-servers)
12. [Use Zsh consistently in VS Code and Warp](ZSH-AND-TERMINALS.md#12-use-zsh-consistently-in-vs-code-and-warp)
13. [Verify, troubleshoot, and maintain the setup](#13-verify-troubleshoot-and-maintain-the-setup)
14. [DataGrip and PostgreSQL connections](#14-datagrip-and-postgresql-connections)

## 1. Prepare the toolchain and profiles

Confirm the editor and the tools selected during Day One Mac setup:

```bash
code --version
git --version
node --version
```

Use the repository's package manager and lockfile. Extensions do not install
Angular, NestJS, Nx, Prisma, ESLint, the PostgreSQL server, or the Docker engine.
Install project dependencies before diagnosing language-server failures.
For a Python-based MCP server, also complete the selected Python/uv setup.

### Choose profiles in the main guide

Use [Choose and create profiles](../apps/VSCODE-PROFILES.md#1-choose-and-create-profiles)
for the manual or generated route. Default, Full Stack, AI and Operations are
available recipes, not a requirement to maintain four profiles. Profiles do
not isolate accounts, agent credentials or database permissions.

## 2. Extension capability reference

Use the [canonical extension lists](../apps/VSCODE-PROFILES.md#2-install-the-final-extension-lists)
for exact IDs, required/optional assignments and installation. Do not install
a second list from this reference after completing the main guide.

### Native capabilities, accounts, and trade-offs

- TypeScript/JavaScript language services, Node/browser debugging, Git graph,
  merge tools, worktrees, and Dark Modern are built in. Git must be installed.
- Current VS Code integrates Copilot Chat. Start with **Use AI Features** and
  sign in; do not force-install an old standalone component over the bundled
  one. Its managed component IDs are `github.copilot` and
  `github.copilot-chat`; neither belongs in your manual install checklist. Plans, models, and employer policies
  affect access. [Copilot setup](https://code.visualstudio.com/docs/setup/copilot).
- The Codex vendor extension uses OpenAI account access; the listing names
  Plus, Pro, Business, Edu, and Enterprise plans. Its Agent Host alternative
  has different access requirements and is experimental. Use the extension
  baseline unless you deliberately choose that route.
- Claude's extension supports eligible Claude subscriptions or usage-based
  access. Selecting a Claude model in Copilot does not switch to Claude Code.
  [Harness and account choices](https://code.visualstudio.com/docs/agents/run/agent-harnesses).
- Prettier owns formatting; ESLint owns lint fixes. Do not add a combined
  formatter. Existing projects should disable conflicting formatting rules
  through their `eslint-config-prettier` package configuration.
- Prisma owns `.prisma` formatting. A Prettier Prisma plugin is unnecessary.
- Container Tools replaces Microsoft's earlier Docker functionality. Dev
  Containers hosts an environment; it is not a duplicate container manager.
- GitLens enhances native Git but some advanced private-repository features
  require an account or paid plan. Skip another graph extension initially.
- Azure Repos uses native Git. Azure Pipelines edits YAML; GitHub Pull Requests
  does not manage Azure Repos PRs.
- DotENV highlights text; it does not validate every runtime's dotenv syntax,
  load variables, mask values, or manage secrets.
- Angular Language Service and angular-html perform different jobs: semantic
  assistance and syntax highlighting. Keep Language Service installed.
- Markdownlint checks Markdown, not whether a skill's instructions or an
  agent's tool names are valid. No skills-manager extension is required.

## 3. AI workflow reference

Follow the maintained [procedure](AI-WORKFLOWS.md#3-ai-workflow-reference).

## 4. Configure import cleanup and keyboard shortcuts

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
One setups. Resolve that through the [shared shortcut guide](../apps/KEYBOARD-SHORTCUTS.md)
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

## 5. Edit environment files

Install DotENV in Full Stack, Operations, and AI. Its verified language identifier
is `dotenv`; the main guide’s profile settings cover `.env`, `.env.local`,
`.env.example`, and `development.env`.
[Language manifest](https://github.com/mikestead/vscode-dotenv/blob/master/package.json).

The [canonical profile settings](../apps/VSCODE-PROFILES.md#4-apply-profile-settings)
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
manager. Use [worktree environment guidance](worktrees/WORKTREES-ENVIRONMENT.md)
for per-worktree ports and databases. Do not share one writable database across
branches with incompatible migrations. The NestJS debugger, Prisma CLI, Docker
Compose, and MCP processes each load variables through their own configuration;
opening `.env` in VS Code does not load it into them.

## 6. Configure Angular and NestJS folder icons

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

## 7. Configure Angular HTML highlighting

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

## 8. Create a native Git worktree: worked example

No worktree extension is required. Use a separate folder for each writing agent
or branch, not two writing agents in the same checkout.
[Native worktree documentation](https://code.visualstudio.com/docs/sourcecontrol/branches-worktrees).

Example: your clean primary Nx checkout is on `main`; a prepared branch
`feature/customer-search` is not checked out anywhere. You want:

```text
~/Developer/Sandbox/customer-platform/                   main
~/Developer/Sandbox/customer-platform.worktrees/customer-search/
                                                       feature/customer-search
```

1. Open the primary checkout using Full Stack. Run **Git: Fetch**. Confirm the
   intended base and branch status before creating the worktree.
2. If the feature branch does not exist, on a clean checkout run **Git: Create
   Branch From…**, choose `origin/main`, and name it `feature/customer-search`.
   Return the primary checkout to `main` without editing the feature branch.
   This frees the feature branch for its own worktree. If the primary checkout
   has unfinished work, use the terminal alternative below instead.
3. Open Source Control with `⌃⇧G`. Run **View: Open View… → Source Control
   Repositories** if that view is hidden.
4. Select the repository row. Open its **More Actions (…) → Worktrees → Create
   Worktree** menu. Choose the prepared feature branch and destination.
5. In the macOS folder picker, `⇧⌘G` navigates to the worktree parent. Follow the
   picker labels to make the resulting folder exactly `customer-search`.
6. Right-click the new worktree and choose **Open Worktree in New Window**.
7. Select Full Stack in that new window, then verify its terminal:

```bash
git rev-parse --show-toplevel
git branch --show-current
git worktree list
```

The menu relationship is:

```text
SOURCE CONTROL REPOSITORIES
└── customer-platform                  …
    └── Worktrees
        ├── Create Worktree
        └── existing worktrees …
```

This is a schematic, not a screenshot of a specific installed build. Prompt
order can vary. The primary window remains on `main`; the new window edits
the feature branch. Git prevents one branch from being checked out twice.

Terminal alternative, which does not switch or disturb the primary checkout:

```bash
git fetch origin
git worktree add -b feature/customer-search \
  ../customer-platform.worktrees/customer-search origin/main
code --new-window --profile "Full Stack" \
  ../customer-platform.worktrees/customer-search
```

Choose either creation route, not both. Install dependencies from the lockfile
in the new worktree, recreate local-only AI files, and use distinct app ports
and Compose project names. Keep dependencies and generated Prisma clients
separate when branches differ. Leave experimental dependency-symlink reuse
unconfigured initially. Commit and integrate through your repository's PR
process; migrating uncommitted worktree changes does not merge commits.
For a complete Day One Mac walkthrough, see [VS Code worktrees](worktrees/WORKTREES-VSCODE.md).

## 9. Share project instructions, skills, and agents

Follow the maintained [procedure](PROJECT-INSTRUCTIONS-AND-SKILLS.md#9-share-project-instructions-skills-and-agents).

## 10. Choose and install project skills

Follow the maintained [procedure](PROJECT-INSTRUCTIONS-AND-SKILLS.md#10-choose-and-install-project-skills).

## 11. Configure project and global MCP servers

Follow the maintained [procedure](MCP-CONNECTIONS.md#11-configure-project-and-global-mcp-servers).
For container-managed tools, follow [Docker MCP setup](MCP-DOCKER.md), including
the VS Code configuration format and client verification steps.

## 12. Use Zsh consistently in VS Code and Warp

Follow the maintained [procedure](ZSH-AND-TERMINALS.md#12-use-zsh-consistently-in-vs-code-and-warp).

## 13. Verify, troubleshoot, and maintain the setup

### First verification

- [ ] Default still edits a normal file with native Git available.
- [ ] Full Stack selects the project's TypeScript version.
- [ ] Explicit save formats TypeScript and fixes project lint rules.
- [ ] Sort Imports keeps an intentionally unused binding; the removal shortcut
      deletes it when deliberately invoked.
- [ ] Prisma schema uses Prisma's formatter.
- [ ] Pipeline YAML shows the Azure Pipelines language mode.
- [ ] `.env.local` shows dotenv highlighting with no inline suggestions.
- [ ] Angular HTML colors match inspected scopes; Language Service diagnostics work.
- [ ] Frontend/API folders have the intended icons.
- [ ] A worktree terminal reports the intended root and branch.
- [ ] Claude skill links resolve and the reviewer is discovered.
- [ ] Each selected MCP server reports its tools and correct project context.
- [ ] No credential appears in an exported profile or shared MCP definition.

| Symptom | Next step |
|---|---|
| A setting has no effect | Check active profile, workspace/language overrides, and employer policy |
| Import sorting repeats or fights another sorter | Keep one sorter; inspect ESLint/plugin configuration |
| Imports vanish while scaffolding | Use manual removal; inspect ESLint unused-import fixers |
| `.env` colors work but variables are missing | Configure the actual app/CLI/MCP environment loader |
| An Angular token has the wrong color | Inspect token scopes; check semantic/custom palette precedence |
| NestJS folder shows a generic icon | Confirm clone base/name and actual folder name; reload icon theme |
| Framework MCP cannot find a workspace | Confirm server cwd, installed CLI support, and workspace layout |
| MCP works in Copilot but not Codex | Configure Codex TOML; do not assume JSON is automatically imported |
| Database server connects to the wrong database | Check the launching process's `DATABASE_URI`; prefer project-specific sessions |
| Skills disappear in a worktree | Recreate excluded local files or share reviewed project files in Git |
| New Claude agent is missing | Restart after creating its first directory; check symlink target and frontmatter |

Inspect/update selected skills deliberately:

```bash
npx skills@latest list
npx skills@latest list --global
npx skills@latest check
npx skills@latest update
```

Rerun the Claude link recipe for new skills. Review instructions after upgrades;
do not automatically install an entire pack to resolve one missing skill.
Update VS Code/extensions, verify changing features against the linked primary
sources, and export a reviewed profile outside this repository. Remote/Dev
Container extension installation and environment variables must be checked
in the environment where the tools actually run.

## 14. DataGrip and PostgreSQL connections

The [PostgreSQL setup guide with DataGrip and VS Code](../databases/DATAGRIP.md) owns the
shared database provisioning, role, migration and recovery procedures. For a
free desktop alternative, use the [DBeaver Community guide](../databases/DBEAVER.md), which
reuses those procedures. Add only the shared development, test and production
connections your work requires.

| Task | Instructions |
|---|---|
| Create the local database and application roles | [Local setup](../databases/POSTGRESQL.md#3-start-a-local-postgresql-server) |
| Configure DataGrip for local or remote servers | [Local connection](../databases/DATAGRIP.md#5-connect-datagrip-to-local-postgresql) · [Remote connections](../databases/DATAGRIP.md#7-connect-datagrip-to-remote-environments) |
| Configure DBeaver Community and hand off SQL files from VS Code | [DBeaver setup](../databases/DBEAVER.md) · [SQL-file handoff](../databases/DBEAVER.md#8-open-a-sql-file-from-vs-code-in-dbeaver) |
| Configure VS Code's own PostgreSQL connections | [VS Code setup](../databases/VSCODE.md#8-connect-vs-code-to-the-same-databases) |
| Set application credentials and deploy schema changes | [Applications and migrations](../databases/OPERATIONS.md#9-configure-applications-and-promote-migrations) |
| Verify access and recover data | [Session checks](../databases/OPERATIONS.md#10-use-and-verify-connections-safely) · [Backup and restore](../databases/OPERATIONS.md#11-back-up-and-rehearse-a-restore) |
| Open SQL files in DataGrip or configure MCP | [Optional handoff and AI access](../databases/DATAGRIP.md#12-optional-sql-handoff-and-ai-access) |

DataGrip, DBeaver and VS Code connect independently. Profiles and connection
colours organize work; server permissions enforce access.

---

[VS Code first launch](../apps/VSCODE.md) · [Profile setup](../apps/VSCODE-PROFILES.md) · [Worktrees](worktrees/WORKTREES-VSCODE.md) · [MCP operations](../modules/advanced/22-ai-skills-and-mcp-operations.md)
