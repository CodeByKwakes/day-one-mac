[← Phase 3](03-security-and-ssh.md) · **Phase 4** · [Phase 5 →](05-dotfiles-and-shell.md)

# Phase 4 — Core tools, folders, Git, and hosting

**Time:** 25–50 minutes · **Required:** everyone; hosting work is track-aware

## Outcome

The software prepared by the Installation Centre is verified, the development
folder layout exists, Git has conservative global defaults, and every provider
selected in Phase 1 passes both CLI and SSH authentication.

## How to use this phase

Run `day-one-mac setup --phase 04`. The runner rechecks the required
applications and command-line tools prepared by the
[Installation Centre](INSTALLATION-CENTRE.md). It does not install them here.
The phase creates the selected hosting folders, sets Git defaults, opens
provider login when required, and verifies SSH. If software is missing, rerun
the Installation Centre and then return to Phase 4.

Homebrew calls a command-line package a **formula** and a macOS app or font a
**cask**. A **CLI** is a tool used through Terminal. See
[GLOSSARY.md](../20-reference/GLOSSARY.md) for recurring terms.

## Step 4.1 — Verify the prepared package selection

The Installation Centre has already checked every required application and
installed the selected command-line formulae. Phase 4 verifies that complete
set before changing Git or opening provider authentication. It stops with a
clear instruction if something has been removed or changed owner.

| Type | Everyone | Conditional |
|---|---|---|
| Formulae | `chezmoi`, `ghq`, `git`, `jq`, `ripgrep`, `starship`, `zsh` | `fnm`, `pnpm` for Node; `uv` for Python; `gh` for Tracks 1 and 3; `azure-cli` for Tracks 2 and 3 |
| Applications/font | JetBrains Mono Nerd Font, Raycast, Visual Studio Code, Warp | Their preferred casks are `font-jetbrains-mono-nerd-font`, `raycast`, `visual-studio-code`, and `warp`; a valid external installation also passes |

1Password and its CLI were prepared in the Installation Centre and configured
in Phase 3. Databases, Docker, AI tools,
MCP servers, large extension catalogues, browsers, and other opinionated macOS
applications are not required. Raycast and Warp are intentionally part of the
base desktop workflow; their optional integrations are configured later.

After this phase verifies the applications, use the
[required application setup hub](../10-app-guides/README.md) for the first-launch
steps. The detailed Raycast and Warp guides explain safe permissions, account
choices, synchronization, and private exports. VS Code is configured in Phase
7. The runner does not make these privacy-sensitive choices automatically.

Track 2 does not require a GitHub account or GitHub authentication. The setup
repository itself may still have been downloaded from public GitHub over HTTPS;
that download does not create a GitHub account requirement or authentication
gate.
The cask identifiers are the preferred Homebrew entries for
[Raycast](https://formulae.brew.sh/cask/raycast) and
[Warp](https://formulae.brew.sh/cask/warp).

The ownership decision is:

```text
Homebrew cask plus valid payload → keep it
Valid app/font without a cask   → accept and preserve it
Nothing found                   → ask for Homebrew, another installer, or safe pause
Receipt or identity conflict    → stop for review
```

Run the read-only check at any time:

```bash
day-one-mac applications --required
```

See [Application ownership](../20-reference/APPLICATION-OWNERSHIP.md) for Company Portal,
optional application, reporting, and rollback behaviour.

For a missing application, rerun the Installation Centre. Select its batch
Homebrew route on a personal Mac, or the item-by-item route when Company Portal
or another approved installer should own selected apps. It rechecks the real
app, command, or font before configuration can resume.

The equivalent manual installations below are recovery commands for the
Installation Centre. Do not run them over a company-managed application:

```bash
brew install chezmoi ghq git jq ripgrep starship zsh
brew install --cask \
  font-jetbrains-mono-nerd-font \
  raycast \
  visual-studio-code \
  warp

# Node stack only
brew install fnm pnpm

# Python stack only
brew install uv

# Tracks 1 and 3
brew install gh

# Tracks 2 and 3
brew install azure-cli
```

Homebrew is the only global owner of `pnpm`. Do not also install the Homebrew
`corepack` formula or install pnpm globally through npm; those create competing
launchers.

## Step 4.2 — Create the development folders

The base layout separates repositories by hosting provider while keeping
sandbox and archive work provider-neutral:

```text
~/Developer/
├── github.com/       Tracks 1 and 3 only
├── dev.azure.com/    Tracks 2 and 3 only
├── _Projectless/     optional — created only if you need it (see below)
├── _sandbox/         disposable experiments
└── _archive/         retained but inactive projects
```

Create the common folders:

```bash
mkdir -p ~/Developer/{_sandbox,_archive}
```

Then create only the selected provider roots:

```bash
mkdir -p ~/Developer/github.com      # Tracks 1 and 3
mkdir -p ~/Developer/dev.azure.com   # Tracks 2 and 3
```

Repositories normally live below an owner or organization directory, for
example `~/Developer/github.com/example/project`.

Do not create `_Projectless` unless you use an AI client or another tool for
file-based tasks that do not yet belong to a repository. Optional Module 10
provides the complete structure and per-client launch commands. When the
portable command is installed, prepare it with the shared manager:

```bash
day-one-mac workspace init
```

Do not initialise `_Projectless` itself as a Git repository. See
[AI workspaces, chats, and projectless tasks](../20-reference/AI-WORKSPACES.md) before opening
an individual task in Claude, Codex, Copilot, Raycast, VS Code, or Warp. A
change to an existing repository belongs in a Git worktree instead.

The canonical playbook location and complete post-setup filesystem map are in
[EXPECTED-LAYOUT.md](../20-reference/EXPECTED-LAYOUT.md).

## Step 4.3 — Configure global Git defaults

The runner uses the name and primary email selected in Phase 1:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.ff only
git config --global fetch.prune true
git config --global push.autoSetupRemote true
git config --global ghq.root "$HOME/Developer"
git config --global core.excludesFile "$HOME/.gitignore_global"
git config --global merge.conflictStyle zdiff3
```

Why these defaults:

- New repositories start on `main`.
- Pull refuses an implicit merge commit when branches diverge.
- Deleted remote branches are pruned during fetch.
- The first push of a new local branch automatically records its upstream.
- A small global ignore file filters macOS metadata and temporary editor files.
- `zdiff3` displays the original text as well as both sides of a merge conflict.

The runner also adds the non-destructive `git lg` history alias. When the
wizard records VS Code as the primary IDE, it additionally configures VS Code
for commit messages, diffs, and merge conflicts. When another IDE is primary,
those editor settings are left untouched. The installer never adds
`safe.directory = *`, because that would disable Git's repository-ownership
protection globally.

The global ignore file is intentionally small. Project decisions such as
`node_modules`, `.env`, lockfiles, `.vscode`, and build output belong in each
repository's own `.gitignore`, not the global file.

When VS Code is primary, the equivalent manual configuration is:

```bash
CODE_BIN="$(command -v code || printf '%s' \
  '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code')"
git config --global core.editor "'$CODE_BIN' --wait"
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd "'$CODE_BIN' --wait \"\$MERGED\""
git config --global diff.tool vscode
git config --global difftool.vscode.cmd \
  "'$CODE_BIN' --wait --diff \"\$LOCAL\" \"\$REMOTE\""
```

Do not run those five commands when another IDE is primary. Rerun the main
wizard, change the primary-IDE choice, and revalidate Phases 4–5 instead.

Because of `pull.ff only`, a `git pull` will sometimes stop with:

```text
fatal: Not possible to fast-forward, aborting.
```

That is the setting working, not a fault. It means your branch and the remote
have both moved on, so Git is asking you to decide how to combine them rather
than creating a merge commit silently. Choose one:

```bash
git pull --rebase   # replay your commits on top of the remote's
git pull --no-ff    # record an explicit merge commit
```

Inspect the result and where every value came from:

```bash
git config --global --list --show-origin
```

Use repository-local `git config user.email ...` when one project needs a
different identity. Do not hardcode credentials or access tokens in Git config.

Verify the repository manager and configured root:

```bash
ghq root
ghq list
```

`ghq root` must print the expanded absolute path — `/Users/your-name/Developer`,
not the literal text `~/Developer`. A GitHub repository
cloned with `ghq get github.com/OWNER/REPOSITORY` is then placed below
`~/Developer/github.com/OWNER/REPOSITORY`. Azure clone URLs may contain a
provider-specific path, so confirm the destination before moving or renaming
an Azure checkout.

## Step 4.4 — Authenticate GitHub on Tracks 1 and 3

Skip this entire section on Track 2.

This step signs the **GitHub CLI** in to your account. It is separate from the
SSH key you set up in Phase 3: the key proves your identity to `git`, while this
token lets `gh` create repositories, read pull requests, and check repository
visibility in Phase 8.

```bash
gh auth login --git-protocol ssh --web --skip-ssh-key
gh config set git_protocol ssh
gh auth status
```

### 🌐 If you chose `https` mode

Phase 3's `https` mode skips SSH entirely, so this step differs:

```bash
gh auth login --git-protocol https --web --skip-ssh-key
gh auth setup-git
```

`gh auth setup-git` makes the GitHub CLI act as Git's credential helper, so
pushes over HTTPS reuse the token you just obtained. You never create or paste
a personal access token. The runner does both of these for you.

The SSH reachability tests below are skipped in this mode — there is no SSH
identity to test.

🏢 **Azure DevOps over HTTPS is not equivalent.** It needs Git Credential
Manager, which is not part of the base install:

```bash
brew install --cask git-credential-manager
```

Git then prompts for a Microsoft Entra ID sign-in, or a personal access token
that you create in Azure DevOps and Git stores in the Keychain. Day One Mac
cannot create that credential for you, and PATs expire — SSH avoids both
problems, which is why it remains the default.

### Why `--skip-ssh-key` 🔴

Your private key lives in 1Password and your public key was already registered
in Phase 3 Step 3.6, so `gh` has no key work left to do.

Without this flag, `gh` inspects `~/.ssh` for `.pub` files and — finding none,
because this project deliberately never writes keys there — offers:

```text
? Generate a new SSH key to add to your GitHub account? (Y/n)
```

The default is **Yes**. Accepting it writes a plaintext private key to
`~/.ssh/id_ed25519`, which breaks the guarantee in Phase 3 and fails the Phase 8
checklist item *"No new plaintext `~/.ssh/id_*` private key was created"*. The
flag removes the question entirely. The runner passes it for you; use it too if
you run the command by hand.

### What the prompts look like

Because `--git-protocol ssh`, `--web` and `--skip-ssh-key` are all supplied, the
only interactive part is the browser step:

```text
! First copy your one-time code: 1A2B-3C4D
Press Enter to open https://github.com/login/device in your browser...
```

Copy the code, press Return, and your browser opens GitHub's device page. Paste
the code, sign in if asked, and authorize the GitHub CLI. Back in Terminal:

```text
✓ Authentication complete.
✓ Configured git protocol
✓ Logged in as your-username
```

Sign in with the **same GitHub account that received the public key in Phase 3**.
A mismatch here is the most common cause of `gh auth status` looking healthy
while Git pushes still fail.

### If you run `gh auth login` without the flags

Running bare `gh auth login` adds prompts the recommended command skips. You may
meet them if you rerun it by hand, so they are worth recognising:

| Prompt | What to answer here |
|---|---|
| `? What is your preferred protocol for Git operations on this host?` | **SSH** — supplied by `--git-protocol ssh` |
| `? Upload your SSH public key to your GitHub account?` | **Skip**. This appears only when `~/.ssh` holds a `.pub` file, such as the `github-auth.pub` from Step 3.7. The key is already registered, so uploading it again just asks for the `admin:public_key` scope for nothing |
| `? Generate a new SSH key to add to your GitHub account? (Y/n)` | **n** — see the warning above |
| `? Enter a passphrase for your new SSH key (Optional):` | You should never reach this. It appears only after answering **Y** above, and it protects a key this project does not want on disk |
| `? Title for your SSH key: (GitHub CLI)` | Only asked when a key is being uploaded. Press Return to accept `GitHub CLI`, or give a name that identifies the Mac, such as `MacBook Pro — Day One Mac` |
| `? How would you like to authenticate GitHub CLI?` | **Login with a web browser** — supplied by `--web` |

**On passphrases generally:** the Day One Mac flow has no SSH passphrase to
choose. 1Password holds the private key and your Mac login plus Touch ID is what
unlocks it. The only time you type an SSH passphrase is Phase 3 Step 3.4c, when
importing an *existing* protected key — and you type the old key's existing
passphrase once, so 1Password can decrypt and re-protect it.

### Confirm the CLI is signed in

```bash
gh auth status
```

```text
github.com
  ✓ Logged in to github.com account your-username (keyring)
  - Active account: true
  - Git operations protocol: ssh
  - Token scopes: 'gist', 'read:org', 'repo', 'workflow'
```

Check three things: the account name is yours, the protocol is `ssh`, and
`Active account` is `true`.

### Test SSH

```bash
ssh -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new \
  -T git@github.com
```

Success looks like this:

```text
Hi your-username! You've successfully authenticated, but GitHub does not provide shell access.
```

GitHub intentionally does not provide shell access, so that sentence is the
expected result — not a failure — even though `ssh` returns a non-zero status.
Check that the username shown is the account that received your public key.

## Step 4.5 — Authenticate Azure DevOps on Tracks 2 and 3 🏢

Skip this section on Track 1.

```bash
az login
az account show
az extension add --name azure-devops
az extension show --name azure-devops
```

If the Mac has no usable browser session, `az login --use-device-code` provides
a device-code flow.

Test Azure SSH:

```bash
ssh -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new \
  -T git@ssh.dev.azure.com
```

Success looks like this:

```text
remote: Shell access is not supported.
shell request failed on channel 0
```

Both lines are expected. `shell request failed` reads like an error but is not:
it means Azure DevOps accepted your key and then declined to open a shell,
which it never provides. A genuine failure says
`remote: Public key authentication failed.` instead.

## Step 4.6 — Run or resume the phase

```bash
day-one-mac setup --phase 04
```

The runner verifies the software prepared by the Installation Centre, writes
Git defaults after recording the prior `.gitconfig`, and pauses if provider
authentication is incomplete. If a required item is missing, it sends you back
to the Installation Centre instead of starting another installer here.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| `GitHub did not accept the 1Password SSH identity` | Unlock 1Password, run `ssh-add -l`, and compare the listed public key with GitHub |
| `Permission denied (publickey)` on Azure | Confirm the key is registered in the correct Azure DevOps user profile and organization |
| Azure rejects the selected key or reports an unsupported key type | Azure DevOps requires RSA; create/import the RSA 3072-bit item in Phase 3 rather than using the GitHub Ed25519 key |
| Azure fails when several 1Password identities are available | Azure accepts the first offered key; use the provider-specific public `IdentityFile` block from Phase 3 Step 3.7 |
| Azure SSH worked before and now fails | Azure DevOps requires a full web sign-in roughly every 30 days. Open the Azure DevOps portal, complete the sign-in prompt, then retry. If it still fails, check whether the key hit an organization-enforced expiry |
| Azure Git LFS files fail to pull over SSH | Azure DevOps does not support Git LFS over SSH; use an HTTPS remote for repositories with LFS-tracked files |
| Two Azure DevOps organizations need different keys | All Azure URLs share `ssh.dev.azure.com`, so add a `Host` alias per organization with its own `IdentityFile` and `IdentitiesOnly yes`, then use the alias in the remote URL |
| `gh auth status` reports the wrong account | Run `gh auth logout`, then repeat the browser login |
| `az account show` reports the wrong tenant | Run `az logout`, then `az login --tenant <tenant-id>` |
| `pnpm` conflicts with a Corepack shim | Do not enable Corepack; inspect `command -v -a pnpm` and retain the Homebrew executable |
| An app exists but Homebrew does not list its cask | This is accepted as an external installation when its bundle identity is valid; the app is left unchanged |
| An app is marked **Needs review** | Read the displayed identity or receipt conflict and use the company support process before reinstalling it |
| A package is already installed | The runner leaves it in place and does not claim it in the precise rollback manifest |

## Phase 4 completion checklist 🚦

- [ ] `git`, `ghq`, `chezmoi`, `jq`, `rg`, and `starship` are available.
- [ ] The ownership check reports Raycast, Warp, VS Code, and the Nerd Font as ready.
- [ ] Every externally installed required app is identified as external and was left unchanged.
- [ ] `ghq root` prints `~/Developer` as an absolute path.
- [ ] `fnm` and `pnpm` exist for `node` or `both`.
- [ ] `uv` exists for `python` or `both`.
- [ ] Only provider folders required by the selected track were created.
- [ ] Git name, email, and defaults are correct.
- [ ] `gh auth status` and GitHub SSH pass on Tracks 1 and 3.
- [ ] `gh` did not create a key of its own. In every mode except `keychain`,
      `ls ~/.ssh/id_*` still finds no private key; in `keychain` mode the one
      key Phase 3 created is expected and is passphrase-protected.
- [ ] `az account show`, the Azure extension, and Azure SSH pass on Tracks 2 and 3.
- [ ] The application setup hub is bookmarked for Raycast, Warp, and VS Code first launch.

---

[← Phase 3](03-security-and-ssh.md) · [Continue to Phase 5 →](05-dotfiles-and-shell.md)
