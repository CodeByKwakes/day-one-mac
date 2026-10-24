[← Worktree overview](README.md) · [Environment files](environment.md) · [Troubleshooting](troubleshooting.md)

# Git worktrees with VS Code Agents and GitHub Copilot

Use this route for feature work, fixes, reviews, and tests with Copilot in VS
Code. Choose one creation method, then follow the task and completion steps.
These are manual workflows, not actions performed by Day One Mac setup.

## Choose where the agent works

| Method | Starting point | Who manages the folder |
|---|---|---|
| Manual worktree opened in VS Code | Explicit branch or commit selected through Git | You, using Git or VS Code's worktree commands |
| Agents window with New Worktree | Selected base branch's committed state | VS Code's agent workflow |
| Cloud target | Remote repository task returning a PR | The remote service; not your local worktree |

Current VS Code distinguishes the **Chat view**, which uses the open workspace,
from the **Agents window**, which offers **New Worktree** and a base selector.
For Copilot, managed worktree sessions use **Allow all** permissions; manually
opening a worktree as **Folder** lets you choose available approval controls.
Worktree isolation separates code, not operating-system access. Availability
and labels depend on your installed version and account. See the
[official session and isolation guide](https://code.visualstudio.com/docs/agents/run/agent-harnesses).

## Method A: open a manually created worktree

**Example:** improve Day One Mac's guide while its primary folder stays on
`main`. Replace this example clone path if yours differs. Use a new branch and
folder name if these already exist; otherwise open the existing worktree.

```bash
REPO="$HOME/Developer/Sandbox/day-one-mac"
WORKTREE_ROOT="${REPO}.worktrees"
git -C "$REPO" fetch --prune origin
mkdir -p "$WORKTREE_ROOT"
git -C "$REPO" worktree add --no-track -b feature/copilot-worktree-guide \
  "$WORKTREE_ROOT/copilot-worktree-guide" origin/main
code -n "$WORKTREE_ROOT/copilot-worktree-guide"
```

Alternatively use the [VS Code GUI walkthrough](vscode.md), replacing
its branch and folder names with the ones above.

In that new window, open Chat, select the available Copilot target and Agent
role, and start a new session. If using the Agents window, select this exact
folder and **Folder**, not another New Worktree. Ask:

> First report the working directory, branch, commit, and pending changes.
> Improve the worktree documentation with a clear login-feature example.
> Keep edits scoped to the guide, run the documentation checks defined by this
> repository, and show the diff and actual check results. Do not commit or push.

Expected: the path ends in `day-one-mac.worktrees/copilot-worktree-guide`, the
branch is `feature/copilot-worktree-guide`, and edits appear in that window's
Source Control. No `.env` file is needed for this documentation-only task.
A new chat in the original window would operate on the original folder.

## Method B: let the Agents window create the worktree

Open the Agents window, start a new session, and select your Git project.
Choose **Copilot** as the Session Target, select **New Worktree**, and choose
`main` as the base. Ensure that local main contains the commits you need before
starting. Submit the documentation prompt above, then verify the reported
worktree path and commit before reviewing edits.

Expected: a separate checkout, without switching the original folder's branch.
Uncommitted edits and ignored environment files are absent by default. If the
controls are unavailable, use Method A. This follows the
[documented VS Code isolation workflow](https://code.visualstudio.com/docs/agents/run/agent-harnesses#_choose-code-isolation).

Do not assume the generated folder or branch matches Method A's example.
Record the actual values. If the result is detached, create a named branch
before keeping new commits for a PR. A second conversation alone does not
create file isolation.

## Feature branch from main

For an application named `acme`, create `feature/user-auth` from freshly fetched
`origin/main` using the [terminal feature recipe](terminal.md#create-a-feature-worktree),
or choose current local main as the managed base. Open only that worktree.

> Implement login validation on this feature branch. First inspect existing
> conventions, propose the affected files, then implement the change and its
> regression tests. Use this worktree's development configuration. Report the
> diff, checks, and anything you could not verify.

Prepare [the environment](environment.md) before running the app.
Expected: scoped feature changes, reproducible check results, and no changes
to the primary checkout's files. Review the output before choosing a completion
route below.

## Bugfix or release hotfix

For a development bug, create `bugfix/login-error` from `origin/main`. For a
production timeout on `release/1.5`, create `hotfix/payment-timeout` from
`origin/release/1.5`. Use the [fix recipe](terminal.md#create-a-hotfix-or-bugfix-worktree)
for explicit commands, then open its folder using Method A.

> Reproduce the payment timeout on this release baseline, add a focused
> regression test, and make the smallest justified fix. Do not import main's
> unreleased features. Report the failing-before and passing-after evidence.

Replace the release name and failure with your real ones. Expected: a fix
based on the deployed release, ready for a PR targeting that release branch.
Arrange a forward-port into main through your project's normal process.

## Review a PR without changing the feature

Follow the [PR snapshot recipe](terminal.md#review-a-pull-request) for
PR 482, then open `review-pr-482` in a separate VS Code window using Method A.
Record its commit and use the actual PR target in this prompt:

> Review this PR snapshot against origin/main. Report actionable bugs with
> file locations and supporting reasoning. Do not edit files, create commits,
> or post a review. Inspect setup scripts before proposing test commands.

Use disposable test credentials if you subsequently run checks. Expected:
findings tied to the recorded revision; submitting the review is a separate
step. If you decide to implement review fixes, create a named branch before
committing. Refresh the snapshot using the terminal recipe if the PR changes.

## Test main and a feature independently

Create `test-main` and `test-user-auth` with the
[detached test recipes](terminal.md#run-tests-in-a-separate-worktree).
Open each in its own window, start one session per folder, and ask each:

> Report this folder's commit. Install dependencies using the repository's
> documented lockfile workflow and run its test command. Use this folder's
> disposable test database. Report commands, exit statuses, and failures;
> do not modify source or repair tests yet.

Configure separate [test environment files](environment.md) first.
Compare results and commit IDs. A feature snapshot includes committed changes
only. For uncommitted feature edits, test inside the feature folder itself.

## Environment files and dependencies

Git does not automatically transfer ignored `.env` files into either route.
Use the [shared environment examples](environment.md): create files
from placeholders, check ignore rules, assign distinct ports and databases,
and select the file using your application's loading mechanism.

For a managed session, use the actual worktree path reported by the agent.
Do not paste secrets into the prompt. Do not share a writable dependency or
environment folder between independent sessions. Review any configured ignored
file copying before allowing it to provision a PR-review checkout.

## Bring latest main into the active feature

Stop ongoing edits, preserve or commit the intended changes, and verify the
feature worktree is clean. In its terminal, with the feature branch selected:

```bash
git branch --show-current
git status --short
git fetch --prune origin
git merge --no-edit origin/main
```

You can ask Copilot to perform the same operation:

> Verify this is the feature worktree and it is clean. Fetch origin and merge
> origin/main into this feature without rewriting history. If it is dirty,
> stop and explain what must be preserved. Report conflicts and rerun checks.

Expected: still on the feature branch, now including main's fetched commits.
Push the updated feature after checks pass. A normal pull usually updates the
feature's own upstream, not main. Follow the [conflict procedure](terminal.md#if-the-merge-conflicts)
if needed. Keep review/test snapshots at their selected commit; update a
release hotfix from its release base instead of main.

## Complete through a PR

For Method A's documentation example:

1. Review the actual diff and check results. Stage and commit only intended files on `feature/copilot-worktree-guide`.
2. Publish that branch, or run `git push -u origin feature/copilot-worktree-guide` in its folder.
3. Create a PR with target `main` and source `feature/copilot-worktree-guide`. Include the change summary and actual checks.
4. Address feedback in the same worktree, rerun checks, and push. Wait for required reviews and CI, then merge the PR.
5. In the clean checkout that owns main, select `main` and run `git pull --ff-only origin main`.

For a managed session, publish its actual named branch, not the example name.
Creating or approving a PR is not the same as merging it. Confirm **Merged**
and verify local main includes the result before cleanup. The
[terminal completion guide](terminal.md#route-a-complete-through-a-pull-request)
includes the GitHub CLI alternative and squash-merge considerations.

## Complete with a local merge

Use only when the repository permits direct main updates. After committing and
testing the feature, switch to the clean primary checkout that owns main:

```bash
cd "$HOME/Developer/Sandbox/day-one-mac"
git switch main
git pull --ff-only origin main
git merge --no-ff feature/copilot-worktree-guide -m "Merge worktree guide improvements"
```

Substitute your clone path and actual branch. Resolve conflicts, run required
checks **here on the combined main**, then `git push origin main` if permitted.
Never force-push to bypass a rejected update. For a protected branch, use a PR.
See [local merge verification](terminal.md#route-b-merge-locally-into-main).

If a session offers to apply or migrate changes to another checkout, inspect
what it transfers. Moving uncommitted edits is not proof that commits were
merged. Verify the destination diff and Git history before deleting the source.

## Finish and clean up

For Method A, stop the agent and running processes, preserve useful ignored
files, and use [Git cleanup](terminal.md#safe-cleanup) or VS Code's
worktree deletion command. Verify the path before removal; branch deletion is
separate and should follow integration verification.

For Method B, use the session's available worktree lifecycle controls after
integration. Do not treat closing the window or archiving a chat as a merge.
If ownership or retained work is unclear, keep the folder and inspect
`git worktree list --verbose` before cleanup.

For a Cloud-target task, review and merge the returned remote PR, then pull
main locally. Local `.env` files and local worktree cleanup do not apply to its
remote environment.
