[← Documentation index](../README.md) · [Start Here](../START-HERE.md)

# Complete Day One Mac project guide

**A self-contained, clean-machine setup for Apple-silicon macOS**

[Start here — beginner route](../START-HERE.md) · [Install the portable command](../reference/PORTABLE-COMMAND.md) · [Add and edit Zsh aliases](../reference/ZSH-ALIASES.md) · [Complete command reference](../reference/COMMAND-REFERENCE.md) · [Private GitHub repository access](../reference/GITHUB-PRIVATE-REPOSITORY.md) · [Complete manual and script-assisted setup](../setup/manual/MANUAL-SETUP-GUIDE.md) · [Whole process overview](PROCESS-OVERVIEW.md) · [Application keyboard shortcuts](../how-to/apps/KEYBOARD-SHORTCUTS.md) · [AI workspaces and projectless tasks](../reference/AI-WORKSPACES.md) · [Git worktrees and AI clients](../how-to/development/worktrees/GIT-WORKTREES-VSCODE-AND-AI.md) · [Existing Mac Stage 0](../setup/existing-mac/README.md) · [Remove or reset](../how-to/recovery/REMOVE-DAY-ONE-MAC.md) · [Post-setup finalisation](../how-to/recovery/FINALIZE.md) · [Plain-English glossary](../reference/GLOSSARY.md) · [Begin with Phase 1 →](../setup/assisted/01-first-boot-and-decisions.md)

This project supports a new or factory-reset Mac, or an existing Mac prepared
through Stage 0. The required phases establish macOS foundations, the selected
Git authentication and hosting, the chosen configuration owner, shell and
prompt, selected language tools, and a reproducibility report.

The **recommended productivity** preset includes Raycast, Warp, VS Code and the
Nerd Font. The **core** preset skips those desktop applications and editor
configuration. Chezmoi, Homebrew zsh and Starship follow independent ownership,
shell and prompt choices; they are not universal requirements. The
[start guide](../START-HERE.md#run-the-recommended-route) explains current choices.

The guide is suitable for an individual developer, a mixed-experience team, or
public onboarding. Commands explain what they change and every phase ends with
a visible gate. No other playbook is required.

For the implementation boundaries, presets, state migration and release trust,
see [Architecture and state](ARCHITECTURE-AND-STATE.md).

## What belongs to this project

```text
day-one-mac/
├── install-day-one-mac   Public release installer
├── scripts/             Public launcher and compatibility entry points
├── src/                 Runtime implementation, grouped by responsibility
├── config/              Catalogues, policy examples and VS Code profile data
├── docs/                Setup journeys, how-to guides, reference, explanation
├── templates/           Shell files and reusable configuration templates
├── integrations/        Warp and macOS Shortcuts assets
├── extensions/          Independent Second Brain builders
├── tests/               Regression tests and isolated fixtures
├── tools/               Contributor validation, packaging and acceptance
├── maintainers/         Architecture, plans, audits and release evidence
└── .agents/skills/      Contributor skills; excluded from runtime packages
```

Everything needed for the Day One setup lives below this directory. The runner
does not call a parent `run.sh`, inherit another setup's state, or require a
document elsewhere in the repository.

## Assumptions

Before starting, all of the following must be true:

- The Mac is new, has been erased through the approved Apple process, or has
  completed the existing-Mac preparation route.
- The Mac uses Apple silicon (an M-series or A-series chip) and the terminal is
  running natively as `arm64`. Intel Macs and terminals running under Rosetta
  are deliberately refused.
- Previous documents, repositories, passwords, and application data are held
  in a separate backup and that backup has been checked.
- You have a personal administrator account, or a managed standard account with an approved elevation process, internet access, and a trusted device for
  account sign-in.
- You will restore individual files intentionally instead of copying an old
  home directory over the clean account.
- Secrets will live in 1Password or a provider credential store, never in this
  repository, a Brewfile, or shell history.

If the Mac contains unbacked-up data, stop here. Use the optional
[Stage 0 existing-Mac route](../setup/existing-mac/README.md). It shows Route A and Route B,
creates the required read-only safety report, then uses a resumable progress
dashboard to copy and check the selected backup before an Apple reset or
account-preserving development cleanup. Its
[encrypted-drive guide](../setup/existing-mac/ENCRYPTED-BACKUP-DRIVE.md) explains the
destructive Disk Utility step separately; the script itself only verifies the
drive and prepares a safely named folder.

Stage 0 keeps its normal snapshot portable by recording reinstallable runtimes,
global npm/pnpm packages, and VS Code extensions instead of copying large local
caches. An optional checkbox includes those caches for offline recovery. File
checksums run in batches with percentage and ETA reporting; an interrupted
checksum can resume without copying the completed snapshot again.

## macOS 27 Golden Gate compatibility

Day One Mac is designed for native Apple-silicon macOS, including macOS 27
Golden Gate. Apple supports macOS 27 only on Apple-silicon Macs, and Homebrew
lists macOS 27 on Apple silicon as Tier 1. The runner therefore refuses Intel
hardware and Rosetta terminals, requires Homebrew at `/opt/homebrew`, and checks
the selected Xcode or Command Line Tools before package installation.

The dependency range is macOS 15–27; CI targets 15 and 26. The audit's native
restore rehearsal ran on 26.7.1. Full macOS 27 and managed-device onboarding
still require the [pilot acceptance matrix](../how-to/recovery/WORKSTATION-ACCEPTANCE.md).
An accepted OS version is not a completed hardware/MDM test.

Compatibility still has an application-specific boundary. On a company-managed
Mac, confirm security-agent and Company Portal support before upgrading the OS.
In particular, 1Password currently documents that **Kolide Device Trust agent
2.4.1 and earlier is not compatible with macOS 27**. This affects the Device
Trust component, not ordinary use of the 1Password application. Ask the employer
to update the agent before upgrading rather than disabling a required control.

Current references:

- [Apple — upgrade to macOS 27 Golden Gate](https://support.apple.com/en-us/127455)
- [Homebrew — supported installation platforms](https://docs.brew.sh/Installation)
- [1Password — Device Trust known issues](https://support.1password.com/device-trust-known-issues/)

This compatibility note was reviewed on **17 September 2026**. Recheck those
links before a future major macOS upgrade.

## Choose a hosting track

The track changes which folders, CLIs, authentication checks, and SSH hosts are
required. It does not select AI tools or databases.

| Track | Hosting | Installed CLI | Required authentication |
|---|---|---|---|
| **1** | GitHub only | `gh` | GitHub login and the selected SSH/HTTPS access method |
| **2** | Azure DevOps only 🏢 | `az` | Azure login and selected SSH/HTTPS access; no GitHub gate |
| **3** | GitHub + Azure DevOps 🏢 | `gh`, `az` | Both providers |
| **4** | Custom/self-managed hosting | No provider CLI required | User-owned provider access |

## Choose a development stack

| Stack | Base tools | Use it for |
|---|---|---|
| `node` | fnm, current Node LTS, npm, pnpm | JavaScript and TypeScript |
| `python` | uv-managed Python | Python and lightweight AI/ML work |
| `both` | All tools above | Full-stack, mixed-platform, or AI applications |

The playbook does not freeze a dated runtime or package-manager version.
Projects declare exact versions through `.node-version`, `.nvmrc`,
`.python-version`, `packageManager`, lockfiles, and `pyproject.toml`.

## Start the setup

For the script-assisted route, the active runtime is available at:

```text
~/.local/share/day-one-mac/current
```

`~/.local/share/day-one-mac` is the runtime container; `current` is the link to
the active versioned release. The fully manual route installs neither path.

Contributors can additionally keep a source checkout under the Phase 4 `ghq`
root. See the complete [expected layout and location
reference](../reference/EXPECTED-LAYOUT.md) for runtime, project, setup-state,
dotfile and conditional track/stack paths.

On a factory-reset Mac, first run the following command and wait for the Apple
installer to finish. The Command Line Tools include Git, which is needed to
download the project:

```bash
xcode-select --install
```

Then choose **one** of the following installation routes. Both produce the same
`~/.local/bin/day-one-mac` command and use the same eight-phase setup.

### Option A — install the standalone runtime

This is the shortest route on a new Mac. Download and inspect the small
installer; it verifies and installs the public release without keeping a Git
checkout:

```bash
DOWNLOAD="$HOME/Downloads/install-day-one-mac"

curl --proto '=https' --tlsv1.2 -fsSL \
  https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
  -o "$DOWNLOAD"

chmod 700 "$DOWNLOAD"
less "$DOWNLOAD"
```

Read the downloaded file. Press `q` to close `less`, then continue:

```bash
"$DOWNLOAD"
export PATH="$HOME/.local/bin:$PATH"
day-one-mac --wizard
```

Do not pipe the downloaded file directly into a shell. Inspecting it first
makes the remote-code boundary visible. Release archives are checked against a
separately downloaded SHA-256 value before extraction.

### Option B — clone for development, then install the runtime

Public repositories clone over HTTPS without a credential:

```bash
mkdir -p "$HOME/Developer/github.com/CodeByKwakes"
git clone https://github.com/CodeByKwakes/day-one-mac.git \
  "$HOME/Developer/github.com/CodeByKwakes/day-one-mac"
```

```bash
"$HOME/Developer/github.com/CodeByKwakes/day-one-mac/src/runtime/install-portable-command.sh" \
  --standalone
export PATH="$HOME/.local/bin:$PATH"
day-one-mac --wizard
```

Confirm either route before continuing:

```bash
command -v day-one-mac
day-one-mac root
day-one-mac --help

# Walk through the same choices and preview every base command.
day-one-mac --wizard --dry-run
```

Expected results are `~/.local/bin/day-one-mac` for the command and
`~/.local/share/day-one-mac/current` for `day-one-mac root`. See the
[complete portable installation guide](../reference/PORTABLE-COMMAND.md) for
updates, rollback, removal and linked development mode.

On a Mac that still contains data or settings, use Stage 0 first:

```bash
day-one-mac prepare-existing --guided
```

The normal wizard also asks whether the Mac is clean, existing, or uncertain
before it collects setup choices. Choosing an existing or uncertain Mac opens
the safe Stage 0 route instead of starting Phase 1.

The wizard uses Up/Down (or `j`/`k`) to move. Space or Enter accepts a
single-choice item; Space toggles a multi-choice item and Enter accepts the
list. Before setup begins, it asks only for choices needed by the required
base: hosting track, development stacks, Git identity, and chezmoi source.
Nothing is saved until **Save choices and begin or resume setup** is selected.

After Phase 1, a short checkpoint asks whether to configure optional macOS
preferences or skip them. Phase 2 prepares Homebrew, then the required
[Installation Centre](../setup/assisted/INSTALLATION-CENTRE.md) installs or accepts every app,
font, and command-line tool needed by Phases 3–8. Those phases can then focus
on configuration instead of stopping for more installers. When Phase 8 passes,
choose **Finish and exit** or open the separate optional setup centre. You can
return to that optional centre at any time with:

```bash
day-one-mac optional --guided
```

Interactive screens use consistent colours and symbols for information,
success, warnings, failures, and pending work. Colour is disabled automatically
for redirected output and can always be disabled with `NO_COLOR=1`; no decision
or status is communicated by colour alone.

On a later run, the first screen offers to resume the saved plan, change it,
show phase status, or exit. Current completed phases are skipped; changed phase
inputs or implementation are revalidated; editorial guide changes do not invalidate required phases. Phase progress, wizard selections, logs,
captured original files, and exact package ownership are stored in:

```text
~/.day-one-mac/
```

The post-Phase-8 optional selection screen is a planner, not a bulk installer. Databases,
AI clients, the OmniRoute gateway, MCP servers, VS Code profiles, enhanced CLI
tools, Warp workflows, advanced modules, and the Second Brain remain outside
the required setup and are handled through their dedicated guides after Phase
8. The saved review is available at `~/.day-one-mac/wizard-selections.md`.

For automation, recovery, or a single phase, supply choices directly and the
entry point bypasses the wizard:

```bash
# Review every required command without opening the wizard.
day-one-mac --dry-run --track 1 --stack both \
  --name "Your Name" --email you@example.com --new-dotfiles \
  --dotfiles-versioning git --macos-settings configure --yes

# Run one phase against saved choices.
day-one-mac setup --phase 04
```

Track numbers are schema-versioned. If state created by an earlier draft lacks
the current schema marker, the runner stops and asks for an explicit `--track`
instead of silently reinterpreting Track 2 or Track 3.

### Upgrading an earlier installation

New installations use only the current `day-one-mac` command and
`~/.day-one-mac` state directory. Compatibility handling for installations
created before the standalone runtime is intentionally kept out of the normal
setup flow. Follow [Upgrade notes](../reference/UPGRADE-NOTES.md) only when an
existing Mac reports an earlier command, state location, or chezmoi-owned
launcher.

Useful portable controls:

```bash
day-one-mac --wizard
day-one-mac --status
day-one-mac install
day-one-mac setup --phase 04
day-one-mac setup --phase 05 --dotfiles-repo <private-repository-url>
day-one-mac setup --phase 05 --local-dotfiles
day-one-mac macos-settings --wizard
day-one-mac --reset-progress
day-one-mac verify
```

`--reset-progress` only archives completion markers. It does not uninstall
anything. Rerunning the normal command resumes at the first incomplete or
changed phase.

## Required phase sequence

| Phase | Result | Conditional work |
|---|---|---|
| [01 · First boot and decisions](../setup/assisted/01-first-boot-and-decisions.md) | Updated Mac, final account, saved track/stack/identity | Everyone |
| [⚙️ Early macOS settings](../setup/assisted/MACOS-SETTINGS.md) | Optional Finder, Dock, keyboard, trackpad and security review before development tools | Configure now or intentionally skip |
| [02 · Command-line foundation](../setup/assisted/02-command-line-foundation.md) | Xcode Command Line Tools and Homebrew | Everyone |
| [📦 · Required Installation Centre](../setup/assisted/INSTALLATION-CENTRE.md) | All required apps, font and Terminal tools installed or accepted before configuration | Track and stack aware |
| [03 · Security and SSH](../setup/assisted/03-security-and-ssh.md) | 1Password CLI/agent and FileVault | Provider key registration follows track |
| [04 · Core tools and hosting](../setup/assisted/04-core-tools-and-hosting.md) | Git defaults, folders and provider authentication | Track aware |
| [05 · Configuration ownership, shell and prompt](../setup/assisted/05-dotfiles-and-shell.md) | User-owned files or a chezmoi source, selected zsh, and optional Starship | Ownership, shell and prompt are independent choices |
| [06 · Language toolchains and pnpm](../setup/assisted/06-language-toolchains.md) | Selected runtimes work in a new shell | Stack aware |
| [07 · VS Code base](../setup/assisted/07-vscode-base.md) | Clean editor, terminal and minimal settings | Recommended productivity preset; skipped for core |
| [08 · Verify and reproduce](../setup/assisted/08-verify-and-reproduce.md) | Audit report, Brewfile and selected dotfiles protection | Track, stack and versioning aware |

```text
Stage 0 safety report + Route A/B transition (only when needed)
      ↓
01 Decisions → 02 Foundation → 📦 Install required software → 03 Security
      → 04 Tools and hosting
      → 05 Selected owner + shell + prompt → 06 Runtime + pnpm → 07 VS Code
      → 08 Audited and reproducible
              ├─ 09 Databases            🤖 ⚙️ Optional
              ├─ 10 AI clients           🤖 ⚙️ Optional
              ├─ 10A OmniRoute gateway   🤖 ⚙️ Optional
              ├─ 11 MCP servers          🤖 ⚙️ Optional
              ├─ 12 VS Code profiles     🤖 ⚙️ Optional
              ├─ 13 Enhanced CLI tools   🤖 ⚙️ Optional
              └─ 14 Warp Drive           🤖 ⚙️ Optional
                    → 15–22 Advanced setup modules  🤖 ⚙️ Optional
```

The base environment is complete at Phase 8. Optional work never blocks its
verification.

The required applications need a few first-launch choices that should not be
guessed by automation. Use the [required application setup hub](../how-to/apps/README.md)
for the recommended order. It links to dedicated VS Code, Raycast, and Warp
guides, Phase 3 for 1Password, and the shared Nerd Font check. The app guides
cover installation ownership, settings, manual or generated Raycast commands,
optional AI-provider choices, selective import, private export, later changes,
and recovery.

## Optional modules

These documents are self-contained and can be used later in any order, except
that OmniRoute and MCP require an installed AI client.

| Module | Add it when |
|---|---|
| [09 · Databases](../how-to/modules/optional/09-databases.md) | A project needs PostgreSQL, Redis, or another local service |
| [10 · AI clients](../how-to/modules/optional/10-ai-agents.md) | You have selected Claude, Codex, the GitHub Copilot app, Copilot in VS Code, Copilot CLI, or Raycast AI and understand its account/billing model |
| [10A · OmniRoute](../how-to/modules/optional/10a-omniroute.md) | Selected clients should optionally use one OrbStack-hosted local Docker AI gateway; includes Raycast Custom Providers and Warp-launched terminal clients |
| [11 · MCP servers](../how-to/modules/optional/11-mcp-servers.md) | An installed AI client needs a specific external tool |
| [13 · Enhanced CLI tools](../how-to/modules/optional/13-enhanced-cli-tools.md) | You want `eza`, Zsh suggestions, `lazydocker`, fuzzy finding, richer Git tools, or content utilities |
| [14 · Warp Drive](../how-to/modules/optional/14-warp-drive.md) | You want the validated setup, cleanup-preview, ghq, chezmoi, toolchain, and Homebrew command collection in Warp |

VS Code profiles are configured in the [application guide](../how-to/apps/VSCODE-PROFILES.md).
Module 12 is retired; existing module numbers are unchanged.

The early installer provides and owns the `day-one-mac` dispatcher before
Phase 1; Phase 5 deliberately keeps it out of chezmoi. Its
machine-local runtime-root record lets Warp workflows call this setup from any
directory without embedding a username or checkout path. The
[command reference](../reference/COMMAND-REFERENCE.md) maps every portable command to its
direct script form and explains which one to use.

Use the [AI workspace and projectless-task guide](../reference/AI-WORKSPACES.md) before
giving an AI client access to local files. It separates private client state,
real repositories, immutable `~/Developer/_Projectless/tasks/<year>` tasks, and reviewed
knowledge-vault summaries, with setup examples for Claude, Codex, GitHub
Copilot, Raycast AI, VS Code, and Warp.

Changes to an existing repository use the separate
[Git worktree guide](../how-to/development/worktrees/GIT-WORKTREES-VSCODE-AND-AI.md), with a sibling
`<repository>.worktrees/` layout and one active writer per worktree.

## Second Brain — Day One Mac

The self-contained [Second Brain chooser](../../extensions/second-brain/README.md) now provides
two independent builds:

- [Obsidian](../../extensions/second-brain/obsidian/README.md) for local Markdown vaults,
  Raycast, Claude Code, Codex, dynamic domains, and filesystem control.
- [Notion](../../extensions/second-brain/notion/README.md) for connected databases, forms,
  dashboards, collaboration, optional Raycast entry points, and review-gated
  AI assistance.

For the Obsidian wizard:

```bash
cd "$(day-one-mac root)/extensions/second-brain/obsidian"
./scripts/second-brain-manager.sh --guided --apply
```

Preview the standard separate-vault-per-domain layout when policy requires
separate vaults:

```bash
./scripts/setup-multi-vaults.sh --tools all
```

For the Notion preview-first planner:

```bash
cd "$(day-one-mac root)/extensions/second-brain/notion"
./scripts/notion-second-brain-manager.sh --guided
```

The Notion planner stores only non-secret local choices and helper files. The
guide walks you through the reviewed cloud workspace build inside Notion.

## Advanced optional setup

The [advanced setup index](../how-to/modules/advanced/README.md) carries across the useful
power-user layer from the wider MacBook design while keeping it out of the
required build. Modules 15–22 cover full chezmoi scaffolding, curated
applications, shell/package automation, multiple Git identities, Azure DevOps,
worktrees, macOS/GUI preferences, selective restore, operational audits,
rebuild rehearsal, shared AI skills, and governed MCP operations.

```bash
day-one-mac advanced --list
day-one-mac advanced --status
day-one-mac advanced --guided
day-one-mac advanced-audit
day-one-mac optional --status --audit
```

The advanced tracker changes no configuration. It fingerprints completed guide
versions so later documentation changes appear as review work rather than
being silently skipped.

The advanced environment report is optional and belongs to Module 21 after the
base setup. It is different from Stage 0's safety report. Use
`day-one-mac advanced-audit`; upgrade-only command aliases are listed in
[Upgrade notes](../reference/UPGRADE-NOTES.md).

For one combined Modules 09–22 view, use `day-one-mac optional --status`. Its
`--audit` mode writes the module report and invokes the same private environment
and repository audit without changing installed state.

Generate a read-only application report at any time:

```bash
day-one-mac inventory
```

The Markdown report separates Homebrew formulae, Homebrew casks, Mac App Store
entries when `mas` exists, non-system application bundles, and Apple system
applications. It does not uninstall anything.

Check just the applications used by this setup and see who owns each one:

```bash
day-one-mac applications --required
day-one-mac applications --optional
```

The setup accepts a valid Company Portal, Mac App Store, or manual
installation. For a missing application it asks whether to use Homebrew,
another approved installer with live recheck, or a safe pause. See the
[application ownership guide](../reference/APPLICATION-OWNERSHIP.md) for the exact rules and
the private provenance report.

## What the required setup installs

Everyone receives `git`, `jq` and `ripgrep`. Configuration and prompt choices
independently select `chezmoi`, Homebrew zsh and Starship; ghq is opt-in and uses
the reviewed root. Node selects `fnm` and `pnpm`, Python selects `uv`, Tracks
1/3 select `gh`, and Tracks 2/3 select `azure-cli`.

The recommended productivity preset selects the Nerd Font, Raycast, VS Code and
Warp. Core skips those desktop applications and editor configuration. 1Password
and its CLI are required only for 1Password authentication. Existing approved
external applications retain ownership. Extensions, Second Brain commands and
Warp Drive workflow import remain optional.

After installation, follow the [application setup hub](../how-to/apps/README.md).
The runner never signs into app accounts, enables cloud synchronization,
imports old settings, or grants broad macOS privacy permissions on the user's
behalf.

The runner checks the application identity and installation source first. Its
manifest records packages it actually added, so a precise rollback never
claims ownership of pre-existing Homebrew or company-managed software.

## Two cleanup modes

For an ownership-aware guided choice, start with:

```bash
day-one-mac remove --guided
```

It inventories Homebrew ownership and repository risks, then offers recorded,
sectional, or full removal. Read
[Remove Day One Mac safely](../how-to/recovery/REMOVE-DAY-ONE-MAC.md) before execution. The two
engines below remain available directly for expert use.

### Clean the complete development state

Use this when you want to remove all Homebrew-managed applications and tools,
Homebrew itself, and active development configuration—even if it was installed
before this runner:

```bash
day-one-mac clean             # read-only inventory
day-one-mac clean --execute   # typed confirmation required
```

This is the broad clean-state tool. It preserves applications that Homebrew
does not manage. Known configuration is moved into a recovery archive instead
of being deleted. Projects, container volumes, SSH private keys, and known
local 1Password data remain untouched unless their explicit archive options
are selected. A macOS Keychain reset and cloud-side 1Password vault/key
deletion remain reviewed manual actions. FileVault, Command Line Tools, macOS,
and the drive are never changed.

### Undo only this runner

Use this when you want the narrower, manifest-owned rollback:

```bash
day-one-mac rollback
day-one-mac rollback --execute
```

Read [ROLLBACK.md](../how-to/recovery/ROLLBACK.md) before either execution. Neither script formats
or erases a disk.

## Maintenance after Phase 8

Review updates periodically. Listing available updates first avoids changing
every formula and graphical application at once—especially important on a work
Mac:

```bash
brew update
brew outdated --formula
brew outdated --cask
# Upgrade only the items you reviewed, then clean up after verification.
brew upgrade <formula>
brew upgrade --cask <cask>
brew cleanup
chezmoi diff
chezmoi update
fnm install --lts             # Node stacks
brew upgrade pnpm             # Node stacks; Homebrew owns this launcher
brew upgrade uv               # Python stacks; Homebrew owns this launcher
```

Prefer `brew upgrade pnpm` and `brew upgrade uv` when Homebrew owns those
executables. Never let two global installers compete for the same command.
See [Advanced 21 — maintenance](../how-to/modules/advanced/21-audit-maintenance-and-rebuild.md) for
the complete review cadence and rollback checks.

---

[Start here](../START-HERE.md) · [Begin with Phase 1 →](../setup/assisted/01-first-boot-and-decisions.md)
