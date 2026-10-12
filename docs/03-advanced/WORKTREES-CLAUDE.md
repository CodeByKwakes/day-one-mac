[← Worktree overview](GIT-WORKTREES-VSCODE-AND-AI.md) · [Environment files](WORKTREES-ENVIRONMENT.md) · [Troubleshooting](WORKTREES-TROUBLESHOOTING.md)

# Git worktrees with Claude

This route covers Claude Code in a terminal. Choose a manually created folder
when you need an exact base or the sibling Day One Mac layout.

## Claude-managed worktree

From the primary repository, start a named isolated session:

```bash
cd "$HOME/Developer/github.com/example/acme"
claude --worktree auth-refactor
```

Replace the path with your repository. By default this creates
`.claude/worktrees/auth-refactor` on `worktree-auth-refactor`. Verify the base:
managed defaults and configuration can differ from your current local branch.
Use the manual route below for an explicit `origin/main`, release, or PR base.

Example prompt: “First report this worktree's path, branch, and commit. Refactor
authentication without changing behavior, and run the existing tests.”

On interactive exit, read Claude's keep/remove prompt and preserve work you
need. Keep useful ignored configuration separately before cleanup. Follow the
[official Claude worktree guide](https://code.claude.com/docs/en/worktrees)
for version-specific lifecycle details. Initialize dependencies and ignored
files using the [environment guide](WORKTREES-ENVIRONMENT.md).

## Manual worktree — recommended for this layout

```bash
REPO="$HOME/Developer/github.com/example/acme"
WORKTREE_ROOT="${REPO}.worktrees"
git -C "$REPO" fetch --prune origin
mkdir -p "$WORKTREE_ROOT"
```

Replace the example repository path before running these commands.

```bash
WORKTREE="$WORKTREE_ROOT/claude-auth-refactor"

git -C "$REPO" worktree add --no-track \
  -b claude/auth-refactor \
  "$WORKTREE" \
  origin/main

cd "$WORKTREE"
claude --permission-mode plan --name auth-refactor
```

When Git already created the worktree, run ordinary `claude` inside it. Do not
also request Claude's worktree mode, which would create a second lifecycle.

For a fix, substitute `bugfix/login-error` or `hotfix/payment-timeout`, its
folder name, and the appropriate `origin/main` or deployed release base.
For a PR or test, use the terminal snapshot recipe and run ordinary `claude`
inside that resulting folder; do not create a nested managed worktree.

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

## Example tasks

Choose the worktree and starting revision first, then give one bounded task:

| Task | Starting point | Example prompt |
|---|---|---|
| Feature | Fresh `main` | “Add login validation and its tests. Work only in this worktree. Show the diff and test results.” |
| Bugfix | Fresh `main` | “Reproduce the login error, add a regression test, and fix it. Report the root cause and checks.” |
| Hotfix | Deployed release branch or commit | “Fix the payment timeout on this release baseline. Keep the change focused and run the regression checks.” |
| PR review | Fetched PR head | “Review this commit against origin/main. Report actionable findings with file locations; do not change files or submit a review.” |
| Tests | Exact main or feature commit | “Run the documented checks here using disposable test settings. Report the commit, commands, and failures. Do not fix files yet.” |

Replace the example task and target branch with the real ones. A prompt saying
“use main” does not verify the actual starting commit. For PR and test
snapshots, create the folder with the [terminal recipes](WORKTREES-TERMINAL.md)
and open it through the manual route above. Review code before running it and
use [separate environment files and services](WORKTREES-ENVIRONMENT.md).

## Update from main and complete the work

For a manually created feature worktree, use this example prompt:

> Confirm the path and feature branch, inspect for pending changes, then fetch
> origin and merge origin/main into this feature without rewriting history.
> Stop if the worktree is dirty and explain what needs preserving. Resolve
> conflicts only when the intended behavior is clear, run the required checks,
> and report the resulting diff and commit.

See [the exact update commands](WORKTREES-TERMINAL.md#bring-the-latest-main-into-an-active-worktree).
For a managed detached worktree, create a named branch first if continuing
feature development. Keep PR review and test snapshots at their intended
revision. A release hotfix should receive its release-base updates, not
unreleased main changes.

Choose the completion instruction that matches your repository:

- **PR:** “Review and commit these changes on the feature branch, push it, and
  create a PR targeting main with the test results.” Inspect the PR and wait
  for the required checks and reviews; creating it is not merging it.
- **Local merge:** “In the clean checkout that owns main, fast-forward from
  origin/main, merge the completed feature branch, and run checks. Report the
  result before pushing main.” Use only when direct updates are allowed.

After the PR is merged, update the checkout that owns main with
`git pull --ff-only origin main`. The
[completion walkthrough](WORKTREES-TERMINAL.md#review-and-integrate) explains
verification, conflicts, squash merges, and cleanup. For an app-managed
checkout, use its branch/publish or handoff controls to preserve the work
before integration, and its worktree cleanup controls afterward. Archiving
alone does not merge code.

## Review and finish

Ask for the changed files, actual diff, test commands and results, and remaining
limitations. Inspect them yourself before committing or publishing. Integrate
through the repository's normal PR process. Do not mistake completion of an
AI task for a merge into `main`.

For a manually created folder, stop the client and use
[Git cleanup](WORKTREES-TERMINAL.md#safe-cleanup). For a tool-managed folder,
use that tool's lifecycle controls and preserve useful ignored files first.
