[← Project home](../README.md) · **Reference** · [Git worktrees and AI clients](../03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md) · [AI clients →](../02-optional/10-ai-agents.md)

# AI workspaces, projectless tasks, and repository work

This guide decides where work from Codex, Claude Code, GitHub Copilot, VS Code,
Raycast AI, or another assistant belongs. Its main safety rule is simple:

> Give each client the smallest folder it needs. Never open your home folder or
> the complete `_Projectless` container merely for convenience.

## Choose the correct workspace first

Use this decision table before creating a folder:

| Situation | Correct place |
|---|---|
| Work belongs to an existing repository | A dedicated Git worktree for that repository |
| New software will be maintained and shared | A real repository created early |
| Standalone research, document, comparison, or generated artifact needs files | One immutable `_Projectless` task folder |
| A short conversation needs no local files | An application-managed chat with no local folder |
| The result is reusable knowledge | A reviewed summary in an approved vault |

Do not copy an existing repository into `_Projectless`. Use the
[worktree guide](../03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md) instead. Worktrees
provide branches, diffs, commits, tests, and safe parallel development;
projectless tasks deliberately do not.

## Keep three storage boundaries separate

| Kind | Recommended location | What belongs there |
|---|---|---|
| Client-managed state | `~/.claude`, `~/.codex`, or the client's support directory | Authentication, internal sessions, logs, caches, settings, and client metadata |
| Working files | A repository/worktree under `~/Developer/<provider>/…`, or one task below `~/Developer/_Projectless/tasks/…` | Code, analysis, supplied files, intermediate work, and deliverables |
| Curated knowledge | An approved vault below `~/Vaults` | Reviewed summaries, decisions, reusable prompts, lessons, and source notes |

Never reorganise or selectively Git-track internal files inside `~/.claude` or
`~/.codex`. Those directories are private application data, not working-note
folders.

## Recommended projectless layout

New Day One Mac tasks use stable, unique paths:

```text
~/Developer/_Projectless/
├── README.md
├── app-storage/
│   ├── codex-projectless/
│   └── claude-cowork/
├── templates/
│   ├── TASK.md
│   └── AGENTS.md
└── tasks/
    └── 2026/
        ├── 2026-09-23--164512--compare-database-clients/
        │   ├── TASK.md
        │   ├── AGENTS.md
        │   ├── CLAUDE.md -> AGENTS.md
        │   ├── input/
        │   ├── working/
        │   └── output/
        └── 2026-09-23--170103--untitled/
            └── …
```

The timestamp prevents two same-day tasks with the same title from sharing a
directory accidentally. The path does not change while the task is active.
Change `status:` in `TASK.md` instead of moving the folder between Inbox,
Active, Generated, and Archive directories.

`_Projectless` is not a Git repository. Never run `git init` at its root.
When a task becomes maintained software, promote the reviewed files to a real
provider-aware repository and use worktrees for parallel changes.

## Configure the desktop application defaults

The desktop applications distinguish their own default projectless storage
from the specific folder a task is allowed to read and change. Keep those two
concepts separate. An app-storage directory is a safe default destination; a
dated task directory is the working boundary for managed work.

Running either of these commands creates both app-storage directories:

```bash
day-one-mac workspace init
```

If the portable command is unavailable, use the direct script:

```bash
day-one-mac workspace init
```

### Codex desktop settings

Open **Settings → General** and use:

| Setting | Recommended value |
|---|---|
| Projectless task folder | `~/Developer/_Projectless/app-storage/codex-projectless` |
| Default file open destination | VS Code |
| Language | Auto detect, or the user's intended language |
| Show in menu bar | On when Codex is used frequently |
| Bottom panel | On when terminal and task progress should remain visible |
| Prevent sleep while running | Off normally; enable for a reviewed long task while connected to power |

Use the normal approval-gated permission profile. Do not grant global full
access merely to avoid prompts. Do not set the projectless default to
`~/Developer`, `_Projectless`, or the complete `tasks` directory.

For durable managed work, create the dated task first and open that individual
folder as a local Codex project. Make it the primary folder so Codex uses it as
the working directory and automatically discovers its `AGENTS.md`. A quick
conversation that needs no files should remain a Quick Chat.

### Claude Desktop and Cowork settings

The Claude **Cowork files** or **Storage folder** setting is application output
storage, not the working boundary for every task. Set it to:

```text
~/Developer/_Projectless/app-storage/claude-cowork
```

Under **Trusted Cowork folders**, do not permanently add `~/Developer`,
`~/Developer/_Projectless`, or the complete `tasks` directory. Connect only an
individual dated task when Claude needs local files. Remove completed sensitive
tasks from the trusted list when continuing access is unnecessary.

Claude Cowork folder instructions and Claude Code's `CLAUDE.md` behavior are
not identical. When using Cowork, explicitly ask it to read `TASK.md` and
`CLAUDE.md`, or copy the essential boundaries into that folder's instructions.
Claude Code automatically receives the shared instructions through the
`CLAUDE.md -> AGENTS.md` symbolic link.

Local files connected to Cowork may be processed by Anthropic's task
environment. Keep credentials, financial data, production secrets, and
unrelated company documents outside connected folders. Review
[Anthropic's current Cowork safety guidance](https://support.claude.com/en/articles/13364135-use-claude-cowork-safely)
before adding a work-confidential folder.

OpenAI's current project guidance likewise recommends granting access only to
the files a task needs and using a separate chat for each distinct outcome.
See [Projects and chats](https://learn.chatgpt.com/docs/projects).

## Create a projectless task

With the portable command installed, run it from any directory:

```bash
day-one-mac workspace --guided
```

If the portable command is unavailable, run the project script directly:

```bash
day-one-mac workspace --guided
```

The wizard asks for:

1. a plain-English title;
2. the kind of work;
3. the primary application;
4. its sensitivity; and
5. whether to open VS Code, Codex CLI, Claude Code, or nothing yet.

For repeatable terminal use:

```bash
TASK_DIR="$(day-one-mac workspace create-task \
  --title 'Compare database clients' \
  --kind research \
  --client codex \
  --sensitivity private \
  --quiet)"

printf '%s\n' "$TASK_DIR"
```

Valid kinds are `research`, `document`, `analysis`, `prototype`, and `other`.
Valid clients are `codex`, `claude`, `vscode`, and `undecided`.

## What each task file means

### `TASK.md`

This is the human-readable control record. It stores the title, status, work
kind, creation time, primary client, sensitivity, intended outcome, boundaries,
completion checks, and decisions.

Example metadata:

```yaml
---
title: Compare database clients
status: active
kind: research
created: 2026-09-23T16:45:12+0100
primary_client: codex
sensitivity: private
repository: none
---
```

### `AGENTS.md` and `CLAUDE.md`

`AGENTS.md` gives Codex persistent task-level instructions. `CLAUDE.md` is a
relative symbolic link to the same file, so Claude Code receives the same
boundaries without maintaining a second copy.

The default instructions require the client to read `TASK.md`, stay inside the
task, treat `input/` as read-only, use `working/` for intermediate files, put
reviewed deliverables in `output/`, and ask before accessing another directory.

### `input/`, `working/`, and `output/`

- `input/` contains copies of files deliberately supplied to the task. Never
  place credentials here.
- `working/` contains drafts, extracts, scripts, and other intermediate work.
- `output/` contains only reviewed deliverables ready to keep or move elsewhere.

## Recommended Codex GUI setup

For a file-based projectless task:

1. Create the task folder with `day-one-mac workspace --guided`.
2. Open Codex and start a new local task.
3. Select the individual dated folder—not `~/Developer/_Projectless`.
4. Use a local environment, not a Git worktree environment; this folder is not
   a repository.
5. Confirm the displayed working directory before approving an edit or command.
6. Start a separate Codex task for each distinct outcome.

Example folder to select:

```text
~/Developer/_Projectless/tasks/2026/
└── 2026-09-23--164512--compare-database-clients
```

Recommended first prompt:

```text
Read TASK.md and AGENTS.md before starting.

Review the material in input/ and produce the requested deliverable. Use
working/ for intermediate files and put the reviewed result in output/.
Do not access files outside this task folder. Show me your plan first.
```

Reopen the same local project when returning later. Do not copy Codex's
authentication, internal transcript store, or `~/.codex` files into the task.

If a conversation needs no files, keep it as an app-managed task without a
local directory and write only its reviewed conclusion to a vault or later
task folder.

## Recommended Codex CLI setup

Start Codex with an explicit working directory and approval boundary:

```bash
day-one-mac workspace start-codex "$TASK_DIR"
```

Equivalent direct command:

```bash
codex -C "$TASK_DIR" \
  --sandbox workspace-write \
  --ask-for-approval on-request
```

Codex treats its starting directory as the local project. `-C` (or `--cd`)
makes that boundary explicit. Run `/status` and inspect permissions before
approving work. OpenAI's current project guidance recommends separate chats for
distinct outcomes even when they share a local project.

## Recommended Claude Code setup

Start Claude in the individual task folder and begin in Plan mode:

```bash
day-one-mac workspace start-claude "$TASK_DIR"
```

Equivalent direct commands:

```bash
cd "$TASK_DIR"
claude \
  --permission-mode plan \
  --name "compare-database-clients"
```

Recommended first prompt:

```text
Read TASK.md and CLAUDE.md. Review input/ and propose a plan. Do not edit
anything until I approve the plan. Keep drafts in working/ and put the final
reviewed deliverable in output/.
```

Continue the most recent session associated with the same directory:

```bash
cd "$TASK_DIR"
claude --continue
```

Or resume its saved name:

```bash
cd "$TASK_DIR"
claude --resume compare-database-clients
```

Do not add the `_Projectless` parent with `--add-dir`. Additional-directory
access is a deliberate exception that must be justified for the individual
task.

### Claude Desktop Code view

Select the individual dated task folder for the local session. Do not ask
Claude Desktop to create a worktree for it: a projectless task is not a Git
repository. Begin with the safest available permission mode and confirm the
folder path before submitting the prompt.

## Recommended VS Code setup

Open only the individual task in a new window:

```bash
day-one-mac workspace open-vscode "$TASK_DIR"
```

Equivalent direct command:

```bash
code -n "$TASK_DIR"
```

On first open:

1. leave the task in Restricted Mode;
2. inspect `TASK.md`, `AGENTS.md`, `input/`, and any `.vscode` directory;
3. trust only the individual task when its contents are understood; and
4. never add the complete `_Projectless` parent as a trusted location by
   default.

The manager does not create `.vscode/settings.json`, tasks, or launch files for
every projectless task. Those files can run or influence tools and should be
added only when the individual task genuinely needs them.

To use VS Code as the visible editor while Codex or Claude writes, open VS Code
first and then run exactly one client from its integrated terminal.

## One active writer

The same folder may be visible in Codex, Claude, and VS Code. For any one task,
only one client should actively modify it at a time:

| Application | Recommended role |
|---|---|
| Codex or Claude Code | One primary writer |
| The other AI client | Closed or read-only second-pass reviewer |
| VS Code | Human inspection, diff review, and deliberate manual edits |

Before handing off between clients:

1. wait for the current client to finish or stop;
2. confirm no command or background process is still writing;
3. record the current result and next action in `TASK.md`; and
4. ask the next client to inspect before editing.

If two clients need competing implementations at the same time, promote the
work to a real repository and give each client a separate worktree.

## Other supported clients

### GitHub Copilot app or CLI

Add or start from the individual dated folder only. For CLI use:

```bash
cd "$TASK_DIR"
copilot
```

Confirm the current directory in the first interaction. Do not add all of
`~/Developer/_Projectless` to the Copilot app.

### Raycast AI

Use Raycast for capture, lookup, rewriting, and short research. Save valuable
output into an approved vault or an individual task. A request that must edit
several files belongs in Codex, Claude, Copilot, VS Code, or Warp with the task
folder explicitly selected.

### Warp

Warp is the terminal host, not the owner of the task. Optional Module 14 ships
workflows that call the same manager rather than reimplementing folder rules.
Use a separate Warp tab for each task.

## Inspect and finish tasks

List tasks without opening them:

```bash
day-one-mac workspace list
```

Inspect the current task:

```bash
day-one-mac workspace status
```

Mark it complete without moving its folder:

```bash
day-one-mac workspace complete "$TASK_DIR"
```

Choose one durable outcome:

| Outcome | Action |
|---|---|
| It became maintained software | Create a provider-aware repository and move only reviewed project files |
| It produced reusable knowledge | Move a reviewed summary into the approved vault |
| It produced a final document | Move the reviewed file from `output/` to its permanent location |
| It was disposable | Review it, close every client, then remove it deliberately |

Do not use `_Projectless` as a permanent backup. Include `~/Developer` in an
encrypted backup and follow employer policy for work content.

## Existing legacy layout

Older Day One versions used:

```text
00_Inbox/  01_Active/  02_Experiments/  03_Generated/  99_Archive/
```

The manager detects those folders but never moves them automatically. Moving a
live task can break client histories, saved permissions, terminal directories,
and editor state. Finish or close every associated client first, then either:

- leave the legacy task where it is and adopt a `TASK.md`; or
- create a new stable task and copy only the reviewed inputs and outputs.

## Verification checklist 🚦

- [ ] Every file-based standalone task has one unique dated folder below `tasks/<year>/`.
- [ ] Existing-repository work uses a real worktree rather than `_Projectless`.
- [ ] `AGENTS.md` exists and `CLAUDE.md` links to it.
- [ ] No client was opened against the home folder or `_Projectless` parent.
- [ ] VS Code trusts only reviewed individual tasks.
- [ ] Only one client actively writes to a task at a time.
- [ ] Credentials and private client state remain outside the task.
- [ ] Final deliverables are reviewed before leaving `output/`.

Official references: [OpenAI projects and local Codex projects](https://learn.chatgpt.com/docs/projects),
[Claude Code CLI reference](https://code.claude.com/docs/en/cli-usage),
[VS Code command-line interface](https://code.visualstudio.com/docs/configure/command-line), and
[VS Code Workspace Trust](https://code.visualstudio.com/docs/editing/workspaces/workspace-trust).

---

[← Project home](../README.md) · [Git worktrees and AI clients](../03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md) · [Configure AI clients →](../02-optional/10-ai-agents.md)
