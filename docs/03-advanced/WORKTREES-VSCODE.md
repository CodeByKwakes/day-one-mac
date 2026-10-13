[← Worktree overview](GIT-WORKTREES-VSCODE-AND-AI.md) · [Environment files](WORKTREES-ENVIRONMENT.md) · [Troubleshooting](WORKTREES-TROUBLESHOOTING.md)

# Git worktrees in VS Code

Use this route to create and work with folders through VS Code's Git UI.
You need an existing Git repository and VS Code's built-in Git support.

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

## Worked example: improve Day One Mac's worktree guide

Suppose you have cloned Day One Mac into `~/Developer/Sandbox/day-one-mac`
and want to improve this guide on `feature/worktree-guide`. Substitute your
actual clone location if it differs. This walkthrough creates a branch first,
then puts it in a separate worktree; it is an alternative to the terminal
creation commands, not an additional step after them.

| Item | Example value |
|---|---|
| Primary folder | `~/Developer/Sandbox/day-one-mac` |
| Starting branch | `main` |
| New branch | `feature/worktree-guide` |
| Worktree parent | `~/Developer/Sandbox/day-one-mac.worktrees` |
| New worktree folder | `~/Developer/Sandbox/day-one-mac.worktrees/feature-worktree-guide` |
| File to edit | `docs/03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md` |

**1. Open the primary checkout and prepare the base.** In VS Code, choose
**File → Open Folder…**, then select `day-one-mac`. Open Source Control with
`⌃⇧G` and confirm it has no unfinished changes before switching branches.
If it has unfinished work, use the [terminal recipe from `origin/main`](WORKTREES-TERMINAL.md#start-from-main)
instead of disturbing that checkout.

Click the branch name in the bottom-left Status Bar and select `main`.
Use the Command Palette (`⇧⌘P`) to run **Git: Fetch**, then **Git: Pull**.
Proceed only when both succeed and there are no divergence or conflict
warnings. This walkthrough assumes local `main` has no unpublished commits;
otherwise use the [explicit `origin/main` terminal recipe](WORKTREES-TERMINAL.md#start-from-main).

**2. Create the feature branch from main.** Open the Command Palette and run
**Git: Create Branch From…**. Choose `main` as the base and enter
`feature/worktree-guide` as the new name, following the prompts' labels.
VS Code switches this primary folder onto the new branch. Before editing,
click the Status Bar branch name again and select `main`. This frees the
feature branch for use in the new worktree.

**3. Create the worktree.** In Source Control, show the **Source Control
Repositories** view. If hidden, use the Command Palette's **View: Open View…**
to find it. Select `day-one-mac`, then its **… → Worktrees → Create Worktree**
action. Choose the existing `feature/worktree-guide` branch.

For the location, use the folder-picker labels to ensure the resulting folder
is `~/Developer/Sandbox/day-one-mac.worktrees/feature-worktree-guide`. You can
create the `day-one-mac.worktrees` parent in Finder first. In a macOS folder
picker, `⇧⌘G` lets you navigate to that parent; if asked for the new folder's
name, enter `feature-worktree-guide`. Keep it beside the primary checkout.

**4. Open the new folder separately.** In the Repositories view, right-click
the new worktree and select **Open Worktree in New Window**. Alternatively,
open a new VS Code window and use **File → Open Folder…** to select the exact
worktree folder above.

The menu actions follow the
[official VS Code worktree documentation](https://code.visualstudio.com/docs/sourcecontrol/branches-worktrees#_create-a-worktree).
Prompt order and labels can vary by version. If the worktree action is absent,
use the [terminal recipe](WORKTREES-TERMINAL.md#create-a-feature-worktree) rather than an ordinary branch checkout.

**5. Verify before editing.** Expect these two windows:

```text
Window A: day-one-mac                  branch: main
Window B: feature-worktree-guide       branch: feature/worktree-guide
```

In Window B, choose **Terminal → New Terminal** and confirm:

```bash
git rev-parse --show-toplevel
git branch --show-current
```

The root should end in
`/Developer/Sandbox/day-one-mac.worktrees/feature-worktree-guide` and the branch
should be `feature/worktree-guide`. If your clone lives elsewhere, its parent
path will differ. The branch name alone does not verify the folder.

**6. Make and review the documentation change.** In Window B, press `⌘P`,
enter `docs/03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md`, and edit the guide.
Save it, then click the changed file in Source Control to inspect the diff.
Stage only that file with its **+** button. After the repository's required
checks pass, enter a message such as `docs: clarify worktree setup` and commit.
Publish the feature branch when ready, then open a PR targeting `main`.

Expected result: the edit and commit belong to `feature/worktree-guide` in
Window B. Window A stays on `main`; it receives the change only after you
integrate and update it. No `.env` file is needed for this Markdown-only
example. For an application, complete the [environment setup](WORKTREES-ENVIRONMENT.md) in Window B
before running it.

If `feature/worktree-guide` already exists, reuse it only if it is the intended
branch. If Git reports it is already checked out, open its existing worktree;
do not force another checkout. Use [Safe cleanup](WORKTREES-TERMINAL.md#safe-cleanup) after the PR is merged.

## Adapt the walkthrough for a bugfix or hotfix

For a login bug, use `bugfix/login-error`, base `main`, and folder
`bugfix-login-error`. Follow the same create-branch, switch-back, create-worktree
sequence. Your original window stays on `main`.

For a production timeout on `release/1.5`, fetch first, then choose that release
base in **Git: Create Branch From…**, name the branch `hotfix/payment-timeout`,
and return the primary window to its original branch before creating the
worktree. Use `hotfix-payment-timeout` as its folder. Confirm the PR targets the
release branch and arrange to forward-port the fix to `main`.

## Review a PR or compare tests

These recipes have an explicit **terminal step** because they need a fetched
PR reference or detached snapshot:

1. In **Terminal → New Terminal**, follow the [PR fetch and worktree recipe](WORKTREES-TERMINAL.md#review-a-pull-request), replacing its example path and PR number.
2. Open the resulting `review-pr-482` folder in a new VS Code window.
3. Inspect the diff and reviewed commit; do not expect a feature branch in a detached review folder.
4. Follow [environment setup](WORKTREES-ENVIRONMENT.md) before running the repository's checks in that window's terminal.

For a comparison, create `test-main` and `test-user-auth` using the
[terminal test recipe](WORKTREES-TERMINAL.md#run-tests-in-a-separate-worktree).
Open each folder separately, run the same supported test command in each
window, and record the commit and result. Keep their test databases separate.

## Bring main updates into the feature window

Example: Window B is on `feature/worktree-guide` and needs teammates' latest
main changes. Commit or deliberately stash its pending edits first.

1. In Window B, confirm the Status Bar shows `feature/worktree-guide`.
2. Run **Git: Fetch** from the Command Palette.
3. Run **Git: Merge…** and select `origin/main`. You stay on the feature branch.
4. Resolve any conflicts shown in Source Control, stage resolved files, and
   complete the merge commit if needed. Rerun the project's checks.
5. Push the feature branch to update its PR, or publish it for the first time.

**Git: Pull** on this window normally updates the feature's upstream; it does
not mean “bring in main”. If you need the explicit commands or want to abort a
conflicted merge, use the [terminal update procedure](WORKTREES-TERMINAL.md#bring-the-latest-main-into-an-active-worktree).

## Complete through a PR

After reviewing, testing, and committing in Window B, publish
`feature/worktree-guide`. On your provider's website, create a PR with source
`feature/worktree-guide` and target `main`. Address feedback in Window B and
push additional commits. Confirm CI and reviews, then merge the PR.

In Window A, confirm the primary folder is clean and on `main`. To pull the
result with an explicit fast-forward check, use **Terminal → New Terminal**:

```bash
git pull --ff-only origin main
```

Expected: Window A now contains the merged change. Only then clean up Window B.

## Complete with a local merge

Use this route only when direct main updates are permitted. In the clean
primary Window A on `main`, run the fast-forward pull above. Run
**Git: Merge…** and select `feature/worktree-guide`. Resolve conflicts if any,
then run the checks in Window A. Push `main` only after checks pass and when
repository policy permits it. If a push is rejected, inspect the reason rather
than force-pushing. The [terminal completion guide](WORKTREES-TERMINAL.md#route-b-merge-locally-into-main)
has explicit commands and integration verification.

## Finish and remove a worktree

Review and stage only intended files in Source Control, run required checks,
and commit on the feature or fix branch. Publish and integrate through the
repository's PR process. A local commit alone does not update `main`.

After preserving useful files, including ignored `.env` files, stop processes
and return to the primary window. Run **Git: Delete Worktree…**, check the
selected path, and remove the completed folder. Do not use **Force Delete** to
skip investigating unfinished changes. Branch deletion is separate; use the
[reviewed cleanup procedure](WORKTREES-TERMINAL.md#safe-cleanup).

## VS Code Agents and GitHub Copilot

Use the [dedicated Agents and Copilot route](WORKTREES-COPILOT.md) for manual
or agent-managed worktrees, feature and fix prompts, PR reviews, tests,
environment setup, main updates, integration, and cleanup.
