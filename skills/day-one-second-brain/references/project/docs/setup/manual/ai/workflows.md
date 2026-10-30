# AI workflows in VS Code

Set up the selected profiles through the [manual VS Code task](../editors/vscode.md). No assisted profile generator is required.

## 1. AI workflow reference

Shared settings, language formatters, environment-file behaviour, profile
colours and agent preferences are defined only in the
[main profile settings](../editors/vscode.md#3-apply-shared-user-settings).
Use its [AI overrides](../editors/vscode.md#ai-overrides) for the settings discussed
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

#### Use a daily editing and review loop

Keep Full Stack as the daily application profile and choose AI for focused
investigation, prompt authoring and review. Use Operations for its selected
infrastructure tools; a profile change does not change database credentials
or agent permissions.

1. Open the exact repository or worktree and save the relevant editor buffers.
   Expected: the editor and agent refer to the same checkout.
2. State the goal, observable success criteria and constraints. Ask for a plan
   when the change spans multiple components; keep small edits direct.
3. Let one agent edit the checkout at a time. Give independent background work
   its own worktree and open that folder when reviewing the result.
4. Inspect the diff and run the repository's required checks. Use a second
   agent for a deliberate review after editing has stopped.
5. Stage the intended scope, review the commit message and commit. Treat
   pushing, publishing and deployment as separate operations.

Keep the configured reasoning level as a starting point, then choose a higher
level in the client's supported model controls for a difficult investigation.
Use the existing Cmd+Enter, queued follow-up and inline-review preferences.
The installed Codex extension's `Cmd+Shift+Enter` shortcut can invert queue
versus steer for one in-progress follow-up. Confirm the shortcut in that
extension's settings before relying on it.
[OpenAI developer settings](https://learn.chatgpt.com/docs/developer-settings).

Before adding more extensions, inspect enablement in the running editor.
A profile can enable Copilot in settings while the current window reports it
disabled by account, policy or another control. Finish a pending extension
restart before verification. Export older profiles before retiring them, and
keep one chosen completion or commit-message tool for each role.

After changing repository recipes, regenerate the bundled packages and
[update the selected installed skill](day-one-skills.md#update-and-remove)
deliberately. A repository commit does not refresh an existing skill installation.
Keep personal extension inventories and account details outside the public guide.

#### Continue a Codex chat between VS Code and desktop

OpenAI documents shared chats and editor context when its desktop app and Codex
extension open the same project. The workflow below targets local work on one
Mac. This capability was checked against the [official IDE sync documentation](https://learn.chatgpt.com/docs/developer-settings#ide-extension-sync)
on 25 October 2026; verify it in your installed clients before relying on it.
Copilot and Claude maintain separate conversations.

Use the Codex extension (`openai.chatgpt`) in Full Stack or AI, plus the desktop
app. Keep both clients current and use the same account and workspace. The
[profile settings](../editors/vscode.md#ai-overrides) configure Cmd+Enter,
queued follow-ups and inline reviews. Those preferences do not enable chat
sharing; the extension has no separate sync switch.

1. Open the intended local project in VS Code.

   Expected result: the window uses Full Stack or AI and shows the intended
   checkout. Save relevant editor files before asking Codex to read them.

2. Run **Codex: Open Codex Sidebar** from the Command Palette.

   Expected result: the Codex panel opens. Complete sign-in if requested.

3. Start a harmless check in that panel: `Reply with continuity-check only.
   Do not use tools or change files.`

   Expected result: the reply appears in a new Codex conversation.

4. Select the same project in the desktop app.

   Expected result: its chat list includes the conversation from VS Code.

5. Open that existing conversation in the desktop app.

   Expected result: the original prompt and reply are visible. Opening a new
   conversation does not continue the existing one.

6. Send `Reply with desktop-check only. Do not use tools or change files.`
   in that conversation.

   Expected result: the follow-up appears in the same conversation in VS Code.
   Use one application at a time to submit further work.

Enable **IDE context** in the desktop composer when you want open editor files
available to Codex. This is optional context sharing. To undo that choice,
turn it off in the composer. No repository change is needed for this check.

For worktrees, open the actual worktree folder containing the task's files in
VS Code. The desktop chat's **Open** button can open its worktree in your IDE.
**Hand off** moves a chat between Local and Worktree and can change Git state;
switching applications alone does not require it.
[OpenAI worktree documentation](https://learn.chatgpt.com/docs/environments/git-worktrees).

If the conversation is missing, confirm the account, workspace and project
selection before creating another chat. Keep personal defaults in
`~/.codex/config.toml`; the app's Codex agents, CLI and extension share this
configuration. In the extension, use its gear menu, **Codex Settings → Open
config.toml**, to inspect it. [Configuration basics](https://learn.chatgpt.com/docs/config-file/config-basic),
[shared agent configuration](https://learn.chatgpt.com/docs/developer-settings#agent-configuration).

Leave `chatgpt.cliExecutable` unset; the installed extension identifies it as a
development-only override. Avoid separate `CODEX_HOME` overrides for this
workflow: the default `~/.codex` holds configuration and session state. Preserve
existing state if investigating a custom location; do not delete or merge
session stores as a troubleshooting shortcut.
[Codex environment variables](https://learn.chatgpt.com/docs/config-file/environment-variables#core-locations).

Remote SSH, Dev Containers and another Mac introduce a different execution
environment. This local check does not establish continuity for those routes.

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

Use [the shared project instructions and symlink guide](instructions-agents-skills.md#1-share-project-instructions-skills-and-agents)
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
`.agents/skills` with the [local excludes and symlinks](instructions-agents-skills.md#keep-local-project-ai-files-out-of-git). A personal skill
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

Reuse the [curated debugging and review skills](instructions-agents-skills.md#2-choose-and-install-project-skills) before writing new ones. The table describes workflows to curate; it is not a list of newly
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

Use the [MCP connection recipes](mcp.md); an AI profile needs no duplicate MCP
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
