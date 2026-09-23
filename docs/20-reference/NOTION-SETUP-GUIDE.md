# Day One Mac — complete developer setup

> 🍎 **Purpose**
> Use this page to turn a new or factory-reset Apple-silicon Mac into a secure,
> working development computer. Choose either the manual route or the automated
> route. Do not combine the two routes step by step unless a troubleshooting
> note explicitly tells you to do so.

> ⚠️ **Important**
> This guide is for Apple-silicon Macs running natively as `arm64`. If the Mac
> still contains the only copy of important data, stop and use the repository's
> Stage 0 existing-Mac process before continuing.

## Contents

1. [Choose a route](#choose-a-route)
2. [Prepare before either route](#prepare-before-either-route)
3. [Record the setup decisions](#record-the-setup-decisions)
4. [Manual setup flow](#manual-setup-flow)
5. [Script-based setup flow](#script-based-setup-flow)
6. [Compare the routes](#compare-the-routes)
7. [Final ready-for-work checklist](#final-ready-for-work-checklist)

## Choose a route

| Route | Best for | Main advantage | Main responsibility |
|---|---|---|---|
| **Script-based — recommended** | Most developers, repeatable team onboarding, and future rebuilds | Resumable phases, ownership records, automatic checks, and precise rollback evidence | Read every prompt and complete the named manual security actions |
| **Manual** | Learning, restricted work Macs, or environments where scripts cannot make changes | Every change is visible and individually approved | Track progress yourself and avoid repeating installation commands |

Both routes produce the same working foundation:

- Apple Command Line Tools and native Homebrew;
- Git and a predictable `~/Developer` repository layout;
- GitHub, Azure DevOps, or both, according to the selected track;
- 1Password-backed SSH and FileVault;
- chezmoi-managed shell files and a Starship prompt;
- Node with npm and pnpm, Python with uv, or both;
- Raycast, Warp, Visual Studio Code, and the required Nerd Font; and
- a reviewed Brewfile and verified environment.

The script route additionally records what it changed under
`~/.day-one-mac/`, installs the portable `day-one-mac` helper, and supports
phase fingerprints and manifest-owned rollback.

## Prepare before either route

### Hardware and account checklist

- [ ] The Mac uses an Apple-silicon M-series or A-series chip.
- [ ] The final macOS administrator account exists and its password is known.
- [ ] The Mac is connected to power and reliable internet.
- [ ] At least 30 GB is free, plus space required by real projects.
- [ ] Important files and repositories exist in a separate, tested backup.
- [ ] The 1Password account and its recovery method are available.
- [ ] The required GitHub and/or Azure DevOps account can be opened in a browser.
- [ ] Company policy permits each selected application and developer tool.

Check the processor architecture:

```bash
uname -m
```

Expected result: `arm64`.

### Choose the correct starting point

- [ ] **New or factory-reset Mac:** continue below.
- [ ] **Existing Mac or uncertain:** install the standalone runtime in the next
      section, but do not start the Phase 1 wizard. Run Stage 0 instead:

```bash
day-one-mac prepare-existing --guided
```

Stage 0 first creates a read-only safety report. Route A hands off to Apple's
erase process; Route B keeps the account and performs a backup-gated development
cleanup. The script itself never formats a disk.

### Install the initial Apple tools and standalone runtime

Open **Terminal** from **Applications → Utilities → Terminal**, then run:

```bash
xcode-select --install
```

Finish the graphical installer. Then download and inspect the public installer:

```bash
INSTALLER="$HOME/Downloads/install-day-one-mac"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
  -o "$INSTALLER"
chmod 700 "$INSTALLER"
less "$INSTALLER"
"$INSTALLER"
export PATH="$HOME/.local/bin:$PATH"
```

> ℹ️ **Why this route?**
> The public release needs no GitHub credential and remains available after a
> source checkout is deleted.

## Record the setup decisions

Complete this worksheet before choosing either route.

### Hosting track

- [ ] **Track 1 — GitHub:** install `gh`; require GitHub browser and SSH checks.
- [ ] **Track 2 — Azure DevOps:** install `az`; require Azure browser and SSH checks.
- [ ] **Track 3 — GitHub + Azure DevOps:** install and verify both.

### Development stack

- [ ] **Node:** fnm, current Node LTS, npm, and pnpm.
- [ ] **Python:** uv and a uv-managed Python interpreter.
- [ ] **Both:** install both toolchains.

### Identity and configuration

- [ ] Git author name: `________________________________`
- [ ] Primary Git email: `________________________________`
- [ ] Primary IDE: VS Code Git integration / another IDE; leave Git tools unchanged
- [ ] chezmoi source: existing private repository / new private Git / local-only
- [ ] After Phase 1, choose early macOS preferences: configure / skip for now

> 🔐 **Local-only chezmoi**
> Local-only removes the Git and remote requirement; it does not remove chezmoi.
> Include `~/.local/share/chezmoi` in an encrypted backup because another Mac
> cannot clone it.

## Manual setup flow

Use this route when every installation and file edit must be performed by hand.
Keep this page open and tick an item only after its verification succeeds.

### Manual 1 — finish macOS and security prerequisites

**Purpose:** establish a supported, encrypted operating-system baseline before
adding developer tools.

- [ ] Finish macOS Setup Assistant with the permanent account.
- [ ] Open **System Settings → General → Software Update**.
- [ ] Install every available update and restart when requested.
- [ ] Recheck Software Update until no further update is offered.
- [ ] Confirm the terminal is native Apple silicon:

```bash
sw_vers
uname -m
```

- [ ] Open **System Settings → Privacy & Security → FileVault**.
- [ ] Turn FileVault on and store its recovery method away from this Mac.
- [ ] Verify:

```bash
fdesetup status
spctl --status
```

Expected results: FileVault is on and Gatekeeper reports assessments enabled.

#### Optional early macOS settings

You may configure Finder, Dock, keyboard, trackpad, battery, and screenshot
preferences now, or skip them without blocking development setup.

For the reviewed interactive selector:

```bash
day-one-mac macos-settings --preview
day-one-mac macos-settings --wizard
```

To remain fully manual, open the documented System Settings locations in
`MACOS-SETTINGS.md` and change only the preferences you understand. Do not
disable Gatekeeper.

**Checkpoint**

- [ ] macOS is current.
- [ ] `uname -m` prints `arm64`.
- [ ] FileVault and Gatekeeper checks pass.
- [ ] Optional preferences were configured or intentionally skipped.

### Manual 2 — install Command Line Tools and Homebrew

**Purpose:** provide the compiler, Git bootstrap, and package manager used by
the remaining setup.

Check the Apple tools:

```bash
xcode-select -p
clang --version
/usr/bin/git --version
```

If `xcode-select -p` fails, rerun `xcode-select --install`, finish the graphical
installer, and repeat the checks.

Check the supported Apple-silicon location first. This catches an existing
installation even when the current Terminal has not loaded it into `PATH`:

```bash
if [[ -x /opt/homebrew/bin/brew ]]; then
  echo "Existing Apple-silicon Homebrew found; skip installation"
elif command -v brew >/dev/null 2>&1; then
  echo "Stop: Homebrew is at $(command -v brew), not /opt/homebrew/bin/brew" >&2
else
  echo "Homebrew is not installed"
fi
```

Install Homebrew only when the check prints `Homebrew is not installed`:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Load native Apple-silicon Homebrew into the current terminal:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
brew update
brew --version
brew --prefix
brew doctor
```

Expected result: `brew --prefix` prints `/opt/homebrew`.

> ⚠️ **Permissions**
> Do not use recursive `sudo chmod` on `/opt/homebrew` or the home folder. Read
> the exact `brew doctor` message and repair only a path you understand.

**Checkpoint**

- [ ] `xcode-select -p`, `clang --version`, and `git --version` succeed.
- [ ] `brew --prefix` is `/opt/homebrew`.
- [ ] Homebrew warnings were reviewed rather than ignored.

### Manual 3 — configure 1Password, SSH, and FileVault

**Purpose:** keep private SSH keys out of plaintext files while allowing Git to
authenticate to the selected hosting provider.

Before installing, check whether work management or another trusted installer
already supplied the app and command:

```bash
test -d /Applications/1Password.app && echo "1Password app exists"
command -v op || true
```

Run only the line for an item that is missing:

```bash
brew install --cask 1password
brew install --cask 1password-cli
```

- [ ] Open 1Password, sign in, and finish device approval.
- [ ] Open **1Password → Settings → Developer**.
- [ ] Enable **Integrate with 1Password CLI**.
- [ ] Enable **Use the SSH agent**.
- [ ] Choose **Application and terminal session** and **Until 1Password locks**,
      or document a consciously reviewed alternative.
- [ ] For GitHub on Tracks 1/3, create an **Ed25519** SSH Key item or import a
      trusted existing GitHub key.
- [ ] For Azure DevOps on Tracks 2/3, create an **RSA 3072-bit** SSH Key item or
      import a trusted existing RSA key. Azure DevOps does not accept Ed25519.
- [ ] For Track 3 with separate personal/work keys, download only the public
      keys and pin them to `github.com` and `ssh.dev.azure.com` with the
      `IdentityFile` blocks in [Phase 3](../01-required/03-security-and-ssh.md#step-37--pin-provider-keys-when-needed).
- [ ] When importing, compare SHA-256 fingerprints before changing or deleting
      any old key file. Retain an encrypted recovery copy until both the agent
      and provider tests pass.
- [ ] Copy only the public key and register it with the provider required by
      the selected track.

Run Phase 3 to create or safely merge a marked, track-specific block into
`~/.ssh/config`. A GitHub block looks like this; Azure DevOps uses the same
agent path under `Host ssh.dev.azure.com`:

```sshconfig
# >>> Day One Mac: 1Password SSH agent >>>
Host github.com
    HostName github.com
    User git
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    ServerAliveInterval 60
    ServerAliveCountMax 3
# <<< Day One Mac: 1Password SSH agent <<<
```

If the corresponding public key is saved as `~/.ssh/github-auth.pub` or
`~/.ssh/azure-devops-auth.pub`, rerunning
Phase 3 also adds the public `IdentityFile` line — together with
`IdentitiesOnly yes` — so 1Password offers the right private identity. Those two
lines always appear as a pair: `IdentitiesOnly yes` without an `IdentityFile`
would stop OpenSSH from using the 1Password agent at all. Existing SSH settings
are backed up before an approved merge.

Apply narrow permissions and verify the agent:

```bash
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/config"
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
test -S "$SSH_AUTH_SOCK"
ssh-add -l
op account list
```

Expected result: `ssh-add -l` lists at least one fingerprint and `op account
list` can use the unlocked desktop app.

**Checkpoint**

- [ ] 1Password is recoverable and its CLI works.
- [ ] The SSH agent offers the intended public identity.
- [ ] Only the public key was registered with hosting providers.
- [ ] No *unexpected* plaintext `~/.ssh/id_*` private key was created. Only
      the `keychain` authentication mode creates one, on purpose.
- [ ] `fdesetup status` reports FileVault on.

### Manual 4 — install core tools, applications, and hosting CLIs

**Purpose:** install the smallest shared toolset and connect only the hosting
services selected in the worksheet.

Install the common command-line tools:

```bash
brew install chezmoi ghq git jq ripgrep starship zsh
```

Install stack-specific tools:

```bash
# Node or both
brew install fnm pnpm

# Python or both
brew install uv
```

Install provider-specific tools:

```bash
# Track 1 or 3
brew install gh

# Track 2 or 3
brew install azure-cli
```

Check required desktop applications before using Homebrew:

```bash
test -d /Applications/Raycast.app || true
test -d /Applications/Warp.app || true
test -d "/Applications/Visual Studio Code.app" || true
```

On a personal Mac, run only the line for each missing app or font:

```bash
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask raycast
brew install --cask visual-studio-code
brew install --cask warp
```

> 🏢 **Managed work Mac**
> If Company Portal, the App Store, or an administrator supplied a valid app,
> keep that copy and its update channel. Do not install a Homebrew cask over it.

Create the repository structure for the selected track:

```bash
mkdir -p "$HOME/Developer/_sandbox" "$HOME/Developer/_archive"
mkdir -p "$HOME/Developer/github.com"      # Track 1 or 3
mkdir -p "$HOME/Developer/dev.azure.com"   # Track 2 or 3
```

Configure Git, replacing both identity values:

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

The script also adds `git lg` and creates the small global ignore file described
in Phase 4. If VS Code was selected as the primary IDE, it configures VS Code
for Git editing, visual diffs, and merge conflicts. Otherwise those editor
settings remain untouched.

Authenticate only the selected providers:

```bash
# Track 1 or 3
gh auth login --git-protocol ssh --web --skip-ssh-key
gh config set git_protocol ssh
gh auth status
ssh -T git@github.com

# Track 2 or 3
az login
az extension add --name azure-devops
az account show
ssh -T git@ssh.dev.azure.com
```

GitHub may return a non-zero shell status while printing “successfully
authenticated”; Azure may print “Shell access is not supported.” Those messages
are expected because neither service provides an interactive SSH shell.

**Checkpoint**

- [ ] `git`, `ghq`, `chezmoi`, `jq`, `rg`, and `starship` report versions.
- [ ] `ghq root` resolves to the absolute `~/Developer` path.
- [ ] Required applications open and retain their intended installation owner.
- [ ] Only selected provider folders and CLIs were installed.
- [ ] Browser and SSH authentication pass for the selected track.

### Manual 5 — configure chezmoi, zsh, and Starship

**Purpose:** keep a small, inspectable source of truth for shell and Git settings.

Initialize either an existing private source or a new source:

```bash
# Existing private repository
chezmoi init <private-repository-url>

# New source
chezmoi init
```

Create `~/.config/zsh/path.zsh` as the one shared owner of Homebrew and user
paths:

```zsh
typeset -U path PATH
if [[ -x /opt/homebrew/bin/brew ]] && {
  [[ ${HOMEBREW_PREFIX:-} != /opt/homebrew ]] ||
  [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] ||
  [[ ":$PATH:" != *":/opt/homebrew/sbin:"* ]]
}; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
export PNPM_HOME="$HOME/Library/pnpm" # Node selections only
case ":$PATH:" in *":$PNPM_HOME:"*) ;; *) export PATH="$PNPM_HOME:$PATH" ;; esac
```

Create or edit `~/.zprofile`:

```zsh
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"
```

Create or edit `~/.zshrc`:

```zsh
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
for completion_dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do
  [[ -d "$completion_dir" ]] || continue
  (( ${fpath[(Ie)$completion_dir]} )) || fpath=("$completion_dir" $fpath)
done
unset completion_dir
autoload -Uz compinit
compinit

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

[[ -r "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Keep syntax highlighting last.
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
```

Create `~/.config/zsh/aliases.zsh`. Start with safe inspection shortcuts; the
complete maintained set is in Phase 5:

```zsh
alias gs='git status --short --branch'
alias gd='git diff'
alias cmstatus='chezmoi status'
alias cmdiff='chezmoi diff --no-pager'
alias brewcleanpreview='brew cleanup --dry-run'
```

The script route also adds `cdayone`, which relies on its portable
`day-one-mac` helper. Omit that alias in the fully manual route.

Register Homebrew zsh and make it the account login shell. The append is safe
to rerun because `grep` prevents a duplicate line:

```bash
BREW_ZSH=/opt/homebrew/bin/zsh
"$BREW_ZSH" --version
grep -Fqx "$BREW_ZSH" /etc/shells || printf '%s\n' "$BREW_ZSH" | sudo tee -a /etc/shells
chsh -s "$BREW_ZSH"
dscl . -read "/Users/$(id -un)" UserShell
```

The final line must report `/opt/homebrew/bin/zsh`. If Homebrew zsh is ever
removed or broken, recover from a working shell with `chsh -s /bin/zsh`.

Create `~/.config/starship.toml`:

```toml
add_newline = false
command_timeout = 1000

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

Optionally record the machine-local editor and setup choices in
`~/.config/chezmoi/chezmoi.toml`. Replace the example values and keep this file
out of the managed source:

```toml
[edit]
command = "code"
args = ["--wait"]

[data]
track = "github"
stack = "both"
name = "Your Name"
email = "you@example.com"
```

Add only reviewed targets:

```bash
chezmoi add "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.gitconfig" \
  "$HOME/.ssh/config" "$HOME/.config/zsh/path.zsh" \
  "$HOME/.config/zsh/aliases.zsh" "$HOME/.config/starship.toml"
chezmoi managed
chezmoi diff --no-pager
```

Do not add tokens, `.env` files, private SSH keys, provider credential files,
browser sessions, caches, or package stores.

For a private-Git source, initialize Git and publish only to a private remote
after the secret review. For local-only, do not create the Git repository and
back up `~/.local/share/chezmoi` separately.

Open a new login shell and verify:

```bash
exec /opt/homebrew/bin/zsh -l
command -v brew git ghq chezmoi starship
chezmoi doctor
chezmoi diff --no-pager
```

**Checkpoint**

- [ ] The source path exists and every managed target is understood.
- [ ] `chezmoi diff --no-pager` is empty or fully reviewed.
- [ ] A new zsh login shell finds Homebrew and displays Starship.
- [ ] The source contains no credentials.
- [ ] Private-Git or local-only recovery has been deliberately chosen.

### Manual 6 — install the selected language toolchains

#### Node route

Load fnm and install the current LTS release:

```bash
eval "$(fnm env --shell zsh)"
fnm install --lts --use
fnm default "$(fnm current)"
node --version
npm --version
fnm current
```

Prepare and verify pnpm:

```bash
mkdir -p "$HOME/Library/pnpm"
pnpm --version
command -v pnpm
brew --prefix pnpm
(cd "$HOME" && pnpm store path)
```

Do not run `corepack enable`, install the Homebrew `corepack` formula, run
`pnpm setup`, or install pnpm globally with npm. Homebrew owns the one global
pnpm launcher; projects pin their expectation in `package.json`.

#### Python route

```bash
uv --version
uv python install
uv python list
"$(uv python find)" --version
```

#### Verify in a new shell

```bash
# Node or both
zsh -lic 'fnm current && node --version && npm --version && pnpm --version'

# Python or both
uv --version
"$(uv python find)" --version
```

**Checkpoint**

- [ ] Only the selected stack was required.
- [ ] Node uses fnm and the current LTS default, when selected.
- [ ] npm comes from the fnm-managed Node installation.
- [ ] pnpm resolves to Homebrew, when selected.
- [ ] Python resolves to a uv-managed interpreter, when selected.

### Manual 7 — configure VS Code, Warp, and Raycast

#### VS Code

- [ ] Open VS Code.
- [ ] Press `⌘⇧P` and run **Shell Command: Install 'code' command in PATH**.
- [ ] Open **Preferences: Open User Settings (JSON)**.
- [ ] Merge this minimal baseline instead of overwriting unrelated settings:

```jsonc
{
  "editor.formatOnSave": true,
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "git.autofetch": true,
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'",
  "chat.tools.global.autoApprove": false,
  "chat.tools.terminal.enableAutoApprove": false
}
```

- [ ] Install only extensions required by an actual project.
- [ ] Leave Settings Sync off until the clean baseline is verified, or review
      the account and synchronized categories before enabling it.

#### Warp and Raycast

- [ ] Open Warp, choose zsh, and select JetBrainsMono Nerd Font.
- [ ] Confirm the Starship prompt renders in a new Warp tab.
- [ ] In macOS Keyboard Shortcuts, disable only **Show Spotlight search**—do
      not disable Spotlight indexing.
- [ ] Set Raycast's main hotkey to `⌘Space` and confirm only Raycast opens.
- [ ] Grant Accessibility or other macOS permissions only when a selected
      feature explains why it needs them.
- [ ] Do not enable cloud sync or import an old backup by default.

Verify VS Code from a new terminal:

```bash
code --version
mkdir -p "$HOME/Developer/_sandbox/editor-check"
code "$HOME/Developer/_sandbox/editor-check"
```

**Checkpoint**

- [ ] VS Code opens from Terminal and its integrated terminal uses zsh.
- [ ] Starship symbols render in VS Code and Warp.
- [ ] Raycast opens from `⌘Space`, while Spotlight indexing remains available
      for file-content search.
- [ ] No app received broader permissions than its selected features need.

### Manual 8 — record and verify the finished environment

Create a Brewfile only when one does not already exist:

```bash
test -e "$HOME/Brewfile" || brew bundle dump --file="$HOME/Brewfile"
brew bundle check --file="$HOME/Brewfile" --no-upgrade
chezmoi add "$HOME/Brewfile"
chezmoi diff --no-pager
```

Review the complete chezmoi source:

```bash
SOURCE="$(chezmoi source-path)"
find "$SOURCE" -maxdepth 5 -type f -print | sort
rg -l 'BEGIN .*PRIVATE KEY|ghp_|github_pat_|AKIA|Bearer[[:space:]]' "$SOURCE" || true
```

Treat every search result as a review item. Documentation examples can be false
positives, but a real credential must be removed and rotated.

Run the final command checks:

```bash
brew --prefix
git config --global --list --show-origin
ghq root
chezmoi doctor
chezmoi diff --no-pager
starship --version
fdesetup status
spctl --status
code --version
```

Then run the selected provider and runtime checks from earlier sections.

For private-Git dotfiles, confirm the remote is private, the source is clean,
and the current branch is pushed. For local-only dotfiles, confirm an encrypted
backup contains `~/.local/share/chezmoi`.

**Manual route complete**

- [ ] Every checkpoint above passes.
- [ ] `~/Brewfile` describes the intended Homebrew state.
- [ ] The chezmoi source is secret-free and recoverable.
- [ ] A small real repository opens, installs dependencies, and runs its tests.

## Script-based setup flow

The automated route uses the same eight phases. It adds saved decisions,
resumable progress, application-ownership checks, reports, and rollback
manifests. It does not automate account sign-in or security decisions.

Before the Installation Centre installs a required application, it scans the complete required
group and shows who currently owns each item. For every missing application,
choose Homebrew, another approved installer, or a safe pause. When using Company
Portal, the App Store, or a vendor installer, leave the terminal open, complete
the installation, then press Enter. The runner rechecks the real app, command,
or font before continuing.

### Automated 1 — preview the complete plan

Using the standalone command installed above:

```bash
day-one-mac runtime-status
day-one-mac --wizard --dry-run
```

The public installer makes the portable command available before Phase 1.
Phase 5 later adopts the same launcher into chezmoi; it does not replace it
with a different tool.

The wizard asks for:

- Mac state: clean, existing, or uncertain;
- hosting track and development stack;
- Git author name and primary email;
- existing, new private-Git, or local-only chezmoi source.

After Phase 1, a separate checkpoint asks whether to configure or skip early
macOS preferences. Other optional selections do not appear until Phase 8 has
passed.

- [ ] Read the final plan.
- [ ] Confirm that the review contains only required-base decisions.
- [ ] Confirm the track, stack, identity, and dotfiles choice.

### Automated 2 — run or resume the wizard

```bash
day-one-mac --wizard
```

The runner performs these equivalents:

| Automated phase | Manual equivalent | What can still require you |
|---|---|---|
| Phase 1 | Manual 1 decisions and system checks | Finish Software Update and confirm the clean-machine boundary |
| Early settings | Optional macOS preference section | Complete selected graphical preferences or skip |
| Phase 2 | Manual 2 | Finish Apple's graphical Command Line Tools installer |
| Installation Centre | Manual 3 and 4 software prerequisites | Choose one Homebrew batch or review external owners; wait for any Company Portal installers |
| Phase 3 | Manual 3 | Sign in to 1Password, choose approval policy, register keys, and enable FileVault |
| Phase 4 | Manual 4 | Complete GitHub/Azure browser authentication and app first launch |
| Phase 5 | Manual 5 | Review an existing chezmoi diff; create a private remote later if selected |
| Phase 6 | Manual 6 | No ordinary action unless a runtime download or shell check fails |
| Phase 7 | Manual 7 | Install the VS Code `code` launcher and review existing settings |
| Phase 8 | Manual 8 | Create and push the selected private dotfiles remote, or confirm local-only recovery |

> ℹ️ **Safe to stop**
> Quit between phases. Completed current phases remain recorded. Rerun the same
> wizard to continue at the first incomplete or changed phase.

### Automated 2a — choose optional work only after Phase 8

When Phase 8 passes, choose **Finish and exit** or open the optional setup
centre. To return later:

```bash
day-one-mac optional --guided
```

The optional centre saves a plan; it does not bulk-install every selected
module.

### Automated 3 — complete the manual batches when prompted

Do not skip a manual gate just to reach the next phase.

- [ ] Phase 1: macOS updates and backup boundary confirmed.
- [ ] Phase 3: 1Password CLI and agent enabled; public key registered; FileVault on.
- [ ] Phase 4: selected hosting provider browser and SSH authentication complete.
- [ ] Phase 4/7: Raycast, Warp, and VS Code first-launch settings reviewed.
- [ ] Phase 8: dotfiles private remote pushed or local-only backup plan confirmed.

After completing the named action, rerun the displayed phase or the wizard.

For an unattended or managed deployment, never rely on an implicit installer
choice. Add `--app-install-policy homebrew` to authorize Homebrew for missing
apps, or `--app-install-policy check-only` to report and stop without installing.
The ordinary `--yes` flag does not select an application owner.

### Automated 4 — inspect status and retry only what failed

```bash
# Show choices, completed phases, and the next action.
day-one-mac --status

# Retry one phase. Replace 03 with the displayed number.
day-one-mac --phase 03

# Reopen the early preference selector.
day-one-mac macos-settings --wizard
```

Do not manually create a completion marker. A phase receives `✓` only after its
current checks pass.

### Automated 5 — review the reports

After Phase 8, inspect:

```text
~/.day-one-mac/verification.md
~/.day-one-mac/application-provenance.md
~/.day-one-mac/wizard-selections.md
~/.day-one-mac/setup.log
~/Brewfile
```

Useful commands:

```bash
sed -n '1,240p' "$HOME/.day-one-mac/verification.md"
sed -n '1,240p' "$HOME/.day-one-mac/application-provenance.md"
brew bundle check --file="$HOME/Brewfile" --no-upgrade
chezmoi diff --no-pager
```

- [ ] Every required gate passes.
- [ ] External/company-managed applications show the correct owner.
- [ ] Only software actually installed by Day One Mac appears as runner-owned.
- [ ] The Brewfile and chezmoi source contain no secrets.

### Automated 6 — complete application setup

The runner installs or recognizes applications but does not sign into them,
grant privacy permissions, enable cloud synchronization, or import old settings.

- [ ] Follow `app-guides/RAYCAST.md`.
- [ ] Follow `app-guides/WARP.md`.
- [ ] Follow `app-guides/VSCODE.md` alongside Phase 7.
- [ ] Export the clean known-good baseline outside the setup repository.

### Automated 7 — validate the project and machine state

```bash
./validate.sh
day-one-mac --phase 08
```

The first command validates the Day One Mac project. Phase 8 validates the
actual selected track, stack, apps, toolchain, and dotfiles protection.

**Script route complete**

- [ ] The wizard reports all eight phases current.
- [ ] Phase 8 verification contains no unexplained failure.
- [ ] Required apps have completed their first-launch checks.
- [ ] A small real project opens, installs dependencies, and runs its tests.

## Compare the routes

| Question | Manual | Script-based |
|---|---:|---:|
| Can a beginner follow it? | Yes, but it requires careful self-tracking | **Yes; recommended** |
| Does it resume automatically? | No | **Yes** |
| Does it preserve company-managed apps? | Only if the user checks first | **Yes; ownership is checked** |
| Does it record exactly what it installed? | No automatic manifest | **Yes** |
| Does it provide precise runner rollback? | No | **Yes** |
| Is every environment change individually visible? | **Yes** | Commands are previewable and logged |
| Is it suitable for repeatable team onboarding? | Possible, but easier to drift | **Yes** |
| Is it useful when scripts are restricted by policy? | **Yes** | Only when policy allows it |

Choose **script-based** unless company policy prevents it or the primary goal is
to learn every underlying action. Choose **manual** when each change requires
separate approval. Do not run both complete flows on the same Mac: the commands
are designed to be idempotent where practical, but a mixed route makes ownership
and troubleshooting harder to explain.

## Final ready-for-work checklist

### Security and operating system

- [ ] macOS is fully updated.
- [ ] The terminal reports `arm64`.
- [ ] FileVault is on and the recovery method is understood.
- [ ] Gatekeeper remains enabled.
- [ ] The chosen authentication mode is set up and recoverable. In
      `1password` mode that means 1Password is recoverable and no plaintext
      private SSH key was added.

### Source control and hosting

- [ ] Git author name and email are correct.
- [ ] `ghq root` points to `~/Developer`.
- [ ] Required GitHub and/or Azure CLI authentication works.
- [ ] Required SSH authentication works.

### Shell and configuration

- [ ] Homebrew uses `/opt/homebrew`.
- [ ] A new zsh login shell finds Homebrew, chezmoi, and Starship.
- [ ] chezmoi reports only understood changes.
- [ ] The dotfiles source is private-Git protected or included in an encrypted backup.

### Languages and editor

- [ ] Selected runtime commands work in a new terminal.
- [ ] Node projects have npm and a single Homebrew-owned pnpm launcher, when selected.
- [ ] Python uses a uv-managed interpreter, when selected.
- [ ] VS Code opens with `code`, starts zsh, and renders the Nerd Font.
- [ ] Raycast and Warp open with only reviewed permissions and settings.

### Real project proof

- [ ] Clone or open one real repository.
- [ ] Confirm its runtime version file is respected.
- [ ] Install dependencies from its lockfile.
- [ ] Run its documented build, test, or lint command.
- [ ] Make a temporary commit and confirm the expected author identity.
- [ ] Fetch from the remote without an authentication error.

> ✅ **Completion point**
> The Mac is ready for development when the required checks above pass and one
> real project can be cloned, opened, installed, tested, and fetched. Databases,
> AI clients, MCP servers, editor profiles, enhanced CLI tools, Warp Drive, and
> the Second Brain are optional additions after this point.
