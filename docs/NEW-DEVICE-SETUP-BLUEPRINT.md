[← Documentation index](README.md) · [Start Here](START-HERE.md) · [Process overview](PROCESS-OVERVIEW.md)

# New-device development environment blueprint

This document audits the Day One Mac repository and the macOS environment
observed on 25 September 2026. It then turns those findings into a repeatable
setup plan for a new Apple-silicon Mac.

Use this page for decisions, sequencing, and verification. Use the linked phase
guides for the exact implementation steps. Existing Macs that contain data or
configuration must complete [Stage 0 preflight](00-preflight/README.md) before
following the new-device sequence.

## Executive summary

The repository is in good condition: it has a clear Bash 3.2 compatibility
target, a standalone installer, idempotent phase scripts, regression fixtures,
CI validation, release automation, and unusually thorough operational
documentation. The largest risks are not defects in the repository. They are
drift between the declared setup and the current Mac, plus several contributor
experience and supply-chain controls that are not yet automated.

The current Mac has Homebrew, Git, Node.js, pnpm, Python, VS Code, Docker,
ShellCheck, jq, and ripgrep. However, Day One Mac has no recorded track, stack,
required-phase completion, or optional plan. The shell uses NVM while this
project standardizes on fnm. `gh`, `ghq`, `chezmoi`, `starship`, `fnm`, `uv`,
`shfmt`, and `direnv` were not available on the audited command path. The
existing Brewfile also has five missing casks and Homebrew reported 13 outdated
items. The missing casks are AppCleaner, MacTools, MCP Bundler, Microsoft Azure
Storage Explorer, and MonitorControl.

Treat a new machine as a controlled installation, not as an opportunity to copy
the current shell configuration wholesale. Run the required phases first,
choose one version manager per language, verify the baseline, and only then add
optional or advanced modules.

## Scope and evidence

The audit covered:

- 126 Markdown files, 75 shell scripts, GitHub Actions workflows, TSV catalogues,
  release packaging, runtime management, tests, and validation rules;
- the active macOS, shell, Homebrew, language, editor, and container command
  environment;
- configuration metadata and file presence, without printing tokens,
  credentials, SSH private keys, or MCP secret values.

The observed machine was macOS 26.7 on Apple silicon with Xcode selected and the
macOS 27.0 SDK available. Some operating-system checks were restricted by the
audit sandbox. In particular, FileVault was not confirmed and Docker's engine
socket was inaccessible. Those results require a direct Terminal check; they
must not be interpreted as proof that FileVault is off or that Docker is broken.

The repository status at audit time was clean, with local `main` two commits
ahead of `origin/main`.

## Priority improvement plan

| Priority | Finding | Recommendation | Why and tradeoff |
|---|---|---|---|
| P0 | No setup track, language stack, or required phase is recorded. | Start or resume `day-one-mac --wizard` and complete Phases 1–8 before optional work. | This restores a verifiable baseline. It may repeat checks for tools already installed, but phase scripts are designed to inspect before changing state. |
| P0 | The current shell initializes NVM, while the project standard is fnm. | Choose fnm for the new device and migrate deliberately; do not initialize NVM and fnm together. | One manager prevents PATH ambiguity and version drift. Global NVM packages must be inventoried and reinstalled intentionally. |
| P0 | The required dotfile and command baseline is incomplete. | Install and configure `ghq`, `chezmoi`, Starship, and the portable `day-one-mac` command through the required phases. | These tools provide the repository layout, reproducible shell state, prompt, and ongoing setup controls. Chezmoi adds a private source repository that must be maintained. |
| P0 | FileVault could not be confirmed in the sandbox. | Run `fdesetup status` directly in Terminal and complete the recovery-key checklist in Phase 3. | Disk encryption is a security gate. The recovery key must be stored outside the Mac, not in this repository. |
| P1 | The Brewfile is missing five casks and 13 installed items are outdated. | Review `brew bundle check --verbose` and `brew outdated --greedy`; install or remove desired entries before upgrading in batches. | Reconciliation restores declared state. Blindly installing or upgrading everything can introduce app conflicts, so review ownership first. |
| P1 | The shell has repeated Homebrew, NVM, Docker, JetBrains, OrbStack, and `/usr/local/bin` PATH entries. | Make `~/.config/zsh/path.zsh` the single PATH authority and source it once. Keep `/usr/local/bin` only for a known Intel-only dependency. | Deterministic ordering avoids shadowed binaries and slow startup. Removing a legacy path can expose tools that were installed outside Homebrew. |
| P1 | `uv`, `gh`, and `ghq` are missing; Azure CLI is installed but its status was not safely testable in the sandbox. | Install only the tools required by the chosen stack and hosting track, then authenticate interactively. | Track- and stack-based installation keeps the machine smaller. Authentication remains a manual security boundary. |
| P1 | There is no repository `.editorconfig` or shared VS Code recommendation/task file. | Add a minimal `.editorconfig` and consider `.vscode/extensions.json` plus validation tasks. Keep personal settings out of the repo. | This reduces whitespace and task-discovery drift. Shared recommendations require maintenance and should remain intentionally small. |
| P1 | GitHub Actions use version tags such as `actions/checkout@v5`. | Pin third-party actions to reviewed commit SHAs and enable automated update proposals for Actions. | SHA pinning reduces supply-chain risk. It makes updates less readable and shifts maintenance into dependency-update pull requests. |
| P2 | Local Git hooks are not configured. | Keep CI authoritative; optionally add an opt-in hook that calls the existing validator before push. | Hooks provide earlier feedback but can surprise contributors and are easy to bypass. Do not duplicate validation logic in the hook. |
| P2 | `shfmt` is catalogued but formatting is not enforced. | Adopt it only after agreeing on a format and applying one reviewed repository-wide change. | Automatic formatting improves consistency but would otherwise create noisy churn in mature scripts. |

## Repository and tooling audit

### Current state

Day One Mac is a macOS bootstrap and operations project, not a Node or Python
application. Its implementation and documentation formats are:

- Bash 3.2-compatible shell scripts for installation, verification, release
  packaging, rollback, status, and optional modules;
- Markdown for tutorials, how-to guides, explanation, reference, and operations;
- YAML for GitHub Actions;
- TSV for application, formula, Raycast, and related catalogues;
- small JSON and TOML examples where an installed tool requires them.

There is deliberately no `package.json`, Python project file, application
framework, or language dependency lockfile at the repository root. Host
dependencies come from macOS, Xcode Command Line Tools, Homebrew, and the
catalogues managed by the project. Release assets are produced by
`scripts/build-release.sh`, with checksums and a standalone installer.

The public runtime supports installation from a release, linked-checkout
development, update, rollback, uninstall, status, and installed documentation.
Version `1.0.7` is declared in `VERSION`.

### What works well

- Every shell script targets the Bash version shipped with macOS and uses
  strict error handling.
- Mutation is preview-first and intended to be idempotent.
- Application and optional formula ownership live in machine-readable
  catalogues rather than being duplicated across guides.
- The validator checks documentation presence and structure, catalogue schema,
  shell syntax, naming consistency, portable dispatch, and regression fixtures.
- `.shellcheckrc` documents each project-wide exception instead of hiding
  suppressions in scattered scripts.
- Release creation verifies that the Git tag matches `VERSION`, builds assets,
  and publishes checksums.

### What should change

Add only lightweight contributor configuration. A root `.editorconfig` should
standardize final newlines, UTF-8, and shell/YAML/Markdown indentation. A small
VS Code recommendation file can suggest ShellCheck, Markdown linting, and YAML
support; a task can invoke `scripts/validate.sh`. Avoid committing personal UI,
theme, AI-provider, account, or machine paths.

Consider pinning workflow actions to full commit SHAs and adding an automated
update configuration for GitHub Actions. The existing release and validation
jobs are sound, so this is hardening rather than a workflow redesign.

## Development workflow audit

### Run and inspect

The normal end-user entry point is the installed command:

```bash
day-one-mac --wizard
day-one-mac --status
day-one-mac docs
```

Repository contributors can invoke scripts directly from the checkout. The
runtime manager reports whether the command uses a packaged release or a linked
checkout:

```bash
scripts/day-one-mac runtime-status
```

At audit time, the repository command reported a linked checkout at version
1.0.7. The portable command existed at `~/.local/bin/day-one-mac`, but
`~/.local/bin` was not available to every non-login command environment. The
managed PATH file should make it consistently available.

### Test and lint

Use the same checks locally that CI relies on:

```bash
scripts/lint.sh
scripts/validate.sh
git diff --check
```

`scripts/lint.sh` runs ShellCheck over all shell scripts. `scripts/validate.sh`
also checks Bash syntax and runs the repository's fixtures, including portable
command behavior. CI runs on `macos-26` for pushes to `main` and pull requests.

For release work, build locally before creating a tag:

```bash
scripts/build-release.sh
```

The release workflow runs only for tags matching `v*` and rejects a tag that
does not match `VERSION`. Updating and pushing `VERSION` alone does not start a
release; pushing the matching version tag does.

### Debugging

Most failures should be reproduced by invoking the smallest affected script
directly, then rerunning the validator. Use shell tracing only in a private
terminal because `set -x` can expose expanded paths or environment values:

```bash
/bin/bash -x scripts/example.sh
```

The repository has no shared debugger launch configuration. That is reasonable
for a script-first project; repeatable fixture scripts are more useful than a
large editor-specific launch file.

## Environment audit

### Observed machine state

| Area | Observed state | Assessment |
|---|---|---|
| macOS and CPU | macOS 26.7, Apple silicon | Matches the project's native Apple-silicon direction. |
| Xcode | Full Xcode selected; macOS 27.0 SDK visible | More than the minimum Command Line Tools requirement. |
| Homebrew | `/opt/homebrew`, 93 formulae, 13 casks | Correct native prefix; desired state currently drifts. |
| Git | 2.55.0 | Available and current enough for the documented workflow. |
| Shell | zsh 5.9 with Oh My Zsh | Usable, but startup and PATH logic are fragmented. |
| Node | 22.22.3 through NVM; npm 12.0.2 | Works, but conflicts with the repository's fnm standard. |
| pnpm | 12.4.2 through Homebrew | Matches the project's package-manager ownership model. |
| Python | Homebrew Python 3.14.7 | Available, but `uv` is missing, so project isolation is not standardized. |
| Editor | VS Code 1.139.1 with many extensions | Functional; the extension set is broad and should be split into purpose-specific profiles. |
| Containers | Docker CLI 29.8.0 | Engine status must be retested outside the sandbox. |
| Quality tools | ShellCheck 0.11.0, jq 1.7.1, ripgrep 15.2.0 | Core repository validation dependencies are available. |

The shell currently initializes Homebrew in `.zprofile`, prepends Homebrew
again in `.zshrc`, appends `/usr/local/bin`, and adds NVM, SQL Server tools,
Docker, JetBrains Toolbox, and OrbStack paths in separate locations. This works
until two directories provide the same command. It also makes a new machine
difficult to reproduce.

### Target state for a new Mac

Use one owner for each concern:

| Concern | Owner |
|---|---|
| System packages and GUI applications | Homebrew and the generated Brewfile |
| Dotfiles | private chezmoi source repository |
| Shell PATH | `~/.config/zsh/path.zsh`, sourced once |
| Interactive aliases | `~/.config/zsh/aliases.zsh` |
| Prompt | Starship |
| Node versions | fnm |
| JavaScript package manager | Homebrew pnpm |
| Python versions, environments, and tools | uv |
| Repository placement | ghq under `~/Developer` |
| Secrets and SSH approval | 1Password, with manual trust decisions |
| Setup state and verification | Day One Mac runtime |

Do not copy `.zshrc` from the audited Mac as-is. Migrate only intentional
aliases and application integrations after the required shell phase passes.

## Automation and consistency audit

Validation CI and tag-driven release automation are present and appropriately
separate. The project also has runtime integrity checks, checksummed release
assets, rollback support, a status command, a unified optional-module dashboard,
and private audit outputs. These are strong controls for a bootstrap repository.

No Makefile, Taskfile, Justfile, pre-commit framework, custom Git hooks,
Dependabot configuration, or Renovate configuration was found. A task-runner
wrapper is not necessary because the existing script names are clear. If a
wrapper is added, it should call those scripts rather than create a second
implementation of validation or release behavior.

Keep CI as the source of truth. An opt-in pre-push hook may run
`scripts/validate.sh`, but contributors must still be able to run the command
directly and understand its output.

## Fresh-device setup sequence

### 1. Establish the safety boundary

On a genuinely new or factory-reset Mac, install macOS updates and confirm that
the primary account is the intended long-term account. On any Mac with existing
data, stop and complete [Stage 0](00-preflight/README.md), including backup and
cleanup decisions.

Do not import an entire legacy home directory before the baseline is verified.
Restore documents and selected application data after the setup, so obsolete
shell files and Intel-era binaries do not become part of the new baseline.

### 2. Install and inspect Day One Mac

Use the [Start Here guide](START-HERE.md) to download the standalone installer,
verify the published checksum, preview its actions, and install the runtime.
The public release is the normal new-device path; cloning the source repository
is only required for project development.

Confirm the runtime before continuing:

```bash
day-one-mac runtime-status
day-one-mac docs
```

### 3. Choose the setup profile

Run the wizard and record:

- hosting track: GitHub, Azure, or both;
- language stack: Node, Python, or both;
- primary editor;
- Git authentication and dotfile approach.

```bash
day-one-mac --wizard
```

These choices control later checks. Do not select tools merely because they are
available; select what the developer will actually maintain.

### 4. Complete required Phases 1–4

Follow [Required phases](01-required/README.md) in order. They establish the
decisions, Xcode Command Line Tools, native Homebrew, the required application
catalogue, FileVault and SSH boundaries, repository layout, and hosting tools.

Application sign-in, FileVault confirmation, 1Password recovery, and SSH host
trust remain manual actions even on the script-assisted route. Never paste a
token or private key into a setup-state file.

### 5. Build the reproducible shell

Use Phase 5 to initialize the private chezmoi source, the managed PATH and alias
files, and Starship. Start with a small dotfile set. Exclude caches, history,
tokens, machine identifiers, and generated completion files.

After applying dotfiles, open a new login shell and check command ownership:

```bash
command -v brew git day-one-mac ghq chezmoi starship
printf '%s\n' "$PATH" | tr ':' '\n'
chezmoi doctor
chezmoi status
```

Each important directory should appear once. `/opt/homebrew/bin` should precede
`/usr/local/bin` on Apple silicon.

### 6. Install language toolchains

For Node, use fnm, install the selected LTS version, and keep pnpm under
Homebrew ownership. For Python, use uv for interpreters, virtual environments,
and tools. Do not install project packages globally merely to make a check pass.

```bash
fnm current
node --version
npm --version
pnpm --version
uv python find
```

If migrating from NVM, inventory global packages first, remove NVM startup lines
only after fnm works in a fresh login shell, and reinstall only the global tools
still required. The cost is a deliberate one-time migration; the benefit is one
predictable Node owner.

### 7. Configure VS Code

Complete the base editor phase, then create workload-specific profiles rather
than installing every extension globally. The audited machine has strong
Angular, Prisma, database, Azure, container, Java, formatting, and Git tooling,
but that breadth increases activation time and extension interaction risk.

Suggested profiles are:

- web: Angular, ESLint, Prettier, Prisma, and browser tools;
- cloud: Azure, Bicep, containers, and Docker;
- data: database clients, PostgreSQL, CSV, and schema tools;
- documentation: Markdown, spelling, PDF, and diagram tools.

Sync account-based settings only after reviewing which settings are appropriate
for every machine. Keep credentials and provider configuration outside the
repository.

### 8. Verify the required baseline

Phase 8 is the gate before optional modules:

```bash
day-one-mac --status
day-one-mac shell-status
day-one-mac applications --required
day-one-mac validate
```

All required phases should be complete. Resolve failed gates before proceeding;
do not mark a phase complete by hand.

### 9. Add optional modules by need

Choose optional modules only after Phase 8 passes. Use the unified dashboard to
distinguish installed evidence from manual sign-in or trust work:

```bash
day-one-mac optional-status
day-one-mac optional-status --audit
day-one-mac optional-status --check
```

For databases, first verify the container engine in a normal Terminal:

```bash
docker info
day-one-mac databases --saved
day-one-mac databases --saved --check
```

An installed Docker command is not proof that its engine is running. A database
module is not complete until its selected containers are healthy and the module
check passes.

### 10. Capture reproducibility state

Generate or reconcile the Brewfile and editor/application inventory only after
the machine reflects the desired setup. Then verify without upgrading:

```bash
brew bundle check --file="$HOME/Brewfile" --no-upgrade
chezmoi status
day-one-mac optional-status --audit --check
```

Commit the private dotfile source only after reviewing its diff for secrets.
Keep recovery material and exported credentials outside both the public project
and the private dotfile repository.

## macOS workflow recommendations

The project's required applications—1Password, Raycast, VS Code, Warp, and the
Nerd Font—form a sensible baseline. Add optional tooling in small tiers:

1. Navigation and inspection: `bat`, `eza`, `fd`, `fzf`, `tree`, and `zoxide`.
2. Git workflow: `gh`, `ghq`, `git-delta`, `git-lfs`, `gitleaks`, and optionally
   `lazygit`.
3. Environment automation: `direnv`, with explicit per-directory approval.
4. Script quality: ShellCheck and, after a formatting decision, `shfmt`.
5. System visibility: `btop`, `duf`, `dust`, and `hyperfine` when their output
   answers a recurring operational question.
6. Containers: choose OrbStack or another Docker-compatible engine, not several
   engines that compete for contexts and startup resources.

Raycast should own repeatable GUI actions and shortcuts; Warp should remain a
terminal rather than a second source of shell configuration; 1Password should
own secrets and SSH approvals; chezmoi should own text configuration. Clear
ownership reduces the chance that the same setting is maintained in three
places.

## Final acceptance checklist

A new device is ready when all of the following are true:

- `day-one-mac --status` shows required Phases 1–8 complete.
- FileVault is confirmed directly and its recovery path is documented privately.
- `brew bundle check --no-upgrade` succeeds for the intended Brewfile.
- `chezmoi doctor` succeeds and `chezmoi status` shows only understood changes.
- PATH output has no accidental duplicates or unexpected Intel-first directory.
- fnm owns Node and uv owns Python for the selected stack.
- the selected hosting CLI is installed and authenticated.
- VS Code opens the project with the intended profile and validation commands
  run successfully.
- the container engine responds to `docker info` if a container module was
  selected.
- `day-one-mac optional-status --audit --check` passes for every selected
  optional or advanced module.
- a restart and a fresh login shell preserve the same successful checks.

## Related documentation

- [Complete process overview](PROCESS-OVERVIEW.md)
- [Required setup phases](01-required/README.md)
- [Optional modules](02-optional/README.md)
- [Advanced modules](03-advanced/README.md)
- [Optional and advanced status dashboard](20-reference/OPTIONAL-STATUS.md)
- [Managing dotfiles with chezmoi](20-reference/MANAGING-DOTFILES-WITH-CHEZMOI.md)
- [Operations and rollback](04-operations/README.md)

---

[← Documentation index](README.md) · [Start setup](START-HERE.md) · [Verify optional modules](20-reference/OPTIONAL-STATUS.md)
