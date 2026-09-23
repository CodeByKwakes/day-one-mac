[← Advanced 17](17-shell-and-package-automation.md) · **🤖 ⚙️ Advanced 18** · [Advanced 19 →](19-macos-gui-and-local-https.md)

# Advanced 18 — Hosting identities, Azure DevOps, and worktrees

**Time:** 45–120 minutes · **Required:** no · **Prerequisite:** required Phase 4

## Outcome

Repositories live in a provider-aware ghq layout, Git chooses the correct
identity from the checkout path, selected hosting CLIs have explicit defaults,
and concurrent branch work uses safe Git worktrees without duplicating Git
history or secrets.

## Choose only the route you need

This module contains two independent upgrades. They may be completed and
checked separately:

| Route | Read these steps | Choose it when |
|---|---|---|
| Multiple Git identities and hosting defaults | 18.1–18.5 | One Mac commits with more than one email or needs Azure defaults |
| Concurrent branch work with Git worktrees | 18.6 onward | You actively need two checked-out branches of one repository at the same time |

Completing the identity route does not require worktrees. Using worktrees does
not require a secondary email. Mark the whole advanced module complete only
after every route you chose has passed its own checks; leave the other route
explicitly recorded as not selected.

## Step 18.1 — Confirm the selected track

```bash
day-one-mac --status
ghq root
git config --global --get user.name
git config --global --get user.email
```

Track meanings in this project are:

```text
Track 1  GitHub
Track 2  Azure DevOps
Track 3  GitHub + Azure DevOps
```

Do not install or authenticate a second provider merely because its commands
appear below. Track 1 skips Azure sections; Track 2 skips GitHub repository
sections; Track 3 completes both.

## Step 18.2 — Use a predictable ghq layout

The required base configures `~/Developer` as `ghq.root`. Clone through ghq:

```bash
ghq get git@github.com:<owner>/<repository>.git
ghq get <azure-ssh-url>
ghq list
```

Expected paths have provider and owner components, for example:

```text
~/Developer/github.com/personal-account/project
~/Developer/github.com/work-organisation/project
~/Developer/ssh.dev.azure.com/v3/organisation/project/repository
```

This layout is the input to identity routing; manually moving a repository to
an arbitrary directory can change which Git identity applies.

## Step 18.3 — Add a secondary identity only when needed

The primary global identity remains a safe fallback. If one Mac genuinely uses
both personal and work email addresses, create a secondary target:

```ini
[user]
    name = Your Name
    email = secondary@example.com
```

Store it as `~/.gitconfig-secondary`, add it to chezmoi as a template when the
email differs by machine, and route only a specific directory prefix from the
main `.gitconfig`:

```ini
[includeIf "gitdir:~/Developer/github.com/work-organisation/"]
    path = ~/.gitconfig-secondary
```

For Azure, route the exact ghq prefix produced on this Mac rather than guessing
it. Inspect first:

```bash
ghq list | rg 'azure|visualstudio|ssh.dev.azure'
```

The more specific include should appear after general configuration. Never
route by branch name or remote text; `includeIf gitdir:` is based on the local
checkout path and works offline.

Verify from real repositories:

```bash
git -C <personal-repository> config user.email
git -C <work-repository> config user.email
git -C <personal-repository> config --show-origin --get user.email
git -C <work-repository> config --show-origin --get user.email
```

## Step 18.4 — Keep provider authentication separate

### Track 1 or 3 — GitHub

```bash
gh auth status
gh config get git_protocol
ssh -T git@github.com
```

The SSH test normally reports successful authentication and no shell access.
In the default `1password` authentication mode the agent supplies the private
identity, and no private key should be
copied into `~/.ssh`.

### Track 2 or 3 — Azure DevOps 🏢

```bash
az account show --output table
az extension show --name azure-devops
ssh -T git@ssh.dev.azure.com
```

Configure defaults explicitly for the current organisation and project:

```bash
az devops configure --defaults \
  organization=https://dev.azure.com/<organisation> \
  project=<project>
az devops configure --list
```

Do not commit organisation URLs or project names into public dotfiles when they
identify a private employer. Put them in machine-local chezmoi data or an
untracked work-specific include.

## Step 18.5 — Verify signing and allowed signers

If commits are signed through the 1Password SSH key, the Git settings are:

```ini
[gpg]
    format = ssh
[commit]
    gpgsign = true
[gpg "ssh"]
    allowedSignersFile = ~/.config/git/allowed_signers
```

The allowed-signers line contains an email/principal followed by the public
key—not a private key. Create a disposable signed commit:

```bash
test_root="$(mktemp -d)"
git -C "$test_root" init
printf 'signing test\n' > "$test_root/check.txt"
git -C "$test_root" add check.txt
git -C "$test_root" commit -m "test: verify SSH signing"
git -C "$test_root" log --show-signature -1
```

Remove the disposable directory after inspection.

## Step 18.6 — Add Azure repository and pipeline helpers 🏢

Use explicit commands before creating aliases:

```bash
az repos list --output table
az repos pr list --status active --output table
az pipelines runs list --top 10 --output table
az devops project list --output table
```

Repository-owned pipeline configuration belongs in the repository. A minimal
Node validation pipeline can use the project's declared Node/package manager
instead of versions from this playbook:

```yaml
trigger:
  - main

pool:
  vmImage: macos-latest

steps:
  - checkout: self
  - script: |
      corepack enable
      pnpm install --frozen-lockfile
      pnpm test
    displayName: Install and test
```

Only use Corepack in CI when the selected hosted image provides it and the
repository's `packageManager` declaration is valid. Otherwise install the
pinned manager through the repository's documented CI action.

## Step 18.7 — Understand worktree layout

Use worktrees when two branches must be open simultaneously. Keep siblings in
a dedicated directory beside the primary checkout and beneath the same
repository owner. This preserves path-based Git identity routing:

```text
project/                      primary checkout
project.worktrees/            manually managed linked worktrees
├── feature-auth/
└── fix-build/
```

Create a new branch worktree:

```bash
git fetch --prune
git worktree add -b feature/auth ../project.worktrees/feature-auth origin/main
```

Create one for an existing remote branch:

```bash
git worktree add ../project.worktrees/fix-build origin/fix/build
```

Inspect before removal:

```bash
git worktree list --porcelain
git -C ../project.worktrees/feature-auth status --short --branch
```

Remove only a clean reviewed worktree:

```bash
git worktree remove ../project.worktrees/feature-auth
git worktree prune --dry-run
git worktree prune
```

Never delete a worktree directory in Finder first. Git retains administrative
state and needs `git worktree remove` or an explicit repair.

For the complete VS Code, Codex, Claude Code, Copilot, Warp, review, runtime
isolation, and cleanup workflow, use
[Git worktrees with VS Code and AI clients](GIT-WORKTREES-VSCODE-AND-AI.md).

## Step 18.8 — Handle ignored local files in worktrees

Worktrees share Git history, not ignored files. `.env`, local certificates, and
tool caches do not automatically appear in a new worktree.

Prefer one of these:

1. A setup script that creates safe defaults from committed examples.
2. A secret manager that injects values at runtime.
3. VS Code's native worktree include-files feature, restricted to reviewed
   Git-ignored patterns.

Never copy every hidden file. That can duplicate client authentication,
package caches, or production credentials.

## Step 18.9 — Verify parallel work

```bash
git worktree list
git -C <worktree-path> status --short --branch
git -C <worktree-path> config user.email
```

Then open the worktree as a separate VS Code window and run the repository's
frozen install. With pnpm, the shared content-addressed store reduces duplicate
downloads while each worktree keeps its own `node_modules` links.

## Rollback

- Remove worktrees with `git worktree remove` after committing or preserving
  their changes.
- Revert identity includes through chezmoi and test both repository paths.
- Remove Azure defaults with the current `az devops configure` command only
  after reviewing its help; signing out does not remove Git remotes.

## Advanced 18 completion checklist 🚦

- [ ] The chosen route(s) are recorded: identities/hosting, worktrees, or both.
- [ ] Any unselected route is explicitly recorded as not selected rather than
      mistaken for incomplete work.
- [ ] `ghq root` and real repository paths match the intended provider layout.
- [ ] Each real repository resolves the correct email and configuration origin.
- [ ] Only selected-track CLIs and SSH hosts are required.
- [ ] 1Password provides SSH private identities; `~/.ssh` contains config/public data only.
- [ ] A disposable signed commit verifies correctly when signing is enabled.
- [ ] Azure defaults are explicit and private where applicable.
- [ ] Every worktree is listed by Git and has a clean/understood status.
- [ ] Ignored files are copied or generated narrowly, never wholesale.

```bash
day-one-mac advanced --complete 18
```

---

[← Advanced 17](17-shell-and-package-automation.md) · [Continue to Advanced 19 →](19-macos-gui-and-local-https.md)
