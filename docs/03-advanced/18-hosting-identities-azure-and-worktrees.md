[← Advanced 17](17-shell-and-package-automation.md) · **🤖 ⚙️ Advanced 18** · [Advanced 19 →](19-macos-gui-and-local-https.md)

# Advanced 18 — Hosting identities, Azure DevOps, and worktrees

**Time:** 45–120 minutes · **Required:** no · **Prerequisite:** required Phase 4

## Outcome

Repositories use your selected folder layout, with ghq only if opted in. Git
chooses the correct identity from the checkout path, selected hosting CLIs have explicit defaults,
and concurrent branch work uses safe Git worktrees without duplicating Git
history or secrets.

## Choose only the route you need

Azure Artifacts package access is separate from Git identities and SSH login.
If a project needs private npm packages, follow the optional
[manual Azure Artifacts guide](../manual/azure-artifacts-npm.md). Module 18 does
not configure npm credentials or collect PATs.

### Executable identity and worktree review

The executable route creates a private review report and proposed Git
configuration fragments. It does **not** edit your Git configuration, create or
remove worktrees, sign commits, authenticate providers, or configure Azure.
Node 22+ and Git must already be on PATH; nothing is installed by this route.
Required Phase 8 must be complete before apply/resume.

Create a selection file with six tab-separated fields: `repository`, absolute
checkout root, expected name, expected email, signing policy (`ssh`, `openpgp`
or `off`), and the directory that should contain this repository's main and
linked checkouts. Replace the example paths and identity with your own:

```bash
umask 077
printf 'repository\t%s\t%s\t%s\t%s\t%s\n' \
  "$HOME/Developer/github.com/my-account/project" \
  'Your Name' 'you@example.com' ssh \
  "$HOME/Developer/github.com/my-account" > identities.tsv
day-one-mac advanced --module 18 --plan --manifest "$PWD/identities.tsv"
```

Keep the selection file private and outside public repositories; it contains
personal identity and local paths.

Add a row for every checkout whose effective identity you want checked,
including linked worktrees. A layout root is a boundary, not an identity rule:
Git's `includeIf gitdir` matches its administrative Git directory, which can
differ from a linked checkout's visible path. The report records both paths.

Review any `FAIL` results, then publish a snapshot and proposals:

```bash
day-one-mac advanced --module 18 --apply --manifest "$PWD/identities.tsv"
day-one-mac advanced --module 18 --check
```

Apply prints the artifact directory. Read `report.md`,
`identity-proposals.json`, and the numbered `identity-*.gitconfig` fragments.
Even a failed check produces diagnostic proposals, but apply exits nonzero
until the selected checks pass. Do not replace a complete configuration file
with a fragment; review the current owner and merge only intended settings.
Choosing `off` explicitly proposes disabling commit signing for that scope.

After manually correcting configuration or layout, preview again and capture
fresh evidence from the saved choices:

```bash
day-one-mac advanced --module 18 --plan
day-one-mac advanced --module 18 --resume
day-one-mac advanced --module 18 --check
```

Resume creates a new snapshot; previous reports remain available. Check detects
drift without accepting it. The layout gate rejects detached, missing, prunable
or out-of-boundary worktrees; a locked worktree is reported but not unlocked.
Signing checks verify configured policy, key presence and a readable SSH
allowed-signers file, **not** a successful signature or trust. Dirty files,
branch freshness, remote access and Azure defaults remain outside this check.
Continue with the selected manual routes below; automated success alone leaves
the dashboard `partial`.

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

For a fully manual setup, skip `day-one-mac --status` and use your own recorded
choices. If you selected ghq, inspect `ghq root` and `ghq root --all` separately.

## Step 18.2 — Use a predictable ghq layout

ghq is optional. Follow [Developer folders and optional ghq](../manual/developer-folders.md)
for the four choices: no predefined layout, repository-oriented, purpose-oriented,
or keep existing. The first two use `~/Developer` as the selected ghq root;
purpose-oriented uses `~/Developer/Projects`; keep-existing retains the root you
confirmed. Without ghq, use `git clone` with an explicit destination instead.

Only if ghq was selected, clone through it after configuring provider access
in Step 18.4. Replace the placeholders with the exact provider clone URL:

```bash
ghq get 'git@github.com:OWNER/REPOSITORY.git'
ghq get 'git@ssh.dev.azure.com:v3/ORGANISATION/PROJECT/REPOSITORY'
ghq list -p
```

Provider and owner components appear below the selected root. These are examples,
not paths to create or assume; inspect the actual output of `ghq list -p`:

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

Adapt the example prefix to your selected layout. For Azure, route the actual
checkout prefix rather than guessing it. With ghq selected, inspect:

```bash
ghq list -p
```

Without ghq, run `git -C '/absolute/path/to/checkout' rev-parse --show-toplevel`
for each checkout. With either route, inspect its remote using
`git -C '/absolute/path/to/checkout' remote -v` before assigning a work identity.

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

Git authentication and Azure CLI authentication are separate. Use the
[1Password](../manual/1password.md) or [Keychain SSH](../manual/keychain-ssh.md)
guide for the selected SSH owner. Register the public key in the correct Azure
organisation; never upload the private key. Verify a first-connection host
fingerprint against [Microsoft's SSH guidance](https://learn.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops).
A GitHub deploy key does not grant Azure access.

Azure CLI and its extension are needed only for `az` commands, not for Git
cloning over SSH. If you chose the CLI route, check its existing sign-in and extension:

```bash
az account show --output table
az extension show --name azure-devops
```

For the CLI route, replace the placeholders and configure defaults explicitly
for the current organisation and project:

```bash
az devops configure --defaults \
  organization='https://dev.azure.com/ORGANISATION' \
  project='PROJECT'
az devops configure --list
```

Do not commit organisation URLs or project names into public dotfiles when they
identify a private employer. Put them in machine-local chezmoi data or an
untracked work-specific include.

### Clone one Azure repository and update it later

This walkthrough is for **Azure Repos Git**, not TFVC. An Azure DevOps project
can contain several repositories. Cloning one does not download every repository,
Boards item, pipeline setting, artifact or wiki. Day One Mac does not bulk-clone
projects or synchronise them into a Second Brain.

1. Confirm that your account can read the chosen repository.
2. In Azure DevOps, open **Repos → Files**, select the repository, and choose
   **Clone**. Copy its SSH URL for the SSH setup above. If company policy requires
   HTTPS, use the HTTPS URL and its approved credential flow instead; never put a
   PAT in the URL or a shell command. See [Microsoft's cloning guide](https://learn.microsoft.com/en-us/azure/devops/repos/git/clone?view=azure-devops).
3. Choose **one** placement route: ghq from Step 18.2, or ordinary Git below.
   Do not run both and create duplicate checkouts.

For ordinary Git, replace the example URL and destination before running.
This example uses the purpose-oriented layout; for other layouts choose a path
under your selected root. Use a new destination, not an existing checkout:

```bash
azure_repo_url='git@ssh.dev.azure.com:v3/ORGANISATION/PROJECT/REPOSITORY'
repo_path="$HOME/Developer/Projects/ORGANISATION/PROJECT/REPOSITORY"
mkdir -p "$(dirname "$repo_path")"
git clone "$azure_repo_url" "$repo_path"
```

If you used ghq, set `repo_path` to the actual absolute checkout path shown by
`ghq list -p`. Verify the remote, branch and effective identity:

```bash
git -C "$repo_path" remote -v
git -C "$repo_path" status --short --branch
git -C "$repo_path" config user.email
```

Confirm the remote is the intended organisation/project/repository. An empty
repository has no source files yet; this alone is not an authentication failure.
Before running project scripts or installing dependencies, review its README
and trust requirements. Package-feed authentication is a separate setup.

To update an existing checkout later, set `repo_path` again in a new Terminal
session. Check for local changes and confirm the branch's upstream:

```bash
git -C "$repo_path" status --short --branch
git -C "$repo_path" branch -vv
```

Stop if changes need preserving, the branch is detached, or its upstream is
missing or incorrect. Once those are resolved, update the current branch:

```bash
git -C "$repo_path" pull --ff-only
git -C "$repo_path" status --short --branch
```

`--ff-only` refuses divergent history instead of creating a merge automatically;
review the branch with your team rather than using a hard reset. It is not a
backup of local changes. See the [Git pull reference](https://git-scm.com/docs/git-pull).

| Problem | What to check |
|---|---|
| Permission denied or repository not found | Exact clone URL, repository read permission, selected SSH key and organisation registration; CLI sign-in alone does not prove Git access |
| Host-key warning | Stop and verify the published fingerprint; do not disable host-key checking |
| Destination already exists | Inspect it; update the existing checkout or choose a new path, never delete it just to retry |
| Pull refuses to fast-forward | Local and remote history diverged; agree on a merge/rebase strategy before proceeding |
| Dependencies fail after a successful clone | Check the project's package registry instructions, including the separate Azure Artifacts guide |

After verification, [link the repository from your Second Brain](../manual/second-brain.md#link-a-repository-without-syncing-its-contents).
Use the browser repository URL for a shared note, not the SSH clone URL.

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
- [ ] Real repository paths match the selected layout; ghq roots are checked only if ghq was selected.
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
