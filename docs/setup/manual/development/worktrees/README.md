[← Advanced 18](../../../assisted/advanced/18-hosting-identities-azure-and-worktrees.md) · [AI workspaces →](../ai-workspaces.md)

# Git worktrees: choose your workflow

A worktree gives an existing Git repository several checked-out folders.
Use one for each feature, fix, review, or test run that needs separate files.
This optional task requires Git and an existing repository. Complete the setup
for your selected editor or AI client before following its worktree workflow.
Choose a workflow below.

## Choose a route

| Route | Use it when |
|---|---|
| [Git worktrees from Terminal](terminal.md) | You want explicit branches, bases, and paths for features, hotfixes, PR reviews, and tests |
| [VS Code GUI](vscode.md) | You prefer a worked GUI example with clearly marked terminal steps for reviews and tests |
| [VS Code Agents and GitHub Copilot](copilot.md) | You want agent-assisted features, fixes, reviews, and tests in VS Code |
| [Codex](codex.md) | You want app-managed isolation or Codex in a manually created worktree |
| [Claude](claude.md) | You want Claude-managed isolation or Claude in a manually created worktree |
| [Environment files and running applications](environment.md) | You need independent `.env` files, ports, databases, and dependencies |
| [Troubleshooting](troubleshooting.md) | The path, branch, environment, or cleanup is not behaving as expected |

Choose one creation route, prepare the environment before running code, then
review, integrate, and clean up through the tool that owns the worktree.
These are manual workflows using Git and the named clients; Day One Mac bundles
the instructions but does not automatically create worktrees or copy secrets.

## Keep working, then finish

- [Bring latest main into a feature worktree](terminal.md#bring-the-latest-main-into-an-active-worktree).
- [Finish through a PR](terminal.md#route-a-complete-through-a-pull-request) or [merge locally into main](terminal.md#route-b-merge-locally-into-main).
- [Pull the merged result into local main](terminal.md#pull-the-merged-result-into-local-main), then [clean up](terminal.md#safe-cleanup).

Each tool route also includes its own update and completion steps. Updating
main, updating a feature from main, and merging a feature into main are three
different operations.

## What is shared?

```text
Repository history, branches, and remotes (shared)
├── acme/                         main
├── acme.worktrees/feature-auth/   feature/auth
└── acme.worktrees/test-main/      detached snapshot

Each folder: own files, staging area, and ignored environment files
Separate configuration needed: ports, databases, containers, external services
```

## Start from main

`main` means your local branch, including local commits. `origin/main` means
its remote reference as of your last fetch. Choose deliberately: starting
from a branch does not mean checking out that same branch twice.

For a new feature, create a new branch from the chosen base. For a parallel
main test, use a detached snapshot while the primary folder remains on `main`.
Manual Git worktrees do not inherit uncommitted edits. App-managed modes can
have different starting-state options, explained on their route pages.

See the [complete main setup](terminal.md#start-from-main).

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

1. One worktree has one purpose and one checked-out branch or detached snapshot.
2. One AI client is the primary writer in a worktree.
3. Open each worktree in its own VS Code window or Warp tab.
4. Verify the path and branch before editing, committing, or pushing.
5. Use distinct ports, databases, and container project names for concurrent
   applications.
6. Remove a worktree through Git or its owning application: never Finder or
   `rm -rf`.

## Check prerequisites

```bash
git --version
code --version
# Optional, only if you use ghq:
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

Read the [Git worktree reference](https://git-scm.com/docs/git-worktree) for Git semantics.
