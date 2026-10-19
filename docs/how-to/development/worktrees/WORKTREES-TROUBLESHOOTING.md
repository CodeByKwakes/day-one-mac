[← Worktree overview](GIT-WORKTREES-VSCODE-AND-AI.md) · [Environment files](WORKTREES-ENVIRONMENT.md) · [Troubleshooting](WORKTREES-TROUBLESHOOTING.md)

# Git worktree troubleshooting

Use these checks when the expected folder, branch, or environment differs.
Run them from the affected worktree unless a command specifies `git -C`.
For commands using `REPO` and `WORKTREE_ROOT`, set the paths from
[terminal setup](WORKTREES-TERMINAL.md#start-from-main) first.

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

## Environment file missing or wrong values

Check the actual worktree root, then follow the
[environment guide](WORKTREES-ENVIRONMENT.md). Ignored files are not copied by
Git. Confirm the application loads the filename you chose, and check for
exported terminal variables overriding its values. Do not print credentials.

## New worktree is missing my changes

A manually created worktree starts from committed state. Verify the base and
commit ID; uncommitted edits in another folder are not part of that commit.
Commit the intended changes or keep working in their original folder.

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
