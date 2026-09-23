[← Early macOS settings](MACOS-SETTINGS.md) · **Phase 2** · [Installation Centre →](INSTALLATION-CENTRE.md)

# Phase 2 — Command-line foundation

**Time:** 20–40 minutes · **Required:** everyone

## Outcome

Apple's Command Line Tools and Homebrew are installed, Homebrew is available in
the current terminal, and its ownership is recorded for later rollback. No
third-party development packages are installed until the Installation Centre
that follows this phase.

## How to use this phase

The recommended route is to run
`day-one-mac setup --phase 02` from any directory
shown in Phase 1. Use Steps 2.1–2.3 to understand what the runner does or to
recover if it pauses. If the phase passes, do not run the same installation
commands again. See [Start Here](../START-HERE.md) for Terminal basics.

## What this phase changes

- Installs Apple's compilers, SDK headers, Git bootstrap, and build utilities.
- Installs native Apple-silicon Homebrew under `/opt/homebrew`.
- Runs `brew update` and records whether this project installed Homebrew.

The cleanup script can remove Homebrew later, but it deliberately leaves
Command Line Tools as a separate operating-system decision.

## Step 2.1 — Install Xcode Command Line Tools

Check first:

```bash
xcode-select -p
```

If it prints a developer directory, the tools are already installed. Otherwise
start Apple's installer:

```bash
xcode-select --install
```

Complete the graphical installer. The setup runner cannot click or accept the
licence on your behalf, so it pauses and asks you to rerun Phase 2 afterwards.

Verify:

```bash
xcode-select -p
clang --version
/usr/bin/git --version
```

When full Xcode is selected, also verify that its licence and first-launch
components are complete:

```bash
xcodebuild -checkFirstLaunchStatus
```

If it fails, review the licence and complete Apple's setup, then rerun Phase 2:

```bash
sudo xcodebuild -license
sudo xcodebuild -runFirstLaunch
```

The runner never accepts the licence automatically.

If you use a standalone Command Line Tools installation rather than full Xcode,
you can check which version is installed:

```bash
pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
```

Expected output:

```text
package-id: com.apple.pkg.CLTools_Executables
version: 27.0.0.0.1788430756
volume: /
location: /
```

The package version follows **Xcode's** release numbering, not the macOS
version, and Xcode normally runs at or ahead of macOS. On macOS 26.7, for
example, the current package already reports `27.x`. So a number higher than
your macOS version is normal and correct.

What matters is the opposite case: a package version **lower** than your macOS
major version means the tools are stale. Install the current ones from Software
Update, or rerun `xcode-select --install`.

If the command reports `No receipt for 'com.apple.pkg.CLTools_Executables'
found at '/'`, the standalone package is not installed. That is fine when
`xcode-select -p` points inside `Xcode.app`, because full Xcode supplies the
same tools.

If the installer says the tools are unavailable, finish all macOS updates,
restart, and try again.

## Step 2.2 — Install Homebrew

The runner checks before it installs anything. It looks for the supported
Apple-silicon executable at `/opt/homebrew/bin/brew`, even when the current
Terminal has not loaded Homebrew into `PATH` yet.

You will see one of these results:

| Message | Meaning | What you do |
|---|---|---|
| `Existing Homebrew found ... installer will be skipped` | The correct copy already exists | Continue; do not reinstall it |
| `Native Homebrew was not found ...` | No supported copy was found | Approve the official installer when prompted |
| `Homebrew is on PATH ... but ... requires /opt/homebrew` | An Intel/Rosetta copy or wrapper was found | Stop, open a native `arm64` Terminal, and review that installation |

This makes the phase safe to rerun: an existing supported Homebrew installation
is updated and verified, not replaced or claimed as Day One Mac-owned.

The equivalent manual check is:

```bash
if [[ -x /opt/homebrew/bin/brew ]]; then
  printf 'Existing Apple-silicon Homebrew: %s\n' /opt/homebrew/bin/brew
elif command -v brew >/dev/null 2>&1; then
  printf 'Unsupported Homebrew location: %s\n' "$(command -v brew)" >&2
  return 1 2>/dev/null || exit 1
else
  printf 'Homebrew is not installed\n'
fi
```

Only when the last line reports that Homebrew is not installed should you run
Homebrew's official installation script:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Read the paths and actions shown by that installer before approving. Do not run
an unofficial mirror with administrator privileges.

After installation, make Homebrew available in the current shell:

```bash
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  printf 'Homebrew was not found\n' >&2
  return 1 2>/dev/null || exit 1
fi
```

On success this block prints nothing — it only adds Homebrew to the current
terminal's `PATH`. Silence is the expected result. The last line reports failure
correctly whether the block is pasted into your shell or saved into a file,
which is why it lists two ways of stopping.

Phase 5 places this native Apple-silicon block in the
chezmoi-managed `~/.config/zsh/path.zsh`, loaded by both `.zprofile` and
`.zshrc`, so it persists in future terminals.

## Step 2.3 — Update and inspect Homebrew

```bash
brew update
brew --version
brew --prefix
brew config
brew doctor
```

The first two should look like this, though your version number will differ:

```text
Homebrew 7.0.4
/opt/homebrew
```

The required prefix is `/opt/homebrew`. A `/usr/local` Homebrew installation is
an Intel or translated setup and is refused by Day One Mac.

`brew doctor` may print advice rather than a hard failure. Read each message.
On a brand-new Mac, `Your system is ready to brew.` is the ideal result, but
messages like these are common and harmless:

```text
Warning: You have unlinked kegs in your Cellar.
Warning: Some installed formulae are deprecated or disabled.
```

A message beginning `Error:` is different — resolve that before continuing.
Do not react by applying `sudo chmod -R` to `/opt/homebrew` or the
home directory. Broad permission changes make later upgrades less predictable.

## Step 2.4 — Run or resume Phase 2

```bash
day-one-mac setup --phase 02
```

The runner behaves idempotently:

1. If Command Line Tools are missing, it opens the installer and stops.
2. It checks `/opt/homebrew/bin/brew` before considering an installation.
3. If native Homebrew exists, it prints the detected path and skips installation.
4. If only an unsupported Intel/Rosetta copy is visible, it stops with a clear
   explanation instead of installing a second copy.
5. If Homebrew is missing, it asks before running the official installer.
6. If both foundations already work, it updates Homebrew and passes the gate.
7. Only a Homebrew installation performed by this runner is marked as
   runner-owned in the precise rollback manifest.

When Phase 2 passes inside the guided setup, the required
[Installation Centre](INSTALLATION-CENTRE.md) opens immediately. It installs or
accepts all required applications and command-line tools before configuration
begins. This removes the repeated install-and-stop cycle from later phases.

## Permission and network recovery

| Symptom | Safe response |
|---|---|
| `xcode-select: error` | Run `xcode-select --install`, finish the UI, then rerun |
| `brew: command not found` immediately after installation | Evaluate the correct `brew shellenv` block above |
| `curl` cannot reach GitHub | Check Wi-Fi, VPN, proxy, DNS, and system time; do not disable TLS checks |
| Homebrew reports files owned by another user | Inspect the exact paths first; repair only those paths using Homebrew's message |
| A formula is already present | Leave it; later installation helpers check before installing |
| Terminal reports `x86_64` | Quit it and reopen the native Apple-silicon build; Day One Mac does not run under Rosetta |
| Xcode reports licence or first-launch work | Run the two reviewed `xcodebuild` commands above, then rerun Phase 2 |

## Phase 2 completion checklist 🚦

- [ ] `xcode-select -p` succeeds.
- [ ] `clang --version` succeeds.
- [ ] Full Xcode, when selected, passes `xcodebuild -checkFirstLaunchStatus`.
- [ ] A standalone Command Line Tools package, if used, is not older than the
      macOS major version (a higher number is normal — it tracks Xcode).
- [ ] `brew --version` succeeds in the current terminal.
- [ ] Phase 2 explicitly reported either that existing Homebrew was found or
      that Day One Mac installed it.
- [ ] `brew --prefix` is `/opt/homebrew`.
- [ ] `brew update` completes without an error.
- [ ] Any `brew doctor` warnings are understood.

Reference: [Homebrew installation](https://brew.sh/) and
[Homebrew installation repository](https://github.com/Homebrew/install).

---

[← Early macOS settings](MACOS-SETTINGS.md) · [Continue to the Installation Centre →](INSTALLATION-CENTRE.md)
