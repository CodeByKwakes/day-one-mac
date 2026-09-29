[← Start Here](../START-HERE.md) · **Command reference** · [Process overview](../PROCESS-OVERVIEW.md) · [Removal and reset](../04-operations/REMOVE-DAY-ONE-MAC.md)

# Day One Mac command reference

This page lists every supported user-facing Day One Mac command, its direct
script equivalent, and when to use it. It does not list files below
`scripts/lib/` or `scripts/tests/` as setup commands: those are internal
libraries and regression fixtures.

## Understand the two command forms

### Portable command — recommended from the beginning

Install the public, checkout-independent runtime:

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

It installs a versioned runtime under `~/.local/share/day-one-mac` and works
from any directory without a Git checkout. The runtime installer remains the
launcher's owner; Phase 5 must not adopt it into chezmoi. See
[Install and manage the standalone runtime](PORTABLE-COMMAND.md).

### Direct scripts — fallback and maintenance

From either the installed runtime or a development checkout:

```bash
cd "$(day-one-mac root)/scripts"
./bootstrap-day-one-mac.sh --wizard
```

Direct scripts are primarily for development and documented troubleshooting.

Check the portable command before relying on it:

```bash
day-one-mac help
day-one-mac --status
```

If the runtime command is deliberately removed, reinstall it using the reviewed
public installer or an offline release archive.

## Complete portable command list

Install this command before Phase 1; the standalone runtime remains its sole owner.
See [PORTABLE-COMMAND.md](PORTABLE-COMMAND.md) for installation,
updates and rollback.

| Portable command | Direct script equivalent | Use it when |
|---|---|---|
| `day-one-mac` | `./bootstrap-day-one-mac.sh` | Open the main setup wizard using saved choices when available. |
| `day-one-mac bootstrap [options]` | Downloaded-dispatcher operation | Clone or reuse the project and install the portable command before Phase 1. |
| `day-one-mac help` | No exact script; dispatcher help | See the installed top-level commands. `-h` and `--help` are equivalent. |
| `day-one-mac --version` | Read the active runtime's `VERSION` | Print the runtime or checkout version. `version` is an alias; this does not check for updates. |
| `day-one-mac root` | Read `~/.day-one-mac/runtime-root` | Print the active standalone runtime or linked development root. |
| `day-one-mac runtime-status` | `./runtime-manager.sh status` | Show the active version, location and checksum result. |
| `day-one-mac update` | `./runtime-manager.sh update` | Download and install the latest verified public release beside the current version. |
| `day-one-mac rollback-runtime [options]` | `./runtime-manager.sh rollback [options]` | Preview or select a previous installed runtime without undoing setup changes. |
| `day-one-mac uninstall-runtime [options]` | `./runtime-manager.sh uninstall [options]` | Remove only the launcher and runtime while preserving setup state and the configured environment. |
| `day-one-mac docs [TOPIC] [--open]` | `./runtime-manager.sh docs …` | List, locate, or open documentation inside the active runtime. Topics include `chezmoi`, `optional`, and `advanced`; use `--list` for all topics or `--folder --open` for the complete documentation folder. |
| `day-one-mac docs [TOPIC] --browser` | `./runtime-manager.sh docs …` | Open a temporary offline HTML reader. Use `handbook` for manual tasks or `chezmoi-guide` for the learning path. No server or extra runtime is needed. |
| `day-one-mac docs export --format html\|markdown --output NEW_DIRECTORY` | `./runtime-manager.sh docs export …` | Export bundled project guides and examples to a new directory. See [contents, printing and safety](DOCUMENTATION-COMMANDS.md). |
| `day-one-mac shell-status` | `./shell-status.sh` | Run a read-only check of Homebrew zsh, startup files, clean-shell PATHs, completions and selected tools. |
| `day-one-mac setup [options]` | `./bootstrap-day-one-mac.sh [options]` | Start, resume, inspect, or reset the required eight-phase setup. |
| `day-one-mac install [options]` | `./bootstrap-day-one-mac.sh --install-centre [options]` | Install or revalidate required applications and command-line tools after Phase 2. |
| `day-one-mac applications [options]` | `./application-status.sh [options]` | Check required or optional application ownership and resolve selected missing apps. |
| `day-one-mac ssh-pin [github\|azure\|both]` | `./bootstrap-day-one-mac.sh --ssh-pin …` | Export reviewed 1Password SSH public keys to stable `~/.ssh` public-key files. |
| `day-one-mac macos-settings [options]` | `./configure-macos-settings.sh [options]` | Configure, inspect, preview, or restore optional Finder, Dock, keyboard, and trackpad preferences. |
| `day-one-mac workspace [command]` | `./workspace-manager.sh [command]` | Create, inspect, complete, or open a bounded projectless task. |
| `day-one-mac raycast [options]` | `./configure-raycast.sh [options]` | Choose `alongside-spotlight` or `raycast-only` launcher guidance, then preview, generate, inspect, or archive the optional track-aware Raycast Script Commands. Raycast uses `⌥Space` in both modes. |
| `day-one-mac optional --guided` | `./bootstrap-day-one-mac.sh --optional --guided` | Choose optional modules after required Phase 8 passes and continue to available installers. |
| `day-one-mac optional --list` | `./optional-module.sh --list` | List executable versus guided module capabilities, not completion. |
| `day-one-mac optional --module ID --plan\|--apply\|--check\|--resume` | `./optional-module.sh [options]` | Modules 09/10/13 install selected payloads; 10A manages an owned gateway; 11/12/14 generate review artifacts only. Apply/resume requires Phase 8; see [Module execution](MODULE-EXECUTION.md). |
| `day-one-mac optional --status [options]` | `./optional-status.sh [options]` | Show one read-only status dashboard for Modules 09–22 or write the combined module, environment, and repository audit. Compatibility aliases: `day-one-mac optional-status` and `day-one-mac modules`. |
| `day-one-mac databases [options]` | `./configure-databases.sh [options]` | Install, resume, inspect, or verify the selected PostgreSQL, Redis, and MongoDB containers. |
| `day-one-mac safety-report [options]` | `./preflight-audit.sh [options]` | Create the read-only Stage 0 report on an existing Mac before choosing a reset or cleanup route. |
| `day-one-mac prepare-existing [options]` | `./prepare-existing-mac.sh [options]` | Open the resumable Route A/Route B dashboard for a Mac that already contains data or setup. With no arguments, the portable command adds `--guided`. |
| `day-one-mac inventory [options]` | `./application-inventory.sh [options]` | Write a complete report of Homebrew, Mac App Store, system, and other application bundles. |
| `day-one-mac advanced [options]` | `./advanced-setup.sh [options]` | Read and track advanced Modules 15–22. No action flag means guide-only behaviour. |
| `day-one-mac advanced --module 16 --inventory\|--plan\|--apply\|--check\|--resume` | `./optional-module.sh --module 16 [options]` | Inventory or install a reviewed software selection; `--manifest PATH` supplies a two-column TSV for plan/apply/check. Accounts, Brewfile edits and removals remain manual. |
| `day-one-mac advanced --module 15\|17 --plan\|--apply\|--check\|--resume` | `./optional-module.sh --module ID [options]` | Choose ID 15 for allowlisted dotfile evidence/proposals or 17 for reviewed shell bundles. Use `--manifest PATH`; neither imports dotfiles nor activates shell configuration. |
| `day-one-mac advanced --module 19 --plan\|--apply\|--check\|--resume` | `./optional-module.sh --module 19 [options]` | Apply explicit scalar preferences with typed originals, pending-write recovery and conflict checks. Never changes security controls or restarts applications. |
| `day-one-mac advanced --module 18 --plan\|--apply\|--check\|--resume` | `./optional-module.sh --module 18 [options]` | Review selected checkout identities, signing settings and worktree layout; generate configuration proposals only. Node 22+ required. |
| `day-one-mac advanced --module 20 --plan\|--apply\|--check\|--resume` | `./optional-module.sh --module 20 [options]` | Use `--manifest PATH` to stage explicit checksummed files from a mounted backup, or record no-restore. Never overwrites live data; Node 22+ required. |
| `day-one-mac advanced --module 21 --plan\|--apply\|--check\|--resume` | `./optional-module.sh --module 21 [options]` | Preview/check bounded setup evidence without writes, or save a versioned snapshot and compare it to the previous one. Never upgrades, cleans or rebuilds. |
| `day-one-mac advanced --module 22 --plan\|--apply\|--check\|--resume` | `./optional-module.sh --module 22 [options]` | Use `--manifest PATH` for explicit skill/MCP metadata ownership and drift snapshots. Never executes skills or changes client trust. |
| `day-one-mac advanced-audit [options]` | `./advanced-audit.sh [options]` | Generate the private, extended environment and repository report. |
| `day-one-mac cli-tools [options]` | `./configure-cli-tools.sh [options]` | Select and install optional Homebrew formulae without removing unselected tools. |
| `day-one-mac finalize [options]` | `./finalize-setup.sh [options]` | Review or compact setup evidence after Phase 8, or deliberately detach the setup system. |
| `day-one-mac remove [options]` | `./remove-day-one-mac.sh [options]` | Choose a recorded, sectional, or full removal plan with an ownership-aware preview. |
| `day-one-mac rollback [options]` | `./rollback-recorded-setup.sh [options]` | Preview or reverse only changes recorded as belonging to Day One Mac. |
| `day-one-mac reset-development [options]` | `./clean-development-state.sh [options]` | Preview a broad reset that can remove **all** Homebrew packages and Homebrew, not just Day One-owned items. `clean` remains a compatibility alias with the same warning. |
| `day-one-mac verify` | `./verify.sh` | Verify installed runtime integrity and syntax without running setup. |
| `day-one-mac validate` | `./validate.sh` (checkout only) | Run contributor regression checks from a checkout; alias for `verify` in an installed runtime. |

Use the current names in this reference for new notes and Warp workflows.
Machines upgraded from a pre-standalone installation can consult
[Upgrade notes](UPGRADE-NOTES.md) for accepted aliases and state migration.

## Required setup commands

### Main wizard and eight phases

```bash
day-one-mac --guided
day-one-mac --status
day-one-mac setup --phase 05
day-one-mac setup --dry-run
day-one-mac setup --reset-progress
```

Direct equivalents:

```bash
./bootstrap-day-one-mac.sh --guided
./bootstrap-day-one-mac.sh --status
./bootstrap-day-one-mac.sh --phase 05
./setup.sh --guided
./setup.sh --phase 05
```

Use `bootstrap-day-one-mac.sh` for the normal choice-first experience. Use the
lower-level `setup.sh` only when following a phase guide or troubleshooting the
eight-phase engine directly.

Important setup selectors include:

```text
--track 1|2|3
--stack node|python|both
--name "Full Name"
--email ADDRESS
--preset core|recommended-productivity
--primary-ide vscode|other
--dotfiles-repo URL
--new-dotfiles
--dotfiles-versioning git|local
--local-dotfiles
--macos-settings ask|configure|skip
--app-install-policy prompt|homebrew|check-only
--phase NN
--dry-run
--status
--reset-progress
```

Run `day-one-mac setup --help` or `./bootstrap-day-one-mac.sh --help` before
using unattended flags. `--yes` accepts ordinary confirmations; it does not
bypass typed destructive confirmations or select an application owner.

### Required-phase action contract

These actions apply to required Phases 1–8. They share the action names used by
optional modules, but are not transactions or saved execution plans. The
[beginner walkthrough](../01-required/README.md#preview-apply-check-and-resume)
shows one complete selection example.

| Action | Behaviour | Writes setup state? |
|---|---|---|
| `setup --plan` | Describe selected phase effects and manual gates; require an explicit or saved track and stack. | No |
| `setup --apply` | Save choices and run selected phases in phase order, even when markers are current. | Yes |
| `setup --check` | Inspect local prerequisites with no sign-in, network probe, template rendering, shell startup or report generation. | No |
| `setup --resume` | Reuse saved choices; skip only current markers with a `pass` or `not-required` local result. Otherwise rerun existing phase gates. | Yes |
| `setup --status` | Show saved choices and recorded completion. Text status also inspects Installation Centre readiness; JSON status does not. | No |

With no `--phase`, actions cover all eight phases. Repeat `--phase NN` to select
several; explicit actions visit them once each in ascending phase order. A
full apply/resume also runs the optional macOS settings checkpoint and required
Installation Centre. Selected Phases 3–8 can invoke the Installation Centre
when it is not current, so selecting one phase is not a guarantee of no package
installation.

Plan/check use supplied choices before saved choices, then defaults for optional
selectors. A plan is not saved: repeat the reviewed choices when applying.
Resume requires a complete saved selection and rejects selection-changing flags
such as `--stack`, `--auth-mode`, `--new-dotfiles` and `--macos-settings`.
Use plan/apply to change choices deliberately. The application-install policy
may still be supplied for a resumed run.

Choose only one action. Do not combine it with `--dry-run`, `--reset-progress`,
`--install-centre` or `--ssh-pin`. Inspection rejects `--yes` and
`--accept-preparation`. When explicit apply/resume includes Phase 1 with `--yes`,
it also requires `--accept-preparation`: your assertion that macOS is updated
and prior data is backed up or the machine contains only disposable test data.
That flag is not independent backup evidence. Interactive runs ask instead.
There is no general unattended guarantee: accounts, passphrases, administrator
approval and GUI operations can still need your participation.

### Local check coverage and limits

| Phase | Local evidence inspected | What remains manual or outside this check |
|---|---|---|
| 1 | Populated author identity | Current updates and verified backup/disposable-data assertion |
| 2 | Selected developer-tools directory and native Homebrew executable | Tool compatibility, licence, update and Homebrew health |
| 3 | FileVault, SSH configuration, selected encrypted key or 1Password payload/CLI | Agent access, registration, signing, recovery-method custody |
| 4 | Command availability, selected Git identity, ghq root, required app payloads | Hosting sessions, SSH reachability, complete Git defaults |
| 5 | Required dotfile paths, commands and launcher | chezmoi ownership/drift, template effects, clean-shell behaviour |
| 6 | Current-PATH tool commands and Node-mode pnpm directory | Node LTS selection and working uv-managed Python |
| 7 | VS Code payload, command and settings file; not required for core | Effective safety settings and GUI launch |
| 8 | Aggregate local checks, runtime verification and Brewfile presence | Source secret scan, remote privacy/push or local backup, Brewfile management |

Presence is not configuration correctness. `manual` results remain even after a
successful earlier acceptance run. At present, only Phase 7 with the core preset
has no manual gate; resume therefore normally reruns the other phases. No check
marks a phase complete. Phase 8 **apply** still writes `verification.md` and can
create/adopt a missing Brewfile; Phase 8 **check** does neither.

### Inspection output and exit codes

```bash
day-one-mac setup --plan --track 1 --stack both --json
day-one-mac setup --check --phase 05 --json
day-one-mac setup --status --json
```

JSON is available only for plan/check/status. Successful inspection requests
emit one object on stdout with `schema_version: 1`, `action`,
`scope: "local-read-only"`, `selection`, `phases`, and `exit_code`. `checked_at`
is a UTC timestamp for check, otherwise `null`. A phase entry has `phase`,
`recorded` (`pending`, `changed`, `current`), `live` (`not-checked`, `pass`,
`fail`, `manual`, `not-required`), `impact`, and human-readable `details`.
Parse the structured fields rather than the details text. Author identity and
credentials are not emitted in these JSON objects.

Invalid arguments/platform or missing required choices produce an error on
stderr and may produce no JSON. Check output remains valid JSON when its exit
code is nonzero. Check timestamps are observations, not saved attestations.

| Exit code | Meaning |
|---:|---|
| 0 | Requested inspection succeeded with no failed/manual checks, or action completed |
| 2 | Invalid arguments, incomplete selections or unsupported check/apply platform |
| 10 | Manual action or verification remains |
| 11 | A local check or setup gate failed; takes precedence over manual checks |

Legacy commands and subprocess failures can also return other nonzero codes;
do not treat an unlisted code as success. JSON status is not machine health,
and exit 0 from plan is not approval to apply.

### Compatibility and validation scope

The no-argument wizard, `--guided`, implicit apply (`setup --phase 05`), and
legacy `--dry-run` remain available. The wizard's historical marker-based resume
is unchanged; use explicit `setup --resume` for the additional local checks.
Existing markers can become `changed` after runner/library changes even if the
Mac itself has not changed. This release keeps conservative fingerprints.

`verify` checks runtime integrity and script syntax, not full machine readiness.
`validate` prints its scope: contributor regression suites in a source checkout,
runtime integrity only in an installed package. Use `setup --check` for bounded
local inspection and Phase 8 apply for the existing acceptance gates.

For optional modules, `optional --status --check` and
`optional --check --status` both select the dashboard. Combining `--status`
with a module selection or apply/plan/resume action is rejected rather than
silently choosing one route.

### Installation Centre and application ownership

```bash
day-one-mac install
day-one-mac applications --required
day-one-mac applications --optional
day-one-mac applications --id raycast
day-one-mac applications --id obsidian --install-missing
day-one-mac applications --required --install-missing \
  --app-install-policy homebrew
```

Use `install` for the required software checkpoint. Use `applications` for a
smaller ownership check or one selected application. The check accepts valid
Homebrew, Company Portal, Mac App Store, and manual installations; it does not
replace an existing externally managed application.

### 1Password public-key pinning

```bash
day-one-mac ssh-pin github
day-one-mac ssh-pin azure
day-one-mac ssh-pin both
```

Use this after the 1Password SSH agent contains the intended key. It stores
only reviewed public keys under `~/.ssh`; private keys remain in 1Password.

### macOS settings

```bash
day-one-mac macos-settings --wizard
day-one-mac macos-settings --preview
day-one-mac macos-settings --status
day-one-mac macos-settings --restore
```

The wizard is optional. Restore uses values captured before the first Day One
change; it does not guess an Apple default.

### Raycast commands and extension recommendations

```bash
day-one-mac raycast --wizard
day-one-mac raycast --preview
day-one-mac raycast --launcher-mode alongside-spotlight --preview
day-one-mac raycast --launcher-mode raycast-only --preview
day-one-mac raycast --status
day-one-mac raycast --extensions
day-one-mac raycast --remove-generated
```

Use this after installing the portable `day-one-mac` command. The
wizard asks for launcher guidance, reads the saved hosting track and AI-client
selection, then writes a separate Script Command directory under
`~/.local/share/day-one-mac/raycast`. Both launcher modes assign `⌥Space` to
Raycast; the choice controls whether Spotlight keeps `⌘Space`. The script saves
the intended mode but does not install Store extensions, edit macOS shortcuts,
or edit Raycast's private settings. See
[Use Day One Mac from Raycast](../10-app-guides/RAYCAST-COMMANDS.md).

## Projectless workspace commands

```bash
day-one-mac workspace --guided
day-one-mac workspace init
day-one-mac workspace create-task --title "Research topic" \
  --kind research --client codex --sensitivity private
day-one-mac workspace list
day-one-mac workspace status "$TASK_DIR"
day-one-mac workspace open-vscode "$TASK_DIR"
day-one-mac workspace start-codex "$TASK_DIR"
day-one-mac workspace start-claude "$TASK_DIR"
day-one-mac workspace complete "$TASK_DIR"
```

Use these only for standalone file-based work that does not belong to a Git
repository. Existing repository changes belong in a Git worktree. See
[AI workspaces](AI-WORKSPACES.md) for the folder and trust boundaries.

## Existing-Mac Stage 0 commands

### Safety report only

```bash
day-one-mac safety-report --guided
day-one-mac safety-report --plan
day-one-mac safety-report --output "/absolute/private/report-folder"
```

This is read-only apart from writing its report. It is not a backup.

### Resumable preparation dashboard

```bash
day-one-mac prepare-existing
day-one-mac prepare-existing --status
day-one-mac prepare-existing --safety-report
day-one-mac prepare-existing --dry-run
```

Use the guided dashboard for normal Route A or Route B work. Direct archive and
apply flags are documented by:

```bash
./prepare-existing-mac.sh --help
```

Do not construct a Route B apply command from memory.

## Reports, optional tools, and advanced modules

```bash
day-one-mac inventory
day-one-mac inventory --output "/absolute/path/applications.md"

day-one-mac cli-tools --list
day-one-mac cli-tools --check
day-one-mac cli-tools --packages eza,fd,lazygit --dry-run

day-one-mac databases --saved
day-one-mac databases --services postgres,redis --dry-run
day-one-mac databases --saved --check

day-one-mac optional --status
day-one-mac optional --status --check
day-one-mac optional --status --audit

day-one-mac advanced --list
day-one-mac advanced --status
day-one-mac advanced --module 18
day-one-mac advanced --complete 18
day-one-mac advanced --reset 18

day-one-mac advanced-audit --stdout
day-one-mac advanced-audit --check
```

The advanced tracker records documentation progress; it does not silently
implement an advanced module.

## Finalisation, rollback, and removal

These commands are deliberately preview-first:

```bash
day-one-mac finalize --status
day-one-mac finalize

day-one-mac rollback
day-one-mac remove --guided
day-one-mac remove --inventory
day-one-mac reset-development
```

Execution requires an explicit mode:

```bash
day-one-mac finalize --execute
day-one-mac rollback --execute
day-one-mac remove --guided --execute
day-one-mac reset-development --execute --archive-root "/absolute/recovery/parent"
```

Choose the narrowest tool:

| Goal | Command |
|---|---|
| Keep setup but compact evidence | `day-one-mac finalize` |
| Reverse only manifest-recorded changes | `day-one-mac rollback` |
| Select recorded changes or sections interactively | `day-one-mac remove --guided` |
| Remove all Homebrew development state with recovery options | `day-one-mac reset-development` |

`clean` is a compatibility alias for the broad reset, **not cache cleanup**.
Use `finalize` only for setup-evidence compaction; it preserves installed tools
and current recovery records. Neither operation deletes an acceptance VM,
revokes test credentials, or removes ad-hoc rehearsal logs. Export and verify
private evidence before considering those separate cleanup actions.

Read [Removal and reset](../04-operations/REMOVE-DAY-ONE-MAC.md) before executing any of them.

## Script-only maintenance commands

These have no portable dispatcher word because they maintain the repository
rather than a configured Mac:

| Direct command | Purpose |
|---|---|
| `./validate-warp-drive.sh` | Validate the 63 importable Warp workflows and their safety rules. |
| `./lint.sh` | Run ShellCheck over every project shell script. Requires `shellcheck`. |
| `./lint.sh --severity warning --format gcc` | Run a narrower machine-readable lint report. |

`./validate.sh` is contributor-only and is excluded from the standalone runtime.
Use `day-one-mac verify` on an installed Mac.

Do not execute files under `scripts/lib/`; they are sourced by other scripts.
Do not use files under `scripts/tests/` as setup entry points; the validator
runs those fixtures in isolated temporary homes.

## Get exact option help

Portable examples:

```bash
day-one-mac help
day-one-mac setup --help
day-one-mac applications --help
day-one-mac raycast --help
day-one-mac workspace --help
day-one-mac remove --help
```

Direct-script examples:

```bash
./bootstrap-day-one-mac.sh --help
./configure-raycast.sh --help
./prepare-existing-mac.sh --help
./clean-development-state.sh --help
./rollback-recorded-setup.sh --help
```

The command's own `--help` output is authoritative for flags. This document is
the authoritative map between portable command names, scripts, and intended
use.

---

[← Start Here](../START-HERE.md) · [Process overview](../PROCESS-OVERVIEW.md) · [Removal and reset](../04-operations/REMOVE-DAY-ONE-MAC.md)
