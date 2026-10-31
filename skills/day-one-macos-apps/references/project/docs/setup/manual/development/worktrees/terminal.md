[← Worktree overview](README.md) · [Environment files](environment.md) · [Troubleshooting](troubleshooting.md)

# Git worktrees from Terminal

Use this route for explicit control over branch, starting commit, and folder.
Read the [overview](README.md) first. The examples are
manual Git procedures; they do not run Day One Mac setup.

Before running an app or tests, follow the [environment guide](environment.md).

## Start from main

**Example:** your project is called `acme`. Its main checkout stays on `main`,
while you add login functionality in another folder. All examples below use
this same project. Replace `example/acme` with your repository owner and name;
`feature/user-auth`, `bugfix/login-error`, and folder names are examples you
can rename. PR `482` and release branch `release/1.5` must be replaced with real
values from your project.

These are shared manual Git procedures. Day One Mac does not create these
worktrees or copy environment files for you. Examples use `main`, `origin`, and
an example repository; replace them with your project's real names and path.
Run the setup below in each new terminal before using the later recipes.

```bash
REPO="$HOME/Developer/github.com/example/acme"
WORKTREE_ROOT="${REPO}.worktrees"

git -C "$REPO" status --short --branch
git -C "$REPO" worktree list --verbose
git -C "$REPO" fetch --prune origin
mkdir -p "$WORKTREE_ROOT"
```

If the primary checkout is clean and you want it on `main`, run:

```bash
git -C "$REPO" switch main
git -C "$REPO" pull --ff-only origin main
```

If it contains unfinished work, leave that checkout alone and use `origin/main`
as the base in the recipes below. Fetching updates the remote reference without
switching your files. If `main` is already checked out elsewhere, use that
existing folder instead of forcing a second checkout of the same branch.

| Starting point | Meaning |
|---|---|
| `main` | Your local branch, including local commits; it can be behind the remote |
| `origin/main` after fetch | The remote main branch as of your last fetch |
| A commit ID or release tag | A particular snapshot for a reproducible test or release fix |

Creating a new branch **from** `main` is different from checking out `main`
itself in another folder. The recipes use `origin/main` for a fresh remote
base; substitute `main` when you deliberately need its local commits.
Uncommitted edits in the primary checkout are not included either way.

```text
acme/                              main (primary checkout)
acme.worktrees/
├── feature-user-auth/             feature/user-auth
├── hotfix-payment-timeout/        hotfix/payment-timeout
├── review-pr-482/                 detached PR snapshot
└── test-main/                     detached main snapshot

Shared: Git history, branch references, remotes
Separate: checked-out files, staging area, ignored .env files
Still shared unless configured: ports, databases, external services
```

### Confirm you are starting from main

After switching and pulling in the clean primary checkout, run:

```bash
git -C "$REPO" branch --show-current
git -C "$REPO" status --short
```

Expected: the first command prints `main`; the second prints nothing for a
clean checkout. For example, the later feature command creates
`acme.worktrees/feature-user-auth` without changing the branch in `acme/`.

## Create a feature worktree

**Example:** add a login form while leaving the main checkout available for
other work. The new folder is `acme.worktrees/feature-user-auth`; its branch is
`feature/user-auth`.

After the setup above, create a new feature branch from the fetched main branch:

```bash
git -C "$REPO" worktree add --no-track \
  -b feature/user-auth \
  "$WORKTREE_ROOT/feature-user-auth" \
  origin/main
code -n "$WORKTREE_ROOT/feature-user-auth"
```

`--no-track` avoids treating `origin/main` as the feature branch's upstream.
To start from your local `main` instead, replace only the final `origin/main`
with `main`; do not run both variants with the same branch and folder names.

In the new window, configure its environment using the [environment guide](environment.md), install
its dependencies, edit, and run the project's checks. Then review and commit:

```bash
cd "$WORKTREE_ROOT/feature-user-auth"
git status --short --branch
git diff
# Stage the specific files you reviewed, then:
git diff --cached
git commit -m "Add user authentication"
git push -u origin feature/user-auth
```

Open a PR targeting `main` using your hosting provider. After it is merged,
follow **Review and integrate** and **Safe cleanup** below.

### Example: commit only the login change

Suppose you edited `src/auth/login.ts` and `tests/auth/login.test.ts` in this
example project. After running its tests, stage those exact files:

```bash
cd "$WORKTREE_ROOT/feature-user-auth"
git branch --show-current
# Expected: feature/user-auth
git add src/auth/login.ts tests/auth/login.test.ts
git diff --cached
git commit -m "Add user authentication"
git push -u origin feature/user-auth
```

These filenames illustrate a project layout; use the files you actually
changed. This is a concrete version of the commit sequence above, not a second
commit you need to make. Expected result: your remote has a
`feature/user-auth` branch ready for a PR into `main`.

## Create a hotfix or bugfix worktree

**Bugfix example:** login errors are unclear in development, so branch from
`main` and target `main` with your fix.

**Hotfix example:** production runs `release/1.5` and payments time out. Start
from that release branch, even if `main` already contains unreleased features.
If your production baseline is `main`, use `origin/main` instead in the hotfix
command below.

A normal bugfix can start from `origin/main`, just like a feature:

```bash
git -C "$REPO" fetch --prune origin
git -C "$REPO" worktree add --no-track -b bugfix/login-error \
  "$WORKTREE_ROOT/bugfix-login-error" origin/main
code -n "$WORKTREE_ROOT/bugfix-login-error"
```

For an urgent hotfix, first identify what is actually deployed. Use
`origin/main` only if it is the correct production baseline. If production uses
a release branch, use that branch; for example, after fetching it:

```bash
git -C "$REPO" worktree add --no-track -b hotfix/payment-timeout \
  "$WORKTREE_ROOT/hotfix-payment-timeout" origin/release/1.5
code -n "$WORKTREE_ROOT/hotfix-payment-timeout"
```

`origin/release/1.5` is an example and must exist. A verified release tag or
commit ID can also be the base. This leaves an unfinished feature in its own
folder untouched. Reproduce the failure, add or run the relevant regression
check, fix it, and run the project's required checks before committing.

```bash
cd "$WORKTREE_ROOT/hotfix-payment-timeout"
git status --short --branch
git diff
# Stage the reviewed fix and tests, then:
git diff --cached
git commit -m "Fix payment timeout"
git push -u origin hotfix/payment-timeout
```

Target the appropriate release branch in the PR. If it differs from `main`,
follow the project's forward-port process so `main` receives the fix too.
Creating a hotfix branch does not deploy it or update any other branch.

### Example: verify the hotfix is separate from the feature

After creating both worktrees, run:

```bash
git -C "$WORKTREE_ROOT/feature-user-auth" branch --show-current
git -C "$WORKTREE_ROOT/hotfix-payment-timeout" branch --show-current
```

Expected output, in order:

```text
feature/user-auth
hotfix/payment-timeout
```

For example, fix `src/payments/timeout.ts`, add a regression check in
`tests/payments/timeout.test.ts`, and stage those real paths before using the
hotfix commit commands. If your project uses different files, substitute them.
The feature folder's unfinished login changes remain where you left them.

## Open an existing branch

Use this instead of creating a second branch for work that already exists.
First check `git worktree list --verbose`; open the existing folder if that
branch is already checked out.

```bash
# Existing local branch; choose a folder that does not already exist.
git -C "$REPO" worktree add \
  "$WORKTREE_ROOT/existing-feature" feature/user-auth
```

If only the remote branch exists, fetch and create a local tracking branch:

```bash
git -C "$REPO" fetch --prune origin
git -C "$REPO" worktree add --track -b hotfix/payment-timeout \
  "$WORKTREE_ROOT/hotfix-payment-timeout" origin/hotfix/payment-timeout
```

Do not run this hotfix example if the previous recipe already created that
local branch.

## Review a pull request

**Example:** a teammate asks you to review PR 482, which targets `main`. You
want to run it without switching away from your login feature. `origin` must
refer to the repository where that PR was opened; if your clone uses `origin`
for your fork and `upstream` for that repository, use `upstream` in this recipe.

For GitHub PR 482, including a PR from a fork, fetch its head into a dedicated
local reference and create a detached review folder:

```bash
git -C "$REPO" fetch origin pull/482/head:refs/reviews/pr-482
git -C "$REPO" worktree add --detach \
  "$WORKTREE_ROOT/review-pr-482" refs/reviews/pr-482
code -n "$WORKTREE_ROOT/review-pr-482"
```

This [PR fetch syntax](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally)
is specific to GitHub. For another provider, use its
published PR fetch instructions, then pass the fetched commit or reference to
`git worktree add --detach`. For a same-repository branch, a freshly fetched
`origin/contributor-branch` is also a valid starting point.

Assuming the PR targets `main`, inspect it with:

```bash
cd "$WORKTREE_ROOT/review-pr-482"
git fetch origin
git rev-parse HEAD
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
```

Replace `origin/main` with the PR's actual target branch. Review the diff and
setup scripts before installing dependencies or running unfamiliar PR code.
Use disposable test credentials, then follow the test recipe below. A detached
HEAD records a snapshot without moving a local branch; it still permits edits
and commits. Create a branch before keeping review fixes:

```bash
git switch -c review/pr-482-fixes
```

If the author updates the PR, the existing folder does not update automatically.
After preserving any review edits, fetch the new head and switch only a clean,
disposable review worktree to it:

```bash
git -C "$WORKTREE_ROOT/review-pr-482" fetch origin pull/482/head
git -C "$WORKTREE_ROOT/review-pr-482" switch --detach FETCH_HEAD
```

Run those commands together: another fetch can replace `FETCH_HEAD`. Record
`git rev-parse HEAD` again and rerun relevant checks. This reviews the PR head;
it does not prove the eventual merge result passes CI.

### Example: confirm the review snapshot

```bash
git -C "$WORKTREE_ROOT/review-pr-482" status --short --branch
git -C "$WORKTREE_ROOT/review-pr-482" rev-parse --short HEAD
```

Expected: status reports detached HEAD, and the second command prints the
reviewed commit's abbreviated ID. Compare it with the PR's latest commit.
Then run the project's checks in that folder. Keep the commit ID with your
review notes so it is clear which revision you tested. These local commands do
not submit a review or approve the PR on the hosting service.

## Run tests in a separate worktree

**Example:** a test fails on your feature. Run the same test against a clean
main snapshot to check whether the failure also exists there. The two folders
need separate test configuration but should use comparable tool versions.

### Test main while continuing feature work

Keep `main` checked out in the primary folder and create a detached snapshot
for tests. This avoids Git's restriction on checking out one branch twice:

```bash
git -C "$REPO" fetch --prune origin
git -C "$REPO" worktree add --detach \
  "$WORKTREE_ROOT/test-main" origin/main
cd "$WORKTREE_ROOT/test-main"
git rev-parse HEAD
```

Use `main` instead of `origin/main` to test local main commits, or an exact
commit ID to reproduce a known result. The snapshot stays at that commit even
if `main` later moves.

### Test the feature separately

```bash
git -C "$REPO" worktree add --detach \
  "$WORKTREE_ROOT/test-user-auth" feature/user-auth
```

This includes committed feature changes only. To test uncommitted edits, run
checks inside the feature worktree itself, or commit the intended changes
before creating the test snapshot.

In each test folder, create its own environment file and install dependencies.
For a project that uses pnpm and defines a `test` script, for example:

```bash
cd "$WORKTREE_ROOT/test-main"
pnpm install --frozen-lockfile
pnpm test
```

Use the repository's actual package manager and test commands. Do not share
`node_modules` between worktrees. Give concurrent runs separate test databases,
ports, containers, coverage directories, and other writable resources.
Compare the commit IDs, exit statuses, and relevant output from both folders.
If a test snapshot reveals a fix worth keeping, create a branch there before
committing. When finished, stop test processes and remove the worktree using
the cleanup procedure below; detached test folders have no branch to delete.

### Example: compare the same test on main and the feature

For a pnpm project whose `test` script accepts a test-file argument:

```bash
cd "$WORKTREE_ROOT/test-main"
pnpm install --frozen-lockfile
pnpm test tests/auth/login.test.ts

cd "$WORKTREE_ROOT/test-user-auth"
pnpm install --frozen-lockfile
pnpm test tests/auth/login.test.ts
```

Use a test present in both revisions and the argument syntax your runner
supports. Run both commands even if the first test fails. For example:

| Main result | Feature result | What to investigate |
|---|---|---|
| Pass | Fail | Feature changes or differences in its setup |
| Fail | Fail | Existing failure, shared service, or local setup |
| Pass | Pass | The original failure may depend on other tests or conditions |

These results narrow the investigation; they do not prove the cause. A new test
that exists only on the feature cannot be run unchanged on an older main
snapshot. Run the existing suite on main and the new regression test on the
feature instead.

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

## Bring the latest main into an active worktree

**Example:** `feature/user-auth` is unfinished and teammates have merged new
changes into `main`. Keep working on your feature branch and merge the fetched
main into it. Set `REPO` and `WORKTREE_ROOT` as in **Start from main** first.

```bash
cd "$WORKTREE_ROOT/feature-user-auth"
git branch --show-current
git status --short
```

Expected: `feature/user-auth` and no pending changes. Commit your intended
work first, or deliberately stash it and restore it after the update. Do not
start a merge with unexplained local changes.

```bash
git fetch --prune origin
git merge --no-edit origin/main
```

Expected: your branch remains `feature/user-auth` and now includes main's
fetched commits. Run the required tests again, then `git push` if the feature
already has an upstream. For its first push, use
`git push -u origin feature/user-auth`.

```text
Fetch:                    remote main → local origin/main reference
Update active feature:    origin/main → feature/user-auth
Complete feature:         feature/user-auth → main (PR or local merge)
```

A plain `git pull` on the feature usually pulls its own upstream feature
branch, not `main`. Fetch alone updates references, not checked-out files.
Updating primary `main` also does not update feature worktrees automatically.
Merging preserves existing commits; use rebase only if your project requires
it and you understand its effect on already published history.

### If the merge conflicts

Run `git status`, resolve each conflicted file, stage only the resolved paths
with `git add`, inspect `git diff --cached`, and run `git merge --continue`.
Then rerun checks. To abandon this merge while it is in progress, use
`git merge --abort` in the same worktree. See the
[Git merge reference](https://git-scm.com/docs/git-merge).

Do not merge main into a detached PR-review or reproducibility-test snapshot
when you intend to preserve its exact revision. Create a separate integration
test branch if you need to test the combined result. For a release hotfix,
update from its release base rather than importing unreleased main changes.

## Choose the integration route

State one completion scope explicitly:

- PR: review and commit the feature changes, push the selected branch and open a
  PR targeting the intended base. Creating the PR does not merge it.
- Local integration: only when repository policy permits direct changes, use the
  clean checkout owning main, update it, merge the feature and run checks. Treat
  pushing main as a separate approved operation.

After a PR merge, update the checkout owning main with `git pull --ff-only origin main`.
For an app-managed checkout, use its branch/publish or handoff controls before
integration and its cleanup controls afterward. Archiving alone does not merge
code. The following walkthrough covers conflicts, squash merges and cleanup.

## Review and integrate

Completion means the intended commits have reached the target branch and any
required remote, followed by cleanup. A commit, a push, an open PR, or archiving
an AI chat alone does not complete that integration.

Before either route, commit the reviewed files and run the required checks:

```bash
cd "$WORKTREE_ROOT/feature-user-auth"
git branch --show-current
git diff --check
git status --short --branch
git log --oneline origin/main..HEAD
```

Expected: your feature branch, a clean working tree, and the intended commits.
Bring in current main using the preceding recipe if required by your project.
Choose **one** completion route below.

### Route A: complete through a pull request

1. Push from the feature worktree:

   ```bash
   git push -u origin feature/user-auth
   ```

2. Open your hosting provider's new-PR page. Set **base/target** to `main` and
   **head/source** to `feature/user-auth`. Review the diff, describe the change
   and checks, and create the PR. For GitHub, with `gh` installed and signed in,
   this opens the creation form:

   ```bash
   gh pr create --base main --head feature/user-auth --web
   ```

3. Address review comments in the same worktree, commit, rerun checks, and push.
   Those pushes update the existing PR. Wait for required reviews and CI, then
   merge using the repository's permitted merge method. Confirm its state is
   **Merged**, not merely **Closed**.
4. Update your local main using the next section, then clean up. If the PR is
   still open, keep the branch and worktree for follow-up changes.

For a hotfix, use its release branch as the target and follow the project's
forward-port process for main. See the
[GitHub PR command reference](https://cli.github.com/manual/gh_pr_create).

### Pull the merged result into local main

Use the existing checkout that owns `main`; in this example that is `REPO`.
Inspect its status first and proceed only when it is clean:

```bash
git -C "$REPO" status --short --branch
git -C "$REPO" switch main
git -C "$REPO" pull --ff-only origin main
git -C "$REPO" log -5 --oneline
```

Expected: local main includes the merged PR. If the fast-forward is refused,
stop and inspect the local/remote divergence rather than forcing a reset.
If main belongs to a different worktree, run these commands in that folder.
This also works when you only want to refresh local main without completing a
feature.

### Route B: merge locally into main

Use this only when your repository permits direct main updates. A protected
branch or team review policy requires Route A instead. First follow **Pull the
merged result into local main** above to make the clean primary main current.
Then merge the committed feature:

```bash
git -C "$REPO" merge --no-ff feature/user-auth -m "Merge feature/user-auth"
```

Resolve any conflicts in the primary checkout, using the conflict procedure
above. Run the repository's required checks **in the primary checkout**, where
the combined result now lives. Once those pass, publish if this repository has
a shared remote and direct pushes are allowed:

```bash
git -C "$REPO" push origin main
```

If rejected because remote main advanced, fetch, inspect the new commits,
integrate them according to project policy, and retest before retrying. Never
force-push main to bypass the rejection. For a purely local repository, omit
remote fetch/pull/push steps; the local merge completes integration.

Before deleting the feature branch after a normal merge, verify ancestry:

```bash
git -C "$REPO" merge-base --is-ancestor feature/user-auth main
```

Exit status zero means main contains the feature tip. Squash or rebase merges
can produce different commit IDs; verify the merged PR and resulting content
instead, and retain the branch if uncertain.

## Safe cleanup

First confirm that valuable work is committed and pushed, the branch is merged
or intentionally disposable, no useful untracked or ignored files remain (including `.env` files), and all
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

Lowercase `-d` checks merge status against the upstream, or HEAD when there
is no upstream. It is not by itself proof that a PR reached main. Verify the
integration above first. After a squash/rebase merge it may refuse deletion;
keep the branch until you have verified the PR and retained any unique work.
Do not replace it with `-D` merely to bypass the warning.

Audit stale administrative records without changing them:

```bash
git -C "$REPO" worktree prune --dry-run --verbose
```

Run `git worktree prune --verbose` only after the preview is understood.

### Example: remove completed review and test folders

After inspecting each folder for changes and useful ignored files, and stopping
its processes:

```bash
git -C "$REPO" worktree remove "$WORKTREE_ROOT/review-pr-482"
git -C "$REPO" worktree remove "$WORKTREE_ROOT/test-main"
git -C "$REPO" worktree remove "$WORKTREE_ROOT/test-user-auth"
git -C "$REPO" worktree list --verbose
```

Expected: those three paths no longer appear. Detached worktrees have no branch
to delete. A removed folder's ignored environment files are removed too; retain
any configuration you need before cleanup. The local `refs/reviews/pr-482`
reference from the fetch can remain without occupying a worktree folder.

## Warp or another terminal

Open one tab per worktree and run `git status --short --branch` before editing.
A new tab alone does not create a worktree. Start only one primary AI writer
in each folder; follow the [Codex](codex.md) or
[Claude](claude.md) route if needed.
