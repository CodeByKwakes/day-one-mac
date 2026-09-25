[← Project home](../README.md) · **Reference** · [Start Phase 1 →](../01-required/01-first-boot-and-decisions.md)

# Expected Day One Mac layout

This reference shows where the standalone runtime, development projects,
dotfiles, application configuration, package-manager data, and private setup
evidence should live after the required Phase 8 gate passes.

The tree is a contract for ownership, not a demand that every implementation
detail has an identical path. `uv`, `pnpm`, Homebrew, and applications may add
versioned cache directories of their own. Use the inspection commands at the
end to discover those paths instead of hardcoding them.

## Standalone runtime and optional source checkout

Normal installations use:

```text
~/.local/bin/day-one-mac
~/.local/share/day-one-mac/current
~/.local/share/day-one-mac/releases/<version>
```

No Git checkout is required. Contributors may clone the public source into the
same `ghq` hierarchy used for other projects:

```text
~/Developer/github.com/CodeByKwakes/day-one-mac
```

Phase 4 configures:

```text
ghq root = ~/Developer
~/Developer/<provider>/<owner-or-organisation>/<repository>
```

Examples:

```text
~/Developer/github.com/CodeByKwakes/day-one-mac
~/Developer/github.com/CodeByKwakes/example-project
~/Developer/dev.azure.com/example-organisation/example-project/example-repository
```

For source development only, clone over public HTTPS:

```bash
mkdir -p "$HOME/Developer/github.com/CodeByKwakes"
git clone \
  https://github.com/CodeByKwakes/day-one-mac.git \
  "$HOME/Developer/github.com/CodeByKwakes/day-one-mac"
```

Do not place source checkouts in Desktop, Documents, iCloud Drive, Dropbox,
`/Applications`, or `~/.local/share/chezmoi`. The last path is a separate
source containing the files managed by chezmoi.

## Beginner view: files you are expected to use

Most users interact with only these locations:

```text
~/Developer/                           cloned project repositories
├── github.com/                        Track 1 or 3; optionally this setup source
├── dev.azure.com/                     Track 2 or 3
├── _Projectless/                      stable standalone AI/file tasks without a repository
├── _sandbox/                          disposable experiments
└── _archive/                          inactive projects kept for reference

~/Brewfile                             reviewed Homebrew software list
~/.zprofile and ~/.zshrc               small shell entry points managed by chezmoi
~/.config/zsh/                         shared PATH and safe aliases
~/.config/starship.toml                Terminal prompt appearance
~/Library/Application Support/Code/    VS Code user settings
```

The remaining paths below are internal evidence or application-owned data.
Users normally inspect them only for troubleshooting, auditing, or rollback.

## Technical ownership tree

The required setup produces or manages the following structure. Entries marked
**conditional** depend on the selected hosting track or development stack.

```text
~
├── Brewfile                              Homebrew desired state; managed by chezmoi
│
├── Developer/                            ghq root
│   ├── github.com/                       Track 1 or 3 project repositories
│   │   └── CodeByKwakes/
│   │       └── day-one-mac/              optional contributor source checkout
│   ├── dev.azure.com/                    Track 2 or 3
│   ├── _Projectless/                     optional AI/file tasks without a repository
│   │   ├── README.md                     boundary and promotion rules
│   │   ├── app-storage/                  default output for tasks started outside projects
│   │   │   ├── codex-projectless/        Codex projectless-task default
│   │   │   └── claude-cowork/            Claude Cowork files/storage default
│   │   ├── templates/
│   │   │   ├── TASK.md                   human-readable task record template
│   │   │   └── AGENTS.md                 shared Codex/Claude boundaries
│   │   └── tasks/<year>/
│   │       └── <timestamp>--<slug>/      immutable individual task path
│   │           ├── TASK.md
│   │           ├── AGENTS.md
│   │           ├── CLAUDE.md -> AGENTS.md
│   │           ├── input/
│   │           ├── working/
│   │           └── output/
│   ├── _sandbox/                         disposable experiments
│   └── _archive/                         retained inactive projects
│
├── .local/
│   ├── bin/day-one-mac                   stable launcher; owned by the standalone runtime
│   └── share/day-one-mac/
│       ├── current -> releases/<version> active verified runtime
│       └── releases/<version>/           versioned scripts, guides and assets
│
├── .day-one-mac/                         private setup evidence; mode 0700
│   ├── preflight/                         optional existing-Mac safety reports
│   │   └── Safety Report - YYYY-MM-DD HH-MM-SS/
│   │       ├── SUMMARY.md
│   │       ├── applications.md
│   │       ├── applications.tsv
│   │       ├── repositories.md
│   │       ├── repositories.tsv
│   │       └── SHA256SUMS.txt
│   ├── completed/
│   │   ├── 01                            phase fingerprints
│   │   ├── 02
│   │   ├── 03
│   │   ├── 04
│   │   ├── 05
│   │   ├── 06
│   │   ├── 07
│   │   └── 08
│   ├── originals/                        prior files captured before replacement
│   ├── install-manifest.tsv              packages added by this runner
│   ├── path-manifest.tsv                 paths created or modified by this runner
│   ├── application-provenance.md         readable application owner and status report
│   ├── application-provenance.tsv        machine-readable application owner records
│   ├── setup.log
│   ├── verification.md                   Phase 8 gate report
│   ├── optional-and-advanced-audit.md     unified Modules 09–22 evidence report
│   ├── advanced-audit.md                  private required/environment audit
│   ├── repository-audit.tsv               private repository state summary
│   ├── finalized-at                      present after optional finalisation
│   ├── finalization.md                   retained-state and archive report
│   ├── finalized/                        checksum-protected evidence archives
│   │   └── Day-One-Mac-Finalization-<UTC timestamp>/
│   │       ├── evidence.tar.gz
│   │       ├── evidence-files.txt
│   │       └── SHA256SUMS.txt
│   ├── wizard-selections.md              reviewed wizard plan
│   ├── runtime-root
│   ├── project-root                      linked-development compatibility only
│   ├── track
│   ├── track-schema-version
│   ├── stack
│   ├── git-name
│   ├── git-email
│   ├── dotfiles-versioning      # git or local
│   ├── dotfiles-repo            # present only for the private-Git route
│   ├── macos-settings-plan       # configure or skip
│   ├── macos-settings-selection  # selected preference identifiers
│   ├── macos-settings-status     # completed, manual-pending, skipped, restored, or failed
│   ├── macos-settings/
│   │   ├── original-values.tsv   # scalar values captured before writes
│   │   └── report.md             # applied and manual settings review
│   ├── optional-modules
│   ├── database-services
│   ├── ai-clients
│   └── mcp-servers
│
├── .config/
│   ├── chezmoi/
│   │   └── chezmoi.toml                  machine-local template data
│   ├── zsh/
│   │   ├── path.zsh                      Homebrew, ~/.local/bin and PNPM_HOME
│   │   └── aliases.zsh                   safe Day One, Git, chezmoi and Brew aliases
│   ├── starship.toml                     prompt configuration
│   └── gh/                               Track 1 or 3
│
├── .azure/                               Track 2 or 3
├── .gitconfig                            conservative Git defaults and ghq root
├── .gitignore_global                     macOS and temporary-editor ignores
├── .zprofile                             loads the shared PATH configuration
├── .zshrc                                history, completion, fnm, aliases and Starship
│
├── .ssh/
│   ├── config                            track-specific 1Password provider blocks
│   ├── github-auth.pub                   optional public selector; never a private key
│   └── azure-devops-auth.pub             optional Azure public selector
│
├── .local/
│   ├── bin/
│   │   └── day-one-mac                   portable setup dispatcher
│   ├── share/
│   │   ├── chezmoi/                      actual dotfiles source repository
│   │   │   ├── Brewfile
│   │   │   ├── dot_gitconfig
│   │   │   ├── dot_gitignore_global
│   │   │   ├── dot_zprofile
│   │   │   ├── dot_zshrc
│   │   │   ├── dot_config/zsh/path.zsh
│   │   │   ├── dot_config/zsh/aliases.zsh
│   │   │   ├── dot_ssh/config
│   │   │   ├── dot_config/starship.toml
│   │   │   └── dot_local/bin/executable_day-one-mac
│   │   └── fnm/                          Node stack
│   └── state/
│       └── fnm_multishells/              Node stack; runtime-generated
│
└── Library/
    ├── pnpm/                             Node stack; PNPM_HOME and store data
    ├── Application Support/
    │   └── Code/User/settings.json       minimal required VS Code settings
    ├── Fonts/
    │   └── JetBrainsMono Nerd Font…
    └── Group Containers/
        └── 2BUA8C4S2C.com.1password/
            └── t/agent.sock              runtime SSH-agent socket
```

During Stage 0, the safety report is created temporarily under
`~/.day-one-mac/preflight/`. After Step 2 verifies the encrypted external drive,
the authoritative report is copied below the selected recovery folder, for
example:

```text
/Volumes/Day One Backup/<Mac name> Backup - YYYY-MM-DD HH-MM/
└── Safety Report - YYYY-MM-DD HH-MM-SS/
```

The saved Stage 0 path then points to that verified external copy.

`originals/` can be empty on a genuinely clean account. An existing private
dotfiles source may contain many more managed entries than the minimum shown
above; inspect all of them before the first apply.

## Login shell

Day One Mac installs Homebrew's zsh and, after asking, makes it the login
shell in Phase 5:

```bash
dscl . -read "/Users/$(id -un)" UserShell
```

```text
UserShell: /opt/homebrew/bin/zsh
```

`/bin/zsh` remains installed and is the recovery path (`chsh -s /bin/zsh`).
The previous value is recorded at `~/.day-one-mac/previous-login-shell`, and
`/opt/homebrew/bin/zsh` is appended to `/etc/shells`. Declining the Phase 5
prompts leaves `UserShell` as `/bin/zsh`, which is also a valid final state.

## Required applications and Homebrew storage

After Phase 4, the required application layer includes:

```text
/Applications/
├── 1Password.app
├── Raycast.app
├── Visual Studio Code.app
└── Warp.app
```

The preferred Homebrew casks are:

```text
1password
1password-cli
font-jetbrains-mono-nerd-font
raycast
visual-studio-code
warp
```

This list describes the Homebrew installation route, not a requirement that
Homebrew own every application. A valid Company Portal, Mac App Store, or
manual installation may provide the same bundle or command. Its source is
recorded in:

```text
~/.day-one-mac/application-provenance.md
~/.day-one-mac/application-provenance.tsv
```

An external application remains in `/Applications` but has no matching entry
under Homebrew's `Caskroom` and is not owned by the precise rollback manifest.

Raycast and Warp are required applications. Importing the supplied Warp Drive
workflow collection and configuring Raycast extensions or Second Brain commands
remain optional actions after Phase 8.

`_Projectless` is intentionally outside `github.com` and `dev.azure.com`. Its
root is not a Git repository. Each dated child keeps a stable path for Claude,
Codex, Copilot, VS Code, or another tool until the work is discarded, distilled
into an approved knowledge vault, or promoted into a real provider-hosted
repository. Existing-repository changes belong in a sibling
`<repository>.worktrees/` directory instead. See
[AI workspaces and projectless tasks](AI-WORKSPACES.md) and
[Git worktrees with VS Code and AI clients](../03-advanced/GIT-WORKTREES-VSCODE-AND-AI.md).

Application accounts and most application-owned settings are not represented
in the filesystem tree because the setup does not control them. Follow the
[required application setup hub](../10-app-guides/README.md) to configure the apps,
export a known-good baseline, understand which data cloud sync covers, and keep
private exports outside this repository.

Day One Mac requires Apple silicon, so Homebrew owns packages under:

```text
/opt/homebrew/
├── bin/
├── Cellar/                               formula versions
├── Caskroom/                             cask downloads and metadata
└── opt/                                  stable formula links
```

`brew --prefix` must report `/opt/homebrew`. A `/usr/local` Homebrew belongs to
an Intel or Rosetta setup and is not accepted by the required phases.

## What should not exist yet

The required eight phases do not create database or OmniRoute containers, AI
authentication, MCP client configuration, custom VS Code profiles, imported
Warp Drive objects, or Second Brain vaults. Wizard selections are saved before
execution. The selector can hand a Database selection to its dedicated
installer; the other optional guides state whether their work is installed,
generated, or guided manually. No saved selection by itself is a completion
claim.

When Optional 10A is completed, its dynamic state is expected to include the
Docker container `omniroute`, named volume `omniroute-data`, and only the
selected clients' host configuration. Codex CLI uses an alternate
`~/.codex/omniroute.config.toml` profile; VS Code stores the OmniCopilot
connection key in SecretStorage/macOS Keychain. No literal endpoint key should
appear in this tree or the chezmoi source.

Stage 0 safety reports may exist before the required phases only when the Mac
began with existing state. They are private checklists, not backups, dotfiles,
or part of the Git repository. Route B apply requires the complete report to be
inside the verified encrypted external recovery root.

The standard SSH design also does not place private key files in `~/.ssh`.
In the default `1password` authentication mode, 1Password owns private key
material and exposes allowed identities through its agent socket; the only
files Day One Mac adds to `~/.ssh` are `config` and the optional public pins
`github-auth.pub` and `azure-devops-auth.pub`.

Two authentication modes change that expectation, both deliberately:

| Mode | Expected in `~/.ssh` |
|---|---|
| `1password`, `external` | `config` plus optional `*-auth.pub` public pins; **no private key** |
| `keychain` | additionally `id_ed25519` and/or `id_rsa_azure` with their `.pub` files — passphrase-protected and held by the macOS Keychain |
| `https` | no managed SSH config block at all |

Check which mode this Mac uses before treating a private key as drift:

```bash
day-one-mac --status | grep 'Git authentication'
```

## Inspect the real machine

Use commands rather than assumptions for implementation-owned locations:

```bash
day-one-mac root
ghq root
chezmoi source-path
chezmoi managed -p absolute
brew --prefix
brew list --formula
brew list --cask
pnpm store path          # Node stack only
uv python dir            # Python stack only
```

Confirm the required desktop applications:

```bash
test -d /Applications/1Password.app
test -d /Applications/Raycast.app
test -d "/Applications/Visual Studio Code.app"
test -d /Applications/Warp.app
```

Phase 8 writes the authoritative machine result to
`~/.day-one-mac/verification.md`. If that report disagrees with this reference,
fix or revalidate the owning phase instead of moving directories by hand.

---

[← Project home](../README.md) · [Start Phase 1 →](../01-required/01-first-boot-and-decisions.md) · [Verify in Phase 8 →](../01-required/08-verify-and-reproduce.md)
