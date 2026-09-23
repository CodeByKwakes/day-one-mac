[← Project home](../README.md) · **Phase 1** · [Early macOS settings →](MACOS-SETTINGS.md)

# Phase 1 — First boot and setup decisions

**Time:** 20–45 minutes plus system updates · **Required:** everyone

## Outcome

At the end of this phase, the permanent administrator account is ready, macOS
is current, the old computer's data is safely out of scope, and the runner has
the decisions it needs: hosting track, development stack, Git identity, primary
IDE behavior, and dotfiles protection. The next checkpoint is the optional macOS Settings Wizard,
which can be completed before Phase 2 or intentionally skipped and run later.
No development packages are installed yet.

## How to use this phase

Read the preparation steps, then use the wizard in Step 1.9. Step 1.8 explains
the dotfiles-protection choice that the wizard will ask you to make. The wizard
is the recommended route and asks for the decisions described below. Earlier command
blocks are checks or explanations; do not repeat them after the phase passes.
The [Start Here guide](../START-HERE.md) explains Terminal, placeholders, preview
mode, and how to resume.

## Before you begin

Keep these nearby:

- The administrator password for this Mac.
- A trusted device for Apple, GitHub, Azure, and 1Password sign-in.
- The 1Password account emergency kit or another verified recovery method.
- Confirmation that old documents and repositories exist in a separate backup.
- Work account details if this Mac will access Azure DevOps.

Do not paste access tokens into Terminal. Browser or device-code login is used
later.

### If this Mac is not actually clean

Do not confirm the clean-machine gate yet. Open
[Stage 0 — Safely prepare an existing Mac](../00-preflight/README.md). The wizard
first explains Route A and Route B. Both start with a read-only safety report
that finds applications, packages, containers, startup components, dirty Git
repositories, and repositories with no remote copy.

The factory-reset route is the standard boundary for this phase. The
account-preserving route is supported only when you accept that unknown macOS
and application settings can remain.

## Day-zero requirement and standalone installation

The normal setup does not require a permanent Git checkout. On a clean Mac,
request Apple's command-line tools first:

```bash
xcode-select --install
```

A dialog appears offering to install the tools; choose **Install** and wait for
it to finish. If the tools are already present you will instead see this, which
is not an error:

```text
xcode-select: note: Command Line Tools are already installed,
use "Software Update" in System Settings to install updates
```

Download and inspect the public installer:

```bash
INSTALLER="$HOME/Downloads/install-day-one-mac"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
  -o "$INSTALLER"
chmod 700 "$INSTALLER"
less "$INSTALLER"
"$INSTALLER"
```

Press `q` after reviewing the installer in `less`. The verified runtime is
stored under `~/.local/share/day-one-mac`. Contributors may additionally
clone the public repository under `~/Developer/github.com/CodeByKwakes`; that
checkout is not required for ordinary setup. The complete filesystem map is
documented in [EXPECTED-LAYOUT.md](../20-reference/EXPECTED-LAYOUT.md).

## Step 1.1 — Finish Setup Assistant

Create the user account you intend to keep. The short username becomes part of
paths such as `/Users/<name>` and should not be changed midway through setup.

Verify it:

```bash
id -un
printf 'Home: %s\n' "$HOME"
dscl . -read "/Users/$(id -un)" RealName UserShell
```

Sample output, where the short username is `alex`:

```text
alex
Home: /Users/alex
RealName: Alex Smith
UserShell: /bin/zsh
```

Expected results:

- `id -un` prints the chosen short username.
- `$HOME` is `/Users/<short-name>`.
- `UserShell` is `/bin/zsh`. Phase 5 later offers to change this to the
  Homebrew zsh; at this point the macOS default is what you expect.

If any value is wrong, correct the account before creating repositories or
dotfiles.

## Step 1.2 — Update macOS completely 🔴

Open **System Settings → General → Software Update**. Install every available
macOS update and restart when requested. Reopen the same panel after each
restart until no additional update is offered.

Then check the installed system:

```bash
sw_vers
uname -m
```

`uname -m` must report `arm64`. Day One Mac supports Apple-silicon Macs only
and refuses Intel hardware or a terminal running under Rosetta. Homebrew must
use its native `/opt/homebrew` prefix.

Apple Account sign-in is optional for the base toolchain. It becomes useful for
App Store applications and VS Code Settings Sync, but it should not block this
phase.

## Step 1.3 — Confirm the clean-machine boundary 🔴

This project assumes the machine itself contains nothing that must be migrated.
Before confirming the runner prompt, verify at least one old backup by opening
several representative files and checking that important repositories exist on
their remotes.

Do not copy an old home directory over the clean account. Later, restore only
documents or project files you have intentionally selected. Old caches,
package-manager directories, SSH agents, and application preferences are not
part of this workflow.

If Stage 0 performed an account-preserving cleanup, also review its generated
`settings-scope.md`. Confirm this phase only if the cleanup completed, its
external recovery directory is readable, the Mac was restarted, and the
remaining account-level state is acceptable.

## Step 1.4 — Select a hosting track

Choose exactly one:

| Track | Select when | What later phases do |
|---|---|---|
| **1 — GitHub** | Repositories are hosted only on GitHub | Install `gh`, create `~/Developer/github.com`, and verify GitHub SSH |
| **2 — Azure DevOps 🏢** | Work is hosted only in Azure DevOps | Install `az`, create only the Azure host folder, and omit every GitHub gate |
| **3 — GitHub + Azure DevOps 🏢** | This Mac uses both providers | Install `gh` and `az`, create both host folders, and verify both |

The track controls hosting only. It does not force Docker, AI clients, the
OmniRoute gateway, MCP, or VS Code profiles.

## Step 1.5 — Select the development stack

Choose `node`, `python`, or `both`:

| Choice | Installed in the required route |
|---|---|
| `node` | fnm, current Node LTS, npm, pnpm |
| `python` | uv and a uv-managed Python interpreter |
| `both` | All Node and Python items |

Select only what is needed now. The other stack can be added later by rerunning
Phases 4 and 6 with a new `--stack` value.

## Step 1.6 — Choose the Git identity

Decide the author name and primary email for commits created on this Mac:

```text
Name:  Your display name
Email: your-address@example.com
```

For a work-only Mac, the work email can be primary. For a personal-only Mac,
use the personal address. On a mixed machine, start with the most common
identity and override individual repositories when necessary:

```bash
cd /path/to/repository
git config user.name "Your Name"
git config user.email "work@example.com"
```

That command is repository-local and does not modify the global default.

## Step 1.7 — Choose whether VS Code is the primary IDE

VS Code remains part of the small required base because projects and company
workflows may expect it. This choice controls only Git integration:

| Choice | Git behavior |
|---|---|
| **Yes — VS Code is primary** | Configure VS Code for commit messages, visual diffs and merge conflicts |
| **No — another IDE is primary** | Do not add or change Git editor, diff or merge-tool settings |

Selecting **No** does not uninstall VS Code. It also does not erase an editor
setting that already belongs to you or company policy.

## Step 1.8 — Choose chezmoi protection

chezmoi always manages the selected dotfiles, but Git version history is a
choice:

| Choice | Phase 8 requirement | Recovery trade-off |
|---|---|---|
| **Private Git — recommended** | Clean source, private matching remote, reachable pushed branch | Version history and another-machine recovery |
| **Local-only** | Readable source and secret scan; no repository or remote gate | No version history; `~/.local/share/chezmoi` must be included in an encrypted backup |

Local-only does not make chezmoi temporary and does not remove existing Git
metadata. Select it for a new source when policy or preference forbids a
dotfiles repository.

## Step 1.9 — Start the wizard

From this project's scripts directory, start the Day One Mac wizard:

```bash
day-one-mac
```

Use Up/Down (or `j`/`k`) to move. Space or Enter accepts one highlighted
choice. On a multi-choice screen, Space toggles an item and Enter accepts the
whole list. The
wizard collects only the decisions needed by the required phases:

1. Hosting track.
2. Node, Python, or both development stacks.
3. Primary Git name and email.
4. Whether VS Code should be Git's primary editor and visual comparison tool.
5. A new chezmoi source protected by private Git, a new local-only source, or
   an existing private dotfiles repository.

Required phases display 🔒 because they cannot be removed; this symbol does
not mean they are already complete. Review the required-base summary
and select **Save choices and begin or resume setup** to continue. Phase 1 then
asks the mandatory macOS-update and backup-readiness question before it records
completion. A separate checkpoint then offers the optional
[macOS Settings Wizard](MACOS-SETTINGS.md) before Phase 2.

The setup does not ask about databases, AI clients, MCP servers, profiles, or
other extras until all eight required phases pass. At that point choose
**Finish and exit** or open the optional setup centre. To open it later, run:

```bash
day-one-mac optional --guided
```

To walk through the same wizard and preview the selected base without saving
choices, run:

```bash
day-one-mac --wizard --dry-run
```

Saved values can be reviewed at any time:

```bash
day-one-mac --status
```

They and a readable `wizard-selections.md` review are stored with private-user
permissions under `~/.day-one-mac/`. Starting the wizard again offers to
resume or revise them. Editing the state files manually is discouraged; use
the wizard or pass an explicit option and rerun the affected phase instead.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| The Mac offers another update after restarting | Install it; Phase 1 is not complete until the panel is current |
| `$HOME` or the short username is wrong | Stop and fix the macOS account before continuing |
| You are unsure between Tracks 1 and 3 | Choose Track 3 only if both GitHub and Azure DevOps will be used on this Mac |
| A work email should apply to only one repository | Keep the normal primary email and set a repository-local identity later |
| The backup cannot be opened | Stop; do not confirm readiness until the backup is independently readable |

## Phase 1 completion checklist 🚦

- [ ] macOS Software Update reports no outstanding update.
- [ ] The administrator short username and `$HOME` are final.
- [ ] `day-one-mac runtime-status` reports a verified standalone runtime.
- [ ] Old data exists in a separate, readable backup.
- [ ] Route A finished an Apple factory reset, or Route B finished the Stage 0
      account cleanup and I accepted its residual-state warning.
- [ ] One hosting track is selected.
- [ ] One development stack is selected.
- [ ] Git author name and primary email are correct.
- [ ] The primary-IDE choice matches how Git should open editors and conflicts.
- [ ] `day-one-mac --status` shows the saved choices.

Do not advance while any item above is uncertain.

---

[← Project home](../README.md) · [Continue to early macOS settings →](MACOS-SETTINGS.md)
