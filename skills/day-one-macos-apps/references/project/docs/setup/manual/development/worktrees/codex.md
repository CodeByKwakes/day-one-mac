[← Worktree overview](README.md) · [Environment files](environment.md) · [Troubleshooting](troubleshooting.md)

# Git worktrees with Codex

Choose **one** route: let the app manage the worktree, or create a folder
manually and open it as a local project. Use one primary writer per folder.

## Codex-managed worktree

For example, to improve Day One Mac's guide:

1. Select the Day One Mac Git project and start a new chat.
2. Choose **Worktree** below the composer and select the intended starting branch, such as `main`.
3. Submit: “Improve the worktree documentation. First report the worktree path and starting commit, then make the documentation change and run its checks.”
4. Confirm the reported path is a separate checkout before reviewing edits.

The selected local branch may be behind its remote: fetch and update it first
when you need current `main`. App-managed worktrees can start detached; create
a branch using the app's Git controls before publishing branch-based work.
Use the app's handoff and worktree archive controls for its managed checkout.
A plain chat fork sharing a folder does not isolate files.

See [official OpenAI worktree documentation](https://learn.chatgpt.com/docs/environments/git-worktrees)
for current app behavior and setup options. Configure dependencies and local
files using the [shared environment guide](environment.md).

## Manual worktree - recommended for this layout

```bash
REPO="$HOME/Developer/github.com/example/acme"
WORKTREE_ROOT="${REPO}.worktrees"
git -C "$REPO" fetch --prune origin
mkdir -p "$WORKTREE_ROOT"
```

Replace the example repository path before running these commands.

```bash
WORKTREE="$WORKTREE_ROOT/codex-payment-timeout"

git -C "$REPO" worktree add --no-track \
  -b codex/payment-timeout \
  "$WORKTREE" \
  origin/main

codex -C "$WORKTREE" \
  --sandbox workspace-write \
  --ask-for-approval on-request
```

For Codex GUI, open the manual worktree folder as a local project and start one
task there. Confirm the branch and directory before approving work.

For the hotfix example, replace the base `origin/main` with the verified
release branch or commit. For a feature, use a new feature branch and folder.
Starting from local `main` instead of `origin/main` includes its committed
local state, not uncommitted edits.

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
snapshots, create the folder with the [terminal recipes](terminal.md)
and open it through the manual route above. Review code before running it and
use [separate environment files and services](environment.md).

## Update from main and complete the work

For a manually created feature worktree, use this example prompt:

> Confirm the path and feature branch, inspect for pending changes, then fetch
> origin and merge origin/main into this feature without rewriting history.
> Stop if the worktree is dirty and explain what needs preserving. Resolve
> conflicts only when the intended behavior is clear, run the required checks,
> and report the resulting diff and commit.

See [the exact update commands](terminal.md#bring-the-latest-main-into-an-active-worktree).
For a managed detached worktree, create a named branch first if continuing
feature development. Keep PR review and test snapshots at their intended
revision. A release hotfix should receive its release-base updates, not
unreleased main changes.

Use the shared [completion instructions](terminal.md#choose-the-integration-route)
to choose a PR or permitted local merge, update the checkout owning main and
clean up through the worktree's original owner. Archiving a client task does
not merge its code.

## Review and finish

Ask for the changed files, actual diff, test commands and results, and remaining
limitations. Inspect them yourself before committing or publishing. Integrate
through the repository's normal PR process. Do not mistake completion of an
AI task for a merge into `main`.

For a manually created folder, stop the client and use
[Git cleanup](terminal.md#safe-cleanup). For a tool-managed folder,
use that tool's lifecycle controls and preserve useful ignored files first.
