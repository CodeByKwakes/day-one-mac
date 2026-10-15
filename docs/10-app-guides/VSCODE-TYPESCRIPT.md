[← VS Code first launch](VSCODE.md) · [Profile setup](VSCODE-PROFILES.md) · [MCP module](../02-optional/11-mcp-servers.md)

# Advanced VS Code reference for TypeScript and AI workflows

**Document type:** reference with task-specific how-to recipes. **Audience:** experienced
TypeScript developers on macOS. **Last source check:** 15 October 2026.

Use this reference after [base setup](VSCODE.md) and the
[main profile guide](VSCODE-PROFILES.md). It explains optional capabilities,
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
3. [AI workflow reference](#3-ai-workflow-reference)
4. [Configure import cleanup and keyboard shortcuts](#4-configure-import-cleanup-and-keyboard-shortcuts)
5. [Edit environment files](#5-edit-environment-files)
6. [Configure Angular and NestJS folder icons](#6-configure-angular-and-nestjs-folder-icons)
7. [Configure Angular HTML highlighting](#7-configure-angular-html-highlighting)
8. [Create a native Git worktree: worked example](#8-create-a-native-git-worktree-worked-example)
9. [Share project instructions, skills, and agents](#9-share-project-instructions-skills-and-agents)
10. [Choose and install project skills](#10-choose-and-install-project-skills)
11. [Configure project and global MCP servers](#11-configure-project-and-global-mcp-servers)
12. [Use Zsh consistently in VS Code and Warp](#12-use-zsh-consistently-in-vs-code-and-warp)
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

Use [Choose and create profiles](VSCODE-PROFILES.md#1-choose-and-create-profiles)
for the manual or generated route. Default, Full Stack, AI and Operations are
available recipes, not a requirement to maintain four profiles. Profiles do
not isolate accounts, agent credentials or database permissions.

## 2. Extension capability reference

Use the [canonical extension lists](VSCODE-PROFILES.md#2-install-the-final-extension-lists)
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

Shared settings, language formatters, environment-file behaviour, profile
colours and agent preferences are defined only in the
[main profile settings](VSCODE-PROFILES.md#3-apply-shared-user-settings).
Use its [AI overrides](VSCODE-PROFILES.md#ai-overrides) for the settings discussed
below. This section describes how to use the resulting tools.

### AI profile: focused agent work and prompt authoring

Use AI for planning, investigation, reviewing diffs, maintaining skills and
preparing prompts. Keep the relevant language diagnostics enabled. Place the
active chat beside the editor/diff and run one editing agent per worktree.
Choose the intended account and permission mode in each client; switching
profiles does not isolate personal skills, MCP processes or CLI configuration.

For experiments, choose models from the actual client's model picker according
to the task and approved access. A profile does not change subscription limits
or provide credentials. Use a separate worktree for independent code changes.

#### Claude Code in the AI profile

Install the verified **Claude Code for VS Code** extension (`anthropic.claude-code`)
in **AI** if it was not included when copying Full Stack:

```bash
code --profile "AI" --install-extension anthropic.claude-code
```

Open its Spark icon or search **Claude Code** in the Command Palette, then
sign in. The current documented requirement is VS Code 1.94+ and a paid Claude
subscription or Claude Console account; managed third-party providers have
separate setup. The extension bundles the CLI for its panel. Running `claude`
in Warp or VS Code's terminal requires the separate standalone CLI install.
[Claude Code listing](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code),
[extension setup](https://code.claude.com/docs/en/vs-code).

The main guide’s AI settings give Claude its own sidebar, Cmd+Enter submission, and
**Manual** starting permissions (`default`). Use **Plan** for prompt generation
or architecture investigation, then select the appropriate editing mode when
implementing. Keep one editing agent active per worktree; use Claude for a
second review after Copilot/Codex has finished its changes.

Open-file attachment and automatic saving are off so context and saves are
explicit. Save relevant editor buffers before starting a task, then attach
files or select code deliberately. Automatic continuation after an editor
reload is also off; resume the session intentionally. Git-ignore-aware search
reduces irrelevant results but does not prevent an explicit file read.

For reusable prompts, select **Claude Code** explicitly in Good Prompts; its
automatic detection may prefer one of your other installed clients. The
extension settings in the main guide belong to **AI User Settings**. Claude's runtime
permissions, hooks, skills, and MCP configuration remain in its own supported
personal/project files and are not isolated by the VS Code profile.

Use [section 9's shared instructions and project symlinks](#9-share-project-instructions-skills-and-agents)
so Claude reads the same canonical skills and shared role policies without
maintaining duplicate content. Use its client-specific agent wrapper and MCP
configuration; do not copy Codex TOML or assume Copilot chat settings control
Claude. Verify the existing skill links through Claude's skills UI after
reloading the project.

#### Prompt builder and optional evaluation extensions

Good Prompts is recommended in **Full Stack and AI**. The two evaluation/app
tools are optional in **AI**. Marketplace names and IDs were checked in October
2026; the main profile guide owns their assignments.

| Display name | Identifier | Purpose | Recommendation and requirements |
|---|---|---|---|
| [Good Prompts](https://marketplace.visualstudio.com/items?itemName=omarbanat.goodprompts) | `omarbanat.goodprompts` | Guided forms for bug fixes, features, refactors, and reviews | Recommended in Full Stack and AI; community local template builder/scorer, with optional MCP connections |
| [Chat Customizations Evaluations](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-chat-customizations-evaluations) | `ms-vscode.vscode-chat-customizations-evaluations` | Analyze skill, agent, instruction, and prompt files | Useful when maintaining a growing library; LLM analysis needs Copilot sign-in; Waza evaluation needs its separate runtime |
| [Foundry Toolkit for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-windows-ai-studio.windows-ai-studio) | `ms-windows-ai-studio.windows-ai-studio` | Model playground, prompt-agent building, and evaluation | Add when building AI applications; formerly called AI Toolkit. Cloud features require provider/Azure access; Windows ML features are not macOS features |

Install the recommended prompt builder in both profiles; choose the evaluator
only if wanted:

```bash
code --profile "Full Stack" --install-extension omarbanat.goodprompts
code --profile "AI" --install-extension davidanson.vscode-markdownlint
code --profile "AI" --install-extension omarbanat.goodprompts
code --profile "AI" --install-extension ms-vscode.vscode-chat-customizations-evaluations
```

**Good Prompts:** run **GoodPrompts: Open Panel**, select the actual target tool,
choose a task, then enter TypeScript, your project's Node version, Angular/NestJS/Nx,
and its style rules in the panel's settings. Attach a small relevant code
selection/error and inspect the preview. Copy it into Copilot or Codex manually
first. Its settings/library use extension state, not documented
`goodprompts.*` User Settings keys. A local quality score is a heuristic, not
proof of better model results. Leave its extra MCP integration unused when
VS Code/Codex already supplies the servers.

**Chat Customizations Evaluations:** open `SKILL.md`, `*.agent.md`,
`*.instructions.md`, or `*.prompt.md`, then run **Chat Customizations Evaluations:
Analyze Prompt**. Review diagnostics in Problems. Keep tracing off for normal
use; don't install Waza just to run the initial analysis. Its LLM diagnostics
are suggestions and do not prove instruction correctness.

If installed, use these **AI User Settings**:

```json
{
  "chatCustomizationsEvaluations.enable": true,
  "chatCustomizationsEvaluations.trace.server": "off"
}
```

**Foundry Toolkit:** start with its model playground to compare a small set of
real prompts against the same examples. Configure providers through its UI
and credential flow, not a shared settings file. Avoid downloading models or
adding local runtimes until you choose that workflow. Platform support varies
by feature; the old Marketplace identifier does not mean its Windows-specific
profiling/conversion features run on your Mac.

#### Generate a good prompt with tools you already have

No generator extension is required. In Copilot's Ask/Plan mode, a Codex
read-only session, or Claude Code's Plan mode, paste this reusable prompt-builder request and your rough
task. Attach only the files and logs it needs:

```text
Turn my rough task into a practical coding-agent prompt. Do not implement it.

Use the attached code/logs and repository instructions. Separate facts from
assumptions; mark missing information rather than inventing it.

Return a concise prompt with:
- Goal and observable success criteria.
- Relevant project/worktree, framework versions, files, and current behavior.
- Desired behavior and constraints, including compatibility requirements.
- Steps to gather evidence and make the smallest appropriate change.
- Meaningful validation and the final report expected from the coding agent.

Preserve my intent. Avoid unrelated changes, broad permission requests,
invented APIs, and unnecessary dependencies. Ask only questions that materially
change the result. Include supplied error messages accurately.

Rough task: [describe the task here]
```

Inspect the generated prompt before starting an editing session. For example,
"fix the API" should become an identifiable endpoint failure with actual
request/response evidence and a testable expected result. A generator cannot
supply missing facts reliably.

#### Store personal workflows without committing repository files

For Copilot and Codex, keep portable reusable workflows as **personal skills**
in `~/.agents/skills/<skill-name>/SKILL.md`. Project-specific workflows can use
`.agents/skills` with the local excludes/symlinks in section 9. A personal skill
is available across repositories and may be selected automatically from its
description; keep the description narrowly scoped.

A useful starter library:

| Workflow | Use it for | Expected result |
|---|---|---|
| Build a task prompt | Turn rough requirements into a bounded request | Goal, context, constraints, validation, expected report |
| Investigate a TypeScript failure | Angular/Nest/Nx errors with logs | Reproduction, likely cause supported by evidence, next check |
| Review the current diff | A prepared change before committing | Concrete defects and missing coverage, with file references |
| Plan a cross-stack feature | Angular UI plus Nest API plus Prisma schema | Contracts, affected components, data changes, verification |
| Review a schema change | A proposed Prisma migration | Compatibility, data risks, deployment sequencing, rollback limits |

Reuse the verified debugging/review skills in section 10 before writing new
ones. The table describes workflows to curate; it is not a list of newly
verified Marketplace extensions or `npx` skill packages.
[Native skill locations](https://code.visualstudio.com/docs/agent-customization/agent-skills).

Current `.prompt.md` slash commands are **Local-harness-only**. If you choose
Local, run **Chat: New Prompt File**, select the **user/profile location**, and
save the prompt body there. For Copilot harness sessions, use a personal skill
or the migration UI to convert a prompt to one. Don't add deprecated
`chat.promptFilesLocations`/`chat.agentSkillsLocations` settings. Local profile
prompt files are not automatically Codex commands.
[Prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files),
[customization migration](https://code.visualstudio.com/docs/agent-customization/migrate-customizations).

#### Keep MCP and context intentional

Use the existing section 11 recipes; an AI profile needs no duplicate MCP
configuration. Start with Angular read-only MCP and Nx for this stack, Context7
when documentation is needed, and Azure DevOps when a task needs work-item or
pipeline context. Add browser/database tools for a specific investigation.
Portable global MCP configuration and personal agent configuration can be
shared across profiles; switching profiles does not stop or sandbox servers.

Attach a relevant selection, file, failure log, or diff instead of exporting
the entire repository through a context-dumping extension. Review every write
before committing, and report the tests actually run. Native Git diffs,
Problems, and terminal output provide the verification surfaces you need.

To check the profile, open the same test worktree using **AI**, run the prompt
builder without edits, review a small prepared diff, verify skill discovery,
check Claude's Plan mode and linked skills,
and confirm that no overlapping inline assistant appears. Then export the
profile as your personal baseline. Keep the main repository associated with
Full Stack; use **AI** deliberately for the agent session.

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
One setups. Resolve that through the [shared shortcut guide](KEYBOARD-SHORTCUTS.md)
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

The [canonical profile settings](VSCODE-PROFILES.md#4-apply-profile-settings)
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
manager. Use [worktree environment guidance](../03-advanced/WORKTREES-ENVIRONMENT.md)
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
For a complete Day One Mac walkthrough, see [VS Code worktrees](../03-advanced/WORKTREES-VSCODE.md).

## 9. Share project instructions, skills, and agents

### Canonical project layout

```text
project/
├── AGENTS.md
├── CLAUDE.md -> AGENTS.md
├── .agents/
│   ├── skills/<skill-name>/SKILL.md
│   ├── roles/fullstack-reviewer.md
│   └── compat/claude/fullstack-reviewer.md
├── .github/agents/fullstack-reviewer.agent.md
├── .codex/agents/fullstack-reviewer.toml
└── .claude/
    ├── skills/<skill-name> -> ../../.agents/skills/<skill-name>
    └── agents/fullstack-reviewer.md
        -> ../../.agents/compat/claude/fullstack-reviewer.md
```

Codex and current Copilot use `.agents/skills` directly. Claude gets links, not
copies. Do not add an unnecessary `.github/skills` alias. A discovery UI may
expose the same physical skill through multiple supported paths. Personal
skills under your home directory remain separate from these project skills.
[VS Code skill discovery](https://code.visualstudio.com/docs/agent-customization/agent-skills),
[Codex discovery](https://learn.chatgpt.com/docs/build-skills).

### Shared instructions

Create or merge `AGENTS.md` in the application repository, not in this setup
repository merely because you are reading the guide:

```markdown
# Project conventions

- Read package.json and the lockfile before choosing commands.
- Use the installed framework versions and repository package manager.
- Inspect Nx projects and targets before running tasks.
- Preserve Nx library boundaries, tags, and existing architecture.
- Follow the existing Angular state and form patterns.
- Preserve NestJS validation and authorization boundaries.
- Do not edit generated Prisma client files.
- Review migration SQL before applying it.
- Use project skills when their descriptions match the task.
- Run relevant checks and report actual results and limitations.
```

The link script below exposes the same file as `CLAUDE.md`. Configured Copilot
reads `AGENTS.md` directly, so a second copilot-instructions copy is unnecessary
for this local setup. Cloud workflows have their own supported instruction
locations and do not inherit untracked local files.

### One review policy, three small agent wrappers

Create `.agents/roles/fullstack-reviewer.md`:

```markdown
# Full Stack Review Policy

Review the requested changes without modifying files.
Check TypeScript correctness, Angular template/state behaviour,
NestJS validation and authorization, Nx boundaries, Prisma transactions,
migration compatibility, and relevant PostgreSQL performance concerns.
Report actionable findings with file locations and consequences.
Distinguish confirmed defects from questions.
Do not claim checks ran without execution evidence.
```

Create `.github/agents/fullstack-reviewer.agent.md` for Copilot:

```markdown
---
name: Full Stack Reviewer
description: Review Angular, NestJS, Nx, TypeScript, and Prisma changes.
tools: ['read', 'search']
---

Before reviewing, read `.agents/roles/fullstack-reviewer.md`
from the repository root and follow it. Do not modify files.
```

Confirm read/search tool sets with the selected harness's tool picker.
Create `.codex/agents/fullstack-reviewer.toml` for Codex:

```toml
name = "fullstack_reviewer"
description = "Review Angular, NestJS, Nx, TypeScript, and Prisma changes."
developer_instructions = """
Before reviewing, read .agents/roles/fullstack-reviewer.md
from the repository root and follow it. Do not modify files.
"""
```

Current Codex supports project TOML agents and inherits the parent's permissions.
Instructions do not create a separate read-only sandbox. If needed, merge this
into personal `~/.codex/config.toml`, preserving an existing agents table:

```toml
[agents]
enabled = true
max_concurrent_threads_per_session = 2
```

Create `.agents/compat/claude/fullstack-reviewer.md`:

```markdown
---
name: fullstack-reviewer
description: Review Angular, NestJS, Nx, TypeScript, and Prisma changes.
tools: Read, Grep, Glob
---

Before reviewing, read `.agents/roles/fullstack-reviewer.md`
from the repository root and follow it. Do not modify files.
```

Agent metadata is format-specific, but the review policy is maintained once.
Do not rename a Codex TOML file to Markdown and expect conversion.
[Copilot agents](https://code.visualstudio.com/docs/agent-customization/custom-agents),
[Codex agents](https://learn.chatgpt.com/docs/agent-configuration/subagents),
[Claude agents](https://code.claude.com/docs/en/sub-agents).

### Link project skills and the Claude adapter manually

Run after creating instructions/adapters and installing skills. This Bash 3.2
compatible recipe preserves existing files and differing links:

```bash
bash <<'BASH'
set -eu
task_repo_root=$(git rev-parse --show-toplevel)
cd "$task_repo_root"
mkdir -p .claude/skills .claude/agents

link_once() {
  task_link_target=$1
  task_link_path=$2
  if [ -L "$task_link_path" ]; then
    if [ "$(readlink "$task_link_path")" != "$task_link_target" ]; then
      printf 'Existing link points elsewhere: %s\n' "$task_link_path"
    fi
  elif [ -e "$task_link_path" ]; then
    printf 'Existing file/directory preserved: %s\n' "$task_link_path"
  else
    ln -s "$task_link_target" "$task_link_path"
    printf 'Linked: %s\n' "$task_link_path"
  fi
}

for task_skill_dir in .agents/skills/*; do
  [ -f "$task_skill_dir/SKILL.md" ] || continue
  task_skill_name=${task_skill_dir##*/}
  link_once "../../.agents/skills/$task_skill_name" \
    ".claude/skills/$task_skill_name"
done
if [ -f AGENTS.md ]; then
  link_once "AGENTS.md" "CLAUDE.md"
fi
if [ -f .agents/compat/claude/fullstack-reviewer.md ]; then
  link_once "../../.agents/compat/claude/fullstack-reviewer.md" \
    ".claude/agents/fullstack-reviewer.md"
fi
BASH
```

Verify a link with `readlink` and open the target through the link. Restart
Claude after creating its first agents directory and confirm reviewer discovery.
Claude explicitly documents skill-folder symlinks; agent-file symlinks rely on
filesystem behaviour and should be checked in your installed version. If an
agent link is not discovered, keep the shared policy and place the tiny adapter
directly in `.claude/agents` instead.
[Claude skill symlinks](https://code.claude.com/docs/en/skills).

To remove a known link without removing its target, use `unlink` with no trailing
slash. Never recursively delete a target directory merely to replace a link.

### Keep local project AI files out of Git

Editor User Settings need no exclusion. If project AI files should also remain
personal, open the local exclude file:

```bash
code "$(git rev-parse --git-path info/exclude)"
```

Add only the untracked personal paths you own, for example:

```gitignore
/.agents/
/.claude/skills/
/.claude/agents/
/.codex/agents/
/.github/agents/fullstack-reviewer.agent.md
/AGENTS.md
/CLAUDE.md
/skills-lock.json
/.mcp.json
/.codex/config.toml
```

Existing tracked files remain tracked. Do not hide team-owned files or overwrite
their instructions. Excluded local files do not follow a new clone/worktree;
reinstall/relink them there. Alternatively, share project AI files in Git while
keeping editor preferences personal. See [AI operations](../03-advanced/22-ai-skills-and-mcp-operations.md).

## 10. Choose and install project skills

Install a small task-relevant set, not a whole catalogue. Run the commands from
the application root. `npx skills add` is the command; there is no `npx add
skills` equivalent. Use `--agent codex github-copilot`, omit `--global` and
`--copy`, and select **Symlink** if prompted. Claude links are added by section 9.
[Skills CLI](https://github.com/vercel-labs/skills).

Sources and names were checked in the source repositories and Skills CLI.
Approximate install counts are a dated adoption signal, not a quality guarantee.
Official ownership and version fit take priority.

### Core skills

| Skill | Source / adoption at check | Why and when |
|---|---|---|
| `angular-developer` | Official Angular; about 42K | Components, signals, DI, routing, HTTP, forms, accessibility, tests; use the installed Angular version |
| `nx-workspace` | Official Nx; about 66K | Explore project graphs, targets, and conventions before monorepo changes |
| `nx-run-tasks` | Official Nx; about 3.7K | Select and run the right build/lint/test/affected targets |
| `nx-generate` | Official Nx; about 3.6K | Scaffold apps/libraries/code using repository conventions |
| `nestjs-best-practices` | Kadajett community; about 29.5K, repository about 289 stars | API architecture, DI, validation, security, testing, performance; not a NestJS-team skill |

Sources: [Angular](https://github.com/angular/skills),
[Nx workspace](https://github.com/nrwl/nx-ai-agents-config/blob/main/skills/nx-workspace/SKILL.md),
[Nx tasks](https://github.com/nrwl/nx-ai-agents-config/blob/main/skills/nx-run-tasks/SKILL.md),
[Nx generation](https://github.com/nrwl/nx-ai-agents-config/blob/main/skills/nx-generate/SKILL.md),
[NestJS](https://github.com/Kadajett/agent-nestjs-skills).

```bash
npx skills@latest add angular/skills \
  --skill angular-developer --agent codex github-copilot
npx skills@latest add nrwl/nx-ai-agents-config \
  --skill nx-workspace nx-run-tasks nx-generate --agent codex github-copilot
npx skills@latest add Kadajett/agent-nestjs-skills \
  --skill nestjs-best-practices --agent codex github-copilot
```

The older Analog Angular skill pack is deprecated; do not install it alongside
the official pack. Use Nx generation rather than Angular CLI new-app guidance
when adding another application to an existing Nx workspace.
[Analog deprecation](https://github.com/analogjs/angular-skills).

### Database skills: check Prisma's major version

| Skill | Source / adoption | Why and when |
|---|---|---|
| `prisma-client-api` | Official Prisma; about 359K | Prisma v7 query API, relations, transactions, and raw queries |
| `prisma-cli` | Official Prisma; about 357K | Prisma v7 generation, migrations, and introspection commands |
| `prisma-database-setup` | Official Prisma; about 358K | Initial database/provider configuration; optional for an established app |
| `supabase-postgres-best-practices` | Supabase-maintained; about 443K | PostgreSQL indexing, schema/query performance, and connection behaviour; apply Supabase-specific advice only when relevant |

For a compatible **Prisma 7** project:

```bash
npx skills@latest add prisma/skills \
  --skill prisma-client-api prisma-cli prisma-database-setup \
  --agent codex github-copilot
```

For PostgreSQL:

```bash
npx skills@latest add supabase/agent-skills \
  --skill supabase-postgres-best-practices --agent codex github-copilot
```

The Prisma registry explicitly distinguishes v7 skills from current
package-shipped skills. Do not apply v7 guidance unconditionally to Prisma 8.
`prisma-postgres` targets the Prisma Postgres service, not every PostgreSQL
database. [Prisma skills](https://www.prisma.io/docs/ai/tools/skills),
[PostgreSQL skill](https://github.com/supabase/agent-skills/blob/main/skills/supabase-postgres-best-practices/SKILL.md).

For a Prisma version supporting native synchronization, inspect the project's
Prisma configuration. Its `skills: { agents: ['agents'] }` option restricts
output to `.agents/skills`; `npx prisma skills sync` uses installed-package skills.
Without that option it can write multiple harness copies. This is a project
Prisma configuration change, not a VS Code setting; do not add it merely to
format a schema. [Native synchronization](https://docs.prisma.io/docs/cli/skills).

### Containers, investigation, and verification

| Skill | Source / adoption | Why and when |
|---|---|---|
| `docker-build-strategies` | Official Docker; newer pack, about 764 | Dockerfiles, multi-stage builds, caching, size, and non-root execution |
| `docker-compose-patterns` | Official Docker | Service wiring, health checks, volumes, networks, development overrides |
| `systematic-debugging` | Superpowers; about 291K | Reproduce a failure and find its cause before changing code |
| `verification-before-completion` | Superpowers | Require actual checks before reporting a fix/refactor complete |

```bash
npx skills@latest add docker/skills \
  --skill docker-build-strategies docker-compose-patterns \
  --agent codex github-copilot
npx skills@latest add obra/superpowers \
  --skill systematic-debugging verification-before-completion \
  --agent codex github-copilot
```

Sources: [Docker skills](https://github.com/docker/skills),
[Compose](https://github.com/docker/skills/blob/main/skills/docker-compose-patterns/SKILL.md),
[debugging](https://www.skills.sh/obra/superpowers/systematic-debugging),
[verification](https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md).
Check existing global skills first; skip project duplicates of the same workflow
unless you deliberately need a different version.

### Optional specialized skills

| Skill | Why and when |
|---|---|
| `typescript-advanced-types` | Complex generic/library APIs; community skill, about 87K; skip for routine CRUD |
| `playwright-cli` | Angular user-flow reproduction and browser evidence; official Microsoft tool, needs its executable/browser setup |
| `pipelines-build-summary` | Azure DevOps build/log investigation; Microsoft sample requiring an authenticated MCP server |
| `boards-work-item-summary` | Azure DevOps acceptance criteria and linked context; same MCP dependency |

```bash
npx skills@latest add wshobson/agents \
  --skill typescript-advanced-types --agent codex github-copilot
npx skills@latest add microsoft/playwright-cli \
  --skill playwright-cli --agent codex github-copilot
npx skills@latest add microsoft/azure-devops-skills \
  --skill pipelines-build-summary boards-work-item-summary \
  --agent codex github-copilot
```

Sources: [TypeScript skill](https://www.skills.sh/wshobson/agents/typescript-advanced-types),
[Playwright CLI](https://github.com/microsoft/playwright-cli),
[Azure DevOps samples](https://github.com/microsoft/azure-devops-skills).
For CLI browser workflows, install Microsoft's executable separately with
`npm install -g @playwright/cli@latest`. Do not additionally install its skill
copies if the canonical skill above is already present. Choose this workflow
or Playwright MCP based on the task; both are not required for the same test.

No special Prettier skill is needed: its executable configuration is the source
of formatting rules. Generic monorepo skills overlap the official Nx set.

## 11. Configure project and global MCP servers

MCP adds live tools and data. Skills add workflow instructions. An extension,
skill, and MCP server are different components and do not install one another.
Add only servers a real task needs. Built-in file/search/terminal tools usually
make a generic filesystem or shell MCP server redundant.

### Useful server reference

| Server | Publisher / use | Launch command or endpoint | Preferred scope / requirements |
|---|---|---|---|
| Angular CLI MCP | Official Angular; framework/project tools | `npx --no-install ng mcp --read-only` | Project; installed CLI must support `mcp`; check `npx --no-install ng mcp --help` |
| Nx MCP | Official Nx; workspace/process/docs/CI tools | `npx --no-install nx mcp` | Project; native command in Nx 21.4+; older versions use separate `nx-mcp` |
| Context7 | Upstash; current library documentation | `npx -y @upstash/context7-mcp` | Global or project; service rate limits/access can require a key; follow provider auth setup |
| Azure DevOps MCP | Microsoft; work items, PRs, builds | Copilot HTTP: `https://mcp.dev.azure.com/YOUR_ORGANIZATION`; local: `npx -y @azure-devops/mcp YOUR_ORGANIZATION` | Organization-global or project; remote Entra prerequisites; local needs Node 20+ |
| Playwright MCP | Microsoft; interactive browser tools | `npx -y @playwright/mcp@latest` | Global or project; supported Node/browser setup; distinct from Playwright CLI skill |
| Postgres MCP Pro | Crystal DBA community; SQL, schema, EXPLAIN | `uvx --python 3.12 postgres-mcp --access-mode=restricted` | Project; Python/uv, `DATABASE_URI`, database permissions; optional, not Microsoft PostgreSQL extension |
| DataGrip MCP | Built into DataGrip 2025.2+; existing database connections and IDE tools | Copy the generated client configuration from DataGrip Settings → Tools → MCP Server | Personal/global initially; local/dev/test, restricted DB role; see final setup |
| GitHub MCP | Official GitHub; GitHub PR/issues/repository context | `https://api.githubcopilot.com/mcp/` | Optional global; GitHub auth; not an Azure Repos substitute |

Sources: [Angular MCP](https://angular.dev/ai/mcp),
[Nx AI setup and MCP reference](https://nx.dev/docs/features/enhance-ai),
[Context7](https://github.com/upstash/context7),
[Azure DevOps remote](https://learn.microsoft.com/en-us/azure/devops/mcp-server/remote-mcp-server),
[Azure DevOps local](https://github.com/microsoft/azure-devops-mcp),
[Playwright MCP](https://github.com/microsoft/playwright-mcp),
[Postgres MCP Pro](https://github.com/crystaldba/postgres-mcp),
[GitHub MCP](https://github.com/github/github-mcp-server).

The Angular/Nx examples deliberately use installed binaries. Do not fetch a
new framework CLI merely because a project lacks `mcp`. Framework tools belong
to that worktree; registering them globally does not install dependencies in
every repository. Some Nx CI capabilities require Nx Cloud access.

### Understand configuration locations

| Client | Project | Personal/global |
|---|---|---|
| Copilot, current portable setup | Root `.mcp.json`, `mcpServers` object | `~/.copilot/mcp-config.json`, `mcpServers` object |
| VS Code compatibility format | `.vscode/mcp.json`, `servers` object | **MCP: Open User Configuration**, profile `mcp.json` |
| Codex extension/CLI | `.codex/config.toml`, `[mcp_servers.NAME]` tables; trusted project | `~/.codex/config.toml`; `codex mcp add` edits personal configuration |
| Claude Code | `.mcp.json`; `claude mcp add --scope project` | `~/.claude.json`; `claude mcp add --scope user` |

Current VS Code recommends the portable destinations for new servers. Profile
MCP storage is distinct from portable global storage: the latter is shared
across profiles. Root JSON can be shared by compatible Copilot/Claude clients,
but Codex uses its own TOML configuration. Do not symlink JSON to TOML.
[VS Code MCP configuration](https://code.visualstudio.com/docs/agent-customization/mcp-servers),
[Codex MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli),
[Claude scopes](https://code.claude.com/docs/en/mcp).

MCP configuration is not ordinary VS Code `settings.json`. Your preference for
User Settings covers editor settings; MCP definitions still need the client's
MCP file. Keep project configuration local through section 9's exclusions if
you do not want to commit it. Never include literal credentials in a shared file.

### Copilot and Claude: project installation

From the repository root, create or merge `.mcp.json`:

```json
{
  "mcpServers": {
    "nx": {
      "command": "npx",
      "args": ["--no-install", "nx", "mcp"]
    },
    "angular": {
      "command": "npx",
      "args": ["--no-install", "ng", "mcp", "--read-only"]
    }
  }
}
```

Include Angular only when the installed CLI supports the command and the server
recognizes your workspace. In an Nx repository without the layout Angular MCP
expects, retain Nx and use Angular documentation/skills. Do not claim all tools
work simply because the process starts.

In Copilot, run **MCP: Add Server** for other entries, choose `.mcp.json`, and
use the launch command/URL from the server table. Review/start the server through
**MCP: List Servers** and inspect its tools in the chat tool picker.

If using Claude to create the project definitions instead, these commands write
the same root file; skip them when the JSON entries already exist:

```bash
claude mcp add --scope project nx -- npx --no-install nx mcp
claude mcp add --scope project angular -- npx --no-install ng mcp --read-only
```

### Copilot: global installation

Run **MCP: Add Server**, select the command/HTTP transport, and choose **Copilot
Global**. Or merge into `~/.copilot/mcp-config.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

Add only the servers you use. These commands register launchers that download
packages when needed; they are not npm global package installations. After a
successful setup, consider replacing `@latest`/unversioned packages with reviewed
versions for reproducibility. Context7's provider offers authenticated setup and
higher limits; if authentication is required, follow its current client recipe
rather than committing a key. [Context7 clients](https://context7.com/docs/resources/all-clients).

For a profile-only server, use **MCP: Open User Configuration** and VS Code's
`servers` format instead. Do not register the same server in both global files
without an intentional scope reason.

### Codex: project and global installation

Project: merge into `.codex/config.toml`:

```toml
[mcp_servers.nx]
command = "npx"
args = ["--no-install", "nx", "mcp"]

[mcp_servers.angular]
command = "npx"
args = ["--no-install", "ng", "mcp", "--read-only"]
```

Launch from the intended worktree and verify the server's working directory.
If a server starts elsewhere, set its supported `cwd` to that checkout; a
machine-specific absolute path should remain local. Do not reuse a primary
checkout's `cwd` when working in a linked worktree.

Global: use the CLI or merge the corresponding tables into personal config:

```bash
codex mcp add context7 -- npx -y @upstash/context7-mcp
codex mcp add playwright -- npx -y @playwright/mcp@latest
codex mcp list
```

The same table syntax works in personal or project config; placement determines
scope. Do not assume `codex mcp add` creates a project definition. For HTTP
servers, use `codex mcp add NAME --url URL`; when supported, complete OAuth with
`codex mcp login NAME`. Keep credentials out of the command text and shared files.

### Claude: global installation

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
claude mcp list
```

For any other local launcher, replace the name and command/arguments using the
server reference. For a compatible HTTP server:

```bash
claude mcp add --scope user --transport http github \
  https://api.githubcopilot.com/mcp/
```

Use `--scope project` instead of `--scope user` when it should belong to that
repository. Review auth/tool status in `/mcp`; availability depends on the server
and account, not simply the command succeeding.

### Azure DevOps: remote for Copilot, local when needed

For supported Copilot accounts, add this object to the selected JSON
`mcpServers` map, replacing the organization name:

```json
{
  "ado": {
    "type": "http",
    "url": "https://mcp.dev.azure.com/YOUR_ORGANIZATION"
  }
}
```

Complete Microsoft Entra sign-in. Current documentation requires an
Entra-backed Azure DevOps Services organization; standalone Microsoft-account
organizations are not supported for the remote route. It notes remote auth
limitations for Codex and custom app-registration requirements for Claude Code.
Use local stdio when the remote route cannot authenticate. Sample skill tool
names can differ between local and remote server versions; inspect actual tools.

Codex local route, global registration:

```bash
codex mcp add ado -- npx -y @azure-devops/mcp YOUR_ORGANIZATION
```

Project equivalent in `.codex/config.toml`:

```toml
[mcp_servers.ado]
command = "npx"
args = ["-y", "@azure-devops/mcp", "YOUR_ORGANIZATION"]
```

Copilot/Claude local alternative, merge this object into `mcpServers`:

```json
{
  "ado": {
    "command": "npx",
    "args": ["-y", "@azure-devops/mcp", "YOUR_ORGANIZATION"]
  }
}
```

Authenticate using the server's supported flow. A local server still needs
organization membership and permissions; do not put a PAT into these examples.
For Claude CLI installation, use the same launcher with `--scope project` or
`--scope user`. Prefer inspecting builds/work items before enabling write tools.

### PostgreSQL: optional project connection

Since DataGrip is already installed, prefer the
[DataGrip/PostgreSQL workflow](VSCODE-PROFILES.md#6-configure-datagrip-and-postgresql-connections)
for your normal setup. The independent server below is an alternative when you
specifically need it; do not add a duplicate database MCP by default.

For ordinary manual queries, the PostgreSQL extension is sufficient. Add a
database MCP server only when an agent needs SQL/schema/plan tools.

Postgres MCP Pro is a community server. Use restricted mode and a database
account with suitable read permissions. Advanced statistics/index analysis
depends on database extensions and privileges; do not install those automatically.

Merge into project JSON's `mcpServers` map:

```json
{
  "postgres": {
    "command": "uvx",
    "args": ["--python", "3.12", "postgres-mcp", "--access-mode=restricted"]
  }
}
```

Codex project equivalent:

```toml
[mcp_servers.postgres]
command = "uvx"
args = ["--python", "3.12", "postgres-mcp", "--access-mode=restricted"]
env_vars = ["DATABASE_URI"]
```

Supply `DATABASE_URI` to the launching client through your selected private
environment/secret-manager workflow. `DATABASE_URL` used by Prisma is not
automatically `DATABASE_URI` used by this server. VS Code launched from Finder
may not inherit terminal variables; an already-running process does not gain
new variables merely because another terminal exports them. An editor's `.env`
highlighting does not load this credential. Check the server connection before
querying. Use a dedicated launch/session when projects need different databases.

For a deliberately global database connection, put the same entry in the
personal MCP file, or register the launcher with `codex mcp add postgres -- ...`
or `claude mcp add --scope user postgres -- ...`. Project scope is preferable
when the connection differs per repository. Never hard-code its password in
shared settings.

### GitHub: conditional global connection

If you also work on GitHub-hosted projects, add through **MCP: Add Server →
HTTP → Copilot Global**, or merge this into the selected map:

```json
{
  "github": {
    "type": "http",
    "url": "https://api.githubcopilot.com/mcp/"
  }
}
```

Codex equivalent: `codex mcp add github --url https://api.githubcopilot.com/mcp/`.
Use the client's supported GitHub authentication and review available tools.
For project scope, place the HTTP object in project JSON or the corresponding
`url` table in project TOML. Do not add GitHub MCP for Azure Repos alone.

## 12. Use Zsh consistently in VS Code and Warp

Use a small shared Zsh configuration: one PATH helper, one Node version
manager, persistent history, and optional Starship. Keep terminal-specific
completion and editing separate. For this stack, a shell framework such as
Oh My Zsh is optional; adding it alongside the existing Phase 5 initialization
creates extra completion and prompt ownership to resolve.

These are personal home-file and **User Settings** changes, with no project
`.vscode` files required. If Phase 5 selected chezmoi ownership, edit through
`chezmoi edit`, inspect the diff, and apply the selected file. Otherwise edit
your own home files directly. Merge the examples; do not replace your entire
configuration. See [shell ownership](../01-required/05-dotfiles-and-shell.md)
and the [reference files](../20-reference/phase-05-shell-files/README.md).

### Choose one shell executable

Apple's `/bin/zsh` is a sensible default. If you deliberately selected Homebrew
Zsh in Phase 5, use `/opt/homebrew/bin/zsh` in both applications instead. Installing
Homebrew Zsh does not automatically change either application's selected shell.
On an Intel Mac, confirm the actual Homebrew path rather than using the Apple
Silicon paths below.

In Warp, find **Default shell for new sessions** in Settings and select the same
executable. In VS Code, use the profile below. A VS Code *terminal profile*
selects a shell; Default, Full Stack, Operations, and AI *editor profiles*
select settings and extensions. They are different features.

### Put initialization in the right files

| File | Recommended responsibility |
|---|---|
| `~/.zshenv` | Leave empty or minimal; runs for non-interactive shells too. No prompt, plugin loading, output, or automatic project `.env` loading |
| `~/.zprofile` | Login environment; source the shared PATH helper |
| `~/.config/zsh/path.zsh` | Idempotent Homebrew, personal executables, and selected package-manager PATH additions |
| `~/.zshrc` | Interactive shell: source PATH helper, history, Node manager, aliases, terminal-specific completion, prompt |
| `~/.config/starship.toml` | Optional shared prompt appearance |

Zsh reads `.zprofile` for login shells and `.zshrc` for interactive shells.
Keeping PATH available through both supports Warp sessions and non-login
integrated terminals. [Zsh startup files](https://zsh.sourceforge.io/Intro/intro_3.html).

Phase 5 already supplies the shared PATH helper and source lines. Preserve
`typeset -U path PATH`, which removes duplicate PATH entries. Do not add another
`brew shellenv` or `fnm env` in several files. With the existing fnm selection,
keep its guarded `fnm env --use-on-cd --shell zsh` initialization once in
`.zshrc`; keep another selected Node manager instead if that is your setup.
Use the project's `.node-version`/`.nvmrc` policy to select Node, and confirm
`node --version` after entering each worktree. GUI-launched extensions and MCP
processes do not necessarily run `.zshrc`: a tool working in your terminal does
not prove its executable is available to the extension host.

### Configure VS Code's terminal in every editor profile

Merge into **User Settings** in Default, Full Stack, Operations, and AI. Replace
the earlier `terminal.integrated.defaultProfile.osx` value with this named
profile. The font assumes the Nerd Font selected during Day One Mac setup.

```json
{
  "terminal.integrated.profiles.osx": {
    "Zsh — development": {
      "path": "/bin/zsh",
      "args": [],
      "icon": "terminal"
    },
    "Zsh — login diagnostics": {
      "path": "/bin/zsh",
      "args": ["-l"],
      "icon": "terminal"
    }
  },
  "terminal.integrated.defaultProfile.osx": "Zsh — development",
  "terminal.integrated.shellIntegration.enabled": true,
  "terminal.integrated.inheritEnv": true,
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font, monospace",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.scrollback": 10000,
  "terminal.integrated.copyOnSelection": false,
  "terminal.integrated.enablePersistentSessions": true,
  "terminal.integrated.suggest.enabled": true,
  "terminal.external.osxExec": "Warp.app"
}
```

The normal profile uses `args: []` to avoid running macOS login PATH setup
again for every integrated terminal. This depends on sourcing the PATH helper
from `.zshrc`. The second profile is for comparing login behavior. VS Code
also resolves a login-shell environment when it starts; keep startup output
quiet and initialization repeatable.
[Terminal profiles and macOS PATH behavior](https://code.visualstudio.com/docs/terminal/profiles).

Automatic shell integration enables command boundaries, working-directory
tracking, and exit-status decorations. Let VS Code inject it; do not also
source it unconditionally in `.zshrc`. If detection fails, follow the official
manual fallback and restrict it to VS Code so it never runs in Warp.
[Shell integration](https://code.visualstudio.com/docs/terminal/shell-integration).

Persistent sessions help retain terminal state across editor reloads. Always
check `pwd` before an agent session; retention does not select the correct
worktree for you. `copyOnSelection: false` avoids replacing the clipboard
when selecting logs. Terminal suggestions are built into VS Code; no terminal
suggestion extension is required. If its dropdown competes with your shell's
grey suggestions, choose one: keep the dropdown and omit `zsh-autosuggestions`,
or set `terminal.integrated.suggest.enabled` to `false` in User Settings and
keep the shell plugin. Phase 7's baseline enables the dropdown.

`terminal.external.osxExec` selects Warp for **Open New External Terminal**
(**Shift+Cmd+C**). Warp remains a separate application; it does not replace
the integrated terminal or render inside it. If launching from a folder does
not preserve that folder on your Warp version, open Warp and explicitly
`cd` there. [VS Code terminal basics](https://code.visualstudio.com/docs/terminal/basics).

### Keep Warp's completion separate from Zsh plugins

Warp lists shell completion hooks, `compinit`, `zsh-autosuggestions`, some
custom keybindings, and other integrations as potential compatibility issues.
Use Warp's native completions and history suggestions there. For the shared
configuration, exclude completion and Zsh line-editor plugins from Warp using
its documented `TERM_PROGRAM=WarpTerminal` detection. This is a conservative
compatibility choice, not a claim that every plugin fails on every version.
[Warp known issues](https://docs.warp.dev/support-and-community/troubleshooting-and-support/known-issues).

Optional installation, if you want these features in VS Code and conventional
terminals:

```bash
brew install zsh-completions zsh-autosuggestions zsh-syntax-highlighting
```

In `.zshrc`, **replace the existing completion/plugin blocks** with the guarded
versions below. Keep your existing PATH, history, fnm, and aliases blocks.
Do not append a second `compinit` or second plugin source line. This example
uses Apple Silicon Homebrew paths; adapt to your installation.

```zsh
# Completion belongs before the Node-manager and prompt initialization.
if [[ ${TERM_PROGRAM:-} != WarpTerminal ]]; then
  for completion_dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do
    [[ -d $completion_dir ]] || continue
    (( ${fpath[(Ie)$completion_dir]} )) || fpath=("$completion_dir" $fpath)
  done
  unset completion_dir
  autoload -Uz compinit
  compinit
fi

# Keep the existing fnm and aliases initialization here.

if [[ ${TERM_PROGRAM:-} != WarpTerminal ]]; then
  if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    ZSH_AUTOSUGGEST_STRATEGY=(history)
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  fi
fi

# Keep this once if Starship was selected; otherwise omit it.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Last plugin integration, after prompt setup and custom ZLE widgets.
if [[ ${TERM_PROGRAM:-} != WarpTerminal ]]; then
  if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  fi
fi
```

History-only autosuggestions avoid an extra completion strategy. Syntax
highlighting must follow your widget definitions. Preserve existing Docker
completion directories inside the non-Warp completion block.
[Autosuggestions configuration](https://github.com/zsh-users/zsh-autosuggestions),
[syntax-highlighting loading order](https://github.com/zsh-users/zsh-syntax-highlighting).

Keep Phase 5's persistent history settings, once near the top of `.zshrc`:

```zsh
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
```

This shares recent commands across interactive terminals, reduces duplicate
entries, and lets you inspect a history expansion before running it. If you
prefer arrows to browse only
commands from the current terminal, replace `SHARE_HISTORY` with
`INC_APPEND_HISTORY`; don't enable both. `HIST_IGNORE_SPACE` is an optional
addition that excludes commands beginning with a space from saved history,
but does not prevent other logging. Avoid putting credentials directly into
commands or automatically sourcing every project's `.env` at shell startup.
[Zsh history options](https://zsh.sourceforge.io/Doc/Release/Options.html#History).

### Choose a prompt for Warp

For a consistent Git/Node prompt, retain Starship and select **Shell (PS1)** in
Warp. Merge this optional small configuration into `~/.config/starship.toml`,
updating existing keys rather than duplicating TOML tables:

```toml
add_newline = false
command_timeout = 1000
format = "$directory$git_branch$git_status$nodejs$cmd_duration$line_break$character"

[directory]
truncation_length = 3
truncate_to_repo = true

[line_break]
disabled = false

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

The prompt shows directory, Git branch/status, Node when relevant, and slow
command duration. The line break gives input its own line; the timeout also
keeps potentially slow Git checks bounded. Large Nx repositories can still
make Git status expensive: disable `[git_status]` if measurements show it is
the bottleneck. [Starship configuration](https://starship.rs/config/).

Use JetBrainsMono Nerd Font in Warp too. Warp documents Starship support with
caveats. Try its native prompt if blocks or agent input behave oddly. If you
prefer Warp's native prompt permanently, guard Starship initialization with
`[[ ${TERM_PROGRAM:-} != WarpTerminal ]]` as well. Add Warp's documented Zsh
newline workaround only if the normal Starship line break fails; do not stack
newline fixes preemptively. Settings labels can move between releases.
[Warp prompt compatibility](https://docs.warp.dev/terminal/appearance/prompt).

### Use terminal shortcuts deliberately

| Action | VS Code on macOS | Warp / shell guidance |
|---|---|---|
| Show integrated terminal | **Ctrl+`** | Warp is a separate app; use your macOS app-switch shortcut |
| New integrated terminal | **Ctrl+Shift+`** | Use Warp's new-tab action; inspect its Keyboard Shortcuts settings |
| Open external terminal | **Shift+Cmd+C** | Opens Warp when configured above |
| Terminal suggestions | **Ctrl+Space** | Use Warp's completion UI; don't bind Tab to `autosuggest-accept` |
| Accept history suggestion | **Right Arrow** with the shell plugin | Right Arrow at the end of input with Warp autosuggestions |
| Search shell history | **Ctrl+R** in a conventional Zsh terminal | Use Warp's history search; its input editor owns key handling |
| Stop foreground command | **Ctrl+C** | **Ctrl+C** |
| End input / exit idle shell | **Ctrl+D** | Behavior depends on focused input and Warp keybindings |

Don't add a universal `bindkey '^J' ...`: Warp flags that binding as a possible
cause of needing Enter twice. Keep custom ZLE bindings in the same non-Warp
guard as plugins. Don't set `terminal.integrated.sendKeybindingsToShell: true`
just to resolve one key conflict; inspect VS Code's Keyboard Shortcuts editor
and change the individual binding instead.
[Warp autosuggestions](https://docs.warp.dev/terminal/command-completions/autosuggestions).

### Verify the same project in both applications

Open a **new** VS Code terminal and Warp tab, then enter the same repository or
worktree. Run these Zsh commands in each:

```zsh
printf 'zsh=%s terminal=%s login=%s interactive=%s\n' "$ZSH_VERSION" "${TERM_PROGRAM:-unknown}" "$options[login]" "$options[interactive]"
pwd
type -a node pnpm git
node --version
pnpm --version
print -l -- $path
```

`echo "$SHELL"` reports the configured login-shell preference; it does not
prove which executable the current terminal is running. Compare the versions,
PATH order, working directory, and selected shell path instead. Use terminal
tabs for Angular, NestJS, and one-shot checks; open an additional agent tab
from the specific worktree. Warp's AI account remains separate from Codex and
GitHub Copilot authentication.

If startup is slow, compare `time /bin/zsh -i -c exit` with
`time /bin/zsh -f -i -c exit` (use your selected executable). The latter skips
user RC initialization for diagnosis, not daily development. A temporarily
added `zmodload zsh/zprof` near the top of `.zshrc` and `zprof` at the bottom
can identify costly functions; remove both after measuring. Do not bypass
completion security checks with `compinit -u`; repair the reported ownership
or permissions instead.
[Completion security checks](https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit).
Start with the existing
[Warp troubleshooting guide](WARP.md#troubleshooting) for app-specific issues.

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

Use DataGrip for substantial database work and Microsoft's PostgreSQL extension
for in-editor browsing. Both connect to the same servers independently; saved
connections, passwords, and SSH tunnels do not automatically synchronize.
Use the approved DataGrip version installed on your Mac.

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

If you install Switch to DataGrip, set its User Settings to the actual application path. For an app installed
in the system Applications folder, the example is:

```json
{
  "switch2datagrip.dataGripPath": "/Applications/DataGrip.app"
}
```

Open the intended DataGrip project first, then use **Open in DataGrip** from
VS Code's editor context menu. This opens the file in DataGrip; it does not
mirror its database tree. Avoid its default Cmd+Shift+D if it conflicts with
VS Code's debugging shortcut.
[Extension listing](https://marketplace.visualstudio.com/items?itemName=MaxPowerEngine.switch2datagrip).

---

[VS Code first launch](VSCODE.md) · [Profile setup](VSCODE-PROFILES.md) · [Worktrees](../03-advanced/WORKTREES-VSCODE.md) · [MCP operations](../03-advanced/22-ai-skills-and-mcp-operations.md)
