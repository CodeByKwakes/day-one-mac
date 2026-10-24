# Install Apple tools and Homebrew

Prepare the native package manager and the small shared command-line baseline.
Complete [macOS setup](macos.md) first. Existing software stays with its current
owner; check before installing a duplicate.

## 1. Check Apple Command Line Tools

Run `xcode-select -p`.

Expected result: an existing developer directory. If it fails, run
`xcode-select --install` and finish Apple's graphical installer before retrying.

## 2. Verify the compiler

Run `clang --version`.

Expected result: an Apple compiler version. For full Xcode, also use
`xcodebuild -checkFirstLaunchStatus`; complete Apple's licence and first-launch
workflow if requested. Full Xcode is optional for this base.

## 3. Inspect Homebrew ownership

Check `/opt/homebrew/bin/brew --prefix` if that executable exists.

Expected result: `/opt/homebrew`. Reuse that installation. If `command -v brew`
finds another prefix, stop and investigate the existing installation. Do not
combine Intel and native Homebrew paths.

## 4. Install Homebrew only if absent

On a managed Mac, ask IT to provision the approved native installation. On a
personal Mac, follow the installer linked by [Homebrew](https://brew.sh/):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Expected result: the installer finishes successfully and reports the native
prefix. Read its prompts. A failed download or installer is a stop condition.

## 5. Load Homebrew in this terminal

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Expected result: `command -v brew` resolves under `/opt/homebrew`. The
[shell guide](shell/README.md) covers persistent startup configuration.

## 6. Update the package metadata

Run `brew update`.

Expected result: repository metadata is current or a specific network error is
reported. This is separate from upgrading all installed packages.

## 7. Check installation health

Run `brew doctor`.

Expected result: no unresolved warning affecting the selected setup. Review
warnings individually; do not use recursive `sudo chmod` on Homebrew or home.

## 8. Install the shared command-line tools

```bash
brew install git jq ripgrep
```

Expected result: `git --version`, `jq --version` and `rg --version` each report a
version. Homebrew keeps already-installed packages under its own management.

## Select further packages

Install only tools required by the following tasks. The
[software catalogue](../../shared/reference/software-catalogue.md) explains each
selection. The language guide owns fnm/pnpm/uv installation; the shell guide owns
chezmoi/Zsh/Starship; the authentication guide owns its credential tools.
Productivity applications are optional for the core selection.

## Troubleshooting and recovery

| Symptom | Check and next action |
|---|---|
| `brew` is not found | Check the native executable, then repeat Step 5 |
| Permission error | Inspect the exact path and its owner; ask IT on a managed Mac |
| Download/TLS failure | Verify the approved network and certificates with IT |
| Compiler unavailable after an OS update | Recheck Apple's developer-tools selection and installation |

Do not uninstall shared Homebrew as a troubleshooting shortcut. Record selected
packages in the final Brewfile and back up data separately.

Next: choose [Git authentication](security/README.md).
