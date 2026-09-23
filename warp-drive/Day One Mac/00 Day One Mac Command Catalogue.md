# Day One Mac — command catalogue

> Install the portable `day-one-mac` command before Phase 1. Phase 5 later
> keeps the launcher under standalone-runtime ownership rather than chezmoi.

This Notebook accompanies the **63 workflows in seven folders** imported with
it. It belongs to the self-contained `day-one-mac` setup and intentionally does
not use commands from the older 20-phase playbook.

## Before using the workflows

1. Complete the eight required day-one-mac phases.
2. Open a new login shell so `~/.local/bin` is on `PATH`.
3. Confirm the portable dispatcher can locate this project:

   ```bash
   day-one-mac root
   day-one-mac validate
   ```

The dispatcher reads the installed runtime location recorded in
`~/.day-one-mac/runtime-root`. The workflows therefore do not contain a
username or hard-coded checkout path. `day-one-mac update` changes the
versioned runtime without editing imported workflows.

## Track and stack boundaries

- **Track 1 — GitHub:** use the GitHub workflows; Azure workflows are not
  expected to work.
- **Track 2 — Azure DevOps:** use the Azure workflows; GitHub authentication is
  not a setup gate.
- **Track 3 — GitHub + Azure DevOps:** both provider groups apply.
- `fnm`, `node`, `npm`, and `pnpm` workflows require the `node` or `both` stack.
- `uv` workflows require the `python` or `both` stack.

An unavailable conditional command is normally evidence that its track or
stack was not selected—not a reason to install it outside the playbook.

## Safety model

Workflow names describe their effect:

- **Show**, **List**, **Status**, **Check**, **Preview**, and **Audit** are
  inspection commands.
- **Run**, **Clone**, **Apply**, **Install**, **Sync**, **Select**, **Write**,
  and **Refresh** can change local state. Read the populated command before
  pressing Enter.
- Cleanup and rollback workflows are **preview-only**. This bundle deliberately
  contains no cleanup workflow with `--execute`, no package-uninstall shortcut,
  and no command that deletes credentials.

For a parameterised workflow, fill each argument in Warp or move between
placeholders with **Shift-Tab**. Never place a password, token, private key, or
1Password secret reference in a saved workflow.

## 01 · Setup and audit

| Workflow | Command | Purpose |
|---|---|---|
| Setup · Show Day One Mac status | `day-one-mac --status` | Show track, stack, and all eight phase states. |
| Setup · Validate Day One Mac project | `day-one-mac validate` | Validate scripts, docs, workflow safety, and regression checks. |
| Setup · Preview all required phases | `day-one-mac setup --guided --dry-run` | Preview the required setup without changing the Mac. |
| Setup · Preview one phase | `day-one-mac setup --phase "{{phase}}" --dry-run` | Preview Phase 01–08. |
| Setup · Run one phase | `day-one-mac setup --phase "{{phase}}"` | Run one reviewed required phase. |
| Setup · Write application inventory | `day-one-mac inventory` | Write a private Markdown report of installed applications. |
| Setup · Pin provider public keys | `day-one-mac ssh-pin` | Save the 1Password public key for each provider in the saved track to `~/.ssh`. |
| Setup · List optional CLI tools | `day-one-mac cli-tools --list` | Show the grouped optional formula catalogue. |
| Setup · Select optional CLI tools | `day-one-mac cli-tools` | Open the interactive optional-formula selector. |
| Setup · Choose optional modules | `day-one-mac optional --guided` | After Phase 8, choose and save optional modules without installing them automatically. |
| Setup · Create projectless task | `day-one-mac workspace --guided` | Create one immutable bounded task for standalone file work. |
| Setup · Show runtime root | `day-one-mac root` | Print the installed runtime used by the portable dispatcher. |
| Setup · Check shell health | `day-one-mac shell-status` | Inspect Homebrew zsh, startup files, clean PATHs and completion permissions. |
| Advanced · Show module status | `day-one-mac advanced --status` | Show state for optional Modules 15–22. |
| Advanced · Open guided checklist | `day-one-mac advanced --guided` | Walk through the advanced module guides. |
| Advanced · Read one module | `day-one-mac advanced --module "{{module}}"` | Open Advanced Module 15–22. |
| Advanced · Write environment report | `day-one-mac advanced-audit` | Write the optional private environment and repository-risk reports after Phase 8. |
| Advanced · Check environment report | `day-one-mac advanced-audit --check` | Write the optional report and fail when a required gate does not pass. |
| Setup · Show finalisation status | `day-one-mac finalize --status` | Show the Phase 8 and retained-record finalisation state. |
| Setup · Preview post-setup finalisation | `day-one-mac finalize` | Preview evidence archiving and log compaction without changing anything. |

Recommended health check:

```bash
day-one-mac --status
day-one-mac validate
day-one-mac advanced --status
day-one-mac advanced-audit --check
day-one-mac finalize --status
```

The finalisation workflow is preview-only. Full detachment disables these Warp
workflows and therefore remains a deliberate terminal action documented in
`day-one-mac/docs/04-operations/FINALIZE.md`; it is never offered as a one-click workflow.

## 02 · Safety and cleanup

| Workflow | Command | Purpose |
|---|---|---|
| Cleanup · Preview broad development cleanup | `day-one-mac clean` | Inventory the broad cleanup scope without changing anything. |
| Cleanup · Preview comprehensive recoverable cleanup | `day-one-mac clean --zap-cask-data --archive-projects --archive-docker-data --archive-orbstack-data --archive-1password-data --archive-ssh-private-keys --prepare-keychain-reset` | Preview the deepest supported archive scope; still makes no changes. |
| Cleanup · Preview recorded rollback | `day-one-mac rollback` | Preview undoing only manifest-owned changes. |
| Cleanup · Preview complete recorded rollback | `day-one-mac rollback --all-recorded` | Include eligible packages, dotfiles source, and setup state in the preview. |
| Cleanup · Preview progress reset | `day-one-mac setup --reset-progress --dry-run` | Show where phase markers would be archived. |
| Cleanup · Show removal ownership inventory | `day-one-mac remove --inventory` | Classify Homebrew ownership and repository risks without changing the Mac. |
| Cleanup · Preview recorded Day One removal | `day-one-mac remove --mode recorded` | Preview manifest-owned removal while preserving Developer content. |

To perform a cleanup, first read `day-one-mac/docs/04-operations/ROLLBACK.md`, run the matching
preview, review the generated inventory and archive destination, then invoke
the underlying script manually with `--execute`. Requiring that separate step
prevents a searchable Warp entry from becoming a one-key destructive action.

## 03 · Repositories and hosting

| Workflow | Command | Purpose |
|---|---|---|
| Repositories · Show ghq root | `ghq root` | Confirm repositories resolve below `~/Developer`. |
| Repositories · List ghq repositories | `ghq list` | List managed checkout paths. |
| Repositories · Clone with ghq | `ghq get "{{repository}}"` | Clone a reviewed URL into the ghq layout. |
| Git · Status | `git status --short --branch` | Show branch and working-tree state. |
| Git · Show remotes | `git remote --verbose` | Review fetch and push endpoints. |
| GitHub · Check authentication | `gh auth status` | Track 1 or 3 GitHub authentication check. |
| Azure · Show active account | `az account show --output table` | Track 2 or 3 account and tenant check. |
| Azure · List repositories | `az repos list --output table` | List Azure Repos using the current defaults. |

Run repository commands from the repository they should inspect. `ghq get`
does not need that—the configured `ghq.root` chooses the destination.

## 04 · Dotfiles

| Workflow | Command | Purpose |
|---|---|---|
| Dotfiles · Status | `chezmoi status` | Show managed targets that differ. |
| Dotfiles · Preview changes in VS Code | `chezmoi diff` | Open every proposed target change in VS Code. |
| Dotfiles · Preview changes in Terminal | `chezmoi --use-builtin-diff diff --no-pager` | Print a non-graphical unified diff without changing the configured tool. |
| Dotfiles · Run doctor | `chezmoi doctor` | Check source, config, and dependencies. |
| Dotfiles · List managed targets | `chezmoi managed` | List source-owned paths. |
| Dotfiles · Edit one target | `chezmoi edit "{{target}}"` | Edit a target's source representation. |
| Dotfiles · Apply one reviewed target | `chezmoi apply "{{target}}"` | Apply only the target already reviewed. |
| Dotfiles · Verify targets | `chezmoi verify` | Verify managed target state. |

Safe edit cycle:

```bash
chezmoi edit "$HOME/.zshrc"
chezmoi diff
chezmoi apply "$HOME/.zshrc"
chezmoi verify
```

The apply workflow intentionally requires a target. Applying the complete
source remains a conscious terminal action after reviewing the complete diff.

## 05 · Toolchains

| Workflow | Command | Purpose |
|---|---|---|
| Toolchains · Show installed versions | `for tool in fnm node npm pnpm uv; do …; done` | Report selected tools without failing for an unselected stack. |
| fnm · Show current Node | `fnm current` | Print the active fnm-managed Node. |
| fnm · Install and use current LTS | `fnm install --lts --use` | Install and activate the current LTS. |
| npm · List project scripts | `npm run` | List scripts in the current npm project. |
| npm · Audit dependencies | `npm audit` | Report vulnerabilities without auto-fixing. |
| pnpm · Install frozen dependencies | `pnpm install --frozen-lockfile` | Reproduce `pnpm-lock.yaml` without changing it. |
| pnpm · Audit dependencies | `pnpm audit` | Report vulnerabilities without auto-fixing. |
| pnpm · Check store status | `pnpm store status` | Check content-addressed store integrity. |
| Python · List uv interpreters | `uv python list` | List available and installed Python interpreters. |
| Python · Sync locked environment | `uv sync --locked` | Reproduce `uv.lock` without changing it. |

Run project dependency commands from the project root. Respect its lockfile
and declared runtime rather than replacing them with a global preference.

## 06 · Homebrew

| Workflow | Command | Purpose |
|---|---|---|
| Homebrew · Check Brewfile | `brew bundle check --file="$HOME/Brewfile" --no-upgrade` | Check Phase 8 desired state without installing. |
| Homebrew · List outdated packages | `brew outdated --greedy` | List outdated formulae and casks. |
| Homebrew · Refresh package metadata | `brew update` | Refresh metadata without upgrading packages. |
| Homebrew · Run doctor | `brew doctor` | Report Homebrew health warnings. |
| Homebrew · Preview cleanup | `brew cleanup --dry-run` | Preview removable old versions and downloads. |
| Homebrew · Preview autoremove | `brew autoremove --dry-run` | Preview unused dependencies. |

`brew update` refreshes catalogue data; it does not upgrade installed packages.
This bundle omits a broad `brew upgrade` because upgrades should be reviewed
against active projects and the current Brewfile first.

## 07 · AI workspaces

| Workflow | Command | Purpose |
|---|---|---|
| AI workspace · Create an untitled task | `day-one-mac workspace create-task …` | Create a unique stable task below `_Projectless/tasks/<year>`. |
| AI workspace · Create a named task | `day-one-mac workspace create-task …` | Create a titled task with validated metadata and shared agent instructions. |
| AI workspace · List projectless tasks | `day-one-mac workspace list` | Show saved status, primary client, title, and path. |
| AI workspace · Open this task in VS Code | `day-one-mac workspace open-vscode "$PWD"` | Validate and open only the current task. |
| AI workspace · Start a new Codex chat here | `day-one-mac workspace start-codex "$PWD"` | Start approval-gated Codex in the validated task. |
| AI workspace · Start a new Claude Code chat here | `day-one-mac workspace start-claude "$PWD"` | Start a named Claude session in Plan mode. |
| AI workspace · Start a new Copilot CLI chat here | Validates with `day-one-mac workspace status` first | Start a Copilot CLI conversation. |
| AI workspace · Open a new Copilot app session here | Validates with `day-one-mac workspace status` first | Open the Copilot app from this task. |

Run a create workflow first. The terminal changes into the new folder, so the
matching launch workflow can use the current directory without requiring a
personal absolute path. Launch workflows refuse the `_Projectless` container,
legacy folders without the control files, and unrelated directories.

## If the runtime is missing or points to a removed checkout

Install the latest verified standalone release. Existing phase fingerprints
and machine choices remain under `~/.day-one-mac`; updating the runtime does
not reset them:

```bash
day-one-mac update
day-one-mac runtime-status
day-one-mac root
```

Do not edit the generated launcher to embed a personal path; chezmoi owns it
and the machine-local runtime record is the intended indirection. Contributors
using linked mode should reinstall linked mode from their chosen source path.
