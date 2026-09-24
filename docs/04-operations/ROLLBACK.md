[← Project home](../README.md) · [Phase 8](../01-required/08-verify-and-reproduce.md)

# Clean the development state without erasing the Mac

For an interactive choice between recorded-only, selected sections, and a full
development reset, use:

```bash
day-one-mac remove --guided
```

See [REMOVE-DAY-ONE-MAC.md](REMOVE-DAY-ONE-MAC.md). The rest of this document
describes the two underlying cleanup engines in detail.

This project provides two cleanup levels:

1. **Broad clean state** removes every Homebrew formula, every Homebrew cask,
   Homebrew itself, and archives known development configuration.
2. **Recorded rollback** removes only packages and paths the Day One Mac runner
   recorded as its own work.

Both tools are preview-first, write a log, and preserve recoverable copies of
configuration. Neither erases a drive, reinstalls macOS, deletes the user
account, disables FileVault, or removes applications that Homebrew does not
manage.

For an existing Mac **before** Phase 1, prefer the guided
[Stage 0 preparation route](../00-preflight/README.md). Its one guided command shows
Route A and Route B first, creates a plain-English safety report, checks the
encrypted external recovery boundary, copies and verifies a development
snapshot, records the restore confirmation and cleanup preview, and only then
delegates Route B work to the broad cleanup below. Its progress dashboard stays
open between safe steps and revalidates saved progress when resumed.

## Which cleanup should I use?

| Goal | Tool |
|---|---|
| Return this user account to a nearly blank development state | `clean-development-state.sh` |
| Choose Route A or Route B and safely prepare an existing Mac | `prepare-existing-mac.sh --guided` |
| Create only the Stage 0 read-only safety report | `prepare-existing-mac.sh --safety-report` |
| Undo only the eight-phase runner while preserving unrelated Homebrew tools | `rollback-recorded-setup.sh` |
| Choose packages, configuration, dotfiles, preferences, containers, state, or Developer content | `remove-day-one-mac.sh --guided` |
| Factory-reset or securely erase the Mac | Neither; use Apple's macOS recovery process |

Choose the **broad clean state** tool when the intended result is to remove the
development environment and all Homebrew-managed apps while preserving apps
that were installed by another method.

# Part A — Broad clean state

## A.1 What it removes or archives

The script inventories and removes:

- Every formula reported by `brew list --formula`.
- Every cask reported by `brew list --cask`, including the applications those
  casks installed.
- Homebrew services, taps, Homebrew-managed dependencies, and Homebrew itself.
- Common shell, Git, npm/pnpm/yarn, fnm/nvm/Volta/asdf, uv/pyenv/Poetry,
  Rust, Ruby, Java, Go, chezmoi, Starship, cloud/Kubernetes/Terraform, GitHub
  CLI, Azure CLI, MCP, Docker client, AI-client, and VS Code configuration.
- The Day One Mac runner's progress and ownership manifests.

Configuration is moved to a timestamped recovery directory instead of being
recursively deleted. The recovery bundle also receives:

```text
cleanup.log
operations.tsv                  machine-readable action and result log
cleanup-options.tsv             exact archive/zap choices required for resume
resume-summary.md               earlier failures versus latest resume results (resume only)
homebrew-formulae.txt
homebrew-casks.txt
homebrew-cask-details.txt
homebrew-taps.txt
Brewfile.before-cleanup
application-inventory.md
reinstall-inventories/        tool versions and reinstallable package/extension lists
settings-scope.md
high-risk-manual-actions.md
home/                         archived configuration tree
resume-additions/             settings recreated after an interrupted cleanup (only when needed)
README.md
homebrew-uninstall.sh         exact official script used for this run
SHA256SUMS.txt                 integrity checks for archived payload and static reports
SNAPSHOT-COMPLETE              completion marker tied to SHA256SUMS.txt
```

The Homebrew uninstall stage uses Homebrew's current official uninstall script
with `NONINTERACTIVE=1`. Review the downloaded copy retained in the recovery
bundle if the uninstaller reports anything left behind.

The final checksum pass excludes the two live log files (`cleanup.log` and
`operations.tsv`) because the script records final status in them afterward.
It also excludes the resume-only `resume-summary.md`, which is generated after
the final resume result is known and is derived entirely from `operations.tsv`.
Files are hashed in batches rather than by starting one process per file. The
terminal shows the total, percentage, rate, elapsed time, and estimated time
remaining. Do not disconnect the recovery volume. If interrupted after copying,
return to guided Step 3 and accept the resume option; it reuses the copied data
and continues from the last complete checksum batch. Later, verify the archived
payload and static reports from the bundle root with
`shasum -a 256 -c SHA256SUMS.txt`.

## A.2 What it always preserves

- The startup disk, macOS, recovery volume, user account, and ordinary personal
  documents.
- Applications that do **not** appear in `brew list --cask`.
- 1Password cloud vault/key data and macOS Keychain data.
- Known local 1Password data and SSH private keys under `~/.ssh`, unless their
  explicit archive flags are selected.
- Xcode Command Line Tools and macOS updates.
- Your login shell. Neither cleanup script runs `chsh` or edits `/etc/shells`
  — see "Restoring the login shell" below.
- `~/Developer` by default.
- Docker Desktop and OrbStack container/VM data by default.

Review `~/.day-one-mac/application-provenance.md` before rollback. It states
whether each checked application was Homebrew-managed, externally supplied, or
installed by Day One Mac. Company Portal and other external applications are
never added to the precise install manifest.

The script may archive configuration belonging to a preserved non-Homebrew app,
such as an AI client, because the goal is a clean development state. It does
not delete that application's executable or `.app` bundle unless Homebrew owns
the cask. AWS, Google Cloud, Kubernetes, Azure, GitHub CLI, and similar local
credential/config directories are moved into the protected recovery tree; they
are not printed or recursively deleted. Even with `--zap-cask-data`, the
1Password app cask is deliberately uninstalled without zap unless local
1Password archival was explicitly selected. Moving local app data does not
delete any cloud vault, item, key, passkey, or account.

### Restoring the login shell

Phase 5 can make Homebrew's zsh your login shell. That is the one macOS
account setting Day One Mac changes, and **neither cleanup script reverses it**,
because doing so silently would be a bigger surprise than leaving it.

If you remove Homebrew while `/opt/homebrew/bin/zsh` is still your login shell,
new terminals will fail to start. Undo it *before* a broad cleanup, or from any
working shell afterwards:

```bash
chsh -s /bin/zsh
```

The value Phase 5 replaced is recorded here, so you can confirm what to restore:

```bash
cat ~/.day-one-mac/previous-login-shell
```

```text
/bin/zsh
```

The `/opt/homebrew/bin/zsh` line appended to `/etc/shells` is harmless once the
binary is gone, but you may remove it with `sudo` if you prefer a tidy file.

## A.3 Preview first

Run from this project's scripts directory:

```bash
day-one-mac clean
```

The preview prints:

- Every installed Homebrew formula.
- Every Homebrew cask/application.
- Every `.app` bundle discovered in `/Applications`, `~/Applications`, and
  `/System/Applications`, with Homebrew ownership reported separately.
- Every existing configuration path that will be archived.
- Whether projects and container data will be kept or archived.
- The exact recovery destination.

Nothing is changed without `--execute`.

Save the preview if you want a separate review artifact:

```bash
day-one-mac clean \
  > "$HOME/Desktop/day-one-mac-cleanup-preview.txt"
```

Open the text file and confirm that every listed Homebrew cask really may be
removed. A manually downloaded application that happens to use the same app
name is not targeted unless Homebrew currently records the cask as installed.

## A.4 Choose the recovery location

The default is a timestamped directory directly under the home folder:

```text
~/Day-One-Mac-Clean-Recovery-YYYYMMDDTHHMMSSZ/
```

To store it on a mounted external volume, create and test the parent first:

```bash
mkdir -p "/Volumes/Backup Drive/Mac-cleanup-recovery"
test -d "/Volumes/Backup Drive/Mac-cleanup-recovery" \
  && test -w "/Volumes/Backup Drive/Mac-cleanup-recovery"
```

Then preview with the same path that execution will use:

```bash
day-one-mac clean \
  --archive-root "/Volumes/Backup Drive/Mac-cleanup-recovery"
```

The script refuses a missing, relative, unwritable, or dangerously broad
recovery parent. It also refuses to place recovery inside a directory selected
for archival.

## A.5 Choose how deep to clean

The normal broad execution preserves project and container data and uses a
normal cask uninstall:

```bash
day-one-mac clean --execute
```

That command proceeds without the matching data-archive option only when Docker
Desktop or OrbStack is not a Homebrew-installed cask. If either cask is present,
the script stops before changing anything because its vendor uninstaller may
remove local VM data. Select Docker Desktop and OrbStack independently in the
guided wizard.

For the closest recoverable equivalent to a blank development account, add the
explicit archive flags you have reviewed:

```bash
day-one-mac clean \
  --execute \
  --zap-cask-data \
  --archive-projects \
  --archive-docker-data \
  --archive-orbstack-data \
  --archive-1password-data \
  --archive-ssh-private-keys \
  --prepare-keychain-reset
```

These flags mean:

| Flag | Effect |
|---|---|
| `--zap-cask-data` | Asks Homebrew to remove support files declared in each cask's zap stanza; inspect carefully because these can be real application data |
| `--archive-projects` | Moves the complete `~/Developer` directory into recovery instead of deleting it |
| `--archive-docker-data` | Moves known Docker Desktop data into recovery |
| `--archive-orbstack-data` | Moves known OrbStack data into recovery |
| `--archive-1password-data` | Moves known local 1Password support data into recovery; writes separate cloud cleanup steps |
| `--archive-ssh-private-keys` | Detects private-key headers under `~/.ssh` and moves those keys plus matching `.pub` files into recovery |
| `--prepare-keychain-reset` | Writes Apple's manual default-Keychain reset procedure; it does not modify the Keychain during the script |
| `--archive-root PATH` | Places recovery under an existing absolute parent |
| `--yes` | Skips the typed confirmation; use only after saving and reviewing an identical preview |

`--archive-projects`, `--archive-docker-data`, and `--archive-orbstack-data` are recoverable moves, but
they can be large and slow. An external archive root should have enough free
space. Step 5 prints item count, bytes processed, percentage, elapsed time, and
estimated time remaining every 30 seconds while a long move is active. If the
destination does not measurably grow for five minutes, it offers a controlled
continue-or-stop choice instead of appearing frozen. Do not disconnect the
external drive while the move is running. The cleanup never zaps
1Password unless its local-data archive was selected. It also declines to zap
Docker Desktop or OrbStack unless its matching data option was selected first.
Quit the selected container application and 1Password before archiving their
live data. Credential archival requires the separate phrase `ARCHIVE LOCAL
CREDENTIALS`, even when `--yes` skips the ordinary confirmation.

Do not interrupt an active Step 5 simply to switch to a newer script or obtain
its progress display. In another terminal, check the printed recovery path with
`du -sh`, inspect `operations.tsv`, and look for active
`clean-development-state`, `mv`, `brew`, or `shasum` processes. If stopping is
unavoidable, press **Control-C once**, wait for the prompt, keep the drive
connected, and verify that `INCOMPLETE.md` exists. Do not start an ordinary new
cleanup: completed items may already be absent from the home folder. Review
`operations.tsv`, then follow
[Recover an incomplete Step 5](../00-preflight/03-account-preserving-cleanup.md#recover-an-incomplete-step-5).
The guarded `--resume-cleanup` mode reuses the same recovery folder and skips
sources already moved. If an application recreated a settings path after the
interruption, resume preserves that newer version under `resume-additions/`
without overwriting the original archive. It also rediscovers Homebrew at its
standard installation path when archived shell settings have removed it from
the current `PATH`. Use Apple's Terminal app, quit Warp and other applications
that Step 5 may remove, and retain the recovery directory until the rebuilt Mac
has been verified.

The guided wizard scans the recorded recovery folder and mounted external
volumes for the latest valid incomplete Step 5. Choose Route B and then
**Resume latest incomplete Step 5**. It restores saved cleanup choices from
`cleanup-options.tsv` or the archived wizard state, and asks for a manual scope
review if neither is available. The cleanup engine refuses to begin Step 5 in
Warp; use Apple Terminal so removing the Warp cask cannot terminate the running
cleanup.

Docker Desktop's own uninstaller can remove local containers, images, and
volumes even without Homebrew's zap mode. Therefore the broad cleanup refuses
to remove an installed Docker Desktop or OrbStack cask unless its matching
`--archive-docker-data` or `--archive-orbstack-data` option is selected. The
archive covers Docker Desktop's standard user container/group-container
locations and OrbStack's known virtual-machine and application-data locations.
A custom OrbStack storage location on another volume is deliberately
not followed or guessed; export it in OrbStack or move it into the chosen
recovery root before executing cleanup.

Each long-running copy names its source and destination and reports elapsed
time every 30 seconds. When the destination has not measurably grown for five
minutes, an interactive run asks whether to continue waiting. Choosing no stops
the copy safely, leaves all source files unchanged, and marks the partial
snapshot `INCOMPLETE.md`.

### Does this remove all settings?

It removes or archives all **known development settings named by the script**:
shell startup files, Git and hosting configuration, chezmoi and Starship,
language/package-manager state, cloud and container CLI configuration, selected
AI client state, Docker client state, and VS Code user data. With
`--zap-cask-data`, Homebrew also applies each selected cask's current zap list.

It does not claim to remove every preference on macOS. Settings for preserved
non-Homebrew applications, Apple system preferences, iCloud state, login
items, privacy grants, and unknown vendor paths remain. The generated
`settings-scope.md` is the precise record of what this run archived.

The Obsidian Second Brain and Notion planner configuration namespaces are
known development settings. Their local plans, launchers, compatibility data,
and Raycast Script Commands are archived by this broad cleanup. Obsidian
knowledge vaults under `~/Vaults` and cloud content in Notion remain in place.
Back them up and remove them deliberately if that is the intended outcome;
cleanup never treats knowledge as disposable settings and cannot delete a
Notion workspace. Exact names retained for upgrades are listed in
[Upgrade notes](../20-reference/UPGRADE-NOTES.md).

### 1Password and Keychain limits

`--archive-1password-data` removes known **local** 1Password data from the
active user account by moving it into recovery. A cloud vault or item must be
deleted or transferred in 1Password itself, and public SSH keys must be revoked
at each service. The generated `high-risk-manual-actions.md` explains the
remaining steps.

`--prepare-keychain-reset` deliberately does not move `~/Library/Keychains` or
call `security delete-keychain`. Reset the default Keychain through **Keychain
Access → Settings → Reset Default Keychains** only after confirming recovery;
Apple's workflow requires logging out and back in and deletes saved Keychain
passwords. It is not a reliable substitute for revoking cloud credentials.

## A.6 Execute and verify

When `--yes` is absent, type exactly:

```text
CLEAN DEVELOPMENT STATE
```

The cleanup stops if the phrase does not match. When it finishes:

```bash
command -v brew || echo "Homebrew removed"
test ! -e "$HOME/.local/share/chezmoi" && echo "chezmoi source archived"
ls -1dt "$HOME"/Day-One-Mac-Clean-Recovery-* 2>/dev/null | head -1
```

Restart the terminal. A stale Dock icon does not mean the corresponding cask
still exists; remove the icon from the Dock manually.

If any cask uninstall fails, the script stops and deliberately keeps Homebrew
installed so you can inspect and retry that cask. The recovery log and package
inventories remain available even though the cleanup is incomplete. Use the
guarded resume procedure above; it treats already-absent casks as completed and
does not repeat successful archive moves.

## A.7 Restore something from recovery

There is deliberately no automatic “restore everything” command. Reinstall
the desired application first, inspect its archived configuration, then copy
only the wanted file back. For example:

```bash
RECOVERY="$HOME/Day-One-Mac-Clean-Recovery-YYYYMMDDTHHMMSSZ"
mkdir -p "$HOME/.config"
cp -p "$RECOVERY/home/.config/starship.toml" "$HOME/.config/starship.toml"
```

Replace the placeholder with the actual recovery directory. If the destination
already exists, compare it before copying anything. Copy first so the recovery
archive remains intact until the rebuilt environment has been verified. Restore
projects by copying the archived `home/Developer` only while `~/Developer` is
absent.

# Part B — Roll back only the recorded Day One Mac run

If the goal is to keep the configured environment and only tidy its setup
records, do not use rollback or `--purge-state`. Use
[post-setup finalisation](FINALIZE.md). `--purge-state` runs after recorded
files and packages have been processed; it is not a state-only cleanup switch.

Use the narrow tool when unrelated Homebrew packages must stay installed.
It trusts only manifests created under:

```text
~/.day-one-mac/
```

## B.1 Preview

```bash
day-one-mac rollback
```

The normal preview handles recorded files and packages. Add `--all-recorded`
to include the chezmoi source, eligible Homebrew removal, and runner state:

```bash
day-one-mac rollback --all-recorded
```

Homebrew itself is removed only when the manifest says this runner installed
it and no unrecorded formulas or casks remain. If the manifest is absent, the
script refuses to guess.

## B.2 Execute

```bash
day-one-mac rollback --all-recorded --execute
```

Type exactly `CLEAN DAY ONE MAC` when prompted. Files that existed before the
runner are restored from captured originals. Newly created paths are archived,
and newly created directories are removed only when empty. Repositories under
`~/Developer` are never recursively deleted by this tool.

## B.3 Narrow cleanup options

```bash
day-one-mac rollback --include-dotfiles-source
day-one-mac rollback --remove-homebrew
day-one-mac rollback --purge-state
```

Combine only the scopes you intend to execute. `--all-recorded` selects all
three. Use `--archive-root` to place its `Day-One-Mac-Recovery-*` directory on
another mounted volume.

# Safety checklist 🚦

- [ ] I ran the exact command once without `--execute`.
- [ ] I saved and reviewed the Homebrew formula and cask inventory.
- [ ] I understand that every Homebrew cask app will be uninstalled by the
      broad tool.
- [ ] I understand that non-Homebrew applications remain installed.
- [ ] I chose whether cask support data, projects, container data, local
      1Password data, and detected SSH keys should stay active or move to
      recovery.
- [ ] The recovery parent exists, is writable, and has enough free space.
- [ ] I closed editors, terminals, containers, and Homebrew-managed services.
- [ ] I understand that 1Password cloud deletion and a macOS Keychain reset are
      manual, high-risk follow-up actions, not silent script operations.
- [ ] FileVault, macOS, the user account, and the disk must remain untouched.
- [ ] I will keep the recovery directory until the rebuilt environment passes
      Phase 8.

---

[← Project home](../README.md) · [Phase 8](../01-required/08-verify-and-reproduce.md)
