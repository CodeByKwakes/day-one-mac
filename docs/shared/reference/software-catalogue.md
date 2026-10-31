[← Reference library](../README.md) · [Manual handbook](../../setup/manual/README.md)

# Applications and formulae catalogue

**Purpose:** understand what each registered package does, when it is selected,
who owns installation and what still needs configuration. This is not an
“install everything” list. It describes this repository's current selection rules,
not the availability or pricing of every upstream product.

## Selection and ownership

Select only tools needed for the chosen workload. The catalogue is reference
material, not an executable installer or a mandate to install every item.
Keep existing approved installations and update them through their actual owner.
Sign-in, trust, configuration and functional verification remain separate tasks.
The selection column identifies the task that needs each package.

A Homebrew **formula** usually supplies a command-line package. A **cask** can
supply a desktop app, font or CLI: `1password-cli` and `codex` are casks here.
Use `brew info --formula TOKEN` or `brew info --cask TOKEN` to inspect the intended
package before choosing installation. Those lookups may access Homebrew's network.

For apps, keep a valid existing Homebrew, Company Portal, App Store or trusted
manual installation. Do not install a duplicate merely because `brew list` does
not know about it. Update through the actual owner. Choose Homebrew only when it is the approved installation owner.

## Registered applications, CLI casks and font

IDs identify entries in the reviewed application catalogue. They are not shell
commands. Use the linked manual guide to install and verify a selected tool.

| ID | Name and purpose | Homebrew cask | Selected task | Manual setup and verification |
|---|---|---|---|---|
| `1password` | 1Password - account secrets and vault-owned SSH keys | `1password` | `1password` auth | Unlock correct account, establish recovery, enable agent; [walkthrough](../../setup/manual/security/1password.md) |
| `1password-cli` | 1Password CLI - authorised vault access from Terminal | `1password-cli` | `1password` auth | Enable integration; `op --version`, then approved account access; [walkthrough](../../setup/manual/security/1password.md) |
| `git-credential-manager` | Git Credential Manager - HTTPS Git browser sign-in and secure credential storage | `git-credential-manager` | HTTPS helper `gcm`, when selected | Existing external installation is preserved; executable, scoped helper and real Git access checks; [Manual recipe](../../setup/manual/git/setup.md) |
| `jetbrains-mono-nerd-font` | JetBrains Mono Nerd Font - coding font with prompt glyphs | `font-jetbrains-mono-nerd-font` | Selected productivity tools | Select font in terminal/editor; inspect glyphs; [font check](../../setup/manual/apps/README.md#check-the-selected-font) |
| `raycast` | Raycast - launcher, capture and chosen workflow shortcuts | `raycast` | Selected productivity tools | Choose shortcuts/permissions, test launch; [Raycast](../../setup/manual/apps/raycast.md) |
| `visual-studio-code` | Visual Studio Code - editor, profiles and extensions | `visual-studio-code` | Selected editor setup | Check `code --version` after CLI integration; select profile; [VS Code](../../setup/manual/editors/vscode.md) |
| `warp` | Warp - terminal and optional shared workflows | `warp` | Selected productivity tools | Open shell, check prompt/font, review account/import; [Warp](../../setup/manual/terminals/warp.md) |
| `docker-desktop` | Docker Desktop - local container engine | `docker-desktop` | Optional | Finish first-run setup; verify `docker --version` and `docker info`; [databases](../../setup/manual/databases/containers.md) |
| `orbstack` | OrbStack - local container engine | `orbstack` | Optional | Launch, review resources/startup and `docker context show`; [databases](../../setup/manual/databases/containers.md) |
| `dbeaver-community` | DBeaver Community - database connection/query GUI | `dbeaver-community` | Optional | [DBeaver and VS Code setup](../../setup/manual/databases/dbeaver.md); connect to intended local test DB; [database services](../../setup/manual/databases/containers.md) |
| `claude-code` | Claude Code - terminal AI coding client | `claude-code` | Optional | `claude --version`, chosen account and workspace permissions; [AI clients](../../setup/manual/ai/clients.md) |
| `codex` | Codex CLI - terminal AI coding client, not the desktop app | `codex` | Optional | `codex --version`, chosen account and workspace permissions; [AI clients](../../setup/manual/ai/clients.md) |
| `copilot-app` | GitHub Copilot app - graphical AI client | `github-copilot-app` | Optional | Open app, confirm account/entitlement and permissions; [AI clients](../../setup/manual/ai/clients.md) |
| `copilot-cli` | GitHub Copilot CLI - terminal AI client | `copilot-cli` | Optional | `copilot --version`, chosen account and permissions; [AI clients](../../setup/manual/ai/clients.md) |
| `obsidian` | Obsidian - local Markdown knowledge vaults | `obsidian` | Optional knowledge system | Open intended vault and test capture/search/backup; [Second Brain](../../setup/manual/second-brain/README.md) |
| `purge` | Purge - optional cleanup application | `jithin-sabu/tap/purge` | Optional | Review exact candidates and recovery before any deletion; [maintenance](../../setup/manual/maintenance.md) |

GUI apps should also be opened and tested: a valid bundle is not evidence of
permissions, connectivity or usability. Do not launch a cleanup operation as an
installation test. The catalogue records DBeaver's `dbeaver` and OrbStack's
`docker` command hints, but a missing optional launcher alone is not proof that
a GUI app is absent.

## Required and conditional formulae

Use `brew list --formula TOKEN` for Homebrew ownership/version evidence. The
command column names the executable, which may differ from the formula token.
Do not run commands against real projects solely as a presence check.

| Formula | Purpose | Selected when | Command | Configuration guide |
|---|---|---|---|---|
| `chezmoi` | Track and render portable dotfiles into the home directory | Local or private-Git ownership only | `chezmoi` | [Learning path](../../setup/manual/shell/README.md); review diffs before apply |
| `ghq` | Locate and clone repositories beneath reviewed roots | Only when opted in | `ghq` | [Developer folders](../../setup/manual/development/folders.md); independent of hosting track and chezmoi |
| `git` | Version control for repositories and dotfiles | Always | `git` | [Manual recipe](../../setup/manual/git/setup.md); author identity and separate signing |
| `jq` | Read and transform JSON | Always | `jq` | [Foundation](../../setup/manual/homebrew.md); no account needed |
| `ripgrep` | Search file contents efficiently | Always | `rg` | [Core tools](../../setup/manual/git/setup.md); no account needed |
| `starship` | Configurable cross-shell prompt | Only when selected | `starship` | [Manual recipe](../../setup/manual/shell/README.md); shell init and font |
| `zsh` | Homebrew-managed interactive shell | Homebrew shell selection only | `zsh` | [Manual recipe](../../setup/manual/shell/README.md); Apple/current zsh does not require this formula |
| `fnm` | Select and install Node.js versions | Node or both | `fnm` | [Manual recipe](../../setup/manual/languages.md); initialise shell, select Node |
| `pnpm` | Node project package manager | Node or both | `pnpm` | [Manual recipe](../../setup/manual/languages.md); respect project manager/version |
| `uv` | Manage Python versions, environments and dependencies | Python or both | `uv` | [Manual recipe](../../setup/manual/languages.md); use project environments |
| `gh` | GitHub account and repository CLI | GitHub or both | `gh` | [Manual recipe](../../setup/manual/git/setup.md); interactive login |
| `azure-cli` | Azure account and service CLI (cask; legacy formula accepted) | Azure or both | `az` | `brew list --cask --versions azure-cli`; [Manual recipe](../../setup/manual/git/setup.md), account/tenant and DevOps extension |

## Optional formulae

Every row below is optional. Select tools for an actual task through the
[shell and tool workflow](../../setup/manual/shell/package-workflows.md).
The purpose descriptions mirror `config/catalogs/optional-formulae.tsv`. Installation
does not activate shell hooks, trust a certificate authority, accept an App Store
purchase or update a desired-state Brewfile. Use a reviewed Brewfile through
[selective Brewfile procedure](../../setup/manual/apps/brewfile.md) when deliberately adding
long-term ownership. The table is a supported selection catalogue, not all formulae
that Homebrew may accept.

| Group | Formula | Purpose | Command / manual follow-up |
|---|---|---|---|
| Containers | `dive` | Inspect Docker image layers and wasted space | `dive`; select a local development image |
| Containers | `lazydocker` | Terminal interface for Docker and Compose | `lazydocker`; verify context before mutating resources |
| Content | `ffmpeg` | Convert and inspect audio and video | `ffmpeg`, `ffprobe`; choose separate output files |
| Content | `gifsicle` | Create and optimise GIF files | `gifsicle`; preserve originals |
| Content | `imagemagick` | Convert and inspect raster images | `magick`; preserve originals |
| Development | `act` | Run GitHub Actions workflows locally | `act`; inspect workflow code, secrets and container context |
| Development | `actionlint` | Statically check GitHub Actions workflow files | `actionlint`; point at intended workflow |
| Development | `httpie` | Human-friendly HTTP client | `http`, `https`; avoid tokens in command history |
| Development | `mkcert` | Create locally trusted development certificates | `mkcert`; CA trust is a separate manual decision in the [local HTTPS task](../../setup/manual/local-https.md) |
| Development | `shellcheck` | Static analysis for shell scripts | `shellcheck`; checks text without running the script |
| Development | `shfmt` | Format shell scripts consistently | `shfmt`; inspect a diff before write mode |
| Development | `watchman` | Watch files and trigger rebuilds | `watchman`; scope watches to the intended project |
| Development | `wget` | Download files from HTTP and FTP | `wget`; inspect source and destination |
| Development | `yq` | Query and edit YAML, JSON and XML | `yq`; inspect output before in-place edits |
| Git | `git-delta` | Readable Git diffs and syntax highlighting | `delta`; opt into pager settings manually |
| Git | `git-lfs` | Git support for large binary files | `git lfs`; review repository hooks/tracking rules |
| Git | `gitleaks` | Detect secrets in repositories | `gitleaks`; findings may themselves contain sensitive data |
| Git | `lazygit` | Terminal interface for Git | `lazygit`; check repository/branch before actions |
| Navigation | `bat` | Syntax-highlighted file viewer | `bat`; shell aliases are optional |
| Navigation | `eza` | Modern replacement for ls | `eza`; shell aliases are optional |
| Navigation | `fd` | Fast file finder | `fd`; choose search root |
| Navigation | `fzf` | Interactive fuzzy finder | `fzf`; shell keybindings/completion require opt-in |
| Navigation | `tree` | Display directory trees | `tree`; avoid publishing private directory inventories |
| Navigation | `zoxide` | Directory jumper learned from shell history | `zoxide`; review shell init before activation |
| Shell | `direnv` | Load per-project environment variables | `direnv`; read each `.envrc` before allowing execution |
| Shell | `zsh-autosuggestions` | Suggest commands from shell history | Shell plugin, no standalone command; source only after review |
| Shell | `zsh-completions` | Additional Zsh completions | Shell plugin; configure completion paths/order deliberately |
| Shell | `zsh-syntax-highlighting` | Highlight valid and invalid shell commands | Shell plugin; review shell load order |
| System | `btop` | Interactive process and resource monitor | `btop`; inspect rather than terminate processes as a test |
| System | `duf` | Readable filesystem usage | `duf`; inspect capacity |
| System | `dust` | Readable directory size analysis | `dust`; scope scans to intended directories |
| System | `hyperfine` | Command-line benchmarking | `hyperfine`; benchmarked commands really execute repeatedly |
| System | `mas` | Inventory and manage Mac App Store applications | `mas`; account, licensing and purchases remain manual |
| System | `tlrc` | Maintained tldr client for concise command examples | `tldr`; read examples before running them |
| System | `watch` | Repeat a command and display changes | `watch`; repeated commands can mutate data |

For a harmless install check, prefer `brew list --formula TOKEN` and
`command -v COMMAND` (replace both placeholders). Shell plugins have no executable to find.
Then use the tool's help in a test context; command presence does not prove shell
activation or correct configuration. [Shell configuration](../../setup/manual/shell/zsh.md)
covers reviewed helper activation, not automatic trust of every shell plugin.

## Related tools with different owners

| Tool or payload | Owner and boundary |
|---|---|
| Xcode Command Line Tools | Apple/macOS installation during foundation setup; not a Homebrew formula |
| Homebrew | Package manager bootstrap during foundation setup; casks/formulae are its separate payloads |
| Node.js and npm | Node installed through `fnm` during language setup; npm comes with Node, not a second global installation |
| Python | Managed through `uv` for the selected stack; do not replace macOS's system Python |
| Azure DevOps CLI extension | Installed through `az extension`, not a separate brew formula |
| Git Credential Manager | Conditional required CLI cask when GCM is the selected HTTPS credential owner; external approved installations are preserved |
| Notion | Cloud account/workspace; browser/manual approved app route, not an automatically installed catalogue cask; [setup](../../setup/manual/second-brain/README.md) |
| SSH, Keychain, FileVault | macOS facilities; use Apple's SSH tools for Keychain integration; [security](../../setup/manual/security/README.md) |
| Database images and OmniRoute | Container payloads with separate versions/digests, volumes and startup policy; the database and gateway guides, not brew formulae |
| VS Code / Raycast extensions | Owned by the app/profile and its extension system; review permissions separately |
| MCP servers and AI subscriptions | Selected endpoint/package/account owners; installation does not grant trust or pay for access |
| Contributor dependencies | Repository `package.json`/lockfile; not required for end-user setup or offline documentation |

## Maintenance contract

Reference catalogues live in `config/catalogs/applications.tsv` and
`config/catalogs/optional-formulae.tsv`. Update this guide when those references
change and verify vendor package names before changing installation advice.

Do not automatically remove unlisted installed software: users and organisations
may own unrelated tools. Removing a package, deleting its data, revoking its account
and removing its dotfile configuration are separate decisions.
