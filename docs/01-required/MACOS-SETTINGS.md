[← Phase 1](01-first-boot-and-decisions.md) · **⚙️ Early optional macOS settings** · [Phase 2 →](02-command-line-foundation.md)

# Early macOS Settings Wizard

**Time:** 10–25 minutes · **Required:** no · **Runs:** after Phase 1 and before Phase 2

## Why this happens early

Phase 1 installs all macOS updates first. The Settings Wizard then establishes
the Finder, Dock, keyboard, trackpad, menu-bar, and screenshot behaviour you
will use during the rest of setup. Running it before the update could be wasted
because a major macOS update may migrate or reset private preferences.

Skipping this step is safe. It records an intentional skip and immediately
continues to Phase 2. Required Apple-silicon, backup, Gatekeeper, FileVault, and
application checks remain in their owning phases and cannot be bypassed by
skipping optional preferences.

## What the Phase 1 checkpoint asks

```text
macOS preferences are optional and run before development tools.
[Enter] configure Finder, Dock, keyboard and trackpad   s skip   q stop:
```

The choice is saved under `~/.day-one-mac`. Press Enter to open the settings
wizard, `s` to continue directly to Phase 2, or `q` to stop safely. Rerunning
the required setup resumes at this checkpoint. Existing saved choices remain
valid, so upgrading this playbook does not reset completed phases.

## What is automatic and what remains manual

The script can safely write and read back these scalar user preferences:

- hidden files, filename extensions, path bar, status bar, and default Finder view;
- a compact Dock on the right, automatic hiding, stable icon sizes, Scale
  minimisation, windows minimised into app icons, reduced launch animation,
  running-app indicators, and no suggested or recent apps;
- keyboard repeat and automatic spelling correction;
- screenshot location.

These settings remain manual because the relevant preference storage is
hardware-specific or changes across macOS versions:

- calculate all folder sizes in Finder;
- show the current user's home folder in the Finder sidebar;
- battery percentage;
- tap to click;
- Natural scrolling.

The report gives the exact current System Settings path for every selected
manual item.

## Recommended Dock preset

The wizard selects each Dock preference separately, so you can keep the full
preset or turn off individual choices with Space before applying it:

| Setting | Day One Mac recommendation | Reason |
|---|---|---|
| Size | 44 | Compact but still easy to target |
| Position | Right | Preserves vertical space for code, terminals, and web pages |
| Magnification | Off | Icons do not move while you are choosing one |
| Automatically hide and show | On | Returns more space to the active window |
| Minimise effect | Scale | Faster and less distracting than Genie |
| Minimise into application icon | On | Avoids a second row of individual window thumbnails |
| Animate opening applications | Off | Reduces unnecessary motion |
| Indicators for open applications | On | Makes running applications visible at a glance |
| Suggested and recent applications | Off | Keeps the Dock stable and intentional |

These are productivity defaults, not requirements. For improved visibility,
increase the size, leave automatic hiding off, or enable magnification. On a
company-managed Mac, an enforced Dock position or layout takes priority over
the wizard selection.

## Security review

Before showing preference changes, the script reports the current Firewall,
FileVault, and Gatekeeper status. It does not change those controls and never
runs `spctl --master-disable`.

Review manually:

| Control | Current path | Recommended baseline |
|---|---|---|
| Firewall | System Settings → Network → Firewall | On; review application prompts |
| FileVault | System Settings → Privacy & Security → FileVault | On with understood recovery arrangements |
| Gatekeeper | System Settings → Privacy & Security → Security | App Store and identified developers |
| File Sharing | System Settings → General → Sharing | Off unless deliberately needed |

On a company-managed Mac, policy may lock a control. Treat a managed value as
the employer's configuration, not as a script failure.

## Run it independently

With the portable command installed, run:

```bash
day-one-mac macos-settings
```

If the portable command is unavailable, run it from this project's scripts directory:

```bash
day-one-mac macos-settings --wizard
```

Use arrow keys or `j`/`k` to move, Space to toggle, and Return to review. The
wizard shows every automated command and asks once before applying anything.
An unselected item is left unchanged; deselecting is not a restore operation.
If manual preferences are selected, the wizard groups them into one batch and
asks for one completion confirmation before the guided setup continues.

## Preview, inspect, or restore

```bash
# Show the saved selection without changing the Mac.
day-one-mac macos-settings --preview

# Show status and report locations.
day-one-mac macos-settings --status

# Restore values captured before the first write.
day-one-mac macos-settings --restore
```

State is private to this Mac:

```text
~/.day-one-mac/
├── macos-settings-plan
├── macos-settings-selection
├── macos-settings-status
└── macos-settings/
    ├── original-values.tsv
    └── report.md
```

`original-values.tsv` records whether each setting was absent and, when
present, its scalar type and value. Restore writes the recorded value or
deletes a key that did not exist before Day One Mac. It never restores an
entire preferences domain over unrelated application settings.

## Completion meanings

| Status | Meaning |
|---|---|
| `completed` | Selected automated settings were written and read back, and selected manual preferences were confirmed |
| `manual-pending` | Automated settings passed, but selected manual preferences were not confirmed; guided setup pauses |
| `skipped` | The main wizard intentionally continued without preference changes |
| `restored` | Captured original values were restored |
| `not run` | No settings decision has been applied yet |

After completion or an intentional skip, continue to
[Phase 2 — Command-line foundation](02-command-line-foundation.md).

## How this replaces the five-year-old web-development guide

| Former instruction | Day One Mac replacement |
|---|---|
| Disable Gatekeeper with `spctl --master-disable` | Removed; keep Gatekeeper enabled and use a reviewed one-app exception only when necessary |
| Separate Apple-silicon and Intel Homebrew instructions | Apple silicon only, `/opt/homebrew`, verified in Phase 2 |
| Install another zsh and edit `/etc/shells` | Kept, but automated: Phase 5 installs Homebrew zsh, registers it in `/etc/shells`, and switches your login shell after asking. Shell files are still small and chezmoi-managed |
| Install Oh My Zsh and clone plugins manually | Starship in the base; optional Homebrew-managed helpers in Module 13 |
| Install NVM from a dynamically discovered script | Homebrew `fnm` with `eval "$(fnm env --use-on-cd --shell zsh)"` |
| Generate a local RSA SSH key by default | 1Password SSH agent; Ed25519 is the documented fallback |
| Install Python with global pip or pyenv | uv-managed Python and project environments |
| Run PostgreSQL, MySQL, and MongoDB as global Homebrew services | Optional reviewed containers through OrbStack in Module 9 |
| Globally ignore broad paths such as `.vscode` and package artefacts | Keep the global ignore small; use repository-specific `.gitignore` files |

---

[← Phase 1](01-first-boot-and-decisions.md) · [Continue to Phase 2 →](02-command-line-foundation.md)
