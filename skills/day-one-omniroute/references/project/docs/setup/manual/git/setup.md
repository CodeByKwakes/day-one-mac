# Configure Git and provider access

Set the author identity and verify repository access for the providers you use.
Complete [Homebrew](../homebrew.md) and select [authentication](../security/README.md)
first. Preserve a backup of existing `~/.gitconfig` and SSH configuration before
editing; do not replace unrelated work identities.

## 1. Set the author name

```bash
git config --global user.name "Your Name"
```

Expected result: `git config --global user.name` prints the intended author.
Replace the example before running it. This value is attribution, not login.

## 2. Set the author email

```bash
git config --global user.email "you@example.com"
```

Expected result: `git config --global user.email` prints your approved email.
Use repository-specific settings for projects requiring another identity.

## 3. Select conservative defaults

Review each independent setting before applying it:

| Command | Expected behaviour |
|---|---|
| `git config --global init.defaultBranch main` | New repositories use `main` |
| `git config --global pull.ff only` | Pull stops when a merge/rebase decision is required |
| `git config --global fetch.prune true` | Fetch removes stale remote-tracking references |
| `git config --global push.autoSetupRemote true` | A first default push can establish its upstream |
| `git config --global merge.conflictStyle zdiff3` | Conflicts include useful base context |
| `git config --global core.excludesFile "$HOME/.gitignore_global"` | Git reads the selected global ignore file |

Create or merge `~/.gitignore_global` with `.DS_Store` and temporary editor files
such as `*.swp`. Project dependencies, secrets and build outputs belong in each
project's reviewed `.gitignore`; a global ignore is not a credential safeguard.

## 4. Install only selected provider tools

For GitHub, run `brew install gh` if missing. For Azure DevOps, use your approved
Azure CLI installation; the project catalogue uses `brew install --cask azure-cli`
and also accepts an existing formula installation.

Expected result: `gh --version` or `az version` succeeds for each selected
provider. A self-managed provider does not require either tool.

## 5. Authenticate the provider CLI

For GitHub with SSH, run:

```bash
gh auth login --git-protocol ssh --web --skip-ssh-key
```

For GitHub with HTTPS, use `--git-protocol https` instead. The skip option keeps
key creation in the chosen authentication task. Expected result: `gh auth status`
identifies the intended account.

For Azure, run `az login` and complete the browser flow. Expected result:
`az account show` identifies the intended tenant/account. Add the DevOps command
group only when needed with `az extension add --name azure-devops`.

CLI authentication and Git credentials are separate. HTTPS users complete
[credential-helper setup](../security/https-git.md); SSH users complete
[public-key registration](../security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication).

## 6. Verify a repository read

Use the clone URL of a repository you are authorised to access:

```bash
git ls-remote 'https://dev.azure.com/ORG/PROJECT/_git/REPO' HEAD
```

Replace the entire example URL; use the provider's SSH URL in SSH mode.
Expected result: a commit and `HEAD` reference for an existing non-empty
repository. A successful empty repository can have no refs; select a known
non-empty repository for this check. Repeat for both providers when selected.
A public repository can be readable without authenticating.

## Optional editor integration

After the [VS Code CLI](../editors/vscode.md) works, set `git config --global
core.editor 'code --wait'` if VS Code is your chosen Git editor. Test it with
`git config --global --edit`, then close the editor without unrelated changes.
Preserve another editor when it is your selected owner.

For separate working directories, use the [worktree guide](../development/worktrees/README.md).
For automatic repository placement, use [developer folders and ghq](../development/folders.md).

## Verify and recover

Inspect `git config --global --list --show-origin` privately and verify the author
inside a real project. Remove or restore only the setting you changed if it is
wrong. Do not upload this output if it contains account or private-host details.

| Symptom | Action |
|---|---|
| CLI login works but Git fails | Check the transport and its credential helper/SSH key separately |
| Wrong author in one project | Inspect local Git configuration and conditional includes |
| SSH says shell access is unsupported | Verify repository access; hosted Git is not an interactive shell |
| Access denied | Check account, repository permission and credential expiry with the owner |

Next: [shell and configuration ownership](../shell/README.md).
