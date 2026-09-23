[← Day One Mac home](README.md) · [Beginner start](START-HERE.md) · [Command reference](20-reference/COMMAND-REFERENCE.md) · [Start Phase 1 →](01-required/01-first-boot-and-decisions.md)

# Day One Mac process overview

This page shows the complete Day One Mac journey in one place. Use it to
understand the order of work before starting, to explain the process to another
person, or to identify where to resume.

Day One Mac turns a new, factory-reset, or carefully cleaned Apple-silicon Mac
into a secure and reproducible development environment. Intel Macs and
terminals running under Rosetta are refused. The required foundation ends after
Phase 8. Databases, AI clients, MCP servers, editor profiles, and power-user
automation are separate optional additions.

```text
Existing Mac safety preparation, when needed
                    ↓
 Eight required phases plus the software checkpoint
                    ↓
 Optional modules and advanced configuration
```

## 1. Choose the correct starting point

### New or factory-reset Mac

Install the standalone runtime, then start the main wizard:

```bash
INSTALLER="$HOME/Downloads/install-day-one-mac"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
  -o "$INSTALLER"
chmod 700 "$INSTALLER"
less "$INSTALLER"
"$INSTALLER"
export PATH="$HOME/.local/bin:$PATH"
day-one-mac --wizard
```

The command is available before Phase 1 and does not require a Git checkout.
The standalone installer remains its sole owner; Phase 5 deliberately keeps
the launcher out of chezmoi. Details are documented in
[PORTABLE-COMMAND.md](20-reference/PORTABLE-COMMAND.md).

### Existing Mac

Run Stage 0 first:

```bash
day-one-mac prepare-existing --guided
```

Stage 0 offers two routes:

- **Route A — erase the Mac:** prepare and verify the backup, then follow the
  handoff to Apple's **Erase All Content and Settings**. The script never
  erases a disk itself.
- **Route B — preserve the user account:** remove Homebrew-owned software and
  known development configuration while preserving macOS, the user account,
  user documents, and applications not owned by Homebrew.

Route B uses five safety gates:

1. Create a read-only safety report.
2. Verify an encrypted external APFS drive and copy the report to it.
3. Create a copy-only development snapshot and open a restored sample.
4. Preview exactly what cleanup would archive and remove.
5. Apply the reviewed cleanup, then restart the Mac.

The Stage 0 dashboard saves completion status and paths after every gate. Read
the full [existing-Mac route](00-preflight/README.md) before applying cleanup.

## 2. Make the setup decisions

The main wizard collects choices before it installs anything.

It also records whether VS Code is the primary IDE. That answer controls Git's
editor, diff, and merge-tool integration only; it does not remove VS Code from
the required compatibility base.

### Hosting track

| Track | Hosting services | Required authentication |
|---|---|---|
| **1** | GitHub | GitHub browser login and SSH |
| **2** | Azure DevOps 🏢 | Azure login and Azure SSH |
| **3** | GitHub and Azure DevOps 🏢 | Both providers |

The track controls provider folders, command-line tools, authentication gates,
and SSH tests. It does not choose an AI client or database.

### Git authentication

| Mode | Identity comes from | Private key in `~/.ssh`? |
|---|---|---|
| **`1password`** *(default)* | The 1Password SSH agent | No |
| **`keychain`** | A key file held by the macOS Keychain | Yes, deliberately |
| **`external`** | An agent you already run | No |
| **`https`** | No SSH — Git over HTTPS | No |

Only `1password` requires the 1Password app; the Installation Centre stops
asking for it in the other modes.
[Phase 3 Step 3.0](01-required/03-security-and-ssh.md) compares them, and
`day-one-mac --status` shows the saved choice.

### Development stack

| Stack | Base tools | Intended use |
|---|---|---|
| `node` | fnm, current Node LTS, npm, pnpm | JavaScript and TypeScript |
| `python` | uv and a uv-managed Python interpreter | Python and lightweight AI/ML work |
| `both` | Both toolchains | Full-stack or mixed-language work |

Projects remain responsible for their exact runtime versions through files
such as `.node-version`, `packageManager`, lockfiles, and `pyproject.toml`.

### Identity and dotfiles

The wizard also records:

- the Git author name and primary email;
- whether chezmoi should use an existing private source, create a new source
  protected by private Git, or create a local-only source with no Git gate.

After Phase 1, a separate checkpoint asks whether to configure or skip optional
macOS preferences. Other optional planning is deliberately withheld until the
required base passes Phase 8.

## 3. Complete the eight required phases

After Phase 1, the optional [macOS Settings Wizard](01-required/MACOS-SETTINGS.md) runs
before Phase 2 when selected. It may be intentionally skipped without blocking
the required setup. Security gates remain in their required phases.

| Phase | Result |
|---|---|
| [**1 — First boot and decisions**](01-required/01-first-boot-and-decisions.md) | Finish Setup Assistant, install macOS updates, confirm the backup boundary, and save the track, stack, Git name, and email. |
| [**⚙️ Early macOS settings — optional**](01-required/MACOS-SETTINGS.md) | Review security status and select Finder, Dock, keyboard, trackpad, menu-bar, and screenshot preferences before development tooling. |
| [**2 — Command-line foundation**](01-required/02-command-line-foundation.md) | Verify Apple Command Line Tools, detect and reuse an existing native Homebrew installation, or install it only when missing. |
| [**📦 Required Installation Centre**](01-required/INSTALLATION-CENTRE.md) | Install or accept every required app, font, and command-line tool in one pass before configuration begins. |
| [**3 — Security and SSH**](01-required/03-security-and-ssh.md) | Set up the chosen authentication mode — by default 1Password, its CLI and SSH agent — register provider keys, and verify FileVault. |
| [**4 — Core tools and hosting**](01-required/04-core-tools-and-hosting.md) | Verify the prepared tools, create the `~/Developer` structure, configure Git, and authenticate the selected providers. |
| [**5 — Dotfiles and shell**](01-required/05-dotfiles-and-shell.md) | Establish the chezmoi source, configure zsh and Starship, and migrate any legacy managed launcher to standalone ownership. |
| [**6 — Language toolchains**](01-required/06-language-toolchains.md) | Configure Node with npm/pnpm, Python with uv, or both in a new login shell. |
| [**7 — VS Code base**](01-required/07-vscode-base.md) | Apply a small portable editor baseline with zsh, the Nerd Font, and safe approval defaults. |
| [**8 — Verify and reproduce**](01-required/08-verify-and-reproduce.md) | Run the complete audit, record the Brewfile, scan for secrets, and verify private-Git or local-only dotfiles protection. |

A phase receives a `✓` only after its current checks pass. If inputs, scripts,
or phase documents change later, the saved fingerprint requires revalidation.

After Phase 8, choose **Finish and exit** or open the optional setup centre.
The centre records a plan for databases, AI clients, MCP servers, profiles, and
other extras; it does not install them silently. Open it later with:

```bash
day-one-mac optional --guided
```

## 4. Understand required applications

The base setup expects these applications or payloads:

- 1Password and 1Password CLI;
- Raycast;
- Warp;
- Visual Studio Code;
- JetBrains Mono Nerd Font.

The Installation Centre checks ownership before installing anything:

```text
Valid Company Portal, Mac App Store, or manual installation
                            ↓
            Keep it and record its external owner

Missing required application
                            ↓
       Choose Homebrew or another approved installer
                   ↓                    ↓
          Install and record     Recheck and preserve
```

This permits one playbook to work on personal and company-managed Macs. Follow
the [application setup hub](10-app-guides/README.md) for first launch, settings,
import, export, and later changes.

## 5. Understand the chezmoi boundary

The required setup keeps the managed source deliberately small and clear:

- `~/.zprofile`, `~/.zshrc`, and the managed files under `~/.config/zsh`;
- `~/.gitconfig`;
- `~/.ssh/config`;
- `~/.config/starship.toml`;
- `~/Brewfile`.

The standalone runtime—not chezmoi—owns `~/.local/bin/day-one-mac`, so updating
the runtime cannot be undone by an older dotfiles source.

Machine-specific choices stay in the local chezmoi configuration. Passwords,
API tokens, private SSH keys, and provider credentials must never enter the
dotfiles source. The normal SSH design keeps private key material in 1Password.

## 6. Expected runtime and project layout

The standalone runtime is:

```text
~/.local/share/day-one-mac/current
```

`ghq` uses `~/Developer` as its root:

```text
~/Developer/
├── github.com/                       Track 1 or 3 project repositories
├── dev.azure.com/                    Track 2 or 3
├── _sandbox/                         disposable experiments
└── _archive/                         inactive retained projects
```

See [Expected Day One Mac layout](20-reference/EXPECTED-LAYOUT.md) for the complete
filesystem and ownership map.

## 7. Know which actions remain manual

Automation handles package installation, file creation, saved state, and
verification. Security and account decisions remain manual:

- complete Setup Assistant and Software Update;
- sign in to 1Password and enable its CLI and SSH agent;
- choose the 1Password approval duration;
- create or import an SSH key and register its public key;
- finish browser-based GitHub or Azure authentication;
- confirm FileVault recovery arrangements;
- review the dotfiles source and either publish it privately or confirm the
  local-only encrypted-backup plan;
- complete application first-launch settings.

Each phase puts its manual batch near the beginning so the runner does not
repeatedly stop for unrelated choices.

## 8. Add optional modules only after Phase 8

| Module | Adds |
|---|---|
| [**9 — Databases**](02-optional/09-databases.md) | PostgreSQL, Redis, or MongoDB through OrbStack containers |
| [**10 — AI clients**](02-optional/10-ai-agents.md) | Claude Code, Codex, GitHub Copilot app, Copilot in VS Code, Copilot CLI, or Raycast AI |
| [**10A — OmniRoute**](02-optional/10a-omniroute.md) | A local Docker AI gateway for selected compatible clients |
| [**11 — MCP servers**](02-optional/11-mcp-servers.md) | Reviewed external tools and data sources for selected AI clients |
| [**12 — VS Code profiles**](02-optional/12-vscode-profiles.md) | Separate work, personal, or content-creation editor environments |
| [**13 — Enhanced CLI tools**](02-optional/13-enhanced-cli-tools.md) | eza, fzf, zoxide, lazygit, lazydocker, Zsh helpers, and related tools |
| [**14 — Warp Drive**](02-optional/14-warp-drive.md) | Importable Day One Mac workflows and command references |

Unselected clients and applications are left unchanged. Deselecting something
is not permission to uninstall it.

## 9. Add advanced capabilities when justified

[Advanced Modules 15–22](03-advanced/README.md) cover expanded dotfiles,
application curation, shell automation, multiple identities, worktrees, macOS
preferences, selective restore, maintenance rehearsals, shared AI skills, and
governed MCP operations.

After installing the portable command, inspect the tracker from any directory:

```bash
day-one-mac advanced --list
day-one-mac advanced --status
day-one-mac advanced --guided
```

The tracker opens guides and records reviewed completion; it does not silently
install advanced features.

## 10. Add the Second Brain separately

The [Second Brain chooser](../second-brain/README.md) offers an Obsidian build for
local Markdown vaults and a Notion build for connected databases and visual
dashboards. Both are optional and independent of the eight-phase foundation.

Start the Obsidian wizard with:

```bash
cd "$(day-one-mac root)/second-brain/obsidian"
./scripts/second-brain-manager.sh --guided --apply
```

Preview the Notion plan with:

```bash
cd "$(day-one-mac root)/second-brain/notion"
./scripts/notion-second-brain-manager.sh --guided
```

## 11. Stop, resume, and inspect progress

Private setup evidence is kept under `~/.day-one-mac/`. It includes saved
wizard choices, phase fingerprints, logs, original files, package/path
manifests, application provenance, and the Phase 8 verification report.

```bash
# Show saved choices and phase status.
day-one-mac --status

# Preview the wizard without changing the Mac.
day-one-mac --wizard --dry-run

# Retry or revalidate one phase.
day-one-mac --phase 03

# Validate the active runtime and completed environment.
day-one-mac validate
```

It is safe to exit between phases. Rerunning the wizard resumes the first
incomplete or changed phase.

## 12. Understand cleanup and rollback

Start with `day-one-mac remove --guided` when you want an ownership report and
a choice between recorded-only, selected sections, or full development
removal. `~/Developer` and non-Homebrew applications remain protected unless
explicitly selected. See [Remove Day One Mac safely](04-operations/REMOVE-DAY-ONE-MAC.md).

Day One Mac has two cleanup boundaries:

- **Recorded rollback** removes only packages and paths recorded as changed by
  the Day One Mac runner.
- **Broad development cleanup** archives known development configuration and
  removes Homebrew-owned formulae and casks.

The broad cleanup preserves macOS, the user account, unselected user data,
FileVault state, and applications not owned by Homebrew. Separate options
control projects, Docker/OrbStack data, local 1Password data, SSH private keys,
rebuildable caches, and Keychain reset instructions.

Neither cleanup script formats or erases a drive. Read [Rollback and clean
state](04-operations/ROLLBACK.md) before using either mode.

## 13. Finalise setup records when the base build is stable

This step is optional and happens only after Phase 8. The recommended mode
creates a checksum-protected evidence archive, compacts the setup log, and
keeps the small operational state used by status, settings restore, ownership
checks, rollback, and the portable `day-one-mac` command:

```bash
day-one-mac finalize
day-one-mac finalize --execute
day-one-mac finalize --status
```

If you no longer want any Day One Mac commands or state, the separate detach
mode moves the complete state and portable command into a recovery directory
without uninstalling the configured environment. Read
[Finalise or detach Day One Mac](04-operations/FINALIZE.md) before choosing that mode. Do not
delete `~/.day-one-mac` manually: it contains the evidence needed to understand
or reverse recorded changes.

## Completion point

After Phase 8, the Mac has:

- a current, FileVault-protected macOS installation;
- Apple Command Line Tools and Homebrew;
- GitHub, Azure DevOps, or both authenticated;
- 1Password-backed SSH;
- a predictable `~/Developer` layout managed with `ghq`;
- chezmoi-managed dotfiles and a Starship-enabled zsh shell;
- Node with npm/pnpm, Python with uv, or both;
- Raycast, Warp, and VS Code;
- a reviewed Brewfile and either a private dotfiles remote or a recorded
  local-only source;
- application provenance, audit evidence, and precise rollback records.

At that point the required build is complete. Add optional complexity only
when a real project or workflow needs it.

---

[← Day One Mac home](README.md) · [Beginner start](START-HERE.md) · [Start Phase 1 →](01-required/01-first-boot-and-decisions.md)
