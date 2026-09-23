[← Advanced 18](18-hosting-identities-azure-and-worktrees.md) · **🤖 ⚙️ Advanced 19** · [Advanced 20 →](20-restore-and-migrate.md)

# Advanced 19 — macOS, GUI applications, and local HTTPS

**Time:** 45–120 minutes · **Required:** no · **Prerequisite:** stable required setup

## Outcome

macOS preferences and application permissions are changed deliberately after
their current values are recorded. Optional productivity applications are
configured without importing unknown legacy state, and local HTTPS uses a new
machine-local development CA that is never committed.

The ordinary Finder, Dock, keyboard, trackpad, menu-bar, and screenshot choices
now belong to the early [macOS Settings Wizard](../01-required/MACOS-SETTINGS.md). Run that
wizard after Phase 1 even if you do not plan to use this advanced module.
Advanced 19 remains optional and covers broader preference design, application
permissions, login items, browser roles, and local HTTPS.

## Step 19.1 — Separate preferences from security controls

| Area | Automation policy |
|---|---|
| Finder, Dock, keyboard repeat, screenshots | Scriptable after current values are captured |
| Accessibility, Full Disk Access, Screen Recording, Automation | Grant manually to a named app only when a feature requires it |
| FileVault, Touch ID, Apple ID, firewall | Keep under System Settings and verify; do not toggle in a preference script |
| Login items | Review in System Settings; keep the set small |
| Browser extensions and default apps | Configure through the owning application |

Do not use a blanket permission tool or copy the privacy database from another
Mac. macOS privacy decisions are machine- and code-signature-specific.

## Step 19.2 — Capture current defaults

Create a private report before writing anything:

```bash
report="$HOME/.day-one-mac/macos-defaults.before-advanced-19.txt"
{
  date
  sw_vers
  printf '\nFinder\n'
  defaults read com.apple.finder 2>/dev/null || true
  printf '\nDock\n'
  defaults read com.apple.dock 2>/dev/null || true
  printf '\nGlobal domain\n'
  defaults read NSGlobalDomain 2>/dev/null || true
  printf '\nScreenshots\n'
  defaults read com.apple.screencapture 2>/dev/null || true
} > "$report"
chmod 600 "$report"
printf '%s\n' "$report"
```

This is an audit record, not an automatic restore file. Before changing a key,
also record the exact old value and value type in a small rollback table:

```text
Domain                 Key                     Type     Old value   New value
NSGlobalDomain         AppleShowAllExtensions  boolean  false       true
com.apple.dock         autohide                boolean  false       true
com.apple.dock         orientation             string   bottom      right
```

Store the table at
`~/.day-one-mac/macos-defaults.rollback-advanced-19.md`. If a key has no old
value, write `not set`; rollback then uses `defaults delete`, not a guessed
replacement. This gives each approved preference a real inverse operation.

## Step 19.3 — Preview a conservative preference set

The wider setup used the following ergonomic preferences. Review each line and
remove anything that is not your choice:

```bash
printf '%s\n' \
  'defaults write NSGlobalDomain AppleShowAllExtensions -bool true' \
  'defaults write com.apple.finder ShowPathbar -bool true' \
  'defaults write com.apple.finder ShowStatusBar -bool true' \
  'defaults write com.apple.finder FXPreferredViewStyle -string Nlsv' \
  'defaults write com.apple.dock tilesize -float 44' \
  'defaults write com.apple.dock orientation -string right' \
  'defaults write com.apple.dock magnification -bool false' \
  'defaults write com.apple.dock autohide -bool true' \
  'defaults write com.apple.dock mineffect -string scale' \
  'defaults write com.apple.dock minimize-to-application -bool true' \
  'defaults write com.apple.dock launchanim -bool false' \
  'defaults write com.apple.dock show-process-indicators -bool true' \
  'defaults write com.apple.dock show-recents -bool false' \
  'defaults write NSGlobalDomain KeyRepeat -int 2' \
  'defaults write NSGlobalDomain InitialKeyRepeat -int 15' \
  'defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"'
```

Keyboard repeat values are accessibility preferences, not universal best
settings. Test them before keeping them. `Nlsv` requests Finder list view.

## Step 19.4 — Apply only approved preferences

Create the screenshot directory first:

```bash
mkdir -p "$HOME/Pictures/Screenshots"
```

Run only the approved `defaults write` lines from Step 19.3. Reload affected
applications after all writes:

```bash
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
```

Log out and back in before diagnosing a preference that does not update
immediately. macOS may rename or ignore private preference keys in future
releases; a missing effect is not permission to use `sudo defaults write`.

Read every value back after signing in again. These commands do not change the
Mac; they show what macOS actually retained:

```bash
defaults read NSGlobalDomain AppleShowAllExtensions
defaults read com.apple.finder ShowPathbar
defaults read com.apple.finder ShowStatusBar
defaults read com.apple.finder FXPreferredViewStyle
defaults read com.apple.dock tilesize
defaults read com.apple.dock orientation
defaults read com.apple.dock magnification
defaults read com.apple.dock autohide
defaults read com.apple.dock mineffect
defaults read com.apple.dock minimize-to-application
defaults read com.apple.dock launchanim
defaults read com.apple.dock show-process-indicators
defaults read com.apple.dock show-recents
defaults read NSGlobalDomain KeyRepeat
defaults read NSGlobalDomain InitialKeyRepeat
defaults read com.apple.screencapture location
```

Compare the output with your rollback table. If macOS 27 ignores a private key,
mark that preference as unsupported and restore or delete the key using the
recorded inverse action. Do not repeatedly rewrite it or add `sudo`.

## Step 19.5 — Complete manual security and permission review

Open **System Settings → Privacy & Security** and review these categories:

- Accessibility
- Full Disk Access
- Files and Folders
- Screen & System Audio Recording
- Automation
- Developer Tools

For each listed application ask:

1. Do I still use this application?
2. Does the feature I use require this exact permission?
3. Is the application installed from the intended source and currently signed?

Remove stale entries. Grant the narrowest permission only after the application
requests it during a feature you initiated. Terminal, Warp, VS Code, AI clients,
and container tools do not all need Full Disk Access by default.

Verify FileVault separately:

```bash
fdesetup status
```

## Step 19.6 — Review login items and background services

Open **System Settings → General → Login Items & Extensions**. Keep only tools
that must be available immediately after sign-in, such as the selected password
manager and container runtime when daily projects need it.

Avoid enabling every menu-bar utility at login. A typical advanced set might
include:

```text
1Password       credential and SSH agent availability
OrbStack        only when local containers are used daily
Raycast         only when it replaces Spotlight workflows
Thaw            only when menu-bar management is wanted
```

Record optional casks in the Brewfile after Advanced 16 review.

## Step 19.7 — Configure Raycast and menu-bar tools intentionally

Raycast configuration can include hotkeys, snippets, aliases, Quicklinks, and
extension settings. For a new Mac, configure a small set manually first. Export
a `.rayconfig` only after it is understood and store it in encrypted backup,
not public Git.

Recommended order:

1. Choose whether Raycast replaces Spotlight.
2. Add one global activation shortcut.
3. Add only reviewed extensions.
4. Configure aliases/Quicklinks without embedded tokens.
5. Export the working configuration to encrypted backup.

Use Thaw as the menu-bar manager when selected. Do not install a second tool
that solves the same menu-bar hiding problem.

## Step 19.8 — Choose browsers by role

Do not install every browser from an old catalogue. Choose roles:

| Role | Suggested decision |
|---|---|
| Personal default | One browser signed into the personal profile |
| Work-managed | Employer-required browser/profile only on relevant Macs |
| Web compatibility | One secondary engine for testing |
| Automated tests | Browser binaries owned by Playwright/project tooling |

Keep password-manager browser extensions paired with the intended account and
review profile sync before importing historical extensions.

## Step 19.9 — Create a new local HTTPS authority

Install mkcert only when local HTTPS is required:

```bash
brew install mkcert
mkcert -install
mkcert -CAROOT
```

`mkcert -install` adds a local development CA to the macOS trust store and may
prompt for approval. The private CA key under the printed CAROOT is a secret.
Never commit it, attach it to a ticket, or copy it to another developer.

Generate repository-local certificates for explicit hostnames:

```bash
mkdir -p .certs
mkcert -cert-file .certs/localhost.pem \
  -key-file .certs/localhost-key.pem \
  localhost 127.0.0.1 ::1
```

Add `.certs/` to that repository's ignore rules. Production certificates must
come from the deployment platform, not this local authority.

To remove trust later:

```bash
mkcert -uninstall
```

Review and remove generated local certificates separately; do not delete the
CAROOT until every local certificate dependency is understood.

## Step 19.10 — Record reproducible versus manual state

| State | Record where |
|---|---|
| Selected casks/formulae | chezmoi-managed Brewfile |
| Approved `defaults` commands | reviewed script in private dotfiles, with OS notes |
| Raycast export | encrypted backup |
| Privacy permissions | checklist/report only; never copy the privacy database |
| Login items | checklist/report plus app-owned setting |
| Local CA private key | machine-local secret; regenerate rather than commit |

## Rollback

- Restore each value from the rollback table with the matching `defaults write`
  type. When its recorded old value is `not set`, use `defaults delete` for that
  exact domain and key instead of inventing a default.
- Revoke privacy permissions through System Settings.
- Disable login items before uninstalling their application.
- Use `mkcert -uninstall` to remove the development CA trust.
- Restore application exports through the owning application, not by copying a
  whole `~/Library` tree.

## Advanced 19 completion checklist 🚦

- [ ] The pre-change defaults report exists with private permissions.
- [ ] Only individually approved preference commands were applied.
- [ ] Privacy permissions are minimal and stale entries were removed.
- [ ] FileVault remains on.
- [ ] Login items contain only daily necessities.
- [ ] Optional GUI applications are represented in the reviewed Brewfile.
- [ ] Raycast/Thaw/browser roles do not duplicate one another unnecessarily.
- [ ] Local HTTPS keys are ignored, private, and never shared.
- [ ] Every changed preference or app has a documented rollback route.

```bash
day-one-mac advanced --complete 19
```

---

[← Advanced 18](18-hosting-identities-azure-and-worktrees.md) · [Continue to Advanced 20 →](20-restore-and-migrate.md)
