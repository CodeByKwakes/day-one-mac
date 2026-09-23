[← Advanced 18](18-hosting-identities-azure-and-worktrees.md) · **🤖 ⚙️ Optional worktree reference** · [AI workspaces →](../20-reference/AI-WORKSPACES.md)

# Git worktrees with VS Code and AI clients

Use this guide when work belongs to an existing Git repository and two or more
branches, reviews, or AI tasks must remain isolated. A worktree gives one
repository several checked-out folders without cloning its full Git history
again.

This is optional. Complete the required Day One Mac phases first.

## Projectless task or worktree?

| Work | Use |
|---|---|
| Standalone research or document with no repository | `_Projectless` task |
| Change to an existing repository | Worktree |
| New maintained software | Create a repository, commit a baseline, then use worktrees if needed |
| Read-only conversation with no files | Client-managed chat |

Do not copy a repository into `_Projectless`. Do not create a worktree for a
plain projectless task.

## Canonical Day One layout

Keep each manual worktree container beside its primary checkout:

```text
~/Developer/github.com/example/acme/
~/Developer/github.com/example/acme.worktrees/
├── codex-payment-timeout/
├── claude-auth-refactor/
└── review-pr-482/
```

For Azure DevOps, the same rule applies below the repository's real ghq path.
The `.worktrees` suffix is plural because the directory can hold several linked
worktrees. Keeping it under the same provider/owner prefix preserves Day One
Mac's `includeIf gitdir:` identity routing.

Tool-managed worktrees may use internal locations. If a tool created the
worktree, let that tool archive, finish, hand off, or remove it. Use the manual
layout only when you own the lifecycle.

## Core rules

1. One worktree has one branch and one purpose.
2. One AI client is the primary writer in a worktree.
3. Open each worktree in its own VS Code window or Warp tab.
4. Verify the path and branch before editing, committing, or pushing.
5. Use distinct ports, databases, and container project names for concurrent
   applications.
6. Remove a worktree through Git or its owning application—never Finder or
   `rm -rf`.

## Check prerequisites

```bash
git --version
code --version
ghq root
```

From the primary checkout:

```bash
git status --short --branch
git worktree list --verbose
git remote -v
```

Keep the primary checkout clean and on its normal integration branch whenever
practical.

## Optional VS Code user settings

Open **Preferences: Open User Settings (JSON)** and review these settings:

```jsonc
{
  "window.title": "${rootName} — ${activeEditorShort}${separator}${appName}",
  "git.detectWorktrees": true,
  "git.detectWorktreesLimit": 30,
  "scm.alwaysShowRepositories": true,
  "scm.repositories.selectionMode": "single",
  "terminal.integrated.cwd": "${workspaceFolder}",
  "terminal.integrated.splitCwd": "workspaceRoot",
  "terminal.integrated.tabs.title": "${workspaceFolderName} · ${process}",
  "terminal.integrated.tabs.description": "${cwdFolder}",
  "workbench.editor.labelFormat": "medium"
}
```

These are personal user settings, not repository settings. Do not commit them
to every project's `.vscode/settings.json`.

VS Code, GitLens, GitHub Pull Requests, or Peacock can improve visibility, but
VS Code's built-in Git support is sufficient for normal worktree operations.

## Create a feature worktree

Assume the primary checkout is:

```text
~/Developer/github.com/example/acme
```

Create a branch from an explicit, current remote base:

```bash
REPO="$HOME/Developer/github.com/example/acme"
WORKTREE_ROOT="${REPO}.worktrees"

git -C "$REPO" fetch --prune origin
mkdir -p "$WORKTREE_ROOT"

git -C "$REPO" worktree add \
  -b feature/user-auth \
  "$WORKTREE_ROOT/feature-user-auth" \
  origin/main
```

Using `origin/main` explicitly prevents the branch from silently starting at
an unrelated commit currently checked out elsewhere.

Open it in a new VS Code window:

```bash
code -n "$WORKTREE_ROOT/feature-user-auth"
```

### VS Code GUI route

1. Open the primary repository.
2. Open Source Control with `⌃⇧G`.
3. Fetch and prune the remote.
4. Open the Command Palette and run **Git: Create Worktree**, or use the
   repository's **Worktrees** menu when the installed version exposes it.
5. Select the intended starting branch.
6. Enter the new branch name.
7. Choose `<repository>.worktrees/<filesystem-safe-name>`.
8. Open the worktree in a new window.

If the installed VS Code build does not expose the expected action, use the
terminal commands. Git is authoritative.

## Existing and review branches

Add an existing local branch:

```bash
git -C "$REPO" worktree add \
  "$WORKTREE_ROOT/feature-user-auth" \
  feature/user-auth
```

Track an existing remote branch:

```bash
git -C "$REPO" worktree add \
  --track \
  -b hotfix/payment-timeout \
  "$WORKTREE_ROOT/hotfix-payment-timeout" \
  origin/hotfix/payment-timeout
```

Create a detached review worktree that cannot accidentally advance a branch:

```bash
git -C "$REPO" worktree add \
  --detach \
  "$WORKTREE_ROOT/review-pr-482" \
  origin/contributor-branch
```

If review work later needs a commit, create a branch first:

```bash
git -C "$WORKTREE_ROOT/review-pr-482" switch -c review/pr-482-fixes
```

## Files Git does not track

A worktree contains committed files. It does not automatically inherit `.env`
files, installed dependencies, local databases, build output, or other ignored
content.

Prefer a repeatable setup:

```bash
cd "$WORKTREE_ROOT/feature-user-auth"
cp .env.example .env.local
pnpm install --frozen-lockfile
pnpm test
```

VS Code can copy narrowly selected ignored files when it creates a worktree:

```jsonc
{
  "git.worktreeIncludeFiles": [
    ".env.test"
  ]
}
```

Do not copy production credentials or entire hidden directories. Reinstall
dependencies instead of copying `node_modules`.

## Verify the active worktree

Before changing or committing files, check:

```bash
printf 'root:   %s\nbranch: %s\n' \
  "$(git rev-parse --show-toplevel)" \
  "$(git branch --show-current)"

git status --short --branch
git worktree list --verbose
```

In VS Code also check the window title, Status Bar branch, Source Control
repository heading, and active integrated-terminal path. Recreate old terminal
tabs after changing the folder shown in a VS Code window.

## Codex

### Manual worktree — recommended for this layout

```bash
WORKTREE="$WORKTREE_ROOT/codex-payment-timeout"

git -C "$REPO" worktree add \
  -b codex/payment-timeout \
  "$WORKTREE" \
  origin/main

codex -C "$WORKTREE" \
  --sandbox workspace-write \
  --ask-for-approval on-request
```

For Codex GUI, open the manual worktree folder as a local project and start one
task there. Confirm the branch and directory before approving work.

### Codex-managed worktree

The Codex app can create an isolated worktree in a managed location. Choose the
repository, starting state, and Worktree environment before the first turn. Use
Codex's review, handoff, archive, and cleanup controls for that worktree. Do not
move or manually delete its directory.

## Claude Code

### Manual worktree — recommended for this layout

```bash
WORKTREE="$WORKTREE_ROOT/claude-auth-refactor"

git -C "$REPO" worktree add \
  -b claude/auth-refactor \
  "$WORKTREE" \
  origin/main

cd "$WORKTREE"
claude --permission-mode plan --name auth-refactor
```

When Git already created the worktree, run ordinary `claude` inside it. Do not
also request Claude's worktree mode, which would create a second lifecycle.

### Claude-managed worktree

Claude Code can create and manage its own worktree. Use that route only when
its managed location is acceptable, then use Claude's session/worktree cleanup
commands. Do not manually delete a Claude-owned worktree.

## VS Code Agents and GitHub Copilot

If the installed VS Code build offers worktree isolation for an agent session:

1. commit every base change the agent needs;
2. fetch the intended base branch;
3. start a new isolated session;
4. choose a new worktree rather than the active checkout;
5. verify its path with `git worktree list --verbose`;
6. give one bounded task and explicit acceptance checks;
7. review every diff and command result; and
8. integrate through a pull request or reviewed merge.

A chat or session fork that shares the same directory is not filesystem
isolation. Use separate worktrees for independent writers.

## Warp

Open one Warp tab per worktree:

```bash
cd "$WORKTREE_ROOT/codex-payment-timeout"
git status --short --branch
```

Then start exactly one writer:

```bash
codex --sandbox workspace-write --ask-for-approval on-request
```

or:

```bash
claude --permission-mode plan --name payment-timeout
```

Do not run `claude --worktree` from a worktree that Git or Warp already
created.

## Isolate running applications

Worktrees isolate files and branches, not ports, databases, containers, or
shared caches. Give each running copy distinct resources:

```bash
PORT=4101 docker compose -p acme-codex-payment up
PORT=4102 docker compose -p acme-claude-auth up
```

Where relevant, also separate database names, test output, local emulators, and
cache directories.

## Review and integrate

Before committing:

```bash
git rev-parse --show-toplevel
git branch --show-current
git diff --check
git diff --stat
git status --short --branch
```

Review the actual diff and run the repository's tests, lint, type checker,
build, or security checks. Prefer the normal pull-request process for shared
repositories.

After merging, update the primary checkout:

```bash
git -C "$REPO" switch main
git -C "$REPO" pull --ff-only
```

## Safe cleanup

First confirm that valuable work is committed and pushed, the branch is merged
or intentionally disposable, no useful untracked files remain, and all
processes using the directory have stopped:

```bash
git -C "$WORKTREE_ROOT/feature-user-auth" status --short --branch
git -C "$WORKTREE_ROOT/feature-user-auth" log --oneline --decorate -5
```

Remove the worktree through Git:

```bash
git -C "$REPO" worktree remove "$WORKTREE_ROOT/feature-user-auth"
git -C "$REPO" branch -d feature/user-auth
```

Lowercase `-d` refuses to delete an unmerged branch. Do not replace it with
`-D` merely to bypass the warning.

Audit stale administrative records without changing them:

```bash
git -C "$REPO" worktree prune --dry-run --verbose
```

Run `git worktree prune --verbose` only after the preview is understood.

## Repair and common problems

### Branch already checked out

Open the existing worktree, choose another branch, or use detached HEAD for a
review. Do not routinely bypass Git's protection with force flags.

### `.git` is a file

That is normal in a linked worktree:

```bash
cat .git
git rev-parse --git-dir
git rev-parse --git-common-dir
```

Scripts must not assume `.git` is always a directory.

### Folder was moved manually

Repair Git's record:

```bash
git -C "$REPO" worktree repair "$WORKTREE_ROOT/new-folder"
```

Prefer `git worktree move` for future moves.

### Folder was deleted manually

Preview stale-record removal:

```bash
git -C "$REPO" worktree prune --dry-run --verbose
```

### Dirty worktree will not remove

Inspect the changes and untracked files. They may be the only remaining copy of
useful work. Do not jump directly to forced deletion.

## Daily checklist 🚦

### Start work

- [ ] Open the correct worktree in its own window or tab.
- [ ] Confirm the root, branch, and status.
- [ ] Confirm which tool owns the lifecycle.
- [ ] Start only one primary writer.
- [ ] Use isolated runtime resources.

### Before integration

- [ ] Review every changed file.
- [ ] Run `git diff --check` and the repository's validation commands.
- [ ] Confirm the correct Git identity and remote.
- [ ] Commit and push the intended branch only.

### Before cleanup

- [ ] Confirm the branch is merged or intentionally disposable.
- [ ] Confirm the worktree is clean and no useful untracked file remains.
- [ ] Stop terminals, agents, servers, watchers, and containers.
- [ ] Use the owning tool or `git worktree remove`.

Official references: [Git worktree](https://git-scm.com/docs/git-worktree),
[VS Code branches and worktrees](https://code.visualstudio.com/docs/sourcecontrol/branches-worktrees),
[OpenAI projects and local Codex projects](https://learn.chatgpt.com/docs/projects),
[Claude Code CLI reference](https://code.claude.com/docs/en/cli-usage), and
[Warp worktree guidance](https://docs.warp.dev/terminal/windows/worktrees).

---

[← Advanced 18](18-hosting-identities-azure-and-worktrees.md) · [AI workspaces →](../20-reference/AI-WORKSPACES.md)
